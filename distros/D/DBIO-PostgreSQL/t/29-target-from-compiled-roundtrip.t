use strict;
use warnings;
use Test::More;

use DBIO::Schema::ModelCompiler ();
use DBIO::PostgreSQL::Adapter ();
use DBIO::PostgreSQL::Introspect ();
use DBIO::PostgreSQL::Diff ();
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
use PrivatePgDatabase;

unless ($ENV{DBIO_TEST_PG_DSN}) {
  plan skip_all => 'Set DBIO_TEST_PG_DSN, _USER and _PASS to run this test';
}

# A server that is not there fails the file, with a plan (karr k113).
LiveServer->require_server;

# Regression for ticket k9: target_from_compiled used to drop the
# `default_value` field entirely (and mis-render auto_increment), so the
# round-trip diff against the introspected source spuriously flagged every
# default-bearing column for DROP DEFAULT.

{
  package Roundtrip::Result::T;
  use base 'DBIO::Core';
  __PACKAGE__->table('roundtrip_defaults');
  __PACKAGE__->add_columns(
    id         => { data_type => 'integer', is_auto_increment => 1 },
    label      => { data_type => 'text',    default_value => 'draft', is_nullable => 1 },
    created_at => { data_type => 'timestamp', default_value => \'now()', is_nullable => 1 },
    counter    => { data_type => 'integer', default_value => 0, is_nullable => 0 },
    is_active  => { data_type => 'boolean', default_value => \'true', is_nullable => 0 },
  );
  __PACKAGE__->set_primary_key('id');

  package Roundtrip::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
  __PACKAGE__->register_class(T => 'Roundtrip::Result::T');
}

# The end-to-end diff below compares the WHOLE introspected database with the
# compiled target, so it runs in a database of its own: anything else
# installed in the shared one -- pgvector, left there by t/48 and t/54 -- is a
# difference too. Dropping that database at the end also replaces the table
# cleanup this file used to do in the shared one (karr k81).
my $schema = Roundtrip::Schema->connect(PrivatePgDatabase->create('t29'));

# Deploy via DDL so the live (source) DB reflects exactly what DBIO would
# produce. target_from_compiled must then match the introspected result.
my $ddl = eval { require DBIO::PostgreSQL::DDL; DBIO::PostgreSQL::DDL->install_ddl($schema) };
ok $ddl, 'DDL generated for defaults schema' or diag $@;

my $dbh = $schema->storage->dbh;
$dbh->do('DROP TABLE IF EXISTS roundtrip_defaults CASCADE');
for my $stmt (split /;\s*\n/, $ddl) {
  $stmt =~ s/^\s+|\s+$//g;
  next unless $stmt;
  $dbh->do($stmt);
}

my $compiled = DBIO::Schema::ModelCompiler
  ->new(adapter => DBIO::PostgreSQL::Adapter->new)
  ->compile($schema);

my $source = DBIO::PostgreSQL::Introspect->new(dbh => $dbh)->model;
my $target = DBIO::PostgreSQL::Diff->target_from_compiled($compiled);

# Per-column: source and target should agree on default_value for the
# four kinds we care about (text, expression, number, bool).
sub col_by_name {
  my ($cols, $name) = @_;
  return (grep { $_->{column_name} eq $name } @$cols);
}

my $src_cols = $source->{columns}{'public.roundtrip_defaults'};
my $tgt_cols = $target->{columns}{'public.roundtrip_defaults'};

for my $name (qw/label created_at counter is_active/) {
  my ($src) = col_by_name($src_cols, $name);
  my ($tgt) = col_by_name($tgt_cols, $name);
  ok ref $src eq 'HASH' && ref $tgt eq 'HASH', "column $name present in both models"
    or next;
  is $tgt->{default_value}, $src->{default_value}, "default_value for $name round-trips";
  unless ((defined $src->{default_value} && defined $tgt->{default_value} && $src->{default_value} eq $tgt->{default_value}) || (!defined $src->{default_value} && !defined $tgt->{default_value})) {
    require Data::Dumper; local $Data::Dumper::Sortkeys = 1;
    diag "source: ", Data::Dumper::Dumper($src);
    diag "target: ", Data::Dumper::Dumper($tgt);
  }
}

# Non-PK auto_increment: the synthesized target must report identity='d',
# not undef, matching what PG actually stores.
{
  my ($src) = col_by_name($src_cols, 'id');
  ok ref $src eq 'HASH', 'id column present in source';
  is $src->{identity}, 'a', 'PK auto_increment PG reports identity=a';
}

# End-to-end: the diff must be empty for a schema compiled from itself.
my $diff = DBIO::PostgreSQL::Diff->new(source => $source, target => $target);
ok !$diff->has_changes, 'round-trip diff is empty for a default-bearing schema'
  or do {
    diag 'SQL: ' . $diff->as_sql;
    diag 'Summary: ' . $diff->summary;
  };

done_testing;
