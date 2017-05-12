package Dancer2::Plugin::Debugger::Panel::Routes;

=head1 NAME

Dancer2::Plugin::Debugger::Panel::Routes - add route data to debugger panels

=head1 VERSION

0.008

=cut

our $VERSION = '0.008';

use Moo;
with 'Dancer2::Plugin::Debugger::Role::Panel';
use namespace::clean;

my $env_key = 'dancer2.debugger.routes';

sub BUILD {
    my $self = shift;

    $self->plugin->app->add_hook(
        Dancer2::Core::Hook->new(
            name => 'after_layout_render',
            code => sub {
                if ( $self->plugin->app->request ) {
                    my $routes = $self->plugin->app->routes;
                    my @result;
                    foreach my $method ( sort keys %$routes ) {
                        foreach my $route ( @{ $routes->{$method} } ) {
                            push @result,
                              {
                                $route->method . ' '
                                  . $route->spec_route => {
                                    method => $route->method,
                                    prefix => $route->prefix,
                                    regexp => '' . $route->regexp,
                                    spec   => '' . $route->spec_route,
                                  }
                              };
                        }
                    }

                    $self->plugin->app->request->env->{$env_key} = \@result;
                }
            },
        )
    );
}

1;
