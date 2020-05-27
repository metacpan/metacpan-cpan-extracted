use Data::AnyXfer::Test::Kit;

use File::Basename                                   ();
use Data::UUID                                       ();
use Data::AnyXfer::Elastic::IndexInfo        ();
use Data::AnyXfer::Elastic::Import::DataFile ();
use Data::AnyXfer::Elastic::Test::Import     ();

my $pkg = 'Data::AnyXfer::ElasticsearchToDataFile';

use_ok($pkg);
does_ok( $pkg, 'Data::AnyXfer::From::Elasticsearch' );
does_ok( $pkg, 'Data::AnyXfer::To::Elasticsearch::DataFile' );



# TEST DATA / INDEX CONFIG

my @index_info_args = (
    silo  => 'public_data',
    alias => File::Basename::basename($0),
    type  => 'test_doc'
);

my @data = map { { test_document => $_ } } 1 .. 10;


# CREATE TEST IMPORT AND INDEX OBJECTS

my $es_test_import = Data::AnyXfer::Elastic::Test::Import->new;
my $test_index_info
    = Data::AnyXfer::Elastic::IndexInfo->new( @index_info_args );

ok $test_index_info, 'created test index info';


# BUILD TEST DATAFILE

my $test_df = Data::AnyXfer::Elastic::Test::Import->datafile(
    index_info => $test_index_info, );

$test_df->add_document($_) for @data;
$test_df->write;
pass 'added test docments to datafile';


# PLAY TEST DATAFILE

$es_test_import->import_test_data(
    index_info => $test_index_info,
    datafile   => $test_df,
);


# INSPECT THE RESULTING INDEX

my $test_index = $test_index_info->get_index;

$es_test_import->index_contains_exact( $test_index, \@data,
    'initial index contains expected documents' );


# IMPORT THE INDEX BACK TO DATAFILE (MAIN TEST)

my $target_df = Data::AnyXfer::Elastic::Test::Import->datafile(
    index_info => $test_index_info, );

my $index_to_df = $pkg->new(
    source_index_info => $test_index_info,
    index_info        => $test_index_info,
    datafile          => $target_df
);
ok $index_to_df->run, 'running elasticsearch index to datafile importer';

ok $target_df, 'target datafile exists after import';
$es_test_import->datafile_contains_exact( $target_df, \@data,
    'target datafile contains expected documents' );



done_testing;
