use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'App::Kit',
    AUTHOR        => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>',
    VERSION_FROM  => 'lib/App/Kit.pm',
    ABSTRACT_FROM => 'lib/App/Kit.pm',
    PL_FILES      => {},
    PREREQ_PM     => {
        'Test::More'      => 0,       # testing
        'Test::Exception' => 0,       # testing
        'Capture::Tiny'   => 0,       # testing
        'Class::Unload'   => 0.08,    # testing

        'Moo'                           => 0,
        'Moo::Role'                     => 0,
        'Role::Tiny'                    => 0,
        'Role::Multiton'                => 0,
        'File::Path::Tiny'              => 0.7,
        'Module::Want'                  => 0.6,
        'Cwd'                           => 0,
        'File::Temp'                    => 0.2304,
        'File::Slurp'                   => 9999.19,
        'Path::Iter'                    => 0,
        'File::Spec'                    => 0,
        'FindBin'                       => 0,
        'File::ShareDir'                => 0,
        'String::UnicodeUTF8'           => 0.21,
        'Try::Tiny'                     => 0,
        'Import::Into'                  => 0,
        'MIME::Types'                   => 0,
        'DBI'                           => 0,
        'DBD::SQLite'                   => 0,
        'Web::Detect'                   => 0,
        'IO::Interactive::Tiny'         => 0,
        'Net::Detect'                   => 0,
        'Test::Detect'                  => 0,
        'HTTP::Tiny'                    => 0,         # HTTP::Tiny::Multipart too?
        'Locale::Maketext::Utils'       => 0,
        'Locale::Maketext::Utils::Mock' => 0,
        'Log::Dispatch'                 => 0,
        'Log::Dispatch::Config'         => 0,
        'YAML::Syck'                    => 1.27,
        'JSON::Syck'                    => 1.27,

        #  ex() 'Running::Commentary' too ? seems to occasianlly have trouble installing die to a dep failing
        'Unix::Whereis'     => 0,
        'IPC::Open3::Utils' => 0,
        'Acme::Spork'       => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'App-Kit-*' },
);
