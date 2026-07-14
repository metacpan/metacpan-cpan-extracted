use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/App/ZofCMS/Plugin/Captcha.pm',
    'lib/App/ZofCMS/Plugin/ImageGallery.pm',
    'lib/App/ZofCMS/Plugin/ImageResize.pm',
    'lib/App/ZofCMS/Plugin/RandomPasswordGenerator.pm',
    'lib/App/ZofCMS/Plugin/Search/Indexer.pm',
    'lib/App/ZofCMS/PluginBundle/Naughty.pm',
    't/00-compile.t',
    't/00-load.t',
    't/01-plugin.t'
);

notabs_ok($_) foreach @files;
done_testing;
