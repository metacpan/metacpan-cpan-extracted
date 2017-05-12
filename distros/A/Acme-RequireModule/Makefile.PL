use strict;
use warnings;
use inc::Module::Install;

name 'Acme-RequireModule';
all_from 'lib/Acme/RequireModule.pm';

build_requires 'Test::More' => 0.62;

tests 't/*.t';
author_tests 'xt';

WriteMakefile(
	OBJECT => '$(O_FILES)',

	clean  => {FILES => q(
		Acme-RequireModule-* *.stackdump
		*.gcda *.gcno *.gcov
		nytprof *.out
		cover_db
	)},
);
