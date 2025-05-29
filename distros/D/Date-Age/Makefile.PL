use ExtUtils::MakeMaker;

my $dist = {
	COMPRESS => 'gzip -9f',	# Compress tarball using gzip
	SUFFIX => 'gz',	# File suffix for tarball
};

if($^O eq 'darwin') {
	$dist->{'TAR'} = 'gtar';
}

WriteMakefile(
    NAME         => 'Date::Age',
    VERSION_FROM => 'lib/Date/Age.pm',
    ABSTRACT     => 'Calculate precise or range-based age from dates',
    AUTHOR       => 'Nigel Horne <njh@nigelhorne.com>',
    LICENSE      => 'GPL',
    PREREQ_PM    => {
	'Time::Local' => 0,
	'Time::Piece' => 0
	}, TEST_REQUIRES => {
		'Test::DescribeMe' => 0,
		'Test::Most' => 0,
		'Test::Needs' => 0,
	}, dist => $dist,
	clean		=> { FILES => 'Date-Age-*' },
	META_MERGE => {
		resources => {
			repository => 'https://github.com/nigelhorne/Date-Age',
			bugtracker => 'https://github.com/nigelhorne/Date-Age/issues',
		},
	}
);
