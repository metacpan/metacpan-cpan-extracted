use strict;
use warnings;
use inc::Module::Install;

all_from      'lib/DBIx/CSSQuery.pm';

name 'DBIx-CSSQuery';

build_requires  'Test::More'        => '0.88';

requires
    'DBD::SQLite' => 0,
    'Sub::Exporter' => 0,
    'self' => '0.32',
    'DBI' => 0;

license        'mit';
repository     'http://github.com/gugod/dbix-cssquery';

tests 't/*.t';
author_tests 'xt/*.t';

WriteAll;


