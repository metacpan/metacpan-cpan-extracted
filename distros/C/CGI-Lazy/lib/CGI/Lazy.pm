package CGI::Lazy;

use strict;

use JSON;
use CGI::Pretty;
use CGI::Lazy::Config;
use CGI::Lazy::Plugin;
use CGI::Lazy::DB;
use CGI::Lazy::DB::RecordSet;
use CGI::Lazy::Session;
use CGI::Lazy::Template;
use CGI::Lazy::Widget;
use CGI::Lazy::Globals;
use CGI::Lazy::ErrorHandler;
use CGI::Lazy::Utility;
use CGI::Lazy::Javascript;
use CGI::Lazy::CSS;
use CGI::Lazy::Image;
use CGI::Lazy::Authn;
use CGI::Lazy::Authz;

use base qw(CGI::Pretty);

our $VERSION = '1.10';

our $AutoloadClass = 'CGI'; #this is neccesarry to get around an autoload problem in CGI.pm.  

#------------------------------------------------------------
sub DESTROY {
	my $self = shift;

	if ($self->plugin && $self->plugin->session) { 
		unless ($self->plugin->session->{saveOnDestroy} == 0) {
			$self->session->save;
		}
	}

	return;
}

#------------------------------------------------------------
sub authn {
	my $self = shift;

	return $self->{_authn};
}

#------------------------------------------------------------
sub authz {
	my $self = shift;

	return $self->{_authz};

}

#------------------------------------------------------------
sub css	{
	my $self = shift;

	return CGI::Lazy::CSS->new($self);

}

#------------------------------------------------------------
sub csswrap {
	my $self = shift;
	my $css = shift;

	my $csspre = "\n<style type='text/css'>\n<!--\n";
	my $csspost = "\n-->\n</style>\n";

	return $csspre.$css.$csspost;
}

#------------------------------------------------------------
sub image {
	my $self = shift;

	return CGI::Lazy::Image->new($self);
}

#------------------------------------------------------------
sub javascript {
	my $self = shift;

	return CGI::Lazy::Javascript->new($self);
}

#------------------------------------------------------------
sub config {
	my $self = shift;

	return $self->{_config};
}

#------------------------------------------------------------
sub db {
	my $self = shift;

	return $self->{_db};
}

#------------------------------------------------------------
sub dbh {
	my $self = shift;

	return $self->db->dbh;
}

#------------------------------------------------------------
sub errorHandler {
	my $self = shift;

	return $self->{_errorHandler};
}

#------------------------------------------------------------
sub header {
	my $self = shift;

	my %args;

	if (scalar @_ % 2 == 0) {
		%args = @_;
	} else {
		my $ref = shift;
		%args = %$ref;
	}

	my $explicitcookies = $args{-cookie} || []; #cookies set explictly in the instance
	my $lazycookie;

	if ($self->plugin) { #it's possible that this object hasn't been built- if the config object doesn't create for instance.
		if ($self->plugin->session && $self->session) {
			$lazycookie = $self->cookie(
						-name		=> $self->plugin->session->{sessionCookie},
						-expires	=> $self->plugin->session->{expires},
						-value 		=> $self->session->sessionID,
			);
		}
	} else { #something really bad happened.  Return a header anyway, so we can show an error message
		return $self->SUPER::header();
	}

	$args{-cookie} = [$lazycookie, @$explicitcookies];

	return $self->SUPER::header(%args);
}

#------------------------------------------------------------
sub jswrap {
	my $self = shift;
	my $js = shift;

	my $jspre = "\n<script type='text/javascript'>\n<!--\n";
	my $jspost = "\n-->\n</script>\n";
	return $jspre.$js.$jspost;
}

#------------------------------------------------------------
sub mod_perl {
	my $self = shift;

	return $self->{_mod_perl};
}

#------------------------------------------------------------
sub new {
	my $class = shift;
	my $vars = shift;

	my $sessionID;

	my $self = bless $class->SUPER::new(@_), $class;

	$self->{_vars} 		= $vars;
	$self->{_errorHandler} 	= CGI::Lazy::ErrorHandler->new($self);
	$self->{_config}	= CGI::Lazy::Config->new($self, $vars);
	$self->{_plugin}	= CGI::Lazy::Plugin->new($self);
	$self->{_db} 		= CGI::Lazy::DB->new($self);

	if ($self->plugin->session) {
		$self->{_session} = CGI::Lazy::Session->open($self, $sessionID);
	}

	if ($self->plugin->authn) {
		$self->{_authn}	= CGI::Lazy::Authn->new($self);
	}

	if ($self->plugin->authz) {
		$self->{_authz}	= CGI::Lazy::Authz->new($self);
	}

	if ($self->plugin->mod_perl) {
		require CGI::Lazy::ModPerl;
		$self->{_mod_perl} = CGI::Lazy::ModPerl->new($self);
	}

	return $self; 
}

#------------------------------------------------------------
sub lazyversion {
	my $self = shift;

	return $VERSION;
}

#------------------------------------------------------------
sub plugin {
	my $self = shift;

	return $self->{_plugin};
}

#------------------------------------------------------------
sub session {
	my $self = shift;

	return $self->{_session};
}

#------------------------------------------------------------
sub template {
	my $self = shift;
	my $template = shift;

	if ($self->{_template}->{$template}) { 		#if it's been created, return it
		return $self->{_template}->{$template};
	} else { 					#if not, create it and return it
		return $self->{_template}->{$template} = CGI::Lazy::Template->new($self, $template);
	}
}

#------------------------------------------------------------
sub util {
	my $self = shift;

	return CGI::Lazy::Utility->new($self);

}

#------------------------------------------------------------
sub vars {
	my $self = shift;

	return $self->{_vars};
}

#------------------------------------------------------------
sub widget {
	my $self = shift;

	return CGI::Lazy::Widget->new($self);
}

1;

__END__

=head1 LEGAL

#===========================================================================

Copyright (C) 2007 by Nik Ogura. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Bug reports and comments to nik.ogura@gmail.com. 

#===========================================================================

=head1 NAME

CGI::Lazy

=head1 SYNOPSIS

	use CGI::Lazy;

	our $q = CGI::Lazy->new({

					tmplDir 	=> "/path/to/templates", 	#not off doc root

					jsDir		=>  "/js",			#off doc root

					plugins 	=> {

						mod_perl => {

							PerlHandler 	=> "ModPerl::Registry",

							saveOnCleanup	=> 1,

						},

						dbh 	=> {

							dbDatasource 	=> "dbi:mysql:somedatabase:localhost",
							
							dbUser 		=> "dbuser",

							dbPasswd 	=> "letmein",

							dbArgs 		=> {"RaiseError" => 1},

						},

						session	=> {

							sessionTable	=> 'SessionData',

							sessionCookie	=> 'frobnostication',

							saveOnDestroy	=> 1,

							expires		=> '+15m',

						},

					},

				});


	print $q->header,

	      $q->start_html({-style => {-src => '/css/style.css'}}),

	      $q->javascript->modules(); 



	print $q->template('topbanner2.tmpl')->process({ logo => '/images/funkyimage.png', mainTitle => 'Funktastic', secondaryTitle => $message, versionTitle => '0.0.1', messageTitle => 'w00t!', });



	print $q->template('navbar1.tmpl')->process({

						one 		=> 'link one',

						one_link	=> '/blah.html',

						two		=> 'link two',

						two_link	=> '/blah.html',

						three		=> 'link three',

						three_link	=> '/blah.html',

						four		=> 'link four',

						four_link	=> '/blah.html',

						});

	print $q->template('fileMonkeyHelp.tmpl')->process({helpMessage => 'help text here'});

	print $q->template('fileMonkeyMain.tmpl')->process({mainmessage => "session info: <br> name: ".$q->session->data->name . "<br> time: ".$q->session->data->time});

	print $q->template('footer1.tmpl')->process({version => $q->lazyversion});



=head1 DESCRIPTION

CGI::Lazy was designed to simply abstract some of the more common cgi scripting tasks because the author finally got sick of writing the same code by hand for every new site or client that comes along.  It is my attempt to extend the wonderful CGI.pm with things that just about every modern website needs or wants, and to do it in a fairly portable manner.

There are plenty of webdev frameworks out there, many are far more full- featured.  Often these solutions are so monstrous that they are overkill for small apps, or so optimized that they require full admin rights on the server they run on.  CGI::Lazy was intended to be lightweight enough to run on any given server that could run perl cgi's.  Of course, the more power you have, the fancier you will be able to get, so Lazy was written to be extensible and to (hopefully) play nice with whatever magic you have up your sleeve. 

Lazy has also been written to be useful in a mod_perl environment if that is your pleasure.  The wonders of persistence and namespaces have been (again, hopefully) all accounted for.  It should plug into your mod_perl environment with little or no fuss.

For the most part, CGI::Lazy is simply a subclass of CGI::Pretty, which is an easier to read version of CGI.pm. 

We need to use CGI::Pretty due to a css issue in IE where the style definitions aren't always followed unless there is the appropriate amount of whitespace between html tags.  Luckilly, CGI::Pretty takes care of this pretty transparently, and its output is easier to read and debug.

CGI::Lazy adds a bunch of hooks in the interest of not working any harder than we need to, otherwise it's a CGI::Pretty object.

Probably 80% of the apps the author has been asked to write have been front ends to some sort of database, so that's definitely the angle Lazy is coming from.  It works just fine with no db, but most of the fancy work is unavailable.

Output to the web is intended to be through templates via HTML::Template.  However, if you want to write your content into the code manually, we won't stop you.  Again, the whole point was to be flexible and reusable, and to spend our time writing new stuff, not the same old crap over and over again.

The CGI::Lazy::Widget::Dataset module especially was written to bring spreadsheet-like access to a database table to the web in a fairly transparent manner- after all, most of the time you're doing one of 4 operations on a database: select, insert, update, delete.  The Dataset is, at least at the time of the original writing, the crown jewel of the Lazy framework.  The templates for a Dataset are pretty complicated, and are tied pretty tightly to the Javascript that controls them on the client side.  Because nobody (especially the author) wants to write these monsters from scratch every time a new Widget is called for, the CGI::Lazy::Template::Boilerplate class exists to generate boring, but functional templates for your Widgets.  The boilerplate templates give you a functional starting place.  After that, it's up to you.

In any event, it is my hope that this is useful to you.  It has saved me quite alot of work.  I hope that it can do the same for you.  Bug reports and comments are always welcome.

=head1 METHODS

=head2 authn ()

Returns authentication object

=head2 authz ()

Returns authorization object

=head2 config ()

Method retrieves CGI::Lazy::Config object for configuration variable retrieval
See CGI::Lazy::Config for details


=head2 db ()

Method retrieves the database object CGI::Lazy::DB.  The db object contains convenience methods for database access, and will contain the default database handle for the object.


=head2 dbh ()

Retrieves dbh from db object for use in cgi.  Convenience method.  Same as $q->db->dbh.


=head2 errorHandler ()

Returns the CGI::Lazy::ErrorHandler object.  ErrorHandler contains convenience methods for trapping and returning error codes without generating a pesky 500 error.


=head2 header (args)

Creates standard http header.  Passes all arguments to CGI::Pretty::header, simply adding our own goodness to it in passing.  

=head3 args

normal header args

=head2 javascript (  )

returns CGI::Lazy::Javascript object.

see CGI::Lazy::Javascript for details.

=head2 jswrap ( script )

Wraps javascript text in script tags and html comments for output to the browser.  Pretty much the same as $q->script, but it comment wraps the script contents.

=head3 script

javascript text to output to the browser.


=head2 mod_perl ()

Returns mod_perl object if plugin is enabled.

See CGI::Lazy::ModPerl for details


=head2 new ( args )

Constructor.  Creates the instance of the CGI::Lazy object.

=head3 args

If args is a hashref, it will assume that the hash is the config. 

If it's just a string, it's assumed to be the absolute path to the config file for the Lazy object.  That file will be parsed as JSON.


	tmplDir 	=> Directory where Lazy will look for html templates.  Absolute path to directory.

	buildDir	=> Directory where Lazy will build template stubs.  Absolute path to directory.

	jsDir		=> Directory where Lazy will look for javascript.  Path relative to document root.

	cssDir		=> Directory where Lazy will look for css.  Path relative to document root.

	noMinify	=> By default javascript is minified before output- all whitespace is removed.  This speeds things up mightily, but can make for difficult debugging.  
			   Set this to a true value, and javascript will be printed with all whitespace intact.

	silent		=> Set to a true value, and internal errors will not be printed to STDERR.  Defaults to false.

	plugins 	=> Optional components

		mod_perl => mod_perl goodness

		dbh 	=> Lazy handles database connection

		dbhVar	=> name of variable that holds database handle created elsewhere

		session	=> stateful sessions (requires database)

=head2 lazyversion ()

returns version of CGI::Lazy.


=head2 plugin ()

Returns plugin object.

see CGI::Lazy::Plugin for details.


=head2 session

Returns the session object
see CGI::Lazy::Session for details.


=head2 template ()

Returns CGI::Lazy::Template object, or if it hasn't been created yet, creates it and returns it.

See CGI::Lazy::Template for details.


=head2 util ()

Returns CGI::Lazy::Utility object

See CGI::Lazy::Utility for details.


=head2 vars ()

Returns hashref to the variables used in creating the object.

=head2 widget ()

returns the CGI::Lazy::Widget object

=head1 Subversion

Subversion repository available at:

	http://www.nikogura.com/svn/CGI/trunk

A collection of demo scripts are available at:

	http://www.nikogura.com/svn/lazydemo/trunk

=cut


