package Data::Feed::Atom;
use Any::Moose;
use Data::Feed::Atom::Entry;
use XML::Atom::Feed;
use XML::Atom::Person;
use DateTime::Format::W3CDTF;
use constant format => 'Atom';

has feed => (
    is => 'rw',
    isa => 'XML::Atom::Feed',
    handles => {
        description => 'tagline',
        map { ( $_ => $_ ) }
            qw(title copyright language generator id updated tagline as_xml icon base),
    },
    required => 1,
    lazy_build => 1,
);

with 'Data::Feed::Web::Feed';

__PACKAGE__->meta->make_immutable;

no Any::Moose;

sub _build_feed {
    return XML::Atom::Feed->new;
}

sub link {
    my $self = shift;
    if (@_) {
        return $self->feed->add_link({ rel => 'alternate', href => $_[0],
                                  type => 'text/html', });
    } else {
        foreach my $link ($self->feed->link) {
            if (defined $link && ! defined $link->rel || $link->rel eq 'alternate' ) {
                return $link->href;
            }
        }
    }
    return ();
}

sub author {
    my $self = shift;
    if (@_ && $_[0]) {
        my $person = XML::Atom::Person->new(Namespace => $self->feed->ns, Version => 1.0);
        $person->name($_[0]);
        $self->feed->author($person);
    } else {
        my $person = $self->feed;
        return $person->author ? $person->author->name : ();
    }
}

sub modified {
    my $self = shift;
    if (@_) {
        $self->feed->modified(DateTime::Format::W3CDTF->format_datetime($_[0]));
    } else {
        return Data::Feed->parse_w3cdtf_date($self->feed->modified);
    }
}

sub entries {
    my $self = shift;

    my @entries;
    for my $entry ($self->feed->entries) {
        push @entries, Data::Feed::Atom::Entry->new(entry => $entry);
    }

    return @entries;
}

sub add_entry {
    my ($self, $entry) = @_;
    return $self->feed->add_entry($entry->entry);
}

1;

__END__

=head1 NAME

Data::Feed::Atom - Atom Feed

=head2 add_entry

=head2 author

=head2 copyright

=head2 description

=head2 entries

=head2 format

=head2 generator

=head2 language

=head2 link

=head2 modified

=head2 title

=head2 icon

=head2 base

=cut

