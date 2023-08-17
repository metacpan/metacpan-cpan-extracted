#!perl -w
use strict;
use warnings;
use lib './lib';
use vars qw( $DEBUG );
$DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
use Test::More;
plan tests => 1;

use Data::Pretty;
local $Data::Pretty::DEBUG = $DEBUG;

$a = {
   a => qr/Foo/,
   b => qr,abc/,is,
   c => qr/ foo /x,
   d => qr/foo/msix,
   e => qr//,
   f => qr/
     # hi there
     how do this look
   /x,
   g => qr,///////,,
   h => qr*/|,:*,
   i => qr*/|,:#*,
};

is(Data::Pretty::dump($a) . "\n", <<'EOT');
{
    a => qr/Foo/,
    b => qr|abc/|si,
    c => qr/ foo /x,
    d => qr/foo/msix,
    e => qr//,
    f => qr/
         # hi there
         how do this look
       /x,
    g => qr|///////|,
    h => qr#/|,:#,
    i => qr/\/|,:#/,
}
EOT
