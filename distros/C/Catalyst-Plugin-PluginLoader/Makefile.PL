use inc::Module::Install 0.87;

name 'Catalyst-Plugin-PluginLoader';
all_from 'lib/Catalyst/Plugin/PluginLoader.pm';

requires 'Catalyst::Runtime' => '5.80002';
requires 'MRO::Compat';
requires 'Scalar::Util';
requires 'namespace::clean';

build_requires 'Test::More';

if(-e 'MANIFEST.SKIP') {
    system("pod2text lib/Catalyst/Plugin/PluginLoader.pm > README");
}

auto_provides;
auto_install;
WriteAll;
