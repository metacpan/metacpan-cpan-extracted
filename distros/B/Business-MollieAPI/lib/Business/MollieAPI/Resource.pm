package Business::MollieAPI::Resource;
use Moo::Role;
use HTTP::Request;
use HTTP::Request::Common;
use JSON::XS;

has client => (
    is => 'ro',
);

requires 'name';

sub _create_request {
    my $self = shift;
    my %args = @_;

    my $url = URI->new_abs(
        '/' . $self->client->version . '/' . $self->name,
        $self->client->endpoint);

    my $body = encode_json(\%args);

    my $req = POST $url->as_string,
        Content_Type => 'application/json',
        Content => $body;

    return $req;
}

sub create {
    my $self = shift;
    my $req = $self->_create_request(@_);
    my $res = $self->client->perform($req);
    return $res;
}

sub _get_request {
    my $self = shift;
    my ($id) = @_;

    my $url = URI->new_abs(
        '/' . $self->client->version . '/' . $self->name . '/' . $id,
        $self->client->endpoint);

    return GET $url->as_string;
}

sub get {
    my $self = shift;
    my $req = $self->_get_request(@_);
    my $res = $self->client->perform($req);
    return $res;
}

sub _all_request {
    my $self = shift;

    my $url = URI->new_abs(
        '/' . $self->client->version . '/' . $self->name,
        $self->client->endpoint);

    return GET $url->as_string;
}

sub all {
    my $self = shift;
    my $req = $self->_all_request(@_);
    my $res = $self->client->perform($req);
    return $res;
}

1;

