package Apertur::SDK::Resource::Webhooks;

use strict;
use warnings;

use JSON qw(encode_json);
use URI::Escape qw(uri_escape);

sub new {
    my ($class, %args) = @_;
    return bless { http => $args{http} }, $class;
}

sub list {
    my ($self, $project_id) = @_;
    return $self->{http}->request('GET', "/api/v1/projects/$project_id/webhooks");
}

sub create {
    my ($self, $project_id, %config) = @_;
    return $self->{http}->request(
        'POST', "/api/v1/projects/$project_id/webhooks",
        body => encode_json(\%config),
    );
}

sub update {
    my ($self, $project_id, $webhook_id, %config) = @_;
    return $self->{http}->request(
        'PATCH', "/api/v1/projects/$project_id/webhooks/$webhook_id",
        body => encode_json(\%config),
    );
}

sub delete {
    my ($self, $project_id, $webhook_id) = @_;
    return $self->{http}->request(
        'DELETE', "/api/v1/projects/$project_id/webhooks/$webhook_id",
    );
}

sub test {
    my ($self, $project_id, $webhook_id) = @_;
    return $self->{http}->request(
        'POST', "/api/v1/projects/$project_id/webhooks/$webhook_id/test",
    );
}

sub deliveries {
    my ($self, $project_id, $webhook_id, %options) = @_;
    my @parts;
    for my $key (sort keys %options) {
        next unless defined $options{$key};
        push @parts, uri_escape($key) . '=' . uri_escape($options{$key});
    }
    my $qs = @parts ? '?' . join('&', @parts) : '';
    return $self->{http}->request(
        'GET', "/api/v1/projects/$project_id/webhooks/$webhook_id/deliveries$qs",
    );
}

sub retry_delivery {
    my ($self, $project_id, $webhook_id, $delivery_id) = @_;
    return $self->{http}->request(
        'POST',
        "/api/v1/projects/$project_id/webhooks/$webhook_id/deliveries/$delivery_id/retry",
    );
}

1;

__END__

=head1 NAME

Apertur::SDK::Resource::Webhooks - Event webhook management

=head1 DESCRIPTION

Manages event webhooks within a project, including delivery history
and retry capabilities.

=head1 METHODS

=over 4

=item B<list($project_id)>

Lists all webhooks for a project.

=item B<create($project_id, %config)>

Creates a new webhook.

=item B<update($project_id, $webhook_id, %config)>

Updates a webhook's configuration.

=item B<delete($project_id, $webhook_id)>

Deletes a webhook.

=item B<test($project_id, $webhook_id)>

Triggers a test delivery for a webhook.

=item B<deliveries($project_id, $webhook_id, %options)>

Lists delivery attempts for a webhook. Options: C<page>, C<limit>.

=item B<retry_delivery($project_id, $webhook_id, $delivery_id)>

Retries a failed webhook delivery.

=back

=cut
