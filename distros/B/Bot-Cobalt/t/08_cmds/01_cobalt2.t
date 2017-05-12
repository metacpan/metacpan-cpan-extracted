use Test::More;
use strict; use warnings;

use Capture::Tiny 'capture';

my ($out, $err, $exit) = capture {
  system($^X, 'bin/cobalt2', '--help')
};

ok $out, '--help produced output';
ok !$exit, '--help exited with status 0';


done_testing
