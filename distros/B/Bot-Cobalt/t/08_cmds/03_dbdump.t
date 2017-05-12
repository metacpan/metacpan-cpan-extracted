use Test::More;
use strict; use warnings;

use Capture::Tiny 'capture';

my ($out, $err, $exit) = capture {
  system($^X, 'bin/cobalt2-dbdump', '--help')
};

ok $out, '--help produced output';
ok !$err, '--help produced no stderr';
ok !$exit, '--help exited 0';


done_testing
