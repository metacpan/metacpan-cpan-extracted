use strict;
use warnings;

use Test::Exception;
use Test::More;

use Config::Onion;

use FindBin;
my $conf_dir = $FindBin::Bin . '/conf';

# GH12: delete hash element by overwriting with !DELETE!
{
  my $cfg = Config::Onion->set_default(foo => { bar => 'test', rest => 'ok' });
  $cfg->set_override(foo => { bar => '!DELETE!' });
  is_deeply($cfg->cfg, { foo => { rest => 'ok' }}, 'key deleted successfully');
}

done_testing;

