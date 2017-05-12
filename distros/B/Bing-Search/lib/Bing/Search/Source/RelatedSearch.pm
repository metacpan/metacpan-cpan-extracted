package Bing::Search::Source::RelatedSearch;
use Moose;
extends 'Bing::Search::Source';

with 'Bing::Search::Role::WebRequest::Count';

with qw(
Bing::Search::Role::SearchRequest::Market
Bing::Search::Role::SearchRequest::Version
Bing::Search::Role::SearchRequest::Options
);

sub _build_source_name { 'RelatedSearch' }

__PACKAGE__->meta->make_immutable;

=head1 NAME

Bing::Search::Source::RelatedSearch - Related searches

=head1 DESCRIPTION

Given a proper query, this source returns a list of related searches.

=head1 METHODS

=over 3

=item C<Market>, C<Version>, C<Options>, C<setOptions>

See L<Bing::Search> for documention on this common methods.

=head1 AUTHOR

Dave Houston, L< dhouston@cpan.org >, 2010

=head1 LICENSE

This library is free software; you may redistribute and/or modify it
under the same terms as Perl itself.

