use ExtUtils::MakeMaker;
use strict;
use warnings;
require 5.6.0;

my %MF = (
	NAME       => "CGI::Lite",
	ABSTRACT   => "Process and decode WWW forms and cookies",
	AUTHOR     => 'Pete Houston (cpan@openstrike.co.uk)',
	LICENSE    => 'perl',
	META_MERGE => {
		'meta-spec' => {
			version => '2',
			url     => 'https://metacpan.org/pod/CPAN::Meta::Spec'
		},
		resources => {
			bugtracker => {
				web =>
				  'https://rt.cpan.org/Public/Dist/Display.html?Name=CGI-Lite'
			},
			repository => {
				type => 'git',
				url  => 'git://gitlab.com/openstrike/cgi-Lite.git',
				web  => 'https://gitlab.com/openstrike/cgi-Lite'
			},
		},
		prereqs => {test => {suggests => {'Test::Trap' => '0.3.0'}}}
	},
	MIN_PERL_VERSION => '5.6.0',
	PREREQ_PM        => {'Symbol' => '0'},
	TEST_REQUIRES    => {'Test::More' => '0'},
	VERSION_FROM     => 'lib/CGI/Lite.pm',
	dist             => {
		COMPRESS => 'gzip -9f',
		SUFFIX   => 'gz'
	},
	clean            => {FILES => 'CGI-Lite-* tmpcgilite'}
);

# Extra tests
if ($ENV{RELEASE_TESTING}   ||
	$ENV{AUTHOR_TESTING}) {
	$MF{test} = { TESTS => 't/*.t xt/*/*.t' };
	$MF{META_MERGE}{prereqs}{test}{requires}{'Test::Vars'} = '0.12';
}

my ($v) = $ExtUtils::MakeMaker::VERSION =~ /([\d._]+)/;
if ($v < 7.12 && $v >= 6.46) {
	$MF{META_MERGE} = {
		'meta-spec' => {version => 1.4},
		resources   => {
			bugtracker =>
			  'https://rt.cpan.org/Public/Dist/Display.html?Name=CGI-Lite',
			repository => 'https://gitlab.com/openstrike/cgi-lite/'
		}
	};
}

if ($v < 6.64) {
	if ($v >= 6.55) {
		$MF{BUILD_REQUIRES} = $MF{TEST_REQUIRES};
	}
	delete $MF{TEST_REQUIRES};
}
if ($v < 6.55) { delete $MF{BUILD_REQUIRES}; }
if ($v < 6.48) { delete $MF{MIN_PERL_VERSION}; }
if ($v < 6.46) { delete $MF{META_MERGE}; }
if ($v < 6.31) { delete $MF{LICENSE}; }
WriteMakefile (%MF);

print <<End_of_Text;

Now do the following to install CGI::Lite:

    % make
    % make test
    % make install

End_of_Text
