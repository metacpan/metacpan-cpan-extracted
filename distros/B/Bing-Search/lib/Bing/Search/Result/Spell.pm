package Bing::Search::Result::Spell;
use Moose;
extends 'Bing::Search::Result';

with 'Bing::Search::Role::Types::UrlType';

with qw(
   Bing::Search::Role::Result::Value
);

__PACKAGE__->meta->make_immutable;

=head1 NAME

Bing::Search::Result::Spell - Let Bing spell for you.

=head1 METHODS

=over 3

=item C<Value>

The properly-spelled word or term, if any.

=back

=head1 AUTHOR

Dave Houston, L< dhouston@cpan.org >, 2010

=head1 LICENSE

This library is free software; you may redistribute and/or modify it
under the same terms as Perl itself.
