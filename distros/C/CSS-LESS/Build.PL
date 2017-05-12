use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'CSS::LESS',
    license             => 'perl',
    dist_abstract	=> 'Compile LESS-stylesheet files (.less) using lessc',
    dist_author         => 'Masanori Ohgita (http://ohgita.info)',
    dist_version_from   => 'lib/CSS/LESS.pm',
    requires => {
        'Test::More'	 => 0,
        'Test::Exception'	 => 0,
        'version'		 => 0,
        'File::Slurp'	 => 0,
        'File::Temp'	 => 0,
        'FindBin'		 => 0,
    },
    add_to_cleanup      => [ 'CSS-LESS-*' ],
);

$builder->create_build_script();
