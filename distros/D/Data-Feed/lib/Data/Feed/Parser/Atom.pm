
package Data::Feed::Parser::Atom;
use Any::Moose;
use Data::Feed::Atom;
use XML::Atom::Feed;

with 'Data::Feed::Parser';

__PACKAGE__->meta->make_immutable;

no Any::Moose;

sub parse {
    my ($self, $xmlref) = @_;

    return Data::Feed::Atom->new(feed => XML::Atom::Feed->new(Stream => $xmlref) );
}

1;

__END__

=head1 NAME

Data::Feed::Parser::Atom - Data::Feed Atom Parser

=head1 METHODS

=head2 parse

=cut
