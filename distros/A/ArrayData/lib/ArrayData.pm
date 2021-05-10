package ArrayData;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-05-07'; # DATE
our $DIST = 'ArrayData'; # DIST
our $VERSION = '0.2.2'; # VERSION

1;
# ABSTRACT: Specification for ArrayData::*, modules that contains array data

__END__

=pod

=encoding UTF-8

=head1 NAME

ArrayData - Specification for ArrayData::*, modules that contains array data

=head1 SPECIFICATION VERSION

0.2

=head1 VERSION

This document describes version 0.2.2 of ArrayData (from Perl distribution ArrayData), released on 2021-05-07.

=head1 SYNOPSIS

Use one of the C<ArrayData::*> modules.

=head1 DESCRIPTION

B<NOTE: EARLY SPECIFICATION; THINGS WILL STILL CHANGE A LOT>.

C<ArrayData::*> modules are modules that contain array data. The array can be
stored in an actual Perl array in the source code, or as lines in the DATA
section of the source code, or in other places. The array data can be accessed
via a standard interface (see L<ArrayDataRole::Spec::Basic>). Some examples of
array data are:

=over

=item * list of country names in English (L<ArrayData::CountryName::EN>)

=item * list of Indonesian words from L<KBBI|https://kbbi.kemdikbud.go.id/> dictionary (L<ArrayData::Word::ID::KBBI>)

Also under L<WordList::ID::KBBI>.

=item * list of CPAN authors' PAUSE ID's (L<ArrayData::CPAN::PAUSEID>)

Also under L<WordList::CPAN::PAUSEID>.

=back

Why put data in a Perl module, as a Perl distribution? To leverage the Perl/CPAN
toolchain and infrastructure: 1) ease of installation, update, and
uninstallation; 2) allowing dependency expression and version comparison; 3)
ease of packaging further as OS packages, e.g. Debian packages (converted from
Perl distribution); 4) testing by CPAN Testers.

To get started, see L<ArrayDataRole::Spec::Basic> and one of existing
C<ArrayData::*> modules.

=head1 NAMESPACE ORGANIZATION

C<ArrayData> (this module) is the specification.

All the modules under C<ArrayData::*> should be modules with actual data (base
classes should be put in C<ArrayDataBase::*>, roles in C<ArrayDataRole::*>).

More specific subnamespaces for more specific types of elements:

=over

=item * C<ArrayData::String::*>

Strings. (But please see other more specific names.)

=item * C<ArrayData::Word::*>

Dictionary word lists (further classified as (further classified in
C<ArrayData::Word::>I<LanguageCode>C<::*> e.g. L<ArrayData::Word::ID::KBBI>).
These are designed to replace old L<WordList>::* modules.

=item * C<ArrayData::Phrase::*>

Phrase lists. Designed to replace old C<WordList::Phrase::*> modules.

=item * C<ArrayData::CPAN::*>

Arrays related to CPAN. Designed to replace old C<WordList::Domain::*> modules.

=item * C<ArrayData::Domain::*>

Domain names or suffixes. Designed to replace old C<WordList::Domain::*>
modules.

=item * C<ArrayData::HTTP::*>

HTTP-related array data. Designed to replace old C<WordList::HTTP::*>
modules.

=item * C<ArrayData::Number::*>

Numbers.

=item * C<ArrayData::Password::*>

Passwords. Designed to replace old C<WordList::HTTP::*> modules.

=back

C<ArrayDataBase::*> the base classes. C<ArrayDataBases::*> are main module names
for distributions that bundle multiple base classes.

C<ArrayDataRole::*> the roles. C<ArrayDataRoles::*> are main module names for
distributions that bundle multiple roles.

C<ArrayDataBundle::*> are main module names for distributions that contain
several C<ArrayData> modules.

=head1 FAQ

=head2 Should I use WordList or ArrayData (ArrayData::Word)?

Both are okay. If you prefer WordList then by all means use it. Existing
WordList::* modules will stay. WordList's API is now frozen. New development and
updates to word lists will happen mostly in ArrayData only.

=head2 What are the differences between ArrayData and WordList?

Method names:

 Function                       In WordList                                      In ArrayData
 --------                       -----------                                      ------------
 iterating words                each_word()                                      each_item() (from Role::TinyCommons::Iterator::Resettable)
                                reset_iterator() + first_word() + next_word()    reset_iterator() + has_next_item() + get_next_item() (from Role::TinyCommons::Iterator::Resettable)
 checking if a word exists      word_exists()                                    has_item() (from Role::TinyCommons::Collection::FindItem)
 getting all words              all_words()                                      get_all_items() (from Role::TinyCommons::Iterator::Resettable)
 picking random words           pick()                                           pick_items() (from Role::TinyCommons::Collection::PickItems)

Additional roles:

 Function                       In WordList                         In ArrayData
 --------                       -----------                         ------------
 Binary search                  WordListRole::BinarySearch          ArrayDataRole::BinarySearch::LinesInHandle
 Bloom filter                   WordListRole::Bloom                 ArrayDataRole::Bloom

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/ArrayData>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-ArrayData>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-ArrayData/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<HashData>, L<TableData> are related projects.

L<WordList> is an older, related project. ArrayData and its sister projects
L<HashData> & L<TableData> are a generalization and cleanup of the WordList API.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
