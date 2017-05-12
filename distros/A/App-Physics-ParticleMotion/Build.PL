use Module::Build;

my $b = Module::Build->new
  (
   module_name => 'App::Physics::ParticleMotion',
   dist_author => 'Steffen Mueller <modules at steffen-mueller dot net>',
   license => 'perl',
   requires => {
				'Config::Tiny' => 0,
				'Math::Symbolic' => '0.163',
				'Math::RungeKutta' => 0,
				'Math::Project3D' => 0,
				'Tk' => 0,
				'Tk::Cloth' => 0,
				'Time::HiRes' => 0,
               },
   recommends => {
                  'Test::Pod' => '1.0',
                  'Test::Pod::Coverage' => '1.0',
                 },
   build_requires => {
                      'Test::More' => 0,
                     },
   create_makefile_pl => 'traditional',
   sign => 1,
#   conflicts => {},
   script_files => ['bin/tk-motion.pl'],
  );

$b->create_build_script;

