use strict;
use warnings;
use ExtUtils::MakeMaker 6.64;

WriteMakefile(
	      NAME                => 'Crypt::RSA::Blind',
	      AUTHOR              => q{Ashish Gulhati <crypt-rsab at hash.neo.email>},
	      VERSION_FROM        => 'lib/Crypt/RSA/Blind.pm',
	      ABSTRACT_FROM       => 'lib/Crypt/RSA/Blind.pm',
	      PL_FILES            => {},
	      MIN_PERL_VERSION    => '5.020',
	      TEST_REQUIRES       => {
				      'Test::More' => 0,
				     },
	      PREREQ_PM => {
			    'Carp' => '1.50',
			    'Carp::Assert' => '0.21',
			    'Crypt::FDH' => '1.010',
			    'Crypt::Random' => '1.57',
			    'Crypt::RSA' => '1.99',
			    'Compress::Zlib' => '2.106',
			    'Feature::Compat::Class' => '0.07',
                            'Math::Pari' => '2.030523'
			   },
	      dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	      clean               => { FILES => 'Crypt-RSA-Blind-*' },
	     );
