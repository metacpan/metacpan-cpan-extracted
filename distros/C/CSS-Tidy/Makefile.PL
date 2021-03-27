use strict;
use warnings;
use ExtUtils::MakeMaker;

my $pm = 'lib/CSS/Tidy.pm';
my $pod = 'lib/CSS/Tidy.pod';
my $github = 'github.com/benkasminbullock/css-tidy';
my $repo = "https://$github";
WriteMakefile (
    NAME => 'CSS::Tidy',
    VERSION_FROM => $pm,
    ABSTRACT_FROM => $pod,
    AUTHOR => 'Ben Bullock <bkb@cpan.org>',
    LICENSE => 'perl',
    PREREQ_PM => {
	'C::Tokenize' => '0.18',
	'File::Slurper' => '0.012',
    },
    EXE_FILES => [
	'script/csstidy',
    ],
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
);
