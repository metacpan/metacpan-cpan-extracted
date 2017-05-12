package BuzzSaw::DB::Schema::Result::CurrentProcessing; # -*-perl-*-
use strict;
use warnings;

# $Id: CurrentProcessing.pm.in 21338 2012-07-11 11:17:23Z squinney@INF.ED.AC.UK $
# $Source:$
# $Revision: 21338 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/BuzzSaw/BuzzSaw_0_12_0/lib/BuzzSaw/DB/Schema/Result/CurrentProcessing.pm.in $
# $Date: 2012-07-11 12:17:23 +0100 (Wed, 11 Jul 2012) $

our $VERSION = '0.12.0';

use DateTime;

use base 'DBIx::Class::Core';

=head1 NAME

BuzzSaw::DB::Schema::Result::CurrentProcessing - BuzzSaw DBIx::Class resultset

=head1 VERSION

This documentation refers to BuzzSaw::DB::Schema::Result::CurrentProcessing version 0.12.0

=head1 DESCRIPTION

This module provides access to the DBIx::Class resultset for the
C<currentprocessing> table in the BuzzSaw database. This table is used
to record which files are currently being processed so that scripts
running concurrently can avoid processing the same files.

The BuzzSaw project provides a suite of tools for processing log file
entries. Entries in files are parsed and filtered into a set of events
of interest which are stored in a database. A report generation
framework is also available which makes it easy to generate regular
reports regarding the events discovered.

=cut

__PACKAGE__->load_components(qw/InflateColumn::DateTime Core/);
__PACKAGE__->table('current_processing');

=head1 ACCESSORS

=head2 id

  data_type: integer
  default_value: nextval('current_processing_id_seq'::regclass)
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: character varying
  default_value: undef
  is_nullable: 0
  size: 200

=head2 starttime

  data_type: timestamp with time zone
  default_value: current_timestamp
  is_nullable: 0

=cut

=cut

__PACKAGE__->add_columns(
  'id',
  {
    data_type         => 'integer',
    default_value     => \q{nextval('current_processing_id_seq'::regclass)},
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
  'starttime',
  {
    data_type         => 'datetime',
    default_value     => undef,
    is_nullable       => 0,
  },
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint( 'current_processing_name_key', ['name'] );

1;
__END__

=head1 DEPENDENCIES

This module requires L<DBIx::Class>, it also needs L<DateTime> and a
C<DateTime::Format> module (e.g. L<DateTime::Format::Pg>) to inflate
the C<starttime> column into something useful.

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
