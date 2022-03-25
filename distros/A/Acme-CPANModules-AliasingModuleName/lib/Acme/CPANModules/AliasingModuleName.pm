package Acme::CPANModules::AliasingModuleName;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-03-08'; # DATE
our $DIST = 'Acme-CPANModules-AliasingModuleName'; # DIST
our $VERSION = '0.002'; # VERSION

our $LIST = {
    summary => 'List of modules to alias a (long) module name to another (shorter) name',
    tags => ['task'],
    entries => [
        {
            module=>'Package::Alias',
        },
        {
            module=>'alias::module',
            description => <<'_',

I used to use <pm:Package::Alias> but later I created <pm:alias::module> that is
more lightweight (avoids using <pm:Carp>) and has a simpler interface.

_
        },
        {
            module=>'abbreviation',
        },
    ],
};

1;
# ABSTRACT: List of modules to alias a (long) module name to another (shorter) name

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::AliasingModuleName - List of modules to alias a (long) module name to another (shorter) name

=head1 VERSION

This document describes version 0.002 of Acme::CPANModules::AliasingModuleName (from Perl distribution Acme-CPANModules-AliasingModuleName), released on 2022-03-08.

=head1 ACME::CPANMODULES ENTRIES

=over

=item * L<Package::Alias> - Alias one namespace as another

Author: L<JOSHUA|https://metacpan.org/author/JOSHUA>

=item * L<alias::module> - Alias one module as another

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

I used to use L<Package::Alias> but later I created L<alias::module> that is
more lightweight (avoids using L<Carp>) and has a simpler interface.


=item * L<abbreviation> - Perl pragma to abbreviate class names

Author: L<MIYAGAWA|https://metacpan.org/author/MIYAGAWA>

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

 % cpanm-cpanmodules -n AliasingModuleName

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries AliasingModuleName | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=AliasingModuleName -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::AliasingModuleName -E'say $_->{module} for @{ $Acme::CPANModules::AliasingModuleName::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-AliasingModuleName>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-AliasingModuleName>.

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

This software is copyright (c) 2022, 2019 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-AliasingModuleName>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
