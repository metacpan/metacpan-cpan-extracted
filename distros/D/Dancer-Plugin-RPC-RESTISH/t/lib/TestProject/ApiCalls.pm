package TestProject::ApiCalls;
use warnings;
use strict;
use Dancer ':syntax';

my $_db = { person => { } };
my $_sequence = 1;

=head2 create_person

=for restish POST@person create_person

=cut

sub create_person {
    my $method = shift;
    my %data = %{$_[0]};
    my $id = $_sequence++;
    $_db->{person}{$id} = { %data, id => $id };

    return $_db->{person}{$id};
}

=head2 update_person

=for restish PATCH@person/:id update_person

=cut

sub update_person {
    my $method = shift;
    my %data = %{$_[0]};

    if (!exists($data{id})) {
        my $error = error_response(
            error_code => 9999,
            error_message => "Cannot update without ID",
            error_data => \%data,
        );
        $error->http_status(400); # bad request
        return $error;
    }
    my $id = delete($data{id});
    if (!exists($_db->{person}{$id})) {
        my $error = error_response(
            error_code => 9998,
            error_message => "Cannot update person with $id...",
            error_data => { %data, id => $id },
        );
        $error->http_status(404); # not found
        return $error;
    }

    for my $key (keys %data) {
        $_db->{person}{$id}{$key} = $data{$key};
    }

    return $_db->{person}{$id};
}

=head2 get_person

=for restish GET@person/:id get_person

=cut

sub get_person {
    my $method = shift;
    my %data = %{$_[0]};

    if (!exists($data{id})) {
        my $error = error_response(
            error_code => 9997,
            error_message => "Cannot fetch without ID",
            error_data => \%data,
        );
        $error->http_status(400); # bad request
        return $error;
    }
    my $id = delete($data{id});
    if (!exists($_db->{person}{$id})) {
        my $error = error_response(
            error_code => 9996,
            error_message => "Cannot fetch person with $id...",
            error_data => { %data, id => $id },
        );
        $error->http_status(404); # not found
        return $error;
    }

    return $_db->{person}{$id};
}

=head2 get_all_persons

=for restish GET@persons get_all_persons

=cut

sub get_all_persons {
    return [
        map { $_db->{person}{$_} } sort {
            $a <=> $b
        } keys %{$_db->{person}}
    ];
}

1;
