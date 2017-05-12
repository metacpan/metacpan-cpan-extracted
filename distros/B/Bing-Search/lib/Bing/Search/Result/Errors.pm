package Bing::Search::Result::Errors;
use Moose;
extends 'Bing::Search::Result';

with 'Bing::Search::Role::Types::UrlType';

with qw(
   Bing::Search::Role::Result::Code
   Bing::Search::Role::Result::Message
   Bing::Search::Role::Result::Parameter
   Bing::Search::Role::Result::HelpUrl
   Bing::Search::Role::Result::Value
);

__PACKAGE__->meta->make_immutable;

=head1 NAME

Bing::Search::Result::Errors - Error result

=head1 DESCRIPTION

This particular result is special.  It indicates that something you
did Bing didn't link.  It certaintly isn't a bug, of course.  

See L<http://msdn.microsoft.com/en-us/library/dd251042.aspx> for 
documented error codes.  

Additionally, if relevent, Bing will return an attribute, C<HelpUrl>
to direct your attention to some more detailed problem solving.

=head1 METHODS

=over 3

=item C<Code>

An error code, almost always a number.

=item C<Message>

The message itself.  Terrifying things like "Required parameter missing".

=item C<Parameter>

If relevent, Bing will tell you which parameter in your request broke.

=item C<HelpUrl>

A L<URI> object containing a URL to point you at More Help.

=item C<Value>

The value Bing got for the C<Parameter> that broke.  

=back

=head1 AUTHOR

Dave Houston, L< dhouston@cpan.org >, 2010

=head1 LICENSE

This library is free software; you may redistribute and/or modify it 
under the same terms as Perl itself.
