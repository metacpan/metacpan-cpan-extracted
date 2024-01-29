package Acme::CPANModules::PortedFrom::PHP;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-01-09'; # DATE
our $DIST = 'Acme-CPANModules-PortedFrom-PHP'; # DIST
our $VERSION = '0.006'; # VERSION

our $LIST = {
    summary => "List of modules/applications that are ported from (or inspired by) ".
        "PHP libraries",
    description => <<'_',

If you know of others, please drop me a message.

_
    entries => [
        {module=>'Weasel', summary=>'Perl port of Mink'},
        {module=>'PHP::Functions::Password'},
        {module=>'PHP::Functions::Mail'},
        {module=>'PHP::Functions::File'},
        {module=>'PHP::Strings'},
        {module=>'PHP::DateTime'},
        {module=>'PHP::ParseStr'},
        {module=>'PHP::HTTPBuildQuery', summary=>'Implement PHP http_build_query() function'},
        {module=>'Acme::Addslashes'},

        # old
        {module=>'AMF::Perl'},
        {module=>'Flash::FLAP'},
    ],
};

1;
# ABSTRACT: List of modules/applications that are ported from (or inspired by) PHP libraries

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::PortedFrom::PHP - List of modules/applications that are ported from (or inspired by) PHP libraries

=head1 VERSION

This document describes version 0.006 of Acme::CPANModules::PortedFrom::PHP (from Perl distribution Acme-CPANModules-PortedFrom-PHP), released on 2024-01-09.

=head1 DESCRIPTION

If you know of others, please drop me a message.

=head1 ACME::CPANMODULES ENTRIES

=over

=item L<Weasel>

Perl port of Mink.

Author: L<EHUELS|https://metacpan.org/author/EHUELS>

=item L<PHP::Functions::Password>

Author: L<CMANLEY|https://metacpan.org/author/CMANLEY>

=item L<PHP::Functions::Mail>

Author: L<YAPPO|https://metacpan.org/author/YAPPO>

=item L<PHP::Functions::File>

Author: L<TNAGA|https://metacpan.org/author/TNAGA>

=item L<PHP::Strings>

Author: L<KUDARASP|https://metacpan.org/author/KUDARASP>

=item L<PHP::DateTime>

Author: L<BLUEFEET|https://metacpan.org/author/BLUEFEET>

=item L<PHP::ParseStr>

Author: L<ABAYLISS|https://metacpan.org/author/ABAYLISS>

=item L<PHP::HTTPBuildQuery>

Implement PHP http_build_query() function.

Author: L<MSCHILLI|https://metacpan.org/author/MSCHILLI>

=item L<Acme::Addslashes>

Author: L<JAITKEN|https://metacpan.org/author/JAITKEN>

=item L<AMF::Perl>

Author: L<SIMONF|https://metacpan.org/author/SIMONF>

=item L<Flash::FLAP>

Author: L<SIMONF|https://metacpan.org/author/SIMONF>

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

 % cpanm-cpanmodules -n PortedFrom::PHP

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries PortedFrom::PHP | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=PortedFrom::PHP -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::PortedFrom::PHP -E'say $_->{module} for @{ $Acme::CPANModules::PortedFrom::PHP::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-PortedFrom-PHP>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-PortedFrom-PHP>.

=head1 SEE ALSO

More on the same theme of modules ported from other languages:
L<Acme::CPANModules::PortedFrom::Clojure>,
L<Acme::CPANModules::PortedFrom::Go>,
L<Acme::CPANModules::PortedFrom::Java>,
L<Acme::CPANModules::PortedFrom::NPM>,
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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024, 2023, 2022, 2021, 2020 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-PortedFrom-PHP>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
