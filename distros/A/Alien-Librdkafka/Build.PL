use Alien::Base::ModuleBuild;

my $builder = Alien::Base::ModuleBuild->new(
    module_name => 'Alien::Librdkafka',
    configure_requires => {
        'Alien::Base::ModuleBuild' => '0.005',
        'Module::Build' => '0.28',
    },
    build_requires => {
        'IO::Socket::SSL' => 0,
    },
    requires => {
        'Alien::Base' => '0.005',
    },
    alien_autoconf_with_pic => 0,
    alien_name => 'rdkafka',
    alien_repository => {
        protocol => 'https',
        exact_filename => 'https://github.com/edenhill/librdkafka/archive/v0.11.6.tar.gz',
        exact_version => 'v0.11.6',
    },
    alien_version_check => '%{pkg_config} --atleast-version 0.9.5 %n && %{pkg_config} --modversion %n',
    meta_merge => {
        resources => {
            homepage   => 'https://github.com/trinitum/perl-Alien-Librdkafka',
            bugtracker => 'https://github.com/trinitum/perl-Alien-Librdkafka/issues',
            repository => 'git://github.com/trinitum/perl-Alien-Librdkafka',
        },
        x_contributors => [
            'Pavel Shaydo <zwon@cpan.org>',
        ],
    },
);

$builder->create_build_script;
