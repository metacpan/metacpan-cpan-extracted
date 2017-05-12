package Catalyst::Plugin::RequireSSL;

use strict;
use base qw/Class::Accessor::Fast/;
use MRO::Compat;

our $VERSION = '0.07';

__PACKAGE__->mk_accessors( qw/_require_ssl _allow_ssl _ssl_strip_output/ );

sub require_ssl {
    my $c = shift;

    $c->_require_ssl(1);

    if ( !$c->req->secure && $c->req->method ne "POST" ) {
        my $redir = $c->_redirect_uri('https');
        if ( $c->config->{require_ssl}->{disabled} ) {
            $c->log->warn( "RequireSSL: Would have redirected to $redir" );
        }
        else {
            $c->_ssl_strip_output(1);
            $c->res->redirect( $redir );
            $c->detach if $c->config->{require_ssl}->{detach_on_redirect};
        }
    }
}

sub allow_ssl {
    my $c = shift;

    $c->_allow_ssl(1);
}

sub finalize {
    my $c = shift;
    
    # Do not redirect static files (only works with Static::Simple)
    if ( $c->isa( "Catalyst::Plugin::Static::Simple" ) ) {
        return $c->next::method(@_) if $c->_static_file;
    }
    
    # redirect back to non-SSL mode
    REDIRECT:
    {
        # No redirect if:
        # we're not in SSL mode
        last REDIRECT if !$c->req->secure;
        # it's a POST request
        last REDIRECT if $c->req->method eq "POST";
        # we're already required to be in SSL for this request
        last REDIRECT if $c->_require_ssl;
        # or the user doesn't want us to redirect
        last REDIRECT if $c->config->{require_ssl}->{remain_in_ssl} || $c->_allow_ssl;
        
        $c->res->redirect( $c->_redirect_uri('http') );
    }

    # do not allow any output to be displayed on the insecure page
    if ( $c->_ssl_strip_output ) {
        $c->res->body( '' );
    }

    return $c->next::method(@_);
}

sub setup {
    my $c = shift;

    $c->next::method(@_);

    # disable the plugin when running under certain engines which don't
    # support SSL
    if ( $c->engine =~ /Catalyst::Engine::HTTP/ ) {
        $c->config->{require_ssl}->{disabled} = 1;
        $c->log->warn( "RequireSSL: Disabling SSL redirection while running "
                     . "under " . $c->engine );
    }
}

sub _redirect_uri {
    my ( $c, $type ) = @_;

    if ( !$c->config->{require_ssl}->{$type} ) {
        my $req_uri = $c->req->uri;
        $c->config->{require_ssl}->{$type} =
          join(':', $req_uri->host, $req_uri->_port);
    }

    $c->config->{require_ssl}->{$type} =~ s/\/+$//;

    my $redir = $c->req->uri->clone;
    $redir->scheme($type);
    $redir->host_port($c->config->{require_ssl}->{$type});

    if ( $c->config->{require_ssl}->{no_cache} ) {        
        delete $c->config->{require_ssl}->{$type};
    }
    
    return $redir;
}

1;
__END__

=head1 NAME

Catalyst::Plugin::RequireSSL - Force SSL mode on select pages

=head1 SYNOPSIS

    # in MyApp.pm
    use Catalyst qw/
        RequireSSL
    /;
    __PACKAGE__->config(
        require_ssl => {
            https => 'secure.mydomain.com',
            http => 'www.mydomain.com',
            remain_in_ssl => 0,
            no_cache => 0,
            detach_on_redirect => 1,
        },
    );
    __PACKAGE__->setup;


    # in any controller methods that should be secured
    $c->require_ssl;

=head1 DESCRIPTION

B<Note:> This module is considered to be deprecated for most purposes. Consider
using L<Catalyst::ActionRole::RequireSSL> instead.

Use this plugin if you wish to selectively force SSL mode on some of your web
pages, for example a user login form or shopping cart.

Simply place $c->require_ssl calls in any controller method you wish to be
secured. 

This plugin will automatically disable itself if you are running under the
standalone HTTP::Daemon Catalyst server.  A warning message will be printed to
the log file whenever an SSL redirect would have occurred.

=head1 WARNINGS

If you utilize different servers or hostnames for non-SSL and SSL requests,
and you rely on a session cookie to determine redirection (i.e for a login
page), your cookie must be visible to both servers.  For more information, see
the documentation for the Session plugin you are using.

=head1 CONFIGURATION

Configuration is optional.  You may define the following configuration values:

    https => $ssl_host
    
If your SSL domain name is different from your non-SSL domain, set this value.

    http => $non_ssl_host
    
If you have set the https value above, you must also set the hostname of your
non-SSL server.

    remain_in_ssl
    
If you'd like your users to remain in SSL mode after visiting an SSL-required
page, you can set this option to 1.  By default, this option is disabled and
users will be redirected back to non-SSL mode as soon as possible.

    no_cache 

If you have a wildcard certificate you will need to set this option if you are
using multiple domains on one instance of Catalyst.

    detach_on_redirect 

By default C<< $c->require_ssl >> only calls C<< $c->response->redirect >> but
does not stop request processing (so it returns and subsequent statements are
run). This is probably not what you want. If you set this option to a true
value C<< $c->require_ssl >> will call C<< $c->detach >> when it redirects.

=head1 METHODS

=head2 require_ssl

Call require_ssl in any controller method you wish to be secured.

    $c->require_ssl;

The browser will be redirected to the same path on your SSL server.  POST
requests are never redirected.

=head2 allow_ssl

Call allow_ssl in any controller method you wish to access both in SSL and
non-SSL mode.

    $c->allow_ssl;

The browser will not be redirected, independently of whether the request was
made to the SSL or non-SSL server.

=head2 setup

Disables this plugin if running under an engine which does not support SSL.

=head2 finalize

Performs the redirect to SSL url if required.

=head1 KNOWN ISSUES

When viewing an SSL-required page that uses static files served from the
Static plugin, the static files are redirected to the non-SSL path.

In order to get the correct behaviour where static files are not redirected,
you should use the Static::Simple plugin or always serve static files
directly from your web server.

=head1 SEE ALSO

L<Catalyst>, L<Catalyst::ActionRole::RequireSSL>,
L<Catalyst::Plugin::Static::Simple>

=head1 AUTHOR

Andy Grundman, <andy@hybridized.org>

=head1 CONTRIBUTORS

Simon Elliott <simon@browsing.co.uk> (support for wildcards)

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
