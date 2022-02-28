# no code
## no critic: TestinAndDebugging::RequireUseStrict
package Acme::CPANModules::PAUSE;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-09-12'; # DATE
our $DIST = 'Acme-CPANModules-PAUSE'; # DIST
our $VERSION = '0.002'; # VERSION

our $LIST = {
    summary => "Modules that interact with PAUSE, the Perl Authors Upload Server",
    entries => [
        {
            module => 'WWW::PAUSE::Simple',
            tags => ['task:upload', 'task:list', 'task:reindex', 'task:cleanup', 'category:api'],
        },
        {
            module => 'App::pause',
            tags => ['task:upload', 'task:list', 'task:reindex', 'task:cleanup', 'category:cli'],
        },
        {
            module => 'App::PAUSE::cleanup',
            tags => ['task:cleanup', 'category:cli'],
        },
        {
            module => 'CPAN::Uploader',
            tags => ['task:upload', 'category:cli', 'category:api'],
        },
        {
            module => 'Dist::Zilla::Plugin::UploadToCPAN',
            tags => ['task:upload', 'category:dzil-plugin'],
        },
        {
            module => 'Dist::Zilla::Plugin::UploadToCPAN::WWWPAUSESimple',
            tags => ['task:upload', 'category:dzil-plugin'],
        },
        {
            module => 'WWW::PAUSE::CleanUpHomeDir',
            tags => ['task:cleanup', 'category:api'],
        },
    ],
};

1;
# ABSTRACT: Modules that interact with PAUSE, the Perl Authors Upload Server

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::PAUSE - Modules that interact with PAUSE, the Perl Authors Upload Server

=head1 VERSION

This document describes version 0.002 of Acme::CPANModules::PAUSE (from Perl distribution Acme-CPANModules-PAUSE), released on 2021-09-12.

=head1 DESCRIPTION

=head1 ACME::MODULES ENTRIES

=over

=item * L<WWW::PAUSE::Simple>

=item * L<App::pause>

=item * L<App::PAUSE::cleanup>

=item * L<CPAN::Uploader>

=item * L<Dist::Zilla::Plugin::UploadToCPAN>

=item * L<Dist::Zilla::Plugin::UploadToCPAN::WWWPAUSESimple>

=item * L<WWW::PAUSE::CleanUpHomeDir>

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

 % cpanm-cpanmodules -n PAUSE

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries PAUSE | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=PAUSE -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::PAUSE -E'say $_->{module} for @{ $Acme::CPANModules::PAUSE::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-PAUSE>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-PAUSE>.

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-PAUSE>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
