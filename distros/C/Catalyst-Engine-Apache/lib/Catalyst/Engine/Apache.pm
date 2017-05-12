package Catalyst::Engine::Apache;
BEGIN {
  $Catalyst::Engine::Apache::AUTHORITY = 'cpan:BOBTFISH';
}
BEGIN {
  $Catalyst::Engine::Apache::VERSION = '1.16';
}
# ABSTRACT: Catalyst Apache Engines

use strict;
use warnings;
use base 'Catalyst::Engine';

use File::Spec;
use URI;
use URI::http;
use URI::https;

use constant MP2 => (
    exists $ENV{MOD_PERL_API_VERSION} and
           $ENV{MOD_PERL_API_VERSION} >= 2
);

__PACKAGE__->mk_accessors(qw/apache return/);

sub prepare_request {
    my ( $self, $c, $r ) = @_;
    $self->apache( $r );
    $self->return( undef );
}

sub prepare_connection {
    my ( $self, $c ) = @_;

    $c->request->address( $self->apache->connection->remote_ip );

    PROXY_CHECK:
    {
        my $headers = $self->apache->headers_in;
        unless ( $c->config->{using_frontend_proxy} ) {
            last PROXY_CHECK if $c->request->address ne '127.0.0.1';
            last PROXY_CHECK if $c->config->{ignore_frontend_proxy};
        }
        last PROXY_CHECK unless $headers->{'X-Forwarded-For'};

        # If we are running as a backend server, the user will always appear
        # as 127.0.0.1. Select the most recent upstream IP (last in the list)
        my ($ip) = $headers->{'X-Forwarded-For'} =~ /([^,\s]+)$/;
        $c->request->address( $ip );
    }

    $c->request->hostname( $self->apache->connection->remote_host );
    $c->request->protocol( $self->apache->protocol );
    $c->request->user( $self->apache->user );
    $c->request->remote_user( $self->apache->user );

    # when config options are set, check them here first
    if ($INC{'Apache2/ModSSL.pm'}) {
        $c->request->secure(1) if $self->apache->connection->is_https;
    } else {
        my $https = $self->apache->subprocess_env('HTTPS');
        $c->request->secure(1) if defined $https and uc $https eq 'ON';
    }

}

sub prepare_query_parameters {
    my ( $self, $c ) = @_;

    if ( my $query_string = $self->apache->args ) {
        $self->SUPER::prepare_query_parameters( $c, $query_string );
    }
}

sub prepare_headers {
    my ( $self, $c ) = @_;

    $c->request->method( $self->apache->method );

    if ( my %headers = %{ $self->apache->headers_in } ) {
        $c->request->header( %headers );
    }
}

sub prepare_path {
    my ( $self, $c ) = @_;

    my $scheme = $c->request->secure ? 'https' : 'http';
    my $host   = $self->apache->hostname || 'localhost';
    my $port   = $self->apache->get_server_port;

    # If we are running as a backend proxy, get the true hostname
    PROXY_CHECK:
    {
        unless ( $c->config->{using_frontend_proxy} ) {
            last PROXY_CHECK if $host !~ /localhost|127.0.0.1/;
            last PROXY_CHECK if $c->config->{ignore_frontend_proxy};
        }
        last PROXY_CHECK unless $c->request->header( 'X-Forwarded-Host' );

        $host = $c->request->header( 'X-Forwarded-Host' );

        if ( $host =~ /^(.+):(\d+)$/ ) {
            $host = $1;
            $port = $2;
        } else {
            # backend could be on any port, so
            # assume frontend is on the default port
            $port = $c->request->secure ? 443 : 80;
        }
    }

    my $base_path = '';

    # Are we running in a non-root Location block?
    my $location = $self->apache->location;
    if ( $location && $location ne '/' ) {
        $base_path = $location;
    }

    # Using URI directly is way too slow, so we construct the URLs manually
    my $uri_class = "URI::$scheme";

    if ( $port !~ /^(?:80|443)$/ && $host !~ /:/ ) {
        $host .= ":$port";
    }

    # We want the path before Apache escapes it.  Under mod_perl2 this is available
    # with the unparsed_uri method.  Under mod_perl 1 we must parse it out of the
    # request line.
    my ($path, $qs);

    if ( MP2 ) {
        ($path, $qs) = split /\?/, $self->apache->unparsed_uri, 2;
    }
    else {
        my (undef, $path_query) = split / /, $self->apache->the_request, 3;
        ($path, $qs)            = split /\?/, $path_query, 2;
    }

    # Don't check for LocationMatch blocks if requested
    # http://rt.cpan.org/Ticket/Display.html?id=26921
    if ( $self->apache->dir_config('CatalystDisableLocationMatch') ) {
        $base_path = '';
    }

    # Check if $base_path appears to be a regex (contains invalid characters),
    # meaning we're in a LocationMatch block
    elsif ( $base_path =~ m/[^$URI::uric]/o ) {
        # Find out what part of the URI path matches the LocationMatch regex,
        # that will become our base
        my $match = qr/($base_path)/;
        my ($base_match) = $path =~ $match;

        $base_path = $base_match || '';
    }

    # Strip leading slash
    $path =~ s{^/+}{};

    # base must end in a slash
    $base_path .= '/' unless $base_path =~ m{/$};

    # Are we an Apache::Registry script? Why anyone would ever want to run
    # this way is beyond me, but we'll support it!
    # XXX: This needs a test
    if ( defined $ENV{SCRIPT_NAME} && $self->apache->filename && -f $self->apache->filename && -x _ ) {
        $base_path .= $ENV{SCRIPT_NAME};
    }

    # If the path is contained within the base, we need to make the path
    # match base.  This handles the case where the app is running at /deep/path
    # but a request to /deep/path fails where /deep/path/ does not.
    if ( $base_path ne '/' && $base_path ne $path && $base_path =~ m{/$path} ) {
        $path = $base_path;
        $path =~ s{^/+}{};
    }

    my $query = $qs ? '?' . $qs : '';
    my $uri   = $scheme . '://' . $host . '/' . $path . $query;

    $c->request->uri( bless \$uri, $uri_class );

    my $base_uri = $scheme . '://' . $host . $base_path;

    $c->request->base( bless \$base_uri, $uri_class );
}

sub read_chunk {
    my $self = shift;
    my $c = shift;

    $self->apache->read( @_ );
}

sub finalize_body {
    my ( $self, $c ) = @_;

    $self->SUPER::finalize_body($c);

    # Data sent using $self->apache->print is buffered, so we need
    # to flush it after we are done writing.
    $self->apache->rflush;
}

sub finalize_headers {
    my ( $self, $c ) = @_;

    for my $name ( $c->response->headers->header_field_names ) {
        next if $name =~ /^Content-(Length|Type)$/i;
        my @values = $c->response->header($name);
        # allow X headers to persist on error
        if ( $name =~ /^X-/i ) {
            $self->apache->err_headers_out->add( $name => $_ ) for @values;
        }
        else {
            $self->apache->headers_out->add( $name => $_ ) for @values;
        }
    }

    # persist cookies on error responses
    if ( $c->response->header('Set-Cookie') && $c->response->status >= 400 ) {
        for my $cookie ( $c->response->header('Set-Cookie') ) {
            $self->apache->err_headers_out->add( 'Set-Cookie' => $cookie );
        }
    }

    # The trick with Apache is to set the status code in $apache->status but
    # always return the OK constant back to Apache from the handler.
    $self->apache->status( $c->response->status );
    $c->response->status( $self->return || $self->ok_constant );

    my $type = $c->response->header('Content-Type') || 'text/html';
    $self->apache->content_type( $type );

    if ( my $length = $c->response->content_length ) {
        $self->apache->set_content_length( $length );
    }

    return 0;
}

sub write {
    my ( $self, $c, $buffer ) = @_;

    if ( ! $self->apache->connection->aborted && defined $buffer) {
        return $self->apache->print( $buffer );
    }
    return;
}

1;


__END__
=pod

=encoding utf-8

=head1 NAME

Catalyst::Engine::Apache - Catalyst Apache Engines

=head1 SYNOPSIS

For example Apache configurations, see the documentation for the engine that
corresponds to your Apache version.

C<Catalyst::Engine::Apache::MP13>  - mod_perl 1.3x

C<Catalyst::Engine::Apache2::MP19> - mod_perl 1.99x

C<Catalyst::Engine::Apache2::MP20> - mod_perl 2.x

=head1 DESCRIPTION

These classes provide mod_perl support for Catalyst.

=head1 METHODS

=head2 $c->engine->apache

Returns an C<Apache>, C<Apache::RequestRec> or C<Apache2::RequestRec> object,
depending on your mod_perl version.  This method is also available as
$c->apache.

=head2 $c->engine->return

If you need to return something other than OK from the mod_perl handler,
you may set any other Apache constant in this method.  You should only use
this method if you know what you are doing or bad things may happen!
For example, to return DECLINED in mod_perl 2:

    use Apache2::Const -compile => qw(DECLINED);
    $c->engine->return( Apache2::Const::DECLINED );

=head2 NOTES ABOUT LOCATIONMATCH

The Apache engine tries to figure out the correct base path if your app is
running within a LocationMatch block.  For example:

    <LocationMatch ^/match/(this|that)*>
        SetHandler          modperl
        PerlResponseHandler MyApp
    </LocationMatch>

This will correctly set the base path to '/match/this/' or '/match/that/' depending
on which path was used for the request.

In some cases this may not be what you want, so you can disable this behavior
by adding this to your configuration:

    PerlSetVar CatalystDisableLocationMatch 1

=head2 NOTES ON NON-STANDARD PORTS

If you wish to run your site on a non-standard port you will need to use the
C<Port> Apache config rather than C<Listen>. This will result in the correct
port being added to urls created using C<uri_for>.

    Port 8080

=head1 OVERLOADED METHODS

This class overloads some methods from C<Catalyst::Engine>.

=over 4

=item prepare_request($r)

=item prepare_connection

=item prepare_query_parameters

=item prepare_headers

=item prepare_path

=item read_chunk

=item finalize_body

=item finalize_headers

=item write

=back

=head1 SEE ALSO

L<Catalyst> L<Catalyst::Engine>.

=head1 AUTHORS

=over 4

=item *

Sebastian Riedel <sri@cpan.org>

=item *

Christian Hansen <ch@ngmedia.com>

=item *

Andy Grundman <andy@hybridized.org>

=item *

Tomas Doran <bobtfish@bobtfish.net>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by The "AUTHORS".

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

