#!perl
use warnings;
use strict;
use Test::Bot::BasicBot::Pluggable::Store;

use File::Temp qw(tmpnam);
my $tempfile = tmpnam();

store_ok( 'Deep', { file => $tempfile } );
unlink($tempfile);
