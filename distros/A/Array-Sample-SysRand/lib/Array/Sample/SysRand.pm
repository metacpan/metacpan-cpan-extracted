package Array::Sample::SysRand;

our $DATE = '2017-06-17'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(sample_sysrand);

sub sample_sysrand {
    my ($ary, $n, $opts) = @_;
    $opts //= {};

    return () if $n < 1 || @$ary < 1;

    my $k = @$ary / $n;
    my $idx = rand() * @$ary;

    my @res;
    for my $i (1..$n) {
        push @res, $opts->{pos} ? int($idx) : $ary->[int($idx)];
        $idx += $k;
        $idx -= @$ary if $idx >= @$ary;
    }

    @res;
}

1;
# ABSTRACT: Systematic random sampling from an array

__END__

=pod

=encoding UTF-8

=head1 NAME

Array::Sample::SysRand - Systematic random sampling from an array

=head1 VERSION

This document describes version 0.001 of Array::Sample::SysRand (from Perl distribution Array-Sample-SysRand), released on 2017-06-17.

=head1 SYNOPSIS

 use Array::Sample::SysRand qw(sample_sysrand);

 sample_partition([0,1,2,3,4,5,6,7,8,9], 5); => (5, 7, 9, 1, 3)

=head1 DESCRIPTION

=head1 FUNCTIONS

All functions are not exported by default, but exportable.

=head2 sample_sysrand

Syntax: sample_sysrand(\@ary, $n [ , \%opts ]) => list

Options:

=over

=item * pos => bool

If set to true, will return positions instead of the elements.

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Array-Sample-SysRand>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Array-Sample-SysRand>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Array-Sample-SysRand>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Array::Sample::Partition>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
