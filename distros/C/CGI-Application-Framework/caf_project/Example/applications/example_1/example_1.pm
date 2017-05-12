package example_1;

use strict;    # always a good idea to include these in your
use warnings;  # modules

# ------------------------------------------------------------------
# You must have this!  Or rather, you must "use base" a module that
# inherets from CGI::Application::Framework and adhers to its
# specifications.
# ------------------------------------------------------------------
use base qw ( Example );
# ------------------------------------------------------------------

# --------------------------------------------------------------
# These are merely being used in the logic below to populate a
# few TMPL_VARs.  Add/subtract modules here as needed in your
# own application.
# --------------------------------------------------------------
use Carp::Heavy;
use Data::Dumper;
use Time::Format qw ( %time );
# --------------------------------------------------------------

sub setup {

    my $self = shift;

    # ----------------------------------------------------------
    # Set up the template parameters
    # ----------------------------------------------------------
    my $config = $self->conf->context;

    # ----------------------------------------------------------
    # Note that "mode_param" and "start_mode", two very basic
    # and essential aspects of CGI::Application programs, are
    # taken care of in a CGI::Application-based superclass of
    # this class.  (Specifically, Framework.pm.)  So,
    # you don't have to worry about it here.  In fact, it is
    # done there so that it can be used and controlled as an
    # integral part of the web MVC framework, and your
    # referring to these things here will probably only screw
    # things up, so don't.
    # ----------------------------------------------------------

    # ----------------------------------------------------------
    # This is a very simple application, with only one run mode.
    # List all run modes here.  While there needed necessarily
    # be a 1:1 correspondance between run modes and subroutine
    # names, it is the easiest way to handle it so that's how I
    # do it.
    # ----------------------------------------------------------
    $self->run_modes(
		     [ qw (
			   main_display
			   )
		       ]
		     );
    # ----------------------------------------------------------
}

sub main_display {

    my $self = shift;

    my $config = $self->conf->context;

    ### ==================================================================
    ### Do what it takes to populate the template variables (a.k.a.
    ### TMPL_VARs) within the composed HTML::Template object
    ### ==================================================================

    my %tmplvars = (); # we'll use this to accumulate tmpl_var values

    # ----------------------------------------------------------------
    # Here's a selection of various things that you can do to populate
    # simple TMPL_VARs.
    # ----------------------------------------------------------------
    $tmplvars{'current_time'}     = $time{'yyyy/mm/dd hh:mm:ss'};
    $tmplvars{'timeout'}          = $config->{'session_timeout'};
    $tmplvars{'self_state_dump'}  = Data::Dumper->Dump([$self], [qw(*self)]);
    $tmplvars{'stack_trace_dump'} = Carp::longmess_heavy
	("Hey hey world I've got something to say... ");
    # ----------------------------------------------------------------

    # ----------------------------------------------------------------
    # Here, note the use of the session within the $self and how to
    # access and modify "session variables" within the composed
    # session object.  The composed session is more or less a
    # scratchpad that you can do what you want to with.  Through the
    # magic of the web MVC framework you don't even have to create it,
    # and it persists across page loads.
    #
    # The first time the programmed referred to
    # $self->session->{count} it created it as well -- this
    # is just good old plain Perl autovivification of complex data
    # structures.
    # ----------------------------------------------------------------
    $tmplvars{'load_count'} = ++$self->session->{count};
    # ----------------------------------------------------------------
    $self->log->info("The Session count is: " . $self->session->{count});

    # ------------------------------------------------------------------
    # Here is a demonstration of the ->make_link method, available
    # through the $self.  The URL it creates references the application
    # itself.  Query string arguments are provided with the "qs_args"
    # reference.  You must provide a "rm" (run mode) argument, which
    # will be the run mode to which the application submits.
    #
    # The make_link method itself will create two more arguments in the
    # query string:  _session_id and _checksum.
    #
    # _session_id is useful if cookies can't be used to provide the
    # session state key.
    #
    # _checksum is an HMAC of the other query string arguments and
    # some secret salt.  If a user tries to alter their query string
    # parameters (for example, typing into the "Location" bar) in
    # their browser then the HMAC of the new query string arguments
    # won't match _checksum, and the web application framework will
    # kill the user's session and provide an error message.
    # ------------------------------------------------------------------
    $tmplvars{'SELF_HREF_LINK'} = $self->make_link
	(
	 qs_args => {
	     rm => 'main_display',
	 }
	 );
    # ------------------------------------------------------------------

    # ----------------------------------------------------------------
    # Here is something a bit different -- we're going to build up
    # an array of values and put a reference to it within %tmplvars
    # so as to populate a TMPL_LOOP variable.  Note that each row in
    # the array is a hashref with key/value pairs, where the keys
    # are TMPL_VARs within the TMPL_LOOP.
    # ----------------------------------------------------------------
    my @random_loop_rows = ();
    foreach my $key ( 1 .. 10 ) {
	my %loopvars       = ();
	$loopvars{'key'}   = $key;
	$loopvars{'value'} = chr($key - 1 + 65) x $key;
	push @random_loop_rows, \%loopvars;
    }
    $tmplvars{'a_random_loop'} = \@random_loop_rows;
    # ----------------------------------------------------------------

    # ----------------------------------------------------------------
    # After we have accumulated all of the TMPL_VAR (and TMPL_LOOP)
    # values within %tmplvars, we use it to populate the composed
    # HTML::Template object within the $self
    # ----------------------------------------------------------------
    # ----------------------------------------------------------------

    ### ==================================================================
    ### /end of populating HTML::Template TMPL_VARs
    ### ==================================================================

    ### ==================================================================
    ### All done -- output the rendered template (including the values of
    ### the TMPL_VARs) and return it as the return value of this sub;
    ### the web MVC framework will look after creating any HTTP headers
    ### and cookies that are needed, as well as returning this output
    ### as the HTML of the web page
    ### ==================================================================
    return $self->template->fill(\%tmplvars);
    ### ==================================================================
}

1; # It's gotta be 1...


