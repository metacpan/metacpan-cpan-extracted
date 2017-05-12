use strict;
use warnings;
use inc::Module::Install;

all_from 'lib/Any/Moose/Convert.pm';

requires 'PerlIO::Util';

test_requires 'Moose' => 0.90;
test_requires 'Mouse' => 0.40;
test_requires 'Test::More' => 0.88; # done_testing()

tests 't/*.t', 't/*/*.t';
author_tests 'xt';

auto_set_repository() if -d '.git';

clean_files qw(
    Any-Moose-Convert-*
    *.stackdump
    cover_db
    nytprof
    *.out
);

WriteAll check_nmake => 0;
