#!/usr/bin/perl

use strict;
use warnings;
use Chemistry::OpenSMILES::Parser;
use Chemistry::OpenSMILES::Writer qw(write_SMILES);
use Test::More;

my @cases = (
    [ 'N[C@](Br)(O)C',
      'N([C@](Br)(O[H])C([H])([H])[H])([H])[H]',
       undef ],
    [ 'NC(Br)=[C@]=C(O)C',
      'N(C(Br)=C=C(O[H])C([H])([H])[H])([H])[H]',
       undef ],
    [ 'N[C@](Br)(O)(C)(Cl)',
      'N([C@TB1](Br)(O[H])(C([H])([H])[H])Cl)([H])[H]',
       undef ],
);

plan tests => 2 * scalar @cases;

for my $case (@cases) {
    my $warning;
    local $SIG{__WARN__} = sub { $warning = $_[0] };

    my $parser = Chemistry::OpenSMILES::Parser->new;
    my @moieties = $parser->parse( $case->[0] );

    is write_SMILES( \@moieties, { unsprout_hydrogens => '' } ), $case->[1];

    $warning =~ s/\n$// if $warning;
    is $warning, $case->[2];
}
