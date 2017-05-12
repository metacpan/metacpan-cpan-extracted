use Module::Build;
my $build = Module::Build->new(
     module_name => 'Class::Builder',
     license => 'perl',
     requires => {
                  'perl'           => '5.6.1',
                 },
     # PL_files => {},
     # script_files => [qw()]
    );
$build->create_build_script;
