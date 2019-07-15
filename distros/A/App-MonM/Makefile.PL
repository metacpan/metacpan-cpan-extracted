#!/usr/bin/perl -w
use strict;
use ExtUtils::MakeMaker;

my $build_requires = {
        'ExtUtils::MakeMaker'   => 6.60,
        'Test::More'            => 0.94,
    };

my $prereq_pm = {
        'Class::C3::Adopt::NEXT'=> 0.13,
        'CTK'                   => 2.01,
        'DBI'                   => 1.60,
        'DBD::SQLite'           => 1.50,
        'File::Copy'            => 2.18,
        'File::Find'            => 1.15,
        'File::Path'            => 2.00,
        'HTTP::Message'         => 6.02,
        'LWP'                   => 5.80,
        'LWP::MediaTypes'       => 6.00,
        'Mail::POP3Client'      => 2.18,
        'Module::Loaded'        => 0.04,
        'Net::Ping'             => 2.36,
        'Net::SMTP'             => 2.31,
        'Net::Telnet'           => 3.03,
        'Socket'                => 0,
        'Sys::Hostname'         => 0,
        'Term::ReadKey'         => 2.33,
        'Text::SimpleTable'     => 2.03,
        'Try::Tiny'             => 0.07,
        'WWW::MLite'            => 2.01,
        'URI'                   => 1.50,
    };

my $exefiles = [qw[
        bin/monm
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
            homepage        => 'http://app-monm.sourceforge.net',
            repository      => 'https://svn.code.sf.net/p/app-monm/code/trunk',
            license         => 'https://dev.perl.org/licenses',
        },
    },
    clean => {
        FILES => '*.db',
    },
);

1;
