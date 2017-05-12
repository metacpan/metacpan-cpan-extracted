use Module::Build;

my $build = new Module::Build 
  (
   module_name  => 'Foo::Bar',
   script_files => [ 'bin/foobar.pl' ],
   dist_author  => 'John Doe',
   license      => 'perl'
  );

$build->create_build_script;
