use strict;
use Module::Build;

my $build = Module::Build->new(
    create_makefile_pl => 'passthrough',
    license            => 'perl',
    module_name        => 'DBIx::Class::WebForm',
    create_readme      => 1,
    requires           =>
      { 'DBIx::Class' => 0, 'HTML::Element' => 0, 'Data::FormValidator' => 0 },
    test_files => [ glob('t/*.t') ]
);
$build->create_build_script;
