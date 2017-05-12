use strict;
use warnings;
use ExtUtils::MakeMaker;

my $pm = 'lib/Compress/Huffman/Binary.pm';
my $pod = 'lib/Compress/Huffman/Binary.pod';
my $github = 'github.com/benkasminbullock/compress-huffman-binary';
my $repo = "https://$github";
WriteMakefile (
    NAME => 'Compress::Huffman::Binary',
    VERSION_FROM => $pm,
    ABSTRACT_FROM => $pod,
    AUTHOR => 'Ben Bullock <bkb@cpan.org>',
    LICENSE => 'perl',
    PREREQ_PM => {
    },
    META_MERGE => {
	'meta-spec' => {
	    version => 2,
	},
        resources => {
            repository => {
		type => 'git',
		url => "git://$github.git",
		web => $repo,
	    },
            bugtracker => {
		web => "$repo/issues",
	    },
#	    homepage => 'http://',
        },
    },
    MIN_PERL_VERSION => '5.006001',
    OBJECT => 'Binary.o huffman.o',
#    OPTIMIZE => '-g -Wall',
);
