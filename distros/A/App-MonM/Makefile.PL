#!/usr/bin/perl -w
use strict;
use ExtUtils::MakeMaker;

my $build_requires = {
        'ExtUtils::MakeMaker'   => 6.60,
        'Test::More'            => 0.94,
    };

my $prereq_pm = {
        'AnyEvent'              => 7.07, # perl(AnyEvent)
        'Clone'                 => 0.32, # perl(Clone)
        'CTK'                   => 2.08,
        'DBD::SQLite'           => 1.50,
        'Email::MIME'           => 1.90, # libemail-mime-perl
        'Email::Sender'         => 1.30, # libemail-sender-perl
        'IPC::Cmd'              => 0.80,
        'LWP'                   => 5.80,
        'LWP::MediaTypes'       => 6.00,
        'LWP::Protocol::https'  => 6.00,
        'Mail::POP3Client'      => 2.18,
        'Module::Loaded'        => 0.04,
        'Net::Ping'             => 2.36,
        'Net::SMTP'             => 2.31,
        'Net::Telnet'           => 3.03,
        'Socket'                => 0,
        'Sys::Hostname'         => 0,
        'Term::ReadKey'         => 2.33,
        'Text::Tabs'            => 0,
        'Text::Wrap'            => 0,
        'Text::ParseWords'      => 0,
        'Try::Tiny'             => 0,
        'URI'                   => 0,
    };

my $exefiles = [qw[
        bin/monm
        bin/monmd
        bin/monm_dbi
        bin/monm_snmp
        bin/monm_nginx
        bin/monm_ftp
        bin/monm_icmp
        bin/monm_pop3
        bin/monm_smtp
        bin/monm_ssh
        bin/monm_whois
        bin/monm_ssl
    ]];

WriteMakefile(
    'NAME'                  => 'App::MonM',
    'MIN_PERL_VERSION'      => 5.016001,
    'VERSION_FROM'          => 'lib/App/MonM.pm',
    'ABSTRACT_FROM'         => 'lib/App/MonM.pm',
    'BUILD_REQUIRES'        => $build_requires,
    'PREREQ_PM'             => $prereq_pm,
    'EXE_FILES'             => $exefiles,
    'AUTHOR'                => 'Serz Minus (Sergey Lepenkov) <abalama@cpan.org>',
    'LICENSE'               => 'perl',
    'META_MERGE' => { 'meta-spec' => { version => 2 },
        recommends => {
            'Data::Dumper'  => 0,
        },
        resources => {
            homepage        => 'https://app-monm.sourceforge.io',
            repository      => 'https://svn.code.sf.net/p/app-monm/code/trunk',
            license         => 'https://dev.perl.org/licenses',
        },
    },
    clean => {
        FILES => '*.db',
    },
);

1;
