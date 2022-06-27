
BEGIN {
    if ($ENV{PERL_CORE}) {
	chdir 't' if -d 't';
	@INC = ("../lib", "lib/compress");
    }
}

use lib qw(lib t t/compress);
use strict;
use warnings;

use Test::More ;

use CompTestUtils;
use File::Spec ;
use Devel::Peek;

use Carp;
# $SIG{ __DIE__ } = sub { Carp::confess( @_ ) };

BEGIN {
    # use Test::NoWarnings, if available
    my $extra = 0 ;
    $extra = 1
        if eval { require Test::NoWarnings ;  import Test::NoWarnings; 1 };

    plan tests => 7931 + $extra ;

    use_ok('IO::Uncompress::Unzip', qw(unzip $UnzipError)) ;
    use_ok('IO::Compress::Zip', qw(zip $ZipError)) ;
    use_ok('Archive::Zip::SimpleZip', qw($SimpleZipError ZIP_CM_STORE ZIP_CM_DEFLATE ZIP_CM_BZIP2 ZIP_CM_LZMA ZIP_CM_XZ ZIP_CM_ZSTD)) ;
    use_ok('Archive::Zip::StreamedUnzip', qw($StreamedUnzipError)) ;

    # eval { require Encode ;  import Encode }
    #use_ok('Encode');
}


eval ' use IO::Uncompress::Bunzip2 2.201 ;';
eval ' use IO::Uncompress::RawInflate 2.201 ;';
eval ' use IO::Uncompress::UnLzma 2.201 ;';
eval ' use IO::Uncompress::UnXz 2.201 ;';
eval ' use IO::Uncompress::UnZstd 2.201 ;';

my %methodNames;

$methodNames{ZIP_CM_STORE()} = 'Store';
$methodNames{ZIP_CM_DEFLATE()} = 'Deflate' ;
$methodNames{ZIP_CM_BZIP2()} = 'Bzip2'  ;
$methodNames{ZIP_CM_LZMA()} = 'LZMA' ;
$methodNames{ZIP_CM_XZ()} = 'XZ' ;
$methodNames{ZIP_CM_ZSTD()} = 'ZSTD' ;

my %methodsAvailable;

$methodsAvailable{ZIP_CM_STORE()} = 'Store';
$methodsAvailable{ZIP_CM_DEFLATE()} = 'Deflate' if defined $IO::Uncompress::RawInflate::VERSION;
$methodsAvailable{ZIP_CM_BZIP2()} = 'Bzip2' if defined $IO::Uncompress::Bunzip2::VERSION ;
$methodsAvailable{ZIP_CM_LZMA()} = 'LZMA' if defined $IO::Uncompress::UnLzma::VERSION ;
$methodsAvailable{ZIP_CM_XZ()} = 'XZ' if defined $IO::Uncompress::UnXz::VERSION ;
$methodsAvailable{ZIP_CM_ZSTD()} = 'ZSTD' if defined $IO::Uncompress::UnZstd::VERSION ;

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

sub createZip
{
    my $filename = shift;
    my @data = @{ shift @_ };
    # my %extra = %{ shift @_ // {} };
    my %extra = @_ ? %{ shift @_ } : {} ;

    my $z = new Archive::Zip::SimpleZip $filename, %extra, CanonicalName => 0 ;
    isa_ok $z, "Archive::Zip::SimpleZip";

    for my $x (@data)
    {
        my ($name, $payload, $expectedType, $opts) = @$x;
        #diag "add [$name][$payload]";
        ok $z->addString($payload, Name => $name, @$opts), "Added $name" ;
    }
    ok $z->close(), "closed";

    my $entries = scalar @data;
    my @got = getContent($filename);
    is @got, $entries, "Added $entries entry in zip";
    for (0 .. $entries-1)
    {
        # is $got[$_]{Name}, canonFile($data[$_][0]), "Added Name ok";
        is $got[$_]{Name}, $data[$_][0], "Added Name ok";
        is $got[$_]{Payload}, $data[$_][1], "Added Payload ok";
    }
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

if(1)
{
    title "errors";

    {
        title "no zip filname";
        my $z = new Archive::Zip::StreamedUnzip ;

        is $z, undef ;
        is $StreamedUnzipError, "Missing Filename",
            "  missing filename";
    }

    if (1)
    {
        title "directory";
        my $lex = new LexDir my $dir;
        my $z = new Archive::Zip::StreamedUnzip $dir ;

        is $z, undef ;
        is $StreamedUnzipError, "Illegal Filename",
            "  missing filename";
    }

    {
        title "zip file in directory that doesn't exist";
        my $lex = new LexDir my $dir;
        my $zipfile = File::Spec->catfile($dir, "not", "exist", "x.zip");

        my $z = new Archive::Zip::StreamedUnzip $zipfile ;

        is $z, undef ;
        like $StreamedUnzipError, qr/cannot open file/,
            "  missing filename";
    }

#    SKIP:
#    {
#        title "file not readable";
#        my $lex = new LexFile my $zipfile;

#        chmod 0444, $zipfile
#            or skip "Cannot create non-readable file", 3 ;

#        skip "Cannot create non-readable file", 3
#            if -r $zipfile ;

#        ok ! -r $zipfile, "  zip file not readable";

#        my $z = new Archive::Zip::StreamedUnzip $zipfile ;

#        is $z, undef ;
#        is $StreamedUnzipError, "Illegal Filename",
#            "  Illegal Filename";

#        chmod 0777, $zipfile ;
#    }


    {
        title "filename undef";
        my $z = new Archive::Zip::StreamedUnzip undef;

        is $z, undef ;
        is $StreamedUnzipError, "Illegal Filename",
            "  missing filename";
    }

    if (0) # TODO
    {
        title "Bad parameter in new";
        my $lex = new LexFile my $zipfile;
        eval { my $z = new Archive::Zip::StreamedUnzip $zipfile, fred => 1 ; };

        like $@,  qr/Archive::Zip::StreamedUnzip: unknown key value(s) fred at/,
            "  value  is bad";

        like $StreamedUnzipError, qr/Archive::Zip::StreamedUnzip: unknown key value(s) fred at/,
            "  missing filename";
    }


}

use Fcntl ':mode';

sub testType
{
    my $object = shift;
    my $expectedType = shift ;

    return $object->isFile()       if $expectedType eq 'file';
    return $object->isDirectory()  if $expectedType eq 'dir';

    die "Bad test '$expectedType'";
}



if (1)
{
    for my $method ( ZIP_CM_DEFLATE, ZIP_CM_BZIP2, ZIP_CM_STORE, ZIP_CM_LZMA, ZIP_CM_XZ, ZIP_CM_ZSTD)
    {
        for my $comment ('', "abcde")
        {
            for my $streamed (0, 1)
            {
                for my $to ( qw(filehandle filename buffer))
                {
                    SKIP:
                    for my $zip64 (0, 1)
                    {
                        my $methodName = $methodsAvailable{$method} || '';

                        title "** TO $to, Method $methodName($method), Comment '$comment', Streamed $streamed. Zip64 $zip64";

                        skip "Skipping method $methodNames{$method} ($method): No uncompressor installed", 85
                            if ! $methodName && $method == ZIP_CM_ZSTD ;

                        skip "Skipping method $methodNames{$method} ($method): No uncompressor installed", 113
                            if ! $methodName ;

                        skip "Skipping Zstd with Streaming", 57
                            if  $method == ZIP_CM_ZSTD && $streamed;

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

                        my $create =
                            [
                                #[ Name => "fred", Payload => "abcd"],
                                # name     payload   type   opts
                                [ "fred1", "abcd1", 'file', [] ],
                                [ "fred2", "abcd2", 'file', [Comment => "member comment"] ],
                                [ "fred3", "abcd3", 'file', [Comment => ''] ],
                                [ "dir2/", "",      'dir',  [] ],
                                [ "empty", "",      'file', [] ],
                            ] ;

                        createZip($zipfile, $create, { ZipComment => $comment,
                                                    Method     => $method,
                                                    Stream     => $streamed,
                                                    Zip64      => $zip64
                                                    } ) ;

                        my $z = new Archive::Zip::StreamedUnzip $zipfile ;
                        isa_ok $z, "Archive::Zip::StreamedUnzip";


                        my $element ;
                        my @got = ();
                        my $payload = '';
                        my $index = 0;

                        {
                            # fred1
                            my $input = $create->[$index ++] ;
                            my $name = $input->[0];
                            my $expected = $input->[1];
                            my $expectedType = $input->[2];

                            $element = $z->next();
                            isa_ok $element, "Archive::Zip::StreamedUnzip::Member";
                            is $element->name(), $name, "Name is '$name'";
                            is $element->content(), $expected, "Payload ok in '$name'";
                            ok testType($element, $expectedType), "Type is '$expectedType'";
                            ok $element->close();
                        }

                        {
                            # fred2
                            my $input = $create->[$index ++] ;
                            my $name = $input->[0];
                            my $expected = $input->[1];
                            my $expectedType = $input->[2];

                            my $element = $z->next();
                            isa_ok $element, "Archive::Zip::StreamedUnzip::Member";
                            is $element->name(), $name, "Name is '$name'";
                            ok testType($element, $expectedType), "Type is '$expectedType'";

                            my $fh = $element->open();
                            isa_ok $fh, "Archive::Zip::StreamedUnzip::Handle";
                            ok !$fh->eof(), "!eof";
                            ok ! eof($fh), "!eof";
                            is tell($fh), 0, "tell == 0";
                            is $fh->tell(), 0, "tell == 0";

                            is $fh->read($payload, 1024), length($expected);
                            is tell($fh), length($expected), "tell == 5"
                                or diag $StreamedUnzipError ;
                            ok $fh->eof(), "eof";
                            ok eof($fh), "eof";

                            is $payload, $expected, "payload ok in '$name'";
                        }

                        {
                            # fred3
                            my $input = $create->[$index ++] ;
                            my $name = $input->[0];
                            my $expected = $input->[1];
                            my $expectedType = $input->[2];

                            $element = $z->next();
                            isa_ok $element, "Archive::Zip::StreamedUnzip::Member";
                            is $element->name(), $name, "Name is '$name'";
                            ok testType($element, $expectedType), "Type is '$expectedType'";

                            my $fh = $element->open();
                            is $fh->tell(), 0;
                            ok !$fh->eof();
                            local $/;
                            $payload = <$fh>;
                            ok $fh->eof();
                            is $fh->tell(), length($expected);
                            is $payload, $expected, "Payload ok in '$name'";
                        }

                        {
                            # dir
                            my $input = $create->[$index ++] ;
                            my $name = $input->[0];
                            my $expected = $input->[1];
                            my $expectedType = $input->[2];

                            $element = $z->next();
                            isa_ok $element, "Archive::Zip::StreamedUnzip::Member";
                            is $element->name(), $name, "Name is '$name'";
                            ok testType($element, $expectedType), "Type is '$expectedType'";

                            is $element->content(), $expected, "Payload ok in '$name'";
                        }

                        {
                            # empty
                            my $input = $create->[$index ++] ;
                            my $name = $input->[0];
                            my $expected = $input->[1];
                            my $expectedType = $input->[2];

                            $element = $z->next();
                            isa_ok $element, "Archive::Zip::StreamedUnzip::Member";
                            is $element->name(), $name, "Name is '$name'";
                            ok testType($element, $expectedType), "Type is '$expectedType'";

                            is $element->content(), $expected, "Payload ok in '$name'";
                        }

                        {
                            $element = $z->next();
                            ok ! defined $element, "No next";
                        }

                        # {
                        #     my $input = $create->[0] ;
                        #     my $name = $input->[0];
                        #     my $expected = $input->[1];
                        #     my $expectedType = $input->[2];

                        #     my $element = $z->member($name);
                        #     isa_ok $element, "Archive::Zip::StreamedUnzip::Member";
                        #     is $element->name(), $name, "Name is '$name'";
                        #     ok testType($element, $expectedType), "Type is '$expectedType'";

                        #     my $fh = $element->open();
                        #     is $fh->tell(), 0;
                        #     ok !$fh->eof();
                        #     my $payload = '';
                        #     my $x;

                        #     my $ix = 1;
                        #     while ($fh->read($x, 1))
                        #     {
                        #         $payload .= $x ;
                        #         is $fh->tell(), $ix ++;
                        #     }
                        #     ok $fh->eof();
                        #     is $fh->tell(), length($expected);
                        #     is $payload, $expected, "Payload ok in '$name'";
                        # }


                        ok $z->close, "closed ok";



                    }


                }
            }
        }
    }
}


# exit;

my $TestZipsDir = "./t/test-zips/";

SKIP:
{
    skip "Skipping BIG tests", 42
        if ! -d $TestZipsDir;

    if (1)
    {
        title "Zip file with exactly 64k members (but not Zip64)" ;

        my $z = new Archive::Zip::StreamedUnzip "$TestZipsDir/test64k-notzip64.zip" ;
        isa_ok $z, "Archive::Zip::StreamedUnzip";

        my $expectedMembers = 0xFFFF;

        my $index = 1 ;
        while (my $member = $z->next())
        {
            last if $member->name() ne "$index" ;
            last if $member->content() ne "$index" ;
            ++ $index ;
        }

        is $index, $expectedMembers+1, "Matched with $expectedMembers";
    }


    if (1)
    {
        title "Zip file with exactly 64k members (is Zip64)" ;

        my $z = new Archive::Zip::StreamedUnzip "$TestZipsDir/test64k.zip" ;
        isa_ok $z, "Archive::Zip::StreamedUnzip";

        my $expectedMembers = 0xFFFF;


        my $index = 1 ;
        while (my $member = $z->next())
        {
            last if $member->name() ne "$index" ;
            last if $member->content() ne  "$index" ;
            ++ $index ;
        }

        is $index, $expectedMembers+1, "Matched with $expectedMembers";
    }


    if (1)
    {
        title "Zip file with  64k + 1 members (must be Zip64)" ;

        my $z = new Archive::Zip::StreamedUnzip "$TestZipsDir/test64k-plus1.zip" ;
        isa_ok $z, "Archive::Zip::StreamedUnzip";

        my $expectedMembers = 0xFFFF + 1;

        my $index = 1 ;
        while (my $member = $z->next())
        {
            last if $member->name() ne "$index" ;
            last if $member->content() ne  "$index" ;
            ++ $index ;
        }

        is $index, $expectedMembers+1, "Matched with $expectedMembers";
    }


    # SKIP:
    if (1)
    {
        my $max32 = 0xFFFFFFFF;
        my @inputs = (
                    # Fist file > 4Gig, plus a small file
                    [ "big1.zip", "zipcomment",
                                        ["first",   "",  [$max32 +1, $max32+1] ],
                                        ["second", "c2", "data"                 ],
                    ],
                    # Combination of files makes archive > 4Gig
                    [ "big2.zip", "", ["first",   "",  [0x80000000, 0x80000000] ],
                                        ["second", "",   "data"                   ],
                                        ["third",  "",   [0x80000000, 0x80000000]],
                                        ["fourth",  "",  "fore"],
                    ],
                    # Uncompressed size >4 Gig, compressed <4Gig
                    [ "big3.zip", "", ["zeros",   "",  [$max32+101, 0x003F99DD ] ],
                    ],
                    # Empry archive - Only thing present is end central header, with zero entries
                    [ "empty.zip", "",
                    ],
                    # Empry archive - Only thing present is end central header, with zero entries
                    [ "empty-with-comment.zip", "zipcomment",
                    ],

        ) ;

        for my $in (@inputs)
        {
            my $zipfile = $TestZipsDir . shift @$in;
            my $comment = shift @$in;
            my $entries = @$in ;
            my @names   = map { $_->[0] } @$in ;

            my $z = new Archive::Zip::StreamedUnzip $zipfile ;
            isa_ok $z, "Archive::Zip::StreamedUnzip", "created object for file $zipfile";
            for my $m (@$in)
            {
                my $mname = shift @$m;
                my $mcomment = shift @$m;
                my $payload = shift @$m;

                my $member = $z->member($mname);
                isa_ok $member, "Archive::Zip::StreamedUnzip::Member";
                is $member->name(), $mname, "Member Name is '$mname'" ;
                if (ref $payload eq 'ARRAY')
                {
                    # check lengths
                    my $uncompSize = shift @$payload;
                    my $compSize = shift @$payload;
                    is $member->uncompressedSize(), $uncompSize, "uncompressedSize is $uncompSize";
                    is $member->compressedSize(), $compSize, "compressedSize is $compSize";
                }
                else
                {
                    is $member->content(), $payload, "Payload ok";
                    is $member->uncompressedSize(), length($payload), "uncompressedSize is ";
                }
            }
        }
    }

}



exit;