
package CGI::Application::Plugin::FormState;

use warnings;
use strict;

use CGI::Application;
use CGI::Session::ID::md5;
use CGI::Application::Plugin::Session;
use vars qw(@ISA @EXPORT);


use Carp;
use Scalar::Util qw(weaken isweak);

use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(form_state);

our $CGIAPP_Namespace     = '__CAP_FORM_STATE';
my  $Default_Expires      = '2d';
my  $Default_Storage_Name = 'cap_form_state';

sub import {
    my $caller = scalar(caller);
    if ($caller->can('add_callback')) {
        $caller->add_callback('load_tmpl', \&_add_form_state_id_to_tmpl);
    }
    else {
        croak "CAP::FormState: Calling package ($caller) is not a CGI::Application module so cannot install load_tmpl hooks.  If you are using \@ISA instead of 'use base', make sure it is in a BEGIN { } block, and make sure these statements appear before the plugin is loaded";
    }
    goto &Exporter::import;
}

=head1 NAME

CGI::Application::Plugin::FormState - Store Form State without Hidden Fields

=head1 VERSION

Version 0.12

=cut

our $VERSION = '0.12';

=head1 SYNOPSIS

FormState is just a temporary stash that you can use for storing and
retrieving private parameters in your multi-page form.

    use CGI::Application::Plugin::FormState;

    my $form = <<EOF;
       <form action="app.cgi">
       <input type="hidden" name="run_mode" value="form_process_runmode">
       <input type="hidden" name="cap_form_state" value="<tmpl_var cap_form_state>">
       ...
       </form>
    EOF

    sub form_display_runmode {
        my $self = shift;

        # Store some parameters
        $self->form_state->param('name'       => 'Road Runner');
        $self->form_state->param('occupation' => 'Having Fun');

        my $t = $self->load_tmpl(scalarref => \$form);
        return $t->output;

    }

    sub form_process_runmode {
        my $self = shift;

        # Retrieve some parameters
        print $self->form_state->param('name');       # 'Road Runner'
        print $self->form_state->param('occupation'); # 'Having Fun'
    }


=head1 EXAMPLE

This is a more complete example, using L<CGI::Application::Plugin::ValidateRM>.

    use CGI::Application::Plugin::Session;
    use CGI::Application::Plugin::FormState;
    use CGI::Application::Plugin::ValidateRM;

    my $form = <<EOF;
       <form action="app.cgi">
       <input type="hidden" name="run_mode" value="my_form_process">
       <input type="hidden" name="cap_form_state" value="<tmpl_var cap_form_state>">
       ...
       </form>
    EOF

    sub my_form_display {
        my $self     = shift;
        my $errs     = shift;
        my $t        = $self->load_tmpl(scalarref => \$form);

        # Stash some data into it
        $self->form_state->param('name'       => 'Wile E. Coyote');
        $self->form_state->param('occupation' => 'Mining Engineer');

        # Normal ValidateRM error handling
        $t->param($errs) if $errs;
        return $t->output;
    }

    sub my_form_process {
        my $self;

        # Normal ValidateRM validation
        my ($results, $err_page) = $self->check_rm('my_form_display','_my_form_profile');
        return $err_page if $err_page;

        # The data from the submitted form
        my $params = $self->dfv_results;

        $params->{'name'}       = $self->form_state->param('name');       # 'Wile E. Coyote'
        $params->{'occupation'} = $self->form_state->param('occupation'); # 'Mining Engineer'


        # Now do something interesting with $params
        # ...


        my $t = $self->load_tmpl('success.html');
        return $t->output;
    }

    # Standard ValiateRM profile
    sub _my_form_profile {
        return {
            required => 'email',
            msgs => {
                    any_errors => 'some_errors',
                    prefix => 'err_',
            },
        };
    }


=head1 DESCRIPTION

C<CGI::Application::Plugin::FormState> provides a temporary storage area
within the user's session for storing form-related data.

The main use of this is for multi-page forms.  Instead of using hidden
fields to store data related to the form, you store and retrieve values
from the form state.

In the first instance of your app:

    $self->form_state->param('some_name' => 'some_value');
    $self->form_state->param('some_other_name' => 'some_other_value');

And later, in a different instance of your app:

    $val1 = $self->form_state->param('some_name');
    $val2 = $self->form_state->param('some_other_name');

To connect the first instance and the second, you put a single hidden
field in your template:

    <input type="hidden" name="cap_form_state" value="<tmpl_var my_storage_name>">

You don't have to worry about creating the template param
C<cap_form_state>; it is added automatically to your template
parameters via the C<load_tmpl> hook.

If you want to use a parameter other than C<cap_form_state> you can do
so via the C<name> parameter to C<form_state->config>.

If you're skeptical about whether all this abstraction is a good idea,
see L<"MOTIVATION">, below.

=head1 PRESERVING FORM STATE ACROSS REDIRECTS

You can include the form_state hash in a link:

    my $link = '/app.cgi?rm=list&cap_form_state=' . $self->form_state->id;

If you use L<CGI::Application::Plugin::Redirect>, you can easily create redirect this way:

    $self->redirect('/app.cgi?rm=list&cap_form_state=' . $self->form_state->id);

If you also use L<CGI::Application::Plugin::LinkIntegrity>
it is as simple as:

    $self->redirect($self->link('/app.cgi', 'rm' => 'list', 'cap_form_state' => $self->form_state->id));

Or, in the case of a link to the currently running app:

    $self->redirect($self->self_link('rm' => 'list', 'cap_form_state' => $self->form_state->id));


=head1 IMPLEMENTATION

When you call C<< $self->form_state >> for the first time, a top-level
key is created in the user's session.  This key contains a random,
hard-to-guess element.  It might look something like:

   form_state_cap_form_state_84eb13cfed01764d9c401219faa56d53

All data you place in the form state with C<param> is stored in the
user's session under this key.

You pass the name of this key on to the next instance of your
application by means of a hidden field in your form:

    <input type="hidden" name="cap_form_state" value="<tmpl_var cap_form_state>">

You manually put this hidden field in your template.  The template
parameter C<cap_form_state> is automatically added to your template
parameters via the C<load_tmpl> hook.  It contains the random,
hard-to-guess portion (e.g. C<84eb13cfed01764d9c401219faa56d53>).  When
the template is filled, the hidden field will look something like this:

    <input type="hidden" name="cap_form_state" value="84eb13cfed01764d9c401219faa56d53">

Since all values are stored on the server in the user's session, the
user can't tamper with any of them.

To keep old form_data from cluttering up the user's session, the system
uses L<CGI::Session>'s C<expire> feature to expire old form state keys
after a reasonable amount of time has passed (2 days by default).

You can manually delete a form state storage by calling:

    $self->form_state->delete;

=cut

sub _new {
    my ($class, $webapp) = @_;

    my $self = {
        '__CGIAPP_OBJ'   => $webapp,
        '__STORAGE_NAME' => undef,
        '__STORAGE_HASH' => undef,
        '__STORAGE_KEY'  => undef,
        '__EXPIRES'      => undef,
        '__CONFIGURED'   => undef,
    };

    # Force reference to CGI::Application object to be weak to avoid
    # circular references
    weaken($self->{'__CGIAPP_OBJ'});

    return bless $self, $class;
}

sub form_state {
    my ($self) = @_;

    # It's possible that in the future we will allow named configs, e.g.
    #    $self->form_state('foo')->param('bar);

    if (not exists $self->{$CGIAPP_Namespace}->{'__DEFAULT_CONFIG'}) {
        $self->{$CGIAPP_Namespace}->{'__DEFAULT_CONFIG'} = __PACKAGE__->_new($self);
    }
    return $self->{$CGIAPP_Namespace}->{'__DEFAULT_CONFIG'};
}

=head1 METHODS

=over 4

=item config(%options)

Sets defaults for the plugin.

B<Calling config is purely optional, since the defaults should be fine most purposes.>

    $self->form_state->config('name' => 'storage_names', 'expires' => '3d')

The following options are allowed:

=over 4

=item name

Sets the name of the default form state storage.  This name is used for
the key in the user's session, for the name of hidden form field, and
the template parameter used to fill the hidden form field.  So if you
set the C<name> to C<foo>:

    $self->form_state_config('name' => 'foo');

then the hidden field in your template should look like this:

    <input type="hidden" name="foo" value="<tmpl_var foo>">

and the key in the user's session would look something like this:

   form_state_foo_84eb13cfed01764d9c401219faa56d53

=item expires

Indicates when form state storage keys should expire and disappear from
the user's session.  Uses the same format as L<CGI::Session>'s
C<expire>.  Defaults to 2 days (C<'2d'>).  To cancel expiration and make
the form state last as long as the user's session does, use:

    $self->form_state_config('expires' => 0);

=back

=cut

my %Installed_Callback;

sub config {
    my $self         = shift;
    my %args         = @_;
    my $storage_name = delete $args{'name'}     if exists $args{'name'};
    my $expires      = delete $args{'expires'}  if exists $args{'expires'};

    if (keys %args) {
        croak "CAP::FormState: unknown configuration keys: " . (join ', ', keys %args);
    }

    $self->{'__STORAGE_NAME'} ||= $storage_name || $Default_Storage_Name;
    $self->{'__EXPIRES'}      ||= $expires      || $Default_Expires;

    $self->{'__CONFIGURED'}   = 1;

    $self->_initialize;
}


# Deprecated method.  Wrapper around 'config'
sub init {
    my $self         = shift;
    my $storage_name = shift;
    my %args         = @_;
    $self->config('name' => $storage_name, %args);
}

sub _initialize {
    my $self          = shift;

    my $webapp        = $self->{__CGIAPP_OBJ};
    my $expires       = $self->{__EXPIRES};

    my $storage_name  = $self->{__STORAGE_NAME};

    my $storage_hash  = $webapp->query->param($storage_name)
                     || $webapp->query->url_param($storage_name);
    my $storage_key;

    my $already_exists;

    if ($storage_hash) {
        # restore existing session
        $storage_key = 'form_state_' . $storage_name . '_' . $storage_hash;
        if (ref $webapp->session->param($storage_key) eq 'HASH') {
            $already_exists = 1;
        }
    }

    unless ($already_exists) {
        # create new session

        $storage_hash = CGI::Session::ID::md5->generate_id;

        $storage_key = 'form_state_' . $storage_name . '_' . $storage_hash;
        $webapp->session->param($storage_key => {});
        $webapp->query->param($storage_name => $storage_hash);

    }

    # reset expiry date on key
    $webapp->session->expire($storage_key, $expires);

    $self->{'__STORAGE_NAME'} = $storage_name;
    $self->{'__STORAGE_HASH'} = $storage_hash;
    $self->{'__STORAGE_KEY'}  = $storage_key;
    $self->{'__EXPIRES'}      = $expires;

    return 1 if $already_exists;
    return;
}

=item param

Read and set values in the form state storage.  It acts like the
C<param> method typically does in modules such as L<CGI>,
L<CGI::Application>, L<CGI::Session>, C<HTML::Template> etc.

    # set a value
    $self->form_state->param('some_name' => 'some_value');

    # retrieve a value
    my $val = $self->form_state->param('some_name');

    # set multiple values
    $self->form_state->param(
        'some_name'       => 'some_value',
        'some_other_name' => 'some_other_value',
    );

    # retrive the names of all the keys
    my @keys = $self->form_state->param;

=cut

sub param {
    my $self = shift;

    if (!$self->{'__CONFIGURED'}) {
        $self->config;
    }
    my $storage_key = $self->{'__STORAGE_KEY'};

    my $webapp = $self->{__CGIAPP_OBJ};
    my $store  = $webapp->session->param($storage_key);

    if (@_) {
        my $param;
        if (ref $_[0] eq 'HASH') {
            $param = shift;
        }
        elsif (@_ == 1) {
            return $store->{$_[0]};
        }
        else {
            $param = { @_ };
        }
        $store->{$_} = $param->{$_} for keys %$param;

        # A param has been changed, so we touch the session
        $webapp->session->param($storage_key => $store);
    }
    else {
        return keys %$store;
    }
}

=item clear_params

Clear all of the values in the form state storage:

   $self->form_state->param('name' => 'Road Runner');
   $self->form_state->clear_params;
   print $self->form_state->param('name'); # undef


=cut

sub clear_params {
    my $self = shift;

    if (!$self->{'__CONFIGURED'}) {
        $self->config;
    }
    my $storage_key = $self->{'__STORAGE_KEY'};

    my $webapp = $self->{__CGIAPP_OBJ};
    $webapp->session->param($storage_key => {});
}

=item delete

Deletes the form_state storage from the user's session.

=cut

sub delete {
    my $self = shift;

    # No need to call $self->config and create the session key since we're
    # just going to delete it.
    #
    # However, it's very important not to call session->clear without a key;
    # if we do, we'll delete all params in the user's session!

    if ($self->{'__STORAGE_KEY'}) {
        $self->{__CGIAPP_OBJ}->session->clear($self->{'__STORAGE_KEY'});
    }
}


=item id

Returns the current value of the storage param - the "hard to guess"
portion of the session key.

    my $id = $self->form_state->id;

=cut

sub id {
    my $self = shift;

    if (!$self->{'__CONFIGURED'}) {
        $self->config;
    }
    $self->{'__STORAGE_HASH'};
}

=item name

Returns the current name being used for storage.
Defaults to C<cap_form_state>.

    my $name = $self->form_state->name;

=cut

sub name {
    my $self = shift;

    if (!$self->{'__CONFIGURED'}) {
        $self->config;
    }
    $self->{'__STORAGE_NAME'};
}

=item session_key

Returns the full key used for storage in the user's session.

    my $key = $self->form_state->session_key;

    # Get the full form state hash
    my $data = $self->session->param($key);

The following can be used to debug the form_state data:

    use Data::Dumper;
    print STDERR Dumper $self->session->param($self->form_state->session_key);

=back

=cut

sub session_key {
    my $self = shift;

    if (!$self->{'__CONFIGURED'}) {
        $self->config;
    }
    $self->{'__STORAGE_KEY'};
}

# add the storage id to the template params
sub _add_form_state_id_to_tmpl {
    my ($self, $ht_params, $tmpl_params, $tmpl_file) = @_;

    my $storage_hash = $self->form_state->id;
    my $storage_name = $self->form_state->name;

    $tmpl_params->{$storage_name} = $storage_hash;
}

=head1 MOTIVATION

=head2 Why not just use hidden fields?

Hidden fields are not secure.  The end user could save a local copy of
your form, change the hidden fields and tamper with your app's form
state.

=head2 Why not just use the user's session?

With C<CGI::Application::Plugin::FormState> the data is associated with
a particular instance of a form, not with the user.  If the user gives
up halfway through your multi-page form, you don't want their session to
be cluttered up with the incomplete form state data.

If a user opens up your application in two browser windows (both sharing
the same user session), each window should have it's own independent
form state.

For instance, in an email application the user might have one window
open for the inbox and another open for the outbox.  If you store the
value of C<"current_mailbox"> in the user's session, then one of these
windows will go to the wrong mailbox.

Finally, the user's session probably sticks around longer than the form
state should.

=head1 AUTHOR

Michael Graham, C<< <mag-perl@occamstoothbrush.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-cgi-application-plugin-formstate@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically
be notified of progress on your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

Thanks to Richard Dice and Cees Hek for helping me sort out the issues
with this approach.

The informative error message text used for when this module is loaded
before your app actually C<@ISA> C<CGI::Application> object was stolen from
Cees's L<CGI::Application::Plugin::TT> module.

=head1 COPYRIGHT & LICENSE

Copyright 2005 Michael Graham, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
