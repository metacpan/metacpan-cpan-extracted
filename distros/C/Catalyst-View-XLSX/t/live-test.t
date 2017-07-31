#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 4;

# setup library path
use FindBin qw($Bin);
use lib "$Bin/lib";

BEGIN {                                                                       
      use_ok ( "Catalyst::Test", "TestApp" );                                     
}   

my $url = '/';
action_ok ( $url, 'Downloading the file' );                                                         

contenttype_is ( $url, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" ,'Expected ContentType received!'); 

my $res = request ('/'); 
is ( $res->filename, 'TestExcel.xlsx','Expected File received!' );

