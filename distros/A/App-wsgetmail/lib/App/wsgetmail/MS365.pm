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

use v5.10;

package App::wsgetmail::MS365;

=head1 NAME

App::wsgetmail::MS365 - Fetch mail from Microsoft 365

=cut

use Moo;
use JSON;

use App::wsgetmail::MS365::Client;
use App::wsgetmail::MS365::Message;
use File::Temp;

=head1 SYNOPSIS

    my $ms365 = App::wsgetmail::MS365->new({
      client_id => "client UUID",
      tenant_id => "tenant UUID",
      secret => "random secret token",
      global_access => 1,
      folder => "Inbox",
      post_fetch_action => "mark_message_as_read",
      debug => 0,
    })

=head1 DESCRIPTION

Moo class providing methods to connect to and fetch mail from Microsoft 365
 mailboxes using the Graph REST API.

=head1 ATTRIBUTES

You must provide C<client_id>, C<tenant_id>, C<post_fetch_action>, and
authentication details. If C<global_access> is false (the default), you must
provide C<username> and C<user_password>. If you set C<global_access> to a
true value, you must provide C<secret>.

=head2 client_id

A string with the UUID of the client application to use for authentication.

=cut

has client_id => (
    is => 'ro',
    required => 1,
);

=head2 tenant_id

A string with the UUID of your Microsoft 365 tenant to use for authentication.

=cut

has tenant_id => (
    is => 'ro',
    required => 1,
);

=head2 username

A string with a username email address. If C<global_access> is false (the
default), the client authenticates with this username. If C<global_access>
is true, the client accesses this user's mailboxes.

=cut

has username => (
    is => 'ro',
    required => 0
);

=head2 user_password

A string with the user password to use for authentication without global
access.

=cut

has user_password => (
    is => 'ro',
    required => 0
);

=head2 folder

A string with the name of the email folder to read. Default "Inbox".

=cut

has folder => (
    is => 'ro',
    required => 0,
    default => sub { 'Inbox' }
);

=head2 global_access

A boolean. If false (the default), the client will authenticate using
C<username> and C<user_password>. If true, the client will authenticate
using its C<secret> token.

=cut

has global_access => (
    is => 'ro',
    default => sub { return 0 }
);

=head2 secret

A string with the client secret to use for global authentication. This
should look like a long string of completely random characters, not a UUID
or other recognizable format.

=cut

has secret => (
    is => 'ro',
    required => 0,
);

=head2 post_fetch_action

A string with the name of a method to call after reading a message. You
probably want to pass either "mark_message_as_read" or "delete_message". In
principle, you can pass the name of any method that accepts a message ID
string argument.

=cut

has post_fetch_action => (
    is => 'ro',
    required => 1
);

=head2 debug

A boolean. If true, the object will issue a warning with details about each
request it issues.

=cut

has debug => (
    is => 'rw',
    default => sub { return 0 }
);

###

has _client => (
    is => 'ro',
    lazy => 1,
    builder => '_build_client',
);

has _fetched_messages => (
    is => 'rw',
    required => 0,
    default => sub { [ ] }
);

has _have_messages_to_fetch => (
    is => 'rw',
    required => 0,
    default => sub { 1 }
);

has _next_fetch_url => (
    is => 'rw',
    required => 0,
    default => sub { '' }
);


# this sets the attributes in the object using values from the config.
# if no value is defined in the config, the attribute's "default" is used
# instead (if defined).
around BUILDARGS => sub {
    my ( $orig, $class, $config ) = @_;

    my $attributes = {
        map {
            $_ => $config->{$_}
        }
        grep {
            defined $config->{$_}
        }
        qw(client_id tenant_id username user_password global_access secret folder post_fetch_action debug)
    };

    return $class->$orig($attributes);
};


=head1 METHODS

=head2 new

Class constructor method, returns new App::wsgetmail::MS365 object

=head2 get_next_message

Object method, returns the next message as an App::wsgetmail::MS365::Message object if there is one.

Will lazily fetch messages until the list is exhausted.

=cut

sub get_next_message {
    my ($self) = @_;
    my $next_message;

    # check for already fetched messages, otherwise fetch more
    my $message_details = shift @{$self->_fetched_messages};
    unless ( $message_details ) {
        if ($self->_have_messages_to_fetch) {
            $self->_fetch_messages();
            $message_details = shift @{$self->_fetched_messages};
        }
    }
    if (defined $message_details) {
        $next_message = App::wsgetmail::MS365::Message->new($message_details);
    }
    return $next_message;
}

=head2 get_message_mime_content

Object method, takes message id and returns filename of fetched raw mime file for that message.

=cut

sub get_message_mime_content {
    my ($self, $message_id) = @_;
    my @path_parts = ($self->global_access) ? ('users', $self->username, 'messages', $message_id, '$value') : ('me', 'messages', $message_id, '$value');

    my $response = $self->_client->get_request([@path_parts]);
    unless ($response->is_success) {
        warn "failed to fetch message $message_id " . $response->status_line;
        warn "response from server : " . $response->content if $self->debug;
        return undef;
    }

    # can we just write straight to file from response?
    my $tmp = File::Temp->new( UNLINK => 0, SUFFIX => '.mime' );
    print $tmp $response->content;
    return $tmp->filename;
}

=head2 delete_message

Object method, takes message id and deletes that message from the outlook365 mailbox

=cut

sub delete_message {
    my ($self, $message_id) = @_;
    my @path_parts = ($self->global_access) ? ('users', $self->username, 'messages', $message_id) : ('me', 'messages', $message_id);
    my $response = $self->_client->delete_request([@path_parts]);
    unless ($response->is_success) {
        warn "failed to mark message as read " . $response->status_line;
        warn "response from server : " . $response->content if $self->debug;
    }

    return $response;
}

=head2 mark_message_as_read

Object method, takes message id and marks that message as read in the outlook365 mailbox

=cut

sub mark_message_as_read {
    my ($self, $message_id) = @_;
    my @path_parts = ($self->global_access) ? ('users', $self->username, 'messages', $message_id) : ('me', 'messages', $message_id);
    my $response = $self->_client->patch_request([@path_parts],
                                                 {'Content-type'=> 'application/json',
                                                  Content => encode_json({isRead => $JSON::true }) });
    unless ($response->is_success) {
        warn "failed to mark message as read " . $response->status_line;
        warn "response from server : " . $response->content if $self->debug;
    }

    return $response;
}


=head2 get_folder_details

Object method, returns hashref of details of the configured mailbox folder.

=cut

sub get_folder_details {
    my $self = shift;
    my $folder_name = $self->folder;
    my @path_parts = ($self->global_access) ? ('users', $self->username, 'mailFolders' ) : ('me', 'mailFolders');
    my $response = $self->_client->get_request(
        [@path_parts], { '$filter' => "DisplayName eq '$folder_name'" }
    );
    unless ($response->is_success) {
        warn "failed to fetch folder detail " . $response->status_line;
        warn "response from server : " . $response->content if $self->debug;
        return undef;
    }

    my $folders = decode_json( $response->content );
    return $folders->{value}[0];
}


##############

sub _fetch_messages {
    my ($self, $filter) = @_;
    my $messages = [ ];
    my $fetched_count = 0;
    # check if expecting to fetch more using result paging
    my ($decoded_response);
    if ($self->_next_fetch_url) {
        my $response = $self->_client->get_request_by_url($self->_next_fetch_url);
        unless ($response->is_success) {
            warn "failed to fetch messages " . $response->status_line;
            warn "response from server : " . $response->content if $self->debug;
            $self->_have_messages_to_fetch(0);
            return 0;
        }
        $decoded_response = decode_json( $response->content );
    } else {
        my $fields = [qw(id subject sender isRead sentDateTime toRecipients parentFolderId categories)];
        $decoded_response = $self->_get_message_list($fields, $filter);
    }

    $messages = $decoded_response->{value};
    if ($decoded_response->{'@odata.nextLink'}) {
        $self->_next_fetch_url($decoded_response->{'@odata.nextLink'});
        $self->_have_messages_to_fetch(1);
    } else {
        $self->_have_messages_to_fetch(0);
    }
    $self->_fetched_messages($messages);
    return $fetched_count;
}

sub _get_message_list {
    my ($self, $fields, $filter) = @_;

    my $folder = $self->get_folder_details;
    unless ($folder) {
        warn "unable to fetch messages, can't find folder " . $self->folder;
        return { '@odata.count' => 0, value => [ ] };
    }

    # don't request list if folder has no items
    unless ($folder->{totalItemCount} > 0) {
        return { '@odata.count' => 0, value => [ ] };
    }
    $filter ||= $self->_get_message_filters;

    #TODO: handle filtering multiple folders using filters
    my @path_parts = ($self->global_access) ? ( 'users', $self->username, 'mailFolders', $folder->{id}, 'messages' ) : ( 'me', 'mailFolders', $folder->{id}, 'messages' );

    # get oldest first, filter (i.e. unread) if filter provided
    my $response = $self->_client->get_request(
        [@path_parts],
        {
            '$count' => 'true', '$orderby' => 'sentDateTime',
            ( $fields ? ('$select' => join(',',@$fields)  ) : ( )),
            ( $filter ? ('$filter' => $filter ) : ( ))
        }
    );

    unless ($response->is_success) {
        warn "failed to fetch messages " . $response->status_line;
        warn "response from server : " . $response->content if $self->debug;
        return { value => [ ] };
    }

    return decode_json( $response->content );
}

sub _get_message_filters {
    my $self = shift;
    #TODO: handle filtering multiple folders
    my $filters = [ ];
    if ( $self->post_fetch_action && ($self->post_fetch_action eq 'mark_message_as_read')) {
        push(@$filters, 'isRead eq false');
    }

    my $filter = join(' ', @$filters);
    return $filter;
 }

sub _build_client {
    my $self = shift;
    my $client = App::wsgetmail::MS365::Client->new( {
        client_id => $self->client_id,
        username => $self->username,
        user_password => $self->user_password,
        secret => $self->secret,
        client_id => $self->client_id,
        tenant_id => $self->tenant_id,
        global_access => $self->global_access,
        debug => $self->debug,
    } );
    return $client;

}

=head1 AUTHOR

Best Practical Solutions, LLC <modules@bestpractical.com>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by Best Practical Solutions, LLC.

This is free software, licensed under:

The GNU General Public License, Version 2, June 1991

=cut

1;
