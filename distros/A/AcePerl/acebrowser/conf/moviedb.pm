use Ace::Browser::LocalSiteDefs '$HTML_PATH';

# ========= DIRECTORIES =========
# base of all our scripts
#$ROOT = '/movies';
$ROOT = '/cgi-bin/ace';

# base of our html files
$DOCROOT = '/ace';

# base of our icons
$ICONS = "$DOCROOT/ico";

# base of our images
$IMAGES = "$DOCROOT/images";

# ========= $HOST  =========
# name of the host to connect to
$HOST = 'stein.cshl.org';

# ========= $PORT  =========
# Port number to connect to
$PORT = 200008;

# ========= $STYLESHEET =========
# stylesheet to use
$STYLESHEET = "$DOCROOT/stylesheets/moviedb.css";

# ========= $PICTURES ==========
# Where to write temporary picture files to:
#   The URL and the physical location, which must be writable
# by the web server.  This is meaningless under Apache::Modperl.
# Otherwise the value is determined by Makefile.PL
@PICTURES = ($IMAGES => "$HTML_PATH/images");

# ========= @SEARCHES  =========
# search scripts available
# NOTE: the order is important
@SEARCHES   = (
	       text => {
			name   => 'Text Search',
			url    =>"$ROOT/searches/text",
		       },
	       browser => {
			   name => 'Class Browser',
			   url  => "$ROOT/searches/browser",
			  },
	       query => {
			 name => 'Acedb Query',
			 url  => "$ROOT/searches/query",
			 },
	       );
$SEARCH_ICON = "$ICONS/unknown.gif";

# ========= %HOME  =========
# Home page URL
@HOME      = (
	      $DOCROOT => 'Home Page'
	     );

# ========= %DISPLAYS =========
# displays to show
%DISPLAYS = (
	     movie => {
		 url   => "$ROOT/moviedb/movie",
		 label => 'Movie Report',
		 },

	     person => {
		 url   => "$ROOT/moviedb/person",
		 label => 'Person Profile',
		 },

	     tree => { 
		 'url'     => "generic/tree",
		 'label'   => 'Tree Display',
		 },
	     pic => { 
		 'url'     => "generic/pic",
		 'label'   => 'Graphic Display',
		    },
	     xml => {
		 'url'     => "generic/xml",
		 'label'   => 'XML Display',
		    },
	    );

# ========= %CLASSES =========
# displays to show
%CLASSES = (
	    Person => ['person'],
	    Movie  => ['movie'],
	    # default is a special "dummy" class to fall back on
	    Default => [ qw/tree xml pic/ ],
	    );

# ========= &URL_MAPPER  =========
# mapping from object type to URL.  Return empty list to fall through
# to default.
sub URL_MAPPER {
  my ($display,$name,$class) = @_;
  return;
}

# ========= $BANNER =========
# Banner HTML
# This will appear at the top of each page. 
$BANNER = <<END;
<center><span class=banner><font size=+3>Movie Database (Test)</font></span></center><p>
END

# ========= PRIVACY STATEMENT
$PRINT_PRIVACY_STATEMENT = 1;

# ========= FEEDBACK STATEMENT
@FEEDBACK_RECIPIENTS = (
			[ " $ENV{SERVER_ADMIN}", 'general complaints and suggestions', 1 ]
);

# ========= $FOOTER =========
# Footer HTML
# This will appear at the bottom of each page
$FOOTER = '';

# configuration for the "basic" seqarch script
@BASIC_OBJECTS = 
  ('Any'       =>   '<i>Anything</i>',
   'Movie'     =>   'Movie Title',
   'Person'    =>   'Person (author/actor/director)',
   'Director'  =>   'Director',
   'Author'    =>   'Author',
   'Actor'     =>   'Actor',
   'Book'      =>   'Book');
1;
