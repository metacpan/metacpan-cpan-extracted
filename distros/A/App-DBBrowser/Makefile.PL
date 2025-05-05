use 5.016;
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
    MIN_PERL_VERSION => '5.016',
    LICENSE          => 'perl',
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            bugtracker => {
                web => "https://github.com/kuerbis/App-DBBrowser/issues",
            },
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
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'bytes'                      => 0,
        'open'                       => 0,
        'strict'                     => 0,
        'warnings'                   => 0,
        'Cwd'                        => 0,
        'DateTime::Format::Strptime' => 0,
        'DBD::SQLite'                => '1.74',
        'DBD::SQLite::Constants'     => 0,
        'DBI'                        => 0,
        'Encode'                     => 0,
        'Encode::Locale'             => 0,
        'File::Basename'             => 0,
        'File::Find'                 => 0,
        'File::HomeDir'              => 0,
        'File::Spec::Functions'      => 0,
        'File::Which'                => 0,
        'FindBin'                    => 0,
        'Getopt::Long'               => 0,
        'JSON::MaybeXS'              => 0,
        'List::MoreUtils'            => '0.428',
        'List::MoreUtils::XS'        => '0.428',
        'Pod::Usage'                 => 0,
        'Scalar::Util'               => 0,
        'Spreadsheet::Read'          => 0,
        'Storable'                   => 0,
        'String::Substitution'       => 0,
        'String::Unescape'           => 0,
        'SQL::Type::Guess'           => 0,
        'Term::Choose'               => '1.774',
        'Term::Choose::Util'         => '0.145',
        'Term::Form'                 => '0.561',
        'Term::Form::ReadLine'       => '0.561',
        'Term::TablePrint'           => '0.171',
        'Text::CSV_XS'               => 0,
        %prereqs_os_specific,
    },
);
