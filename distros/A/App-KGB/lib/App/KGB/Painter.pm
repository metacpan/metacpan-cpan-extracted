package App::KGB::Painter;

=head1 NAME

App::KGB::Painter -- add color to KGB notifications

=head1 DESCRIPTION

B<App::KGB::Painter> is a simple class encapsulating coloring of KGB messages.

=cut

use strict;
use warnings;

our $VERSION = 1.27;

use base 'Class::Accessor::Fast';

__PACKAGE__->mk_accessors( qw(item_colors color_codes simulate) );

our %color_codes = (
    bold      => "\002",     # ^B
    normal    => "\017",     # ^O
    underline => "\037",     # ^_
    reverse   => "\026",     # ^V
    black     => "\00301",
    navy      => "\00302",
    green     => "\00303",
    red       => "\00304",
    brown     => "\00305",
    purple    => "\00306",
    orange    => "\00307",
    yellow    => "\00308",
    lime      => "\00309",
    teal      => "\00310",
    aqua      => "\00311",
    blue      => "\00312",
    fuchsia   => "\00313",
    silver    => "\00314",
    white     => "\00316",
    reset     => "\017",
);

our %item_colors = (
    revision  => undef,
    path      => 'teal',
    author    => 'purple',
    branch    => 'brown',
    project   => 'blue',
    module    => 'green',
    web       => 'silver',
    separator => undef,

    addition     => 'green',
    modification => 'teal',
    deletion     => 'bold red',
    replacement  => 'brown',

    prop_change => 'underline',
);

=head1 CONSTRUCTOR

=head2 new

 my $p = App::KGB::Painter->new({ color_codes => { ... }, item_colors => { ... } } );

B<color_codes> is a hash with the special symbols interpreted as coloring
commands by IRC clients.

B<item_colors> is another hash describing what colors to apply to different parts of
the messages.

=cut

sub new {
    my $self = shift->SUPER::new(@_);

    # default colors
    $self->color_codes( \%color_codes ) unless $self->color_codes;
    my $c = $self->color_codes;
    while ( my ($k,$v) = each %color_codes ) {
        $c->{$k} = $v unless exists $c->{$k};
    }

    # default styles
    $self->item_colors( \%item_colors ) unless $self->item_colors;
    my $s = $self->item_colors;
    while ( my ($k,$v) = each %item_colors ) {
        $s->{$k} = $v unless exists $s->{$k};
    }

    return $self;
}

=head1 METHODS

=over

=item B<colorize> I<category> I<text>

Applies the colors of the style I<category> to the given I<text>.

=cut

sub colorize {
    my ( $self, $category, $text ) = @_;

    return $text if $self->simulate;

    my $color = $self->item_colors->{$category};

    unless ($color) {
        warn
            "Not coloring '$text' due to unknown color '$color' for category '$category'"
            if 0;
        return $text;
    }

    my $c = $self->color_codes;

    for ( split( /\s+/, $color ) ) {
        $text = $c->{$_} . $text if $c->{$_};
    }

    $text .= $c->{reset};

    warn "Colored ($category/$color): $text" if 0;
    return $text;
}

our %action_items = (
    A => 'addition',
    M => 'modification',
    D => 'deletion',
    R => 'replacement',
);

=item B<colorize_change> I<change>

Given a change, applies colors to its files depending on the type of the change
-- update, addition, deletion or property change.

=cut

sub colorize_change {
    my $self = shift;
    my $c = shift;

    my $action_item = $action_items{ $c->action };
    unless ($action_item) {
        warn $c->action . " is an unknown action\n";
        return $c->path;
    }

    my $text = $self->colorize( $action_item, $c->path );

    $text = $self->colorize( 'prop_change', $text ) if $c->prop_change;

    return $text;
}

=back

=head1 COPYRIGHT & LICENSE

Copyright (c) 2013, 2018, Damyan Ivanov L<dmn@debian.org>.

This module is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to the Free Software Foundation, Inc., 51
Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

=cut

1;
