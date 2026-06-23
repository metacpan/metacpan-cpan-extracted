use strict;
use warnings;

use Test::More;
use Test::Exception;
use DBIO::SQLite::Test;

my $schema = DBIO::SQLite::Test->init_schema( dsn => 'dbi:SQLite::memory:' );

# --- source() "did you mean?" suggestions ---
{
  # Exact match still works
  my $src = $schema->source('CD');
  isa_ok($src, 'DBIO::ResultSource', 'source() exact match works');

  # Typo close to Artist (1 char missing)
  throws_ok {
    $schema->source('Artis')
  } qr/Did you mean:.*Artist/, 'source() suggests Artist for "Artis"';

  # Typo close to CD (1 char added)
  throws_ok {
    $schema->source('Cdd')
  } qr/Did you mean:.*CD/, 'source() suggests CD for "Cdd"';

  # Case-insensitive distance calculation
  throws_ok {
    $schema->source('artist')
  } qr/Did you mean:.*Artist/i, 'source() case-insensitive suggestion';

  # Completely wrong name — should show available sources, not suggestions
  throws_ok {
    $schema->source('ZZZZZZ')
  } qr/Available sources:/, 'source() shows available sources for no match';

  # Completely wrong name should NOT show "Did you mean"
  throws_ok {
    $schema->source('ZZZZZZ')
  } qr/Can't find source for ZZZZZZ/,
    'source() error message includes the bad name';

  # No argument
  throws_ok {
    $schema->source()
  } qr/expects a source name/, 'source() with no args throws';

  # Full class name mapping still works
  my $mapped = eval { $schema->source('DBIO::Test::Schema::CD') };
  ok($mapped, 'source() accepts full class name');
}

# --- datetime convenience methods ---
{
  my $parser = $schema->datetime_parser;
  ok($parser, 'datetime_parser returns parser');
  like(ref($parser) || $parser, qr/DateTime::Format/,
    'datetime_parser returns DateTime::Format class');

  # format_datetime
  eval { require DateTime };
  SKIP: {
    skip 'DateTime not available', 2 if $@;
    my $dt = DateTime->now;
    my $formatted = $schema->format_datetime($dt);
    ok(defined $formatted, 'format_datetime returns value');
    like($formatted, qr/\d{4}-\d{2}-\d{2}/, 'format_datetime looks like a date');
  }
}

done_testing;
