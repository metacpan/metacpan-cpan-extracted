
use Test::More tests => 12;

BEGIN {
    use_ok('DataFlow::Proc::DPath');
}

$fail = eval q{DataFlow::Proc::DPath->new};
ok($@);

$ok = DataFlow::Proc::DPath->new( search_dpath => '//*[2]', references => 1 );
ok($ok);

$data = [ 0, 10, 20, 30, 40 ];

@res = $ok->process($data);
is( scalar @res,    1 );
is( ref( $res[0] ), 'SCALAR' );
is( ${ $res[0] },   20 );

${ $res[0] } = 35;
is( ref( $res[0] ), 'SCALAR' );
is( ${ $res[0] },   35 );
is_deeply( $data, [ 0, 10, 35, 30, 40 ] );

$cckey = DataFlow::Proc::DPath->new(
    search_dpath => '//*[key =~ /cc/]',
    references   => 1
);
ok($cckey);

$data = {
    aa => 'bb',
    cc => {
        dd1 => 123,
        dd2 => 'abc',
        dd3 => [qw/yaba daba doo/],
    },
    'ee' => 'ff',
};

@res = $cckey->process($data);
is( scalar @res, 1 );    # problem in Data::DPath ??
${ $res[0] } = 42;
is_deeply(
    $data,
    {
        aa => 'bb',
        cc => 42,
        ee => 'ff',
    }
);
