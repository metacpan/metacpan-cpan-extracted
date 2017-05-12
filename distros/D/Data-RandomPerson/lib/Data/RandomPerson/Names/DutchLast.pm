package Data::RandomPerson::Names::DutchLast;

use strict;
use warnings;

use base 'Data::RandomPerson::WeightedNames';

1;

=pod

=head1 NAME

Data::RandomPerson::Names::DutchLast - A list of last names

=head1 SYNOPSIS

  use Data::RandomPerson::Names::DutchLast;

  my $n = Data::RandomPerson::Names::DutchLast->new();

  print $n->get();

=head1 DESCRIPTION

=head2 Overview

Returns Dutch last names from the list curated by Gerrit Bloothoooft
and made available under the 'Creative Commons
"Naamsvermelding-Gelijk delen 3.0 Nederland" license.
I obtained it from L<http://www.naamkunde.net/?page_id=294>

=head2 Constructors and initialization

=over 4

=item new()

Create the Data::RandomPerson::Names::DutchLast object.

=back

=head2 Class and object methods

=over 4

=item get()

Returns a random name from the list.

=item size()

Returns the size of the list

=back

=head1 AUTHOR

Michiel Beijen <michiel.beijen@gmail.com>

=head1 COPYRIGHT

Copyright (c) 2016, Michiel Beijen. This module is
free software. It may be used, redistributed and/or modified under the
same terms as Perl itself.

=cut

