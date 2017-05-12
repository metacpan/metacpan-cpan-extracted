use inc::Module::Install 0.64;

name 'CouchDB-Deploy';

perl_version '5.006';
license 'perl';
all_from 'lib/CouchDB/Deploy.pm';

requires 'Sub::Exporter';
requires 'CouchDB::Client';
requires 'Data::Compare';
requires 'File::Spec';

WriteAll;
