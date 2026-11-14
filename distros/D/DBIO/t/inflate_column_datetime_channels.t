use strict;
use warnings;

use Test::More;

BEGIN {
  eval { require DateTime; 1 }
    or plan skip_all => "DateTime not installed: $@";
}

use DateTime;
use DBIO::Test::Storage;

# Every column type has its own channel: parse_<type>/format_<type> of the
# storage's parser when it has them, else parse_datetime/format_datetime
# (parse_date/format_date for a date). A date is read at 12:00:00.

our @CALLS;
sub _log { push @CALLS, join ':', @_ }

{
  package TestDBIO::ICDTC::Parser::Plain;
  sub parse_datetime  { main::_log(parse => 'datetime');  DateTime->new(year => 2026, month => 1, day => 2, hour => 3) }
  sub format_datetime { main::_log(format => 'datetime'); 'F-datetime' }
  sub parse_date      { main::_log(parse => 'date');      DateTime->new(year => 2026, month => 10, day => 25) }
  sub format_date     { main::_log(format => 'date');     'F-date' }

  package TestDBIO::ICDTC::Parser::Typed;
  our @ISA = ('TestDBIO::ICDTC::Parser::Plain');
  sub parse_datetime2  { main::_log(parse => 'datetime2');  DateTime->new(year => 2026, month => 1, day => 2, hour => 3) }
  sub format_datetime2 { main::_log(format => 'datetime2'); 'F-datetime2' }
  sub parse_time_with_time_zone  { main::_log(parse => 'time_with_time_zone');  DateTime->new(year => 2026, month => 1, day => 2, hour => 3) }
  sub format_time_with_time_zone { main::_log(format => 'time_with_time_zone'); 'F-twtz' }

  package TestDBIO::ICDTC::Parser::Half;
  our @ISA = ('TestDBIO::ICDTC::Parser::Plain');
  # parses on the typed channel, has no typed format method
  sub parse_datetime2  { main::_log(parse => 'datetime2'); DateTime->new(year => 2026, month => 1, day => 2) }
}

{
  package TestDBIO::ICDTC::Schema;
  use base 'DBIO::Schema';
}
{
  package TestDBIO::ICDTC::Schema::Result::Thing;
  use base 'DBIO::Core';
  __PACKAGE__->load_components(qw/InflateColumn::DateTime/);
  __PACKAGE__->table('thing');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    dt2  => { data_type => 'datetime2(7)', inflate_datetime => 1, is_nullable => 1 },
    twtz => { data_type => 'time with time zone', inflate_datetime => 1, is_nullable => 1 },
    vdate => { data_type => 'varchar', size => 10, inflate_date => 1, is_nullable => 1 },
    plain_dt2 => { data_type => 'datetime2', is_nullable => 1 },
    d    => { data_type => 'date', is_nullable => 1 },
    d_la => { data_type => 'date', timezone => 'America/Los_Angeles', is_nullable => 1 },
    d_nz => { data_type => 'date', timezone => 'Pacific/Auckland', is_nullable => 1 },
    v_la => { data_type => 'varchar', size => 10, inflate_date => 1, timezone => 'America/Los_Angeles', is_nullable => 1 },
    d_utc => { data_type => 'date', timezone => 'UTC', is_nullable => 1 },
    v_utc => { data_type => 'varchar', size => 10, inflate_date => 1, timezone => 'UTC', is_nullable => 1 },
    dt_utc => { data_type => 'datetime', timezone => 'UTC', is_nullable => 1 },
    v_nz => { data_type => 'varchar', size => 10, inflate_date => 1, timezone => 'Pacific/Auckland', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}
TestDBIO::ICDTC::Schema->register_class(Thing => 'TestDBIO::ICDTC::Schema::Result::Thing');
TestDBIO::ICDTC::Schema->storage_type('+DBIO::Test::Storage');

{
  # a database whose date type carries a time of day, as Oracle's DATE does
  package TestDBIO::ICDTC::Storage::DateWithTime;
  our @ISA = ('DBIO::Test::Storage');
  sub datetime_date_carries_time { 1 }
}

sub fresh {
  my ($parser, $class) = @_;
  my $schema  = TestDBIO::ICDTC::Schema->connect(sub { });
  my $storage = ($class || 'DBIO::Test::Storage')->new($schema);
  $storage->{datetime_parser} = $parser;
  $schema->storage($storage);
  return ($schema, $storage);
}

sub read_row {
  my ($schema, $storage, $col, $value) = @_;
  my @cols = qw/id dt2 twtz vdate plain_dt2 d d_la d_nz v_la d_utc v_utc dt_utc v_nz/;
  my @row = (1, (undef) x $#cols);
  $row[ (grep { $cols[$_] eq $col } 0..$#cols)[0] ] = $value;
  $storage->mock(qr/SELECT.*FROM "thing"/i, [\@row]);
  my $r = $schema->resultset('Thing')->search({ id => 1 })->next;
  return $r->$col;
}

sub written {
  my ($schema, $storage, $col, $dt) = @_;
  @CALLS = ();
  $storage->reset_captured;
  $schema->resultset('Thing')->create({ $col => $dt });
  my ($insert) = grep { $_->{op} eq 'insert' } $storage->captured_queries;
  my ($bind) = grep { $_->[0]{dbic_colname} eq $col } @{ $insert->{bind} };
  return ($bind->[1], [@CALLS]);
}

my $dt = DateTime->new(year => 2026, month => 3, day => 4);

subtest 'types outside the list go to parse_<type>/format_<type>' => sub {
  my ($schema, $storage) = fresh('TestDBIO::ICDTC::Parser::Typed');

  @CALLS = ();
  isa_ok read_row($schema, $storage, dt2 => 'x'), 'DateTime', 'datetime2(7) read';
  is_deeply \@CALLS, ['parse:datetime2'], 'datetime2(7) read on the datetime2 channel';

  @CALLS = ();
  read_row($schema, $storage, twtz => 'x');
  is_deeply \@CALLS, ['parse:time_with_time_zone'], 'time with time zone read on time_with_time_zone';

  my ($bound, $calls) = written($schema, $storage, dt2 => $dt);
  is $bound, 'F-datetime2', 'datetime2(7) written through format_datetime2';
  is_deeply $calls, ['format:datetime2'];

  ($bound, $calls) = written($schema, $storage, twtz => $dt);
  is $bound, 'F-twtz', 'time with time zone written through format_time_with_time_zone';
};

subtest 'a parser without the type method falls back to the datetime channel' => sub {
  my ($schema, $storage) = fresh('TestDBIO::ICDTC::Parser::Plain');

  @CALLS = ();
  read_row($schema, $storage, dt2 => 'x');
  is_deeply \@CALLS, ['parse:datetime'], 'read falls back to parse_datetime';

  my ($bound, $calls) = written($schema, $storage, dt2 => $dt);
  is $bound, 'F-datetime', 'write falls back to format_datetime (a time of day never does, see inflate_column_datetime_time.t)';
  is_deeply $calls, ['format:datetime'];
};

subtest 'each direction decides alone' => sub {
  my ($schema, $storage) = fresh('TestDBIO::ICDTC::Parser::Half');

  @CALLS = ();
  read_row($schema, $storage, dt2 => 'x');
  is_deeply \@CALLS, ['parse:datetime2'], 'read uses the typed channel';

  my ($bound, $calls) = written($schema, $storage, dt2 => $dt);
  is_deeply $calls, ['format:datetime'], 'write falls back, as the parser has no format_datetime2';
};

subtest 'a data_type without an inflate flag does not inflate' => sub {
  my ($schema, $storage) = fresh('TestDBIO::ICDTC::Parser::Typed');
  @CALLS = ();
  is read_row($schema, $storage, plain_dt2 => 'raw'), 'raw', 'untouched';
  is_deeply \@CALLS, [], 'no parser call';
};

subtest 'inflate_date on varchar goes to parse_date/format_date' => sub {
  my ($schema, $storage) = fresh('TestDBIO::ICDTC::Parser::Typed');

  @CALLS = ();
  isa_ok read_row($schema, $storage, vdate => '2026-10-25'), 'DateTime';
  is_deeply \@CALLS, ['parse:date'], 'read through parse_date';

  my ($bound, $calls) = written($schema, $storage, vdate => $dt);
  is $bound, 'F-date', 'written through format_date';
  is_deeply $calls, ['format:date'];
};

subtest 'a date is read at 12:00:00 and keeps its day across timezones' => sub {
  my ($schema, $storage) = fresh('TestDBIO::ICDTC::Parser::Typed');

  for my $col (qw/d vdate/) {
    my $v = read_row($schema, $storage, $col => '2026-10-25');
    is $v->hour, 12, "$col at hour 12";
    is $v->minute + $v->second + $v->nanosecond, 0, "$col at 12:00:00.0";
    is $v->ymd, '2026-10-25', "$col keeps the day";
  }

  for my $col (qw/d_la d_nz v_la v_nz/) {
    my $v = read_row($schema, $storage, $col => '2026-10-25');
    is $v->ymd, '2026-10-25', "$col keeps the day after set_time_zone";
  }
};

{
  package TestDBIO::ICDTC::Parser::Real;
  use base 'DBIO::Storage::DateTimeFormat';
  __PACKAGE__->datetime_parse_pattern('%Y-%m-%d %H:%M:%S');
  __PACKAGE__->datetime_format_pattern('%Y-%m-%d %H:%M:%S');
  __PACKAGE__->date_parse_pattern('%Y-%m-%d');
  __PACKAGE__->date_format_pattern('%Y-%m-%d');
}

subtest 'writing a date writes the calendar day of the value, not a converted one' => sub {
  eval { require DateTime::Format::Strptime; 1 } or plan skip_all => 'no Strptime';
  my ($schema, $storage) = fresh('TestDBIO::ICDTC::Parser::Real');

  my $berlin = DateTime->new(year => 2026, month => 10, day => 25, hour => 0, minute => 30,
    time_zone => 'Europe/Berlin');

  for my $col (qw/d_utc v_utc/) {
    my ($bound) = written($schema, $storage, $col => $berlin);
    is $bound, '2026-10-25', "$col: the day in the value's own zone is written";
    is $berlin->time_zone->name, 'Europe/Berlin', "$col: the caller's DateTime keeps its zone";
    is $berlin->hour, 0, "$col: and its time";
  }

  my ($bound) = written($schema, $storage, dt_utc => $berlin);
  is $bound, '2026-10-24 22:30:00', 'a datetime column still converts to the column timezone';
};

{
  # reads a date as midnight UTC, as some DateTime::Format classes do
  package TestDBIO::ICDTC::Parser::UTC;
  our @ISA = ('TestDBIO::ICDTC::Parser::Plain');
  sub parse_date { main::_log(parse => 'date'); DateTime->new(year => 2026, month => 10, day => 25, time_zone => 'UTC') }
}

subtest 'a date from a parser with a zone is the floating calendar day' => sub {
  my ($schema, $storage) = fresh('TestDBIO::ICDTC::Parser::UTC');

  my $v = read_row($schema, $storage, d => '2026-10-25');
  ok $v->time_zone->is_floating, 'floating';
  is $v->ymd . ' ' . $v->hms, '2026-10-25 12:00:00', 'the day at noon';

  for my $col (qw/d_la d_nz v_la v_nz/) {
    my $v = read_row($schema, $storage, $col => '2026-10-25');
    is $v->ymd . ' ' . $v->hms, '2026-10-25 12:00:00', "$col keeps the day and noon";
  }
};

subtest 'writing a datetime converts a copy, the caller keeps its object' => sub {
  eval { require DateTime::Format::Strptime; 1 } or plan skip_all => 'no Strptime';
  my ($schema, $storage) = fresh('TestDBIO::ICDTC::Parser::Real');

  my $berlin = DateTime->new(year => 2026, month => 10, day => 25, hour => 0, minute => 30,
    time_zone => 'Europe/Berlin');
  my ($bound) = written($schema, $storage, dt_utc => $berlin);
  is $bound, '2026-10-24 22:30:00', 'converted to the column timezone';
  is $berlin->time_zone->name, 'Europe/Berlin', 'the caller\'s DateTime keeps its zone';
  is $berlin->hour, 0, 'and its time';
};

{
  # a date with a time of day, read as Oracle's DATE is
  package TestDBIO::ICDTC::Parser::DateWithTime;
  our @ISA = ('TestDBIO::ICDTC::Parser::Plain');
  sub parse_date { main::_log(parse => 'date'); DateTime->new(year => 2026, month => 10, day => 25, hour => 20, minute => 21, second => 50) }
}

subtest 'a date that carries a time of day keeps it' => sub {
  my ($schema, $storage) = fresh('TestDBIO::ICDTC::Parser::DateWithTime',
    'TestDBIO::ICDTC::Storage::DateWithTime');

  @CALLS = ();
  my $v = read_row($schema, $storage, d => 'x');
  is_deeply \@CALLS, ['parse:date'], 'read through parse_date';
  is $v->ymd . ' ' . $v->hms, '2026-10-25 20:21:50', 'the time of day as read';

  $v = read_row($schema, $storage, d_la => 'x');
  is $v->hms, '20:21:50', 'with a column timezone as well';
  is $v->time_zone->name, 'America/Los_Angeles', 'in the column timezone';
};

subtest 'a date that carries a time of day is written converted' => sub {
  eval { require DateTime::Format::Strptime; 1 } or plan skip_all => 'no Strptime';
  my ($schema, $storage) = fresh('TestDBIO::ICDTC::Parser::Real',
    'TestDBIO::ICDTC::Storage::DateWithTime');

  my $berlin = DateTime->new(year => 2026, month => 10, day => 25, hour => 0, minute => 30,
    time_zone => 'Europe/Berlin');
  my ($bound) = written($schema, $storage, d_utc => $berlin);
  is $bound, '2026-10-24', 'the date of the value converted to the column timezone';
  is $berlin->time_zone->name, 'Europe/Berlin', 'the caller\'s DateTime keeps its zone';
};

subtest 'a datetime keeps its time' => sub {
  my ($schema, $storage) = fresh('TestDBIO::ICDTC::Parser::Typed');
  my $v = read_row($schema, $storage, dt2 => 'x');
  is $v->hour, 3, 'datetime channel is not moved to noon';
};

done_testing;
