#!perl -w

use strict;

use Benchmark qw(:all);

use Clone::Fast ();
use Clone ();
use Data::Clone ();

my @array = (
    [1 .. 10],
    [1 .. 10]
);

print "ArrayRef:\n";
cmpthese -1 => {
    'Clone' => sub{
        my $x = Clone::clone(\@array);
    },
    'Clone::Fast' => sub{
        my $x = Clone::Fast::clone(\@array);
    },
    'Data::Clone' => sub{
        my $x = Data::Clone::clone(\@array);
    },
};

my %hash = (
    key => \@array,
);
print "HashRef:\n";
cmpthese -1 => {
    'Clone' => sub{
        my $x = Clone::clone(\%hash);
    },
    'Clone::Fast' => sub{
        my $x = Clone::Fast::clone(\%hash);
    },
    'Data::Clone' => sub{
        my $x = Data::Clone::clone(\%hash);
    },
};
