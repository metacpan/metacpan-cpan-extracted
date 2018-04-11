

BEGIN {
    if ($ENV{PERL_CORE}) {
	chdir 't' if -d 't';
	@INC = ("../lib", "lib/compress");
    }
}

use lib qw(t t/compress);
use strict;
use warnings;

use Test::More ; 
use CompTestUtils;
use File::Spec ;
use Devel::Peek;

BEGIN {    
    # use Test::NoWarnings, if available
    my $extra = 0 ;
    $extra = 1
        if eval { require Test::NoWarnings ;  import Test::NoWarnings; 1 };

    plan tests => 833 + $extra ;

    use_ok('IO::Uncompress::Unzip', qw(unzip $UnzipError)) ;
    use_ok('Archive::Zip::SimpleZip', qw($SimpleZipError)) ;
    
    eval { require Encode ;  import Encode }
    #use_ok('Encode');
}

my $symlink_exists = eval { symlink("", ""); 1 } ;

sub getContent
{
    my $filename = shift;

    my $u = new IO::Uncompress::Unzip $filename, Append => 1, @_
        or die "Cannot open $filename: $UnzipError";

    isa_ok $u, "IO::Uncompress::Unzip";

    my @content;
    my $status ;

    for ($status = 1; $status > 0 ; $status = $u->nextStream())
    {
        die "xxx" if ! defined $u;
        my %info = %{ $u->getHeaderInfo() } ;
        my $name = $u->getHeaderInfo()->{Name};
        #warn "Processing member $name\n" ;

        my $buff = '';
        1 while ($status = $u->read($buff)) ;
        $info{Payload} = $buff;

        #push @content, [$name, $buff];
        push @content, \%info;
        last unless $status == 0;
    }

    die "Error processing $filename: $status $!\n"
        if $status < 0 ;    

    return @content;
}

sub canonFile
{
    IO::Compress::Zip::canonicalName($_[0], 0);
}

sub canonDir
{
    IO::Compress::Zip::canonicalName($_[0], 1);
}

sub unixToDosTime    # Archive::Zip::Member
{
    my $time_t = shift;
    
    # TODO - add something to cope with unix time < 1980 
    my ( $sec, $min, $hour, $mday, $mon, $year ) = localtime($time_t);
    my $dt = 0;
    $dt += ( $sec >> 1 );
    $dt += ( $min << 5 );
    $dt += ( $hour << 11 );
    $dt += ( $mday << 16 );
    $dt += ( ( $mon + 1 ) << 21 );
    $dt += ( ( $year - 80 ) << 25 );
    return $dt;
}

sub dosToUnixTime
{
    my $dt = shift;

    my $year = ( ( $dt >> 25 ) & 0x7f ) + 80;
    my $mon  = ( ( $dt >> 21 ) & 0x0f ) - 1;
    my $mday = ( ( $dt >> 16 ) & 0x1f );

    my $hour = ( ( $dt >> 11 ) & 0x1f );
    my $min  = ( ( $dt >> 5 ) & 0x3f );
    my $sec  = ( ( $dt << 1 ) & 0x3e );


    use POSIX 'mktime';

    my $time_t = mktime( $sec, $min, $hour, $mday, $mon, $year, 0, 0, -1 );
    return 0 if ! defined $time_t;
    return $time_t;
}

sub roundTripUnixTime
{
    my $t = shift;
    return unixToDosTime(dosToUnixTime($t));
}

{
    title "errors";
    
    {
        title "no zip filname";
        my $z = new Archive::Zip::SimpleZip ;
    
        is $z, undef ;
        is $SimpleZipError, "Missing Filename",
            "  missing filename";
    }
    
    {
        title "directory";
        my $lex = new LexDir my $dir;
        my $z = new Archive::Zip::SimpleZip $dir ;
    
        is $z, undef ;
        is $SimpleZipError, "Illegal Filename",
            "  missing filename";
    }    

    {
        title "zip file in directory that doesn't exist";
        my $lex = new LexDir my $dir;
        my $zipfile = File::Spec->catfile($dir, "not", "exist", "x.zip");
        
        my $z = new Archive::Zip::SimpleZip $zipfile ;
    
        is $z, undef ;
        is $SimpleZipError, "Illegal Filename",
            "  missing filename";
    }  
    
    SKIP:
    {
        title "file not writable";
        my $lex = new LexFile my $zipfile;
        
        chmod 0444, $zipfile 
            or skip "Cannot create non-writable file", 3 ;

        skip "Cannot create non-writable file", 3 
            if -w $zipfile ;

        ok ! -w $zipfile, "  zip file not writable";
                
        my $z = new Archive::Zip::SimpleZip $zipfile ;
    
        is $z, undef ;
        is $SimpleZipError, "Illegal Filename",
            "  Illegal Filename";
            
        chmod 0777, $zipfile ;           
    }    
  
            
    {
        title "filename undef";
        my $z = new Archive::Zip::SimpleZip undef;
    
        is $z, undef ;
        is $SimpleZipError, "Illegal Filename",
            "  missing filename";
    }    
    
    {
        title "Bad parameter in new";
        my $lex = new LexFile my $zipfile;        
        eval { my $z = new Archive::Zip::SimpleZip $zipfile, fred => 1 ; };
    
        like $@,  qr/Parameter Error: unknown key value\(s\) fred/,
            "  value  is bad";
                   
        like $SimpleZipError, qr/Parameter Error: unknown key value\(s\) fred/,
            "  missing filename";
    }   
            
    {
        title "Bad parameter in add";
        my $lex = new LexFile my $zipfile;
        my $lex1 = new LexFile my $file1;
        writeFile($file1, "abc");
            
        my $z = new Archive::Zip::SimpleZip $zipfile;
        isa_ok $z, "Archive::Zip::SimpleZip";        
        eval { $z->add($file1, Fred => 1) ; };
    
        like $@,  qr/Parameter Error: unknown key value\(s\) Fred/,
            "  value  is bad";
                   
        like $SimpleZipError, qr/Parameter Error: unknown key value\(s\) Fred/,
            "  missing filename";
    }   
    
            
    {
        title "Name option invalid in constructor";

        my $zipfile ;
            
        eval { my $z = new Archive::Zip::SimpleZip \$zipfile, Name => "fred"; } ;
    
        like $@,  qr/name option not valid in constructor/,
            "  option invalid";
                   
        like $SimpleZipError, qr/name option not valid in constructor/,
            "  option invalid";
    }
    
    {
        title "Comment option invalid in constructor";

        my $zipfile ;
            
        eval { my $z = new Archive::Zip::SimpleZip \$zipfile, Comment => "fred"; } ;
    
        like $@,  qr/comment option not valid in constructor/,
            "  option invalid";
                   
        like $SimpleZipError, qr/comment option not valid in constructor/,
            "  option invalid";
    } 
    
    
    {
        title "ZipComment option only valid in constructor";

        my $zipfile ;
            
        my $z = new Archive::Zip::SimpleZip \$zipfile ;
        eval {  $z->addString("", ZipComment => "fred"); } ;        
    
        like $@,  qr/zipcomment option only valid in constructor/,
            "  option invalid";
                   
        like $SimpleZipError, qr/zipcomment option only valid in constructor/,
            "  option invalid";
    } 
    
            
    {
        title "Missing Name paramter in addString";
        
        my $zipfile;
            
        my $z = new Archive::Zip::SimpleZip \$zipfile;
        isa_ok $z, "Archive::Zip::SimpleZip";        
        eval { $z->addString("abc") ; };
    
        like $@,  qr/Missing 'Name' parameter in addString/,
            "  value  is bad";
                   
        like $SimpleZipError, qr/Missing 'Name' parameter in addString/,
            "  missing filename";
    }     
    
            
    {
        title "Missing Name paramter in addFileHandle";
        
        my $zipfile;
            
        my $z = new Archive::Zip::SimpleZip \$zipfile;
        isa_ok $z, "Archive::Zip::SimpleZip";        
        eval { $z->addFileHandle("abc") ; };
    
        like $@,  qr/Missing 'Name' parameter in addFileHandle/,
            "  value  is bad";
                   
        like $SimpleZipError, qr/Missing 'Name' parameter in addFileHandle/,
            "  missing filename";
    }       
        
}

{
    title "file doesn't exist";

    my $lex1 = new LexFile my $zipfile;
    my $file1 = "notexist";

    my $z = new Archive::Zip::SimpleZip $zipfile ;
    isa_ok $z, "Archive::Zip::SimpleZip";

    is $z->add($file1), 0, "add not ok";
    is $SimpleZipError, "File '$file1' does not exist";
 

    ok ! -e $file1, "no zip file created";
}

# {
#     # exports
# }

use Fcntl ':mode';

SKIP:
{
    title "file cannot be read";

    my $lex1 = new LexFile my $zipfile;
    my $lex = new LexFile my $file1;
    
    writeFile($file1, "abc");
    chmod 0222, $file1 ;

    skip "Cannot create non-readable file", 6
        if -r $file1 ;

    ok ! -r $file1, "  input file not readable";          
       
    my $z = new Archive::Zip::SimpleZip $zipfile ;
    isa_ok $z, "Archive::Zip::SimpleZip";

    is $z->add($file1), 0, "add not ok";
    is $SimpleZipError, "File '$file1' cannot be read";
    ok $z->close, "closed ok";

    ok -z $zipfile, "zip file created, but empty";
    
    chmod 0777, $file1 ;
    
}


SKIP:
{
    title "one file cannot be read";

    my $lex1 = new LexFile my $zipfile;
    my $lex2 = new LexFile my $file1;
    my $lex3 = new LexFile my $file2;
    my $lex4 = new LexFile my $file3;        
    
    writeFile($file1, $file1);
    writeFile($file2, $file2);
    writeFile($file3, $file3);
    chmod 0222, $file2 ;

    skip "Cannot create non-readable file", 13
        if -r $file2 ;

    ok ! -r $file2, "  input file not readable";          
       
    my $z = new Archive::Zip::SimpleZip $zipfile ;
    isa_ok $z, "Archive::Zip::SimpleZip";

    ok $z->add($file1), "add $file1";

    is $z->add($file2), 0, "add not ok";
    is $SimpleZipError, "File '$file2' cannot be read";

    ok ! $z->add($file3), "not add $file3";
    is $SimpleZipError, "File '$file2' cannot be read";
            
    ok $z->close, "closed ok";

    ok -e $zipfile, "zip file created";
    
    my @got = getContent($zipfile);
    is @got, 1, "two entries in zip";
    is $got[0]{Name}, canonFile($file1);
    is $got[0]{Payload}, $file1;    

    
    chmod 0777, $file2 ;        
}

{
    title "simple" ;

    my $lex1 = new LexFile my $zipfile;
    my $lex = new LexFile my $file1;

    writeFile($file1, "hello world");

    my $z = new Archive::Zip::SimpleZip $zipfile ;
    isa_ok $z, "Archive::Zip::SimpleZip";

    ok $z->add($file1), "add ok";
    ok $z->close, "closed ok";

    my @got = getContent($zipfile);
    is @got, 1, "one entry in zip";
    is $got[0]{Name}, canonFile($file1);
    is $got[0]{Payload}, "hello world";
}


{
    title "simple - no close" ;

    my $lex1 = new LexFile my $zipfile;
    my $lex = new LexFile my $file1;

    writeFile($file1, "hello world");

    {
        my $z = new Archive::Zip::SimpleZip $zipfile ;
        isa_ok $z, "Archive::Zip::SimpleZip";
    
        ok $z->add($file1), "add ok";
    }


    my @got = getContent($zipfile);
    is @got, 1, "one entry in zip";
    is $got[0]{Name}, canonFile($file1);
    is $got[0]{Payload}, "hello world";
}


{
    title "simple - no add" ;

    my $lex1 = new LexFile my $zipfile;
    my $lex = new LexFile my $file1;

    writeFile($file1, "hello world");

    {
        my $z = new Archive::Zip::SimpleZip $zipfile ;
        isa_ok $z, "Archive::Zip::SimpleZip";
    
        #ok $z->add($file1), "add ok";
    }

    ok -e $zipfile, "file exists" ;
    is -s $zipfile, 0, "file empty" ;       
}

{
    title "simple dir" ;

    my $lex1 = new LexFile my $zipfile;
    my $lex = new LexDir my $dir1;

    ok -d $dir1;

    my $dir2 = File::Spec->catfile($dir1, "dir2");
    ok mkdir $dir2;
    ok -d $dir2, "$dir2 is a directory";

    my $z = new Archive::Zip::SimpleZip $zipfile ;
    isa_ok $z, "Archive::Zip::SimpleZip";

    ok $z->add($dir1), "add $dir1 ok";
    ok $z->add($dir2), "add $dir2 ok";
    ok $z->close, "closed ok";

    my @got = getContent($zipfile);
    is @got, 2, "two entries in zip";
    is $got[0]{Name}, canonDir($dir1);
    is substr($got[0]{Name}, -1), "/";
    is $got[0]{Payload}, "";
    is $got[1]{Name}, canonDir($dir2);
    is substr($got[1]{Name}, -1), "/";
    is $got[1]{Payload}, "";
}

{
    title "Absolute path converted to relative" ;

    my $lex1 = new LexFile my $zipfile;


    my $z = new Archive::Zip::SimpleZip $zipfile ;
    isa_ok $z, "Archive::Zip::SimpleZip";

    my $dir1 = "fred" ;
    my $dir2 = $dir1 . "joe";
    ok $z->addString("1", Name => "/" . $dir1), "add /$dir1 ok";
    ok $z->addString("2", Name => "/" . $dir2), "add /$dir2 ok";
    ok $z->close, "closed ok";

    my @got = getContent($zipfile);
    is @got, 2, "two entries in zip";
    is $got[0]{Name}, $dir1;
    is $got[0]{Payload}, "1";
    is $got[1]{Name}, $dir2;
    is $got[1]{Payload}, "2";
}


SKIP:
{
    title "symbolic link - StoreLinks => 0" ;
    skip "symlink not available on this platform", 10
        unless $symlink_exists;


    my $lex1 = new LexFile my $zipfile;
    my $lex = new LexDir my $dir1;

    my $from = File::Spec->catfile($dir1, "from");
    my $link = File::Spec->catfile($dir1, "to");

    writeFile $from, "hello";
    ok symlink("from" => $link), "create link";

    ok -d $dir1;
    ok -l $link;

    my $z = new Archive::Zip::SimpleZip $zipfile ;
    isa_ok $z, "Archive::Zip::SimpleZip";

    ok $z->add($link), "add ok";
    ok $z->close, "closed ok";

    my @got = getContent($zipfile);
    is @got, 1, "one entry in zip";
    is $got[0]{Name}, canonFile($link);
    is $got[0]{Payload}, "hello";
}

SKIP:
{
    title "symbolic link - StoreLinks => 1" ;
    skip "symlink not available on this platform", 10
        unless $symlink_exists;


    my $lex1 = new LexFile my $zipfile;
    my $lex = new LexDir my $dir1;

    my $from = File::Spec->catfile($dir1, "from");
    my $link = File::Spec->catfile($dir1, "to");

    writeFile $from, "hello";
    ok symlink("from" => $link), "create link";

    ok -d $dir1;
    ok -l $link;

    my $z = new Archive::Zip::SimpleZip $zipfile ;
    isa_ok $z, "Archive::Zip::SimpleZip";

    ok $z->add($link, StoreLinks => 1), "add ok";
    ok $z->close, "closed ok";

    my @got = getContent($zipfile);
    is @got, 1, "one entry in zip";
    is $got[0]{Name}, canonFile($link);
    is $got[0]{Payload}, "from";
}

SKIP:
{
    title "symbolic link to dir - StoreLinks => 1" ;
    skip "symlink not available on this platform", 11
        unless $symlink_exists;


    my $lex1 = new LexFile my $zipfile;    
    my $lex = new LexDir my $dir1;

    my $from = File::Spec->catfile($dir1, "from");
    my $link = File::Spec->catfile($dir1, "to");

    ok -d $dir1;
    
    mkdir $from;
    ok -d $from, "$from is a directory";
    
    ok symlink("from" => $link), "create link to dir";

    ok -l $link, "$link is a link";

    my $z = new Archive::Zip::SimpleZip $zipfile ;
    isa_ok $z, "Archive::Zip::SimpleZip";

    ok $z->add($link, StoreLinks => 1), "add ok";
    ok $z->close, "closed ok";

    my @got = getContent($zipfile);
    is @got, 1, "one entry in zip";
    is $got[0]{Name}, canonFile($link);
    is $got[0]{Payload}, "from";
}


SKIP:
{
    title "symbolic link to dir - StoreLinks => 0" ;
    skip "symlink not available on this platform", 11
        unless $symlink_exists;


    my $lex1 = new LexFile my $zipfile;    
    my $lex = new LexDir my $dir1;

    my $from = File::Spec->catfile($dir1, "from");
    my $link = File::Spec->catfile($dir1, "to");

    ok -d $dir1;
    
    mkdir $from;
    ok -d $from, "$from is a directory";
    
    ok symlink("from" => $link), "create link to dir";

    ok -l $link, "$link is a link";

    my $z = new Archive::Zip::SimpleZip $zipfile ;
    isa_ok $z, "Archive::Zip::SimpleZip";

    ok $z->add($link, StoreLinks => 0), "add ok";
    ok $z->close, "closed ok";

    my @got = getContent($zipfile);
    is @got, 1, "one entry in zip";
    is $got[0]{Name}, canonDir($link);
    is $got[0]{Payload}, "";
}




SKIP:
{
    title "mixed content";
    skip "symlink not available on this platform", 20
        unless $symlink_exists;


    my $lex1 = new LexFile my $zipfile;
    my $lex2 = new LexFile my $file1;
    my $lex3 = new LexDir my $dir1;

    my $from = File::Spec->catfile($dir1, "from");
    my $link = File::Spec->catfile($dir1, "to");

    writeFile($from, "hello world");

    ok symlink("from" => $link), "create link";

    my $z = new Archive::Zip::SimpleZip $zipfile, Stream => 1 ;
    isa_ok $z, "Archive::Zip::SimpleZip";

    ok $z->add($from), "add file ok";
    ok $z->add($dir1, Zip64 => 1, Stream => 0), "add dir ok";
    ok $z->add($link, StoreLinks => 1), "add link ok";
    
    ok $z->close, "closed ok";

    my @got = getContent($zipfile);
    is @got, 3, "three entries in zip";
    is $got[0]{Name}, canonFile($from);
    is $got[0]{Payload}, "hello world";
    is $got[0]{Zip64}, 0, "not zip64";
    is $got[0]{Stream}, 1, "Stream";    
    is $got[1]{Name}, canonDir($dir1);
    is $got[1]{Payload}, "";
    is $got[1]{Zip64}, 1, "zip64";
    is $got[1]{Stream}, 0, "not Stream"; 
    is $got[2]{Name}, canonFile($link);
    is $got[2]{Payload}, "from";
    is $got[2]{Zip64}, 0, "not zip64";   
    is $got[2]{Stream}, 1, "Stream";  
}

{
    title "mixed content - no symlink";


    my $lex1 = new LexFile my $zipfile;
    my $lex2 = new LexFile my $file1;
    my $lex3 = new LexDir my $dir1;

    my $from = File::Spec->catfile($dir1, "from");
    my $link = File::Spec->catfile($dir1, "to");

    writeFile($from, "hello world");
    writeFile($link, "not a link");

    my $z = new Archive::Zip::SimpleZip $zipfile, Stream => 1 ;
    isa_ok $z, "Archive::Zip::SimpleZip";

    ok $z->add($from), "add file ok";
    ok $z->add($dir1, Zip64 => 1, Stream => 0), "add dir ok";
    ok $z->add($link, StoreLinks => 1), "add link ok"
        or diag "$SimpleZipError\n";
    
    ok $z->close, "closed ok";

    my @got = getContent($zipfile);
    is @got, 3, "three entries in zip";
    is $got[0]{Name}, canonFile($from);
    is $got[0]{Payload}, "hello world";
    is $got[0]{Zip64}, 0, "not zip64";
    is $got[0]{Stream}, 1, "Stream";    
    is $got[1]{Name}, canonDir($dir1);
    is $got[1]{Payload}, "";
    is $got[1]{Zip64}, 1, "zip64";
    is $got[1]{Stream}, 0, "not Stream"; 
    is $got[2]{Name}, canonFile($link);
    is $got[2]{Payload}, "not a link";
    is $got[2]{Zip64}, 0, "not zip64";   
    is $got[2]{Stream}, 1, "Stream";  
}

#{
#    title "Name ignored in constructor" ;
#
#    my $lex1 = new LexFile my $zipfile;
#    my $lex = new LexFile my $file1;
#
#    writeFile($file1, "hello world");
#
#    my $z = new Archive::Zip::SimpleZip $zipfile, Name => "fred" ;
#    isa_ok $z, "Archive::Zip::SimpleZip";
#
#    ok $z->add($file1), "add ok";
#    ok $z->close, "closed ok";
#
#    my @got = getContent($zipfile);
#    is @got, 1, "one entry in zip";
#    is $got[0]{Name}, canonFile($file1);
#    is $got[0]{Payload}, "hello world";
#}


{
    title "Name not sticky" ;

    my $lex1 = new LexFile my $zipfile;
    my $lex = new LexFile my $file1;

    writeFile($file1, "hello world");

    my $z = new Archive::Zip::SimpleZip $zipfile;
    isa_ok $z, "Archive::Zip::SimpleZip";

    ok $z->add($file1, Name => "fred" ), "add ok";
    ok $z->add($file1 ), "add ok";    
    ok $z->close, "closed ok";

    my @got = getContent($zipfile);
    is @got, 2, "two entry in zip";
    is $got[0]{Name}, "fred";
    is $got[0]{Payload}, "hello world";
    is $got[1]{Name}, canonFile($file1);
    is $got[1]{Payload}, "hello world";    
}


{
    title "simple output to filehandle" ;


    my $lex = new LexFile my $file1;
    my $lex1 = new LexFile my $zfile;
        
   
    open my $zipfile, ">$zfile";
    writeFile($file1, "hello world");

    my $z = new Archive::Zip::SimpleZip $zipfile ;
    isa_ok $z, "Archive::Zip::SimpleZip";

    ok $z->add($file1), "add ok";
    ok $z->close, "closed ok";

    ok close $zipfile;
    
    my @got = getContent($zfile);
    is @got, 1, "one entry in zip";
    is $got[0]{Name}, canonFile($file1);
    is $got[0]{Payload}, "hello world";
}


{
    title "simple output to stdout" ;

    my $lex1 = new LexFile my $zipfile;
    
    open(SAVEOUT, ">&STDOUT");
    my $dummy = fileno SAVEOUT;
    open STDOUT, ">$zipfile" ;

    my $lex = new LexFile my $file1;
 
    writeFile($file1, "hello world");

    my $z = new Archive::Zip::SimpleZip '-' ;
    
    isa_ok $z, "Archive::Zip::SimpleZip";

    ok $z->add($file1), "add ok";
    ok $z->close, "closed ok";

    open(STDOUT, ">&SAVEOUT");
    
    my @got = getContent($zipfile);
    is @got, 1, "one entry in zip";
    is $got[0]{Name}, canonFile($file1);
    is $got[0]{Payload}, "hello world";
}


{
    title "simple output to string" ;

    my $string;
    my $zipfile = \$string;
    my $lex = new LexFile my $file1;

    writeFile($file1, "hello world");

    my $z = new Archive::Zip::SimpleZip $zipfile ;
    isa_ok $z, "Archive::Zip::SimpleZip";

    ok $z->add($file1), "add ok";
    ok $z->close, "closed ok";

    my @got = getContent($zipfile);
    is @got, 1, "one entry in zip";
    is $got[0]{Name}, canonFile($file1);
    is $got[0]{Payload}, "hello world";
}


{
    title "addString: simple output to string" ;

    my $string;
    my $zipfile = \$string;
    my $lex = new LexFile my $file1;

    my $payload = "hello world";

    my $z = new Archive::Zip::SimpleZip $zipfile ;
    isa_ok $z, "Archive::Zip::SimpleZip";

    ok $z->addString($payload, Name => "abc"), "addString ok";
    ok $z->close, "closed ok";

    my @got = getContent($zipfile);
    is @got, 1, "one entry in zip";
    is $got[0]{Name}, canonFile("abc");
    is $got[0]{Payload}, $payload;
}

{
    title "addFileHandle: simple output to string" ;

    my $string;
    my $zipfile = \$string;
    my $lex = new LexFile my $file1;

    my $payload = "hello world";
    writeFile($file1, $payload);

    my $z = new Archive::Zip::SimpleZip $zipfile ;
    isa_ok $z, "Archive::Zip::SimpleZip";

    my $fh;
    ok open($fh, "<$file1");
    ok $z->addFileHandle($fh, Name => "abc"), "addFileHandle ok";
    ok $z->close, "closed ok";

    my @got = getContent($zipfile);
    is @got, 1, "one entry in zip";
    is $got[0]{Name}, canonFile("abc");
    is $got[0]{Payload}, $payload;
}

{
    title "raw - one member, explicit close";
    
    my $string;
    my $zipfile = \$string;
    my $lex = new LexFile my $file1;
    
    my $payload1 = "hello world";
    
    my $z = new Archive::Zip::SimpleZip $zipfile ;
    isa_ok $z, "Archive::Zip::SimpleZip";

    my $fh = $z->openMember(Name => "abc");
#    isa_ok $fh, "Archive::Zip::SimpleZip::Handle";    
#    is tied $fh, "Archive::Zip::SimpleZip::Handle";  
    ok $fh;  
    
    print $fh $payload1 ;
    
    ok close($fh), "closed ok";      
    ok $z->close, "closed ok";  
      
    my @got = getContent($zipfile);
    is @got, 1, "one entry in zip";
    is $got[0]{Name}, canonFile("abc");  
    is $got[0]{Payload}, $payload1;   
}

{
    title "raw - one member, simplezip scoped close";
    
    my $string;
    my $zipfile = \$string;
    my $lex = new LexFile my $file1;
    
    my $payload1 = "hello world";
    
    {
        my $z = new Archive::Zip::SimpleZip $zipfile ;
        isa_ok $z, "Archive::Zip::SimpleZip";
    
        my $fh = $z->openMember(Name => "abc");
#        isa_ok $fh, "Archive::Zip::SimpleZip::Handle";    
        ok $fh;
        
        print $fh $payload1 ;
        ok $fh->close, "closed ok";
         # let the zip object go out of scope
    }
 
    my @got = getContent($zipfile);
    is @got, 1, "one entry in zip";
    is $got[0]{Name}, canonFile("abc");  
    is $got[0]{Payload}, $payload1;      

}

{
    title "raw - one member, all scoped close";
    
    my $string;
    my $zipfile = \$string;
    my $lex = new LexFile my $file1;
    
    my $payload1 = "hello world";
    
    {
        my $z = new Archive::Zip::SimpleZip $zipfile ;
        isa_ok $z, "Archive::Zip::SimpleZip";
    
        my $fh = $z->openMember(Name => "abc");
#        isa_ok $fh, "Archive::Zip::SimpleZip::Handle"; 
        ok $fh;   
        
        print $fh $payload1 ;
        # let the filehandle & zip objects go out of scope
    }
 
    my @got = getContent($zipfile);
    is @got, 1, "one entry in zip";
    is $got[0]{Name}, canonFile("abc");  
    is $got[0]{Payload}, $payload1;      
}

{
    title "raw - close zip before member";
    
    my $string;
    my $zipfile = \$string;
    my $lex = new LexFile my $file1;
    
    my $payload1 = "hello world";
     
    my $z = new Archive::Zip::SimpleZip $zipfile ;
    isa_ok $z, "Archive::Zip::SimpleZip";

    my $fh = $z->openMember(Name => "abc");
#    isa_ok $fh, "Archive::Zip::SimpleZip::Handle";    
    ok $fh;
    
    print $fh $payload1 ;
    
    # close zip before filehandle
    ok $z->close, "closed ok";
 
    my @got = getContent($zipfile);
    is @got, 1, "one entry in zip";
    is $got[0]{Name}, canonFile("abc");  
    is $got[0]{Payload}, $payload1;      

}


{
    title "raw - two members, one FH, one addString";
    
    my $string;
    my $zipfile = \$string;
    my $lex = new LexFile my $file1;
    
    my $payload1 = "hello world";
    my $payload2 = "goodnight vienna";
    
    my $z = new Archive::Zip::SimpleZip $zipfile ;
    isa_ok $z, "Archive::Zip::SimpleZip";

    my $fh = $z->openMember(Name => "abc");
#    isa_ok $fh, "Archive::Zip::SimpleZip::Handle";   
    ok $fh; 
    
    is tell($fh), 0 ;
    is $fh->tell(), 0;
    
    print $fh $payload1 ;
    
    is tell($fh), length($payload1) ;
    ok 1; # TODO is $fh->tell(), length $payload1 ;
        
    ok $fh->close, "closed ok";
    
    ok $z->addString($payload2, Name => "def"), "addString ok";
    
    ok $z->close, "closed ok";    

    my @got = getContent($zipfile);
    is @got, 2, "two entries in zip";
    is $got[0]{Name}, canonFile("abc");  
    is $got[0]{Payload}, $payload1;      
    is $got[1]{Name}, canonFile("def"); 
    is $got[1]{Payload}, $payload2;
}


{
    title "raw - error addString while raw open";
    
    my $string;
    my $zipfile = \$string;
    my $lex = new LexFile my $file1;
    
    my $payload1 = "hello world";
    my $payload2 = "goodnight vienna";
    
    my $z = new Archive::Zip::SimpleZip $zipfile ;
    isa_ok $z, "Archive::Zip::SimpleZip";

    my $fh = $z->openMember(Name => "abc");
#    isa_ok $fh, "Archive::Zip::SimpleZip::Handle";  
    ok $fh;  
    
    print $fh $payload1 ;
    
    # Not closed
    #ok $fh->close, "closed ok";
    
    ok ! $z->addString($payload2, Name => "def"), "addString  not ok";
}


{
    title "raw - open raw while raw open";
    
    my $string;
    my $zipfile = \$string;
    my $lex = new LexFile my $file1;
    
    my $payload1 = "hello world";
    my $payload2 = "goodnight vienna";
    
    my $z = new Archive::Zip::SimpleZip $zipfile ;
    isa_ok $z, "Archive::Zip::SimpleZip";

    my $fh = $z->openMember(Name => "abc");
#    isa_ok $fh, "Archive::Zip::SimpleZip::Handle";    
    ok $fh;
    
    ok print $fh $payload1 ;
    
    # Not closed
    #ok $fh->close, "closed ok";
    
    my $fh1 = $z->openMember(Name => "def");
    is $fh1, undef;    
}

{
    title "raw - write to closed member";
    
    my $string;
    my $zipfile = \$string;
    my $lex = new LexFile my $file1;
    
    my $payload1 = "hello world";
    my $payload2 = "goodnight vienna";
    
    my $z = new Archive::Zip::SimpleZip $zipfile ;
    isa_ok $z, "Archive::Zip::SimpleZip";

    my $fh = $z->openMember(Name => "abc");
#    isa_ok $fh, "Archive::Zip::SimpleZip::Handle";
    ok $fh;    
    
    ok print $fh $payload1 ;

    ok $fh->close, "closed ok";
    
    ok ! print $fh $payload1 ;

    ok $z->close();
    
    my @got = getContent($zipfile);
    is @got, 1, "one entry in zip";
    is $got[0]{Name}, canonFile("abc");  
    is $got[0]{Payload}, $payload1;      
}

{
    title "raw - write to closed zip";
    
    my $string;
    my $zipfile = \$string;
    my $lex = new LexFile my $file1;
    
    my $payload1 = "hello world";
    my $payload2 = "goodnight vienna";
    
    my $z = new Archive::Zip::SimpleZip $zipfile ;
    isa_ok $z, "Archive::Zip::SimpleZip";

    my $fh = $z->openMember(Name => "abc");
#    isa_ok $fh, "Archive::Zip::SimpleZip::Handle";    
    ok $fh;
    
    ok print $fh $payload1 ;

    ok $z->close();
        
    ok ! print $fh $payload1 ;
    
    my @got = getContent($zipfile);
    is @got, 1, "one entry in zip";
    is $got[0]{Name}, canonFile("abc");  
    is $got[0]{Payload}, $payload1;      
}

for my $ix (1 .. 5)
{
    title "raw - $ix members in sequence - all FH";
    
    for my $to ( qw(filehandle buffer filename))
    {
        title "To $to";

        my $lex = new LexFile my $name2 ;
        my $output;
        my $buffer;
        my $zipfile;

        if ($to eq 'buffer')
        {
            $output = $zipfile = \$buffer ; 
        }
        elsif ($to eq 'filename')
        {
            $output = $zipfile = $name2 ;
        }
        elsif ($to eq 'filehandle')
        {
            $zipfile = $name2;
            $output = new IO::File ">$name2" ;
        }

        my $payload1 = "hello world";
        
        my $z = new Archive::Zip::SimpleZip $zipfile ;
        isa_ok $z, "Archive::Zip::SimpleZip";

        for my $m (1 .. $ix)
        {
            my $fh1 = $z->openMember(Name => "abc$m");
#            isa_ok $fh1, "Archive::Zip::SimpleZip::Handle"
            ok $fh1
                or diag "Error for $m is $SimpleZipError";    
            
            print $fh1 $payload1 . "$m" ;
            
            ok $fh1->close, "closed member $to-$ix-$m ok";
        }
        
        ok $z->close, "closed ok";    

        my @got = getContent($zipfile);
        is @got, $ix, "$to-$ix entries in zip";
        for my $m (0 .. $ix -1)
        {
            my $i = $m +1 ;
            is $got[$m]{Name}, canonFile("abc$i"), "name $to-$ix-$m ok";  
            is $got[$m]{Payload}, "$payload1$i", "payload $to-$ix-$m ok";      
        }
    }
}

SKIP:
{
    title "Unknown encoding";
    
    skip "Encode not available", 1 if ! defined &Encode::find_encoding ;
    
    my $output;
    eval { my $cs = new Archive::Zip::SimpleZip(\$output, Encode => 'fred'); } ;
    like($@, qr/Unknown Encoding 'fred'/, 
             "  Unknown Encoding 'fred'");
} 
    
SKIP:    
{
    title "Encode option";
    
    skip "Encode not available", 48 if ! defined &Encode::find_encoding ;
        
    my $string = "\x{df}\x{100}\x80"; 
    my $encString = Encode::encode_utf8($string);
    my $buffer = $encString;
    
    for my $to ( qw(filehandle buffer filename))
    {
        title "Encode: To $to";

        my $lex2 = new LexFile my $name2 ;
        my $output;
        my $buffer;
        my $zipfile;

        if ($to eq 'buffer')
        {
            $output = $zipfile = \$buffer ; 
        }
        elsif ($to eq 'filename')
        {
            $output = $zipfile = $name2 ;
        }
        elsif ($to eq 'filehandle')
        {
            $zipfile = $name2;
            $output = new IO::File ">$name2" ;
        }

        my $z = new Archive::Zip::SimpleZip $output, Encode => 'utf8' ;
        isa_ok $z, "Archive::Zip::SimpleZip";

        my $lex = new LexFile my $file1;
        writeFile($file1, $encString);
        
        ok $z->add($file1, Name => "1");
        ok $z->addString($string, Name => "2");  
        
        my $fh;
        ok $fh = $z->openMember(Name => "3");
        print $fh $string;
        is tell($fh), bytes::length($string);
        ok close $fh; 
         
        ok $z->close, "closed ok";    
    
        my @got = getContent($zipfile);
        is @got, 3, "three entries in zip";
        is $got[0]{Name},    canonFile("1");     
        is $got[0]{Payload}, $encString;          
        is $got[1]{Name},    canonFile("2"); 
        is $got[1]{Payload}, $encString;   
        is $got[2]{Name},    canonFile("3"); 
        is $got[2]{Payload}, $encString;
    }        
}

{
    title "no Encode option";
    
    my $string = "hello world";
    my $encString = $string;
    my $buffer = $encString;
    
    for my $to ( qw(filehandle buffer filename))
    {
        title "Encode: To $to";

        my $lex2 = new LexFile my $name2 ;
        my $output;
        my $buffer;
        my $zipfile;

        if ($to eq 'buffer')
        {
            $output = $zipfile = \$buffer ; 
        }
        elsif ($to eq 'filename')
        {
            $output = $zipfile = $name2 ;
        }
        elsif ($to eq 'filehandle')
        {
            $zipfile = $name2;
            $output = new IO::File ">$name2" ;
        }

        my $z = new Archive::Zip::SimpleZip $output ;
        isa_ok $z, "Archive::Zip::SimpleZip";

        my $lex = new LexFile my $file1;
        writeFile($file1, $encString);
        
        ok $z->add($file1, Name => "1");
        ok $z->addString($string, Name => "2");  
        
        my $fh;
        ok $fh = $z->openMember(Name => "3");
        print $fh $string;
        is tell($fh), bytes::length($string);
        #flush $fh; 
        ok close $fh; 
         
        ok $z->close, "closed ok";    
    
        my @got = getContent($zipfile);
        is @got, 3, "three entries in zip";
        is $got[0]{Name},    canonFile("1");     
        is $got[0]{Payload}, $encString;          
        is $got[1]{Name},    canonFile("2"); 
        is $got[1]{Payload}, $encString;   
        is $got[2]{Name},    canonFile("3"); 
        is $got[2]{Payload}, $encString;
    }        
}

{
    title "raw - oo ";
    
    my $string;
    my $zipfile = \$string;
    my $lex = new LexFile my $file1;
    
    my $payload1 = "hello world";
    my $payload2 = "goodnight vienna";

    
    for my $to ( qw(filehandle buffer filename))
    {
        title " $to";

        my $lex2 = new LexFile my $name2 ;
        my $output;
        my $buffer;
        my $zipfile;

        if ($to eq 'buffer')
        {
            $output = $zipfile = \$buffer ; 
        }
        elsif ($to eq 'filename')
        {
            $output = $zipfile = $name2 ;
        }
        elsif ($to eq 'filehandle')
        {
            $zipfile = $name2;
            $output = new IO::File ">$name2" ;
        }        
            
        my $z = new Archive::Zip::SimpleZip $zipfile ;
        isa_ok $z, "Archive::Zip::SimpleZip";
    
        my $fh1 = $z->openMember(Name => "abc");
#        isa_ok $fh1, "Archive::Zip::SimpleZip::Handle";  
        ok $fh1;  
        
        ok 1; # TODO is $fh1->tell(), 0 ;
                
        ok $fh1->print($payload1) ;
        
        ok 1; # TODO is $fh1->tell(), length $payload1 ;
        
        ok $fh1->close;
              
        my $fh2 = $z->openMember(Name => "def");
#        isa_ok $fh2, "Archive::Zip::SimpleZip::Handle";  
        ok $fh2;  
        
        ok $fh2->printf("%s", $payload2) ;  
        is $fh2->syswrite($payload2), length $payload2;   
       
        ok $fh2->close;        
      
        ok $z->close, "closed ok";    
    
        my @got = getContent($zipfile);
        is @got, 2, "one entries in zip";
        is $got[0]{Name}, canonFile("abc");  
        is $got[0]{Payload}, $payload1;
        is $got[1]{Name}, canonFile("def");  
        is $got[1]{Payload}, $payload2 . $payload2;
    }    
}
    
{
    title "raw - non-oo ";
    
    my $string;
    my $zipfile = \$string;
    my $lex = new LexFile my $file1;
    
    my $payload1 = "hello world";
    my $payload2 = "goodnight vienna";

    
    for my $to ( qw(filehandle buffer filename))
    {
        title " $to";

        my $lex2 = new LexFile my $name2 ;
        my $output;
        my $buffer;
        my $zipfile;

        if ($to eq 'buffer')
        {
            $output = $zipfile = \$buffer ; 
        }
        elsif ($to eq 'filename')
        {
            $output = $zipfile = $name2 ;
        }
        elsif ($to eq 'filehandle')
        {
            $zipfile = $name2;
            $output = new IO::File ">$name2" ;
        }        
            
        my $z = new Archive::Zip::SimpleZip $zipfile ;
        isa_ok $z, "Archive::Zip::SimpleZip";
    
        my $fh1 = $z->openMember(Name => "abc");
#        isa_ok $fh1, "Archive::Zip::SimpleZip::Handle";
        ok $fh1;    
        
        ok 1; # TODO is tell($fh1), 0 ;
        
        ok print $fh1 $payload1 ;
        ok 1; # TODO is tell($fh1), length $payload1 ;
        
       
        ok close $fh1 ;
                       
        my $fh2 = $z->openMember(Name => "def");
#        isa_ok $fh2, "Archive::Zip::SimpleZip::Handle"
        ok $fh2
            or diag "SimpleZipError = [$SimpleZipError]";    
        
        ok printf $fh2 "%s", $payload2 ; 
        is syswrite($fh2, $payload2), length $payload2; ;       
        ok close $fh2 ;
        
        ok $z->close, "closed ok";    
    
        my @got = getContent($zipfile);
        is @got, 2, "one entries in zip";
        is $got[0]{Name}, canonFile("abc");  
        is $got[0]{Payload}, $payload1;
        is $got[1]{Name}, canonFile("def");  
        is $got[1]{Payload}, $payload2 . $payload2;
    }    
        
}

{
    for my $canonical (1, 0)
    {
        title "CanonicalName => $canonical" ;        
        my $output ;
        my $z = new Archive::Zip::SimpleZip \$output, CanonicalName => $canonical;
        isa_ok $z, "Archive::Zip::SimpleZip";

        my $lex = new LexFile my $file1;
        my $data1 = "one";
        my $data2 = "two";
        my $data3 = "three";
        writeFile($file1, $data1);
        
        my $name1 = "/abc/def1" ;
        my $name2 = "/abc/def2" ;
        my $name3 = "/abc/def3" ;

        ok $z->add($file1, Name => $name1);
        ok $z->addString($data2, Name => $name2);  
        
        my $fh;
        ok $fh = $z->openMember(Name => $name3);
        print $fh $data3;
        ok close $fh; 
         
        ok $z->close, "closed ok";    
    
        my @got = getContent(\$output);
        is @got, 3, "three entries in zip";
        is $got[0]{Name},    $canonical ? canonFile($name1) : $name1;     
        is $got[0]{Payload}, $data1;          
        is $got[1]{Name},    $canonical ? canonFile($name2) : $name2;     
        is $got[1]{Payload}, $data2;   
        is $got[2]{Name},    $canonical ? canonFile($name3) : $name3;     
        is $got[2]{Payload}, $data3;
    }
}

__END__
{
    title "time  - explicitly setting";
    
    my $string;
    my $zipfile = \$string;
    my $lex = new LexFile my $file1;
    
    my $payload1 = "hello world";
    my $payload2 = "goodnight vienna";

    
    #for my $to ( qw(filehandle buffer filename))
    for my $to ( qw( filename ))
    {
        title " $to";

        my $lex2 = new LexFile my $name2 ;
         $name2 = "/tmp/fred.zip";
        my $output;
        my $buffer;
        my $zipfile;
        
        my $payload1 = "payload1";
        my $payload2 = "payload2";
        my $payload3 = "payload3"; 
        
        my $t1 = 12345;
        my $t2 = 2456;
        my $t3 = 9753 ;      

        if ($to eq 'buffer')
        {
            $output = $zipfile = \$buffer ; 
        }
        elsif ($to eq 'filename')
        {
            $output = $zipfile = $name2 ;
        }
        elsif ($to eq 'filehandle')
        {
            $zipfile = $name2;
            $output = new IO::File ">$name2" ;
        }        
            
        my $z = new Archive::Zip::SimpleZip $zipfile ;
        isa_ok $z, "Archive::Zip::SimpleZip";
    
        my $lex = new LexFile my $file1;
        writeFile($file1, $payload1);
        
        ok $z->add($file1, Name => "1", Time => $t1);
        ok $z->addString($payload2, Name => "2", Time => $t2);  
        
        my $fh;
        ok $fh = $z->openMember(Name => "3", Time => $t3);
        print $fh $payload3;
        ok close $fh;     
        
        ok $z->close, "closed ok";    
    
        my @got = getContent($zipfile);
        is @got, 3, "three entries in zip";
        
        is $got[0]{Name}, "1";  
        is $got[0]{Payload}, $payload1;
        ok $got[0]{Time};
        is $got[0]{Time}, roundTripUnixTime($t1) ;        
        
        is $got[1]{Name}, "2";  
        is $got[1]{Payload}, $payload2 ;
        is $got[1]{Time}, roundTripUnixTime($t2) ;
        
        is $got[2]{Name}, "3";  
        is $got[2]{Payload}, $payload3 ;
        is $got[2]{Time}, roundTripUnixTime($t3) ;    
    }            
}
