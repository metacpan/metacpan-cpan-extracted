use warnings;
use strict;

=for testing
use_ok('Class::DBI::DataMigration');

=cut

package Class::DBI::DataMigration;

=head1 NAME

Class::DBI::DataMigration - Migrate data from one database to another using Class::DBI.

=head1 Version

Version 0.02

=head1 Description

Class::DBI::DataMigration provides a formalized framework for migrating data
from one data storage schema to another.  Using an explicit mapping between
source and target data in YAML format, Class::DBI::DataMigration performs
migration and synchronization bewtween databases.

=cut

our $VERSION = '0.02';

=head1 Caveat

The code on which this framework is based has been used in production by the
author for over a year and works quite stably. However, this remains pre-1.00
software. You have been warned.

=head1 Todo

Write better documentation.

Provide documented examples (for now the tests are a good place to start; hint, hint).

=head1 Author

Dan Friedman, C<< <lamech@cpan.org> >>

=head1 Acknowledgements

Thanks to Kirrily "Skud" Robert and Mike Schwern for early idea bouncing and
encouragement.

Thanks to TransGaming Technologies for supporting the initial development and
release of this project.

=head1 Bugs

Please report any bugs or feature requests to
C<bug-class-dbi-datamigration@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically
be notified of progress on your bug as I make changes.

=head1 Copyright & License

Copyright 2004 Dan Friedman, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

Please note that these modules are not products of or supported by the
employers of the various contributors to the code.

=cut

1;
