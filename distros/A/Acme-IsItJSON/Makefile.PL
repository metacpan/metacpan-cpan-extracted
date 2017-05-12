use strict;
use warnings;
use ExtUtils::MakeMaker;

my $pm = 'lib/Acme/IsItJSON.pm';
my $pod = 'lib/Acme/IsItJSON.pod';
my $github = 'github.com/benkasminbullock/acme-isitjson';
my $repo = "https://$github";

WriteMakefile (
    NAME => 'Acme::IsItJSON',
    VERSION_FROM => $pm,
    ABSTRACT_FROM => $pod,
    AUTHOR => 'Ben Bullock <bkb@cpan.org>',
    LICENSE => 'perl',
    PREREQ_PM => {
	'JSON::Parse' => '0.42',
	'JSON::Create' => '0.22',
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
);
