#!perl

use strict;
use warnings;
use Test::More;
use Test::Deep;

use_ok('Bash::Completion') or die "Could not load Bash::Completion, ";

my $req = _complete('bash-complete ');
cmp_deeply(
  [$req->candidates],
  bag('setup', 'complete', '-h', '--help'),
  'Expected for empty args'
);

$req = _complete('bash-complete se');
cmp_deeply([$req->candidates], bag('setup'), 'Expected for single "se"');

$req = _complete('bash-complete complete ');
ok(scalar(grep {/BashComplete|Perldoc/} $req->candidates),
  'Expected for "complete"');


sub _complete {
  my ($l, $p) = @_;
  my $bc = Bash::Completion->new;

  local $ENV{COMP_LINE} = $l;
  local $ENV{COMP_POINT} = $p || length($ENV{COMP_LINE});

  return $bc->complete('BashComplete', []);
}


done_testing();
