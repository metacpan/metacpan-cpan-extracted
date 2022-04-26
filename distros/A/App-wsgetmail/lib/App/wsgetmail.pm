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

package App::wsgetmail;

use Moo;

our $VERSION = '0.06';

=head1 NAME

App::wsgetmail - Fetch mail from the cloud using webservices

=head1 SYNOPSIS

Run:

    wsgetmail [options] --config=wsgetmail.json

where C<wsgetmail.json> looks like:

    {
    "client_id": "abcd1234-xxxx-xxxx-xxxx-1234abcdef99",
    "tenant_id": "abcd1234-xxxx-xxxx-xxxx-123abcde1234",
    "secret": "abcde1fghij2klmno3pqrst4uvwxy5~0",
    "global_access": 1,
    "username": "rt-comment@example.com",
    "folder": "Inbox",
    "command": "/opt/rt5/bin/rt-mailgate",
    "command_args": "--url=http://rt.example.com/ --queue=General --action=comment",
    "command_timeout": 30,
    "action_on_fetched": "mark_as_read"
    }

Using App::wsgetmail as a library looks like:

    my $getmail = App::wsgetmail->new({config => {
      # The config hashref takes all the same keys and values as the
      # command line tool configuration JSON.
    }});
    while (my $message = $getmail->get_next_message()) {
        $getmail->process_message($message)
          or warn "could not process $message->id";
    }

=head1 DESCRIPTION

wsgetmail retrieves mail from a folder available through a web services API
and delivers it to another system. Currently, it only knows how to retrieve
mail from the Microsoft Graph API, and deliver it by running another command
on the local system.

=head1 INSTALLATION

    perl Makefile.PL
    make
    make test
    sudo make install

C<wsgetmail> will be installed under C</usr/local/bin> if you're using the
system Perl, or in the same directory as C<perl> if you built your own.

=cut

use Clone 'clone';
use Module::Load;
use App::wsgetmail::MDA;

=head1 ATTRIBUTES

=head2 config

A hash ref that is passed to construct the C<mda> and C<client> (see below).

=cut

has config => (
    is => 'ro',
    required => 1
);

=head2 mda

An instance of L<App::wsgetmail::MDA> created from our C<config> object.

=cut

has mda => (
    is => 'rw',
    lazy => 1,
    handles => [ qw(forward) ],
    builder => '_build_mda'
);

=head2 client_class

The name of the App::wsgetmail package used to construct the
C<client>. Default C<MS365>.

=cut

has client_class => (
    is => 'ro',
    default => sub { 'MS365' }
);

=head2 client

An instance of the C<client_class> created from our C<config> object.

=cut

has client => (
    is => 'ro',
    lazy => 1,
    handles => [ qw( get_next_message
                     get_message_mime_content
                     mark_message_as_read
                     delete_message) ],
    builder => '_build_client'
);


has _post_fetch_action => (
    is => 'ro',
    lazy => 1,
    builder => '_build__post_fetch_action'
);


sub _build__post_fetch_action {
    my $self = shift;
    my $fetched_action_method;
    my $action = $self->config->{action_on_fetched};
    return undef unless (defined $action);
    if (lc($action) eq 'mark_as_read') {
        $fetched_action_method = 'mark_message_as_read';
    } elsif ( lc($action) eq "delete" ) {
        $fetched_action_method = 'delete_message';
    } else {
        $fetched_action_method = undef;
        warn "no recognised action for fetched mail, mailbox not updated";
    }
    return $fetched_action_method;
}

=head1 METHODS

=head2 process_message($message)

Given a Message object, retrieves the full message content, delivers it
using the C<mda>, and then executes the configured post-fetch
action. Returns a boolean indicating success.

=cut

sub process_message {
    my ($self, $message) = @_;
    my $client = $self->client;
    my $filename = $client->get_message_mime_content($message->id);
    unless ($filename) {
        warn "failed to get mime content for message ". $message->id;
        return 0;
    }
    my $ok = $self->forward($message, $filename);
    if ($ok) {
        $ok = $self->post_fetch_action($message);
    }
    if ($self->config->{dump_messages}) {
        warn "dumped message in file $filename" if ($self->config->{debug});
    }
    else {
        unlink $filename or warn "couldn't delete message file $filename : $!";
    }
    return $ok;
}

=head2 post_fetch_action($message)

Given a Message object, executes the configured post-fetch action. Returns a
boolean indicating success.

=cut

sub post_fetch_action {
    my ($self, $message) = @_;
    my $method = $self->_post_fetch_action;
    my $ok = 1;
    # check for dry-run option
    if ($self->config->{dry_run}) {
        warn "dry run so not running $method action on fetched mail";
        return 1;
    }
    if ($method) {
        $ok = $self->$method($message->id);
    }
    return $ok;
}

###

sub _build_client {
    my $self = shift;
    my $classname = 'App::wsgetmail::' . $self->client_class;
    load $classname;
    my $config = clone $self->config;
    $config->{post_fetch_action} = $self->_post_fetch_action;
    return $classname->new($config);
}


sub _build_mda {
    my $self = shift;
    my $config = clone $self->config;
    if ( defined $self->config->{username}) {
        $config->{recipient} //= $self->config->{username};
    }
    return App::wsgetmail::MDA->new($config);
}

=head1 CONFIGURATION

=head2 Configuring Microsoft 365 Client Access

To use wsgetmail, first you need to set up the app in Microsoft 365.
Two authentication methods are supported:

=over

=item Client Credentials

This method uses shared secrets and is preferred by Microsoft.
(See L<Client credentials|https://docs.microsoft.com/en-us/azure/active-directory/develop/msal-authentication-flows#client-credentials>)

=item Username/password

This method is more like previous connections via IMAP. It is currently
supported by Microsoft, but not recommended. (See L<Username/password|https://docs.microsoft.com/en-us/azure/active-directory/develop/msal-authentication-flows#usernamepassword>)

=back

This section walks you through each piece of configuration wsgetmail needs,
and how to obtain it.

=over 4

=item tenant_id

wsgetmail authenticates to an Azure Active Directory (AD) tenant. This
tenant is identified by an identifier that looks like a UUID/GUID: it should
be mostly alphanumeric, with dividing dashes in the same places as shown in
the example configuration above. Microsoft documents how to find your tenant
ID, and create a tenant if needed, in the L<"Set up a tenant"
quickstart|https://docs.microsoft.com/en-us/azure/active-directory/develop/quickstart-create-new-tenant>. Save
this as the C<tenant_id> string in your wsgetmail configuration file.

=item client_id

You need to register wsgetmail as an application in your Azure Active
Directory tenant. Microsoft documents how to do this in the L<"Register an
application with the Microsoft identity platform"
quickstart|https://docs.microsoft.com/en-us/azure/active-directory/develop/quickstart-register-app#register-an-application>,
under the section "Register an application." When asked who can use this
application, you can leave that at the default "Accounts in this
organizational directory only (Single tenant)."

After you successfully register the wsgetmail application, its information
page in your Azure account will display an "Application (client) ID" in the
same UUID/GUID format as your tenant ID. Save this as the C<client_id>
string in your configuration file.

After that is done, you need to grant wsgetmail permission to access the
Microsoft Graph mail APIs. Microsoft documents how to do this in the
L<"Configure a client application to access a web API"
quickstart|https://docs.microsoft.com/en-us/azure/active-directory/develop/quickstart-configure-app-access-web-apis#application-permission-to-microsoft-graph>,
under the section "Add permissions to access Microsoft Graph." When selecting
the type of permissions, select "Application permissions." When prompted to
select permissions, select all of the following:

=over 4

=item * Mail.Read

=item * Mail.Read.Shared

=item * Mail.ReadWrite

=item * Mail.ReadWrite.Shared

=item * openid

=item * User.Read

=back

=back

=head3 Configuring client secret authentication

We recommend you deploy wsgetmail by configuring it with a client
secret. Client secrets can be granted limited access to only the mailboxes
you choose. You can adjust or revoke wsgetmail's access without interfering
with other applications.

Microsoft documents how to create a client secret in the L<"Register an
application with the Microsoft identity platform"
quickstart|https://docs.microsoft.com/en-us/azure/active-directory/develop/quickstart-register-app#add-a-client-secret>,
under the section "Add a client secret." Take care to record the secret
token when it appears; it will never be displayed again. It should look like
a completely random string, not a UUID/GUID.

=over 4

=item global_access

Set this to C<1> in your wsgetmail configuration file.

=item secret

Set this to the secret token string you recorded earlier in your wsgetmail
configuration file.

=item username

wsgetmail will fetch mail from this user's account. Set this to an email
address string in your wsgetmail configuration file.

=back

=head3 Configuring user+password authentication

If you do not want to use a client secret, you can also configure wsgetmail
to authenticate with a traditional username+password combination. As noted
above, this method is not recommended by Microsoft. It also does not work
for systems with federated authentication enabled.

=over 4

=item global_access

Set this to C<0> in your wsgetmail configuration file.

=item username

wsgetmail will authenticate as this user. Set this to an email address
string in your wsgetmail configuration file.

=item user_password

Set this to the password string for C<username> in your wsgetmail
configuration file.

=back

=head2 Configuring the mail delivery command

Now that you've configured wsgetmail to access a mail account, all that's
left is configuring delivery. Set the following in your wsgetmail
configuration file.

=over 4

=item folder

Set this to the name string of a mail folder to read.

=item command

Set this to an executable command. You can specify an absolute path,
or a plain command name which will be found from C<$PATH>. For each
email wsgetmail retrieves, it will run this command and pass the
message data to it via standard input.

=item command_args

Set this to a string with additional arguments to pass to C<command>.
These arguments follow shell quoting rules: you can escape characters
with a backslash, and denote a single string argument with single or
double quotes.

=item command_timeout

Set this to the number of seconds the C<command> has to return before
timeout is reached.  The default value is 30.

=item action_on_fetched

Set this to a literal string C<"mark_as_read"> or C<"delete">.
For each email wsgetmail retrieves, after the configured delivery
command succeeds, it will take this action on the message.

If you set this to C<"mark_as_read">, wsgetmail will only retrieve and
deliver messages that are marked unread in the configured folder, so it does
not try to deliver the same email multiple times.

=back

=head1 TESTING AND DEPLOYMENT

After you write your wsgetmail configuration file, you can test it by running:

    wsgetmail --debug --dry-run --config=wsgetmail.json

This will read and deliver messages, but will not mark them as read or
delete them. If there are any problems, those will be reported in the error
output. You can update your configuration file and try again until wsgetmail
runs successfully.

Once your configuration is stable, you can configure wsgetmail to run
periodically through cron or a systemd service on a timer.

=head1 LIMITATIONS

=head2 Fetching from Multiple Folders

wsgetmail can only read from a single folder each time it runs. If you need
to read multiple folders (possibly spanning different accounts), then you
need to run it multiple times with different configuration.

If you only need to change a couple small configuration settings like the
folder name, you can use the C<--options> argument to override those from a
base configuration file. For example:

    wsgetmail --config=wsgetmail.json --options='{"folder": "Inbox"}'
    wsgetmail --config=wsgetmail.json --options='{"folder": "Other Folder"}'

NOTE: Setting C<secret> or C<user_password> with C<--options> is not secure
and may expose your credentials to other users on the local system. If you
need to set these options, or just change a lot of settings in your
configuration, just run wsgetmail with different configurations:

    wsgetmail --config=account01.json
    wsgetmail --config=account02.json

=head2 Office 365 API Limits

Microsoft applies some limits to the amount of API requests allowed as
documented in their L<Microsoft Graph throttling guidance|https://docs.microsoft.com/en-us/graph/throttling>.
If you reach a limit, requests to the API will start failing for a period
of time.

=head1 SEE ALSO

=over 4

=item * L<wsgetmail>

=item * L<App::wsgetmail::MDA>

=item * L<App::wsgetmail::MS365>

=item * L<App::wsgetmail::MS365::Message>

=back

=head1 AUTHOR

Best Practical Solutions, LLC <modules@bestpractical.com>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2015-2020 by Best Practical Solutions, LLC.

This is free software, licensed under:

The GNU General Public License, Version 2, June 1991

=cut

1;
