
use ExtUtils::testlib ;
use IO::File ;
use Apache::ImageMagick ;
use CGI::ImageMagick ;

# Path where to look for image sources
my $basepath    = 'images' ;

# Path for cache
my $cachepath   = 'images/tmp' ;

# Path for image results to compare
my $cmppath     = 'images/cmp' ;

my $testfile ;
my $errors = 0 ;

sub transform 

    {
    my ($file, $filter, $args) = @_ ;

    my $r = CGI::ImageMagick -> new ({filename => "$basepath/$file",
                                                  path_info => $filter || '',
                                                  args => $args ,
                                                  'AIMDebug' => 1,
                                                  'AIMCacheDir' => $cachepath,
                                                  'AIMScriptDir' => '.',
                                                 }) ;

    my $rc = Apache::ImageMagick::handler ($r, 'IO::File') ;
    die "Error code $rc" if ($rc) ;

    my $fn ;
    $testfile = $fn = $r -> filename ;
    $fn =~ /.*\.(.*?)$/;
    my $ext = $1 ;

    my $pi = $filter?"-$filter":'' ;
    $pi =~ s#/#_# ;
    my $cmpfn = "$cmppath/$file$pi" ;

    open PIC, $fn or die "Cannot open $fn ($!)" ;
    open CMP, $cmpfn or die "Cannot open $cmpfn ($!)" ;

    binmode (PIC) ;
    binmode (CMP) ;

    my $picbuf ;
    my $cmbuf ;
    while (my $npic = read(PIC, $picbuf, 32768))
        {
        my $ncmp = read(CMP, $cmpbuf, 32768) ;

        die "Read picture $npic bytes and should be $ncmp bytes" if ($npic != $ncmp) ;
        die "Picture is different as is should" if ($picbuf ne $cmpbuf) ;
        }

    }

sub test 

    {
    my ($desc, $file, $filter, $args) = @_ ;

    print "$desc..." ;

    $testfile = '' ;
    eval { transform ($file, $filter, $args) ; } ;

    if ($@)
        {
        print $@ ;

        if ($testfile && -f $testfile)
            {
            system ("display $testfile") ;
            }

        $errors++ ;
        return ;
        }
    else
        {
        print "ok\n" ;
        return 1 ;
        }
    }


die "no cachedir" if (!-d $cachepath) ;

system ("rm $cachepath/*") ;

test ('Frame',  'h_content.gif', 'Frame', {color=>red, width=>10, height=>10}) ;
test ('Frame/shade',  'h_content.gif', 'Frame/shade', {'Frame:color'=>red, 'Frame:width'=>10, 'frame:height'=>10, 'Shade:color'=>'true'}) ;
test ('Annotate', 'h_content.gif', 'annotate', { text=>'Plus', 'gravity'=>'east', 'pointsize'=>18 }) ;
test ('New button from script with text', 'button.gif', undef, { -new => 1, text => 'Hi' }) ;
test ('New button from script with text "Hi"', 'button2.gif', undef, { -new => 1, text => 'Hi' }) ;

print "Errors $errors\n" ;
