package Astro::VEX::Container;

=head1 NAME

Astro::VEX::Container - VEX (VLBI Experiment Definition) container base class

=cut

use strict;
use warnings;

our $VERSION = '0.001';

use parent qw/Astro::VEX::NamedItem/;

sub new {
    my $proto = shift; my $class = ref($proto) || $proto;
    my $name = shift;
    my $content = shift;

    return bless {
        NAME => $name,
        CONTENT => $content,
    }, $class;
}

sub items {
    my $self = shift;

    return grep {not $_->isa('Astro::VEX::Comment')} @{$self->{'CONTENT'}};
}

sub param {
    my $self = shift;
    my $name = shift;

    for my $item (@{$self->{'CONTENT'}}) {
        if ($item->isa('Astro::VEX::Param')) {
            if ($item->name eq $name) {
                return $item;
            }
        }
    }

    die 'Parameter not found: ' . $name;
}

1;

__END__

=head1 COPYRIGHT

Copyright (C) 2021 East Asian Observatory
All Rights Reserved.

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful,but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to the Free Software Foundation, Inc.,51 Franklin
Street, Fifth Floor, Boston, MA  02110-1301, USA

=cut
