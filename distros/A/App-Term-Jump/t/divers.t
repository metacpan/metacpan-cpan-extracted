
use strict ;
use warnings ;

use t::Jump qw(jump_test) ;

use File::HomeDir ;
my $default_database_file = home() . '/.jump_db' ;
my $default_configuration_file = home() . '/.jump_config'  ;


jump_test
	(
	name => 'default setup files',

 	tests =>
		[
		{
		command => q{ run('--show_configuration_files') },
		captured_output_expected => 
			[
			$default_database_file,
			$default_configuration_file,
			],
		} ,
		]
	) ;

jump_test
	(
	name => 'database setup file',

	temporary_directory_structure => {subdir => {}}, 

 	tests =>
		[
		{
		command => q{ run('--show_configuration_files') },
		captured_output_expected => 
			[
			'TD/temporary_jump_database',
			$default_configuration_file,
			],
		} ,
		]
	) ;

jump_test
	(
	name => 'setup files',

	temporary_directory_structure => {subdir => {}}, 
	configuration => '{}', # a sting

 	tests =>
		[
		{
		command => q{ run('--show_configuration_files') },
		captured_output_expected => 
			[
			'TD/temporary_jump_database',
			'TD/temporary_jump_configuration',
			],
		} ,
		]
	) ;


#---------------

my $configuration = <<'EOC' ;
{
black_listed_directories =>
	[
	'BLACKLISTED', # string
	qr/BL.*B/, # qr
	],

ignore_case => 1, #case insensitive search and completion

no_direct_path => 1, # ignore directories directly under cwd
no_sub_cwd => 1, # ignore directories and sub directories under cwd
no_sub_db => 1, # ignore directories under the database entries

}
EOC

my $directories_and_db_yaml = <<'END_OF_YAML' ; 
BLACKLISTER_DIR: {}
B_BL_BBB: {}

DIRECT_PATH: {}

NOT_IN_DB:
 A:
  INDIA: {}

A:
 in_db: 5 
 B:
  JULIETTE: {}
 BB: 
  in_db: 3


END_OF_YAML


jump_test
	(
	name => 'search',
	configuration => $configuration,
	directories_and_db => $directories_and_db_yaml, 
	tests =>
		[
		{
		name => 'blacklisted string',
		command => q{ run('--add', 'BLACKLISTED_DIR') },
		captured_output_expected => [],
		db_expected => {'TD/A' => 5, 'TD/A/BB' => 3},
		},  
		{
		name => 'blacklisted qr',
		command => q{ run('--add', 'B_BL_BBB') },
		captured_output_expected => [],
		db_expected => {'TD/A' => 5, 'TD/A/BB' => 3},
		} ,
		{
		name => 'ignore case',
		command => q{ run('--search', 'bb') }, 
		captured_output_expected => ['TD/A/BB'],
		} ,
		{
		name => 'direct path',
		command => q{ run('--search', 'DIRECT_PATH') }, 
		captured_output_expected => [],
		} ,
		{
		name => 'direct path',
		command => q{ run('--search', 'BLACKLISTED_DIR') }, 
		captured_output_expected => [],
		} ,
		{
		name => 'under cdw',
		cd => 'TD/NOT_IN_DB',
		command => q{ run('--search', 'INDIA') },
		captured_output_expected => [],
		} ,
		{
		name => 'under db entries',
		cd => 'TD/NOT_IN_DB',
		command => q{ run('--search', 'JULIETTE')},
		captured_output_expected => [],
		} ,
		]
	) ;

#---------------
jump_test
	(
	name => 'start directory',

	temporary_directory_structure => 
		{
		# /lib is part of the linux filesystem
		blib => 
			{
			a => {},
			},
		lib => 
			{
			a => {},
			},
		},
	db_start => {},
 	tests =>
		[
		{
		command => q{ run('--search', '/lib') },
		captured_output_expected => ['/lib'],
		} ,
		{
		command => q{ run('--search', 'lib', 'a') },
		captured_output_expected => ['TD/blib/a'],
		} ,
		{
		command => q{ run('--search', './lib', 'a') },
		captured_output_expected => ['TD/lib/a'],
		} ,
		{
		command => q{ run('--search', '/lib', 'a') },
		captured_output_expected => ['TD/lib/a'],
		} ,
		],
	) ;

#---------------
jump_test
	(
	name => 'show_database',

	directories_and_db => <<'END_OF_YAML' ,
in_db: 10

existing_test_directory:
 in_db: 5 

sub_directory:
 in_db: 3
 existing_test_directory: {}

END_OF_YAML

 	tests =>
		[
		{
		command => q{ run('--show_database') },
		db_expected => {'TD' => 10, 'TD/sub_directory' => 3, 'TD/existing_test_directory' => 5},
		captured_output_expected => 
			[
			'10 TD',
			'5 TD/existing_test_directory',
			'3 TD/sub_directory',
			],
		} ,
		]
	) ;


#---------------
jump_test
	(
	name => 'show_database',

	directories_and_db => <<'END_OF_YAML' ,
in_db: 10

existing_test_directory:
 in_db: 5 

sub_directory:
 in_db: 3
 existing_test_directory: {}

END_OF_YAML

 	tests =>
		[
		{
		command => q{ run('--search') },
		db_expected => {'TD' => 10, 'TD/sub_directory' => 3, 'TD/existing_test_directory' => 5},
		captured_output_expected => [], 
		} ,
		]
	) ;


#---------------
jump_test
	(
	name => 'argument with slash',

	directories_and_db => <<'END_OF_YAML' ,
A:
 BB:
  in_db: 5 
END_OF_YAML

 	tests =>
		[
		{
		cd => 'TD/A', # make sure we don't find the searched path under cwd
		command => q{ run('--search', 'A') },
		db_expected => {'TD/A/BB' => 5,},
		captured_output_expected => ['TD/A'], 
		} ,
		{
		cd => 'TD/A', # make sure we don't find the searched path under cwd
		command => q{ run('--search', 'B') },
		db_expected => {'TD/A/BB' => 5,},
		captured_output_expected => ['TD/A/BB'], 
		} ,
		{
		cd => 'TD/A', # make sure we don't find the searched path under cwd
		command => q{ run('--search', 'A/B') },
		db_expected => {'TD/A/BB' => 5,},
		captured_output_expected => ['TD/A/BB'], 
		} ,
		]
	) ;


#---------------
jump_test
	(
	name => 'ignore directory in search',

	directories_and_db => <<'END_OF_YAML' ,
A:
 BB:
  in_db: 5 
 .GIT:
  A: {}
  B: {}
  C: {}
 CC:
  IGNORE:
   CCC: {}
  DDD:
   CC: {}

END_OF_YAML

 	tests =>
		[
		{
		command => q{ run('--search', 'C') },
		db_expected => {'TD/A/BB' => 5,},
		captured_output_expected => ['TD/A/.GIT/C'], 
		matches_expected => 
			[
			'TD/A/.GIT/C',
			'TD/A/CC',
			'TD/A/CC/DDD',
			'TD/A/CC/DDD/CC',
			'TD/A/CC/IGNORE',
			'TD/A/CC/IGNORE/CCC',
			],
		},
		{
		name => 'ignore .git and pattern',
		command => q{ run('--ignore_path', '^\.GIT', '--ignore_path', 'IGN', '--search', 'C') },
		captured_output_expected => ['TD/A/CC'], 
		matches_expected => 
			[
			'TD/A/CC',
			'TD/A/CC/DDD',
			'TD/A/CC/DDD/CC',
			],
		},
		{
		name => 'ignore via configuration file',
		configuration => <<'EOC',
			{
			ignore_path => [qr/^\.GIT/, 'IGN'],
			} 
EOC
		#show_test => 1,
		#parsed_options => 1,
		command => q{ run('--search', 'C') },
		captured_output_expected => ['TD/A/CC'], 
		matches_expected => 
			[
			'TD/A/CC',
			'TD/A/CC/DDD',
			'TD/A/CC/DDD/CC',
			],
		},
		{
		name => 'ignore via configuration file and cli',
		configuration => <<'EOC',
			{
			ignore_path => [qr/^\.GIT/],
			}
EOC
		command => q{ run('--ignore_path', 'IGN', '--search', 'C') },
		captured_output_expected => ['TD/A/CC'], 
		matches_expected => 
			[
			'TD/A/CC',
			'TD/A/CC/DDD',
			'TD/A/CC/DDD/CC',
			],
		},
		],
	) ;
 
