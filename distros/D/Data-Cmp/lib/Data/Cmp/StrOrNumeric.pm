package Data::Cmp::StrOrNumeric;

our $DATE = '2021-04-12'; # DATE
our $VERSION = '0.010'; # VERSION

use 5.010001;
use strict;
use warnings;

use Scalar::Util qw(looks_like_number blessed reftype refaddr);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(cmp_data);

our $EPSILON;

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
        my $lln1 = looks_like_number($d1);
        my $lln2 = looks_like_number($d2);
        if ($lln1 && $lln2) {
            if (defined $EPSILON && abs($d1 - $d2) < $EPSILON) {
                return 0;
            } else {
                return $d1 <=> $d2;
            }
        } else {
            return $d1 cmp $d2;
        }
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
# ABSTRACT: Compare two data structures, return -1/0/1 like cmp or <=>

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Cmp::StrOrNumeric - Compare two data structures, return -1/0/1 like cmp or <=>

=head1 VERSION

This document describes version 0.010 of Data::Cmp::StrOrNumeric (from Perl distribution Data-Cmp), released on 2021-04-12.

=head1 SYNOPSIS

 use Data::Cmp::StrOrNumeric qw(cmp_data);

 cmp_data(["a", "b", "c"], ["a", "b", "d"]);            # => -1
 cmp_data([0, 1, 10], [0, 1, 9]);                       # => 1

Contrasted with L<Data::Cmp>:

 use Data::Cmp ();

 Data::Cmp::cmp_data(["a", "b", "c"], ["a", "b", "d"]); # => -1
 Data::Cmp::cmp_data([0, 1, 10], [0, 1, 9]);            # => -1

Perform numeric comparison with some tolerance:

 {
     local $Data::Cmp::StrOrNumeric::EPSILON = 1e-3;
     cmp_data(1, 1.1   );     # -1
     cmp_data(1, 1.0001);     #  0
     cmp_data([1], [1.0001]); #  0
 }

=head1 DESCRIPTION

=head1 VARIABLES

=head2 $EPSILON

Can be set to perform numeric comparison with some tolerance. See example in
Synopsis.

=head1 FUNCTIONS

=head2 cmp_data

Usage:

 cmp_data($d1, $d2) => -1/0/1/2

This module's C<cmp_data()> is just like L<Data::Cmp>'s except that when the two
non-references being compared look like number (tested using L<Scalar::Util>'s
C<looks_like_number()>, they are compared with C<< <=> >> instead of C<cmp>. If
none or only one of the non-reference is a number, C<cmp> is used like in
Data::Cmp.

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

L<Data::Cmp>

L<Data::Cmp::Numeric>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2019, 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
