package BuzzSaw::DB::Schema::Result::Log; # -*-perl-*-
use strict;
use warnings;

# $Id: Log.pm.in 21338 2012-07-11 11:17:23Z squinney@INF.ED.AC.UK $
# $Source:$
# $Revision: 21338 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/BuzzSaw/BuzzSaw_0_12_0/lib/BuzzSaw/DB/Schema/Result/Log.pm.in $
# $Date: 2012-07-11 12:17:23 +0100 (Wed, 11 Jul 2012) $

our $VERSION = '0.12.0';

use base 'DBIx::Class::Core';

=head1 NAME

BuzzSaw::DB::Schema::Result::Log - BuzzSaw DBIx::Class resultset

=head1 VERSION

This documentation refers to BuzzSaw::DB::Schema::Result::Log version 0.12.0

=head1 DESCRIPTION

This module provides access to the DBIx::Class resultset for the
C<log> table in the BuzzSaw database. This table records the log files
which have been processed along with their SHA digest.  For efficiency
reasons this is used to avoid parsing a file multiple times.

The BuzzSaw project provides a suite of tools for processing log file
entries. Entries in files are parsed and filtered into a set of events
of interest which are stored in a database. A report generation
framework is also available which makes it easy to generate regular
reports regarding the events discovered.

=cut

__PACKAGE__->table('log');

=head1 ACCESSORS

=head2 id

  data_type: integer
  default_value: nextval('log_id_seq'::regclass)
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: character varying
  default_value: undef
  is_nullable: 0
  size: 200

=head2 digest

  data_type: character varying
  default_value: undef
  is_nullable: 0
  size: 200

=cut

__PACKAGE__->add_columns(
  'id',
  {
    data_type         => 'integer',
    default_value     => \q{nextval('log_id_seq'::regclass)},
    is_auto_increment => 1,
    is_nullable       => 0,
  },
  'name',
  {
    data_type         => 'character varying',
    default_value     => undef,
    is_nullable       => 0,
    size              => 200,
  },
  'digest',
  {
    data_type         => 'character varying',
    default_value     => undef,
    is_nullable       => 0,
    size              => 200,
  },
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint( 'name_digest', ['name', 'digest'] );
__PACKAGE__->add_unique_constraint( 'log_digest_key', ['digest'] );

1;
__END__

=head1 DEPENDENCIES

This module requires L<DBIx::Class>.

=head1 SEE ALSO

L<BuzzSaw::DB>, L<BuzzSaw::DB::Schema>

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
