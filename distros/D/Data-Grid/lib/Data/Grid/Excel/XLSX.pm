package Data::Grid::Excel::XLSX;

use 5.012;
use strict;
use warnings FATAL => 'all';

use Moo;

use Spreadsheet::ParseXLSX;

extends 'Data::Grid::Excel';

=head1 NAME

Data::Grid::Excel::XLSX - OOXML standard Excel driver for Data::Grid

=head1 VERSION

Version 0.02_01

=cut

our $VERSION = '0.02_01';

sub _init {
    my ($self, $options) = @_;

    my $driver = Spreadsheet::ParseXLSX->new(%$options);
    $driver->parse($self->fh) or Carp::croak($driver->error);
}


=head1 AUTHOR

Dorian Taylor, C<< <dorian at cpan.org> >>

=head1 SEE ALSO

=over 4

=item

L<Data::Grid>

=item

L<Data::Grid::Excel>

=item

L<Spreadsheet::XLSX>

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

1; # End of Data::Grid::Excel
