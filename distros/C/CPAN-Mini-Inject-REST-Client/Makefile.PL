use inc::Module::Install;

name     'CPAN-Mini-Inject-REST-Client';
all_from 'lib/CPAN/Mini/Inject/REST/Client.pm';
author   q{Jon Allen (JJ) <jj@jonalen.info>};
license  'perl';

requires 'App::Cmd';
requires 'Config::General';
requires 'File::HomeDir';
requires 'HTTP::Request::Common';
requires 'JSON';
requires 'REST::Client';
requires 'Try::Tiny';
requires 'URI';

build_requires 'Test::More';

install_script 'bin/mcpani-client';

auto_install;

WriteAll;

