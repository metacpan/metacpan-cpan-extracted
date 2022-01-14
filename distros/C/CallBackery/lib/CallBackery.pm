package CallBackery;


=head1 NAME

CallBackery - Appliance Frontend Builder

=head1 SYNOPSIS

 require Mojolicious::Commands;
 Mojolicious::Commands->start_app('CallBackery');

=head1 DESCRIPTION

Configure the mojo engine to run our application logic as webrequests arrive.

=head1 ATTRIBUTES

=cut

use strict;
use warnings;

# load the two modules to have perl check them

use Mojolicious::Plugin::Qooxdoo;
use Mojo::URL;
use Mojo::JSON;
use Mojo::Util qw(hmac_sha1_sum);
use Mojo::File qw(path);
use File::Basename;
use CallBackery::Config;
use CallBackery::Plugin::Doc;
use CallBackery::Database;
use CallBackery::User;


our $VERSION = '0.41.3';

use Mojo::Base 'Mojolicious';

=head2 config

A hash pointer to the configuration object. See L<CallBackery::Config> for details.
The default configuration file is located in etc/callbackery.cfg. You can override the
path by setting the C<CALLBACKERY_CONF> environment variable.

The config property is set automatically on startup.

=cut

has 'config' => sub {
    my $app = shift;
    my $conf = CallBackery::Config->new(
        app => $app,
        file => $ENV{CALLBACKERY_CONF} || $app->home->child('etc','callbackery.cfg')
    );
};

=head2 database

An instance of L<CallBackery::Database> or a module with the same API.

=cut

has 'database' => sub {
    CallBackery::Database->new(app=>shift);
};

has 'userObject' => sub {
    CallBackery::User->new();
};

=head2 securityHeaders

A hash of headers to set on every response to ask the webbrowser to
help us fight the bad guys.

=cut

has securityHeaders => sub { {
    # prevent click jacking
    'X-Frame-Options' => 'SAMEORIGIN',
    # some magic browser based anti xss action
    'X-XSS-Protection' => '1; mode=block',
    # the browser should obej the servers settings regarding content-type
    'X-Content-Type-Options' => 'nosniff',
    # do not store our data ever
    'Pragma' => 'private',
}};

=head2 rpcServiceNamespace

our rpc service namespace

=cut

has rpcServiceNamespace => 'CallBackery';

=head2 rpcServiceController

our rpc service controller

=cut

has rpcServiceController => 'Controller::RpcService';

=head2 docIndex

initial document to be presented on the doc link

=cut

has docIndex => __PACKAGE__ . '::Index';

=head1 METHODS

All  the methods of L<Mojolicious> as well as:

=cut

=head2 startup

Mojolicious calls the startup method at initialization time.

=cut

sub startup {
    my $app = shift;

    $app->config->postProcessCfg();
    my $gcfg = $app->config->cfgHash->{BACKEND};
    if ($gcfg->{log_file}){
        if (open my $file, '>>', $gcfg->{log_file}){
           $app->log->handle($file);
        }
        else {
           $app->log->debug("Opening $gcfg->{log_file}: $!");
        }
    }

    unshift @{$app->static->paths}, 
        $app->home->rel_file('frontend').'/compiled/source/'
        if $app->mode eq 'development';    # Router

    # properly figure your own path when running under fastcgi
    $app->hook( before_dispatch => sub {
        my $c = shift;
        my $reqEnv = $c->req->env;
        my $uri = $reqEnv->{SCRIPT_URI} || $reqEnv->{REQUEST_URI};
        my $path_info = $reqEnv->{PATH_INFO};
        $uri =~ s|/?${path_info}$|/| if $path_info and $uri;
        $c->req->url->base(Mojo::URL->new($uri)) if $uri;
    });

    my $securityHeaders = $app->securityHeaders;
    $app->hook( after_dispatch => sub {
        my $c = shift;
        # not telling anyone that we are mojo
        $c->res->headers->remove('Server');
        for my $header ( keys %$securityHeaders){
            $c->res->headers->header($header,$securityHeaders->{$header});
        }
        $c->res->headers->cache_control('no-cache, no-store, must-revalidate')
            unless $c->req->url->path =~ m{/resource/.+};
    });

    # on initial startup lets get all the 'stuff' into place
    # reconfigure will also create the secretFile.
    if (not -f $app->config->secretFile){
        $app->config->reConfigure;
    }

    $app->secrets([ path($app->config->secretFile)->slurp ]);

    my $routes = $app->routes;

    $app->plugin('CallBackery::Plugin::Doc', {
        root => '/doc',
        index => $app->docIndex,
        template => Mojo::Asset::File->new(
            path=>dirname($INC{'CallBackery/Config.pm'}).'/templates/doc.html.ep',
        )->slurp,
    });

    $routes->any('/upload')->to(namespace => $app->rpcServiceNamespace, controller=>$app->rpcServiceController, action => 'handleUpload');
    $routes->any('/download')->to(namespace => $app->rpcServiceNamespace, controller=>$app->rpcServiceController, action => 'handleDownload');

    # this is a dummy login screen, we use inside an iframe to trick the browser
    # into storing our password for auto-fill. Since there is no standard for triggering the
    # behavior, this is all a bit voodoo, sorry. -- tobi
    $routes->get('/login')->to(cb => sub {
        my $c = shift;
        $c->render(data=><<HTML, format=>'html');
<!DOCTYPE html><html><body><form id="cbLoginForm"  name="cbLoginForm" autocomplete="on" method="POST" >
<input type="text" id="cbUsername"  name="cbUsername" autocomplete="on" />
<input type="password" id="cbPassword"  name="cbPassword" autocomplete="on" />
</form></body></html>
HTML
    });
    # second stage of the deception. the answer page for login must not be the same as the original page
    # otherwise the browser assumes the login failed and does not offer to save the password.
    $routes->post('/login')->to(cb => sub {
        shift->render(text=>'gugus :)');
    });


    $app->plugin('qooxdoo',{
        path => '/QX-JSON-RPC',
        namespace => $app->rpcServiceNamespace,
        controller => $app->rpcServiceController,
    });


    return 0;
}

1;

__END__

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

=head1 COPYRIGHT

Copyright (c) 2013 by OETIKER+PARTNER AG. All rights reserved.

=head1 AUTHOR

S<Tobias Oetiker E<lt>tobi@oetiker.chE<gt>>

=head1 HISTORY

 2013-12-06 to 1.0 first version
 2020-02-19 to 2.0 go REST
 2020-11-20 fz 2.1 call Config::postProcessCfg here

=cut

# Emacs Configuration
#
# Local Variables:
# mode: cperl
# eval: (cperl-set-style "PerlStyle")
# mode: flyspell
# mode: flyspell-prog
# End:
#
# vi: sw=4 et
