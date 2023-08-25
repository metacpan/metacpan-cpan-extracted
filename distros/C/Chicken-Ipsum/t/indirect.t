#!perl
use 5.012;
use warnings FATAL => 'all';

use Test::More 'no_plan';
require_ok 'Chicken::Ipsum';
my $ci = Chicken::Ipsum->new;

# Possible indirect call to 'sample' for the $num parameter

my $tn = TestNumber->new(2);
isnt(scalar $ci->words($tn), '',
    '->words() worked with an object-as-number'
);
ok(!$tn->{sample_called},
    'object-as-number had sample() method called by library'
);

package TestNumber;
use 5.012;
use warnings FATAL => 'all';
use parent 'Math::BigInt';

sub sample {
    my $self = shift;
    $self->{sample_called} = 1;
    return;
}
