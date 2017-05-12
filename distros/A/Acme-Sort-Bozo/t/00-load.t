#!perl

use Test::More tests => 13;
use Try::Tiny;
use List::Util qw/shuffle/;
use 5.010;

BEGIN {
    use_ok( 'Acme::Sort::Bozo' ) || print "Bail out!\n";
}

diag( "Testing Acme::Sort::Bozo $Acme::Sort::Bozo::VERSION, Perl $], $^X" );

can_ok( 'Acme::Sort::Bozo', qw/bozo is_ordered compare swap/ );


note ( "Testing Acme::Sort::Bozo::compare()" );
my %comparisons = (
    descending  => [ 'B', 'A',  1, "compare( qw/B A/ ) ==  1" ],
    ascending   => [ 'A', 'B', -1, "compare( qw/A B/ ) == -1" ],
    equal       => [ 'A', 'A',  0, "compare( qw/A A/ ) ==  0" ],
);
foreach my $comp ( keys %comparisons ) {
    is( 
        Acme::Sort::Bozo::compare( 
            $comparisons{$comp}[0], 
            $comparisons{$comp}[1] 
        ),
        $comparisons{$comp}[2],
        $comparisons{$comp}[3]
    );
}

my $caught;
try {
    Acme::Sort::Bozo::compare( 'A' );
} catch {
    $caught = $_;
};

like(
    $caught,
    qr/requires two/,
    "compare() throws exception if given other than two args to compare."
);


note( "Testing Acme::Sort::Bozo::is_ordered() -- Default ascending order." );
my $compare = \&Acme::Sort::Bozo::compare;
is( 
    Acme::Sort::Bozo::is_ordered( $compare, [ qw/ A B C D E / ] ), 
    1, 
    "is_ordered( \&compare, [ qw/ A B C D E / ] ) returns true." 
);

isnt(
    Acme::Sort::Bozo::is_ordered( $compare, [ qw/ E D C B A / ] ),
    1,
    "is_ordered( \&compare, [ qw/ E D C B A / ] ) returns false."
);

undef $caught;
try {
    Acme::Sort::Bozo::is_ordered( [ qw/ A B C D E / ] );
} catch { $caught = $_ };
like( 
    $caught, 
    qr/expects a coderef/, 
    "is_ordered() throws exception when not handed a coderef as first param."
);

undef $caught;
try {
    Acme::Sort::Bozo::is_ordered( $compare, qw/ A B C D E / );
} catch { $caught = $_ };
like(
    $caught,
    qr/expects an arrayref/,
    "is_ordered() throws an exception when not handed an arrayref as second param."
);

note "Testing Acme::Sort::Bozo::swap()";
my $listref = [qw/ A B C D E / ];
my $orig = join '', @{$listref};
my $new = join '', @{ Acme::Sort::Bozo::swap( $listref ) };
isnt( $new, $orig, "Swap successfully swapped two elements." );





note "Testing Acme::Sort::Bozo::bozo().";
my @unsorted = shuffle( 'A' .. 'E' );
my @sorted = bozo( @unsorted );
is_deeply( 
    \@sorted, 
    [ qw/ A B C D E / ], 
    "bozo( \@unsorted ) - Default sort order returns correct results."
);
@sorted = bozo( \&my_cmp, @unsorted );
is_deeply( 
    \@sorted, 
    [ qw/ E D C B A / ], 
    "bozo( \&my_cmp, \@unsorted ) - Alternate sort order via coderef returns correct results." 
);

# Provide a reverse standard string comparison order alternative.
sub my_cmp {
    return $_[1] cmp $_[0];
}

note "13 tests; This thing may go O(INF) after all!"