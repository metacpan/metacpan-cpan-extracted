use inc::Module::Install;

name 'Catalyst-Plugin-Session-Store-BerkeleyDB';
all_from 'lib/Catalyst/Plugin/Session/Store/BerkeleyDB.pm';

requires 'BerkeleyDB::Manager';
requires 'Catalyst::Plugin::Session', '0.27';
requires 'Catalyst::Runtime';
requires 'Class::Data::Inheritable';
requires 'MRO::Compat';
requires 'Scalar::Util';
requires 'Storable';
requires 'namespace::clean';

build_requires 'File::Remove';
build_requires 'Test::WWW::Mechanize::Catalyst';
build_requires 'Test::More';
build_requires 'ok';

WriteAll();
