use lib 't/lib';
use TestImportFile;


run_multipart_tests_with {

    use Data::AnyXfer::Elastic::Import::File::MultiPart;

    # file instance to use for testing
    Data::AnyXfer::Elastic::Import::File::MultiPart
        ->new( name => 'test_file_multipart_es_import', @_ );
};


done_testing();
