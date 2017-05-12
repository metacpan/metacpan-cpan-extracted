package Plack::Middleware::Debug::Dancer::Routes;
BEGIN {
  $Plack::Middleware::Debug::Dancer::Routes::VERSION = '0.03';
}

# ABSTRACT: Show available and matched routes for your application

use strict;
use warnings;
use parent qw(Plack::Middleware::Debug::Base);
use Dancer::Session;

sub run {
    my ( $self, $env, $panel ) = @_;

    return sub {
        my $routes = Dancer::Route::Registry->routes();
        my $hash_routes;

        foreach my $method ( keys %$routes ) {
            map {
                my $name = $_->{method} . ' ' . $_->{route};
                $hash_routes->{$name} = {
                    method  => $_->{method},
                    options => $_->{options},
                    params  => $_->{params},
                    route   => $_->{route}
                };
            } @{ $routes->{$method} };
        }

        $panel->title('Dancer::Route');
        $panel->nav_subtitle(
            "Dancer::Route (" . ( keys %$hash_routes ) . ")" );
        $panel->content(
            sub { $self->render_hash( $hash_routes, [ keys %$hash_routes ] ) }
        );
    };
}

1;


__END__
=pod

=head1 NAME

Plack::Middleware::Debug::Dancer::Routes - Show available and matched routes for your application

=head1 VERSION

version 0.03

=head1 SYNOPSIS

To activate this panel:

    plack_middlewares:
      Debug:
        - panels
        -
          - Dancer::Routes

=head1 AUTHOR

franck cuny <franck@lumberjaph.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by franck cuny.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

