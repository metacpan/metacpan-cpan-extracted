use inc::Module::Install 0.65;

name 'Catalyst-Engine-HTTP-POE';
all_from 'lib/Catalyst/Engine/HTTP/POE.pm';

requires 'Catalyst::Runtime';
requires 'POE';

tests 't/0*.t';

auto_install;
WriteAll;
