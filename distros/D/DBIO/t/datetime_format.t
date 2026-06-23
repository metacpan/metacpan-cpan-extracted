use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBIO::Storage::DateTimeFormat;
use DateTime;

{
  package My::Format::Full;
  use base 'DBIO::Storage::DateTimeFormat';
  __PACKAGE__->datetime_parse_pattern('%Y-%m-%dT%H:%M:%S');
  __PACKAGE__->datetime_format_pattern('%m/%d/%Y %H:%M:%S');
  __PACKAGE__->date_parse_pattern('%Y-%m-%d');
  __PACKAGE__->date_format_pattern('%Y-%m-%d');
}

{
  package My::Format::Other;
  use base 'DBIO::Storage::DateTimeFormat';
  __PACKAGE__->datetime_parse_pattern('%d.%m.%Y %H:%M:%S');
  __PACKAGE__->datetime_format_pattern('%d.%m.%Y %H:%M:%S');
}

{
  package My::Format::Bare;
  use base 'DBIO::Storage::DateTimeFormat';
}

{
  package My::Format::Preferred;
  use base 'DBIO::Storage::DateTimeFormat';
  __PACKAGE__->preferred_format_class('My::Fake::DTFormat');
  __PACKAGE__->datetime_parse_pattern('%Y-%m-%dT%H:%M:%S');
  __PACKAGE__->datetime_format_pattern('%Y-%m-%dT%H:%M:%S');
}

{
  package My::Format::PreferredMissing;
  use base 'DBIO::Storage::DateTimeFormat';
  __PACKAGE__->preferred_format_class('Does::Not::Exist::DTFormat');
  __PACKAGE__->datetime_parse_pattern('%Y-%m-%dT%H:%M:%S');
  __PACKAGE__->datetime_format_pattern('%Y-%m-%dT%H:%M:%S');
}

{
  package My::Fake::DTFormat;
  sub parse_datetime  { 'fake-parsed' }
  sub format_datetime { 'fake-formatted' }
}
BEGIN { $INC{'My/Fake/DTFormat.pm'} = __FILE__ }

# 1. pattern-backed parse/format roundtrip
{
  my $dt = My::Format::Full->parse_datetime('2026-06-12T13:37:42');
  isa_ok $dt, 'DateTime', 'parse_datetime result';
  is $dt->ymd, '2026-06-12', 'parsed date parts';
  is $dt->hms, '13:37:42', 'parsed time parts';
  is(My::Format::Full->format_datetime($dt), '06/12/2026 13:37:42',
    'format_datetime uses its own (asymmetric) pattern');
}

# 2. date patterns work; missing date patterns throw
{
  my $d = My::Format::Full->parse_date('2026-06-12');
  isa_ok $d, 'DateTime', 'parse_date result';
  is(My::Format::Full->format_date($d), '2026-06-12', 'format_date roundtrip');

  throws_ok { My::Format::Other->parse_date('2026-06-12') }
    qr/defines no date_parse_pattern/,
    'parse_date without date_parse_pattern throws';
}

# 3. preferred_format_class delegation
{
  is(My::Format::Preferred->parse_datetime('anything'), 'fake-parsed',
    'parse_datetime delegates to loadable preferred class');
  is(My::Format::Preferred->format_datetime('anything'), 'fake-formatted',
    'format_datetime delegates to loadable preferred class');
  throws_ok { My::Format::Preferred->parse_date('2026-06-12') }
    qr/defines no date_parse_pattern/,
    'parse_date does not delegate when preferred class lacks parse_date';
}

# 4. unloadable preferred class falls back to patterns
{
  my $dt = My::Format::PreferredMissing->parse_datetime('2026-06-12T01:02:03');
  isa_ok $dt, 'DateTime', 'fallback parse result';
  is(My::Format::PreferredMissing->format_datetime($dt), '2026-06-12T01:02:03',
    'fallback format via own pattern');
}

# 5. no cache crosstalk between subclasses
{
  my $dt_full  = My::Format::Full->parse_datetime('2026-06-12T13:37:42');
  my $dt_other = My::Format::Other->parse_datetime('12.06.2026 13:37:42');
  is $dt_full->ymd, $dt_other->ymd, 'both subclasses parse to same date';
  is(My::Format::Other->format_datetime($dt_other), '12.06.2026 13:37:42',
    'Other keeps its own format after Full was used');
  is(My::Format::Full->format_datetime($dt_full), '06/12/2026 13:37:42',
    'Full keeps its own format after Other was used');
}

# 6. no patterns, no preferred class
{
  throws_ok { My::Format::Bare->parse_datetime('2026-06-12T13:37:42') }
    qr/defines no datetime_parse_pattern/,
    'bare subclass throws on parse_datetime';
  throws_ok { My::Format::Bare->format_datetime(DateTime->now) }
    qr/defines no datetime_format_pattern/,
    'bare subclass throws on format_datetime';
}

done_testing;
