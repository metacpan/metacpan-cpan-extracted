package CGI::Panel;
use strict;
use CGI;
use CGI::Carp 'fatalsToBrowser';
use Apache::Session::File;

BEGIN {
	use Exporter ();
	use vars qw ($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
	$VERSION     = 0.97;
	@ISA         = qw (Exporter);
	@EXPORT      = qw ();
	@EXPORT_OK   = qw ();
	%EXPORT_TAGS = ();
}

########################################### main pod documentation begin ##

=head1 NAME

CGI::Panel - Create stateful event-driven web applications from simple panel objects

=head1 SYNOPSIS

A very simple working application consisting of a driver cgi and two panel classes...

In simpleapp.cgi:

    use SimpleApp;
    my $simple_app = obtain SimpleApp;
    $simple_app->cycle();

In SimpleApp.pm:

    package SimpleApp;

    use base qw(CGI::Panel);
    use Basket;

    sub init {
        my ($self) = @_;
        $self->add_panel('basket1', new Basket); # Add a sub-panel
        $self->add_panel('basket2', new Basket); # Add a sub-panel
        $self->add_panel('basket3', new Basket); # Add a sub-panel
        $self->{count} = 1;   # Initialise some persistent data
    }

    sub _event_add {    # Respond to the button click event below
        my ($self, $event) = @_;
        
        $self->{count}++;  # Change the persistent data
    }

    sub display {
        my ($self) = @_;
    
        return
    	'This is a very simple app.<p>' .
    	# Display the persistent data...
    	"My current count is $self->{count}<p>" .
    	# Display the sub-panels...
    	"<table><tr>" .
    	"<td>" . $self->panel('basket1')->display . "</td>" .
    	"<td>" . $self->panel('basket2')->display . "</td>" .
    	"<td>" . $self->panel('basket3')->display . "</td>" .
        "</tr></table>" .
    	# Display a button that will generate an event...
    	$self->event_button(label => 'Add 1', name => 'add');
    }

    1;

In Basket.pm:

    package Basket;

    use base qw(CGI::Panel);
    
    sub init {
        my ($self) = @_;
    
        $self->{contents} = [];
    }
    
    sub _event_add {  # Respond to the button event in 'display'
        my ($self, $event) = @_;

        # Get panel's localised parameters    
	# (Many instances of this panel each get
	# their own local parameters)
        my %local_params = $self->local_params;
    
        push @{$self->{contents}}, $local_params{item_name};
    }
    
    sub display {
        my ($self) = @_;
    
        return
          '<table bgcolor="#CCCCFF">' .
          join('', (map { "<tr><td>$_</td></tr>" } @{$self->{contents}})) .
          '<tr>' .
	          # Localised text field
    	  '<td>' . $self->local_textfield({name => 'item_name', size => 10}) . '</td>' .
                  # Button that will generate an event (handled by _event_add above)
    	  '<td>' . $self->event_button(label => 'Add', name => 'add') . '</td>' .
          '</tr>' .
          '</table>';
    };
    
    1;

This example is included with the module.  It's in the 'demo'
directory and can be seen in action at
http://www.cyberdesignfactory.com/public-cgi-bin/simpleapp.cgi

=head1 DESCRIPTION

CGI::Panel allows applications to be built out of simple object-based
components.  It'll handle the state of your data and objects so you
can write a web application just like a desktop app.  You can forget
about the http requests and responses, whether we're getting or
posting, and all that stuff because that is all handled for you
leaving to you interact with a simple API.

An application is constructed from a set of 'panels', each of which
can contain other panels.  The panels are managed behind the scenes
as persistent objects.  See the sample applications for examples of
how complex object-based applications can be built from simple
encapsulated components.  To try the demo app, copy the contents of
the 'demo' directory to a cgi-bin directory.

CGI::Panel allows you to design the logic of your application in an
event-driven manner.  That is, you set up your application the way
you want it, with special buttons and links that trigger 'events'.
The application then sits back and when an event is triggered, the
code associated with that event is run.  The code that responds to an
event goes in the same class as the code that generates the event
button or link, making the code more readable and maintainable.  If
the event code changes the state of any of the panels, the panels
will then stay in the new state, until their state is changed again.

Each panel is encapsulated not only in terms of the code, but in
terms of the form data that is passed through.  For example a panel
class can be defined which has a textfield called 'name'.  Three
instances of this panel can then exist simultaneously and each will
get the correct value of the 'name' parameter when they read their
parameters (see the 'local_params' method).

Please let me know by email if you're using the module and would
like to be informed when there's an update.

=head1 USAGE

See 'SYNOPSIS'

=head1 BUGS

=head1 SUPPORT

=head1 AUTHOR

	Robert J. Symes
	CPAN ID: RSYMES
	rob@robsymes.com

=head1 COPYRIGHT

Copyright (c) 2002 Robert J. Symes. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

perl(1).

=head1 PUBLIC METHODS

Each public function/method is described here.
These are how you should interact with this module.

=cut

############################################# main pod documentation end ##


# Public methods and functions go here. 


###############################################################

=head2 new

Creates a new panel object

Use:

    my $panel = new Panel;

=cut

###############################################################

sub new
{
    my ($class, %args) = @_;

    my $panel = {};

    bless $panel, $class;

    $panel->init;

    return $panel;
}

###############################################################

=head2 init

Initialises a panel object.  This should be used to add panels
to the current panel.  We provide a default method here which
can be overridden.

Example:

    sub init {
        my ($self) = @_;

        $self->add_panel('first_panel',  App::Panel::First);
        $self->add_panel('second_panel', App::Panel::Second);
    }

=cut

###############################################################

sub init
{
    my ($self) = @_;

    # No action for default init routine
}

###############################################################

=head2 parent

Get or set the parent of the panel object.

Examples:

    my $parent = $self->parent;
    $self->parent($other_panel);

=cut

###############################################################

sub parent {
    my ($self, $parent) = @_;

    die "Parent not a panel object"
        if $parent && !($parent->isa('CGI::Panel'));
    $self->{_parent} = $parent if defined($parent);
#    die "No parent set" unless defined($self->{_parent});

    return $self->{_parent};
}

###############################################################
# We should remove this state method as it's unnecessary and confusing
###############################################################

sub state {
    my ($self, $state) = @_;

    $self->{_state} = $state if defined($state);
#    croak "No state set" unless defined($self->{_state});

    return $self->{_state};
}

###############################################################

=head2 get_session_id

Gets the session id for the application

Note:  It's essential that all panels are added using the
proper add_panel routine for this routine to work correctly.

Example:

    my $id = $self->get_session_id;

=cut

###############################################################

sub get_persistent_id {
    my ($self) = @_;

    warn "get_persistent id now called get_session_id - please rename";

    $self->get_session_id
}

sub get_session_id {
    my ($self) = @_;

    # If we're the main panel, return our stored session id
    return $self->{session_id} unless $self->parent;

    die "ERROR: No main panel found for get_session_id call"
	unless ref($self->main_panel);

    return $self->main_panel->get_session_id
}

###############################################################

=head2 panel

Retrieves a sub-panel by name

Example:

    my $first_panel = $self->panel('first_panel');

=cut

###############################################################

sub panel
{
    my ($self, $panel_name) = @_;

    confess "ERROR: No such panel ($panel_name)"
          . " - Can be caused by attaching unstorable "
          . "data to panel object\n"
          . "Available panels: " . join("\n", keys %{$self->{panels}})
	unless $self->{panels}->{$panel_name};

    return $self->{panels}->{$panel_name};
}

###############################################################

=head2 get_panels

Retrieves the set of panels as a hash

Example:

    my %panels = $self->get_panels;

=cut

###############################################################

sub get_panels {
    my ($self) = @_;

    return $self->{panels} ? %{$self->{panels}} : ();
}

###############################################################

=head2 get_id

Gets the id of the panel.
If one is not currently stored, we generate a
new one with help from the main panel.
This method can be overridden if you want to give a unique name
to a panel.

Examples:

    sub get_id { 'unique_name' }

or

    my $id = $self->get_id;

and later...

    $self->get_panel_by_id('unique_name');

or

    $self->get_panel_by_id($id);

See documentation of get_panel_by_id for more details.  (Of course,
you can also just use this get_id to get the auto-generated id and
use that later in get_panel_by_id.)

=cut

###############################################################

sub get_id {
    my ($self) = @_;

    unless (defined($self->{id})) {
        my $main_panel = $self->main_panel;
        $self->{id} = $main_panel->register_panel($self);
    }

    return $self->{id};
}

###############################################################

=head2 main_panel

Get the main panel (by recursing up the panel tree)
Eventually this will reach a panel without a parent,
which we will assume to be the main panel.

Example:

    my $main_panel = $self->main_panel;

=cut

###############################################################

sub main_panel {
    my ($self) = @_;

    # Return cached result if found
    return $self->{_main_panel}
        if $self->{_main_panel};

    my $parent = $self->parent
        or return $self;

    $self->{_main_panel} = $parent->main_panel;
    return $self->{_main_panel};
}

###############################################################

=head2 add_panel

Adds a panel to the current panel in a way that maintains
referential integrity, ie the child panel's parent value will
be set to the current panel.  All panels should be added to
their parents using this routine to keep referential integrity
and allow certain other mechanisms to work.
Specify the name to refer to the panel by and the panel object.

Example:

    $self->add_panel('first_panel', new App::Panel::First);

=cut

###############################################################

sub add_panel
{
    my ($self, $panel_name, $panel) = @_;

    $self->{panels}->{$panel_name} = $panel;
    $panel->parent($self);
}

###############################################################

=head2 remove_panels

Remove all the panels from the current panel.

Example:

    $self->remove_panels;

=cut

###############################################################

sub remove_panels {
    my ($self) = @_;

    $self->{panels} = {};
}

###############################################################

=head2 local_params

Get the parameter list for the current panel.  This fetches the
parameter list and returns the parameters that are relevant to
the current panel.  This allows each panel to be written in
isolation.  Two panels may have input controls (textboxes etc)
with the same name and they can each retrieve the value of
that input from their %local_params hash.

eg

    my %local_params = $self->local_params;
    my $name = $local_params{name};

=cut

###############################################################

sub local_params
{
    my ($self) = @_;

    my $cgi = new CGI;
    my $panel_id = $self->get_id;
    my %cgi_params = map { $_ => $cgi->param($_) } $cgi->param;
    my %local_params;

    foreach my $key (keys %cgi_params) {
        my $value = $cgi_params{$key};
        if (my ($lp_panel_id, $lp_name) = split($self->SEPRE, $key)) {
            if ($lp_panel_id eq $panel_id) {
                $local_params{$lp_name} = $value;
            }
        }
    }

    return %local_params;
}

###############################################################

=head2 event_button

Display a button which when pressed re-cycles the application
and generates an event to be handled by the next incarnation of
the application.  The name of the routine that will be called
will have _event_ prepended.  This is partly for aesthesic reasons
but mainly for security, to stop a wily hacker from calling any
routine by changing what is passed through the browser.  We'll
probably be encrypting what is passed through in a later version.

  Input:
    label:       Caption to display on button
    name:        Name of the event
    routine:     Name of the event routine to call
                 (defaults to name value if not specified)
                 ('_event_' is prepended to the routine name)
    other_tags:  Other tags for the html item

For example:

    $shop->event_button(
        label      => 'Add Item',
        name       => 'add',
        routine    => 'add',
        other_tags => {
            class => 'myclass'
        }
    );

=cut

###############################################################

sub event_button
{
    my ($self, %args) = @_;

    my $label = $args{label}
        or die "ERROR: event has no label";
    my $name  = $args{name}
        or die "ERROR: event has no event name";
    my $panel_id = $self->get_id;
    my $routine = $args{routine} || $args{name};  # Default to name
    my $other_tags = $args{other_tags};

    my $SEP = $self->SEP;
    my $n = "$name$SEP$routine$SEP$panel_id";

    my $cgi = new CGI;

    my $args_hash = {
        label => $label,
        name => "eventbutton+$n",
    };
    foreach my $other_tag (keys %$other_tags) {
        $args_hash->{$other_tag} = $other_tags->{$other_tag}
    }

    return $cgi->submit($args_hash);

  #  return $cgi->submit({
  #      label => $label,
  #      name => "eventbutton+$n",
  #      style => $style
  #  });
}

###############################################################

=head2 event_link

Display a link (which can be an image link) which when pressed
re-cycles the application and generates an event to be handled
by the next incarnation of the application.

  Input:
    label:       Caption to display on link
     * OR *
    img:         Image to display as link

    name:        Name of the event
    routine:     Name of the event routine to call
                 (defaults to name value if not specified)
                 ('_event_' is prepended to the routine name)
    other_tags:  Other tags for the html item
    img_tags:    Other tags for the image (if the link is an image)

For example:

    $shop->event_link(
        label => 'Add Item',
        name  => 'add',
        other_tags => {
            width => 20
        }
    );

=cut

###############################################################

sub event_link
{
    my ($self, %args) = @_;

    my $label = $args{label};
    my $img = $args{img};
    croak "ERROR: event_link has neither a label nor an image"
        unless $label || $img;
    my $name  = $args{name}
        or die "ERROR: event_link has no event name";
    my $panel_id = $self->get_id;
    my $routine = $args{routine} || $args{name};  # Default to name
    my $other_tags = $args{other_tags};
    my $img_tags = $args{img_tags};
    my $cgi = new CGI;
    my $script_name = $cgi->script_name;

    my $session_id = $self->get_session_id;

    my $SEP = $self->SEP;
    my $n = "$name$SEP$routine$SEP$panel_id";

    my $href = "$script_name?session_id=$session_id&n=$n";
    my $args_hash = {
        href => $href,
    };
    foreach my $other_tag (keys %$other_tags) {
        $args_hash->{$other_tag} = $other_tags->{$other_tag}
    }

    my $output;
    if ($label) {
  #      $output = $cgi->a({href => $href}, $label);
        $output = $cgi->a($args_hash, $label);
    }
    else {
        my $img_args_hash = {
            src => $img,
        };
        foreach my $img_tag (keys %$img_tags) {
            $img_args_hash->{$img_tag} = $img_tags->{$img_tag}
        }
    #    $output = $cgi->a($args_hash, $cgi->img({src => $img}));
        $output = $cgi->a($args_hash, $cgi->img($img_args_hash));
    }

    return $output;
}

###############################################################

=head2 CGI input functions

The CGI input functions are available here with local_ prepended
so the name can be made panel-specific, and they can be called
as a method.  The same effect can be achieved by using the
get_localised_name function for the name of the parameter.

Example:

    $self->local_textfield({name => 'testinput', size => 40})

is equivalent to:

    my $cgi = new CGI;
    $cgi->textfield({name => $self->get_localised_name('testinput'), size => 40})

Using these methods means that the panel will have exclusive
access to the named input parameter.  So to obtain the value of
the input parameter above, we would write the following:

    my %local_params = $self->local_params;
    my $test_input_value = $local_params{'testinput'};

Note that with this technique, several panels could have 
input controls with the same name and they will each receive
the correct value.  This is especially useful for sets of panels
of the same class.

=cut

###############################################################

# Overridden functions

# May be able to combine these into one AUTOLOAD function

###############################################################

=head2 get_localised_name

Return a name that has the panel id encoded into it.  This is
used by the local_... functions and can be used to build a custom
html input control that will deliver its value when the panel's
local_params method is called.

Example:

    $output .= $cgi->textfield({name => $self->get_localised_name('sometext')});

The equivalent could be done by calling:

    $output .= $self->local_textfield({name => 'sometext'});

=cut

###############################################################

sub get_localised_name {
    my ($self, $name) = @_;

    my $localised_name = $self->get_id . $self->SEP . $name;
    return $localised_name;
}

###############################################################

=head2 local_textfield

Generate a localised textfield

Example:

    $output .= $self->local_textfield({name => 'sometext'});

=cut

###############################################################

sub local_textfield {
     my ($self, $args) = @_;
     my $cgi = new CGI;
     $args->{name} = $self->get_localised_name($args->{name});

     return $cgi->textfield($args);
}

###############################################################

sub local_textarea {
     my ($self, $args) = @_;
     my $cgi = new CGI;
     $args->{name} = $self->get_localised_name($args->{name});

     return $cgi->textarea($args);
}

###############################################################

sub local_popup_menu {
     my ($self, $args) = @_;
     my $cgi = new CGI;
     $args->{name} = $self->get_localised_name($args->{name});

     return $cgi->popup_menu($args);
}

###############################################################

sub local_radio_group {
     my ($self, $args) = @_;
     my $cgi = new CGI;
     $args->{name} = $self->get_localised_name($args->{name});

     return $cgi->radio_group($args);
}

###############################################################

# Define the separator used when passing panel ids etc
# and a version which can be used in regexps

sub SEP { ':.:' }
sub SEPRE { qr{:\.:} }

###############################################################

=head2 MAIN PANEL METHODS

These methods provide extra functionality useful for the main
panel of an application.  Apache::Session is used to handle session
information.  An application built using the CGI::Panel framework should
typically have one main panel and a hierarchy of other panels, all of
which inherit from CGI::Panel.

=head2 obtain

Obtains the master panel object

This will either restore the current master panel session
or create a new one

Use:

    my $shop = obtain Shop;

=cut

###############################################################

sub obtain
{
    my ($class) = @_;

    my $messages = $class->interpret_messages();
    my $session_id = $messages->{session_id} || undef;

    my %session = $class->get_or_create_apache_session($session_id);

    my $panel;

    if ($session{mainpanel}) {
        $panel = $session{mainpanel};
    }
    else {
        $panel = new $class;
    }

    # Store the session id in the panel object
    $panel->{session_id} = $session{_session_id};

    ## Store the panel information in the session file
    #$panel->save;

    return $panel;
}

###############################################################

sub tie_apache_session {
    my ($self, $session_id) = @_;

    my %session;
    tie %session, 'Apache::Session::File', $session_id, {
	Directory => $self->session_directory,
	LockDirectory => $self->lock_directory
    };

    return %session;
}

sub get_or_create_apache_session {
    my ($self, $session_id) = @_;

    my %session;
    eval {
        %session = $self->tie_apache_session($session_id);
	die "Session has expired" if $session{state} eq 'EXPIRED';
    };

    # If the session doesn't exist or has expired, create a new one
    my $eval_result = $@;
    if ($eval_result =~ /(expired|does not exist)/) {
        %session = $self->tie_apache_session(undef);
    }
    elsif ($eval_result) {
        die "Unexpected problem in tie_apache_session: $eval_result";
    }

    return %session;
}

sub end_session {
    my ($self) = @_;

    my $session_id = $self->get_session_id
	or die "No session id";
    my %session = $self->tie_apache_session($session_id);
    $session{state} = 'EXPIRED';
}

###############################################################

=head2 cycle

Performs a complete cycle of the application

Takes all the actions that are required for a complete cycle
of the application, including processing events and form data
and displaying the updated screen.  Also manages persistence
for the panel hierarchy.

Use:

    $shop->cycle();

=cut

###############################################################

sub cycle
{
    my ($self) = @_;

    my $messages = $self->interpret_messages();

    if ($messages->{event})
    {
        $self->handle_event($messages->{event});
    }

    if ($messages->{n})
    {
        $self->handle_link_event($messages->{n});
    }

    ## $self->update();  # Probably don't need this as this
                         # will always be handled as an event

    my $screen_name = $self->{screenname} || 'main';
    my $screen_method = "screen_$screen_name";
    $self->$screen_method();

    $self->save();

    return 1;
}

###############################################################

=head2 save

Saves an object to persistent storage indexed by session id.  You don't
normally need to explicitly call this in your application, as it's called
during the 'cycle' method.

Use:

    $self->save;

=cut

###############################################################

sub save
{
    my ($self) = @_;

    my $session_id = $self->{session_id};

    die "ERROR: No session id for save - this shouldn't be possible!"
        unless $session_id;

    my %session;

    tie %session, 'Apache::Session::File', $session_id, {
        Directory => $self->session_directory,
        LockDirectory => $self->lock_directory
    };

    # Store our current state in the tied session hash (ie in persistent storage)
    $session{mainpanel} = $self;

    # Could we have some sort of check here to ensure that the session is
    # saved correctly.  So if there is a problem (like trying to save
    # Net::FTP objects or Tangram storage objects where usually nothing
    # is stored) we detect this and report the problem.

    return 1;
}

###############################################################

=head2 get_panel_by_id

Look up the panel in our list and return it.  Note that this is
different to the 'panel' routine in CGI::Panel, which gets a
sub-panel of the current panel by name.  All the panels
in an application will be registered with the main panel
which stores them in a special hash with an automatically
generated key.  This routine gets any panel in the application
based on the key supplied.

Use:

    my $panel_id = $main_panel->get_panel_by_id(3);

=cut

###############################################################

sub get_panel_by_id
{
    my ($self, $id) = @_;

    # WE SHOULD PROBABLY START USING A HASH HERE
    # IN CASE PANELS ARE REMOVED...
    my $panel = $self->{panel_list}->[$id];
    die "ERROR: Panel ($id) not found:"
        . join ("\n", map { "$_ => " . ref ($self->{panel_list}->[$_]) } (0..10))
        unless $panel;

    return $panel;
}

###############################################################

=head1 OTHER METHODS

The following methods are used behind the scenes, usually from
the 'cycle' method above.  They will generally be sufficient as
they are but can be overridden if necessary for greater
flexibility.

=cut

###############################################################

=head2 register_panel

Accept a panel object and 'register' it - ie store a reference to
it in a special list.  Return the id (hash key) to the caller.

Use:

    my $id = $main_panel->register($panel);

=cut

###############################################################

sub register_panel
{
    my ($self, $panel) = @_;

    # Create the panel list if it doesn't already exist
    $self->{panel_list} = [] unless $self->{panel_list};

    my $list_size = scalar(@{$self->{panel_list}});
    push @{$self->{panel_list}}, $panel;

    return $list_size;
}

###############################################################

=head2 screen_main

Display main screen for the master panel. This is called
automatically by the 'cycle' routine.  Other screen methods
can be defined if necessary, however judicious use of panels
should avoid the need for this.

=cut

###############################################################

sub screen_main
{
    my ($self) = @_;

    my $cgi = new CGI;

    print
      $cgi->header() .
      $cgi->start_form() .
        $cgi->hidden({name     => 'session_id',
                      default  => $self->get_session_id(),
                      override => 1}) .
	$self->display() .
      $cgi->end_form();
}

###############################################################

=head2 handle_event

Handle a button event by passing the event information to the
appropriate event routine of the correct panel.
Currently this is always the panel that generates the event.

=cut

###############################################################

sub handle_event
{
    my ($self, $event_details) = @_;

    my ($name, $routine_name, $panel_id) = split($self->SEPRE, $event_details);
    die "ERROR: Unable to obtain name or routine name"
        unless $name && $routine_name;

    my $real_routine_name = "_event_" . $routine_name;

    my $target_panel = $self->get_panel_by_id($panel_id);
    $target_panel->$real_routine_name({name => $name});
}

###############################################################

=head2 handle_link_event

Handle a link event by passing the event information to the
appropriate event routine of the correct panel.
Currently this is always the panel that generates the event.

=cut

###############################################################

sub handle_link_event {
    my ($self, $event_details) = @_;

    $self->handle_event($event_details);
}

###############################################################

=head2 interpret_messages

Read the request information using the CGI module and
present this data in a more structured way.  In particular
this detects events and decodes the information associated
with them.

=cut

###############################################################

sub interpret_messages
{
    my ($self) = @_;

    my $cgi = new CGI;
    my $t_messages = { map { $_ => $cgi->param($_) } $cgi->param() };
    my $messages;

    # Need to untaint here

    foreach my $messagename(keys %$t_messages)
    {
        # Untaint
        $t_messages->{$messagename} =~ /^(.*)$/;
        my $untainted_value = $1;
        $messages->{$messagename} = $untainted_value;

        # Look for events
        if ($messagename =~ /^eventbutton\+(.*)$/s)
        {
            my $buttondata = $1;
          #  my $buttonmessages;
          #  eval ('$buttonmessages = ' . decrypt($buttondata));
          #  die "ERROR: eval failed ($@)" if $@;
          #  $messages->{event} = $buttonmessages;
            $messages->{event} = $buttondata;
        }
        # Other parameters can be handled here...
    }

    return $messages;
}

###############################################################

=head2 session_directory

This method returns the name of the directory that is used to
store the session files.  It's currently set to '/tmp'.  Override
this method to return a different directory if desired.

=cut

###############################################################

sub session_directory {
    my ($self) = @_;

    # Get cached result if we have it
    #return $class_session_directory
    #    if $class_session_directory};

    my $session_directory = '/tmp';
#    $session_directory = '/tmp/sessions'
#	if -d '/tmp/sessions';
    #$class_session_directory = $session_directory;
    return $session_directory;
}

###############################################################

=head2 lock_directory

This method returns the name of the directory that is used to
store the lock files.  It's currently set to '/tmp'.  Override
this method to return a different directory if desired.

=cut

###############################################################

sub lock_directory {
    my ($self) = @_;

    # Get cached result if we have it
    #return $class_lock_directory
    #    if $class_lock_directory;

    my $lock_directory = '/tmp';
#    $lock_directory = '/var/lock'
#        if -d '/var/lock';
#    $lock_directory = '/var/lock/sessions'
#        if -d '/var/lock/sessions';
#    #$class_lock_directory = $lock_directory;
    return $lock_directory;
}

###############################################################

1; #this line is important and will help the module return a true value
__END__

