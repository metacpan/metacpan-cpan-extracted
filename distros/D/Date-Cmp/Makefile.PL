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
	NAME => 'Date::Cmp',		# Name of the module
	VERSION_FROM => 'lib/Date/Cmp.pm',	# Automatically fetch version from the module
	ABSTRACT_FROM	=> 'lib/Date/Cmp.pm',
	((defined($ExtUtils::MakeMaker::VERSION) && ($ExtUtils::MakeMaker::VERSION >= 6.3002))
		? ('LICENSE'=> 'gpl')
		: ()),
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => 6.64,	# Minimum version for TEST_REQUIRES support
	},
	PREREQ_PM	=> {						# Runtime dependencies (with minimum versions)
		'autodie' => 2.06,
		'Carp' => 0,
		'DateTime::Format::Genealogy' => 0.11,
		'Readonly' => 0,
		'Scalar::Util' => 0,
		'Term::ANSIColor' => 0
	}, TEST_REQUIRES => {
		'FindBin' => 0,
		'IPC::System::Simple' => 0,
		'Readonly' => 0,
		'Test::DescribeMe' => 0,
		'Test::Memory::Cycle' => 0,
		'Test::Mockingbird' => 0,
		'Test::Most' => 0,
		'Test::Needs' => 0,
		'Test::Returns' => 0.03,
		'Test::Warnings' => 0,
		'Test::Without::Module' => 0,
	}, dist => $dist,
	clean => {
		FILES => 'Date-Cmp-*',
	}, META_MERGE => {	# https://perldoc.perl.org/CPAN::Meta::Spec
		'meta-spec' => { version => 2 },
		resources => {
			homepage => 'https://metacpan.org/pod/Date::Cmp',
			repository => {
				type => 'git',
				url => 'git://github.com/nigelhorne/Date-Cmp.git',
				web => 'https://github.com/nigelhorne/Date-Cmp'
			}, bugtracker => {
				mailto => 'bug-Date-Cmp@rt.cpan.org',
				url => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Date-Cmp',
				web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Date-Cmp',
				# url => 'https://github.com/nigelhorne/Date-Cmp/issues',
				# web => 'https://github.com/nigelhorne/Date-Cmp/issues'
			}
		},
	},
	MIN_PERL_VERSION	=> '5.008'
);
