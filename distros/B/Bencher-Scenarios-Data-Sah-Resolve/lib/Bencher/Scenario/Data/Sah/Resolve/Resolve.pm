package Bencher::Scenario::Data::Sah::Resolve::Resolve;

use 5.010001;
use strict;
use warnings;

use Sah::Schema::poseven; # to pull dependency
use Sah::Schema::posint;  # to pull dependency

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-01-19'; # DATE
our $DIST = 'Bencher-Scenarios-Data-Sah-Resolve'; # DIST
our $VERSION = '0.005'; # VERSION

our $scenario = {
    summary => 'Benchmark resolving',
    participants => [
        {
            fcall_template => 'Data::Sah::Resolve::resolve_schema(<schema>)',
        },
    ],

    datasets => [
        {name=>"int"           , args=>{schema=>'int'}},
        {name=>"posint"        , args=>{schema=>'posint'}},
        {name=>"poseven"       , args=>{schema=>'poseven'}},
    ],
};

1;
# ABSTRACT: Benchmark resolving

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Data::Sah::Resolve::Resolve - Benchmark resolving

=head1 VERSION

This document describes version 0.005 of Bencher::Scenario::Data::Sah::Resolve::Resolve (from Perl distribution Bencher-Scenarios-Data-Sah-Resolve), released on 2023-01-19.

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
