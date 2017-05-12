use strict;
use warnings;

use Test::More tests => 4;
use Test::NoWarnings;
use Test::Exception;

use aliased 'DBIx::Table::TestDataGenerator';
use aliased 'DBIx::Table::TestDataGenerator::SelfReference';
use aliased 'DBIx::Table::TestDataGenerator::Query';
use aliased 'DBIx::Table::TestDataGenerator::Tree';

my $table = 'test_TDG';

my $dsn = 'dbi:SQLite:dbname=:memory:';
my $user = my $password = q{};

my $generator = TestDataGenerator->new(
    dsn                   => $dsn,
    user                  => $user,
    password              => $password,
    on_the_fly_schema_sql => 't/db/schema_null_root_parents.sql',
    table                 => $table,
);

my $target_size  = 50;
my $num_random   = $target_size;
my $min_children = 2;
my $min_roots    = 3;
my $max_tree_depth = 5;

$generator->create_testdata(
    target_size               => $target_size,
    num_random                => $num_random,
    max_tree_depth            => $max_tree_depth,
    min_children              => $min_children,
    min_roots                 => $min_roots,
    roots_have_null_parent_id => 1,
    keep_connection_alive     => 1,
);

#test number of records
is( Query->num_records( $generator->schema, $table ),
    $target_size, "there are now $target_size records in the target table" );

#test number of roots
ok( SelfReference->num_roots( $generator->schema, $table, 1 ) >= $min_roots,
    "the number of roots is at least $min_roots" );

#test maximum tree depth
my ( $nodes, $root ) =
  @{ SelfReference->selfref_tree( $generator->schema, $table, 'id', 'refid' ) };
my $tree = Tree->new( nodes => $nodes, root => $root );
ok(
    $tree->depth() <= $max_tree_depth + 1,
    "tree depth at most $max_tree_depth"
);

$generator->disconnect();
