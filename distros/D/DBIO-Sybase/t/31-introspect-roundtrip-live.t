use strict;
use warnings;

use Test::More;
use DBI;
use FindBin;
use lib "$FindBin::Bin/lib";
use AseDatabase;
use AseNoFkActions;
use DBIO::Test;
use DBIO::Test::Schema;
use DBIO::Sybase::Deploy;
use DBIO::Sybase::Introspect;

# Live round-trip for the catalog introspection (karr k48): install a schema,
# then diff the live database against the same schema. Deploy::diff deploys
# the desired schema into a SECOND, fresh database and introspects both, so an
# empty diff means every catalog value reads back identically across two
# deployments of the same DDL -- the server-named PK index and the expression
# defaults included. Before k48 this died at the first introspection query:
# ASE has no INFORMATION_SCHEMA.
#
# Runs in a throwaway database it creates and drops itself; needs a login
# allowed to CREATE DATABASE (sa on the docker/k8s ASE image).

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_SYBASE_${_}" } qw/DSN USER PASS/};
plan skip_all => 'Set $ENV{DBIO_TEST_SYBASE_DSN}, _USER and _PASS to run this test.'
  unless $dsn && $user;

# All of the shared DBIO::Test::Schema result classes (not redefined here)
# that install on ASE today (karr k69, after k52): it was a subset of 17 while
# the temporary database of diff() had the server's default size, which the
# whole schema -- 36 tables, 733 pages -- did not fit into. The temporary
# database is now as large as the schema needs, so the whole of it round-trips.
# Not among them (the same two as %NOT_YET of t/63-uniqueidentifier-live.t):
# ArtistGUID, whose artistid is a uniqueidentifier + is_auto_increment that
# DBIO::Sybase::DDL refuses, and Dummy, whose table is named dummy, an ASE
# keyword.
my %NOT_YET = map { $_ => 1 } qw(ArtistGUID Dummy);
my @CLASSES = grep { !$NOT_YET{$_} }
  sort map { DBIO::Test::Schema->source($_)->result_class =~ s/.*:://r }
  DBIO::Test::Schema->sources;
{
  package DBIO::Sybase::Test::K48Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('Sybase');
  __PACKAGE__->load_classes({ 'DBIO::Test::Schema' => [ @CLASSES ] });
  # These classes declare SET NULL / CASCADE / RESTRICT, which ASE cannot do
  # and the DDL refuses (karr k91); this test is about the round trip.
  AseNoFkActions::strip(__PACKAGE__);
}

my $db = "dbio_k48_rt_$$";
my $db_dsn = $dsn;
$db_dsn =~ s/\bdatabase=[^;]*/database=$db/i
  or $db_dsn .= ($dsn =~ /:$/ ? '' : ';') . "database=$db";

my $admin = DBI->connect($dsn, $user, $pass,
  { RaiseError => 1, PrintError => 0, AutoCommit => 1 });
$admin->do('USE master');
# 64 MB: the whole schema needs 733 pages of 16K (11.5 MB) and the default
# size of the server (24 MB, 686 pages free) does not hold it; a database that
# runs full suspends the session instead of failing.
$admin->do("CREATE DATABASE $db ON default = '64M'");

my $ok = eval {
  my $schema = DBIO::Sybase::Test::K48Schema->connect($db_dsn, $user, $pass);
  my $deploy = DBIO::Sybase::Deploy->new(schema => $schema);
  $deploy->install;

  # An empty diff proves nothing if both models are empty: the installed
  # tables must actually be read back.
  my $live = DBIO::Sybase::Introspect->new(dbh => $schema->storage->dbh)->model;
  # The tables and views the sources stand for: several sources share the
  # table artist, a virtual view exists in no database, CustomSql is a query.
  my %expected;
  for my $name (DBIO::Sybase::Test::K48Schema->sources) {
    my $source = DBIO::Sybase::Test::K48Schema->source($name);
    my $table  = ref $source->name ? ${ $source->name } : $source->name;
    next if $table =~ /\s/ || ( $source->isa('DBIO::ResultSource::View') && $source->is_virtual );
    $expected{$table} = 1;
  }
  note scalar(@CLASSES) . ' classes, ' . scalar(keys %expected) . ' tables and views';
  is_deeply [ sort keys %{ $live->{tables} } ], [ sort keys %expected ],
    'every table and view of the whole installable schema is read back';
  ok scalar(@{ $live->{columns}{artist} // [] }) >= 2, 'artist columns read back';
  # CLAIM RESPELLED (karr k56): this compared the origin of EVERY artist
  # index to ['pk'] -- true only while artist had no other index. Its unique
  # constraints are now installed too; the claim is that the key's index is
  # the one marked pk.
  is_deeply [ map { $_->{columns} } grep { ($_->{origin} // '') eq 'pk' }
      values %{ $live->{indexes}{artist} // {} } ],
    [ ['artistid'] ], 'artist PK index read back as origin pk';

  # install_ddl emits the schema's foreign keys (karr k54) -- cd references
  # artist, track and genre, and track references cd back, so they can only
  # have been added after every CREATE TABLE. Both sides of the diff below now
  # carry them; before k54 neither did, and the empty diff said nothing.
  is_deeply [ sort map { $_->{constraint_name} } @{ $live->{foreign_keys}{cd} // [] } ],
    [qw/fk_cd_artist fk_cd_genreid fk_cd_single_track/],
    'cd FKs installed under their generated names';
  is_deeply [ map { $_->{to_table} } @{ $live->{foreign_keys}{track} // [] } ], ['cd'],
    'track -> cd installed (the reference cycle with cd)';

  # install_ddl emits add_unique_constraint as unique indexes (karr k56);
  # before, only the is_unique column flag reached the database.
  is_deeply [ sort grep { ($live->{indexes}{track}{$_}{origin} // '') ne 'pk' }
      keys %{ $live->{indexes}{track} // {} } ],
    [qw/track_cd_position track_cd_title/],
    'track unique constraints installed as unique indexes';
  ok $live->{indexes}{track}{track_cd_position}{is_unique}, '... unique';

  my $diff = $deploy->diff;
  ok !$diff->has_changes, 'install -> diff against the same schema is empty'
    or diag $diff->as_sql;

  # A numeric default must be usable, not just deployable (karr k55). Artist's
  # rank is `integer, default_value => 13`; rendered DEFAULT '13' (pre-k55) the
  # CREATE TABLE ran and the diff above was empty -- both sides quoted -- but
  # every INSERT leaving rank out failed with Msg 257 "Implicit conversion
  # from datatype 'VARCHAR' to 'INT' is not allowed". The insert, the value it
  # got, and the literal the catalog reads back are what is pinned.
  my $rank_dbh = $schema->storage->dbh;
  ok eval { $rank_dbh->do(q{INSERT INTO artist (name) VALUES ('k55')}); 1 },
    'INSERT leaving the numeric-defaulted column out succeeds'
    or diag $@;
  is scalar $rank_dbh->selectrow_array(q{SELECT rank FROM artist WHERE name = 'k55'}), 13,
    '... and the column gets its default 13';
  my ($rank) = grep { $_->{column_name} eq 'rank' } @{ $live->{columns}{artist} };
  is $rank->{default_value}, '13', 'numeric default reads back as the plain literal 13';
  ok !ref $rank->{default_value}, '... not as an SQL expression';

  # Composite FK and view: the test schema has neither (and install_ddl emits
  # no view for it), so read them from objects created directly.
  my $dbh = $schema->storage->dbh;
  $dbh->do('CREATE TABLE k48_parent (id INT NOT NULL, seq INT NOT NULL, PRIMARY KEY (id, seq))');
  $dbh->do('CREATE TABLE k48_child (id INT NOT NULL PRIMARY KEY, p INT NULL, s INT NULL,'
    . ' CONSTRAINT k48_fk FOREIGN KEY (p, s) REFERENCES k48_parent (id, seq))');
  $dbh->do('CREATE VIEW k48_view AS SELECT id, p FROM k48_child');

  my $intro = DBIO::Sybase::Introspect->new(dbh => $dbh);
  is_deeply $intro->model->{foreign_keys}{k48_child}, [ {
    constraint_name => 'k48_fk',
    from_columns    => [qw/p s/],
    to_table        => 'k48_parent',
    to_columns      => [qw/id seq/],
    on_update       => 'NO ACTION',
    on_delete       => 'NO ACTION',
  } ], 'composite FK read from sysreferences, columns paired in key order';
  is_deeply $intro->table_pk_info('k48_parent'), [qw/id seq/],
    'composite PK read from the PK-constraint index';
  is $intro->table_is_view('k48_view'), 1, 'view listed as a view';
  is $intro->view_definition('k48_view'), 'SELECT id, p FROM k48_child',
    'view definition read from syscomments';
  ok !exists $intro->model->{tables}{sysquerymetrics},
    'the system view sysquerymetrics is not reported';

  $schema->storage->disconnect;
  1;
};
my $err = $@;

# The server may refuse the drop for a moment (Msg 3702, karr k74): repeated
# in t/lib/AseDatabase.pm, and a database that stays is a failure by name.
eval { $admin->do('USE master') };
is AseDatabase::drop($admin, $db), '', "the database of this test, $db, is dropped";

die $err unless $ok;

done_testing;
