use Test::More tests => 4;
use Builder;

my $builder = Builder->new();
my $xm = $builder->block( 'Builder::XML', { namespace => 'foo', qualified_attr => 0 } );

my $expected = q{<foo:body><foo:em>emphasized</foo:em><foo:div id="mydiv"><foo:bold>hello</foo:bold><foo:em>world</foo:em></foo:div></foo:body>};

# test 1
$xm->body( sub {
    $xm->em("emphasized");
    $xm->div( { id => 'mydiv' }, $xm->bold('hello'), $xm->em('world') );
});

is $builder->render, $expected, "xml test 1";

# test2
my $xm2 = $builder->block( 'Builder::XML', { namespace => 'foo', qualified_attr => 1 } );
$expected = q{<foo:body><foo:em>emphasized</foo:em><foo:div foo:id="mydiv"><foo:bold>hello</foo:bold><foo:em>world</foo:em></foo:div></foo:body>};

$xm2->body( sub {
    $xm2->em("emphasized");
    $xm2->div( { id => 'mydiv' }, $xm2->bold('hello'), $xm2->em('world') );
});

is $builder->render, $expected, "xml test 2";


# test 3
$expected = q{<foo:body xmlns:foo="http://www.w3.org/TR/REC-html40"><foo:em>emphasized</foo:em><foo:div id="mydiv"><foo:bold>hello</foo:bold><foo:em>world</foo:em></foo:div></foo:body>};
$xm->body( { _xmlns_ => "http://www.w3.org/TR/REC-html40" },
    sub {
    $xm->em("emphasized");
    $xm->div( { id => 'mydiv' }, $xm->bold('hello'), $xm->em('world') );
});

is $builder->render, $expected, "xml test 3";


# test 4
$expected = q{<foo:body xmlns:foo="http://www.w3.org/TR/REC-html40"><foo:em>emphasized</foo:em><foo:div foo:id="mydiv"><foo:bold>hello</foo:bold><foo:em>world</foo:em></foo:div></foo:body>};
$xm2->body( { _xmlns_ => "http://www.w3.org/TR/REC-html40" },
    sub {
    $xm2->em("emphasized");
    $xm2->div( { id => 'mydiv' }, $xm2->bold('hello'), $xm2->em('world') );
});

is $builder->render, $expected, "xml test 4";