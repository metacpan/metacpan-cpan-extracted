package Catmandu::Store::Adlib::Bag;

use strict;
use warnings;

use Moo;
use Catmandu::Sane;

use Catmandu::Adlib::API;

with 'Catmandu::Bag';

has api => (is => 'lazy');

sub _build_api {
    my $self = shift;
    return Catmandu::Adlib::API->new(
        username => $self->store->username,
        password => $self->store->password,
        endpoint => $self->store->endpoint,
        database => $self->store->database
    );
}


sub generator {
    # TODO: OAI
    my $self = shift;
    my $stack = $self->api->list()->{'adlibJSON'}->{'recordList'}->{'record'};
    # TODO: PAGING
    return sub {
        my $item = pop @{$stack};
        my $priref = $self->api->get_priref($item);
        return $self->api->get_by_priref($priref);
    };
}

sub each {
    my ($self, $sub) = @_;
    my $n = 0;
    my $list = $self->api->list();
    my $stack = $list->{'adlibJSON'}->{'recordList'}->{'record'};
    my $start = $list->{'adlibJSON'}->{'diagnostic'}->{'first_item'};
    my $hits = $list->{'adlibJSON'}->{'diagnostic'}->{'hits'};
    my $limit = $list->{'adlibJSON'}->{'diagnostic'}->{'limit'};
    my $new_start;
    while (my $item = pop @{$stack}) {
        if (scalar @{$stack} == 0) {
            # Stack is empty; add the next page
            $new_start = $start + $limit;
            if ($new_start <= $hits) {
                $list = $self->api->list($new_start);
                $stack = $list->{'adlibJSON'}->{'recordList'}->{'record'};
                $start = $list->{'adlibJSON'}->{'diagnostic'}->{'first_item'};
                $limit = $list->{'adlibJSON'}->{'diagnostic'}->{'limit'};
            }
        }
        my $priref = $self->api->get_priref($item);
        # Spare the API a bit
        sleep(int(rand(2)));
        my $full_item = $self->api->get_by_priref($priref);
        $sub->($full_item);
        $n++;
    }
    return $n;
}

sub get {
    my ($self, $id) = @_;
    return $self->api->get_by_priref($id);
}

sub add {
    my ($self, $data) = @_;
    return $self->api->add($data);
}

sub update {
    my ($self, $id, $data) = @_;
    return $self->api->update($id, $data);
}

sub delete {
    my ($self, $id) = @_;
    return $self->api->delete($id);
}

sub delete_all {
    my $self = shift;
    Catmandu::NotImplemented->throw(
        message => 'Deleting items from store not supported.'
    );
}
1;
__END__