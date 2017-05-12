use utf8;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'App::CatalystStarter::Bloated',
    AUTHOR              => 'Torbjørn Lindahl <torbjorn.lindahl@gmail.com>',
    VERSION_FROM        => 'lib/App/CatalystStarter/Bloated.pm',
    ABSTRACT_FROM       => 'lib/App/CatalystStarter/Bloated.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'File::Which'         => '1.09',
        'Path::Tiny'          => '0.051',
        'Test::FailWarnings'  => '0.008',
        'Test::Most'          => '0.31',
        'Test::Perl::Critic'  => '1.02',
        'Test::Pod'           => '1.48',
        'Test::Pod::Coverage' => '1.08',
        'utf8::all'           => '0.011',
        'Archive::Zip'        => '1.30',
        'Capture::Tiny'       => '0.23',
        'DBI'                 => '1.63',
        'File::ShareDir'      => '1.03',
        'List::MoreUtils'     => '0.33',
        'Log::Log4perl'       => '1.42',
        'Test::Output'        => '1.02',
        'Test::File::ShareDir'=> '0.3.1',
        'Catalyst::Runtime'   => '5.90053',
        'Catalyst::View::JSON'=> '0.30',
        'Catalyst::View::TT'  => '0.41',
        'Moose'               => '2.1005',
        'namespace::autoclean'=> '0.13',
        'IO::All'             => '0.53',
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'App-CatalystStarter-Bloated-*' },
    EXE_FILES           => [qw{bin/catalyst-fatstart.pl}],
);
