#!perl -wT

use strict;
use warnings;

use Test::More tests => 1;

use_ok( 'Catalyst::Model::Akismet' );

diag( 'Testing Catalyst::Model::Akismet '
            . $Catalyst::Model::Akismet::VERSION );
