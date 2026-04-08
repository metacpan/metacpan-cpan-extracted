use 5.014;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Data::JSEmail',
    AUTHOR           => q{Bron Gondwana <brong@cpan.org>},
    VERSION_FROM     => 'lib/Data/JSEmail.pm',
    ABSTRACT         => 'Convert between Email::MIME and the JSON format from RFC 8621 (JMAP Mail)',
    LICENSE          => 'Perl_5',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.014,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Email::MIME'                          => 0,
        'Email::MIME::ContentType'             => 0,
        'Email::MIME::Header::AddressList'     => 0,
        'Encode'                               => 0,
        'Encode::MIME::Header'                 => 0,
        'Unicode::Normalize'                   => 0,
        'Date::Format'                         => 0,
        'Date::Parse'                          => 0,
        'DateTime'                             => 0,
        'DateTime::Format::Mail'               => 0,
        'DateTime::Format::ISO8601::Format'    => 0,
        'Data::UUID'                           => 0,
        'Digest::SHA'                          => 0,
        'HTML::Strip'                          => 0,
        'JSON'                                 => 0,
        'JSON::XS'                             => 0,
        'Sys::Hostname'                        => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Data-JSEmail-*' },
);
