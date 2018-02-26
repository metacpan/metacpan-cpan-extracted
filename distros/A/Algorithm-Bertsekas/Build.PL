use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Algorithm::Bertsekas',
    license             => 'perl',
    dist_author         => 'Claudio Fernandes de Souza Rodrigues <claudiofsr@yahoo.com>',
	dist_abstract       => 'auction algorithm for the assignment problem',
    dist_version_from   => 'lib/Algorithm/Bertsekas.pm',
    requires            => {},
    add_to_cleanup      => [ 'Algorithm-Bertsekas-*' ],
);

$builder->create_build_script();
