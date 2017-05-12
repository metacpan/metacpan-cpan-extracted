package CGI::Framework;

# $Header: /cvsroot/CGI::Framework/lib/CGI/Framework.pm,v 1.130 2005/10/11 16:21:24 mina Exp $

use strict;
use HTML::Template;
use CGI::Session qw/-api3/;
use CGI;
use CGI::Carp qw(fatalsToBrowser set_message);
use Fcntl ':flock';

BEGIN {
	use Exporter ();
	use vars qw ($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $LASTINSTANCE);
	$VERSION     = "0.23";
	@ISA         = qw (Exporter);
	@EXPORT      = qw ();
	@EXPORT_OK   = qw (add_error assert_form assert_session clear_session dispatch form get_cgi_object get_cgi_session_object html html_push html_unshift initial_template initialize_cgi_framework log_this remember session show_template return_template);
	%EXPORT_TAGS = ('nooop' => [@EXPORT_OK],);
}

=head1 NAME

CGI::Framework - A simple-to-use, lightweight web CGI framework

It is primarily a glue between HTML::Template, CGI::Session, CGI, Locale::Maketext and some magic :)

=head1 SYNOPSIS

  use CGI::Framework;
  use vars qw($f);
  
  #
  # Setup the initial framework instance
  #
  $f = new CGI::Framework (
	  sessions_dir		=>	"/tmp",
	  templates_dir		=>	"/home/stuff/myproject/templates",
	  initial_template	=>	"enterusername",
  )
  || die "Failed to create a new CGI::Framework instance: $@\n";

  #
  # Get the instance to "do it's magic", including handling the verification of the
  # just-submitting form, preparing the data for the upcoming template to be sent, and any cleanup
  #
  $f->dispatch();

  #
  # This sub is automatically called after the "enterusername" template is submitted by the client
  #
  sub validate_enterusername {
	  my $f = shift;
	  if (!$f->form("username")) {
		  $f->add_error("You must enter a username");
	  }
	  elsif (!$f->form("password")) {
		  $f->add_error("You must enter your password");
	  }
	  else {
		  if ($f->form("username") eq "mina" && $f->form("password") eq "verysecret") {
			  $f->session("username", "mina");
			  $f->session("authenticated", "1");
		  }
		  else {
			  $f->add_error("Authentication failed");
		  }
	  }
  }

  #
  # This sub is automatically called before the "mainmenu" template is sent
  #
  sub pre_mainmenu {
	  my $f = shift;
	  $f->assert_session("authenticated");
	  $f->html("somevariable", "somevalue");
	  $f->html("name", $f->session("username"));
  }

  #
  # This sub is automatically called after the "logout" template is sent
  #
  sub post_logout {
	  my $f = shift;
	  $f->clear_session();
  }

=head1 DESCRIPTION

CGI::Framework is a simple and lightweight framework for building web-based CGI applications.  It features complete code-content separation (templating) by utilizing the HTML::Template library, stateful file or database-based sessions by utilizing the CGI::Session library, form parsing by utilizing the CGI library, (optional) multi-lingual templates support, and an extremely easy to use methodology for the validation, pre-preparation and post-cleanup associated with each template.  It also provides easy logging mechanisms, graceful fatal error handling, including special templates and emails to admins.

=head1 CONCEPTUAL OVERVIEW

Before we jump into the technical details, let's skim over the top-level philosophy for a web application:

=over 4

=item *

The client sends an initial GET request to the web server

=item *

The CGI recognizes that this is a new client, creates a new session, sends the session ID to the client in the form of a cookie, followed by sending a pre-defined initial template

=item *

The user interacts with the template, filling out any form elements, then re-submits the form back to the CGI

=item *

The CGI reloads the session based on the client cookie, validates the form elements the client is submitting.  If any errors are found, the client is re-sent the previous template along with error messages.  If no errors were found, the form values are either acted on, or stored into the session instance for later use.  The client is then sent the next template.

=item *

The flow of templates can either be linear, where there's a straight progression from template 1 to template 2 to template 3 (such as a simple ordering form) or can be non-linear, where the template shown will be based on one of many buttons a client clicks on (such as a main-menu always visible in all the templates)

=item *

Sessions should automatically expire if not loaded in X amount of time to prevent unauthorized use.

=back

=head1 IMPLEMENTATION OVERVIEW

Implementing this module usually consists of:

=over 4

=item *

Writing the stub code as per the SYNOPSIS.  This entails creating a new CGI::Framework instance, then calling the dispatch() method.

=item *

Creating your templates in the templates_dir supplied earlier.  Templates should have the .html extension and can contain any templating variables, loops, and conditions described in the L<HTML::Template> documentation.

=item *

For each template created, you can optionally write none, some or all of the needed perl subroutines to interact with it.  The possible subroutines that, if existed, will be called automatically by the dispatch() method are:

=over 4

=item validate_templatename()

This sub will be called after a user submits the form from template templatename.  In this sub you should use the assert_session() and assert_form() methods to make sure you have a sane environment populated with the variables you're expecting.

After that, you should inspect the supplied input from the form in that template.  If any errors are found, use the add_error() method to record your objections.  If no errors are found, you may use the session() or remember() methods to save the form variables into the session for later utilization.

=item pre_templatename()

This sub will be called right before the template templatename is sent to the browser.  It's job is to call the html() method, giving it any dynamic variables that will be interpolated by L<HTML::Template> inside the template content.

=item post_templatename()

This sub will be called right after the template templatename has been sent to the browser and right before the CGI finishes.  It's job is to do any clean-up necessary after displaying that template.  For example, on a final-logout template, this sub could call the clear_session() method to delete any sensitive information.

=back

There are also 4 special sub names you can create:

=over 4

=item pre__pre__all()

This sub will be called before any template is sent (and before pre_templatename() is called).  It is rarely needed to write or use such a sub.

=item post__pre__all()

This sub will be called before any template is sent (and after pre_templatename() is called).  It is rarely needed to write or use such a sub.

=item pre__post__all()

This sub will be called after any template is sent (and before post_templatename() is called).  It is rarely needed to write or use such a sub.

=item post__post__all()

This sub will be called after any template is sent (and after post_templatename() is called).  It is rarely needed to write or use such a sub.

=back

If any of the above subroutines are found and called, they will be passed 2 arguments: The CGI::Framework instance itself, and the name of the template about to be/just sent.

=back

=head1 STARTING A NEW PROJECT

If you're impatient, skip to the STARTING A NEW PROJECT FOR THE IMPATIENT section below, however it is recommended you at least skim-over this detailed section, especially if you've never used this module before.

The following steps should be taken to start a new project:

=over 4

=item SETUP DIRECTORY STRUCTURE

This is the recommended directory structure for a new project:

=over 4

=item F<cgi-bin/>

This is where your CGI that use()es CGI::Framework will be placed.  CGIs placed there will be very simple, initializing a new CGI::Framework instance and calling the dispatch() method.  The CGIs should also add F<lib/> to their 'use libs' path, then require pre_post and validate.

=item F<lib/>

This directory will contain 2 important files require()ed by the CGIs, F<pre_post.pm> and F<validate.pm>.  F<pre_post.pm> should contain all pre_templatename() and post_templatename() routines, while F<validate.pm> should contain all validate_templatename() routines.  This seperation is not technically necessary, but is recommended.  This directory will also possibly contain F<localization.pm> which will be a base sub-class of L<Locale::Maketext> if you decide to make your errors added via add_error() localized to the use's language (refer to the "INTERNATIONALIZATION AND LOCALIZATION" section).  This directory will also hold any custom .pm files you write for your project.

=item F<templates/>

This directory will contain all the templates you create.  Templates should end in the .html extension to be found by the show_template() or return_template() methods.  More on how you should create the actual templates in the CREATE TEMPLATES section

=item F<sessions/>

If you decide to use file-based sessions storage (the default), this directory will be the holder for all the session files.  It's permissions should allow the user that the web server runs as (typically "nobody") to write to it.

The other alternative is for you to use MySQL-based sessions storage, in which case you won't need to create this directory, but instead initialize the database.  More info about this in the CONSTRUCTOR/INITIALIZER documentation section.

=item F<public_html/>

This directory should contain any static files that your templates reference, such as images, style sheets, static html links, multimedia content, etc...

=back

=item CONFIGURE YOUR WEB SERVER

How to do this is beyond this document due to the different web servers out there, but in summary, you want to create a new virtual host, alias the document root to the above F<public_html/> directory, alias /cgi-bin/ to the above F<cgi-bin/> directory and make sure the server will execute instead of serve files there, and in theory you're done.

=item CREATE TEMPLATES

You will need to create a template for each step you want your user to see.  Templates are regular HTML pages with the following additions:

=over 4

=item CGI::Framework required tags

The CGI::Framework absolutely requires you insert these tags into the templates.  No ands, iffs or butts about it.  The framework will NOT work if you do not place these tags in your template:

=over 4

=item <cgi_framework_header>

Place this tag right under the <body> tag

=item <TMPL_INCLUDE NAME="errors.html">

Place this tag wherever you want errors added with the add_error() method to appear

=item <cgi_framework_footer>

Place this tag right before the </body> tag

=back

It is recommended that you utilize HTML::Template's powerful <TMPL_INCLUDE> tag to create base templates that are included at the top and bottom of every template (similar to Server-Side Includes, SSIs).  This has the benefit of allowing you to change the layout of your entire site by modifying only 2 files, as well as allows you to insert the above 3 required tags into the shared header and footer templates instead of having to put them inside every content template.

=item HTML::Template tags

All tags mentioned in the documentation of the HTML::Template module may be used in the templates.  This allows dynamic variable substitutions, conditionals, loops, and a lot more.

To use a variable in the template (IFs, LOOPs, etc..) , it must either:

=over 4

=item *

Have just been added using the html() method, probably in the pre_templatename() routine.

=item *

Has just been submitted from the previous template

=item *

Has been added in the past to the session using the session() method.

=item *

Has been added automatically for you by CGI::Framework. Refer to the "PRE-DEFINED TEMPLATE VARIABLES" section.

=back

=item CGI::Framework language tags

If you supplied a "valid_languages" arrayref to the new() constructor of CGI::Framework, you can use any of the languages in that arrayref as simple HTML tags.  Refer to the "INTERNATIONALIZATION AND LOCALIZATION" section.

=item The process() javascript function

This javascript function will become available to all your templates and will be sent to the client along with the templates.  Your templates should call this function whenever the user has clicked on something that indicates they'd like to move on to the next template.  For example, if your templates offer a main menu at the top with 7 options, each one of these options should cause a call to this process() javascript function.  Every next, previous, logout, etc.. button should cause a call to this function.

This javascript function accepts the following parameters:

=over 4

=item templatename

B<MANDATORY>

This first parameter is the name of the template to show.  For example, if the user clicked on an option called "show my account info" that should load the accountinfo.html template, the javascript code could look like this:

	<a href="#" onclick="return process('accountinfo');">Show my account info</a>

or

	<input type="button" value=" LIST MY ACCOUNT BALANCES &gt;&gt; " onclick="return process('accountbalances');">

=item item

B<OPTIONAL>

If this second parameter is supplied to the process() call, it's value will be available back in your perl code as key "_item" through the form() method.

This is typically used to distinguish between similar choices.  For example, if you're building a GUI that allows the user to change the password of any of their accounts, you could have something similar to this:

	bob@domain.com   <input type="button" value="CHANGE PASSWORD" onclick="return process('changepassword', 'bob@domain.com');">
	<br>
	mary@domain.com  <input type="button" value="CHANGE PASSWORD" onclick="return process('changepassword', 'mary@domain.com');">
	<br>
	john@domain.com  <input type="button" value="CHANGE PASSWORD" onclick="return process('changepassword', 'john@domain.com');">

=item skipvalidation

B<OPTIONAL>

If this third parameter is supplied to the process() call with a true value such as '1', it will cause CGI::Framework to send the requested template without first calling validate_templatename() on the previous template and forcing the correction of errors.

=back

=back

=over 4

=item The errors template

It is mandatory to create a special template named F<errors.html>.  This template will be included in all the served pages, and it's job is to re-iterate over all the errors added with the add_error() method and display them.  A simple F<errors.html> template looks like this:

=over 4

=item F<errors.html> sample:

	<TMPL_IF NAME="_errors">
		<font color=red><b>The following ERRORS have occurred:</b></font>
		<blockquote>
			<TMPL_LOOP NAME="_errors">
				* <TMPL_VAR NAME="error"><br>
			</TMPL_LOOP>
		</blockquote>
		<font color=red>Please correct below and try again.</font>
		<p>
	</TMPL_IF>

=back

=item The missing info template

It is recommended, although not mandatory, to create a special template named F<missinginfo.html>.  This template will be shown to the client when an assertion made through the assert_form() or assert_session() methods fail.  It's job is to explain to the client that they're probably using a timed-out session or submitting templates out of logical order (possibly a cracking attempt), and invites them to start from the beginning.

If this template is not found, the above error will be displayed to the client in a text mode.

When this template is called due to a failed assertion by assert_form() or assert_session(), 2 special variables: _missing_info and _missing_info_caller, are available for use in the missinginfo template.  Refer to the "PRE-DEFINED TEMPLATE VARIABLES" section for details.

=item The fatal error template

It is recommended, although not mandatory, to create a special template called F<fatalerror.html> and specify that name as the fatal_error_template constructor key.  Usually when a fatal error occurs it will be caught by L<CGI::Carp> and a trace will be shown to the browser.  This is often technical and is always an eyesore since it does not match your site design.  If you'd like to avoid that and show a professional apologetic message when a fatal error occurs, make use of this fatal error template feature.

See the "PRE-DEFINED TEMPLATE VARIABLES" section below for an elaboration on the fatal error template and the special variable _fatal_error that you could use in it.

=back

=item ASSOCIATE THE CODE WITH THE TEMPLATES

For each template you created, you might need to write a pre_templatename() sub, a post_templatename() sub and a validate_templatename() sub as described earlier.  None of these subs are mandatory.

For clarity and consistency purposes, the pre_templatename() and post_templatename() subs should go into the F<pre_post.pm> file, and the validate_templatename() subs should go into the F<validate.pm> file.

There are also 4 special sub names.  pre__pre__all(), post__pre__all(), pre__post__all() and post__post__all().  If you create these subs, they will be called before pre_templatename(), after pre_templatename(), before post_templatename() and after post_templatename() respectively for all templates.

=item WRITE YOUR CGI

Copying the SYNOPSIS into a new CGI file in the F<cgi-bin/> directory is usually all that's needed unless you have some advanced requirements such as making sure the user is authenticated first before allowing them access to certain templates.

=item TEST, FINE TUNE, ETC . . .

Every developer does this part, right :) ?

=back

=head1 STARTING A NEW PROJECT FOR THE IMPATIENT

=over 4

=item *

Install this module

=item *

Run: perl -MCGI::Framework -e 'CGI::Framework::INITIALIZENEWPROJECT "F</path/to/your/project/base>"'

=item *

cd F</path/to/your/project/base>

Customize the stubs that were created there for you.  Refer back to the not-so-impatient section above for clarifications of anything you see there.

=back

=head1 OBJECT-ORIENTED VS. FUNCTION MODES

This module allows you to use an object-oriented or a function-based approach when using it.  The only drawback to using the function-based mode is that there's a tiny bit of overhead during startup, and that you can only have one instance of the object active within the interpreter (which is not really a logical problem since that is never a desirable thing. It's strictly a technical limitation).

=over 4

=item THE OBJECT-ORIENTED WAY

As the examples show, this is the object-way of doing things:

	use CGI::Framework;

	my $instance = new CGI::Framework (
		this	=>	that,
		foo	=>	bar,
	);

	$instance->dispatch();

	sub validate_templatename {
		my $instance = shift;
		if (!$instance->form("country")) {
			$instance->add_error("You must select a country");
		}
		else {
			$instance->remember("country");
		}
	}

	sub pre_templatename {
		my $instance = shift;
		$instance->html("country", [qw(CA US BR)]);
	}

=item THE FUNCTION-BASED WAY

The function-based way is very similar (and slightly less cumbersome to use due to less typing) than the OO way. The differences are: You have to use the ":nooop" tag in the use() line to signify that you want the methods exported to your namespace, as well as use the initialize_cgi_framework() method to initialize the instance instead of the new() method in OO mode.  An example of the function-based way of doing things:

	use CGI::Framework ':nooop';

	initialize_cgi_framework (
		this	=>	that,
		foo	=>	bar,
	);

	dispatch();

	sub validate_templatename {
		if (!form("country")) {
			add_error("You must select a country");
		}
		else {
			remember("country");
		}
	}

	sub pre_templatename {
		html("country", [qw(CA US BR)]);
	}

=back

=head1 THE CONSTRUCTOR / INITIALIZER

=over 4

=item new(%hash)

This is the standard object-oriented constructor.  When called, will return a new CGI::Framework instance.  It accepts a hash (or a hashref) with the following keys:

=over 4

=item action

B<OPTIONAL>

If this key is supplied, it should contain the value to be used in the <form> HTML element's "action" parameter.  If not supplied, it will default to environment variable SCRIPT_NAME

=item callbacks_namespace

B<OPTIONAL>

This key should have a scalar value with the name of the namespace that you will put all the validate_templatename(), pre_templatename(), post_templatename(), pre__pre__all(), post__pre__all(), pre__post__all() and post__post__all() subroutines in.  If not supplied, it will default to the caller's namespace.  Finally if the caller's namespace cannot be determined, it will default to "main".

The main use of this option is to allow you, if you so choose, to place your callbacks subs into any arbitrary namespace you decide on (to avoid pollution of your main namespace for example).

=item cookie_domain
   
B<OPTIONAL>
	   
The key should have a scalar value with the domain that cookie_name is set to.  If not supplied the cookie will not be assigned to a specific domain, essentially making tied to the current hostname.

=item cookie_name

B<OPTIONAL>

This key should have a scalar value with the name of the cookie to use when communicating the session ID to the client.  If not supplied, will default to "sessionid_" and a simplified representation of the URL.

=item disable_back_button

B<OPTIONAL>

This key should have a scalar value that's true (such as 1) or false (such as 0).  Setting it to true will instruct the framework not to allow the user to use their browser's back button.  This is done by setting no-cache pragmas on every page served, setting a past expiry date, as well as detecting submissions from previously-served templates and re-showing the last template sent.

This behaviour is often desired in time-sensitive web applications.

=item expire

B<OPTIONAL>

Set this to a value that will be passed to CGI::Session's expire() method.  If supplied and contains non-digits (such as "+2h") it will be passed verbatim.  If supplied and is digits only, it will be passed as minutes.  If not supplied will default to "+15m"

=item fatal_error_email

B<OPTIONAL>

If you would like to receive an email when a fatal error occurs, supply this key with a value of either a scalar email address, or an arrayref of multiple email addresses.  You will also need to supply the smtp_host key and/or the sendmail key.

=item fatal_error_template

B<OPTIONAL>

Normally fatal errors (caused by a die() anywhere in the program) are captured by CGI::Carp and sent to the browser along with the web server's error log file.  If this key is supplied, it's value should be a template name.  That template would then be showed instead of the normal CGI::Carp error message.  When the template is called, the special template variable _fatal_error will be set.  This will allow you to optionally show or not show it by including it in the template content.

=item initial_template

B<MANDATORY>

This key should have a scalar value with the name of the first template that will be shown to the client when the dispatch() method is called.  It can be changed after initialization with the initial_template() method before the dispatch() method is called.

=item import_form

B<OPTIONAL>

This variable should have a scalar value with the name of a namespace in it.   It imports all the values of the just-submitted form into the specified namespace.  For example:

	import_form	=>	"FORM",

You can then use form elements like:

	$error = "Sorry $FORM::firstname, you may not $FORM::action at this time.";

It provides a more flexible alternative to using the form() method since it can be interpolated inside double-quoted strings, however costs more memory.  I am also unsure about how such a namespace would be handled under mod_perl and if it'll remain persistent or not, possibly causing "variable-bleeding" problems across sessions.

=item log_filename

B<OPTIONAL>

This variable should have a scalar value with a fully-qualified filename in it.  It will be used by the log_this() method as the filename to log messages to.  If supplied, make sure that it is writeable by the user your web server software runs as.

=item maketext_class_name

B<OPTIONAL>

If you wish to localize errors you add via the add_error() method, this key should contain the name of the class you created as the L<Locale::Maketext> localization class, such as for example "MyProject::L10N" or "MyProjectLocalization".   Refer to the "INTERNATIONALIZATION AND LOCALIZATION" section.  You must also set the "valid_languages" key if you wish to set this key.

=item output_filter

B<OPTIONAL>

If you would like to do any manual hacking to the content just before it's sent to the browser, this key should contain the name of a sub (or a reference to a sub) that you'd like to have the framework call.  The sub will be passed 2 argumets: The CGI::Framework instance itself, and a reference to a scalar containing the content about to be sent.

=item sendmail

B<OPTIONAL>

If you supplied the fatal_error_email key, you must also supply this key and/or the smtp_host key.  If you'd like to deliver the mail using sendmail, supply this key with a value of the fully qualified path to your sendmail binary.

=item sessions_dir

B<OPTIONAL>

This key should have a scalar value holding a directory name where the session files will be stored.  If not supplied, a suitable temporary directory will be picked from the system.

Note: You may not supply this if you supply the sessions_mysql_dbh key.

=item sessions_mysql_dbh

B<OPTIONAL>

This key should have a value that's a MySQL DBH (DataBase Handle) instance created with the DBI and DBD::Mysql modules.  If supplied then the session data will be stored in the mysql table instead of text files.  For more information on how to prepare the database, refer to the L<CGI::Session::MySQL> documentation.

Note: You may not supply this if you supply the sessions_dir key.

=item sessions_serializer_default

B<OPTIONAL>

This key should be set to true if you wish to use the default serialization method for your sessions.  This requires the perl module Data::Dumper.  For more information refer to the L<CGI::Session::Serialize::Default> documentation.

Note: You may not supply this if you supply the sessions_serializer_storable or sessions_serializer_freezethaw keys.

=item sessions_serializer_freezethaw

B<OPTIONAL>

This key should be set to true if you wish to use the FreezeThaw serialization method for your sessions.  This requires the perl module FreezeThaw.  For more information refer to the L<CGI::Session::Serialize::FreezeThaw> documentation.

Note: You may not supply this if you supply the sessions_serializer_default or sessions_serializer_storable keys.

=item sessions_serializer_storable

B<OPTIONAL>

This key should be set to true if you wish to use the Storable serialization method for your sessions.  This requires the perl module Storable.  For more information refer to the L<CGI::Session::Serialize::Storable> documentation.

Note: You may not supply this if you supply the sessions_serializer_default or sessions_serializer_freezethaw keys.

=item smtp_from

B<OPTIONAL>

If your mail server supplied in smtp_host is picky about the "from" address it accepts emails from, set this key to a scalar email address value.  If not set, the email address 'cgiframework@localhost' will be set as the from-address.

=item smtp_host

B<OPTIONAL>

If you supplied the fatal_error_email key, you must also supply this key and/or the sendmail key.  If you'd like to deliver the mail using direct SMTP transactions (and have Net::SMTP installed), supply this key with a value of the hostname of the mailserver to connect to.

If your mailserver is picky about the "from" address it accepts mail from, you should also supply the smtp_from key when using this key, otherwise 'cgiframework@localhost' will be supplied as the from address.

=item templates_dir

B<OPTIONAL>

This key should have a scalar value holding a directory name which contains all the template files.  If not supplied, it will be guessed based on the local directory.

=item valid_languages

B<OPTIONAL>

This key should have an arrayref value.  The array should contain all the possible language tags you've used in the templates.  Refer to the "INTERNATIONALIZATION AND LOCALIZATION" section.  You must set this key if you wish to also set the "maketext_class_name" key.

=back

=item initialize_cgi_framework(%hash)

Just like the above new() constructor, except used in the function-based approach instead of the object-oriented approach.

=back

=head1 METHODS / FUNCTIONS

=over 4

=item add_error($scalar [, @array ] )

This method accepts a scalar error and adds it to the list of errors that will be shown to the client.  It should only be called from a validate_templatename() subroutine for each error found during validating the form.  This will cause the dispatch() method to re-display the previous template along with all the errors added.

If you specified the "valid_languages" and the "maketext_class_name" keys to the initializer, the error message you give to this method will be localized to the user's preferred language (or the default language) before being showed to the user.  Refer to the "INTERNATIONALIZATION AND LOCALIZATION" section.  If this is the case, you may specify extra arguments after the main $scalar, and they will be passed verbatim to L<Locale::Maketext>'s maketext() method - this is often used to localize variables within a sentence.

=item assert_form(@array)

This method accepts an array of scalar values.  Each element will be checked to make sure that it has been submitted in the just-submitted form and has a true value.  If any elements aren't found or have a false value, the missinginfo template is shown to the client.  The missinginfo template will be passed special variables _missing_info and _missing_info_caller which you can use to display details about the failed assertions.  Refer to the "PRE-DEFINED TEMPLATE VARIABLES" section for more info.

=item assert_session(@array)

Just like the assert_form() method, except it checks the values against the session instead of the submitted form.

=item clear_session

This method deletes all the previously-stored values using the session() or remember() methods.

=item dispatch

This method is the central dispatcher.  It calls validate_templatename on the just-submitted template, checks to see if any errors were added with the add_error() method.  If any errors were added, re-sends the client the previous template, otherwise sends the client the template they requested.

=item finalize

This method undefs some internal references that prevent the object from being destroyed.  It's called automatically for you when show_template() is done or if there's a fatal error, so there is usually no need to call it manually.

This method exit()s when done - it does not return.

=item form($scalar)

This method accepts an optional scalar as it's first argument, and returns the value associated with that key from the just-submitted form from the client.  If no scalar is supplied, returns all entries from the just-submitted form.

=item get_cgi_object

Returns the underlying CGI object.  To be used if you'd like to do anything fancy this module doesn't provide methods for, such as processing extra cookies, etc...

=item get_cgi_session_object

Returns the underlying CGI::Session object.  To be used if you'd like to do anything fancy this module doesn't provide methods for.

=item html($scalar, $scalar)

This method accepts a scalar key as it's first argument and a scalar value as it's second.  It associates the key with the value in the upcoming template.  This method is typically called inside a pre_template() subroutine to prepare some dynamic variables/loops/etc in the templatename template.

=item html_push($scalar, $scalar)

Very similar to the above html() method, except it treats the key's value as an arrayref (creates it as an arrayref if it didn't exist), and push()es the value into that array.  This method is typically used to append to a key that will be used in a template loop with HTML::Template's <TMPL_LOOP> tag, the value in which case is normally a hashref.

=item html_unshift($scalar, $scalar)

Very similar to the above html_push() method, except it unshift()s instead of push()es the value.

=item log_this($scalar)

This method accepts a scalar message and logs it to the filename specified in the log_filename parameter in the new constructor.  You can not use this method if you have not supplied a log_filename setting to the constructor.

=item remember($scalar [, $scalar])

This method accepts a mandatory scalar source key name as it's first argument and an optional scalar destination key name as it's second argument .  It then treats that source scalar as a key in the just-submitted form, and saves that key-value pair into the session.  This method is simply shorthand for saying:

	$instance->session($sourcekeyname, $instance->form($sourcekeyname));

If the second optional parameter is supplied, then that destination key is used in the session.  This allows the key saved in the session to have a different name than the one submitted in the form.  In that case, this method becomes a shorthand for:

	$instance->session($destinationekeyname, $instance->form($sourcekeyname));

It is frequently used to premanently save a submitted form key+value inside the validate_templatename() sub after it has been checked for correctness.

=item return_template($scalar)

This method accepts a scalar template name, and returns the content parsed from that template suitable for sending to the client.  Internally it takes care of language substitution, and the <cgi_framework_header>, <cgi_framework_footer> tags.

In scalar context it returns the content suitable for sending to the client.  In array context it returns the content and the content-type.

=item session($scalar [, $scalar])

This method accepts a scalar key as it's first argument and an optional scalar value as it's second.  If a value is supplied, it saves the key+value pair into the session for future retrieval.  If no value is supplied, it returns the previously-saved value associated with the given key.

=item show_template($scalar [, $nofinalize])

This method accepts a scalar template name, calls the pre__pre__all() sub if found, calls the pre_templatename() sub if found, calls the post__pre__all() sub if found, sends the template to the client, calls the pre__post__all() sub if found, calls the post_templatename() sub if found, calls the post__post__all() sub if found, then exits.  Internally uses the return_template() method to calculate actual content to send.

Note: This method calls finalize() when done unless $nofinalize is set to true.  You probably never want to do this, in which case the call to finalize() will cause this method to never return.

=back

=head1 PRE-DEFINED TEMPLATE VARIABLES

Aside from variables added through the html() method, the submitted form and the current session, these pre-defined variables will be automatically set for you to use in your templates:

=over 4

=item _current_template

This variable will contain the name of the current template

=item _fatal_error

This variable will contain the error message that caused a fatal error.  It will only be available when a fatal error occurs and the fatal error template specified by the fatal_error_template constructor argument is being shown.

=item _form_action

This variable will contain the URL to the current CGI

=item _missing_info

This variable will only be available when the missinginfo template is being called from a call to assert_form() or assert_session() methods.  It's value will be an arrayref of hashes.  Each hash will have a key named "name", the value of which is the name of a key supplied to assert_form() or assert_session() that failed the assertion.  This variable can be used with L<HTML::Template>'s TMPL_LOOP macro to display the variables that failed the assertion.

=item _missing_info_caller

This variable will only be available when the missinginfo template is being called from a call to assert_form() or assert_session() methods.  It's value will be a scalar describing the caller of assert_form() or assert_method().

=back

=head1 INTERNATIONALIZATION (i18n) AND LOCALIZATION (l10n)

One of this module's strengths is simplifying support for multi-(human)languages.  When the user is presented lingual pieces using this module, it has usually originated from either:

=over 4

=item *

Content inside one of the templates

=item *

Errors added via the add_error() method

=back

Multi-language support is initiated by you by supplying the "valid_languages" arrayref to the CGI::Framework constructor.  This arrayref should contain a list of language tags you wish to support in your application.  These tags are not necessarily the exact same tags as the ISO-specified official language tag, and as a matter of fact it is recommended that you use tags that are as short as possible for reasons that will be apparent below.

As an example, if you intend to support English and French in your application, supplying this to the constructor would indicate that:

	"valid_languages"	=>	['en', 'fr'],

When the module sends output to the user, it will try to send the "appropriate" language localization.

B<What is the "appropriate" language localization to send ?>

The module uses a fairly simple logic to determine which is the language localization to send:

=over 4

=item The session variable "_lang"

If the session variable "_lang" is set, it will be used as the user's desired localization.

You can either populate this variable manually in your code, such as by:

	session("_lang", "en");

Or more conveniently, let CGI::Framework handle that job for you by having the templates set a form element named "_lang".  This allows you to add to a top-header template a "Switch to English" button that sets the form element "_lang" to "en", and a "Switch to French" button that sets the form element "_lang" to "fr".

When CGI::Framework is processing the submitted form and notices that the form element "_lang" is set, it will update the session's "_lang" correspondingly, hence setting that user's language.

=item The default language

If the session variable "_lang" is not set as described above, the default language that will be used is the first language tag listed in the "valid_languages" arrayref.

=back

Finally, this is how to actually define your multi-lingual content:

=over 4

=item Localizing content inside the templates

This is where pleasantness begins.  The language tags you defined in the "valid_languages" constructor key can be used as HTML tags inside the templates!  CGI::Framework will take care of parsing and presenting the correct language and illiminating the others.  An example in a bilingual template:

	<en>Good morning!</en>
	<fr>Bonjour!</fr>

=item Localizing errors added via the add_error() method

By default, errors you add via the add_error() method will not be localized and will be passed straight-through to the errors template and shown as-is to the end user.

To enable localization for the errors, you will need to, aside from supplying the "valid_languages" key, also supply the "maketext_class_name" key to the constructor.  This should be the name of a class that you created.  CGI::Framework will take care of use()ing that class.  For example:

	"maketext_class_name"	=>	"MyProjectLocalization",

Exactly what should be in that class ?  This is where I direct you to read L<Locale::Maketext>.  This class is your project's base localization class.  For the impatient, skip down in L<Locale::Maketext>'s POD to the "HOW TO USE MAKETEXT" section.  Follow it step by step except the part about replacing all your print() statements with print maketext() - this is irrelevant in our scenario.

After you do the above, your calls to the add_error() method will be automatically localized, using L<Locale::Maketext> and your custom localization class.  In our example here, you would end up with:

=over 4

=item *

A file in your F<lib/> folder named F<MyProjectLocalization.pm>

=item *

Inside that file, you should have created the following packages:

=over 4

=item *

	package MyProjectLocalization;

=item *

	package MyProjectLocalization::en;

=item *

	package MyProjectLocalization::fr;

=back

=back

=back

=head1 BUGS

I do not (knowingly) release buggy software.  If this is the latest release, it's probably bug-free as far as I know.  If you do find a problem, please contact me and let me know.

=head1 AUTHOR

	Mina Naguib
	CPAN ID: MNAGUIB
	mnaguib@cpan.org
	http://mina.naguib.ca

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

Copyright (C) 2003-2005 Mina Naguib.


=head1 SEE ALSO

L<HTML::Template>, L<CGI::Session>, L<CGI::Session::MySQL>, L<CGI>, L<Locale::Maketext>, L<CGI::Carp>.

=cut

#
# Takes a scalar
# Adds it to the errors que
#
sub add_error {
	my $self            = _getself(\@_);
	my $error           = shift || croak "Error not supplied";
	my @parameters      = @_;
	my $existing_errors = $self->{_html}->{_errors} || [];
	$error = $self->localize($error, @parameters);
	push(@$existing_errors, { error => $error, });
	$self->{_html}->{_errors} = $existing_errors;
	return 1;
}

#
# This sub asserts that the key(s) supplied to it exists in the submitted form
# If the value is not true, it calls show_template with "missinginfo"
# It's mostly used by the subs in pre_post* to validate that the values they need exist
#
sub assert_form {
	my $self = _getself(\@_);
	my @failed = grep { !$self->form($_) } @_;
	if (@failed) {
		foreach (@failed) {
			$self->html_push("_missing_info", { "name" => $_, });
		}
		$self->html("_missing_info_caller", join(" -- ", caller));
		$self->_missinginfo();
	}
	else {
		return 1;
	}
}

#
# This sub asserts that the key(s) supplied to it exists in the session
# If the value is not true, it calls show_template with "missinginfo"
# It's mostly used by the subs in pre_post* to validate that the values they need exist
#
sub assert_session {
	my $self = _getself(\@_);
	my @failed = grep { !$self->session($_) } @_;
	if (@failed) {
		foreach (@failed) {
			$self->html_push("_missing_info", { "name" => $_, });
		}
		$self->html("_missing_info_caller", join(" -- ", caller));
		$self->_missinginfo();
	}
	else {
		return 1;
	}
}

#
# Clears the session
#
sub clear_session {
	my $self     = _getself(\@_);
	my %preserve = (
		"_lastsent" => "",
		"_lang"     => "",
	);

	#
	# Save preserve-able values
	#
	foreach (keys %preserve) {
		$preserve{$_} = $self->session($_);
	}

	#
	# Delete all values
	#
	$self->{_session}->clear();

	#
	# Restore preserved values
	#
	foreach (keys %preserve) {
		$self->session($_, $preserve{$_});
	}

	return 1;
}

#
# This sub takes care of calling any validate_XYZ methods, displaying old page or requested page
# based on whether there were errors or not
#
sub dispatch {
	my $self = _getself(\@_);
	my $validate_template;

	no strict 'refs';

	#
	# Validate the data entered:
	#
	if ($self->form("_sv")) {

		#We skip validation as per requested
	}
	else {
		if ($self->form("_template") && !$self->session("_lastsent")) {

			#
			# They are submitting a page but we don't have a lastsent template in session - they probably timed out
			#
			$self->_missinginfo();
		}

		if ($self->{disable_back_button} && $self->session("_lastsent")) {

			#
			# If disable_back_button is set, we always validate last template we sent them
			#
			$validate_template = $self->session("_lastsent");
		}
		elsif ($self->form("_template")) {

			#
			# Otherwise we validate the template they're submitting
			#
			$validate_template = $self->form("_template");
		}

		#
		# We implement validation if possible
		#
		if ($validate_template && defined &{"$self->{callbacks_namespace}::validate_$validate_template"}) {
			&{"$self->{callbacks_namespace}::validate_$validate_template"}($self);
			if ($self->{_html}->{_errors}) {

				#
				# The validation didn't go so well and errors were recorded
				# so we re-show the template the failed validation
				#
				$self->show_template($validate_template);
			}
		}
	}

	#
	# If we reached here, we're all good and present the action they requested
	#
	$self->show_template($self->form("_action") || $self->{initial_template});

	# Should not reach here
	die "Something's wrong.  You should not be seeing this.\n";
}

#
# Cleans up internal references to allow for destruction THEN EXITS
#
sub finalize {
	undef $LASTINSTANCE;
	set_message(undef);
	exit;
}

#
# Takes a scalar key
# Returns the value for that key from the just-submitted form
#
sub form {
	my $self = _getself(\@_);
	my $key  = shift;
	my $value;

	no strict 'refs';

	if (length($key)) {
		return $self->{_import_form} ? ${ $self->{_import_form} . '::' . $key } : $self->{_cgi}->param($key);
	}
	else {
		return $self->{_cgi}->param();
	}
}

#
# Returns the CGI object
#
sub get_cgi_object {
	my $self = _getself(\@_);
	return $self->{_cgi};
}

#
# Returns the CGI::Session object
#
sub get_cgi_session_object {
	my $self = _getself(\@_);
	return $self->{_session};
}

#
# Takes a scalar key and a scalar value
# Adds them to the html que
#
sub html {
	my $self  = _getself(\@_);
	my $key   = shift || croak "key not supplied";
	my $value = shift;
	$self->{_html}->{$key} = $value;
	return 1;
}

#
# Takes a scalar key and a scalar value
# Pushes the value into the html element as an array
#
sub html_push {
	my $self           = _getself(\@_);
	my $key            = shift || croak "key not supplied";
	my $value          = shift;
	my $existing_value = $self->{_html}->{$key} || [];
	if (ref($existing_value) ne "ARRAY") {
		croak "Key $key already exists as non-array. Cannot push into it.";
	}
	push(@{$existing_value}, $value);
	$self->{_html}->{$key} = $existing_value;
	return 1;
}

#
# Takes a scalar key and a scalar value
# Unshifts the value into the html element as an array
#
sub html_unshift {
	my $self           = _getself(\@_);
	my $key            = shift || croak "key not supplied";
	my $value          = shift;
	my $existing_value = $self->{_html}->{$key} || [];
	if (ref($existing_value) ne "ARRAY") {
		croak "Key $key already exists as non-array. Cannot unshift into it.";
	}
	unshift(@{$existing_value}, $value);
	$self->{_html}->{$key} = $existing_value;
	return 1;
}

#
# Re-sets initial_template
#
sub initial_template {
	my $self = _getself(\@_);
	my $initial_template = shift || croak "initial template not supplied";
	$self->{initial_template} = $initial_template;
}

#
# An alias to new(), to be used in nooop mode
#
sub initialize_cgi_framework {
	my %para = ref($_[0]) eq "HASH" ? %{ $_[0] } : @_;
	$para{callbacks_namespace} ||= (caller)[0] || "main";
	return new("CGI::Framework", \%para);
}

#
# The constructor.  Initializes pretty much everything, returns a new bless()ed instance
#
sub new {
	my $class = shift || "CGI::Framework";
	my %para = ref($_[0]) eq "HASH" ? %{ $_[0] } : @_;
	my $self = {};
	my $cookie_value;
	my $temp;
	my $expire;
	my $sessions_driver;
	my $sessions_serializer;
	local (*FH);

	$self = bless($self, ref($class) || $class);

	#
	# Paranoia: It should be clear anyways... but
	#
	if ($LASTINSTANCE) {
		$LASTINSTANCE->finalize();
	}

	#
	# Backwards compatability support
	#
	foreach (qw(callbacks_namespace cookie_name import_form initial_template sessions_dir templates_dir valid_languages)) {
		$temp = $_;
		$temp =~ s/_//g;
		if (!exists $para{$_} && exists $para{$temp}) {
			$para{$_} = $para{$temp};
			delete $para{$temp};
		}
	}

	#
	# Custom fatal error handling
	#
	$para{fatal_error_email} && !$para{smtp_host} && !$para{sendmail} && croak "You must supply smtp_host and/or sendmail when supplying fatal_error_email";
	if ($para{"fatal_error_template"} || $para{"fatal_error_email"}) {
		set_message(
			sub {
				my $error     = shift;
				my $emailsent = 0;
				my $errorsent = 0;
				my $index;
				my @callerparts;
				my @stack;
				local (*SMH);

				#
				# Hold your horses - some errors should just be ignored
				#
				if (exists $ENV{"HTTPS"} && $ENV{"HTTPS"} && $error =~ /^((103:)?Software caused connection abort)|((104:)?Connection reset by peer)/i) {

					#
					# This is generated by some braindead web browsers that do not properly terminate an SSL session
					#
					$self->finalize();
					return ();
				}

				#
				# Append stack to error message:
				#
				for ($index = 0 ; @callerparts = caller($index) ; $index++) {
					push(@stack, "$callerparts[1]:$callerparts[2] ($callerparts[3])");
				}
				@stack = reverse @stack;
				$error .= "\n\nStack trace appended by CGI::Framework fatal error handler:\n";
				foreach (0 .. $#stack) {
					$error .= "    " x ($_ + 1);
					$error .= $stack[$_];
					$error .= "\n";
				}

				#
				# Show something back to the web user regarding the error
				# We do this first BEFORE sending off emails because under mod_perl, an open() to a pipe (sendmail) sends some
				# crap to the browser - FIXME - NEEDS INVESTIGATING
				#
				if ($para{"fatal_error_template"}) {
					eval {
						$self->{_html}->{_fatal_error} = $error;
						$self->show_template($para{"fatal_error_template"}, 1);
					};
					if (!$@) {
						$errorsent = 1;
					}
					elsif ($@ =~ /mod_?perl/i && $@ =~ /exit/i) {

						#
						# Under mod_perl, an exit() (deep in finalize()) called inside an eval (above) gets thrown and therefore caught above
						# so we treat it as success
						#
						$errorsent = 1;
					}
				}
				if (!$errorsent) {
					print "Content-type: text/html\n\n<h1>The following fatal error occurred:</h1><p><pre>$error</pre>\n";
				}

				#
				# Now try to send the fatal error email
				#
				if (!$emailsent && $para{"fatal_error_email"} && $para{"sendmail"}) {
					eval {
						open(SMH, "| $para{sendmail} -t -i") || die "Failed to open pipe to sendmail: $!\n";
						print SMH "From: " . ($para{"smtp_from"} || 'cgiframework@localhost') . "\n";
						print SMH "To: ", (ref($para{"fatal_error_email"}) eq "ARRAY" ? join(",", @{ $para{"fatal_error_email"} }) : $para{"fatal_error_email"}), "\n";
						print SMH "Subject: Fatal Error\n";
						print SMH "X-CGI-Framework-Method: sendmail $para{sendmail}\n";
						print SMH "X-CGI-Framework-REMOTE-ADDR: $ENV{REMOTE_ADDR}\n";
						print SMH "X-CGI-Framework-PID: $$\n";
						print SMH "\n";
						print SMH "The following fatal error occurred:\n\n$error\n";
						close(SMH);
					};
					$emailsent = 1 if !$@;
				}
				if (!$emailsent && $para{"fatal_error_email"} && $para{"smtp_host"}) {
					eval {
						require Net::SMTP;
						my $smtp = Net::SMTP->new($para{"smtp_host"}) || die "Could not create Net::SMTP object: $@\n";
						$smtp->mail($para{"smtp_from"} || 'cgiframework@localhost') || die "Could not send MAIL command: $@\n";
						$smtp->recipient(ref($para{"fatal_error_email"}) eq "ARRAY" ? @{ $para{"fatal_error_email"} } : $para{"fatal_error_email"}) || die "Could not send RECIPIENT command: $@\n";
						$smtp->data("X-CGI-Framework-Method: Net::SMTP $para{smtp_host}\nX-CGI-Framework-REMOTE-ADDR: $ENV{REMOTE_ADDR}\nX-CGI-Framework-PID: $$\n\nThe following fatal error occurred:\n\n$error") || die "Could not send DATA command: $@\n";
						$smtp->quit();
					};
					$emailsent = 1 if !$@;
				}

				#
				# Finally cleanup cruft:
				#
				$self->finalize();
			}
		);
	}

	#
	# Some initial setup
	#
	$para{_html} = {};

	#
	# We set some defaults if unsupplied
	#
	$para{valid_languages} ||= [];
	$para{callbacks_namespace} ||= (caller)[0] || "main";
	if (!$para{cookie_name}) {
		$para{cookie_name} = "sessionid_$ENV{SCRIPT_NAME}";
		$para{cookie_name} =~ s/[^0-9a-z]//gi;
	}
	if (!$para{sessions_mysql_dbh} && !$para{sessions_dir}) {

		#
		# They didn't supply any sessions stuff, so let's take a guess at some directories for file-based storage:
		#
		foreach (qw(/tmp /var/tmp c:/tmp c:/temp c:/windows/temp)) {
			if (-d $_) {
				$para{sessions_dir} = $_;
				last;
			}
		}
	}
	if (!$para{templates_dir}) {
		foreach (qw(./templates ../templates)) {
			if (-d $_) {
				$para{templates_dir} = $_;
				last;
			}
		}
	}
	if (!$para{sessions_serializer_default} && !$para{sessions_serializer_storable} && !$para{sessions_serializer_freezethaw}) {
		$para{sessions_serializer_default} = 1;
	}

	#
	# Now we do sanity checking
	#
	ref $para{valid_languages} eq "ARRAY" || croak "valid_languages must be an array ref";
	if ($para{"maketext_class_name"}) {
		@{ $para{valid_languages} } || croak "valid_languages must be set to at least one language to specify the maketext_class_name key";
	}
	$para{sessions_dir} && $para{sessions_mysql_dbh} && croak "Only one of sessions_dir and sessions_mysql_dbh may be supplied";
	if ($para{sessions_dir}) {

		#
		# Supplied (or determined) file-based sessions storage
		#
		-e $para{sessions_dir} && !-d $para{sessions_dir} && croak "$para{sessions_dir} exists but is not a directory";
		-d $para{sessions_dir} || mkdir($para{sessions_dir}, 0700) || croak "Failed to create $para{sessions_dir}: $!";
		-w $para{sessions_dir} || croak "$para{sessions_dir} is not writable by me";
	}
	elsif ($para{sessions_mysql_dbh}) {

		#
		# Supplied mysql-based sessions storage
		# Should be a reference to mysql object - but I'll just make sure it's *a* reference to something
		#
		ref($para{sessions_mysql_dbh}) || croak "Invalid sessions_mysql_dbh supplied";
	}
	else {
		croak "Neither sessions_dir or sessions_mysql_dbh were supplied, and could not automatically determine a suitable sessions_dir";
	}
	if ((grep { $para{$_} } qw(sessions_serializer_default sessions_serializer_storable sessions_serializer_freezethaw)) > 1) {
		croak "Only one of sessions_serializer_default, sessions_serializer_storable and sessions_serializer_freezethaw may be supplied";
	}
	$para{templates_dir}                  || croak "templates_dir must be supplied";
	-d $para{templates_dir}               || croak "$para{templates_dir} does not exist or is not a directory";
	-f "$para{templates_dir}/errors.html" || croak "Templates directory $para{templates_dir} does not contain the mandatory errors.html template";
	$para{initial_template}               || croak "initial_template not supplied";
	if ($para{log_filename}) {
		open(FH, ">>$para{log_filename}") || croak "Log filename $para{log_filename} is not writeable by me: $@";
		close(FH);
	}
	if ($para{output_filter}) {
		if (ref($para{output_filter}) eq "CODE") {

			#
			# It's a code ref - good
			#
		}
		elsif (defined &{"$self->{callbacks_namespace}::$para{output_filter}"}) {

			#
			# It's a sub name that exists. good
			#
			$para{output_filter} = &{"$self->{callbacks_namespace}::$para{output_filter}"};
		}
		else {
			croak "Output filter not a code ref and not a sub name that I can find";
		}
	}

	#
	# And now some initialization
	#
	$self->{action}              = $para{action};
	$self->{valid_languages}     = $para{valid_languages};
	$self->{templates_dir}       = $para{templates_dir};
	$self->{initial_template}    = $para{initial_template};
	$self->{callbacks_namespace} = $para{callbacks_namespace};
	$self->{log_filename}        = $para{log_filename};
	$self->{disable_back_button} = $para{disable_back_button};
	$self->{output_filter}       = $para{output_filter};
	$self->{_cgi}                = new CGI || die "Failed to create a new CGI instance: $! $@\n";
	$cookie_value = $self->{_cgi}->cookie($para{cookie_name}) || undef;

	if ($para{"maketext_class_name"}) {
		undef $@;
		eval { eval("require $para{'maketext_class_name'};") || die "Failed to require() $para{'maketext_class_name'}: $! $@"; };
		if ($@) {
			croak "Could not properly initialize maketext_class_name ($para{'maketext_class_name'}): $@";
		}
		else {
			$self->{maketext_class_name} = $para{"maketext_class_name"};
		}
	}

	#
	# Initialize session object
	#
	if ($para{sessions_dir}) {
		$sessions_driver = "File";
	}
	else {
		$sessions_driver = "MySQL";
	}
	if ($para{sessions_serializer_storable}) {
		$sessions_serializer = "Storable";
	}
	elsif ($para{sessions_serializer_freezethaw}) {
		$sessions_serializer = "FreezeThaw";
	}
	else {
		$sessions_serializer = "Default";
	}
	$self->{_session} = new CGI::Session(
		"driver:$sessions_driver;serializer:$sessions_serializer",
		$cookie_value,
		{
			Handle    => $para{sessions_mysql_dbh},
			Directory => $para{sessions_dir},
		}
	  )
	  || die "Failed to create new CGI::Session instance with $sessions_driver - based storage and $sessions_serializer - based serialization: $! $@\n";

	if ($para{"import_form"}) {
		$self->{_cgi}->import_names($para{"import_form"});
		$self->{_import_form} = $para{"import_form"};
	}

	if (!$cookie_value || ($self->{_session}->id() ne $cookie_value)) {

		# We just created a new session - send it to the user
		print "Set-Cookie: $para{cookie_name}=", $self->{_session}->id(), ($para{cookie_domain} ? "; domain=" . $para{cookie_domain} : ""), "\n";
	}
	$expire = $para{"expire"} ? ($para{"expire"} =~ /[^0-9]/ ? $para{"expire"} : "+$para{expire}m") : "+15m";
	$self->{_session}->expire($expire);

	#
	# Language handling
	#
	if ($self->{_cgi}->param("_lang") && scalar @{ $self->{valid_languages} }) {
		if (grep { $self->{_cgi}->param("_lang") eq $_ } @{ $self->{valid_languages} }) {

			#
			# Override session language
			#
			$self->{_session}->param("_lang", scalar $self->{_cgi}->param("_lang"));
		}
		else {
			print "Content-type: text/plain\n\n";
			print "Unsupported language\n";
			$self->finalize();
		}
	}
	elsif (scalar @{ $self->{valid_languages} } && !$self->{_session}->param("_lang")) {

		# Set default language
		$self->{_session}->param("_lang", $self->{valid_languages}->[0]);
	}

	#
	# We're done initializing !
	#
	$LASTINSTANCE = $self;
	return ($self);
}

#
# Takes a scalar key
# Copies that key from the form to the session
#
sub remember {
	my $self           = _getself(\@_);
	my $sourcekey      = shift || croak "key not supplied";
	my $destinationkey = shift || $sourcekey;
	$self->session($destinationkey, $self->form($sourcekey));
}

#
# Takes a template name
# returns scalar output string containing parsed template, with lang and tags substitution
# In array mode also returns a second element which is the content-type
#
sub return_template {
	my $self = _getself(\@_);
	my $template_name = shift || croak "Template name not supplied";
	my $template;
	my $content_type;
	my $filename;
	my $output;
	my ($key, $value);
	my $temp;
	my $header;
	my $footer;
	my $action;

	no strict 'refs';

	#
	# Prepare template
	#
	($filename, $content_type) = $self->_get_template_details($template_name);
	croak "Could not find template $template_name" if !$filename;

	$template = HTML::Template->new(
		filename          => $filename,
		path              => [ $self->{templates_dir} ],
		associate         => [ $self->{_session}, $self->{_cgi} ],
		die_on_bad_params => 0,
		loop_context_vars => 1,
	  )
	  || die "Error creating HTML::Template instance: $! $@\n";
	$template->param($self->{_html});
	$template->param(
		{
			_form_action      => $ENV{SCRIPT_NAME},
			_formaction       => $ENV{SCRIPT_NAME},
			_current_template => $template_name,
		}
	);
	$output = $template->output();

	#
	# Implement language substitutions:
	#
	foreach (@{ $self->{valid_languages} }) {
		if ($self->session("_lang") eq $_) {
			$output =~ s#<$_>(.*?)</$_>#$1#gsi;
		}
		else {
			$output =~ s#<$_>(.*?)</$_>##gsi;
		}
	}

	if ($content_type eq "application/x-netscape-autoconfigure-dialer") {

		#
		# We're sending a netscape INS file. It needs to be formatted to binary first
		#
		($output) = ($output =~ /\[netscape\]\s*\n((?:.*=.*\n)+)/i);
		$temp = "";
		foreach ("STATUS=OK", split /\n/, $output) {
			($key, $value) = split(/=/);
			$temp .= pack("nA*nA*", length($key), $key, length($value), $value);
		}
		$output = $temp;
	}
	elsif ($content_type eq "text/html") {

		#
		# We're sending an html file. We need to substitute the cgi_framework_STUFF
		#
		foreach (qw(cgi_framework_header cgi_framework_footer)) {
			$output =~ /<$_>/i || croak "Error: Cumulative templates for step $template_name does not contain the required <$_> tag";
		}
		$action = $self->{action} || $ENV{"SCRIPT_NAME"};
		$header = <<"EOM";
	<!-- CGI::Framework BEGIN HEADER -->
	<script language="JavaScript">
	<!--
	function process(a,i,sv) {
		document.myform._action.value=a;
		if (i != null) {
			document.myform._item.value=i;
		}
		if (sv != null) {
			document.myform._sv.value=sv;
		}
		document.myform.submit();
		return false;
	}
	function checksubmit() {
		if (document.myform._action.value == "") {
			return false;
		}
		else {
			return true;
		}
	}
	// -->
	</script>
	<form name="myform" method="POST" enctype="multipart/form-data" action="$action" onSubmit="return checksubmit();">
	<input type="hidden" name="_action" value="">
	<input type="hidden" name="_item" value="">
	<input type="hidden" name="_sv" value="">
	<input type="hidden" name="_template" value="$template_name">
	<!-- CGI::Framework END HEADER -->
EOM
		$footer = <<"EOM";
<!-- CGI::Framework BEGIN FOOTER -->
</form>
<!-- CGI::Framework END FOOTER -->
EOM
		$output =~ s/<cgi_framework_header>/$header/i;
		$output =~ s/<cgi_framework_footer>/$footer/i;
	}

	return wantarray ? ($output, $content_type) : $output;
}

#
# Takes a scalar key, and an optional value
# Gives them to the param() method of CGI::Session
#
sub session {
	my $self  = _getself(\@_);
	my $key   = shift || croak "key not supplied";
	my $value = shift;
	return defined($value) ? $self->{_session}->param($key, $value) : $self->{_session}->param($key);
}

#
# Takes a template name
# Calls pre__pre__all() and pre_templatename() and post__pre__all()
# Shows it
# Calls pre__post__all() and post_templatename() and post__post__all()
# THEN EXITS
#
sub show_template {
	my $self          = _getself(\@_);
	my $template_name = shift || croak "Template name not supplied";
	my $nofinalize    = shift;
	my $content;
	my $content_type;

	no strict 'refs';

	if (defined &{"$self->{callbacks_namespace}::pre__pre__all"}) {

		#
		# Execute a pre__pre__all
		#
		&{"$self->{callbacks_namespace}::pre__pre__all"}($self, $template_name);
	}

	if (defined &{"$self->{callbacks_namespace}::pre_$template_name"}) {

		#
		# Execute a pre_ for this template
		#
		&{"$self->{callbacks_namespace}::pre_$template_name"}($self, $template_name);
	}

	if (defined &{"$self->{callbacks_namespace}::post__pre__all"}) {

		#
		# Execute a post__pre__all
		#
		&{"$self->{callbacks_namespace}::post__pre__all"}($self, $template_name);
	}

	#
	# Parse template
	#
	($content, $content_type) = $self->return_template($template_name);

	#
	# Implement outbound filter
	#
	if ($self->{output_filter}) {
		&{ $self->{output_filter} }($self, \$content);
	}

	#
	# Send content
	#
	print "Content-type: $content_type\n";
	if ($self->{disable_back_button}) {
		print "Cache-control: no-cache\n";
		print "Pragma: no-cache\n";
		print "Expires: Thu, 01 Dec 1994 16:00:00 GMT\n";
	}
	print "\n";
	print $content;
	$self->session("_lastsent", $template_name);

	if (defined &{"$self->{callbacks_namespace}::pre__post__all"}) {

		#
		# Execute a pre__post__all
		#
		&{"$self->{callbacks_namespace}::pre__post__all"}($self, $template_name);
	}

	if (defined &{"$self->{callbacks_namespace}::post_$template_name"}) {

		#
		# Execute a post_ for this template
		#
		&{"$self->{callbacks_namespace}::post_$template_name"}($self);
	}

	if (defined &{"$self->{callbacks_namespace}::post__post__all"}) {

		#
		# Execute a post__post__all
		#
		&{"$self->{callbacks_namespace}::post__post__all"}($self, $template_name);
	}

	if (!$nofinalize) {
		$self->finalize();
	}

}

#
# This sub takes whatever's passed to it and
# records it in the log file
#
sub log_this {
	my $self     = _getself(\@_);
	my $message  = shift;
	my $filename = $self->{log_filename} || croak "Can not use log_this since no log_filename was defined in the constructor";
	local (*FH);
	$message =~ s/[\n\r]/-/g;
	open(FH, ">>$filename") || die "Error opening $filename: $!\n";
	flock(FH, LOCK_EX);
	seek(FH, 0, 2);
	print FH scalar(localtime), " : ", $ENV{'REMOTE_ADDR'}, " : ", $ENV{"SCRIPT_NAME"}, " : ", $message, "\n";
	flock(FH, LOCK_UN);
	close(FH);
	return (1);
}

#
# Takes a scalar
# Returns it's localized version
# or exact same unmodified string if localization is not applicable in current session
#
sub localize {
	my $self       = _getself(\@_);
	my $string     = shift || croak "string not supplied to localize";
	my @parameters = @_;
	my $localized;
	my $language;
	$self->{"maketext_class_name"} || return $string;
	if (!$self->{_language_handle}) {
		foreach $language (@{ $self->{valid_languages} }) {
			if ($self->session("_lang") eq $language) {
				undef $@;
				eval { eval('$self->{_language_handle} = ' . $self->{'maketext_class_name'} . '->get_handle( "' . $language . '" );') || die "Failed to get_handle() from $self->{'maketext_class_name'}: $! $@"; };
				die $@ if $@;
				last;
			}
		}
	}
	$localized = $self->{_language_handle}->maketext($string, @parameters);
	return $localized;
}

############################################################################
#
# PRIVATE SUBS START HERE

#
# Takes a templatename
# If found, returns templatefilename, contenttype if wantarray and just the filename in scalar mode
# otherwise, returns undef
#
sub _get_template_details {
	my $self = _getself(\@_);
	my $template_name = shift || croak "templatename not supplied";
	my $filename;
	my $content_type;

	if (-e "$self->{templates_dir}/$template_name.html") {
		$filename     = "$template_name.html";
		$content_type = "text/html";
	}
	elsif (-e "$self->{templates_dir}/$template_name.ins") {
		$filename = "$template_name.ins";
		if ($ENV{HTTP_USER_AGENT} =~ /MSIE/i) {
			$content_type = "application/x-internet-signup";
		}
		else {
			$content_type = "application/x-netscape-autoconfigure-dialer";
		}
	}
	elsif (-e "$self->{templates_dir}/$template_name.txt") {
		$filename     = "$template_name.txt";
		$content_type = "text/plain";
	}
	else {
		return undef;
	}
	return wantarray ? ($filename, $content_type) : $filename;
}

#
# Shows the missinginfo template
# If the template doesn't exist, writes it as text
#
sub _missinginfo {
	my $self = _getself(\@_);
	if ($self->_get_template_details("missinginfo")) {
		$self->show_template("missinginfo");
	}
	else {
		print "Content-type: text/plain\n\n";
		print "You are trying to submit a form with some missing information.  Please start from the beginning.";
		$self->finalize();
	}
}

#
# THIS IS A SUB, NOT A METHOD
# Takes an arrayref which should be a reference to the @_ array from whatever sub's calling it
# If the first argument is an instance: of this class, shifts it from the arrayref
# else returns $LASTINSTANCE
# or die()s if lastinstance isn't set
#
sub _getself {
	my $arrayref = shift;
	my $self;
	ref($arrayref) eq "ARRAY" || die "Arrayref not provided to _getself\n";
	if (ref($arrayref->[0]) eq "CGI::Framework") {
		$self = shift @$arrayref;
		return $self;
	}
	elsif (ref($LASTINSTANCE) eq "CGI::Framework") {
		return $LASTINSTANCE;
	}
	else {
		croak "Cannot use this method/sub without creating an instance of CGI::Framework first";
	}
}

#
# THIS IS A SUB, NOT A METHOD
# Takes a directory name
# Creates a skeleton of a new project under it
#
sub INITIALIZENEWPROJECT {
	my $dir           = shift || die "\n\nError: You must supply a directory as the first argument\n\n";
	my $cgi_dir       = "$dir/cgi-bin";
	my $lib_dir       = "$dir/lib";
	my $sessions_dir  = "$dir/sessions";
	my $templates_dir = "$dir/templates";
	my $public_dir    = "$dir/public_html";
	my $images_dir    = "$public_dir/images";
	local (*FH);
	my $filename;
	my $content;
	my $mode;

	$dir =~ m#^([/\\])|(\w:)# || die "\n\nYou must specify a fully-qualified, not a relative path\n\n";
	-d $dir && die "\n\n$dir already exists.  This is not recommended.  Please specify a non-existant directory\n\n";

	print "\n\nINITIALIZING A NEW PROJECT IN $dir\n\n";

	#
	# Create the directories
	#
	foreach ($dir, $cgi_dir, $lib_dir, $sessions_dir, $templates_dir, $public_dir, $images_dir) {
		print "Creating directory $_ ";
		mkdir($_, 0755) || die "\n\n:Error: Failed to create $_ : $!\n\n";
		print "\n";
	}
	print "Changing $sessions_dir mode ";
	chmod(0777, $sessions_dir) || die "\n\nError: Failed to chmod $sessions_dir to 777: $!\n\n";
	print "\n";

	#
	# Create the files
	#
	foreach (
		[
			"$templates_dir/header.html", 0644, <<"EOM"
	<html>
		<!-- Stub CGI created by CGI::Framework's INITIALIZENEWPROJECT command -->
	<head>
		<title>Welcome to my page</title>
	</head>
	<body bgcolor=silver text=navy link=orange alink=orange vlink=orange>

	<cgi_framework_header>

	<TMPL_INCLUDE NAME="errors.html">
EOM
		],
		[
			"$templates_dir/footer.html", 0644, <<"EOM"
	<!-- Stub CGI created by CGI::Framework's INITIALIZENEWPROJECT command -->
	<hr>
	<center><font size=1>Copyright (C) 2005 ME !!!</font></center>

	<cgi_framework_footer>

	</body>
	</html>
EOM
		],
		[
			"$templates_dir/login.html", 0644, <<"EOM"
	<!-- Stub CGI created by CGI::Framework's INITIALIZENEWPROJECT command -->
	<TMPL_INCLUDE NAME="header.html">

	The time is now: <TMPL_VAR NAME="currenttime">
	<p>

	<b>Enter your username:</b>
	<br>
	<input type="text" name="username" value="<TMPL_VAR NAME="username" ESCAPE=HTML>">

	<p>

	<b>Enter your password:</b>
	<br>
	<input type="password" name="password" value="<TMPL_VAR NAME="password" ESCAPE=HTML>">

	<p>

	<input type="button" value=" login &gt;&gt; " onclick="return process('mainmenu');">

	<TMPL_INCLUDE NAME="footer.html">
EOM
		],
		[
			"$templates_dir/mainmenu.html", 0644, <<"EOM"
	<!-- Stub CGI created by CGI::Framework's INITIALIZENEWPROJECT command -->
	<TMPL_INCLUDE NAME="header.html">

	<b>Welcome <TMPL_VAR NAME="username"></b>
	<p>
	Please select from the main menu:
	<UL>
		<LI> <a href="#" onclick="return process('youraccount');"> View your account details</a>
		<LI> <a href="#" onclick="return process('logout');"> Log out</a>
	</UL>

	<TMPL_INCLUDE NAME="footer.html">
EOM
		],
		[
			"$templates_dir/youraccount.html", 0644, <<"EOM"
	<!-- Stub CGI created by CGI::Framework's INITIALIZENEWPROJECT command -->
	<TMPL_INCLUDE NAME="header.html">

	<b>Your account details:</b>
	<p>
	Username: <b><TMPL_VAR NAME="username"></b>
	<p>
	Your services:
	<br>
	<table>
		<tr>
			<th align=left>Type</th>
			<th align=left>Details</th>
			<th align=left>Amount Due</th>
		</tr>
	<TMPL_LOOP NAME="services">
		<tr>
			<td><TMPL_VAR NAME="type"></td>
			<td><TMPL_VAR NAME="details"></td>
			<td><TMPL_VAR NAME="amount"></td>
		</tr>
	</TMPL_LOOP>
	</table>

	<p>

	<input type="button" value=" &lt;&lt; back to main menu " onclick="return process('mainmenu');">

	<TMPL_INCLUDE NAME="footer.html">
EOM
		],
		[
			"$templates_dir/missinginfo.html", 0644, <<"EOM"
	<!-- Stub CGI created by CGI::Framework's INITIALIZENEWPROJECT command -->
	<TMPL_INCLUDE NAME="header.html">



	<!--

	DEBUGGING INFO:

	CALLER: <TMPL_VAR NAME="_missing_info_caller">

	<TMPL_LOOP "_missing_info">
	FAILED ASSERTION: <TMPL_VAR NAME="name">
	</TMPL_LOOP>

	// -->



	<font color=red>PROBLEM:</font>

	It appears that your session is missing some information.  This is usually because you've just attempted to submit a session that has timed-out.  Please <a href="<TMPL_VAR NAME="_form_action" ESCAPE=HTML>">click here</a> to go to the beginning.

	<TMPL_INCLUDE NAME="footer.html">
EOM
		],
		[
			"$templates_dir/errors.html", 0644, <<"EOM"
	<!-- Stub CGI created by CGI::Framework's INITIALIZENEWPROJECT command -->
	<TMPL_IF NAME="_errors">
		<center>
		<table width=80% border=0 cellspacing=0 cellpadding=5 style="border-style:solid;border-width:1px;border-color:#CC0000;">
		<tr>
			<td valign=top align=left>
				<img src="/images/exclamation.gif"> <font color=red><b>The following ERRORS have occurred:</b></font>
				<blockquote>
					<TMPL_LOOP NAME="_errors">
						<img src="/images/dotarrow.gif"> <TMPL_VAR NAME="error"><br>
					</TMPL_LOOP>
				</blockquote>
				<font color=red>Please correct below and try again.</font>
			</td>
		</tr>
		</table>
		</center>
		<p>
	</TMPL_IF>
EOM
		],
		[
			"$templates_dir/logout.html", 0644, <<"EOM"
	<!-- Stub CGI created by CGI::Framework's INITIALIZENEWPROJECT command -->
	<TMPL_INCLUDE NAME="header.html">

	<b>You have been successfully logged out.</b>

	<TMPL_INCLUDE NAME="footer.html">
EOM
		],
		[
			"$cgi_dir/hello.cgi", 0755, <<"EOM"
#!$^X

	# Stub CGI created by CGI::Framework's INITIALIZENEWPROJECT command

	use strict;
	use CGI::Framework;
	use lib "$lib_dir";
	require pre_post;
	require validate;

	my \$f = new CGI::Framework (
		sessions_dir		=>	"$sessions_dir",
		templates_dir		=>	"$templates_dir",
		initial_template	=>	"login",
	)
	|| die "Failed to create a new CGI::Framework instance: \$\@\\n";

	#
	# Unless they've successfully logged in, keep showing the login page
	#
	if (\$f->session("authenticated") || \$f->form("_action") eq "mainmenu") {
		\$f->dispatch();
	}
	else {
		\$f->show_template("login");
	}

EOM
		],
		[
			"$lib_dir/validate.pm", 0644, <<"EOM"

	# Stub module created by CGI::Framework's INITIALIZENEWPROJECT command
	
	use strict;

	sub validate_login {
		my \$f = shift;
		if (!\$f->form("username")) {
			\$f->add_error("You must supply your username");
		}
		if (!\$f->form("password")) {
			\$f->add_error("You must supply your password");
		}
		if (\$f->form("username") eq "goodusername" && \$f->form("password") eq "cleverpassword") {
			# Logged in fine
			\$f->remember("username");
			\$f->session("authenticated", 1);
		}
		elsif (\$f->form("username") && \$f->form("password")) {
			\$f->add_error("Login failed");
		}
	}

	1;
EOM
		],
		[
			"$lib_dir/pre_post.pm", 0644, <<"EOM"

	# Stub module created by CGI::Framework's INITIALIZENEWPROJECT command

	use strict;

	sub pre_login {
		my \$f = shift;
		\$f->html("currenttime", scalar localtime(time));
	}

	sub pre_youraccount {
		my \$f = shift;
		my \@services = (
			{
				type	=>	"Cell Phone",
				details	=>	"(514) 123-4567",
				amount	=>	'\$25.00',
			},
			{
				type	=>	"Laptop Rental",
				details	=>	"SuperDuper Pentium 4 3.01hz",
				amount	=>	'\$35.99',
			},
		);
		\$f->html("services", \\\@services);
	}

	sub post_logout {
		my \$f = shift;
		\$f->clear_session();
	}

	1;
EOM
		],
		[ "$images_dir/dotarrow.gif",    0644, "\x47\x49\x46\x38\x39\x61\x0b\x00\x08\x00\xb3\x00\x00\xff\xff\xff\xff\x63\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x21\xf9\x04\x01\x00\x00\x00\x00\x2c\x00\x00\x00\x00\x0b\x00\x08\x00\x00\x04\x14\x10\xc8\x09\x42\xa0\xd8\xe2\x2d\xb5\xbf\xd6\x57\x81\x17\x67\x76\x25\xa7\x01\x11\x00\x3b\x00" ],
		[ "$images_dir/exclamation.gif", 0644, "\x47\x49\x46\x38\x39\x61\x0e\x00\x0e\x00\xa2\xff\x00\xff\xff\xff\xff\xe6\xb3\xff\xcc\x66\x80\x80\x80\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x21\xff\x0b\x41\x44\x4f\x42\x45\x3a\x49\x52\x31\x2e\x30\x02\xde\xed\x00\x21\xff\x0b\x4e\x45\x54\x53\x43\x41\x50\x45\x32\x2e\x30\x03\x01\x07\x00\x00\x21\xf9\x04\x04\x28\x00\x00\x00\x2c\x00\x00\x00\x00\x0e\x00\x0e\x00\x00\x03\x28\x08\xba\x44\xfb\x8f\x08\xe1\x20\x9b\xb3\x42\x49\xb9\x56\x5c\x87\x69\xa1\x38\x02\xa5\x39\xa6\x0d\x96\xa1\x6e\x4c\x5d\x59\xf8\xc1\xe6\x0d\xba\x3a\xdd\x47\xba\x04\x00\x21\xf9\x04\x04\x0f\x00\x00\x00\x2c\x06\x00\x03\x00\x02\x00\x08\x00\x00\x03\x04\x28\xba\xdc\x92\x00\x21\xf9\x04\x04\x0f\x00\x00\x00\x2c\x00\x00\x00\x00\x0e\x00\x0e\x00\x00\x03\x25\x08\xba\x33\xfb\x6f\x84\xe0\x20\x9b\xb3\x42\x89\xf3\xee\x9d\xc6\x81\x98\x33\x92\xe5\x89\x52\x80\x0a\x8a\xab\xa6\xb8\xf2\x55\x5a\x76\x6d\x35\x56\x02\x00\x21\xf9\x04\x04\x19\x00\x00\x00\x2c\x00\x00\x00\x00\x0e\x00\x0e\x00\x00\x03\x0d\x08\xba\xdc\xfe\x30\xca\x49\xab\xbd\x38\xeb\xed\x12\x00\x21\xf9\x04\x04\x0f\x00\x00\x00\x2c\x00\x00\x00\x00\x0e\x00\x0e\x00\x00\x03\x25\x08\xba\x33\xfb\x6f\x84\xe0\x20\x9b\xb3\x42\x89\xf3\xee\x9d\xc6\x81\x98\x33\x92\xe5\x89\x52\x80\x0a\x8a\xab\xa6\xb8\xf2\x55\x5a\x76\x6d\x35\x56\x02\x00\x21\xf9\x04\x04\x0f\x00\x00\x00\x2c\x00\x00\x00\x00\x0e\x00\x0e\x00\x00\x03\x25\x08\xba\x44\xfb\x8f\x08\xe1\x20\x9b\xb3\x42\x89\xf3\xee\x9d\xc6\x81\x98\x33\x92\xe5\x89\x52\x80\x0a\x8a\xab\xa6\xb8\xf2\x55\x5a\x76\x6d\x35\x56\x02\x00\x21\xf9\x04\x04\x28\x00\x00\x00\x2c\x06\x00\x03\x00\x02\x00\x08\x00\x00\x03\x05\x48\xba\x2c\xc2\x09\x00\x3b\x00" ],
	  ) {
		($filename, $mode, $content) = @$_;
		print "Creating file $filename ";
		open(FH, ">$filename") || die "\n\nError: Failed to open $filename for writing: $!\n\n";
		print FH $content;
		close(FH);
		print "Setting permission to ", sprintf("%o", $mode), " ";
		chmod($mode, $filename) || die "\n\nError: Failed to set mode on $filename to $mode: $!\n\n";
		print "\n";
	}

	print "\n\nDONE: Your stub project is now ready in $dir\n\n";
	exit;
}

############################################################################
#
# OLD COMPATABILITY SUBS START HERE

sub adderror {
	return add_error(@_);
}

sub clearsession {
	return clear_session(@_);
}

sub showtemplate {
	return show_template(@_);
}

sub logthis {
	return log_this(@_);
}

1;
__END__

