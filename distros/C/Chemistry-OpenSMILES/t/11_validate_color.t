#!/usr/bin/perl

use strict;
use warnings;
use Chemistry::OpenSMILES qw( clean_chiral_centers );
use Chemistry::OpenSMILES::Parser;
use Test::More;

my %cases = (
    'C[C@](C)(C)(C)' => 'tetrahedral chiral setting for C(1) is not needed as not all 4 neighbours (including possible lone pair) are distinct',
    'C[C@](Cl)(F)(O)' => undef,
    'C(Cl)(F)(O)' => 'atom C(0) has 4 distinct neighbours, but does not have a chiral setting',
    # Anomers must not loose chirality settings
    'N[C@@]12NC(N[C@]2(NC(N1))N)' => undef,
);

plan tests => 3 * scalar keys %cases;

for (sort keys %cases) {
    my $warning;
    local $SIG{__WARN__} = sub { $warning = $_[0] };

    my $parser   = Chemistry::OpenSMILES::Parser->new;
    my( $graph ) = $parser->parse( $_ );
    Chemistry::OpenSMILES::_validate( $graph,
                                      sub { return $_[0]->{symbol} } );
    $warning =~ s/\n$// if defined $warning;
    is $warning, $cases{$_};

    # Unnecessary chiral centers should be removed
    my @affected = clean_chiral_centers( $graph,
                                         sub { return $_[0]->{symbol} } );
    is @affected != 0,
       defined $cases{$_} && $cases{$_} =~ /not needed/,
       "$_ - affected atoms";

    # After removal, validation should pass
    undef $warning;
    Chemistry::OpenSMILES::_validate( $graph,
                                      sub { return $_[0]->{symbol} } );
    $warning =~ s/\n$// if defined $warning;
    is !defined $warning,
       !defined $cases{$_} || @affected != 0,
       "$_ - validation";
}
