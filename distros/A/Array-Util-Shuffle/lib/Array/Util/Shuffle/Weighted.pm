package Array::Util::Shuffle::Weighted;

#use 5.010001;
use strict;
use warnings;

use Exporter qw(import);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-07-02'; # DATE
our $DIST = 'Array-Util-Shuffle'; # DIST
our $VERSION = '0.004'; # VERSION

our @EXPORT_OK = qw(shuffle);

sub shuffle {
    require Array::Sample::WeightedRandom;

    my ($ary, $opts) = @_;
    $opts //= {};

    Array::Sample::WeightedRandom::sample_weighted_random_no_replacement($ary, scalar(@$ary));
}

1;
# ABSTRACT: Shuffle an array, with weighting options

__END__

=pod

=encoding UTF-8

=head1 NAME

Array::Util::Shuffle::Weighted - Shuffle an array, with weighting options

=head1 VERSION

This document describes version 0.004 of Array::Util::Shuffle::Weighted (from Perl distribution Array-Util-Shuffle), released on 2022-07-02.

=head1 SYNOPSIS

=head1 FUNCTIONS

=head2 shuffle

Shuffle an array, with weighting options.

Usage:

 shuffle(\@ary [ , \%opts ]

Given array reference (C<\@ary>), shuffle it. Each array element must be a
2-element arrayref C<< [$val, $weight] >>. The greater the weight, the greater
the chance that the value will be shuffled into the beginning of the array.

Will return the shuffled values (without the weights).

Known options:

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Array-Util-Shuffle>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Array-Util-Shuffle>.

=head1 SEE ALSO

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Array-Util-Shuffle>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
