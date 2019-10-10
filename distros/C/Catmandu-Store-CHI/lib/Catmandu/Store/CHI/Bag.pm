package Catmandu::Store::CHI::Bag;

use Moo;
use CHI;
use Catmandu::IdGenerator::UUID;

with 'Catmandu::Bag';

has 'chi'    => (is => 'ro' , lazy => 1 , builder => 1);
has 'idgen'  => (is => 'ro' , lazy => 1 , builder => 1);

sub _build_chi {
    my ($self) = @_;
    my $driver = $self->store->driver;
    my $opts   = $self->store->opts;
    my $name   = __PACKAGE__ . '::' . $self->name;
    CHI->new(namespace => $name , driver => $driver, %$opts);
}

sub _build_idgen {
    Catmandu::IdGenerator::UUID->new;
}

sub generator {
    my $self = shift;
    my $keys = [ $self->chi->get_keys ];
    sub {
        my $id = shift @$keys;

        return undef unless $id;

        $self->get($id);
    };
}

sub get {
    my ($self,$id) = @_;
    $self->chi->get($id);
}

sub add {
    my ($self,$data) = @_;
    $data->{_id} //= $self->idgen->generate;
    my $id = $data->{_id};
    $self->chi->set($id,$data);
    return $data;
}

sub delete {
    my ($self,$id) = @_;
    $self->chi->remove($id);
}

sub delete_all {
    my ($self) = @_;
    $self->chi->clear();
}

sub gen_id {
    Data::UUID->new->create_str();
}

1;
