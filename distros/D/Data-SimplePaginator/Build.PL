use Module::Build;

  my $build = Module::Build->new
    (
     module_name => 'Data::SimplePaginator',
     license => 'perl',
    );
  $build->create_build_script;

use Module::Build::Compat;
Module::Build::Compat->write_makefile('makefile'=>'Makefile','build_class'=>'Module::Build');
