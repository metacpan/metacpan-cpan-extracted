package Data::Cmp;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-04-12'; # DATE
our $DIST = 'Data-Cmp'; # DIST
our $VERSION = '0.010'; # VERSION

use 5.010001;
use strict;
use warnings;

use Scalar::Util qw(blessed reftype refaddr);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(cmp_data);

# for when dealing with circular refs
my %_seen_refaddrs;

sub _cmp_data {
    my $d1 = shift;
    my $d2 = shift;

    my $def1 = defined $d1;
    my $def2 = defined $d2;
    if ($def1) {
        return 1 if !$def2;
    } else {
        return $def2 ? -1 : 0;
    }

    # so both are defined ...

    my $reftype1 = reftype($d1);
    my $reftype2 = reftype($d2);
    if (!$reftype1 && !$reftype2) {
        return $d1 cmp $d2;
    } elsif ( $reftype1 xor $reftype2) { return 2 }

    # so both are refs ...

    return 2 if $reftype1 ne $reftype2;

    # so both are refs of the same type ...

    my $pkg1 = blessed($d1);
    my $pkg2 = blessed($d2);
    if (defined $pkg1) {
        return 2 unless defined $pkg2 && $pkg1 eq $pkg2;
    } else {
        return 2 if defined $pkg2;
    }

    # so both are non-objects or objects of the same class ...

    my $refaddr1 = refaddr($d1);
    my $refaddr2 = refaddr($d2);

    if ($reftype1 eq 'ARRAY' && !$_seen_refaddrs{$refaddr1} && !$_seen_refaddrs{$refaddr2}) {
        $_seen_refaddrs{$refaddr1}++;
        $_seen_refaddrs{$refaddr2}++;
      ELEM:
        for my $i (0..($#{$d1} < $#{$d2} ? $#{$d1} : $#{$d2})) {
            my $cmpres = _cmp_data($d1->[$i], $d2->[$i]);
            return $cmpres if $cmpres;
        }
        return $#{$d1} <=> $#{$d2};
    } elsif ($reftype1 eq 'HASH' && !$_seen_refaddrs{$refaddr1} && !$_seen_refaddrs{$refaddr2}) {
        $_seen_refaddrs{$refaddr1}++;
        $_seen_refaddrs{$refaddr2}++;
        my $nkeys1 = keys %$d1;
        my $nkeys2 = keys %$d2;
      KEY:
        for my $k (sort keys %$d1) {
            unless (exists $d2->{$k}) { return $nkeys1 <=> $nkeys2 || 2 }
            my $cmpres = _cmp_data($d1->{$k}, $d2->{$k});
            return $cmpres if $cmpres;
        }
        return $nkeys1 <=> $nkeys2;
    } else {
        return $refaddr1 == $refaddr2 ? 0 : 2;
    }
}

sub cmp_data {
    my $d1 = shift;
    my $d2 = shift;

    %_seen_refaddrs = ();
    _cmp_data($d1, $d2);
}

1;
# ABSTRACT: Compare two data structures, return -1/0/1 like cmp

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Cmp - Compare two data structures, return -1/0/1 like cmp

=head1 VERSION

This document describes version 0.010 of Data::Cmp (from Perl distribution Data-Cmp), released on 2021-04-12.

=head1 SYNOPSIS

 use Data::Cmp qw(cmp_data);

 cmp_data(["one", "two", "three"],
          ["one", "two", "three"]); # => 0

 cmp_data(["one", "two" , "three"],
          ["one", "two2", "three"]); # => -1

 cmp_data(["one", "two", "three"],
          ["one", "TWO", "three"]); # => 1

 # hash/array is not "comparable" with scalar
 cmp_data(["one", "two", {}],
          ["one", "two", "three"]); # => 2

Sort data structures (of similar structures):

 my @arrays = (["c"], ["b"], ["a", "b"], ["a"], ["a","c"]);
 my @sorted = sort { cmp_data($a, $b) } @arrays; # => (["a"], ["a","b"], ["a","c"], ["b"], ["c"])

=head1 DESCRIPTION

This relatively lightweight (no non-core dependencies, under 100 lines of code)
module offers the C<cmp_data> function that, like Perl's C<cmp>, returns -1/0/1
value. C<cmp_data> differs from C<cmp> in that it can compare two data of
different types and compare data items recursively, with pretty sensible
semantics. In addition to returning -1/0/1, C<cmp_data> can also return 2 if two
data differ but not comparable: there is no sensible notion of which one is
"greater than" the other. An example is empty hash C<{}> vs empty array C<[]>).

This module can handle circular structure.

The following are the rules of comparison used by C<cmp_data()>:

=over

=item * Two undefs are the same

 cmp_data(undef, undef); # 0

=item * A defined value is greater than undef

 cmp_data(undef, 0); # -1

=item * Two non-reference scalars are compared string-wise using Perl's cmp

 cmp_data("a", "A"); # 1
 cmp_data(10, 9);    # -1

=item * A reference and non-reference are different and not comparable

 cmp_data([], 0); # 2

=item * Two references that are of different types are different and not comparable

 cmp_data([], {}); # 2

=item * Blessed references that are blessed into different packages are different and not comparable

 cmp_data(bless([], "foo"), bless([], "bar")); # 2
 cmp_data(bless([], "foo"), bless([], "foo")); # 0

=item * Two array references are compared element by element (unless at least one of the arrayref has been seen, in which case see last rule)

 cmp_data(["a","b","c"], ["a","b","c"]); #  0
 cmp_data(["a","b","c"], ["a","b","d"]); # -1
 cmp_data(["a","d","c"], ["a","b","e"]); #  1

=item * A longer arrayref is greater than its shorter subset

 cmp_data(["a","b"], ["a"]); # 1

=item * Two hash references are compared key by key (unless at least one of the hashref has been seen, in which case see last rule)

 cmp_data({k1=>"a", k2=>"b", k3=>"c"}, {k1=>"a", k2=>"b", k3=>"c"}); # 0
 cmp_data({k1=>"a", k2=>"b", k3=>"c"}, {k1=>"a", k2=>"b", k3=>"d"}); # 1

=item * When two hash references share a common subset of pairs but have non-common pairs, the greater hashref is the one that has more non-common pairs

If the number of non-common pairs are the same, they are just different and not
comparable:

 cmp_data({k1=>"", k2=>"", k3=>""}, {k1=>"", k5=>""});                #  1 (hash1 has 2 non-common keys: k2 & k3; hash2 only has 1: k5)
 cmp_data({k1=>"", k2=>"", k3=>""}, {k1=>"", k5=>"", k6=>", k7=>""}); # -1 (hash1 has 2 non-common keys: k2 & k3; hash2 has 3 non-common pairs: k5, k6, k7)
 cmp_data({k1=>"", k2=>"", k3=>""}, {k1=>"", k5=>"", k6=>"});         #  2 (both hashes have 2 non-common pairs)

=item * All other types of references (i.e. non-hash, non-array) are the same only if their address is the same; otherwise they are different and not comparable

 cmp_data(\1, \1); # 2
 my $ref = \1; cmp_data($ref, $ref); # 0

=item * A seen (hash or array) reference is no longer recursed, it's compared by address (see previous rule)

 my $ary1 = [1]; push @$ary1, $ary1;
 my $ary2 = [1]; push @$ary2, $ary2;
 my $ary3 = [1]; push @$ary3, $ary1;
 cmp_data($ary1, $ary2); # 2
 cmp_data($ary1, $ary3); # 0

=back

=head1 FUNCTIONS

=head2 cmp_data

Usage:

 cmp_data($d1, $d2) => -1/0/1/2

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Cmp>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Cmp>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-Data-Cmp/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head2 Data comparison

Other variants of Data::Cmp: L<Data::Cmp::Numeric>, L<Data::Cmp::StrOrNumeric>,
L<Data::Cmp::Custom> (allows custom actions and comparison routines),
L<Data::Cmp::Diff> (generates diff structure instead of just returning
-1/0/1/2), L<Data::Cmp::Diff::Perl> (generates diff in the form of Perl code).

Modules that just return boolean result ("same or different"): L<Data::Compare>,
L<Test::Deep::NoTest> (offers flexibility or approximate or custom comparison).

Modules that return some kind of "diff" data: L<Data::Comparator>,
L<Data::Diff>.

Of course, to check whether two structures are the same you can also serialize
each one then compare the serialized strings/bytes. There are many modules for
serialization: L<JSON>, L<YAML>, L<Sereal>, L<Data::Dumper>, L<Storable>,
L<Data::Dmp>, just to name a few.

Test modules that do data structure comparison: L<Test::DataCmp> (test module
based on Data::Cmp::Custom), L<Test::More> (C<is_deeply()>), L<Test::Deep>,
L<Test2::Tools::Compare>.

=head2 Others

L<Scalar::Cmp> which employs roughly the same rules as Data::Cmp but does not
recurse into arrays/hashes and is meant to compare two scalar values.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2019, 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
