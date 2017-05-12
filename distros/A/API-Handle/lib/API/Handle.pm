package API::Handle;
{
  $API::Handle::VERSION = '0.02';
}

use Moose::Role;
use namespace::autoclean;
use HTTP::Request;
use bytes;
use feature ':5.10';
use String::CamelCase qw/camelize decamelize/;
use Tie::Hash::Indexed;

has _config => (
	is => 'rw'
	, isa => 'Nour::Config'
	, handles => [ qw/config/ ]
	, required => 1
	, lazy => 1
	, default => sub {
		require Nour::Config;
		 return new Nour::Config ( -base => 'config' );
	}
);

has _printer => (
	is => 'rw'
	, isa => 'Nour::Printer'
	, handles => [ qw/verbose debug info warn warning error fatal dumper/ ]
	, required => 1
	, lazy => 1
	, default => sub {
		my $self = shift;
		my %conf = $self->config->{printer} ? %{ $self->config->{printer} } : (
			timestamp => 1
			, verbose => 1
			, dumper => 1
			, debug => 1
			, pid => 1
		);
		require Nour::Printer;
		 return new Nour::Printer ( %conf );
	}
);

has _database => (
	is => 'rw'
	, isa => 'Nour::Database'
	, required => 1
	, lazy => 1
	, default => sub {
		my $self = shift;
		my %conf = $self->config->{database} ? %{ $self->config->{database} } : (
			# default options here
		);
		%conf = ();
		require Nour::Database;
		 return new Nour::Database ( %conf );
	}
);

#has _util     # TODO factor all the _methods to $self->util->methods... or not

has _json => (
	is => 'rw'
	, isa => 'JSON::XS'
	, lazy => 1
	, required => 1
	, default => sub {
		require JSON::XS;
		 return JSON::XS->new->utf8->ascii->relaxed;
	}
);

has _xml => (
	is => 'rw'
	, isa => 'XML::TreePP'
	, lazy => 1
	, required => 1
	, default => sub {
		require XML::TreePP;
		 return new XML::TreePP (
			output_encoding => 'UTF-8'
			, utf8_flag => 1
			, attr_prefix => '-'
			, indent => 2
			, use_ixhash => 1
		);
	}
);

has ua => (
	is => 'rw'
	, isa => 'LWP::UserAgent'
	, lazy => 1
	, required => 1
	, default => sub {
		require LWP::UserAgent;
		 return new LWP::UserAgent;
	}
);

has uri => (
	is => 'rw'
	, isa => 'Str'
	, required => 1
	, lazy => 1
	, default => sub { '' }
);

sub BUILD {
	my $self = shift;

	# Initialize attributes like 'uri' that may be set
	# in the configuration YAML.
	for my $attr ( keys %{ $self->config } ) {
		$self->$attr( $self->config->{ $attr } )
			if $self->can( $attr );
	}

	# Add request wrapper.
	$self->ua->add_handler(
		request_prepare => sub {
			my ( $req, $ua, $h ) = @_;

			# Set Content-Length header.
			if ( my $data = $req->content ) {
				$req->headers->header( 'Content-Length' => $self->_bytes( $data ) );
			}
		}
	);
}

sub req {
	my ( $self, %args ) = @_;
	my $req = new HTTP::Request;

	$args{content} ||= $args{data} ||= $args{body};
	$args{method}  ||= $args{type};
	$args{uri}     ||= $self->_join_uri( $args{path} );

	# Preserve hash order. Maybe needed for SOAP.
	if ( defined $args{content} and (
			( ref $args{content} eq 'ARRAY' ) or # Deprecated - backwards compatibility
			( ref $args{content} eq 'REF' and ref ${ $args{content} } eq 'ARRAY' ) # New style ? => \[]
		)
	) {
		$self->_tied( ref => \%args, key => 'content', tied => 1 );
	}

	# Leave it up to the API implementation to encode the hash/array ref into JSON / Form data / XML / etc.
	$req->content( $args{content} ) if defined $args{content};
	$req->method(   $args{method} ) if defined $args{method};
	$req->uri(         $args{uri} );

	my $res = $self->ua->request( $req );

	return wantarray ? ( $res, $req ) : $res;
}

sub db {
	my ( $self, @args ) = @_;
	$self->_database->switch_to( @args ) if @args;
	return $self->_database;
}

# TODO: change all references to ->_encode to use ->encode and rename sub-routines
# TODO: same for _decode
sub _encode {
	my ( $self, %args ) = @_;
	my ( $data );

	for ( $args{type} ) {
		when ( 'json' ) {
			$data = $self->_json->encode( $args{data} );
		}
		when ( 'xml' ) {
			$data = $self->_xml->write( $args{data} );
		}
		when ( 'form' ) {
			require URI;
			my $uri = URI->new('http:');
			$uri->query_form( ref $args{data} eq "HASH" ? %{ $args{data} } : @{ $args{data} } );
			$data = $uri->query;
			$data =~ s/(?<!%0D)%0A/%0D%0A/g if defined $data;
		}
	}

	return $data;
}

sub _decode {
	my ( $self, %args ) = @_;
	my ( $data );

	for ( $args{type} ) {
		when ( 'json' ) {
			$data = $self->_json->decode( $args{data} );
		}
		when ( 'xml' ) {
			$data = $self->_xml->parse( $args{data} );
		}
	}

	return $data;
}

sub _bytes {
	my ( $self, $data ) = @_;
	return length $data;
}

# A method that will let us write readable requests insteadOfCamelCase.
# Helpful for Google SOAP APIs. See ./t/02-google-dfp.t for example.
sub _camelize {
	my $self = shift;
	my $data = shift;

	$data->{ lcfirst camelize $_ } = delete $data->{ $_ } for keys %{ $data };

	for my $data ( values %{ $data } ) {
		for ( ref $data ) {
			when ( 'ARRAY' ) {
				for my $data ( @{ $data } ) {
					$self->_camelize( $data ) if ref $data eq 'HASH';
				}
			}
			when ( 'HASH' ) {
				$self->_camelize( $data );
			}
		}
	}
}

sub _decamelize {
	my $self = shift;
	my $data = shift;
	my %args = @_;

	delete $data->{ $_ } # delete -xmlns and other attrs... why not?
		for grep { $_ =~ /^-/ } keys %{ $data };

	for ( keys %{ $data } ) {
		$data->{ decamelize $_ } = delete $data->{ $_ };
	}

	for my $data ( values %{ $data } ) {
		for ( ref $data ) {
			when ( 'ARRAY' ) {
				for my $data ( @{ $data } ) {
					$self->_decamelize( $data, %args ) if ref $data eq 'HASH';
				}
			}
			when ( 'HASH' ) {
				$self->_decamelize( $data, %args );
			}
		}
	}
}

sub _join_uri {
	my ( $self, @path ) = @_;
	my ( $base ) = ( $self->uri );

	@path = map { $_ =~ s/^\///; $_ =~ s/\/$//; $_ } @path;
	$base =~ s/\/$//;

	return join '/', $base, @path;
}


sub _tied {
	my ( $self, %args ) = @_;
	my ( @array, %hash, $ref, $tied );

	$ref = $args{ref}->{ $args{key} } if ref $args{ref} eq 'HASH';
	$ref = $args{ref}->[ $args{index} ] if ref $args{ref} eq 'ARRAY';
	$ref = ${ $args{ref} }->[ $args{index} ] if ref $args{ref} eq 'REF' and ref ${ $args{ref} } eq 'ARRAY';

	for ( ref $ref ) { # Recursion
		when ( 'REF' ) {
			if ( ref ${ $ref } eq 'ARRAY' ) { # \[]
				for my $index ( 0 .. $#{ ${ $ref } } ) {
					my $val = $$ref->[ $index ];
					$self->_tied( ref => $ref, index => $index ) if grep { ref $val eq $_ } qw/ARRAY HASH REF/;
				}

				$tied = 1;
			}
		}
		when ( 'ARRAY' ) {
			for my $index ( 0 .. $#{ $ref } ) {
				my $val = $ref->[ $index ];
				$self->_tied( ref => $ref, index => $index ) if grep { ref $val eq $_ } qw/ARRAY HASH REF/;
			}

			$tied = 1 if $args{tied}; # i.e. $args{content} from $self->req routine
		}
		when ( 'HASH' ) {
			for my $key ( keys %{ $ref } ) {
				my $val = $ref->{ $key };
				$self->_tied( ref => $ref, key => $key ) if grep { ref $val eq $_ } qw/ARRAY HASH REF/;
			}
		}
	}

	if ( $tied ) {
		tie my %hash, 'Tie::Hash::Indexed';

		for ( ref $ref ) {
			when ( 'ARRAY' ) {
				@array = @{ $ref };
			}
			when ( 'REF' ) {
				@array = @{ ${ $ref } };
			}
		}

		%hash = @array;

		for ( ref $args{ref} ) {
			when ( 'HASH' ) {
				$args{ref}->{ $args{key} } = \%hash;
			}
			when ( 'ARRAY' ) {
				$args{ref}->[ $args{index} ] = \%hash;
			}
			when ( 'REF' ) {
				${ $args{ref} }->[ $args{index} ] = \%hash;
			}
		}
	}
}

1;

__END__

=pod

=head1 NAME

API::Handle

=head1 VERSION

version 0.02

=head3 _tied

Recursively tie \[ key => $val, key => $val, ... ] data to create preserved-order hashes ( needed for SOAP ).

=head1 AUTHOR

Nour Sharabash <amirite@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Nour Sharabash.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
