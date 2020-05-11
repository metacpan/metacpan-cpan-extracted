package Acme::CPANModules::ListsOfWordsAndNames;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-03-01'; # DATE
our $DIST = 'Acme-CPANModules-ListsOfWordsAndNames'; # DIST
our $VERSION = '0.001'; # VERSION

use strict;
use Acme::CPANModulesUtil::Misc;

our $LIST = {
    summary => 'Modules that contain lists of words and names',
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
# ABSTRACT: Modules that contain lists of words and names

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::ListsOfWordsAndNames - Modules that contain lists of words and names

=head1 VERSION

This document describes version 0.001 of Acme::CPANModules::ListsOfWordsAndNames (from Perl distribution Acme-CPANModules-ListsOfWordsAndNames), released on 2020-03-01.

=head1 DESCRIPTION

Modules that contain lists of words and names.

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

=head1 INCLUDED MODULES

=over

=item * L<Games::Words::Wordlist>

=item * L<Games::Words::Phraselist>

=item * L<WordList>

=item * L<Acme::MetaSyntactic>

=back

=head1 FAQ

=head2 What are ways to use this module?

Aside from reading it, you can install all the listed modules using
L<cpanmodules>:

    % cpanmodules ls-entries ListsOfWordsAndNames | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=ListsOfWordsAndNames -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

This module also helps L<lcpan> produce a more meaningful result for C<lcpan
related-mods> when it comes to finding related modules for the modules listed
in this Acme::CPANModules module.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-ListsOfWordsAndNames>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-ListsOfWordsAndNames>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-ListsOfWordsAndNames>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
