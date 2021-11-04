package Astro::VEX::Param;

=head1 NAME

Astro::VEX::Param - VEX (VLBI Experiment Definition) parameter class

=cut

use strict;
use warnings;

our $VERSION = '0.001';

use parent qw/Astro::VEX::NamedItem/;

use overload '""' => 'stringify';

sub new {
    my $proto = shift; my $class = ref($proto) || $proto;
    my $name = shift;
    my $values = shift;

    return bless {
        NAME => $name,
        VALUES => $values,
    }, $class;
}

sub item {
    my $self = shift;

    my $num_val = scalar @{$self->{'VALUES'}};

    if ($num_val == 0) {
        die 'Parameter has no values';
    }
    elsif ($num_val > 1) {
        die 'Parameter has multiple values';
    }

    return $self->{'VALUES'}->[0];
}

sub value {
    my $self = shift;

    return $self->item->value;
}

sub stringify {
    my $self = shift;

    return (' ' x $self->indent) . $self->{'NAME'} . ' = ' . (join ' : ', @{$self->{'VALUES'}}) . ';';
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
