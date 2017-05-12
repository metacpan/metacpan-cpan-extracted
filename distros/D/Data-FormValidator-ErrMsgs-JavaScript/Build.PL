use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Data::FormValidator::ErrMsgs::JavaScript',
    license             => 'perl',
    dist_author         => 'Mark Stosberg <mark@summersault.com>',
    dist_version_from   => 'lib/Data/FormValidator/ErrMsgs/JavaScript.pm',
    build_requires => {
        'Test::More' => 0,
        'Carp'       => 0,
        'Data::FormValidator' => 0,
    },
    create_makefile_pl => 'traditional',
    create_readme => 1,
    add_to_cleanup      => [ 'Data-FormValidator-ErrMsgs-JavaScript-*' ],
);

$builder->create_build_script();
