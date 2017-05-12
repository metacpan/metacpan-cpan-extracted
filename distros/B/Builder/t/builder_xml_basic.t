use Test::More tests => 5;
use Builder;

my $builder = Builder->new();
my $xm = $builder->block( 'Builder::XML' );

my $expected = q{<body><em>emphasized</em><div id="mydiv"><bold>hello</bold><em>world</em></div></body>};

# test 1
$xm->body( sub {
    $xm->em("emphasized");
    $xm->div( { id => 'mydiv' }, $xm->bold('hello'), $xm->em('world') );
});

is $builder->render, $expected, "xml test 1 failed";


# test 2
$xm->body(
    $xm->em("emphasized"),
    $xm->div( { id => 'mydiv' }, sub {
        $xm->bold('hello'); $xm->em('world');
    }),
);

is $builder->render, $expected, "xml test 2 failed";


# test 3
$xm->test('hello');
my $zz = $builder->render;

$xm->body( sub {
    $xm->em("emphasized");
    $xm->div( { id => 'mydiv' },
        $xm->bold('hello'),
        $xm->em('world'),
        $zz,
        $xm->div( sub {
            $xm->p('para'); 
            $xm->__say__($zz);
        }),
    );
});

$expected = q{<body><em>emphasized</em><div id="mydiv"><bold>hello</bold><em>world</em><test>hello</test><div><p>para</p><test>hello</test></div></div></body>};
is $builder->render, $expected, "xml test 3 failed";


# test 4
# parameter(s) are content  =>  element text

$xm->p( 'one', 'two', 'and three' );
is $builder->render, q{<p>one two and three</p>}, "xml test 4 failed";

# test 5
# parameter(s) are Builder blocks  =>  nesting

$xm->p( $xm->span( 'one' ), 'two', 'and three' );
is $builder->render, q{<p><span>one</span>twoand three</p>}, "xml test 5 failed";

__END__

# however this fails (doesn't do span callback)... need to look at....
$xm->p( 'one', $xm->span( 'two' ), 'and three' );


