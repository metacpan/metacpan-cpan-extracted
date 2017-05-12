use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

use ExtUtils::CppGuess;

my $guess = ExtUtils::CppGuess->new;

WriteMakefile(
    NAME              => 'Acme::TestDist::Cpp::EUMM::EUCppGuess',
    AUTHOR			  => 'Helmut Wollmersdorfer <helmut.wollmersdorfer@gmail.com>',
    ABSTRACT_FROM     => 'lib/Acme/TestDist/Cpp/EUMM/EUCppGuess.pm',
    VERSION_FROM      => 'lib/Acme/TestDist/Cpp/EUMM/EUCppGuess.pm', # finds $VERSION
    MIN_PERL_VERSION  => '5.6.0',
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    dist	 => {
	    PREOP	=> 'pod2text lib/Acme/TestDist/Cpp/EUMM/EUCppGuess.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
	    COMPRESS	=> 'gzip -9v',
	    SUFFIX	=> '.gz',
	},
    $guess->makemaker_options,

    TEST_REQUIRES		=> {
            'Test::More' => '0.88',
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        license  => [ 'perl_5' ],
        prereqs => {
  			runtime => {
    			requires => {
      				'perl'          => '5.006',
    			},
    			recommends => {
    			},
    			suggests => {
    			},
  			},
 			build => {
    			requires => {
    			    'ExtUtils::MakeMaker' => '0',
      				'ExtUtils::CppGuess' => '0.11',
    			},
  			},
  			configure => {
         		requires => {
            		'ExtUtils::MakeMaker' => '0',
            		'ExtUtils::CppGuess' => '0.11',
         		}
      		},
  			test => {
    			requires => {
            		'Test::More' 	  => '0.88',
    			},
  			}
		},
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/wollmers/Acme-TestDist-Cpp-EUMM-EUCppGuess.git',
                web  => 'https://github.com/wollmers/Acme-TestDist-Cpp-EUMM-EUCppGuess',
            },
            homepage => 'https://github.com/wollmers/Acme-TestDist-Cpp-EUMM-EUCppGuess',
            bugtracker => {
                web => 'https://github.com/wollmers/Acme-TestDist-Cpp-EUMM-EUCppGuess/issues',
            },
        },
     },
);

