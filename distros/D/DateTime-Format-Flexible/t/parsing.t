#!/usr/bin/perl

use strict;
use warnings;
use lib '.';

use Test::More tests => 8060;
use File::Spec::Functions 'catfile';

use t::lib::helper;

foreach my $data_file ( 'tests.txt' , 'timezones.txt' )
{
    my $test_file = catfile( 't' , 'data' , $data_file );
    open my $tests , $test_file or BAIL_OUT( "unable to open $test_file: $!" );

    t::lib::helper::run_tests( <$tests> );

    close $tests;
}
