use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME              => 'Data::Dump::Sexp',
	VERSION_FROM      => 'lib/Data/Dump/Sexp.pm',
	ABSTRACT_FROM     => 'lib/Data/Dump/Sexp.pm',
	AUTHOR            => 'Marius Gavrilescu <marius@ieval.ro>',
	MIN_PERL_VERSION  => '5.14.0',
	LICENSE           => 'perl',
	SIGN              => 1,
	PREREQ_PM         => {
		qw/Data::SExpression 0.41/,
	},
	META_ADD          => {
		dynamic_config => 0,
		resources      => {
			repository   => 'https://git.ieval.ro/?p=data-dump-sexp.git',
		},
	}
);
