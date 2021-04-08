use strict;
use warnings;
use File::Spec::Functions qw(rel2abs);
use Test::More;

plan skip_all => "Cannot load tt: $! ($@)" unless my $tt = do(rel2abs 'script/tt');
ok $tt->can("command_$_"), "tt $_" for qw(export log start stop status register);

eval { $tt->_time('13T29') };
like $@, qr{Invalid time: 13T29}, 'invalid time';
test_time('2019-01-03T23:02:01', '2019-01-03T23:02:01');
test_time('2019-1-03T23:2:01',   '2019-01-03T23:02:01');
test_time('3T23',                '03T23:00:00');
test_time('9-3T23',              '09-03T23:00:00');
test_time('6:5',                 'T06:05:00');
test_time('09:04:01',            'T09:04:01');

my $home = $tt->home;

{
  local $ENV{TT_HOME} = '/tmp/tt';
  delete $tt->{home};
  is $tt->home, '/tmp/tt', 'TIMETRACKER_HOME';
  isnt $tt->home, $home, 'not default home';
}

{
  local $ENV{TIMETRACKER_HOME} = '/tmp/tt';
  delete $tt->{home};
  is $tt->home, '/tmp/tt', 'TIMETRACKER_HOME';
  isnt $tt->home, $home, 'not default home';
}

done_testing;

sub test_time {
  my ($str, $exp) = @_;
  my $tp = $tt->_time($str);
  like $tp->datetime, qr{$exp}, "$exp = $tp";
}
