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
	ABSTRACT_FROM	=> 'lib/Array/Iterator.pm',
	AUTHOR => 'Nigel Horne <njh@bandsman.co.uk>',
	NAME => 'Array::Iterator',
	VERSION_FROM => 'lib/Array/Iterator.pm', # finds $VERSION in the module
	((defined($ExtUtils::MakeMaker::VERSION) && ($ExtUtils::MakeMaker::VERSION >= 6.3002))
		? ('LICENSE'=> 'GPL')
		: ()),
	PREREQ_PM => {
		'Carp' => 0,
		'ExtUtils::MakeMaker' => 6.64,	# Minimum version for TEST_REQUIRES
	}, META_MERGE => {	# https://perldoc.perl.org/CPAN::Meta::Spec
		'meta-spec' => { version => 2 },
		resources => {
			homepage => 'https://metacpan.org/pod/Array::Iterator',
			repository => {
				repository => 'https://github.com/nigelhorne/Array-Iterator',
				type => 'git',
				url => 'git://github.com/nigelhorne/Array-Iterator.git',
				web => 'https://github.com/nigelhorne/Array-Iterator',
				# license => 'http://dev.perl.org/licenses/',
			}, bugtracker => {
				web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Array-Iterator',
				url => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Array-Iterator',
				# web => 'https://github.com/nigelhorne/Array-Iterator/issues',
				# url => 'https://github.com/nigelhorne/Array-Iterator/issues',
				mailto => 'bug-Array-Iterator@rt.cpan.org'
			}
		},
	}, TEST_REQUIRES => {
		'Test::DescribeMe' => 0,
		'Test::Most' => 0,
		'Test::Needs' => 0,
	}, dist => $dist,
	clean => { FILES => 'Array-Iterator-*' },  # Clean up distribution files
);
