#!perl

# Make sure that the objects get destroyed at the appropriate time

use Test::More tests => 4;
use strict;
use warnings;

use Data::Iterator::Hierarchical;

my $destroyed;

sub Data::Iterator::Hierarchical::Test::DESTROY {
    $destroyed++;
}

sub test_data {
    [
    [ 1, 1, 999 ],
    [ 2, 2, 2 ],
    [ bless {}, 'Data::Iterator::Hierarchical::Test' ],
    ];
}

{
    my $it = hierarchical_iterator(test_data);
    my ($one) = $it->(my $it2,1);
    my ($two) = $it2->(my $it3,1);
    my ($three) = $it3->();
    is($three,999,'sanity check - looking at right data');
    ok(!$destroyed,'santy check - not prematurely destroyed');
}

SKIP: {
    if ( $] < 5.010 ) {
	skip('known to leak pre-5.10',1);
    } else {
	ok($destroyed,'destroyed unpon relasee of iterator');
    }
}

$destroyed=0;

{
    my $it = hierarchical_iterator(test_data);
    while (my ($one) = $it->(my $it2,1)) {
	my ($two) = $it2->(my $it3,1);
    }
    ok($destroyed,'release of input on exhaustion');
}
