use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME           => 'DB::Transaction',
	AUTHOR         => 'Shutterstock, Inc. <sstk@cpan.org>',
	VERSION_FROM   => 'lib/DB/Transaction.pm',
	ABSTRACT_FROM  => 'lib/DB/Transaction.pm',
	PL_FILES => {},
	PREREQ_PM => {
		'Test::More' => 0,
	},
	META_MERGE => {
		resources => {
			bugtracker => 'https://github.com/shutterstock/perl-db-transaction/issues',
			homepage => 'https://github.com/shutterstock/perl-db-transaction',
			repository => 'git://github.com/shutterstock/perl-db-transaction.git',
		},
	},
	dist => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean => { FILES => 'DB-Transaction-*' },
);
