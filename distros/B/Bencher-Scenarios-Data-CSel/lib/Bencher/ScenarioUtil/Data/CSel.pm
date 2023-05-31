package Bencher::ScenarioUtil::Data::CSel;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-01-18'; # DATE
our $DIST = 'Bencher-Scenarios-Data-CSel'; # DIST
our $VERSION = '0.041'; # VERSION

our @datasets = (
    {name => 'small1-hash'  , summary => '16 elements, 4 levels (hash-based nodes)'  , args=>{tree=>'small1-hash'}},
    {name => 'small1-array' , summary => '16 elements, 4 levels (array-based nodes)' , args=>{tree=>'small1-array'}},
    {name => 'medium1-hash' , summary => '20k elements, 7 levels (hash-based nodes)' , args=>{tree=>'medium1-hash'}},
    {name => 'medium1-array', summary => '20k elements, 7 levels (array-based nodes)', args=>{tree=>'medium1-array'}},
);

# we want to record the version of these modules too in the benchmark result
# metadata
our @extra_modules = (
    'PERLANCAR::Tree::Examples',
);

1;
# ABSTRACT: Utility routines

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::ScenarioUtil::Data::CSel - Utility routines

=head1 VERSION

This document describes version 0.041 of Bencher::ScenarioUtil::Data::CSel (from Perl distribution Bencher-Scenarios-Data-CSel), released on 2023-01-18.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-Data-CSel>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-Data-CSel>.

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

This software is copyright (c) 2023, 2017, 2016 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-Data-CSel>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
