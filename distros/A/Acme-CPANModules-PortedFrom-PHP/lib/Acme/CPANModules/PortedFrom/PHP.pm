package Acme::CPANModules::PortedFrom::PHP;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-01-14'; # DATE
our $DIST = 'Acme-CPANModules-PortedFrom-PHP'; # DIST
our $VERSION = '0.004'; # VERSION

our $LIST = {
    summary => "Modules/applications that are ported from (or inspired by) ".
        "PHP libraries",
    description => <<'_',

If you know of others, please drop me a message.

_
    entries => [
        {module=>'Weasel', summary=>'Mink'},
        {module=>'PHP::Functions::Password', summary=>'PHP password functions'},
    ],
};

1;
# ABSTRACT: Modules/applications that are ported from (or inspired by) PHP libraries

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::PortedFrom::PHP - Modules/applications that are ported from (or inspired by) PHP libraries

=head1 VERSION

This document describes version 0.004 of Acme::CPANModules::PortedFrom::PHP (from Perl distribution Acme-CPANModules-PortedFrom-PHP), released on 2022-01-14.

=head1 DESCRIPTION

If you know of others, please drop me a message.

=head1 ACME::CPANMODULES ENTRIES

=over

=item * L<Weasel> - Mink

=item * L<PHP::Functions::Password> - PHP password functions

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2021, 2020 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-PortedFrom-PHP>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
