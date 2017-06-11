use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Business::Bitcoin',
    AUTHOR              => q{Ashish Gulhati <biz-btc at hash.neo.tc>},
    VERSION_FROM        => 'lib/Business/Bitcoin.pm',
    ABSTRACT_FROM       => 'lib/Business/Bitcoin.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'artistic_2')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
	'LWP' => 6.15,
	'LWP::Protocol::https' => 0,
	'Test::More' => 0,
	'DBI' => 0,
	'DBD::SQLite' => 1.54,
	'Math::EllipticCurve::Prime' => 0.003,
	'Digest::SHA' => 5.95,
	'Encode::Base58::BigInt' => 0,
	'Crypt::RIPEMD160' => 0,
	'Mozilla::CA' => 0
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Business-Bitcoin-*' },
);
