use strict;
use warnings;

use Test::Exception;
use Test::More;

use Config::Onion;

use FindBin;
my $conf_dir = $FindBin::Bin . '/conf';

# construct bare, then load conf file
{
  my $cfg = Config::Onion->new;
  isa_ok($cfg, 'Config::Onion', 'construct bare config');
  $cfg->load("$conf_dir/basic");
  is($cfg->get->{foo}, 'bar', 'retrieve value from single conf file');
}

# construct by loading conf file
{
  my $cfg = Config::Onion->load("$conf_dir/basic");
  isa_ok($cfg, 'Config::Onion', 'construct by loading config file');
  is($cfg->get->{xyzzy}, 'plugh', 'get value after constucting via load');
}

# override main conf file with local conf
{
  my $cfg = Config::Onion->load("$conf_dir/withlocal");
  is($cfg->get->{main}, 1, 'local config does not clear main values');
  is($cfg->get->{local}, 1, 'local config does override main values');
}

# load list of conf files
{
  my $cfg = Config::Onion->load("$conf_dir/basic", "$conf_dir/withlocal");
  is_deeply([ $cfg->get->{xyzzy}, $cfg->get->{main}, $cfg->get->{local} ],
    [ 'plugh', 1, 1 ], 'multiple config files loaded correctly');
}

# load files by glob match
{
  my $cfg = Config::Onion->load_glob("$conf_dir/*");
  ok(defined $cfg->get->{joker}, 'load multiple configs');
  is($cfg->get->{joker}, 'wild',
    'globbed load gives precedence to later files');
  is($cfg->get->{local}, 1, 'globbed load gives precedence to local files');
}

# GH5: handle load_glob correctly when nothing matches
{
  my $cfg;
  lives_ok {
    $cfg = Config::Onion->load_glob("$conf_dir/DoesNotExist");
  } q(glob with no matches doesn't die);
  is_deeply($cfg->get, {}, 'glob with no matches loads nothing');
}

# prefix structures
{
  my $cfg = Config::Onion->load("$conf_dir/prefix");
  is($cfg->get->{deep_key}, 1, 'prefix structure disabled by default');
  ok(exists $cfg->get->{_prefix}, 'prefix key present by default');

  $cfg = Config::Onion->new(prefix_key => '_prefix');
  $cfg->load("$conf_dir/prefix");
  is($cfg->get->{some}{levels}{down}{deep_key}, 1,
    'key found in prefix structure');
  is($cfg->get->{some}{levels}{down}{deep}{subkey}, 2,
    'subkey found in prefix structure');
  ok(!defined $cfg->get->{_prefix}, 'prefix key replaced by prefix structure');
  ok(!defined $cfg->get->{deep}, 'non-prefix keys cleared from config');
}

# pass parameter to Config::Any, overrides use_ext
{
  my $cfg = Config::Onion->load_glob("$conf_dir/basic*", {force_plugins => ['Config::Any::YAML']});
  is($cfg->get->{joker}, 'one', 'use_ext was not used');
}

done_testing;

