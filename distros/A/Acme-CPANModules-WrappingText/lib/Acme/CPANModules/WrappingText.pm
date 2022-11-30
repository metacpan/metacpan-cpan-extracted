package Acme::CPANModules::WrappingText;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-11-24'; # DATE
our $DIST = 'Acme-CPANModules-WrappingText'; # DIST
our $VERSION = '0.001'; # VERSION

our $LIST = {
    summary => "List of modules and utilities to wrap text",
    description => <<'_',

See also: <prog:fold> Unix command line.

_
    # TODO: use Module::Features
    entry_features => {
        can_unicode => {summary => 'Can wrap Unicode text, including wide characters'},
        can_cjk     => {summary => 'Can wrap CJK wide characters'},
        can_ansi    => {summary => 'Can wrap text that contains ANSI color/escape codes'},
    },
    entries => [
        {
            module => 'App::TextWrapUtils',
            script => 'textwrap',
            description => <<'_',

CLI front-end for various backends mentioned in this list.

_
        },
        {
            module => 'Lingua::JA::Fold',
            function => 'fold',
            description => <<'_',

Specifically for folding Japanese (and other CJK) text.

_
            features => {
                can_unicode => 0,
                can_cjk => 1,
                can_ansi => 0,
            },
        },
        {
            module => 'Text::ANSI::Fold',
            function => 'ansi_fold',
            description => <<'_',

_
            features => {
                can_unicode => 1,
                can_cjk => 1,
                can_ansi => 1,
            },
        },
        {
            module => 'Text::ANSI::Util',
            function => 'ta_wrap',
            description => <<'_',

For wrapping text that contains ANSI escape/color codes.

_
            features => {
                can_unicode => 0,
                can_cjk => 0,
                can_ansi => 1,
            },
        },
        {
            module => 'Text::ANSI::WideUtil',
            function => 'ta_mbwrap',
            description => <<'_',

For wrapping text that contains ANSI escape/color codes *and* Unicode wide
characters.

_
            features => {
                can_unicode => 1,
                can_cjk => 0,
                can_ansi => 1,
            },
        },
        {
            module => 'Text::WideChar::Util',
            function => 'mbwrap',
            description => <<'_',

For wrapping text that contains Unicode wide characters.

_
            features => {
                can_unicode => 1,
                can_cjk => 0,
                can_ansi => 0,
            },
        },
        {
            module => 'Text::Fold',
            function => 'fold_text',
            description => <<'_',

_
            features => {
                can_unicode => 1,
                can_cjk => 0,
                can_ansi => 0,
            },
        },
        {
            module => 'Text::LineFold',
            method => 'fold',
            description => <<'_',

_
            features => {
                can_unicode => 0,
                can_cjk => 0,
                can_ansi => 0,
            },
        },
        {
            module => 'Text::Wrap',
            description => <<'_',

Core module.

_
            features => {
                can_unicode => 0,
                can_cjk => 0,
                can_ansi => 0,
            },
        },
    ],
};

1;
# ABSTRACT: List of modules and utilities to wrap text

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::WrappingText - List of modules and utilities to wrap text

=head1 VERSION

This document describes version 0.001 of Acme::CPANModules::WrappingText (from Perl distribution Acme-CPANModules-WrappingText), released on 2022-11-24.

=head1 DESCRIPTION

See also: L<fold> Unix command line.

=head1 ACME::CPANMODULES ENTRIES

=over

=item L<App::TextWrapUtils>

CLI front-end for various backends mentioned in this list.


Script: L<textwrap>

=item L<Lingua::JA::Fold>

Author: L<HATA|https://metacpan.org/author/HATA>

Specifically for folding Japanese (and other CJK) text.


=item L<Text::ANSI::Fold>

Author: L<UTASHIRO|https://metacpan.org/author/UTASHIRO>

=item L<Text::ANSI::Util>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

For wrapping text that contains ANSI escape/color codes.


=item L<Text::ANSI::WideUtil>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

For wrapping text that contains ANSI escape/color codes I<and> Unicode wide
characters.


=item L<Text::WideChar::Util>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

For wrapping text that contains Unicode wide characters.


=item L<Text::Fold>

Author: L<DMUEY|https://metacpan.org/author/DMUEY>

=item L<Text::LineFold>

Author: L<NEZUMI|https://metacpan.org/author/NEZUMI>

=item L<Text::Wrap>

Author: L<ARISTOTLE|https://metacpan.org/author/ARISTOTLE>

Core module.


=back

=head1 ACME::CPANMODULES FEATURE COMPARISON MATRIX

 +----------------------+--------------+-------------+-----------------+
 | module               | can_ansi *1) | can_cjk *2) | can_unicode *3) |
 +----------------------+--------------+-------------+-----------------+
 | App::TextWrapUtils   | N/A          | N/A         | N/A             |
 | Lingua::JA::Fold     | no           | yes         | no              |
 | Text::ANSI::Fold     | yes          | yes         | yes             |
 | Text::ANSI::Util     | yes          | no          | no              |
 | Text::ANSI::WideUtil | yes          | no          | yes             |
 | Text::WideChar::Util | no           | no          | yes             |
 | Text::Fold           | no           | no          | yes             |
 | Text::LineFold       | no           | no          | no              |
 | Text::Wrap           | no           | no          | no              |
 +----------------------+--------------+-------------+-----------------+


Notes:

=over

=item 1. can_ansi: Can wrap text that contains ANSI color/escape codes

=item 2. can_cjk: Can wrap CJK wide characters

=item 3. can_unicode: Can wrap Unicode text, including wide characters

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

 % cpanm-cpanmodules -n WrappingText

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries WrappingText | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=WrappingText -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::WrappingText -E'say $_->{module} for @{ $Acme::CPANModules::WrappingText::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-WrappingText>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-WrappingText>.

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

This software is copyright (c) 2022 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-WrappingText>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
