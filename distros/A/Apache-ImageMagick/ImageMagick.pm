
##--------------------------------------------------------------------------
##
##  Copyright (c) 2002 Gerald Richter / ecos gmbh www.ecos.de
##  parts (c) Lincoln Stein & Doug MacEachern
##
##  You may distribute under the terms of either the GNU General Public 
##  License or the Artistic License, as specified in the Perl README file.
## 
##  THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED 
##  WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF 
##  MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
##
##  $Id: ImageMagick.pm,v 1.13 2002/09/20 08:07:51 richter Exp $
##
##--------------------------------------------------------------------------


package Apache::ImageMagick ;


use strict;
use vars qw{$VERSION %scriptmtime %scriptsub $packnum $debug} ;

use Image::Magick ();
use File::Basename qw(fileparse);
use DirHandle ();
use Digest::MD5 ;
use Text::ParseWords ;

$VERSION = '2.0b7' ;

# define constants here instead of use Apache::Constants qw(:common);to remove dependency
use constant OK => 0 ;
use constant NOT_FOUND => 404 ;
use constant SERVER_ERROR => 500 ;
use constant DECLINED => -1 ;

$packnum = 1 ;
$debug = 0 ;


my %LegalArguments = map { $_ => 1 } 
qw (antialias adjoin authenticate
    background blue-primary bordercolor 
    cache-threshold colormap colorspace compression
    debug delay density depth dispose dither display
    endian
    filename file fill font fuzz 
    gravity green-primary
    index iterations interlace
    loop 
    magick mattecolor matte monochrome
    page pen pixel pointsize preview
    quality 
    red_primary render 
    sampling-factor scene subimage subrange server size stroke
    tile texture type 
    unit
    verbose
    white-primary
    );

my %LegalFilters = map { $_ => 1 } 
qw(Annotate AddNoise Blur Border Charcoal Chop
   Contrast Crop ColorFloodfill Colorize Comment CycleColormap
   Despeckle Draw Edge Emboss Enhance Equalize Flip Flop
   Frame Gamma Implode Label Layer Magnify Map Minify
   MatteFloodfill MedianFilter Modulate MotionBlur
   Modulate Negate Normalize OilPaint Opaque Quantize
   Raise ReduceNoise Roll Rotate Resize Sample Scale Segment Shade
   Sharpen Shave Shear Signature Stereo Solarize Spread Swirl Texture Transparent
   Threshold Trim Wave UnsharpMask Zoom);

my %QueryFilters = map { $_ => 1 } 
qw(QueryFormat QueryFont QueryColor) ;



my %Attributes = map { $_ => 1 } 
qw(
adjoin
antialias
background
blue-primary
bordercolor
cache-threshold
colormap
colorspace
compression
delay
density
dispose
dither
display
file
filename
font
fuzz
green-primary
index
interlace
iterations
loop
magick
matte
mattecolor
monochrome
page
pixel
pointsize
preview
quality
red-primary
rendering-intent
scene
subimage
subrange
server
size
tile
texture
type
units
verbose
white-point
Image
base-columns
base-filename
base-rows
class
colors
comment
columns
depth
directory
error
filesize
format
gamma
geometry
height
label
maximum-error
mean-error
montage
rows
signature
taint
width
x-resolution
y-resolution) ;

# ---------------------------------------------------------------------------
#
#   find a image with the same base name, but of different type
#

sub find_image 
    {
    my ($r, $directory, $base) = @_;
    my $dh = DirHandle->new($directory) or return;

    my $source;
    for my $entry ($dh->read) 
        {
  	my $candidate = fileparse($entry, '\.\w+');
  	if ($base eq $candidate || $base eq $entry) 
            {
  	    # determine whether this is an image file
	    $source = join '', $directory, $entry;
  	    my $subr = $r->lookup_file($source);
  	    last if $subr->content_type =~ m:^image/:;
	    $source = "";
  	    }
        }
    $dh->close;
    return $source;
    }


# ---------------------------------------------------------------------------
#
#   compile, cache and execute external script
#


sub execute_script

    {
    my ($script, $r, $image, $filter, $args) = @_ ;

    return 1 if (!-r $script) ;

    my $package ;
    my $sub ;

    if ($scriptmtime{$script} != -M _)
        { # load and compile script
        $r -> log_error ("Apache::ImageMagick: Compile $script") if ($debug) ;
        my $content ;
        {
        local $/ = undef ;
        open FH, $script or do { $r -> log_error ("Apache::ImageMagick: Cannot open script $script ($!)") ; return undef ; } ;
        $content = <FH> ;
        close FH ;
        }
        $package = "Apache::ImageMagick::_$packnum" ;
        $packnum++ ;
        my $code = join("\n", "package $package ;",
                              '\sub {', "#line 1 \"$script\"",
                              $content, ';} ;') ;
        $sub = eval $code ;
        if ($@) 
            {
            $r -> log_error ("Apache::ImageMagick: $@") ; 
            return undef ;
            }
         
        $scriptmtime{$script} = -M _ ;
        $scriptsub{$script} = $sub ;
        }
    else
        {
        $sub = $scriptsub{$script} ;
        }
    
    $r -> log_error ("Apache::ImageMagick: Call $script") if ($debug) ;
    my $rc = eval { &{$$sub}($r, $image, $filter, $args) ; } ;
    if ($@) 
        {
        $r -> log_error ("Apache::ImageMagick: $@") ; 
        return undef ;
        }
    if (!$rc) 
        {
        $r -> log_error ("Apache::ImageMagick: Script $script doesn't returned true") ; 
        return undef ;
        }
    return $rc ;
    }



# ---------------------------------------------------------------------------
#
#   Fixup handler
#


sub handler 
    {
    my $r = shift;
    my $useiofile = shift  ;    

    my $args = $r -> args ;
    my $path_info = $r -> path_info ;

    # If the file exists and there are no transformation arguments
    # just decline the transaction.  It will be handled as usual.
    return OK if ((!$args && !$path_info) || -d $r -> finfo) ;

    # calculate name of cache file
    my $file = $r->filename;
    my $uri  = $r -> uri ;
    my $md5  = Digest::MD5::md5_hex($uri . $args) ;
    $file =~ /.*\.(.*?)$/;
    my $ext = $1 ;
    my $cachefn = "$md5.$ext" ;
    my $cachedir  = $r -> dir_config ("AIMCacheDir") || '.' ;
    my $cachepath = "$cachedir/$cachefn" ;
    my $checkmtime = $r -> dir_config ("AIMCheckMTime") || 0 ;
    $checkmtime = 0 if (lc($checkmtime) eq 'off') ;
    
    if (!$checkmtime && -r $cachepath)
        { # let apache do the rest if image already exists
        $r -> filename ($cachepath) ;
        $r -> path_info ('') ;
        return OK ;
        }


    my $srcdir      = $r -> dir_config ("AIMSourceDir") ;
    my $stripprefix = $r -> dir_config ("AIMStripPrefix") ;
    my $scriptdir   = $r -> dir_config ("AIMScriptDir") ;
    my $scriptdef   = $r -> dir_config ("AIMScriptDefault") ;
    my $scriptext   = $r -> dir_config ("AIMScriptExt") || 'pl' ;
    my $cache       = $r -> dir_config ("AIMCache") || 1 ;
    my $param       = $r -> dir_config ("AIMParameter")  ;
    my $disablesearch = $r -> dir_config ("AIMDisableSearch") || 0 ;
    $debug       = $r -> dir_config ("AIMDebug") || 0 ;
    $cache = 0 if (lc($cache) eq 'off') ;
    $debug = 0 if (lc($debug) eq 'off') ;
    $disablesearch = 0 if (lc($disablesearch) eq 'off') ;


    if ($debug)
        {
        $r -> log_error ("Apache::ImageMagick: AIMCacheDir      = $cachedir") ;
        $r -> log_error ("Apache::ImageMagick: AIMSourceDir     = $srcdir") ;
        $r -> log_error ("Apache::ImageMagick: AIMStripPrefix   = $stripprefix") ;
        $r -> log_error ("Apache::ImageMagick: AIMScriptDir     = $scriptdir") ;
        $r -> log_error ("Apache::ImageMagick: AIMScriptDefault = $scriptdef") ;
        $r -> log_error ("Apache::ImageMagick: AIMScriptExt     = $scriptext") ;
        $r -> log_error ("Apache::ImageMagick: AIMCache         = $cache") ;
        $r -> log_error ("Apache::ImageMagick: AIMParameter     = $param")  ;
        $r -> log_error ("Apache::ImageMagick: AIMCheckMTime    = $checkmtime") ;
        $r -> log_error ("Apache::ImageMagick: AIMDisableSearch = $disablesearch") ;
        }

    my $script ;
    my $basefile ;
    my $source ;
    my ($base, $directory, $extension) = fileparse($file, '\.\w+'); 

    if ($stripprefix) 
        {
        $file =~ /$stripprefix(.*?)^/ ;
        $basefile = $1 ;
        }
    else
        {
        $basefile = $base . $extension ;
        }

    $file = "$srcdir/$basefile" if ($srcdir) ;

    # Conversion arguments are kept in the query string, and the
    # image filter operations are kept in the path info
    my (%arguments) = $r->args;
    my @filters     = split '/', $r->path_info ;

    if (-r $file || $arguments{-new}) 
        { # file exists or new, so it becomes the source
  	$source = $file;
        } 
    elsif (!$disablesearch)
        {              # file doesn't exist, so we search for it
  	return DECLINED unless -r $directory;
  	$source = find_image($r, $directory, $base);
        }
    
    unless ($source) 
        {
  	$r->log_error("Apache::ImageMagick: Couldn't find a replacement for $file");
  	return NOT_FOUND;
        }

    if ($checkmtime && -M $file > -M $cachepath && -r _)
        { # let apache do the rest if image already exists and is not new then cache
        $r -> filename ($cachepath) ;
        $r -> path_info ('') ;
        $r -> log_error ("Apache::ImageMagick: Use cached image") if ($debug) ;
        return OK ;
        }


    if ($scriptdir) 
        {
        if ($scriptdir eq '.')
            {
            $script = "$file.$scriptext" ;
            }
        else
            {
            $script = "$scriptdir/$basefile.$scriptext" ;
            }
        }
    

    
    $r -> log_error ("Apache::ImageMagick: Source: $source  Script: $script  Cachefile: $cachepath") if ($debug) ;

    #$r->send_http_header;
    #return OK if $r->header_only;
    


    # Read the image
    my $q = Image::Magick->new;
    my $err ;
    $err = $q->Read($source) if (!$arguments{-new}) ;
    my $errfilter ;

    execute_script ($script, $r, $q, \@filters, \%arguments) or return SERVER_ERROR if ($script) ;
    execute_script ($scriptdef, $r, $q, \@filters, \%arguments)  or return SERVER_ERROR if ($scriptdef) ;

    if ($param)
        {    
	my @arglist = quotewords ('\s+', 0, $param) ;
        foreach (@arglist)
	    {
	    /^(\!)?(.*?)\s*=\s*(.*?)$/ ;
	    if ($1)
                {
                $arguments{$2} = $3 ;
                }
            else
                {
                $arguments{$2} = $3 if (!defined ($arguments{$2})) ;
                }
	    }
        }

    # Run the filters
    foreach my $f (@filters) 
        {
        my $filter = ucfirst $f;  
  	next unless $LegalFilters{$filter};
  	my %args = map { 
                        if (/^-/)
                            {
                            ()
                            }
                        elsif (!(/:/)) 
                            { 
                            ($_ => $arguments{$_}) 
                            } 
                        else 
                            { 
                            if (/^$filter:(.*?)$/i) 
                                { 
                                ($1 => $arguments{$_})  
                                }
                            else
                                {
                                ()
                                }
                            }                                 
                        } keys %arguments ;
        
        if ($debug) 
            {
            $r -> log_error ("Apache::ImageMagick: Filter $filter (", join (',', map { "$_=>$args{$_}" } keys %args), ")") ;
            }
        my $ferr = $q->$filter(%args);
        if ($ferr)
            {
            my @args = %args ;
            $err       ||= $ferr ;
            $errfilter ||= "$filter (@args)" ;
            }
        }

    my($tmpnam, $fh) ;
    if (!$useiofile)
        {
        require Apache::File ;
        if ($cache)
            { # create and open cachefile
            $tmpnam = $cachepath ;
            $fh = Apache::File->new(">$tmpnam");
            }
        else
            {
            # Create a temporary file name to use for conversion
            # The file is automaticly deleted after the request
            ($tmpnam, $fh) = Apache::File->tmpfile;
            $tmpnam ||= 'temporary file' if (!$fh) ;
            }
        }
    else
        {
        require IO::File ;
        if ($cache)
            { # create and open cachefile
            $tmpnam = $cachepath ;
            $fh = IO::File->new(">$tmpnam");
            }
        else
            {
            # Create a temporary file name to use for conversion
            # The file is automaticly deleted after the request
            ($tmpnam, $fh) = IO::File->new_tmpfile;
            $tmpnam ||= 'temporary file' if (!$fh) ;
            }
        }
    
    unless ($fh) 
        {
  	$r->log_error("Apache::ImageMagick: Couldn't open file $tmpnam for writing ($!)");
  	return SERVER_ERROR;
        }

    # Remove invalid arguments before the conversion
    foreach (keys %arguments) 
        { 	
        $arguments{$1} = $arguments{$_} if (/^Set:(.*?)$/i) ;
	delete $arguments{$_} unless $LegalArguments{$_};
        }

    if ($debug) 
        {
        $r -> log_error ("Apache::ImageMagick: Write $tmpnam (", join (',', map { "$_=>$arguments{$_}" } keys %arguments), ")") ;
        }

    # Write out the modified image
    my $werr ;    
    open(OLDOUT, ">&STDOUT");
    open(STDOUT, ">&=" . fileno($fh));
    $werr = $q->Write('filename' => "\U$ext\L:-", %arguments);
    $err ||= $werr ;    
    close $fh;
    open(STDOUT, ">&OLDOUT");
    if ($err) 
        {
  	$r->log_error("Apache::ImageMagick: $errfilter $err");
        if ($err !~ /Warning/) 
            {
            unlink $tmpnam;
            return SERVER_ERROR;
            }
        }
    $r -> filename ($tmpnam) ;
    $r -> path_info ('') ;
        
    return OK;
    }


1;
__END__

=pod

=head1 NAME

Apache::ImageMagick - Convert and manipulate images on the fly

=head1 SYNOPSIS

 In httpd.conf or .htaccess

 <Location /images>
 PerlFixupHandler Apache::ImageMagick
 PerlSetVar AIMCacheDir /var/aimcache
 </Location>   

 Then request

 http://localhost/images/whatever.gif/Annotate?font=Arial&x=5&gravity=west&text=Hello+world+!
 http://localhost/images/whatever.jpg


=head1 DESCRIPTION

This module uses the Image::Magick library to process an image on the fly. 
It is able to convert the source image to any type you request that is supported
by Image::Magick (e.g. TIFF, PPM, PGM, PPB, GIF, JPEG and more). The requested
fileformat is determinated by the fileextention of the request and 
Apache::ImageMagick will search for an image with the same basename and convert it
automaticly (unless you set C<AIMDisableSearch>).
Addtionaly you can specify (multiple) image manipulation filters in the additional path info,
and format options in the query string. All filters applied in the order they apear in
the path info. A list of available filters can be found at 
http://www.imagemagick.org/www/perl.html#mani . As of this writing there are 67 very 
powerfull filters available.
The parameters you give in the URL are passed to all filters. So the URL

 http://localhost/images/whatever.gif/Frame?color=gold

will request the image whatever.gif and apply the filter C<Frame> and pass the parameter
C<color> with the argument C<gold> to it, so you end up with a golden frame around 
that image. Addtionaly you can give all parameters that allowed in the C<Set> method
(see http://www.imagemagick.org/www/perl.html#seta ), for example to set the
quality of your jpeg image you can use

 http://localhost/images/whatever.jpg?quality=10
 
A filter croaks on parameters it doesn't knows, so there is a problem when you give multiple
filters different parameters. To distiguish the parameters for different filters or
to give the same parameter with different values to two filters you can
prefix the parameter name with the filter name separated by a colon:

 http://localhost/images/whatever.gif/Frame/Shade?Frame:color=gold&Shade:color=true

This will again draw a golden frame and will additonaly add a colored shadow.
The parameters for the C<Set> method a prefixed with C<Set:>

 http://localhost/images/whatever.jpg/Frame/Shade?Frame:color=gold&Shade:color=true&Set:quality=10

The C<AIMParameter> configuration diretive can be used to set defaults and/or force
parameters values. So you can say 

 PerlSetVar AIMParameter "font=/usr/images/fonts/arial.ttf !color=red" 

By prefixing the parameter with an !, the parameter values is foreced, so it 
can't be overridden by parameters passed to the hanlder via th URI.

=head2 Caching

Since conversion takes time Apache::ImageMagick caches the result unless you turn
off caching with the C<AIMCache> directive. If a cached image is found 
Apache::ImageMagick does nothing, but let Apache serve it just like a normal image.
To make cacheing work you normaly have to set the directory where to cache files.
This is done with the C<AIMCacheDir> directive. Of course the directoy must be
writeable by your http daemon. If you set addtionaly the C<AIMCheckMTime>
Apache::ImageMagick always check if the source file is newer then the
cached file. 

=head2 Using Scripts to process images

Another powerfull features of Apache::ImageMagick are scripts. These scripts 
are called after the image is loaded and before any processing takes places.
Such a script can modify all parameters or make operations on the image.
There are two possible sorts of scripts. A per image script, the name is build
by appending the extension given by C<AIMScriptExt> to the filename and searched
in the directory given by C<AIMScriptDir>. So if C<AIMScriptDir> is set to
F</usr/images/scripts> and a request for F<whatever.gif> comes in, Apache::ImageMagick
looks for a script named F</usr/images/scripts/whatever.gif.pl>. If the script is
found it is loaded into memory, compiled and executed. If the script is already in
memory, Apache::ImageMagick checks if the scripts is modified and if not it is only
executed, so the Perl code has to be compiled only when the script changes.
If C<AIMScriptDir> is not set, Apache::ImageMagick doesn't search for a per image
script. There is a second sort of script the default one. The full path of this script
is specfied by the C<AIMScriptDefault> directive and is executed after the per image
script was executed. So it is able to force some default values.
Both sort of scripts takes four parameters. The Apache request record, the Image::Magick
object of the loaded image, an arrayref which contains the names of all filters and a
hashref that contains all arguments. You can use the Apache object to retrives any
information about the request. You can make any operation on the image object and you
can modify the filters and arguments parameters. Here is an example that forces any fontname
to be searched in a certain directory with the extention ttf. This actualy causes 
Image::Magick to use true type fonts:


    use constant FONTPATH    => '/usr/images/fonts/' ; 
    use constant FONTDEFAULT => 'arial' ; 

    my ($r, $image, $filters, $args) = @_ ;

    my $font ;
    if ($args->{font})
        {
        $args->{font} =~ m#(^|.*/)([a-zA-z0-9_]+)# ;
        $font = $2 ;
        }
    else
        {
        $font = FONTDEFAULT ;
        }

    $args -> {font} = FONTPATH . $font . '.ttf' ;

    1 ;

=head2 Createing images from scratch

Instead of modifing an existing image you can also create one from the scratch.
You do this by giving the C<-new=1> parameter. In this case Apache::ImageMagick
will not try to read an exiting image form disk, but create an empty one. You 
can use a script to create whatever you like. Here is an example:

In your F<httpd.conf> or F<.htaccess> you should set at least the cache directory
and the script directory:

    PerlSetVar AIMCacheDir /var/images/tmp
    PerlSetVar AIMScriptDir .

The C<'.'> as script directory will cause Apache::ImageMagick to look in the 
directory where the requested image should be for a script. So if you request:

    http://localhost/images/button.gif?-new=1

Apache::ImageMagick will look in the F<images> directory for script named
F<button.gif.pl>, which may look like the following. The script gets an
empty image object along with the other parameters. The scripts creates the
image and Apache::ImageMagick cares about saving the image:


    my ($r, $image, $filters, $args) = @_ ;

    $image->Set(size=>'30x105');
    $image->Read('gradient:#00f685-#0083f8');
    $image->Rotate(-90);
    $image->Raise('6x6');
    $image->Annotate(text=>'Push Me',font=>'/usr/fonts/arial.ttf',fill=>'black',
      gravity=>'Center',pointsize=>18);

    1 ;

Of course you can run normal filters on such a created image, so you might like to use
a script like this, which creates an empty button, add the annotate filter  and sets 
some defaults arguments for it:


    my ($r, $image, $filters, $args) = @_ ;

    $image->Set(size=>'30x105');
    $image->Read('gradient:#00f685-#0083f8');
    $image->Rotate(-90);
    $image->Raise('6x6');

    push @$filters, 'Annotate' ;

    $args -> {font}         = '/usr/fonts/arial.ttf' ;
    $args -> {gravity}      = 'Center' ;
    $args -> {pointsize}    = 18 ;


    1 ;

And request it with:

    http://localhost/images/button.gif?-new=1&text=Push+Me


=head2 Apache configuration directives

The following configuration directives are set via C<PerlSetVar> and used to 
control the operation of Apache::ImageMagick.

=over 4

=item AIMCacheDir

Directory for creating cached image files. Default: Directory of requested image.

=item AIMSourceDir

Directory in which Apache::ImageMagick looks for the source image files. 

Default: Directory of requested image.


=item AIMStripPrefix

This is prefix is stripped from the filename, before it is append to AIMSourceDir.
It's actually a Perl regex.

=item AIMScriptDir

Directory in which Apache::ImageMagick looks for a script that should be executed
to modfiy the parameters before conversion. The name of the script is build
by removing the AIMStripPrefix from the filename, append the result to AIMScriptDir
and appending the extension given with AIMScriptExt. If no AIMStripPrefix is given
the basename of the image is taken, the AIMScriptExt appended and searched in the
AIMScriptDir. The special value '.' means the same directory as the source image
itself. If AIMScriptDir is not set, no script is executed.

Default: No script is executed.

=item AIMScriptExt

Fileextention append to script name.

Default: pl


=item AIMScriptDefault

If given, this script is always executed before the image is created.

Default: No script is executed.

=item AIMCache

Turn caching off. Default: on.

=item AIMParameter

can be used to set defaults and/or force
parameters values. It contains a space spearated list of parameter values pairs. If you
need spaces inside your values, you have to quote the parameter/value pair.

Example:

 PerlSetVar AIMParameter "font=/usr/images/fonts/arial.ttf !color=red" 

By prefixing the parameter with an !, the parameter values is foreced, so it 
can't be overridden by parameters passed to the hanlder via th URI. If there is no !
then the parameter acts as a default value.

=item AIMDebug

Turn this on to get some debug info into the httpd error log. Default: off.

=item AIMCheckMTime

When set the modification time of the source image is compared to the time of
the chached version. If the source is newer the it is recomputed. Default is off.

=item AIMDisableSearch

When set the search for a file with a different format is disabled. Default is
the automatic search and conversion is on.


=back

=head1 Non mod_perl frontend proxy

For performance reasons many people are running a setup with multiple Apache 
server, where you have a non mod_perl frontend that delivers static pages and
images, while mod_perl requests are proxy to a mod_perl server. (like decribed 
for example here: http://perl.apache.org/guide/strategy.html#Apache_s_mod_proxy)
If you are using Apache::ImageMagick every request to such an image must be 
handled by a mod_perl enabled server. When most requests are deliverd from the
cache there is actualy no need to have mod_perl. For such situations 
Apache::ImageMagick comes with a Apache module, named mod_aimproxy, which
will be linked in the frontend server. When a request comes in, the module
first checks if the image is available from the cache. If yes the frontend
server can deliver it directly, just like a static image. If no, the request
is proxied to the backend mod_perl server. To get this working the uri of the
request in the frontend and the backend must be exactly the same (expcet for the
host and/or port part). Also you must configure the same cache directory. A
setup for the frontend might look like

    AIMCacheDir /var/aimcache
    AIMProxyPassTo /images localhost:8765

and the corresponding backend setup

    <Location /images>
    PerlFixupHandler Apache::ImageMagick
    PerlSetVar AIMCacheDir /var/aimcache
    </Location>   

mod_aimproxy has two configuration directives:

=over 4

=item AIMCacheDir

Give the location of the cache. Can only given once

=item AIMProxyPassTo

Gives the location for which mod_aimproxy should take care
and a hostname and optional a portname, where the request 
should proxied to, if the image is not found in the cache.

This directive can be given multiple times, to cover different
locations/backend hosts.

=back


=head1 SUPPORT

As far as possible for me, support will be available via the modperl mailing 
list. See http://perl.apache.org.

=head1 AUTHOR

G.Richter (richter@dev.ecos.de)

Based on work from Lincoln Stein and Doug MacEachern publish in 
"Writing Apache Modules with Perl and C" see www.modperl.com

=head1 SEE ALSO

=over 4

=item Perl(1)

=item Image::Magick

=item http://perl.apache.org

=item http://www.modperl.com

=back


