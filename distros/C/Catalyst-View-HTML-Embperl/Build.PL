use strict;
use Module::Build;

my $build = Module::Build->new(
    create_makefile_pl => 'passthrough',
    license            => 'perl',
    module_name        => 'Catalyst::View::HTML::Embperl',
    requires           => { 'Catalyst' => 5, 'HTML::Embperl' => 0 },
    create_makefile_pl => 'passthrough',
    test_files         => [ glob('t/*.t') ]
);
$build->create_build_script;
