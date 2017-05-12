package Dancer::Plugin::Nitesi::Cart::Session;

use strict;
use warnings;

=head1 NAME

Dancer::Plugin::Nitesi::Cart::Session - Session cart backend for Nitesi

=cut

use Dancer qw/session/;

use base 'Nitesi::Cart';

=head1 METHODS

=head2 load

Loads cart from Dancer's session.

=cut

sub load {
    my $self = shift;
    my $carts;

    $carts = session('cart');

    if ($carts) {
	# load cart from session
	$self->seed(session('cart')->{$self->name});
    }
}

=head2 save

Saves cart to Dancer's session.

=cut

sub save {
    my $self = shift;
    my $carts;

    $carts = session('cart');
    $carts->{$self->name} = $self->items();
    session cart => $carts;
}

=head1 AUTHOR

Stefan Hornburg (Racke), <racke@linuxia.de>

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2013 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
