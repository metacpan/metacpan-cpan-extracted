use inc::Module::Install;

name 'DBICx-TxnInsert';
perl_version '5.006001';
author 'Vladimir Timofeev <vovkasm@gmail.com>';
license 'perl';
all_from 'lib/DBICx/TxnInsert.pm';

requires 'DBIx::Class' => 0.08010;

test_requires 'Test::More';
test_requires 'Test::Compile';
test_requires 'DBD::Mock';

githubmeta;

WriteAll;

