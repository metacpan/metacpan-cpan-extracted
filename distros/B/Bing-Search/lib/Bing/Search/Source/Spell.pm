package Bing::Search::Source::Spell;
use Moose;
extends 'Bing::Search::Source';


with qw(
Bing::Search::Role::SearchRequest::Market
Bing::Search::Role::SearchRequest::Version
Bing::Search::Role::SearchRequest::Options
);

sub _build_source_name { 'Spell' }

__PACKAGE__->meta->make_immutable;

=head1 NAME

Bing::Search::Source::Spell - Spelling from Bing

=head1 METHODS

=over 3

=item C<Market>, C<Version>, C<Options>, and C<setOptions> 

See L<Bing::Search> for documentation on this common attributes.

=back

=head1 AUTHOR

Dave Houston, L< dhouston@cpan.org >, 2010

=head1 LICENSE

This library is free software; you may redistribute and/or modify it
under the same terms as Perl itself.
