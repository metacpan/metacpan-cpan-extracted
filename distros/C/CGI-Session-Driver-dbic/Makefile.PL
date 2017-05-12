use inc::Module::Install;

name     'CGI-Session-Driver-dbic';
all_from 'lib/CGI/Session/Driver/dbic.pm';
author   q{Sergey Homenkow <shomenkow@gmail.com>};
license  'perl';

resources homepage => 'http://github.com/hsw/CGI-Session-Driver-dbic';
resources repository => 'git://github.com/hsw/CGI-Session-Driver-dbic.git';

requires 'CGI::Session' => 4;
requires 'DBIx::Class';

test_requires 'Test::More';

auto_install;

WriteAll;
