#!/usr/bin/perl -w
use strict;
use ExtUtils::MakeMaker;

my $build_requires = {
        'ExtUtils::MakeMaker'   => 6.60,
        'Test::More'            => 0.94,
    };

my $prereq_pm = {
        'Class::C3::Adopt::NEXT'=> 0.13,
        'CTK'                   => 1.16,
        'Data::Dumper'          => 0,
        'DBI'                   => 1.60,
        'DBD::SQLite'           => 1.40,
        'File::Copy'            => 2.18,
        'File::Find'            => 1.15,
        'File::Path'            => 2.00,
        'HTTP::Cookies'         => 6.00,
        'HTTP::Message'         => 6.02,
        'JSON'                  => 2.53,
        'LWP'                   => 5.80,
        'LWP::MediaTypes'       => 6.00,
        'LWP::UserAgent'        => 5.80,
        'Mail::POP3Client'      => 2.18,
        'Module::Loaded'        => 0.04,
        'Net::Ping'             => 2.36,
        'Net::SMTP'             => 2.31,
        'Net::Telnet'           => 3.03,
        'TemplateM'             => 3.03,
        'Text::SimpleTable'     => 2.03,
        'Text::Unidecode'       => 0.04,
        'Try::Tiny'             => 0.07,
        'WWW::MLite'            => 1.05,
        'URI'                   => 1.50,
        'XML::Simple'           => 2.20,
        'YAML::Tiny'            => 1.50,
    };
my $exefiles = [qw[
        bin/monm
        bin/oradebug
        bin/sendalertsms
        bin/alertgrid_snmp
        bin/alertgrid_nginx
        bin/checkers/ftpchecker
        bin/checkers/pop3checker
        bin/checkers/sshchecker
        bin/checkers/pingchecker
        bin/checkers/smtpchecker
    ]];

WriteMakefile(
    'NAME'                  => 'App::MonM',
    'DISTNAME'              => 'App-MonM',
    'MIN_PERL_VERSION'      => 5.008001,
    'VERSION_FROM'          => 'lib/App/MonM.pm', 
    'ABSTRACT_FROM'         => 'lib/App/MonM.pm', ,
    'BUILD_REQUIRES'        => $build_requires,
    'PREREQ_PM'             => $prereq_pm,
    'EXE_FILES'             => $exefiles,
    'AUTHOR'                => 'Lepenkov Sergey (Serz Minus) <minus@mail333.com>',
    'LICENSE'               => 'gpl',
    'META_MERGE' => {
        recommends => {
            'Data::Dumper'  => 0,
        },
        resources => {
            homepage        => 'http://app-monm.sourceforge.net',
            repository      => 'https://svn.code.sf.net/p/app-monm/code/trunk',
            license         => 'http://opensource.org/licenses/gpl-license.php',
        },
    },
);

1;
