use ExtUtils::MakeMaker;
use strict;

my $version = '1.0';

WriteMakefile(
	      NAME            => 'Catalyst::Model::DBR',
	      VERSION         => $version,
	      PREREQ_PM       => {
				  'DBR'             => 0,
				  'Catalyst::Model' => 0
				 },
	     );
