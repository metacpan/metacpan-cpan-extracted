package Bing::Search::Source::Web;
use Moose;
extends 'Bing::Search::Source';

with 'Bing::Search::Role::WebRequest::Count';

with qw(
Bing::Search::Role::SearchRequest::Market
Bing::Search::Role::SearchRequest::Version
Bing::Search::Role::SearchRequest::Latitude
Bing::Search::Role::SearchRequest::Longitude
Bing::Search::Role::SearchRequest::Options
Bing::Search::Role::WebRequest::Offset
Bing::Search::Role::WebRequest::Options
Bing::Search::Role::WebRequest::FileType
);


sub _build_source_name { 'Web' }

__PACKAGE__->meta->make_immutable;

=head1 NAME

Bing::Search::Source::Web - Search the web with Bing

=head1 METHODS

=over 3

=item C<Market>, C<Version>, C<Latitude>, C<Longitude>, C<Options>, and C<setOptions>

See L<Bing::Search> for documentation on these common attributes.

=item C<Web_Count> and C<Web_Offset>

The range for C<Web_Count> is 1 to 50.

The maximum value of C<Web_Count> and C<Web_Offset> must not exceed 1,000.

=item C<Web_Options>

Contains an arrayref for options available.  See L<http://msdn.microsoft.com/en-us/library/dd250969.aspx>
for details on what each option does.  You should use C<setWeb_Option> to adjust
this.

=item C<set_WebOption>

Supply the name of an option, optionally prepended with a C<+> to add it.
Prepend a C<-> to remove it.

=item C<Web_FileType>

Select only certain file types.  See L<http://msdn.microsoft.com/en-us/library/dd250876.aspx>
for the list of valid types.  

=back

=head1 AUTHOR

Dave Houston, L< dhouston@cpan.org >, 2010

=head1 LICENSE

This library is free software; you may redistribute and/or modify it under
the same terms as Perl itself.
