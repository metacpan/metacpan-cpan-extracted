package Acme::CPANModules::DiffingStructuredData;

use strict;
use warnings;
use Acme::CPANModulesUtil::Misc;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-12-09'; # DATE
our $DIST = 'Acme-CPANModules-DiffingStructuredData'; # DIST
our $VERSION = '0.002'; # VERSION

my $text = <<'_';

<pm:Data::Comparator>

<pm:Data::Diff>

<pm:Data::Cmp::Diff>

<pm:Hash::Diff>

<pm:Struct::Diff>

<pm:Value::Diff>

_

our $LIST = {
    summary => 'List of modules to diff structured data',
    description => $text,
    tags => ['task'],
};

Acme::CPANModulesUtil::Misc::populate_entries_from_module_links_in_description;

1;
# ABSTRACT: List of modules to diff structured data

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::DiffingStructuredData - List of modules to diff structured data

=head1 VERSION

This document describes version 0.002 of Acme::CPANModules::DiffingStructuredData (from Perl distribution Acme-CPANModules-DiffingStructuredData), released on 2022-12-09.

=head1 DESCRIPTION

L<Data::Comparator>

L<Data::Diff>

L<Data::Cmp::Diff>

L<Hash::Diff>

L<Struct::Diff>

L<Value::Diff>

=head1 ACME::CPANMODULES ENTRIES

=over

=item L<Data::Comparator>

Author: L<CORNELIS|https://metacpan.org/author/CORNELIS>

=item L<Data::Diff>

Author: L<GCAMPBELL|https://metacpan.org/author/GCAMPBELL>

=item L<Data::Cmp::Diff>

=item L<Hash::Diff>

Author: L<BOLAV|https://metacpan.org/author/BOLAV>

=item L<Struct::Diff>

Author: L<MIXAS|https://metacpan.org/author/MIXAS>

=item L<Value::Diff>

Author: L<BRTASTIC|https://metacpan.org/author/BRTASTIC>

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

 % cpanm-cpanmodules -n DiffingStructuredData

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries DiffingStructuredData | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=DiffingStructuredData -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::DiffingStructuredData -E'say $_->{module} for @{ $Acme::CPANModules::DiffingStructuredData::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-DiffingStructuredData>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-DiffingStructuredData>.

=head1 SEE ALSO

L<Acme::CPANModules::DiffingStuffs>

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

This software is copyright (c) 2022 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-DiffingStructuredData>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
