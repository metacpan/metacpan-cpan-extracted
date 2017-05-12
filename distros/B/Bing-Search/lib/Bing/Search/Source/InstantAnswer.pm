package Bing::Search::Source::InstantAnswer;
use Moose;
extends 'Bing::Search::Source';


with qw(
Bing::Search::Role::SearchRequest::Market
Bing::Search::Role::SearchRequest::Version
Bing::Search::Role::SearchRequest::Latitude
Bing::Search::Role::SearchRequest::Longitude
);

sub _build_source_name { 'InstantAnswer' }

__PACKAGE__->meta->make_immutable;

=head1 NAME

Bing::Search::Source::InstantAnswer - Get "instant" answer from Bing

=head1 SYNOPSIS

 my $source = Bing::Search::Source::InstantAnswer->new;

=head1 DESCRIPTION

The InstantAnswer Source will provide "instant" answers for two 
very specific (as of right now) types of requests -- 
one from Encarta (usually definitions of words) and for
the airline flight status updates.

In both cases, Bing chooses the proper result based on the 
query.  The generally accepted -- but not guaranteed -- 
method to get an Encarta result is to use a query like:

 define rocks

For flight status updates, the general format is the airline 
code followed by the flight number.  For example, American Airlines
flight 100 would be a query of:

 aa100

=head1 METHODS

=over 3

=item C<Market>, C<Version>, C<Latitude>, C<Longitude>

See L<Bing::Search> for documentation of this common attributes.

=back

=head1 AUTHOR

Dave Houston, L< dhouston@cpan.org >, 2010

=head1 LICENSE

This library is free software; you may redistribute and/or modify it
under the same terms as Perl itself.
