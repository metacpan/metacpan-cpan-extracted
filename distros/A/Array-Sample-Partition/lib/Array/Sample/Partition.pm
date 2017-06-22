package Array::Sample::Partition;

our $DATE = '2017-06-14'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);
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

This document describes version 0.001 of Array::Sample::Partition (from Perl distribution Array-Sample-Partition), released on 2017-06-14.

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

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Array-Sample-Partition>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Array-Sample-Partition>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Array-Sample-Partition>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Array::Sample::SysRand>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
