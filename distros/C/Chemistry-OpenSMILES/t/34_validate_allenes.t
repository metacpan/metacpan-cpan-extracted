#!/usr/bin/perl

use strict;
use warnings;
use Chemistry::OpenSMILES;
use Chemistry::OpenSMILES::Parser;
use Test::More;

my %cases = (
    'NC(Br)=[C@]=C(O)C' => undef,
    'CC(C)=[C@]=C(C)C'  => 'tetrahedral chiral allenal setting for C(3) is not needed as not all 4 neighbours are distinct',
    'CC(C)=C=[C@]=C=C(C)C' => 'tetrahedral chiral allenal setting for C(4) is not needed as not all 4 neighbours are distinct',
    'C/C(C)=C=[C@]=C(C)/C' => 'tetrahedral chiral allenal setting for C(4) observed for an atom which is not a center of an allenal system',

    'F/C=C=C=C/F' => undef,
    'F/C=C=C=CF' => 'allene system between atoms C(1) and C(4) has only one cis/trans marker',
    'FC=C=C=CF' => 'allene system between atoms C(1) and C(4) has 4 neighbours, but does not have cis/trans setting',
);

plan tests => scalar keys %cases;

for (sort keys %cases) {
    my $warning;
    local $SIG{__WARN__} = sub { $warning = $_[0] };

    my $parser   = Chemistry::OpenSMILES::Parser->new;
    my( $graph ) = $parser->parse( $_ );
    Chemistry::OpenSMILES::_validate( $graph, sub { $_[0]->{symbol} } );
    $warning =~ s/\n$// if defined $warning;
    is $warning, $cases{$_}, $_;
}
