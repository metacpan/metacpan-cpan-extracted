use inc::Module::Install;

use 5.010;

name 'App-TemplateServer-Provider-Mason';
all_from 'lib/App/TemplateServer/Provider/Mason.pm';

requires 'App::TemplateServer' => '0.02';
requires 'File::Find';
requires 'HTML::Mason';
requires 'Method::Signatures';
requires 'Moose';
build_requires 'Directory::Scratch';
build_requires 'Test::More';
build_requires 'ok';

WriteAll();
