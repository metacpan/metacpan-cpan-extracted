use 5.14.2;
use strict;
use warnings;

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Catalyst::Plugin::Session::Store::RedisFast',
    LICENSE           => 'perl_5',
    AUTHOR            => 'Pavel Andryushin',
    VERSION_FROM      => 'lib/Catalyst/Plugin/Session/Store/RedisFast.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {
        'Test::Mock::Redis'         => 0,
        'Catalyst::Test'            => 0,
        'Redis::Fast'               => '0.25',
        'CBOR::XS'                  => '1.71',
        'Catalyst'                  => 0,
        'MIME::Base64'              => '3.13',
    },
    META_MERGE   => {
          requires  => { perl => '5.14.2' },
          resources => {
                license     => 'http://dev.perl.org/licenses/',
                repository  => 'https://github.com/vrag86/catalyst-plugin-session-store-redisfast',
                bugtracker  => 'https://github.com/vrag86/catalyst-plugin-session-store-redisfast/issues'
              },
        },
    AUTHOR            => 'vrag <vrag867@gmail.com>',
);

