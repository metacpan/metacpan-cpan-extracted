use strict;
use warnings;
use ExtUtils::MakeMaker;

my $dist = {
	COMPRESS => 'gzip -9f', # Compress tarball using gzip
	SUFFIX => 'gz',	# File suffix for tarball
};

if($^O eq 'darwin') {
	$dist->{'TAR'} = 'gtar';
}

WriteMakefile(
	AUTHOR		=> q{Nigel Horne <njh@nigelhorne.com>},
	NAME	 => 'Date::Cmp',		# Name of the module
	VERSION_FROM => 'lib/Date/Cmp.pm',	# Automatically fetch version from the module
	ABSTRACT_FROM	=> 'lib/Date/Cmp.pm',
	((defined($ExtUtils::MakeMaker::VERSION) && ($ExtUtils::MakeMaker::VERSION >= 6.3002))
		? ('LICENSE'=> 'GPL')
		: ()),
	PREREQ_PM	=> {						# Dependencies (with versions)
		'ExtUtils::MakeMaker' => 6.64,	# Minimum version for TEST_REQUIRES
		'DateTime::Format::Genealogy' => 0,
		'Scalar::Util' => 0,
		'Term::ANSIColor' => 0
	}, TEST_REQUIRES => {
		'Test::DescribeMe' => 0,
		'Test::Most' => 0,
		'Test::Needs' => 0,
		'Test::Warnings' => 0
	}, dist => $dist,
	clean	 => {
		FILES => 'Date-Cmp-*',
	}, META_MERGE => {	# https://perldoc.perl.org/CPAN::Meta::Spec
		'meta-spec' => { version => 2 },
		resources => {
			homepage => 'https://metacpan.org/pod/Date::Cmp',
			repository => {
				repository => 'https://github.com/nigelhorne/Date-Cmp',
				type => 'git',
				url => 'git://github.com/nigelhorne/Date-Cmp.git',
				web => 'https://github.com/nigelhorne/Date-Cmp'
			}, bugtracker => {
				mailto => 'bug-Date-Cmp@rt.cpan.org',
				url => 'https://github.com/nigelhorne/Date-Cmp/issues',
				# web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Date-Cmp',
				web => 'https://github.com/nigelhorne/Date-Cmp/issues'
			}
		},
	},
	MIN_PERL_VERSION	=> '5.008'
);
