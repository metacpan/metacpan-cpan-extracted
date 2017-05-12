
# This is a sample CGI script to use Apache::ImageMagick without Apache :-)

use IO::File ;
use CGI ;


eval {
    
my $q = CGI -> new ;

# Path where to find Apache::ImageMagick for require
my $modpath     = 'c:\Programme\Perl\User\aim' ;            

# Path where to look for image sources
my $basepath    = 'c:\data\images' ;

# Path for cache
my $cachepath   = 'c:\data\cache' ;


my $file ;

# Try to get the real path_info and filename from IIS
my $pi = $ENV{PATH_INFO} ;
my $sn = $ENV{SCRIPT_NAME} ;

$pi =~ /^$sn(.*?)$/ ;
$file = $1 || $q -> param('-file') ;

while ($file =~ s/\.\./_/g)
    { ; }

$file =~ s/[^a-zA-Z0-9_.-]/_/g ;

$ENV{PATH} .= ';' . $ENV{MAGICK_HOME} ;

require "$modpath/ImageMagick.pm" ;
require "$modpath/CGI/ImageMagick.pm" ;


my $r = CGI::ImageMagick -> new ({filename => "$basepath/$file",
                                                  path_info => $q -> param('-filter') || '',
                                                 args => { $q -> Vars} ,
                                                 'AIMDebug' => 1,
                                                  'AIMCacheDir' => $cachepath,
                                                 }) ;

my $rc = Apache::ImageMagick::handler ($r, 'IO::File') ;
die "Error code $rc" if ($rc) ;

my $fn = $r -> filename ;
$fn =~ /.*\.(.*?)$/;
my $ext = $1 ;


open PIC, $fn or die "Cannot open $fn ($!)" ;

my $size = -s $fn ;

print "Content-Type: image/$ext\n" ;
print "Connection: close\n" ;
print "Content-Length: $size\n\n" ;

binmode (PIC) ;
binmode (STDOUT) ;

print $buffer while read(PIC, $buffer, 32768);

close PIC ;

} ;
if ($@)
    {
    print "Content-Type: text/plain\n\n" ;
    print "ERROR:$@\n" ;
    }