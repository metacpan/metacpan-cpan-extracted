use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Algorithm::Voting',
    license           => 'perl',
    dist_author       => 'John Trammell <johntrammell@gmail.com>',
    dist_version_from => 'lib/Algorithm/Voting.pm',
    requires => {
        'Carp'                  => 0,
        'Class::Accessor::Fast' => 0,
        'Data::Dumper'          => 0,
        'Digest::MD5'           => 0,
        'List::Util'            => 0,
        'Math::BigInt'          => 0,
        'Params::Validate'      => 0,
        'Scalar::Util'          => 0,
    },
    build_requires => {
        'base'                  => 0,
        'strict'                => 0,
        'warnings'              => 0,
	'File::Spec'            => 0,
        'Test::More'            => 0,
        'Test::Exception'       => 0,
        'Module::Build::Compat' => 0,
    },
    recursive_test_files => 1,
    add_to_cleanup       => [ 'Algorithm-Voting-*', '*.bak' ],
);

$builder->create_build_script;

