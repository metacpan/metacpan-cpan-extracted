use strict;
use warnings;
use Test::More;
use Chemistry::Mol;
use Chemistry::File::Dumper;

plan 'no_plan';
#plan tests => 21;

Chemistry::Mol->register_descriptor(
    number_of_atoms => sub {
        my $mol = shift;
        return scalar $mol->atoms;
    }
);

my $mol = Chemistry::Mol->read("t/mol.pl");
my $n = $mol->descriptor('number_of_atoms');
is ($n, 8, 'number_of_atoms == 8');
