# Taco Perl utility module.
# Copyright (C) 2013 Graham Bell
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

=head1 NAME

Alien::Taco::Util - Taco Perl utility module

=head1 DESCRIPTION

This module contains utility subroutines used to implement the
Perl Taco client and server.

=cut

package Alien::Taco::Util;

use strict;

our $VERSION = '0.003';

use Exporter;
use base 'Exporter';
our @EXPORT_OK = qw/filter_struct/;

=head1 SUBROUTINES

=over 4

=item filter_struct($ref, $predicate, $function)

Walk through the given data structure and replace each entry
for which the predicate is true with the result of applying the
function to it.

=cut

sub filter_struct {
    my $x = shift;
    my $pred = shift;
    my $func = shift;

    my $type = ref $x;

    if ($type eq 'HASH') {
        foreach my $k (keys %$x) {
            if ($pred->($x->{$k})) {
                $x->{$k} = $func->($x->{$k});
            }
            elsif (ref $x->{$k}) {
                filter_struct($x->{$k}, $pred, $func);
            }
        }
    }
    elsif ($type eq 'ARRAY') {
        for (my $i = 0; $i < scalar @$x; $i ++) {
            if ($pred->($x->[$i])) {
                $x->[$i] = $func->($x->[$i]);
            }
            elsif (ref $x->[$i]) {
                filter_struct($x->[$i], $pred, $func);
            }
        }
    }
}

1;

__END__

=back

=cut
