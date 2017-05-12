package Bing::Search::Result::Translation;
use Moose;
extends 'Bing::Search::Result';


with qw(
   Bing::Search::Role::Result::TranslatedTerm
);

__PACKAGE__->meta->make_immutable;

=head1 NAME

Bing::Search::Result::Translation - Translations by Bing!

=head1 METHODS

=over 3

=item C<TranslatedTerm>

The translated .. term.  I know, huh.

=back

=head1 AUTHOR

Dave Houston, L< dhouston@cpan.org >, 2010

=head1 LICENSE

This library is free software; you may redistribute and/or modify it under
the same terms as Perl itself.

