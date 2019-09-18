use warnings;
use strict;
use Test::More;

my $app = eval <<"HERE" or die $@;
use Applify;
option str  => file => 'input';
option bool => save => 'save work';
option num  => arr  => 'array',         n_of => '\@';
option str  => def  => 'array',         n_of => '\@', default => [9];
option int  => rep  => '1 or 2 things', n_of => '1,2';
app {};
HERE

my $script = $app->_script;

is_deeply(run(), {arr => [], def => [9], file => undef, rep => [], save => ''}, 'no arguments');

is_deeply(run('--save'), {arr => [], def => [9], file => undef, rep => [], save => 1}, 'only --save');

is_deeply(
  run(qw(--arr 1 --arr 2 --file /tmp/3)),
  {def => [9], arr => [1, 2], file => '/tmp/3', rep => [], save => ''},
  'both --arr and --file'
);

is_deeply(run(qw(--file /tmp/1)), {def => [9], arr => [], file => '/tmp/1', rep => [], save => ''}, 'only --file');

is_deeply(
  run(qw(--arr 1 --arr 2 --file /tmp/3)),
  {def => [9], arr => [1, 2], file => '/tmp/3', rep => [], save => ''},
  'both --arr and --file again'
);

is_deeply(run(qw(--def 8 --def 7)), {def => [8, 7], arr => [], file => undef, rep => [], save => ''}, 'override --def');

is_deeply(run(qw(--rep 7 8)), {def => [9], arr => [], file => undef, rep => [7, 8], save => ''}, 'only --rep');

done_testing;

sub run {
  local @ARGV = @_;
  my $app = $script->app;
  return {map { ($_ => $app->$_) } qw(arr def file rep save)};
}
