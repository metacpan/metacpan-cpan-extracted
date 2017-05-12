use strict;
use warnings;
use Test::More 0.96;
use lib 't/lib';
use TestBundles;
use Test::Differences;

my $mod = 'Config::MVP::BundleInspector';
eval "require $mod" or die $@;

subtest mvp_bundle_config => sub {
  my $bundle = 'TestBundles::RoundHere';
  my $bi = new_ok($mod, [
    bundle_class => $bundle,
  ]);

  local *pkg  = sub { $bundle . '::' . $_[0] };
  eq_or_diff $bi->plugin_specs, [
    [Omaha   => pkg('Jones'),         { salutation => 'mr' }],
    [Perfect => pkg('BlueBuildings'), { ':version' => '0.003' }],

  ], 'plugin_specs';

  eq_or_diff $bi->prereqs->as_string_hash, {
    $bundle . '::Jones'         => 0,
    $bundle . '::BlueBuildings' => '0.003',
  }, 'simplified prereqs with version';

  eq_or_diff $bi->ini_string, <<INI, 'ini_string';
[${bundle}::Jones / Omaha]
salutation = mr

[${bundle}::BlueBuildings / Perfect]
:version = 0.003
INI
};

subtest bundle_config => sub {
  my $bundle = 'TestBundles::AnnaBegins';
  my $bi = new_ok($mod, [
    bundle_class => $bundle,
    bundle_method => 'bundle_config',
  ]);

  local *pkg  = sub { $bundle . '::' . $_[0] };
  eq_or_diff $bi->plugin_specs, [
    [Time      => pkg('Time'), {':version' => '1.2', needs_feature => 'b',}],
    [TimeAgain => pkg('Time'), {':version' => '1.1', only_needs => ['feature', 'a'] }],
    [Rain      => pkg('King')],

  ], 'plugin_specs';

  eq_or_diff $bi->prereqs->as_string_hash, {
    $bundle . '::Time' => '1.2',
    $bundle . '::King' => 0,
  }, 'prereqs with latest version';

  eq_or_diff $bi->ini_string, <<INI, 'ini_string';
[${bundle}::Time / Time]
:version      = 1.2
needs_feature = b

[${bundle}::Time / TimeAgain]
:version   = 1.1
only_needs = feature
only_needs = a

[${bundle}::King / Rain]
INI
};

subtest dzil_bundle => sub {
  my $bundle = 'Dist::Zilla::PluginBundle::SullivanStreet';
  my $bi = new_ok($mod, [
    bundle_class  => $bundle,
    bundle_method => 'bundle_config',
    ini_opts      => {
      rewrite_package => sub {
        local $_ = $_[0];
        my $prefix = 'Dist::Zilla::';

          s/^${prefix}PluginBundle::/\@/ or
          s/^${prefix}Plugin::// or
          s/^/=/;

        return $_;
      },
    },
  ]);

  local *pkg  = sub { 'Dist::Zilla::' . $_[0] };
  eq_or_diff $bi->plugin_specs, [
    [Ghost   => pkg('Plugin::Train')],
    [Raining => 'In::Baltimore', { ':version' => 'v1.23.45' }],
    [Murder  => pkg('PluginBundle::Of::One'),  { 'version'  => 'not :version' }],
    [August  => pkg('Plugin::Everything')],
    [After   => pkg('Plugin::Everything')],
  ], 'plugin_specs';

  eq_or_diff $bi->prereqs->as_string_hash, {
    pkg('Plugin::Train')         => 0,
    'In::Baltimore'              => 'v1.23.45',
    pkg('PluginBundle::Of::One') => 0,
    pkg('Plugin::Everything')    => 0,
  }, 'prereqs';

  eq_or_diff $bi->ini_string, <<INI, 'ini_string';
[Train / Ghost]

[=In::Baltimore / Raining]
:version = v1.23.45

[\@Of::One / Murder]
version = not :version

[Everything / August]
[Everything / After]
INI
};

done_testing;
