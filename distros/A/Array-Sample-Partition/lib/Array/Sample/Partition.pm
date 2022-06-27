package Array::Sample::Partition;

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-05-20'; # DATE
our $DIST = 'Array-Sample-Partition'; # DIST
our $VERSION = '0.003'; # VERSION

our @EXPORT_OK = qw(sample_partition);

sub sample_partition {
    my ($ary, $n, $opts) = @_;
    $opts //= {};

    $n = @$ary if $n > @$ary;

    my @res;
    for my $i (1..$n) {
        my $idx = int($i*@$ary/($n+1));
        push @res, $opts->{pos} ? $idx : $ary->[$idx];
    }

    @res;
}

1;
# ABSTRACT: Sample elements from an array by equal partitions

__END__

=pod

=encoding UTF-8

=head1 NAME

Array::Sample::Partition - Sample elements from an array by equal partitions

=head1 VERSION

This document describes version 0.003 of Array::Sample::Partition (from Perl distribution Array-Sample-Partition), released on 2022-05-20.

=head1 SYNOPSIS

 use Array::Sample::Partition qw(sample_partition);

 sample_partition([0,1,2,3,4], 1); => (2)
 sample_partition([0,1,2,3,4], 2); => (1,3)
 sample_partition([0,1,2,3,4], 3); => (1,2,3)

 sample_partition([0,1,2,3,4,5], 1); => (3)
 sample_partition([0,1,2,3,4,5], 2); => (2,4)
 sample_partition([0,1,2,3,4,5], 3); => (1,3,4)
 sample_partition([0,1,2,3,4,5], 4); => (1,2,3,4)

=head1 DESCRIPTION

=head1 FUNCTIONS

All functions are not exported by default, but exportable.

=head2 sample_partition

Syntax: sample_partition(\@ary, $n [ , \%opts ]) => list

Options:

=over

=item * pos => bool

If set to true, will return positions instead of the elements.

=back

The function takes an array reference (C<\@ary>) and number of samples to take
(C<$n>). It will first divide the array into C<$n>+1 of (whenever possible)
equal-sized partitions, leaving an element between partitions, then get the
elements between the partitions.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Array-Sample-Partition>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Array-Sample-Partition>.

=head1 SEE ALSO

Other sampling methods: L<Array::Sample::SysRand>,
L<Array::Sample::SimpleRandom>, L<Array::Sample::WeightedRandom>.

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

This software is copyright (c) 2022, 2017 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Array-Sample-Partition>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
