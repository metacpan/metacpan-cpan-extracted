use 5.010;
use inc::Module::Install;

name 'DBIx-ThinSQL-SQLite';
version '0.0.17';
license 'gpl3';
perl_version '5.010';

homepage 'https://github.com/mlawren/p5-DBIx-ThinSQL-SQLite';
bugtracker 'https://github.com/mlawren/p5-DBIx-ThinSQL-SQLite/issues';
repository 'git://github.com/mlawren/p5-DBIx-ThinSQL-SQLite.git';

all_from 'lib/DBIx/ThinSQL/SQLite.pm';
readme_from 'lib/DBIx/ThinSQL/SQLite.pm';

cpanfile;

tests_recursive 't';
author_tests 'xt';

no_index package => 'DBIx::ThinSQL::SQLite::agg_sha1';
no_index package => 'DBIx::ThinSQL::SQLite::agg_sha1_hex';
no_index package => 'DBIx::ThinSQL::SQLite::agg_sha1_base64';

auto_install;

WriteAll;
