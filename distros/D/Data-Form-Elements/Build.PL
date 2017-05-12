use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Data::Form::Elements',
    license             => 'perl',
    dist_author         => ['jason gessner <jason@multiply.org>'],
    dist_version_from   => 'lib/Data/Form/Elements.pm',
    requires => {
        'Test::More' => 0,
        'Data::FormValidator' => 0
    },
    add_to_cleanup      => [ 'Data-Form-Elements-*' ],
    create_makefile_pl  => 'passthrough'
);

$builder->create_build_script();
$builder->create_makefile_pl( 'passthrough' );

