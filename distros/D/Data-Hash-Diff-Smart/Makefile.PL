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
	NAME		 => 'Data::Hash::Diff::Smart',
	ABSTRACT_FROM => 'lib/Data/Hash/Diff/Smart.pm',
	VERSION_FROM => 'lib/Data/Hash/Diff/Smart.pm',
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
		'Test::DescribeMe' => 0,
		'Test::Most' => 0,
		'Test::Needs' => 0,
	}, dist => $dist,
	clean		=> { FILES => 'Data-Hash-Diff-Smart-*' },
	META_MERGE => {	# https://perldoc.perl.org/CPAN::Meta::Spec
		'meta-spec' => { version => 2 },
		resources => {
			homepage => 'https://metacpan.org/pod/Data::Hash::Diff::Smart',
			repository => {
				repository => 'https://github.com/nigelhorne/Data-Hash-Diff-Smart',
				type => 'git',
				url => 'git://github.com/nigelhorne/Data-Hash-Diff-Smart.git',
				web => 'https://github.com/nigelhorne/Data-Hash-Diff-Smart',
				# license => 'http://dev.perl.org/licenses/',
			}, bugtracker => {
				web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Hash-Diff-Smart',
				url => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Hash-Diff-Smart',
				# web => 'https://github.com/nigelhorne/Data-Hash-Diff-Smart/issues',
				# url => 'https://github.com/nigelhorne/Data-Hash-Diff-Smart/issues',
				mailto => 'bug-Data-Hash-Diff-Smart@rt.cpan.org'
			}
		},
	},
	MIN_PERL_VERSION	=> '5.008'
);
