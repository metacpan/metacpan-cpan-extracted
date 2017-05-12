package Catmandu::Store::Resolver::Bag;

use Moo;
use JSON;

use Catmandu::Sane;
use Catmandu::Store::Resolver::API;

with 'Catmandu::Bag';

has api => (is => 'lazy');

has pid => (is => 'rw');

sub _build_api {
    my $self = shift;
    my $api = Catmandu::Store::Resolver::API->new(
        url => $self->store->url,
        username => $self->store->username,
        password => $self->store->password
    );
    return $api;
}

around add => sub {
    my ($orig, $self, $data) = @_;
    $self->$orig($data);
    $data->{'_id'} = $self->pid;
    return $data;
};

around update => sub {
    my ($orig, $self, $data) = @_;
    $self->$orig($data);
    $data->{'_id'} = $self->pid;
    return $data;
};

sub generator {
    my $self = shift;
}

sub get {
    my ($self, $id) = @_;
    return $self->api->get($id);
}

sub add {
    my ($self, $data) = @_;
    my $response = $self->api->post($data);
    if (defined($response->{'data'}->{'work_pid'})) {
        $self->pid($response->{'data'}->{'work_pid'});
    } else {
        $self->pid($response->{'data'}->{'persistentURIs'}->[0]);
    }
}

sub update {
    my ($self, $id, $data) = @_;
    my $response = $self->api->put($id, $data);
    if (defined($response->{'data'}->{'work_pid'})) {
        $self->pid($response->{'data'}->{'work_pid'});
    } else {
        $self->pid($response->{'data'}->{'persistentURIs'}->[0]);
    }
}

sub delete {
    my ($self, $id) = @_;
    return $self->api->delete($id);
}

sub delete_all {
    my $self = shift;
}

1;