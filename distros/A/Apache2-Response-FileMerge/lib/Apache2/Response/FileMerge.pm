package Apache2::Response::FileMerge;

use strict;
use warnings;

use HTTP::Date;
use APR::Table           ();
use URI::Escape          ();
use Apache2::RequestUtil ();
use Apache2::Log         ();
use Apache2::RequestRec  ();
use Apache2::RequestIO   ();
use Apache2::Const       -compile => qw( OK HTTP_NOT_MODIFIED NOT_FOUND ); 

use constant {

    # http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html
    LAST_MODIFIED         => 'Last-Modified',
    MODIFIED_SINCE        => 'If-Modified-Since',
    LAST_MODIFIED_PATTERN => '%a, %b %e %Y %H:%M:%S PST',
    COMMENT_PATTERN       => '/* %s */',

    # Actions that can be manipulated from httpd.conf and mod_perl's
    # PerlSetVar pragma
    DIR_ACTIONS           => [ qw(
        minimize        cache            compress          stats
        document_root   file_seperator   append_inc_name  
    ) ],

    # What, in theory, the stats should look like when statistics are enabled
    STATS_PATTERN         => '
/*
         URI: %s
       mtime: %s
       Cache: %s
   Minify JS: %s
  Minify CSS: %s
   Separator: %s
    Compress: %s
   Doc. Root: %s
      Append: %s
      Render: %s
*/
%s',
};

BEGIN {
    our $VERSION = join( '.', 1, map{ sprintf( '%03d', $_ - 18 ) } ( '$Revision: 123 $' =~ /(\d+)/g ) );
};

my ( $i, $x )       = ( 0, 0 );
my $ua              = undef;
my $LOG             = undef;
my $DO_MIN_JS       = 0;
my $DO_MIN_CSS      = 0;
my $DO_MODIFIED     = 0;
my $DO_COMPRESS     = 0;
my $DO_STATS        = 0;
my $APPEND_INC_NAME = 0;
my $SEPARATOR       = '~';
my $DOC_ROOT        = '';
my %CONTENT_TYPES   = ( 'js'=> 'text/javascript', 'css' => 'text/css', );
my %VARS;


{
    my %cache;
    my $mtime = 0;
    sub handler {
        my ($r) = @_;
        _init($r);
        $LOG    = $r->log();
        my $uri = $r->uri();

        # Undocumented as it's not the most efficient way of doing
        # things, but still here if/when needed (ie. unit tests)
        __PACKAGE__->$_(
            $r->dir_config->get($_)
        ) for (
            grep{
                $r->dir_config->get($_)
            } @{ DIR_ACTIONS() }
        );

        my $start = _time();

        if ( $DO_MODIFIED ) {
            if ( my $modified = $r->headers_in()->{MODIFIED_SINCE()} ) {
                # Sat, Dec 20 2008 4:48:03

                return Apache2::Const::HTTP_NOT_MODIFIED if (
                    $cache{$uri}{'mtime'}
                    && $cache{$uri}{'mtime'} <= str2time( $modified )
                );
            }
        }

        my $content = '';
        my $type    = '';

        my ( $location, $file );
        ( $location, $file, $type ) = $uri =~ /^(.*)\/(.*)\.(js|css)$/;
        my $root                    = $DOC_ROOT || $r->document_root();

        _substitute_vars( \$location, \$file ) if ( %VARS );

        foreach my $input ( split( $SEPARATOR, $file ) ) {
            $input     =~ s/\./\//g;
            $content  .= ( _load_content( $root, $location, $input, $type ) || '' );
        }

        my $has_content = ! ! $content;
        
        {
            no strict 'refs';
            $content  = &{ "_minimize_$type" }( 'input' => $content ) if ( $DO_MIN_JS || $DO_MIN_CSS );
        }

        my $delta = _time() - $start;
        $content  = sprintf(
            STATS_PATTERN,
            $uri,
            $mtime,
            $DO_MODIFIED,
            $DO_MIN_JS,
            $DO_MIN_CSS,
            $SEPARATOR,
            $DO_COMPRESS,
            $DOC_ROOT,
            $APPEND_INC_NAME,
            $delta,
            $content
        ) if ( $DO_STATS );

        $r->content_type( $CONTENT_TYPES{$type} || 'text/plain' );
        my $headers                 = $r->headers_out();
        $headers->{LAST_MODIFIED()} = time2str($mtime);
        $cache{$uri}{'mtime'}       = $mtime;

        if ( $DO_COMPRESS ) {
            $r->content_encoding('gzip');
            $content = _compress($content);
        }

        $r->print($content);

        return ( $has_content ) ? Apache2::Const::OK 
                                : Apache2::Const::NOT_FOUND;
    }

    {
        my %loaded;

        sub _init {
            my( $r ) = @_;

            %loaded  = ();
            %VARS    = map {
                my( $k, $v ) = split(/=/);
                $k => URI::Escape::uri_unescape( ( $v || '' ) )
            } split( /[&;]/, $r->args() );
        }

        sub _load_content {
            my ( $root, $location, $file_name, $type ) = @_;
            return unless ( $file_name );

            _substitute_vars( \$location, \$file_name ) if ( %VARS );

            $LOG->debug( "\$location = $location" );
            $location =~ s/\/$//g;
            $location = "$location/";
            $LOG->debug( "\$location = $location" );

            $file_name       =  "${location}${file_name}" if ( $location );
            $file_name       =  "$root/$file_name.$type";
            my $cname        =  $file_name;
            $cname           =~ s/\///g;
            my $this_mtime   =  ( stat($file_name) )[9];
            $mtime         ||= 0;
            $mtime           =  $this_mtime if ( ! $mtime || $mtime > ( $this_mtime || 0 ) );
            my $content      =  '';

            if ( exists( $loaded{$cname} ) ) {
                $LOG->debug("Attempting to include \"$file_name\" more than once");
                return;
            }
            else {
                $loaded{$cname} = \0;
                $LOG->debug("Loading: $file_name");        
            }

            if ( open( my $handle, '<', $file_name ) ) {
                {
                    local $/ = undef;
                    $content = <$handle>;
                }
                close( $handle );
            }
            else {
                $LOG->error("File not found: \"$file_name\".");
                return;
            }

            $content = _sf_escape($content);
            while ( $content =~ /(\/\\\*\\\*\s*[Ii]nc(?:lude)\s*([-\{\}\w\.\/]+)\s*\\\*\\\*\/)/sgm ) {
                my ( $matcher, $file )      =  ( $1, $2 );
                my ( $inc_file, $inc_type ) =  $file =~ /^(.*?)\.(js|css)$/;
                my $new_file_content        =  _load_content( $root, '', $inc_file, $inc_type ) || '';
                $new_file_content           = sprintf( COMMENT_PATTERN, "$root/$inc_file" ) 
                                                . "\n\n$new_file_content" if ( $APPEND_INC_NAME );
                $content                    =~ s/\/\\\*\\\*\s*[Ii]nc(?:lude)\s*[-\{\}\w\.\/]+\s*\\\*\\\*\//$new_file_content/sm;
            }

            return _sf_unescape($content);
        }

        sub _substitute_vars {
            foreach my $string ( @_ ) {
                while( $$string =~ /\{\s*([\w-]+)\s*\}/g ) {
                    my $varname = $1;
                    next unless defined $VARS{$varname};
                    $$string =~ s/\{\s*$varname\s*\}/$VARS{$varname}/g;
                }
            }
        }
    }
}

sub append_inc_name {
    return $APPEND_INC_NAME = pop;
}

sub document_root {
    return $DOC_ROOT = pop;
}

sub file_separator {
    return $SEPARATOR = pop;
}

sub cache {
    return $DO_MODIFIED ||= ! ! 1;
}

sub stats {
    $DO_STATS = ! ! 1;

    $DO_STATS = _register_function(
        'Time::HiRes',
        '_time',
        \&Time::HiRes::time
    );

    return $DO_STATS;
}

sub minimize {
    $DO_MIN_JS  = ! ! 1;
    $DO_MIN_CSS = ! ! 1;

    $DO_MIN_JS = _register_function(
        'JavaScript::Minifier',
        '_minimize_js',
        \&JavaScript::Minifier::minify
    );

    $DO_MIN_CSS = _register_function(
        'CSS::Minifier',
        '_minimize_css',
        \&CSS::Minifier::minify
    );

    return $DO_MIN_JS || $DO_MIN_CSS;
}

sub compress {
    $DO_COMPRESS = ! ! 1;

    $DO_COMPRESS = _register_function(
        'Compress::Zlib',
        '_compress',
        \&Compress::Zlib::memGzip
    );

    return $DO_COMPRESS;
}

sub _sf_escape {
    my ($escaper) = @_; 
    $escaper =~ s/\*/\\*/g;
    return $escaper;
}

sub _sf_unescape {
    my ($escaper) = @_;
    $escaper =~ s/\\\*/\*/g;
    return $escaper;
}

sub _register_function {
    my ( $class, $func, $ref ) = @_;

    eval {
        eval("use $class ();");
        if ( my $e = $@ ) {
            print STDERR "\"$class\" not installed, cannot use\n";
            return ! ! 0;
        }
        else {
            {
                no strict 'refs';
                no warnings 'redefine';
                *{$func} = $ref;
            }
            return ! ! 1;
        }
    }
}

sub _minimize_js  { return pop; }
sub _minimize_css { return pop; }
sub _compress($)  { return pop; }
sub _time()       { return 0;   }

1;

__END__

=head1 NAME

Apache2::Response::FileMerge - Easily merge JavaScript and CSS into a single file dynamically. 

=head1 SYNOPSIS

L<Apache2::Response::FileMerge> gives you the ability to merge, include, minimize
and compress multiple JavaScript and CSS files into a single file (respective of type)
to place anywhere into an HTML document.  All handled by an easy to configure mod_perl
Response handler with absolutely no alteration needed for existing JavaScript or CSS.

=head1 DESCRIPTION

=head2 Problem(s) Solved

There are a number of best practices on how to generate content into a web page.
Yahoo!, for example, publishes such a document (http://developer.yahoo.com/performance/rules.html)
and is relatively well respected as it contains a number of good and useful tips 
for high-performance sites along with sites that are less strained but are still
trying to conserve the resources they have.  The basis of this module will contribute
to the resolution of three of these points and one that is not documented there.

=head2 File Merging

A common problem with the standard development of sites is the number of <script/>,
<style/> and other static file includes that may/must be made in a single page.
Each requiring time, connections... overhead.  Although this isn't a revolutionary
solution, it is in terms of simple mod_perl handlers that can easily be integrated
into a single site.  Look to 'URI PROTOCOL' to see how this module will let you
programaticlly merge multiple files into a single file, allowing you to drop from
'n' <s(?:cript|style)> tags to a single file (per respective type).

=head2 File Minimization

A feature that can be administered programatically (see ATTRIBUTES), will minimize
whitespace usage for all CSS/Javascript files that leave the server.

=head2 File Compression

A feature that can be administered programatically (see ATTRIBUTES), will gzip 
the content before leaving the server.  Now, I can't ever imagine the need to
apply compression to a style or script file without wanting to apply it to /all/
content.  That said, I recommend the use of mod_gzip (L<http://sourceforge.net/projects/mod-gzip/>) 
rather than this attribute.  Still, I wanted to implement it, so I did.

=head2 C-Style Inlcudes

Merging files through a URI protocol is useful, however if you have a large-scale
application written in javascript, you quickly introduce namespacing, class
heirarchies and countless dependancies and files.  That said, it's tough to ask
a developer "List all the dependancies this class has, taking each of it's 
super-classes and encapsualted heirarchies into consideration".  Most modern
languages take care of this by allowing the developer to include it's particular
dependancies in the application code in it's particular file.  That said, this
module lets you do the same thing with CSS and Javascript.

As an example:

    /**
     * foo/bar.js
     * @inherits foo.js
     **/

     // Rather tha including foo.js as it's required by foo/bar.js,
     // simply include it directly in the file with the following
     // syntax:

     /** Include foo.js **/
     Foo.Bar = {};
     Foo.Bar.prototype = Foo;

Where, with that example, the file 'foo.js' will be a physical replacement
of the include statement and therefore will no longer need to be added to 
the URI.

=head1 ATTRIBUTES

=head2 cache

    Apache2::Response::FileMerge->cache();

Will enable HTTP 304 return codes, respecting the If-Modified-Since
keyword and therefore preventing the overhead of scraping through 
files again.

Given the nature of the module, the mtime of the requested document
will be the newest mtime of all the combined documents.

Furthermore, the server will only find the mtime of a collection of
documents when it reads the disk for the content.  Therfore, when 
enabled, any changes to the underlying files will also require
a reload/graceful of the server to pick up the changes and discontinue
the 304 return for the particular URI.

=head2 stats

    Apache2::Response::FileMerge->stats();

Will include statictics (pre-minimization) in a valid comment section
at the top of the document.  Something like the following can be expected:

    /*
             URI: /js/foo.bar-bar.baz.js
           mtime: 1229843477
           Cache: 1
        Minimize: 0
        Compress: 0
          Render: 0.0628039836883545
    */

=head2 minimize
    
    Apache2::Response::FileMerge->minimize();

Will use <JavaScript::Minifier> to minimize the Javascript and
L<CSS::Minifier> to minimize CSS, if installed.

=head2 compress 

    Apache2::Response::FileMerge->compress();

Will use <Compress::Zlib> to compress the document, if installed.

=head2 file_separator

    # Will change the separator from '~' to '-'
    Apache2::Response::FileMerge->file_separator('-');

Will change the default file separator from '~' to any character you choose.
The default is '~' as defined in the URI PROTOCOL section.

=head2 document_root
    
    Apache2::Response::FileMerge->document_root('/var/www/custom-docroot');

Will change the module's relative document root from the servers default
and defined root to that of any string passed to the attribute.

=head2 append_inc_name 

Will append each inclucded file name, as a comment, into the included file.
The intent is only to find a file that needs attention within the merged
document with a little more ease.  A nice feature when developing swarths
of JS/CSS code.

Where, for example, if the handler merged 'foo/bar.js' and 'foo/bar/baz.js', 
the output would look similar to the following (when enabled, default off):

    /* foo/bar.js */
    Foo.Bar = function(){}();

    /* foo/bar/baz.js */
    Foo.Bar.Baz = function(){}();

=head1 EXAMPLES

=head2 httpd.conf

If all you want is the URI protocol and C-style includes, 
this is all you have to do:

    # httpd.conf
    <LocationMatch "\.js$">
        SetHandler perl-script
        PerlResponseHandler Apache2::Response::FileMerge
    </LocationMatch>

=head2 C-Style includes

This can be applied to either CSS or JS at any point in your document.
The moduel will implicitly trust the developer and therefore must be
syntaxually correct in all cases.  The handler will inject the code
of the included file into it's literal location.

The include will be respective of the DocumentRoot of the server.

Note the double-asterisks ('**') comment to indicate the include.

The 'Include' keyword is required (but can be replaced with 'Inc' if
you're lazy like me).

    /** Include foo/bar/baz.js **/

    /** Include foo/bar/baz.css **/

In all cases, the intent is that any file that is consumed by this module
can also be rendered and executed without this module, which is the point
behind the commented include structure.

=head2 URI Protocol

The URI will also allow you to include files.  The URI will include files
in the exact order they are listed, from left to right.  Furthermore, if a
URI that is requested is already included in a dependant file, the handler
will only include the first instance of the file (which will generally be
the first Include point).

The URI will be respective of directory location relative to the 
DocumentRoot.

'.' implies directory traversal.

'~' implies file separation (Default, see ATTRIBUTES).

    # File foo/bar.js will be loaded, which is in the '/js/' directory
    http://...com/js/foo.bar.js

    # Will do the same as above, but makes less sense IMHO
    http://...com/js.foo.bar.js

    # File foo/bar.js will be loaded, which is in the document root
    http://...com/foo.bar.js

    # Will include foo.js and foo/bar.js respectively
    http://...com/foo-foo.bar.js

=head2 File Name Variable Substitution

File names, both in the url, and in the C-style includes, are subject
to possible variable-substitution.  Any parameters in the url's query
string will be checked as variables in file names.  All variables must
be prefixed with "{" and suffixed with "}"; no spaces allowed (don't ask).
For example: 

    { var } // Doesn't work
    [ var ] // Doesn't work
    [var]   // Doesn't work
    {var}   // Works!

Further examples:

    http://www.example.com/foo.bar~baz.qux.js?var=example

    # Later, in foo/bar.js:
    /** Include languages/{var}/foobar_text.js **/

    # Resolves to:
    /** Include languages/example/foobar_text.js **/

=head1 URI PROTOCOL

The generall usefulness of the advanced URI protocol is to combine 
files that are seemingly not dependant upon one another.  See
the EXAMPLES section for more details on this.

=head1 TROUBLESHOOTING AND COMMON ISSUES

=item1 File name too large errors

There is a common barrier with Apache (v1+, v2+) servers (also others, 
though Apache is the most susceptible) where you will be served a 
Forbidden page rather than the requested JS/CSS source when a file
name grows larger than 256 characters.  When combining multiple files
with deep relative path locations, this is an easy threshold to cross.
A work-around to this issue is by using variable substitution to
put the file-name as a query string parameter rather than the file name,
where the total lenght of a URI isn't limited as tightly as the file name
itself.

For example:

    http://yourdomain.com/js/dir.dir2.dir<.. 256 characters later>.dirn.file.js

Can be altered to:

    http://yourdomain.com/{file}/?file=js/dir.dir2.dir<.. 256 characters later>.dirn.file.js


The big, big caveat being that the current implementation of this module
will only process varaibles once and in a single-dimension.  Therefore, if you
are troubleshooting a URL that already utilizes variable substitution, such as:

    http://yourdomain.com/js/{lang}.dir.dir2.dir<.. 256 characters later>.dirn.file.js?lang=en

And you attempt to convert it to:

    http://yourdomain.com/{file}/?file=js/{lang}.dir.dir2.dir<.. 256 characters later>.dirn.file.js&lang=en

The "lang" variable will not be substitued as it lies within the querystring rather than the path.  For
these cases, we recommend you put the secondary variable substitution into an "Include" rather than 
the path, which should be sufficient in most cases.


=head1 KNOWN ISSUES

=over

=item mod_perl v1.x

This will only work as a mod_perl 2.x PerlResponseHandler.  If there
is demand for 1.x, I will take the time to dynamically figure out 
what the right moduels, API, etc to use will be.  For now, being that
/I/ only use mod_perl 2.x, I have decided to not be overly clumsy 
with the code to take into consideration a platform people may not use.

=item CPAN shell installation

The unit tests each require L<Apache::Test> to run.  Yet, there are a
lot of conditions that would prevent you from actually having mod_perl
installed on a system of which you are trying to install this module.
Although I don't really see the need or think it's good practice to
install Apache2 namespaced modules without mod_perl, I have not made
Apache::Test a prerequisite of this module for the case I mentioned
earlier.  That said, no unit tests will pass without mod_perl already
installed and therefore will require a force install if that is what
you would like.  If that method is preferred, it is always possible
to re-test the module via the CPAN shell once mod_perl is installed.

At the time of this writing, L<Apache::Test> is included with the
mod_perl 2.x distribution.

=back

=head1 SEE ALSO

=over

=item L<Compress::Zlib>

=item L<JavaScript::Minifier>

=item L<CSS::Minifier>

=back

=head1 AUTHORS

=item Trevor Hall, E<lt>wazzuteke@cpan.orgE<gt>

Original author and maintainer.

=item Romuald Brunet

Generously submitted a patch adopting HTTP::Date to support
POSIX locales and standard international date formats; particularly
useful for file-modification based caching.

=item Stephen Howard (L<http://search.cpan.org/~howars/>)

Submitted concept and patches for file/dir name substituion. 

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


