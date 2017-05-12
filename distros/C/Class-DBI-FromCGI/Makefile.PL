use ExtUtils::MakeMaker;

my $me = "lib/Class/DBI/FromCGI.pm";

WriteMakefile(
	NAME          => 'Class::DBI::FromCGI',
	AUTHOR        => 'Tony Bowden <kasei@tmtm.com>',
	ABSTRACT_FROM => $me,
	VERSION_FROM  => $me,
	PREREQ_PM     => {
		'Class::DBI'   => 0.91,
		'CGI::Untaint' => 0.8,
		'Test::More'   => '0.17',
	},
);

