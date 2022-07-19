package Array::Util::Shuffle;

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-07-02'; # DATE
our $DIST = 'Array-Util-Shuffle'; # DIST
our $VERSION = '0.004'; # VERSION

our @EXPORT_OK = qw(shuffle);

sub shuffle {
    my ($ary0, $opts) = @_;
    $opts //= {};

    my $ary = $opts->{inplace} ? $ary0 : [@$ary0];

    for (my $i = $#{$ary}; $i >= 1; $i--) {
        my $j = int rand($i + 1);
        @{$ary}[$i, $j] = @{$ary}[$j, $i];
    }

    if ($opts->{inplace}) {
        return $ary;
    } else {
        return @$ary;
    }
}

1;
# ABSTRACT: Shuffle an array

__END__

=pod

=encoding UTF-8

=head1 NAME

Array::Util::Shuffle - Shuffle an array

=head1 VERSION

This document describes version 0.004 of Array::Util::Shuffle (from Perl distribution Array-Util-Shuffle), released on 2022-07-02.

=head1 SYNOPSIS

 use Array::Util::Shuffle qw(shuffle);

 my @myarray = (1..10);
 my @shuffled = shuffle(\@myarray);

 # shuffle inplace
 shuffle(\@myarray, {inplace=>1});

=head1 DESCRIPTION

This module provides C<shuffle()> to shuffle an array using the standard
Fisher-Yates algorithm, like that implemented in L<List::Util> or
L<List::MoreUtils>. It accepts an arrayref instead of a list and can be
instructed to shuffle the array in-place. There will be more options provided in
the future.

=head1 FUNCTIONS

=head2 shuffle

Shuffle an array.

Usage:

 shuffle(\@ary [ , \%opts ]);

Given an array reference (C<\@ary>), will return the shuffled list.

Options:

=over

=item * inplace

Bool. If set to true, will modify the array in-place and return the array
reference, instead of returning the shuffled list.

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Array-Util-Shuffle>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Array-Util-Shuffle>.

=head1 SEE ALSO

The Fisher-Yates shuffle algorithm described by Durstenfeld, 1964.

L<Algorithm::Numerical::Shuffle>, L<Array::Shuffle>, and a few others like
L<List::MoreUtils::PP>'s C<samples> do the same thing.

Modules that provide a random-sampling-without-replacement function can also be
used to shuffle. Shuffling is basically random total sampling. These modules
include L<List::Util> (C<sample>), L<List::MoreUtils> (L<samples>),
L<Array::Sample::SimpleRandom>.

L<Array::Util::Shuffle::Weighted>

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
