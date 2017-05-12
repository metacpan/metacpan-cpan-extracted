#!perl
use strict;
use warnings;

use Test::More tests => 2;
BEGIN { use_ok( 'Data::Domain', qw/:all/ );}

my $dom;
my $msg;

# DISCLAIMER: THIS STUFF IS STILL EXPERIMENTAL
# Tests are far from complete, and the API is subject to change


$dom = Whatever(-has => [
   _stringify       => String,
   [inspect => 123] => Undef,
   foobar           => String,
 ]);

my $obj = Int(-max=> 100);
$msg = $dom->inspect($obj);

ok($msg, 'does not have all requested methods');
note(explain($msg));

