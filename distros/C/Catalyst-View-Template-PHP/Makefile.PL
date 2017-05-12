use inc::Module::Install;

name     'Catalyst-View-Template-PHP';
all_from 'lib/Catalyst/View/Template/PHP.pm';
author   q{Marty O'Brien <mob@cpan.org>};
license  'perl';

build_requires 'Test::More';

requires 'Catalyst::View';
requires 'Moose';
requires 'PHP' => 0.14; # 0.15 needed for 2nd arg to options(header => ...)

test_requires 'Test::More';
test_requires 'Catalyst::Test';
test_requires 'Plack::Test';
test_requires 'Catalyst::Action::RenderView';
test_requires 'Catalyst::Plugin::ConfigLoader';
test_requires 'Catalyst::Plugin::Session::Store::File';
test_requires 'Catalyst::Plugin::Session::State::Cookie';
test_requires 'JSON';

auto_install;

WriteAll;

