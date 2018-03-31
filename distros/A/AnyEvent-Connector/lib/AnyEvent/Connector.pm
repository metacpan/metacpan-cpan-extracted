package AnyEvent::Connector;
use strict;
use warnings;
use Carp qw(croak);
use AnyEvent::Socket ();
use URI;

use AnyEvent::Connector::Proxy::http;


our $VERSION = "0.02";

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        proxy_obj => undef,
        no_proxy => []
    }, $class;
    $self->_env_proxy_for($args{env_proxy});
    my $proxy = $args{proxy};
    if(defined($proxy)) {
        $self->_set_proxy($proxy);
    }
    my $no_proxy = $args{no_proxy};
    if(defined($no_proxy)) {
        $self->_set_no_proxy($no_proxy);
    }
    return $self;
}

sub _set_proxy {
    my ($self, $proxy) = @_;
    if($proxy eq "") {
        $self->{proxy_obj} = undef;
        return;
    }
    my $proxy_uri = URI->new($proxy);
    my $scheme = $proxy_uri->scheme;
    if(!defined($scheme) || $scheme ne "http") {
        croak "Only http proxy is supported: $proxy";
    }
    $self->{proxy_obj} = AnyEvent::Connector::Proxy::http->new($proxy_uri);
}

sub _set_no_proxy {
    my ($self, $no_proxy) = @_;
    my $ref = ref($no_proxy);
    if($ref eq "ARRAY") {
        ;
    }elsif(!$ref) {
        $no_proxy = [$no_proxy];
    }else {
        croak "no_proxy expects STRING or ARRAYREF, but it was $ref";
    }
    $self->{no_proxy} = [grep {$_ ne ""} @$no_proxy];
}

sub _env_proxy_for {
    my ($self, $protocol) = @_;
    return if !defined($protocol);
    $self->_env_no_proxy();
    my @keys = (lc($protocol) . "_proxy", uc($protocol) . "_PROXY");
    foreach my $key (@keys) {
        my $p = $ENV{$key};
        if(defined($p)) {
            $self->_set_proxy($p);
            return;
        }
    }
}

sub _env_no_proxy {
    my ($self) = @_;
    foreach my $key (qw(no_proxy NO_PROXY)) {
        my $no_proxy = $ENV{$key};
        if(defined($no_proxy)) {
            $self->_set_no_proxy([split /\s*,\s*/, $no_proxy]);
            return;
        }
    }
}

sub _proxy_uri_for {
    my ($self, $host, $port) = @_;
    foreach my $no_domain (@{$self->{no_proxy}}) {
        if($host =~ /\Q$no_domain\E$/) {
            return undef;
        }
    }
    return $self->{proxy_obj};
}

sub proxy_for {
    my ($self, $host, $port) = @_;
    my $p = $self->_proxy_uri_for($host, $port);
    return defined($p) ? $p->uri_string : undef;
}

sub tcp_connect {
    my ($self, $host, $port, $connect_cb, $prepare_cb) = @_;
    my $proxy = $self->_proxy_uri_for($host, $port);
    if(!defined($proxy)) {
        return AnyEvent::Socket::tcp_connect $host, $port, $connect_cb, $prepare_cb;
    }
    return AnyEvent::Socket::tcp_connect $proxy->host, $proxy->port, sub {
        my ($fh, $conn_host, $conn_port, $retry) = @_;
        if(!defined($fh)) {
            $connect_cb->();
            return;
        }
        $proxy->establish_proxy($fh, $host, $port, sub {
            my ($success) = @_;
            $connect_cb->($success ? ($fh, $conn_host, $conn_port, $retry) : ());
        });
    }, $prepare_cb;
}

1;
__END__

=pod

=head1 NAME

AnyEvent::Connector - tcp_connect with transparent proxy handling

=head1 SYNOPSIS

    use AnyEvent::Connector;
    
    ## Specify the proxy setting explicitly.
    my $c = AnyEvent::Connector->new(
        proxy => 'http://proxy.example.com:8080',
        no_proxy => ['localhost', 'your-internal-domain.net']
    );
    
    ## Proxy setting from "http_proxy" and "no_proxy" environment variables.
    my $cenv = AnyEvent::Connector->new(
        env_proxy => "http",
    );
    
    ## Same API as AnyEvent::Socket::tcp_connect
    my $guard = $c->tcp_connect(
        "target.hogehoge.org", 80,
        sub {
            ## connect callback
            my ($fh ,$host, $port, $retry) = @_;
            ...;
        },
        sub {
            ## prepare calback
            my ($fh) = @_;
            ...;
        }
    );

=head1 DESCRIPTION

L<AnyEvent::Connector> object has C<tcp_connect> method compatible
with that from L<AnyEvent::Socket>, and it handles proxy settings
transparently.

=head1 CLASS METHODS

=head2 $conn = AnyEvent::Connector->new(%args)

The constructor.

Fields in C<%args> are:

=over

=item C<proxy> => STR (optional)

String of proxy URL. Currently only C<http> proxy is supported.

If both C<proxy> and C<env_proxy> are not specified, the C<$conn> will directly connect to the destination host.

If both C<proxy> and C<env_proxy> are specified, setting by C<proxy> is used.

Setting empty string to C<proxy> disables the proxy setting done by C<env_proxy> option.

=item C<no_proxy> => STR or ARRAYREF of STR (optional)

String or array-ref of strings of domain names, to which the C<$conn> will directly connect.

If both C<no_proxy> and C<env_proxy> are specified, setting by C<no_proxy> is used.

Setting empty string or empty array-ref to C<no_proxy> disables the no_proxy setting done by C<env_proxy> option.

=item C<env_proxy> => STR (optional)

String of protocol specifier. If specified, proxy settings for that
protocol are loaded from environment variables, and C<$conn> is
created.

For example, if C<"http"> is specified, C<http_proxy> (or
C<HTTP_PROXY>) and C<no_proxy> (or C<NO_PROXY>) environment variables
are used to set C<proxy> and C<no_proxy> options, respectively.

C<proxy> and C<no_proxy> options have precedence over C<env_proxy>
option.

=back

=head1 OBJECT METHOD

=head2 $guard = $conn->tcp_connect($host, $port, $connect_cb, $prepare_cb)

Make a (possibly proxied) TCP connection to the given C<$host> and
C<$port>.

If C<< $conn->proxy_for($host, $port) >> returns C<undef>, the
behavior of this method is exactly the same as C<tcp_connect> function
from L<AnyEvent::Socket>.

If C<< $conn->proxy_for($host, $port) >> returns a proxy URL, it
behaves in the following way.

=over

=item *

It connects to the proxy, and tells the proxy to connect to the final
destination, C<$host> and C<$port>.

=item *

It runs C<$connect_cb> after the connection to the proxy AND
(hopefully) the connection between the proxy and the final destination
are both established.

    $connect_cb->($cb_fh, $cb_host, $cb_port, $cb_retry)

C<$cb_fh> is the filehandle to the proxy. C<$cb_host> and C<$cb_port>
are the hostname and port of the proxy.

=item *

If the TCP connection to the proxy is established but the connection
to the final destination fails for some reason, C<$connect_cb> is
called with no argument passed (just as the original C<tcp_connect>
does).

=item *

If given, it runs C<$prepare_cb> before it starts connecting to the
proxy.

=back

=head2 $proxy = $conn->proxy_for($host, $port)

If C<$conn> uses a proxy to connect to the given C<$host> and
C<$port>, it returns the string of the proxy URL. Otherwise, it
returns C<undef>.


=head1 SEE ALSO

=over

=item *

L<AnyEvent::Socket>

=item *

L<AnyEvent::HTTP> - it has C<tcp_connect> option to implement proxy
connection. You can use L<AnyEvent::Connector> for it.

=back

=head1 REPOSITORY

L<https://github.com/debug-ito/AnyEvent-Connector>

=head1 BUGS AND FEATURE REQUESTS

Please report bugs and feature requests to my Github issues
L<https://github.com/debug-ito/AnyEvent-Connector/issues>.

Although I prefer Github, non-Github users can use CPAN RT
L<https://rt.cpan.org/Public/Dist/Display.html?Name=AnyEvent-Connector>.
Please send email to C<bug-AnyEvent-Connector at rt.cpan.org> to report bugs
if you do not have CPAN RT account.


=head1 AUTHOR
 
Toshio Ito, C<< <toshioito at cpan.org> >>


=head1 LICENSE AND COPYRIGHT

Copyright 2018 Toshio Ito.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


=cut

