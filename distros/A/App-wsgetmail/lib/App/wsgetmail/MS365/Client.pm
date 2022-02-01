# BEGIN BPS TAGGED BLOCK {{{
#
# COPYRIGHT:
#
# This software is Copyright (c) 2020-2022 Best Practical Solutions, LLC
#                                          <sales@bestpractical.com>
#
# (Except where explicitly superseded by other copyright notices)
#
#
# LICENSE:
#
# This work is made available to you under the terms of Version 2 of
# the GNU General Public License. A copy of that license should have
# been provided with this software, but in any event can be snarfed
# from www.gnu.org.
#
# This work is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
# 02110-1301 or visit their web page on the internet at
# http://www.gnu.org/licenses/old-licenses/gpl-2.0.html.
#
#
# CONTRIBUTION SUBMISSION POLICY:
#
# (The following paragraph is not intended to limit the rights granted
# to you to modify and distribute this software under the terms of
# the GNU General Public License and is only of importance to you if
# you choose to contribute your changes and enhancements to the
# community by submitting them to Best Practical Solutions, LLC.)
#
# By intentionally submitting any modifications, corrections or
# derivatives to this work, or any other work intended for use with
# Request Tracker, to Best Practical Solutions, LLC, you confirm that
# you are the copyright holder for those contributions and you grant
# Best Practical Solutions,  LLC a nonexclusive, worldwide, irrevocable,
# royalty-free, perpetual, license to use, copy, create derivative
# works based on those contributions, and sublicense and distribute
# those contributions and any derivatives thereof.
#
# END BPS TAGGED BLOCK }}}

package App::wsgetmail::MS365::Client;

=head1 NAME

App::wsgetmail::MS365::Client - Low-level client to the Microsoft Graph API

=cut

use Moo;
use URI::Escape;
use URI;
use JSON;
use LWP::UserAgent;
use Azure::AD::ClientCredentials;

=head1 DESCRIPTION

This class performs the actual REST requests to support
L<App::wsgetmail::MS365>.

=head1 ATTRIBUTES

The following attributes are received from L<App::wsgetmail::MS365> and have
the same meaning:

=over 4

=item * secret

=cut

has secret  => (
    is => 'ro',
    required => 0,
);

=item * client_id

=cut

has client_id => (
    is => 'ro',
    required => 1,
);

=item * tenant_id

=cut

has tenant_id => (
    is => 'ro',
    required => 1,
);

=item * username

=cut

has username => (
    is => 'ro',
    required => 0
);

=item * user_password

=cut

has user_password => (
    is => 'ro',
    required => 0
);

=item * global_access

=item * debug

=cut

has global_access => (
    is => 'ro',
    default => sub { return 0 }
);

=back

=head2 resource_url

A string with the URL for the overall API endpoint.

=cut

has resource_url => (
    is => 'ro',
    default => sub { return 'https://graph.microsoft.com/' }
);

=head2 resource_path

A string with the REST API endpoint URL path.

=cut

has resource_path => (
    is => 'ro',
    default => sub { return 'v1.0' }
);

has debug => (
    is => 'rw',
    default => sub { return 0 }
);

has _ua => (
    builder   => '_build_authorised_ua',
    is => 'ro',
    lazy => 1,
);

has _credentials => (
    is => 'ro',
    lazy => 1,
    builder => '_build__credentials',
);

has _access_token => (
    is => 'ro',
    lazy => 1,
    builder => '_build__access_token',
);

sub BUILD {
    my ($self, $args) = @_;

    if ($args->{global_access}) {
        unless ($args->{secret}) {
            die "secret is required when using global_access";
        }
    }
    else {
        unless ($args->{username} && $args->{user_password}) {
            die "username and user_password are required when not using global_access";
        }
    }
}


=head1 METHODS

=head2 build_rest_uri(@endpoint_parts)

Given a list of URL component strings, returns a complete URL string to
reach that endpoint from this object's C<resource_url> and C<resource_path>.

=cut

sub build_rest_uri {
    my ($self, @endpoint_parts) = @_;
    my $base_url = $self->resource_url . $self->resource_path;
    return join('/', $base_url, @endpoint_parts);
}

=head2 get_request($parts, $params)

Makes a GET request to the API. C<$parts> is an arrayref of URL endpoint
strings with the specific endpoint to request. C<$params> is a hashref of
query parameters to send with the request.

=cut

sub get_request {
    my ($self, $parts, $params) = @_;
    # add error handling!
    my $uri = URI->new($self->build_rest_uri(@$parts));
    warn "making GET request to url $uri" if ($self->debug);
    $uri->query_form($params) if ($params);
    return $self->_ua->get($uri);
}

=head2 get_request_by_url($url)

Makes a GET request to the URL in the C<$url> string.

=cut

sub get_request_by_url {
    my ($self, $url) = @_;
    warn "making GET request to url $url" if ($self->debug);
    return $self->_ua->get($url);
}

=head2 delete_request($parts, $params)

Makes a DELETE request to the API. C<$parts> is an arrayref of URL endpoint
strings with the specific endpoint to request. C<$params> is unused.

=cut

sub delete_request {
    my ($self, $parts, $params) = @_;
    my $url = $self->build_rest_uri(@$parts);
    warn "making DELETE request to url $url" if ($self->debug);
    return $self->_ua->delete($url);
}

=head2 post_request($path_parts, $post_data)

Makes a POST request to the API. C<$path_parts> is an arrayref of URL
endpoint strings with the specific endpoint to request. C<$post_data> is a
reference to an array or hash of data to include in the POST request body.

=cut

sub post_request {
    my ($self, $path_parts, $post_data) = @_;
    my $url = $self->build_rest_uri(@$path_parts);
    warn "making POST request to url $url" if ($self->debug);
    return $self->_ua->post($url,$post_data);
}

=head2 patch_request($path_parts, $patch_params)

Makes a PATCH request to the API. C<$path_parts> is an arrayref of URL
endpoint strings with the specific endpoint to request. C<$patch_params> is
a hashref of data to include in the PATCH request body.

=cut

sub patch_request {
     my ($self, $path_parts, $patch_params) = @_;
     my $url = $self->build_rest_uri(@$path_parts);
     warn "making PATCH request to url $url" if ($self->debug);
     return $self->_ua->patch($url,%$patch_params);
 }

######

sub _build_authorised_ua {
    my $self = shift;
    my $ua = $self->_new_useragent;
    warn "getting system access token" if ($self->debug);
    $ua->default_header( Authorization => $self->_access_token() );
    return $ua;
}

sub _build__access_token {
    my $self = shift;
    my $access_token;
    if ($self->global_access) {
        $access_token = $self->_credentials->access_token;
    }
    else {
        $access_token = $self->_get_user_access_token;
    }
    return $access_token;
}

sub _get_user_access_token {
    my $self = shift;
    my $ua = $self->_new_useragent;
    my $access_token;
    warn "getting user access token" if ($self->debug);
    my $oauth_login_url = sprintf('https://login.windows.net/%s/oauth2/token', $self->tenant_id);
    my $response = $ua->post( $oauth_login_url,
                              {
                                  resource=> $self->resource_url,
                                  client_id => $self->client_id,
                                  grant_type=>'password',
                                  username=>$self->username,
                                  password=>$self->user_password,
                                  scope=>'openid'
                              }
                          );
    my $raw_message = $response->content;
    # check details
    if ($response->is_success) {
        my $token_details = decode_json( $response->content );
        $access_token = "Bearer " . $token_details->{access_token};
    }
    else {
        # throw error
        warn "auth response from server : $raw_message" if ($self->debug);
        die sprintf('unable to get user access token for user %s request failed with status %s ', $self->username, $response->status_line);
    }
    return $access_token;
}

sub _build__credentials {
    my $self = shift;
    my $creds = Azure::AD::ClientCredentials->new(
        resource_id => $self->resource_url,
        client_id => $self->client_id,
        secret_id => $self->secret,
        tenant_id => $self->tenant_id
    );
    return $creds;
}

sub _new_useragent {
    return LWP::UserAgent->new();
}

=head1 SEE ALSO

=over 4

=item * L<App::wsgetmail::MS365>

=back

=head1 AUTHOR

Best Practical Solutions, LLC <modules@bestpractical.com>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by Best Practical Solutions, LLC

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
