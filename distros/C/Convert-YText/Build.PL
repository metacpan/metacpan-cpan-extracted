use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new
  (
   module_name => 'Convert::YText',
   dist_author => [ 'David Bremner <ddb@cpan.org>'],
   (sign => 1),
   requires => {
		'Test::More'=>0,
               },
   license => 'unknown',
   create_readme => 0,
   meta_merge => { 
		  resources => 
		  { homepage =>
		    'http://pivot.cs.unb.ca/git/?p=convert-ytext.git;a=summary' }
		 }
  );

$build->create_build_script;
