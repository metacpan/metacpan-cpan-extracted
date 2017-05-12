package Bio::BioVeL::Service;
use strict;
use warnings;
use Getopt::Long;
use CGI;
use YAML qw(Dump Load DumpFile LoadFile);
use Apache2::Request;
use Apache2::RequestRec ();
use Apache2::RequestIO ();
use Apache2::Const -compile => qw(OK);
use LWP::UserAgent;
use Bio::Phylo::Util::Logger ':levels';

# this increments the verbosity in the concrete service classes
# we've implemented so far. in production systems this should
# probably be set to WARN instead to prevent flooding apache's
# /var/log/apache2/error_log (or wherever it is located).
my $log = Bio::Phylo::Util::Logger->new(
	'-level' => INFO,
	'-class' => [ 
		'Bio::BioVeL::Service::NeXMLMerger', 
		'Bio::BioVeL::Service::NeXMLExtractor' 
	]
);
our $AUTOLOAD;

=head1 NAME

Bio::BioVeL::Service - base class for synchronous web services

=head1 DESCRIPTION

The BioVeL API makes a distinction between "synchronised" and "asynchronous" services.
Synchronised services produce their final result within a single HTTP request/response
cycle by generating a response_body that is returned to the client at the end of the
cycle. Asynchronous services produce a result at the end of a longer running, forked 
process, which needs to be tracked between request/response cycles.

All concrete service classes need to inherit from either one of these service type 
superclasses (L<Bio::BioVeL::Service> or L<Bio::BioVeL::AsynchronousService>) so that
all the bookkeeping (processing request parameters, managing forked processes) is 
taken care of and the concrete child class only needs to worry about producing its
result.

=head1 METHODS

=over

=item new

The constructor takes at least one named argument, C<parameters>, whose value is an
array reference of names. The constructor then tries to obtain the values for these
named parameters. It does in a number of ways: 1. by probing the @ARGV command line
argument array, 2. by probing the apache request object (if provided), 3. by 
instantiating and querying a L<CGI> object. Once the constructor returns, the object
will have properties whose values are available to the child class for constructing
its response body.

=cut

sub new {
	my $class = shift;
	my %args  = @_;
	my $self  = { '_params' => {} };
	bless $self, $class;
	my $params = delete $args{'parameters'};
	if ( $params ) {
		if ( @ARGV ) {
			my %getopt;
			for my $p ( @{ $params } ) {
				$getopt{"${p}=s"} = sub {
					my $value = pop;
					$self->{'_params'}->{$p} = $value;
				};
			}
			GetOptions(%getopt);			
		}
		elsif ( my $req = delete $args{'request'} ) {
			for my $p ( @{ $params } ) {
				$self->{'_params'}->{$p} = $req->param($p);
			}		
		}
		else {
			my $cgi = CGI->new;
			for my $p ( @{ $params } ) {
				$self->{'_params'}->{$p} = $cgi->param($p);
			}
		}
	}
	for my $key ( keys %args ) {
		$self->$key( $args{$key} );
	}	
	return $self;
}

# the AUTOLOAD method traps all undefined method calls that child classes might
# make on themselves. the method names are turned into keys inside the object's
# '_params' hash, whose values are returned (and optionally updated, if an argument
# was provided.

sub AUTOLOAD {
	my $self = shift;
	my $method = $AUTOLOAD;
	$method =~ s/.+://;
	if ( $method !~ /^[A-Z]+$/ ) {
	
		# an argument was provided, update the parameter
		if ( @_ ) {
			$self->{'_params'}->{$method} = shift;
		}
		return $self->{'_params'}->{$method};
	}	
}

=item get_handle

Given a string parameter name, such as 'tree', returns a readable handle that corresponds
with the specified data.

=cut

sub get_handle {
	my ( $self, $location ) = @_;
	
	# location is a URL
	if ( $location =~ m#^(?:http|ftp|https)://# ) {
		my $ua = LWP::UserAgent->new;
		my $response = $ua->get($location);
		if ( $response->is_success ) {
			my $content = $response->decoded_content;
			open my $fh, '<', \$content;
			return $fh;
		}
	}
	else {
		open my $fh, '<', $location or die $!;
		return $fh;
	}
}

=item handler

This method is triggered by mod_perl when a URL path fragment is encountered that matches
the mapping specified in httpd.conf. Example:

 <Location /foo>
         SetHandler perl-script
         PerlResponseHandler Bio::BioVeL::Service::Foo
 </Location>

In this case, requests to http://example.com/foo will be dispatched to 
C<Bio::BioVeL::Service::Foo::handler>.

The method instantiates a concrete service class based on the request parameter 
C<service>, passes in the L<Apache2::Request> object and expects the concrete service
to produce a response body, which the handler prints out. The return value, 
C<Apache2::Const::OK>, indicates to mod_perl that everything went well.

=cut

sub handler {
	my $request = Apache2::Request->new(shift);
	my $subclass = __PACKAGE__ . '::' . $request->param('service');
	eval "require $subclass";
	my $self = $subclass->new( 'request' => $request );
	print $self->response_body;
	return Apache2::Const::OK;
}

=item response_header

Returns the HTTP response header. This might include the content-type.

=cut

sub response_header {
	die "Implement me!";
}

=item response_body

Returns the response body as a big string.

=cut

sub response_body {
	die "Implement me!";
}

=item logger

Returns a logger object.

=cut

sub logger { $log }

=back

=head1 CLONING

The following methods read and write service objects to/from L<YAML>. This is used for
(de-)serializing objects so that they can be persisted between HTTP request cycles.

=over

=item to_string

Returns a L<YAML> string representation of the object.

=cut

sub to_string {
	Dump(shift);
}

=item to_file

Writes the object as L<YAML> to the provided file location.

=cut

sub to_file {
	my ( $self, $location ) = @_;
	DumpFile( $location, $self );
}

=item from_string

Instantiates an object from the provided YAML string.

=cut

sub from_string {
	my ( $class, $string ) = @_;
	Load($string);
}

=item from_file

Instantiates an object from the provided location.

=cut

sub from_file {
	my ( $class, $location ) = @_;
	LoadFile($location);
}

=back

=cut

1;