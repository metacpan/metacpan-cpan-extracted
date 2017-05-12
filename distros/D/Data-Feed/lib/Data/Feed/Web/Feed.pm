package Data::Feed::Web::Feed;
use Any::Moose '::Role';

sub BUILD {
    my ($self, $args) = @_;

    foreach my $method (qw( author copyright description format generator language link modified title )) {
        if ( exists $args->{$method} ) {
            $self->$method( $args->{$method} );
        }
    }

    if ($args->{entries}) {
        $self->add_entry($_) for @{ $args->{entries} };
    }

    return $self;
}

requires qw(
    add_entry
    as_xml
    author
    copyright
    description
    entries
    format
    generator
    language
    link
    modified
    title
);

no Any::Moose '::Role';

1;

__END__

=head1 NAME

Data::Feed::Web::Feed - Role For Web-Related Feeds

=cut
