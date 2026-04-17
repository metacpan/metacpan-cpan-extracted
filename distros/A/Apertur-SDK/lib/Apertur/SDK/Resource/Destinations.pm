package Apertur::SDK::Resource::Destinations;

use strict;
use warnings;

use JSON qw(encode_json);

sub new {
    my ($class, %args) = @_;
    return bless { http => $args{http} }, $class;
}

sub list {
    my ($self, $project_id) = @_;
    return $self->{http}->request('GET', "/api/v1/projects/$project_id/destinations");
}

sub create {
    my ($self, $project_id, %config) = @_;
    return $self->{http}->request(
        'POST', "/api/v1/projects/$project_id/destinations",
        body => encode_json(\%config),
    );
}

sub update {
    my ($self, $project_id, $dest_id, %config) = @_;
    return $self->{http}->request(
        'PATCH', "/api/v1/projects/$project_id/destinations/$dest_id",
        body => encode_json(\%config),
    );
}

sub delete {
    my ($self, $project_id, $dest_id) = @_;
    return $self->{http}->request(
        'DELETE', "/api/v1/projects/$project_id/destinations/$dest_id",
    );
}

sub test {
    my ($self, $project_id, $dest_id) = @_;
    return $self->{http}->request(
        'POST', "/api/v1/projects/$project_id/destinations/$dest_id/test",
    );
}

1;

__END__

=head1 NAME

Apertur::SDK::Resource::Destinations - Destination management

=head1 DESCRIPTION

Manages upload destinations (S3, webhook, long-poll queue, etc.)
within a project.

=head1 METHODS

=over 4

=item B<list($project_id)>

Lists all destinations for a project.

=item B<create($project_id, %config)>

Creates a new destination.

=item B<update($project_id, $dest_id, %config)>

Updates a destination's configuration.

=item B<delete($project_id, $dest_id)>

Deletes a destination.

=item B<test($project_id, $dest_id)>

Triggers a test delivery to a destination.

=back

=cut
