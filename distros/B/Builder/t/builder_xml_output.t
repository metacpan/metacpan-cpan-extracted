use Test::More tests => 2;
use Builder;

# local test lib
use lib 't/lib';
use IO::Scalar;

my $got;

# below only works in 5.8.* and greater
# open my $fh, '>', \$got or die $!;  
 
my $fh = IO::Scalar->new( \$got );   # so use IO::Scalar insteead
my $builder = Builder->new( output => $fh );

my $xm  = $builder->block( 'Builder::XML', { indent => 4, newline => 1 } );

my $expected = 
q{<body>
    <em>emphasized</em>
    <div id="mydiv">
        <bold>hello</bold>
        <em>world</em>
    </div>
</body>
};

##############################################################
# test 1
$xm->body( sub {
    $xm->em("emphasized");
    $xm->div( { id => 'mydiv' }, $xm->bold('hello'), $xm->em('world') );
});

is $got, $expected, "xml ouput test 1 failed";


##############################################################
# test 2

$expected.= 
q{<body>
    <em>emphasized</em>
    <div id="mydiv">
        <li>
            <em>1</em>
        </li>
        <li>
            <em>2</em>
        </li>
        <li>
            <em>3</em>
        </li>
    </div>
</body>
};

$xm->body( sub {
    $xm->em("emphasized");
    $xm->div( { id => 'mydiv' }, sub {
       for my $numb ( 1..3 ) {
           $xm->li( $xm->em( $numb ) );
       }
    });
});

is $got, $expected, "xml ouput test 2 failed";


close $fh;
