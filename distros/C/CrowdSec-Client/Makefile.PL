use 5.036000;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME           => 'CrowdSec::Client',
    VERSION_FROM   => 'lib/CrowdSec/Client.pm',
    ABSTRACT_FROM  => 'lib/CrowdSec/Client.pm',
    AUTHOR         => 'Yadd <yadd@>',
    LICENSE        => 'perl',
    BUILD_REQUIRES => {
        'Date::Parse'           => 0,
        'HTTP::Request::Common' => 0,
        'JSON'                  => 0,
        'LWP::UserAgent'        => 0,
        'Moo'                   => 0,
    },
    META_MERGE => {
        resources => {
            repository => {
                url  => 'https://github.com/linagora/perl-crowdsec-client.git',
                web  => 'https://github.com/linagora/perl-crowdsec-client',
                type => 'git',
            },
            license    => 'https://opensource.org/license/agpl-v3/',
            bugtracker =>
              'https://github.com/linagora/perl-crowdsec-client/issues',
        },
    },
    PREREQ_PM => {
        'Date::Parse'           => 0,
        'HTTP::Request::Common' => 0,
        'JSON'                  => 0,
        'LWP::UserAgent'        => 0,
        'Moo'                   => 0,
    },
);
