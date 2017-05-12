package Bing::Search::Source::MobileWeb;
use Moose;
extends 'Bing::Search::Source';

with 'Bing::Search::Role::MobileWebRequest::Count';

with qw(
Bing::Search::Role::SearchRequest::Market
Bing::Search::Role::SearchRequest::Version
Bing::Search::Role::SearchRequest::Latitude
Bing::Search::Role::SearchRequest::Longitude
Bing::Search::Role::SearchRequest::Options
Bing::Search::Role::MobileWebRequest::Offset
Bing::Search::Role::MobileWebRequest::Options
);

sub _build_source_name { 'MobileWeb' }

__PACKAGE__->meta->make_immutable;

=head1 NAME

Bing::Search::Source::MobileWeb - Source for MobileWeb documents

=head1 METHODS

=over 3

=item C<Market>, C<Version>, C<Latitude>, C<Longitude>, C<Options>, and C<setOptions>

See L<Bing::Search> for documentation of this common attributes.

=item C<MobileWeb_Count>, C<MobileWeb_Offset>

The number of documents to return, and the offset.

=item C<setMobileWeb_Option> and C<MobileWeb_Options>

Use the C<setMobileWeb_Option> method to set appropriate appropriate
options.  The two valid options are: DisableHostCollapsing and DisableQueryAlterations.

More information on what each of these does is available at
L<http://msdn.microsoft.com/en-us/library/dd560917.aspx>

=back

=head1 AUTHOR

Dave Houston, L< dhouston@cpan.org >, 2010

=head1 LICENSE

This library is free software; you may redistribute and/or modify it under
the same terms as Perl itself.
