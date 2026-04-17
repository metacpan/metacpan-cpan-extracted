package Apertur::SDK::Resource::Keys;

use strict;
use warnings;

use JSON qw(encode_json);

sub new {
    my ($class, %args) = @_;
    return bless { http => $args{http} }, $class;
}

sub list {
    my ($self, $project_id) = @_;
    return $self->{http}->request('GET', "/api/v1/projects/$project_id/keys");
}

sub create {
    my ($self, $project_id, %options) = @_;
    return $self->{http}->request(
        'POST', "/api/v1/projects/$project_id/keys",
        body => encode_json(\%options),
    );
}

sub update {
    my ($self, $project_id, $key_id, %options) = @_;
    return $self->{http}->request(
        'PATCH', "/api/v1/projects/$project_id/keys/$key_id",
        body => encode_json(\%options),
    );
}

sub delete {
    my ($self, $project_id, $key_id) = @_;
    return $self->{http}->request(
        'DELETE', "/api/v1/projects/$project_id/keys/$key_id",
    );
}

sub set_destinations {
    my ($self, $key_id, $destination_ids, $long_polling) = @_;

    my %payload = (destination_ids => $destination_ids);
    $payload{long_polling_enabled} = $long_polling
        if defined $long_polling;

    return $self->{http}->request(
        'PUT', "/api/v1/keys/$key_id/destinations",
        body => encode_json(\%payload),
    );
}

1;

__END__

=head1 NAME

Apertur::SDK::Resource::Keys - API key management

=head1 DESCRIPTION

Manages API keys within a project, including destination assignments.

=head1 METHODS

=over 4

=item B<list($project_id)>

Lists all API keys for a project.

=item B<create($project_id, %options)>

Creates a new API key.

=item B<update($project_id, $key_id, %options)>

Updates an API key's settings.

=item B<delete($project_id, $key_id)>

Deletes an API key.

=item B<set_destinations($key_id, \@destination_ids, $long_polling)>

Assigns destinations to an API key. C<$long_polling> is an optional
boolean to enable or disable long polling.

=back

=cut
