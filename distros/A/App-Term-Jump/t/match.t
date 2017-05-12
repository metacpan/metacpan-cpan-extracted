
use strict ;
use warnings ;

use t::Jump qw(jump_test) ;

jump_test
	(
	name => 'no_match',

	temporary_directory_structure => 
		{
		A => {}, 
		B =>
			{
			C => {},
			},
		D => {},
		},
	db_start => {},
 	tests =>
		[
		{
		command => q{ run('--search', 'E') },
		captured_output_expected => [],
		matches_expected => [],
		} ,
		]
	) ;


jump_test
	(
	name => 'search',

	directories_and_db => <<'END_OF_YAML' ,

NO_SUBDIRS: {}

NOT_IN_DB:
 A:
  B:
   C:
    INDIA: {}
    INDIA2: {}
 A2:
  B:
   C:
    INDIA: {}
A:
 in_db: 5 
 B:
  C:
   D:
    E:
     FOXTROT: {}
     GOLF_A: {}
     HOTEL_B: {}
     
 B_2:
  in_db: 2
  GOLF_B: {}
 B_3:
  HOTEL_A: {}
	
DIRECT_PATH:
 BB: 
  in_db: 3

C:
 CC_1: {}
 CC_2: 
  PARTIAL_DIR_CCC:
   in_db: 1
  CHARLIE_CCC:
   in_db: 2 
  FULL_MATCH:
   in_db: 1
 CC_3:
  in_db: 1
  SAME_WEIGHT_PATH_WEIGHT:
   in_db: 5
 CC_4:
  in_db: 1
  SAME_WEIGHT_DIFF_PATH_WEIGHT:
   in_db: 5
 BRAVO:
  CCC:
   in_db: 1
D:
 DD_1:
  ALPHA_DDD:
   DDDD: 
    in_db: 10
  CHARLIE_DDD:
   DDDD:
    in_db: 1
 DD_2: {}
 DD_3:
  in_db: 1 
  SAME_WEIGHT_PATH_WEIGHT:
   in_db: 5
 DD_4:
  in_db: 10 
  SAME_WEIGHT_DIFF_PATH_WEIGHT:
   in_db: 5
 BRAVO_DD:
  DDD:
   in_db: 10

E:
 EE_1:
  in_db: 1
  DELTA_EEE_1:
   EEEE_1:
    in_db: 1
 EE_2:
  in_db: 2
  DELTA_EEE_2:
   EEEE_2:
    in_db: 1
 EE_3:
  in_db: 5
  ECHO:
   XYZ:
    in_db: 2
   ABC:
    in_db: 2

HEAVY_WEIGHT:
 in_db: 20
 XX:
  XXX:
   XXXX:
    NOT_IN_DB: {}

HEAVY_WEIGHT_2:
 in_db: 10
 XX:
  in_db: 5
  XXX:
   XXXX:
    in_db: 6
    NOT_IN_DB: {}

END_OF_YAML

 	tests =>
		[
		{
		name => 'no  match',
		command => q{ run('--search', 'NO_MATCH') },
		captured_output_expected => [],
		} ,
#---------------
		{
		name => 'direct path match',
		command => q{ run('--search', 'DIRECT_PATH') },
		captured_output_expected => ['DIRECT_PATH'],
		} ,
#---------------
		{
		name => 'full directory match',
		command => q{ run('--search', 'FULL_MATCH') },
		captured_output_expected => ['TD/C/CC_2/FULL_MATCH'],
		} ,
#---------------
		{
		name => 'partial directory match',
		command => q{ run('--search', 'PARTIAL_DIR') },
		captured_output_expected => ['TD/C/CC_2/PARTIAL_DIR_CCC'],
		} ,
		{
		name => 'partial directory and partial path match, different weight',
		command => q{ run('--search', 'CHARLIE') },
		captured_output_expected => ['TD/C/CC_2/CHARLIE_CCC'],
		matches_expected => 
			[
			'TD/C/CC_2/CHARLIE_CCC',
			'TD/D/DD_1/CHARLIE_DDD/DDDD',
			],
		} ,
#---------------
		{
		name => 'partial path match, single match',
		command => q{ run('--search', 'ALPHA') },
		captured_output_expected => 
			[
			'TD/D/DD_1/ALPHA_DDD',
			],
		matches_expected => 
			[
			'TD/D/DD_1/ALPHA_DDD/DDDD',
			],
		} ,
#---------------
		{
		name => 'multiple partial path match, different  weight',
		command => q{ run('--search', 'BRAVO') },
		captured_output_expected => ['TD/D/BRAVO_DD'],
		matches_expected => 
			[
			'TD/D/BRAVO_DD/DDD',
			'TD/C/BRAVO/CCC',
			],
		},
		{
		name => 'multiple partial path match, same weight, different cumulated weight',
		command => q{ run('--search', 'DELTA') },
		captured_output_expected => ['TD/E/EE_2/DELTA_EEE_2'],
		matches_expected => 
			[
			'TD/E/EE_2/DELTA_EEE_2/EEEE_2',
			'TD/E/EE_1/DELTA_EEE_1/EEEE_1',
			],
		}, 
		{
		name => 'multiple partial path match, same weight, same cumulated weight, different name',
		command => q{ run('--search', 'ECHO') },
		captured_output_expected => ['TD/E/EE_3/ECHO'],
		matches_expected => 
			[
			'TD/E/EE_3/ECHO/ABC',
			'TD/E/EE_3/ECHO/XYZ',
			],
		} ,
#---------------
		{
		name => 'multiple full directory match with same weight, same path weight',
		command => q{ run('--search', 'SAME_WEIGHT_PATH_WEIGHT') },
		weight_expected => 5,
		matches_expected => 
			[
			'TD/C/CC_3/SAME_WEIGHT_PATH_WEIGHT',
			'TD/D/DD_3/SAME_WEIGHT_PATH_WEIGHT',
			],
		captured_output_expected => ['TD/C/CC_3/SAME_WEIGHT_PATH_WEIGHT'],
		} ,
		{
		name => 'multiple full directory match with same weight, different path weight', 
		command => q{ run('--search', 'SAME_WEIGHT_DIFF_PATH_WEIGHT') },
		weight_expected => 5,
		weight_path_expected => 15,
		matches_expected => 
			[
			'TD/D/DD_4/SAME_WEIGHT_DIFF_PATH_WEIGHT',
			'TD/C/CC_4/SAME_WEIGHT_DIFF_PATH_WEIGHT',
			],
		captured_output_expected => ['TD/D/DD_4/SAME_WEIGHT_DIFF_PATH_WEIGHT'],
		} ,

#---------------
		# anywhere in the filesystem

		{
		name => 'under cdw',
		cd => 'TD/NOT_IN_DB',
		command => q{ run('--search', 'NOT_EXISTING') },
		captured_output_expected => [],
		matches_expected => [],
		} ,


		{
		name => 'under cw',
		cd => 'TD/NOT_IN_DB',
		command => q{ run('--search', 'INDIA') },
		captured_output_expected => ['TD/NOT_IN_DB/A/B/C/INDIA'],
		matches_expected => 
			[
			'TD/NOT_IN_DB/A/B/C/INDIA',
			'TD/NOT_IN_DB/A/B/C/INDIA2',
			'TD/NOT_IN_DB/A2/B/C/INDIA',
			],
		} ,

#---------------
		{
		name => 'under db entries, uniq match',
		cd => 'TD/NOT_IN_DB',
		command => q{ run('--search', 'FOXTROT') },
		captured_output_expected => ['TD/A/B/C/D/E/FOXTROT'],
		matches_expected => 
			[
			'TD/A/B/C/D/E/FOXTROT',
			],
		} ,

		{
		name => 'under db entries, same_weight, alphabetic order',
		cd => 'TD/NOT_IN_DB',
		command => q{ run('--search', 'HOTEL') },
		captured_output_expected => ['TD/A/B/C/D/E/HOTEL_B'],
		matches_expected => 
			[
			'TD/A/B/C/D/E/HOTEL_B',
			'TD/A/B_3/HOTEL_A',
			] ,
		} ,

		{
		name => 'ignore case, no match',
		cd => 'TD/NOT_IN_DB',
		command => q{ run('--search', 'HoTeL') },
		captured_output_expected => [],
		matches_expected => [], 
		} ,

		{
		name => 'ignore case, no match',
		cd => 'TD/NOT_IN_DB',
		command => q{ run('--search', '--ignore_case', 'HoTeL') },
		captured_output_expected => ['TD/A/B/C/D/E/HOTEL_B'],
		matches_expected => 
			[
			'TD/A/B/C/D/E/HOTEL_B',
			'TD/A/B_3/HOTEL_A',
			] ,
		} ,

		]
	) ;


