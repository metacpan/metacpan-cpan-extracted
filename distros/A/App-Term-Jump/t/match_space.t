
use strict ;
use warnings ;

use t::Jump qw(jump_test) ;


jump_test
	(
	name => 'space and quote',

	directories_and_db => <<'END_OF_YAML' ,

DIRECTORIES:
 THE:
  B: {}

 THE SPACE:
  B:
   C:
    in_db: 1

 THE SECOND SPACE: {}

 A3:
   SPACE IN DB: {}

END_OF_YAML

 	tests =>
		[
		{
		name => 'add space', 
		command => q{ run('--debug', '--add', '5', 'DIRECTORIES/A3/SPACE IN DB') },
		db_expected => 
			{
			'TD/DIRECTORIES/THE SPACE/B/C' => 1,
			'TD/DIRECTORIES/A3/SPACE IN DB' => 5,
			}, 
		} ,

		{
		name => 'find space', 
		command => q{ run('--search', 'SPACE') },
		weight_expected => 5,
		captured_output_expected => ['TD/DIRECTORIES/A3/SPACE IN DB'],
		matches_expected => 
			[
			'TD/DIRECTORIES/A3/SPACE IN DB',
			'TD/DIRECTORIES/THE SPACE/B/C',	
			],
		} ,

		{
		name => 'quoted', 
		command => q{ run('--quote', '--search', 'SPACE') },
		weight_expected => 5,
		captured_output_expected => ['"TD/DIRECTORIES/A3/SPACE IN DB"'],
		matches_expected => 
			[
			'TD/DIRECTORIES/A3/SPACE IN DB',
			'TD/DIRECTORIES/THE SPACE/B/C',	
			],
		} ,

		{
		name => 'complete', 
		command => q{ run('--complete', 'SPACE') },
		weight_expected => 5,
		captured_output_expected => 
			[
			'TD/DIRECTORIES/A3/SPACE IN DB',
			'TD/DIRECTORIES/THE SPACE/B/C',	
			'TD/DIRECTORIES/THE SECOND SPACE',
			'TD/DIRECTORIES/THE SPACE',
			'TD/DIRECTORIES/THE SPACE/B' ,
			],
		} ,
		],
	) ;

