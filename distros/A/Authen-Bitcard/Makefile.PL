use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Authen::Bitcard',
    AUTHOR              => 'Ask Bjoern Hansen <ask@develooper.com>',
    VERSION_FROM        => 'lib/Authen/Bitcard.pm',
    ABSTRACT_FROM       => 'lib/Authen/Bitcard.pm',
    PL_FILES            => {},
    PREREQ_PM => {
                  'Test::More'     => 0,
                  'Math::BigInt'   => 0,
                  'MIME::Base64'   => 0,
                  'Digest::SHA1'   => 0,
                  'LWP::UserAgent' => 0,
                  'HTTP::Status'   => 0,
                  'URI'            => 1.22,
                  'Class::ErrorHandler' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);


