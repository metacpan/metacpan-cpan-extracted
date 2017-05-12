use inc::Module::Install;

all_from 'lib/CGI/Application/Emulate/PSGI.pm';
readme_from 'lib/CGI/Application/Emulate/PSGI.pm';

requires 'CGI::Application';
requires 'CGI::Emulate::PSGI' => '0.05';
requires 'Plack';

test_requires 'Test::More' => '0.88';

auto_include;
WriteAll;
