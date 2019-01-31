use Test::More;
use Test::Exception;
use Data::Dumper;
use Cwd qw(getcwd);

BEGIN {
    use_ok( 'App::iperlmoddir::Utils', qw(:all) );
}

my $mods_dir = 't/samples';
my $mods = [ 'ABC.pm', 'Bar.pm', 'Baz.pm', 'Foo.pm', 'Package.pm', 'XYZ.pm' ];
my $sample_parse_res = [
    {
        'name'   => 'ABC',
        'subs'   => ['foo'],
        'used'   => ['Exporter'],
        'consts' => []
    },
    {
        'name'   => 'Bar',
        'subs'   => [ 'abc', 'print_info' ],
        'used'   => [ 'Carp', 'Cwd', 'lib', 'parent' ],
        'consts' => []
    },
    {
        'name'   => 'Baz',
        'subs'   => [ 'LOOKS_LIKE_CONSTANT', 'new', 'print_info', 'some_attr' ],
        'used'   => [ 'constant', 'lib', 'parent' ],
        'consts' => [ 'lowercase', 'MINIMAL_MATCH', 'SEC' ]
    },
    {
        'name'   => 'Foo',
        'subs'   => ['hello'],
        'used'   => [ 'strict', 'utf8', 'warnings' ],
        'consts' => []
    },
    {
        'name'   => 'XYZ',
        'subs'   => ['bar'],
        'used'   => ['ABC'],
        'consts' => []
    }
];

my $subs_csv_unsorted = [
    [ 'ABC', 'Bar',        'Baz',                 'Foo',   'XYZ' ],
    [ 'foo', 'abc',        'LOOKS_LIKE_CONSTANT', 'hello', 'bar' ],
    [ undef, 'print_info', 'new',                 undef,   undef ],
    [ undef, undef,        'print_info',          undef,   undef ],
    [ undef, undef,        'some_attr',           undef,   undef ],
];

my $cols =
  [ [ 'Header1', 1, 2, 3 ], [ 'Header2', 2, 3 ], [ 'Header3', 7, 7, 7 ] ];

my $rows = [
    [ 'Header1', 'Header2', 'Header3' ],
    [ 1,         2,         7 ],
    [ 2,         3,         7 ],
    [ 3,         undef,     7 ]
];

my $rows_sorted = [
    [ 'Header1', 'Header2', 'Header3' ],
    [ 1,         undef,     undef ],
    [ 2,         2,         undef ],
    [ 3,         3,         undef ],
    [ undef,     undef,     7 ]
];

subtest "_substr_aldc" => sub {
    is _substr_aldc("Foo::bar"), "bar";
    is _substr_aldc("bar"),      "bar";
};

subtest "_cols2rows" => sub {
    is_deeply _cols2rows($cols), $rows;

};

subtest "_rm_header_from_cols_AoA" => sub {

    my $input = [
        [ 'Header1', 's1', 's2',  's3' ],
        [ 'Header2', 's2', 's3',  undef ],
        [ 'Header3', 's7', undef, undef ]
    ];

    is_deeply
      [ 'Header1', 'Header2', 'Header3' ],
      _rm_header_from_cols_AoA($input);

};

subtest "_add_header_to_cols_AoA" => sub {

    my $input =
      [ [ 's1', 's2', 's3' ], [ 's2', 's3', undef ], [ 's7', undef, undef ] ];

    my $header = [ 'Header1', 'Header2', 'Header3' ];

    my $output = [
        [ 'Header1', 's1', 's2',  's3' ],
        [ 'Header2', 's2', 's3',  undef ],
        [ 'Header3', 's7', undef, undef ]
    ];

    is_deeply
      _add_header_to_cols_AoA( $input, $header ),
      $output;

};

subtest "_sort_cols_AoA_by_neighbour" => sub {

    my $input1 =
      [ [ 's1', 's2', 's3' ], [ 's2', 's3', undef ], [ 's7', undef, undef ] ];

    my $expected1 = [
        [ "s1",  "s2",  "s3",  undef ],
        [ undef, "s2",  "s3",  undef ],
        [ undef, undef, undef, "s7" ],
    ];

    my $input2 =
      [ [ 's1', 's2', 's3' ], [ 's2', 's3', '' ], [ 's7', '', '' ] ];

    my $input3 = [
        [ 'Header1', 's1', 's2',  's3' ],
        [ 'Header2', 's2', 's3',  undef ],
        [ 'Header3', 's7', undef, undef ]
    ];

    my $expected2 = [
        [ 'Header1', "s1",  "s2",  "s3",  undef ],
        [ 'Header2', undef, "s2",  "s3",  undef ],
        [ 'Header3', undef, undef, undef, "s7" ],
    ];

    is_deeply _sort_cols_AoA_by_neighbour($input1), $expected1;
    is_deeply $input1, $expected1;

    is_deeply _sort_cols_AoA_by_neighbour($input2), $expected1;
    is_deeply $input2, $expected1;

    # is_deeply _sort_cols_AoA_by_neighbour($input3, 1), $expected2;

};

subtest "_validate_module_fullname" => sub {
    ok _validate_module_fullname('Test.pm');
    ok !_validate_module_fullname('test.pl');
    ok _validate_module_fullname('foo/bar/Test.pm');    # but warning
};

subtest "_extract_base" => sub {
    is( _extract_base( abs => '/foo/bar/Foo/Bar.pm', rel => 'Foo/Bar.pm' ),
        '/foo/bar' );

    dies_ok {
        _extract_base( abs => '/lib/libwww/Bar.pm', rel => 'Foo/Bar.pm' )
    }
    'Die when rel is not substing of abs';

};

subtest "get_inspected_modules_list" => sub {
    is_deeply(
        $mods,
        get_inspected_modules_list($mods_dir),
        'get_inspected_modules_list at ' . $mods_dir . ' return ok'
    );
};

subtest "parse_modules" => sub {

    my $cwd = getcwd();
    chdir $mods_dir;

    is_deeply $sample_parse_res,
      parse_modules(
        [ 'Package.pm', 'Foo.pm', 'Baz.pm', 'Bar.pm', 'ABC.pm', 'XYZ.pm' ] ),
      'Sample modules parsed fine, Package.pm excluded from results';

    chdir $cwd;

};

done_testing();
