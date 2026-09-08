package Antybrowser;
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

Antybrowser - Official Antybrowser SDK for Perl

=head1 SYNOPSIS

    use Antybrowser;
    my $client = Antybrowser->new(api_key => 'your_key');
    my $profiles = $client->get_profiles();

=head1 DESCRIPTION

Perl client for the Antybrowser Local API.

=head1 AUTHOR

Antybrowser.com <support@antybrowser.com>

=head1 LICENSE

MIT

=cut
