#! /usr/bin/perl
use strict;
use Cwd;

use File::Basename;

use File::Spec 0.82;
use lib File::Spec->catdir('lib');      # use our self to install
use lib File::Spec->catdir('t'); # use bundled Test::More
use Module::Build;
my $build = Module::Build->new
  (
   module_name => 'Config::Basic',
   dist_name => 'Config-Basic',
   dist_abstract => 'Basic parser for simple configuration file',
   license => 'gpl',
   requires => {
		'perl'           => '5.005_03',
		'Data::Dumper'   => 0,
		'Carp' => 0,
		'IO::All'  => 0,
	       },
   recommends => {
		  'Config::General' =>  0,
		  'Pod::Readme' => 0.04,
		 },
   sign => 0,
   create_readme => 1,

   auto_features => {
		     YAML_support =>
		     {
		      description => "Use YAML.pm to write META.yml files",
		      requires => { YAML => ' >= 0.35, != 0.49_01 ' },
		     },
		     manpage_support =>
		     {
		      description => "Create Unix man pages",
		      requires => { 'Pod::Man' => 0 },
		     },
		    },
  );

$build->create_build_script;

