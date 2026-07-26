use strict;
use warnings;
use ExtUtils::MakeMaker 6.64;	# 6.64 for TEST_REQUIRES

my $dist = {
	COMPRESS => 'gzip -9f',
	SUFFIX => 'gz'
};

if($^O eq 'darwin') {
	$dist->{'TAR'} = 'gtar';
}

WriteMakefile(
	NAME		=> 'DateTime::Format::Genealogy',
	AUTHOR		=> q{Nigel Horne <njh@nigelhorne.com>},
	VERSION_FROM	=> 'lib/DateTime/Format/Genealogy.pm',
	ABSTRACT_FROM	=> 'lib/DateTime/Format/Genealogy.pm',
	((defined($ExtUtils::MakeMaker::VERSION) &&
	 ($ExtUtils::MakeMaker::VERSION >= 6.3002))
	  ? ('LICENSE'=> 'gpl_2')
	  : ()),
	PL_FILES	=> {},
	TEST_REQUIRES => {
		'Data::Dumper' => 0,
		'English' => 0,
		'File::Spec' => 0 ,
		'IPC::System::Simple' => 0,
		'Test::CleanNamespaces' => 0,
		'Test::Carp' => 0,
		'Test::Compile' => 0,
		'Test::Deep' => 0,
		'Test::DescribeMe' => 0,
		'Test::Memory::Cycle' => 0,
		'Test::Most' => 0,
		'Test::Needs' => 0,
		'Test::Mockingbird' => 0,
		'Test::NoWarnings' => 0,
		'Time::HiRes' => 0,
		'Test::Returns' => 0,
		'Test::Warn' => 0,
		'Test::Without::Module' => 0,
		'strict' => 0,
		'warnings' => 0,
		'WWW::RT::CPAN' => 0
	}, PREREQ_PM => {
		'Carp' => 0,
		'DateTime::Format::Natural' => 0,
		'Genealogy::Gedcom::Date' => 2.01,
		'Object::Configure' => 0.23,
		'Params::Get' => 0.15,
		'Params::Validate::Strict' => 0,
		'Readonly' => 0,
		'Readonly::Values::Months' => 0.02,
		'Scalar::Util' => 0,
		'Sub::Private' => 0,
		'Sub::Protected' => 0,
		'namespace::clean' => 0,
	}, dist => $dist,
	clean		=> { FILES => 'DateTime-Format-Genealogy-*' },
	META_MERGE		=> {
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url => 'https://github.com/nigelhorne/DateTime-Format-Genealogy.git',
				web => 'https://github.com/nigelhorne/DateTime-Format-Genealogy',
			},
			bugtracker => {
				# web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=DateTime-Format-Genealogy',
				web => 'https://github.com/nigelhorne/DateTime-Format-Genealogy/issues',
				url => 'https://github.com/nigelhorne/DateTime-Format-Genealogy/issues',
				mailto => 'bug-DateTime-Format-Genealogy@rt.cpan.org'
			}
		},
	},
	MIN_PERL_VERSION	=> '5.10.0'	# Hard requirement: // and //= operators require Perl 5.10.0
);
