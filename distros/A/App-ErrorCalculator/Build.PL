use Module::Build;

my $b = Module::Build->new
  (
   module_name => 'App::ErrorCalculator',
   dist_author => 'Steffen Mueller <modules at steffen-mueller dot net>',
   license => 'perl',
   requires => {
				'Math::Symbolic' => '0.163',
				'Math::SymbolicX::Error' => 0,
				'Math::SymbolicX::NoSimplification' => 0,
				'Number::WithError' => 0.03,
				'Gtk2' => 0,
				'Gtk2::Ex::Dialogs' => 0,
                                'Spreadsheet::Read' => 0,
               },
   recommends => {
                  'Test::Pod' => '1.0',
                  'Test::Pod::Coverage' => '1.0',
                 },
   build_requires => {
                      'Test::More' => 0,
                     },
   create_makefile_pl => 'traditional',
#   conflicts => {},
   script_files => ['bin/errorcalculator'],
  );

$b->create_build_script;

