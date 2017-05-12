use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name   => 'Data::Tabular',
    license       => 'perl',
    requires => {
    	'perl'		=> '5.6.0',
    },
    build_requires => {
	'Test::More'     => 0,    
	'Digest::MD5'    => 0,    
    },
    recommends => {
    	'Spreadsheet::WriteExcel' 		=> 0,
    	'Spreadsheet::WriteExcel::Simple' 	=> 0,
	'Spreadsheet::WriteExcel::Utility'	=> 0,
	'Spreadsheet::ParseExcel'	=> 0,
    },
    create_readme      => 1,
    sign               => 1,
    create_makefile_pl => 'traditional',
    add_to_cleanup     => [ 'Data-Tabular-*' ],
);
$builder->create_build_script;
