BEGIN {
    if ($ENV{PERL_CORE}) {
	chdir 't' if -d 't';
    #@INC = ("../lib", "lib/compress");
	@INC = ("../lib");
    }
}

use lib 't';
use strict;
use warnings;
use bytes;

use Test::More  ;
#use CompTestUtils;


BEGIN 
{ 
    # use Test::NoWarnings, if available
    my $extra = 0 ;
    $extra = 1
        if eval { require Test::NoWarnings ;  import Test::NoWarnings; 1 };


    my $count = 0 ;
    if ($] < 5.005) {
        $count = 103 ;
    }
    elsif ($] >= 5.006) {
        $count = 689 ;
    }
    else {
        $count = 131 ;
    }

    plan tests => $count + $extra;

    use_ok('Compress::Raw::Lzma') ;
}

sub title
{
    #diag "" ;
    ok 1, $_[0] ;
    #diag "" ;
}

sub mkErr
{
    my $string = shift ;
    my ($dummy, $file, $line) = caller ;
    -- $line ;

    $string = quotemeta $string;
    $file = quotemeta($file);

    #return "/$string\\s+at $file line $line/" if $] >= 5.006 ;
    return "/$string\\s+at /" ;
}

sub mkEvalErr
{
    my $string = shift ;

    return "/$string\\s+at \\(eval /" if $] > 5.006 ;
    return "/$string\\s+at /" ;
}


sub doit
{
    my $compress_class = shift;
    my $uncompress_class = shift;

    title  "$compress_class and $uncompress_class";

    my $hello = <<EOM ;
hello world
this is a test
EOM

    my $len   = length $hello ;

    if (0)
    {
        title "Error Cases" ;

        eval { $compress_class->new(1,2,3,4,5,6) };
        like $@,  mkErr "Usage: Compress::Raw::Lzma::lzma_alone_encoder(class, appendOut=1)";

    }


    if (1)
    {

        title  "lzma - small buffer";
        # ==============================

        my $hello = "I am a HAL 9000 computer" ;
        my @hello = split('', $hello) ;
        my ($err, $x, $X, $status); 
     
        ($x, $err) = $compress_class->new();
        isa_ok $x, "Compress::Raw::Lzma::Encoder";
        cmp_ok $err, '==', LZMA_OK, "status is LZMA_OK" ;
     
        is $x->uncompressedBytes(), 0, "uncompressedBytes() == 0" ;
        is $x->compressedBytes(), 0, "compressedBytes() == 0" ;

        $X = "" ;
        my $Answer = '';
        foreach (@hello)
        {
            $status = $x->code($_, $X) ;
            last unless $status == LZMA_OK ;
        
            $Answer .= $X ;
        }
         
        cmp_ok $status, '==', LZMA_OK, "code returned LZMA_OK" ;
        
        cmp_ok  $x->flush($X), '==', LZMA_STREAM_END, "flush returned LZMA_OK" ;
        $Answer .= $X ;
         
        is $x->uncompressedBytes(), length $hello, "uncompressedBytes ok" ;
        is $x->compressedBytes(), length $Answer, "compressedBytes ok" ;
         
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
        my $GOT = '';
        my $Z;
        $Z = 1 ;#x 2000 ;
        foreach (@Answer)
        {
            $status = $k->code($_, $Z) ;
            $GOT .= $Z ;
            last if $status == LZMA_STREAM_END or $status != LZMA_OK ;
         
        }
         
        cmp_ok $status, '==', LZMA_STREAM_END, "Got LZMA_STREAM_END" ;
        is $GOT, $hello, "uncompressed data matches ok" ;
        is $k->compressedBytes(), length $Answer, "compressedBytes ok" ;
        is $k->uncompressedBytes(), length $hello , "uncompressedBytes ok";

    }


    if (1)
    {
        # bzdeflate/bzinflate - small buffer with a number
        # ==============================

        my $hello = 6529 ;
     
        ok  my ($x, $err) = $compress_class->new(AppendOutput => 1) ;
        ok $x ;
        cmp_ok $err, '==', LZMA_OK ;
     
        my $status;
        my $Answer = '';
         
        cmp_ok $x->code($hello, $Answer), '==', LZMA_OK ;
        
        cmp_ok $x->flush($Answer), '==', LZMA_STREAM_END, "flush returned LZMA_STREAM_END";
         
        my @Answer = split('', $Answer) ;
         
        my $k;
        ok(($k, $err) = $uncompress_class->new(AppendOutput => 1,
                                                         ConsumeInput => 0) );
        ok $k ;
        cmp_ok $err, '==', LZMA_OK ;
         
        #my $GOT = '';
        my $GOT ;
        foreach (@Answer)
        {
            $status = $k->code($_, $GOT) ;
            last if $status == LZMA_STREAM_END or $status != LZMA_OK ;
         
        }
         
        cmp_ok $status, '==', LZMA_STREAM_END ;
        is $GOT, $hello ;

    }

    if(1)
    {

    # bzdeflate/bzinflate options - AppendOutput
    # ================================

        # AppendOutput
        # CRC

        my $hello = "I am a HAL 9000 computer" ;
        my @hello = split('', $hello) ;
         
        ok  my ($x, $err) = $compress_class->new(AppendOutput => 1), "  Created lzma object" ;
        ok $x ;
        cmp_ok $err, '==', LZMA_OK, "Status is LZMA_OK" ;
         
        my $status;
        my $X;
        foreach (@hello)
        {
            $status = $x->code($_, $X) ;
            last unless $status == LZMA_OK ;
        }
         
        cmp_ok $status, '==', LZMA_OK ;
         
        cmp_ok $x->flush($X), '==', LZMA_STREAM_END ;
         
         
        my @Answer = split('', $X) ;
         
        my $k;
        ok(($k, $err) = $uncompress_class->new( {-AppendOutput =>1}));
        ok $k ;
        cmp_ok $err, '==', LZMA_OK ;
         
        my $Z;
        foreach (@Answer)
        {
            $status = $k->code($_, $Z) ;
            last if $status == LZMA_STREAM_END or $status != LZMA_OK ;
         
        }
         
        cmp_ok $status, '==', LZMA_STREAM_END ;
        is $Z, $hello ;
    }

     
    if(1)
    {

        title "lzma - larger buffer";
        # ==============================

        # generate a long random string
        my $contents = '' ;
        foreach (1 .. 50000)
          { $contents .= chr int rand 255 }
        
        
        ok my ($x, $err) = $compress_class->new(AppendOutput => 0) ;
        ok $x, "  lzma object ok" ;
        cmp_ok $err, '==', LZMA_OK,"  status is LZMA_OK" ;
         
        is $x->uncompressedBytes(), 0, "  uncompressedBytes() == 0" ;
        is $x->compressedBytes(), 0, "  compressedBytes() == 0" ;

        my (%X, $Y, %Z, $X, $Z);
        #cmp_ok $x->code($contents, $X{key}), '==', LZMA_OK ;
        my $status =  $x->code($contents, $X);
        #cmp_ok $x->code($contents, $X), '==', LZMA_OK, "  compressed ok" ;
        cmp_ok $status, '==', LZMA_OK, "  compressed ok" ;
        
        #$Y = $X{key} ;
        $Y = $X ;
         
         
        #cmp_ok $x->flush($X{key}), '==', LZMA_OK ;
        #$Y .= $X{key} ;
        cmp_ok $x->flush($X), '==', LZMA_STREAM_END ;
        $Y .= $X ;
         
         
     
        my $keep = $Y ;

        my $k;
        ok(($k, $err) = $uncompress_class->new(AppendOutput => 0,
                                                         ConsumeInput => 0) );
        ok $k ;
        cmp_ok $err, '==', LZMA_OK ;
         
        #cmp_ok $k->code($Y, $Z{key}), '==', LZMA_STREAM_END ;
        #ok $contents eq $Z{key} ;
        cmp_ok $k->code($Y, $Z), '==', LZMA_STREAM_END ;
        ok $contents eq $Z ;

        # redo deflate with AppendOutput

        ok (($k, $err) = $uncompress_class->new(AppendOutput => 1,
                                                          ConsumeInput => 0)) ;
        ok $k ;
        cmp_ok $err, '==', LZMA_OK ;
        
        my $s ; 
        my $out ;
        my @bits = split('', $keep) ;
        foreach my $bit (@bits) {
            $s = $k->code($bit, $out) ;
        }
        
        cmp_ok $s, '==', LZMA_STREAM_END ;
         
        ok $contents eq $out ;


    }


    for my $consume ( 0 .. 1)
    {
        title "lzma - check remaining buffer after LZMA_STREAM_END, Consume $consume";

        ok my $x = $compress_class->new(AppendOutput => 0) ;
     
        my ($X, $Y, $Z);
        cmp_ok $x->code($hello, $X), '==', LZMA_OK;
        cmp_ok $x->flush($Y), '==', LZMA_STREAM_END;
        $X .= $Y ;
     
        ok my $k = $uncompress_class->new(AppendOutput => 0,
                                                    ConsumeInput => $consume) ;
     
        my $first = substr($X, 0, 2) ;
        my $remember_first = $first ;
        my $last  = substr($X, 2) ;
        cmp_ok $k->code($first, $Z), '==', LZMA_OK;
        if ($consume) {
            ok $first eq "" ;
        }
        else {
            ok $first eq $remember_first ;
        }

        my $T ;
        $last .= "appendage" ;
        my $remember_last = $last ;
        cmp_ok $k->code($last, $T),  '==', LZMA_STREAM_END;
        is $hello, $Z . $T  ;
        if ($consume) {
            is $last, "appendage" ;
        }
        else {
            is $last, $remember_last ;
        }

    }


    {
        title "ConsumeInput and a read-only buffer trapped" ;

        ok my $k = $uncompress_class->new(AppendOutput => 0,
                                                    ConsumeInput => 1) ;
         
        my $Z; 
        eval { $k->code("abc", $Z) ; };
        like $@, mkErr("Compress::Raw::Lzma::Decoder::code input parameter cannot be read-only when ConsumeInput is specified");

    }

    foreach (1 .. 2)
    {
        next if $] < 5.005 ;

        title 'test lzma with a substr';

        my $contents = '' ;
        foreach (1 .. 5000)
          { $contents .= chr int rand 255 }
        ok  my $x = $compress_class->new(AppendOutput => 1) ;
         
        my $X ;
        my $status = $x->code(substr($contents,0), $X);
        cmp_ok $status, '==', LZMA_OK ;
        
        cmp_ok $x->flush($X), '==', LZMA_STREAM_END  ;
         
        my $append = "Appended" ;
        $X .= $append ;
         
        ok my $k = $uncompress_class->new(AppendOutput => 1,
                                                    ConsumeInput => 1) ;
         
        my $Z; 
        my $keep = $X ;
        $status = $k->code(substr($X, 0), $Z) ;
         
        cmp_ok $status, '==', LZMA_STREAM_END ;
        #print "status $status X [$X]\n" ;
        is $contents, $Z ;
        ok $X eq $append;
        #is length($X), length($append);
        #ok $X eq $keep;
        #is length($X), length($keep);
    }

    title 'Looping Append test - checks that deRef_l resets the output buffer';
    foreach (1 .. 2)
    {

        my $hello = "I am a HAL 9000 computer" ;
        my @hello = split('', $hello) ;
        my ($err, $x, $X, $status); 
     
        ok( ($x, $err) = $compress_class->new(AppendOutput => 0) );
        ok $x ;
        cmp_ok $err, '==', LZMA_OK ;
     
        $X = "" ;
        my $Answer = '';
        foreach (@hello)
        {
            $status = $x->code($_, $X) ;
            last unless $status == LZMA_OK ;
        
            $Answer .= $X ;
        }
         
        cmp_ok $status, '==', LZMA_OK ;
        
        cmp_ok  $x->flush($X), '==', LZMA_STREAM_END ;
        $Answer .= $X ;
         
        my @Answer = split('', $Answer) ;
         
        my $k;
        ok(($k, $err) = $uncompress_class->new(AppendOutput => 1,
                                                        ConsumeInput => 0) );
        ok $k ;
        cmp_ok $err, '==', LZMA_OK ;
     
        my $GOT ;
        my $Z;
        $Z = 1 ;#x 2000 ;
        foreach (@Answer)
        {
            $status = $k->code($_, $GOT) ;
            last if $status == LZMA_STREAM_END or $status != LZMA_OK ;
        }
         
        cmp_ok $status, '==', LZMA_STREAM_END ;
        is $GOT, $hello ;

    }

    if ($] >= 5.005)
    {
        title 'test lzma input parameter via substr';

        my $hello = "I am a HAL 9000 computer" ;
        my $data = $hello ;

        my($X, $Z);

        ok my $x = $compress_class->new(AppendOutput => 1);

        cmp_ok $x->code($data, $X), '==',  LZMA_OK ;

        cmp_ok $x->flush($X), '==', LZMA_STREAM_END ;
         
        my $append = "Appended" ;
        $X .= $append ;
        my $keep = $X ;
         
        ok my $k = $uncompress_class->new( AppendOutput => 1,
                                                    ConsumeInput => 1);
         
    #    cmp_ok $k->code(substr($X, 0, -1), $Z), '==', LZMA_STREAM_END ; ;
        cmp_ok $k->code(substr($X, 0), $Z), '==', LZMA_STREAM_END ; ;
         
        ok $hello eq $Z ;
        is $X, $append;
        
        $X = $keep ;
        $Z = '';
        ok $k = $uncompress_class->new( AppendOutput => 1,
                                                    ConsumeInput => 0);
         
        cmp_ok $k->code(substr($X, 0, -1), $Z), '==', LZMA_STREAM_END ; ;
        #cmp_ok $k->code(substr($X, 0), $Z), '==', LZMA_STREAM_END ; ;
         
        ok $hello eq $Z ;
        is $X, $keep;
        
    }

    exit if $] < 5.006 ;

    title 'Looping Append test with substr output - substr the end of the string';
    foreach (1 .. 2)
    {

        my $hello = "I am a HAL 9000 computer" ;
        my @hello = split('', $hello) ;
        my ($err, $x, $X, $status); 
     
        ok( ($x, $err) = $compress_class->new (AppendOutput => 1) );
        ok $x ;
        cmp_ok $err, '==', LZMA_OK ;
     
        $X = "" ;
        my $Answer = '';
        foreach (@hello)
        {
            $status = $x->code($_, substr($Answer, length($Answer))) ;
            last unless $status == LZMA_OK ;
        
        }
         
        cmp_ok $status, '==', LZMA_OK ;
        
        cmp_ok  $x->flush(substr($Answer, length($Answer))), '==', LZMA_STREAM_END ;
         
        my @Answer = split('', $Answer) ;
         
        my $k;
        ok(($k, $err) = $uncompress_class->new(AppendOutput => 1,
                                                        ConsumeInput => 0) );
        ok $k ;
        cmp_ok $err, '==', LZMA_OK ;
     
        my $GOT = '';
        my $Z;
        $Z = 1 ;#x 2000 ;
        foreach (@Answer)
        {
            $status = $k->code($_, substr($GOT, length($GOT))) ;
            last if $status == LZMA_STREAM_END or $status != LZMA_OK ;
        }
         
        cmp_ok $status, '==', LZMA_STREAM_END ;
        is $GOT, $hello ;

    }

    title 'Looping Append test with substr output - substr the complete string';
    foreach (1 .. 2)
    {

        my $hello = "I am a HAL 9000 computer" ;
        my @hello = split('', $hello) ;
        my ($err, $x, $X, $status); 
     
        ok( ($x, $err) = $compress_class->new (AppendOutput => 1) );
        ok $x ;
        cmp_ok $err, '==', LZMA_OK ;
     
        $X = "" ;
        my $Answer = '';
        foreach (@hello)
        {
            $status = $x->code($_, substr($Answer, 0)) ;
            last unless $status == LZMA_OK ;
        
        }
         
        cmp_ok $status, '==', LZMA_OK ;
        
        cmp_ok  $x->flush(substr($Answer, 0)), '==', LZMA_STREAM_END ;
         
        my @Answer = split('', $Answer) ;
         
        # append, consume, limit
        my $k;
        ok(($k, $err) = $uncompress_class->new(AppendOutput => 1,
                                                        ConsumeInput => 0) );
        ok $k ;
        cmp_ok $err, '==', LZMA_OK ;
     
        my $GOT = '';
        my $Z;
        $Z = 1 ;#x 2000 ;
        foreach (@Answer)
        {
            $status = $k->code($_, substr($GOT, 0)) ;
            last if $status == LZMA_STREAM_END or $status != LZMA_OK ;
        }
         
        cmp_ok $status, '==', LZMA_STREAM_END ;
        is $GOT, $hello ;
    }

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
