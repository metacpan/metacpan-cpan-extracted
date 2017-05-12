
use strict ;
use warnings ;

use t::Jump qw(jump_test) ;

# directory not in database not under cwd, max weight, alphabetically

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
    F:
     in_db: 5
     JULIETTE: {}
 
 B_2:
  in_db: 2
  GOLF_B: {}
 B_3:
  HOTEL_A: {}
 B_4:
  in_db: 10
  JULIETTE: {}
	
DIRECT_PATH:
 BB: 
  in_db: 3

C:
 CC_1: {}
 CC_2: 
  PARTIAL_DIR_CCC:
   in_db: 1
  PARTIAL_DIR_CCC_1:
   in_db: 1
  PARTIAL_DIR_DDD_1:
   in_db: 1
  PARTIAL_DIR_DDD_2:
   in_db: 2
  CHARLIE_CCC:
   in_db: 2 
  FULL_MATCH:
   in_db: 1
 CC_3:
  in_db: 1
  PARTIAL_DIR_CCC_1:
   in_db: 1
  PARTIAL_DIR_CCC_2_AAA:
   in_db: 1
  SAME_WEIGHT_PATH_WEIGHT:
   in_db: 5
 CC_4:
  in_db: 1
  SAME_WEIGHT_DIFF_PATH_WEIGHT:
   in_db: 5
  PARTIAL_DIR_CCC_2_AAA:
   in_db: 1
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
		command => q{ run('--search', 'NO_MATCH', 'A') },
		captured_output_expected => [],
		} ,
		{
		name => 'no  match',
		command => q{ run('--search', 'A', 'B', 'NO_MATCH') },
		captured_output_expected => [],
		} ,


#---------------
		{
		name => 'full directory match',
		command => q{ run('--search', 'C', 'FULL_MATCH') },
		captured_output_expected => ['TD/C/CC_2/FULL_MATCH'],
		} ,

		{
		name => 'multiple full directory match with same weight, same path weight, alpha',
		command => q{ run('--search', 'SAME_WEIGHT_PATH_WEIGHT') },
		weight_expected => 5,
		captured_output_expected => ['TD/C/CC_3/SAME_WEIGHT_PATH_WEIGHT'],
		matches_expected => 
			[
			'TD/C/CC_3/SAME_WEIGHT_PATH_WEIGHT',
			'TD/D/DD_3/SAME_WEIGHT_PATH_WEIGHT',
			],
		} ,
		{
		name => 'multiple full directory match with same weight, different path weight', 
		command => q{ run('--search', 'SAME_WEIGHT_DIFF_PATH_WEIGHT') },
		weight_expected => 5,
		weight_path_expected => 15,
		captured_output_expected => ['TD/D/DD_4/SAME_WEIGHT_DIFF_PATH_WEIGHT'],
		matches_expected => 
			[
			'TD/D/DD_4/SAME_WEIGHT_DIFF_PATH_WEIGHT',
			'TD/C/CC_4/SAME_WEIGHT_DIFF_PATH_WEIGHT',
			],
		} ,
#---------------

		{
		name => 'partial directory match, single match',
		command => q{ run('--search', 'CC', 'FUL') },
		captured_output_expected => ['TD/C/CC_2/FULL_MATCH'],
		} ,

		{
		name => 'partial directory match, different weight',
		command => q{ run('--search', 'CC', 'PARTIAL_DIR_D') },
		captured_output_expected => ['TD/C/CC_2/PARTIAL_DIR_DDD_2'],
		matches_expected => 
			[
			'TD/C/CC_2/PARTIAL_DIR_DDD_2',
			'TD/C/CC_2/PARTIAL_DIR_DDD_1',
			],
		} ,

		{
		name => 'partial directory match, same weight, different path weight',
		command => q{ run('--search', 'CC', 'PARTIAL_DIR_C') },
		captured_output_expected => ['TD/C/CC_3/PARTIAL_DIR_CCC_1'],
		matches_expected => 
			[
			'TD/C/CC_3/PARTIAL_DIR_CCC_1',
			'TD/C/CC_3/PARTIAL_DIR_CCC_2_AAA',
			'TD/C/CC_4/PARTIAL_DIR_CCC_2_AAA',
			'TD/C/CC_2/PARTIAL_DIR_CCC',
			'TD/C/CC_2/PARTIAL_DIR_CCC_1',
			],
		} ,

		{
		name => 'partial directory match, same weight, same path weight, alpha',
		command => q{ run('--search', 'CC', 'AA') },
		captured_output_expected => ['TD/C/CC_3/PARTIAL_DIR_CCC_2_AAA'],
		matches_expected => 
			[
			'TD/C/CC_3/PARTIAL_DIR_CCC_2_AAA',
			'TD/C/CC_4/PARTIAL_DIR_CCC_2_AAA',
			],
		} ,

#---------------
		{
		name => 'partial directory and partial path match, different weight',
		command => q{ run('--search', 'TD', 'CHARLIE') },
		captured_output_expected => ['TD/C/CC_2/CHARLIE_CCC'],
		matches_expected => 
			[
			'TD/C/CC_2/CHARLIE_CCC',
			'TD/D/DD_1/CHARLIE_DDD/DDDD',
			],
		} ,
		# full directory -> different weight -> different path weight, -> alpha

#---------------
		{
		name => 'partial path match, single match',
		command => q{ run('--search', 'D', 'ALPHA') },
		captured_output_expected => ['TD/D/DD_1/ALPHA_DDD'],
		matches_expected => 
			[
			'TD/D/DD_1/ALPHA_DDD/DDDD',
			],
		} ,

		{
		name => 'multiple partial path match, different  weight',
		command => q{ run('--search', 'TD', 'BRAVO') },
		captured_output_expected => ['TD/D/BRAVO_DD'],
		matches_expected => 
			[
			'TD/D/BRAVO_DD/DDD',
			'TD/C/BRAVO/CCC',
			],
		} ,
		{
		name => 'partial path match, same weight, different cumulated weight',
		command => q{ run('--search', 'E', 'DELTA') },
		captured_output_expected => ['TD/E/EE_2/DELTA_EEE_2'],
		matches_expected => 
			[
			'TD/E/EE_2/DELTA_EEE_2/EEEE_2',
			'TD/E/EE_1/DELTA_EEE_1/EEEE_1',
			],
		} ,

		{
		name => 'partial path match, same weight, same cumulated weight, different name',
		command => q{ run('--search', 'EE', 'ECHO') },
		captured_output_expected => ['TD/E/EE_3/ECHO'],
		matches_expected => 
			[
			'TD/E/EE_3/ECHO/ABC',
			'TD/E/EE_3/ECHO/XYZ',
			],
		} ,

#---------------
		{
		name => 'under cwd, nothing in the db',
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
		name => 'under db entries, single match',
		cd => 'TD/NOT_IN_DB',
		command => q{ run('--search', 'FOXTROT') },
		captured_output_expected => ['TD/A/B/C/D/E/FOXTROT'],
		matches_expected => 
			[
			'TD/A/B/C/D/E/FOXTROT',
			],
		} ,

		{
		name => 'under db entries, diff path weight',
		cd => 'TD/NOT_IN_DB',
		command => q{ run('--search', 'JULIETTE') },
		captured_output_expected => ['TD/A/B_4/JULIETTE'],
		matches_expected => 
			[
			'TD/A/B_4/JULIETTE',
			'TD/A/B/C/D/F/JULIETTE',
			] ,
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
		]
	) ;




jump_test
	(
	name => 'search',

	directories_and_db => <<'END_OF_YAML' ,

A:
 BCDE_FG: 
  in_db: 1
 BCDE_HI:
  in_db: 1

END_OF_YAML

 	tests =>
		[
		{
		name => 'match multi in end directory name',
		command => q{ run('--search', 'B', 'C') },
		captured_output_expected => ['TD/A/BCDE_FG'],
		matches_expected => 
			[
			'TD/A/BCDE_FG',
			'TD/A/BCDE_HI',
			],
		} ,

#---------------
		{
		name => 'match mlti in end directoy pth and name',
		command => q{ run('--search', 'A', 'B', 'C') },
		captured_output_expected => ['TD/A/BCDE_FG'],
		matches_expected => 
			[
			'TD/A/BCDE_FG',
			'TD/A/BCDE_HI',
			],
		} ,

		 ],
	) ;

