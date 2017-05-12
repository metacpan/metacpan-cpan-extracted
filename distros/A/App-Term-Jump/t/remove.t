
use strict ;
use warnings ;

use t::Jump qw(jump_test) ;

jump_test
	(
	name => 'remove entry',

	directories_and_db => <<'END_OF_YAML' ,
A: {}
A2: {}

END_OF_YAML

 	tests =>
		[
		{
		command => q{ run('--add', 'A') },
		db_expected => {'TD/A' => 1},
		} ,
		{
		command => q{ run('--remove', 'A') },
		db_expected => {},
		} ,
		{
		command => q{ run('--add', 'A') },
		} ,
		{
		command => q{ run('--add', 'A2') },
		db_expected => {'TD/A' => 1, 'TD/A2' => 1},
		} ,
		{
		command => q{ run('--remove', 'A') },
		db_expected => {'TD/A2' => 1},
		} ,
		]
	) ;


jump_test
	(
	name => 'remove all entries',

	directories_and_db => <<'END_OF_YAML' ,
A:
 in_db: 1
A2:
 in_db: 1
B:
 in_db: 1

END_OF_YAML

 	tests =>
		[
		{
		command => q{ run('-s') },
		db_expected => {'TD/A' => 1, 'TD/A2' => 1, 'TD/B' => 1},
		} ,
		{
		command => q{ run('--remove_all') },
		db_expected => {},
		} ,
		]
	) ;


jump_test
	(
	name => 'remove selected entries',

	directories_and_db => <<'END_OF_YAML' ,
A:
 in_db: 1
A2:
 in_db: 1
B:
 in_db: 1
C:
 in_db: 1

END_OF_YAML

 	tests =>
		[
		{
		command => q{ run('-s') },
		db_expected => {'TD/A' => 1, 'TD/A2' => 1, 'TD/B' => 1, 'TD/C' => 1},
		} ,
		{
		command => q{ run('--remove_all', 'A', 'C') },
		db_expected => {'TD/B' => 1},
		} ,
		{
		name => 'path ending with /',
		command => q{ run('--remove_all', 'B/') },
		db_expected => {},
		} ,
		]
	) ;


