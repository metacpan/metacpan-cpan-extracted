use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Cuckoo::Filter',
    license             => 'artistic2',
    dist_author         => 'Kenji Doi <kend@cpan.org>',
    dist_version_from   => 'lib/Cuckoo/Filter.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
    },
    add_to_cleanup      => [ 'Cuckoo-Filter-*' ],
);

$builder->create_build_script();
