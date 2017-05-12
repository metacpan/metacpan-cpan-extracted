package CAM::App;

=head1 NAME

CAM::App - Web database application framework

=head1 LICENSE

Copyright 2005 Clotho Advanced Media, Inc., <cpan@clotho.com>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SYNOPSIS

You can either directly instantiate this module, or create a subclass,
creating overridden methods as needed.

Direct use:

    use CAM::App;
    require "Config.pm";  # user-edited config hash
    
    my $app = CAM::App->new(Config->new(), CGI->new());
    $app->authenticate() or $app->error("Login failed");
    
    my $tmpl = $app->template("message.tmpl");
    my $ans = $app->getCGI()->param('ans');
    if (!$ans) {
       $tmpl->addParams(msg => "What is your favorite color?");
    } elsif ($ans eq "blue") {
       $tmpl->addParams(msg => "Very good.");
    } else {
       $tmpl->addParams(msg => "AIIEEEEE!");
    }
    $tmpl->print();

Subclass:  (then use just like above, replacing CAM::App with my::App)

    package my::App;
    use CAM::App;
    @ISA = qw(CAM::App);
    
    sub init {
       my $self = shift;
       
       my $basedir = "..";
       $self->{config}->{cgidir} = ".";
       $self->{config}->{basedir} = $basedir;
       $self->{config}->{htmldir} = "$basedir/html";
       $self->{config}->{templatedir} = "$basedir/tmpls";
       $self->{config}->{libdir} = "$basedir/lib";
       $self->{config}->{sqldir} = "$basedir/lib/sql";
       $self->{config}->{error_template} = "error_tmpl.html";
       
       $self->addDB("App", "live", "dbi:mysql:database=app", "me", "mypass");
       $self->addDB("App", "dev", "dbi:mysql:database=appdev", "me", "mypass");
       
       return $self->SUPER::init();
    }
    
    sub authenticate {
       my $self = shift;
       return(($self->getCGI()->param('passwd') || "") eq "secret");
    }
    
    sub selectDB {
       my ($self, $params) = @_;
       my $key = $self->{config}->{myURL} =~ m,^http://dev\.foo\.com/, ? 
           "dev" : "live";
       return @{$params->{$key}};
    }

=head1 DESCRIPTION

CAM::App is a framework for web-based, database-driven applications.
This package abstracts away a lot of the tedious interaction with the
application configuration state.  It is quite generic, and is designed
to be subclassed with more specific functions overriding its behavior.

=cut

#--------------------------------#

require 5.005_62;
use strict;
use warnings;
use File::Spec;
use Carp;
use CGI;

## These are loaded on-demand below, if they are not already loaded.
## Please keep this list up to date!
#use DBI;
#use CAM::Template;
#use CAM::EmailTemplate;
#use CAM::EmailTemplate::SMTP;
#use CAM::Template::Cache;
#use CAM::Session;

# The following modules may loaded externally, if at all.  This module
# detects their presence by looking for their $VERSION variables.
#   CGI::Compress::Gzip
#   CAM::Session
#   CAM::SQLManager
#   CAM::Template::Cache

our @ISA = qw();
our $VERSION = '1.07';

### Package globals
our %global_dbh_cache = ();  # used to hold DBH objects created by this package

#--------------------------------#

=head1 CONFIGURATION

CAM::App relies on a few configuration variables set externally to
achieve full functionality.  All of the following are optional, and
the descriptions below explain what will happen if they are not
present.  The following settings may be used:

=over 2

=item cookiename (default 'session')

=item sessiontime (default unlimited)

=item sessiontable (default 'session')

These three are all used for session tracking via CAM::Session.  New
sessions are created with the getSession() method.  The C<cookiename> can
be any alphanumeric string.  The C<sessiontime> is the duration of the
cookie in seconds.  The C<sessiontable> is the name of a MySQL table
which will store the session data.  The structure of this latter table
is described in CAM::Session.  The session tracking requires a
database connection (see the database config parameters)

=item dbistr

=item dbhost

=item dbport

=item dbname

=item dbusername

=item dbpassword

Parameters used to open a database connection.  Either C<dbistr> or
C<dbhost>, C<dbport> and C<dbname> are used, but not both.  If
C<dbistr> is present, it is used verbatim.  Otherwise the C<dbistr> is
constructed as either
C<DBI:mysql:database=dbname;host=dbhost;port=dbport> (the host and
port clauses are omitted if the corresponding variables are not
present in the configuration).  If dbpassword is missing, it is
assumed to be the empty string ("").

An alternative database registration scheme is described in the
addDB() method below.

=item mailhost

If this config variable is set, then all EmailTemplate messages will
go out via SMTP through this host.  If not set, EmailTemplate will use
the C<sendmail> program on the host computer to send the message.

=item templatedir

The directory where CAM::Template and its subclasses look for template
files.  If not specified and the template files are not in the current
directory, all of the getTemplate() methods will trigger errors.

=item sqldir

The directory where CAM::SQLManager should look for SQL XML files.
Without it, CAM::SQLManager will not find its XML files.

=item error_template

The name of a file in the C<templatedir> directory.  This template is
used in the error() method (see below for more details).

=item sessionclass

The Perl package to use for session instantiation.  The default is
CAM::Session.  CAM::App is closely tied to CAM::Session, so only a
CAM::Session subclass will likely function here.

=back

=cut

#--------------------------------#

=head1 FUNCTIONS 

=over 4

=cut

#--------------------------------#

=item new [config => CONFIGURATION], [cgi => CGI], [dbi => DBI], [session => SESSION]

Create a new application instance.  The configuration object must be a
hash reference (blessed or unblessed, it doesn't matter).  Included in
this distibution is the example/SampleConfig.pm module that shows what
sort of config data should be passed to this constructor.  Otherwise,
you can apply configuration parameters by subclassing and overriding
the constructor.

Optional objects will be accepted as arguments; otherwise they will be
created as needed.  If you pass an argument with value undef, that
will be interpreted as meaning that you don't want the object
auto-created.  For example, C<new()> will cause a CGI object to be
created, C<new(cgi =E<gt> $cgi)> will use the passed CGI object, and
C<new(cgi =E<gt> undef)> will not create use CGI object at all.  The
latter is useful where the creation of a CGI object may be
destructive, for example in a SOAP::Lite environment.

=cut

sub new
{
   my $pkg = shift;
   my %params = (@_);

   my $self = bless({
      dbparams => {},
      status => [],
   }, $pkg);
   $self->applyDBH(); # clear any cached values

   foreach my $key (qw(cgi dbh session config))
   {
      $self->{$key} = $params{$key} if (exists $params{$key});
   }
   if (!$self->{config})
   {
      $self->{config} = {};
   }
   $self->init();
   return $self;
}

#--------------------------------#

=item init

After an object is constructed, this method is called.  Subclasses may
want to override this method to apply tweaks before calling the
superclass initializer.  An example:

   sub init {
      my $self = shift;
      $self->{config}->{sqldir} = "../lib/sql";
      return $self->SUPER::init();
   }

This init function does the following:

* Sets up some of the basic configuration parameters 
(myURL, fullURL, cgidir, cgiurl)

* Creates a new CGI object if one does not exist (as per getCGI)

* Sets up the DBH object if one exists

* Tells CAM::SQLManager where the sqldir is located if possible

=cut

sub init
{
   my $self = shift;

   my $cfg = $self->{config}; # shorthand

   #$SIG{__DIE__} = sub {$self->{dying}=1;$self->error(@_)};

   ## Initialize session package
   $cfg->{sessionclass} ||= "CAM::Session";

   ## Initialize CGI
   $self->getCGI(); # initialize CGI if possible/appropriate

   ## Initialize myURL
   if (!exists $cfg->{myURL})
   {
      $cfg->{myURL} = CGI->url();
   }
   if (!exists $cfg->{fullURL} && $self->getCGI())
   {
      # For file uploads, the self_url call generates a
      #    "Use of uninitialized value at (eval 29) line 8."
      # error because of a bug in CGI v2.46.
      # Block this by turning off warnings for this line.
      no warnings;
      $cfg->{fullURL} = $self->getCGI()->self_url();
      use warnings;
   }

   ## Initialize cgiurl
   if ($cfg->{myURL} && (!exists $cfg->{cgiurl}))
   {
      # Truncate the filename from the URL
      ($cfg->{cgiurl} = $cfg->{myURL}) =~ s,/[^/\\]*$,,;
   }

   ## Initialize cgidir
   if (!exists $cfg->{cgidir})
   {
      $cfg->{cgidir} = $self->computeDir();
   }

   ## Initialize DBH
   if ($self->{dbh})
   {
      # Note that unlike getDBH(), the DBH is NOT cached in this case.
      # This is the correct behavior.  Since the calling script handed
      # us the DBH, it's assumed that the caller will handle any
      # caching

      $self->applyDBH();
   }

   ## Initialize sqldir
   if ($CAM::SQLManager::VERSION && $self->{config}->{sqldir})
   {
      CAM::SQLManager->setDirectory($self->{config}->{sqldir});
   }

   return $self;
}
#--------------------------------#

=item computeDir

Returns the directory in which this CGI script is located.  This can
be a class or instance method.

=cut

sub computeDir
{
   my $pkg_or_self = shift;

   my $cgidir;
   if ($ENV{SCRIPT_FILENAME})
   {
      ($cgidir = $ENV{SCRIPT_FILENAME}) =~ s,/[^/\\]*$,,;
   }
   elsif ($ENV{PATH_TRANSLATED})
   {
      $cgidir = $ENV{PATH_TRANSLATED};
   }
   elsif ($ENV{PWD})
   {
      # Append the calling path (if any) to the PWD
      if ($0 =~ /(.*)[\/\\]/)
      {
         my $execpath = $1;
         if ($execpath =~ m,^[/\\],)
         {
            $cgidir = $execpath;
         }
         else
         {
            $cgidir = File::Spec->catdir($ENV{PWD}, $execpath);
         }
      }
      else
      {
         $cgidir = $ENV{PWD};
      }
   }
   # Fix odd cases, like a script called from "./myscript" or "../myscript
   if ($cgidir)
   {
      $cgidir =~ s,/[^/]+/\.\.,,g;    # remove "/dir/.."
      $cgidir =~ s,\\[^\\]+\\\.\.,,g; # remove "\dir\.."
      $cgidir =~ s,/\./,/,g;          # change "path/./path" to "path/path"
      $cgidir =~ s,\\\.\\,\\,g;       # change "path\.\path" to "path\path"
      $cgidir =~ s,/\.$,,g;           # change "path/." to "path"
      $cgidir =~ s,\\\.$,,g;          # change "path\." to "path"
      $cgidir =~ s,//+$,/,g;          # change "path///path" to "path/path"
      $cgidir =~ s,\\\\+$,\\,g;       # change "path\\\path" to "path\path"
   }
   return $cgidir;
}
#--------------------------------#

=item authenticate

Test the login information, if any.  Currently no tests are performed
-- this is a no-op.  Subclasses may override this method to test login
credentials.  Even though it's currently trivial, subclass methods
should alway include the line:

    return undef if (!$self->SUPER::authenticate());

In case the parent authenticate() method adds a test in the future.

=cut

sub authenticate {
   my $self = shift;

   # No checks

   return $self;
}

#--------------------------------#

=item header

Compose and return a CGI header, including the CAM::Session cookie, if
applicable (i.e. if getSession() has been called first).  Returns the
empty string if the header has already been printed.

=cut

sub header {
   my $self = shift;

   my $cgi = $self->getCGI();
   if (!$cgi)
   {
      if (!$self->{header_printed})
      {
         $self->{header_printed} = 1;
         return "Content-Type: text/html\n\n";
      }
      else
      {
         return "";
      }
   }
   elsif (!$cgi->{'.header_printed'})
   {
      if ($self->{session})
      {
         return $cgi->header(-cookie => $self->{session}->getCookie(), @_);
      }
      else
      {
         return $cgi->header(@_);
      }
   }
   else
   {
      return "";
   }
}
#--------------------------------#

=item isAllowedHost

This function is called from authenticate().  Checks the incoming host
and returns false if it should be blocked.  Currently no tests are
performed -- this is a no-op.  Subclasses may override this behavior.

=cut

sub isAllowedHost {
   my $self = shift;

   # For now, let any host view the site
   # Return undef to block access to a host
   return $self;
}
#--------------------------------#

=item getConfig

Returns the configuration hash.

=cut

sub getConfig
{
   my $self = shift;
   return $self->{config};
}
#--------------------------------#

=item getCGI

Returns the CGI object.  If a CGI object does not exist, one is
created.  If this application is initialized explicitly like 
C<new(cgi =E<gt> undef)>, then no new CGI object is created.  This
behavior is useful for non-CGI applications, like SOAP handlers.

CGI::Compress::Gzip is preferred over CGI.  The former will be used if
it is installed and the client browser supports gzip encoding.

=cut

sub getCGI
{
   my $self = shift;
   if (!exists $self->{cgi})
   {
      if ($ENV{HTTP_ACCEPT_ENCODING} && # don't bother unless it's possible
          $self->loadModule("CGI::Compress::Gzip"))
      {
         $self->{cgi} = CGI::Compress::Gzip->new();
      }
      else
      {
         $self->{cgi} = CGI->new();
      }
   }
   return $self->{cgi};
}
#--------------------------------#

=item getDBH

=item getDBH NAME

Return a DBI handle.  This object is created, if one does not already
exist, using the configuration parameters to initialize a DBI object.

There are two methods for specifying how to open the database
connection: 1) use the C<dbistr>, C<dbhost>, C<dbport>, C<dbname>,
C<dbusername>, and C<dbpassword> configuration variables, is set; 2)
use the NAME argument to select from the parameters entered via the
addDB() method.

The config variables C<dbusername> and C<dbpassword> are used, along
with either C<dbistr> (if present) or C<dbname> and C<dbhost>.
If no C<dbistr> is specified via config, MySQL is assumed.  The DBI
handle is cached in the package for future use.  This means that under
mod_perl, the database connection only needs to be opened once.

If NAME is specified, the database definitions entered from addDB()
are searched for a matching name.  If one is found, the connection is
established.  If the addDB() call specified multiple options, they are
resolved via the selectDB() method, which mey be overridden by
subclasses.

=cut

sub getDBInfo
{
   my $self = shift;
   my $name = shift;  # optional

   my $dbistr;
   my $dbuser;
   my $dbpass;

   my $cfg = $self->{config}; # shorthand
   
   if ($name)
   {
      # Retrieve parameters for a named handle
      my $dbparams = $self->{dbparams}->{$name};
      if ($dbparams)
      {
         ($dbistr, $dbuser, $dbpass) = $self->selectDB($dbparams);
      }
   }
   elsif (($cfg->{dbistr} || $cfg->{dbname}) && $cfg->{dbusername})
   {
      ($dbistr, $dbuser, $dbpass) = $self->getDBInfoFromCfg($cfg);
   }

   return ($dbistr, $dbuser, $dbpass);
}

sub getDBInfoFromCfg
{
   my $self = shift;
   my $cfg = shift;

   # Get the config parameters for the handle
   # Use "dbistr" if possible, otherwise use "dbname", "dbhost"
   # and "dbport"
   
   my $dbistr;
   my $dbuser;
   my $dbpass;
   
   if ($cfg)
   {
      $dbistr = $cfg->{dbistr};
      if (!$dbistr && $cfg->{dbname})
      {
         $dbistr = "DBI:mysql:database=".$cfg->{dbname};
         $dbistr .= ";host=".$cfg->{dbhost} if ($cfg->{dbhost});
         $dbistr .= ";port=".$cfg->{dbport} if ($cfg->{dbport});
      }
      $dbuser = $cfg->{dbusername};
      $dbpass = $cfg->{dbpassword};
   }
   return ($dbistr, $dbuser, $dbpass);
}

sub getDBH
{
   my $self = shift;
   my $name = shift;  # optional

   my $cfg = $self->{config};

   # Build the DBH if there is no DBH yet, or if the requested one has
   # a different name from the previous one.
   if ((!exists $self->{dbh}) ||
       ($name && ((!$self->{dbhname}) ||
                  $self->{dbhname} ne $name)))
   {
      my ($dbistr, $dbuser, $dbpass) = $self->getDBInfo($name);

      if (!$dbistr)
      {
         # return undef below
      }
      else
      {
         if (!$self->loadModule("DBI"))
         {
            $self->error("Internal error: Failed to load the DBI library");
         }
         
         # First try to retrieve a global dbh object, shared between
         # CAM::App objects, or left over from a previous mod_perl run.
         # Construct a unique key from the connection parameters
         
         $dbpass = "" if (!defined $dbpass);  # fix possible undef

         my $cache_key = ($dbistr .
                          ";username=".($dbuser || "") .
                          ";password=".($dbpass));
         
         if ($global_dbh_cache{$cache_key})
         {
            #print STDERR "reuse cached dbh for key $cache_key\n";
            $self->{dbh} = $global_dbh_cache{$cache_key};
         }
         else
         {
            #print STDERR "open new dbh as key $cache_key\n";
            $self->{dbh} = DBI->connect($dbistr, $dbuser, $dbpass,
                                        {autocommit => 0, 
                                         RaiseError => !$self->{config}->{dbnonfatal}});
            if (!$self->{dbh})
            {
               if (!$self->{config}->{dbnonfatal})
               {
                  $self->error("Failed to connect to the database: " . 
                               ($DBI::errstr || $! || "(unknown error)"));
               }
            }
            $global_dbh_cache{$cache_key} = $self->{dbh};
         }
      }
      $self->{dbhname} = $name;
      $self->applyDBH();
   }
   else
   {
      #print STDERR "reuse existing dbh\n";
   }
   return $self->{dbh};
}

#--------------------------------#

=item addDB NAME, LABEL, DBISTR, USERNAME, PASSWORD

Add a record to the list of available database connections.  The NAME
specified here is what you would pass to getDBH() later.  The LABEL is
used by selectDB(), if necessary, to choose between database options.
If multiple entries with the same NAME and LABEL are entered, only the
last one is remembered.

=cut

sub addDB
{
   my $self = shift;
   my $name = shift;
   my $label = shift;
   my $dbistr = shift;
   my $user = shift;
   my $pass = shift;

   $self->{dbparams}->{$name} ||= {};  # create if missing
   $self->{dbparams}->{$name}->{$label} = [$dbistr, $user, $pass];
   return $self;
}
#--------------------------------#

=item selectDB DB_PARAMETERS

Given a data structure of possible database connection parameters,
select one to use for the database.  Returns an array with C<dbistr>,
C<dbusername> and C<dbpassword> values, or an empty array on failure.

The incoming data structure is a hash reference where the keys are
labels for the various database connection possibilities and the
values are array references with three elements: dbistr, dbusername
and dbpassword.  For example:

   {
      live     => ["dbi:mysql:database=game",     "gameuser", "gameon"],
      internal => ["dbi:mysql:database=game_int", "gameuser", "gameon"],
      dev      => ["dbi:mysql:database=game_dev", "chris", "pass"],
   }

This default implementation simply picks the first key in alphabetical
order.  Subclasses will almost certainly want to override this method.
For example:

   sub selectDB {
      my ($self, $params) = @_;
      if ($self->getCGI()->url() =~ m,/dev/, && $params->{dev}) {
         return @{$params->{dev}};
      } elsif ($self->getCGI()->url() =~ /internal/ && $params->{internal}) {
         return @{$params->{internal}};
      } elsif ($params->{live}) {
         return @{$params->{live}};
      }
      return ();
   }

=cut

sub selectDB
{
   my $self = shift;
   my $params = shift;

   # Find the first key alphabetically, if any
   my $key = (sort keys %$params)[0];
   if ($key)
   {
      return @{$params->{$key}};
   }
   return ();
}

#--------------------------------#

=item applyDBH

Tell other packages to use this new DBH object.  This method is called
from init() and getDBH() as needed.  This contacts the following
modules, if they are already loaded: 
CAM::Session, CAM::SQLManager, and CAM::Template::Cache.

=cut

sub applyDBH
{
   my $self = shift;

   my $dbh = $self->{dbh};
   CAM::Session->setDBH($dbh)         if ($CAM::Session::VERSION);
   CAM::SQLManager->setDBH($dbh)      if ($CAM::SQLManager::VERSION);
   CAM::Template::Cache->setDBH($dbh) if ($CAM::Template::Cache::VERSION);
}
#--------------------------------#

=item getSession

Return a CAM::Session object for this application.  If one has not yet
been created, make one now.  Note!  This must be called before the CGI
header is printed, if at all.

To use a class other than CAM::Session, set the C<sessionclass> config
variable.

=cut

sub getSession
{
   my $self = shift;
   my $dbname = shift;

   if (!exists $self->{session})
   {
      my $class = $self->{config}->{sessionclass};
      if (!$self->loadModule($class))
      {
         $self->error("Internal error: Failed to load the $class library");
      }

      if ($self->{config}->{cookiename})
      {
         $class->setCookieName($self->{config}->{cookiename});
      }
      if ($self->{config}->{sessiontable})
      {
         $class->setTableName($self->{config}->{sessiontable});
      }
      if ($self->{config}->{sessiontime})
      {
         $class->setExpiration($self->{config}->{sessiontime});
      }
      if (!$class->getDBH())
      {
         if (!$self->getDBH($dbname))
         {
            $self->error("No database connection, so a session could not be recorded");
         }
         $class->setDBH($self->getDBH($dbname));
      }
      $self->{session} = $class->new();
   }
   return $self->{session};
}
#--------------------------------#

=item getTemplate FILE, [KEY => VALUE, KEY => VALUE, ...]

Creates, prefills and returns a CAM::Template object.  The FILE should
be the template filename relative to the template directory specified
in the Config file.

See the prefillTemplate() method to see which key-value pairs are
preset.

=cut

sub getTemplate {
   my $self = shift;
   my $file = shift;

   return $self->_template("CAM::Template", $file, undef, @_);
}
#--------------------------------#

=item getTemplateCache CACHEKEY, FILE, [KEY => VALUE, KEY => VALUE, ...]

Creates, prefills and returns a CAM::Template::Cache object.  The
CACHEKEY should be the unique string that identifies the filled
template in the database cache.

=cut

sub getTemplateCache {
   my $self = shift;
   my $key = shift;
   my $file = shift;

   return $self->_template("CAM::Template::Cache", $file, $key, @_);
}
#--------------------------------#

=item getEmailTemplate FILE, [KEY => VALUE, KEY => VALUE, ...]

Creates, prefills and returns a CAM::EmailTemplate object.  This is
very similar to the getTemplate() method.

If the 'mailhost' config variable is set, this instead uses
CAM::EmailTemplate::SMTP.

=cut

sub getEmailTemplate {
   my $self = shift;
   my $file = shift;

   my $module = "CAM::EmailTemplate";
   if ($self->{config}->{mailhost})
   {
      $module = "CAM::EmailTemplate::SMTP";
      if (!$self->loadModule($module))
      {
         $self->error("Internal error: Failed to load the $module library" .
                      ( $self->{load_error} ? "($$self{load_error})" : "" ));
      }
      CAM::EmailTemplate::SMTP->setHost($self->{config}->{mailhost});
   }
   return $self->_template($module, $file, undef, @_);
}
#--------------------------------#

=item getPkgTemplate PKG, FILE, [KEY => VALUE, KEY => VALUE, ...]

Creates, prefills and returns a template instance of the specified
class.  That class should have a similar API to CAM::Template.  For
example:

    my $tmpl = $app->getPkgTemplate("CAM::PDFTemplate", "tmpl.pdf");
    ...
    $tmpl->print();

=cut

sub getPkgTemplate
{
   my $self = shift;
   my $templatePkg = shift;
   my $file = shift;

   return $self->_template($templatePkg, $file, undef, @_);
}
#--------------------------------#
# Internal function:
# builds, fills and returns a template object

sub _template {
   my $self = shift;
   my $module = shift || "CAM::Template";
   my $file = shift;
   my $key = shift;

   if (!$self->loadModule($module))
   {
      $self->error("Internal error: Failed to load the $module library")
          unless ($self->{in_error});
   }

   my $template;
   if ($key)
   {
      # This is a ::Cache template
      $template = $module->new($key, $self->getDBH());
   }
   else
   {
      # This is a normal template
      $template = $module->new();
   }

   if (defined $file)
   {
      my $dir = $self->{config}->{templatedir} || "";
      if (defined $dir)
      {
         $dir =~ s,[/\\]$,,; # trim trailing sep char
      }
      if (!$template->setFilename(defined $dir && $dir ne "" ? File::Spec->catfile($dir, $file) : $file))
      {
         $self->error("Internal error: problem locating the web page template")
             unless ($self->{in_error});
      }
   }
   $self->prefillTemplate($template, @_);

   return $template;
}
#--------------------------------#

=item prefillTemplate TEMPLATE, [KEY => VALUE, KEY => VALUE, ...]

This fills the search-and-replace list of a template with typical
values (like the base URL, the URL of the script, etc.  Usually, it is
just called from withing getTemplate() and related methods, but if you
build your own templates you may want to use this explicitly.

The following value are set (and the order is significant, since later
keys can override earlier ones):

   - the configuration variables, including:
      - myURL => URL of the current script
      - fullURL => URL of the current page, including CGI parameters and target
      - cgiurl => URL of the directory containing the current script
      - cgidir => directory containing the current script
      - many others...
   - mod_perl => boolean indicating whether the script is in mod_perl mode
   - anything passed as arguments to this method

Subclasses may override this to add more fields to the template.  We
recommend implementing override methods like this:

    sub prefillTemplate {
      my $self = shift;
      my $template = shift;
      
      $self->SUPER::prefillTemplate($template);
      $template->addParams(
                           myparam => myvalue,
                           # any other key-value pairs or hashes ...
                           @_,  # add this LAST to override any earlier params
                           );
      return $self;
    }

=cut

sub prefillTemplate
{
   my $self = shift;
   my $template = shift;

   if (!$template->setParams(

                             # you MUST update the documentation above
                             # if you change anything in this list!!!

                             %{$self->{config}},
                             mod_perl => (exists $ENV{MOD_PERL}),
                             @_,
                             ))
   {
      $self->error("Internal error: problem setting template parameters")
          unless ($self->{in_error});
   }
   return $self;
}
#--------------------------------#

=item addStatusMessage MESSAGE

This is a handy repository for non-fatal status messages accumulated
by the application.  [Fatal messages can be handled by the error()
method] Applications who use this mechanism frequently may wish to
override prefillTemplate to set something like:

    status => join("<br>", $app->getStatusMessages())

so in template HTML you could, for example, display this via

    <style> .status { color: red } </style>
    ...
    ??status??<div class="status">::status::</div>??status??

=cut

sub addStatusMessage
{
   my $self = shift;
   push @{$self->{status}}, join("", @_);
   return $self;
}
#--------------------------------#

=item getStatusMessages

Returns the array of messages that had been accumulated by the
application via the addStatusMessage() method.

=cut

sub getStatusMessages
{
   my $self = shift;
   return @{$self->{status}};
}
#--------------------------------#

=item clearStatusMessages

Clears the array of messages that had been accumulated by the
application via the addStatusMessage() method.

=cut

sub clearStatusMessages
{
   my $self = shift;
   $self->{status} = [];
   return $self;
}
#--------------------------------#

=item error MSG

Prints an error message to the browser and exits.

If the 'error_template' configuration parameter is set, then that
template is used to display the error.  In that case, the error
message will be substituted into the ::error:: template variable.

For the sake of your error template HTML layout, use these guidelines:

   1) error messages do not end with puncuation
   2) error messages might be multiline (with <br> tags, for example)
   3) this function prepares the message for HTML display 
      (like escaping "<" and ">" for example).

=cut

sub error {
   my $self = shift;
   my $msg = shift;

   if ($self->{cgi})
   {
      $msg = $self->{cgi}->escapeHTML($msg);
      $msg =~ s/\n/<br>\n/gs;
   }
   else
   {
      $msg = "<pre>$msg</pre>";
   }

   if ($self->{in_error})
   {
      die "Error function called too many times";
   }
   $self->{in_error} = 1;  # Flag so we don't call error() recursively

   print $self->header();
   my $tmplFilename = $self->{config}->{error_template};
   my $errTmpl;

   if ($tmplFilename)
   {
      $errTmpl = $self->getTemplate($tmplFilename, error => $msg);
   }

   if (!$errTmpl)
   {
      print $msg,"\n";
   }
   else
   {
      $errTmpl->print();
   }

   confess if ($self->{dying});
   delete $self->{in_error};
   exit;
}
#--------------------------------#

=item loadModule MODULE

Load a perl module, returning a boolean indicating success or failure.
Shortcuts are taken if the module is already loaded, or loading has
previously failed.  This can be called as either a class or an
instance method.  If called on an instance, any error messages are
stored in $self->{load_error}.

=cut

sub loadModule {
   my $pkg_or_self = shift;
   my $module = shift;

   # Get a reference to the module VERSION and ISA variables
   my $ver_ref = eval "\\\$${module}::VERSION";
   my $isa_ref = eval "\\\@${module}::ISA";
   delete $pkg_or_self->{load_error} if (ref $pkg_or_self);  # clear if it was previously set
   unless (defined($$ver_ref) || @$isa_ref > 0)
   {
      local $SIG{__WARN__} = 'DEFAULT';
      local $SIG{__DIE__} = 'DEFAULT';
      eval "use $module;";
      if ($@ || (!defined $$ver_ref && @$isa_ref == 0))
      {
         $pkg_or_self->{load_error} = "$@" if (ref($pkg_or_self) && $@);
         # Set the version to a false-but-defined value to prevent re-eval
         $$ver_ref = 0;
      }
   }
   # Note: this is deliberately not "defined $$ver_ref" unlike above
   return $$ver_ref || @$isa_ref;
}
#--------------------------------#

=item DESTROY

Override this method to perform any final cleanup when the application
run ends.  You can use this, perhaps, to do an logging or
benchmarking.  For example:

    package MyApp;
    use CAM::App;
    our @ISA = qw(CAM::App);
    
    sub new {
       my $pkg = shift;
       my $start = time();
       my $self = $pkg->SUPER::new(@_);
       $self->{start_time} = $start;
       return $self;
    }
    sub DESTROY {
       my $self = shift;
       my $elapsed = time() - $self->{start_time};
       print STDERR "elapsed time: $elapsed seconds\n";
       $self->SUPER::DESTROY();
    }

=cut

sub DESTROY
{
   # do nothing special, just here to silence warnings, and to let
   # subclasses override
}

1;
__END__

=back

=head1 AUTHOR

Clotho Advanced Media Inc., I<cpan@clotho.com>

Primary developer: Chris Dolan
