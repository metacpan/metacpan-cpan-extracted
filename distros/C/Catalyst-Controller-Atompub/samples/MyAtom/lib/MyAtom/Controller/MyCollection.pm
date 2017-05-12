package # hide from PAUSE
    MyAtom::Controller::MyCollection;

use strict;
use warnings;
use base qw(Catalyst::Controller::Atompub::Collection);

# List resources in a Feed Document, which must be implemented in
# the mehtod with "Atompub(list)" attribute
sub get_feed :Atompub(list) {
    my($self, $c) = @_;

    # Skeleton of the Feed (XML::Atom::Feed) was prepared by
    # C::C::Atompub
    my $feed = $self->collection_resource->body;

    # Retrieve Entries sorted in descending order
    my $rs = $c->model('DBIC::Entries')->search({}, {
        order_by => 'edited desc',
    });

    # Add Entries to the Feed
    while (my $entry_resource = $rs->next) {
        my $entry = XML::Atom::Entry->new(\$entry_resource->xml);
        $feed->add_entry($entry);
    }

    # Return true on success
    1;
}

# Create new Entry in the method with "Atompub(create)" attribute
sub create_entry :Atompub(create) {
    my($self, $c) = @_;

    # URI of the new Entry, which was determined by C::C::Atompub
    my $uri = $self->entry_resource->uri;

    # app:edited element, which was assigned by C::C::Atompub,
    # is coverted into UNIX time
    my $edited = $self->edited->epoch;

    # POSTed Entry (XML::Atom::Entry)
    my $entry = $self->entry_resource->body;

    # Create new Entry
    $c->model('DBIC::Entries')->create({
        uri    => $uri,
        edited => $edited,
        xml    => $entry->as_xml,
    });

    # Return true on success
    1;
}

# Search the requested Entry in the method with "Atompub(read)"
# attribute
sub get_entry :Atompub(read) {
    my($self, $c) = @_;

    my $uri = $c->req->uri;

    # Retrieve the Entry
    my $rs = $c->model('DBIC::Entries')->find({ uri => $uri });

    # Set the Entry
    my $entry = XML::Atom::Entry->new(\$rs->xml);
    $self->entry_resource->body($entry);

    # Return true on success
    1;
}

# Update the requested Entry in the method with "Atompub(update)"
# attribute
sub update_entry :Atompub(update) {
    my($self, $c) = @_;

    my $uri = $c->req->uri;

    # app:edited element, which was assigned by C::C::Atompub,
    # is coverted into UNIX time
    my $edited = $self->edited->epoch;

    # PUTted Entry (XML::Atom::Entry)
    my $entry = $self->entry_resource->body;

    # Update the Entry
    $c->model('DBIC::Entries')->find({ uri => $uri })->update({
        uri => $uri,
        edited => $edited,
        xml => $entry->as_xml,
    });

    # Return true on success
    1;
}

# Delete the requested Entry in the method with "Atompub(delete)"
# attribute
sub delete_entry :Atompub(delete) {
    my($self, $c) = @_;

    my $uri = $c->req->uri;

    # Delete the Entry
    $c->model('DBIC::Entries')->find({ uri => $uri })->delete;

    # Return true on success
    1;
}

1;
