use Module::Build;

my $b = Module::Build->new
  (
   module_name => 'Acme::Chef',
   dist_author => 'Marc-Philip Werner <mpw96@gmx.de>',
   license => 'perl',
   meta_merge => {
      resources => {
         repository => 'https://github.com/mpw96/perl-Acme-Chef',
         bugtracker => 'https://github.com/mpw96/perl-Acme-Chef/issues', 
      }
   },
   requires => {
	            'File::Temp' => '0',
               },
   recommends => {
                  'Test::Pod' => '1.0',
                  'Test::Pod::Coverage' => '1.0',
                 },
   script_files => ['script/compilechef', 'script/chef'],
   build_requires => {
                      'Test::More' => 0,
                     },
   configure_requires => {
                      'Module::Build' => '0.40',
                     },
   create_makefile_pl => 'traditional',
  );

$b->create_build_script;

