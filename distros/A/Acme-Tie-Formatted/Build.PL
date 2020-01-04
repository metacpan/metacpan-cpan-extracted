use Module::Build;
Module::Build->new
      ( module_name => 'Acme::Tie::Formatted',
        license => 'perl',
      )->create_build_script;
