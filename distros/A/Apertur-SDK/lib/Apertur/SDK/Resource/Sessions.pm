package Apertur::SDK::Resource::Sessions;

use strict;
use warnings;

use JSON qw(encode_json);
use URI::Escape qw(uri_escape);

sub new {
    my ($class, %args) = @_;
    return bless { http => $args{http} }, $class;
}

sub create {
    my ($self, %options) = @_;
    return $self->{http}->request(
        'POST', '/api/v1/upload-sessions',
        body => encode_json(\%options),
    );
}

sub get {
    my ($self, $uuid) = @_;
    return $self->{http}->request('GET', "/api/v1/upload/$uuid/session");
}

sub update {
    my ($self, $uuid, %options) = @_;
    return $self->{http}->request(
        'PATCH', "/api/v1/upload-sessions/$uuid",
        body => encode_json(\%options),
    );
}

sub list {
    my ($self, %params) = @_;
    my $qs = _build_query_string(%params);
    return $self->{http}->request('GET', "/api/v1/sessions$qs");
}

sub recent {
    my ($self, %params) = @_;
    my $qs = _build_query_string(%params);
    return $self->{http}->request('GET', "/api/v1/sessions/recent$qs");
}

sub qr {
    my ($self, $uuid, %options) = @_;
    my $qs = _build_query_string(%options);
    return $self->{http}->request_raw('GET', "/api/v1/upload-sessions/$uuid/qr$qs");
}

sub verify_password {
    my ($self, $uuid, $password) = @_;
    return $self->{http}->request(
        'POST', "/api/v1/upload/$uuid/verify-password",
        body => encode_json({ password => $password }),
    );
}

sub delivery_status {
    my ($self, $uuid, %opts) = @_;
    my $path = "/api/v1/upload-sessions/$uuid/delivery-status";
    my %req_opts;
    if (defined $opts{poll_from}) {
        $path .= '?pollFrom=' . uri_escape($opts{poll_from});
        # Long-poll: server holds up to 5 min; give the request 6 min so the
        # server releases first under the happy path.
        $req_opts{timeout} = 360;
    }
    return $self->{http}->request('GET', $path, %req_opts);
}

sub _build_query_string {
    my (%params) = @_;
    my @parts;
    for my $key (sort keys %params) {
        next unless defined $params{$key};
        push @parts, uri_escape($key) . '=' . uri_escape($params{$key});
    }
    return @parts ? '?' . join('&', @parts) : '';
}

1;

__END__

=head1 NAME

Apertur::SDK::Resource::Sessions - Upload session management

=head1 DESCRIPTION

Provides methods to create, retrieve, update, and list upload sessions,
as well as password verification, QR code generation, and delivery status
checking.

=head1 METHODS

=over 4

=item B<create(%options)>

Creates a new upload session. Returns the session hashref including C<uuid>.

=item B<get($uuid)>

Retrieves session details by UUID.

=item B<update($uuid, %options)>

Updates a session's settings.

=item B<list(%params)>

Lists sessions with optional pagination (C<page>, C<pageSize>).

=item B<recent(%params)>

Returns recently created sessions with optional C<limit>.

=item B<qr($uuid, %options)>

Returns the QR code image as raw bytes. Options: C<format>, C<size>,
C<style>, C<fg>, C<bg>, C<borderSize>, C<borderColor>.

=item B<verify_password($uuid, $password)>

Verifies a password for a protected session.

=item B<delivery_status($uuid, %opts)>

Returns the delivery status snapshot for a session as a hashref:

    {
        status      => 'pending' | 'active' | 'completed' | 'expired',
        files       => [ { record_id => ..., filename => ..., size_bytes => ...,
                           destinations => [ { destination_id => ..., status => ..., ... } ] } ],
        lastChanged => '<ISO 8601>',
    }

Options:

=over 4

=item C<poll_from>

ISO 8601 timestamp. When provided, the server long-polls for up to 5 minutes
waiting for something to change before responding. This call automatically
widens the per-request timeout to 360 s (6 min) so the server releases first
under the happy path.

=back

=back

=cut
