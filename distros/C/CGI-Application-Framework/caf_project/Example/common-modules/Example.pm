package Example;

use warnings;  # only a foolhearty and foolish Perl programmer
use strict;    # doesn't include these in their modules

use Data::Dumper;  # these are useful to have these around for debugging
use Carp;          # purposes, but not 100% necessary

use base 'CGI::Application::Framework';  # This absolutely must remain!

# ======================================================================

# ======================================================================
# These are used according to the needs of the logic given below.
# You'll almost definitely want to create your own Class::DBI subclass
# to handle database interactions, and if you want timeout-based
# logic then Time::HiRes is probably a good one to keep around.
# Other than that, go nuts and use what you need to use.
# ======================================================================
use Time::HiRes;
use CDBI::Example::example;
# ======================================================================


########################################################################
# This merges the values in the config file into the template
# for all of the example programs
########################################################################

sub template_pre_process {
    my $self       = shift;
    my ($template) = @_;

    # Change the internal template parameters by reference
    my $template_params = $template->get_param_hash;

    my $config = $self->conf->context;

    foreach (keys %$config) {
        unless (exists $template_params->{$_}) {
            $template_params->{$_} = $config->{$_};
        }
    }
    return $self->SUPER::template_pre_process(@_);
}

########################################################################
########################################################################
#####
##### The following subroutines are all needed by Framework.pm.
##### Your application will, at some point in time or another, crash
##### if you do not provide the subs such that they do what they're
##### supposed to do.  Probably, the crash will happen very soon
##### indeed.
#####
########################################################################
########################################################################

sub _login_authenticate {

    my $self = shift;

    # ===============================================================
    # Framework.pm expects this subroutine to return a list
    # with 2 values:
    #
    #    1st value -- 0 or 1, 0 being failure to login-authenticate
    #                 a user, 1 being success
    #                     --> 1 means that both the username and
    #                         password matched
    #                     --> 0 means that they didn't
    #
    #    2nd value -- undef, or a $user object
    #                     --> undef means that no such user could
    #                         be found
    #                     --> $user object means that a user with
    #                         the given username was found
    #
    # The combination that these return values create is interpreted
    # by Framework.pm as follows:
    #
    #   (0, undef) --> Unknown user
    #   (0, $user) --> user was found, incorrect password given
    #   (1, $user) --> user was found, password given correct
    #
    #   ** (1, undef) --> not possible!  this will never happen **
    #
    # Note that you are responsible for creating a login.html
    # HTML::Template file (or just plain HTML file I guess
    # but that's a dumb idea) that is on the template search path
    # that will provide something logically equivalent to username
    # and password form fields, that you will use here.  You can
    # name them what you want to here;  Framework.pm makes
    # no assumptions regarding what they should be called.
    #
    # Technically, you don't even need username and password fields.
    # If you can creatively figure out a way to authenticate without
    # these concepts then that's up to you.  Framework.pm
    # doesn't depend on username and password concepts.
    # ===============================================================

    # ---------------------------------------------------------------
    # Note that picking up the query param 'username' comes from a
    # web login attempt.
    # ---------------------------------------------------------------
    my $user     = undef;
    my $username = $self->query->param('username');

    ($user) = CDBI::Example::example::Users->search(
						    username => $username
						    )
	if length($username);

    # ---------------------------------------------------------------

    # Note that, in this example, _password_authenticate_user generates
    # the 2-element list that is finally returned to Framework.pm

    return $self->_password_authenticate_user($user);
}

sub _relogin_authenticate {

    my $self = shift;

    # ===============================================================
    # Framework.pm expects this subroutine to return a list
    # with 2 values:
    #
    #    1st value -- 0 or 1, 0 being failure to login-authenticate
    #                 a user, 1 being success
    #                     --> 1 means that both the username and
    #                         password matched
    #                     --> 0 means that they didn't
    #
    #    2nd value -- undef, or a $user object
    #                     --> undef means that no such user could
    #                         be found
    #                     --> $user object means that a user with
    #                         the given username was found
    #
    # The combination that these return values create is interpreted
    # by Framework.pm as follows:
    #
    #   (0, undef) --> Unknown user
    #   (0, $user) --> user was found, incorrect password given
    #   (1, $user) --> user was found, password given correct
    #
    #   ** (1, undef) --> not possible!  this will never happen **
    #
    # Note that you are responsible for creating a relogin.html
    # HTML::Template file (or just plain HTML file I guess
    # but that's a dumb idea) that is on the template search path
    # that will provide something logically equivalent to a password
    # form field, that you will use here.  You can name them what
    # you want to here;  Framework.pm makes no assumptions
    # regarding what they should be called.
    #
    # Technically, you don't even need a password field. If you can
    # creatively figure out a way to authenticate without these
    # concepts then that's up to you.  Framework.pm doesn't
    # depend on username and password concepts.
    # ===============================================================

    # ---------------------------------------------------------------
    # Since we are reauthenticating from within the application we
    # have the username (and uid) stuck within the session, so we
    # retrieve it from there.
    # ---------------------------------------------------------------
    my $user = undef;
    $user = CDBI::Example::example::Users->retrieve
	(
	 $self->session->{uid}
	 );
    # ---------------------------------------------------------------

    # Note that, in this example, _password_authenticate_user generates
    # the 2-element list that is finally returned to Framework.pm

    return $self->_password_authenticate_user($user);
}

sub _login_profile {

    # --------------------------------------------------
    # This is a Data::FormValidate definition, needed by
    # CGI::Application::Plugin::ValidateRM
    #
    # It is invoked from Framework.pm.  The
    # specifics of this should match the needs of your
    # login.html form-displaying HTML::Template.
    # --------------------------------------------------

    return {
	required => [ qw ( username password ) ],
	msgs     => {
	    any_errors => 'some_errors', # just want to set a true value here
	    prefix     => 'err_',
	},
    };
    # --------------------------------------------------
}

sub _relogin_profile {

    # --------------------------------------------------
    # This is a Data::FormValidate definition, needed by
    # CGI::Application::Plugin::ValidateRM
    #
    # It is invoked from Framework.pm.  The
    # specifics of this should match the needs of your
    # relogin.html form-displaying HTML::Template.
    # --------------------------------------------------

    return {
	required => [ qw ( password ) ],
	msgs     => {
	    any_errors => 'some_errors', # just want to set a true value here
	    prefix     => 'err_',
	},
    };
    # --------------------------------------------------
}

sub _login_failed_errors {

    my $self = shift;

    my $is_login_authenticated = shift;
    my $user = shift;

    # ------------------------------------------------------------------
    # It has already been determined that the user did not successfully
    # log into the application.  So, create some error messages for
    # the HTML template regarding the 'login' mode to display.  This
    # subroutine returns $err which is a hashref to key/value pairs
    # where the key is the name of the HTML::Template TMPL_VAR that
    # should be populated in the event of a certain kind of error, and
    # the value is the error message it should display.
    # Framework.pm provides $is_login_authenticated and $user
    # parameters to this subroutine so that this sub can perform
    # the necessary login checks.  Note that this $user is the some
    # one that is created within the _login_authenticate subroutine,
    # also in this package.  _login_authenticate provides it to
    # Framework.pm, which gives it back here.  Note that
    # $is_login_authenticated should always == 0.  (XXX fixme -- so
    # why even bother giving it to this subroutine?  Note sure...)
    #
    # Note that this isn't the same as that the login form was not
    # well-constructed.  Determining what is and what is not a
    # syntactically valid login form, and the generation of any
    # needed error messages thereof, is handled by the aspect of
    # Framework.pm that calls uses _login_profile, so make
    # sure that whatever you need to do along these lines is reflected
    # there.
    # ------------------------------------------------------------------

    my $errs = undef;

    if ( $user && (!$is_login_authenticated) ) {
	$errs->{'err_password'} = 'Incorrect password for this user';
    } elsif ( ! $user ) {
	$errs->{'err_username'} = 'Unknown user';
    } else {
	die "Can't happen! ";
    }
    $errs->{some_errors} = '1';

    return $errs;
}

sub _relogin_failed_errors {

    my $self = shift;

    my $is_login_authenticated = shift;
    my $user = shift;

    # ------------------------------------------------------------------
    # It has already been determined that the user did not successfully
    # reauthenticate.   So, create some error messages for
    # the HTML template regarding the 'relogin' mode to display.  This
    # subroutine returns $err which is a hashref to key/value pairs
    # where the key is the name of the HTML::Template TMPL_VAR that
    # should be populated in the event of a certain kind of error, and
    # the value is the error message it should display.
    # Framework.pm provides $is_login_authenticated and $user
    # parameters to this subroutine so that this sub can perform
    # the necessary login checks.  Note that this $user is the some
    # one that is created within the _relogin_authenticate subroutine,
    # also in this package.  _relogin_authenticate provides it to
    # Framework.pm, which gives it back here.  Note that
    # $is_login_authenticated should always == 0.  (XXX fixme -- so
    # why even bother giving it to this subroutine?  Note sure...)
    # ------------------------------------------------------------------

    my $errs = undef;

    if ( $user && (!$is_login_authenticated) ) {

	$errs->{err_password}
	= 'Incorrect password for this user';

    } elsif ( ! $user ) {

	$errs->{err_username} = 'Unknown username';

        $self->log_confess("Can't happen! ");
    }
    $errs->{some_errors} = '1';

    return $errs;
}

sub _relogin_test {
    my $self = shift;

    my $config = $self->conf($self->config_name)->context;

    # ------------------------------------------------------------
    # Do whatever you have to do to check to see if a transfer
    # from run mode -to- run mode within an application is good.
    # The return value that Framework.pm expects back
    # should be:
    #
    #      1 - the relogin test has been successfully passed
    #          (implying no relogin authentication check)
    #
    #      0 - the relogin test has been failed
    #          (implying a relogin authentication check is forced)
    #
    # For example, a good candidate is to check for a "timeout".
    # If the user hasn't loaded a page within the application in
    # some duration of time then return 1 -- meaning that a
    # reauthentication isn't necessary.  If a reauthentication is
    # necessary then return 0.
    # ------------------------------------------------------------

    my $now  = &Time::HiRes::time;
    my $then = $self->session->{_timestamp};

    if ( ($now - $then) < $config->{'session_timeout'} ) {

	# -------------------------------------------
	# timeout hasn't happened, so things are good
	# -------------------------------------------
	return 1;
	# -------------------------------------------

    } else {

	# --------------------------------------
	# timeout has happened -- return failure
	# --------------------------------------
	return 0;
	# --------------------------------------

    }
    $self->log_confess("I shouldn't be able to get here ");
}

sub _initialize_session {

    my $self = shift;
    my $user = shift;

    # --------------------------------------------------------------------
    # This code is located in this file because different subclasses of
    # Framework.pm might have different session initialization needs.
    # --------------------------------------------------------------------

    # --------------------------------------------------------------------
    # Note that the Framework.pm superclass also initializes some of
    # its own session parameters, called "_session_id", "_timeout" and
    # "_cgi_query".  As long as you don't screw with (i.e. write to)
    # these session parameters here (or anywhere else in your application)
    # then you'll be okay.  Well, don't delete your session either, again
    # here or anywhere else in your program(s).
    # --------------------------------------------------------------------

    # --------------------------------------------------------------------
    # Set whatever session variables make sense in your application (or
    # really in your collection of applications that use this base class)
    # given that a first-time successful login has just occured.
    # --------------------------------------------------------------------
    $self->session->{user}     = $user;
    $self->session->{uid}      = $user->uid;
    $self->session->{user_id}  = $user->uid;
    $self->session->{username} = $user->username;
    $self->session->{fullname} = $user->fullname;
    # --------------------------------------------------------------------

    # ------------------------------------------------------
    # nothing in particular needed in this return, so may as
    # well provide a true vale
    # ------------------------------------------------------
    return 1;
    # ------------------------------------------------------
}

sub _relogin_tmpl_params {

    my $self = shift;

    # -----------------------------------------------------------------
    # This is used to provide TMPL_VAR parameters to the "relogin"
    # form, as needed by the Framework superclass.  In this case,
    # the logical things to provide to the relogin form are uid and
    # username;  your application logic might differ.  Likely you
    # should keep all of this information the session composed within
    # the $self object, and you probably should have populated the data
    # into the session in the _initialize_session subroutine.
    # -----------------------------------------------------------------

    # --------------------------------------------------------------------
    # The format of the return value of the subroutine should be a list,
    # where each element of the list is a hash-ref, where the keys are the
    # names of TMPL_VARs and the values are what value should be inserted
    # in to that TMPL_VAR
    #
    # E.g. ( { tmpl_var_name_A => 'tmpl_var_value_A' },
    #        { tmpl_var_name_B => 'tmpl_var_value_B' },
    #        { day_of_week     => 'Wednesday' },
    #        { city            => 'Toronto' },
    #        { country         => 'Canada' } )
    # --------------------------------------------------------------------

    my @pairs = ();

    foreach my $key ( qw ( username ) ) {
	push @pairs, { $key => $self->session->{$key} };
    }

    return @pairs;
}

sub _login_tmpl_params {

    my $self = shift;

    # ----------------------------------------------------------------
    # This is used to provide TMPL_VAR parameters to the "login" form,
    # as needed by the Framework superclass.
    #
    # Honestly, there isn't much use for this subroutine, and it's
    # basically a hook in case someone ever has a need for it.
    # ----------------------------------------------------------------

    # --------------------------------------------------------------------
    # In case you do come up with a use for this subroutine, the format of
    # the return value should be a list, where each element of the list is
    # a hash-ref, where the keys are the names of TMPL_VARs and the values
    # are what value should be inserted in to that TMPL_VAR
    #
    # E.g. ( { tmpl_var_name_A => 'tmpl_var_value_A' },
    #        { tmpl_var_name_B => 'tmpl_var_value_B' },
    #        { day_of_week     => 'Wednesday' },
    #        { city            => 'Toronto' },
    #        { country         => 'Canada' } )
    # --------------------------------------------------------------------

    return ();
}

########################################################################
########################################################################
#####
##### The following subroutines do not need to be provided (as named)
##### by Framework.pm.  You can edit these, rename them, etc.
##### as needed.
#####
########################################################################
########################################################################

sub _password_authenticate_user {

    my $self = shift;
    my $user = shift;

    if ( $user ) {

	# ------------------------------------------------------------
	# There was a user with this username or uid found, so now
	# do a password check.  Note that passwords should properly
	# be encrypted within the database and so the password check
	# should be testing some hash algorithm (e.g. Digest::MD5)
	# of the query-string password parameter with the value
	# stored in the database (which was hashed with the same
	# technique at some earlier time)
	#
	# You might want to do a better test on $user to see if it is
	# appropriate for your password check than what is done here.
	# ------------------------------------------------------------

	if ( $self->query->param('password') eq $user->password() ) {

	    return (1, $user); # password check good

	} else {

	    return (0, $user); # password check failed
	}

	# ------------------------------------------------------------

    } else {

	# ----------------------------------------------------------
	# No valid user was provided to this sub, so return an error
	# code (0) and undef, signifying that no user was found
	# ----------------------------------------------------------
	return (0, undef);
	# ----------------------------------------------------------
    }

    $self->log_confess(
	    "I shouldn't be able to get here!\n"
	    . Data::Dumper->Dump([$user],[qw(*user)])
	    . " "
	    );
}

sub make_navbar {
    my $self = shift;

    my %tmplvars = ();

    my $url = $self->query->url(-full=>1);
    $url .= $ENV{'PATH_INFO'} if $ENV{'PATH_INFO'};

    $url =~ s/example_(\d+[a-z]?)/example_1/g;
    $tmplvars{'EXAMPLE_1'} = $self->make_link
	(
	 url => $url,
	 qs_args => {
	     rm => 'main_display',
	 }
	 );

    $url =~ s/example_(\d+[a-z]?)/example_2a/g;
    $tmplvars{'EXAMPLE_2'} = $self->make_link
	(
	 url => $url,
	 qs_args => {
	     rm => 'main_display_mutt',
	 }
	 );

    $url =~ s/example_(\d+[a-z]?)/example_3/g;
    $tmplvars{'EXAMPLE_3'} = $self->make_link
	(
	 url => $url,
	 qs_args => {
	     rm => 'navbar',
	 }
	 );

    $url =~ s/example_(\d+[a-z]?)/example_4/g;
    $tmplvars{'EXAMPLE_4'} = $self->make_link
	(
	 url => $url,
	 qs_args => {
	     rm => 'main_view',
	 }
	 );

    $url =~ s/example_(\d+[a-z]?)/example_5/g;
    $tmplvars{'EXAMPLE_5'} = $self->make_link
	(
	 url => $url,
	 qs_args => {
	     rm => 'show_user_table',
	 }
	 );

    return $self->template->fill(\%tmplvars);

}

1;


