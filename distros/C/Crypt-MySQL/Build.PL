use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Crypt::MySQL',
    license             => 'perl',
    dist_author         => 'Tomohiro IKEBE <ikebe@shebang.jp>',
    dist_version_from   => 'lib/Crypt/MySQL.pm',
    requires => {
        'Test::More' => 0,
        'Digest::SHA1' => 0,
    },
    add_to_cleanup      => [ 'Crypt-MySQL-*' ],
);

$builder->create_build_script();
