package Acme::CPANModules::PortedFrom::NPM;

our $DATE = '2021-08-10'; # DATE
our $VERSION = '0.004'; # VERSION

our $LIST = {
    summary => "Modules/applications that are ported (or inspired from) NPM libraries",
    description => <<'_',

If you know of others, please drop me a message.

_
    entries => [
        {
            module => 'App::AsciiChart',
            npm_module => 'asciichart',
            tags => ['cli', 'chart'],
        },
        {
            module => 'App::chalk',
            npm_module => 'chalk',
            tags => ['cli', 'color'],
        },
        {
            module => 'App::envset',
            npm_module => 'envset',
            tags => ['cli','configuration'],
        },
        {
            module => 'Inky',
            npm_module => 'inky',
            tags => ['html', 'template'],
        },
        {
            module => 'Smart::Options',
            npm_module => 'optimist',
            tags => ['html', 'template'],
        },
    ],
};

1;
# ABSTRACT: Modules/applications that are ported (or inspired from) NPM libraries

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::PortedFrom::NPM - Modules/applications that are ported (or inspired from) NPM libraries

=head1 VERSION

This document describes version 0.004 of Acme::CPANModules::PortedFrom::NPM (from Perl distribution Acme-CPANModules-PortedFrom-NPM), released on 2021-08-10.

=head1 DESCRIPTION

If you know of others, please drop me a message.

=head1 ACME::MODULES ENTRIES

=over

=item * L<App::AsciiChart>

=item * L<App::chalk>

=item * L<App::envset>

=item * L<Inky>

=item * L<Smart::Options>

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

 % cpanm-cpanmodules -n PortedFrom::NPM

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries PortedFrom::NPM | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=PortedFrom::NPM -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::PortedFrom::NPM -E'say $_->{module} for @{ $Acme::CPANModules::PortedFrom::NPM::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-PortedFrom-NPM>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-PortedFrom-NPM>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-PortedFrom-NPM>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

More on the same theme of modules ported from other languages:
L<Acme::CPANModules::PortedFrom::Java>,
L<Acme::CPANModules::PortedFrom::PHP>,
L<Acme::CPANModules::PortedFrom::Python>,
L<Acme::CPANModules::PortedFrom::Ruby>.

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

This software is copyright (c) 2021, 2018 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
