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
	EXE_FILES => [ 'bin/date-age' ],
    PREREQ_PM => {
	'Time::Local' => 0
	}, TEST_REQUIRES => {
		'IPC::Run3' => 0,
		'Test::DescribeMe' => 0,
		'Test::Most' => 0,
		'Test::Needs' => 0,
		'Test::Which' => 0,
	}, dist => $dist,
	clean		=> { FILES => 'Date-Age-*' },
	META_MERGE => {	# https://perldoc.perl.org/CPAN::Meta::Spec
		'meta-spec' => { version => 2 },
		resources => {
			homepage => 'https://metacpan.org/pod/Date::Age',
			repository => {
				repository => 'https://github.com/nigelhorne/Date-Age',
				type => 'git',
				url => 'git://github.com/nigelhorne/Date-Age.git',
				web => 'https://github.com/nigelhorne/Date-Age',
				# license => 'http://dev.perl.org/licenses/',
			}, bugtracker => {
				mailto => 'bug-Date-Age@rt.cpan.org',
				url => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Date-Age',
				web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Date-Age',
				# url => 'https://github.com/nigelhorne/Date-Age/issues',
				# web => 'https://github.com/nigelhorne/Date-Age/issues'
			}
		},
	},
	MIN_PERL_VERSION	=> '5.010'
);
