use inc::Module::Install;

name 'Catalyst-Controller-LeakTracker';
all_from 'lib/Catalyst/Controller/LeakTracker.pm';
repository 'http://github.com/wreis/catalyst-controller-leaktracker';
license 'perl';

build_requires(
    'Test::More' => 0.88,
    'Test::use::ok' => 0,
);

requires(
    'parent' => 0,
    'Catalyst::Runtime' => 5.8,
    'Devel::Size' => 0,
    'Devel::Cycle' => 0,
    'Catalyst::Plugin::LeakTracker' => 0,
    'Data::Dumper' => 0,
    'Template::Declare' => 0.42,
    'Number::Bytes::Human' => 0.07,
    'YAML::XS' => 0,
);

auto_install;

WriteAll;
