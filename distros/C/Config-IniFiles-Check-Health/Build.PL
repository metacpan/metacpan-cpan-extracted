use 5.006;
use strict;
use warnings;
use Module::Build;
Module::Build->VERSION('0.4004');

my $builder = Module::Build->new(
    module_name        => 'Config::IniFiles::Check::Health',
    license            => 'artistic_2',
    dist_author        => q{Richard Lippmann <horshack@cpan.org>},
    dist_version_from  => 'lib/Config/IniFiles/Check/Health.pm',
    release_status     => 'stable',
    configure_requires => {
        'Module::Build' => '0.4004',
    },
    test_requires => {
        'Test::Simple'  => '1.302191',
        'Test::More'    => '0',
        'Test::Compile' => '3.3.3',
    },
    requires => {
        'perl'             => '5.20.0',
        'Config::IniFiles' => "3.000003",
        'Log::Log4perl'    => 0,
        'Moo'              => '2.004000',
        'Params::Validate' => '1.30',
        'strictures'       => '2.000006',
        'namespace::clean' => '0',
    },
    add_to_cleanup => ['Config-IniFiles-Check-Health-*'],
);

$builder->create_build_script();
