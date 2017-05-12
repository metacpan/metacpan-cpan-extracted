use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Data::FormValidator::Tutorial',
    license             => 'perl',
    dist_author         => [
                               'William McKee <william@knowmad.com>',
                               'Jason Purdy <jason@purdy.info>'
                           ],
    dist_abstract       => 'Data::FormValidator Tutorial',
    dist_version_from   => 'lib/Data/FormValidator/Tutorial.pm',
    create_readme       => 1,
);

$builder->create_build_script();
