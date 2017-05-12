package Test::CAPREST;
use strict;
use warnings;
use base 'CGI::Application';
use CGI::Application::Plugin::REST qw( :all );

sub setup {
    my ($self) = @_;

    $self->run_modes([ 'default' ]);
    $self->rest_error_mode('error');
    $self->start_mode('default');

    if (defined $self->query->param('bogusdispatch')) {
        $self->rest_route( '/baz/string/*/' );
    }
    elsif (defined $self->query->param('bogusroute')) {
        $self->rest_route(
            '/zing' => [qw/ ptang krrang /],
        );
    }
    elsif (defined $self->query->param('bogusmethod')) {
        $self->rest_route(
            '/zing' => {
                'WTF' => 'ptang',
            },
        );
    }
    elsif (defined $self->query->param('bogussubroute')) {
        $self->rest_route(
            '/zing' => {
                'GET' => ['application/xml', 'arf'],
            },
        );
    }
    elsif (defined $self->query->param('routeprefix')) {
        $self->rest_route(
            '/zing' => {
                'GET' => 'zap',
            },
        );
        $self->rest_route_prefix('/app');
    }
    elsif (defined $self->query->param('defaultroute')) {
        $self->rest_route(
            q{} => {
                'GET' => 'argle',
            },
            '/' => {
                'GET' => 'bargle',
            },
        );
    }
    elsif (!defined $self->query->param('nodispatch')) {
        # Remember to change rest_route_return_value test in t/routes.t
        # when you change number of routes here. (add 1 for default '/'.)
        my $routes = {
            '/foo'                    => 'wibble',
            '/bar/:name/:id?/:email'  => \&wobble,
        };
        $self->rest_route($routes);
        $self->rest_route(
            '/baz/string/*'           => 'woop',
            '/quux'                   => {
                'GET'    => 'ptang',
                'DELETE' => 'krrang',
            },
            '/edna'                   => {
                'POST'   => 'blip',
                '*'      => 'blop',
            },
            '/grudnuk'                => {
                'GET'      => {
                    'application/xml' => 'zip',
                    '*/*'             => 'zap',
                },
                'POST'      => {
                    'application/xml' => 'zoom',
                    '*/*'             => 'zap',
                },
                'PUT'      => {
                    'application/xml' => 'zoom',
                },
            },
            '/arf'       => {
                'GET'                   => 'zap',
            },
            '/wibble/*'    => {
                'GET'                   => 'warble'
            },
        );
    }

    return;
}

sub default {
    my ($self) = @_;

    my $q = $self->query;

    return $q->start_html('default') .
           $q->end_html;
}

sub error {
    my ($self) = @_;

    my $q = $self->query;

    return $q->start_html('error') .
           $q->end_html;
}

sub wibble {
    my ($self) = @_;

    my $q = $self->query;

    return $q->start_html('No parameters') .
           $q->end_html;
}

sub wobble {
    my ($self) = @_;

    my $q = $self->query;

    my $title = join q{ }, ($self->rest_param('email'),
        $self->rest_param('name'), $self->rest_param('id'));
    return $q->start_html($title) .
           $q->end_html;
}

sub woop {
    my ($self) = @_;

    my $q = $self->query;

    my $title = $self->rest_param('dispatch_uri_remainder');
    return $q->start_html($title) .
           $q->end_html;
}

sub ptang {
    my ($self) = @_;

    my $q = $self->query;

    my $title = scalar keys %{ $self->rest_route };
    return $q->start_html($title) .
           $q->end_html;
}

# krrang() intentionally omitted.

sub blip {
    my ($self) = @_;

    my $q = $self->query;

    return $q->start_html('blip') .
           $q->end_html;
}

sub blop {
    my ($self) = @_;

    my $q = $self->query;

    return $q->start_html('blop') .
           $q->end_html;
}

sub zip {
    my ($self) = @_;

    my $q = $self->query;

    return $q->start_html('zip') .
           $q->end_html;
}

sub zap {
    my ($self) = @_;

    my $q = $self->query;

    return $q->start_html('zap') .
           $q->end_html;
}

sub zoom {
    my ($self) = @_;

    my $q = $self->query;

    return $q->start_html('zoom') .
           $q->end_html;
}

sub argle {
   my ($self) = @_;

    my $q = $self->query;

    return $q->start_html('argle') .
           $q->end_html;
}

sub bargle {
   my ($self) = @_;

    my $q = $self->query;

    return $q->start_html('bargle') .
           $q->end_html;
}

sub warble {
   my ($self) = @_;

    my $info = $self->rest_route_info;
    my $title = join ' ', ($info->{path_received}, $info->{rule_matched},
        $info->{runmode}, $info->{method}, $info->{mimetype});
    my $q = $self->query;

    return $q->start_html($title) .
           $q->end_html;
}

1;
