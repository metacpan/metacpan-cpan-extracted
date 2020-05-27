use lib 't/lib';
use TestImportFile;

my $tmp_file;

run_tar_storage_tests_with {

    use Data::AnyXfer ();
    use Data::AnyXfer::Elastic::Import::Storage::LzmaFile;

    $tmp_file //= Data::AnyXfer
        ->tmp_dir({ name => 'es_import_datefile-lzma', cleanup => 1 })
        ->file('test-archive.lzma');

    # storage instance to use for testing
    Data::AnyXfer::Elastic::Import::Storage::LzmaFile
        ->new(file => $tmp_file, @_);
};


done_testing();
