package Acme::CPANModules::PodConverters;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-10-31'; # DATE
our $DIST = 'Acme-CPANModules-PodConverters'; # DIST
our $VERSION = '0.002'; # VERSION

our $LIST = {
    summary => "List of modules to convert POD to/from other formats",
    description => <<'_',


_
    entries => [
        {module=>'POD::Text', summary=>'POD to formatted text', description=>'Distribution includes <prog:pod2text>'},
        {module=>'POD::Man' , summary=>'POD to formatted *roff input (Unix manpage)', description=>'Distribution includes <prog:pod2man>'},
        {module=>'Pod::Html', summary=>'POD to HTML', description=>'Distribution includes <prog:pod2html>'},
        {module=>'App::podtohtml', summary=>'Alternative CLI to convert POD to HTML', description=>'Distribution comes with <prog:podtohtml>. Fix some annoyances with Pod::Html/pod2html which leaves temporary files lying around in current directory. Add templates, sending HTML to browser, and tab completion.'},
        {module=>'Pod::Simple::HTML', summary=>'Another module to convert POD to HTML'}, # XXX what's the diff with Pod::Html?
        {module=>'Pod::Pdf', summary=>'POD to PDF'},
        {module=>'Pod::Markdown', summary=>'POD to Markdown'},

        {module=>'Pod::HTML2Pod', summary=>'HTML to POD'},
        {module=>'Markdown::Pod', summary=>'Markdown to POD', description=>'Have some annoyances so I created <Markdown::To::POD>'},
        {module=>'Markdown::To::POD', summary=>'Markdown to POD'},
        {module=>'App::MarkdownUtils', summary=>'Contains CLI for converting Markdown to POD, <prog:markdown-to-pod>'},
    ],
};

1;
# ABSTRACT: List of modules to convert POD to/from other formats

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::PodConverters - List of modules to convert POD to/from other formats

=head1 VERSION

This document describes version 0.002 of Acme::CPANModules::PodConverters (from Perl distribution Acme-CPANModules-PodConverters), released on 2023-10-31.

=head1 DESCRIPTION

=head1 ACME::CPANMODULES ENTRIES

=over

=item L<POD::Text>

POD to formatted text.

Distribution includes L<pod2text>


=item L<POD::Man>

POD to formatted *roff input (Unix manpage).

Distribution includes L<pod2man>


=item L<Pod::Html>

POD to HTML.

Author: L<RJBS|https://metacpan.org/author/RJBS>

Distribution includes L<pod2html>


=item L<App::podtohtml>

Alternative CLI to convert POD to HTML.

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

Distribution comes with L<podtohtml>. Fix some annoyances with Pod::Html/pod2html which leaves temporary files lying around in current directory. Add templates, sending HTML to browser, and tab completion.


=item L<Pod::Simple::HTML>

Another module to convert POD to HTML.

Author: L<KHW|https://metacpan.org/author/KHW>

=item L<Pod::Pdf>

POD to PDF.

Author: L<AJFRY|https://metacpan.org/author/AJFRY>

=item L<Pod::Markdown>

POD to Markdown.

Author: L<RWSTAUNER|https://metacpan.org/author/RWSTAUNER>

=item L<Pod::HTML2Pod>

HTML to POD.

Author: L<SBURKE|https://metacpan.org/author/SBURKE>

=item L<Markdown::Pod>

Markdown to POD.

Author: L<KEEDI|https://metacpan.org/author/KEEDI>

Have some annoyances so I created <Markdown::To::POD>


=item L<Markdown::To::POD>

Markdown to POD.

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<App::MarkdownUtils>

Contains CLI for converting Markdown to POD, <prog:markdown-to-podE<gt>.

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

 % cpanm-cpanmodules -n PodConverters

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries PodConverters | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=PodConverters -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::PodConverters -E'say $_->{module} for @{ $Acme::CPANModules::PodConverters::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-PodConverters>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-PodConverters>.

=head1 SEE ALSO

L<https://orgmode.org>

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-PodConverters>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
