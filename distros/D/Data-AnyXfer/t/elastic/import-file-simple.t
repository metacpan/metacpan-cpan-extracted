use lib 't/lib';
use TestImportFile;


run_file_tests_with {

    use Data::AnyXfer::Elastic::Import::File::Simple;

    # file instance to use for testing
    Data::AnyXfer::Elastic::Import::File::Simple
        ->new( name => 'test_file_simple_es_import', @_ );
};

done_testing();
