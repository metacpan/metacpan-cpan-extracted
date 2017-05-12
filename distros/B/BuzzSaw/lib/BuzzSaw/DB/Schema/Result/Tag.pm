package BuzzSaw::DB::Schema::Result::Tag;
use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 NAME

BuzzSaw::DB::Schema::Result::Tag - BuzzSaw DBIx::Class resultset

=head1 VERSION

This documentation refers to BuzzSaw::DB::Schema::Result::Tag version 0.12.0

=head1 DESCRIPTION

This module provides access to the DBIx::Class resultset for the
C<tag> table in the BuzzSaw database. When an event is selected at the
filtering stage a set of, zero or more, tags may be specified. This
table records the tags for each event.

The BuzzSaw project provides a suite of tools for processing log file
entries. Entries in files are parsed and filtered into a set of events
of interest which are stored in a database. A report generation
framework is also available which makes it easy to generate regular
reports regarding the events discovered.

=cut

__PACKAGE__->table('tag');

=head1 ACCESSORS

=head2 id

  data_type: integer
  default_value: nextval('tag_id_seq'::regclass)
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: character varying
  default_value: undef
  is_nullable: 0
  size: 20

=head2 event

  data_type: integer
  default_value: undef
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  'id',
  {
    data_type         => 'integer',
    default_value     => \q{nextval('tag_id_seq'::regclass)},
    is_auto_increment => 1,
    is_nullable       => 0,
  },
  'name',
  {
    data_type         => 'character varying',
    default_value     => undef,
    is_nullable       => 0,
    size              => 20,
  },
  'event',
  {
    data_type         => 'integer',
    default_value     => undef,
    is_foreign_key    => 1,
    is_nullable       => 0,
  },
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint( 'name_event', ['name', 'event'] );

=head1 RELATIONS

=head2 event

Type: belongs_to

Related object: L<BuzzSaw::DB::Schema::Result::Event>

=cut

__PACKAGE__->belongs_to(
  'event',
  'BuzzSaw::DB::Schema::Result::Event',
  { id => 'event' },
  {},
);

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
