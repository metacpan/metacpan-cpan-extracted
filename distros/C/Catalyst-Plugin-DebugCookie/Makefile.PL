use inc::Module::Install '0.68';

name 'Catalyst-Plugin-DebugCookie';
all_from 'lib/Catalyst/Plugin/DebugCookie.pm';

requires 'Catalyst' => '5.7014';
requires 'MRO::Compat' => '0.07';
requires 'Digest::MD5';
requires 'Sub::Exporter';

build_requires 'Test::WWW::Mechanize::Catalyst';
build_requires 'Catalyst::Plugin::ConfigLoader';
build_requires 'Catalyst::Plugin::Static::Simple';
build_requires 'Catalyst::Action::RenderView';
build_requires 'Config::General';

# generate README file
if ($Module::Install::AUTHOR) {
  system('pod2text lib/Catalyst/Plugin/DebugCookie.pm > README');
}

tests_recursive();
auto_install;
WriteAll;

