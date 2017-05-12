
use strict ;
use warnings ;

use t::Jump qw(jump_test) ;

# directory not in database not under cwd, max weight, alphabetically

jump_test
	(
	name => 'search',

	directories_and_db => <<'END_OF_YAML' ,
A:
 B:
  in_db: 1
  C:
   D:
    in_db: 1

BETA:
 B:
  in_db: 1
  C:
   D:
    in_db: 1
    ECHO: {}

END_OF_YAML

 	tests =>
		[
		{
		name => '', 
		command => q{ run('--complete', 'B') },
		weight_expected => 1,
		weight_path_expected => 1,
		captured_output_expected => 
			[
			'TD/A/B',
			'TD/BETA/B',
			'TD/A/B/C/D',
			'TD/BETA/B/C/D',
			'TD/A/B/C',
			'TD/BETA',
			'TD/BETA/B/C',
			'TD/BETA/B/C/D/ECHO',
			],
		},
#---------------

		{
		name => '', 
		command => q{ run('--complete', 'ECHO') },
		weight_expected => 0,
		weight_path_expected => 0,
		captured_output_expected => 
			[
			'TD/BETA/B/C/D/ECHO',
			],
		matches_expected => 
			[
			'TD/BETA/B/C/D/ECHO',
			],
		} ,
#---------------

		]
	) ;


