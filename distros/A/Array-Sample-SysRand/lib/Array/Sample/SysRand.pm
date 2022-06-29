package Array::Sample::SysRand;

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-05-20'; # DATE
our $DIST = 'Array-Sample-SysRand'; # DIST
our $VERSION = '0.002'; # VERSION

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

This document describes version 0.002 of Array::Sample::SysRand (from Perl distribution Array-Sample-SysRand), released on 2022-05-20.

=head1 SYNOPSIS

 use Array::Sample::SysRand qw(sample_sysrand);

 sample_sysrand([0,1,2,3,4,5,6,7,8,9], 5); => (5, 7, 9, 1, 3)
 sample_sysrand([0,1,2,3,4,5,6,7,8,9], 5); => (2, 4, 6, 8, 0)

 sample_sysrand([0,1,2,3,4,5,6,7,8,9], 3); => (2, 6, 9)
 sample_sysrand([0,1,2,3,4,5,6,7,8,9], 3); => (4, 8, 1)

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

The function takes an array reference (C<\@ary>) and the number of samples
requested (C<$n>) and will return a list of samples. It will start from a random
position to get the first sample then jump at fixed interval to get the
subsequent ones.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Array-Sample-SysRand>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Array-Sample-SysRand>.

=head1 SEE ALSO

About systematic (random) sampling:
L<https://www.investopedia.com/terms/s/systematic-sampling.asp>

Other sampling methods: L<Array::Sample::Partition>,
L<Array::Sample::SimpleRandom>

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Array-Sample-SysRand>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
