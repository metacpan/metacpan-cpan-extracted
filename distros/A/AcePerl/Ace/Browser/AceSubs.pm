package Ace::Browser::AceSubs;

=head1 NAME

Ace::Browser::AceSubs - Subroutines for AceBrowser

=head1 SYNOPSIS

  use Ace;
  use Ace::Browser::AceSubs;
  use CGI qw(:standard);
  use CGI::Cookie;

  my $obj = GetAceObject() || AceNotFound();
  PrintTop($obj);
  print $obj->asHTML;
  PrintBottom();

=head1 DESCRIPTION

Ace::Browser::AceSubs exports a set of routines that are useful for
creating search pages and displays for AceBrowser CGI pages. See
http://stein.cshl.org/AcePerl/AceBrowser.

The following subroutines are exported by default:

  AceError
  AceMissing
  AceNotFound
  Configuration
  DoRedirect
  GetAceObject
  Object2URL
  ObjectLink
  OpenDatabase
  PrintTop
  PrintBottom
  Url

The following subroutines are exported if explicitly requested:

  AceAddCookie
  AceInit
  AceHeader
  AceMultipleChoices
  AceRedirect
  DB_Name
  Footer
  Header
  ResolveUrl
  Style
  Toggle
  TypeSelector

To load the default subroutines load the module with:

   use Ace::Browser::AceSubs;

To bring in a set of optionally routines, load the module with:

   use Ace::Browser::AceSubs qw(AceInit AceRedirect);

To bring in all the default subroutines, plus some of the optional
ones:

   use Ace::Browser::AceSubs qw(:DEFAULT AceInit AceRedirect);

There are two main types of AceBrowser scripts:

=over 4

=item display scripts

These are called with the CGI parameters b<name> and b<class>,
corresponding to the name and class of an AceDB object to display.
The subroutine GetAceObject() will return the requested object, or
undef if the object does not exist.

To retrieve the parameters, use the CGI.pm param() method:

  $name  = param('name');
  $class = param('class');


=item search scripts

These are not called with any CGI parameters on their first
invocation, but can define their own parameter lists by creating
fill-out forms.  The AceBrowser system remembers the last search
performed by a search script in a cookie and regenerates the CGI
parameters the next time the user selects that search script.

=back

=head1 SUBROUTINES

The following sections describe the exported subroutines.

=over 4

=cut

use strict;
use Ace::Browser::SiteDefs;
use Ace 1.76;
use CGI qw(:standard escape);
use CGI::Cookie;
use File::Path 'mkpath';

use vars qw/@ISA @EXPORT @EXPORT_OK $VERSION %EXPORT_TAGS 
  %DB %OPEN $HEADER $TOP @COOKIES
  $APACHE_CONF/;

require Exporter;
@ISA = qw(Exporter);
$VERSION = 1.21;

######################### This is the list of exported subroutines #######################
@EXPORT = qw(
	     GetAceObject AceError AceNotFound AceMissing DoRedirect
	     OpenDatabase Object2URL Url
	     ObjectLink Configuration PrintTop PrintBottom);
@EXPORT_OK = qw(AceRedirect Toggle ResolveUrl AceInit AceAddCookie
		AceHeader TypeSelector Style AcePicRoot
		Header Footer DB_Name AceMultipleChoices);
%EXPORT_TAGS = ( );

use constant DEFAULT_DATABASE  => 'default';
use constant PRIVACY           => 'misc/privacy';  # privacy/cookie statement
use constant SEARCH_BROWSE     => 'search';   # a fallback search script
my %VALID;  # cache for get_symbolic() lookups

=item AceError($message)

This subroutine will print out an error message and exit the script.
The text of the message is taken from $message.

=cut

sub AceError {
    my $msg = shift;
    PrintTop(undef,undef,'Error');
    print CGI::font({-color=>'red'},$msg);
    PrintBottom();
    Apache->exit(0) if defined &Apache::exit;
    exit(0);
}

=item AceHeader()

This function prints the HTTP header and issues a number of cookies
used for maintaining AceBrowser state.  It is not exported by default.

=cut

=item AceAddCookie(@cookies)

This subroutine, which must be called b<after> OpenDatabase() and/or
GetAceObject() and b<before> PrintTop(), will add one or more cookies
to the outgoing HTTP headers that are emitted by AceHeader().  
Cookies must be CGI::Cookie objects.

=cut

sub AceAddCookie {
   push @COOKIES,@_;  # add caller's to our globals
}

################## canned header ############
sub AceHeader {

  my %searches = map {$_=>1} Configuration()->searches;
  my $quovadis = url(-relative=>1);

  my $db = get_symbolic();

  my $referer  = referer();
  $referer =~ s!^http://[^/]+!! if defined $referer;
  my $home = Configuration()->Home->[0] if Configuration()->Home;

  if ($referer && $home && index($referer,$home) >= 0) {
    my $bookmark = cookie(
			  -name=>"HOME_${db}",
			  -value=>$referer,
			  -path=>'/');
    push(@COOKIES,$bookmark);
  }

  if ($searches{$quovadis}) {
    Delete('Go');
    my $search_name = "SEARCH_${db}_${quovadis}";
    my $search_data = cookie(-name  => $search_name,
			     -value => query_string(),
			     -path=>'/',
			    );
    my $last_search = cookie(-name=>"ACEDB_$db",
			     -value=>$quovadis,
			     -path=>'/');
    push(@COOKIES,$search_data,$last_search);
  }

  print @COOKIES ? header(-cookie=>\@COOKIES,@_) : header(@_);

  @COOKIES = ();
  $HEADER++;
}

=item AceInit()

This subroutine initializes the AcePerl connection to the configured
database.  If the database cannot be opened, it generates an error
message and exits.  This subroutine is not exported by default, but is 
called by PrintTop() and Header() internally.

=cut

# Subroutines used by all scripts.
# Will generate an HTTP 'document not found' error if you try to get an 
# undefined database name.  Check the return code from this function and
# return immediately if not true (actually, not needed because we exit).
sub AceInit   {
  $HEADER   = 0;
  $TOP      = 0;
  @COOKIES  = ();

  # keeps track of what sections should be open
  %OPEN = param('open') ? map {$_ => 1} split(' ',param('open')) : () ;

  return 1 if Configuration();

  # if we get here, it is a big NOT FOUND error
  print header(-status=>'404 Not Found',-type=>'text/html');
  $HEADER++;
  print start_html(-title => 'Database Not Found',
		   -style => Ace::Browser::SiteDefs->getConfig(DEFAULT_DATABASE)->Style,
		  ),
        h1('Database not found'),
        p('The requested database',i(get_symbolic()),'is not recognized',
	  'by this server.');
  print p('Please return to the',a({-href=>referer()},'referring page.')) if referer();
  print end_html;
  Apache::exit(0) if defined &Apache::exit;  # bug out of here!
  exit(0);
}

=item AceMissing([$class,$name])

This subroutine will print out an error message indicating that an
object is present in AceDB, but that the information the user
requested is absent. It will then exit the script. This is
infrequently encountered when following XREFed objects. If the class
and name of the object are not provided as arguments, they are taken
from CGI's param() function.

=cut

sub AceMissing {
    my ($class,$name) = @_;
    $class ||= param('class');
    $name  ||= param('name');
    PrintTop(undef,undef,$name);
    print strong('There is no further information about this object in the database.');
    PrintBottom();
    Apache->exit(0) if defined &Apache::exit;
    exit(0);
}

=item AceMultipleChoices($symbol,$report,$objects)

This function is called when a search has recovered multiple objects
and the user must make a choice among them.  The user is presented
with an ordered list of the objects, and asked to click on one of
them.

The three arguements are:

   $symbol   The keyword or query string the user was searching
             on, undef if none.

   $report   The symbolic name of the current display, or undef
	     if none.

   $objects  An array reference containing the Ace objects in
	     question.

This subroutine is not exported by default.

=cut

sub AceMultipleChoices {
  my ($symbol,$report,$objects) = @_;
  if ($objects && @$objects == 1) {
    my $destination = Object2URL($objects->[0]);
    AceHeader(-Refresh => "1; URL=$destination");
    print start_html (
			   '-Title' => 'Redirect',
			   '-Style' => Style(),
			),
      h1('Redirect'),
      p("Automatically transforming this query into a request for corresponding object",
	ObjectLink($objects->[0],$objects->[0]->class.':'.$objects->[0])),
      p("Please wait..."),
      Footer(),
      end_html();
    return;
  }
  PrintTop(undef,undef,'Multiple Choices');
  print
    p("Multiple $report objects correspond to $symbol.",
      "Please choose one:"),
    ol(
       li([
	   map {ObjectLink($_,font({-color=>'red'},$_->class).': '.$_)} @$objects
	  ])
	    );
  PrintBottom();
}

=item AceNotFound([$class,$name])

This subroutine will print out an error message indicating that the
requested object is not present in AceDB, even as a name. It will then
exit the script. If the class and name of the object are not provided
as arguments, they are taken from CGI's param() function.

=cut

sub AceNotFound {
  my $class = shift || param('class');
  my $name  = shift || param('name');
  PrintTop(undef,undef,"$class: $name not found");
  print p(font({-color => 'red'},
	       strong("The $class named \"$name\" is not found in the database.")));
  PrintBottom();
  Apache->exit(0) if defined &Apache::exit;
  exit(0);
}

=item ($uri,$physical_path) = AcePicRoot($directory)

This function returns the physical and URL paths of a temporary
directory in which the pic script can write pictures.  Not exported by
default.  Returns a two-element list containing the URL and physical
path.

=cut

sub AcePicRoot {
  my $path = shift;
  my $umask = umask();
  umask 002;  # want this writable by group
  my ($picroot,$uri);
  if ($ENV{MOD_PERL} && Apache->can('request')) { # we have apache, so no reason not to take advantage of it
    my $r = Apache->request;
    $uri  = join('/',Configuration()->Pictures->[0],"/",$path);
    my $subr = $r->lookup_uri($uri);
    $picroot = $subr->filename if $subr;
  } else {
    ($uri,$picroot) = @{Configuration()->Pictures} if Configuration()->Pictures;
    $uri     .= "/$path";
    $picroot .= "/$path";
  }
  mkpath ($picroot,0,0777) || AceError("Can't create directory to store image in") unless -d $picroot;
  umask $umask;
  return ($uri,$picroot);
}


=item AceRedirect($report,$object)

This function redirects the user to a named display script for viewing 
an Ace object.  It is used, for example, to convert a request for a
sequence into a request for a protein:

  $obj = GetAceObject();
  if ($obj->CDS) {
    my $protein	= $obj->Corresponding_protein;
    AceRedirect('protein',$protein);
  }

AceRedirect must be called b<before> PrintTop() or  AceHeader().  It
invokes exit(), so it will not return.

This subroutine is not exported by default.  It differs from
DoRedirect() in that it displays a message to the user for two seconds
before it generates the new page. It also allows the display to be set
explicitly, rather than determined automatically by the AceBrowser
system.

=cut

###############  redirect to a different report #####################
sub AceRedirect {
  my ($report,$object) = @_;

  my $url = Configuration()->display($report,'url');

  my $args = ref($object) ? "name=$object&class=".$object->class
                          : "name=$object";
  my $destination = ResolveUrl($url => $args);
  AceHeader(-Refresh => "1; URL=$destination");
  print start_html (
			 '-Title' => 'Redirect',
			 '-Style' => Style(),
		         '-head'  => meta({-http_equiv=>'Refresh',-content=>"1; URL=$destination"})
			),
    h1('Redirect'),
    p("This request is being redirected to the \U$report\E display"),
    p("This page will automatically display the requested object in",
	   "one seconds",a({-href=>$destination},'Click on this link'),
	'to load the page immediately.'),
    end_html();
    Apache->exit(0) if defined &Apache::exit;
    exit(0);
}

=item $configuration = Configuration()

The Configuration() function returns the Ace::Browser::SiteDefs object
for the current session.  From this object you can retrieve
information from the configuration file.

=cut

# get the configuration object for this database
sub Configuration {
  my $s = get_symbolic()||return;
  return Ace::Browser::SiteDefs->getConfig($s);
}

=item $name = DB_Name()

This function returns the symbolic name of the current database, for
example "default".

=cut

*DB_Name = \&get_symbolic;

=item DoRedirect($object)

This subroutine immediately redirects to the default display for the
Ace::Object indicated by $object and exits the script.  It must be
called before PrintTop() or any other HTML-generating code.  It
differs from AceRedirect() in that it generates a fast redirect
without alerting the user.

This function is not exported by default.

=cut

# redirect to the URL responsible for an object
sub DoRedirect {
    my $obj = shift;
    print redirect(Object2URL($obj));
    Apache->exit(0) if defined &Apache::exit;
    exit(0);
}

=item $footer = Footer()

This function returns the contents of the footer as a string, but does 
not print it out.  It is not exported by default.

=cut

# Contents of the HTML footer.  It gets printed immediately before the </BODY> tag.
# The one given here generates a link to the "feedback" page, as well as to the
# privacy statement.  You may or may not want these features.
sub Footer {
  if (my $footer = Configuration()->Footer) {
    return $footer;
  }
  my $webmaster = $ENV{SERVER_ADMIN} || 'webmaster@sanger.ac.uk';

  my $obj_name =  escape(param('name'));
  my $obj_class = escape(param('class')) || ucfirst url(-relative=>1);
  my $referer   = escape(self_url());
  my $name      = get_symbolic();

  # set up the feedback link
  my $feedback_link = Configuration()->Feedback_recipients &&
      $obj_name &&
	  (url(-relative=>1) ne 'feedback') ?
    a({-href=>ResolveUrl("misc/feedback/$name","name=$obj_name;class=$obj_class;referer=$referer")},
      "Click here to send data or comments to the maintainers")
      : '';

  # set up the privacy statement link
  my $privacy_link = ( Configuration()->Print_privacy_statement &&
		       url(-relative=>1) ne PRIVACY()) 
    ?
      a({ -href=>ResolveUrl(PRIVACY."/$name") },'Privacy Statement')
	: '';

  my ($home,$label) = @{Configuration()->Home};
  my $hlink = $home ? a({-href=>$home},$label) : '';

  # Either generate a pointer to ACeDB home page, or the copyright statement.
  my $clink = Configuration()->Copyright ? a({-href=>Configuration()->Copyright,-target=>"_new"},'Copyright Statement')
                                       : qq(<A HREF="http://stein.cshl.org/AcePerl">AcePerl Home Page</A>);


  return <<END;
<TABLE WIDTH="100%" BORDER=0 CELLPADDING=0 CELLSPACING=0>
<TR CLASS="technicalinfo">
    <TD  CLASS="small" VALIGN="TOP">
    $hlink<br>$clink
    </TD>
    <TD  CLASS="small" ALIGN=RIGHT VALIGN=TOP><p><strong>$feedback_link</strong><br>
    $privacy_link<br>
    <A HREF="mailto:$webmaster"><address>$webmaster</address></A><br>
    </TD>
</TR>
</TABLE>
END
}

=item $object = GetAceObject()

This function is called by display scripts to return the
Ace::Object.that the user wishes to view.  It automatically opens or
refreshes the database, and performs the request using the values of the
"name" and "class" CGI variables.

If a single object is found, the function returns it as the function
result.  If no objects are found, it returns undef.  If more than one
object is found, the function invokes AceMultipleChoices() and exits
the script.

=cut

# open database, return object requested by CGI parameters
sub GetAceObject {
  my $db = OpenDatabase() ||  AceError("Couldn't open database."); # exits
  my $name  = param('name') or return;
  my $class = param('class') or return;
  my @objs = $db->fetch($class => $name);
  if (@objs > 1) {
    AceMultipleChoices($name,'',\@objs);
    Apache->exit(0) if defined &Apache::exit;
    exit(0);
  }
  return $objs[0];
}

=item $html = Header()

This subroutine returns the boilerplate at the top of the HTML page as 
a string, but does not print it out.  It is not exported by default.

=cut

sub Header {
  my $config = Configuration();
  my $dbname = get_symbolic();

  return unless my $searches = $config->Searches;
  my $banner                 = $config->Banner;

  # next select the correct search script
  my @searches = @{$searches};
  my $self = url(-relative=>1);
  my $modperl = $ENV{MOD_PERL} && Apache->can('request') && eval {Apache->request->dir_config('AceBrowserConf')};
  my @row;
  foreach (@searches) {
    my ($name,$url,$on,$off,$size) = @{$config->searches($_)}{qw/name url onimage
								offimage size/};
    my $active = $url =~ /\b$self\b/;
    my $image = $active ? $on : $off;

    # replace the url with a cookie, if one is defined
    my $cookie_name = "SEARCH_${dbname}_${_}";
    my $query_string = cookie($cookie_name) unless /blast/;
    $url .= "/$dbname" unless $url =~ /\b$dbname\b/ or $modperl;
    $url .= "?$query_string" if $query_string;

    if ($image) {
    push @row,a({-href=>$url},img({-src=>$image,-border=>0,
				   -width=>$size->[0],-height=>$size->[1],
				   -alt=>$name}));

  } else {
    push @row,$active ? font({-color=>'black'},$name) : a({-href=>$url,-class=>'searchbanner'},$name);
  }
  }

  my ($home,$label) = @{$config->Home} if $config->Home;

  return table({-border=>0,-cellspacing=>1,-width=>'100%'},
	       Tr(td({-align=>'CENTER',-class=>'searchbanner'},\@row)),
	       Tr(td({-align=>'CENTER',-valign=>'BOTTOM',colspan=>scalar(@row)},
		     a({-href=>$home},$banner))
		 )
	      );
}

=item $url = Object2URL($object)

=item $url = Object2URL($name,$class)

In its single-argument form, this function takes an AceDB Object and
returns an AceBrowser URL.  The URL chosen is determined by the
configuration settings.

It is also possible to pass Object2URL an object name and class, in
the case that an AceDB object isn't available.

The return value is a URL.

=cut

# general mapping from a display to a url
sub Object2URL {
    my ($object,$extra) = @_;
    my ($name,$class);
    if (ref($object)) {
	($name,$class) = ($object,$object->class);
    } else {
	($name,$class) = ($object,$extra);
    }
    my $display = url(-relative=>1);
    my ($disp,$parameters) = Configuration()->map_url($display,$name,$class);
    return $disp unless $parameters;
    return Url($disp,$parameters);
}

=item $link = ObjectLink($object [,$link_text])

This function converts an AceDB object into a hypertext link.  The
first argument is an Ace::Object.  The second, optional argument is
the text to use for the link.  If not provided, the object's name
becomes the link text.

This function is used extensively to create cross references between
Ace::Objects on AceBrowser pages.

Example:

  my $author = $db->fetch(Author => 'Sulston JE');
  print ObjectLink($author,$author->Full_name);

This will print out a link to a page that will display details on the
author page.  The text of the link will be the value of the Full_name
tag.

=cut

sub ObjectLink {
  my $object     = shift;
  my $link_text  = shift;
  my $target     = shift;
  my $url = Object2URL($object,@_) or return ($link_text || "$object");
  my @targ = $target ? (-target=>$target) : ();
  return a({-href=>Object2URL($object,@_),-name=>"$object",@targ},($link_text || "$object"));
}

=item $db = OpenDatabase()

This function opens the Acedb database designated by the configuration
file.  In modperl environments, this function caches database handles
and reuses them, pinging and reopening them in the case of timeouts.

This function is not exported by default.

=cut

use Carp 'cluck';

################ open a database #################
sub OpenDatabase {
  my $name = shift || get_symbolic();
  AceInit();
  $name =~ s!/$!!;
  my $db = $DB{$name};
  return $db if $db && $db->ping;

  my ($host,$port,$user,$password,
      $cache_root,$cache_size,$cache_expires,$auto_purge_interval)
    = getDatabasePorts($name);
  my @auth  = (-user=>$user,-pass=>$password) if $user && $password;
  my @cache = (-cache => { cache_root=>$cache_root,
			   max_size            => $cache_size || $Cache::SizeAwareCache::NO_MAX_SIZE || -1,  # hardcoded $NO_MAX_SIZE constant
			   default_expires_in  => $cache_expires       || '1 day',
			   auto_purge_interval => $auto_purge_interval || '6 hours',
			 } 
	      ) if $cache_root;
  $DB{$name} = Ace->connect(-host=>$host,-port=>$port,-timeout=>50,@auth,@cache);
  return $DB{$name};
}

=item PrintTop($object,$class,$title,@html_headers)

The PrintTop() function generates all the boilerplate at the top of a
typical AceBrowser page, including the HTTP header information, the
page title, the navigation bar for searches, the web site banner, the
type selector for choosing alternative displays, and a level-one
header.

Call it with one or more arguments.  The arguments are:

  $object    An AceDB object.  The navigation bar and title will be
	     customized for the object.

  $class     If no AceDB object is available, then you can pass 
	     a string containing the AceDB class that this page is
	     designed to display.

  $title     A title to use for the HTML page and the first level-one
	     header.  If not provided, a generic title "Report for
	     Object" is generated.

  @html_headers  Additional HTML headers to pass to the the CGI.pm
             start_html. 
	

=cut

# boilerplate for the top of the page
sub PrintTop {
  my ($object,$class,$title,@additional_header_stuff) = @_;
  return if $TOP++;
  $class = $object->class if defined $object && ref($object);
  $class ||= param('class') unless defined($title);
  AceHeader();
  $title ||= defined($object) ? "$class Report for: $object" : $class ? "$class Report" : ''
    unless defined($title);
  print start_html (
                    '-Title'   => $title,
                    '-Style'   => Style(),
                    @additional_header_stuff,
                    );
  print Header();
  print TypeSelector($object,$class) if defined $object;
  print h1($title) if $title;
}

=item PrintBottom()

The PrintBottom() function outputs all the boilerplate at the bottom
of a typical AceBrowser page.  If a user-defined footer is present in
the configuration file, that is printed.  Otherwise, the method prints 
a horizontal rule followed by links to the site home page, the AcePerl 
home page, the privacy policy, and the feedback page.

=cut

sub PrintBottom {
  print hr,Footer(),end_html();
}


=item $hashref = Style()

This subroutine returns a hashref containing a reference to the
configured stylesheet, in the following format:

  { -src => '/ace/stylesheets/current_stylesheet.css' }

This hash is suitable for passing to the -style argument of CGI.pm's
start_html() function, or for use as an additional header in
PrintTop().  You may add locally-defined stylesheet elements to the
hash before calling start_html().  See the pic script for an example
of how this is done this.

This function is not exported by default.

=cut

=item $url = ResolveUrl($url,$param)

Given a URL and a set of parameters, this function does the necessary
magic to add the symbolic database name to the end of the URL (if
needed) and then tack the parameters onto the end.

A typical call is:

  $url = ResolveUrl('/cgi-bin/ace/generic/tree','name=fred;class=Author');

This function is not exported by default.

=cut

sub ResolveUrl {
    my ($url,$param) = @_;
    my ($main,$query,$frag) = $url =~ /^([^?\#]+)\??([^\#]*)\#?(.*)$/ if defined $url;
    $main ||= '';
    
    if (!defined $APACHE_CONF) {
      $APACHE_CONF = eval { Apache->request->dir_config('AceBrowserConf') } ? 1 : 0;
    }

    $main = Configuration()->resolvePath($main) unless $main =~ m!^/!;
    if (my $id = get_symbolic()) {
      $main .= "/$id" unless $main =~ /$id/ or $APACHE_CONF;
    }

    $main .= "?$query" if $query; # put the query string back
    $main .= "?$param" if $param and !$query;
    $main .= ";$param" if $param and  $query;
    $main .= "#$frag" if $frag;
    return $main;
}

# A consistent stylesheet across pages
sub Style {
    my $stylesheet = Configuration()->Stylesheet;
    return { -src => $stylesheet };
}

=item $boolean = Toggle($section,[$label,$object_count,$add_plural,$add_count])

=item ($link,$bool) = Toggle($section,$label,$object_count,$add_plural,$add_count)

The Toggle() subroutine makes it easy to create HTML sections that
open and close when the user selects a toggle icon (a yellow
triangle).

Toggle() can be used to manage multiple collapsible HTML sections, but
each section must have a unique name.  The required first argument is
the section name.  Optional arguments are:

  $label         The text of the generated link, for example "sequence"

  $object_count  The number of objects that opening the section will reveal

  $add_plural    If true, the label will be pluralized when
		 appropriate

  $add_count	 If true, the label will have the object count added
		 when appropriate

In a scalar context, Toggle() prints the link HTML and returns a
boolean flag.  A true result indicates that the section is expanded
and should be generated.  A false result indicates that the section is 
collapsed.

In a list context, Toggle() returns a two-element list.  The first
element is the HTML link that expands and contracts the section.  The
second element is a boolean that indicates whether the section is
currently open or closed.

This example indicates typical usage:

  my $sequence = GetAceObject();
  print "sequence name = ",$sequence,"\n";
  print "sequence clone = ",$sequence->Clone,"\n";
  if (Toggle('dna','Sequence DNA')) {
      print $sequence->asDNA;
  }

An alternative way to do the same thing:

  my $sequence = GetAceObject();
  print "sequence name = ",$sequence,"\n";
  print "sequence clone = ",$sequence->Clone,"\n";
  my ($link,$open) = Toggle('dna','Sequence DNA');
  print $link;
  print $sequence->asDNA if $open;

=cut

# Toggle a subsection open and close
sub Toggle {
    my ($section,$label,$count,$addplural,$addcount,$max_open) = @_;
    $OPEN{$section}++ if defined($max_open) && $count <= $max_open;

    my %open = %OPEN;
    $label ||= $section;
    my $img;
    if (exists $open{$section}) {
	delete $open{$section};
	$img =  img({-src=>'/ico/triangle_down.gif',-alt=>'^',
			-height=>6,-width=>11,-border=>0}),
    } else {
	$open{$section}++;
	$img =  img({-src=>'/ico/triangle_right.gif',-alt=>'&gt;',
			-height=>11,-width=>6,-border=>0}),
	my $plural = ($addplural and $label !~ /s$/) ? "${label}s" : "$label";
	$label = font({-class=>'toggle'},!$addcount ? $plural : "$count $plural");
    }
    param(-name=>'open',-value=>join(' ',keys %open));
    my $url = url(-absolute=>1,-path_info=>1,-query=>1);

    my $link = a({-href=>"$url#$section",-name=>$section},$img.'&nbsp;'.$label);
    if (wantarray ){
      return ($link,$OPEN{$section})
    } else {
      print $link,br;
      return $OPEN{$section};
    }
}

=item $html = TypeSelector($name,$class)

This subroutine generates the HTML for the type selector navigation
bar.  The links in the bar are dynamically generated based on the
values of $name and $class.  This function is called by PrintTop().
It is not exported by default.

=cut

# Choose a set of displayers based on the type.
sub TypeSelector {
    my ($name,$class) = @_;
    return unless $class;

    my ($n,$c) = (escape("$name"),escape($class));
    my @rows;

    # add the special displays
    my @displays       = Configuration()->class2displays($class,$name);
    my @basic_displays = Configuration()->class2displays('default');
    @basic_displays    = Ace::Browser::SiteDefs->getConfig(DEFAULT_DATABASE)->class2displays('default') 
      unless @basic_displays;

    my $display = url(-absolute=>1,-path=>1);

    foreach (@displays,@basic_displays) {
 	my ($url,$icon,$label) = @{$_}{qw/url icon label/};
	next unless $url;
	my $u = ResolveUrl($url,"name=$n;class=$c");
	($url = $u) =~ s/[?\#].*$//;

	my $active = $url =~ /^$display/;
	my $cell;
	unless ($active) {
	  $cell = defined $icon ? a({-href=>$u,-target=>'_top'},
				    img({-src=>$icon,-border=>0}).br().$label)
				: a({-href=>$u,-target=>'_top'},$label);
	} else {
	  $cell = defined $icon ? img({-src=>$icon,-border=>0}).br().font({-color=>'red'},$label)
				: font({-color=>'red'},$label);
	}
	  push (@rows,td({-align=>'CENTER',-class=>'small'},$cell));
	}
    return table({-width=>'100%',-border=>0,-class=>'searchtitle'},
		 TR({-valign=>'bottom'},@rows));
}

=item $url = Url($display,$params)

Given a symbolic display name, such as "tree" and a set of parameters, 
this function looks up its URL and then calls ResolveUrl() to create a 
single Url.

When hard-coding relative URLs into AceBrowser scripts, it is
important to pass them through Url().  The reason for this is that
AceBrowser may need to attach the database name to the URL in order to
identify it.

Example:

  my $url = Url('../sequence_dump',"name=$name;long_dump=yes");
  print a({-href=>$url},'Dump this sequence');

=cut

sub Url {
  my ($display,$parameters) = @_;
  my $url = Configuration()->display($display,'url');
  return ResolveUrl($url,$parameters);
}


sub Open_table{
print '<table width=660>
<tr>
<td>';
}

sub Close_table{
print '</tr>
</td>
</table>';
}


# return host and port for symbolic database name
sub getDatabasePorts {
  my $name = shift;
  my $config = Ace::Browser::SiteDefs->getConfig($name);
  return ($config->Host,$config->Port,
	  $config->Username,$config->Password,
	  $config->Cacheroot,$config->Cachesize,$config->Cacheexpires,$config->Cachepurge,
	 ) if $config;

  # If we get here, then try getservbynam()
  # I think this is a bit of legacy code.
  my @s = getservbyname($name,'tcp');
  return unless @s;
  return unless $s[2]>1024;  # don't allow connections to reserved ports
  return ('localhost',$s[2]);
}

sub get_symbolic {

  if (exists $ENV{MOD_PERL} && Apache->can('request')) {  # the easy way
    if (my $r = Apache->request) {
      if (my $conf = $r->dir_config('AceBrowserConf')) {
	my ($name) = $conf =~ m!([^/]+)\.(?:pm|conf)$!;
	return $name if $name;
      }
    }
  }

  # otherwise, the hard way
  (my $name = path_info())=~s!^/!!;
  return $name if defined $name && $name ne '';  # get from additional path info
  my $path = url(-absolute=>1);
  return $VALID{$path} if exists $VALID{$path};
  my @path = split '/',$path;
  pop @path;
  for my $name ((reverse @path),'default') {
    next unless $name;
    return $VALID{$path} if exists $VALID{$name};
    return $VALID{$path} = $name if Ace::Browser::SiteDefs->getConfig($name);
    $VALID{$path} = undef;
  }
  return;
}

1;
__END__

=back

=head1 BUGS

Please report them.

=head1 SEE ALSO

L<Ace::Object>, L<Ace::Browser::SiteDefs>, L<Ace::Browsr::SearchSubs>,
the README.ACEBROWSER file.

=head1 AUTHOR

Lincoln Stein <lstein@cshl.org>.

Copyright (c) 2001 Cold Spring Harbor Laboratory

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  See DISCLAIMER.txt for
disclaimers of warranty.

=cut
