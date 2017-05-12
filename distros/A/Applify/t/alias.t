use warnings;
use strict;
use Test::More;

my $app = eval <<"HERE" or die $@;
use Applify;
option str => iii => 'd1';
option str => input_file => 'd2';
app {};
HERE

my $script = $app->_script;

is_deeply(run('-i'   => 'no-match'), [undef, undef], 'undef');
is_deeply(run('--ii' => 'ii'),       ['ii',  undef], 'ii');

$script->{options}[1]{alias} = ['i'];
is_deeply(run('-i' => 'f2', '--iii' => 'i1'), ['i1', 'f2'], 'i1,f2');

done_testing;

sub run {
  local @ARGV = @_;
  my $app = $script->app;
  return [$app->iii, $app->input_file];
}
