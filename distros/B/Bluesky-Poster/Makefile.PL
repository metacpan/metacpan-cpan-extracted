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
	NAME => 'Bluesky::Poster',
	AUTHOR => q{Nigel Horne <njh@nigelhorne.com>},
	ABSTRACT_FROM => 'lib/Bluesky/Poster.pm',
	VERSION_FROM => 'lib/Bluesky/Poster.pm',
	LICENSE => 'GPL',
	EXE_FILES => [ 'bin/bluesky' ],
	PREREQ_PM => {
		'Carp' => 0,
		'LWP::UserAgent' => 0,
		'JSON::MaybeXS' => 0,
		'Object::Configure' => 0,
		'Params::Validate::Strict' => 0,
		'Params::Get' => 0,
		'URI' => 0,
	}, TEST_REQUIRES => {
		'Test::DescribeMe' => 0,
		'Test::Most' => 0,
	}, dist => $dist,
	clean => {
		FILES => 'Bluesky-Poster-*',
	}
);
