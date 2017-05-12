use strict;
use warnings;
use inc::Module::Install;

name 'Acme-Lambda-Expr';

all_from 'lib/Acme/Lambda/Expr.pm';

requires 'Exporter'   => 5.57;
requires 'Moose'      => 0.57;
requires 'Data::Util' => 0.10;

test_requires 'Test::More' => 0.62;

WriteMakefile(
	clean => {FILES => q(
			Acme-Lambda-Expr-* *.stackdump
			cover_db
			nytprof
			*.out
		)},
);
