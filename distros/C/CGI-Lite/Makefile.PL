use ExtUtils::MakeMaker;
use strict;
use warnings;
require 5.6.0;


my %MF = (
	NAME      =>   "CGI::Lite",
	ABSTRACT  =>   "Process and decode WWW forms and cookies",
	AUTHOR    =>   'Pete Houston (cpan@openstrike.co.uk)',
	LICENSE         => 'perl',
	META_MERGE => {
		'meta-spec' => { version => 1.4 },
		resources   => {
			bugtracker => 'http://rt.cpan.org/Public/Dist/Display.html?Name=CGI-Lite',
			repository => 'https://github.com/openstrike/perl-CGI-Lite',
#			bugtracker => {
#				web  => 'http://rt.cpan.org/Public/Dist/Display.html?Name=CGI-Lite'
#			},
#			repository => {
#				type => 'git',
#				url  => 'git://github.com/openstrike/perl-CGI-Lite.git',
#				web  => 'https://github.com/openstrike/perl-CGI-Lite',
#			}
		}
	},
	MIN_PERL_VERSION    => '5.6.0',
	PREREQ_PM       =>  {
		'Symbol' => '0',
	},
	TEST_REQUIRES => {
		'Test::More'	=> '0',
	},
	VERSION_FROM    => 'lib/CGI/Lite.pm',
   	'dist'    =>   {
		COMPRESS => 'gzip -9f', 
		SUFFIX   => 'gz'
   	}
);

if ($ExtUtils::MakeMaker::VERSION lt 6.64) {
	if ($ExtUtils::MakeMaker::VERSION ge 6.55) {
		$MF{BUILD_REQUIRES} = $MF{TEST_REQUIRES};
	}
	delete $MF{TEST_REQUIRES};
}
if ($ExtUtils::MakeMaker::VERSION lt 6.55) { delete $MF{BUILD_REQUIRES};   }
if ($ExtUtils::MakeMaker::VERSION lt 6.48) { delete $MF{MIN_PERL_VERSION}; }
if ($ExtUtils::MakeMaker::VERSION lt 6.46) { delete $MF{META_MERGE};       }
if ($ExtUtils::MakeMaker::VERSION lt 6.31) { delete $MF{LICENSE};          }
WriteMakefile (%MF);

print <<End_of_Text;

Now do the following to install CGI::Lite:

    % make
    % make test
    % make install

End_of_Text
