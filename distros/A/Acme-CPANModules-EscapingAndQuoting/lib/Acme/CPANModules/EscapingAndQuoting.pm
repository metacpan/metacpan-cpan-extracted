package Acme::CPANModules::EscapingAndQuoting;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-10-29'; # DATE
our $DIST = 'Acme-CPANModules-EscapingAndQuoting'; # DIST
our $VERSION = '0.003'; # VERSION

our $LIST = {
    summary => 'List of modules that escape/quote data to make it safe',
    entries => [
        {
            module=>'HTML::Entities',
        },
        {
            module=>'URI::Escape',
            alternate_modules => ['URI::Escape::XS'],
        },
        {
            module=>'String::PodQuote',
        },
        {
            module=>'String::ShellQuote',
            alternate_modules => ['Win32::ShellQuote', 'ShellQuote::Any', 'ShellQuote::Any::Tiny'],
        },
        {
            module=>'String::ShellQuote',
        },
        {
            module=>'String::Escape',
        },
        {
            module=>'String::JS',
        },
        {
            module=>'Unicode::Escape',
        },
        {
            module=>'TeX::Encode',
        },
        {
            module=>'String::PerlQuote',
        },
        {
            module=>'MIME::Base64',
        },
        {
            module=>'Data::Clean',
        },
        {
            module=>'Data::Clean::ForJSON',
        },
    ],
};

1;
# ABSTRACT: List of modules that escape/quote data to make it safe

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::EscapingAndQuoting - List of modules that escape/quote data to make it safe

=head1 VERSION

This document describes version 0.003 of Acme::CPANModules::EscapingAndQuoting (from Perl distribution Acme-CPANModules-EscapingAndQuoting), released on 2023-10-29.

=head1 ACME::CPANMODULES ENTRIES

=over

=item L<HTML::Entities>

Author: L<OALDERS|https://metacpan.org/author/OALDERS>

=item L<URI::Escape>

Author: L<OALDERS|https://metacpan.org/author/OALDERS>

Alternate modules: L<URI::Escape::XS>

=item L<String::PodQuote>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<String::ShellQuote>

Author: L<ROSCH|https://metacpan.org/author/ROSCH>

Alternate modules: L<Win32::ShellQuote>, L<ShellQuote::Any>, L<ShellQuote::Any::Tiny>

=item L<String::ShellQuote>

Author: L<ROSCH|https://metacpan.org/author/ROSCH>

=item L<String::Escape>

Author: L<EVO|https://metacpan.org/author/EVO>

=item L<String::JS>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Unicode::Escape>

Author: L<ITWARRIOR|https://metacpan.org/author/ITWARRIOR>

=item L<TeX::Encode>

Author: L<ATHREEF|https://metacpan.org/author/ATHREEF>

=item L<String::PerlQuote>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<MIME::Base64>

Author: L<CAPOEIRAB|https://metacpan.org/author/CAPOEIRAB>

=item L<Data::Clean>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Data::Clean::ForJSON>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

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

 % cpanm-cpanmodules -n EscapingAndQuoting

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries EscapingAndQuoting | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=EscapingAndQuoting -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::EscapingAndQuoting -E'say $_->{module} for @{ $Acme::CPANModules::EscapingAndQuoting::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-EscapingAndQuoting>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-EscapingAndQuoting>.

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

This software is copyright (c) 2023, 2019 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-EscapingAndQuoting>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
