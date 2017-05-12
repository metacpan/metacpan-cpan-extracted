use inc::Module::Install 0.87;

name 'Catalyst-Plugin-Session-State-Cookie';
all_from 'lib/Catalyst/Plugin/Session/State/Cookie.pm';

requires 'Catalyst'                  => '5.80005';
requires 'Catalyst::Plugin::Session' => '0.27';
requires 'MRO::Compat';
requires 'Moose';
requires 'namespace::autoclean';
test_requires 'Moose';
test_requires 'Test::More';

auto_install;
resources repository => 'http://dev.catalyst.perl.org/repos/Catalyst/Catalyst-Plugin-Session-State-Cookie/trunk/';

if ($Module::Install::AUTHOR) {
    system("pod2text lib/Catalyst/Plugin/Session/State/Cookie.pm > README")
        and die;
}

WriteAll;
