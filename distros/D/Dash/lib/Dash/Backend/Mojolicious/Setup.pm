package Dash::Backend::Mojolicious::Setup;

use Mojo::Base -base;
use Try::Tiny;
use File::ShareDir 1.116;
use Path::Tiny;
use Scalar::Util;

has 'dash_app';

sub register_app {
    my $self     = shift;
    my $renderer = shift;
    my $routes   = shift;
    my $dash_app = shift;
    $dash_app //= sub {
        return $self->dash_app;
    };

    push @{ $renderer->classes }, __PACKAGE__;

    $routes->get(
        '/' => sub {
            my $c = shift;
            $c->stash( perl_dash_mojo_backend_stylesheets          => $dash_app->()->_rendered_stylesheets,
                       perl_dash_mojo_backend_external_stylesheets => $dash_app->()->_rendered_external_stylesheets,
                       perl_dash_mojo_backend_scripts              => $dash_app->()->_rendered_scripts,
                       perl_dash_mojo_backend_title                => $dash_app->()->app_name
            );
            $c->render( template => 'index' );
        }
    );

    my $dist_name = 'Dash';
    $routes->get(
        '/_dash-component-suites/:perl_dash_mojo_backend_namespace/*perl_dash_mojo_backend_asset' => sub {

            # TODO Component registry to find assets file in other dists
            my $c    = shift;
            my $file = $dash_app->()->_filename_from_file_with_fingerprint( $c->stash('perl_dash_mojo_backend_asset') );

            $c->reply->file(
                   File::ShareDir::dist_file( $dist_name,
                                              Path::Tiny::path( 'assets', $c->stash('perl_dash_mojo_backend_namespace'),
                                                                $file )->canonpath
                   )
            );
        }
    );

    $routes->get(
        '/_favicon.ico' => sub {
            my $c = shift;
            $c->reply->file( File::ShareDir::dist_file( $dist_name, 'favicon.ico' ) );
        }
    );

    $routes->get(
        '/_dash-layout' => sub {
            my $c = shift;
            $c->render( json => $dash_app->()->layout() );
        }
    );

    $routes->get(
        '/_dash-dependencies' => sub {
            my $c            = shift;
            my $dependencies = $dash_app->()->_dependencies();
            $c->render( json => $dependencies );
        }
    );

    $routes->post(
        '/_dash-update-component' => sub {
            my $c = shift;

            my $request = $c->req->json;
            try {
                my $content = $dash_app->()->_update_component($request);
                $c->render( json => $content );
            } catch {
                if ( Scalar::Util::blessed $_ && $_->isa('Dash::Exceptions::PreventUpdate') ) {
                    $c->render( status => 204, json => '' );
                } else {
                    die $_;
                }
            };
        }
    );

    return;
}

1;

=pod

=encoding UTF-8

=head1 NAME

Dash::Backend::Mojolicious::Setup

=head1 VERSION

version 0.11

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Pablo Rodríguez González.

This is free software, licensed under:

  The MIT (X11) License

=cut

__DATA__

@@ index.html.ep
% layout 'default';
% title 'Renderer';
<div id="react-entry-point">
    <div class="_dash-loading">
        Loading...
    </div>
</div>

        <footer>
            <%== $perl_dash_mojo_backend_scripts %>
        </footer>


@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="X-UA-Compatible" content="IE=edge">
      <meta charset="UTF-8">
        <title><%= $perl_dash_mojo_backend_title %></title>
        <link rel="icon" type="image/x-icon" href="/_favicon.ico?v=1.7.0">
        <%== $perl_dash_mojo_backend_stylesheets %>
        <%== $perl_dash_mojo_backend_external_stylesheets %>
    </head>
    <body>
        
  <%= content %>
    </body>
</html>


