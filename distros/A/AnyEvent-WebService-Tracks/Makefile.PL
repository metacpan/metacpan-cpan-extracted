use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'AnyEvent::WebService::Tracks',
    AUTHOR              => q{Rob Hoelz <rob@hoelz.ro>},
    VERSION_FROM        => 'lib/AnyEvent/WebService/Tracks.pm',
    ABSTRACT_FROM       => 'lib/AnyEvent/WebService/Tracks.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'AnyEvent'                  => 0,
        'AnyEvent::HTTP'            => 0,
        'DateTime'                  => 0,
        'DateTime::Format::ISO8601' => 0,
        'FindBin'                   => 0,
        'List::MoreUtils'           => 0,
        'MIME::Base64'              => 0,
        'namespace::clean'          => 0,
        'Scalar::Util'              => 0,
        'Storable'                  => 0,
        'Test::Exception'           => 0,
        'Test::More'                => 0,
        'URI'                       => 0,
        'XML::Parser'               => 0,
        'XML::Writer'               => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'AnyEvent-WebService-Tracks-*' },
);
