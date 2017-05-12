#!perl -w

use strict;

use Benchmark qw(:all);

use Storable ();
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
    'Storable' => sub{
        my $x = Storable::dclone(\@array);
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
    'Storable' => sub{
        my $x = Storable::dclone(\%hash);
    },
    'Data::Clone' => sub{
        my $x = Data::Clone::clone(\%hash);
    },
};
