use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME                => 'DB::Batch',
	AUTHOR              => q{Chris Becker <clbecker@gmail.com>},
	VERSION_FROM        => 'lib/DB/Batch.pm',
	ABSTRACT_FROM       => 'lib/DB/Batch.pm',
	($ExtUtils::MakeMaker::VERSION >= 6.3002
		? ('LICENSE'=> 'perl')
		: ()),
	PL_FILES            => {},
	PREREQ_PM => {
		'File::Path'  => 0,
		'Digest::MD5' => 0,
		'List::Util'  => 0,
		'POSIX'       => 0,
	},
	META_MERGE => {
		resources => {
			license => 'http://dev.perl.org/licenses/',
			homepage => 'https://github.com/clbecker/DB-Batch',
			repository => 'https://github.com/clbecker/DB-Batch',
		},
	},
	dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean               => { FILES => 'DB-Batch-*' },
);
