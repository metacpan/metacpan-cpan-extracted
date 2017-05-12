# -*- Mode: perl -*-
#
# $Id: Button.pm,v 0.1 2001/04/22 17:57:03 ram Exp $
#
#  Copyright (c) 1998-2001, Raphael Manfredi
#  Copyright (c) 2000-2001, Christophe Dehaudt
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: Button.pm,v $
# Revision 0.1  2001/04/22 17:57:03  ram
# Baseline for first Alpha release.
#
# $EndLog$
#


package CGI::MxScreen::Form::Button;

use Carp::Datum;
use Getargs::Long qw(ignorecase);

# index of the array
BEGIN {
    sub NAME ()           {0}
    sub TARGET ()         {1}
    sub ACTION ()         {2}
    sub VALUE ()          {3}
    sub DYN_TARGET ()     {4}
    sub ON_ERROR ()       {5}
    sub DYN_ON_ERROR ()   {6}

    sub CGI_ARGS ()       {7}
}


#
# ->make
#
# Arguments: (that are considered, others values are kept aside) 
#   -name           => string
#   -action         => 
#   -target         => 'symbol' or ['symbol' , @arg ]
#   -value          => string to display (optional, defaults to name)
#   -dyn_target     => 'symbol' or ['symbol' , @arg ]
#   -on_error       => 'symbol' or ['symbol' , @arg ]
#   -dyn_on_error   => 'symbol' or ['symbol' , @arg ]
#
sub make {
    DFEATURE my $f_;
    my $self = bless [], shift;
	my ($name, $value, $target, $dyn_target, $action,
		$on_error, $dyn_on_error) =
	cxgetargs(@_, { -strict => 0, -extra => 0 },
		-name			=> 's',
		-value			=> ['s'],
		-target			=> [],
		-dyn_target		=> [],
		-action			=> [],
		-on_error		=> [],
		-dyn_on_error	=> [],
	);

    VERIFY defined $target || defined $dyn_target,
		"must specify one of -target or -dyn_target";

    VERIFY !defined $on_error || !defined $dyn_on_error,
		"cannot specify both -on_error and -dyn_on_error";

    VERIFY implies(defined $on_error || defined $dyn_on_error, defined $action),
		"must specify -action when using -on_error or -dyn_on_error";

	$self->[VALUE] = $value eq '' ? $name : $value;
    $self->update(@_);
    return DVAL $self;
}

#
# ->update
#
sub update {
    DFEATURE my $f;
    my $self = shift;
 
    ($self->[NAME], 
     $self->[ACTION],
     $self->[TARGET], 
     $self->[DYN_TARGET], 
     $self->[ON_ERROR], 
     $self->[DYN_ON_ERROR], 
     @{$self->[CGI_ARGS]}) =
		cxgetargs(@_, {-strict => 0},
			-name			=> 's',
			-action			=> ['ARRAY'],
			-target			=> [undef],
			-dyn_target		=> [undef],
			-on_error		=> [undef],
			-dyn_on_error	=> [undef],
		);

    DREQUIRE equiv(defined $self->[DYN_TARGET], !defined $self->[TARGET]);

    unshift @{$self->[CGI_ARGS]}, (-name => $self->name);
    return DVOID;
}


# Temporary method
#
# To Be Removed
# when storable would be able to select what is stored with
# Storable::Hook
sub cleanup {
    DFEATURE my $f_;
    my $self = shift;
    
    $#{$self} = DYN_ON_ERROR;

    return DVOID;
}


#########################################################################
# Class Feature: usable from the external world                         # 
#########################################################################
sub name           { $_[0]->[NAME] }
sub action         { $_[0]->[ACTION] }
sub target         { $_[0]->[TARGET] }
sub dyn_target     { $_[0]->[DYN_TARGET] }
sub on_error       { $_[0]->[ON_ERROR] }
sub dyn_on_error   { $_[0]->[DYN_ON_ERROR] }
sub value          { $_[0]->[VALUE] }

sub is_computed_target { defined $_[0]->[DYN_TARGET] }
sub has_error_trap
	{ defined $_[0]->[ON_ERROR] || defined $_[0]->[DYN_ON_ERROR] }

#
# ->properties
#
# return the full list of arg that were given at creation time. The
# result can be used to supply the CGI functions.
#
# Return:
#   a list of arguments.
#
sub properties {
    DFEATURE(my $f_);
    my $self = shift;
    
    return DARY (@{$self->[CGI_ARGS]});
}

1;

=head1 NAME

CGI::MxScreen::Form::Button - A recorded button

=head1 SYNOPSIS

 # $self is a CGI::MxScreen::Screen

 use CGI qw/:standard/;

 my $ok = $self->record_button(
     -name       => "ok",
     -value      => "OK to Continue",
     -action     => ['validate', [$obj, 'do_something', @args]],
     -target     => "next_screen",
     -on_error   => "error_screen",
 );

 print submit($ok->properties);

=head1 DESCRIPTION

This class models a recorded button.  One does not manually create objects
from this class, they are created by C<CGI::MxScreen> when the
C<record_button()> routine is called on a screen object to declare a new
button.

In order to use the state machine features from C<CGI::MxScreen>, it is
necessary to declare all the submit buttons you are going to generate.
The declaration routine takes a set of meaningful arguments, and lets
the others pass through verbatim (they are recorded to be given back when
C<properties()> is called).

The minimal set of arguments to supply are C<-name> and C<-target> (or
C<-dyn_target>).  You will probably supply C<-action> as well if you
wish to perform validation of control fields, or any other processing
attached to the pressing of that button.

=head1 INTERFACE

=head2 Creation Arguments

Some of the arguments below expect I<callback> arguments.
The callback representation rules are documented in L<CGI::MxScreen/Callbacks>.

Some of the callbacks or arguments below are expected to yield I<states>.
See L<CGI::MxScreen/States> for state representation rules.

The following named arguments may be given to C<record_button()>.
Any other argument is simply recorded and will be propagated via
C<properties()>.  Arguments are all optional but for C<-name>, and one
of C<-target> or C<-dyn_target> must be supplied:

=over 4

=item C<-action> => [I<callback1>, I<callback2>, ...]

The list of action callbacks that should be run when the button is pressed.
Those will be run before any state change, since failure of one of those
callbacks could mean we stay in the same state.

A trailing C<CGI::MxScreen::Action_Env> object is appended to the list
of callback arguments.  It can be used to check whether any action callback
in the chain as already reported an error.  In the last action callback
listed, this could be used to execute some processing only if we're about
to change state, i.e. when no error occured.

B<Note>: when using the second form of callback specification (i.e. an array
ref), double brackets must be used, since the list of callback actions must
itself be within brackets:

    -action => [['callback', $arg1]],   # RIGHT

If you were to write by mistake:

    -action => ['callback', $arg1],     # WRONG

then that would result in the following actions (C<$screen> is the current
screen object where the button is recorded):

    $screen->callback($env);            # $env is the Action_Env
    $screen->$arg1($env);

which will usually not be what you intended.

Each callback must return a success/error status, as documented
in L<CGI::MxScreen::Error>.

=item C<-dyn_on_error> => I<callback>

When any of the C<-action> callbacks returns a non-OK status, an error flag
is raised.  By default, the same screen will be re-displayed.  When a
C<-dyn_on_error> callback is specified, the screen to display is computed
dynamically.  You may not use this option in conjunction with C<-on_error>.

A trailing C<CGI::MxScreen::Action_Env> object is appended to the callback
argument list.  This object records the failed action callbacks, in case
that could help determine the state to move to.
See L<CGI::MxScreen::Action_Env>.

The I<callback> is expected to return a new state specification: it can
be a single scalar (the state name), or an array ref (state name as
first item, remaining values being C<display()> parameters).
See L<CGI::MxScreen/States> for details.

=item C<-dyn_target> => I<callback>

When a C<-dyn_target> callback is specified, the next target state is
computed dynamically.  You may not use this option in conjunction with
C<-target>.

The I<callback> is expected to return a new state specification: it can
be a single scalar (the state name), or an array ref (state name as
first item, remaining values being C<display()> parameters).
See L<CGI::MxScreen/States> for details.

=item C<-name> => I<name>

Madantory parameter, giving the name of the button.  This is the CGI parameter
name.  The displayed button will be labeled with I<name>, unless there is
also a C<-value> given.

=item C<-on_error> => I<target_state>

When any of the C<-action> callbacks returns a non-OK status, an error flag
is raised.  By default, the same screen will be re-displayed.  When an
C<-on_error> trap is specified, the screen to display is given by
I<target_state>.  You cannot use C<-dyn_on_error> in conjunction with
this argument.

The I<target_state> can be a single scalar (the state name), or an
array ref (state name as first item, remaining values being C<display()>
parameters).  See L<CGI::MxScreen/States>.

=item C<-target> => I<target_state>

This argument defines the target state to move to when all action callabacks
(if any) returned an OK status.  Either this argument or C<-dyn_target>
B<must> be specified when recording a button.

=item C<-value> => I<value>

This specifies the button's value, which will be displayed by browser instead
of the parameter name.

=back

Any other argument will be recorded as-is and passed through when
C<properties()> is called on the button object.

=head2 Features

Once created via C<record_button>, the following features may be called
on the object:

=over 4

=item C<has_error_trap>

Returns I<true> when there is an C<-on_error> or C<-dyn_on_error> argument.

=item C<name>

Returns the button name.

=item C<properties>

Generates the list of CGI arguments suitable to use with the routines
in the C<CGI> modules.  An easy way to generate a submit button is to
do:

	print submit($b->properties);

assuming C<$b> was obtained through a C<record_button()> call.

=item C<value>

Returns the recorded button value, or the name if no value was given.
When referring to a button, this is the feature to use, as in:

	print p("Once done, press the", b($done->value), "button.");

which lets you factorize the button's value (aka label) in one place, making
things easier if you decide to change it later on.

=back

=head1 AUTHORS

The original authors are
Raphael Manfredi F<E<lt>Raphael_Manfredi@pobox.comE<gt>>
and
Christophe Dehaudt F<E<lt>Christophe.Dehaudt@teamlog.frE<gt>>.

Send bug reports, suggestions, problems or questions to
Jason Purdy F<E<lt>Jason@Purdy.INFOE<gt>>

=head1 SEE ALSO

CGI::MxScreen(3), CGI::MxScreen::Form::Field(3).

=cut

