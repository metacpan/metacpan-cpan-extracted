# -*- Mode: perl -*-
#
# $Id: Screen.pm,v 0.1.1.1 2001/05/30 21:14:06 ram Exp $
#
#  Copyright (c) 1998-2001, Raphael Manfredi
#  Copyright (c) 2000-2001, Christophe Dehaudt
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: Screen.pm,v $
# Revision 0.1.1.1  2001/05/30 21:14:06  ram
# patch1: added sub-section on creation routine
#
# Revision 0.1  2001/04/22 17:57:03  ram
# Baseline for first Alpha release.
#
# $EndLog$
#

use strict;

package CGI::MxScreen::Screen;

use Carp::Datum;
use Log::Agent;
use Getargs::Long;

use CGI::MxScreen::Constant;
use CGI::MxScreen::Error;
require CGI;

require CGI::MxScreen::Form::Field;
require CGI::MxScreen::Form::Button;

#
# ->make
#
# Screen is the base class of all user defined screens.
#
# Once done, the value of the defined parameters are initialized
# thanks to the data collected by the CGI package within the CGI post.
# For each of the parameters which has a given value, a field 'value'
# is inserted into the parameter record.
#
# Returns: a reference to the newly created object
#
sub make {
    DFEATURE my $f_;
    my $self = bless {}, shift;

	my ($manager, $name, $title, $bgcolor) = cxgetargs(@_, 
		'manager' => 'CGI::MxScreen',
		'name'    => undef,
		'title'   => undef,
		'bgcolor' => []
	);

	$self->{__name} = $name;
	$self->{__title} = $title;
	$self->{__bgcolor} = $bgcolor;

	$self->relink_to_manager($manager);
	$self->_init;				# Internal initialization
	$self->init;				# May be redefined by heirs

    return DVAL $self;
}

#
# ->init
#
# Initialization routine
# It is called the first time the screen is ever made.
#
# This routine is meant to be redefined by heirs, when needed.
#
sub init {}

#
# ->remake
#
# Alternate "creation" routine where object was already created but
# incompletely initialized.
#
sub remake {
    DFEATURE my $f_;
    my $self = shift;
	my ($manager) = @_;

	DREQUIRE defined $manager && $manager->isa("CGI::MxScreen");
	DREQUIRE $self->manager == $manager;

	$self->_init;
	return DVAL $self;
}

#
# ->relink_to_manager
#
# Partial initialization routine which links _manager and _context
# to the new manager.  This allows callbacks referring to a screen to
# still use $screen->vars for instance and get something useful.
#
# This routine is systematically called on all the screens present in
# the context.
#
sub relink_to_manager {
	DFEATURE my $f_;
	my $self = shift;
	my ($manager) = @_;

    $self->{__manager} = $manager;
    $self->{__context} = $manager->context(PERSISTENT);

	return DVOID;
}

#
# ->_init
#
# Internal initalization routine.
#
sub _init {
	DFEATURE my $f_;
	my $self = shift;
	my $manager = $self->manager;

	#
    # Restore previous displayed fields of this screen (if any)
	#

    $self->{__field} = {};
    for my $field (@{$manager->context(SCREEN_FIELD)}) {
        DASSERT $field->isa('CGI::MxScreen::Form::Field');
        $self->{__field}->{$field->name} = $field;
    }

	#
    # Restore previous displayed button of this screen (if any)
	#

    $self->{__transition} = {};
    for my $button (@{$manager->context(SCREEN_BUTTON)}) {
        DASSERT $button->isa('CGI::MxScreen::Form::Button');
        $self->{__transition}->{$button->name} = $button;
    }

	return DVOID;
}

#
# Public attribute access
#

sub manager        { $_[0]->{__manager} }
sub name           { $_[0]->{__name} }

sub error          { $_[0]->{__error} }
sub set_error      { $_[0]->{__error} = $_[1] }
sub error_env      { $_[0]->{__error_env} }

sub vars           { $_[0]->{__context} }
sub screen_title   { $_[0]->{__title} }        # title() conflicts with CGI
sub default_button { $_[0]->{__default_button} }

#
# Private attribute access/setting
#

sub set_error_env { $_[0]->{__error_env} = $_[1] }

#
# ->bgcolor
#
# The background color used to display this screen
#
sub bgcolor {
    DFEATURE my $f_;
	my $self = shift;
	my $color = $self->{__bgcolor};
	$color = $self->manager->bgcolor unless defined $color;
	return DVAL $color;
}

#
# ->_clear_internal_context
#
# clear the fields and buttons context
#
# That method is not suppose to be used by someone else than the
# manager.
#
sub _clear_internal_context {
    DFEATURE my $f_;
    my $self = shift;
    
    $self->{__field} = {};
    $self->{__transition} = {};
    $self->{__default_button} = undef;

    return DVOID;
}

#
# Public methods
#

#
# ->set_default_button
#
# Screens may record a default button (object returned by record_button())
# which will be used when the browser submits a form without indicating a
# pressed button, because they hit "return" in the sole textfield of a form.
#
sub set_default_button {
	DFEATURE my $f_;
	my $self = shift;
	my ($button) = @_;

    VERIFY ref $button && $button->isa("CGI::MxScreen::Form::Button"),
		"argument is a button object: $button";

	my $prev_default = $self->{__default_button};
	logwarn "new default button (%s) in screen \"%s\" supersedes old (%s)",
		$button->value, $self->name, $prev_default->value
		if defined $prev_default;

	return DVAL $self->{__default_button} = $button;
}

#
# ->current_screen
#
# Return screen id along with its parameters for displaying.
#
sub current_screen {
    DFEATURE my $f_;
    return DVAL $_[0]->manager->current_screen;
}

#
# ->previous_screen
#
# Return previous screen id along with its parameters for displaying.
#
sub previous_screen {
    DFEATURE my $f_;
    return DVAL $_[0]->manager->previous_screen;
}

#
# ->spring_screen
#
# Return screen we sprang from, along with its parameters for displaying.
#
sub spring_screen {
    DFEATURE my $f_;
    return DVAL $_[0]->manager->spring_screen;
}

#
# ->record_field
#
# Arguments:
#
sub record_field {
    DFEATURE my $f_;
    my $self = shift;
    my (%args) = @_;

    VERIFY defined $args{-name};

    my $mgr = $self->manager;
    my $id = $args{-name};
    if (defined $self->{__field}->{$id}) {
        DTRACE "field $id already exists";
        $self->{__field}->{$id}->update(%args);

        # save it into the context that must have been previously reset
        push @{$mgr->context(SCREEN_FIELD)}, $self->{__field}->{$id};
        return DVAL $self->{__field}->{$id};
    }

    my $field = CGI::MxScreen::Form::Field->make(%args);
    $self->{__field}->{$id} = $field;
    push @{$mgr->context(SCREEN_FIELD)}, $field;

    return DVAL $field;
}

#
# ->record_button
#
# Arguments:
#
sub record_button {
    DFEATURE my $f_;
    my $self = shift;
    my (%args) = @_;

    VERIFY defined $args{-name};
    
    my $mgr = $self->manager;
    my $id = $args{-name};
    if (defined $self->{__transition}->{$id}) {
        DTRACE("button $id already exists");
        $self->{__transition}->{$id}->update(%args);

        # save it into the context that must have been previously reset
        push @{$mgr->context(SCREEN_BUTTON)}, $self->{__transition}->{$id};
        return DVAL $self->{__transition}->{$id};
    }

    my $button = CGI::MxScreen::Form::Button->make(%args);
    $self->{__transition}->{$id} = $button;
    push @{$mgr->context(SCREEN_BUTTON)}, $button;

    return DVAL $button;
}

#
# ->display		-- deferred
#
sub display { logconfess "deferred" }

#
# (validate)		-- CGI::MxScreen action callback
#
# Validate all the fields, by running all the validation routines.
#
# If any error is found, return CGI_MX_ABORT to abort processing, unless
# $cont was true in which case CGI_MX_ERROR is returned.
#
sub validate {
    DFEATURE my $f_;
    my $self = shift;
	my $env = pop @_;			# Action_Env field
	my ($cont) = @_;
    my $error = 0;

    # run the validation routine for each of fields
    while (my ($k, $field) = each %{$self->{__field}}) {
        DASSERT $field->isa('CGI::MxScreen::Form::Field');

        unless ($field->validate()) {
            $error++;
            next;
        }
    }

    return DVAL
		$error == 0 ? CGI_MX_OK : ($cont ? CGI_MX_ERROR : CGI_MX_ABORT);
}

#
# (abort_on_error)		-- CGI::MxScreen action callback
#
# Action callback which returns CGI_MX_ABORT if an error has been already
# detected in the callback chain.
#
sub abort_on_error {
    DFEATURE my $f_;
    my $self = shift;
	my ($env) = @_;

	DREQUIRE defined $env && $env->isa("CGI::MxScreen::Action_Env");

	return $env->error_count == 0 ? CGI_MX_OK : CGI_MX_ABORT;
}

#
# ->bounce
#
# Raise exception to bounce to another state.
#
# This routine must be called only during ->display(), and no output should
# have been emitted by the displaying routine routine.
#
sub bounce {
	DFEATURE my $f_;
	my $self = shift;

	require CGI::MxScreen::Exception::Bounce;
	my $exception = CGI::MxScreen::Exception::Bounce->make([@_]);

	DTRACE "raising $exception...";

	die $exception;			# The manager traps errors from display()
}

#
# ->enter		-- to be redefined by heirs
#
# Called when we enter a screen from another state.
#
# The screen we come from is given as sole parameter, but can be
# undef for the very first screen ever displayed in the session.
#
sub enter {
}

#
# ->leave		-- to be redefined by heirs
#
# Called when we leave a screen to go another state.
#
# The screen we go to is given as sole parameter.
#
sub leave {
}

#
# (clear_context)		-- CGI::MxScreen action callback
#
# Clear a specific section of the overal context where CGI params that
# are considered orphans (no record_field for them) are automatically
# saved. That section is indexed by the screen name to allow this
# partial clearing.
#
# That method is a good candidate to be put in a list of actions
# associated to a button.
#
# If a state is given, the context of that state is deleted instead of the
# one for the current screen.
#
sub clear_context {
    DFEATURE my $f_;
    my $self = shift;
    pop @_; # any action callbacks receive an extra parameter
	my ($state) = @_;

	VERIFY implies(defined $state, $self->manager->is_valid_state($state)),
		"valid state '$state'";
    
	$state = $self->name unless defined $state;
    my $cgi_ctxt = $self->manager->context(CGI_PARAM);

    return DVAL CGI_MX_OK unless defined (my $ctxt = $cgi_ctxt->{$state});

	DTRACE "About to delete context of state '$state'";

    # first, delete the param in the CGI table 
    while (my ($k, $v) = each %$ctxt) {
        DTRACE "Deleting CGI param '$k'";
        CGI::delete($k);
    }

    # then, delete the key in the context
    delete $cgi_ctxt->{$state};

    return DVAL CGI_MX_OK; # means a success for the action
}

###
### Storable hooks.
###

sub STORABLE_freeze {
	DFEATURE my $f_;
	my ($self, $cloning) = @_;
	return if $cloning;

	my %copy = %$self;
	delete $copy{__context};
	delete $copy{__error_env};
	delete $copy{__error};
	delete $copy{__field};
	delete $copy{__manager};
	delete $copy{__transition};

	return DARY ("", \%copy);
}

sub STORABLE_thaw {
	DFEATURE my $f_;
	my ($self, $cloning, $x, $copy) = @_;

	DREQUIRE !$cloning;
	DREQUIRE length $x == 0;
	DREQUIRE ref $copy eq 'HASH';

	%$self = %$copy;

	return DVOID;
}

1;

=head1 NAME

CGI::MxScreen::Screen - Ancestor for all user screens

=head1 SYNOPSIS

 use base qw(CGI::MxScreen::Screen);

 sub display {                # display screen -- defined
     my $self = shift;
     my ($arg1, $arg2) = @_;
     ...
 }

=head1 DESCRIPTION

This B<deferred> class is meant to be the ancestor of all your application
screens.  You must inherit from C<CGI::MxScreen::Screen> and at least
define the C<display()> routine, which will be called by the C<CGI::MxScreen>
manager when that screen is selected for display.

C<CGI::MxScreen::Screen> objects are blessed hashes.  In order to leave
you as much of the key namespace as possible, all attributes defined by
the deferred class start with I<two> leading underscores.  Contrary to the
routine namespace (see L<"INTERFACE"> below), this simple workaround should
prevent any accidental attribute collision.

Screen objects must be B<serializable>.  That means they must never hold or
refer to objects or data containing things known to be non-serializable,
like GLOB and CODE references.

Screen objects are never created by the user.  They are handled by the
C<CGI::MxScreen> manager, who will ensure that at most B<one instance> of
each screen name will be created during a session.  That means the C<init()>
routine will be called at most once.  I say I<at most> because screens
are created on demand, and if your application does not need to show some
state during a session, then the screen object will never be created.

=head1 INTERFACE

Because you need to inherit, you must be very familiar with the internals
of the class, i.e. not just only the public interface, but also with the
routines used throughout the framework but not meant for public consumption.
Indeed, Perl will not warn you when you accidentally define a routine bearing
the same name as one present in the ancestors (i.e. redefinition is automatic,
which is dangerous here).  And redefining routines as essential as
C<validate()> or C<name()> would lead to havoc.

=head2 Listing

Before detailing the interface, here is a compact list of all the public
features, to make it easier to see what is provided (and know which routine
names are forbidden to you...  A trailing + indicates a routine that you
may choose to redefine, a trailing * indicates a deferred routine, which you
must define.  Functions listed between (parenthesis) are action callbacks,
not meant to be called directly.

The following interface is public, i.e. you may safely use those features
on screen objects:

    (abort_on_error)
    bgcolor
    bounce
    (clear_context)
    current_screen
    default_button
    display*
    enter+
    error
    error_env
    init+
    leave+
    manager
    name
    previous_screen
    record_button
    record_field
    screen_title
    set_default_button
    set_error
    spring_screen
    (validate)
    vars

The following interface is private, i.e. you should never make direct use
of those features on screen objects.  It is used internally by C<CGI::MxScreen>
and is documented (well, listed) so that you never define a feature bearing
that name in your own classes.

Those names you should absolutely B<never override>:

    make
    remake
    relink_to_manager
    _init
    set_error_env
    _clear_internal_context

You must also know that, in order to be serializable with C<Storable>, the
screen defines the following hooks:

    STORABLE_freeze
    STORABLE_thaw

If for some reason you need to redefine those hooks, you B<can't simply>
call C<SUPER::> on them, whilst doing your local processing in the
redefinition.  Look at the source code to understand what needs to be done.

Because the above hooks were necessary, it means that adding other
serializer support (see L<CGI::MxScreen::Serializer>) will probably require
similar hooks.  Unfortunately, although we could design things so as to make
this choice possible, the only serializer we knew about was C<Storable>.

=head2 Creation Routine

Screens are created automatically by the C<CGI::MxScreen> manager, based
on the C<-screens> settings, as explained in
L<CGI::MxScreen/"Creation Routine">.  The only special argument is C<-class>,
which is handled internally by C<CGI::MxScreen>, but the others are passed
verbatim to the screen creation routine.

The supported arguments are:

=over 4

=item C<-bgcolor> => I<color>

Optinal. Overrides the default background for this screen.

=item C<-title> => I<screen_title>

Mandatory.  Sets the screen title.

=back

=head2 Attributes

The following attributes are defined:

=over 4

=item C<bgcolor>

The background color (string form, i.e. either a color name like C<"gray"> or
an hexadecimal representation of the RGB triplet like C<"#1e32ef">) used
to display this screen.

=item C<current_screen>

The current screen being displayed, along with the C<display()> arguments,
as an array reference, for instance:

    ["Welcome", 010125]

where the first item is the screen name, the remaining are the displaying
arguments.  This makes it possible to use that as a C<-target> argument
for buttons (see L<CGI::MxScreen::Form::Button>).

B<Note>: The notion of C<current_screen> is maintained by the manager.
Whatever screen object you query, you will always obtain the I<same> answer.
This note also applies to C<previous_screen> and C<spring_screen>.

=item C<default_button>

The default button recorded via C<set_default_button>.

The default button is used when the user presses <Enter> when submitting
a form, without pressing one of the submit buttons.  Usually, browsers allow
this when there is only one CGI input field in the form.

If there is no default button specified, C<CGI::MxScreen> will remain in
the current state and redisplay the screen.

=item C<error>

The error information, recorded vi C<set_error>.  This is a user-defined
field, i.e. it is not used by C<CGI::MxScreen>.  It is meant to be filled
by action callbacks, when an error is detected.  Since it will be used by
your own screens, you may put whatever you wish.

=item C<error_env>

When an action callback failed, this attribute holds the
C<CGI::MxScreen::Action_Env> object used during the execution of the callback
chain.  See L<CGI::MxScreen::Action_Env> for its access interface.

The attribute is otherwise C<undef>, so you may test it boolean-wise to
determine whether an error did occur or not.

=item C<manager>

The C<CGI::MxScreen> object who manages this screen.

=item C<name>

The screen name, as defined by the C<-screens> argument when C<CGI::MxScreen>
was built.  See L<CGI::MxScreen/"Creation Routine">.

=item C<previous_screen>

The previously displayed screen, in the same form as C<current_screen>.
It will be C<undef> the first time.

If you had a transition from one screen to the same one, then
C<previous_screen> and C<current_screen> will return the same information.
However, see C<spring_screen>.

=item C<screen_title>

This is the title of the screen, as configured during the creation of
the C<CGI::MxScreen> manager, via the C<-screens> argument.  See
L<CGI::MxScreen/"Creation Routine">.

It is not called simply C<title> because screens may use the C<CGI> module,
and C<CGI> exports a C<title()> routine as part of its HTML generation
routines.

=item C<spring_screen>

The screen we sprang from.  This is the last I<stable> state we were in
before jumping into the current screen, transitions to the same screen
not withstanding.  The format is the same as C<current_screen>.

This may be used as C<-target> for buttons to come back to the screen that
directed a transition to the current screen, whatever it was.  See
L<CGI::MxScreen::Form::Button>.

=item C<vars>

This returns a reference to a global persistent hash table, available in all
states.  It is free for use by user screens, but all the values you will
store there must be serializable (by C<Storable>, or any other serializer
you configured).

By default, access to keys within this hash table are protected, to guard
against typos (at runtime, alas).  If you don't like that behaviour, you
can set C<$mx_check_vars> to false in the global configuration.  See
L<CGI::MxScreen::Config>.

=back

=head2 Attribute Setting

The following routines allow changing of some attributes:

=over 4

=item C<set_default_button> I<button_object>

Records a default button for the screen, to be used if they press <Enter> to
submit the form data.  The I<button_object> is a C<CGI::MxScreen::Form::Button>
object, obtained via C<record_button()>.

=item C<set_error> I<value>

Set the C<error> attribute, which is free for use by action callback, for
instance to propagate some error indication to the screen.

=back

=head2 Feature To Be Defined

To make your screen a concrete class, you need to define the B<deferred>
feature, C<display>.

=over 4

=item C<display> I<args>

The routine that displays the CGI form.

It is called by the C<CGI::MxScreen> manager, with some arguments, as defined
by the C<-initial> argument (see L<CGI::MxScreen/"Creation Routine">) or
by the C<-target> button argument (see L<CGI::MxScreen::Form::Button>), or
generally speaking, anything that defines a state transition (e.g. the
C<bounce()> routine, as described below).

Before calling the routine, C<CGI::MxScreen> initialized the HTML headers
and opened the form tag, directing the submission to the script's URL, but
I<without> the query string: if one is supplied initially, it is up to you
to save the relevant information in the persistent context, or in your
screen objects, since they are also persistent.

The routine must print to STDOUT its generated HTML, and can make use of
all the helper routines from the C<CGI> module to generate form controls
or emit HTML via routines.  There are also some other helper routines defined
in L<CGI::MxScreen::HTML>.

When it returns, the screen is supposed to have been fully displayed, and the
form will be closed automatically by C<CGI::MxScreen>.  If you haven't read
them already, you should study L<CGI::MxScreen/"Example"> and
L<CGI::MxScreen::Layout>.

A screen is given the opportunity to redirect itself to another state, by
sending a bounce execption to the manager via C<bounce()>.  However, it may
do so only if it has not already emitted anything.  If you left
C<$mx_buffer_stdout> to its default I<true> setting
(see L<CGI::MxScreen::Config>), anything you output before bouncing will be
discarded for you.

Usually, your screens will define fields and submit buttons.  You should
record them to be able to attach validation routines or action callbacks,
but you may choose not to and use plain raw C<CGI> routines, with manual
hidden context propagation.  However, note that it would be a waste, because
C<CGI::MxScreen> is supposed to handle that for you, and also the only
C<display()> routine called is the one for the visible screen.  Any other
parameters defined on other screens would not even have the opportunity to
hide themselves...  As for buttons, not recording them means you won't be
able to make use of the state machine features.

To record fields and buttons, use C<record_field()> and C<record_button()>.

=back

=head2 Features To Be Redefined

The following features have empty default implementations, and are meant to
be B<redefined> in your screens.  It is not necessary to redefine all of
them, or any of them, if you don't need them:

=over 4

=item C<enter> I<from_screen>

Called when we enter a screen whilst coming from another one.  The screen
object we sprang from is given as argument, but will be C<undef> for the
very first screen displayed (the I<initial> screen).

B<Note>: we're passed a screen I<object>, not a list representation like
the one returned by C<spring_screen()>.

=item C<init>

Called when the screen object is created.

You may do whatever initialization is necessary on your object, but remember
that screen objects are created B<once> and remain persistent accross the
whole session.  Therefore, if you need runtime initialization each time
one enters this screen, write it within C<enter()>.

=item C<leave> I<to_screen>

Called when we leave a screen to go to I<to_screen>, which is a screen
object.  Contrary to C<enter()>, this one is always defined, by construction.

B<Note>: we're passed a screen I<object>, not a list representation like
the one returned by C<spring_screen()>.

=back

=head2 Control Features 

Those features are necessary to let the screen control what's going to
happen when the form is submitted.  They are meant to be used during
C<display()> processing:

=over 4

=item C<bounce> I<screen_name>, I<args>

This is an I<exception> (sic!) to the definition given above.
By calling C<bounce()>, a screen redirects the state machine to the
screen called I<screen_name>, with I<args> being the C<display()> arguments.

You should not call C<bounce()> after having emitted something.  This feature
is meant to be an exception, allowing to bypass a state when some condition
is met.

To avoid endless loops, there is an hardwired limit of 20 consecutive bounces
allowed.  As famous people said on other occasion when talking about
computer limits, "this should be sufficient for any application".

=item C<record_button> I<args>

Records a submit button, and returns a C<CGI::MxScreen::Form::Button> object.
Please see L<CGI::MxScreen::Form::Button> for the interface, and the
description of what I<args> can be.

=item C<record_field> I<args>

Records a control field, and returns a C<CGI::MxScreen::Form::Field> object.
Please see L<CGI::MxScreen::Form::Field> for the interface, and the
description of what I<args> can be.

=back

=head2 Action Callbacks

Those features are not meant to be used directly, but are provided so that
they can be used as action callbacks attached to buttons, as described in
L<CGI::MxScreen::Form::Button>.

The most important one is C<'validate'> (spelled as a string because this
is how it should be used: see L<CGI::MxScreen/"Callbacks">), which will
trigger all the field verfication and patching callbacks.

=over 4

=item C<abort_on_error>

This callback returns C<CGI_MX_ABORT> to immediately abort the callback
chain if there is an error already in one of the preceding callbacks.
See L<CGI::MxScreen::Error>.

=item C<clear_context> [I<screen_name>]

Clears a specific section of the overal context where I<orphan> CGI parameters
are saved. A CGI parameter is B<orphan> if there was no C<record_field()>
done for it.

If I<screen_name> is not specified, this applies to the current screen.

This callback is useful if you wish to discard the state of orphan CGI
parameters, so that the next time they are created, they get their default
value.

=item C<validate> [I<continue>]

Runs the validation and patching callbacks on all the recorded fields for
this screen.  If I<continue> is I<true>, any error will not be fatal
immediately, i.e. C<CGI_MX_ERROR> will be returned, so that other action
callbacks may execute.  If not specified, it defaults to I<false>, meaning
a failed validation immediately triggers the error and the end of the
action callback sequence.

=back

Here is an example of action callback settings for a submit button:

    my $ok = $self->record_button(
        -name       => "OK",
        -target     => "Next",
        -action     => [
            'validate',                 # Same as ['validate', 0]
            ['do_something', $self],
            'abort_on_error',
            ['clear_context', "Next"],
        ]
    );

See L<CGI::MxScreen::Form::Button> for more information on C<record_button()>.

=head1 AUTHORS

The original authors are
Raphael Manfredi F<E<lt>Raphael_Manfredi@pobox.comE<gt>>
and
Christophe Dehaudt F<E<lt>Christophe.Dehaudt@teamlog.frE<gt>>.

Send bug reports, suggestions, problems or questions to
Jason Purdy F<E<lt>Jason@Purdy.INFOE<gt>>

=head1 SEE ALSO

CGI::MxScreen(3), CGI::MxScreen::Form::Button(3),
CGI::MxScreen::Form::Field(3).

=cut

