use inc::Module::Install 0.87;
use strict;

name 'Catalyst-Plugin-FillInForm';
all_from  'lib/Catalyst/Plugin/FillInForm.pm';

requires 'Catalyst' => '5.7012';
requires 'MRO::Compat';
requires 'HTML::FillInForm';

build_requires 'Catalyst::Action::RenderView';

resources repository => 'http://dev.catalyst.perl.org/repos/Catalyst/trunk/Catalyst-Plugin-FillInForm/';

WriteAll();
