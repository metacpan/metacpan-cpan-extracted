use Test::More tests=>22;
use strict;

BEGIN { 
  use_ok(qw(App::SimpleScan));
}

my @cmds = 
  (
    [ []                       => { run => 1,     generate => undef, warn => undef } ],
    [ [qw(--run)]              => { run => 1,     generate => undef, warn => undef } ],
    [ [qw(--gen)]              => { run => undef, generate => 1,     warn => undef } ],
    [ [qw(--warn)]             => { run => 1,     generate => undef, warn => 1     } ],
    [ [qw(--run --warn)]       => { run => 1,     generate => undef, warn => 1     } ],
    [ [qw(--gen --warn)]       => { run => undef, generate => 1,     warn => 1     } ],
    [ [qw(--run --gen --warn)] => { run => 1,     generate => 1,     warn => 1     } ],
  );

foreach my $argset (@cmds) {
  my ($arglist, $resultset) = @$argset;
  my %results = %$resultset;
  local @ARGV = @$arglist;
  my $app = new App::SimpleScan;
  for my $method (qw(run generate warn)) {
    is ${$app->$method}, $results{$method}, "$method (@{$arglist})"; 
  }
  undef $app;
}
