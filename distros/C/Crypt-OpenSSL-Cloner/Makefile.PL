use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Crypt::OpenSSL::Cloner',
    AUTHOR              => q{M. Nunberg <mnunberg@haskalah.org>},
    VERSION_FROM        => 'lib/Crypt/OpenSSL/Cloner.pm',
    ABSTRACT_FROM       => 'lib/Crypt/OpenSSL/Cloner.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'            => 0,
		'Crypt::OpenSSL::CA'    => 0,
		'Crypt::OpenSSL::RSA'   => 0,
		'Convert::ASN1'         => 0,
        'File::Slurp'           => 0,
    },
    
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Crypt-OpenSSL-Cloner-*' },
);
