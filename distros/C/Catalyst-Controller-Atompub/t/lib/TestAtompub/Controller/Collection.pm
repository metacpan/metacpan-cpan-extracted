package TestAtompub::Controller::Collection;

use strict;
use warnings;

use XML::Atom::Entry;

use base qw(Catalyst::Controller::Atompub::Collection);

sub get_feed :Atompub(list) {
    my($self, $c) = @_;
    $self->collection_resource->body->add_entry($self->_make_entry);
    return $self;
}

sub get_resource :Atompub(read) {
    my($self, $c) = @_;
    $self->entry_resource->body($self->_make_entry);
    return $self;
}

sub _make_entry {
    my $entry = XML::Atom::Entry->new;

    my $link = XML::Atom::Link->new;
    $link->rel('edit');
    $link->href('http://localhost/collection/entry_1.atom');
    $entry->add_link( $link );

    $entry->edited('2007-01-01T00:00:00Z');
    $entry->updated('2007-01-01T00:00:00Z');
    $entry->title('Entry 1');
    $entry->content('This is the 1st entry');

    return $entry;
}

1;
