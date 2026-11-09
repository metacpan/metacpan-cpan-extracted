use strict;
use warnings;
use Test::More;

# Offline: a column without is_nullable is NOT NULL (ADR 0043, karr k52).
#
# DBIO::Schema::Type::canonical_column (core) turns a missing is_nullable into
# not_null => 1, and that is what a compiled target model says. The install DDL
# used to emit NOT NULL only for an *explicit* false, so a table deployed from
# the same schema held a nullable column and the diff against the compiled
# model never came back empty. The DDL now agrees with the model: only
# is_nullable => 1 is nullable.

use DBIO::Firebird::DDL;
use DBIO::Schema::Type;

{
  package DBIO::Firebird::Test::K52Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_classes({ 'DBIO::Test::Schema' => [qw/Artist CD ComputedColumn/] });
}

my $schema = 'DBIO::Firebird::Test::K52Schema';

# karr k34: the shared CD declares is_deferrable => 1 on its relationships and
# Firebird has no deferrable constraints, so install_ddl refuses that
# (t/69-ddl-constraints.t). This file is not about it: the process-local copy
# of the source has the attribute off.
for my $rel ($schema->source('CD')->relationships) {
  $schema->source('CD')->relationship_info($rel)->{attrs}{is_deferrable} = 0;
}
my $ddl    = DBIO::Firebird::DDL->install_ddl($schema);

# Artist.rank has a default and no is_nullable key; Artist.name is_nullable 1.
my $artist = $schema->source('Artist');
ok(!exists $artist->column_info('rank')->{is_nullable},
  'precondition: Artist.rank declares no is_nullable');
is($artist->column_info('name')->{is_nullable}, 1,
  'precondition: Artist.name declares is_nullable => 1');

like($ddl, qr/^  "rank" INTEGER DEFAULT '13' NOT NULL,?$/m,
  'a column without is_nullable is NOT NULL, DEFAULT still first');
like($ddl, qr/^  "name" VARCHAR\(100\),?$/m,
  'is_nullable => 1 stays nullable');

# is_nullable => 0 and a missing key render the same.
{
  my $info = $artist->column_info('rank');
  local $info->{is_nullable} = 0;
  like(DBIO::Firebird::DDL->install_ddl($schema),
    qr/^  "rank" INTEGER DEFAULT '13' NOT NULL,?$/m,
    'is_nullable => 0 is NOT NULL, as before');
}

# Every column line carries NOT NULL exactly when the column is not
# is_nullable => 1: nothing is nullable by omission.
for my $src_name (qw/Artist CD ComputedColumn/) {
  my $source = $schema->source($src_name);
  my $table  = ref $source->name eq 'SCALAR' ? ${ $source->name } : $source->name;
  my ($body) = $ddl =~ /CREATE TABLE "?\Q$table\E"? \(\n(.*?)\n\);/s;
  ok(defined $body, "CREATE TABLE for $table found") or next;
  my %line = map { /^  "([^"]+)" / ? ($1 => $_) : () } split /\n/, $body;
  for my $col ($source->columns) {
    my $nullable = $source->column_info($col)->{is_nullable} ? 1 : 0;
    my $has_nn   = $line{$col} =~ /NOT NULL/ ? 1 : 0;
    is($has_nn, 1 - $nullable, "$table.$col: NOT NULL iff not is_nullable");

    # the compiled model's claim, per column, is the same one (canonical_column
    # refuses a column that declares no data_type; there is no model for it)
    next unless defined $source->column_info($col)->{data_type};
    my $canon = DBIO::Schema::Type::canonical_column($col, $source->column_info($col));
    is($canon->{not_null} ? 1 : 0, $has_nn,
      "$table.$col: DDL agrees with the compiled model's not_null");
  }
}

done_testing;
