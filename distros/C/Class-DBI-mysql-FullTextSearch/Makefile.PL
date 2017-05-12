use ExtUtils::MakeMaker;

my $me = "lib/Class/DBI/mysql/FullTextSearch.pm";

WriteMakefile(
	NAME          => 'Class::DBI::mysql::FullTextSearch',
	AUTHOR        => 'Tony Bowden <kasei@tmtm.com>',
	ABSTRACT_FROM => $me,
	VERSION_FROM  => $me,
	PREREQ_PM     => {
		'Class::DBI::mysql'    => '0.22',
		'DBIx::FullTextSearch' => '0.57',
		'Lingua::Stem'         => '0.50',
		'Test::Simple'         => '0.17',
	},
);
