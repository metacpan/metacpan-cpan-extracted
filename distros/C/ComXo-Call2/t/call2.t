#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use ComXo::Call2;

plan skip_all => "ENV CALL2_ACCOUNT/CALL2_PASSWORD/CALL2_FROM/CALL2_TO is required to continue."
    unless ($ENV{CALL2_ACCOUNT} and $ENV{CALL2_PASSWORD} and $ENV{CALL2_FROM} and $ENV{CALL2_TO});

my $call2 = ComXo::Call2->new(
    account  => $ENV{CALL2_ACCOUNT},
    password => $ENV{CALL2_PASSWORD},
    debug    => 0,
);

diag("Test InitCall..");
my $call_id = $call2->InitCall(
    bnumber => $ENV{CALL2_FROM},
    anumber => $ENV{CALL2_TO},
    alias   => 'FixedOdds',
) or die $call2->errstr;
diag("Get call_id as $call_id");
ok($call_id > 0);    # 15387787

diag("Test GetAllCalls..");
my @d = localtime(time() - 86400);
my $dt_from = sprintf('%04d-%02d-%02d %02d:%02d', $d[5] + 1900, $d[4] + 1, $d[3], $d[2], $d[1]);
@d = localtime();
my $dt_to = sprintf('%04d-%02d-%02d %02d:%02d', $d[5] + 1900, $d[4] + 1, $d[3], $d[2], $d[1]);
my @calls = $call2->GetAllCalls(
    fromdate => $dt_from,
    todate   => $dt_to
);
ok(grep { $_->[0] == $call_id } @calls);

diag("Test GetCallStatus");
my @status = $call2->GetCallStatus($call_id) or die $call2->errstr;
is($status[0], $call_id);
is($status[2], $ENV{CALL2_TO});
is($status[3], $ENV{CALL2_FROM});

done_testing();

1;
