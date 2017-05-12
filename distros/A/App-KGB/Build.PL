package main;
use strict;
use warnings;
use lib qw(privinc);
use My::Builder;
use utf8;

my $json_rpc_client_module
    = eval { require JSON::RPC::Client }
    ? 'JSON::RPC::Client'
    : 'JSON::RPC::Legacy::Client';

my $builder = My::Builder->new(
    dist_name   => 'App-KGB',
    dist_version_from => 'lib/App/KGB.pm',
    dist_author => [ "Martín Ferrari", "Damyan Ivanov", "gregor herrmann" ],
    license        => 'GPL_2',
    create_license => 1,
    configure_requires => {
        'Module::Build'       => '0.40',
        perl                  => '5.010',
    },
    test_requires => {
        autodie               => 0,
        'File::Remove'        => 0,
        'Git'                          => 0,
        perl                  => '5.010',
        'SVN::Core'                    => 0,
        'SVN::Fs'                      => 0,
        'SVN::Repos'                   => 0,
        'Test::Compile'       => 0,
        'Test::Differences'   => 0,
        'Test::Exception'     => 0,
        'Test::Perl::Critic'  => 0,
        'Test::Pod::Coverage' => 0,
        'Test::Pod'           => 0,
        'Test::Simple'        => '0.92',
        'YAML'                         => 0,
    },
    requires => {
        perl                           => '5.010',
        'Class::Accessor'              => 0,
        'Digest::SHA'                  => 0,
        'DirHandle'                    => 0,
        'File::Touch'                  => 0,
        'Git'                          => 0,
        'IPC::Run'                     => 0,
        'IPC::System::Simple'          => 0,
        'JSON::XS'                     => 0,
        $json_rpc_client_module        => 0,
        'POE'                          => 0,
        'POE::Component::IRC'          => '5.56',
        'POE::Component::Server::SOAP' => 0,
        'Proc::PID::File'              => 0,
        'SOAP::Lite'                   => 0,
        'SVN::Core'                    => 0,
        'SVN::Fs'                      => 0,
        'SVN::Repos'                   => 0,
        'Schedule::RateLimiter'        => 0,
        'Time::Piece'                  => 0,
        'WWW::Shorten'                 => 0,
        'YAML'                         => 0,
    },
    bindoc_dirs  => [qw(script sbin)],
    install_path => {
        sbin => '/usr/sbin',
        etc  => 'etc'
    },
    sbin_files => {
        'script/kgb-bot'          => 'sbin/kgb-bot',
        'script/kgb-add-project'  => 'sbin/kgb-add-project',
        'script/kgb-split-config' => 'sbin/kgb-split-config',
    },
    etc_files => { 'etc/kgb.conf' => 'etc/kgb-bot/kgb.conf' },
    man_files => { 'man5/*' => 'man5/' },
    script_files => [ 'script/kgb-client' ],
    no_index => {
        directory => [ 'privinc' ],
    },
);

$builder->add_build_element('sbin');
$builder->add_build_element('etc');
$builder->add_build_element('man');

$builder->create_build_script();
