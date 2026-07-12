use strict;
use warnings;

use Test::More;
use DateTime;

use DBIO::Test::Storage;
use DBIO::Storage::DateTimeFormat;

# Exercises the DBIO::InflateColumn::DateTime SYNOPSIS: a datetime column
# inflates to a real DateTime object on read (SYNOPSIS shows ->month_name)
# and deflates back to a formatted string on write.
#
# DBIO::Test::Storage defaults to DBIO::Test::DateTimeParser, whose
# parse_datetime/format_datetime are the identity function -- fine for SQL
# generation tests, but it means no actual DateTime object would ever be
# produced, so this test would not be able to fail if inflation broke. We
# instead point the fake storage at a real pattern-backed format class
# (the same DBIO::Storage::DateTimeFormat base every driver format class
# uses -- see t/datetime_format.t), which is still entirely offline/mock.

{
  package TestDBIO::ICDT::Format;
  use base 'DBIO::Storage::DateTimeFormat';
  __PACKAGE__->datetime_parse_pattern('%Y-%m-%d %H:%M:%S');
  __PACKAGE__->datetime_format_pattern('%Y-%m-%d %H:%M:%S');
}

{
  package TestDBIO::ICDT::Schema;
  use base 'DBIO::Schema';
}

{
  package TestDBIO::ICDT::Schema::Result::Event;
  use base 'DBIO::Core';

  __PACKAGE__->load_components(qw/InflateColumn::DateTime/);

  __PACKAGE__->table('event');
  __PACKAGE__->add_columns(
    id => { data_type => 'integer', is_auto_increment => 1 },

    # SYNOPSIS: plain datetime data_type inflates automatically
    starts_when => { data_type => 'datetime' },

    # SYNOPSIS: inflate_datetime forces inflation on a non-datetime type
    varchar_when => { data_type => 'varchar', size => 20, inflate_datetime => 1, is_nullable => 1 },

    # SYNOPSIS: inflate_datetime => 0 explicitly opts out despite the data_type
    skip_when => { data_type => 'datetime', inflate_datetime => 0, is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}

TestDBIO::ICDT::Schema->register_class(Event => 'TestDBIO::ICDT::Schema::Result::Event');

my $schema  = TestDBIO::ICDT::Schema->connect(sub { });
my $storage = DBIO::Test::Storage->new($schema);
$storage->datetime_parser_type('TestDBIO::ICDT::Format');
$schema->storage($storage);

subtest 'SYNOPSIS: reading a datetime column inflates to a real DateTime object' => sub {
  $storage->mock(qr/SELECT.*FROM "event"/i, [[ 1, '2026-07-15 10:20:30', undef, undef ]]);

  my $event = $schema->resultset('Event')->search({ id => 1 })->next;
  isa_ok $event->starts_when, 'DateTime', 'starts_when';
  is $event->starts_when->month_name, 'July', 'starts_when->month_name matches the SYNOPSIS usage';
  is $event->starts_when->ymd, '2026-07-15', 'the parsed date is correct';
};

subtest 'writing a DateTime object deflates to a formatted string' => sub {
  $storage->reset_captured;

  my $dt = DateTime->new(year => 2026, month => 3, day => 4, hour => 5, minute => 6, second => 7);
  $schema->resultset('Event')->create({ starts_when => $dt });

  my ($insert) = grep { $_->{op} eq 'insert' } $storage->captured_queries;
  my ($bind) = grep { $_->[0]{dbic_colname} eq 'starts_when' } @{ $insert->{bind} };
  is $bind->[1], '2026-03-04 05:06:07', 'the bound INSERT value is the formatted (deflated) string';
};

subtest 'inflate_datetime => 1 forces inflation on a non-datetime data_type' => sub {
  $storage->mock(qr/SELECT.*FROM "event"/i, [[ 2, undef, '2026-01-02 03:04:05', undef ]]);

  my $event = $schema->resultset('Event')->search({ id => 2 })->next;
  isa_ok $event->varchar_when, 'DateTime', 'varchar_when despite data_type => varchar';
};

subtest 'inflate_datetime => 0 opts out despite a datetime data_type' => sub {
  $storage->mock(qr/SELECT.*FROM "event"/i, [[ 3, undef, undef, '2026-01-02 03:04:05' ]]);

  my $event = $schema->resultset('Event')->search({ id => 3 })->next;
  is $event->skip_when, '2026-01-02 03:04:05', 'skip_when stays a raw string, not inflated';
  ok !ref($event->skip_when), 'skip_when is not a reference/object';
};

done_testing;
