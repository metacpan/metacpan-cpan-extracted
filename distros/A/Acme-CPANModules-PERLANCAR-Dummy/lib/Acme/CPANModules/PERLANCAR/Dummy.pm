package Acme::CPANModules::PERLANCAR::Dummy;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-10-31'; # DATE
our $DIST = 'Acme-CPANModules-PERLANCAR-Dummy'; # DIST
our $VERSION = '0.002'; # VERSION

our $LIST = {
    summary => 'List of some modules (a dummy Acme::CPANModules list for various testing)',
    entry_features => {
        foo => {summary=>'Foo feature (bool)'},
        bar => {summary=>'Bar feature (bool)'},
        baz => {summary=>'Baz feature (string)', schema=>'str*'},
    },
    entries => [
        {
            module => "App::Trrr",
            features => {
                foo => {value=>undef, summary=>'Some note'},
                bar => {value=>undef, summary=>'Some note'},
                baz => 'value1',
            },
        },
        {
            module => "App::Wax",
            features => {foo=>1, bar=>1}},
        {
            module => "App::cpangrep",
            features => {foo=>0, bar=>0},
        },
        {
            module => "Acme::PPIx::MetaSyntactic",
            features => {foo=>1, bar=>0},
        },
    ],
};

1;
# ABSTRACT: List of some modules (a dummy Acme::CPANModules list for various testing)

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::PERLANCAR::Dummy - List of some modules (a dummy Acme::CPANModules list for various testing)

=head1 VERSION

This document describes version 0.002 of Acme::CPANModules::PERLANCAR::Dummy (from Perl distribution Acme-CPANModules-PERLANCAR-Dummy), released on 2023-10-31.

=head1 ACME::CPANMODULES ENTRIES

=over

=item L<App::Trrr>

=item L<App::Wax>

Author: L<CHOCOLATE|https://metacpan.org/author/CHOCOLATE>

=item L<App::cpangrep>

Author: L<TSIBLEY|https://metacpan.org/author/TSIBLEY>

=item L<Acme::PPIx::MetaSyntactic>

Author: L<TOBYINK|https://metacpan.org/author/TOBYINK>

=back

=head1 ACME::CPANMODULES FEATURE COMPARISON MATRIX

 +---------------------------+---------+---------+---------+
 | module                    | bar *1) | baz *2) | foo *3) |
 +---------------------------+---------+---------+---------+
 | App::Trrr                 | N/A *4) | value1  | N/A *4) |
 | App::Wax                  | yes     | N/A     | yes     |
 | App::cpangrep             | no      | N/A     | no      |
 | Acme::PPIx::MetaSyntactic | no      | N/A     | yes     |
 +---------------------------+---------+---------+---------+


Notes:

=over

=item 1. bar: Bar feature (bool)

=item 2. baz: Baz feature (string)

=item 3. foo: Foo feature (bool)

=item 4. Some note

=back

=head1 FAQ

=head2 What is an Acme::CPANModules::* module?

An Acme::CPANModules::* module, like this module, contains just a list of module
names that share a common characteristics. It is a way to categorize modules and
document CPAN. See L<Acme::CPANModules> for more details.

=head2 What are ways to use this Acme::CPANModules module?

Aside from reading this Acme::CPANModules module's POD documentation, you can
install all the listed modules (entries) using L<cpanm-cpanmodules> script (from
L<App::cpanm::cpanmodules> distribution):

 % cpanm-cpanmodules -n PERLANCAR::Dummy

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries PERLANCAR::Dummy | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=PERLANCAR::Dummy -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::PERLANCAR::Dummy -E'say $_->{module} for @{ $Acme::CPANModules::PERLANCAR::Dummy::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-PERLANCAR-Dummy>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-PERLANCAR-Dummy>.

=head1 SEE ALSO

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

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

This software is copyright (c) 2023, 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-PERLANCAR-Dummy>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
