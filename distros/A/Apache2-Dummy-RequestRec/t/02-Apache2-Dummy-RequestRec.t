#!/usr/bin/perl

use strict;
use warnings;

use DateTime;
use Test::More;
use Test::Output;
use Data::Printer;
use Data::Compare;

my $tno = 0;

use Test2::Require::Module 'Apache2::RequestData';

use_ok('Apache2::Dummy::RequestRec');
$tno++;

my $r = Apache2::Dummy::RequestRec->new(
    {
        args => 'bla=blu&blu=bla',
        body => 'ble=blo&bli=bli',
    }
                                    );

my $fd = Apache2::RequestData->new($r);
my $params = $fd->params;
my $fparams =
{
    bla    => "blu",
    ble    => "blo",
    bli    => "bli",
    blu    => "bla",
};
ok(Compare($params, $fparams), "request data");
$tno++;

done_testing($tno);
