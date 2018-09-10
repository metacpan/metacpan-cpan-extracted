package Data::Grid::Cell;

use 5.012;
use strict;
use warnings FATAL => 'all';

use overload '0+'   => 'value';
use overload '""'   => 'value';
use overload 'bool' => 'value';

use Moo;

extends 'Data::Grid::Container';


=head1 NAME

Data::Grid::Cell - Cell implementation for Data::Grid::Row

=head1 VERSION

Version 0.01_01

=cut

our $VERSION = '0.01_01';


=head1 SYNOPSIS

    for my $cell (@$cells) {
        warn $cell->value;

        # string overload
        printf "%s\n", $cell;
    }

=head1 METHODS

=head2 value

Retrieves a representation of the value of the cell, potentially
formatted by the source, versus a possible alternate L</literal>
value. This method is a I<stub>, and should be defined in a driver
subclass. If the cell is stringified, compared numerically or tested
for truth, this is the method that is called, like so:

     print "$cell\n"; # stringification overloaded

=cut

sub value {
    Carp::croak("Somebody forgot to override this method.");
}

=head2 literal

Spreadsheets tend to have a literal value underlying a formatted value
in a cell, which is why we have this class and are not just using
scalars to represent cells. If your driver has literal values,
override this method, otherwise it is a no-op.

=cut

sub literal {
    $_[0]->value;
}

=head2 quoted

Returns the value with quotes, per L<RFC
4180|https://tools.ietf.org/html/rfc4180>, if it needs to be quoted.

=cut

sub quoted {
    my $val = $_[0]->value;

    # rfc4180
    if ($val =~ /[",\x0a\x0d]/sm) {
        $val =~ s/"/""/g;
        $val = '"' . $val . '"';
    }

    $val;
}


=head2 row

Alias for L<Data::Grid::Container/parent>.

=cut

sub row {
    $_[0]->parent;
}

=head1 AUTHOR

Dorian Taylor, C<< <dorian at cpan.org> >>

=head1 SEE ALSO

=over 4

=item

L<Data::Grid>

=item

L<Data::Grid::Container>

=item

L<Data::Grid::Table>

=item

L<Data::Grid::Row>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2010-2018 Dorian Taylor.

Licensed under the Apache License, Version 2.0 (the "License"); you
may not use this file except in compliance with the License. You may
obtain a copy of the License at
L<http://www.apache.org/licenses/LICENSE-2.0>.

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
implied.  See the License for the specific language governing
permissions and limitations under the License.

=cut

1; # End of Data::Grid::Cell
