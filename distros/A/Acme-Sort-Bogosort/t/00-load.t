#!perl

use Test::More tests => 12;
use Try::Tiny;
use List::Util qw/shuffle/;
use 5.010;

BEGIN {
    use_ok( 'Acme::Sort::Bogosort' ) || print "Bail out!\n";
}

diag( "Testing Acme::Sort::Bogosort $Acme::Sort::Bogosort::VERSION, Perl $], $^X" );

can_ok( 'Acme::Sort::Bogosort', qw/bogosort is_ordered compare/ );


note ( "Testing Acme::Sort::Bogosort::compare()" );
my %comparisons = (
    descending  => [ 'B', 'A',  1, "compare( qw/B A/ ) ==  1" ],
    ascending   => [ 'A', 'B', -1, "compare( qw/A B/ ) == -1" ],
    equal       => [ 'A', 'A',  0, "compare( qw/A A/ ) ==  0" ],
);
foreach my $comp ( keys %comparisons ) {
    is( 
        Acme::Sort::Bogosort::compare( 
            $comparisons{$comp}[0], 
            $comparisons{$comp}[1] 
        ),
        $comparisons{$comp}[2],
        $comparisons{$comp}[3]
    );
}

my $caught;
try {
    Acme::Sort::Bogosort::compare( 'A' );
} catch {
    $caught = $_;
};

like(
    $caught,
    qr/requires two/,
    "compare() throws exception if given other than two args to compare."
);


note( "Testing Acme::Sort::Bogosort::is_ordered() -- Default ascending order." );
my $compare = \&Acme::Sort::Bogosort::compare;
is( 
    Acme::Sort::Bogosort::is_ordered( $compare, [ qw/ A B C D E / ] ), 
    1, 
    "is_ordered( \&compare, [ qw/ A B C D E / ] ) returns true." 
);

isnt(
    Acme::Sort::Bogosort::is_ordered( $compare, [ qw/ E D C B A / ] ),
    1,
    "is_ordered( \&compare, [ qw/ E D C B A / ] ) returns false."
);

undef $caught;
try {
    Acme::Sort::Bogosort::is_ordered( [ qw/ A B C D E / ] );
} catch { $caught = $_ };
like( 
    $caught, 
    qr/expects a coderef/, 
    "is_ordered() throws exception when not handed a coderef as first param."
);

undef $caught;
try {
    Acme::Sort::Bogosort::is_ordered( $compare, qw/ A B C D E / );
} catch { $caught = $_ };
like(
    $caught,
    qr/expects an arrayref/,
    "is_ordered() throws an exception when not handed an arrayref as second param."
);

note "Testing Acme::Sort::Bogosort::bogosort().";
my @unsorted = shuffle( 'A' .. 'E' );
my @sorted = bogosort( @unsorted );
is_deeply( 
    \@sorted, 
    [ qw/ A B C D E / ], 
    "bogosort( qw/ A B C D E / ) - Default sort order returns correct results."
);
@sorted = bogosort( \&my_cmp, @unsorted );
is_deeply( 
    \@sorted, 
    [ qw/ E D C B A / ], 
    "bogosort( \&my_cmp, @unsorted ) - Alternate sort order via coderef returns correct results." 
);

# Provide a reverse standard string comparison order alternative.
sub my_cmp {
    return $_[1] cmp $_[0];
}
