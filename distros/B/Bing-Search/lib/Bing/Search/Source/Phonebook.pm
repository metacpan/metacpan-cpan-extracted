package Bing::Search::Source::Phonebook;
use Moose;
extends 'Bing::Search::Source';

with 'Bing::Search::Role::PhonebookRequest::Count';

with qw(
Bing::Search::Role::SearchRequest::Market
Bing::Search::Role::SearchRequest::Version
Bing::Search::Role::SearchRequest::Adult
Bing::Search::Role::SearchRequest::UILanguage
Bing::Search::Role::SearchRequest::Latitude
Bing::Search::Role::SearchRequest::Longitude
Bing::Search::Role::SearchRequest::Radius
Bing::Search::Role::SearchRequest::Options
Bing::Search::Role::PhonebookRequest::Offset
Bing::Search::Role::PhonebookRequest::FileType
Bing::Search::Role::PhonebookRequest::LocId
Bing::Search::Role::PhonebookRequest::SortBy
);

sub _build_source_name { 'Phonebook' }

__PACKAGE__->meta->make_immutable;

=head1 NAME

Bing::Search::Source::Phonebook - Phonebook lookups with Bing. 

=head1 SYNOPSIS

 my $source = Bing::Search::Source::Phonebook->new();

=head1 METHODS

=over 3

=item C<Market>, C<Version>, C<Adult>, C<UILanguage>, C<Latitude>, C<Longitude>, C<Radius>, C<Options>, and C<setOptions>

See L<Bing::Search> for documentation on this common options.

=item C<Phonebook_Offset> and C<Phonebook_Count>

The default value for C<Phoneboot_Count> is 10, with a potential range of 1 to 25.  
The potential range for C<Phonebook_Offset> is 0 to 1,000.  The sum of both the Count and
Offset may not exceed 1,000.

=item C<Phoneook_FileType>

Selects which sort of listing to search.  Valid optionsa re B<YP> or B<WP>, for commercial
listings ("yellow pages") or residential ("white pages") respectivly.

See L<http://msdn.microsoft.com/en-us/library/dd250976.aspx> for details.  

=item C<Phonebook_LocId>

If you happen to have a C<UniqueId> value from a L<Bing::Search::Result::Phonebook>,
you can put it here to do a lookup on a specific entry.

=item C<Phonebook_SortyB>

See L<http://msdn.microsoft.com/en-us/library/dd250925.aspx> for details.

Influences the sort order of the results.  Valid options are B<Default>, B<Distance>, or
B<Relevance>.  

=back

=head1 AUTHOR

Dave Houston, L< dhouston@cpan.org >, 2010

=head1 LICENSE

This library is free software; you may redistribute and/or modify it under
the same terms as Perl itself.
