package Bencher::Scenario::Data::Sah::Resolve::Overhead;

use 5.010001;
use strict;
use warnings;

use Sah::Schema::perl::distname; # to pull dependency
use Sah::Schema::perl::modname;  # to pull dependency
use Sah::Schema::poseven;        # to pull dependency
use Sah::Schema::posint;         # to pull dependency

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-01-19'; # DATE
our $DIST = 'Bencher-Scenarios-Data-Sah-Resolve'; # DIST
our $VERSION = '0.005'; # VERSION

our $scenario = {
    summary => 'Benchmark the overhead of resolving schemas',
    modules => {
        'Data::Sah' => {},
        'Data::Sah::Normalize' => {},
        'Data::Sah::Resolve' => {},
    },
    participants => [
        {
            name => 'resolve_schema',
            perl_cmdline_template => ["-MData::Sah::Resolve=resolve_schema", "-e", 'for (@{ <schemas> }) { resolve_schema($_) }'],
        },
        {
            name => 'normalize_schema',
            perl_cmdline_template => ["-MData::Sah::Normalize=normalize_schema", "-e", 'for (@{ <schemas> }) { normalize_schema($_) }'],
        },
        {
            name => 'gen_validator',
            perl_cmdline_template => ["-MData::Sah=gen_validator", "-e", 'for (@{ <schemas> }) { gen_validator($_, {return_type=>q(str)}) }'],
        },
    ],

    datasets => [
        {name=>"int"           , args=>{schemas=>'[q(int)]'}},
        {name=>"perl::modname" , args=>{schemas=>'[q(perl::modname)]'}},
        {name=>"5-schemas"     , args=>{schemas=>'[q(int),q(perl::distname),q(perl::modname),q(posint),q(poseven)]'}},
    ],
};

1;
# ABSTRACT: Benchmark the overhead of resolving schemas

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Data::Sah::Resolve::Overhead - Benchmark the overhead of resolving schemas

=head1 VERSION

This document describes version 0.005 of Bencher::Scenario::Data::Sah::Resolve::Overhead (from Perl distribution Bencher-Scenarios-Data-Sah-Resolve), released on 2023-01-19.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-Data-Sah-Resolve>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-Data-Sah-Resolve>.

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-Data-Sah-Resolve>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
