# vim: filetype=perl :
use strict;
use warnings;

#use Test::More tests => 1, import => ['!pass']; # last test to print
use Test::More import => ['!pass'];
plan tests => 3;

use Dancer ':syntax';
use Dancer::Test;

setting plugins => {
   FlashNote => {
      queue   => 'single',
      dequeue => 'when_used',
      whatever => 'it is',
      foo => 'bar',
   },
};
ok(! eval "use Dancer::Plugin::FlashNote", 'extra arguments');
like($@, qr/invalid configuration keys.*$_/, "'$_' included in error")
   for qw( whatever foo );
