use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Crypt::CipherSaber',
    license             => 'perl',
    dist_author         => 'chromatic <chromatic@cpan.org>',
    dist_version_from   => 'lib/Crypt/CipherSaber.pm',
    requires            =>
    {
        'Scalar::Util'  => '1.004002',
    },
    build_requires      =>
    {
        'Test::Simple'  => '0.60',
        'Test::Warn'    => '0.30',
    },
    add_to_cleanup      => [ 'Crypt-CipherSaber-*' ],
    create_makefile_pl  => 'traditional',
);

$builder->create_build_script();
