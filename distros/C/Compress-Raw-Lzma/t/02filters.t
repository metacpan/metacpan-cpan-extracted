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

BEGIN
{
    # use Test::NoWarnings, if available
    my $extra = 0 ;
    $extra = 1
        if eval { require Test::NoWarnings ;  import Test::NoWarnings; 1 };

    plan tests => 2463 + $extra ;

    use_ok('Compress::Raw::Lzma') ;

}

{
    title "BCJ";

    my @filters = map { "Lzma::Filter::$_" }
                  qw(X86 PowerPC IA64 ARM ARMThumb Sparc);

    for my $filter (@filters)
    {
        no strict 'refs';
        my $x = &{ $filter } ;
        isa_ok $x, $filter;
        isa_ok $x, 'Lzma::Filter::BCJ';
        isa_ok $x, 'Lzma::Filter';
    }

    isa_ok Lzma::Filter::X86, "Lzma::Filter::X86";
}

{
    title "Delta";

    {
        my $x = Lzma::Filter::Delta;
        isa_ok $x, 'Lzma::Filter::Delta';
        isa_ok $x, 'Lzma::Filter';
    }

    {
        my $x = Lzma::Filter::Delta Type => LZMA_DELTA_TYPE_BYTE,
                                    Distance => LZMA_DELTA_DIST_MAX  ;
        isa_ok $x, 'Lzma::Filter::Delta';
        isa_ok $x, 'Lzma::Filter';
    }

    # TODO -- add error cases

}

{
    title "Lzma";

    my @filters = map { "Lzma::Filter::$_" }
                  qw(Lzma1 Lzma2);

    for my $filter (@filters)
    {
        no strict 'refs';
        #my $x = &{ $filter } ;
        my $x = $filter->();
        isa_ok $x, $filter;
        isa_ok $x, 'Lzma::Filter::Lzma';
        isa_ok $x, 'Lzma::Filter';
    }

    {
        my $x = Lzma::Filter::Lzma2
                DictSize   => 1024 * 1024 * 100,
                Lc         => 0,
                Lp         => 3,
                Pb         => LZMA_PB_MAX,
                Mode       => LZMA_MODE_FAST,
                Nice       => 128,
                Mf         => LZMA_MF_HC4,
                Depth      => 77;

        isa_ok $x, 'Lzma::Filter::Lzma2';
        isa_ok $x, 'Lzma::Filter';
    }

    use constant oneK => 1024;
    use constant oneMeg => 1024 * 1024;

    sub testParam
    {
        my $name = shift;
        my $good_range = shift;
        my $bad_range = shift;
        my $message = shift;
        my $other = shift || [];

        for my $filter (@filters)
        {
            for my $value (@$good_range)
            {
                title "$filter + $name $value";

                no strict 'refs';
                #my $x = &{ $filter } ;
                my $x = $filter->($name => $value, @$other);
                isa_ok $x, $filter;
                isa_ok $x, 'Lzma::Filter::Lzma';
                isa_ok $x, 'Lzma::Filter';
            }

            for my $value (@$bad_range)
            {
                title "$filter + $name $value  - error";

                no strict 'refs';
                #my $x = &{ $filter } ;
                eval { $filter->($name => $value, @$other) ; } ;
                like $@,  mkErr(sprintf $message, $value), " catch error";

            }
        }
    }

    testParam "DictSize",
              [ 4 * oneK,  1536 * oneMeg ],
              [ (4 * oneK) - 1, (1536 * oneMeg) + 1 ],
              "Dictsize %d not in range 4KiB - 1536Mib" ;

    testParam "Lc",
              [ 0 .. 4 ],
              [ 5 .. 10 ],
              "Lc %d not in range 0-4" ;

    testParam "Lp",
              [ 0 .. 4 ],
              [ 5 .. 10 ],
              "Lp %d not in range 0-4",
               [Lc => 0] ;

    testParam "Mode",
              [ LZMA_MODE_NORMAL, LZMA_MODE_FAST ],
              [ 5 .. 10 ],
              "Mode %d not LZMA_MODE_FAST or LZMA_MODE_NORMAL" ;

    testParam "Mf",
              [ LZMA_MF_HC3, LZMA_MF_HC4, LZMA_MF_BT2,
                LZMA_MF_BT3, LZMA_MF_BT4],
              [ 100, 300 ],
              "Mf %d not valid" ;


    testParam "Nice",
              [ 2 .. 273 ],
              [ 0, 1, 274 ],
              "Nice %d not in range 2-273" ;


}
