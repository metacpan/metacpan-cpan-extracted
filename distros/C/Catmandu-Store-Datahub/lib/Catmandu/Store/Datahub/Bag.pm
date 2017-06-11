package Catmandu::Store::Datahub::Bag;

use Moo;
use Scalar::Util qw(reftype);
use LWP::UserAgent;
use Catmandu::Util qw(is_string require_package);
use Time::HiRes qw(usleep);
use Catmandu::Sane;
use Catmandu::Store::Datahub::API;
use JSON;

with 'Catmandu::Bag';

has api => (is => 'lazy');

sub _build_api {
    my $self = shift;
    my $api = Catmandu::Store::Datahub::API->new(
        url           => $self->store->url,
        client_id     => $self->store->client_id,
        client_secret => $self->store->client_secret,
        username      => $self->store->username,
        password      => $self->store->password
    );
    return $api;
}

##
# before add in ::Bag creates a _id tag, which is useful for hashes and NoSQL-dbs, but breaks our
# XML conversion. You *can* remove it in your add/update function, but that feels unclean.
# You cannot use before add here to remove the _id, as this one is added before the before add
# from ::Bag (see http://search.cpan.org/~ether/Moose-2.1806/lib/Moose/Manual/MethodModifiers.pod).
# But around is called last. So we use it here.
around add => sub {
    my $orig = shift;
    my ($self, $data) = @_;
    delete $data->{'_id'};
    return $self->$orig($data);
};

sub generator {
    my $self = shift;
    # api/v1/data -> results ; not paginated
    my $stack = $self->api->list()->{'results'};
    return sub {
        return pop @{$stack};
    };
}

sub each {
    my ($self, $sub) = @_;
    my $n = 0;
    my $stack = $self->api->list()->{'results'};
    while (my $item = pop @{$stack}) {
        $sub->($item);
        $n++;
    }
    return $n;
}


##
# Return a record identified by $id
sub get {
    my ($self, $id) = @_;
    return $self->api->get($id);
}

##
# Create a new record
sub add {
    my ($self, $data) = @_;
    return $self->api->update($data->{'id'}, $data->{'_'});
}

##
# Delete a record
sub delete {
    my ($self, $id) = @_;
    return $self->api->delete($id);
}

sub delete_all {}

1;

__END__
