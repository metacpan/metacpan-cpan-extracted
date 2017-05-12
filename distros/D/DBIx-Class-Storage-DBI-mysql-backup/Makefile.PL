use strict;
use warnings;
use inc::Module::Install;

name          'DBIx-Class-Storage-DBI-mysql-backup';
all_from      'lib/DBIx/Class/Storage/DBI/mysql/backup.pm';
readme_from   'lib/DBIx/Class/Storage/DBI/mysql/backup.pm';
readme_markdown_from 'lib/DBIx/Class/Storage/DBI/mysql/backup.pm';

requires      'DBIx::Class';
requires      'DBIx::Class::Storage::DBI::mysql';
requires      'MySQL::Backup';
requires      'FindBin::libs';
requires      'Symbol';

test_requires 'Test::More';
test_requires 'Test::mysqld';
test_requires 'FindBin::libs';
test_requires 'DBIx::Class::Schema::Versioned';

resources( repository => 'http://github.com/ngs/p5-dbix-class-storage-dbi-mysql-backup' );

WriteAll;