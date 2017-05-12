use inc::Module::Install 0.64;

name 'Catalyst-Model-CouchDB';

perl_version '5.006';
license 'perl';
all_from 'lib/Catalyst/Model/CouchDB.pm';

requires 'Catalyst' => '5.8';
requires 'CouchDB::Client' => '0.04';

WriteAll;
