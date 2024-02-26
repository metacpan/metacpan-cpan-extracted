package Comparer::by_similarity;

use 5.010001;
use strict;
use warnings;

use Text::Levenshtein::XS;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-01-24'; # DATE
our $DIST = 'Comparer-by_similarity'; # DIST
our $VERSION = '0.001'; # VERSION

sub meta {
    return +{
        v => 1,
        args => {
            string => {schema=>'str*', req=>1},
            reverse => {schema => 'bool*'},
            ci => {schema => 'bool*'},
        },
    };
}

sub gen_comparer {
    my %args = @_;

    my $reverse = $args{reverse};
    my $ci = $args{ci};

    sub {
        (
            $args{ci} ? (Text::Levenshtein::XS::distance(lc($args{string}), lc($_[0])) <=> Text::Levenshtein::XS::distance(lc($args{string}), lc($_[1]))) :
            (Text::Levenshtein::XS::distance($args{string}, $_[0]) <=> Text::Levenshtein::XS::distance($args{string}, $_[1]))
        ) * ($args{reverse} ? -1 : 1)
    };
}

1;
# ABSTRACT: Compare similarity to a reference string

__END__

=pod

=encoding UTF-8

=head1 NAME

Comparer::by_similarity - Compare similarity to a reference string

=head1 VERSION

This document describes version 0.001 of Comparer::by_similarity (from Perl distribution Comparer-by_similarity), released on 2024-01-24.

=head1 SYNOPSIS

 use Comparer::by_similarity;

 my $cmp = Comparer::by_similarity::gen_sorter(string => 'foo');
 my @sorted = sort { $cmp->($a,$b) } "food", "foolish", "foo", "bar";

=head1 DESCRIPTION

=for Pod::Coverage ^(meta|gen_comparer)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Comparer-by_similarity>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Comparer-by_similarity>.

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Comparer-by_similarity>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
