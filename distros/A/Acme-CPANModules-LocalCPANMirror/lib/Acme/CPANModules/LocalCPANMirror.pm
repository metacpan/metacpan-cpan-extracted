package Acme::CPANModules::LocalCPANMirror;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-10-29'; # DATE
our $DIST = 'Acme-CPANModules-LocalCPANMirror'; # DIST
our $VERSION = '0.002'; # VERSION

our $LIST = {
    summary => 'List of modules/tools to create a local CPAN mirror',
    description => <<'_',

Since CPAN repository is just a hierarchy of files, you can simply use a
recursive download/mirror tool over http/https/ftp. However, for additional
features you can take a look at the modules in this list.

_
    entries => [
        {
            module=>'CPAN::Mini',
            description => <<'_',

This module lets you create a so-called "mini mirror", which only contains the
newest release for each distribution (where CPAN might also contains previous
versions of a distribution as long as the CPAN author does not clean up his
previous releases). This produces a significantly smaller CPAN mirror which you
can use on your PC/laptop for offline development use.

_
        },
        {
            module=>'App::lcpan',
            description => <<'_',

This application not only lets you download a CPAN mini mirror (using
<pm:CPAN::Mini> actually) but also index the package list and distribution
metadata into a SQLite database so you can perform various queries, like list of
modules/distributions/scripts of a CPAN author, or related modules using
cross-mention information on modules' PODs, or various rankings.

_
        },
    ],
};

1;
# ABSTRACT: List of modules/tools to create a local CPAN mirror

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::LocalCPANMirror - List of modules/tools to create a local CPAN mirror

=head1 VERSION

This document describes version 0.002 of Acme::CPANModules::LocalCPANMirror (from Perl distribution Acme-CPANModules-LocalCPANMirror), released on 2023-10-29.

=head1 DESCRIPTION

Since CPAN repository is just a hierarchy of files, you can simply use a
recursive download/mirror tool over http/https/ftp. However, for additional
features you can take a look at the modules in this list.

=head1 ACME::CPANMODULES ENTRIES

=over

=item L<CPAN::Mini>

Author: L<RJBS|https://metacpan.org/author/RJBS>

This module lets you create a so-called "mini mirror", which only contains the
newest release for each distribution (where CPAN might also contains previous
versions of a distribution as long as the CPAN author does not clean up his
previous releases). This produces a significantly smaller CPAN mirror which you
can use on your PC/laptop for offline development use.


=item L<App::lcpan>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

This application not only lets you download a CPAN mini mirror (using
L<CPAN::Mini> actually) but also index the package list and distribution
metadata into a SQLite database so you can perform various queries, like list of
modules/distributions/scripts of a CPAN author, or related modules using
cross-mention information on modules' PODs, or various rankings.


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

 % cpanm-cpanmodules -n LocalCPANMirror

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries LocalCPANMirror | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=LocalCPANMirror -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::LocalCPANMirror -E'say $_->{module} for @{ $Acme::CPANModules::LocalCPANMirror::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-LocalCPANMirror>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-LocalCPANMirror>.

=head1 SEE ALSO

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

L<Acme::CPANModules::CustomCPAN>

L<Acme::CPANModules::LocalCPANIndex>

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-LocalCPANMirror>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
