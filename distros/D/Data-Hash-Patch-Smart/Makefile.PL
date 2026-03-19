use strict;
use warnings;
use ExtUtils::MakeMaker;

my $dist = {
	COMPRESS => 'gzip -9f',	# Compress tarball using gzip
	SUFFIX => 'gz',	# File suffix for tarball
};

if($^O eq 'darwin') {
	$dist->{'TAR'} = 'gtar';
}

WriteMakefile(
	NAME		 => 'Data::Hash::Patch::Smart',
	ABSTRACT_FROM => 'lib/Data/Hash/Patch/Smart.pm',
	VERSION_FROM => 'lib/Data/Hash/Patch/Smart.pm',
	AUTHOR	   => 'Nigel Horne (njh@nigelhorne.com)',
	((defined($ExtUtils::MakeMaker::VERSION) && ($ExtUtils::MakeMaker::VERSION >= 6.3002))
		? ('LICENSE'=> 'GPL')
		: ()),
	PREREQ_PM	=> {
		'Exporter' => 0,
		'JSON::MaybeXS' => 0,
		'Scalar::Util' => 0,
		'YAML::XS' => 0,
	}, CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => 6.64,	# Minimum version for TEST_REQUIRES
	}, TEST_REQUIRES => {
		'Data::Hash::Diff::Smart' => 0,
		'Test::DescribeMe' => 0,
		'Test::Most' => 0,
		'Test::Needs' => 0,
	}, dist => $dist,
	clean		=> { FILES => 'Data-Hash-Patch-Smart-*' },
	META_MERGE => {	# https://perldoc.perl.org/CPAN::Meta::Spec
		'meta-spec' => { version => 2 },
		resources => {
			homepage => 'https://metacpan.org/pod/Data::Hash::Patch::Smart',
			repository => {
				repository => 'https://github.com/nigelhorne/Data-Hash-Patch-Smart',
				type => 'git',
				url => 'git://github.com/nigelhorne/Data-Hash-Patch-Smart.git',
				web => 'https://github.com/nigelhorne/Data-Hash-Patch-Smart',
				# license => 'http://dev.perl.org/licenses/',
			}, bugtracker => {
				web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Hash-Patch-Smart',
				url => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Hash-Patch-Smart',
				# web => 'https://github.com/nigelhorne/Data-Hash-Patch-Smart/issues',
				# url => 'https://github.com/nigelhorne/Data-Hash-Patch-Smart/issues',
				mailto => 'bug-Data-Hash-Patch-Smart@rt.cpan.org'
			}
		},
	},
	MIN_PERL_VERSION	=> '5.008'
);
