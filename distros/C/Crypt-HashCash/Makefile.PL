use strict;
use warnings;
use ExtUtils::MakeMaker 6.64;

WriteMakefile(
	      NAME                => 'Crypt::HashCash',
	      AUTHOR              => q{Ashish Gulhati <crypt-hashcash at hash.neo.tc>},
	      VERSION_FROM        => 'lib/Crypt/HashCash.pm',
	      ABSTRACT_FROM       => 'lib/Crypt/HashCash.pm',
              LICENSE             => 'Artistic_2_0',
	      PL_FILES            => {},
	      TEST_REQUIRES       => {
				      'Test::More' => 0,
				     },
	      PREREQ_PM => {
			    'DBI' => 0,
			    'DBD::SQLite' => 0,
			    'Crypt::RSA::Blind' => 0,
			    'Crypt::ECDSA::Blind' => 0,
			    'Crypt::EECDH' => 0,
			    'Math::BaseCnv' => 1.14,
			    'Compress::Zlib' => 0,
			    'Persistence::Object::Simple' => 0,
			   },
	      META_MERGE => {
			     "meta-spec" => { version => 2 },
			     prereqs => {
					 runtime => {
						     recommends => {
								    'Wx' => 0,
								    'IO::Socket::INET' => 0,
								    'GD::Barcode::QRcode' => 0,
								    'Crypt::Diceware' => 0,
								    'IPC::Queue::Duplex' => 1.005,
								    'Authen::TuringImage' => 0,
								    'Business::Bitcoin' => 0
								   },
						    },
					},
			    },
	      EXE_FILES => [ 'bin/vault.pl', 'bin/hashcash.pl' ],
	      dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	      clean               => { FILES => 'Crypt-HashCash-*' },
	     );
