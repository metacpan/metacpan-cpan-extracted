use lib 't/lib';
use TestImportFile;

my $tmp_dir;

run_directory_storage_tests_with {

    use Data::AnyXfer;
    use Data::AnyXfer::Elastic::Import::Storage::Directory;

    $tmp_dir //= Data::AnyXfer
        ->tmp_dir({ name => 'es_import_datefile-dir', cleanup => 1 });

    # storage instance to use for testing
    Data::AnyXfer::Elastic::Import::Storage::Directory
        ->new(dir => $tmp_dir, @_);
};


done_testing();
