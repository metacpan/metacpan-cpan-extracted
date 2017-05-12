use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'App::Tweet',
    AUTHOR        => 'Josh McAdams <josh dot mcadams at gmail dot com>',
    VERSION_FROM  => 'lib/App/Tweet.pm',
    ABSTRACT_FROM => 'lib/App/Tweet.pm',
    EXE_FILES     => ['bin/tweet'],
    PL_FILES      => {},
    PREREQ_PM     => {
        'Config::YAML'     => 0,
        'Crypt::Blowfish'  => 0,
        'Crypt::CBC'       => 0,
        'File::HomeDir'    => 0,
        'File::Slurp'      => 0,
        'File::Spec'       => 0,
        'File::Touch'      => 0,
        'FindBin'          => 0,
        'Getopt::Long'     => 0,
        'IO::Interactive'  => 0,
        'Log::Log4perl'    => 0,
        'Net::Twitter'     => 0,
        'Pod::Usage'       => 0,
        'String::Random'   => 0,
        'Term::Prompt'     => 0,
        'Test::MockObject' => 0,
        'Test::More'       => 0,
    },
    dist => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);

