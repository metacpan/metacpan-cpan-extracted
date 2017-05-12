use strict;
use Test::More;
use File::Path qw( remove_tree );

plan skip_all => 'Cannot read bin/sibs' unless -x 'bin/sibs';

$ENV{HOME} = 't/home';
my $script = do 'bin/sibs';

{
  local $ENV{HARNESS_IS_VERBOSE} = 1;
  is $script->run, 0, 'exit=0';
  is_deeply $script, { config => 't/home/.sibs.conf' }, 'no args passed';

  $script->run('--verbose');
  is_deeply $script, { verbose => '--verbose', config => 't/home/.sibs.conf' }, 'got --verbose';

  $script->run('-s');
  is_deeply $script, { verbose => '--verbose', silent => '-s', config => 't/home/.sibs.conf' }, 'got -s';

  $script->run('--silent', $0, '-v', 'foo');
  is_deeply $script, { verbose => '-v', silent => '--silent', config => $0 }, 'got config';
}

done_testing;
