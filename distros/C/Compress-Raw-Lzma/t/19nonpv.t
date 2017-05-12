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

BEGIN 
{ 
    # use Test::NoWarnings, if available
    my $extra = 0 ;
    $extra = 1
        if eval { require Test::NoWarnings ;  import Test::NoWarnings; 1 };

    plan tests => 77 + $extra ;

    use_ok('Compress::Raw::Lzma') ;
}
 


sub doit
{

    my $compress_class = shift;
    my $uncompress_class = shift;    

    title  "$compress_class - non-PV buffers";
    # ==============================

    my $hello = *hello;
    $hello = *hello;
    my ($err, $x, $X, $status); 
 
    ($x, $err) = $compress_class->new();
    isa_ok $x, "Compress::Raw::Lzma::Encoder";
    cmp_ok $err, '==', LZMA_OK, "status is LZMA_OK" ;
 
    is $x->uncompressedBytes(), 0, "uncompressedBytes() == 0" ;
    is $x->compressedBytes(), 0, "compressedBytes() == 0" ;

    $X = "" ;
    my $Answer = *Answer;
    $Answer = *Answer;
    $status = $x->code($hello, $Answer) ;
    
     
    cmp_ok $status, '==', LZMA_OK, "code returned LZMA_OK" ;
    
    $X = *X;
    cmp_ok  $x->flush($X), '==', LZMA_STREAM_END, "flush returned LZMA_OK" ;
    $Answer .= $X ;
     
    is $x->uncompressedBytes(), length $hello, "uncompressedBytes ok" ;
    is $x->compressedBytes(), length $Answer, "compressedBytes ok" ;
     
    $X = *X;
    cmp_ok $x->flush($X), '==', LZMA_STREAM_END, "flush returned LZMA_STREAM_END";
    $Answer .= $X ;

    #open F, ">/tmp/xx1"; print F $Answer ; close F;
    my @Answer = split('', $Answer) ;
     
    my $k;
    ok(($k, $err) = $uncompress_class->new(AppendOutput => 0,
                                           ConsumeInput => 0));
    isa_ok $k, "Compress::Raw::Lzma::Decoder" ;
    cmp_ok $err, '==', LZMA_OK, "status is LZMA_OK" 
        or diag "GOT $err\n";
 
    is $k->compressedBytes(), 0, "compressedBytes() == 0" ;
    is $k->uncompressedBytes(), 0, "uncompressedBytes() == 0" ;
    my $GOT = *GOT;
    $GOT = *GOT;
    $status = $k->code($Answer, $GOT) ;
     
    cmp_ok $status, '==', LZMA_STREAM_END, "Got LZMA_STREAM_END" ;
    is $GOT, $hello, "uncompressed data matches ok" ;
    is $k->compressedBytes(), length $Answer, "compressedBytes ok" ;
    is $k->uncompressedBytes(), length $hello , "uncompressedBytes ok";

}

for my $class ([qw(AloneEncoder AloneDecoder)], 
               [qw(StreamEncoder StreamDecoder)], 
               [qw(RawEncoder RawDecoder)] ,
               [qw(EasyEncoder AutoDecoder)] ,
           )
{
    my $c = "Compress::Raw::Lzma::" . $class->[0];
    my $u = "Compress::Raw::Lzma::" . $class->[1];
    doit $c, $u;
}
