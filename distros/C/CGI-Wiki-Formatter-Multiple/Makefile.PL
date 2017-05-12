    use Module::Build::Compat 0.02;
    Module::Build::Compat->run_build_pl(args => \@ARGV);
    Module::Build::Compat->write_makefile();
