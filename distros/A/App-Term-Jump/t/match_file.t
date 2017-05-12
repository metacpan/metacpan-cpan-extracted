
use strict ;
use warnings ;

use t::Jump qw(jump_test) ;

# directory not in database not under cwd, max weight, alphabetically

jump_test
	(
	name => 'search file',

	directories_and_db => <<'END_OF_YAML' ,

SOME_DIRECTORY:
 A:
  B:
   DIRECTORY:
    FILE:
     - line 1
     - line 2
 A2:
  B:
   C: {}
 A3:
  DIRECTORY:
   in_db: 5 
   FILE:
    - line 1
    - line 2
 A4:
  B:
   C:
    DIRECTORY_XXX:
     in_db: 10 
     FILE:
      - line 1
      - line 2
   DIRECTORY:
    in_db: 10
    ANOTHER_FILE: 
     - line 1
     - line 2

END_OF_YAML

 	tests =>
		[
		{
		name => 'file', 
		command => q{ run('--file', 'FILE', '--search', 'DIRECTORY') },
		weight_expected => 5,
		weight_path_expected => 5,
		captured_output_expected => ['TD/SOME_DIRECTORY/A3/DIRECTORY'],
		matches_expected => 
			[
			'TD/SOME_DIRECTORY/A3/DIRECTORY',
			'TD/SOME_DIRECTORY/A4/B/C/DIRECTORY_XXX',
			],
		} ,
		{
		name => 'file regex', 
		command => q{ run('--file', '*FILE*', '--search', 'DIRECTORY') },
		weight_expected => 10,
		weight_path_expected => 10,
		captured_output_expected => ['TD/SOME_DIRECTORY/A4/B/DIRECTORY'],
		matches_expected => 
			[
			'TD/SOME_DIRECTORY/A4/B/DIRECTORY',
			'TD/SOME_DIRECTORY/A3/DIRECTORY',
			'TD/SOME_DIRECTORY/A4/B/C/DIRECTORY_XXX',
			],
		} ,
		],
	) ;


