#!perl -wT

use strict;
use warnings;

use Test::More tests => 1;

use_ok( 'Catalyst::Model::S3' );

diag( 'Testing Catalyst::Model::S3 '
            . $Catalyst::Model::S3::VERSION );
