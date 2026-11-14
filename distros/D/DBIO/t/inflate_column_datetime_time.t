use strict;
use warnings;

use Test::More;

BEGIN {
  eval { require DateTime; 1 }
    or plan skip_all => "DateTime not installed: $@";
}

use DateTime;
use DBIO::Test::Storage;

# A time of day stays a string unless asked for. Asked for, it goes through the
# channel of its type, stands on 1970-01-01, is not converted to the column
# timezone, and never falls back to parse_datetime/format_datetime.

our @CALLS;
sub _log { push @CALLS, join ':', @_ }

{
  # no time methods at all
  package TestDBIO::ICDTT::Parser::Plain;
  sub parse_datetime  { main::_log(parse => 'datetime');  DateTime->new(year => 2026, month => 1, day => 2, hour => 3) }
  sub format_datetime { main::_log(format => 'datetime'); 'F-datetime' }

  # parse_time answers with another date than 1970-01-01
  package TestDBIO::ICDTT::Parser::Time;
  our @ISA = ('TestDBIO::ICDTT::Parser::Plain');
  sub parse_time  { main::_log(parse => 'time');  DateTime->new(year => 2026, month => 5, day => 5, hour => 7, minute => 8, second => 9) }
  sub format_time { main::_log(format => 'time'); 'F-time' }

  # offset-carrying methods
  package TestDBIO::ICDTT::Parser::Tz;
  our @ISA = ('TestDBIO::ICDTT::Parser::Time');
  sub parse_timetz  { main::_log(parse => 'timetz');  DateTime->new(year => 2026, month => 5, day => 5, hour => 7, time_zone => '+0300') }
  sub format_timetz { main::_log(format => 'timetz'); 'F-timetz' }

  # own channel for the long type name
  package TestDBIO::ICDTT::Parser::Own;
  our @ISA = ('TestDBIO::ICDTT::Parser::Tz');
  sub parse_time_with_time_zone  { main::_log(parse => 'time_with_time_zone');  DateTime->new(year => 2026, month => 5, day => 5, hour => 1, time_zone => '+0100') }
  sub format_time_with_time_zone { main::_log(format => 'time_with_time_zone'); 'F-twtz' }

  # reads through parse_time only
  package TestDBIO::ICDTT::Parser::ReadOnly;
  our @ISA = ('TestDBIO::ICDTT::Parser::Plain');
  sub parse_time { main::_log(parse => 'time'); DateTime->new(year => 2000, month => 1, day => 1, hour => 4) }

  # parse_time answers in UTC, parse_timetz in a named zone
  package TestDBIO::ICDTT::Parser::Zoned;
  our @ISA = ('TestDBIO::ICDTT::Parser::Plain');
  sub parse_time   { main::_log(parse => 'time');   DateTime->new(year => 2026, month => 7, day => 5, hour => 7, minute => 8, second => 9, time_zone => 'UTC') }
  sub parse_timetz { main::_log(parse => 'timetz'); DateTime->new(year => 2026, month => 7, day => 5, hour => 15, time_zone => 'Europe/Berlin') }

  package TestDBIO::ICDTT::Schema;
  use base 'DBIO::Schema';

  package TestDBIO::ICDTT::Schema::Result::Thing;
  use base 'DBIO::Core';
  __PACKAGE__->load_components(qw/InflateColumn::DateTime/);
  __PACKAGE__->table('thing');
  __PACKAGE__->add_columns(
    id        => { data_type => 'integer', is_auto_increment => 1 },
    t_plain   => { data_type => 'time', is_nullable => 1 },
    t         => { data_type => 'time', inflate_datetime => 1, is_nullable => 1 },
    t_ts      => { data_type => 'time', inflate_timestamp => 1, is_nullable => 1 },
    t_la      => { data_type => 'time', inflate_datetime => 1, timezone => 'America/Los_Angeles', is_nullable => 1 },
    t_wo      => { data_type => 'time without time zone', inflate_datetime => 1, is_nullable => 1 },
    t_p3      => { data_type => 'time(3)', inflate_datetime => 1, is_nullable => 1 },
    t_wz      => { data_type => 'time with time zone', inflate_datetime => 1, is_nullable => 1 },
    t_tz      => { data_type => 'timetz', inflate_datetime => 1, is_nullable => 1 },
    t_wz_la   => { data_type => 'time with time zone', inflate_datetime => 1, timezone => 'America/Los_Angeles', is_nullable => 1 },
    t_loc     => { data_type => 'time', inflate_datetime => 1, locale => 'de_DE', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}
TestDBIO::ICDTT::Schema->register_class(Thing => 'TestDBIO::ICDTT::Schema::Result::Thing');
TestDBIO::ICDTT::Schema->storage_type('+DBIO::Test::Storage');

sub fresh {
  my $parser = shift;
  my $schema  = TestDBIO::ICDTT::Schema->connect(sub { });
  my $storage = DBIO::Test::Storage->new($schema);
  $storage->{datetime_parser} = $parser;
  $schema->storage($storage);
  return ($schema, $storage);
}

sub read_row {
  my ($schema, $storage, $col, $value) = @_;
  my @cols = $schema->source('Thing')->columns;
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

sub stamp { my $d = shift; $d->ymd . 'T' . $d->hms . ($d->nanosecond ? '.' . sprintf('%09d', $d->nanosecond) : '') }

my $time = sub {
  my ($h, $m, $s, $ns, $tz) = @_;
  DateTime->new(year => 2026, month => 3, day => 4, hour => $h, minute => $m, second => $s,
    nanosecond => $ns || 0, time_zone => $tz || 'floating');
};

subtest 'a time without a request stays a string' => sub {
  my ($schema, $storage) = fresh('TestDBIO::ICDTT::Parser::Plain');
  @CALLS = ();
  is read_row($schema, $storage, t_plain => '15:14:15'), '15:14:15', 'untouched';
  is_deeply \@CALLS, [], 'no parser call';
};

subtest 'time with a request: core reads and writes, 1970-01-01, floating' => sub {
  my ($schema, $storage) = fresh('TestDBIO::ICDTT::Parser::Plain');
  for my $col (qw/t t_ts t_wo t_p3/) {
    @CALLS = ();
    my $v = read_row($schema, $storage, $col => '15:14:15.25');
    isa_ok $v, 'DateTime', "$col";
    is stamp($v), '1970-01-01T15:14:15.250000000', "$col read";
    ok $v->time_zone->is_floating, "$col floating";
    is_deeply \@CALLS, [], "$col: no parse_datetime";

    my ($bound, $calls) = written($schema, $storage, $col => $time->(15, 14, 15, 250_000_000));
    is $bound, '15:14:15.25', "$col written";
    is_deeply $calls, [], "$col: no format_datetime";
  }
};

subtest 'the column timezone does not convert a time' => sub {
  my ($schema, $storage) = fresh('TestDBIO::ICDTT::Parser::Plain');
  my $v = read_row($schema, $storage, t_la => '15:14:15.25');
  is stamp($v), '1970-01-01T15:14:15.250000000', 'read stays 15:14:15.25';

  my $berlin = $time->(15, 14, 15, 250_000_000, 'Europe/Berlin');
  my ($bound) = written($schema, $storage, t_la => $berlin);
  is $bound, '15:14:15.25', 'written in the value\'s own zone';
  is $berlin->time_zone->name, 'Europe/Berlin', 'caller object keeps its zone';
  is $berlin->hour, 15, 'caller object keeps its time';
};

subtest 'locale applies' => sub {
  my ($schema, $storage) = fresh('TestDBIO::ICDTT::Parser::Plain');
  my $v = read_row($schema, $storage, t_loc => '15:14:15');
  is $v->locale->code, 'de-DE', 'locale set';
};

subtest 'fraction is written only when not zero, without trailing zeros' => sub {
  my ($schema, $storage) = fresh('TestDBIO::ICDTT::Parser::Plain');
  is +(written($schema, $storage, t => $time->(1, 2, 3, 0)))[0], '01:02:03', 'zero fraction: none';
  is +(written($schema, $storage, t => $time->(1, 2, 3, 120_000_000)))[0], '01:02:03.12', 'trailing zeros cut';
  is +(written($schema, $storage, t => $time->(1, 2, 3, 1)))[0], '01:02:03.000000001', 'nanosecond kept';
  is stamp(read_row($schema, $storage, t => '01:02:03')), '1970-01-01T01:02:03', 'read without fraction';
  is stamp(read_row($schema, $storage, t => '01:02:03.123456789')), '1970-01-01T01:02:03.123456789', 'read nine digits';
};

subtest 'time with time zone: offset from the value' => sub {
  my ($schema, $storage) = fresh('TestDBIO::ICDTT::Parser::Plain');
  for my $col (qw/t_wz t_tz/) {
    my $v = read_row($schema, $storage, $col => '15:14:15+02:00');
    is stamp($v), '1970-01-01T15:14:15', "$col read";
    is $v->offset, 7200, "$col offset +0200";

    $v = read_row($schema, $storage, $col => '15:14:15Z');
    is $v->offset, 0, "$col Z";
    ok !$v->time_zone->is_floating, "$col Z is not floating";

    $v = read_row($schema, $storage, $col => '15:14:15-05');
    is $v->offset, -18000, "$col +-HH";

    $v = read_row($schema, $storage, $col => '15:14:15.5+05:30');
    is $v->offset, 19800, "$col half hour offset";
    is $v->nanosecond, 500_000_000, "$col fraction with offset";

    my ($bound, $calls) = written($schema, $storage, $col => $time->(15, 14, 15, 0, '+0200'));
    is $bound, '15:14:15+02:00', "$col written with the offset";
    is_deeply $calls, [], "$col: no parser call";

    ($bound) = written($schema, $storage, $col => $time->(15, 14, 15, 500_000_000, '-0530'));
    is $bound, '15:14:15.5-05:30', "$col fraction and negative offset";
  }
};

subtest 'time with time zone is not converted to the column timezone' => sub {
  my ($schema, $storage) = fresh('TestDBIO::ICDTT::Parser::Plain');
  my $v = read_row($schema, $storage, t_wz_la => '15:14:15+02:00');
  is $v->offset, 7200, 'offset stays';
  is $v->hour, 15, 'hour stays';
  my ($bound) = written($schema, $storage, t_wz_la => $time->(15, 14, 15, 0, '+0200'));
  is $bound, '15:14:15+02:00', 'written as it is';
};

subtest 'parse_time/format_time is used, the date is 1970-01-01 anyway' => sub {
  my ($schema, $storage) = fresh('TestDBIO::ICDTT::Parser::Time');
  @CALLS = ();
  my $v = read_row($schema, $storage, t => 'x');
  is stamp($v), '1970-01-01T07:08:09', 'date set to the epoch day';
  is_deeply \@CALLS, ['parse:time'];
  my ($bound, $calls) = written($schema, $storage, t => $time->(1, 2, 3));
  is $bound, 'F-time';
  is_deeply $calls, ['format:time'];

  @CALLS = ();
  read_row($schema, $storage, t_wo => 'x');
  is_deeply \@CALLS, ['parse:time'], 'time without time zone follows parse_time';
};

subtest 'a type with a zone does not use parse_time/format_time' => sub {
  my ($schema, $storage) = fresh('TestDBIO::ICDTT::Parser::Time');
  @CALLS = ();
  my $v = read_row($schema, $storage, t_wz => '15:14:15+02:00');
  is $v->offset, 7200, 'core read';
  is_deeply \@CALLS, [], 'parse_time not called';
  my ($bound) = written($schema, $storage, t_wz => $time->(15, 14, 15, 0, '+0200'));
  is $bound, '15:14:15+02:00';
  is_deeply \@CALLS, [], 'format_time not called';
};

subtest 'a type with a zone uses parse_timetz/format_timetz, own channel first' => sub {
  my ($schema, $storage) = fresh('TestDBIO::ICDTT::Parser::Tz');
  @CALLS = ();
  my $v = read_row($schema, $storage, t_wz => 'x');
  is_deeply \@CALLS, ['parse:timetz'];
  is stamp($v), '1970-01-01T07:00:00', 'epoch day';
  is $v->offset, 10800, 'offset from the parser';
  my ($bound, $calls) = written($schema, $storage, t_wz => $time->(1, 2, 3, 0, '+0200'));
  is $bound, 'F-timetz';
  is_deeply $calls, ['format:timetz'];

  ($schema, $storage) = fresh('TestDBIO::ICDTT::Parser::Own');
  @CALLS = ();
  read_row($schema, $storage, t_wz => 'x');
  is_deeply \@CALLS, ['parse:time_with_time_zone'], 'own channel wins';
  ($bound) = written($schema, $storage, t_wz => $time->(1, 2, 3, 0, '+0200'));
  is $bound, 'F-twtz';
};

subtest 'a time keeps what it was read with, whatever zone the parser used' => sub {
  my ($schema, $storage) = fresh('TestDBIO::ICDTT::Parser::Zoned');

  my $v = read_row($schema, $storage, t => 'x');
  ok $v->time_zone->is_floating, 'time without a zone is floating';
  is stamp($v), '1970-01-01T07:08:09', 'and keeps its time';

  $v = read_row($schema, $storage, t_wz => 'x');
  is stamp($v), '1970-01-01T15:00:00', 'time with a zone keeps its time';
  is $v->offset, 7200, 'and the offset it was read with, not the one of 1970-01-01';
};

subtest 'a floating time in a column with a zone is written without an offset' => sub {
  my ($schema, $storage) = fresh('TestDBIO::ICDTT::Parser::Plain');
  for my $col (qw/t_wz t_tz/) {
    my ($bound) = written($schema, $storage, $col => $time->(15, 14, 15));
    is $bound, '15:14:15', "$col: no invented offset";
  }
  is stamp(read_row($schema, $storage, t_wz => '15:14:15')), '1970-01-01T15:14:15', 'read without an offset';
};

subtest 'each direction decides alone' => sub {
  my ($schema, $storage) = fresh('TestDBIO::ICDTT::Parser::ReadOnly');
  @CALLS = ();
  read_row($schema, $storage, t => 'x');
  is_deeply \@CALLS, ['parse:time'];
  my ($bound, $calls) = written($schema, $storage, t => $time->(1, 2, 3));
  is $bound, '01:02:03', 'core writes, format_datetime not used';
  is_deeply $calls, [];
};

subtest 'garbage is an error' => sub {
  my ($schema, $storage) = fresh('TestDBIO::ICDTT::Parser::Plain');
  eval { read_row($schema, $storage, t => 'noon') };
  like $@, qr/Error while inflating column 't'/, 'unreadable time throws';
};

done_testing;
