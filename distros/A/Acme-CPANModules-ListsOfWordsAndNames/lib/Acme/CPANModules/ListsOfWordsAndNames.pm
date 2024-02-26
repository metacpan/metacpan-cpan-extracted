package Acme::CPANModules::ListsOfWordsAndNames;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-10-29'; # DATE
our $DIST = 'Acme-CPANModules-ListsOfWordsAndNames'; # DIST
our $VERSION = '0.002'; # VERSION

use strict;
use Acme::CPANModulesUtil::Misc;

our $LIST = {
    summary => 'List of modules that contain lists of words and names',
    description => <<'_',

The following namespaces are for modules that contain lists of words and names:

<pm:Games::Words::Wordlist> modules usually contain dictionary words, originally
created to be source of words for word games e.g. hangman.

Instead of words, <pm:Games::Words::Phraselist> modules contain phrases. These
are also usually used for games like hangman.

<pm:WordList> modules contains lists of words and are more general than
Games::Words::Wordlist::*.

<pm:Acme::MetaSyntactic> modules (themes) contain list of names that are suited
for varible names, etc. They range from movie/TV characters, people names, to
plants, dishes, and so on.

_
};

Acme::CPANModulesUtil::Misc::populate_entries_from_module_links_in_description;

1;
# ABSTRACT: List of modules that contain lists of words and names

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::ListsOfWordsAndNames - List of modules that contain lists of words and names

=head1 VERSION

This document describes version 0.002 of Acme::CPANModules::ListsOfWordsAndNames (from Perl distribution Acme-CPANModules-ListsOfWordsAndNames), released on 2023-10-29.

=head1 DESCRIPTION

The following namespaces are for modules that contain lists of words and names:

L<Games::Words::Wordlist> modules usually contain dictionary words, originally
created to be source of words for word games e.g. hangman.

Instead of words, L<Games::Words::Phraselist> modules contain phrases. These
are also usually used for games like hangman.

L<WordList> modules contains lists of words and are more general than
Games::Words::Wordlist::*.

L<Acme::MetaSyntactic> modules (themes) contain list of names that are suited
for varible names, etc. They range from movie/TV characters, people names, to
plants, dishes, and so on.

=head1 ACME::CPANMODULES ENTRIES

=over

=item L<Games::Words::Wordlist>

=item L<Games::Words::Phraselist>

=item L<WordList>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Acme::MetaSyntactic>

Author: L<BOOK|https://metacpan.org/author/BOOK>

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

 % cpanm-cpanmodules -n ListsOfWordsAndNames

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries ListsOfWordsAndNames | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=ListsOfWordsAndNames -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::ListsOfWordsAndNames -E'say $_->{module} for @{ $Acme::CPANModules::ListsOfWordsAndNames::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-ListsOfWordsAndNames>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-ListsOfWordsAndNames>.

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-ListsOfWordsAndNames>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
