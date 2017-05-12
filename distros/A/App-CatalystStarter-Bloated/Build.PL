use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'App::CatalystStarter::Bloated',
    license             => 'artistic',
    dist_author         => 'Torbjørn Lindahl <torbjorn.lindahl@gmail.com>',
    dist_version_from   => 'lib/App/CatalystStarter/Bloated.pm',
    requires => {
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
        'HTML::TreeBuilder'   => '5.03',
        'List::MoreUtils'     => '0.33',
        'Log::Log4perl'       => '1.42',
        'Test::Output'        => '1.02',
        'Test::File::ShareDir' => '0.3.1',
        'Catalyst::View::JSON'=> '0.30',
        'Catalyst::View::TT'  => '0.41',
        'Moose'               => '2.1005',
        'namespace::autoclean'=> '0.13',
        'IO::All'             => '0.53',
    },
    configure_requires => {
        'Module::Build'       => '0.42',
    },
    add_to_cleanup      => [ 'App-CatalystStarter-Bloated-*' ],
    script              => [ 'bin/catalyst-fatstart.pl' ],
    share_dir           => { module => { 'App::CatalystStarter::Bloated::Initializr' => ['share'] } },
);

$builder->create_build_script();
