#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Test::Exception;

BEGIN {
    use_ok( 'App::ProcTrends::Config' ) || print "Bail out!\n";
}

diag( "Testing App::ProcTrends::Config $App::ProcTrends::Config::VERSION, Perl $], $^X" );

my $obj;

lives_ok { $obj = App::ProcTrends::Config->new(); } "constructor test";

done_testing();