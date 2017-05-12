use inc::Module::Install 0.65;

name 'Catalyst-Controller-BindLex';
all_from 'lib/Catalyst/Controller/BindLex.pm';

perl_version '5.8.1';

requires 'Catalyst::Runtime';
requires 'PadWalker';
requires 'Devel::LexAlias';
requires 'Devel::Caller';
requires 'Array::RefElem';
requires 'Test::use::ok';

auto_install;
WriteAll;
