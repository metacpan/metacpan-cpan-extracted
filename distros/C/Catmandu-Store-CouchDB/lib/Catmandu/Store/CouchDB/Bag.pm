package Catmandu::Store::CouchDB::Bag;

use Catmandu::Sane;
use Moo;

with 'Catmandu::Bag';

sub BUILD {
    my ($self) = @_;
    $self->store->couch_db->create_db($self->name);
}

sub generator {
    my ($self) = @_;
    sub {
        state $i = 0;
        state $rows = do {
           $self->store->couch_db->method('GET');
           my $res = $self->store->couch_db->_call($self->name.'/_all_docs');
           $res->{rows};
        };
        while (my $row = $rows->[$i++]) {
            my $key = $row->{key};
            if ($key =~ /^_design/) {
                next;
            }
            return $self->get($key) || next;
        }
        return;
    };
}

sub get {
    my ($self, $id) = @_;
    $self->store->couch_db->get_doc({dbname => $self->name, id => $id});
}

sub add {
    my ($self, $data) = @_;
    my ($id, $rev ) = $self->store->couch_db->put_doc({dbname => $self->name, doc => $data});
    $data->{_id}  = $id;
    $data->{_rev} = $rev;
}

sub delete {
    my ($self, $id) = @_;
    $self->store->couch_db->del_doc({dbname => $self->name, id => $id});
}

sub delete_all {
    my ($self) = @_;
    $self->each(sub {
        $self->delete($_[0]->{_id});
    });
}

1;
