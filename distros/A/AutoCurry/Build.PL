use Module::Build;
my $build = Module::Build->new
( module_name        => "AutoCurry",
  license            => "perl",
  create_makefile_pl => "traditional",
  create_readme      => 1,
  requires           => { Test::More => 0, Carp => 0 },
);

$build->create_build_script;
