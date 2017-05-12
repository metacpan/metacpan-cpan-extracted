# -*- Mode: perl -*-
#
# $Id: MxScreen.pm,v 0.1.1.1 2001/05/30 21:13:07 ram Exp $
#
#  Copyright (c) 1998-2001, Raphael Manfredi
#  Copyright (c) 2000-2001, Christophe Dehaudt
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: MxScreen.pm,v $
# Revision 0.1.1.1  2001/05/30 21:13:07  ram
# patch1: fixed HISTORY section
# patch1: random cleanup in named argument docs
# patch1: updated version number
#
# Revision 0.1  2001/04/22 17:57:03  ram
# Baseline for first Alpha release.
#
# $EndLog$
#


use strict;

package CGI::MxScreen;

use vars qw($VERSION $BIN_VERSION);
$VERSION = '0.103';
$BIN_VERSION = '0.1';

use CGI::MxScreen::Constant;
use CGI::MxScreen::Error;
use Carp::Datum;
use Log::Agent;
use Getargs::Long;
use Time::HiRes qw(time);

require CGI;
require CGI::MxScreen::Form::Field;
require CGI::MxScreen::Form::Button;
require CGI::MxScreen::Layout;
require CGI::MxScreen::Session;

my @managers;		# For END {}

#
# ->make
#
# Creation routine.
#
sub make {
    DFEATURE my $f_;
    my $self = bless {}, shift;
	my ($tm_start, $tm_user, $tm_sys) = (time, times);

	#
	# Prevent anything to be written to STDOUT by tieing it to a package
	# that will log anything written there, without letting it go through.
	#

	require CGI::MxScreen::Tie::Stdout;
	tie *main::STDOUT, "CGI::MxScreen::Tie::Stdout";

	#
	# Argument parsing.
	#

    (
		$self->{_screen_list},
		$self->{_initial_state}, 
		$self->{_cgi_version},
		$self->{_valid_time},
		$self->{_bgcolor},
		$self->{_layout},
	) =
		cxgetargs(@_,
			-screens	=> 'HASH',
			-initial	=> undef, 
			-version	=> [undef, '1.0'],
			-timeout	=> ['i'],
			-bgcolor	=> [undef, '#bfbfbf'],
			-layout		=> ['CGI::MxScreen::Layout'],
		);
    
	$self->{_start_times} = [$tm_start, $tm_user, $tm_sys];
	$self->{_last_times} = [$tm_start, $tm_user, $tm_sys];
	$self->{_layout} = CGI::MxScreen::Layout->make()
		unless defined $self->{_layout};

	#
	# Perform default initialization if not already done via a call
	# to "use CGI::MxScreen::Config;".
	#

	require CGI::MxScreen::Config;
	CGI::MxScreen::Config::configure();		# Will return if already done

	if (defined $CGI::MxScreen::Config::LOG) {
		$self->{_log} = $CGI::MxScreen::Config::LOG;
	} else {
		use File::Spec;
		require Log::Agent::Logger;
		require Log::Agent::Channel::File;

		my $devnull = Log::Agent::Channel::File->make(
			-filename		=> File::Spec->devnull,
			-no_prefixing	=> 1,
			-no_ucfirst		=> 1,
			-no_newline		=> 1,
		);
		$self->{_log} = Log::Agent::Logger->make(-channel => $devnull);
	}

	#
	# Now that logging is up, validate the creation routine parameters.
	#

	logcroak "-initial must be either a plain scalar or an ARRAY ref"
		if ref $self->initial_state && ref $self->initial_state ne "ARRAY";

	my $state_name = ref $self->initial_state ?
		$self->initial_state->[0] : $self->initial_state;

	logcroak "initial state '$state_name' is not a known state"
		unless $self->is_valid_state($state_name);

	#
    # Initialize whole script context.
	#

	$self->trace_incoming;	# XXX if logtrace_at("info") or logdebug_at("warn")

	my $session = $self->{_session} = CGI::MxScreen::Session->make(
		-serializer		=> $CGI::MxScreen::Config::SERIALIZER,
		-medium			=> $CGI::MxScreen::Config::MEDIUM,
	);

	$self->{_context} = $session->restore;
	$self->check_validity();

	#
	# Relink all serialized screens to the new manager.
	#

	my $ctx = $self->ctx;

	if (exists $ctx->{'screens'}) {
		foreach my $screen (values %{$ctx->{'screens'}}) {
			$screen->relink_to_manager($self);
		}
	}

	#
	# For session logging, maintain the following parameters in
	# the private CGI::MxScreen context.
	#
	#    log_session    unique session ID for logging (IP number-PID)
	#    log_starttime  time when session started
	#    log_cnt        counter incremented each time we're invoked
	#
	#

	unless (exists $ctx->{'log_session'}) {
		$ctx->{'log_session'} = CGI::remote_host() . "-" . $$;
		$ctx->{'log_starttime'} = int(time);
		$ctx->{'log_cnt'} = 0;
	} else {
		$ctx->{'log_cnt'}++;
	}

	#
	# From now on, all Log::Agent messages will bear the session ID.
	#

	require Log::Agent::Tag::String;
	use Log::Agent qw(logtags);

	my $tag = Log::Agent::Tag::String->make(
		-name		=> "session id",
		-value		=> "(" . $ctx->{'log_session'} . ")",
	);

	my $log = $self->log;
	$log->tags->append($tag);
	logtags()->append($tag);

	$log->warning("");
	$log->warning(\&log_session, $self);
	$log->info(\&log_agent, $self);
	$log->debug(\&log_inc_times, $self, "context restore + log init");

	#
	# Process incoming parameters, trap all errors.
	#
	# Since we might be using CGI::Carp, we must cancel any trap hook by
	# localizing the __DIE__ and __WARN__ special handlers.
	#

	eval {
		local $SIG{__DIE__};
		local $SIG{__WARN__};

		$self->process_params;
	};
	$log->debug(\&log_inc_times, $self, "parameter init");
	$self->internal_error($@) if chomp $@;

	push(@managers, $self);

    return DVAL $self;
}

#
# ->process_params
#
# Get CGI parameters, fill internal data structures.
#
sub process_params {
	DFEATURE my $f_;
	my $self = shift;

    #
    # Save params provided by CGI
    #
    # It is a quite big story because there are different possiblities
    # for the store location according to the way the fields have been
    # recorded, and also according to the storage indication settings.
    #
    # When the field has been recorded at display time (use of
    # record_field method), it might contain some storage indications
    # (see Form::Field). It may also contain an indication to not save
    # the value (useful for password). Anyway, when the incoming param
    # matches a recorded field from the last display, the store_value
    # method of the field is invoked to perform the task according to
    # the indication. Returning true indicates there is no need to
    # save the param value in the MxScreen repository (see
    # below). Actually, either the value has been save somewhere else
    # or there were some indication to not keep the value persistent.
    # 
    # When there is no specific indication for the storage (either the
    # field has not been recorded but has been merely displayed, or
    # the store_value method returned false), the value is memorized
    # into the MxScreen repository for the orphan params. It is a
    # dedicated section of the context. Each orphan params is stored
    # in that section under the index of the screen name. All the orphan
    # params are replayed --put into the CGI param list-- to benefit
    # from their values when the field is once again displayed.
    #
    # NOTES: You have to know that a button press returns also a value
    # into the incoming CGI param list. The following code needs to
    # take care of that by filtering them before being considered as
    # orphan fields. For simple button, it is quite easy since the
    # param name must have been recorded into the Mxscreen Button
    # list, but for image button the returned param does not match
    # exactly the one recorded. For this latter button, the returned
    # param is in fact 2 params which indicates the click
    # location. Their name is composed by the param name (recorded in
    # the Mxscreen Button list) plus '.x' or '.y'.
    #
    # NOTES: CGI param list does not alway returned a value for all
    # displayed field of the screen. For some specific elements (for
    # instance checkbox group), no value is returned when the field is
    # cleared (no box checked in the previous example). This clear
    # value must however be saved into the storage location. To cope
    # this problem, all the known displayed fields (those in the
    # recorded list of fields, and those in the orphan repository of
    # the screen) are checked to validate the existence of a value
    # into the CGI param list. When no value is found, a clear value
    # ('') is enforced.
    #

    # load the package of the last screen where all needed classes
    # should have been defined.
    my $current_state = $self->initial_state;
    $current_state = $self->ctx->{'current_state'} if
      (defined $self->ctx->{'current_state'});
    my ($screen_name) = $self->scatter($current_state);
    $self->load_screen_package($screen_name);

    # build a easy access way to recorded field and button: make a
    # hash from the array
    my $var_ctx = $self->context(PERSISTENT);
    my $field_hash = {};
    for my $field (@{$self->context(SCREEN_FIELD)}) {
        DASSERT $field->isa('CGI::MxScreen::Form::Field');
        $field_hash->{$field->name} = $field;
    }

    my $button_hash = {};
    for my $button (@{$self->context(SCREEN_BUTTON)}) {
        DASSERT $button->isa('CGI::MxScreen::Form::Button');
        $button_hash->{$button->name} = $button;
    }

	#
    # Patch the CGI param list for fields which are known to be
    # displayed but no value appears in the CGI list.
	#

    my $cgi_param = $self->context(CGI_PARAM);

    while (my ($k, $v) = each %{$cgi_param->{$screen_name}}) {
        CGI::param(-name => $k, -values => $v) unless 
          defined CGI::param($k);
    }
    while (my ($k, $v) = each %$field_hash) {
        CGI::param(-name => $k, -values => $v->value) unless 
          defined CGI::param($k);
    }
    
    # walkthrough the CGI param list to store values
    for my $param (CGI::param()) {
        DTRACE "storing incoming param $param";
        my $field = $field_hash->{$param};

        # return form CGI param might be either a single element or a
        # list of elements. To get all of them, an array context must
        # be used. Then, the value that will be stored is either the
        # array reference or the first and single element of the
        # array.
        my @value = CGI::param($param);
        my $value = $#value == 0 ? $value[0]: \@value;

        if (defined $field) {
			#
            # Patch the value (if needed)
            # Then store value according to the storage indication given in
            # the field (if any)
			#
			my ($patched, $nvalue) = $field->patch_value($value);
			if ($patched) {
				CGI::param(-name => $param, -values => $nvalue) if $patched;
				next if $field->store_value($var_ctx, $nvalue);
			} else {
				next if $field->store_value($var_ctx, $value);
			}
        }
        # no storage indication is present

        #
        # perhaps it was a button rather than a field
        #

        # image button press is embarrassing. In such a case, the
        # returned param is not 1 but 2 params which represents the
        # location of the click within the image
        if ($param =~ /(.*)\.([xy])$/) {
            if (defined (my $x = CGI::param("$1.x")) &&
                defined (my $y = CGI::param("$1.y"))) {
                next if $2 eq "y"; # do the job only for x
                $param = $1;
            }
        }

        if (defined $button_hash->{$param}) {
            $self->internal_error(
                "invalid input form: buttons '" . $self->button_pressed->name .
                 "' and '$param' were simultaneously pressed!")
              if defined $self->button_pressed;

            # Remember it as the button that was pressed
            $self->{_button_pressed} = $button_hash->{$param};
            next;
        }

        # It is an orphan field that has not been saved.  Keep it in
        # mind into the param repository.  The param context is stored
        # under the name of the screen to build a kind of
        # hierachy. That allows the clean up functionality when
        # leaving a screen (on explicit request).
        $cgi_param->{$screen_name}->{$param} = $value;
    }

    # all orphan params will populate the CGI's param list if they are
    # not already present. That will allow to prefill fields when
    # redisplay and to give an access to their values with regular
    # CGI::param().
    #
    # Information is organized in a hash table where the key is the
    # screen id (state name) and the value is another hash. The latter
    # contains the pair of data: symbol, value that must be restored.
    while (my ($screen , $hash) = each %$cgi_param) {
        while (my ($k, $v) = each %$hash) {
            CGI::param(-name => $k, -values => $v);
        }
    }

	return DVOID;
}


#########################################################################
# Internal Attribute Access: these methods are not intended to be used  #
# from the external world.                                              #
#########################################################################

sub screen_list    { $_[0]->{'_screen_list'} }
sub context_root   { $_[0]->{'_context'} }
sub screen         { $_[0]->{'_screen'} }
sub session        { $_[0]->{'_session'} }
sub cgi_version    { $_[0]->{'_cgi_version'} }
sub valid_time     { $_[0]->{'_valid_time'} }
sub initial_state  { $_[0]->{'_initial_state'} }
sub bgcolor        { $_[0]->{'_bgcolor'} }
sub layout         { $_[0]->{'_layout'} }
sub log            { $_[0]->{'_log'} }
sub start_times    { $_[0]->{'_start_times'} }
sub last_times     { $_[0]->{'_last_times'} }

sub button_pressed { $_[0]->{_button_pressed} }
sub ctx            {
	defined $_[0]->{'_context'} ? $_[0]->{'_context'}->[MXSCREEN] : {}
}

#
# ->is_valid_state
#
# Check whether state is known
#
sub is_valid_state {
    DFEATURE my $f_;
    my $self = shift;
    my ($state) = @_;

    return DVAL exists $self->screen_list->{$state};
}

#
# ->load_screen_package
#
# Load source file for the class implementing the screen $name, unless
# it is already present.
#
sub load_screen_package {
    DFEATURE my $f_;
    my $self = shift;
    my ($name) = @_;

    DREQUIRE $self->is_valid_state($name), "valid state '$name'";

    my ($class_name) = cgetargs(@{$self->screen_list->{$name}}, 
                                {-strict => 0},
                                qw(class));

	#
	# The following eval "" attempts to load the screen class by using
	# a require, assuming there is one class by file.  However, we
	# check for the presence of an @ISA variable in the target package
	# before performing the require, since the application could have
	# already loaded all the screen classes.  Given that all screens must
	# inherit from CGI::MxScreen::Screen, we know @ISA is defined if the
	# package is present.
	#

	eval "require $class_name unless defined \@${class_name}::ISA;";
	if (chomp $@) {
		logerr "loading of $class_name failed: $@";
		logdie "can't locate class \"$class_name\" for screen state \"$name\"";
	}

    return DVOID;
}

#
# ->make_screen
#
# Create the screen for given state.
#
sub make_screen {
    DFEATURE my $f_;
    my $self = shift;
    my ($name) = @_;

    DREQUIRE $self->is_valid_state($name), "valid state '$name'";

    $self->load_screen_package($name);
    my ($class_name, @remaining) = cgetargs(@{$self->screen_list->{$name}},
                                            {-strict => 0, -extra => 1},
                                            qw(class));

	#
	# If the state has already been seen already, it has been serialized
	# in the context, but it needs to be relinked to the new manager instance.
	#
	# Otherwise, a new object is created and remembered in the context.
	#

	my $cxt = $self->ctx;		# CGI::MxScreen own private context
	my $screen;

	if (exists $cxt->{'screens'}->{$name}) {
		$screen = $cxt->{'screens'}->{$name};
		$screen->remake($self);
	} else {
		$screen = $class_name->make(
			-manager => $self,
			-name    => $name,
			@remaining
		);
		$cxt->{'screens'}->{$name} = $screen;
	}

    return DVAL $screen;
}

#
# ->scatter
#
# Return:
#   either a list with a single element when incoming param is a
#   scalar value or a list with all element of the incoming list.
#
sub scatter {
    DFEATURE my $f_;
    my $self = shift;
    my ($id) = @_;

    return DARY @$id if ref $id eq 'ARRAY';
    return DARY ($id);
}

#
# ->obj_scatter
#
# Same as scatter(), but handles ($obj, $routine, @args) as well.
# Supplies the screen if no blessed object is identified in the first
# position of the list.
#
sub obj_scatter {
    DFEATURE my $f_;
    my $self = shift;
    my ($screen, $id) = @_;

	return DARY ($screen, $id) unless ref $id eq 'ARRAY';

	if (ref $id->[0] && UNIVERSAL::isa($id->[0], "UNIVERSAL")) {
		$screen = $id->[0];
		return DARY ($screen, @$id[1..$#$id]);
	}

	return DARY ($screen, @$id);
}

#########################################################################
# Class Feature: usable from the external world                         #
#########################################################################

#
# ->context
#
# return a reference of a given section withtin the overal context
# area
#
# Arguments:
#   $index: index of the context section to returned
#
# Return:
#   a reference to the requested context section
#
sub context {
    DFEATURE my $f_;

    DREQUIRE $_[1] =~ /^\d+$/;
	DREQUIRE $_[1] >= 0 && $_[1] < CONTEXT_COUNT;

    return DVAL $_[0]->context_root->[$_[1]];
}

#
# ->spring_screen
# ->previous_screen
# ->current_screen
#
# Returns [state, display_args]
#
sub spring_screen {
    DFEATURE my $f_;
    return DVAL $_[0]->ctx->{'spring_state'};		# Last stable state(args)
}
sub previous_screen {
    DFEATURE my $f_;
    return DVAL $_[0]->ctx->{'previous_state'};		# Previous state(args)
}
sub current_screen {
    DFEATURE my $f_;
    return DVAL $_[0]->ctx->{'current_state'};		# Current state(args)
}


#
# ->play
#
# Play the sequence of action necessary to display the new screen.
#
sub play {
    DFEATURE my $f_;
    my $self = shift;

# coderef is a temporary arg until storable is able to select things to
# store (storable::Hook)
    my ($coderef) = @_;

	my $log = $self->log;
	$log->debug(\&log_inc_times, $self, "outside CGI::MxScreen");

	#
	# Compute target screen, trap all errors.
	#
	# Since we might be using CGI::Carp, we must cancel any trap hook by
	# localizing the __DIE__ and __WARN__ special handlers.
	#

	my ($screen, $args);
	eval {
		local $SIG{__DIE__};
		local $SIG{__WARN__};

		($screen, $args) = $self->compute_screen;
	};
	$log->debug(\&log_inc_times, $self, "screen computation");
	$self->internal_error($@) if chomp $@;

	#
	# Emit CGI headers
	# From now on, output is safe and will not get us a server error.
	#

	untie *main::STDOUT;			# Restore original STDOUT stream

	#
	# If they configured us to buffer all STDOUT until context is ready
	# to be emitted, then create object, print headers and mark the
	# output of headers as done: further output to STDOUT will be buffered
	# and printed only after the context.
	#
	# The reason for this is to have the context emitted before any other
	# form widget.  That way, pressing a submit button before the whole form
	# is loaded in the browser won't matter as much, since we'll have at
	# least the context to propagate in the POST parameters.
	#

	my $stdout;
	if ($CGI::MxScreen::cf::mx_buffer_stdout) {
		require CGI::MxScreen::Tie::Buffered_Output;
		$stdout = tie *main::STDOUT, "CGI::MxScreen::Tie::Buffered_Output";
	}

	#
	# Display screen, with proper "bounce" exception support.
	# Returns screen that was finally displayed.
	#

	$screen = $self->display($screen, $args, $stdout);
	$log->debug(\&log_inc_times, $self, "\"%s\" display", $screen->name);

	#
	# Snapshot current time and last modification date of the
	# scriptright before saving context.  That fields can be used to
	# check for session validity.
	#

    $self->ctx->{'time'} = time;
    $self->ctx->{'script_date'} = (stat($0))[9]; 

	#
	# Cleanup context to avoid saving transient data
	#

    &{$coderef}() if defined $coderef; # TBR

    for my $f (@{$self->context_root->[SCREEN_FIELD]}) {
        DASSERT $f->isa('CGI::MxScreen::Form::Field');
        $f->cleanup();
    }
    for my $b (@{$self->context_root->[SCREEN_BUTTON]}) {
        DASSERT $b->isa('CGI::MxScreen::Form::Button');
        $b->cleanup();
    }

	#
	# If STDOUT was bufferd, the context must be emitted explicitely
	# between the header of the form and the remaining data.
	#

	if (defined $stdout) {
		my $context = $self->session->save;
		$stdout->print_all($context);
		untie_stdout();
	} else {
		print $self->session->save;
	}

	$log->debug(\&log_inc_times, $self, "context save");

	#
	# Emit CGI trailers.
	#

	print CGI::endform;

	my $layout = $self->layout;
	$layout->postamble;
	$layout->end_HTML;

    return DVOID;
}

#
# ->compute_screen
#
# Compute target screen, and run and enter/leave hooks if we change screens.
# This routine does not display anything, but runs all the action callbacks.
#
# Returns new screen object, and a ref to the argument list.
#
sub compute_screen {
	DFEATURE my $f_;
	my $self = shift;
    my ($current_state, $previous_state, $new_state);
    my ($origin_name, $target_name, @arg_list);
    my $screen;
	my $errors = 0;
    my $ctx = $self->ctx;

   
    # get the current state from the context its format can be either
    # 'screen_name' or ['screen_name', @arg_list]. 'screen_name' is the
    # symbol key given to a screen name into the given screen list (at
    # make time) and @arg_list is a list of arg to pass to the display
    # routine of the screen.

    $current_state = $self->initial_state;
    $current_state = $ctx->{'current_state'} if
      (defined $ctx->{'current_state'});

    $previous_state = $current_state;
    $new_state = $current_state;

    #
    # Compute the destination and process the associated actions when
    # a button has been detected as pressed (during the make method).
	#
	# If we could not identify a button that was pressed, we'll simply
	# remain in the current state and re-display the form unless there was
	# a default button recorded in the previous screen.
    #

	my $button_pressed = $self->button_pressed;

	if ($ctx->{'log_cnt'} && !defined $button_pressed) {

		#
        # Create the previous screen to lookup for a default button
		#

        ($origin_name) = $self->scatter($previous_state);
        $screen = $self->make_screen($origin_name);
		my $default = $screen->default_button;

		if (defined $default) {
			$button_pressed = $self->{_button_pressed} = $default;
			$self->log->warning("no button pressed, using default \"%s\"",
				$default->value);
		} else {
			$self->log->error(
				"no button pressed, no default, will stay in same state");
		}
	}

    if (defined $button_pressed) {
     
		#
        # Create the previous screen to perform the actions
		# Screen could have been created above, during the default
		# button computation, hence the check.
		#

		unless (defined $screen) {
			($origin_name) = $self->scatter($previous_state);
			$screen = $self->make_screen($origin_name);
		}

		# Those are not serialized
		DASSERT !defined $screen->error_env, "no callback error condition";
		DASSERT !defined $screen->error, "no user error condition";

		my $act_env;					# Action environment

        if (defined $button_pressed->action) {
            DASSERT ref $button_pressed->action eq 'ARRAY';

			use CGI::MxScreen::Error qw(is_mx_errcode);
			require CGI::MxScreen::Action_Env;

			$act_env = CGI::MxScreen::Action_Env->make();

            for my $action (@{$button_pressed->action}) {
                my ($obj, $routine, @routine_arg) =
					$self->obj_scatter($screen, $action);

				my $errcode = $obj->$routine(@routine_arg, $act_env);

				#
				# Temporary safety net whilst migration of all callback
				# returned values is ongoing.
				#

				if ($errcode == 0 || $errcode == 1) {
					logwarn "callback %s->%s returned OLD boolean status",
						ref $obj, $routine;
					$errcode = $errcode ? CGI_MX_OK : CGI_MX_ABORT;
				}

				VERIFY is_mx_errcode($errcode),
					"callback ", ref($obj), "->$routine returns valid code",
					" -- returned $errcode";

				next if $errcode == CGI_MX_OK;

				#
                # an error occurred, don't process the remaining
                # of actions if it is CGI_MX_ABORT.
				#
				# The screen is tagged with an error flag and the state
				# destination is resumed to the origin screen.
				#

				my $called = sprintf "%s->%s", ref($obj), $routine;
				my $binfo = sprintf "for button \"%s\"",
					$button_pressed->value;
				$binfo .= sprintf " (%s)", $button_pressed->name
					if $button_pressed->name ne $button_pressed->value;

                DTRACE "error in action callback: $called $binfo";
                $self->log->error("action callback $called failed $binfo%s",
					$errcode == CGI_MX_ABORT ? ", aborting" : "");

				$errors++;
                $screen->set_error_env($act_env);
				$act_env->add_error($obj, $routine, \@routine_arg);
				last if $errcode == CGI_MX_ABORT;
			}

			$new_state = $current_state if $errors;
        }
        
		#
        # Get the destination
		#
		#  * when an error was found, we look at -on_error or -dyn_on_error,
		#    and if one is found, we clear the error condition.
		#  * when no error is raised, we look at -dyn_target or -target.
		#

        if ($errors) {
			#
			# Look for possible error trapping, which will force a move to
			# an alternate screen.  The error condition is reset, therefore
			# the internal context of the screen will be cleared.
			#
			# For -dyn_on_error, we append the action environment.
			#

			DASSERT defined $act_env, "at least one action ran";

            if ($button_pressed->has_error_trap) {
				my $dyn = $button_pressed->dyn_on_error;
				if (defined $dyn) {
					my ($routine, @args) = $self->scatter($dyn); 
					DASSERT $screen->can($routine);
					$new_state = $screen->$routine(@args, $act_env);
				} else {
					$new_state = $button_pressed->on_error;
				}
				DASSERT defined $new_state;
				$errors = 0;			# Moving to alternate screen
			}
		} else {
			#
			# No error found.
			#

            if ($button_pressed->is_computed_target) {
                my ($routine, @args) = 
                  $self->scatter($button_pressed->dyn_target); 
                DASSERT $screen->can($routine);

                $new_state = $screen->$routine(@args);
            }
            else {
                $new_state = $button_pressed->target;
            }
        }
    }

    # clear context area dedicated to save field handles
    $self->context_root->[SCREEN_FIELD] = [];
    $self->context_root->[SCREEN_BUTTON] = [];
    # context might have been saved by the screen -> also clear the copy
    $screen->_clear_internal_context() if defined $screen && !$errors;

	#
    # update the MXSCREEN context
	#
    $ctx->{'current_state'} = $new_state;
    $ctx->{'previous_state'} = $previous_state unless $errors;
    $ctx->{'cgi_version'} = $self->cgi_version;
    $ctx->{'bin_version'} = $BIN_VERSION;

	$self->log->notice(\&log_state, $self, $previous_state, $new_state);

    #
    # Create the destination state (if needed)
	# Then call ->leave and ->enter hooks.
    #

    ($target_name, @arg_list) = $self->scatter($new_state);
	unless (defined $screen && $target_name eq $origin_name) {
		my $prev_screen = $screen;
		$screen = $self->make_screen($target_name);
		if (defined $prev_screen) {
			$prev_screen->leave($screen);
			$ctx->{'spring_state'} = $previous_state;	# Where we came from
		}
		$screen->enter($prev_screen);
	}

    return DARY ($screen, \@arg_list);
}

#
# ->display
#
# Display $screen, with args @$args, with proper support for screen "bounce".
#
# If $stdout is not undef, then it is a ref to a tied object, meaning STDOUT
# is buffered.  When bouncing with untied STDOUT, the layout and the headers
# can only be emitted once, i.e. for the original screen.  A warning is issued
# if bouncing.
#
# Returns screen that was finally displayed.
#
sub display {
	DFEATURE my $f_;
	my $self = shift;
	my ($screen, $args, $stdout) = @_;

	for (my $i = 0; $i < 20; $i++) {		# Max 20 bounces

		#
		# Can only emit the layout and the header each time when $stdout
		# is tied.  We always emit the first time, naturally, since we
		# don't know whether we'll bounce at all.
		#

		if ($i == 0 || defined $stdout) {

			#
			# The layout object controls the following aspects:
			#
			#  html headers
			#    preamble
			#      <form goes here>
			#    postabmle
			#  html trailers
			#

			my $layout = $self->layout;

			$layout->init($screen);
			$layout->start_HTML(
				-title		=> $screen->screen_title,
				-bgcolor	=> $screen->bgcolor,
			);
			$layout->preamble;

			#
			# Start the form
			#

			my @args = (-method => 'POST', -action => CGI::url());
			print $CGI::DISABLE_UPLOADS ?
				CGI::startform(@args) : CGI::start_multipart_form(@args);

		}

		$stdout->header_ok if defined $stdout;		# Buffer remaining as BODY

		#
		# Display target screen, trap all errors.
		#

		eval {
			local $SIG{__DIE__};
			local $SIG{__WARN__};

			$screen->display(@$args);
		};

		#
		# Deal with "bounce" exceptions.
		#

		if (ref $@ && $@->isa("CGI::MxScreen::Exception::Bounce")) {
			my $old_state = $self->current_screen;
			my $new_state = $@->target;
			my $log = $self->log;
			my $old_name = $screen->name;
			my $old_screen = $screen;

			$log->notice(\&log_bounce, $self, $old_state, $new_state, $@);
			$log->debug(\&log_inc_times, $self, "bounce on \"%s\"", $old_name);

			my ($target_name, @arg_list) = $self->scatter($new_state);

			#
			# Clear buffered data in tied STDOUT, so we may start afresh
			# with new screen.  If the old screen had started emitting data
			# before bouncing, warn them: the screen should not have done so
			# anyway, so we may discard data bluntly.
			#

			if (defined $stdout) {
				my $discarded = $stdout->reset;
				logwarn "discarded %d byte%s emitted by \"%s\" " .
					"(before bouncing to \"%s\")",
					$discarded, $discarded == 1 ? "" : "s",
					$old_name, $target_name if $discarded;
			}

			#
			# Set args for next loop.
			#

			$screen = $self->make_screen($target_name);
			$args   = \@arg_list;
			$self->ctx->{'current_state'} = $new_state;

			#
			# Need to call ->leave() and ->enter() when states are different.
			# We pass undef to leave() to indicate that we left as the result
			# of a bounce.
			#
			# We don't alter `spring_state' though.
			#

			if ($target_name ne $screen->name) {
				$old_screen->leave(undef);				# Signals: bounced
				$screen->enter($old_screen);
			}

			next;			# Restart display loop
		}

		#
		# Regular display error.
		#

		if (ref $@ || chomp $@) {
			my $msg = $@;
			$msg =~ s/^\(.*?\)\s+//;	# Remove already added session tag
			$self->log->critical("display error for screen \"%s\": %s",
					$screen->name, $msg);

			#
			# If they buffered STDOUT, it's nice, because the screen will not
			# mix regular output and the error message.  And since we discard
			# even the form header, the Content-Type printed by CGI::Carp will
			# not even show!
			#

			untie_stdout(1) if defined $stdout;
			logdie $msg;
		}

		return DVAL $screen;		# Successfully displayed the screen
	}

	$self->log->critical("too many screen bounces");
	logdie "possible infinite loop detected, aborting";
}

#
# ->check_validity
#
# Check context validity: proper version, no timeout.
#
sub check_validity {
    DFEATURE my $f_;
    my $self = shift;

	unless (defined $self->context_root) {
		logerr "mangled context from %s", CGI::remote_host();
		$self->internal_error("cannot retrieve application context");
	}

    my $ctx = $self->ctx;
	return DVOID unless exists $ctx->{'cgi_version'};	# Empty context

	#
	# Ensure binary version (which traces variations in the way session
	# context are represented) is compatible.
	#

	my $bin = $ctx->{'bin_version'};
    if ($bin > $BIN_VERSION) {
        $self->internal_error(<<EOS);
Script session used a format (v$bin) more recent than I am (v$BIN_VERSION).
Please restart a new session.
EOS
	}

    #
    # check that the script file has not been modified (compare the
    # last modification time on the file system)
    #
    if ($ctx->{'script_date'} != (stat($0))[9]) {
        $self->internal_error(<<EOS);
Script file has been modified since the last display, 
please restart a new session.
EOS
    }

    #
    # check whether the cgi version is still the same
    #
    if (defined $ctx->{'cgi_version'}) {
        my $version = $ctx->{'cgi_version'};

        if ($version ne $self->cgi_version) {
            $self->internal_error(<<EOS);
Script version has evolved since the last display, please restart a new session.
EOS
        }
    }

    #
    # check whether the timeout is not exhausted
    #
    if (defined $self->valid_time && defined $ctx->{'time'}) {
        my $last_time = $ctx->{'time'};

        if ((time - $last_time) > $self->valid_time) {
            $self->internal_error(<<EOS);
Session timeout since the last display, please restart a new session.
EOS
        }
    }

    return DVOID;
}

#
# ->internal_error
#
#
sub internal_error {
    DFEATURE my $f_;
    my $self = shift;
    my ($message) = @_;

	my $logmsg = $message;
	$logmsg =~ s/\s+/ /sg;
	logerr "internal error: $logmsg";

	untie_stdout(1);		# Restore original STDOUT stream, discard all

	my $layout = $self->layout;

	$layout->init(undef);
	$layout->start_HTML("Internal Script Error");
	$layout->preamble;

    print CGI::h1("Internal Script Error");
    print CGI::p(CGI::tt(ucfirst($message)));
    print CGI::p(CGI::a({-href => CGI::url()}, "Restart a new session"));

	$layout->postamble;
	$layout->end_HTML;

	my $log = $self->log;
	$log->alert("internal error: $logmsg") if defined $log;

    exit 0;
}

#
# ->trace_incoming
#
# Trace incoming parameters
#
sub trace_incoming {
	DFEATURE my $f_;
	foreach my $p (CGI::param()) {
		my $value = CGI::param($p);
		DTRACE(TRC_INFO, "incoming param: '$p' => '$value'");
	}
	return DVOID;
}

#
# (log_session)			-- logging callback
#
# Log session state
#
sub log_session {
	DFEATURE my $f_;
	my $self = shift;
    my $current = $self->current_screen || $self->initial_state;
	my $cxt = $self->ctx;
	my $cnt = $cxt->{log_cnt};
	my ($state) = $self->scatter($current);
	my $user = CGI::remote_user();
	my @url_param = CGI::url_param();
	my $query = join(';', map { "$_=" . CGI::url_param($_) } @url_param);

	my $msg = sprintf "[%s/%d]", $state, $cnt;
	$msg .= sprintf " t=%s", relative_age(int(time) - $cxt->{log_starttime});
	$msg .= sprintf " d=%s", relative_age($^T - $cxt->{time}) if $cnt;
	$msg .= " u=\"$user\"" if $user;

	#
	# If there were no parameters on the URL, CGI still returns one entry
	# for a "keywords" parameter, so we need to guard against this as well.
	#

	$msg .= " q=\"$query\"" if $query ne '' && $query ne 'keywords=';

	return DVAL $msg;
}

#
# (log_state)			-- logging callback
#
# Log state change and button pressed
#
sub log_state {
	DFEATURE my $f_;
	my $self = shift;
	my ($old, $new) = @_;
	my $cxt = $self->ctx;
	my $cnt = $cxt->{log_cnt};

	my ($old_state, @old_args) = $self->scatter($old);

	my $msg = sprintf "%s%s",
		$old_state, @old_args ? ("(" . join(', ', @old_args) . ")") : "";

	unless ($cnt) {							# First time
		return DVAL '' unless @old_args;	# Don't log state if no args
		return DVAL $msg
	}

	my ($new_state, @new_args) = $self->scatter($new);

	$msg .= sprintf " -> %s%s",
		$new_state, @new_args ? ("(" . join(', ', @new_args) . ")") : "";

	#
	# Log button pressed, or bounce indication.
	#

	my $button = $self->button_pressed;
	if (defined $button) {
		my $name = $button->name;
		my $value = $button->value;
		$msg .= sprintf " on \"%s\" pressed", $value;
		$msg .= sprintf " (%s)", $name if $value ne $name;
	}

	return DVAL $msg;
}

#
# (log_bounce)			-- logging callback
#
# Log screen bounces
#
sub log_bounce {
	DFEATURE my $f_;
	my $self = shift;
	my ($old, $new, $bounce) = @_;
	my $cxt = $self->ctx;

	my ($old_state, @old_args) = $self->scatter($old);

	my $msg = sprintf "%s%s",
		$old_state, @old_args ? ("(" . join(', ', @old_args) . ")") : "";

	my ($new_state, @new_args) = $self->scatter($new);

	$msg .= sprintf " -> %s%s",
		$new_state, @new_args ? ("(" . join(', ', @new_args) . ")") : "";

	$msg .= " (via $bounce)";

	return DVAL $msg;
}

#
# (log_agent)			-- logging callback
#
# Log user agent
#
sub log_agent {
	DFEATURE my $f_;
	my $self = shift;
	my $cnt = $self->ctx->{log_cnt};
	return if $cnt;					# Nothing after first time
	return DVAL sprintf "using \"%s\"", CGI::user_agent();
}

#
# (log_inc_times)		-- logging callback
#
# Log incremental time between values recorded in last_times and now.
# Update last_times as a side effect for next incremental logging.
#
sub log_inc_times {
	DFEATURE my $f_;
	my $self = shift;
	my ($fmt, @args) = @_;			# Can be single string or (fmt, args)
	$fmt = sprintf $fmt, @args if @args;
	my $times = $self->last_times;
	my $new_times = [time, (times)[0,1]];
	$self->{_last_times} = $new_times;
	my @delta;
	for (my $i = 0; $i < @$times; $i++) {
		$delta[$i] = $new_times->[$i] - $times->[$i];
	}
	return DVAL sprintf "t=%.2fs usr=%.2fs sys=%.2fs [%s]", @delta, $fmt;
}

#
# (log_total_time)		-- logging callback
#
# Log total time spent since start_times.
#
sub log_total_time {
	DFEATURE my $f_;
	my $self = shift;
	my $times = $self->start_times;
	my $new_times = [time, (times)[0,1]];
	my @delta;
	for (my $i = 0; $i < @$times; $i++) {
		$delta[$i] = $new_times->[$i] - $times->[$i];
	}
	my $runtime = time - $^T;
	return DVAL sprintf "t=%.2fs usr=%.2fs sys=%.2fs [total time] T=%.2fs",
		@delta, $runtime;
}

#
# relative_age
#
# Given seconds, convert to 4d9h23m15s format.
#
sub relative_age {
	DFEATURE my $f_;
	my ($secs) = @_;
	my ($days, $hours, $mins);

	$days  = int($secs / (24 * 60 * 60));
	$secs -= $days     * (24 * 60 * 60);

	$hours = int($secs / (60 * 60));
	$secs -= $hours    * (60 * 60);

	$mins  = int($secs / 60);
	$secs -= $mins     * 60;

	my $retstr  = '';
	$retstr .= $days  . "d" if $days;
	$retstr .= $hours . "h" if $hours;
	$retstr .= $mins  . "m" if $mins;
	$retstr .= int($secs + 0.5) . "s";	# can be fractional with Time::HiRes

	return DVAL $retstr;
}

#
# ::add_utils_path              -- static
#
# Screen designers can identify new Form::Utils packages for their own
# specific uses with this routine. It must be invoked in the user
# script as a static routine => CGI::MxScreen::add_utils_path , and
# before the creation of the MxScreen object.
#
# NB: This routine name is misleading: it does not involve file paths, but
# module names.  The purpose is to allow some kind of routine lookup to
# be able to locate a validation routine named "is_time" for instance.
# I'm keeping it for now, because it's been used in production, but this
# mechanism will have to be revisited.
#	-- RAM, 13/04/2001
#
sub add_utils_path {
    DFEATURE my $f_;

    VERIFY defined($_[0]) && !UNIVERSAL::isa($_[0], __PACKAGE__);

	require CGI::MxScreen::Form::Utils;

    CGI::MxScreen::Form::Utils::add_path(@_);
    return DVOID;
}

#
# ::untie_stdout
#
# Safely untie STDOUT by forcing a DESTROY, in case someone holds a reference
# on the tied object.
#
sub untie_stdout {
    DFEATURE my $f_;
	my ($discard) = @_;
	my $stdout = tied *main::STDOUT;

	#
	# Within CGI::MxScreen, all the packages that can be tied to STDOUT are
	# heirs of CGI::MxScreen::Tie::Sinkable, which provides a discard_all()
	# method.
	#

	DASSERT !defined($stdout) || $stdout->isa("CGI::MxScreen::Tie::Sinkable");

	if (defined $stdout) {
		logtrc 'info', "un-tieing STDOUT (%s) with%s discarding",
			ref $stdout, $discard ? "" : "out";
		$stdout->discard_all if defined $discard && $discard;
		$stdout->DESTROY;
		untie *main::STDOUT;
	}
    return DVOID;
}

#
# END
#
# Whatever happens, log total running time, provided they created a manager.
#
sub END {
	untie_stdout();		# They might have not got a chance to do so yet

	#
	# Log running time, once per manager.
	#

	foreach my $self (@managers) {
		$self->log->info(\&log_total_time, $self);
	}
}

1;
__END__

=head1 NAME

CGI::MxScreen - a multi-screen stateful CGI framework

=head1 SYNOPSIS

 require CGI::MxScreen;

 my $manager = CGI::MxScreen->make(
     -bgcolor    => "#dedeef",
     -screens    =>
         {
             "state_1"   =>
                 [-class => "STATE_1", -title => "Hello"],
             "state_2"   =>
                 [-class => "STATE_2", -title => "Hello #2"],
         },
     -initial    => "state_1",
     -version    => "1.0",
 );

 $manager->play();

=head1 DESCRIPTION

C<CGI::MxScreen> is a framework for building multi-screen stateful CGI
programs.  It is rather object-oriented, with some peculiarities brought
by persistency constraints: all objects must be handled by C<Storable>.

C<CGI::MxScreen> is based on the C<CGI> module, and co-operates with it,
meaning you are able to use most C<CGI> calls normally.  The few places
where you should not is where C<CGI::MxScreen> supersedes the C<CGI>
functionalities: for instance, there's no need to propagate hidden values
when you use C<CGI::MxScreen>.

C<CGI::MxScreen> is architected around the concept of B<screens>.
Among the set of defined screens within the same script, only one is visible
at a time.  One moves around the various screens by pressing buttons,
which submit data to the server and possibly move you to a different screen.
The state machine is handled by C<CGI::MxScreen>, the user only defines
which state (I<screen>) a button shall move the application to

C<CGI::MxScreen> is stateful in the sense that many of the runtime objects
created to operate (and screens are among those) are made persistent.
This is a very interesting property, because you do not have to worry
too much about the underlying stateless nature of the CGI protocol.  The
C<CGI> module brought the statefulness to the level of form controls, but
C<CGI::MxScreen> raises it to the level of the application itself.

C<CGI::MxScreen> is not meant to be used for so-called I<quick and dirty>
scripts, or for scripts which do not require some fair amount of round trips
between the browser and the server.  You'll be better off with using
the good old C<CGI> module.  However, for more complex web applications,
where there is a fair amount of processing required on the server side, and
where each script involves several states, C<CGI::MxScreen> is for you.

OK, enough talking.

=head1 FRAMEWORK

This section describes the C<CGI::MxScreen> framework.  If you wish to
read about the interface of the C<CGI::MxScreen> managing object, please
skip down to L<"INTERFACE">.

=head2 Features

Here are the main features of C<CGI::MxScreen>:

=over 4

=item *

The module is a superset of the C<CGI> module.  You can continue to use C<CGI>
routines wherever you like.

=item *

It handles B<sessions> for you, saving much of the application state, and
making CGI hidden parameters useless.  You may save sessions within the
browser, or to files, or you may even build your own medium backend.
You may also define your own serializing options, although C<Storable> is
natively supported.
See L<CGI::MxScreen::Session::Medium> for the medium interface and
L<CGI::MxScreen::Serializer> for the serialization interface.

=item *

It handles the state machine for you.  You define the various B<screen
objects>, and then specify, for each submit button, which state the
application should go.  The target state can be specified statically,
or computed dynamically by the application.  Action routines can be
attached to the button, to run some processing during the state change.
See L<CGI::MxScreen::Form::Button> for more information.

=item *

It has an object-oriented design.  Each screen is an object inheriting from
C<CGI::MxScreen::Screen> and redefining the C<display> routine, at least.
There are also C<enter> and C<leave> hooks for each screen.
Each created screen object is made persistent accross the whole session.
See L<CGI::MxScreen::Screen> for the full interface.

=item *

Any script output done before the screen's C<display> routine is called
will be trapped and discarded (with logging showing the place where such a
violation occurs).  This architecturally enforces proper application behaviour.
Furthermore, by default, the whole output is buffered until it is
time to save the context, thereby protecting against further submits
with a partially received form on the browser side, and also strengthening
the protection when the application uses bounce exceptions to jump into
another state.

=item *

Each CGI parameter (form control) can be given an explicit storage indication
(i.e. how the application should dispose of the value), a validation routine,
and an on-the-fly patching routines (to normalize values, for instance).
Each parameter may also be given a mandatory status, causing an error when
it is not filled.
See L<CGI::MxScreen::Form::Field> for more information.

=item *

There is a global hash that is made available to all screens and which is
made persistent accross the whole session.  By default, every key access
to that hash is checked to prevent typos, and reading an unknown key is
a fatal error (at run-time, unfortunately).

=item *

There are layout hooks allowing the generation of a common preamble and
postamble section, common to a group of scripts.  See L<CGI::MxScreen::Layout>
for details.

=item *

The framework can be configured by loading a configuration Perl script,
allowing easy sharing of the settings among a set of scripts, with
possible local superseding on a script basis.  See L<CGI::MxScreen::Config>
for details.

=item *

All error logging is done via C<Log::Agent>, and application logging is
done via C<Log::Agent::Logger>, which ensures the maximum flexibility.
Logfile rotation is also supported via C<Log::Agent::Rotate>.
Configuration of the various logging parameters is done via the
C<CGI::MxScreen::Config> interface.

=item *

C<CGI::MxScreen> uses C<Carp::Datum> internally.  If you have chosen to
install a non-stripped version, you may trace parts of the module to better
understand what is going on with the various callbacks you register.

=back

=head2 Flow

Here is a high-level description of the processing flow when issuing requests
to a C<CGI::MxScreen> script:

=over 4

=item *

An initial log tracing the user (if HTTP authentication is used), the
time since the session started, the elapsed time since the previous display,
and the CGI query string is emitted.

=item *

The session context is retrieved if any, otherwise a new one is created.
The context holds the various screen objects, the submit buttons and other
form fields descriptions, plus all the other data stored within the
persistent global hash.

=item *

Input parameters are processed, following the directives held within the
session to validate and optionally store them in some place.
If an error is detected, the application remains in the same state and
the previous screen is redisplayed.

=item *

If no error occurred during parameter processing, the target state is computed
based on the descriptions attached to the button that was pressed.  The
state can be given statically, or computed by a routine.
The determined target state is composed of a screen object, plus some optional
arguments that are to be given to its C<display> routine.
Any processing action attached to the button is also run at that point.

=item *

The transition is logged, tracing the pressed button, the previous state
and the new one.

=item *

If a screen change occurs (i.e. the new screen to display is not the same
as the previously displayed one), the C<leave> routine is called on the
old screen and C<enter> is called on the new one.

=item *

The enclosing form setting is emitted, and the screen's C<display> routine
is called to actually generate the form's content.  Before they output
anything, screens are allowed to request the bouncing to some other state,
based on some local information (but if output buffering is configured, any
spurious output from the old screen will be cleanly discarded).
Any other exception that can occur during C<display> is trapped and cleanly
logged, before displaying an internal error message.

=item *

The application context is saved, the form is closed, and buffered output
is emitted.  A final log tracing the total time spent is emitted.

=back

=head2 Example

The following example demonstrates the various common operations that need
to be performed with C<CGI::MxScreen>.

An important comment first: if we forget about the fact that you need
an object per screen (which has some code overhead compared to using
plain C<CGI>), you will need to write more I<declarative> code with
C<CGI::MxScreen> than you would with C<CGI>, but this buys you more
persistent state for fields, and lets you define the state transitions and
associated processing for buttons.

Moreover, please note that this example could be written in less code
by using the C<CGI> module only.  But C<CGI::MxScreen> is not aimed at
simple scripts.

Our example defines a two-state script, where one choose a color in the
first screen, and then a week day in the second screen.  The script reminds
you about the choice made in the other screen, if any.  It is possible to
"redraw" the first screen to prove that the selection made is sticky.
First, the whole script:

  1 #!/usr/local/bin/perl -T
  2 
  3 package Color; use base qw(CGI::MxScreen::Screen);
  4 
  5 use CGI qw/:standard/;
  6 
  7 sub init {
  8     my $self = shift;
  9     $self->vars->{color} = "";
 10 }
 11 
 12 sub display {
 13     my $self = shift;
 14     print h1($self->screen_title);
 15 
 16     my $color = $self->record_field(
 17         -name       => "color",
 18         -storage    => "color",
 19         -default    => $self->vars->{color} || "Green",
 20         -override   => 1,
 21         -values     => [qw(Red Green Blue White Black Yellow Orange Cyan)],
 22     );
 23 
 24     print p("You told me your favorite weekday was", $self->vars->{weekday})
 25         if exists $self->vars->{weekday};
 26 
 27     print p("Your favorite color is", popup_menu($color->properties));
 28 
 29     my $ok = $self->record_button(
 30         -name   => "Next",
 31         -target => "Weekday");
 32 
 33     my $redraw = $self->record_button(
 34         -name   => "Redraw",
 35         -target => $self->current_screen);
 36 
 37     print submit($ok->properties), submit($redraw->properties);
 38 }
 39 
 40 package Weekday; use base qw(CGI::MxScreen::Screen);
 41 
 42 use CGI qw/:standard/;
 43 
 44 sub init {
 45     my $self = shift;
 46     $self->vars->{weekday} = "";
 47 }
 48 
 49 sub display {
 50     my $self = shift;
 51     print h1($self->screen_title);
 52 
 53     print p("You told me your favorite color was", $self->vars->{color});
 54 
 55     my $weekday = $self->record_field(
 56         -name       => "day",
 57         -storage    => "weekday",
 58         -default    => $self->vars->{weekday} || "Mon",
 59         -override   => 1,
 60         -values     => [qw(Mon Tue Wed Thu Fri Sat Sun)],
 61     );
 62 
 63     print p("Your favorite weekday is", popup_menu($weekday->properties));
 64 
 65     my $back = $self->record_button(
 66         -name       => "Back",
 67         -target     => $self->spring_screen,
 68     );
 69 
 70     print submit($back->properties);
 71 }
 72 
 73 package main;
 74 
 75 require CGI::MxScreen;
 76 
 77 my $manager = CGI::MxScreen->make(
 78     -screens    =>
 79         {
 80             'Color'     => [-class => 'Color',   -title => "Choose Color" ],
 81             'Weekday'   => [-class => 'Weekday', -title => "Choose Day" ],
 82         },
 83     -initial    => ['Color'],
 84 );
 85 
 86 $manager->play();
 87 

Let's study this a piece at a time:

  1 #!/usr/local/bin/perl -T
  2 

The classical declaration for a CGI script, in taint mode.

  3 package Color; use base qw(CGI::MxScreen::Screen);
  4 

This defines the first state, C<Color>.  It inherits from
C<CGI::MxScreen::Screen>, as it should.

  5 use CGI qw/:standard/;
  6 

We're going to use CGI routines.  We could do with less than what is
exported by the C<:standard> tag, but I did not bothered.

  7 sub init {
  8     my $self = shift;
  9     $self->vars->{color} = "";
 10 }
 11 

The C<init()> routine is called on the screen the first time it is created.
Upon further invocations, the same screen object will be used and re-used
each time we need to access the C<Color> state.

To differentiate from a plain C<CGI> script which would use hidden parameters
to propagate the information, we store the application variable in the
persistent hash table, which every screen can access through C<$self-E<gt>vars>.
Here, we initialize the C<"color"> key, because any access to an unknown
key is an error at runtime (to avoid malicious typos).

 12 sub display {
 13     my $self = shift;

The C<display()> routine is invoked by the state manager on the screen
selected for displaying.

 14     print h1($self->screen_title);
 15 

Prints screen title.  This refers to the defined title in the manager,
which are declared for each known screen further down on lines 78-82.

 16     my $color = $self->record_field(
 17         -name       => "color",
 18         -storage    => "color",
 19         -default    => $self->vars->{color} || "Green",
 20         -override   => 1,
 21         -values     => [qw(Red Green Blue White Black Yellow Orange Cyan)],
 22     );
 23 

This declaration is very important.  It tells C<CGI::MxScreen> that the
screen makes use of a field named C<"color">, and whose value should be
stored in the global persistent hash under the key C<"color"> (as per
the C<-storage> indication).

The remaining attributes are simply collected to be passed to the
C<popup_menu()> routine via C<$color->properties> below.  They could be
omitted, and added inline when C<popup_menu()> is called, but it's best
to regroup common things together.

The underlying object created by C<record_field()> will be serialized
and included in the C<CGI::MxScreen> context (only the relevant attributes
are serialized, i.e. C<CGI> parameters such as C<-values> are not).
This will allow the processing engine to honour some meaningful actions,
such as validation, storage, or on-the-fly patching.

Another important property of those objects is that C<CGI::MxScreen> will
update the value attribute, which would be noticeable if there was no
C<-default> line: you could query C<$color->value> to get the current
CGI parameter value, as submitted.

 24     print p("You told me your favorite weekday was", $self->vars->{weekday})
 25         if exists $self->vars->{weekday};
 26 

If we have been in the C<Weekday> screen, then the key C<"weekday"> will
be existing in the global hash C<$self-E<gt>vars>, because it is created by
the C<init()> routine of that object, at line 46.  If we tried to access
the key without protecting by the C<exists> test on line 25, we'd get
a fatal error saying:

    access to unknown key 'weekday'

This protection can be disabled if you want it so, but it is on by default.
It will probably save you one day, but unfortunately this is a runtime check.

 27     print p("Your favorite color is", popup_menu($color->properties));
 28 

The above is generating the sole input of this screen, i.e. a popup
menu so that you can select your favorite color.  Note that we're passing
C<popup_menu()>, which is a routine from the C<CGI> module, a list of
arguments derived from the recorded field C<$color>, created at line 16.

 29     my $ok = $self->record_button(
 30         -name   => "Next",
 31         -target => "Weekday");
 32 

This declaration is also very important.  We're using C<record_button()>
to declare a state transition: we wish to move to the C<Weekday> screen
when the button I<Next> is pressed.

 33     my $redraw = $self->record_button(
 34         -name   => "Redraw",
 35         -target => $self->current_screen);
 36 

The I<Redraw> button simply redisplays the current screen, i.e. there
is no transition to another screen (state).  The I<current_screen>
routine returns the name of the current screen we're in, along with all
the parameters we were called with, so that the transition is indeed towards
the exact same state.

 37     print submit($ok->properties), submit($redraw->properties);
 38 }
 39 

We're finishing the C<display> routine by calling the C<submit()> routine
from the C<CGI> module to generate the submit buttons.  Here again, we're
calling C<properties()> on each button object to expand the CGI parameters,
just like we did for the field on line 27.

 40 package Weekday; use base qw(CGI::MxScreen::Screen);
 41 
 42 use CGI qw/:standard/;
 43 

This defines the second state, C<Weekday>.  It inherits from
C<CGI::MxScreen::Screen>, as it should.  We also import the C<CGI>
functions in that new package.

Note that the name of the class need not be the name of the state.
The association between state name and classes is done during the creation
of the manager object (see lines 78-82).

 44 sub init {
 45     my $self = shift;
 46     $self->vars->{weekday} = "";
 47 }
 48 

Recall that C<init()> is called when the screen is created.  Since screen
objects are made persistent for the duration of the whole session (i.e.
while the user is interacting with the script's forms), that means the
routine is called I<once> for every screen that gets created.

Here, we initialize the C<"weekday"> key, which is necessary because we're
going to use it line 58 below...

 49 sub display {
 50     my $self = shift;
 51     print h1($self->screen_title);
 52 

This is the C<display()> routine for the screen C<Weekday>.  It will be
called by the C<CGI::MxScreen> manager when the selected state is C<"Weekday">
(name determined line 81 below).

 53     print p("You told me your favorite color was", $self->vars->{color});
 54 

We remind them about the color they have chosen in the previous screen.
Note that we don't rely on a hidden parameter to propagate that value:
because it is held in the global persistent hash, it gets part of the
session context and is there for the duration of the session.

 55     my $weekday = $self->record_field(
 56         -name       => "day",
 57         -storage    => "weekday",
 58         -default    => $self->vars->{weekday} || "Mon",
 59         -override   => 1,
 60         -values     => [qw(Mon Tue Wed Thu Fri Sat Sun)],
 61     );
 62 

The declaration of the field used to ask them about their preferred week day.
It looks a lot like the one we did for the color, on lines 16-22, with the
exception that the field name is C<"day"> but the storage in the context
is C<"weekday"> (we used the same string C<"color"> previously).

 63     print p("Your favorite weekday is", popup_menu($weekday->properties));
 64 

The above line generates the popup.  This will create a selection list
whose CGI name is C<"day">.  However, upon reception of that parameter,
C<CGI::MxScreen> will immediately save the value to the location identified
by the C<-storage> line, thereby making the value available to the application
via the C<$self-E<gt>vars> hash.

 65     my $back = $self->record_button(
 66         -name       => "Back",
 67         -target     => $self->spring_screen,
 68     );
 69 

We declare a button named I<Back>, which will bring us back to the screen
we were when we sprang into the current screen.  That's what C<spring_screen>
is about: it refers to the previous stable screen.  Here, since there is
no possibility to remain in the current screen, it will be the previous screen.
But if we had a I<redraw> button like we had in the I<Color> screen, which
would make a transition to the same state, then C<spring_screen> will still
correctly point to C<Color>, whereas C<previous_screen> would be C<Weekday>
in that case.

 70     print submit($back->properties);
 71 }
 72 

This closes the C<display()> routine by generating the sole submit button
for that screen.

 73 package main;
 74 

We now leave the screen definition and enter the main part, where the
C<CGI::MxScreen> manager gets created and invoked.  In real life, the code
for screens would not be inlined but stored in a dedicated file, one file
for each class, and the CGI script would only contain the following code,
plus some additional configuration.

 75 require CGI::MxScreen;
 76 

We're not "using" it, only "requiring" since we're creating an object,
not using any exported routine.

 77 my $manager = CGI::MxScreen->make(
 78     -screens    =>
 79         {
 80             'Color'     => [-class => 'Color',   -title => "Choose Color" ],
 81             'Weekday'   => [-class => 'Weekday', -title => "Choose Day" ],
 82         },
 83     -initial    => ['Color'],
 84 );
 85 

The states of our state machine are described above.  The keys of the
C<-screens> argument are the valid state names, and each state name is
associated with a class, and a screen title.  This screen title will be
available to each screen with C<$self-E<gt>title>, but there's no
obligation for screens to display that information.  However, the manager
needs to know because when the C<display()> routine for the script is called,
the HTML header has already been generated, and that includes the title.

The act of creating the manager object raises some underlying processing:
the session context is retrieved, incoming parameters are processed and
silently validated.

 86 $manager->play();
 87 

This finally launches the state machine: the next state is computed, action
callbacks are fired, and the target screen is displayed.

=head2 More Readings

To learn about the interface of the C<CGI::MxScreen> manager object,
see L<"INTERFACE"> below.

To learn about the screen interface, i.e. what you must implement when you
derive your own objects, what you can redefine, what you should not override
(the other features that you cannot redefine, so to speak), please
read L<CGI::MxScreen::Screen>.

To learn more about the configuration options, see L<CGI::MxScreen::Config>.

For information on the processing done on recorded fields, read
L<CGI::MxScreen::Form::Field> and L<CGI::MxScreen::Form::Utils>.

For information on the state transitions that can be recorded, and the
associated actions, see L<CGI::MxScreen::Form::Button>.

The various session management schemes offered are described in
L<CGI::MxScreen::Session::Medium>.

The layering hooks allowing you to control where the generated HTML for
the current screen goes in your grand formatting scheme are described
in L<CGI::MxScreen::Layout>.

Finally, the extra HTML-generating routines that are not implemented by
the C<CGI> module are presented in L<CGI::MxScreen::HMTL>.

=head1 SPECIFIC DATA TYPES

This sections documents in a central place the I<state> and I<callback>
representations that can be used throughout the C<CGI::MxScreen> framework.

Those specifications must be serializable, therefore all callbacks
are expressed in various symbolic forms, avoiding code references.

Do not forget that I<all> the arguments you specify in callbacks and screens
get serialized into the context.  Therefore, you must make sure your
objects are indeed serializable by the serializer (which is C<Storable>
by default, well, actually C<CGI::MxScreen::Serializer::Storable>, which is
wrapping the C<Storable> interface to something C<CGI::MxScreen> understands).
See L<CGI::MxScreen::Config> to learn how to change the
serializer, and L<CGI::MxScreen::Serializer> for the interface it must
follow.

=head2 States

A state is a screen name plus all the arguments that are given to its
C<display()> routine.  However, the language used throughout this
documentation is not too strict, and we tend to blurr the distinction between
a state and a screen by forgetting about the parameters.  That is because,
in practice, the parameters are simply there to offer a slight variation
of the overall screen dispay, but it is fundamentally the same screen.

Anyway, a state can be either given as:

=over 4

=item *

A plain scalar, in which case it must be the name of a screen, as
configured via C<-screens> (see L<Creation Routine> below), and the
screen's C<display()> routine will be called without any parameter.

=item *

An array ref, whose first item is the screen name, followed by
arguments to be given to C<display()>.  For instance:

	["Color", "blue"]

would represent the state obtained by calling C<display("blue")> on the
screen object known as I<Color>.

=back

=head2 Callbacks

When an argument expects a I<callback>, you may provide it under the
foloowing forms.

=over 4

=item *

As a scalar name, e.g. C<'validate'>.

The exact interpretation of this form depends on the object where you
specify it.  Withing a C<CGI::MxScreen::Form::Button>, it specifies a
routine to call on the screen object, without any user parameter.  However,
within a C<CGI::MxScreen::Form::Field>, it could be a routine to lookup
within the utility namespaces.  More on the latter in L<Utility Path>.

=item *

As a list reference, starting with a scalar name:

	['routine', @args]

This specifies that C<routine(@args)> should be called on the screen object.

=item *

As a list reference, beginning with an object reference:

	[$obj, 'routine', @args]

which specifies that <$obj-E<gt>routine(@args)> should be called, i.e.
the target object is no longer the screen object.
It is available to C<CGI::MxScreen::Form::Button> objects only.

=back

=head1 INTERFACE

The public interface with the manager object is quite limited.
The main entry points are the creation routine, which configures the
overall operating mode, and the C<play()> routine, which launches the
state machine resolution.

=head2 Creation Routine

As usual, the creation routine is called C<make()>.  It takes a list of
named arguments, some of which are optional:

=over 4

=item C<-bgcolor> => I<color>

Optional, sets the default background color to be used for all screens.
If unspecified, the value is I<gray75>, aka C<"#bfbfbf">, which is the
default background in Netscape on Unix.  The value you supply will be
used in the BGCOLOR HTML tag, so any legal value there can be used.
For instance:

    -bgcolor    => "beige"

You may override the default background on a screen basis, as explained
in L<CGI::MxScreen::Screen/"Creation Routine">.

=item C<-initial> => I<scalar> | I<array_ref>

Mandatory, defines the initial state.  See L<States> above for the
actual format details.

The following two forms have identical effects:

    -initial    => ["Color"]
    -initial    => "Color"

and both define a state I<Color> whose C<display()> routine is called
without arguments.

=item C<-layout> => I<layout_object>

Optional, provides a C<CGI::MxScreen::Layout> object to be used for laying
out the screen's HTML generated by C<display()>.  See L<CGI::MxScreen::Layout>
for details.

=item C<-screens> => I<hash_ref>

Mandatory, defines the list of valid states, whose class will handle it, and
what the title of the page should be in that state.  Usually, there is
identity between a screen and a state, but via the C<display()> parameters,
you can have the same screen object used in two different states, with a
slightly different mode of operation.

The hash reference given here is indexed by state names.  The values must
be array references, and their content is the list of arguments to supply
to the screen's creation routine, plus a C<-class> argument defining the
class to use.  See L<CGI::MxScreen::Screen/"Creation Routine">.

Example of I<hash_ref>:

    {
        'Color'     => [-class => 'Color',   -title => "Choose Color" ],
        'Weekday'   => [-class => 'Weekday', -title => "Choose Day" ],
    }

The above sequence defines two states, each implemented by its own class.

=item C<-timeout> => I<seconds>

Optional, defines a session timeout, which will be enforced by C<CGI::MxScreen>
when retrieving the session context.  It must be smaller than the session
cleaning timout, if sessions are not stored within the browser.

When the session is expired, there is an error message stating so and the
user is invited to restart a new session.

=item C<-version> => I<string>

Defines the script's version.  This is I<your> versioning scheme, which has
nothing to do with the one used by C<CGI::MxScreen>.

You should use this to track changes in the screen objects that would
make deserialization of previous ones (from an old session) improper.  For
instance, if you add attributes to your screen objects and depend on them
being set up, an old screen will not bear them, and your application will
fail in mysterious ways.

By upgrading C<-version> each time such an incompatibility is introduced,
you let C<CGI::MxScreen> trap the error and produce an error message.

=back

=head2 Features

=over 4

=item C<internal_error> I<string>

Immediately abort current processing and emit the error message I<string>.
If a layout is defined, it is honoured during the generation of the
error message.

If you buffer STDOUT (which is the case by default), then all the output
currently generated will be discarded cleanly.  Otherwise, users might have
to scroll down to see the error message.

=item C<log>

Gives you access to the C<Log::Agent::Logger> logging object.  There is
always an object, whether or not you enabled logging, if only to redirect
all the logs to C</dev/null>.  This is the same object used by
C<CGI::MxScreen> to do its hardwired logging.

See L<Log::Agent::Logger> to learn what can be done with such objects.

=item C<play>

The entry point that dispatches the state machine handling.  Upon return,
the whole HTML has been generated and sent back to the browser.

=back

=head2 Utility Path

The concept of I<utility path> stems from the need to keep all callback
specification serializable.  Since C<Storable> cannot handle CODE references,
C<CGI::MxScreen> uses function names.  In some cases, we have a default
object to call the method on (e.g. during action callbacks), or one can
specify an object.  In some other case, a plain name must be used, and you
must tell C<CGI::MxScreen> in which packages it should look to find that name.

This is analogous to the PATH search done by the shell.  Unless you specify
an absolute path, the shell looks throughout your defined PATH directories,
stopping at the first match.

Here, we're looking through package namespaces.  For instance, given the
name "is_num", we could check C<main::is_num>, then C<Your::Module::is_num>,
etc...  That's what the utility path is.

The routine C<CGI::MxScreen::add_utils_path> must be used I<before> the
creation of the C<CGI::MxScreen> manager, and takes a list of strings,
which define the package namespaces to look through for field validation
callbacks and patching routines.  The reason it must be done I<before>
is that incoming CGI parameters are currently processed during the
manager's creation routine.

=head1 LOGGING

During its operation, C<CGI::MxScreen> can emit application logs.  The
amount emitted depends on the configuration, as described in
L<CGI::MxScreen::Config>.

Logs are emitted with the session number prefixed, for instance:

    (192.168.0.3-29592) t=0.13s usr=0.12s sys=0.01s [screen computation]

The logged session number is the IP address of the remote machine, and the
PID of the script when the session started.  It remains constant throughout
all the session.

There is also some timestamping and process pre-fixing done by the
underlying logging channel.  See L<Log::Agent::Stamping> for details.
The so-called "own" date stamping format is used by C<CGI::MxScreen>,
and it looks like this:

    01/04/18 12:08:22 script:

showing the date in yy/mm/dd format, and the time in HH::MM::SS format.
The C<script:> part is the process name, here the name of your CGI script.

At the "debug" logging level, you'll get this whole list of logs for
every intial script invocation:

    [main/0] t=0s u="ram" q="id=4"
    using "Mozilla/4.75 [en] (X11; U; Linux 2.4.3-ac4 i686)"
    t=0.20s usr=0.17s sys=0.01s [context restore + log init]
    t=1.15s usr=0.86s sys=0.05s [parameter init]
    t=1.71s usr=0.61s sys=0.07s [outside CGI::MxScreen]
    main()
    t=0.13s usr=0.12s sys=0.01s [screen computation]
    t=46.46s usr=43.42s sys=1.67s ["main" display]
    t=0.30s usr=0.29s sys=0.02s [context save]
    t=50.01s usr=45.53s sys=1.83s [total time] T=52.45s

The C<t=0s> indicates the start of a new session, and C<u="ram"> signals
that the request is made for an HTTP-authenticated user named I<ram>.
The C<[main/0]> indicates that we're in the state called I<main>, and C<0>
is the interaction counter (incremented at each roundtrip).
The C<q="id=4"> traces the query string.

The next line traces the user agent, and is only emitted at the start of
a new session.  May be useful if something goes wrong later on, so that
you can suspect the user's browser.

Then follows a bunch of timing lines, each indicating what was timed
in trailing square brackets.  The final total summs up all the other lines,
and also provides a precious C<T=52.45s> priece of statistics, measuring the
total wallclock time since the script startup.  This helps you evaluate
the overhead of loading the various modules.

The single C<main()> line traces the state information.  Here, since this
is the start of a new session, we enter the initial state and there's no
state transition.

Note the very large time spent by the C<display()> routine for that
screen.  This is because C<Carp::Datum> was on, and there was a lot of
activity to trace.

Compare this to the following log, where the user pressed a button
called I<refresh>, which simply re-displays the same screen, and where
C<Carp::Datum> was turned off:

    [main/1] t=1m11s d=19s u="ram"
    t=0.90s usr=0.83s sys=0.08s [context restore + log init]
    t=0.01s usr=0.00s sys=0.00s [parameter init]
    t=0.02s usr=0.02s sys=0.00s [outside CGI::MxScreen]
    main() -> main() on "refresh" pressed
    t=0.02s usr=0.01s sys=0.00s [screen computation]
    t=0.56s usr=0.58s sys=0.00s ["main" display]
    t=0.05s usr=0.05s sys=0.00s [context save]
    t=1.56s usr=1.50s sys=0.08s [total time] T=3.24s

The new C<d=19s> item on the first line indicates the elapsed time since
the end of the first invocation of the script, and this new one.  It is
the time the user contemplated the screen before pressing a button.

Note that there is no C<q="id=4"> shown: C<CGI::MxScreen> uses POST requests
between its invocations, and does not propagate the initial query string.
It is up to you to save any relevant information into the context.

The following table indicates the logging level used to emit each of the
logging lines outlined above:

   Level    Logging Line Exerpt
   -------  --------------------------------
   warning  [main/1] ...
   info     using "Mozilla/4.75...
   debug    ... [context restore + log init]
   debug    ... [parameter init]
   debug    ... [outside CGI::MxScreen]
   notice   main() -> main() on "refresh"...
   debug    ... [screen computation]
   debug    ... ["main" display]
   debug    ... [context save]
   info     ... [total time] T=3.24s

All timing logs but the last one summarizing the total time are made at
the I<debug> level.  All state transitions (button press, or even bounce
exceptions) are logged at the I<notice> level.  Invocations are logged
at the I<warning> level, in order to trace them more systematically.

=head1 BUGS

There are still some rough edges.  Time will certainly help polishing them.

If you find any bug, please contact both authors with the same message.

=head1 HISTORY AND CREDITS

C<CGI::MxScreen> began when Raphael Manfredi, who knew next to nothing about
CGI programming, stumbled on the wonderful C<MxScreen> program, by
Tom Christiansen, circa 1998.  It was a graphical query compiler for his
I<Magic: The Gathering> database. I confess I learned eveything there was to
learn about by studying this program.  I owed so much to that C<MxScreen>
script that I decided to keep the name in the module.

However, C<MxScreen> was a single application, very well written, but not
reusable without doing massive cut-and-paste, and rather monolithic.
The first C<CGI::MxScreen> version was written by Raphael Manfredi to
modularize the various concepts in late 1998 and early 1999.  It was
never published, and was too procedural.

In late 1999, I introduced my C<CGI::MxScreen> to Christophe Dehaudt.
After studying it for a while, he bought the overall concept, but
proposed to drop the procedural approach and switch to a pure object-oriented
design, to make the framework easier to work with.  I agreed.


The current version of C<CGI::MxScreen> is the result of a joint work
between us.  Christophe did the initial experimenting with the new ideas,
and Raphael consolidated the work, then wrote the whole documentation
and regression test suite.  We discussed the various implementation
decisions together, and although the result is necessarily a compromise,
I (Raphael) believe it is a good compromise.

We managed to use C<CGI::MxScreen> in the industrial development of a
web-based project time tracking system.  The source was well over 20000
lines of pure Perl code (comments and blank lines stripped), and we reused
more than 50000 lines of CPAN code.  I don't think we would have succeeded
without C<CGI::MxScreen>, and without CPAN.

The public release of C<CGI::MxScreen> was delayed more than a year because
the dependencies of the module needed to be released first, and also
we were lacking C<CGI::Test> which was developped only recently.  Without
it, writing the regression test suite of C<CGI::MxScreen> would have been
a real pain, due to its context-sensitive nature.  See L<CGI::Test> if
you're curious.

=head1 AUTHORS

The original authors are
Raphael Manfredi F<E<lt>Raphael_Manfredi@pobox.comE<gt>>
and
Christophe Dehaudt F<E<lt>Christophe.Dehaudt@teamlog.frE<gt>>.

Send bug reports, suggestions, problems or questions to
Jason Purdy F<E<lt>Jason@Purdy.INFOE<gt>>

=head1 SEE ALSO

CGI::MxScreen::Config(3), CGI::MxScreen::Screen(3), CGI::MxScreen::Layout(3).

=cut

