use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'DBIx::ParseDSN',
    license             => 'artistic',
    dist_author         => 'Torbjørn Lindahl <torbjorn.lindahl@gmail.com>',
    dist_version_from   => 'lib/DBIx/ParseDSN.pm',
    requires => {
        'DBI'                       => '1.628',
        'Test::FailWarnings'        => '0.008',
        'Test::Most'                => '0.31',
        'Test::Perl::Critic'        => '1.02',
        'Test::Pod'                 => '1.48',
        'Test::Pod::Coverage'       => '1.08',
        'URI'                       => '1.60',
        'utf8::all'                 => '0.011',
        'Class::Load'               => '0.20',
        'Module::Load::Conditional' => '0.54',
        'Moo'                       => '1.004002',
        'MooX::Aliases'             => '0.001000',
        'MooX::HandlesVia'          => '0.001005',
    },
    add_to_cleanup      => [ 'DBIx-ParseDSN-*' ],
    configure_requires => { 'Module::Build' => 0.42 }
);

$builder->create_build_script();
