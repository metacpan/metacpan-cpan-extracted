use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Crypt::SelfCertificate',
    VERSION_FROM     => 'lib/Crypt/SelfCertificate.pm',
    ABSTRACT         => 'Generate random self-signed SSL certificates in memory',
    AUTHOR           => 'Ryan Scott',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.008001',
    PREREQ_PM        => {
        'strict'          => 0,
        'warnings'        => 0,
        'Exporter'        => 0,
        'File::Basename'  => 0,
        'File::Spec'      => 0,
        'MIME::Base64'    => 0,
        'IO::Socket::SSL' => '2.000',
    },
);
