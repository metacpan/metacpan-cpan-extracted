package Array::Sample::SimpleRandom;

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-05-20'; # DATE
our $DIST = 'Array-Sample-SimpleRandom'; # DIST
our $VERSION = '0.001'; # VERSION

our @EXPORT_OK = qw(sample_simple_random_with_replacement
                    sample_simple_random_no_replacement);

sub sample_simple_random_with_replacement {
    my ($ary, $n, $opts) = @_;
    $opts //= {};

    return () unless @$ary;

    my @res;
    for my $i (1..$n) {
        my $idx = int(rand(@$ary));
        push @res, $opts->{pos} ? $idx : $ary->[$idx];
    }

    @res;
}

sub sample_simple_random_no_replacement {
    my ($ary, $n, $opts) = @_;
    $opts //= {};

    $n = @$ary if $n > @$ary;
    my @ary_copy = @$ary;
    my @pos      = 0 .. $#ary_copy;

    my @res;
    for my $i (1..$n) {
        my $idx = int(rand(@ary_copy));
        push @res, $opts->{pos} ? $pos[$idx] : $ary_copy[$idx];
        splice @ary_copy, $idx, 1;
        splice @pos     , $idx, 1;
    }

    @res;
}

1;
# ABSTRACT: Sample elements randomly (with or without replacement)

__END__

=pod

=encoding UTF-8

=head1 NAME

Array::Sample::SimpleRandom - Sample elements randomly (with or without replacement)

=head1 VERSION

This document describes version 0.001 of Array::Sample::SimpleRandom (from Perl distribution Array-Sample-SimpleRandom), released on 2022-05-20.

=head1 SYNOPSIS

 use Array::Sample:: qw(sample_simple_random_with_replacement sample_simple_random_no_replacement);

 sample_simple_random_with_replacement([0,1], 1); => (0)
 sample_simple_random_with_replacement([0,1], 3); => (0,1,0)

 sample_simple_random_no_replacement([0,1,2,3,4], 1); => (3)
 sample_simple_random_no_replacement([0,1,2,3,4], 3); => (2,1,4)
 sample_simple_random_no_replacement([0,1,2,3,4], 7); => (3,4,2,1,0)

=head1 DESCRIPTION

=head1 FUNCTIONS

All functions are not exported by default, but exportable.

=head2 sample_simple_random_with_replacement

Syntax: sample_simple_random_with_replacement(\@ary, $n [ , \%opts ]) => list

Options:

=over

=item * pos => bool

If set to true, will return positions instead of the elements.

=back

The function takes an array reference (C<\@ary>) and number of samples to take
(C<$n>). It will take samples at random position. An element can be picked more
than once.

=head2 sample_simple_random_no_replacement

Syntax: sample_simple_random_no_replacement(\@ary, $n [ , \%opts ]) => list

Options:

=over

=item * pos => bool

If set to true, will return positions instead of the elements.

=back

The function takes an array reference (C<\@ary>) and number of samples to take
(C<$n>). It will take samples at random position. An element can only be epicked
once. If C<$n> is larger than the number of elements in the array, only that
many elements will be taken.

The implementation constructs a (shallow) copy of the array then remove elements
randomly from the copy-array until the number of requested samples are met.
There is another implementation that avoids creating a copy but scans the array
once; see L<Array::Sample::SimpleRandom::Scan>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Array-Sample-SimpleRandom>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Array-Sample-SimpleRandom>.

=head1 SEE ALSO

Other sampling methods: L<Array::Sample::SysRand>, L<Array::Sample::Partition>.

L<Array::Sample::SimpleRandom::Scan>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Array-Sample-SimpleRandom>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
