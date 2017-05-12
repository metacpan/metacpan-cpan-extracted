package CGI::Builder::Auth::Example::CBAuthDBI;
use strict;
use lib qw(.);
use CGI::Builder qw/ CGI::Builder::Session CGI::Builder::Auth /;
use DBI;
use DBD::SQLite;

sub OH_init {
	my ($app) = @_;

#Create the database if it doesn't exist.
#Normally you wouldn't need to do this, but I want this test example to work without you having to do anything 
#if you have all the dependencies.
my $dbname = '/tmp/htusers';
if(! -e $dbname) {
my $dbh;
$dbh = DBI->connect("dbi:SQLite:$dbname","","",{AutoCommit=>0,PrintError=>1}) || print "Unable to connect to database\n" if(!$dbh);
$dbh->do("CREATE TABLE users (user_id varchar(12) primary key, password varchar(12))");
$dbh->do("CREATE TABLE groups (user_id varchar(12), group_id varchar(12) primary key)");
$dbh->commit();
$dbh->disconnect();
};
	#
	# If you have special configuration for C::B::Session, do it here
	# before configuring the Auth module
	#
#--------------------------------------------------------------------
# Configure the location of the user database. 
# Set to something reasonable for your system. 
# YOU MUST CREATE THE TABLE YOU WISH TO USE FIRST!! 
# NOTE: /tmp is a BAD place to store your passwd file!
#--------------------------------------------------------------------

	#Gets/adds to a table named "users" with fields "user_id" and "password"
	$app->auth_user_config(DBType=>'SQL'
			       , DRIVER => "SQLite",
			       , DB=>$dbname
			       , USERTABLE  => 'users'
			       , NAMEFIELD  => 'user_id'
			       , PASSWORDFIELD  => 'password'
	);
	#Gets/adds to a table named "groups" with fields "user_id" and "group_id"
	$app->auth_group_config( DBType => 'SQL'
			       , DRIVER => "SQLite"
			       , DB=>$dbname
			       , GROUPTABLE  => 'groups'
			       , NAMEFIELD  => 'user_id'
			       , GROUPFIELD  => 'group_id'
	);

	# The magic_string is used to verify auth tokens loaded from the
	# session, to make sure you are loading the right context.
	$app->auth_config(
		magic_string => 'Something unique for your application!'
	);
}

#--------------------------------------------------------------------
# Switch handlers control access to specific pages
#--------------------------------------------------------------------

# 
# 'protected' page available only to authenticated (logged in) users
#
sub SH_protected {
	my ($app) = @_;
	$app->auth->require_valid_user or return $app->switch_to('login');
}
sub PH_protected {
	my ($app) = @_;
	#
	# Greet the user by name!
	#
	$app->page_content(sprintf('<p>Welcome %s! 
			You can see this page because you are logged in!</p>'
			, $app->auth->user
			)
		);
}

# 
# 'admin' page available only to members of 'administrators' group
#
sub SH_admin {
	my ($app) = @_;
	# Be nice and send visitor to login page if not logged in.
	$app->auth->require_valid_user or return $app->switch_to('login');
	$app->auth->require_group('administrators') 
		or return $app->switch_to('forbidden');
}
sub PH_admin {
	my ($app) = @_;
	$app->page_content(sprintf('<p>Welcome %s! 
			You can see this page because you are an administrator!</p>'
			, $app->auth->user
			)
		);
}


# 
# 'private' page available only to select users
#
sub SH_private {
	my ($app) = @_;
	# Be nice and send visitor to login page if not logged in.
	$app->auth->require_valid_user or return $app->switch_to('login');
	$app->auth->require_user(qw/ bob carol ted alice /) 
		or return $app->switch_to('forbidden');
}
sub PH_private {
	my ($app) = @_;
	$app->page_content(sprintf('<p>Welcome %s! 
			You can see this page because you are on "the list"!</p>'
			, $app->auth->user
			)
		);
}


# 
# New users can be added to the database 
#
sub PH_register {
 	my ($app) = @_;
	my $me = $app->cgi->script_name;
	my $form = "
	<p>Users with 'admin' in their name will be added to the 'administrators' 
	group.</p>
	<form method='POST' action='$me'>
	  <input type='hidden' name='p' value='register'>
	  Username: <input name='username'><br>
	  Password: <input type='password' name='password'><br>
	  <input type='submit'>
	</form>
	";
	if ( $app->cgi->request_method eq 'GET' ) {
		$app->page_content($form);
	} else {
		$app->page_content(
		"<p>Congratulations, you are registered! 
		You must now <a href='$me?p=login'>login</a> with your new account.
		</p>"
		);
	}#END if

}#END sub PH_register

sub SH_register {
 	my ($app,$user) = @_;
	if ($app->cgi->request_method eq 'POST') 
	{ 	$user = $app->auth->add_user(
			# You want to validate or untaint these first!
			{ 	username => $app->cgi->param('username')
			,	password => $app->cgi->param('password')
			}
		) or return $app->switch_to('register_error');

		# Users with "admin" in their names become administrators.
		# You should have stricter checks than this!
		if ( $user =~ /admin/ ) {
			# Ensure the group exists, for this example only.
			$app->auth->add_group('administrators'); 
			$app->auth->add_member('administrators',$user);
		}#END if
	}
}

sub PH_register_error {
	my ($app) = @_;
	$app->page_content("<p>Register Error! 
		The username may already be in use. Go back and try again!</p>");
}

sub PH_index {
 	my ($app) = @_;
	my $me = $app->cgi->script_name;
	my $content = "
	<p>Welcome to the CGI::Builder::Auth example! This page is accessible to
	anyone.  </p> <p>The <a href='$me?p=protected'>Protected</a> page is accessible only to registered users.
	You will be asked to login when you try to access it. Click the <a href='$me?p=register'>Register</a>
	link to create an account.  </p> <p>The <a href='$me?p=admin'>Admin</a> page is accessible only to
	users in the 'administrators' group. To access it, create a user with
	'admin' in the name, for example 'administrator' or 'test_admin_user'.
	</p> <p>The <a href='$me?p=private'>Private</a> page is accessible only to users named bob, carol, ted,
	or alice. Create an account with one of these names to access it.  </p>
	<p>See the source code of this example to find out how to do these things
	in your application. Happy programming!  </p> ";
	$app->page_content($content);
}#END sub PH_index


# 
# Login!
#
sub PH_login {
 	my ($app) = @_;
	my $me = $app->cgi->script_name;
	my $form = "
	<form method='POST' action='$me'>
	  <input type='hidden' name='p' value='login'>
	  Username: <input name='username'><br>
	  Password: <input type='password' name='password'><br>
	  <input type='submit'>
	</form>
	";
	if ( $app->cgi->request_method eq 'GET' ) {
		$app->page_content($form);
	} else {
		$app->page_content(sprintf(
			"<p><a href='%s?p=index'>Congratulations %s, you are logged in!</a></p>",
			$me,
			$app->auth->user
			)
		);
	}#END if

}#END sub PH_login

sub SH_login {
 	my ($app,$user) = @_;
	
	if ($app->cgi->request_method eq 'POST') 
	{ 	$app->auth->login( 
			$app->cgi->param('username'), 
			$app->cgi->param('password')
		) or return $app->switch_to('login_error');
	}
	warn "SH_login passed";
}

sub PH_login_error {
	my ($app) = @_;
	$app->page_content("<p>Login Error! Go back and try again!</p>");
}

sub PH_logout {
	my ($app) = @_;
	$app->auth->logout;
	$app->page_content("<p>You are now logged out.</p>");
}


sub PH_forbidden {
	my ($app) = @_;
	$app->page_content("<p>Go away! We're closed! You are forbidden to enter!</p>");
}


#--------------------------------------------------------------------
# Some generic output routines
#--------------------------------------------------------------------
sub myHeader {
	my ($app,$title) = @_;
	return "<html><head><title>CGI::Builder::Auth Test: $title</title></head><body><h1>$title</h1>\n";
}
sub myFooter {
	my ($app,$title) = @_;
	my $me = $app->cgi->script_name;
	my $content = '<p align="center">';
	my @menu = map { sprintf("<a href='%s?p=%s'>%s</a>\n", $me, $_, ucfirst) }
					qw/ index protected admin private register login logout / ;
	$content .= join " | ", @menu;
	return "$content\n</body></html>\n";
}

sub OH_fixup {
	my ($app) = @_;
	$app->page_content($app->myHeader(uc $app->page_name)
		.$app->page_content
		.$app->myFooter(uc $app->page_name)
	);
}

1;
