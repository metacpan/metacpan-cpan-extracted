package BuzzSaw::DB::Schema::Result::Event; # -*-perl-*-
use strict;
use warnings;

# $Id: Event.pm.in 23014 2013-04-04 16:08:20Z squinney@INF.ED.AC.UK $
# $Source:$
# $Revision: 23014 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/BuzzSaw/BuzzSaw_0_12_0/lib/BuzzSaw/DB/Schema/Result/Event.pm.in $
# $Date: 2013-04-04 17:08:20 +0100 (Thu, 04 Apr 2013) $

our $VERSION = '0.12.0';

use DateTime;
use Try::Tiny;

use base 'DBIx::Class::Core';

=head1 NAME

BuzzSaw::DB::Schema::Result::Event - BuzzSaw DBIx::Class resultset

=head1 VERSION

This documentation refers to BuzzSaw::DB::Schema::Result::Event version 0.12.0

=head1 DESCRIPTION

This module provides access to the DBIx::Class resultset for the
C<event> table in the BuzzSaw database. This table is used to record
the parsed log entries after they have been selected in the filtering
stage. The selected entries are split into useful separate attributes
to make querying and report generation easier.

The BuzzSaw project provides a suite of tools for processing log file
entries. Entries in files are parsed and filtered into a set of events
of interest which are stored in a database. A report generation
framework is also available which makes it easy to generate regular
reports regarding the events discovered.

=cut

__PACKAGE__->load_components(qw/InflateColumn::DateTime Core/);
__PACKAGE__->table('event');

=head1 ACCESSORS

=head2 id

  data_type: integer
  default_value: nextval('event_id_seq'::regclass)
  is_auto_increment: 1
  is_nullable: 0

=head2 raw

  data_type: character varying
  default_value: undef
  is_nullable: 0
  size: 1000

=head2 digest

  data_type: character varying
  default_value: undef
  is_nullable: 0
  size: 200

=head2 logtime

  data_type: timestamp with time zone
  default_value: undef
  is_nullable: 0

=head2 logdate

  data_type: date
  default_value: undef
  is_nullable: 0

=head2 hostname

  data_type: character varying
  default_value: undef
  is_nullable: 0
  size: 100

=head2 message

  data_type: character varying
  default_value: undef
  is_nullable: 0
  size: 1000

=head2 program

  data_type: character varying
  default_value: undef
  is_nullable: 1
  size: 100

=head2 pid

  data_type: integer
  default_value: undef
  is_nullable: 1

=head2 userid

  data_type: character varying
  default_value: undef
  is_nullable: 1
  size: 20

=cut

__PACKAGE__->add_columns(
  'id',
  {
    data_type         => 'integer',
    default_value     => \q{nextval('event_id_seq'::regclass)},
    is_auto_increment => 1,
    is_nullable       => 0,
  },
  'raw',
  {
    data_type         => 'character varying',
    default_value     => undef,
    is_nullable       => 0,
    size              => 1000,
  },
  'digest',
  {
    data_type         => 'character varying',
    default_value     => undef,
    is_nullable       => 0,
    size              => 200,
  },
  'logtime',
  {
    data_type         => 'datetime',
    default_value     => undef,
    is_nullable       => 0,
  },
  'logdate',
  {
    data_type         => 'date',
    default_value     => undef,
    is_nullable       => 0,
  },
  'hostname',
  {
    data_type         => 'character varying',
    default_value     => undef,
    is_nullable       => 0,
    size              => 100,
  },
  'message',
  {
    data_type         => 'character varying',
    default_value     => undef,
    is_nullable       => 0,
    size              => 1000,
  },
  'program',
  {
    data_type         => 'character varying',
    default_value     => undef,
    is_nullable       => 1,
    size              => 100,
  },
  'pid',
  { data_type         => 'integer',
    default_value     => undef,
    is_nullable       => 1 },
  'userid',
  {
    data_type         => 'character varying',
    default_value     => undef,
    is_nullable       => 1,
    size              => 20,
  },
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint( 'event_digest_key', ['digest'] );

=head1 RELATIONS

=head2 tags

Type: has_many

Related object: L<BuzzSaw::DB::Schema::Result::Tag>

=cut

__PACKAGE__->has_many(
  'tags',
  'BuzzSaw::DB::Schema::Result::Tag',
  { 'foreign.event' => 'self.id' },
);

=head2 extra_info

Type: has_many

Related object: L<BuzzSaw::DB::Schema::Result::ExtraInfo>

=cut

__PACKAGE__->has_many(
  'extra_info',
  'BuzzSaw::DB::Schema::Result::ExtraInfo',
  { 'foreign.event' => 'self.id' },
);

sub localtime {
    my ($self) = @_;

    # This might just count as hack of the week!

    use feature 'state';
    require DateTime::TimeZone;
    state $localtz = DateTime::TimeZone->new( name => 'local' );

    # When a specially computed localtime column exists we get the
    # value and inflate to a datetime object. When it does not exist
    # we copy the logtime object and shift to the local timezone. The
    # second option is much slower for large numbers of rows but
    # should always work.

    my $dt = try { 
        my $timestamp = $self->get_column('localtime');
        my $dtf = $self->result_source->storage->datetime_parser();
        $dtf->parse_datetime($timestamp);
    } catch {
        my $clone = $self->logtime->clone();
        $clone->set_time_zone($localtz);
    };

    return $dt;
}

1;
__END__

=head1 DEPENDENCIES

This module requires L<DBIx::Class>, it also needs L<DateTime> and a
C<DateTime::Format> module (e.g. L<DateTime::Format::Pg>) to inflate
the C<logtime> column into something useful.

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
