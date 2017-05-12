use Test::More tests => 6;

BEGIN {
    use_ok('DataFlow::Proc::MultiPageURLGenerator');
}

eval { $m = DataFlow::Proc::MultiPageURLGenerator->new };
ok( $@, 'Needs required parameters' );

$m =
  DataFlow::Proc::MultiPageURLGenerator->new(
    make_page_url => sub { $_[1] . '?page=' . $_[2] }, );
ok($m);

eval { $m->last_page };
ok( $@, q{Must pass 'last_page' or 'produce_last_page'} );

$m = DataFlow::Proc::MultiPageURLGenerator->new(
    make_page_url => sub { $_[1] . '?page=' . $_[2] },
    last_page     => 10,
);
@res = $m->process('http://a.b.c.d/bozo');
is( scalar( @{ $res[0] } ), 10, 'result has the right size' );
is_deeply(
    $res[0],
    [
        'http://a.b.c.d/bozo?page=1', 'http://a.b.c.d/bozo?page=2',
        'http://a.b.c.d/bozo?page=3', 'http://a.b.c.d/bozo?page=4',
        'http://a.b.c.d/bozo?page=5', 'http://a.b.c.d/bozo?page=6',
        'http://a.b.c.d/bozo?page=7', 'http://a.b.c.d/bozo?page=8',
        'http://a.b.c.d/bozo?page=9', 'http://a.b.c.d/bozo?page=10',
    ],
    'produces the expected result'
);
