use strict;
use warnings;

use Module::Build;

my $build = Module::Build
  ->new( module_name  => "Data::Microformat",
         license      => 'perl',
		 dist_author  => 'Brendan O\'Connor <perl@ussjoin.com>',
		 dist_abstrct => 'A module to parse and create hCards and related microformats',
		 dist_version => 0.04,
		 build_requires => {
							'Test::More'            	=> 0,
						},
         requires     => {
							'HTML::Entities' 			=> 0,
							'HTML::Stream' 				=> 0,
                            'HTML::TreeBuilder'     	=> 0,
							'DateTime::Format::W3CDTF'	=> 0,
                        },
         create_makefile_pl => 'traditional',
       );

$build->create_build_script;

