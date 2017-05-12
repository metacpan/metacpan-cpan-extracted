use inc::Module::Install;

all_from 'lib/CGI/Application/Plugin/Header.pm';
readme_from 'lib/CGI/Application/Plugin/Header.pm';

repository 'https://github.com/anazawa/p5-CGI-Application-Plugin-Header';

requires 'parent';
requires 'Exporter';
requires 'CGI::Header' => '0.63';

test_requires 'Test::More';
test_requires 'Test::Pod';
test_requires 'CGI::Application';
test_requires 'CGI::Application::Plugin::Redirect' => '1.00';
test_requires 'CGI::Application::Plugin::Stream' => '2.10';
test_requires 'CGI::Application::Plugin::Session' => '1.04';

tests 't/*.t xt/*.t';

WriteAll;
