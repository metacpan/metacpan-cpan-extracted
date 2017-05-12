#!perl -wT

use strict;
use warnings;

use Test::More tests => 1;

use_ok( 'Catalyst::Model::Filemaker' );

diag( 'Testing Catalyst::Model::Filemaker '
            . $Catalyst::Model::Filemaker::VERSION );
