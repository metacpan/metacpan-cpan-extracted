use Module::Build;

my $b = Module::Build->new
  (
   module_name => 'Class::Accessor::Assert',
   dist_author => 'Steffen Mueller <accessor-module at steffen-mueller dot net>',
   license => 'perl',
   requires => {
                'Class::Accessor' => '0.25',
                'Class::Data::Inheritable' => '0',
               },
   recommends => {
                  'Test::Pod' => '1.0',
                 },
   build_requires => {
                      'Test::More' => 0,
                     },
   create_makefile_pl => 'traditional',
#   conflicts => {},
#   script_files => [],
  );

$b->create_build_script;

