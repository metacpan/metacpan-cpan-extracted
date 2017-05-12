package Bing::Search::Source::Translation;
use Moose;
extends 'Bing::Search::Source';

with qw(
Bing::Search::Role::TranslationRequest::SourceLanguage
Bing::Search::Role::TranslationRequest::TargetLanguage
);

sub _build_source_name { 'Translation' }

__PACKAGE__->meta->make_immutable;

=head1 NAME

Bing::Search::Source::Translation - Translate with Bing

=head1 METHODS

=over 3

=item C<Translation_SourceLanguage> and C<Translation_TargetLanguage>

These methods describe the source and target langauge for the 
translation request.  The language codes are RFC1766-style

See L<http://msdn.microsoft.com/en-us/library/dd877907.aspx> for a
list of valid language codes.  

=head1 SEE ALSO

=over 3

=item * RFC1766 - L<http://datatracker.ietf.org/doc/rfc1766/>

=back

=head1 AUTHOR

Dave Houston, L< dhouston@cpan.org >, 2010

=head1 LICENSE

This library is free software; you may redistribute and/or modify it under
the same terms as Perl itself.
