use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'DNS::Robot',
    AUTHOR           => 'DNS Robot <cpan@dnsrobot.net>',
    VERSION_FROM     => 'lib/DNS/Robot.pm',
    ABSTRACT_FROM    => 'lib/DNS/Robot.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.014',
    PREREQ_PM        => {},
    TEST_REQUIRES    => {
        'Test::More' => '0.96',
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            homepage   => 'https://dnsrobot.net',
            repository => {
                type => 'git',
                url  => 'https://github.com/dnsrobot/dns-robot-cli.git',
                web  => 'https://github.com/dnsrobot/dns-robot-cli',
            },
            bugtracker => {
                web => 'https://github.com/dnsrobot/dns-robot-cli/issues',
            },
        },
        keywords => [
            'dns', 'whois', 'ssl', 'spf', 'dkim', 'dmarc',
            'network', 'lookup', 'api', 'client',
        ],
    },
);
