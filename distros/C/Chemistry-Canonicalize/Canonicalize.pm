package Chemistry::Canonicalize;

# $Id: Canonicalize.pm,v 1.2 2009/05/10 20:16:22 itubert Exp $
$VERSION = '0.11';

use strict;
use warnings;

use Math::BigInt;
use Carp;
use base 'Exporter';
our @EXPORT_OK = qw(canonicalize);
our %EXPORT_TAGS = ( all => \@EXPORT_OK ); 


=head1 NAME

Chemistry::Canonicalize - Number the atoms in a molecule in a unique way

=head1 SYNOPSIS

    use Chemistry::Canonicalize ':all';

    # $mol is a Chemistry::Mol object
    canonicalize($mol);
    print "The canonical number for atom 1 is: ", 
        $mol->atoms(1)->attr("canon/class");
    print "The symmetry class for for atom 1 is: ", 
        $mol->atoms(1)->attr("canon/symmetry_class");

=head1 DESCRIPTION

This module provides functions for "canonicalizing" a molecular structure; that
is, to number the atoms in a unique way regardless of the input order.

The canonicalization algorithm is based on: Weininger, et. al., J. Chem. Inf.
Comp. Sci. 29[2], 97-101 (1989)

This module is part of the PerlMol project, L<http://www.perlmol.org/>.

=head1 ATOM ATTRIBUTES

During the canonicalization process, the following attributes are set on each
atom:

=over

=item canon/class

The unique canonical number; it is an integer going from 1 to the number of
atoms.

=item canon/symmetry_class

The symmetry class number. Atoms that have the same symmetry class are
considered to be topologicaly equivalent. For example, the two methyl carbons
on 2-propanol would have the same symmetry class.

=back

=head1 FUNCTIONS

These functions may be exported, although nothing is exported by default.

=over

=cut

my @PRIMES = qw( 1
      2      3      5      7     11     13     17     19     23     29 
     31     37     41     43     47     53     59     61     67     71 
     73     79     83     89     97    101    103    107    109    113 
    127    131    137    139    149    151    157    163    167    173 
    179    181    191    193    197    199    211    223    227    229 
    233    239    241    251    257    263    269    271    277    281 
    283    293    307    311    313    317    331    337    347    349 
    353    359    367    373    379    383    389    397    401    409 
    419    421    431    433    439    443    449    457    461    463 
    467    479    487    491    499    503    509    521    523    541 
    547    557    563    569    571    577    587    593    599    601 
    607    613    617    619    631    641    643    647    653    659 
    661    673    677    683    691    701    709    719    727    733 
    739    743    751    757    761    769    773    787    797    809 
    811    821    823    827    829    839    853    857    859    863 
    877    881    883    887    907    911    919    929    937    941 
    947    953    967    971    977    983    991    997   1009   1013 
   1019   1021   1031   1033   1039   1049   1051   1061   1063   1069 
   1087   1091   1093   1097   1103   1109   1117   1123   1129   1151 
   1153   1163   1171   1181   1187   1193   1201   1213   1217   1223
   1229   1231   1237   1249   1259   1277   1279   1283   1289   1291
   1297   1301   1303   1307   1319   1321   1327   1361   1367   1373
   1381   1399   1409   1423   1427   1429   1433   1439   1447   1451
   1453   1459   1471   1481   1483   1487   1489   1493   1499   1511
   1523   1531   1543   1549   1553   1559   1567   1571   1579   1583
   1597   1601   1607   1609   1613   1619   1621   1627   1637   1657
   1663   1667   1669   1693   1697   1699   1709   1721   1723   1733
   1741   1747   1753   1759   1777   1783   1787   1789   1801   1811
   1823   1831   1847   1861   1867   1871   1873   1877   1879   1889
   1901   1907   1913   1931   1933   1949   1951   1973   1979   1987
   1993   1997   1999   2003   2011   2017   2027   2029   2039   2053
   2063   2069   2081   2083   2087   2089   2099   2111   2113   2129
   2131   2137   2141   2143   2153   2161   2179   2203   2207   2213
   2221   2237   2239   2243   2251   2267   2269   2273   2281   2287
   2293   2297   2309   2311   2333   2339   2341   2347   2351   2357
   2371   2377   2381   2383   2389   2393   2399   2411   2417   2423
   2437   2441   2447   2459   2467   2473   2477   2503   2521   2531
   2539   2543   2549   2551   2557   2579   2591   2593   2609   2617
   2621   2633   2647   2657   2659   2663   2671   2677   2683   2687
   2689   2693   2699   2707   2711   2713   2719   2729   2731   2741
   2749   2753   2767   2777   2789   2791   2797   2801   2803   2819
   2833   2837   2843   2851   2857   2861   2879   2887   2897   2903
   2909   2917   2927   2939   2953   2957   2963   2969   2971   2999
);

=item canonicalize($mol, %opts)

Canonicalizes the molecule. It adds the canon/class and canon/symmetry class to
every atom, as discussed above. This function may take the following options:

=over

=item sort

If true, sort the atoms in the molecule in ascending canonical number order.

=item invariants

This should be a subroutine reference that takes an atom and returns a number.
These number should be based on the topological invariant properties of the
atom, such as symbol, charge, number of bonds, etc.

=back

=cut

sub canonicalize {
    my ($mol, %opts) = @_;

    if ($mol->atoms > @PRIMES - 1) {
        croak "maximum number of atoms exceeded for canonicalization\n";
    }

    my $invariants_sub = $opts{invariants} || \&atom_invariants;

    # set up initial classes
    for my $atom ($mol->atoms) {
        $atom->attr("canon/class", $invariants_sub->($atom));
        $atom->attr("canon/prev_class", 1);
    }
    #printf "$_: %s\n", $_->attr("canon/class") for $mol->atoms;

    # run one canonicalization step
    my $atoms;
    my $n_classes;
    ($atoms, $n_classes) = rank_classes($mol);
    ($atoms, $n_classes) = canon($mol, $n_classes);
    my $n_atom = $mol->atoms;

    # atoms with the same class are topologically symmetric
    for my $atom ($mol->atoms) {
        $atom->attr("canon/symmetry_class", $atom->attr("canon/class"));
    }
    #printf "$_: %s\n", $_->attr("canon/class") for $mol->atoms;

    # break symmetry to get a canonical numbering
    while ($n_classes < $n_atom) {

        # multiply all classes by 2
        for my $atom (@$atoms) {
            my $class = $atom->attr("canon/class");
            $atom->attr("canon/class", $class * 2); 
        }

        # break first tie
        my $last_class = -1;
        my $last_atom;
        for my $atom (@$atoms) {
            my $class = $atom->attr("canon/class");
            if ($class == $last_class) { # tie
                #print "breaking tie for $last_atom\n";
                $last_atom->attr("canon/class", $class - 1);
                last;
            }
            $last_class = $class;
            $last_atom  = $atom;
        }
        #printf "$_: %s\n", $_->attr("canon/class") for $mol->atoms;
        #print "---\n";

        # run another canonicalization step
        ($atoms, $n_classes) = canon($mol, $n_classes);
        #printf "$_: %s\n", $_->attr("canon/class") for $mol->atoms;
    }
    if ($opts{'sort'}) {
        $mol->sort_atoms( 
            sub { $_[0]->attr("canon/class") <=> $_[1]->attr("canon/class") } 
        );
    }
    # clean up temporary classes
    $_->del_attr("canon/new_class") for $mol->atoms;
    $n_classes;
}

sub atom_invariants {
    no warnings 'uninitialized';
    my ($atom) = @_;
    my $n_bonds = $atom->bonds;
    my $valence = 0;
    #$valence += $_->order for $atom->bonds;
    for ($atom->bonds) {
        $valence += $_->order if defined $_
    }
    my $Z = $atom->Z;
    my $q = $atom->formal_charge + 5;
    return $n_bonds*10_000 + $valence*1000 + $q*100 + $Z;
}

# atom class comparison function. Only compare the class if the 
# previous classes are equal
sub _cmp {
    $a->attr("canon/prev_class") <=> $b->attr("canon/prev_class")
    or $a->attr("canon/class") <=> $b->attr("canon/class")
}

sub rank_classes {
    my ($mol) = @_;
    my @atoms = sort _cmp $mol->atoms; # consider Schwartzian transform?
    my $n = 0;
    local ($a, $b);
    for $b (@atoms) {
        $n++ if (!$a || _cmp);
        $a = $b;
        $b->attr("canon/new_class", $n);
    }
    #use diagnostics;
    for my $atom (@atoms) {
        $atom->attr("canon/class", $atom->attr("canon/new_class"));
    }
    (\@atoms, $n);
}

sub canon {
    my ($mol, $n) = @_;

    my $old_classes = 0;
    my $n_atom = $mol->atoms;
    my $atoms;
    while ($n > $old_classes and $n < $n_atom) {
        $old_classes = $n;
        # save current classes
        for my $atom ($mol->atoms) {
            $atom->attr("canon/prev_class", $atom->attr("canon/class"));
        }

        # set new class to product of neighbor's primes
        for my $atom ($mol->atoms) {
            my $class = Math::BigInt->new('1');
            #my $class = 1;
            for my $neighbor ($atom->neighbors) {
                $class *= $PRIMES[$neighbor->attr("canon/prev_class")];
            }
            #print "$class\n";
            $atom->attr("canon/class", $class);
        }
        ($atoms, $n) = rank_classes($mol);
    }
    ($atoms, $n);
}

1;

=back

=head1 VERSION

0.11

=head1 TO DO

Add some tests.

=head1 CAVEATS

Currently there is an atom limit of about 430 atoms.

These algorithm is known to fail to discriminate between non-equivalent atoms
for some complicated cases. These are usually highly bridged structures
explicitly designed to break canonicalization algorithms; I don't know of any
"real-looking structure" (meaning something that someone would actually
synthesize or find in nature) that fails, but don't say I didn't warn you!

=head1 SEE ALSO

L<Chemistry::Mol>, L<Chemistry::Atom>, L<Chemistry::Obj>,
L<http://www.perlmol.org/>.

=head1 AUTHOR

Ivan Tubert E<lt>itub@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2009 Ivan Tubert. All rights reserved. This program is free
software; you can redistribute it and/or modify it under the same terms as
Perl itself.

=cut

