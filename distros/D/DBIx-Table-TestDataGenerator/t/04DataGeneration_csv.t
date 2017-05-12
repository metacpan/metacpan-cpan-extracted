use strict;
use warnings;

use Test::More tests => 2;
use Test::NoWarnings;
use Test::Exception;

use File::Spec qw/ make_path /;

use aliased 'DBIx::Table::TestDataGenerator';
use aliased 'DBIx::Table::TestDataGenerator::SelfReference';
use aliased 'DBIx::Table::TestDataGenerator::DBIxHelper';
use aliased 'DBIx::Table::TestDataGenerator::Query';
use aliased 'DBIx::Table::TestDataGenerator::Tree';

my $table = 'test_tdg';

my $dsn = 'dbi:SQLite:dbname=:memory:';
my $user = my $password = q{};

my $csv_dir = 't/db';

my $generator = DBIx::Table::TestDataGenerator->new(
    dsn                   => $dsn,
    user                  => $user,
    password              => $password,
    on_the_fly_schema_sql => 't/db/schema.sql',
    table                 => $table,
);

my $target_size    = 500;
my $num_random     = $target_size;
my $max_tree_depth = 3;
my $min_children   = 2;
my $min_roots      = 12;

$generator->create_testdata(
    target_size    => $target_size,
    num_random     => $num_random,
    max_tree_depth => $max_tree_depth,
    min_children   => $min_children,
    min_roots      => $min_roots,
    csv_dir        => $csv_dir,
);

#test number of records, must be
#"target size" - "original size" + "one line for header", #i.e. 496

my $csv_path = File::Spec->catfile( $csv_dir, $table );

open( my $fh, '<:encoding(UTF-8)', $csv_path )
  or die "Could not open csv file '$csv_path' $!";

1 while (<$fh>);

is( $., 496,
    "the correct number of 495 records have been found in the csv file" );
    
END {
    close $fh;
    $generator->disconnect();
}
