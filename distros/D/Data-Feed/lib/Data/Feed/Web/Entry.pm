package Data::Feed::Web::Entry;
use Any::Moose '::Role';
use Data::Feed::Web::Enclosure;

with 'Data::Feed::Item';

sub BUILD {
    my ($self, $args) = @_;

    my $entry = $self->entry;
    foreach my $method (qw( title link content summary category author id issued modified )) {
        if (exists $args->{$method}) {
            $self->$method( $args->{ $method } );
        }
    }
    return $self;
}

requires 'extract_node_values';
requires 'title';
requires 'link';
requires 'content';
requires 'summary';
requires 'category';
requires 'author';
requires 'id';
requires 'issued';
requires 'modified';
requires 'enclosures';

no Any::Moose '::Role';

1;

__END__

=head1 NAME

Data::Feed::Web::Entry - Role For Web-Related Feed Entry

=cut
