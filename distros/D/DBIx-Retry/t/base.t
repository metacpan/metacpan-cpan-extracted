#!/usr/bin/env perl -w
 
use strict;
use warnings;

#modules
use Test::More 'no_plan';
#add local lib to path
use FindBin;
use lib "$FindBin::Bin/../lib";

my $CLASS;
BEGIN {
    $CLASS = 'DBIx::Retry';
    use_ok $CLASS or die;
}

my ($t,$v) = (3,0);
# check the basics - copy straight from DBIx::Connector test
ok my $conn = $CLASS->new('dbi::dumy','','',{retry_time => $t, verbose => $v} ), "New object OK";
isa_ok $conn, $CLASS, "New object isa $CLASS";

is $conn->retry_time,$t, 'Timeout value set OK';
is $conn->verbose,$v, 'Verbose value set OK';
