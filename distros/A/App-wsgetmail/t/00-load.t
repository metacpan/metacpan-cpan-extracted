#!perl 
use strict;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

use_ok( 'App::wsgetmail' );
use_ok( 'App::wsgetmail::MS365' );
use_ok( 'App::wsgetmail::MS365::Client' );
use_ok( 'App::wsgetmail::MS365::Message');
use_ok( 'App::wsgetmail::MDA' );

done_testing();
