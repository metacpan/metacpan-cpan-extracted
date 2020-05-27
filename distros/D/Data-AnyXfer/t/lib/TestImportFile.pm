package TestImportFile;


use Exporter qw( import );

use Data::AnyXfer::Test::Kit;




# EXPORTED SUBS


our @EXPORT = qw/
    run_file_tests_with
    run_multipart_tests_with
    run_storage_tests_with
    run_directory_storage_tests_with
    run_tar_storage_tests_with
    done_testing
/;




# SETUP TEST DATA


sub std_test_data {
    map {
         {
             "settings_$_" => { name => 'testing', value => 'x' x 10 },
             "message$_" => [ ('very ') x $_, qw/silly buggers always fetch eggs / ],
         }
    } 1..10
}

{
    my ($inc, @data) = 1;
    sub numeric_test_data { return @data; }

    foreach (1..10) {
        push @data, ([map { $_ * $inc++ } 1..5]);
    }
}


sub simple_test_data1 {
    return
    item_1 => 'Foolish camels always run backwards',
    item_2 => 'Elastic Ed runs forwards',
}

sub simple_test_data2 {
    return
    item_2 => 'Row row row your boat',
    item_1 => 'Quickly, but safely',
};




# FILE TESTING INTERFACE


sub run_file_tests_with (&) {

    my @test_data = std_test_data();
    my $new_file_sub = $_[0];


    # BASIC TEST OF DEFAULTS

    my $file = $new_file_sub->();
    ok $file, 'new - created import file';

    # add_status will be zero if *any* of the calls return zero
    my $add_status = 1;
    $add_status *= $file->add($_) foreach (@test_data);
    ok $add_status, 'add - added test data to import file successfully';


    # BASIC TEST WITH COMMON STORAGE

    my $new_file = $new_file_sub->( storage => $file->storage );

    is_deeply $new_file->get, $test_data[0],
    'get - get on new file instance returns matching first item test data';

    $new_file->get;

    is_deeply $new_file->get, $test_data[2],
    'get - third get on new file instance returns matching third item test data';


    ok $new_file->add(@test_data),
    'add - added more test data to existing file';

    ok ! defined $new_file->get,
    'get - get jumps to last item after add operation, returning undef';

    return $file;
}


sub run_multipart_tests_with (&) {

    my @test_data = numeric_test_data();
    my $new_file_sub = $_[0];
    my $part_size = 2;


    # RUN STANDARD FILE TESTS

    &run_file_tests_with($new_file_sub);


    # RUN EXTENDED MULTI-PART FILE SPECIFIC TESTS

    my $file = $new_file_sub->(part_size => $part_size);
    $file->add($_) foreach (@test_data);

    # tests which verify part sequences and data

    my @new_parts = $file->list_part_names;
    my $expected_parts = 10 / $part_size;
    is scalar(@new_parts), $expected_parts,
    "parts - new part size after add matches expected number ($expected_parts)";

    ok $file->reset,
    'parts - reset (to beginning) returns true multi-part file';

    is_deeply
    [map { $file->get }  (undef) x scalar @test_data],
    [@test_data],
    'parts - fully restored data from multi-part file matches original complete data';

    return $file;
}



sub run_storage_tests_with (&) {

    my $build_new_storage = $_[0];
    my $storage = $build_new_storage->();

    my %test_data_add = simple_test_data1();
    my %test_data_set = simple_test_data2();


    # TEST ADD ITEM

    foreach ( keys %test_data_add ) {
        ok $storage->add_item($_, $test_data_add{$_}),
        "add_item - $_ added to storage";
    }

    is_deeply
    [map { $storage->get_item($_) ? 1 : 0 } keys %test_data_add],
    [(1) x scalar keys %test_data_add],
    'add_item - added items exist on storage instance';

    foreach ( keys %test_data_add ) {
        is $storage->get_item($_), $test_data_add{$_},
        "add_item - $_ - initialised data matches test data";
    }


    #TEST SET ITEM

    foreach ( keys %test_data_set ) {
        ok $storage->set_item($_, $test_data_set{$_}),
        "set_item - $_ set on storage";
    }

    is_deeply
    [map { $storage->get_item($_) ? 1 : 0 } keys %test_data_set],
    [(1) x scalar keys %test_data_set],
    'set_item - set items exist on storage instance';

    foreach ( keys %test_data_set ) {
        is $storage->get_item($_), $test_data_set{$_},
        "set_item - $_ - initialised data matches test data";
    }


    # TEST REMOVE

    is_deeply
    [map { $storage->remove_item($_) ? 1 : 0 } keys %test_data_set],
    [(1) x scalar keys %test_data_set],
    'remove_item - set items removed on storage instance';

    is_deeply
    [map { $storage->get_item($_) ? 1 : 0 } keys %test_data_set],
    [(0) x scalar keys %test_data_set],
    'remove_item - removed items no longer exist on storage instance';


    # TEST NEW INSTANCE

    my $map = $storage->_export_internal_item_map;
    my $storage_new = $build_new_storage->(working_dir => $storage->working_dir);

    is_deeply $map, $storage_new->_export_internal_item_map,
    'new - items persist across storage instances with common working_dir';

    ok $storage_new->set(%test_data_set),
    'set - multi-set returns true on new storage instance';

    is_deeply
    [map { $storage_new->get_item($_) ? 1 : 0 } keys %test_data_set],
    [(1) x scalar keys %test_data_set],
    'set - set items exist on new storage instance';

    is_deeply
    [map { $storage->get_item($_) ? 1 : 0 } keys %test_data_set],
    [(0) x scalar keys %test_data_set],
    'reload - set items do not exist on old storage instance';

    ok $storage->reload,
    'reload - reload returns true on old storage instance';

    is_deeply
    [map { $storage->get_item($_) ? 1 : 0 } keys %test_data_set],
    [(1) x scalar keys %test_data_set],
    'reload - set items exist on old storage instance after reload';

    return $storage;
}


sub run_directory_storage_tests_with (&) {

    my %test_data_set = simple_test_data2();


    # RUN STANDARD STORAGE TESTS

    my $storage = &run_storage_tests_with;


    # RUN EXTENDED DIRECTORY STORAGE TESTS

    # extra tests - save
    ok $storage->save,
        'save - storage save method returns true';
    is scalar @{[$storage->dir->children]}, scalar keys %test_data_set,
        'save - final directory contains items after save operation';

    # extra tests - cleanup
    ok $storage->cleanup,
        'cleanup - storage cleanup method returns true';

    ok ! -e $storage->working_dir,
        'cleanup - temporary directory no longer exists';

    return $storage;
}


sub run_tar_storage_tests_with (&) {

    my $create_storage_sub = $_[0];


    # RUN STANDARD STORAGE TESTS

    my $storage = &run_storage_tests_with(@_);


    # RUN EXTENDED TARFILE STORAGE TESTS

    # extra tests - save
    ok $storage->save,
        'save (tar) - storage save method returns true';

    my $storage_new = $create_storage_sub->();
    cmp_deeply
        [keys %{$storage_new->_export_internal_item_map}],
        bag(keys %{$storage->_export_internal_item_map}),
        'save (tar) - items consistent after save/restore operation';

    # extra tests - cleanup
    ok $storage->cleanup,
        'cleanup - storage cleanup method returns true';

    ok ! -e $storage->working_dir,
        'cleanup - temporary directory no longer exists';

    return $storage;
}

1;


=head1 COPYRIGHT

This software is copyright (c) 2019, Anthony Lucas.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut
