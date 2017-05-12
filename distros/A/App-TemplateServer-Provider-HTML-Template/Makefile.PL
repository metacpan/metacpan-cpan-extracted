use inc::Module::Install;

name 'App-TemplateServer-Provider-HTML-Template';
all_from 'lib/App/TemplateServer/Provider/HTML/Template.pm';

requires 'App::TemplateServer' => '0.02';
requires 'HTML::Template';
requires 'Method::Signatures';
requires 'Moose';
build_requires 'Test::More';
build_requires 'ok';

WriteAll();
