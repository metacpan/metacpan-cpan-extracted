use 5.008003;
use warnings;
use strict;
use ExtUtils::MakeMaker;


my %prereqs_os_specific;
if ( $^O eq 'MSWin32' ) {
    %prereqs_os_specific = (
        'Win32::Console::ANSI' => 0,
    );
}


WriteMakefile(
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.008003',
    LICENSE          => 'perl',
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
              type => 'git',
              web  => 'https://github.com/kuerbis/App-DBBrowser',
              url  => 'https://github.com/kuerbis/App-DBBrowser.git',
            },
        },
    },
    AUTHOR           => 'Matthaeus Kiem <cuer2s@gmail.com>',
    NAME             => 'App::DBBrowser',
    ABSTRACT_FROM    => 'lib/App/DBBrowser.pm',
    VERSION_FROM     => 'lib/App/DBBrowser.pm',
    EXE_FILES        => [ 'bin/db-browser' ],
    BUILD_REQUIRES   => {
        'Test::More'             => 0,
    },
    PREREQ_PM => {
        'bytes'                  => 0,
        'if'                     => 0,
        'strict'                 => 0,
        'warnings'               => 0,
        'Clone'                  => 0,
        'Cwd'                    => 0,
        'DBI'                    => 0,
        'Encode'                 => 0,
        'Encode::Locale'         => 0,
        'File::Basename'         => 0,
        'File::Find'             => 0,
        'File::HomeDir'          => 0,
        'File::Spec::Functions'  => 0,
        'File::Temp'             => 0,
        'File::Which'            => 0,
        'FindBin'                => 0,
        'Getopt::Long'           => 0,
        'JSON'                   => 0,
        'List::MoreUtils'        => 0,
        'List::Util'             => 0,
        'Pod::Usage'             => 0,
        'Scalar::Util'           => 0,
        'Spreadsheet::Read'      => 0,
        'Term::Choose'           => '1.500',
        'Term::Choose::LineFold' => '1.500',
        'Term::Choose::Util'     => '0.050',
        'Term::Form'             => 0,
        'Term::TablePrint'       => '0.053',
        'Text::CSV'              => 0,
        %prereqs_os_specific,
    },
    dist  => {
        COMPRESS => 'gzip',
        SUFFIX   => '.gz',
        TARFLAGS => '--format=gnu -cvf',
    },
    clean => {
        FILES => 'App-DBBrowser-*',
    },
);
