use strict;
use warnings;

use Test::More;
use DBIO::SQLite::Test;

my $schema = DBIO::SQLite::Test->init_schema( dsn => 'dbi:SQLite::memory:' );

# --- TO_JSON ---
{
  my $cd = $schema->resultset('CD')->first;
  my $json = $cd->TO_JSON;

  is(ref $json, 'HASH', 'TO_JSON returns hashref');
  ok(exists $json->{title}, 'TO_JSON includes title');
  ok(exists $json->{year}, 'TO_JSON includes year');
  ok(exists $json->{cdid}, 'TO_JSON includes cdid');

  # Numeric columns should be numified
  my $year = $json->{year};
  ok(!ref $year, 'year is not a ref');
  # Perl internals: numified value has no string flag
  # Just check it works as a number
  ok($year > 0, 'year is a number');
}

# --- TO_JSON with is_serializable ---
{
  # Artist has name (varchar) and artistid (integer)
  my $artist = $schema->resultset('Artist')->first;
  my $json = $artist->TO_JSON;
  ok(exists $json->{name}, 'TO_JSON includes name');
  ok(exists $json->{artistid}, 'TO_JSON includes artistid');
}

# --- serializable_columns ---
{
  my $cd = $schema->resultset('CD')->first;
  my $cols = $cd->serializable_columns;
  is(ref $cols, 'ARRAY', 'serializable_columns returns arrayref');
  ok(scalar @$cols > 0, 'serializable_columns has columns');
}

# --- self_rs ---
{
  my $cd = $schema->resultset('CD')->first;
  my $rs = $cd->self_rs;
  isa_ok($rs, 'DBIO::ResultSet', 'self_rs returns ResultSet');

  my $found = $rs->single;
  is($found->cdid, $cd->cdid, 'self_rs contains the correct row');
  is($rs->count, 1, 'self_rs contains exactly one row');

  # Can chain RS methods on self_rs
  my $hri = $cd->self_rs->hri->single;
  is(ref $hri, 'HASH', 'self_rs can chain hri');
  is($hri->{title}, $cd->title, 'self_rs->hri returns correct data');
}

# --- TO_JSON with convert_blessed ---
{
  eval { require JSON::MaybeXS };
  SKIP: {
    skip 'JSON::MaybeXS not available', 2 if $@;

    my $cd = $schema->resultset('CD')->first;
    my $json_str = JSON::MaybeXS->new(convert_blessed => 1)->encode($cd);
    ok(defined $json_str, 'convert_blessed works with TO_JSON');
    like($json_str, qr/"title"/, 'JSON output contains title');
  }
}

# --- clean_rs ---
{
  my $cd = $schema->resultset('CD')->first;
  my $clean = $cd->clean_rs;
  isa_ok($clean, 'DBIO::ResultSet', 'clean_rs returns ResultSet');
  ok($clean->count > 1, 'clean_rs returns unfiltered RS');

  # Compare with self_rs (which is filtered)
  is($cd->self_rs->count, 1, 'self_rs has 1 row');
  ok($cd->clean_rs->count > $cd->self_rs->count, 'clean_rs > self_rs');
}

done_testing;
