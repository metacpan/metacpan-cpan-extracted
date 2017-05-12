package Array::Set;

our $DATE = '2016-09-16'; # DATE
our $VERSION = '0.05'; # VERSION

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(set_diff set_symdiff set_union set_intersect);

sub _doit {
    my $op = shift;

    my $opts;
    if (ref($_[0]) eq 'HASH') {
        $opts = shift;
    } else {
        $opts = {};
    }

    require Tie::IxHash;
    tie my(%res), 'Tie::IxHash';

    my $ic  = $opts->{ignore_case};
    my $ib  = $opts->{ignore_blanks};
    my $ign = $ic || $ib;

    my $i = 0;
  SET:
    for my $i (1..@_) {
        my $set = $_[$i-1];

        if ($op eq 'union') {

            if ($ign) {
                for (@$set) {
                    my $k = $ic ? lc($_) : $_;
                    $k =~ s/\s+//g if $ib;
                    $res{$k} = $_ unless exists $res{$k};
                }
                # return result
                if ($i == @_) {
                    return [values %res];
                }
            } else {
                for (@$set) { $res{$_}++ }
                # return result
                if ($i == @_) {
                    return [keys %res];
                }
            }

        } elsif ($op eq 'intersect') {

            if ($ign) {
                if ($i == 1) {
                    for (@$set) {
                        my $k = $ic ? lc($_) : $_;
                        $k =~ s/\s+//g if $ib;
                        $res{$k} = [1,$_] unless exists $res{$k};
                    }
                } else {
                    for (@$set) {
                        my $k = $ic ? lc($_) : $_;
                        $k =~ s/\s+//g if $ib;
                        if ($res{$k} && $res{$k}[0] == $i-1) {
                            $res{$k}[0]++;
                        }
                    }
                }
                # return result
                if ($i == @_) {
                    return [map {$res{$_}[1]}
                                grep {$res{$_}[0] == $i} keys %res];
                }
            } else {
                if ($i == 1) {
                    for (@$set) { $res{$_} = 1 }
                } else {
                    for (@$set) {
                        if ($res{$_} && $res{$_} == $i-1) {
                            $res{$_}++;
                        }
                    }
                }
                # return result
                if ($i == @_) {
                    return [grep {$res{$_} == $i} keys %res];
                }
            }

        } elsif ($op eq 'diff') {

            if ($ign) {
                if ($i == 1) {
                    for (@$set) {
                        my $k = $ic ? lc($_) : $_;
                        $k =~ s/\s+//g if $ib;
                        $res{$k} = $_ unless exists $res{$k};
                    }
                } else {
                    for (@$set) {
                        my $k = $ic ? lc($_) : $_;
                        $k =~ s/\s+//g if $ib;
                        delete $res{$k};
                    }
                }
                # return result
                if ($i == @_) {
                    return [values %res];
                }
            } else {
                if ($i == 1) {
                    for (@$set) { $res{$_}++ }
                } else {
                    for (@$set) {
                        delete $res{$_};
                    }
                }
                # return result
                if ($i == @_) {
                    return [keys %res];
                }
            }

        } elsif ($op eq 'symdiff') {

            if ($ign) {
                if ($i == 1) {
                    for (@$set) {
                        my $k = $ic ? lc($_) : $_;
                        $k =~ s/\s+//g if $ib;
                        $res{$k} = [1,$_] unless exists $res{$k};
                    }
                } else {
                    for (@$set) {
                        my $k = $ic ? lc($_) : $_;
                        $k =~ s/\s+//g if $ib;
                        if (!$res{$k}) {
                            $res{$k} = [1, $_];
                        } elsif ($res{$k}[0] <= 2) {
                            $res{$k}[0]++;
                        }
                    }
                }
                # return result
                if ($i == @_) {
                    return [map {$res{$_}[1]}
                                grep {$res{$_}[0] == 1} keys %res];
                }
            } else {
                if ($i == 1) {
                    for (@$set) { $res{$_} = 1 }
                } else {
                    for (@$set) {
                        if (!$res{$_} || $res{$_} <= 2) {
                            $res{$_}++;
                        }
                    }
                }
                # return result
                if ($i == @_) {
                    return [grep {$res{$_} == 1} keys %res];
                }
            }

        }

    } # for set

    # caller does not specify any sets
    return [];
}

sub set_diff {
    my $opts = ref($_[0]) eq 'HASH' ? shift : {};
    if ($opts->{ignore_case} || $opts->{ignore_blanks}) {
        _doit('diff', $opts, @_);
    } else {
        # fast version, without ib/ic
        my $set1 = shift;
        my $res = $set1;
        while (@_) {
            my %set2 = map { $_=>1 } @{ shift @_ };
            $res = [];
            for my $el (@$set1) {
                push @$res, $el unless $set2{$el};
            }
            $set1 = $res;
        }
        $res;
    }
}

sub set_symdiff {
    my $opts = ref($_[0]) eq 'HASH' ? shift : {};
    if ($opts->{ignore_case} || $opts->{ignore_blanks}) {
        _doit('symdiff', $opts, @_);
    } else {
        # fast version, without ib/ic
        my $set1 = shift;
        my $res = $set1;
        my %set1;
        my %set2;
        while (@_) {
            my $set2 = shift;
            $set2{$_} = 1 for @$set2;
            $res = [];
            for my $el (@$set1) {
                push @$res, $el unless $set2{$el};
            }
            $set1{$_} = 1 for @$set1;
            for my $el (@$set2) {
                push @$res, $el unless $set1{$el};
            }
            $set1 = $res;
        }
        $res;
    }
}

sub set_union {
    my $opts = ref($_[0]) eq 'HASH' ? shift : {};
    if ($opts->{ignore_case} || $opts->{ignore_blanks}) {
        _doit('union', $opts, @_);
    } else {
        # fast version, without ib/ic
        my %mem;
        my $res = [];
        while (@_) {
            for my $el (@{ shift @_ }) {
                push @$res, $el unless $mem{$el}++;
            }
        }
        $res;
    }
}

sub set_intersect {
    my $opts = ref($_[0]) eq 'HASH' ? shift : {};
    if ($opts->{ignore_case} || $opts->{ignore_blanks}) {
        _doit('intersect', $opts, @_);
    } else {
        # fast version, without ib/ic
        my $set1 = shift;
        my $res = $set1;
        while (@_) {
            my %set2 = map { $_=>1 } @{ shift @_ };
            $res = [];
            for my $el (@$set1) {
                push @$res, $el if $set2{$el};
            }
            $set1 = $res;
        }
        $res;
    }
}

1;
# ABSTRACT: Perform set operations on arrays

__END__

=pod

=encoding UTF-8

=head1 NAME

Array::Set - Perform set operations on arrays

=head1 VERSION

This document describes version 0.05 of Array::Set (from Perl distribution Array-Set), released on 2016-09-16.

=head1 SYNOPSIS

 use Array::Set qw(set_diff set_symdiff set_union set_intersect);

 set_diff([1,2,3,4], [2,3,4,5]);            # => [1]
 set_diff([1,2,3,4], [2,3,4,5], [3,4,5,6]); # => [1]
 set_diff({ignore_case=>1}, ["a","b"], ["B","c"]);   # => ["a"]

 set_symdiff([1,2,3,4], [2,3,4,5]);            # => [1,5]
 set_symdiff([1,2,3,4], [2,3,4,5], [3,4,5,6]); # => [1,6]

 set_union([1,3,2,4], [2,3,4,5]);            # => [1,3,2,4,5]
 set_union([1,3,2,4], [2,3,4,5], [3,4,5,6]); # => [1,3,2,4,5,6]

 set_intersect([1,2,3,4], [2,3,4,5]);            # => [2,3,4]
 set_intersect([1,2,3,4], [2,3,4,5], [3,4,5,6]); # => [3,4]

=head1 DESCRIPTION

This module provides routines for performing set operations on arrays. Set is
represented as a regular Perl array. All comparison is currently done with C<eq>
(string comparison) so currently no support for references/objects/undefs. You
have to make sure that the arrays do not contain duplicates/undefs.

Characteristics and differences with other similar modules:

=over

=item * simple functional (non-OO) interface

=item * functions accept more than two arguments

=item * option to do case-insensitive comparison

=item * option to ignore blanks

=item * preserves ordering

=back

=head1 FUNCTIONS

All functions are not exported by default, but exportable.

=head2 set_diff([ \%opts ], \@set1, ...) => array

Perform difference (find elements in the first set not in the other sets).
Accept optional hashref as the first argument for options. Known options:

=over

=item * ignore_case => bool (default: 0)

If set to 1, will perform case-insensitive comparison.

=item * ignore_blanks => bool (default: 0)

If set to 1, will ignore blanks (C<" foo"> == C<"foo"> == C<"f o o">).

=back

=head2 set_symdiff([ \%opts ], \@set1, ...) => array

Perform symmetric difference (find elements in the first set not in the other
set, as well as elements in the other set not in the first). Accept optional
hashref as the first argument for options. See C<set_diff> for known options.

=head2 set_union([ \%opts ], \@set1, ...) => array

Perform union (find elements in the first or in the other, duplicates removed).
Accept optional hashref as the first argument for options. See C<set_diff> for
known options.

=head2 set_intersect([ \%opts ], \@set1, ...) => array

Perform intersection (find elements common in all the sets). Accept optional
hashref as the first argument for options. See C<set_diff> for known options.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Array-Set>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Array-Set>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Array-Set>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

See some benchmarks in L<Bencher::Scenarios::ArraySet>.

L<App::setop> to perform set operations on lines of files on the command-line.

L<Array::Utils>, L<Set::Scalar>, L<List::MoreUtils> (C<uniq> for union,
C<singleton> for symmetric diff), L<Set::Array>, L<Array::AsObject>,
L<Set::Object>, L<Set::Tiny>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
