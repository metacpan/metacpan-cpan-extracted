use inc::Module::Install;
name 'CGI-Application-Plugin-DebugScreen';
all_from 'lib/CGI/Application/Plugin/DebugScreen.pm';

requires 'HTML::Template';
requires 'Devel::StackTrace';
requires 'IO::File';
requires 'CGI::Application' => '4.0';
requires 'CGI::Application::Plugin::ViewCode';
requires 'UNIVERSAL::require';

test_requires 'Test::More';

tests 't/*.t';

auto_set_repository;
WriteAll;

