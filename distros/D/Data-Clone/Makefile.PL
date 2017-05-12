use strict;
use warnings;
use inc::Module::Install;
use Module::Install::XSUtil;

BEGIN{
    *auto_set_repository = sub{ } if !defined &auto_set_repository;
}

all_from 'lib/Data/Clone.pm';

use_xshelper;
cc_warnings;

requires    'parent';

test_requires 'Test::More'     => 0.88; # done_testing()
test_requires 'Test::Requires' => 0.03;

install_headers qw(data_clone.h);

tests 't/*.t t/*/*.t';
author_tests 'xt';

auto_set_repository() if -d '.git';

clean_files qw(
    Data-Clone-* *.stackdump
    *.gcda *.gcno *.gcov
    nytprof *.out
    cover_db
);

WriteAll check_nmake => 0;

