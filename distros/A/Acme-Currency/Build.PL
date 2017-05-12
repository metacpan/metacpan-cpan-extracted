use Module::Build;

my $b = Module::Build->new
  (
   module_name => 'Acme::Currency',
   dist_author => 'Steffen Mueller <currency-module at steffen-mueller dot net>',
   license => 'perl',
   requires => {
	            'Filter::Simple' => '0',
               },
   recommends => {
                  'Test::Pod' => '1.0',
                  'Test::Pod::Coverage' => '1.0',
                 },
   build_requires => {
                      'Test::More' => 0,
                     },
   create_makefile_pl => 'traditional',
#   sign => 1,
#   conflicts => {},
#   script_files => [],
  );

$b->create_build_script;

