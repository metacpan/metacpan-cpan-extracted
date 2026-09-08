package Antybrowser::SDK;
use strict;
use warnings;
our $VERSION = '1.0.2';
use JSON;
use LWP::UserAgent;

sub new {
    my ($class, %args) = @_;
    my $port = $args{port} || 5173;
    return bless {
        api_key  => $args{api_key} || die "api_key required",
        base_url => $args{base_url} || "http://127.0.0.1:$port",
        ua       => LWP::UserAgent->new,
        json     => JSON->new->utf8,
    }, $class;
}

sub _request {
    my ($self, $method, $path, $body) = @_;
    my $url = $self->{base_url} . $path;
    my @headers = ('x-api-key' => $self->{api_key}, 'Content-Type' => 'application/json');
    my $response;

    if ($method eq 'GET') {
        $response = $self->{ua}->get($url, @headers);
    } elsif ($method eq 'POST') {
        $response = $self->{ua}->post($url, @headers, Content => $body ? $self->{json}->encode($body) : '{}');
    } elsif ($method eq 'PUT') {
        my $req = HTTP::Request->new(PUT => $url);
        $req->push_header(@headers);
        $req->content($self->{json}->encode($body));
        $response = $self->{ua}->request($req);
    } elsif ($method eq 'DELETE') {
        my $req = HTTP::Request->new(DELETE => $url);
        $req->push_header(@headers);
        $response = $self->{ua}->request($req);
    }

    die "HTTP " . $response->code . ": " . $response->decoded_content unless $response->is_success;
    return $self->{json}->decode($response->decoded_content);
}

# System
sub get_status       { $_[0]->_request('GET', '/api/status') }
sub get_settings     { $_[0]->_request('GET', '/api/settings') }
sub get_sync_status  { $_[0]->_request('GET', '/api/sync/status') }
sub refresh_sync     { my ($self, $pid) = @_; $self->_request('POST', '/api/sync/refresh', $pid ? {profileId => $pid} : {}) }

# Profiles
sub get_profiles     { $_[0]->_request('GET', '/api/profiles') }
sub create_profile   { $_[0]->_request('POST', '/api/profiles', $_[1]) }
sub update_profile   { $_[0]->_request('PUT', "/api/profiles/$_[1]", $_[2]) }
sub delete_profile   { $_[0]->_request('DELETE', "/api/profiles/$_[1]") }
sub start_profile    { $_[0]->_request('POST', "/api/profiles/$_[1]/start") }
sub stop_profile     { $_[0]->_request('POST', "/api/profiles/$_[1]/stop") }
sub duplicate_profile { my ($self, $id, $name) = @_; $self->_request('POST', "/api/profiles/$id/duplicate", $name ? {name => $name} : {}) }

# Automations
sub get_automations  { $_[0]->_request('GET', '/api/automations') }
sub run_automation   { $_[0]->_request('POST', "/api/automations/$_[1]/run", {profileId => $_[2]}) }

# Groups
sub get_groups       { $_[0]->_request('GET', '/api/groups') }
sub create_group     { $_[0]->_request('POST', '/api/groups', $_[1]) }
sub update_group     { $_[0]->_request('PUT', "/api/groups/$_[1]", $_[2]) }
sub delete_group     { $_[0]->_request('DELETE', "/api/groups/$_[1]") }

# Proxies
sub get_proxies      { $_[0]->_request('GET', '/api/proxies') }
sub create_proxy     { $_[0]->_request('POST', '/api/proxies', $_[1]) }
sub check_proxy      { $_[0]->_request('POST', '/api/proxies/check', $_[1]) }
sub delete_proxy     { $_[0]->_request('DELETE', "/api/proxies/$_[1]") }

# Extensions
sub get_extensions           { $_[0]->_request('GET', '/api/extensions') }
sub delete_extension         { $_[0]->_request('DELETE', "/api/extensions/$_[1]") }
sub get_profile_extensions   { $_[0]->_request('GET', "/api/profiles/$_[1]/extensions") }
sub set_profile_extensions   { $_[0]->_request('POST', "/api/profiles/$_[1]/extensions", {extensionIds => $_[2]}) }

1;
__END__

=head1 NAME

Antybrowser::SDK - Official Antybrowser SDK for Perl

=head1 VERSION

Version 1.0.2

=head1 SYNOPSIS

    use Antybrowser::SDK;

    my $client = Antybrowser::SDK->new(api_key => 'your_api_key');

    # System status
    my $status = $client->get_status();

    # List profiles
    my $profiles = $client->get_profiles();

    # Create a profile
    my $profile = $client->create_profile({ name => 'My Profile' });

    # Start a profile (returns debug port)
    my $result = $client->start_profile($profile->{id});
    print "Debug port: $result->{data}{debugPort}\n";

    # Stop and delete
    $client->stop_profile($profile->{id});
    $client->delete_profile($profile->{id});

=head1 DESCRIPTION

C<Antybrowser::SDK> is the official Perl client for the
L<Antybrowser|https://antybrowser.com> Local API. It provides access to
profiles, automations, groups, proxies, and extensions of a running
Antybrowser desktop application.

=head1 INSTALLATION

=head2 From CPAN

    cpan Antybrowser::SDK

=head2 From source

    cd perl
    perl Makefile.PL
    make
    make install

=head1 PREREQUISITES

=over 4

=item *

The L<Antybrowser|https://antybrowser.com> desktop app running with the
B<Local API> enabled.

=item *

An B<API key> from Antybrowser Settings -> API.

=item *

Default port B<5173> (configurable via the C<port> option).

=back

=head1 CONSTRUCTOR

=head2 new( %args )

Creates a new client. The C<api_key> argument is required.

=over 4

=item * C<api_key> - your Antybrowser API key (required)

=item * C<port> - Local API port (default: C<5173>)

=item * C<base_url> - override the full base URL (default:
C<http://127.0.0.1:$port>)

=back

    my $client = Antybrowser::SDK->new(api_key => 'key', port => 5173);

=head1 METHODS

All methods return a decoded JSON hashref. On HTTP errors the client
dies with an error message (see L</ERROR HANDLING>).

=head2 System

=over 4

=item * C<get_status()> - get system status (health check, no auth)

=item * C<get_settings()> - get all application settings

=item * C<get_sync_status()> - get sync queue status

=item * C<refresh_sync($profile_id?)> - trigger a sync refresh,
optionally for a single profile

=back

=head2 Profiles

=over 4

=item * C<get_profiles()> - list all profiles

=item * C<create_profile($data)> - create a new profile from a hashref

=item * C<update_profile($id, $data)> - update an existing profile

=item * C<delete_profile($id)> - delete a profile

=item * C<start_profile($id)> - start a profile browser, returns the
debug port

=item * C<stop_profile($id)> - stop a running profile

=item * C<duplicate_profile($id, $name?)> - clone a profile, optionally
with a new name

=back

=head2 Automations

=over 4

=item * C<get_automations()> - list all automations

=item * C<run_automation($id, $profile_id)> - run an automation on a
profile

=back

=head2 Groups

=over 4

=item * C<get_groups()> - list all groups

=item * C<create_group($data)> - create a group

=item * C<update_group($id, $data)> - update a group

=item * C<delete_group($id)> - delete a group

=back

=head2 Proxies

=over 4

=item * C<get_proxies()> - list all proxies

=item * C<create_proxy($data)> - add a proxy (validated)

=item * C<check_proxy($data)> - test a single proxy

=item * C<delete_proxy($id)> - delete a proxy

=back

=head2 Extensions

=over 4

=item * C<get_extensions()> - list all extensions

=item * C<delete_extension($id)> - delete an extension

=item * C<get_profile_extensions($profile_id)> - list extensions
installed on a profile

=item * C<set_profile_extensions($profile_id, \@extension_ids)> - set
the extensions of a profile

=back

=head1 ERROR HANDLING

On any non-2xx response the client dies with a message of the form:

    HTTP <code>: <response body>

Wrap calls in C<eval> to handle errors gracefully:

    my $profiles = eval { $client->get_profiles() };
    if (!$profiles) {
        warn "Request failed: $@";
    }

=head1 REPOSITORY

The source code is available on GitHub:
L<https://github.com/antybrowser/SDK>

=head1 WEBSITE

L<https://antybrowser.com>

=head1 AUTHOR

Antybrowser.com <support@antybrowser.com>

=head1 LICENSE

This module is licensed under the MIT License. See the LICENSE file in
the distribution for details.

=cut