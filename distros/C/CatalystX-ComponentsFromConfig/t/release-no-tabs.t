
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::NoTabsTests 0.09

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/CatalystX/ComponentsFromConfig.pm',
    'lib/CatalystX/ComponentsFromConfig/ModelAdaptor.pm',
    'lib/CatalystX/ComponentsFromConfig/ModelPlugin.pm',
    'lib/CatalystX/ComponentsFromConfig/Role/AdaptorRole.pm',
    'lib/CatalystX/ComponentsFromConfig/Role/PluginRole.pm',
    'lib/CatalystX/ComponentsFromConfig/ViewAdaptor.pm',
    'lib/CatalystX/ComponentsFromConfig/ViewPlugin.pm',
    't/lib/Foo.pm',
    't/lib/TestApp.pm',
    't/lib/TestApp/ModelAdaptor.pm',
    't/lib/TestApp/ModelBase/Foo.pm',
    't/lib/TestApp/Trait.pm',
    't/lib/TestApp/TraitFor/View/Magic.pm',
    't/lib/TestApp/ViewBase/Foo.pm',
    't/more.t',
    't/test.t',
    't/testapp-more.conf',
    't/testapp.conf'
);

notabs_ok($_) foreach @files;
done_testing;
