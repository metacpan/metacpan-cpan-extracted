use Module::Build;

my $build = Module::Build->new (
     module_name => 'Alzabo::Display::SWF',
     license => 'perl',
     requires => {
                  'perl'           => '5.6.1',
                  'Alzabo'         => '0.72',
                  'GraphViz'       => '1.6',
                  'SWF'            => '0.01',
                  'YAML'           =>  0
                 },
    );
$build->create_build_script;
