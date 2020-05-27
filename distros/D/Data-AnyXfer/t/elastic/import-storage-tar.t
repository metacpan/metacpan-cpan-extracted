use lib 't/lib';
use TestImportFile;

my $tmp_file;

run_tar_storage_tests_with {

    use Data::AnyXfer ();
    use Data::AnyXfer::Elastic::Import::Storage::TarFile;

    $tmp_file //= Data::AnyXfer
        ->tmp_dir({ name => 'es_import_datefile-targ', cleanup => 1 })
        ->file('test-archive.tar');

    # storage instance to use for testing
    Data::AnyXfer::Elastic::Import::Storage::TarFile
        ->new(file => $tmp_file, @_);
};


done_testing();
