package DBIx::Table::TestDataGenerator::ResultSetWithRandom;

use strict;
use warnings;

our $VERSION = "0.005";
$VERSION = eval $VERSION;

use Carp;

use DBIx::Class::Helper::ResultSet::Random;

use parent 'DBIx::Class::ResultSet';

__PACKAGE__->load_components('Helper::ResultSet::Random');

1;    # End of DBIx::Table::TestDataGenerator::ResultSetWithRandom

__END__

=pod

=head1 NAME

DBIx::Table::TestDataGenerator::ResultSetWithRandom - Helper class enabling random selections

=head1 DESCRIPTION

We do not know at compile time which ResultSet classes will exist. In order to enable making random selections from ResultSet objects, one can bless them into the current class which provides a rand() method. See the usage in L<DBIx::Table::TestDataGenerator::Randomize>.

=head1 AUTHOR

Jose Diaz Seng, C<< <josediazseng at gmx.de> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012-2013, Jose Diaz Seng.

This module is free software; you can redistribute it and/or modify it under the same terms as Perl 5.10.0. For more details, see the full text of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but without any warranty; without even the implied warranty of merchantability or fitness for a particular purpose. 
