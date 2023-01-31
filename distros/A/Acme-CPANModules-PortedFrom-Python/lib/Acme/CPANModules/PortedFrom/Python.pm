package Acme::CPANModules::PortedFrom::Python;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-11-13'; # DATE
our $DIST = 'Acme-CPANModules-PortedFrom-Python'; # DIST
our $VERSION = '0.005'; # VERSION

our $LIST = {
    summary => "Modules/applications that are ported from (or inspired by) ".
        "Python libraries",
    description => <<'_',

If you know of others, please drop me a message.

_
    entries => [
        {
            module => 'Docopt',
            python_package => 'docopt',
            tags => ['cli'],
        },
        {
            module => 'Getopt::ArgParse',
            python_package => 'argparse',
            tags => ['cli'],
        },
        {
            module => 'PSGI',
            python_package => undef,
            python_url => 'https://www.python.org/dev/peps/pep-3333/',
            tags => ['web'],
            description => <<'_',

From Plack's documentation: "Plack is like Ruby's Rack or Python's Paste for
WSGI." Plack and PSGI were created by MIYAGAWA in 2009 and were inspired by both
Python's WSGI specification (hence the dual specification-implementation split)
and Ruby's Plack (hence the name).

_
        },
        {
            module => 'Data::XLSX::Parser',
            description => <<'_',

Quoted from the module's documentation: "The implementation of this module is
highly inspired from Python's FastXLSX library."

_
        },
    ],
};

1;
# ABSTRACT: Modules/applications that are ported from (or inspired by) Python libraries

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::PortedFrom::Python - Modules/applications that are ported from (or inspired by) Python libraries

=head1 VERSION

This document describes version 0.005 of Acme::CPANModules::PortedFrom::Python (from Perl distribution Acme-CPANModules-PortedFrom-Python), released on 2022-11-13.

=head1 DESCRIPTION

=head2 SEE ALSO

L<Acme::CPANModules::PortedFrom::Ruby> and other
C<Acme::CPANModules::PortedFrom::*> modules.

If you know of others, please drop me a message.

=head1 ACME::CPANMODULES ENTRIES

=over

=item L<Docopt>

Author: L<TOKUHIROM|https://metacpan.org/author/TOKUHIROM>

=item L<Getopt::ArgParse>

Author: L<MYTRAM|https://metacpan.org/author/MYTRAM>

=item L<PSGI>

Author: L<MIYAGAWA|https://metacpan.org/author/MIYAGAWA>

From Plack's documentation: "Plack is like Ruby's Rack or Python's Paste for
WSGI." Plack and PSGI were created by MIYAGAWA in 2009 and were inspired by both
Python's WSGI specification (hence the dual specification-implementation split)
and Ruby's Plack (hence the name).


=item L<Data::XLSX::Parser>

Author: L<ACIDLEMON|https://metacpan.org/author/ACIDLEMON>

Quoted from the module's documentation: "The implementation of this module is
highly inspired from Python's FastXLSX library."


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

 % cpanm-cpanmodules -n PortedFrom::Python

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries PortedFrom::Python | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=PortedFrom::Python -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::PortedFrom::Python -E'say $_->{module} for @{ $Acme::CPANModules::PortedFrom::Python::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-PortedFrom-Python>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-PortedFrom-Python>.

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

This software is copyright (c) 2022, 2021, 2020, 2018 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-PortedFrom-Python>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
