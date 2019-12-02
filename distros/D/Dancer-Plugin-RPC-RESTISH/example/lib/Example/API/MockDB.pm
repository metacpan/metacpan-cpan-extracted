package Example::API::MockDB;
use Moo;

use Dancer::RPCPlugin::ErrorResponse;

has db => (is => 'rw');

my $_sequence = 0;

=head2 create_person

=for restish PUT@person create_person

=cut

sub create_person {
    my $self = shift;
    my %data = %{ $_[0] };

    my $id = exists $data{id} ? $data{id} : ++$_sequence;

    if (exists $self->db->{person}{$id}) {
        $self->db->{person}{$id} = \%data;
    }
    else {
        $self->db->{person}{$id} = {
            %data,
            id => $id,
        };
    }
    return $self->db->{person}{$id};
}

=head2 get_person

=for restish GET@person/:id get_person

=cut

sub get_person {
    my $self = shift;
    my %data = %{$_[0]};

    die error_response(
        error_message => "No id for person provided...",
    ) if !exists($data{id});

    my $id = $data{id};
    if (!exists($self->db->{person}{$id})) {
        my $error = error_response(
            error_code    => 404,
            error_message => "Could not find person::$data{id}...",
            error_data    => \%data,
        );
        $error->http_status(404);
        return $error;
    }

    return $self->db->{person}{$id};
}

=head2 update_person

=for restish POST@person/:id update_person

=cut

sub update_person {
    my $self = shift;
    my %data = %{ $_[0] };

    my $id = delete($data{id});
    if (!$id) {
        my $error = error_response(
            error_code => -32601,
            error_message => "Cannot update without ID...",
            error_data => \%data,
        );
        $error->http_status(400); # Bad request
        return $error;
    }

    my $record = $self->db->{person}{$id};
    if (!$record) {
        my $error = error_response(
            error_code => -32601,
            error_message => "Could not find person ($id)...",
            error_data => { id => $id, %data },
        );
        $error->http_status(404); # Not found
        return $error;
    }

    for my $key (keys %data) {
        $record->{$key} = $data{$key};
    }

    return $self->db->{person}{$id};
}

=head2 get_all_persons

=for restish GET@persons get_all_persons

=cut

sub get_all_persons {
    my $self = shift;

    return [
        map { $self->db->{person}{$_} } sort { $a <=> $b } keys %{ $self->db->{person} }
    ];
}

1;
