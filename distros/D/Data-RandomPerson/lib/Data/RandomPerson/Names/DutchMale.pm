package Data::RandomPerson::Names::DutchMale;

use strict;
use warnings;

use base 'Data::RandomPerson::WeightedNames';

1;

=pod

=head1 NAME

Data::RandomPerson::Names::DutchMale - A list of male names

=head1 SYNOPSIS

  use Data::RandomPerson::Names::DutchMale;

  my $n = Data::RandomPerson::Names::DutchMale->new();

  print $n->get();

=head1 DESCRIPTION

=head2 Overview

Returns a random element from a list of Dutch male first names from the
Nederlandse Voornamenbank van het Meertens Instituut KNAW 
L<http://www.meertens.knaw.nl/nvb>

=head2 Constructors and initialization

=over 4

=item new()

Create the Data::RandomPerson::Names::DutchMale object.

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

