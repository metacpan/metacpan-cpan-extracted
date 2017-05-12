package AnyEvent::RPC;

use 5.006000;
use common::sense 2;
m{
	use strict;
	use warnings;
}; # Until cpants will know it make strict
use Carp;
=head1 NAME

AnyEvent::RPC - Abstract framework for Asyncronous RPC clients

=cut

our $VERSION = '0.05';

=head1 SYNOPSIS

    use AnyEvent::RPC;
    
    my $rpc = AnyEvent::RPC->new(
        host => 'your.api.host',
        port => 8080,
        base => '/api/rest/',

        type => 'REST', # or type => '+AnyEvent::RPC::Enc::REST',
    )
    
    $rpc->req(  # will be called as GET http://your.api.host:8080/api/rest/method/path/args?query=param
        call  => [ method => qw(path args)],
        query => { query => 'param' },
        cb    => sub { # ( response, code, error )
            if (my $response = shift) {
                # 
            } else {
                my ($code,$err) = @_;
            }
        },
    );

=cut

sub ua      { shift->{ua} }
sub encoder { shift->{encoder} }

sub new {
	my $pkg = shift;
	my $self = bless {}, $pkg;
	$self->init(@_);
	$self->components;
	$self;
}

sub init {
	my $self = shift;
	local $SIG{__WARN__} = sub { local $_ = shift; s{\n$}{};carp $_ };
	my %args = (
		base => '/',
		@_
	);
	@$self{keys %args} = values %args;
	$self->{$_} or croak "$_ not defined" for qw(host);
	$self->{useragent} ||= 'AnyEvent::RPC/'.$AnyEvent::RPC::VERSION;
	return;
}

sub components {
	my $self = shift;
	my $package = ref $self;
	unless ( ref $self->{encoder} ) {
		$self->{encoder} = $self->_load(
			'::Enc', $self->{encoder}, 'REST',
			debug => $self->{debug},
		);
	}
	unless ( ref $self->{ua} ) {
		$self->{ua} = $self->_load(
			'::UA', $self->{ua}, '',
			ua      => $self->{useragent} || $package.'/'.( do{ no strict 'refs'; ${$package.'::VERSION'} } || $VERSION ),
			timeout => $self->{timeout},
			debug => $self->{debug},
		);
	}
	return;
}

sub _load {
	my $pkg = shift;
	my ($suffix,$req,$default,@args) = @_;
	my $prefix = __PACKAGE__.$suffix;
	if (defined $req) {
		$req =~ s{^\+}{} or $req = $prefix.'::'.$req;
	} else {
		$req = $prefix.($default ? '::'.$default : '' );
	}
	eval {
		$req->can('new')
			or require join '/', split '::', $req.'.pm';
		1;
	}
	or do {
		croak "Can't load $req: $@\n";
	};
	return $req->new(@args) or croak "$req not created";
}

sub req {
	my $self = shift;
	my %args = @_;
	croak("req have no cb and useragent is async") unless $args{cb};
	#my ( $methodname, @params ) = @{ $args{call} };
	#my $uri = "$url#$methodname";
	my %req = $self->encoder->request( $self, %args );
	#warn "request: ".dumper(\%req) if $args{debug} or $self->{debug} > 2;

	#my $start = time;
	my @data;
	#warn "Call $body";
	$self->ua->call(
		($args{method} || $req{method} || 'POST') => $req{uri},
		headers => {
			exists $req{headers} ? ( %{$req{headers}} ) : (),
			exists $args{headers} ? ( %{$args{headers}} ) : (),
		},
		exists $req{body} ? (body => $req{body}) : (),
		cb      => sub {
			my $res = shift;
			my @rv = $self->encoder->decode($self, $res);
			$args{cb}(@rv);
			return;
			my @data;
			{
				( my $status = $res->status_line )=~ s/:?\s*$//s;
				$res->code == 200 or #$args{cb}(undef);
				@data = 
					(rpcfault( $res->code, "Call to $req{uri} failed: $status" ))
					and last;
				my $text = $res->content;
				length($text) and $text =~ /^\s*<\?xml/s or @data = 
					({fault=>{ faultCode => 499,        faultString => "Call to $req{uri} failed: Response is not an XML: \"$text\"" }})
					and last;
				eval {
					@data = $self->encoder->decode( $text );
					1;
				} or @data = 
					({fault=>{ faultCode => 499,     faultString => "Call to $req{uri} failed: Bad Response: $@, \"$text\"" }})
					and last;
			}
			#warn "Have data @data";
			if ($args{cb}) {{
				#local $faultCode = $data[0]{fault}{faultCode} if ref $data[0] eq 'HASH' and exists $data[0]{fault};
				$args{cb}(@data);
				return;
			}}
		},
	);
	$args{cb} and defined wantarray and carp "Useless use of return value for ".__PACKAGE__."->call(cb)";
	return if $args{cb};
	#if ( ref $data[0] eq 'HASH' and exists $data[0]{fault} ) {
	#	$faultCode = $data[0]{fault}{faultCode};
	#	croak( "Remote Error [$data[0]{fault}{faultCode}]: ".$data[0]{fault}{faultString} );
	#}
	return @data == 1 ? $data[0] : @data;
}


=head1 AUTHOR

Mons Anderson, C<< <mons@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Mons Anderson, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of AnyEvent::RPC
