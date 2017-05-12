use strict;
use warnings;
use ExtUtils::MakeMaker;

my $meta_merge = {
    META_MERGE => {
        resources => {
            repository  => 'https://github.com/pfischermx/foca-perl',
        },
    }
};

WriteMakefile(
    NAME                => 'App::Foca',
    AUTHOR              => q{Pablo Fischer <pablo@yahoo-inc.com>},
    VERSION_FROM        => 'lib/App/Foca/Server.pm',
    ABSTRACT            => 'Foca application - server and client',
    SKIP                => ['examples/example_commands.yaml',
        'examples/foca-client', 'examples/foca-server'],
    PREREQ_PM => {
        'Cache::FastMmap'           => 0,
        'Data::Dumper'              => 0,
        'Exporter'                  => 0,
        'File::Basename'            => 0,
        'FindBin'                   => 0,
        'HTTP::Status'              => 0,
        'HTTP::Response'            => 0,
        'HTTP::Daemon'              => 0,
        'IPC::Cmd'                  => 0,
        'Linux::Proc::Net::TCP'     => 0,
        'Log::Log4perl'             => 0,
        'Moose'                     => 0,
        'Parallel::ForkManager'     => 0,
        'Time::HiRes'               => 0,
        'WWW::Curl::Easy'           => 0,
        'YAML::Syck'                => 0,
        'Test::More'                => 0,
    },
    $ExtUtils::MakeMaker::VERSION >= 6.50 ? (%$meta_merge) : (),
);
