BEGIN {
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = ("../lib", "lib/compress");
    }
}

use lib qw(t t/compress);
use strict;
use warnings;
use bytes;

use Test::More ;
use CompTestUtils;

my $XZ ;

sub ExternalXzWorks
{
    my $lex = new LexFile my $outfile;
    my $content = qq {
Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Ut tempus odio id
 dolor. Camelus perlus.  Larrius in lumen numen.  Dolor en quiquum filia
 est.  Quintus cenum parat.
};

    my $compressed;
    writeWithXz($content, $compressed)
        or return 0;

    writeFile($outfile, $compressed);
    
    my $got;
    readWithXz($outfile, $got)
        or return 0;

    if ($content ne $got)
    {
        diag "Uncompressed content is wrong";
        return 0 ;
    }

    return 1 ;
}

sub rdFile
{
    my $f = shift ;

    my @strings ;

    {
        open (F, "<$f") 
            or croak "Cannot open $f: $!\n" ;
        binmode F;
        @strings = <F> ;	
        close F ;
    }

    return @strings if wantarray ;
    return join "", @strings ;
}


sub readWithXz
{
    my $file = shift ;
    my $opts = $_[1] || "";

    my $lex = new LexFile my $outfile;

    my $comp = "$XZ -dc $opts 2>/dev/null" ;

    if (system("$comp $file >$outfile") == 0 )
    {
        $_[0] = rdFile($outfile);
        return 1 ;
    }

    diag "'$comp' failed: $?";
    return 0 ;
}

sub writeWithXz
{
    my $content = shift ;
    my $output = \$_[0] ;
    my $options = $_[1] || '';

    my $lex1 = new LexFile my $infile;
    my $lex2 = new LexFile my $outfile;
    writeFile($infile, $content);

    my $comp = "$XZ -c $options $infile >$outfile 2>/dev/null" ;

    if (system($comp) == 0)
    {
        $$output = rdFile($outfile);
        return 1 ;
    }

    diag "'$comp' failed: $?";
    return 0 ;
}

BEGIN 
{

    # Check external xz is available
    my $name = $^O =~ /mswin/i ? 'xz.exe' : 'xz';
    my $split = $^O =~ /mswin/i ? ";" : ":";

    for my $dir (reverse split $split, $ENV{PATH})    
    {
        $XZ = "$dir/$name"
            if -x "$dir/$name" ;
    }

    # Handle spaces in path to xz 
    $XZ = "\"$XZ\"" if defined $XZ && $XZ =~ /\s/;    

    plan(skip_all => "Cannot find $name")
        if ! $XZ ;

    plan(skip_all => "$name doesn't work as expected")
        if ! ExternalXzWorks();
    
    # use Test::NoWarnings, if available
    my $extra = 0 ;
    $extra = 1
        if eval { require Test::NoWarnings ;  import Test::NoWarnings; 1 };

    plan tests => 1006 + $extra ;

    use_ok('Compress::Raw::Lzma') ;

}

sub compressWith
{
    my $class = shift;
    my $xz_opts = shift;
    my %opts = @_ ;

    my $contents = '' ;
    foreach (1 .. 5000)
      { $contents .= chr int rand 255 }
    
    
    my ($x, $err) = $class->new(AppendOutput => 1, %opts) ;

    SKIP:
    {
        skip "Not Enough Memory", 7 if $err == LZMA_MEM_ERROR;

        isa_ok $x, $class;
        isa_ok $x, "Compress::Raw::Lzma::Encoder";

        cmp_ok $err, '==', LZMA_OK,"  status is LZMA_OK" 
            or diag "Error is $err";
         
        my (%X, $Y, %Z, $X, $Z);
        cmp_ok $x->code($contents, $X), '==', LZMA_OK, "  compressed ok" ;
        
        cmp_ok $x->flush($X), '==', LZMA_STREAM_END, "  flushed ok" ;
         
        my $lex = new LexFile my $file;
        writeFile($file, $X);
        
        my $got = '';
        ok readWithXz($file, $got, $xz_opts), "  readWithXz returns 0";
        is $got, $contents, "  got content";
    }
}

sub uncompressWith
{
    my $class = shift;
    my $xz_opts = shift;
    my %opts = @_ ;

    my $contents = '' ;
    foreach (1 .. 5000)
      { $contents .= chr int rand 255 }
    
    
    my $compressed;  
    writeWithXz($contents, $compressed, $xz_opts);

    my ($x, $err) = $class->new(AppendOutput => 1, %opts) ;
    isa_ok $x, $class;
    isa_ok $x, "Compress::Raw::Lzma::Decoder";
    cmp_ok $err, '==', LZMA_OK,"  status is LZMA_OK" ;
     
    my $got = '';
    cmp_ok $x->code($compressed, $got), '==', LZMA_STREAM_END, "  compressed ok" ;
    
    #is $got, $contents, "got content";
    ok $got eq $contents, "  got content";
}

{
    title "Test AloneEncoder interop with xz" ;

    compressWith('Compress::Raw::Lzma::AloneEncoder', '-F auto');

    compressWith('Compress::Raw::Lzma::AloneEncoder', '-F auto',
            Filter => Lzma::Filter::Lzma1 );

#    # Error
#    eval {
#        compressWith('Compress::Raw::Lzma::AloneEncoder', '-F auto',
#            Filter => Lzma::Filter::X86);
#    };
#    like $@,  mkErr("filter is not an Lzma::Filter::Lzma1 object"), " catch error";

    compressWith('Compress::Raw::Lzma::AloneEncoder', '-F auto',
            Filter => Lzma::Filter::Lzma1(
                #DictSize   => 1024 * 100,
                Lc         => LZMA_LCLP_MAX,
                #Lp         => 3,
                Pb         => LZMA_PB_MAX,
                Mode       => LZMA_MODE_FAST,
                Nice       => 128,
                Mf         => LZMA_MF_HC4,
                Depth      => 77
                )
            )  ;

    sub compressAloneWithParam
    {
        my $name = shift;
        my $range = shift;

        for my $value (@$range)
        {
            title "test $name with $value";
            compressWith('Compress::Raw::Lzma::AloneEncoder', '-F auto',
                Filter => Lzma::Filter::Lzma1($name, $value)
                )  ;
        }
    }

    compressAloneWithParam "Lc", [ 0 .. 4 ];
    #compressAloneWithParam "Lp", [ 0 .. 4 ];
    compressAloneWithParam "Mode", [ LZMA_MODE_NORMAL, LZMA_MODE_FAST ];
    compressAloneWithParam "Mf", [ LZMA_MF_HC3, LZMA_MF_HC4, LZMA_MF_BT2, 
                              LZMA_MF_BT3, LZMA_MF_BT4];
    #compressAloneWithParam "Nice", [ 2 .. 273 ];
    #compressAloneWithParam "Depth", [ 2 .. 273 ];
}


{
    # EasyEncoder

    for my $check (LZMA_CHECK_NONE, LZMA_CHECK_CRC32, LZMA_CHECK_CRC64, LZMA_CHECK_SHA256)
    {
        for my $extreme (0 .. 1)
        {
            for my $preset (0 .. 9)
            {
                title "Test EasyEncoder interop with xz, Check $check, Extreme $extreme, Preset $preset" ;
                compressWith('Compress::Raw::Lzma::EasyEncoder', '-F xz',
                                Check => $check, 
                                Extreme => $extreme,
                                Preset => $preset);
            }
        }
    }
}


my @Filters = (
                ["Lzma2",               [ Lzma::Filter::Lzma2
                                        ]
                ],
                ["x86 + Lzma2",         [ Lzma::Filter::X86, 
                                          Lzma::Filter::Lzma2
                                        ]
                ],
                ["x86 + Delta + Lzma2", [ Lzma::Filter::X86, 
                                          Lzma::Filter::Delta,
                                          Lzma::Filter::Lzma2
                                        ]
                ],
                ["x86 + Delta + x86 + Lzma2", [ Lzma::Filter::X86, 
                                          Lzma::Filter::Delta,
                                          Lzma::Filter::X86,
                                          Lzma::Filter::Lzma2
                                        ]
                ],
              );
    
{
    # StreamEncoder

    for my $check (LZMA_CHECK_NONE LZMA_CHECK_CRC32 LZMA_CHECK_CRC64 LZMA_CHECK_SHA256)
    {
        for my $f (@Filters)
        {
            my ($name, $filter) = @$f;
            title "Test StreamEncoder interop with xz, Filter '$name' Check $check" ;
            compressWith('Compress::Raw::Lzma::StreamEncoder', '-F xz',
                                Check => $check, 
                                Filter => $filter, 
                            );
        }
    }

    compressWith('Compress::Raw::Lzma::StreamEncoder', '-F auto',
            Filter => Lzma::Filter::Lzma2(
                #DictSize   => 44,
                Lc         => LZMA_LCLP_MAX,
                #Lp         => 3,
                Pb         => LZMA_PB_MAX,
                Mode       => LZMA_MODE_FAST,
                Nice       => 128,
                Mf         => LZMA_MF_HC4,
                Depth      => 77)
            ) ;

    sub compressStreamWithParam
    {
        my $name = shift;
        my $range = shift;

        for my $value (@$range)
        {
            title "test $name with $value";
            compressWith('Compress::Raw::Lzma::StreamEncoder', '-F auto',
                Filter => Lzma::Filter::Lzma2($name, $value)
                )  ;
        }
    }

    compressStreamWithParam "Lc", [ 0 .. 4 ];
    #compressStreamWithParam "Lp", [ 0 .. 4 ];
    compressStreamWithParam "Mode", [ LZMA_MODE_NORMAL, LZMA_MODE_FAST ];
    compressStreamWithParam "Mf", [ LZMA_MF_HC3, LZMA_MF_HC4, LZMA_MF_BT2, 
                              LZMA_MF_BT3, LZMA_MF_BT4];
    #compressStreamWithParam "Nice", [ 2 .. 273 ];
    #compressStreamWithParam "Depth", [ 2 .. 273 ];
}

{
    title "Test RawEncoder interop with xz" ;

    compressWith('Compress::Raw::Lzma::RawEncoder', '-F raw');

    sub compressRawWithParam
    {
        my $name = shift;
        my $range = shift;
        my $xz_opts = shift || "";
        my $xz_values = shift || $range;

        for my $value (@$range)
        {
            my $xz_value = shift @$xz_values;
            title "test $name with $value";
            compressWith('Compress::Raw::Lzma::RawEncoder', 
                "-F raw $xz_opts=$xz_value",
                Filter => Lzma::Filter::Lzma2($name, $value)
                )  ;
        }
    }

    compressRawWithParam "Lc", [ 0 .. 4 ], "--lzma2=lc";
    #compressRawWithParam "Lp", [ 0 .. 4 ], "--lzma2=lp";
    compressRawWithParam "Mode", [ LZMA_MODE_NORMAL, LZMA_MODE_FAST ],
                          "--lzma2=mode", ["normal", "fast"];
    compressRawWithParam "Mf", [ LZMA_MF_HC3, LZMA_MF_HC4, LZMA_MF_BT2, 
                              LZMA_MF_BT3, LZMA_MF_BT4], "--lzma2=mf",
                              [qw(hc3 hc4 bt2 bt3 bt4)];
    #compressRawWithParam "Nice", [ 2 .. 273 ], "--lzma2=nice";
    #compressRawWithParam "Depth", [ 2 .. 273 ], "--lzma2=depth";
}




{
    title "Test AutoDecoder interop with xz" ;

    uncompressWith('Compress::Raw::Lzma::AutoDecoder', '-F xz');

}

{
    title "Test AloneDecoder interop with xz" ;

    uncompressWith('Compress::Raw::Lzma::AloneDecoder', '-F lzma');

}

{
    title "Test StreamDecoder interop with xz" ;

    uncompressWith('Compress::Raw::Lzma::StreamDecoder', '-F xz');

}

{
    title "Test RawDecoder interop with xz" ;

    uncompressWith('Compress::Raw::Lzma::RawDecoder', '-F raw');

}
