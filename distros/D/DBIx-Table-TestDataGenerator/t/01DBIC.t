use strict;
use warnings;

use Test::More tests => 10;
use Test::NoWarnings;
use Test::Exception;

use aliased 'DBIx::Table::TestDataGenerator';
use aliased 'DBIx::Table::TestDataGenerator::DBIxSchemaDumper';
use aliased 'DBIx::Table::TestDataGenerator::Randomize';
use aliased 'DBIx::Table::TestDataGenerator::ForeignKey';
use aliased 'DBIx::Table::TestDataGenerator::UniqueConstraint';
use aliased 'DBIx::Table::TestDataGenerator::SelfReference';
use aliased 'DBIx::Table::TestDataGenerator::DBIxHelper';
use aliased 'DBIx::Table::TestDataGenerator::Query';

my $table = 'test_TDG';

my $dsn = 'dbi:SQLite:dbname=:memory:';
my $user = my $password = q{};

my $dumper = DBIxSchemaDumper->new(
    dsn                   => $dsn,
    user                  => q{},
    password              => q{},
    table                 => $table,
    on_the_fly_schema_sql => 't/db/schema.sql',
);

my ( $dbh, $schema ) = @{ $dumper->dump_schema() };

#test unique_columns_with_max
my $uniq_info = UniqueConstraint->new(
    schema => $schema,
    table  => $table,
);

my %unique_constraints =
  %{ $uniq_info->unique_columns_with_max( $schema, $table, 0 ) };

#test num_records
my $initial_num_records = Query->num_records( $schema, $table );
is( $initial_num_records, 5, 'check initial number of records' );

#test column_names
my @column_names_sorted =
  sort( @{ DBIxHelper->column_names( $schema, $table ) } );
is_deeply(
    \@column_names_sorted,
    [ 'dt', 'id', 'j', 'refid', 'ud' ],
    'correct column names'
);

#test random_record
my %ids;
my $num_samples = 2**31 - 2;
my $cols = [ 'dt', 'id', 'j', 'refid', 'ud' ];
for ( 1 .. $num_samples ) {
    my %r = %{ Randomize->random_record( $schema, $table, $cols ) };
    $ids{ $r{id} }++;
    last if keys %ids == $initial_num_records;
}

#by choice of $num_samples, the probability of one of those pkeys
#missing is $num_samples / $max_signed_int
is( keys %ids, $initial_num_records, 'all pkeys found in random samples' );

#test num_roots
is( SelfReference->num_roots( $schema, $table ), 2,
    'checking number of roots' );

my $foreign_key_handler = ForeignKey->new(
    schema                 => $schema,
    table                  => $table,
    handle_self_ref_wanted => 1,
    pkey_col               => 'id',
    pkey_col_names         => ['id'],
);

#test _fkey_name_to_source
my $fkey_to_src = $foreign_key_handler->_fkey_name_to_source($table);
is_deeply(
    $fkey_to_src,
    {
        'j'     => 'TestTdgRef',
        'refid' => 'TestTdg'
    },
    'foreign keys correctly determined'
);

#test fkey_referenced_cols_to_referencing_cols
my $refd_to_refng =
  $foreign_key_handler->_fkey_referenced_cols_to_referencing_cols($table);
is_deeply(
    $refd_to_refng,
    {
        'refid' => { 'id' => 'refid' },
        'j'     => { 'i'  => 'j' }
    },
    'referenced to referencing foreign key constrained columns determined'
);

#test fkey_referenced_cols
my $fkey_refd_cols = $foreign_key_handler->_fkey_referenced_cols($table);
is_deeply(
    $fkey_refd_cols,
    {
        'refid' => ['id'],
        'j'     => ['i']
    },
    'fkeys to lists of referenced constrained columns determined'
);

#test get_self_reference
my $self_ref_info = SelfReference->get_self_reference( $schema, $table );
is_deeply(
    $self_ref_info,
    [ 'refid', 'refid' ],
    'self reference correctly determined'
);

#test selfref_tree
my ( $tree_ref, $root ) =
  @{ SelfReference->selfref_tree( $schema, $table, 'id', 'refid' ) };
is_deeply(
    $tree_ref,
    { $root => [ 1, 4 ], 1 => [ 2, 3 ], 4 => [5] },
    'self reference tree correctly determined'
);

$dbh->disconnect();