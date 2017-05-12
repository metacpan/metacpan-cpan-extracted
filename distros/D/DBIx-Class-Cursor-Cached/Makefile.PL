use strict;
use warnings;
use inc::Module::Install 1;

name 'DBIx-Class-Cursor-Cached';
all_from 'lib/DBIx/Class/Cursor/Cached.pm';

requires 'DBIx::Class' => '0.08124';
requires 'Digest::SHA';
requires 'Carp::Clan' => '6.0';

build_requires 'DBD::SQLite' => '1.25';
build_requires 'Test::More';
build_requires 'Cache::FileCache';

auto_install;

resources repository => 'git://git.shadowcat.co.uk/dbsrgits/DBIx-Class-Cursor-Cached.git';

WriteAll;
