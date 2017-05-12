#!perl -T

use lib qw(inc);
use Test::More;
plan tests => 1;

use_ok( 'Catalyst::Model::MogileFS::Client' );

diag( "Testing Catalyst::Model::MogileFS::Client $Catalyst::Model::MogileFS::Client::VERSION, Perl $], $^X" );
