#!/usr/bin/perl

use 5.006;
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

BEGIN { use_ok('Amibroker::OLE::APXCreator'); }

my $new_apx_file = Amibroker::OLE::APXCreator::create_apx_file(
    {
        afl_file   => "$FindBin::Bin/test_afl.afl",
        symbol     => 'ADANIPORTS-I',
        timeframe  => '20-minute',
        from       => '01-09-2015',
        to         => '20-09-2015',
        range_type => 0,
        apply_to   => 1
    }
);
is( $new_apx_file, 'C:/ADANIPORTS-I.apx', 'apx file created' );
eval {
    my $new_apx_file1 = Amibroker::OLE::APXCreator::create_apx_file(
        {
            afl_file => 'test_afl.afl',
            symbol   => 'ADANIPORTS-I',
        }
    );
};
pass('Not accepting wrong parameters') if ($@);

done_testing();
