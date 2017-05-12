package CGI::Auth::Auto;
use Carp;
use strict;
use base qw(CGI::Auth);
use LEOCHARRE::DEBUG;
use CGI::Scriptpaths;
use vars qw($VERSION);
$VERSION = sprintf "%d.%02d", q$Revision: 1.21 $ =~ /(\d+)/g;

$CGI::Auth::Auto::CGI_APP_COMPATIBLE = 'rm=logout';


sub new {
	my $proto = shift;
   my $class = ref($proto) || $proto;
	my $self = {};
	bless $self, $class;

	my $param = shift;
	$param->{-authfields} ||= [
            {id => 'user', display => 'User Name', hidden => 0, required => 1},
            {id => 'pw', display => 'Password', hidden => 1, required => 1},
        ];      
   
	$param->{-authdir}      ||= _guess_authdir();
   
	$param->{-formaction}   ||= CGI::Scriptpaths::script_rel_path(); #_guess_formaction();
   $param->{-sessdir}      ||= $param->{-authdir}.'/sess';
 
   if (defined $param->{-logintmplpath} or defined $param->{-logintmpl}){
      $param->{-logintmplpath}   ||= $param->{-authdir};
      $param->{-logintmpl}       ||= 'login.html';
   }
   
   if (DEBUG){
      require Data::Dumper;
      printf STDERR __PACKAGE__."::new() params: %s\n", Data::Dumper::Dumper($param);
      #debug(Data::Dumper::Dumper(\%ENV)."\n");
   }
     
   if (!defined $param->{-authdir}){
      carp(__PACKAGE__."::new() missing -authdir param to constructor or setting \$ENV{DOCUMENT_ROOT}");
      return; 
   }
   
	unless( $self->init($param) ){
      warn( sprintf "%s\::init() failed, authdir [%s], userfile expected at:[%s]",__PACKAGE__,$param->{-authdir}, $param->{-authdir}.'/user.dat');
      return undef;
   }

	return $self;
}



sub authdir {
   my $self = shift;
   return $self->{authdir};
}

sub userdat {
   my $self = shift;
   return $self->{userdat};
}

sub sessdir {
   my $self = shift;
   return $self->{sessdir};
}

sub userfile {
   my $self = shift;
   return $self->{userfile};
}


# override check so that we can do cookie thing
sub check {
	my $self = shift;	
	$self->_pre_check;
	$self->SUPER::check; # access overridden method
	$self->_post_check;
   return;
}



# this runs before auth check
# RATIONALE: pre only tries to load an auth string (unless logout is detected)
sub _pre_check {
	my $self = shift;



	# 1) first of all see if a prev sess_file id (filename really) can be gotten from cookie	
	my $sess_file = $self->_get_sess_file_from_cookie 
		or # no sess_file on cooie? no harm done.. just return.
			return; 





	# 2) ok. so the cookie has a sess_file in it...	
	# TODO: had to mess with internals of CGI::Auth ( with $self->{sess_file} ) because that module
	# does not provide for a set() type of method for the sess_file, it does accept as constructor
	# but i'd rather leave the constructor to do what it does, which seems to be to assure that 
	# CGI::Auth finds its support files, user db, template, etc.
	
	$self->{sess_file} = $sess_file; # <- had to mess with CGI::Auth internals here. 
	unless( $self->OpenSessionFile ){ # CGI::Auth::OpenSessionFile() checks with $CGI::Auth::OpenSessionFile::sess_file
		# delete the cookie 
		$self->_ruin_cookie_and_redirect and exit(0);
	}
	
	
	
	
	# 3) cookie was found, sess_file was ok.. now pass it for CGI::Auth::check() to use later.
	### $sess_file
	$self->{cgi}->param( -name=> $self->sfparam_name, -value=> $sess_file );
	
	return 1;
}



sub _ruin_cookie_and_redirect {
	my $self = shift;
	
	print $self->get_cgi->redirect(
		-uri			=> $self->{formaction}, 
		-cookie		=> 
			$self->get_cgi->cookie(
				-name		=> $self->sfparam_name, 
				-value	=> '',
				-expire	=> 'now'
			)
	);

	return 1;
}

sub _set_cookie_and_redirect {
	my $self = shift;
	
	print $self->get_cgi->redirect(
		-uri			=> $self->{formaction}, 
		-cookie		=> 
			$self->get_cgi->cookie(
				-name		=> $self->sfparam_name, 
				-value	=> $self->sfparam_value,
				-expire	=> $self->get_cookie_expire_time
			)
	);

	return 1;
}








# post_check() only runs if user is successfully authenticated.
# its task is 
#	a) to assure a cookie is present.
#  b) check for a logout for this already authenticated user
sub _post_check {
	my $self = shift;

	# 1) assure cookie is here
	unless ( $self->_get_sess_file_from_cookie ) { # if no cookie
		$self->_set_cookie_and_redirect() and exit(0);	
	}

	# 2) detect logout for authenticated user
	# ok. so now we found cookie and sess_file id in it- did the user request a logout???
		
	if ( $self->_requested_logout ) { # check if logout was requested.	
		$self->logout; # logout will exit(0). we dont do it here because logout() method could be called directly.		
	};
	
	return 1;
}






sub logout {
	my $self = shift;

	# delete auth session 
	$self->endsession; 

	# ruin cookie and redirects back here
	$self->_ruin_cookie_and_redirect and exit(0);	
}

# legacy
sub run {
	my $self = shift;
	$self->check;
}




# basic get and set methods. useful..
# these methods dont do anything major like exit or redirect etc

sub get_cgi {
	my $self = shift;
	return $self->{cgi};
}

sub username {
	my $self = shift;
   my ($username, undef) =	$self->OpenSessionFile;
	$username or return;
	return $username;
}


sub start_session {
	my $self = shift;
	return $self->SUPER::start_session; 
}

sub _get_sess_file_from_cookie {
	## _load_cookie()
	my $self = shift;
	my $session_file = $self->get_cgi->cookie($self->sfparam_name);	
	$session_file or return;
	return $session_file;
}

sub _requested_logout {
	my $self= shift;

   # does the query string look like we are trying to log out?


   # for cgi application:
   
   if ($CGI::Auth::Auto::CGI_APP_COMPATIBLE){
      my($param,$runmode) = split(/\=/, $CGI::Auth::Auto::CGI_APP_COMPATIBLE );
      
      if ( defined $self->get_cgi->param($param) and $self->get_cgi->param($param) eq $runmode ){
         debug("detected $CGI::Auth::Auto::CGI_APP_COMPATIBLE\n");
         return 1;
      }
   }

   if ( defined $ENV{QUERY_STRING} ){
      debug("\$ENV{QUERY_STRING} $ENV{QUERY_STRING}\n");
      return 1 if $ENV{QUERY_STRING} eq 'logout';
   }
   
   my $paramname = $self->get_logout_param_name;
   my $paramval = $self->get_cgi->param($self->get_logout_param_name);   
   debug( sprintf " param name: $paramname [$paramval:%s]", ( defined $paramval ? 1 : 0 ));  

   defined $paramval or return 0;
	return 1;
}

sub set_cookie_expire_time {
	my $self= shift;
	my $val = shift; $val or croak("must have valid arg to set_cookie_expire()");
	$self->{cookie_expire_time}= $val;
	return $self->{cookie_expire_time};
}

sub get_cookie_expire_time {
	my $self= shift;
	$self->{cookie_expire_time} ||= '+1h';
	return $self->{cookie_expire_time};
}

sub get_logout_param_name {
	my $self = shift;
	$self->{logout_param_name} ||= 'logout';
	return $self->{logout_param_name};
}

sub set_logout_param_name {
	my $self = shift;
	my $val = shift; $val or croak("must have arg to set_logout_param_name()");
	$self->{logout_param_name} = $val;
	return $self->{logout_param_name};
}





# GUESSING SUBS


sub _guess_authdir {   
   my $dir = __guess_base().'/auth';   
   debug("$dir\n");
   return $dir;
}

sub __guess_base {
   my $cgibin = CGI::Scriptpaths::abs_cgibin();

   unless(defined $cgibin){
      $cgibin = script_abs_loc() or confess("cant get script's absolute location");   
   }
   debug($cgibin);
   return $cgibin;
}

sub _guess_sessdir {
   my $dir = __guess_authdir().'/sess';   
   debug("$dir\n");
   return $dir;
}


1;


__END__

=pod

=head1 NAME

CGI::Auth::Auto - Automatic authentication maintenance and persistence for cgi scrips.

=head1 SYNOPSIS

	my $auth = new CGI::Auth::Auto;
	$auth->check;

	# ok, authenticated, logged in.

   # anything in the script that happens here on is received by an authenticated user

=head1 DESCRIPTION

This is a system to add one line into a cgi script and now.. voila, it requires authrentication
to run the rest of the code.
You don't have to change anything else of what your script is already doing.
It will work with CGI::Application instances as well.

=head2 MOTIVATION

CGI::Auth is a nice module- But I wanted to be able to use it without having to set up a
bunch of parameters to the constructor. This module attempts to make good guesses
about what those parameters should be.

The other thing this module addresses, is having to pass the session id around.
CGI::Auth makes you pass the "session id"- Via query string, in a form, a cookie, etc.

=head2 FEATURES

I wanted to be able to simply drop in a line into any cgi application and have it take 
care of authentication without any further change to the code.

I also wanted to not *have* to pass certain arguments to the constructor. So new() constrcutor
had been overridden to optionally use default params for -authfields -logintmpl -authdir 
and -formaction. 

CGI::Auth::Auto has automatic "sess_file" id passing via a cookie.

This module uses CGI::Auth as base.

This module adds functionality to check() to keep track of the sess_file id for you, and to
detect a user "logout" and do something about it.

You use this exactly as you would use CGI::Auth, only the client *must* accept cookies.
And you no longer have to worry about passing the session id returned from CGI::Auth.
Basically this is like a plugin for any script you have that adds a nice authorization.

Keep in mind you can fully edit the template for the login to make it look like whatever 
you want.

=head1 OVERRIDDEN METHODS

=head2 new()

Exactly like CGI::Auth new(). Added functionality has been added.
Now you have the option to not pass any parameters to new().
Default constructor parameters have been placed for the lazy. 

These are the parameters that if left out to new(), will be set to defaults:
-authfields, -authdir, and -formaction.

Thus if you normally CGI::Auth new() like this:

	my $auth = new CGI::Auth({
		-formaction             => '/cgi-bin/myscript.cgi',	
		-authfields             => [
            {id => 'user', display => 'User Name', hidden => 0, required => 1},
            {id => 'pw', display => 'Password', hidden => 1, required => 1},
        ],
	   -authdir                => /home/myself/cgi-bin/auth",
	});

You can use this module and do this instead:

	my $auth = new CGI::Auth::Auto;

   # the rest is unchanged
	my $auth = new CGI::Auth({
		-formaction             => '/cgi-bin/myscript.cgi',	
		-authfields             => [
            {id => 'user', display => 'User Name', hidden => 0, required => 1},
            {id => 'pw', display => 'Password', hidden => 1, required => 1},
        ],
	   -authdir                => /home/myself/cgi-bin/auth",
	});

Shown are the defaults. You do not need to provide these parameters.


-formaction 
If you do not provide one, the module tries to guess what the rel path to the script is.
 

-authdir
Now a default value of $ENV{DOCUMENT_ROOT} ../cgi-bin/authdir is present.
That means for most hosting accounts if you have this kind of (very common) setup:
/path/to/home/
           |__ public_html/
           |__ cgi-bin/

You should place the support files that come with CGI::Auth as 
/path/to/home/
           |__ public_html/
           |__ cgi-bin/
                   \__ authdir/
                         |__ authman.pl
                         |__ user.dat
                         |__ login.html
                         |__ sess/
                         |__ AuthCfg.pm

Remember you can still tell new() to use whatever you want for these arguments.
This added functionality simply enables you to instance without any arguments.


=head2 check()

Checks for existing authentication in a cookie.
Prompts for authentication (log in).

After a succesful authentication, a cookie is made to keep track of their credential. 
So you don't have to!

Also checks for logout. If so, drops cookie, deletes CGI::Auth session file.

	$auth->check();

See CGI::Auth check() for more. 
Should always be called, BEFORE anything else happens that you are trying to protect.



=head1 ADDED METHODS

All methods available via CGI::Auth are present, additionally:

=head2 set_cookie_expire_time()

Default is +1h 
You can set the cookie expire time before check is called to change this value.

	my $auth = new CGI::Auth::Auto( ... );	
	$auth->set_cookie_expire_time('+15m');
	$auth->check;

Per the above example, if a cookie is made because user logged in, then it will be set to 15 minutes expiry
instead of the default 1 hour.

=head2 get_cookie_expire_time() 

Returns what the expiry was set at. I don't know why you may want this, but
it keeps people from having to check the internals. Returns '+1h' by default. If you 
have used set_cookie_expire() then it would return *that* value.


=head2 set_logout_param_name() and get_logout_param_name()

By default the logout field cgi parameter name is 'logout'. You can change the name this way:

	my $auth = new CGI::Auth::Auto( ... );	
	$auth->set_logout_param_name('elvis_has_left_the_building');
	$auth->check;

That means that http://mysite.com/cgi-bin/myapp.cgi?logout=1 will no longer log an authorized 
user out. But http://mysite.com/cgi-bin/myapp.cgi?elvis_has_left_the_building=1 will work 
instead.


=head2 logout()

Forces logout. Makes cookie expired and blank.
Then redirects to whatever CGI::Auth::Auto formaction was set to.
Then exit(0)s the script. You don't need to use this, likely, but it is here.
It is expected that logout() is called *after* authentication has been deemed true.


=head2 get_cgi()

Returns cgi object used, for re-use.

	my $cgi = $auth->get_cgi;

=head2 username()

Returns name of the user that logged. 
Actually returns field 0 of the sess file. 
Consult CGI::Auth for more on this.
Returns undef if no set.





=head1 LOGGING OUT

This module tries to detect a logout request when you call the medhod check().
If there is a field submitted via a form or url query string (POST or GET) that is called
logout and it holds a true value, it will call method logout().

If your script is in :

   http://mysite.com/cgi-bin/myapp.cgi

There url calls will cause a logout:
   
   http://mysite.com/cgi-bin/myapp.cgi?logout=1
   http://mysite.com/cgi-bin/myapp.cgi?logout=
   http://mysite.com/cgi-bin/myapp.cgi?logout   
   http://mysite.com/cgi-bin/myapp.cgi?rm=logout
   
The last one is for L<CGI::Application Compatibility>

=head2 CGI::Application Compatibility
   
   http://mysite.com/cgi-bin/myapp.cgi?rm=logout

If you want to run  a CGI::Application app, and don't want to bother setting up
the wonderful (but a little complex) CGI::Application::Plugin::Authentication module..
Be aware that then ALL of your runmodes in the cgi app will be protected.

By default, to trigger a logout by CGI::Application, we are looking for 

   rm=logout

In the query string.

What if you want it to be something else? Like runmode=log_me_out ?
Do this:
   
   use CGI::Auth::Auto;
   use MyCGIApp;
   $CGI::Auth::Auto::CGI_APP_COMPATIBLE = 'runmode=log_me_out';
   
   my $auth = new CGI::Auth::Auto;
   $auth->check;

   my $cgiapp = new MyCGIApp;
   $cgiapp->run;   
   
=head2 logout() EXAMPLE

Method logout() forces logout. This calls CGI::Auth method endsession() (see CGI::Auth doc), this sets the 
cookie expiry to 'now', and clears the CGI::Auth session id value from the cookie.
Effectively logging you out.
Keep in mind that logout() calls a CGI.pm redirect and then exits! 
This is to assure nothing else runs after that.

	if ($mycode_has_decided_to_boot_this_user){
		$auth->logout;
	}	

If the user maybe called an bad instruction or submitted funny data, or you detect a possible
intrusion etc.. Then your code should log it, and then call logout() as a last step.

	my $auth = new CGI::Auth::Auto;
	$auth->check;

   # check user input
	

	if( $we_really_dont_like_this_user_input ){

		# ok log it
		# ...
		
		# ok drop this auth and log user out, will exit(0)
		$auth->logout;
	}
	
	# nothing wrong.. continue script..
	# ...


=head1 EXAMPLE SCRIPT

This example script is included in the distribution.
Example assumes you installed CGI::Auth support files in $ENV{DOCUMENT_ROOT}/../cgi-bin/auth

Make this $ENV{DOCUMENT_ROOT}/../cgi-bin/auth.cgi to test it. Don't forget chmod 0755.

	#!/usr/bin/perl -w
	BEGIN { use CGI::Carp qw(fatalsToBrowser); eval qq|use lib '$ENV{DOCUMENT_ROOT}/../lib';|; } # or wherever your lib is 
	use strict;
	use CGI::Auth::Auto;
	use CGI qw(:all);
	
	my $auth = new CGI::Auth::Auto({
		-authdir => "$ENV{DOCUMENT_ROOT}/../cgi-bin/auth"
	}); # the program guesses for authdir, you can leave out if it resides alongside your script
	$auth->check;
	
   my $html =
	 header() .
	 start_html() .
	 h1("hello ".$auth->username) .
	 p('You are logged in now.') .
	 p('Would you like to log out? <a href="'.$ENV{SCRIPT_NAME}.'?logout=1">logout</a>');	
	
   print $html;

	exit;


Parameter -authdir is where you have the CGI::Auth support files. You need the user.dat file there, etc.
See CGI::Auth for more.

In the example user.dat provided, username:default password:

=head1 BUGS

Please report bugs via email to author.

=head1 CHANGES

A previous temptation was to add CGI::Session automation in addition to the cookie system. 
This way, by simply using this module, you will have authentication and state maintained
for you. I consider this now out of scope here. after simply running check() you could safely
run CGI::Session::new() without fear of creating multiple sessions. Since check() already 
decided by that point that the user is truly authenticated.

A custom login.html template has been included in this distribution under cgi-bin/auth/login.html.
This template is minimal as compares to the candy one that comes with CGI::Auth. 

=head1 DEBUG

To turn on debug info, in your cgi script, before you call check() :

   $CGI::Auth::Auto::DEBUG = 1;

=head1 ERRORS

The most common error is that you are not passing the right authdir to the object.

The authdir needs to exist and contain a user.dat simple text file.
If you do not provide an authdir argument, that's ok, we try to guess for it.
If your script is in /home/myself/cgi-bin/script.pl , then your auth dir is guessed as
/home/myself/cgi-bin/auth
And it must exist and contain the user.dat file. This can be a blank text file to begin with.
Make sure it is chown and chmod properly.

If your cgi is failing, turn on L<DEBUG> and run it again. A lot of useful information may be there.

=head2  Auth::check - Invalid 'User Name' field at ...

Erase your user.dat and recreate.

=head1 users.dat

This file must reside inside your auth dir.
If you script is in cgi-bin/script.cgi,
you must have a cgi-bin/auth/sess dir and a cgi-bin/auth/users.dat file
an example file is included in this distribution
please read CGI::Auth for more info on managing that file.

=head1 login.html

If you define the 'logintmpl' or 'logintmplpath' arguments to constructor, the program
tries to find login.html template or dies.
If not, it uses a barebones hard coded output.

So, again, if you have a cgi-bin/auth/login.html template:

   my $auth = new CGI::Auth::Auto({ -logintmpl => 'login.html' });

If not:

   my $auth = new CGI::Auth::Auto;

If you do but it resides elsewhere:

   my $auth = new CGI::Auth::Auto({ -logintmplpath => '/home/myself/public_html/templates' });


=head1 SEE ALSO

CGI::Auth, CGI::Cookie, HTML::Template

=head1 CONTRIBUTIONS

Dulaunoy Fabrice

=head1 AUTHOR

Leo Charre leocharre at cpan dot org

=cut



