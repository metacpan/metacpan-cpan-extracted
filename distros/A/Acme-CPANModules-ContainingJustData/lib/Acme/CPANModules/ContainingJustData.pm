package Acme::CPANModules::ContainingJustData;

use strict;
use Acme::CPANModulesUtil::Misc;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-08-06'; # DATE
our $DIST = 'Acme-CPANModules-ContainingJustData'; # DIST
our $VERSION = '0.003'; # VERSION

my $text = <<'_';

Modules under <pm:WordList>::* contain lists of words.
<pm:Games::Word::Wordlist::*> modules also contain lists of words.

Modules under <pm:TableData>::* contains table data.

<pm:DataDist>::* distributions also contain mostly data.

_

our $LIST = {
    summary => 'List of modules that just contain data',
    description => $text,
};

Acme::CPANModulesUtil::Misc::populate_entries_from_module_links_in_description;

1;
# ABSTRACT: List of modules that just contain data

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::ContainingJustData - List of modules that just contain data

=head1 VERSION

This document describes version 0.003 of Acme::CPANModules::ContainingJustData (from Perl distribution Acme-CPANModules-ContainingJustData), released on 2023-08-06.

=head1 DESCRIPTION

Modules under L<WordList>::* contain lists of words.
L<Games::Word::Wordlist::*> modules also contain lists of words.

Modules under L<TableData>::* contains table data.

L<DataDist>::* distributions also contain mostly data.

=head1 ACME::CPANMODULES ENTRIES

=over

=item L<WordList>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<TableData>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<DataDist>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

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

 % cpanm-cpanmodules -n ContainingJustData

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries ContainingJustData | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=ContainingJustData -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::ContainingJustData -E'say $_->{module} for @{ $Acme::CPANModules::ContainingJustData::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-ContainingJustData>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-ContainingJustData>.

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

This software is copyright (c) 2023 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-ContainingJustData>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
