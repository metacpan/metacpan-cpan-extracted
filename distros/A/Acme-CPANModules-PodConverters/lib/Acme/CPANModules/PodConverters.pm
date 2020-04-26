package Acme::CPANModules::PodConverters;

our $DATE = '2019-12-26'; # DATE
our $VERSION = '0.001'; # VERSION

our $LIST = {
    summary => "Modules to convert POD to/from other formats",
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
# ABSTRACT: Modules to convert POD to/from other formats

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::PodConverters - Modules to convert POD to/from other formats

=head1 VERSION

This document describes version 0.001 of Acme::CPANModules::PodConverters (from Perl distribution Acme-CPANModules-PodConverters), released on 2019-12-26.

=head1 DESCRIPTION

Modules to convert POD to/from other formats.

=head1 INCLUDED MODULES

=over

=item * L<POD::Text> - POD to formatted text

Distribution includes L<pod2text>


=item * L<POD::Man> - POD to formatted *roff input (Unix manpage)

Distribution includes L<pod2man>


=item * L<Pod::Html> - POD to HTML

Distribution includes L<pod2html>


=item * L<App::podtohtml> - Alternative CLI to convert POD to HTML

Distribution comes with L<podtohtml>. Fix some annoyances with Pod::Html/pod2html which leaves temporary files lying around in current directory. Add templates, sending HTML to browser, and tab completion.


=item * L<Pod::Simple::HTML> - Another module to convert POD to HTML

=item * L<Pod::Pdf> - POD to PDF

=item * L<Pod::Markdown> - POD to Markdown

=item * L<Pod::HTML2Pod> - HTML to POD

=item * L<Markdown::Pod> - Markdown to POD

Have some annoyances so I created <Markdown::To::POD>


=item * L<Markdown::To::POD> - Markdown to POD

=item * L<App::MarkdownUtils> - Contains CLI for converting Markdown to POD, <prog:markdown-to-pod>

=back

=head1 FAQ

=head2 What are ways to use this module?

Aside from reading it, you can install all the listed modules using
L<cpanmodules>:

    % cpanmodules ls-entries PodConverters | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=PodConverters -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

This module also helps L<lcpan> produce a more meaningful result for C<lcpan
related-mods> when it comes to finding related modules for the modules listed
in this Acme::CPANModules module.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-PodConverters>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-PodConverters>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-PodConverters>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<https://orgmode.org>

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
