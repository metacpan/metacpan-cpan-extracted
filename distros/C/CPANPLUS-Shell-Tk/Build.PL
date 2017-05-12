use 5.006;
use Module::Build;
my $build = new Module::Build( module_name => 'CPANPLUS::Shell::Tk',
                               license     => 'perl',
                               requires    => { perl             => '5.6.0',
                                                Tk               => 1.0,
                                                Tk::MListbox     => 1.11,
                                                Tk::Pod          => 4.0,
                                                Tk::Splashscreen => 1.0,
                                              }
                             );
$build->create_build_script;
