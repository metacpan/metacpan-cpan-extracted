package Catalyst::Plugin::StatusMessage;
{
  $Catalyst::Plugin::StatusMessage::VERSION = '1.002000';
}

use strictures 1;
use Sub::Name ();


=head1 NAME

Catalyst::Plugin::StatusMessage - Handle passing of status (success and error)
messages between screens of a web application.


=head1 SYNOPSIS

In MyApp.pm:

    use Catalyst qr/
        StatusMessage
    /;

In controller where you want to save a message for display on the next page
(here, once the "delete" action taken is complete, we are redirecting to a
"list" page to show the status [we don't want to leave the delete action in the
browser URL]):

   $c->response->redirect($c->uri_for($self->action_for('list'),
        {mid => $c->set_status_msg("Deleted widget")}));

Or, to save an error message:

   $c->response->redirect($c->uri_for($self->action_for('list'),
        {mid => $c->set_error_msg("Error deleting widget")}));

Then, in the controller action that corresponds to the redirect above:

    sub list :Path {
        my ($self, $c) = @_;
        ...
        $c->load_status_msgs;
        ...
    }

And, to display the output (here using L<Template Toolkit|Template>):

    ...
    <span class="message">[% status_msg %]</span>
    <span class="error">[% error_msg %]</span>
    ...


=head1 DESCRIPTION

There are a number of ways people commonly use to pass "status messages"
between screens in a web application.

=over 4

=item *

Using $c->stash: The stash only exists for a single request, so this
approach can leave the wrong URL in the user's browser.

=item *

Using $c->flash: The "flash" feature does provide a mechanism where the
application can redirect to an appropriate URL, but it can also lead to
a race condition where the wrong status message is displayed in the
wrong browser window or tab (and can therefore be confusing to the users
of your application).

=item *

Query parameters in the URL: This suffers from issues related to
long/ugly URLs and leaves the message displayed even after a browser
refresh.

=back


This plugin attempts to address these issues through the following mechanisms:

=over 4

=item *

Stores messages in the C<$c-E<gt>session> so that the application is free
to redirect to the appropriate URL after an action is taken.

=item *

Associates a random 8-digit "token" with each message, so it's completely
unambiguous what message should be shown in each window/tab.

=item *

Only requires that the token (not the full message) be included in the
redirect URL.

=item *

Automatically removes the message after the first time it is displayed.
That way, if users hit refresh in their browsers they only see the
messages the first time.

=back


=head1 METHODS


=head2 load_status_msgs

Load both messages that match the token parameter on the URL (e.g.,
http://myserver.com/widgits/list?mid=1234567890) into the stash
for display by the viewer.

In general, you will want to include this in an C<auto> or "base" (if
using Chained dispatch) controller action.  Then, if you have a
"template wrapper page" that displays both "C<status_msg>" and
"C<error_msg>", you can automatically and safely send status messages to
any related controller action.


=head1 CONFIGURABLE OPTIONS


=head2 session_prefix

The location inside $c->session where messages will be stored.  Defaults
to "C<status_msg>".


=head2 token_param

The name of the URL param that holds the token on the page where you
want to retrieve/display the status message.  Defaults to "C<mid>".


=head2 status_msg_stash_key

The name of the stash key where "success" status messages are loaded
when C<$c-E<gt>load_status_msgs> is called.  Defaults to C<status_msg>.


=head2 error_msg_stash_key


The name of the stash key where error messages are loaded when
C<$c-E<gt>load_status_msgs> is called.  Defaults to C<error_msg>.


=head2 Configuration Example

Here is a quick example showing how Catalyst::Plugin::StatusMessage
can be configured in 


    # Configure Catalyst::Plugin::StatusMessage
    __PACKAGE__->config(
        'Plugin::StatusMessage' => {
            session_prefix          => 'my_status_msg',
            token_param             => 'my_mid',
            status_msg_stash_key    => 'my_status_msg',
            error_msg_stash_key     => 'my_error_msg',
        }
    );


=head1 INTERNALS

Note: You normally shouldn't need any of the information in this section
to use L<Catalyst::Plugin::StatusMessage>.


=head2 get_error_msg

A dynamically generated accessor to retrieve saved error messages

=cut


=head2 get_status_msg

A dynamically generated accessor to retrieve saved status messages

=cut


=head2 set_error_msg

A dynamically generated accessor to save error messages

=cut


=head2 set_status_msg

A dynamically generated accessor to save status messages

=cut


=head2 _get_cfg

Subref that handles default values and lets them be overriden from the MyApp
configuration.

=cut

my $_get_cfg = sub {
    my ($self) = @_;

    my %config = (
        session_prefix       =>  'status_msg',
        token_param          =>  'mid',
        msg_types            =>  [ qw(status error) ],
        status_msg_stash_key =>  'status_msg',
        error_msg_stash_key  =>  'error_msg',
        %{$self->config->{"Plugin::StatusMessage"} || {}}
    );
    \%config;
};


=head2 get_status_message_by_type

Fetch the requested message type from the user's session

=cut

sub get_status_message_by_type {
    my ($self, $token, $conf, $type) = @_;

    return delete($self->session->{$conf->{session_prefix}}{$type}{$token})||'';
}


=head2 set_status_message_by_type

Save a message to the user's session

=cut

sub set_status_message_by_type {
    my ($self, $conf, $type, $value) = @_;

    my $token = int(rand(90_000_000))+10_000_000;
    $self->session->{$conf->{session_prefix}}{$type}{$token} = $value;
    return $token;
}


=head2 load_status_msgs

Load both messages that match the token param (mid=###) into the stash
for display by the view.

=cut

sub load_status_msgs {
    my ($self) = @_;

    my $conf = $self->$_get_cfg;

    my $token  = $self->request->params->{$conf->{token_param}} || return;

    $self->stash(
        map +(
            $conf->{"${_}_msg_stash_key"}
                =>  $self->get_status_message_by_type($token, $conf, $_)
        ), @{$conf->{msg_types}}
    );
}


=head2 make_status_message_get_set_methods_for_type

Called at startup to install getters and setters for each type of
message (status & error)

=cut

sub make_status_message_get_set_methods_for_type {
    my ($pkg, $type) = @_;

    # Make getter for messages of $type
    my $get_name = "${pkg}::get_${type}_msg";
    my $get = Sub::Name::subname($get_name, sub {
        my ($self, $token) = @_;
        $self->get_status_message_by_type($token, $self->$_get_cfg, $type);
    });
    # Make getter for messages of $type
    my $set_name = "${pkg}::set_${type}_msg";
    my $set = Sub::Name::subname($set_name, sub {
        my ($self, $value) = @_;
        $self->set_status_message_by_type($self->$_get_cfg, $type, $value);
    });
    # Install getter and setter into class
    {
        no strict 'refs';
        *{$get_name} = $get;
        *{$set_name} = $set;
    }
    return;
}


# Add class methods to save/retrieve messages for status & error message types 
__PACKAGE__->make_status_message_get_set_methods_for_type($_) for qw(status error);


=head1 AUTHOR

Kennedy Clark, hkclark@cpan.org


With many thanks to Matt Trout (MST) for coaching on the details of Catalyst
Plugins and for most of the magic behind the current implementation.


=head1 COPYRIGHT

This library is free software. You can redistribute it and/or modify it under
the same terms as Perl itself.


=cut

1;
