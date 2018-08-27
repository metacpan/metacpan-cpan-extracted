use strict;
use warnings;
use ExtUtils::MakeMaker;

sub MY::postamble
{
return <<'POST'
pure_all :: README.md

README.md : lib/$(subst ::,/,$(NAME)).pm
	pod2markdown < '$<' > '$@.~tmp~' && $(MV) -- '$@.~tmp~' '$@'
POST
}

WriteMakefile(
	NAME	          => 'DBIx::Perlish',
	AUTHOR	          => q{Dmitry Karasik <dmitry@karasik.eu.org>},
	VERSION_FROM	  => 'lib/DBIx/Perlish.pm',
	MIN_PERL_VERSION  => '5.14.1',
	LICENSE           => 'bsd',
	PREREQ_PM         => {
		'Keyword::Pluggable' => 1.01,
		'DBI'                => 0,
		'Devel::Caller'      => 0,
		'Pod::Markdown'      => 3.1,
	},
	META_MERGE        => {
		resources => {
			repository => 'http://github.com/dk/DBIx-Perlish',
		},
		no_index  => {
			directory  => [qw(devel t)],
			file	   => [qw(Makefile.PL)],
		},
	},
);
