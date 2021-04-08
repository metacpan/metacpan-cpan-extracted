use strict;
use warnings;
use File::Spec::Functions qw(rel2abs);
use File::Temp qw(tempdir);
use Test::More;

$ENV{TT_COLUMNS}         = 'project,date,hours,rounded,tags,description';  # not the same as default
$ENV{TT_HOME}            = tempdir;
$ENV{TT_HOURS_PER_MONTH} = 0;
$ENV{TT_PTY}             = 1;

plan skip_all => "Cannot load tt: $! ($@)" unless my $tt = do(rel2abs 'script/tt');
plan skip_all => "home is not a tempdir" if int $tt->home->list_tree;

use Mojo::Util;

note 'zero events';
test_output(
  'command_log', [],
  qr{Log for \w+ \d+},
  qr{Month\s+Date\s+Start\s+Duration\s+Project\s+Tags},
  qr{Total events\s+:\s+0},
  qr{Total time\s+:\s+0h 0m 0s},
);

test_output(
  'command_export', [],
  qr{"project","date","hours","rounded","tags","description"},
  \qr{Exact hours:  0:00\. Rounded hours: 0\. Events: 0\.},
);

note 'status, stop';
test_output('command_status', [], qr{No event});
test_output('command_stop',   [], \qr{No event});

note 'register';
test_output('command_register', [], qr{This command is used to import data from other sources});

$tt->project('oss-tt');
$tt->tag([qw(a b c)]);
test_output('command_register', [qw(09:30:07 10:34:12)],
  qr{Registered "oss-tt" at .* \d\d:30:07 \d{4} with duration 1:\d+:\d+\.},
);

note 'start, status, stop';
test_output('command_start',  [], qr{Started "oss-tt" at \d\d:\d\d:\d\d\.});
test_output('command_status', [], qr{Tracking "oss-tt" for 0h 0m \ds since \d\d:\d\d:\d\d\.});
test_output('command_stop',   [], \qr{Dropping "oss-tt" since the event is shorter than 300s\.});

note 'start, stop, status - with time';
my $h = +(localtime)[2] - 1;
test_output('command_start',  ["foo", "$h:02"], qr{Started "foo" at 09:02:00\.});
test_output('command_stop',   ["$h:32:1"],      qr{Stopped "foo" at .* after 0h 30m 1s\.});
test_output('command_status', [],               qr{Stopped "foo" at .* after 0h 30m 1s\.});

note 'got events';
$tt->project('');
$tt->tag([]);
test_output(
  'command_log', [],
  qr{Log for \w+ \d+},
  qr{Month\s+Date\s+Start\s+Duration\s+Project\s+Tags},
  qr{9:02.*foo}s, qr{9:30.*oss-tt}s,
  qr{Total events\s+:\s+2},
  qr{Total time\s+:\s+1h 34m 6s},
);

test_output(
  'command_export',
  [],
  qr{"project","date","hours","rounded","tags","description"},
  qr/"foo","\d{4}-\d{2}-\d{2}","0\.5","1","a,b,c",""/,
  \qr{Exact hours:  1:34\. Rounded hours: 2\. Events: 2\.},
);

done_testing;

sub test_output {
  my ($method, $args, @re) = @_;
  open my $STDERR, '>', \(my $stderr = '');
  open my $STDOUT, '>', \(my $stdout = '');
  local $tt->{stderr} = $STDERR;
  local $tt->{stdout} = $STDOUT;
  my $res = $tt->$method(@$args);

  subtest "$method @$args" => sub {
    ref $_ eq 'REF' ? like $stderr, $$_, "stderr $$_" : like $stdout, $_, "stdout $_" for @re;
  };
  return $res;
}
