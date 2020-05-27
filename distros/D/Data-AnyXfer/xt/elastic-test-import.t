
use Path::Class ();

use Data::AnyXfer::Test::Kit;
use Data::AnyXfer;
use Data::AnyXfer::Elastic::Test::Import;
use Data::AnyXfer::Elastic::IndexInfo;



use constant TEST_IMPORT_MODULE =>
    qw( Data::AnyXfer::Elastic::Test::Import );




# DEFINE TEST DATA

my @test_data = (
    {   userId => 1,
        id     => 1,
        title =>
            "sunt aut facere repellat provident occaecati excepturi optio reprehenderit",
        body =>
            "quia et suscipit suscipit recusandae consequuntur expedita et cum reprehenderit molestiae ut ut quas totam nostrum rerum est autem sunt rem eveniet architecto"
    },
    {   userId => 1,
        id     => 2,
        title  => "qui est esse",
        body =>
            "est rerum tempore vitae\nsequi sint nihil reprehenderit dolor beatae ea dolores neque\nfugiat blanditiis voluptate porro vel nihil molestiae ut reiciendis\nqui aperiam non debitis possimus qui neque nisi nulla"
    },
    {   userId => 1,
        id     => 3,
        title =>
            "ea molestias quasi exercitationem repellat qui ipsa sit aut",
        body =>
            "et iusto sed quo iure\nvoluptatem occaecati omnis eligendi aut ad\nvoluptatem doloribus vel accusantium quis pariatur\nmolestiae porro eius odio et labore et velit aut"
    },
    {   userId => 1,
        id     => 4,
        title  => "eum et est occaecati",
        body =>
            "ullam et saepe reiciendis voluptatem adipisci\nsit amet autem assumenda provident rerum culpa\nquis hic commodi nesciunt rem tenetur doloremque ipsam iure\nquis sunt voluptatem rerum illo velit"
    },
    {   userId => 1,
        id     => 5,
        title  => "nesciunt quas odio",
        body =>
            "repudiandae veniam quaerat sunt sed\nalias aut fugiat sit autem sed est\nvoluptatem omnis possimus esse voluptatibus quis\nest aut tenetur dolor neque"
    }
);

my @additional_test_data = (
    {   postId => 1,
        id     => 5,
        name   => "vero eaque aliquid doloribus et culpa",
        email  => "Hayden\@althea.biz",
        body =>
            "harum non quasi et ratione\ntempore iure ex voluptates in ratione\nharum architecto fugit inventore cupiditate\nvoluptates magni quo et"
    }
);




# SETUP TEST INDEX

my $test_indexinfo = Data::AnyXfer::Elastic::IndexInfo->new(
    silo  => 'testing',
    alias => 'test-import',
    type  => 'test-import'
);


# SETUP TEST DATAFILE

my ( $datafile, $datafile_path );
{

    my $tmp_dir = Data::AnyXfer->tmp_dir;
    $datafile = TEST_IMPORT_MODULE()->datafile(
        index_info => $test_indexinfo,
        dir        => $tmp_dir
    );

    $datafile->add_document($_) foreach @test_data;
    $datafile_path = Path::Class::dir($datafile->write);

    ok -f $datafile_path, 'created test datafile';
    TEST_IMPORT_MODULE()
        ->datafile_contains_exact( $datafile, [@test_data],
        'datafile_contains_exact matches as expected' );

    TEST_IMPORT_MODULE()
        ->datafile_contains( $datafile, [@test_data],
        'datafile_contains matches as expected' );

    TEST_IMPORT_MODULE()->datafile_contains(
        $datafile,
        [ @test_data[ 2, 4 ] ],
        'datafile_contains matches on superset as expected'
    );

}


# IMPORT TEST DATAFILE

my $test_index;
{
    $test_index = $test_indexinfo->get_index;
    my $df_dir = $datafile_path->parent;

    sub check_index {

        my ( $index, $name, $data ) = @_;

        my $data_supplied = defined $data;
        $data ||= [@test_data];

        TEST_IMPORT_MODULE()
            ->index_contains_exact( $index, $data,
            "${name} - index_contains_exact matches as expected" );

        TEST_IMPORT_MODULE()
            ->index_contains( $index, $data,
            "${name} - index_contains matches as expected" );

        unless ($data_supplied) {
            TEST_IMPORT_MODULE()->index_contains(
                $index,
                [ @{$data}[ 2, 4 ] ],
                "${name} - index_contains matches on superset as expected"
            );
        }
    }


    # Test import by datafile arg
    ok TEST_IMPORT_MODULE()->import_test_data( datafile => $datafile ),
        'import_test_data - direct datafile argument';
    sleep(2);
    check_index $test_index, 'direct datafile argument';

    # Test import by file path arg
    ok TEST_IMPORT_MODULE()->import_test_data( file => $datafile_path ),
        'import_test_data - file argument';
    sleep(2);
    check_index $test_index, 'file argument';

    # Test import by dir arg
    ok TEST_IMPORT_MODULE()->import_test_data( dir => $df_dir ),
        'import_test_data - dir argument (across single datafile)';
    sleep(2);
    check_index $test_index, 'dir argument (across single datafile)';




    # Test import by dir arg w/ multiple datafiles

    # remove the existing datafile and index
    $datafile_path->remove;
    eval {
        $test_index->elasticsearch->indices->delete(
            index => $datafile->index );
    };
    sleep(2);

    # call get_index in order to trigger the index to be recreated
    $test_index = $test_indexinfo->get_index;

    # create a separate datafile and index for each test data element
    my @test_datafiles;
    my ( $num, $file, $index_info );
    foreach (@test_data) {

        # create target filename
        $file = $df_dir->file(
            sprintf( "test-dir-import-%s.datafile", ++$num ) );

        # create sequential index
        $index_info = $datafile->export_index_info;
        $index_info->alias( $index_info->alias . "-$num" );
        $index_info->index( $index_info->index . "-$num" );

        # create the datafile instance
        $file = TEST_IMPORT_MODULE()
            ->datafile( index_info => $index_info, file => $file, );
        push @test_datafiles, $file;

        # add test data and write
        $file->add_document($_);
        $file = $file->write;

        ok $file, "import_test_data (dir) - created datafile ($file)";
    }

    # import the entire directory
    ok TEST_IMPORT_MODULE()->import_test_data( dir => $df_dir ),
        'import_test_data (dir) - imported directory of test datafiles';
    sleep(2);

    # check each datafile was imported correctly
    $num = 0;
    foreach (@test_datafiles) {
        check_index $_->index_info->get_index,
            'dir argument (across multiple datafiles / '
            . $datafile->file->basename . ')',
            [ $test_data[ $num++ ] ];
    }

}


done_testing();
