
use strict ;
use warnings ;

use t::Jump qw(jump_test) ;

jump_test
	(
	name => 'cwd added',

	temporary_directory_structure => 
		{
		A => {}, 
		},
	db_start => {},
 	tests =>
		[
		{
		command => q{ run('--add', 'A') },
		db_expected => {'TD/A' => 1},
		} ,
		]
	) ;

jump_test
	(
	name => 'direct_path',

	temporary_directory_structure => 
		{
		existing_test_directory => {}, 
		sub_directory =>
			{
			existing_test_directory => {},
			},
		},
	db_start => {},
 	tests =>
		[
		{
		command => q{ run('--add', 'TD/existing_test_directory') },
		db_expected => {'TD/existing_test_directory' => 1},
		} ,
		{
		command => q{ run('--add', 'TD/sub_directory/existing_test_directory') },
		db_expected => 
			{
			'TD/existing_test_directory' => 1,
			'TD/sub_directory/existing_test_directory' => 1,
			 },
		} ,
		]
	) ;

jump_test
	(
	name => 'no_existing_path',

	temporary_directory_structure => 
		{
		existing_test_directory => {}, 
		sub_directory =>
			{
			existing_test_sub_directory => {},
			},
		},
	db_start => {},
 	tests =>
		[
		{
		command => q{ run('--add', 'TD/non_existing_test_directory') },
		warnings_expected => [qr{Jump: Warning, directory '.+/non_existing_test_directory' doesn not exist, ignoring it}],
		db_expected => {},
		} ,
		{
		command => q{ run('--add', 'TD/non_existing_sub_directory/non_existing_test_directory') },
		warnings_expected => [qr{Jump: Warning, directory '.+/non_existing_sub_directory/non_existing_test_directory' doesn not exist, ignoring it}],
		db_expected => {}, 
		} ,
		]
	) ;

jump_test
	(
	name => 'default_to_cwd',

	temporary_directory_structure => {}, 
	db_start => {},
 	tests =>
		[
		{
		command => q{ run('--add') },
		db_expected => {'TD' => 1},
		} ,
		]
	) ;


jump_test
	(
	name => 'increase',

	temporary_directory_structure => {}, 
	db_start => {},
 	tests =>
		[
		{
		command => q{ run('--add') },
		db_expected => {'TD' => 1},
		} ,
		{
		command => q{ run('--add', 10) },
		db_expected => {'TD' => 11},
		} ,
		]
	) ;


jump_test
	(
	name => 'reversed arguments',

	temporary_directory_structure => {}, 
	db_start => {},
 	tests =>
		[
		{
		command => q{ run('--add', 'TD', 10) },
		db_expected => {'TD' => 10},
		} ,
		]
	) ;

#---------------
jump_test
	(
	name => 'remove all',

	temporary_directory_structure => {subdir => {}}, 
	db_start => {},
 	tests =>
		[
		{
		command => q{ run('--add', 'TD', 10) },
		db_expected => {'TD' => 10},
		} ,
		{
		command => q{ run('--add', 'subdir') },
		db_expected => {'TD' => 10, 'TD/subdir' => 1},
		} ,
		{
		command => q{ run('--remove_all') },
		db_expected => {},
		} ,
		]
	) ;

jump_test
	(
	name => 'remove',

	temporary_directory_structure => {subdir => {}}, 
	db_start => {},
 	tests =>
		[
		{
		command => q{ run('--add', 'TD', 10) },
		db_expected => {'TD' => 10},
		} ,
		{
		command => q{ run('--add', 'subdir') },
		db_expected => {'TD' => 10, 'TD/subdir' => 1},
		} ,
		{
		command => q{ run('--remove') },
		db_expected => {'TD/subdir' => 1},
		} ,
		]
	) ;

jump_test
	(
	name => 'decrease',

	temporary_directory_structure => {}, 
	db_start => {},
 	tests =>
		[
		{
		commands => 
			[
			q{ run('--add', 'TD', 10) },
			q{ run('--remove', '--add', 5) },
			], 
		db_expected => {'TD' => 5},
		} ,
		]
	) ;

