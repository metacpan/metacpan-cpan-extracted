package Acme::CPANModules::CLI::Sort;

our $DATE = '2018-07-29'; # DATE
our $VERSION = '0.001'; # VERSION

our $LIST = {
    summary => "Various CLIs to perform sorting",
    description => <<'_',

If you know of others, please drop me a message.

_
    entries => [
        {
            summary => 'Sort JSON objects by key field(s)',
            module => 'App::PipeFilter',
            script => 'jsort',
        },
        {
            summary => 'Sort version numbers',
            module => 'App::VersionUtils',
            script => 'sort-versions',
        },
        {
            summary => 'Sort lines of text using Sort::Sub routines',
            module => 'App::subsort',
            script => 'subsort',
            related_modules => ['Sub::Sort'],
        },
        {
            summary => 'Sort XML "records"',
            module => 'Unicode::Tussle',
            script => 'xmlsort',
        },
        {
            summary => 'Topological sort',
            module => 'PerlPowerTools',
            script => 'tsort',
        },
        {
            summary => 'Another topological sort script',
            module => 'App::toposort',
            script => 'toposort',
        },
        {
            summary => 'Sort lines of text (Perl port of the sort Unix command)',
            module => 'PerlPowerTools',
            script => 'sort',
        },
        {
            summary => 'Sort lines of text using cmp operator or custom Perl code',
            module => 'App::psort',
            script => 'psort',
        },
        {
            summary => 'Sort lines of text by their length',
            module => 'App::lensort',
            script => 'lensort',
        },
    ],
};

1;
# ABSTRACT: Various CLIs to perform sorting

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::CLI::Sort - Various CLIs to perform sorting

=head1 VERSION

This document describes version 0.001 of Acme::CPANModules::CLI::Sort (from Perl distribution Acme-CPANModules-CLI-Sort), released on 2018-07-29.

=head1 DESCRIPTION

Various CLIs to perform sorting.

If you know of others, please drop me a message.

=head1 INCLUDED MODULES

=over

=item * L<App::PipeFilter> - Sort JSON objects by key field(s)

=item * L<App::VersionUtils> - Sort version numbers

=item * L<App::subsort> - Sort lines of text using Sort::Sub routines

Related modules: L<Sub::Sort>

=item * L<Unicode::Tussle> - Sort XML "records"

=item * L<PerlPowerTools> - Topological sort

=item * L<App::toposort> - Another topological sort script

=item * L<PerlPowerTools> - Sort lines of text (Perl port of the sort Unix command)

=item * L<App::psort> - Sort lines of text using cmp operator or custom Perl code

=item * L<App::lensort> - Sort lines of text by their length

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-CLI-Sort>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-CLI-Sort>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-CLI-Sort>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
