use inc::Module::Install;

name 'App-TemplateServer-Provider-TD';
all_from 'lib/App/TemplateServer/Provider/TD.pm';

requires 'App::TemplateServer' => '0.02';
requires 'Class::MOP';
requires 'Method::Signatures';
requires 'Module::Pluggable::Object';
requires 'Moose';
requires 'Template::Declare';
build_requires 'Test::More';
build_requires 'ok';

WriteAll();
