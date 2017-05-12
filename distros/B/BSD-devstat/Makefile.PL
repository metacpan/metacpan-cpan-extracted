use inc::Module::Install;
name 'BSD-devstat';
all_from 'lib/BSD/devstat.pm';

can_cc or die "This module requires a C compiler";

system("./compstat-gen.PL > compstat.h");

makemaker_args(
    OBJECT => '$(O_FILES)',
    clean => {
        FILES => q{
            *.stackdump
            *.gcov *.gcda *.gcno
            *.out
            nytprof
            cover_db
        },
    },
    LIBS => '-ldevstat',
);

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
