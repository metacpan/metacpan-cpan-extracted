use strict;
use warnings;
use ExtUtils::MakeMaker;

my $dist = {
	COMPRESS => 'gzip -9f',
	SUFFIX => 'gz'
};

if($^O eq 'darwin') {
	$dist->{'TAR'} = 'gtar';
}

WriteMakefile(
	NAME		=> 'Class::Simple::Readonly::Cached',
	AUTHOR		=> q{Nigel Horne <njh@nigelhorne.com>},
	VERSION_FROM	=> 'lib/Class/Simple/Readonly/Cached.pm',
	ABSTRACT_FROM	=> 'lib/Class/Simple/Readonly/Cached.pm',
	((defined($ExtUtils::MakeMaker::VERSION) &&
	 ($ExtUtils::MakeMaker::VERSION >= 6.3002))
	  ? ('LICENSE'=> 'gpl_2')
	  : ()),
	PL_FILES	=> {},
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => 6.64,	# Minimum version for TEST_REQUIRES
	}, TEST_REQUIRES => {
		'CHI' => 0,
		'Test::Carp' => 0,
		'Test::DescribeMe' => 0,
		'Test::Most' => 0,
		'Test::Needs' => 0,
		'Test::Memory::Cycle' => 0,
		'Test::NoWarnings' => 0,
		'Test::Mockingbird' => 0,
		'Test::Returns' => 0,
		# 'Test::Kwalitee' => 0,
	}, PREREQ_PM => {
		'Carp'         => 0,
		'Class::Simple' => 0,
		'Data::Reuse'  => 0,		# Fails installation tests on recent Perls, RT#100461
		'List::Util'   => 1.33,		# none() added in 1.33
		'Params::Get'  => 0.15,
		'Readonly'     => 0,
		'Scalar::Util' => 0,
		'Sub::Private' => 0.05,
	}, clean => {
		FILES => 'Class-Simple-Readonly-Cached-*'
	}, dist => $dist,
	# META_ADD => {
		# provides => {}
	# },
	META_MERGE		=> {
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url => 'https://github.com/nigelhorne/Class-Simple-Readonly-Cached.git',
				web => 'https://github.com/nigelhorne/Class-Simple-Readonly-Cached',
				repository => 'https://github.com/nigelhorne/Class-Simple-Readonly-Cached',
			}, bugtracker => {
				url => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Class-Simple-Readonly-Cached',
				web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Class-Simple-Readonly-Cached',
				mailto => 'bug-Class-Simple-Readonly-Cached@rt.cpan.org',
				# web => 'https://github.com/nigelhorne/Class-Simple-Readonly-Cached/issues',
				# url => 'https://github.com/nigelhorne/Class-Simple-Readonly-Cached/issues',
			}
		},
	},
	MIN_PERL_VERSION	=> '5.6.2'	# Probably would work, but never tested on earlier versions than this
);
