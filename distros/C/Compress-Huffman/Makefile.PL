use strict;
use warnings;
use ExtUtils::MakeMaker;

my $pm = 'lib/Compress/Huffman.pm';
my $pod = 'lib/Compress/Huffman.pod';
my $github = 'github.com/benkasminbullock/compress-huffman';
my $repo = "https://$github";

WriteMakefile (
    NAME => 'Compress::Huffman',
    VERSION_FROM => $pm,
    ABSTRACT_FROM => $pod,
    AUTHOR => 'Ben Bullock <bkb@cpan.org>',
    LICENSE => 'perl',
    PREREQ_PM => {
	'Scalar::Util' => 0,
	'JSON::Create' => '0.22',
	'JSON::Parse' => '0.42',
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
#           homepage => 'http://',
        },
    },
    MIN_PERL_VERSION => '5.006001',
);
