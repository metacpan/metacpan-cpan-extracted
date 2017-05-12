use Module::Build;
my $build = Module::Build->new
  (
   dist_abstract	=> 'Electronic structure data accessor objects',
   dist_author		=> 'Jason L. Sonnenberg <sonnenberg.11@osu.edu>',
   dist_version		=> '0.01',
   license 		=> 'perl',
   module_name 		=> 'Chemistry::ESPT',
   requires 		=> {
		      	     'perl'		=> '5.8.8'
			   },
  );
$build->create_build_script;

