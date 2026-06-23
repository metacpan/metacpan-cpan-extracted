use strict;
use warnings;

use Test::More;
use Test::Exception;

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_PG_${_}" } qw/DSN USER PASS/};

plan skip_all => 'Set $ENV{DBIO_TEST_PG_DSN}, _USER and _PASS to run this test'
  unless $dsn && $user;

use DBIO::Core;
use DBIO::Schema;

# --- Minimal schema with only the UTF-8 test table ---

{
  package UTF8TestSchema;
  use base 'DBIO::Schema';
}

{
  package UTF8TestSchema::Utf8Test;
  use base 'DBIO::Core';
  __PACKAGE__->table('utf8_test');
  __PACKAGE__->add_columns(
    id      => { data_type => 'integer', is_auto_increment => 1 },
    label   => { data_type => 'text' },
    content => { data_type => 'text', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}

UTF8TestSchema->load_classes({ UTF8TestSchema => ['Utf8Test'] });

my $schema = UTF8TestSchema->connect($dsn, $user, $pass, {
  pg_enable_utf8 => 1,
});

# All operations use the same DBI connection so TEMP TABLE is visible
my $dbh = $schema->storage->dbh;

# Verify we're in UTF-8
my ($encoding) = $dbh->selectrow_array("SHOW client_encoding");
diag "client_encoding: $encoding";

$dbh->do(q{
  CREATE TEMP TABLE utf8_test (
    id      serial  PRIMARY KEY,
    label   text    NOT NULL,
    content text
  )
});

# Sample strings covering BMP, SMP, combining chars, and RTL
my @strings = (
  [ 'ASCII baseline',        'hello world'                         ],
  [ 'Latin extended',        "Sch\x{f6}n ist die Welt"            ],
  [ 'Cyrillic',              "\x{041f}\x{0440}\x{0438}\x{0432}\x{0435}\x{0442}" ],
  [ 'CJK',                   "\x{4e2d}\x{6587}\x{6d4b}\x{8bd5}"   ],
  [ 'Arabic',                "\x{0645}\x{0631}\x{062d}\x{0628}\x{0627}" ],
  [ 'Emoji (SMP U+1F600)',   "\x{1f600}\x{1f389}\x{1f4aa}"        ],
  [ 'Combining diacritics',  "e\x{0301}a\x{0300}"                 ],
  [ 'Mixed script',          "Hello \x{4e16}\x{754c} \x{1f30d}"   ],
  [ 'NUL-safe surroundings', "before\x{2603}after"                ],
  [ 'Long multibyte',        "\x{1f600}" x 100                    ],
);

# INSERT via raw DBI
for my $pair (@strings) {
  my ($label, $str) = @$pair;
  $dbh->do(
    'INSERT INTO utf8_test (label, content) VALUES (?, ?)',
    undef, $label, $str,
  );
}

# --- Part 1: raw DBI SELECT ---

for my $pair (@strings) {
  my ($label, $expected) = @$pair;
  my ($got) = $dbh->selectrow_array(
    'SELECT content FROM utf8_test WHERE label = ?', undef, $label,
  );

  ok defined $got,            "DBI: row returned for: $label";
  ok utf8::is_utf8($got),     "DBI: utf8 flag set: $label";
  is $got, $expected,         "DBI: round-trip value correct: $label";
  is length($got), length($expected),
                              "DBI: character length correct: $label";
}

# --- Part 2: DBIO ResultSet ---

my $rs = $schema->resultset('Utf8Test');

for my $pair (@strings) {
  my ($label, $expected) = @$pair;

  my $row = $rs->search({ label => $label })->first;
  ok $row,                         "DBIO: row returned for: $label";
  ok utf8::is_utf8($row->content), "DBIO: utf8 flag set: $label";
  is $row->content, $expected,     "DBIO: round-trip value correct: $label";
}

# --- Part 3: UPDATE round-trip via DBIO ---

{
  my $new_val = "\x{1f680} updated \x{2665}";
  my $row = $rs->search({ label => 'ASCII baseline' })->first;
  $row->update({ content => $new_val });
  $row->discard_changes;

  ok utf8::is_utf8($row->content), 'DBIO UPDATE: utf8 flag set after reload';
  is $row->content, $new_val,      'DBIO UPDATE: round-trip correct';
}

# --- Part 4: CREATE via DBIO ---

{
  my $new_str = "DBIO \x{2665} PostgreSQL \x{1f418}";
  my $new_row = $rs->create({ label => 'dbio_create', content => $new_str });

  ok utf8::is_utf8($new_row->content), 'DBIO CREATE: utf8 flag set on fresh row';
  is $new_row->content, $new_str,      'DBIO CREATE: content correct';

  $new_row->discard_changes;
  ok utf8::is_utf8($new_row->content), 'DBIO CREATE: utf8 flag after discard_changes';
  is $new_row->content, $new_str,      'DBIO CREATE: content correct after reload';
}

# --- Part 5: LIKE search with unicode pattern ---

{
  my $count = $rs->search({ content => { like => "%\x{1f600}%" } })->count;
  cmp_ok $count, '>=', 1, 'LIKE search with unicode pattern returns results';
}

done_testing;
