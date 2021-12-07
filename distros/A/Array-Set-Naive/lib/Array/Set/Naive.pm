package Array::Set::Naive;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-05-15'; # DATE
our $DIST = 'Array-Set-Naive'; # DIST
our $VERSION = '0.001'; # VERSION

use strict;
use warnings;

# not yet used, problem with hang during build
#use List::Keywords qw(any);
use List::Util qw(any);

use Exporter qw(import);
our @EXPORT_OK = qw(set_diff set_symdiff set_union set_intersect);

sub set_diff {
    my $opts = ref($_[0]) eq 'HASH' ? shift : {};

    my $set1 = @_ ? shift : [];
    my $res = $set1;
    while (@_) {
        my $set2 = shift;
        $res = [];
        for my $el (@$set1) {
            push @$res, $el unless any { $_ eq $el } @$set2;
            $set1 = $res;
        }
    }
    $res;
}

sub set_symdiff {
    my $opts = ref($_[0]) eq 'HASH' ? shift : {};

    my $res = [];
    for my $i (0..$#_) {
        my $set1 = $_[$i];
      ELEM:
        for my $el1 (@$set1) {
            next ELEM if any { $_ eq $el1 } @$res;
            for my $j (0..$#_) {
                next if $i == $j;
                my $set2 = $_[$j];
                next ELEM if any { $_ eq $el1 } @$set2;
            }
            push @$res, $el1;
        }
    }
    $res;
}

sub set_union {
    my $opts = ref($_[0]) eq 'HASH' ? shift : {};

    my $res = [];
    for my $set (@_) {
        for my $el (@$set) {
            push @$res, $el unless any { $_ eq $el } @$res;
        }
    }
    $res;
}

sub set_intersect {
    my $opts = ref($_[0]) eq 'HASH' ? shift : {};

    return [] unless @_;
    my $set1 = shift @_;
    my $res = [];
  EL:
    for my $el (@$set1) {
        for my $set (@_) {
            next EL unless any { $_ eq $el } @$set;
        }
        push @$res, $el;
    }
    $res;
}

1;
# ABSTRACT: Like Array::Set, but uses naive algorithms

__END__

=pod

=encoding UTF-8

=head1 NAME

Array::Set::Naive - Like Array::Set, but uses naive algorithms

=head1 VERSION

This document describes version 0.001 of Array::Set::Naive (from Perl distribution Array-Set-Naive), released on 2021-05-15.

=head1 SYNOPSIS

 use Array::Set::Naive qw(set_diff set_symdiff set_union set_intersect);

 set_diff([1,2,3,4], [2,3,4,5]);            # => [1]
 set_diff([1,2,3,4], [2,3,4,5], [3,4,5,6]); # => [1]

 set_symdiff([1,2,3,4], [2,3,4,5]);            # => [1,5]
 set_symdiff([1,2,3,4], [2,3,4,5], [3,4,5,6]); # => [1,6]

 set_union([1,3,2,4], [2,3,4,5]);            # => [1,3,2,4,5]
 set_union([1,3,2,4], [2,3,4,5], [3,4,5,6]); # => [1,3,2,4,5,6]

 set_intersect([1,2,3,4], [2,3,4,5]);            # => [2,3,4]
 set_intersect([1,2,3,4], [2,3,4,5], [3,4,5,6]); # => [3,4]

=head1 DESCRIPTION

This module is like L<Array::Set>, but instead of using hash (L<Tie::IxHash>) it
performs linear search. This module is mostly for testing only, including for
testing using L<List::Keywords> (note: this release does not use List::Keywords
yet due to problem in distro building).

=head1 FUNCTIONS

=head2 set_diff([ \%opts ], \@set1, ...) => array

Like Array::Set's, but no options are currently recognized.

=head2 set_symdiff([ \%opts ], \@set1, ...) => array

Like Array::Set's, but no options are currently recognized.

=head2 set_union([ \%opts ], \@set1, ...) => array

Like Array::Set's, but no options are currently recognized.

=head2 set_intersect([ \%opts ], \@set1, ...) => array

Like Array::Set's, but no options are currently recognized.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Array-Set-Naive>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Array-Set-Naive>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Array-Set-Naive>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Array::Set>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
