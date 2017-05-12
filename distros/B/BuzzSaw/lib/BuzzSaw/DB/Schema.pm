package BuzzSaw::DB::Schema;  # -*-perl-*-
use strict;
use warnings;

# $Id: Schema.pm.in 21338 2012-07-11 11:17:23Z squinney@INF.ED.AC.UK $
# $Source:$
# $Revision: 21338 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/BuzzSaw/BuzzSaw_0_12_0/lib/BuzzSaw/DB/Schema.pm.in $
# $Date: 2012-07-11 12:17:23 +0100 (Wed, 11 Jul 2012) $

our $VERSION = '0.12.0';

use base 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces;

1;
__END__

=head1 NAME

BuzzSaw::DB::Schema - The BuzzSaw database schema class

=head1 VERSION

This documentation refers to BuzzSaw::DB::Schema version 0.12.0

=head1 SYNOPSIS

   use BuzzSaw::DB::Schema;

   my $schema
        = BuzzSaw::DB::Schema->connect( $dsn, $user, $pass, \%opts );

=head1 DESCRIPTION

This module provides access to the DBIx::Class layer which is used to
provide an interface to the BuzzSaw database.

The BuzzSaw project provides a suite of tools for processing log file
entries. Entries in files are parsed and filtered into a set of events
of interest which are stored in a database. A report generation
framework is also available which makes it easy to generate regular
reports regarding the events discovered.

=head1 SUBROUTINES/METHODS

This class has one method:

=over

=item connect( $dsn, $user, $pass, \%options )

This takes the DBI Data Source Name (DSN) and, optionally, a username
and password to be used for connecting to the database. It can also
take a reference to a hash of options which control how the DBI layer
functions. A schema object is returned, see L<DBIx::Class::Schema> for
details of the available methods for this object.

=back

=head1 CONFIGURATION AND ENVIRONMENT

This class is not normally loaded directly, instead the
L<BuzzSaw::DB> module has support for retrieving the database
configuration parameters from a configuration file, see that module
for details.

=head1 DEPENDENCIES

This module requires L<DBIx::Class>, you will also need a DBI driver
module such as L<DBD::Pg>.

=head1 SEE ALSO

L<BuzzSaw>, L<BuzzSaw::DB>

=head1 PLATFORMS

This is the list of platforms on which we have tested this
software. We expect this software to work on any Unix-like platform
which is supported by Perl.

ScientificLinux6

=head1 BUGS AND LIMITATIONS

Please report any bugs or problems (or praise!) to bugs@lcfg.org,
feedback and patches are also always very welcome.

=head1 AUTHOR

    Stephen Quinney <squinney@inf.ed.ac.uk>

=head1 LICENSE AND COPYRIGHT

    Copyright (C) 2012 University of Edinburgh. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the terms of the GPL, version 2 or later.

=cut
