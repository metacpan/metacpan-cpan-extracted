package Dash::Backend::Mojolicious::App;

use Mojo::Base 'Mojolicious';
use Dash::Backend::Mojolicious::Setup;

has 'dash_app';

sub startup {
    my $self = shift;

    my $setup = Dash::Backend::Mojolicious::Setup->new();
    $setup->register_app(
        $self->renderer,
        $self->routes,
        sub {
            return $self->dash_app;
        }
    );

    return $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dash::Backend::Mojolicious::App

=head1 VERSION

version 0.11

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Pablo Rodríguez González.

This is free software, licensed under:

  The MIT (X11) License

=cut
