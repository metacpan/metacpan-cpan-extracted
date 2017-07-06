use warnings;
use strict;
use Test::More;

my $app = eval <<"HERE" or die $@;
use Applify;
option str => input_file => 'input';
option str => save => 'save work';
option str => example => 'array', n_of => '\@';
option str => defaults => 'array', n_of => '\@', default => [9];
app {};
HERE

my $script = $app->_script;

## -save /path
is_deeply(run('--save' => '/tmp/1'),     [[], undef, '/tmp/1', [9]], 'save only');

## set -e and -i
is_deeply(run('-e' => 1, '-e', 2, '-i' => '/tmp/3'), [[1, 2], '/tmp/3', undef, [9]], 'arrays');

## neither -i nor -e should be set...
is_deeply(run('--save' => '/tmp/1'),     [[], undef, '/tmp/1', [9]], 'saved?');

## only -i
is_deeply(run('-i' => '/tmp/1'),     [[], '/tmp/1', undef, [9]], 'input only');

is_deeply(run('-e' => 1, '-e', 2, '-i' => '/tmp/3'), [[1, 2], '/tmp/3', undef, [9]], 'arrays again');

## defaults
is_deeply(run('-d' => 8, '-d' => 7), [[], undef, undef, [9, 8, 7]], 'push...');

done_testing;

sub run {
  local @ARGV = @_;
  my $app = $script->app;
  return [$app->example, $app->input_file, $app->save, $app->defaults];
}
