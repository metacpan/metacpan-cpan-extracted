use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	NAME	=> 'DBIx::AnyDBD',
	ABSTRACT_FROM => 'lib/DBIx/AnyDBD.pm',
	AUTHOR		=> q{Nigel Horne <njh@bandsman.co.uk>},
	clean		=> { FILES => 'DBIx-AnyDBD-*' },
	TEST_REQUIRES => {
		'Test::Most' => 0,
	}, PREREQ_PM => {
		'DBI' => 0,
	}, META_MERGE => {
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url => 'git://github.com/nigelhorne/DBIx-AnyDBD.git',
				web => 'https://github.com/nigelhorne/DBIx-AnyDBD',
				repository => 'https://github.com/nigelhorne/DBIx-AnyDBD',
			},
			bugtracker => {
				# web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=DBIx-AnyDBD',
				# mailto => 'bug-DBIx-AnyDBD@rt.cpan.org'
				web => 'https://github.com/nigelhorne/DBIx-AnyDBD/issues',
				url => 'https://github.com/nigelhorne/DBIx-AnyDBD/issues',
			}

		},
	},
	VERSION_FROM => 'lib/DBIx/AnyDBD.pm', # finds $VERSION
);
