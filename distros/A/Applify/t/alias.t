use warnings;
use strict;
use Test::More;

my $app = eval <<"HERE" or die $@;
use Applify;
option int => age => 'whatever';
app {};
HERE

my $script = $app->_script;

is_deeply(run(qw(-i 42)),    undef, 'alias -i not defined');
is_deeply(run(qw(--age 43)), 43,,   'but --age is defined');

$script->{options}[0]{alias} = ['i'];
is_deeply(run(qw(-i 44)), 44, 'alias -i defined');

done_testing;

sub run {
  local @ARGV = @_;
  return $script->app->age;
}
