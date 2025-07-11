use strict;
use warnings;
use ExtUtils::MakeMaker;
use File::Spec;

my $dist = {
	COMPRESS => 'gzip -9f',	# Compress tarball using gzip
	SUFFIX => 'gz',	# File suffix for tarball
};

if($^O eq 'darwin') {
	$dist->{'TAR'} = 'gtar';
}

my $libs;
my $inc;

if($^O eq 'darwin') {
	# MACOS
	$libs = (-d '/opt/homebrew/opt/berkeley-db/lib') ? ['-L/opt/homebrew/opt/berkeley-db/lib -ldb'] : ['-L/usr/local/opt/berkeley-db/lib -ldb'];
	$inc = (-d '/opt/homebrew/opt/berkeley-db/include') ? '-I/opt/homebrew/opt/berkeley-db/include' : '-I/usr/local/opt/berkeley-db/include';
} else {
	$libs = ['-ldb'];
	$inc = '';
}

WriteMakefile(
	NAME => 'DB::Berkeley',
	VERSION_FROM => 'lib/DB/Berkeley.pm',
	AUTHOR	=> q{Nigel Horne <njh@nigelhorne.com>},
	ABSTRACT_FROM => 'lib/DB/Berkeley.pm',
	((defined($ExtUtils::MakeMaker::VERSION) && ($ExtUtils::MakeMaker::VERSION >= 6.3002))
		? ('LICENSE'=> 'GPL')
		: ()),
	'LIBS' => $libs,
	'INC' => $inc,
	TYPEMAPS => ['typemap'],
	'DEFINE' => '',	# e.g., '-DHAVE_SOMETHING'
	PL_FILES => {},
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => 6.64,	# Minimum version for TEST_REQUIRES
	}, PREREQ_PM => {
		'ExtUtils::MakeMaker' => 6.64,	# Minimum version for TEST_REQUIRES
		'Exporter' => 0,
		'XSLoader' => 0,
	}, TEST_REQUIRES => {
		'FindBin' => 0,
		'File::Temp' => 0,
		'Storable' => 0,
		'Test::DescribeMe' => 0,
		'Test::Most' => 0,
		'Test::Needs' => 0,
		'Test::NoWarnings' => 0,
		'autodie' => 0,
		'strict' => 0,
		'warnings' => 0,
	}, dist => $dist,
	clean	 => { FILES => 'DB-Berkeley-*' },
	# META_ADD => {
		# provides => {}
	# },
	META_MERGE => {	# https://perldoc.perl.org/CPAN::Meta::Spec
		'meta-spec' => { version => 2 },
		resources => {
			homepage => 'https://metacpan.org/pod/DB::Berkeley',
			repository => {
				repository => 'https://github.com/nigelhorne/DB-Berkeley',
				type => 'git',
				url => 'git://github.com/nigelhorne/DB-Berkeley.git',
				web => 'https://github.com/nigelhorne/DB-Berkeley',
				# license => 'http://dev.perl.org/licenses/',
			}, bugtracker => {
				mailto => 'bug-DB-Berkeley@rt.cpan.org',
				url => 'https://github.com/nigelhorne/DB-Berkeley/issues',
				# web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=DB-Berkeley',
				web => 'https://github.com/nigelhorne/DB-Berkeley/issues'
			}
		},
	},
	MIN_PERL_VERSION	=> '5.008'
);
