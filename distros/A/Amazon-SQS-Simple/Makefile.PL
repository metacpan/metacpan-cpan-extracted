use strict;
use warnings;
use ExtUtils::MakeMaker;
use 5.0073;   # for Encode/utf8

WriteMakefile(
    NAME                => 'Amazon::SQS::Simple',
    AUTHOR              => 'Simon Whitaker <sw@netcetera.org>',
    VERSION_FROM        => 'lib/Amazon/SQS/Simple.pm',
    ABSTRACT_FROM       => 'lib/Amazon/SQS/Simple.pm',
    PL_FILES            => {},
    PREREQ_PM => {
		'AWS::Signature4'   => 0,
        'Test::More'        => 0,
        'Digest::HMAC_SHA1' => 0,
        'Digest::SHA'       => 0,
        'LWP::UserAgent'    => 0,
        'MIME::Base64'      => 0,
        'URI::Escape'       => 0,
        'XML::Simple'       => 0,
        'VM::EC2::Security::CredentialCache' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Amazon-SQS-Simple-*' },
);
