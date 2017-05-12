use strict;
use warnings;
use inc::Module::Install;

all_from 'lib/Acme/Hidek.pm';

use_ppport 3.19;
cc_warnings;

requires 'Mouse';
requires 'Time::Piece';

test_requires 'Test::More' => 0.88; # done_testing()

tests_recursive;
author_tests 'xt';

auto_set_repository() if -d '.git';

clean_files qw(
    Acme-Hidek-* *.stackdump
    *.gcda *.gcno *.gcov
    nytprof *.out
    cover_db
);

WriteAll(check_nmake => 0);

