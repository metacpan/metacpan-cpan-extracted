####################################################################
#
#    This file was generated using Parse::Yapp version 1.05.
#
#        Don't edit this file, use source file instead.
#
#             ANY CHANGE MADE HERE WILL BE LOST !
#
####################################################################
package DDC::PP::yyqparser;
use vars qw ( @ISA );
use strict;

@ISA= qw ( Parse::Yapp::Driver );
use Parse::Yapp::Driver;

#line 16 "lib/DDC/PP/yyqparser.yp"


################################################################
##
##      File: DDC::yyqparser.yp
##    Author: Bryan Jurish <moocow@cpan.org>
##
## Description: Yapp parser for DDC queries
##  + OBSOLETE: needs update for ddc-2.x syntax
##
################################################################

##==============================================================
##
## * WARNING * WARNING * WARNING * WARNING * WARNING * WARNING *
##
##==============================================================
##
##  Do *NOT* change yyqparser.pm directly, change yyqparser.yp
##  and re-call 'yapp' instead!
##
##==============================================================

package DDC::PP::yyqparser;
use DDC::Utils qw(:escape);
use DDC::PP::Constants;
use DDC::PP::CQuery;
use DDC::PP::CQCount;
use DDC::PP::CQFilter;
use DDC::PP::CQueryOptions;

##----------------------------------------
## API: Hints

## undef = $yyqparser->hint($hint_code,$curtok,$curval)
##
sub show_hint {
  $_[0]->{USER}{'hint'} = $_[1];
  $_[0]->YYCurtok($_[2]);
  $_[0]->YYCurval($_[3]);
  $_[0]->YYError;
}



sub new {
        my($class)=shift;
        ref($class)
    and $class=ref($class);

    my($self)=$class->SUPER::new( yyversion => '1.05',
                                  yystates =>
[
	{#State 0
		ACTIONS => {
			'STAR_LBRACE' => 34,
			'INTEGER' => 55,
			'AT_LBRACE' => 32,
			'PREFIX' => 31,
			"\"" => 13,
			'DATE' => 53,
			"{" => 52,
			'INDEX' => 28,
			'COLON_LBRACE' => 51,
			'NEAR' => 49,
			'INFIX' => 5,
			"%" => 6,
			'KEYS' => 39,
			"\@" => 4,
			"(" => 36,
			'COUNT' => 57,
			"[" => 22,
			'NEG_REGEX' => 65,
			"<" => 64,
			"!" => 19,
			'DOLLAR_DOT' => 63,
			"*" => 8,
			'REGEX' => 69,
			'SUFFIX' => 26,
			"^" => 25,
			'SYMBOL' => 68,
			"\$" => 24
		},
		GOTOS => {
			'qw_without' => 45,
			'qw_suffix' => 10,
			's_word' => 46,
			's_index' => 47,
			'qc_word' => 40,
			'regex' => 41,
			'qw_set_infl' => 42,
			'qc_tokens' => 43,
			'qc_near' => 9,
			'qw_prefix_set' => 44,
			'qw_chunk' => 35,
			'qw_set_exact' => 2,
			'qc_boolean' => 3,
			'index' => 37,
			'qc_matchid' => 38,
			's_suffix' => 7,
			'qw_bareword' => 1,
			'qw_thesaurus' => 29,
			'qw_listfile' => 30,
			'query' => 33,
			'qw_morph' => 23,
			'qw_keys' => 70,
			'neg_regex' => 71,
			'count_query' => 72,
			'qw_any' => 27,
			'qw_prefix' => 17,
			'symbol' => 62,
			'qw_infix_set' => 18,
			'qwk_indextuple' => 20,
			'qw_suffix_set' => 21,
			'qc_concat' => 67,
			'qw_with' => 66,
			'qw_regex' => 56,
			'qw_matchid' => 16,
			'qw_exact' => 58,
			'query_conditions' => 59,
			's_prefix' => 61,
			'q_clause' => 60,
			'qc_basic' => 48,
			'qc_phrase' => 50,
			's_infix' => 11,
			'qw_lemma' => 12,
			'qw_anchor' => 54,
			'qw_withor' => 15,
			'qw_infix' => 14
		}
	},
	{#State 1
		DEFAULT => -141
	},
	{#State 2
		DEFAULT => -146
	},
	{#State 3
		DEFAULT => -118
	},
	{#State 4
		ACTIONS => {
			'SYMBOL' => 68,
			'INTEGER' => 55,
			'DATE' => 53
		},
		GOTOS => {
			'symbol' => 62,
			's_word' => 73
		}
	},
	{#State 5
		DEFAULT => -271
	},
	{#State 6
		ACTIONS => {
			'INTEGER' => 55,
			'DATE' => 53,
			'SYMBOL' => 68
		},
		GOTOS => {
			'symbol' => 74,
			's_lemma' => 75
		}
	},
	{#State 7
		DEFAULT => -181
	},
	{#State 8
		DEFAULT => -173
	},
	{#State 9
		ACTIONS => {
			"=" => 78
		},
		DEFAULT => -131,
		GOTOS => {
			'matchid' => 76,
			'matchid_eq' => 77
		}
	},
	{#State 10
		DEFAULT => -151
	},
	{#State 11
		DEFAULT => -183
	},
	{#State 12
		DEFAULT => -155
	},
	{#State 13
		ACTIONS => {
			"{" => 52,
			'INDEX' => 28,
			'COLON_LBRACE' => 51,
			'INTEGER' => 55,
			'STAR_LBRACE' => 34,
			'DATE' => 53,
			'AT_LBRACE' => 32,
			'PREFIX' => 31,
			'KEYS' => 39,
			"%" => 6,
			'INFIX' => 5,
			"(" => 79,
			"\@" => 4,
			'DOLLAR_DOT' => 63,
			"*" => 8,
			'NEG_REGEX' => 65,
			"[" => 22,
			"<" => 64,
			'SUFFIX' => 26,
			'REGEX' => 69,
			'SYMBOL' => 68,
			"\$" => 24,
			"^" => 25
		},
		GOTOS => {
			'qw_anchor' => 54,
			'qw_infix' => 14,
			'qw_withor' => 15,
			's_infix' => 11,
			'qw_lemma' => 12,
			's_prefix' => 61,
			'qw_regex' => 56,
			'qw_exact' => 58,
			'qw_matchid' => 16,
			'qwk_indextuple' => 20,
			'qw_with' => 66,
			'qw_suffix_set' => 21,
			'symbol' => 62,
			'qw_prefix' => 17,
			'qw_infix_set' => 18,
			'neg_regex' => 71,
			'qw_keys' => 70,
			'qw_any' => 27,
			'qw_morph' => 23,
			'qw_listfile' => 30,
			'l_phrase' => 81,
			'qw_bareword' => 1,
			'qw_thesaurus' => 29,
			'index' => 37,
			's_suffix' => 7,
			'qw_chunk' => 35,
			'qw_set_exact' => 2,
			'qw_set_infl' => 42,
			'qw_prefix_set' => 44,
			'regex' => 41,
			'qc_word' => 80,
			's_index' => 47,
			'qw_suffix' => 10,
			'qw_without' => 45,
			's_word' => 46
		}
	},
	{#State 14
		DEFAULT => -147
	},
	{#State 15
		DEFAULT => -161
	},
	{#State 16
		DEFAULT => -163
	},
	{#State 17
		DEFAULT => -149
	},
	{#State 18
		DEFAULT => -148
	},
	{#State 19
		ACTIONS => {
			'STAR_LBRACE' => 34,
			'INTEGER' => 55,
			'PREFIX' => 31,
			"\"" => 13,
			'AT_LBRACE' => 32,
			'DATE' => 53,
			'INDEX' => 28,
			"{" => 52,
			'COLON_LBRACE' => 51,
			'NEAR' => 49,
			'INFIX' => 5,
			"%" => 6,
			'KEYS' => 39,
			"\@" => 4,
			"(" => 36,
			"[" => 22,
			'NEG_REGEX' => 65,
			"<" => 64,
			"!" => 19,
			"*" => 8,
			'DOLLAR_DOT' => 63,
			'REGEX' => 69,
			'SUFFIX' => 26,
			"^" => 25,
			"\$" => 24,
			'SYMBOL' => 68
		},
		GOTOS => {
			'qw_lemma' => 12,
			'qc_basic' => 48,
			'qc_phrase' => 50,
			's_infix' => 11,
			'qw_withor' => 15,
			'qw_infix' => 14,
			'qw_anchor' => 54,
			'qw_matchid' => 16,
			'qw_exact' => 58,
			'qw_regex' => 56,
			'q_clause' => 82,
			's_prefix' => 61,
			'qw_infix_set' => 18,
			'qw_prefix' => 17,
			'symbol' => 62,
			'qw_suffix_set' => 21,
			'qw_with' => 66,
			'qc_concat' => 67,
			'qwk_indextuple' => 20,
			'qw_morph' => 23,
			'qw_any' => 27,
			'neg_regex' => 71,
			'qw_keys' => 70,
			'qw_thesaurus' => 29,
			'qw_bareword' => 1,
			'qw_listfile' => 30,
			'qw_set_exact' => 2,
			'qw_chunk' => 35,
			's_suffix' => 7,
			'qc_boolean' => 3,
			'index' => 37,
			'qc_matchid' => 38,
			'qc_word' => 40,
			'regex' => 41,
			'qc_near' => 9,
			'qw_prefix_set' => 44,
			'qw_set_infl' => 42,
			'qc_tokens' => 43,
			's_word' => 46,
			'qw_without' => 45,
			'qw_suffix' => 10,
			's_index' => 47
		}
	},
	{#State 20
		ACTIONS => {
			"=" => 83
		}
	},
	{#State 21
		DEFAULT => -152
	},
	{#State 22
		DEFAULT => -215,
		GOTOS => {
			'l_morph' => 84
		}
	},
	{#State 23
		DEFAULT => -154
	},
	{#State 24
		ACTIONS => {
			"(" => 85
		},
		DEFAULT => -249
	},
	{#State 25
		ACTIONS => {
			'DATE' => 53,
			'INTEGER' => 55,
			'SYMBOL' => 68
		},
		GOTOS => {
			'symbol' => 87,
			's_chunk' => 86
		}
	},
	{#State 26
		DEFAULT => -270
	},
	{#State 27
		DEFAULT => -144
	},
	{#State 28
		DEFAULT => -267
	},
	{#State 29
		DEFAULT => -153
	},
	{#State 30
		DEFAULT => -158
	},
	{#State 31
		DEFAULT => -269
	},
	{#State 32
		DEFAULT => -212,
		GOTOS => {
			'l_set' => 88
		}
	},
	{#State 33
		ACTIONS => {
			'' => 89
		}
	},
	{#State 34
		DEFAULT => -212,
		GOTOS => {
			'l_set' => 90
		}
	},
	{#State 35
		DEFAULT => -156
	},
	{#State 36
		ACTIONS => {
			'INTEGER' => 55,
			'STAR_LBRACE' => 34,
			'DATE' => 53,
			'PREFIX' => 31,
			"\"" => 13,
			'AT_LBRACE' => 32,
			"{" => 52,
			'INDEX' => 28,
			'COLON_LBRACE' => 51,
			'NEAR' => 49,
			'KEYS' => 39,
			"%" => 6,
			'INFIX' => 5,
			"(" => 36,
			"\@" => 4,
			'NEG_REGEX' => 65,
			"[" => 22,
			"!" => 19,
			"<" => 64,
			'DOLLAR_DOT' => 63,
			"*" => 8,
			'SUFFIX' => 26,
			'REGEX' => 69,
			'SYMBOL' => 68,
			"\$" => 24,
			"^" => 25
		},
		GOTOS => {
			'qw_morph' => 23,
			'neg_regex' => 71,
			'qw_keys' => 70,
			'qw_any' => 27,
			'symbol' => 62,
			'qw_prefix' => 17,
			'qw_infix_set' => 18,
			'qwk_indextuple' => 20,
			'qc_concat' => 95,
			'qw_with' => 66,
			'qw_suffix_set' => 21,
			'qw_regex' => 56,
			'qw_exact' => 58,
			'qw_matchid' => 16,
			's_prefix' => 61,
			'q_clause' => 94,
			'qc_phrase' => 93,
			's_infix' => 11,
			'qc_basic' => 48,
			'qw_lemma' => 12,
			'qw_anchor' => 54,
			'qw_withor' => 15,
			'qw_infix' => 14,
			'qw_suffix' => 10,
			'qw_without' => 45,
			's_word' => 46,
			's_index' => 47,
			'regex' => 41,
			'qc_word' => 92,
			'qc_tokens' => 43,
			'qw_set_infl' => 42,
			'qc_near' => 97,
			'qw_prefix_set' => 44,
			'qw_chunk' => 35,
			'qw_set_exact' => 2,
			'qc_matchid' => 91,
			'index' => 37,
			'qc_boolean' => 96,
			's_suffix' => 7,
			'qw_bareword' => 1,
			'qw_thesaurus' => 29,
			'qw_listfile' => 30
		}
	},
	{#State 37
		DEFAULT => -250
	},
	{#State 38
		DEFAULT => -120
	},
	{#State 39
		ACTIONS => {
			"(" => 98
		}
	},
	{#State 40
		ACTIONS => {
			"=" => 78,
			'WITH' => 101,
			'WITHOUT' => 102,
			'WITHOR' => 100
		},
		DEFAULT => -136,
		GOTOS => {
			'matchid' => 99,
			'matchid_eq' => 77
		}
	},
	{#State 41
		DEFAULT => -169
	},
	{#State 42
		DEFAULT => -145
	},
	{#State 43
		ACTIONS => {
			"=" => 78
		},
		DEFAULT => -130,
		GOTOS => {
			'matchid' => 103,
			'matchid_eq' => 77
		}
	},
	{#State 44
		DEFAULT => -150
	},
	{#State 45
		DEFAULT => -160
	},
	{#State 46
		DEFAULT => -225,
		GOTOS => {
			'l_txchain' => 104
		}
	},
	{#State 47
		ACTIONS => {
			"=" => 105
		}
	},
	{#State 48
		ACTIONS => {
			'DOLLAR_DOT' => 63,
			'NEG_REGEX' => 65,
			"<" => 64,
			'REGEX' => 69,
			'SYMBOL' => 68,
			"{" => 52,
			'COLON_LBRACE' => 51,
			'NEAR' => 49,
			'INTEGER' => 55,
			'DATE' => 53,
			'INDEX' => 28,
			'STAR_LBRACE' => 34,
			'PREFIX' => 31,
			'AT_LBRACE' => 32,
			'KEYS' => 39,
			"(" => 107,
			"[" => 22,
			'SUFFIX' => 26,
			"\$" => 24,
			"^" => 25,
			"\"" => 13,
			"*" => 8,
			'INFIX' => 5,
			"%" => 6,
			"\@" => 4
		},
		DEFAULT => -117,
		GOTOS => {
			's_index' => 47,
			'qw_suffix' => 10,
			'qw_without' => 45,
			's_word' => 46,
			'qw_set_infl' => 42,
			'qc_tokens' => 43,
			'qc_near' => 9,
			'qw_prefix_set' => 44,
			'regex' => 41,
			'qc_word' => 40,
			'index' => 37,
			's_suffix' => 7,
			'qw_chunk' => 35,
			'qw_set_exact' => 2,
			'qw_listfile' => 30,
			'qw_bareword' => 1,
			'qw_thesaurus' => 29,
			'qw_keys' => 70,
			'neg_regex' => 71,
			'qw_any' => 27,
			'qw_morph' => 23,
			'qwk_indextuple' => 20,
			'qw_with' => 66,
			'qw_suffix_set' => 21,
			'symbol' => 62,
			'qw_prefix' => 17,
			'qw_infix_set' => 18,
			's_prefix' => 61,
			'qw_regex' => 56,
			'qw_exact' => 58,
			'qw_matchid' => 16,
			'qw_anchor' => 54,
			'qw_infix' => 14,
			'qw_withor' => 15,
			's_infix' => 11,
			'qc_phrase' => 50,
			'qc_basic' => 106,
			'qw_lemma' => 12
		}
	},
	{#State 49
		ACTIONS => {
			"(" => 108
		}
	},
	{#State 50
		DEFAULT => -137
	},
	{#State 51
		ACTIONS => {
			'SYMBOL' => 68,
			'INTEGER' => 55,
			'DATE' => 53
		},
		GOTOS => {
			'symbol' => 109,
			's_semclass' => 110
		}
	},
	{#State 52
		DEFAULT => -212,
		GOTOS => {
			'l_set' => 111
		}
	},
	{#State 53
		DEFAULT => -265
	},
	{#State 54
		DEFAULT => -157
	},
	{#State 55
		DEFAULT => -264
	},
	{#State 56
		DEFAULT => -143
	},
	{#State 57
		ACTIONS => {
			"(" => 112
		}
	},
	{#State 58
		DEFAULT => -142
	},
	{#State 59
		DEFAULT => -1
	},
	{#State 60
		ACTIONS => {
			'OP_BOOL_AND' => 115,
			"=" => 78,
			'OP_BOOL_OR' => 116
		},
		DEFAULT => -30,
		GOTOS => {
			'matchid_eq' => 77,
			'matchid' => 113,
			'q_filters' => 114
		}
	},
	{#State 61
		DEFAULT => -179
	},
	{#State 62
		DEFAULT => -253
	},
	{#State 63
		ACTIONS => {
			"=" => 117,
			'SYMBOL' => 68,
			'INTEGER' => 55,
			'DATE' => 53
		},
		GOTOS => {
			'symbol' => 118
		}
	},
	{#State 64
		ACTIONS => {
			'SYMBOL' => 68,
			'INTEGER' => 55,
			'DATE' => 53
		},
		GOTOS => {
			'symbol' => 120,
			's_filename' => 119
		}
	},
	{#State 65
		ACTIONS => {
			'REGOPT' => 121
		},
		DEFAULT => -275
	},
	{#State 66
		DEFAULT => -159
	},
	{#State 67
		ACTIONS => {
			'STAR_LBRACE' => 34,
			'AT_LBRACE' => 32,
			'PREFIX' => 31,
			'INDEX' => 28,
			'KEYS' => 39,
			"(" => 107,
			'NEG_REGEX' => 65,
			"<" => 64,
			'DOLLAR_DOT' => 63,
			'REGEX' => 69,
			'SYMBOL' => 68,
			'INTEGER' => 55,
			'DATE' => 53,
			"{" => 52,
			'COLON_LBRACE' => 51,
			'NEAR' => 49,
			"*" => 8,
			"%" => 6,
			'INFIX' => 5,
			"\@" => 4,
			"[" => 22,
			'SUFFIX' => 26,
			"^" => 25,
			"\$" => 24,
			"\"" => 13
		},
		DEFAULT => -119,
		GOTOS => {
			'regex' => 41,
			'qc_word' => 40,
			'qc_tokens' => 43,
			'qw_set_infl' => 42,
			'qw_prefix_set' => 44,
			'qc_near' => 9,
			'qw_suffix' => 10,
			'qw_without' => 45,
			's_word' => 46,
			's_index' => 47,
			'qw_bareword' => 1,
			'qw_thesaurus' => 29,
			'qw_listfile' => 30,
			'qw_chunk' => 35,
			'qw_set_exact' => 2,
			'index' => 37,
			's_suffix' => 7,
			'symbol' => 62,
			'qw_prefix' => 17,
			'qw_infix_set' => 18,
			'qwk_indextuple' => 20,
			'qw_with' => 66,
			'qw_suffix_set' => 21,
			'qw_morph' => 23,
			'qw_keys' => 70,
			'neg_regex' => 71,
			'qw_any' => 27,
			's_infix' => 11,
			'qc_phrase' => 50,
			'qc_basic' => 122,
			'qw_lemma' => 12,
			'qw_anchor' => 54,
			'qw_withor' => 15,
			'qw_infix' => 14,
			'qw_regex' => 56,
			'qw_exact' => 58,
			'qw_matchid' => 16,
			's_prefix' => 61
		}
	},
	{#State 68
		DEFAULT => -263
	},
	{#State 69
		ACTIONS => {
			'REGOPT' => 123
		},
		DEFAULT => -273
	},
	{#State 70
		DEFAULT => -162
	},
	{#State 71
		DEFAULT => -171
	},
	{#State 72
		DEFAULT => -2
	},
	{#State 73
		DEFAULT => -167
	},
	{#State 74
		DEFAULT => -255
	},
	{#State 75
		DEFAULT => -195
	},
	{#State 76
		DEFAULT => -134
	},
	{#State 77
		ACTIONS => {
			'INTEGER' => 124
		},
		GOTOS => {
			'int_str' => 125,
			'integer' => 126
		}
	},
	{#State 78
		DEFAULT => -284
	},
	{#State 79
		ACTIONS => {
			'PREFIX' => 31,
			'AT_LBRACE' => 32,
			'DATE' => 53,
			'STAR_LBRACE' => 34,
			'INTEGER' => 55,
			'INDEX' => 28,
			"{" => 52,
			'COLON_LBRACE' => 51,
			"\@" => 4,
			"(" => 79,
			"%" => 6,
			'INFIX' => 5,
			'KEYS' => 39,
			"<" => 64,
			"[" => 22,
			'NEG_REGEX' => 65,
			'DOLLAR_DOT' => 63,
			"*" => 8,
			"^" => 25,
			"\$" => 24,
			'SYMBOL' => 68,
			'REGEX' => 69,
			'SUFFIX' => 26
		},
		GOTOS => {
			'qw_infix_set' => 18,
			'qw_prefix' => 17,
			'symbol' => 62,
			'qw_suffix_set' => 21,
			'qw_with' => 66,
			'qwk_indextuple' => 20,
			'qw_morph' => 23,
			'qw_any' => 27,
			'neg_regex' => 71,
			'qw_keys' => 70,
			'qw_lemma' => 12,
			's_infix' => 11,
			'qw_infix' => 14,
			'qw_withor' => 15,
			'qw_anchor' => 54,
			'qw_matchid' => 16,
			'qw_exact' => 58,
			'qw_regex' => 56,
			's_prefix' => 61,
			'qc_word' => 127,
			'regex' => 41,
			'qw_prefix_set' => 44,
			'qw_set_infl' => 42,
			's_word' => 46,
			'qw_without' => 45,
			'qw_suffix' => 10,
			's_index' => 47,
			'qw_thesaurus' => 29,
			'qw_bareword' => 1,
			'qw_listfile' => 30,
			'qw_set_exact' => 2,
			'qw_chunk' => 35,
			's_suffix' => 7,
			'index' => 37
		}
	},
	{#State 80
		ACTIONS => {
			'WITH' => 101,
			'WITHOR' => 100,
			'WITHOUT' => 102,
			"=" => 78
		},
		DEFAULT => -219,
		GOTOS => {
			'matchid' => 99,
			'matchid_eq' => 77
		}
	},
	{#State 81
		ACTIONS => {
			"\@" => 4,
			"(" => 79,
			'INFIX' => 5,
			"%" => 6,
			'KEYS' => 39,
			"#" => 130,
			"\"" => 128,
			'AT_LBRACE' => 32,
			'PREFIX' => 31,
			'DATE' => 53,
			'STAR_LBRACE' => 34,
			'INTEGER' => 55,
			'INDEX' => 28,
			'COLON_LBRACE' => 51,
			"{" => 52,
			"^" => 25,
			'SYMBOL' => 68,
			"\$" => 24,
			'REGEX' => 69,
			'SUFFIX' => 26,
			"<" => 64,
			"[" => 22,
			'NEG_REGEX' => 65,
			'HASH_LESS' => 129,
			'HASH_EQUAL' => 131,
			'HASH_GREATER' => 132,
			"*" => 8,
			'DOLLAR_DOT' => 63
		},
		GOTOS => {
			'index' => 37,
			's_suffix' => 7,
			'qw_chunk' => 35,
			'qw_set_exact' => 2,
			'qw_listfile' => 30,
			'qw_bareword' => 1,
			'qw_thesaurus' => 29,
			's_index' => 47,
			'qw_suffix' => 10,
			'qw_without' => 45,
			's_word' => 46,
			'qw_set_infl' => 42,
			'qw_prefix_set' => 44,
			'regex' => 41,
			'qc_word' => 133,
			's_prefix' => 61,
			'qw_regex' => 56,
			'qw_exact' => 58,
			'qw_matchid' => 16,
			'qw_anchor' => 54,
			'qw_withor' => 15,
			'qw_infix' => 14,
			's_infix' => 11,
			'qw_lemma' => 12,
			'qw_keys' => 70,
			'neg_regex' => 71,
			'qw_any' => 27,
			'qw_morph' => 23,
			'qwk_indextuple' => 20,
			'qw_with' => 66,
			'qw_suffix_set' => 21,
			'symbol' => 62,
			'qw_prefix' => 17,
			'qw_infix_set' => 18
		}
	},
	{#State 82
		ACTIONS => {
			"=" => 78
		},
		DEFAULT => -125,
		GOTOS => {
			'matchid_eq' => 77,
			'matchid' => 113
		}
	},
	{#State 83
		ACTIONS => {
			'KEYS' => 134
		}
	},
	{#State 84
		ACTIONS => {
			'INTEGER' => 55,
			"," => 137,
			"]" => 139,
			'DATE' => 53,
			'SYMBOL' => 68,
			";" => 136
		},
		GOTOS => {
			'symbol' => 138,
			's_morphitem' => 135
		}
	},
	{#State 85
		ACTIONS => {
			'SYMBOL' => 68,
			"\$" => 140,
			'DATE' => 53,
			'INTEGER' => 55,
			'INDEX' => 28
		},
		DEFAULT => -230,
		GOTOS => {
			'l_indextuple' => 142,
			's_indextuple_item' => 141,
			's_index' => 144,
			'index' => 37,
			'symbol' => 143
		}
	},
	{#State 86
		DEFAULT => -197
	},
	{#State 87
		DEFAULT => -256
	},
	{#State 88
		ACTIONS => {
			"}" => 145,
			"," => 147,
			'INTEGER' => 55,
			'DATE' => 53,
			'SYMBOL' => 68
		},
		GOTOS => {
			's_word' => 146,
			'symbol' => 62
		}
	},
	{#State 89
		DEFAULT => 0
	},
	{#State 90
		ACTIONS => {
			'SYMBOL' => 68,
			'DATE' => 53,
			"," => 147,
			'INTEGER' => 55,
			'RBRACE_STAR' => 148,
			"}" => 149
		},
		GOTOS => {
			's_word' => 146,
			'symbol' => 62
		}
	},
	{#State 91
		ACTIONS => {
			")" => 150
		},
		DEFAULT => -120
	},
	{#State 92
		ACTIONS => {
			'WITH' => 101,
			'WITHOR' => 100,
			'WITHOUT' => 102,
			"=" => 78,
			")" => 151
		},
		DEFAULT => -136,
		GOTOS => {
			'matchid_eq' => 77,
			'matchid' => 99
		}
	},
	{#State 93
		ACTIONS => {
			")" => 152
		},
		DEFAULT => -137
	},
	{#State 94
		ACTIONS => {
			'OP_BOOL_AND' => 115,
			"=" => 78,
			'OP_BOOL_OR' => 116
		},
		GOTOS => {
			'matchid' => 113,
			'matchid_eq' => 77
		}
	},
	{#State 95
		ACTIONS => {
			'DOLLAR_DOT' => 63,
			"*" => 8,
			"[" => 22,
			'NEG_REGEX' => 65,
			"<" => 64,
			'REGEX' => 69,
			'SUFFIX' => 26,
			"^" => 25,
			'SYMBOL' => 68,
			"\$" => 24,
			")" => 153,
			'INDEX' => 28,
			'COLON_LBRACE' => 51,
			"{" => 52,
			'NEAR' => 49,
			'STAR_LBRACE' => 34,
			'INTEGER' => 55,
			'AT_LBRACE' => 32,
			"\"" => 13,
			'PREFIX' => 31,
			'DATE' => 53,
			"%" => 6,
			'INFIX' => 5,
			'KEYS' => 39,
			"\@" => 4,
			"(" => 107
		},
		DEFAULT => -119,
		GOTOS => {
			'qw_matchid' => 16,
			'qw_exact' => 58,
			'qw_regex' => 56,
			's_prefix' => 61,
			'qw_lemma' => 12,
			'qc_basic' => 122,
			's_infix' => 11,
			'qc_phrase' => 50,
			'qw_withor' => 15,
			'qw_infix' => 14,
			'qw_anchor' => 54,
			'qw_morph' => 23,
			'qw_any' => 27,
			'qw_keys' => 70,
			'neg_regex' => 71,
			'qw_infix_set' => 18,
			'qw_prefix' => 17,
			'symbol' => 62,
			'qw_suffix_set' => 21,
			'qw_with' => 66,
			'qwk_indextuple' => 20,
			'qw_set_exact' => 2,
			'qw_chunk' => 35,
			's_suffix' => 7,
			'index' => 37,
			'qw_thesaurus' => 29,
			'qw_bareword' => 1,
			'qw_listfile' => 30,
			's_word' => 46,
			'qw_without' => 45,
			'qw_suffix' => 10,
			's_index' => 47,
			'qc_word' => 40,
			'regex' => 41,
			'qw_prefix_set' => 44,
			'qc_near' => 9,
			'qc_tokens' => 43,
			'qw_set_infl' => 42
		}
	},
	{#State 96
		ACTIONS => {
			")" => 154
		},
		DEFAULT => -118
	},
	{#State 97
		ACTIONS => {
			"=" => 78,
			")" => 155
		},
		DEFAULT => -131,
		GOTOS => {
			'matchid_eq' => 77,
			'matchid' => 76
		}
	},
	{#State 98
		ACTIONS => {
			"*" => 8,
			'DOLLAR_DOT' => 63,
			"<" => 64,
			"!" => 19,
			"[" => 22,
			'NEG_REGEX' => 65,
			"^" => 25,
			'SYMBOL' => 68,
			"\$" => 24,
			'REGEX' => 69,
			'SUFFIX' => 26,
			'NEAR' => 49,
			'INDEX' => 28,
			'COLON_LBRACE' => 51,
			"{" => 52,
			"\"" => 13,
			'AT_LBRACE' => 32,
			'PREFIX' => 31,
			'DATE' => 53,
			'STAR_LBRACE' => 34,
			'INTEGER' => 55,
			'COUNT' => 57,
			"\@" => 4,
			"(" => 36,
			'INFIX' => 5,
			"%" => 6,
			'KEYS' => 39
		},
		GOTOS => {
			'query_conditions' => 157,
			's_prefix' => 61,
			'q_clause' => 60,
			'qw_matchid' => 16,
			'qw_exact' => 58,
			'qw_regex' => 56,
			'qw_infix' => 14,
			'qw_withor' => 15,
			'qw_anchor' => 54,
			'qw_lemma' => 12,
			'qc_basic' => 48,
			's_infix' => 11,
			'qc_phrase' => 50,
			'qw_any' => 27,
			'neg_regex' => 71,
			'qw_keys' => 70,
			'count_query' => 158,
			'qw_morph' => 23,
			'qw_suffix_set' => 21,
			'qc_concat' => 67,
			'qw_with' => 66,
			'qwk_indextuple' => 20,
			'qw_infix_set' => 18,
			'qw_prefix' => 17,
			'symbol' => 62,
			's_suffix' => 7,
			'qc_boolean' => 3,
			'index' => 37,
			'qc_matchid' => 38,
			'qw_set_exact' => 2,
			'qw_chunk' => 35,
			'qw_listfile' => 30,
			'qw_thesaurus' => 29,
			'qw_bareword' => 1,
			's_index' => 47,
			's_word' => 46,
			'qw_without' => 45,
			'qw_suffix' => 10,
			'qw_prefix_set' => 44,
			'qc_near' => 9,
			'qw_set_infl' => 42,
			'qwk_countsrc' => 156,
			'qc_tokens' => 43,
			'qc_word' => 40,
			'regex' => 41
		}
	},
	{#State 99
		DEFAULT => -211
	},
	{#State 100
		ACTIONS => {
			"%" => 6,
			'INFIX' => 5,
			'KEYS' => 39,
			"\@" => 4,
			"(" => 79,
			"{" => 52,
			'COLON_LBRACE' => 51,
			'INDEX' => 28,
			'STAR_LBRACE' => 34,
			'INTEGER' => 55,
			'PREFIX' => 31,
			'AT_LBRACE' => 32,
			'DATE' => 53,
			'REGEX' => 69,
			'SUFFIX' => 26,
			"^" => 25,
			'SYMBOL' => 68,
			"\$" => 24,
			'DOLLAR_DOT' => 63,
			"*" => 8,
			"[" => 22,
			'NEG_REGEX' => 65,
			"<" => 64
		},
		GOTOS => {
			'qw_with' => 66,
			'qw_suffix_set' => 21,
			'qwk_indextuple' => 20,
			'qw_infix_set' => 18,
			'symbol' => 62,
			'qw_prefix' => 17,
			'qw_any' => 27,
			'neg_regex' => 71,
			'qw_keys' => 70,
			'qw_morph' => 23,
			'qw_withor' => 15,
			'qw_infix' => 14,
			'qw_anchor' => 54,
			'qw_lemma' => 12,
			's_infix' => 11,
			's_prefix' => 61,
			'qw_exact' => 58,
			'qw_matchid' => 16,
			'qw_regex' => 56,
			'qw_prefix_set' => 44,
			'qw_set_infl' => 42,
			'regex' => 41,
			'qc_word' => 159,
			's_index' => 47,
			's_word' => 46,
			'qw_suffix' => 10,
			'qw_without' => 45,
			'qw_listfile' => 30,
			'qw_thesaurus' => 29,
			'qw_bareword' => 1,
			's_suffix' => 7,
			'index' => 37,
			'qw_set_exact' => 2,
			'qw_chunk' => 35
		}
	},
	{#State 101
		ACTIONS => {
			'SUFFIX' => 26,
			'REGEX' => 69,
			'SYMBOL' => 68,
			"\$" => 24,
			"^" => 25,
			'NEG_REGEX' => 65,
			"[" => 22,
			"<" => 64,
			'DOLLAR_DOT' => 63,
			"*" => 8,
			'KEYS' => 39,
			"%" => 6,
			'INFIX' => 5,
			"(" => 79,
			"\@" => 4,
			'INTEGER' => 55,
			'STAR_LBRACE' => 34,
			'DATE' => 53,
			'PREFIX' => 31,
			'AT_LBRACE' => 32,
			'COLON_LBRACE' => 51,
			"{" => 52,
			'INDEX' => 28
		},
		GOTOS => {
			'regex' => 41,
			'qc_word' => 160,
			'qw_prefix_set' => 44,
			'qw_set_infl' => 42,
			's_word' => 46,
			'qw_suffix' => 10,
			'qw_without' => 45,
			's_index' => 47,
			'qw_thesaurus' => 29,
			'qw_bareword' => 1,
			'qw_listfile' => 30,
			'qw_set_exact' => 2,
			'qw_chunk' => 35,
			's_suffix' => 7,
			'index' => 37,
			'qw_infix_set' => 18,
			'symbol' => 62,
			'qw_prefix' => 17,
			'qw_with' => 66,
			'qw_suffix_set' => 21,
			'qwk_indextuple' => 20,
			'qw_morph' => 23,
			'qw_any' => 27,
			'qw_keys' => 70,
			'neg_regex' => 71,
			'qw_lemma' => 12,
			's_infix' => 11,
			'qw_withor' => 15,
			'qw_infix' => 14,
			'qw_anchor' => 54,
			'qw_exact' => 58,
			'qw_matchid' => 16,
			'qw_regex' => 56,
			's_prefix' => 61
		}
	},
	{#State 102
		ACTIONS => {
			"*" => 8,
			'DOLLAR_DOT' => 63,
			'NEG_REGEX' => 65,
			"[" => 22,
			"<" => 64,
			'SUFFIX' => 26,
			'REGEX' => 69,
			'SYMBOL' => 68,
			"\$" => 24,
			"^" => 25,
			'INDEX' => 28,
			"{" => 52,
			'COLON_LBRACE' => 51,
			'INTEGER' => 55,
			'STAR_LBRACE' => 34,
			'DATE' => 53,
			'PREFIX' => 31,
			'AT_LBRACE' => 32,
			'KEYS' => 39,
			"%" => 6,
			'INFIX' => 5,
			"(" => 79,
			"\@" => 4
		},
		GOTOS => {
			'qw_morph' => 23,
			'qw_keys' => 70,
			'neg_regex' => 71,
			'qw_any' => 27,
			'qw_prefix' => 17,
			'symbol' => 62,
			'qw_infix_set' => 18,
			'qwk_indextuple' => 20,
			'qw_suffix_set' => 21,
			'qw_with' => 66,
			'qw_regex' => 56,
			'qw_matchid' => 16,
			'qw_exact' => 58,
			's_prefix' => 61,
			's_infix' => 11,
			'qw_lemma' => 12,
			'qw_anchor' => 54,
			'qw_withor' => 15,
			'qw_infix' => 14,
			'qw_without' => 45,
			'qw_suffix' => 10,
			's_word' => 46,
			's_index' => 47,
			'qc_word' => 161,
			'regex' => 41,
			'qw_set_infl' => 42,
			'qw_prefix_set' => 44,
			'qw_chunk' => 35,
			'qw_set_exact' => 2,
			'index' => 37,
			's_suffix' => 7,
			'qw_bareword' => 1,
			'qw_thesaurus' => 29,
			'qw_listfile' => 30
		}
	},
	{#State 103
		DEFAULT => -138
	},
	{#State 104
		ACTIONS => {
			'EXPANDER' => 162
		},
		DEFAULT => -165,
		GOTOS => {
			's_expander' => 163
		}
	},
	{#State 105
		ACTIONS => {
			'SUFFIX' => 26,
			'REGEX' => 69,
			'SYMBOL' => 68,
			"^" => 165,
			"*" => 167,
			":" => 172,
			'NEG_REGEX' => 65,
			"[" => 164,
			"<" => 171,
			"%" => 169,
			'INFIX' => 5,
			"\@" => 170,
			"{" => 174,
			'INTEGER' => 55,
			'STAR_LBRACE' => 178,
			'DATE' => 53,
			'PREFIX' => 31,
			'AT_LBRACE' => 179
		},
		GOTOS => {
			's_suffix' => 168,
			's_prefix' => 175,
			'neg_regex' => 173,
			's_word' => 177,
			'regex' => 176,
			's_infix' => 166,
			'symbol' => 62
		}
	},
	{#State 106
		DEFAULT => -127
	},
	{#State 107
		ACTIONS => {
			"^" => 25,
			"\$" => 24,
			'SYMBOL' => 68,
			'REGEX' => 69,
			'SUFFIX' => 26,
			"<" => 64,
			"[" => 22,
			'NEG_REGEX' => 65,
			"*" => 8,
			'DOLLAR_DOT' => 63,
			"\@" => 4,
			"(" => 107,
			"%" => 6,
			'INFIX' => 5,
			'KEYS' => 39,
			"\"" => 13,
			'AT_LBRACE' => 32,
			'PREFIX' => 31,
			'DATE' => 53,
			'STAR_LBRACE' => 34,
			'INTEGER' => 55,
			'NEAR' => 49,
			"{" => 52,
			'INDEX' => 28,
			'COLON_LBRACE' => 51
		},
		GOTOS => {
			'qw_suffix_set' => 21,
			'qw_with' => 66,
			'qwk_indextuple' => 20,
			'qw_infix_set' => 18,
			'qw_prefix' => 17,
			'symbol' => 62,
			'qw_any' => 27,
			'neg_regex' => 71,
			'qw_keys' => 70,
			'qw_morph' => 23,
			'qw_withor' => 15,
			'qw_infix' => 14,
			'qw_anchor' => 54,
			'qw_lemma' => 12,
			'qc_phrase' => 181,
			's_infix' => 11,
			's_prefix' => 61,
			'qw_matchid' => 16,
			'qw_exact' => 58,
			'qw_regex' => 56,
			'qw_prefix_set' => 44,
			'qc_near' => 180,
			'qw_set_infl' => 42,
			'qc_word' => 127,
			'regex' => 41,
			's_index' => 47,
			's_word' => 46,
			'qw_without' => 45,
			'qw_suffix' => 10,
			'qw_listfile' => 30,
			'qw_thesaurus' => 29,
			'qw_bareword' => 1,
			's_suffix' => 7,
			'index' => 37,
			'qw_set_exact' => 2,
			'qw_chunk' => 35
		}
	},
	{#State 108
		ACTIONS => {
			'SYMBOL' => 68,
			"\$" => 24,
			"^" => 25,
			'SUFFIX' => 26,
			'REGEX' => 69,
			"<" => 64,
			'NEG_REGEX' => 65,
			"[" => 22,
			"*" => 8,
			'DOLLAR_DOT' => 63,
			"(" => 182,
			"\@" => 4,
			'KEYS' => 39,
			'INFIX' => 5,
			"%" => 6,
			'DATE' => 53,
			'PREFIX' => 31,
			'AT_LBRACE' => 32,
			"\"" => 13,
			'INTEGER' => 55,
			'STAR_LBRACE' => 34,
			'COLON_LBRACE' => 51,
			"{" => 52,
			'INDEX' => 28
		},
		GOTOS => {
			'qc_word' => 40,
			'regex' => 41,
			'qc_tokens' => 183,
			'qw_set_infl' => 42,
			'qw_prefix_set' => 44,
			'qw_without' => 45,
			'qw_suffix' => 10,
			's_word' => 46,
			's_index' => 47,
			'qw_bareword' => 1,
			'qw_thesaurus' => 29,
			'qw_listfile' => 30,
			'qw_chunk' => 35,
			'qw_set_exact' => 2,
			'index' => 37,
			's_suffix' => 7,
			'qw_prefix' => 17,
			'symbol' => 62,
			'qw_infix_set' => 18,
			'qwk_indextuple' => 20,
			'qw_suffix_set' => 21,
			'qw_with' => 66,
			'qw_morph' => 23,
			'qw_keys' => 70,
			'neg_regex' => 71,
			'qw_any' => 27,
			's_infix' => 11,
			'qc_phrase' => 50,
			'qw_lemma' => 12,
			'qw_anchor' => 54,
			'qw_withor' => 15,
			'qw_infix' => 14,
			'qw_regex' => 56,
			'qw_matchid' => 16,
			'qw_exact' => 58,
			's_prefix' => 61
		}
	},
	{#State 109
		DEFAULT => -254
	},
	{#State 110
		ACTIONS => {
			"}" => 184
		}
	},
	{#State 111
		ACTIONS => {
			'DATE' => 53,
			"," => 147,
			'INTEGER' => 55,
			'RBRACE_STAR' => 186,
			"}" => 185,
			'SYMBOL' => 68
		},
		GOTOS => {
			's_word' => 146,
			'symbol' => 62
		}
	},
	{#State 112
		ACTIONS => {
			"%" => 6,
			'INFIX' => 5,
			'KEYS' => 39,
			"\@" => 4,
			"(" => 36,
			'STAR_LBRACE' => 34,
			'INTEGER' => 55,
			'AT_LBRACE' => 32,
			'PREFIX' => 31,
			"\"" => 13,
			'DATE' => 53,
			'COLON_LBRACE' => 51,
			"{" => 52,
			'INDEX' => 28,
			'NEAR' => 49,
			'REGEX' => 69,
			'SUFFIX' => 26,
			"^" => 25,
			'SYMBOL' => 68,
			"\$" => 24,
			"[" => 22,
			'NEG_REGEX' => 65,
			"!" => 19,
			"<" => 64,
			'DOLLAR_DOT' => 63,
			"*" => 8
		},
		GOTOS => {
			'qw_morph' => 23,
			'qw_any' => 27,
			'qw_keys' => 70,
			'neg_regex' => 71,
			'qw_infix_set' => 18,
			'symbol' => 62,
			'qw_prefix' => 17,
			'qc_concat' => 67,
			'qw_with' => 66,
			'qw_suffix_set' => 21,
			'qwk_indextuple' => 20,
			'qw_exact' => 58,
			'qw_matchid' => 16,
			'qw_regex' => 56,
			'q_clause' => 60,
			's_prefix' => 61,
			'query_conditions' => 187,
			'qw_lemma' => 12,
			'qc_phrase' => 50,
			's_infix' => 11,
			'qc_basic' => 48,
			'qw_infix' => 14,
			'qw_withor' => 15,
			'qw_anchor' => 54,
			's_word' => 46,
			'qw_suffix' => 10,
			'qw_without' => 45,
			's_index' => 47,
			'regex' => 41,
			'qc_word' => 40,
			'qw_prefix_set' => 44,
			'qc_near' => 9,
			'qc_tokens' => 43,
			'qw_set_infl' => 42,
			'qw_set_exact' => 2,
			'qw_chunk' => 35,
			's_suffix' => 7,
			'qc_matchid' => 38,
			'index' => 37,
			'qc_boolean' => 3,
			'qw_thesaurus' => 29,
			'qw_bareword' => 1,
			'qw_listfile' => 30
		}
	},
	{#State 113
		DEFAULT => -121
	},
	{#State 114
		ACTIONS => {
			'LESS_BY' => 217,
			'GREATER_BY' => 219,
			'NOSEPARATE_HITS' => 203,
			'LESS_BY_MIDDLE' => 202,
			'LESS_BY_LEFT' => 205,
			'RANDOM' => 204,
			'GREATER_BY_MIDDLE' => 216,
			'GREATER_BY_SIZE' => 208,
			'GREATER_BY_DATE' => 224,
			'LESS_BY_SIZE' => 221,
			'WITHIN' => 220,
			'IS_DATE' => 223,
			'GREATER_BY_LEFT' => 222,
			'GREATER_BY_RIGHT' => 206,
			'IS_SIZE' => 209,
			'HAS_FIELD' => 194,
			'LESS_BY_DATE' => 188,
			'DEBUG_RANK' => 192,
			'LESS_BY_RIGHT' => 190,
			'CNTXT' => 191,
			'FILENAMES_ONLY' => 198,
			"!" => 213,
			'GREATER_BY_RANK' => 212,
			'SEPARATE_HITS' => 214,
			":" => 201,
			'KW_COMMENT' => 200,
			'LESS_BY_RANK' => 211
		},
		DEFAULT => -29,
		GOTOS => {
			'q_comment' => 189,
			'qf_rank_sort' => 215,
			'qf_date_sort' => 195,
			'q_filter' => 197,
			'qf_bibl_sort' => 196,
			'qf_context_sort' => 207,
			'qf_random_sort' => 218,
			'qf_size_sort' => 199,
			'qf_has_field' => 193,
			'q_flag' => 210
		}
	},
	{#State 115
		ACTIONS => {
			'NEG_REGEX' => 65,
			"[" => 22,
			"<" => 64,
			"!" => 19,
			"*" => 8,
			'DOLLAR_DOT' => 63,
			'SUFFIX' => 26,
			'REGEX' => 69,
			"\$" => 24,
			'SYMBOL' => 68,
			"^" => 25,
			'INTEGER' => 55,
			'STAR_LBRACE' => 34,
			'DATE' => 53,
			'AT_LBRACE' => 32,
			"\"" => 13,
			'PREFIX' => 31,
			"{" => 52,
			'COLON_LBRACE' => 51,
			'INDEX' => 28,
			'NEAR' => 49,
			'KEYS' => 39,
			"%" => 6,
			'INFIX' => 5,
			"(" => 36,
			"\@" => 4
		},
		GOTOS => {
			'regex' => 41,
			'qc_word' => 40,
			'qc_near' => 9,
			'qw_prefix_set' => 44,
			'qc_tokens' => 43,
			'qw_set_infl' => 42,
			's_word' => 46,
			'qw_suffix' => 10,
			'qw_without' => 45,
			's_index' => 47,
			'qw_thesaurus' => 29,
			'qw_bareword' => 1,
			'qw_listfile' => 30,
			'qw_set_exact' => 2,
			'qw_chunk' => 35,
			's_suffix' => 7,
			'qc_matchid' => 38,
			'index' => 37,
			'qc_boolean' => 3,
			'qw_infix_set' => 18,
			'symbol' => 62,
			'qw_prefix' => 17,
			'qc_concat' => 67,
			'qw_with' => 66,
			'qw_suffix_set' => 21,
			'qwk_indextuple' => 20,
			'qw_morph' => 23,
			'qw_any' => 27,
			'qw_keys' => 70,
			'neg_regex' => 71,
			'qw_lemma' => 12,
			'qc_phrase' => 50,
			's_infix' => 11,
			'qc_basic' => 48,
			'qw_withor' => 15,
			'qw_infix' => 14,
			'qw_anchor' => 54,
			'qw_exact' => 58,
			'qw_matchid' => 16,
			'qw_regex' => 56,
			'q_clause' => 225,
			's_prefix' => 61
		}
	},
	{#State 116
		ACTIONS => {
			'REGEX' => 69,
			'SUFFIX' => 26,
			"^" => 25,
			'SYMBOL' => 68,
			"\$" => 24,
			'DOLLAR_DOT' => 63,
			"*" => 8,
			"[" => 22,
			'NEG_REGEX' => 65,
			"!" => 19,
			"<" => 64,
			"%" => 6,
			'INFIX' => 5,
			'KEYS' => 39,
			"\@" => 4,
			"(" => 36,
			'INDEX' => 28,
			'COLON_LBRACE' => 51,
			"{" => 52,
			'NEAR' => 49,
			'STAR_LBRACE' => 34,
			'INTEGER' => 55,
			'PREFIX' => 31,
			'AT_LBRACE' => 32,
			"\"" => 13,
			'DATE' => 53
		},
		GOTOS => {
			'qw_bareword' => 1,
			'qw_thesaurus' => 29,
			'qw_listfile' => 30,
			'qw_chunk' => 35,
			'qw_set_exact' => 2,
			'qc_matchid' => 38,
			'index' => 37,
			'qc_boolean' => 3,
			's_suffix' => 7,
			'regex' => 41,
			'qc_word' => 40,
			'qc_tokens' => 43,
			'qw_set_infl' => 42,
			'qc_near' => 9,
			'qw_prefix_set' => 44,
			'qw_suffix' => 10,
			'qw_without' => 45,
			's_word' => 46,
			's_index' => 47,
			's_infix' => 11,
			'qc_phrase' => 50,
			'qc_basic' => 48,
			'qw_lemma' => 12,
			'qw_anchor' => 54,
			'qw_withor' => 15,
			'qw_infix' => 14,
			'qw_regex' => 56,
			'qw_exact' => 58,
			'qw_matchid' => 16,
			's_prefix' => 61,
			'q_clause' => 226,
			'symbol' => 62,
			'qw_prefix' => 17,
			'qw_infix_set' => 18,
			'qwk_indextuple' => 20,
			'qc_concat' => 67,
			'qw_with' => 66,
			'qw_suffix_set' => 21,
			'qw_morph' => 23,
			'neg_regex' => 71,
			'qw_keys' => 70,
			'qw_any' => 27
		}
	},
	{#State 117
		ACTIONS => {
			'INTEGER' => 124
		},
		GOTOS => {
			'int_str' => 227
		}
	},
	{#State 118
		ACTIONS => {
			"=" => 228
		}
	},
	{#State 119
		DEFAULT => -201
	},
	{#State 120
		DEFAULT => -257
	},
	{#State 121
		DEFAULT => -276
	},
	{#State 122
		DEFAULT => -128
	},
	{#State 123
		DEFAULT => -274
	},
	{#State 124
		DEFAULT => -279
	},
	{#State 125
		DEFAULT => -280
	},
	{#State 126
		DEFAULT => -283
	},
	{#State 127
		ACTIONS => {
			")" => 151,
			'WITHOUT' => 102,
			'WITH' => 101,
			'WITHOR' => 100,
			"=" => 78
		},
		GOTOS => {
			'matchid' => 99,
			'matchid_eq' => 77
		}
	},
	{#State 128
		DEFAULT => -139
	},
	{#State 129
		ACTIONS => {
			'INTEGER' => 124
		},
		GOTOS => {
			'int_str' => 125,
			'integer' => 229
		}
	},
	{#State 130
		ACTIONS => {
			'INTEGER' => 124
		},
		GOTOS => {
			'int_str' => 125,
			'integer' => 230
		}
	},
	{#State 131
		ACTIONS => {
			'INTEGER' => 124
		},
		GOTOS => {
			'int_str' => 125,
			'integer' => 231
		}
	},
	{#State 132
		ACTIONS => {
			'INTEGER' => 124
		},
		GOTOS => {
			'int_str' => 125,
			'integer' => 232
		}
	},
	{#State 133
		ACTIONS => {
			"=" => 78,
			'WITHOR' => 100,
			'WITH' => 101,
			'WITHOUT' => 102
		},
		DEFAULT => -220,
		GOTOS => {
			'matchid_eq' => 77,
			'matchid' => 99
		}
	},
	{#State 134
		ACTIONS => {
			"(" => 233
		}
	},
	{#State 135
		DEFAULT => -216
	},
	{#State 136
		DEFAULT => -218
	},
	{#State 137
		DEFAULT => -217
	},
	{#State 138
		DEFAULT => -258
	},
	{#State 139
		DEFAULT => -193
	},
	{#State 140
		DEFAULT => -249
	},
	{#State 141
		DEFAULT => -231
	},
	{#State 142
		ACTIONS => {
			")" => 235,
			"," => 234
		}
	},
	{#State 143
		DEFAULT => -252
	},
	{#State 144
		DEFAULT => -251
	},
	{#State 145
		DEFAULT => -175
	},
	{#State 146
		DEFAULT => -213
	},
	{#State 147
		DEFAULT => -214
	},
	{#State 148
		DEFAULT => -185
	},
	{#State 149
		DEFAULT => -189
	},
	{#State 150
		DEFAULT => -122
	},
	{#State 151
		DEFAULT => -164
	},
	{#State 152
		DEFAULT => -140
	},
	{#State 153
		DEFAULT => -129
	},
	{#State 154
		DEFAULT => -126
	},
	{#State 155
		DEFAULT => -135
	},
	{#State 156
		ACTIONS => {
			")" => 236
		}
	},
	{#State 157
		DEFAULT => -4,
		GOTOS => {
			'count_filters' => 237
		}
	},
	{#State 158
		DEFAULT => -209
	},
	{#State 159
		ACTIONS => {
			"=" => 78
		},
		DEFAULT => -205,
		GOTOS => {
			'matchid_eq' => 77,
			'matchid' => 99
		}
	},
	{#State 160
		ACTIONS => {
			"=" => 78
		},
		DEFAULT => -203,
		GOTOS => {
			'matchid_eq' => 77,
			'matchid' => 99
		}
	},
	{#State 161
		ACTIONS => {
			"=" => 78
		},
		DEFAULT => -204,
		GOTOS => {
			'matchid_eq' => 77,
			'matchid' => 99
		}
	},
	{#State 162
		DEFAULT => -272
	},
	{#State 163
		DEFAULT => -226
	},
	{#State 164
		DEFAULT => -215,
		GOTOS => {
			'l_morph' => 238
		}
	},
	{#State 165
		ACTIONS => {
			'DATE' => 53,
			'INTEGER' => 55,
			'SYMBOL' => 68
		},
		GOTOS => {
			's_chunk' => 239,
			'symbol' => 87
		}
	},
	{#State 166
		DEFAULT => -184
	},
	{#State 167
		DEFAULT => -174
	},
	{#State 168
		DEFAULT => -182
	},
	{#State 169
		ACTIONS => {
			'SYMBOL' => 68,
			'INTEGER' => 55,
			'DATE' => 53
		},
		GOTOS => {
			's_lemma' => 240,
			'symbol' => 74
		}
	},
	{#State 170
		ACTIONS => {
			'SYMBOL' => 68,
			'DATE' => 53,
			'INTEGER' => 55
		},
		GOTOS => {
			'symbol' => 62,
			's_word' => 241
		}
	},
	{#State 171
		ACTIONS => {
			'SYMBOL' => 68,
			'DATE' => 53,
			'INTEGER' => 55
		},
		GOTOS => {
			'symbol' => 120,
			's_filename' => 242
		}
	},
	{#State 172
		ACTIONS => {
			"{" => 243
		}
	},
	{#State 173
		DEFAULT => -172
	},
	{#State 174
		DEFAULT => -212,
		GOTOS => {
			'l_set' => 244
		}
	},
	{#State 175
		DEFAULT => -180
	},
	{#State 176
		DEFAULT => -170
	},
	{#State 177
		DEFAULT => -225,
		GOTOS => {
			'l_txchain' => 245
		}
	},
	{#State 178
		DEFAULT => -212,
		GOTOS => {
			'l_set' => 246
		}
	},
	{#State 179
		DEFAULT => -212,
		GOTOS => {
			'l_set' => 247
		}
	},
	{#State 180
		ACTIONS => {
			"=" => 78,
			")" => 155
		},
		GOTOS => {
			'matchid_eq' => 77,
			'matchid' => 76
		}
	},
	{#State 181
		ACTIONS => {
			")" => 152
		}
	},
	{#State 182
		ACTIONS => {
			"\"" => 13,
			'PREFIX' => 31,
			'AT_LBRACE' => 32,
			'DATE' => 53,
			'STAR_LBRACE' => 34,
			'INTEGER' => 55,
			'INDEX' => 28,
			"{" => 52,
			'COLON_LBRACE' => 51,
			"\@" => 4,
			"(" => 182,
			"%" => 6,
			'INFIX' => 5,
			'KEYS' => 39,
			"<" => 64,
			"[" => 22,
			'NEG_REGEX' => 65,
			"*" => 8,
			'DOLLAR_DOT' => 63,
			"^" => 25,
			'SYMBOL' => 68,
			"\$" => 24,
			'REGEX' => 69,
			'SUFFIX' => 26
		},
		GOTOS => {
			'qw_bareword' => 1,
			'qw_thesaurus' => 29,
			'qw_listfile' => 30,
			'qw_chunk' => 35,
			'qw_set_exact' => 2,
			'index' => 37,
			's_suffix' => 7,
			'qc_word' => 127,
			'regex' => 41,
			'qw_set_infl' => 42,
			'qw_prefix_set' => 44,
			'qw_without' => 45,
			'qw_suffix' => 10,
			's_word' => 46,
			's_index' => 47,
			'qc_phrase' => 181,
			's_infix' => 11,
			'qw_lemma' => 12,
			'qw_anchor' => 54,
			'qw_infix' => 14,
			'qw_withor' => 15,
			'qw_regex' => 56,
			'qw_matchid' => 16,
			'qw_exact' => 58,
			's_prefix' => 61,
			'qw_prefix' => 17,
			'symbol' => 62,
			'qw_infix_set' => 18,
			'qwk_indextuple' => 20,
			'qw_suffix_set' => 21,
			'qw_with' => 66,
			'qw_morph' => 23,
			'neg_regex' => 71,
			'qw_keys' => 70,
			'qw_any' => 27
		}
	},
	{#State 183
		ACTIONS => {
			"=" => 78,
			"," => 248
		},
		GOTOS => {
			'matchid' => 103,
			'matchid_eq' => 77
		}
	},
	{#State 184
		DEFAULT => -191
	},
	{#State 185
		DEFAULT => -225,
		GOTOS => {
			'l_txchain' => 249
		}
	},
	{#State 186
		DEFAULT => -187
	},
	{#State 187
		DEFAULT => -4,
		GOTOS => {
			'count_filters' => 250
		}
	},
	{#State 188
		ACTIONS => {
			"[" => 252
		},
		DEFAULT => -92,
		GOTOS => {
			'qfb_date' => 251
		}
	},
	{#State 189
		DEFAULT => -31
	},
	{#State 190
		ACTIONS => {
			"[" => 253
		},
		DEFAULT => -106,
		GOTOS => {
			'qfb_ctxsort' => 254
		}
	},
	{#State 191
		ACTIONS => {
			'INTEGER' => 124,
			"[" => 256
		},
		GOTOS => {
			'int_str' => 125,
			'integer' => 255
		}
	},
	{#State 192
		DEFAULT => -44
	},
	{#State 193
		DEFAULT => -49
	},
	{#State 194
		ACTIONS => {
			"[" => 257
		}
	},
	{#State 195
		DEFAULT => -53
	},
	{#State 196
		DEFAULT => -54
	},
	{#State 197
		DEFAULT => -33
	},
	{#State 198
		DEFAULT => -42
	},
	{#State 199
		DEFAULT => -52
	},
	{#State 200
		ACTIONS => {
			"[" => 258,
			'INTEGER' => 55,
			'DATE' => 53,
			'SYMBOL' => 68
		},
		GOTOS => {
			'symbol' => 259
		}
	},
	{#State 201
		ACTIONS => {
			'INTEGER' => 55,
			'DATE' => 53,
			'SYMBOL' => 68
		},
		DEFAULT => -46,
		GOTOS => {
			'qf_subcorpora' => 261,
			'symbol' => 262,
			's_subcorpus' => 260
		}
	},
	{#State 202
		ACTIONS => {
			"[" => 253
		},
		DEFAULT => -106,
		GOTOS => {
			'qfb_ctxsort' => 263
		}
	},
	{#State 203
		DEFAULT => -41
	},
	{#State 204
		ACTIONS => {
			"[" => 264
		},
		DEFAULT => -78
	},
	{#State 205
		ACTIONS => {
			"[" => 253
		},
		DEFAULT => -106,
		GOTOS => {
			'qfb_ctxsort' => 265
		}
	},
	{#State 206
		ACTIONS => {
			"[" => 253
		},
		DEFAULT => -106,
		GOTOS => {
			'qfb_ctxsort' => 266
		}
	},
	{#State 207
		DEFAULT => -51
	},
	{#State 208
		ACTIONS => {
			"[" => 267
		},
		DEFAULT => -85,
		GOTOS => {
			'qfb_int' => 268
		}
	},
	{#State 209
		ACTIONS => {
			"[" => 269
		}
	},
	{#State 210
		DEFAULT => -32
	},
	{#State 211
		DEFAULT => -65
	},
	{#State 212
		DEFAULT => -64
	},
	{#State 213
		ACTIONS => {
			'FILENAMES_ONLY' => 271,
			"!" => 270,
			'DEBUG_RANK' => 273,
			'HAS_FIELD' => 194
		},
		GOTOS => {
			'qf_has_field' => 272
		}
	},
	{#State 214
		DEFAULT => -40
	},
	{#State 215
		DEFAULT => -50
	},
	{#State 216
		ACTIONS => {
			"[" => 253
		},
		DEFAULT => -106,
		GOTOS => {
			'qfb_ctxsort' => 274
		}
	},
	{#State 217
		ACTIONS => {
			"[" => 275
		}
	},
	{#State 218
		DEFAULT => -55
	},
	{#State 219
		ACTIONS => {
			"[" => 276
		}
	},
	{#State 220
		ACTIONS => {
			'KW_FILENAME' => 279,
			'INTEGER' => 55,
			'DATE' => 53,
			'SYMBOL' => 68
		},
		GOTOS => {
			's_breakname' => 278,
			'symbol' => 277
		}
	},
	{#State 221
		ACTIONS => {
			"[" => 267
		},
		DEFAULT => -85,
		GOTOS => {
			'qfb_int' => 280
		}
	},
	{#State 222
		ACTIONS => {
			"[" => 253
		},
		DEFAULT => -106,
		GOTOS => {
			'qfb_ctxsort' => 281
		}
	},
	{#State 223
		ACTIONS => {
			"[" => 282
		}
	},
	{#State 224
		ACTIONS => {
			"[" => 252
		},
		DEFAULT => -92,
		GOTOS => {
			'qfb_date' => 283
		}
	},
	{#State 225
		ACTIONS => {
			"=" => 78
		},
		DEFAULT => -123,
		GOTOS => {
			'matchid_eq' => 77,
			'matchid' => 113
		}
	},
	{#State 226
		ACTIONS => {
			"=" => 78
		},
		DEFAULT => -124,
		GOTOS => {
			'matchid' => 113,
			'matchid_eq' => 77
		}
	},
	{#State 227
		DEFAULT => -199
	},
	{#State 228
		ACTIONS => {
			'INTEGER' => 124
		},
		GOTOS => {
			'int_str' => 284
		}
	},
	{#State 229
		ACTIONS => {
			'DOLLAR_DOT' => 63,
			"*" => 8,
			"[" => 22,
			'NEG_REGEX' => 65,
			"<" => 64,
			'REGEX' => 69,
			'SUFFIX' => 26,
			"^" => 25,
			'SYMBOL' => 68,
			"\$" => 24,
			'INDEX' => 28,
			'COLON_LBRACE' => 51,
			"{" => 52,
			'STAR_LBRACE' => 34,
			'INTEGER' => 55,
			'AT_LBRACE' => 32,
			'PREFIX' => 31,
			'DATE' => 53,
			'INFIX' => 5,
			"%" => 6,
			'KEYS' => 39,
			"\@" => 4,
			"(" => 79
		},
		GOTOS => {
			'symbol' => 62,
			'qw_prefix' => 17,
			'qw_infix_set' => 18,
			'qwk_indextuple' => 20,
			'qw_with' => 66,
			'qw_suffix_set' => 21,
			'qw_morph' => 23,
			'qw_keys' => 70,
			'neg_regex' => 71,
			'qw_any' => 27,
			's_infix' => 11,
			'qw_lemma' => 12,
			'qw_anchor' => 54,
			'qw_withor' => 15,
			'qw_infix' => 14,
			'qw_regex' => 56,
			'qw_exact' => 58,
			'qw_matchid' => 16,
			's_prefix' => 61,
			'regex' => 41,
			'qc_word' => 285,
			'qw_set_infl' => 42,
			'qw_prefix_set' => 44,
			'qw_suffix' => 10,
			'qw_without' => 45,
			's_word' => 46,
			's_index' => 47,
			'qw_bareword' => 1,
			'qw_thesaurus' => 29,
			'qw_listfile' => 30,
			'qw_chunk' => 35,
			'qw_set_exact' => 2,
			'index' => 37,
			's_suffix' => 7
		}
	},
	{#State 230
		ACTIONS => {
			'SYMBOL' => 68,
			"\$" => 24,
			"^" => 25,
			'SUFFIX' => 26,
			'REGEX' => 69,
			"*" => 8,
			'DOLLAR_DOT' => 63,
			"<" => 64,
			'NEG_REGEX' => 65,
			"[" => 22,
			"(" => 79,
			"\@" => 4,
			'KEYS' => 39,
			'INFIX' => 5,
			"%" => 6,
			'COLON_LBRACE' => 51,
			'INDEX' => 28,
			"{" => 52,
			'DATE' => 53,
			'PREFIX' => 31,
			'AT_LBRACE' => 32,
			'INTEGER' => 55,
			'STAR_LBRACE' => 34
		},
		GOTOS => {
			'qw_keys' => 70,
			'neg_regex' => 71,
			'qw_any' => 27,
			'qw_morph' => 23,
			'qwk_indextuple' => 20,
			'qw_with' => 66,
			'qw_suffix_set' => 21,
			'symbol' => 62,
			'qw_prefix' => 17,
			'qw_infix_set' => 18,
			's_prefix' => 61,
			'qw_regex' => 56,
			'qw_exact' => 58,
			'qw_matchid' => 16,
			'qw_anchor' => 54,
			'qw_withor' => 15,
			'qw_infix' => 14,
			's_infix' => 11,
			'qw_lemma' => 12,
			's_index' => 47,
			'qw_suffix' => 10,
			'qw_without' => 45,
			's_word' => 46,
			'qw_set_infl' => 42,
			'qw_prefix_set' => 44,
			'regex' => 41,
			'qc_word' => 286,
			'index' => 37,
			's_suffix' => 7,
			'qw_chunk' => 35,
			'qw_set_exact' => 2,
			'qw_listfile' => 30,
			'qw_bareword' => 1,
			'qw_thesaurus' => 29
		}
	},
	{#State 231
		ACTIONS => {
			"(" => 79,
			"\@" => 4,
			'KEYS' => 39,
			'INFIX' => 5,
			"%" => 6,
			'COLON_LBRACE' => 51,
			'INDEX' => 28,
			"{" => 52,
			'DATE' => 53,
			'AT_LBRACE' => 32,
			'PREFIX' => 31,
			'INTEGER' => 55,
			'STAR_LBRACE' => 34,
			'SYMBOL' => 68,
			"\$" => 24,
			"^" => 25,
			'SUFFIX' => 26,
			'REGEX' => 69,
			"*" => 8,
			'DOLLAR_DOT' => 63,
			"<" => 64,
			'NEG_REGEX' => 65,
			"[" => 22
		},
		GOTOS => {
			'qw_listfile' => 30,
			'qw_thesaurus' => 29,
			'qw_bareword' => 1,
			's_suffix' => 7,
			'index' => 37,
			'qw_set_exact' => 2,
			'qw_chunk' => 35,
			'qw_prefix_set' => 44,
			'qw_set_infl' => 42,
			'qc_word' => 287,
			'regex' => 41,
			's_index' => 47,
			's_word' => 46,
			'qw_without' => 45,
			'qw_suffix' => 10,
			'qw_withor' => 15,
			'qw_infix' => 14,
			'qw_anchor' => 54,
			'qw_lemma' => 12,
			's_infix' => 11,
			's_prefix' => 61,
			'qw_matchid' => 16,
			'qw_exact' => 58,
			'qw_regex' => 56,
			'qw_suffix_set' => 21,
			'qw_with' => 66,
			'qwk_indextuple' => 20,
			'qw_infix_set' => 18,
			'qw_prefix' => 17,
			'symbol' => 62,
			'qw_any' => 27,
			'neg_regex' => 71,
			'qw_keys' => 70,
			'qw_morph' => 23
		}
	},
	{#State 232
		ACTIONS => {
			'SYMBOL' => 68,
			"\$" => 24,
			"^" => 25,
			'SUFFIX' => 26,
			'REGEX' => 69,
			'DOLLAR_DOT' => 63,
			"*" => 8,
			"<" => 64,
			'NEG_REGEX' => 65,
			"[" => 22,
			"(" => 79,
			"\@" => 4,
			'KEYS' => 39,
			'INFIX' => 5,
			"%" => 6,
			"{" => 52,
			'COLON_LBRACE' => 51,
			'INDEX' => 28,
			'DATE' => 53,
			'PREFIX' => 31,
			'AT_LBRACE' => 32,
			'INTEGER' => 55,
			'STAR_LBRACE' => 34
		},
		GOTOS => {
			'qw_exact' => 58,
			'qw_matchid' => 16,
			'qw_regex' => 56,
			's_prefix' => 61,
			'qw_lemma' => 12,
			's_infix' => 11,
			'qw_infix' => 14,
			'qw_withor' => 15,
			'qw_anchor' => 54,
			'qw_morph' => 23,
			'qw_any' => 27,
			'qw_keys' => 70,
			'neg_regex' => 71,
			'qw_infix_set' => 18,
			'symbol' => 62,
			'qw_prefix' => 17,
			'qw_with' => 66,
			'qw_suffix_set' => 21,
			'qwk_indextuple' => 20,
			'qw_set_exact' => 2,
			'qw_chunk' => 35,
			's_suffix' => 7,
			'index' => 37,
			'qw_thesaurus' => 29,
			'qw_bareword' => 1,
			'qw_listfile' => 30,
			's_word' => 46,
			'qw_suffix' => 10,
			'qw_without' => 45,
			's_index' => 47,
			'regex' => 41,
			'qc_word' => 288,
			'qw_prefix_set' => 44,
			'qw_set_infl' => 42
		}
	},
	{#State 233
		ACTIONS => {
			'NEAR' => 49,
			'COLON_LBRACE' => 51,
			'INDEX' => 28,
			"{" => 52,
			'AT_LBRACE' => 32,
			"\"" => 13,
			'PREFIX' => 31,
			'DATE' => 53,
			'STAR_LBRACE' => 34,
			'INTEGER' => 55,
			'COUNT' => 57,
			"\@" => 4,
			"(" => 36,
			"%" => 6,
			'INFIX' => 5,
			'KEYS' => 39,
			"*" => 8,
			'DOLLAR_DOT' => 63,
			"!" => 19,
			"<" => 64,
			"[" => 22,
			'NEG_REGEX' => 65,
			"^" => 25,
			"\$" => 24,
			'SYMBOL' => 68,
			'REGEX' => 69,
			'SUFFIX' => 26
		},
		GOTOS => {
			'qc_basic' => 48,
			's_infix' => 11,
			'qc_phrase' => 50,
			'qw_lemma' => 12,
			'qw_anchor' => 54,
			'qw_infix' => 14,
			'qw_withor' => 15,
			'qw_regex' => 56,
			'qw_matchid' => 16,
			'qw_exact' => 58,
			'query_conditions' => 157,
			's_prefix' => 61,
			'q_clause' => 60,
			'qw_prefix' => 17,
			'symbol' => 62,
			'qw_infix_set' => 18,
			'qwk_indextuple' => 20,
			'qw_suffix_set' => 21,
			'qw_with' => 66,
			'qc_concat' => 67,
			'qw_morph' => 23,
			'qw_keys' => 70,
			'neg_regex' => 71,
			'count_query' => 158,
			'qw_any' => 27,
			'qw_bareword' => 1,
			'qw_thesaurus' => 29,
			'qw_listfile' => 30,
			'qw_chunk' => 35,
			'qw_set_exact' => 2,
			'qc_boolean' => 3,
			'qc_matchid' => 38,
			'index' => 37,
			's_suffix' => 7,
			'qc_word' => 40,
			'regex' => 41,
			'qwk_countsrc' => 289,
			'qc_tokens' => 43,
			'qw_set_infl' => 42,
			'qc_near' => 9,
			'qw_prefix_set' => 44,
			'qw_without' => 45,
			'qw_suffix' => 10,
			's_word' => 46,
			's_index' => 47
		}
	},
	{#State 234
		ACTIONS => {
			'SYMBOL' => 68,
			"\$" => 140,
			'INDEX' => 28,
			'DATE' => 53,
			'INTEGER' => 55
		},
		GOTOS => {
			'symbol' => 143,
			's_indextuple_item' => 290,
			's_index' => 144,
			'index' => 37
		}
	},
	{#State 235
		DEFAULT => -208
	},
	{#State 236
		DEFAULT => -206
	},
	{#State 237
		ACTIONS => {
			'SAMPLE' => 296,
			'KW_COMMENT' => 200,
			'LESS_BY_COUNT' => 300,
			'BY' => 293,
			'GREATER_BY_COUNT' => 303,
			'GREATER_BY_KEY' => 298,
			'CLIMIT' => 294,
			'LESS_BY_KEY' => 304
		},
		DEFAULT => -210,
		GOTOS => {
			'count_sample' => 301,
			'count_by' => 295,
			'q_comment' => 297,
			'count_filter' => 299,
			'count_limit' => 292,
			'count_sort_op' => 302,
			'count_sort' => 291
		}
	},
	{#State 238
		ACTIONS => {
			'DATE' => 53,
			"]" => 305,
			"," => 137,
			'INTEGER' => 55,
			'SYMBOL' => 68,
			";" => 136
		},
		GOTOS => {
			'symbol' => 138,
			's_morphitem' => 135
		}
	},
	{#State 239
		DEFAULT => -198
	},
	{#State 240
		DEFAULT => -196
	},
	{#State 241
		DEFAULT => -168
	},
	{#State 242
		DEFAULT => -202
	},
	{#State 243
		ACTIONS => {
			'INTEGER' => 55,
			'DATE' => 53,
			'SYMBOL' => 68
		},
		GOTOS => {
			'symbol' => 109,
			's_semclass' => 306
		}
	},
	{#State 244
		ACTIONS => {
			'DATE' => 53,
			'INTEGER' => 55,
			"," => 147,
			'RBRACE_STAR' => 308,
			"}" => 307,
			'SYMBOL' => 68
		},
		GOTOS => {
			'symbol' => 62,
			's_word' => 146
		}
	},
	{#State 245
		ACTIONS => {
			'EXPANDER' => 162
		},
		DEFAULT => -166,
		GOTOS => {
			's_expander' => 163
		}
	},
	{#State 246
		ACTIONS => {
			'DATE' => 53,
			"," => 147,
			'INTEGER' => 55,
			'RBRACE_STAR' => 310,
			"}" => 309,
			'SYMBOL' => 68
		},
		GOTOS => {
			's_word' => 146,
			'symbol' => 62
		}
	},
	{#State 247
		ACTIONS => {
			'INTEGER' => 55,
			"," => 147,
			"}" => 311,
			'DATE' => 53,
			'SYMBOL' => 68
		},
		GOTOS => {
			's_word' => 146,
			'symbol' => 62
		}
	},
	{#State 248
		ACTIONS => {
			"(" => 182,
			"\@" => 4,
			'KEYS' => 39,
			'INFIX' => 5,
			"%" => 6,
			'DATE' => 53,
			'AT_LBRACE' => 32,
			"\"" => 13,
			'PREFIX' => 31,
			'INTEGER' => 55,
			'STAR_LBRACE' => 34,
			"{" => 52,
			'COLON_LBRACE' => 51,
			'INDEX' => 28,
			'SYMBOL' => 68,
			"\$" => 24,
			"^" => 25,
			'SUFFIX' => 26,
			'REGEX' => 69,
			"<" => 64,
			'NEG_REGEX' => 65,
			"[" => 22,
			'DOLLAR_DOT' => 63,
			"*" => 8
		},
		GOTOS => {
			'qc_phrase' => 50,
			's_infix' => 11,
			'qw_lemma' => 12,
			'qw_anchor' => 54,
			'qw_infix' => 14,
			'qw_withor' => 15,
			'qw_regex' => 56,
			'qw_exact' => 58,
			'qw_matchid' => 16,
			's_prefix' => 61,
			'symbol' => 62,
			'qw_prefix' => 17,
			'qw_infix_set' => 18,
			'qwk_indextuple' => 20,
			'qw_with' => 66,
			'qw_suffix_set' => 21,
			'qw_morph' => 23,
			'qw_keys' => 70,
			'neg_regex' => 71,
			'qw_any' => 27,
			'qw_bareword' => 1,
			'qw_thesaurus' => 29,
			'qw_listfile' => 30,
			'qw_chunk' => 35,
			'qw_set_exact' => 2,
			'index' => 37,
			's_suffix' => 7,
			'regex' => 41,
			'qc_word' => 40,
			'qc_tokens' => 312,
			'qw_set_infl' => 42,
			'qw_prefix_set' => 44,
			'qw_suffix' => 10,
			'qw_without' => 45,
			's_word' => 46,
			's_index' => 47
		}
	},
	{#State 249
		ACTIONS => {
			'EXPANDER' => 162
		},
		DEFAULT => -177,
		GOTOS => {
			's_expander' => 163
		}
	},
	{#State 250
		ACTIONS => {
			'LESS_BY_KEY' => 304,
			'GREATER_BY_KEY' => 298,
			")" => 313,
			'CLIMIT' => 294,
			'KW_COMMENT' => 200,
			'SAMPLE' => 296,
			'LESS_BY_COUNT' => 300,
			'BY' => 293,
			'GREATER_BY_COUNT' => 303
		},
		GOTOS => {
			'count_sample' => 301,
			'count_by' => 295,
			'count_limit' => 292,
			'q_comment' => 297,
			'count_filter' => 299,
			'count_sort_op' => 302,
			'count_sort' => 291
		}
	},
	{#State 251
		DEFAULT => -75
	},
	{#State 252
		ACTIONS => {
			'INTEGER' => 316,
			"," => 317,
			"]" => 314,
			'DATE' => 315
		},
		GOTOS => {
			'date' => 318
		}
	},
	{#State 253
		ACTIONS => {
			"=" => 78,
			'SYMBOL' => 319
		},
		DEFAULT => -111,
		GOTOS => {
			'qfb_ctxkey' => 322,
			'sym_str' => 323,
			'qfbc_matchref' => 320,
			'matchid' => 321,
			'matchid_eq' => 77
		}
	},
	{#State 254
		DEFAULT => -68
	},
	{#State 255
		DEFAULT => -37
	},
	{#State 256
		ACTIONS => {
			'INTEGER' => 124
		},
		GOTOS => {
			'integer' => 324,
			'int_str' => 125
		}
	},
	{#State 257
		ACTIONS => {
			'INTEGER' => 55,
			'DATE' => 53,
			'SYMBOL' => 68
		},
		GOTOS => {
			's_biblname' => 325,
			'symbol' => 326
		}
	},
	{#State 258
		ACTIONS => {
			'SYMBOL' => 68,
			'INTEGER' => 55,
			'DATE' => 53
		},
		GOTOS => {
			'symbol' => 327
		}
	},
	{#State 259
		DEFAULT => -34
	},
	{#State 260
		DEFAULT => -47
	},
	{#State 261
		ACTIONS => {
			"," => 328
		},
		DEFAULT => -36
	},
	{#State 262
		DEFAULT => -259
	},
	{#State 263
		DEFAULT => -70
	},
	{#State 264
		ACTIONS => {
			'INTEGER' => 124,
			"]" => 330
		},
		GOTOS => {
			'int_str' => 329
		}
	},
	{#State 265
		DEFAULT => -66
	},
	{#State 266
		DEFAULT => -69
	},
	{#State 267
		ACTIONS => {
			"]" => 332,
			"," => 333,
			'INTEGER' => 124
		},
		GOTOS => {
			'int_str' => 331
		}
	},
	{#State 268
		DEFAULT => -73
	},
	{#State 269
		ACTIONS => {
			'INTEGER' => 124
		},
		GOTOS => {
			'int_str' => 334
		}
	},
	{#State 270
		ACTIONS => {
			"!" => 270,
			'HAS_FIELD' => 194
		},
		GOTOS => {
			'qf_has_field' => 272
		}
	},
	{#State 271
		DEFAULT => -43
	},
	{#State 272
		DEFAULT => -63
	},
	{#State 273
		DEFAULT => -45
	},
	{#State 274
		DEFAULT => -71
	},
	{#State 275
		ACTIONS => {
			'SYMBOL' => 68,
			'INTEGER' => 55,
			'KW_DATE' => 336,
			'DATE' => 53
		},
		GOTOS => {
			's_biblname' => 335,
			'symbol' => 326
		}
	},
	{#State 276
		ACTIONS => {
			'SYMBOL' => 68,
			'DATE' => 53,
			'KW_DATE' => 338,
			'INTEGER' => 55
		},
		GOTOS => {
			's_biblname' => 337,
			'symbol' => 326
		}
	},
	{#State 277
		DEFAULT => -261
	},
	{#State 278
		DEFAULT => -39
	},
	{#State 279
		DEFAULT => -262
	},
	{#State 280
		DEFAULT => -72
	},
	{#State 281
		DEFAULT => -67
	},
	{#State 282
		ACTIONS => {
			'INTEGER' => 316,
			'DATE' => 315
		},
		GOTOS => {
			'date' => 339
		}
	},
	{#State 283
		DEFAULT => -76
	},
	{#State 284
		DEFAULT => -200
	},
	{#State 285
		ACTIONS => {
			"=" => 78,
			'WITHOR' => 100,
			'WITH' => 101,
			'WITHOUT' => 102
		},
		DEFAULT => -222,
		GOTOS => {
			'matchid_eq' => 77,
			'matchid' => 99
		}
	},
	{#State 286
		ACTIONS => {
			'WITHOUT' => 102,
			'WITHOR' => 100,
			'WITH' => 101,
			"=" => 78
		},
		DEFAULT => -221,
		GOTOS => {
			'matchid' => 99,
			'matchid_eq' => 77
		}
	},
	{#State 287
		ACTIONS => {
			'WITH' => 101,
			'WITHOR' => 100,
			'WITHOUT' => 102,
			"=" => 78
		},
		DEFAULT => -224,
		GOTOS => {
			'matchid' => 99,
			'matchid_eq' => 77
		}
	},
	{#State 288
		ACTIONS => {
			'WITHOUT' => 102,
			'WITH' => 101,
			'WITHOR' => 100,
			"=" => 78
		},
		DEFAULT => -223,
		GOTOS => {
			'matchid' => 99,
			'matchid_eq' => 77
		}
	},
	{#State 289
		ACTIONS => {
			")" => 340
		}
	},
	{#State 290
		DEFAULT => -232
	},
	{#State 291
		DEFAULT => -9
	},
	{#State 292
		DEFAULT => -8
	},
	{#State 293
		ACTIONS => {
			'DATE' => 53,
			'KW_FILENAME' => 344,
			'INTEGER' => 55,
			'INDEX' => 28,
			"(" => 345,
			'KW_DATE' => 348,
			"\@" => 351,
			'KW_FILEID' => 341,
			"[" => 347,
			"*" => 350,
			'SYMBOL' => 68,
			"\$" => 140
		},
		DEFAULT => -227,
		GOTOS => {
			'symbol' => 326,
			'l_countkeys' => 346,
			's_biblname' => 342,
			'index' => 37,
			's_index' => 343,
			'count_key' => 349
		}
	},
	{#State 294
		ACTIONS => {
			'INTEGER' => 124,
			"[" => 352
		},
		GOTOS => {
			'int_str' => 125,
			'integer' => 353
		}
	},
	{#State 295
		DEFAULT => -6
	},
	{#State 296
		ACTIONS => {
			"[" => 355,
			'INTEGER' => 124
		},
		GOTOS => {
			'integer' => 354,
			'int_str' => 125
		}
	},
	{#State 297
		DEFAULT => -10
	},
	{#State 298
		DEFAULT => -19
	},
	{#State 299
		DEFAULT => -5
	},
	{#State 300
		DEFAULT => -20
	},
	{#State 301
		DEFAULT => -7
	},
	{#State 302
		ACTIONS => {
			"[" => 356
		},
		DEFAULT => -22,
		GOTOS => {
			'count_sort_minmax' => 357
		}
	},
	{#State 303
		DEFAULT => -21
	},
	{#State 304
		DEFAULT => -18
	},
	{#State 305
		DEFAULT => -194
	},
	{#State 306
		ACTIONS => {
			"}" => 358
		}
	},
	{#State 307
		DEFAULT => -225,
		GOTOS => {
			'l_txchain' => 359
		}
	},
	{#State 308
		DEFAULT => -188
	},
	{#State 309
		DEFAULT => -190
	},
	{#State 310
		DEFAULT => -186
	},
	{#State 311
		DEFAULT => -176
	},
	{#State 312
		ACTIONS => {
			"," => 360,
			"=" => 78
		},
		GOTOS => {
			'matchid_eq' => 77,
			'matchid' => 103
		}
	},
	{#State 313
		DEFAULT => -4,
		GOTOS => {
			'count_filters' => 361
		}
	},
	{#State 314
		DEFAULT => -93
	},
	{#State 315
		DEFAULT => -281
	},
	{#State 316
		DEFAULT => -282
	},
	{#State 317
		ACTIONS => {
			'DATE' => 315,
			'INTEGER' => 316
		},
		GOTOS => {
			'date' => 362
		}
	},
	{#State 318
		ACTIONS => {
			"]" => 363,
			"," => 364
		}
	},
	{#State 319
		DEFAULT => -268
	},
	{#State 320
		ACTIONS => {
			"-" => 367,
			'INTEGER' => 124,
			"+" => 368
		},
		DEFAULT => -113,
		GOTOS => {
			'qfbc_offset' => 366,
			'int_str' => 125,
			'integer' => 365
		}
	},
	{#State 321
		DEFAULT => -112
	},
	{#State 322
		ACTIONS => {
			"]" => 370,
			"," => 369
		},
		GOTOS => {
			'qfb_bibl_ne' => 371
		}
	},
	{#State 323
		ACTIONS => {
			"=" => 78
		},
		DEFAULT => -111,
		GOTOS => {
			'matchid' => 321,
			'matchid_eq' => 77,
			'qfbc_matchref' => 372
		}
	},
	{#State 324
		ACTIONS => {
			"]" => 373
		}
	},
	{#State 325
		ACTIONS => {
			"," => 374
		}
	},
	{#State 326
		DEFAULT => -260
	},
	{#State 327
		ACTIONS => {
			"]" => 375
		}
	},
	{#State 328
		ACTIONS => {
			'SYMBOL' => 68,
			'INTEGER' => 55,
			'DATE' => 53
		},
		GOTOS => {
			'symbol' => 262,
			's_subcorpus' => 376
		}
	},
	{#State 329
		ACTIONS => {
			"]" => 377
		}
	},
	{#State 330
		DEFAULT => -79
	},
	{#State 331
		ACTIONS => {
			"," => 379,
			"]" => 378
		}
	},
	{#State 332
		DEFAULT => -86
	},
	{#State 333
		ACTIONS => {
			'INTEGER' => 124,
			"]" => 381
		},
		GOTOS => {
			'int_str' => 380
		}
	},
	{#State 334
		ACTIONS => {
			"]" => 382
		}
	},
	{#State 335
		ACTIONS => {
			"," => 369
		},
		DEFAULT => -98,
		GOTOS => {
			'qfb_bibl' => 384,
			'qfb_bibl_ne' => 383
		}
	},
	{#State 336
		ACTIONS => {
			"," => 369
		},
		DEFAULT => -98,
		GOTOS => {
			'qfb_bibl' => 385,
			'qfb_bibl_ne' => 383
		}
	},
	{#State 337
		ACTIONS => {
			"," => 369
		},
		DEFAULT => -98,
		GOTOS => {
			'qfb_bibl' => 386,
			'qfb_bibl_ne' => 383
		}
	},
	{#State 338
		ACTIONS => {
			"," => 369
		},
		DEFAULT => -98,
		GOTOS => {
			'qfb_bibl' => 387,
			'qfb_bibl_ne' => 383
		}
	},
	{#State 339
		ACTIONS => {
			"]" => 388
		}
	},
	{#State 340
		DEFAULT => -207
	},
	{#State 341
		DEFAULT => -235
	},
	{#State 342
		DEFAULT => -239
	},
	{#State 343
		ACTIONS => {
			"=" => 78
		},
		DEFAULT => -243,
		GOTOS => {
			'matchid' => 389,
			'matchid_eq' => 77,
			'ck_matchid' => 390
		}
	},
	{#State 344
		DEFAULT => -236
	},
	{#State 345
		ACTIONS => {
			'KW_FILENAME' => 344,
			'INTEGER' => 55,
			'DATE' => 53,
			'INDEX' => 28,
			"*" => 350,
			'KW_FILEID' => 341,
			"\@" => 351,
			"(" => 345,
			'KW_DATE' => 348,
			"\$" => 140,
			'SYMBOL' => 68
		},
		GOTOS => {
			'symbol' => 326,
			's_biblname' => 342,
			'index' => 37,
			's_index' => 343,
			'count_key' => 391
		}
	},
	{#State 346
		ACTIONS => {
			"," => 392
		},
		DEFAULT => -11
	},
	{#State 347
		ACTIONS => {
			"*" => 350,
			'INDEX' => 28,
			'DATE' => 53,
			'KW_FILENAME' => 344,
			'INTEGER' => 55,
			'SYMBOL' => 68,
			"\$" => 140,
			'KW_DATE' => 348,
			"(" => 345,
			"\@" => 351,
			'KW_FILEID' => 341
		},
		DEFAULT => -227,
		GOTOS => {
			'l_countkeys' => 393,
			'symbol' => 326,
			'count_key' => 349,
			's_biblname' => 342,
			's_index' => 343,
			'index' => 37
		}
	},
	{#State 348
		ACTIONS => {
			"/" => 394
		},
		DEFAULT => -237
	},
	{#State 349
		ACTIONS => {
			"~" => 395
		},
		DEFAULT => -228
	},
	{#State 350
		DEFAULT => -233
	},
	{#State 351
		ACTIONS => {
			'SYMBOL' => 68,
			'INTEGER' => 55,
			'DATE' => 53
		},
		GOTOS => {
			'symbol' => 396
		}
	},
	{#State 352
		ACTIONS => {
			'INTEGER' => 124
		},
		GOTOS => {
			'int_str' => 125,
			'integer' => 397
		}
	},
	{#State 353
		DEFAULT => -15
	},
	{#State 354
		DEFAULT => -13
	},
	{#State 355
		ACTIONS => {
			'INTEGER' => 124
		},
		GOTOS => {
			'integer' => 398,
			'int_str' => 125
		}
	},
	{#State 356
		ACTIONS => {
			'SYMBOL' => 68,
			"]" => 399,
			'DATE' => 53,
			'INTEGER' => 55,
			"," => 401
		},
		GOTOS => {
			'symbol' => 400
		}
	},
	{#State 357
		DEFAULT => -17
	},
	{#State 358
		DEFAULT => -192
	},
	{#State 359
		ACTIONS => {
			'EXPANDER' => 162
		},
		DEFAULT => -178,
		GOTOS => {
			's_expander' => 163
		}
	},
	{#State 360
		ACTIONS => {
			"^" => 25,
			'SYMBOL' => 68,
			"\$" => 24,
			'REGEX' => 69,
			'SUFFIX' => 26,
			"<" => 64,
			"[" => 22,
			'NEG_REGEX' => 65,
			"*" => 8,
			'DOLLAR_DOT' => 63,
			"\@" => 4,
			"(" => 182,
			'INFIX' => 5,
			"%" => 6,
			'KEYS' => 39,
			'AT_LBRACE' => 32,
			"\"" => 13,
			'PREFIX' => 31,
			'DATE' => 53,
			'STAR_LBRACE' => 34,
			'INTEGER' => 402,
			'INDEX' => 28,
			'COLON_LBRACE' => 51,
			"{" => 52
		},
		GOTOS => {
			'qw_set_exact' => 2,
			'qw_chunk' => 35,
			's_suffix' => 7,
			'index' => 37,
			'qw_thesaurus' => 29,
			'qw_bareword' => 1,
			'qw_listfile' => 30,
			's_word' => 46,
			'qw_without' => 45,
			'qw_suffix' => 10,
			's_index' => 47,
			'qc_word' => 40,
			'regex' => 41,
			'int_str' => 125,
			'qw_prefix_set' => 44,
			'qc_tokens' => 403,
			'qw_set_infl' => 42,
			'qw_matchid' => 16,
			'qw_exact' => 58,
			'qw_regex' => 56,
			's_prefix' => 61,
			'qw_lemma' => 12,
			'integer' => 404,
			'qc_phrase' => 50,
			's_infix' => 11,
			'qw_withor' => 15,
			'qw_infix' => 14,
			'qw_anchor' => 54,
			'qw_morph' => 23,
			'qw_any' => 27,
			'neg_regex' => 71,
			'qw_keys' => 70,
			'qw_infix_set' => 18,
			'qw_prefix' => 17,
			'symbol' => 62,
			'qw_suffix_set' => 21,
			'qw_with' => 66,
			'qwk_indextuple' => 20
		}
	},
	{#State 361
		ACTIONS => {
			'SAMPLE' => 296,
			'KW_COMMENT' => 200,
			'LESS_BY_COUNT' => 300,
			'GREATER_BY_COUNT' => 303,
			'BY' => 293,
			'LESS_BY_KEY' => 304,
			'GREATER_BY_KEY' => 298,
			'CLIMIT' => 294
		},
		DEFAULT => -3,
		GOTOS => {
			'count_sort_op' => 302,
			'count_sort' => 291,
			'count_filter' => 299,
			'count_limit' => 292,
			'q_comment' => 297,
			'count_by' => 295,
			'count_sample' => 301
		}
	},
	{#State 362
		ACTIONS => {
			"]" => 405
		}
	},
	{#State 363
		DEFAULT => -94
	},
	{#State 364
		ACTIONS => {
			"]" => 407,
			'DATE' => 315,
			'INTEGER' => 316
		},
		GOTOS => {
			'date' => 406
		}
	},
	{#State 365
		DEFAULT => -114
	},
	{#State 366
		DEFAULT => -110
	},
	{#State 367
		ACTIONS => {
			'INTEGER' => 124
		},
		GOTOS => {
			'integer' => 408,
			'int_str' => 125
		}
	},
	{#State 368
		ACTIONS => {
			'INTEGER' => 124
		},
		GOTOS => {
			'int_str' => 125,
			'integer' => 409
		}
	},
	{#State 369
		ACTIONS => {
			'SYMBOL' => 68,
			'INTEGER' => 55,
			"," => 410,
			'DATE' => 53
		},
		DEFAULT => -100,
		GOTOS => {
			'symbol' => 411
		}
	},
	{#State 370
		DEFAULT => -107
	},
	{#State 371
		ACTIONS => {
			"]" => 412
		}
	},
	{#State 372
		ACTIONS => {
			'INTEGER' => 124,
			"+" => 368,
			"-" => 367
		},
		DEFAULT => -113,
		GOTOS => {
			'integer' => 365,
			'qfbc_offset' => 413,
			'int_str' => 125
		}
	},
	{#State 373
		DEFAULT => -38
	},
	{#State 374
		ACTIONS => {
			"{" => 416,
			'PREFIX' => 31,
			'DATE' => 53,
			'NEG_REGEX' => 65,
			'INTEGER' => 55,
			'SYMBOL' => 68,
			'REGEX' => 69,
			'SUFFIX' => 26,
			'INFIX' => 5
		},
		GOTOS => {
			'regex' => 418,
			's_infix' => 419,
			'symbol' => 414,
			's_suffix' => 420,
			'neg_regex' => 415,
			's_prefix' => 417
		}
	},
	{#State 375
		DEFAULT => -35
	},
	{#State 376
		DEFAULT => -48
	},
	{#State 377
		DEFAULT => -80
	},
	{#State 378
		DEFAULT => -88
	},
	{#State 379
		ACTIONS => {
			'INTEGER' => 124,
			"]" => 422
		},
		GOTOS => {
			'int_str' => 421
		}
	},
	{#State 380
		ACTIONS => {
			"]" => 423
		}
	},
	{#State 381
		DEFAULT => -87
	},
	{#State 382
		DEFAULT => -74
	},
	{#State 383
		DEFAULT => -99
	},
	{#State 384
		ACTIONS => {
			"]" => 424
		}
	},
	{#State 385
		ACTIONS => {
			"]" => 425
		}
	},
	{#State 386
		ACTIONS => {
			"]" => 426
		}
	},
	{#State 387
		ACTIONS => {
			"]" => 427
		}
	},
	{#State 388
		DEFAULT => -77
	},
	{#State 389
		DEFAULT => -244
	},
	{#State 390
		ACTIONS => {
			'INTEGER' => 124,
			"-" => 429,
			"+" => 430
		},
		DEFAULT => -245,
		GOTOS => {
			'integer' => 428,
			'int_str' => 125,
			'ck_offset' => 431
		}
	},
	{#State 391
		ACTIONS => {
			")" => 432,
			"~" => 395
		}
	},
	{#State 392
		ACTIONS => {
			'KW_FILEID' => 341,
			"(" => 345,
			'KW_DATE' => 348,
			"\@" => 351,
			"\$" => 140,
			'SYMBOL' => 68,
			'KW_FILENAME' => 344,
			'INTEGER' => 55,
			'DATE' => 53,
			'INDEX' => 28,
			"*" => 350
		},
		GOTOS => {
			'count_key' => 433,
			's_index' => 343,
			'index' => 37,
			's_biblname' => 342,
			'symbol' => 326
		}
	},
	{#State 393
		ACTIONS => {
			"]" => 434,
			"," => 392
		}
	},
	{#State 394
		ACTIONS => {
			'INTEGER' => 124
		},
		GOTOS => {
			'int_str' => 125,
			'integer' => 435
		}
	},
	{#State 395
		ACTIONS => {
			'REGEX_SEARCH' => 436
		},
		GOTOS => {
			'replace_regex' => 437
		}
	},
	{#State 396
		DEFAULT => -234
	},
	{#State 397
		ACTIONS => {
			"]" => 438
		}
	},
	{#State 398
		ACTIONS => {
			"]" => 439
		}
	},
	{#State 399
		DEFAULT => -23
	},
	{#State 400
		ACTIONS => {
			"]" => 441,
			"," => 440
		}
	},
	{#State 401
		ACTIONS => {
			'DATE' => 53,
			"]" => 443,
			'INTEGER' => 55,
			'SYMBOL' => 68
		},
		GOTOS => {
			'symbol' => 442
		}
	},
	{#State 402
		ACTIONS => {
			")" => -279
		},
		DEFAULT => -264
	},
	{#State 403
		ACTIONS => {
			"=" => 78,
			"," => 444
		},
		GOTOS => {
			'matchid_eq' => 77,
			'matchid' => 103
		}
	},
	{#State 404
		ACTIONS => {
			")" => 445
		}
	},
	{#State 405
		DEFAULT => -97
	},
	{#State 406
		ACTIONS => {
			"]" => 446
		}
	},
	{#State 407
		DEFAULT => -95
	},
	{#State 408
		DEFAULT => -116
	},
	{#State 409
		DEFAULT => -115
	},
	{#State 410
		ACTIONS => {
			'INTEGER' => 55,
			'DATE' => 53,
			'SYMBOL' => 68
		},
		DEFAULT => -101,
		GOTOS => {
			'symbol' => 447
		}
	},
	{#State 411
		ACTIONS => {
			"," => 448
		},
		DEFAULT => -102
	},
	{#State 412
		DEFAULT => -108
	},
	{#State 413
		DEFAULT => -109
	},
	{#State 414
		ACTIONS => {
			"]" => 449
		}
	},
	{#State 415
		ACTIONS => {
			"]" => 450
		}
	},
	{#State 416
		DEFAULT => -212,
		GOTOS => {
			'l_set' => 451
		}
	},
	{#State 417
		ACTIONS => {
			"]" => 452
		}
	},
	{#State 418
		ACTIONS => {
			"]" => 453
		}
	},
	{#State 419
		ACTIONS => {
			"]" => 454
		}
	},
	{#State 420
		ACTIONS => {
			"]" => 455
		}
	},
	{#State 421
		ACTIONS => {
			"]" => 456
		}
	},
	{#State 422
		DEFAULT => -89
	},
	{#State 423
		DEFAULT => -91
	},
	{#State 424
		DEFAULT => -83
	},
	{#State 425
		DEFAULT => -81
	},
	{#State 426
		DEFAULT => -84
	},
	{#State 427
		DEFAULT => -82
	},
	{#State 428
		DEFAULT => -246
	},
	{#State 429
		ACTIONS => {
			'INTEGER' => 124
		},
		GOTOS => {
			'integer' => 457,
			'int_str' => 125
		}
	},
	{#State 430
		ACTIONS => {
			'INTEGER' => 124
		},
		GOTOS => {
			'integer' => 458,
			'int_str' => 125
		}
	},
	{#State 431
		DEFAULT => -240
	},
	{#State 432
		DEFAULT => -242
	},
	{#State 433
		ACTIONS => {
			"~" => 395
		},
		DEFAULT => -229
	},
	{#State 434
		DEFAULT => -12
	},
	{#State 435
		DEFAULT => -238
	},
	{#State 436
		ACTIONS => {
			'REGEX_REPLACE' => 459
		}
	},
	{#State 437
		DEFAULT => -241
	},
	{#State 438
		DEFAULT => -16
	},
	{#State 439
		DEFAULT => -14
	},
	{#State 440
		ACTIONS => {
			'SYMBOL' => 68,
			"]" => 461,
			'DATE' => 53,
			'INTEGER' => 55
		},
		GOTOS => {
			'symbol' => 460
		}
	},
	{#State 441
		DEFAULT => -25
	},
	{#State 442
		ACTIONS => {
			"]" => 462
		}
	},
	{#State 443
		DEFAULT => -24
	},
	{#State 444
		ACTIONS => {
			'INTEGER' => 124
		},
		GOTOS => {
			'integer' => 463,
			'int_str' => 125
		}
	},
	{#State 445
		DEFAULT => -132
	},
	{#State 446
		DEFAULT => -96
	},
	{#State 447
		DEFAULT => -104
	},
	{#State 448
		ACTIONS => {
			'INTEGER' => 55,
			'DATE' => 53,
			'SYMBOL' => 68
		},
		DEFAULT => -103,
		GOTOS => {
			'symbol' => 464
		}
	},
	{#State 449
		DEFAULT => -56
	},
	{#State 450
		DEFAULT => -58
	},
	{#State 451
		ACTIONS => {
			'SYMBOL' => 68,
			"}" => 465,
			'INTEGER' => 55,
			"," => 147,
			'DATE' => 53
		},
		GOTOS => {
			's_word' => 146,
			'symbol' => 62
		}
	},
	{#State 452
		DEFAULT => -59
	},
	{#State 453
		DEFAULT => -57
	},
	{#State 454
		DEFAULT => -61
	},
	{#State 455
		DEFAULT => -60
	},
	{#State 456
		DEFAULT => -90
	},
	{#State 457
		DEFAULT => -248
	},
	{#State 458
		DEFAULT => -247
	},
	{#State 459
		ACTIONS => {
			'REGOPT' => 466
		},
		DEFAULT => -277
	},
	{#State 460
		ACTIONS => {
			"]" => 467
		}
	},
	{#State 461
		DEFAULT => -26
	},
	{#State 462
		DEFAULT => -27
	},
	{#State 463
		ACTIONS => {
			")" => 468
		}
	},
	{#State 464
		DEFAULT => -105
	},
	{#State 465
		ACTIONS => {
			"]" => 469
		}
	},
	{#State 466
		DEFAULT => -278
	},
	{#State 467
		DEFAULT => -28
	},
	{#State 468
		DEFAULT => -133
	},
	{#State 469
		DEFAULT => -62
	}
],
                                  yyrules  =>
[
	[#Rule 0
		 '$start', 2, undef
	],
	[#Rule 1
		 'query', 1,
sub
#line 106 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->SetQuery($_[1]) }
	],
	[#Rule 2
		 'query', 1,
sub
#line 107 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->SetQuery($_[1]) }
	],
	[#Rule 3
		 'count_query', 6,
sub
#line 114 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newCountQuery($_[3], {%{$_[4]}, %{$_[6]}}) }
	],
	[#Rule 4
		 'count_filters', 0,
sub
#line 119 "lib/DDC/PP/yyqparser.yp"
{ {} }
	],
	[#Rule 5
		 'count_filters', 2,
sub
#line 120 "lib/DDC/PP/yyqparser.yp"
{ my $tmp={%{$_[1]}, %{$_[2]}}; $tmp }
	],
	[#Rule 6
		 'count_filter', 1,
sub
#line 125 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 7
		 'count_filter', 1,
sub
#line 126 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 8
		 'count_filter', 1,
sub
#line 127 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 9
		 'count_filter', 1,
sub
#line 128 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 10
		 'count_filter', 1,
sub
#line 129 "lib/DDC/PP/yyqparser.yp"
{ {}    }
	],
	[#Rule 11
		 'count_by', 2,
sub
#line 133 "lib/DDC/PP/yyqparser.yp"
{ {Keys=>$_[2]} }
	],
	[#Rule 12
		 'count_by', 4,
sub
#line 134 "lib/DDC/PP/yyqparser.yp"
{ {Keys=>$_[3]} }
	],
	[#Rule 13
		 'count_sample', 2,
sub
#line 138 "lib/DDC/PP/yyqparser.yp"
{ {Sample=>$_[2]} }
	],
	[#Rule 14
		 'count_sample', 4,
sub
#line 139 "lib/DDC/PP/yyqparser.yp"
{ {Sample=>$_[3]} }
	],
	[#Rule 15
		 'count_limit', 2,
sub
#line 144 "lib/DDC/PP/yyqparser.yp"
{ {Limit=>$_[2]} }
	],
	[#Rule 16
		 'count_limit', 4,
sub
#line 145 "lib/DDC/PP/yyqparser.yp"
{ {Limit=>$_[3]} }
	],
	[#Rule 17
		 'count_sort', 2,
sub
#line 149 "lib/DDC/PP/yyqparser.yp"
{ $_[2]->{Sort}=$_[1]; $_[2] }
	],
	[#Rule 18
		 'count_sort_op', 1,
sub
#line 153 "lib/DDC/PP/yyqparser.yp"
{ DDC::PP::LessByCountKey }
	],
	[#Rule 19
		 'count_sort_op', 1,
sub
#line 154 "lib/DDC/PP/yyqparser.yp"
{ DDC::PP::GreaterByCountKey }
	],
	[#Rule 20
		 'count_sort_op', 1,
sub
#line 155 "lib/DDC/PP/yyqparser.yp"
{ DDC::PP::LessByCountValue }
	],
	[#Rule 21
		 'count_sort_op', 1,
sub
#line 156 "lib/DDC/PP/yyqparser.yp"
{ DDC::PP::GreaterByCountValue }
	],
	[#Rule 22
		 'count_sort_minmax', 0,
sub
#line 160 "lib/DDC/PP/yyqparser.yp"
{ {} }
	],
	[#Rule 23
		 'count_sort_minmax', 2,
sub
#line 161 "lib/DDC/PP/yyqparser.yp"
{ {} }
	],
	[#Rule 24
		 'count_sort_minmax', 3,
sub
#line 162 "lib/DDC/PP/yyqparser.yp"
{ {} }
	],
	[#Rule 25
		 'count_sort_minmax', 3,
sub
#line 163 "lib/DDC/PP/yyqparser.yp"
{ {Lo=>$_[2]} }
	],
	[#Rule 26
		 'count_sort_minmax', 4,
sub
#line 164 "lib/DDC/PP/yyqparser.yp"
{ {Lo=>$_[2]} }
	],
	[#Rule 27
		 'count_sort_minmax', 4,
sub
#line 165 "lib/DDC/PP/yyqparser.yp"
{ {Hi=>$_[3]} }
	],
	[#Rule 28
		 'count_sort_minmax', 5,
sub
#line 166 "lib/DDC/PP/yyqparser.yp"
{ {Lo=>$_[2],Hi=>$_[4]} }
	],
	[#Rule 29
		 'query_conditions', 2,
sub
#line 173 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 30
		 'q_filters', 0,
sub
#line 179 "lib/DDC/PP/yyqparser.yp"
{ undef }
	],
	[#Rule 31
		 'q_filters', 2,
sub
#line 180 "lib/DDC/PP/yyqparser.yp"
{ undef }
	],
	[#Rule 32
		 'q_filters', 2,
sub
#line 181 "lib/DDC/PP/yyqparser.yp"
{ undef }
	],
	[#Rule 33
		 'q_filters', 2,
sub
#line 182 "lib/DDC/PP/yyqparser.yp"
{ undef }
	],
	[#Rule 34
		 'q_comment', 2,
sub
#line 186 "lib/DDC/PP/yyqparser.yp"
{ push(@{$_[0]->qopts->{Comments}}, $_[2]); undef }
	],
	[#Rule 35
		 'q_comment', 4,
sub
#line 187 "lib/DDC/PP/yyqparser.yp"
{ push(@{$_[0]->qopts->{Comments}}, $_[3]); undef }
	],
	[#Rule 36
		 'q_flag', 2,
sub
#line 191 "lib/DDC/PP/yyqparser.yp"
{ undef }
	],
	[#Rule 37
		 'q_flag', 2,
sub
#line 192 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->qopts->{ContextSentencesCount} = $_[2]; undef }
	],
	[#Rule 38
		 'q_flag', 4,
sub
#line 193 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->qopts->{ContextSentencesCount} = $_[3]; undef }
	],
	[#Rule 39
		 'q_flag', 2,
sub
#line 194 "lib/DDC/PP/yyqparser.yp"
{ push(@{$_[0]->qopts->{Within}}, $_[2]); undef }
	],
	[#Rule 40
		 'q_flag', 1,
sub
#line 195 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->qopts->{SeparateHits} = 1; undef }
	],
	[#Rule 41
		 'q_flag', 1,
sub
#line 196 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->qopts->{SeparateHits} = 0; undef }
	],
	[#Rule 42
		 'q_flag', 1,
sub
#line 197 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->qopts->{EnableBibliography} = 0; undef }
	],
	[#Rule 43
		 'q_flag', 2,
sub
#line 198 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->qopts->{EnableBibliography} = 1; undef }
	],
	[#Rule 44
		 'q_flag', 1,
sub
#line 199 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->qopts->{DebugRank} = 1; undef }
	],
	[#Rule 45
		 'q_flag', 2,
sub
#line 200 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->qopts->{DebugRank} = 0; undef }
	],
	[#Rule 46
		 'qf_subcorpora', 0,
sub
#line 205 "lib/DDC/PP/yyqparser.yp"
{ undef }
	],
	[#Rule 47
		 'qf_subcorpora', 1,
sub
#line 206 "lib/DDC/PP/yyqparser.yp"
{ push(@{$_[0]->qopts->{Subcorpora}}, $_[1]); undef }
	],
	[#Rule 48
		 'qf_subcorpora', 3,
sub
#line 207 "lib/DDC/PP/yyqparser.yp"
{ push(@{$_[0]->qopts->{Subcorpora}}, $_[3]); undef }
	],
	[#Rule 49
		 'q_filter', 1,
sub
#line 211 "lib/DDC/PP/yyqparser.yp"
{ $_[1]; }
	],
	[#Rule 50
		 'q_filter', 1,
sub
#line 212 "lib/DDC/PP/yyqparser.yp"
{ $_[1]; }
	],
	[#Rule 51
		 'q_filter', 1,
sub
#line 213 "lib/DDC/PP/yyqparser.yp"
{ $_[1]; }
	],
	[#Rule 52
		 'q_filter', 1,
sub
#line 214 "lib/DDC/PP/yyqparser.yp"
{ $_[1]; }
	],
	[#Rule 53
		 'q_filter', 1,
sub
#line 215 "lib/DDC/PP/yyqparser.yp"
{ $_[1]; }
	],
	[#Rule 54
		 'q_filter', 1,
sub
#line 216 "lib/DDC/PP/yyqparser.yp"
{ $_[1]; }
	],
	[#Rule 55
		 'q_filter', 1,
sub
#line 217 "lib/DDC/PP/yyqparser.yp"
{ $_[1]; }
	],
	[#Rule 56
		 'qf_has_field', 6,
sub
#line 221 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newf('CQFHasFieldValue', $_[3], $_[5]) }
	],
	[#Rule 57
		 'qf_has_field', 6,
sub
#line 222 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newf('CQFHasFieldRegex', $_[3], $_[5]) }
	],
	[#Rule 58
		 'qf_has_field', 6,
sub
#line 223 "lib/DDC/PP/yyqparser.yp"
{ (my $f=$_[0]->newf('CQFHasFieldRegex', $_[3], $_[5]))->Negate(); $f }
	],
	[#Rule 59
		 'qf_has_field', 6,
sub
#line 224 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newf('CQFHasFieldPrefix', $_[3],$_[5]) }
	],
	[#Rule 60
		 'qf_has_field', 6,
sub
#line 225 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newf('CQFHasFieldSuffix', $_[3],$_[5]) }
	],
	[#Rule 61
		 'qf_has_field', 6,
sub
#line 226 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newf('CQFHasFieldInfix', $_[3],$_[5]) }
	],
	[#Rule 62
		 'qf_has_field', 8,
sub
#line 227 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newf('CQFHasFieldSet', $_[3], $_[6]) }
	],
	[#Rule 63
		 'qf_has_field', 2,
sub
#line 228 "lib/DDC/PP/yyqparser.yp"
{ $_[2]->Negate; $_[2] }
	],
	[#Rule 64
		 'qf_rank_sort', 1,
sub
#line 232 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newf('CQFRankSort', DDC::PP::GreaterByRank) }
	],
	[#Rule 65
		 'qf_rank_sort', 1,
sub
#line 233 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newf('CQFRankSort', DDC::PP::LessByRank) }
	],
	[#Rule 66
		 'qf_context_sort', 2,
sub
#line 237 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newCFilter(DDC::PP::LessByLeftContext,      -1, $_[2]) }
	],
	[#Rule 67
		 'qf_context_sort', 2,
sub
#line 238 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newCFilter(DDC::PP::GreaterByLeftContext,   -1, $_[2]) }
	],
	[#Rule 68
		 'qf_context_sort', 2,
sub
#line 239 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newCFilter(DDC::PP::LessByRightContext,      1, $_[2]) }
	],
	[#Rule 69
		 'qf_context_sort', 2,
sub
#line 240 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newCFilter(DDC::PP::GreaterByRightContext,   1, $_[2]) }
	],
	[#Rule 70
		 'qf_context_sort', 2,
sub
#line 241 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newCFilter(DDC::PP::LessByMiddleContext,     0, $_[2]) }
	],
	[#Rule 71
		 'qf_context_sort', 2,
sub
#line 242 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newCFilter(DDC::PP::GreaterByMiddleContext,  0, $_[2]) }
	],
	[#Rule 72
		 'qf_size_sort', 2,
sub
#line 246 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newf('CQFSizeSort', DDC::PP::LessBySize,    @{$_[2]}) }
	],
	[#Rule 73
		 'qf_size_sort', 2,
sub
#line 247 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newf('CQFSizeSort', DDC::PP::GreaterBySize, @{$_[2]}) }
	],
	[#Rule 74
		 'qf_size_sort', 4,
sub
#line 248 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newf('CQFSizeSort', DDC::PP::LessBySize,    $_[3],$_[3]) }
	],
	[#Rule 75
		 'qf_date_sort', 2,
sub
#line 252 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newf('CQFDateSort', DDC::PP::LessByDate,    @{$_[2]}) }
	],
	[#Rule 76
		 'qf_date_sort', 2,
sub
#line 253 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newf('CQFDateSort', DDC::PP::GreaterByDate, @{$_[2]}) }
	],
	[#Rule 77
		 'qf_date_sort', 4,
sub
#line 254 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newf('CQFDateSort', DDC::PP::LessByDate,    $_[3],$_[3]) }
	],
	[#Rule 78
		 'qf_random_sort', 1,
sub
#line 258 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newf('CQFRandomSort') }
	],
	[#Rule 79
		 'qf_random_sort', 3,
sub
#line 259 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newf('CQFRandomSort') }
	],
	[#Rule 80
		 'qf_random_sort', 4,
sub
#line 260 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newf('CQFRandomSort',$_[3]) }
	],
	[#Rule 81
		 'qf_bibl_sort', 5,
sub
#line 264 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newf('CQFDateSort', DDC::PP::LessByDate,    @{$_[4]}) }
	],
	[#Rule 82
		 'qf_bibl_sort', 5,
sub
#line 265 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newf('CQFDateSort', DDC::PP::GreaterByDate, @{$_[4]}) }
	],
	[#Rule 83
		 'qf_bibl_sort', 5,
sub
#line 266 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newf('CQFBiblSort', DDC::PP::LessByFreeBiblField, $_[3], @{$_[4]}) }
	],
	[#Rule 84
		 'qf_bibl_sort', 5,
sub
#line 267 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newf('CQFBiblSort', DDC::PP::LessByFreeBiblField, $_[3], @{$_[4]}) }
	],
	[#Rule 85
		 'qfb_int', 0,
sub
#line 275 "lib/DDC/PP/yyqparser.yp"
{ [] }
	],
	[#Rule 86
		 'qfb_int', 2,
sub
#line 276 "lib/DDC/PP/yyqparser.yp"
{ [] }
	],
	[#Rule 87
		 'qfb_int', 3,
sub
#line 277 "lib/DDC/PP/yyqparser.yp"
{ [] }
	],
	[#Rule 88
		 'qfb_int', 3,
sub
#line 278 "lib/DDC/PP/yyqparser.yp"
{ [$_[2]] }
	],
	[#Rule 89
		 'qfb_int', 4,
sub
#line 279 "lib/DDC/PP/yyqparser.yp"
{ [$_[2]] }
	],
	[#Rule 90
		 'qfb_int', 5,
sub
#line 280 "lib/DDC/PP/yyqparser.yp"
{ [$_[2],$_[4]] }
	],
	[#Rule 91
		 'qfb_int', 4,
sub
#line 281 "lib/DDC/PP/yyqparser.yp"
{ [undef,$_[3]] }
	],
	[#Rule 92
		 'qfb_date', 0,
sub
#line 286 "lib/DDC/PP/yyqparser.yp"
{ [] }
	],
	[#Rule 93
		 'qfb_date', 2,
sub
#line 287 "lib/DDC/PP/yyqparser.yp"
{ [] }
	],
	[#Rule 94
		 'qfb_date', 3,
sub
#line 288 "lib/DDC/PP/yyqparser.yp"
{ [$_[2]] }
	],
	[#Rule 95
		 'qfb_date', 4,
sub
#line 289 "lib/DDC/PP/yyqparser.yp"
{ [$_[2]] }
	],
	[#Rule 96
		 'qfb_date', 5,
sub
#line 290 "lib/DDC/PP/yyqparser.yp"
{ [$_[2],$_[4]] }
	],
	[#Rule 97
		 'qfb_date', 4,
sub
#line 291 "lib/DDC/PP/yyqparser.yp"
{ [undef,$_[3]] }
	],
	[#Rule 98
		 'qfb_bibl', 0,
sub
#line 296 "lib/DDC/PP/yyqparser.yp"
{ [] }
	],
	[#Rule 99
		 'qfb_bibl', 1,
sub
#line 297 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 100
		 'qfb_bibl_ne', 1,
sub
#line 303 "lib/DDC/PP/yyqparser.yp"
{ [] }
	],
	[#Rule 101
		 'qfb_bibl_ne', 2,
sub
#line 304 "lib/DDC/PP/yyqparser.yp"
{ [] }
	],
	[#Rule 102
		 'qfb_bibl_ne', 2,
sub
#line 305 "lib/DDC/PP/yyqparser.yp"
{ [$_[2]] }
	],
	[#Rule 103
		 'qfb_bibl_ne', 3,
sub
#line 306 "lib/DDC/PP/yyqparser.yp"
{ [$_[2]] }
	],
	[#Rule 104
		 'qfb_bibl_ne', 3,
sub
#line 307 "lib/DDC/PP/yyqparser.yp"
{ [undef,$_[3]] }
	],
	[#Rule 105
		 'qfb_bibl_ne', 4,
sub
#line 308 "lib/DDC/PP/yyqparser.yp"
{ [$_[2],$_[4]] }
	],
	[#Rule 106
		 'qfb_ctxsort', 0,
sub
#line 313 "lib/DDC/PP/yyqparser.yp"
{ [] }
	],
	[#Rule 107
		 'qfb_ctxsort', 3,
sub
#line 314 "lib/DDC/PP/yyqparser.yp"
{ $_[2] }
	],
	[#Rule 108
		 'qfb_ctxsort', 4,
sub
#line 315 "lib/DDC/PP/yyqparser.yp"
{ [@{$_[2]}, @{$_[3]}] }
	],
	[#Rule 109
		 'qfb_ctxkey', 3,
sub
#line 320 "lib/DDC/PP/yyqparser.yp"
{ [$_[1],$_[2],$_[3]] }
	],
	[#Rule 110
		 'qfb_ctxkey', 2,
sub
#line 321 "lib/DDC/PP/yyqparser.yp"
{ [undef,$_[1],$_[2]] }
	],
	[#Rule 111
		 'qfbc_matchref', 0,
sub
#line 326 "lib/DDC/PP/yyqparser.yp"
{ 0 }
	],
	[#Rule 112
		 'qfbc_matchref', 1,
sub
#line 327 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 113
		 'qfbc_offset', 0,
sub
#line 332 "lib/DDC/PP/yyqparser.yp"
{  undef }
	],
	[#Rule 114
		 'qfbc_offset', 1,
sub
#line 333 "lib/DDC/PP/yyqparser.yp"
{  $_[1] }
	],
	[#Rule 115
		 'qfbc_offset', 2,
sub
#line 334 "lib/DDC/PP/yyqparser.yp"
{  $_[2] }
	],
	[#Rule 116
		 'qfbc_offset', 2,
sub
#line 335 "lib/DDC/PP/yyqparser.yp"
{ -$_[2] }
	],
	[#Rule 117
		 'q_clause', 1,
sub
#line 343 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 118
		 'q_clause', 1,
sub
#line 344 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 119
		 'q_clause', 1,
sub
#line 345 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 120
		 'q_clause', 1,
sub
#line 346 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 121
		 'qc_matchid', 2,
sub
#line 350 "lib/DDC/PP/yyqparser.yp"
{ $_[1]->SetMatchId($_[2]); $_[1] }
	],
	[#Rule 122
		 'qc_matchid', 3,
sub
#line 351 "lib/DDC/PP/yyqparser.yp"
{ $_[2] }
	],
	[#Rule 123
		 'qc_boolean', 3,
sub
#line 358 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQAnd', $_[1],$_[3]) }
	],
	[#Rule 124
		 'qc_boolean', 3,
sub
#line 359 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQOr', $_[1],$_[3]) }
	],
	[#Rule 125
		 'qc_boolean', 2,
sub
#line 360 "lib/DDC/PP/yyqparser.yp"
{ $_[2]->Negate; $_[2] }
	],
	[#Rule 126
		 'qc_boolean', 3,
sub
#line 361 "lib/DDC/PP/yyqparser.yp"
{ $_[2] }
	],
	[#Rule 127
		 'qc_concat', 2,
sub
#line 367 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQAndImplicit', $_[1],$_[2]) }
	],
	[#Rule 128
		 'qc_concat', 2,
sub
#line 368 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQAndImplicit', $_[1],$_[2]) }
	],
	[#Rule 129
		 'qc_concat', 3,
sub
#line 369 "lib/DDC/PP/yyqparser.yp"
{ $_[2] }
	],
	[#Rule 130
		 'qc_basic', 1,
sub
#line 377 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 131
		 'qc_basic', 1,
sub
#line 378 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 132
		 'qc_near', 8,
sub
#line 382 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQNear', $_[7],$_[3],$_[5]) }
	],
	[#Rule 133
		 'qc_near', 10,
sub
#line 383 "lib/DDC/PP/yyqparser.yp"
{  $_[0]->newq('CQNear', $_[9],$_[3],$_[5],$_[7]) }
	],
	[#Rule 134
		 'qc_near', 2,
sub
#line 384 "lib/DDC/PP/yyqparser.yp"
{ $_[1]->SetMatchId($_[2]); $_[1] }
	],
	[#Rule 135
		 'qc_near', 3,
sub
#line 385 "lib/DDC/PP/yyqparser.yp"
{ $_[2] }
	],
	[#Rule 136
		 'qc_tokens', 1,
sub
#line 393 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 137
		 'qc_tokens', 1,
sub
#line 394 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 138
		 'qc_tokens', 2,
sub
#line 395 "lib/DDC/PP/yyqparser.yp"
{ $_[1]->SetMatchId($_[2]); $_[1] }
	],
	[#Rule 139
		 'qc_phrase', 3,
sub
#line 399 "lib/DDC/PP/yyqparser.yp"
{ $_[2] }
	],
	[#Rule 140
		 'qc_phrase', 3,
sub
#line 400 "lib/DDC/PP/yyqparser.yp"
{ $_[2] }
	],
	[#Rule 141
		 'qc_word', 1,
sub
#line 408 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 142
		 'qc_word', 1,
sub
#line 409 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 143
		 'qc_word', 1,
sub
#line 410 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 144
		 'qc_word', 1,
sub
#line 411 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 145
		 'qc_word', 1,
sub
#line 412 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 146
		 'qc_word', 1,
sub
#line 413 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 147
		 'qc_word', 1,
sub
#line 414 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 148
		 'qc_word', 1,
sub
#line 415 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 149
		 'qc_word', 1,
sub
#line 416 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 150
		 'qc_word', 1,
sub
#line 417 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 151
		 'qc_word', 1,
sub
#line 418 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 152
		 'qc_word', 1,
sub
#line 419 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 153
		 'qc_word', 1,
sub
#line 420 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 154
		 'qc_word', 1,
sub
#line 421 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 155
		 'qc_word', 1,
sub
#line 422 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 156
		 'qc_word', 1,
sub
#line 423 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 157
		 'qc_word', 1,
sub
#line 424 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 158
		 'qc_word', 1,
sub
#line 425 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 159
		 'qc_word', 1,
sub
#line 426 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 160
		 'qc_word', 1,
sub
#line 427 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 161
		 'qc_word', 1,
sub
#line 428 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 162
		 'qc_word', 1,
sub
#line 429 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 163
		 'qc_word', 1,
sub
#line 430 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 164
		 'qc_word', 3,
sub
#line 431 "lib/DDC/PP/yyqparser.yp"
{ $_[2] }
	],
	[#Rule 165
		 'qw_bareword', 2,
sub
#line 435 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokInfl', "", $_[1], $_[2]) }
	],
	[#Rule 166
		 'qw_bareword', 4,
sub
#line 436 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokInfl', $_[1], $_[3], $_[4]) }
	],
	[#Rule 167
		 'qw_exact', 2,
sub
#line 440 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokExact', "", $_[2]) }
	],
	[#Rule 168
		 'qw_exact', 4,
sub
#line 441 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokExact', $_[1], $_[4]) }
	],
	[#Rule 169
		 'qw_regex', 1,
sub
#line 445 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokRegex', "",   $_[1]) }
	],
	[#Rule 170
		 'qw_regex', 3,
sub
#line 446 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokRegex', $_[1],$_[3]) }
	],
	[#Rule 171
		 'qw_regex', 1,
sub
#line 447 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokRegex', "",    $_[1], 1) }
	],
	[#Rule 172
		 'qw_regex', 3,
sub
#line 448 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokRegex', $_[1], $_[3], 1) }
	],
	[#Rule 173
		 'qw_any', 1,
sub
#line 452 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokAny') }
	],
	[#Rule 174
		 'qw_any', 3,
sub
#line 453 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokAny',$_[1]) }
	],
	[#Rule 175
		 'qw_set_exact', 3,
sub
#line 457 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokSet', "",    undef, $_[2]) }
	],
	[#Rule 176
		 'qw_set_exact', 5,
sub
#line 458 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokSet', $_[1], undef, $_[2]) }
	],
	[#Rule 177
		 'qw_set_infl', 4,
sub
#line 462 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokSetInfl', "",    $_[2], $_[4]) }
	],
	[#Rule 178
		 'qw_set_infl', 6,
sub
#line 463 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokSetInfl', $_[1], $_[4], $_[6]) }
	],
	[#Rule 179
		 'qw_prefix', 1,
sub
#line 467 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokPrefix', "",    $_[1]) }
	],
	[#Rule 180
		 'qw_prefix', 3,
sub
#line 468 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokPrefix', $_[1], $_[3]) }
	],
	[#Rule 181
		 'qw_suffix', 1,
sub
#line 472 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokSuffix', "",    $_[1]) }
	],
	[#Rule 182
		 'qw_suffix', 3,
sub
#line 473 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokSuffix', $_[1], $_[3]) }
	],
	[#Rule 183
		 'qw_infix', 1,
sub
#line 477 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokInfix', "",    $_[1]) }
	],
	[#Rule 184
		 'qw_infix', 3,
sub
#line 478 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokInfix', $_[1], $_[3]) }
	],
	[#Rule 185
		 'qw_infix_set', 3,
sub
#line 482 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokInfixSet', "", $_[2]) }
	],
	[#Rule 186
		 'qw_infix_set', 5,
sub
#line 483 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokInfixSet', $_[1], $_[4]) }
	],
	[#Rule 187
		 'qw_prefix_set', 3,
sub
#line 487 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokPrefixSet',"", $_[2]) }
	],
	[#Rule 188
		 'qw_prefix_set', 5,
sub
#line 488 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokPrefixSet',$_[1], $_[4]) }
	],
	[#Rule 189
		 'qw_suffix_set', 3,
sub
#line 492 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokSuffixSet',"", $_[2]) }
	],
	[#Rule 190
		 'qw_suffix_set', 5,
sub
#line 493 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokSuffixSet',$_[1], $_[4]) }
	],
	[#Rule 191
		 'qw_thesaurus', 3,
sub
#line 497 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokThes', "Thes",$_[2]) }
	],
	[#Rule 192
		 'qw_thesaurus', 6,
sub
#line 498 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokThes', $_[1], $_[5]) }
	],
	[#Rule 193
		 'qw_morph', 3,
sub
#line 502 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokMorph', "MorphPattern", $_[2]) }
	],
	[#Rule 194
		 'qw_morph', 5,
sub
#line 503 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokMorph', $_[1], $_[4]) }
	],
	[#Rule 195
		 'qw_lemma', 2,
sub
#line 507 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokLemma', "Lemma", $_[2]) }
	],
	[#Rule 196
		 'qw_lemma', 4,
sub
#line 508 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokLemma', $_[1], $_[4]) }
	],
	[#Rule 197
		 'qw_chunk', 2,
sub
#line 512 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokChunk', "", $_[2]) }
	],
	[#Rule 198
		 'qw_chunk', 4,
sub
#line 513 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokChunk', $_[1], $_[4]) }
	],
	[#Rule 199
		 'qw_anchor', 3,
sub
#line 517 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokAnchor', "",    $_[3]) }
	],
	[#Rule 200
		 'qw_anchor', 4,
sub
#line 518 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokAnchor', $_[2], $_[4]) }
	],
	[#Rule 201
		 'qw_listfile', 2,
sub
#line 522 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokFile', "",    $_[2]) }
	],
	[#Rule 202
		 'qw_listfile', 4,
sub
#line 523 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokFile', $_[1], $_[4]) }
	],
	[#Rule 203
		 'qw_with', 3,
sub
#line 527 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQWith', $_[1],$_[3]) }
	],
	[#Rule 204
		 'qw_without', 3,
sub
#line 531 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQWithout', $_[1],$_[3]) }
	],
	[#Rule 205
		 'qw_withor', 3,
sub
#line 535 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQWithor', $_[1],$_[3]) }
	],
	[#Rule 206
		 'qw_keys', 4,
sub
#line 539 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newKeysQuery($_[3][0], $_[3][1]); }
	],
	[#Rule 207
		 'qw_keys', 6,
sub
#line 540 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newKeysQuery($_[5][0], $_[5][1], $_[1]); }
	],
	[#Rule 208
		 'qwk_indextuple', 4,
sub
#line 544 "lib/DDC/PP/yyqparser.yp"
{ $_[3] }
	],
	[#Rule 209
		 'qwk_countsrc', 1,
sub
#line 549 "lib/DDC/PP/yyqparser.yp"
{ [$_[1], {}] }
	],
	[#Rule 210
		 'qwk_countsrc', 2,
sub
#line 550 "lib/DDC/PP/yyqparser.yp"
{ [$_[0]->newCountQuery($_[1], $_[2]), $_[2]] }
	],
	[#Rule 211
		 'qw_matchid', 2,
sub
#line 554 "lib/DDC/PP/yyqparser.yp"
{ $_[1]->SetMatchId($_[2]); $_[1] }
	],
	[#Rule 212
		 'l_set', 0,
sub
#line 562 "lib/DDC/PP/yyqparser.yp"
{ [] }
	],
	[#Rule 213
		 'l_set', 2,
sub
#line 563 "lib/DDC/PP/yyqparser.yp"
{ push(@{$_[1]}, $_[2]); $_[1] }
	],
	[#Rule 214
		 'l_set', 2,
sub
#line 564 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 215
		 'l_morph', 0,
sub
#line 569 "lib/DDC/PP/yyqparser.yp"
{ [] }
	],
	[#Rule 216
		 'l_morph', 2,
sub
#line 570 "lib/DDC/PP/yyqparser.yp"
{ push(@{$_[1]}, $_[2]); $_[1] }
	],
	[#Rule 217
		 'l_morph', 2,
sub
#line 571 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 218
		 'l_morph', 2,
sub
#line 572 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 219
		 'l_phrase', 1,
sub
#line 576 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQSeq', [$_[1]]) }
	],
	[#Rule 220
		 'l_phrase', 2,
sub
#line 577 "lib/DDC/PP/yyqparser.yp"
{ $_[1]->Append($_[2]); $_[1] }
	],
	[#Rule 221
		 'l_phrase', 4,
sub
#line 578 "lib/DDC/PP/yyqparser.yp"
{ $_[1]->Append($_[4], $_[3]); $_[1] }
	],
	[#Rule 222
		 'l_phrase', 4,
sub
#line 579 "lib/DDC/PP/yyqparser.yp"
{ $_[1]->Append($_[4], $_[3], '<'); $_[1] }
	],
	[#Rule 223
		 'l_phrase', 4,
sub
#line 580 "lib/DDC/PP/yyqparser.yp"
{ $_[1]->Append($_[4], $_[3], '>'); $_[1] }
	],
	[#Rule 224
		 'l_phrase', 4,
sub
#line 581 "lib/DDC/PP/yyqparser.yp"
{ $_[1]->Append($_[4], $_[3], '='); $_[1] }
	],
	[#Rule 225
		 'l_txchain', 0,
sub
#line 585 "lib/DDC/PP/yyqparser.yp"
{ []; }
	],
	[#Rule 226
		 'l_txchain', 2,
sub
#line 586 "lib/DDC/PP/yyqparser.yp"
{ push(@{$_[1]}, $_[2]); $_[1] }
	],
	[#Rule 227
		 'l_countkeys', 0,
sub
#line 591 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQCountKeyExprList') }
	],
	[#Rule 228
		 'l_countkeys', 1,
sub
#line 592 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQCountKeyExprList', Exprs=>[$_[1]]) }
	],
	[#Rule 229
		 'l_countkeys', 3,
sub
#line 593 "lib/DDC/PP/yyqparser.yp"
{ $_[1]->PushKey($_[3]); $_[1] }
	],
	[#Rule 230
		 'l_indextuple', 0,
sub
#line 597 "lib/DDC/PP/yyqparser.yp"
{ [] }
	],
	[#Rule 231
		 'l_indextuple', 1,
sub
#line 598 "lib/DDC/PP/yyqparser.yp"
{ [$_[1]] }
	],
	[#Rule 232
		 'l_indextuple', 3,
sub
#line 599 "lib/DDC/PP/yyqparser.yp"
{ push(@{$_[1]},$_[3]); $_[1] }
	],
	[#Rule 233
		 'count_key', 1,
sub
#line 606 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQCountKeyExprConstant', "*") }
	],
	[#Rule 234
		 'count_key', 2,
sub
#line 607 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQCountKeyExprConstant', $_[2]) }
	],
	[#Rule 235
		 'count_key', 1,
sub
#line 608 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQCountKeyExprFileId', $_[1]) }
	],
	[#Rule 236
		 'count_key', 1,
sub
#line 609 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQCountKeyExprFileName', $_[1]) }
	],
	[#Rule 237
		 'count_key', 1,
sub
#line 610 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQCountKeyExprDate', $_[1]) }
	],
	[#Rule 238
		 'count_key', 3,
sub
#line 611 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQCountKeyExprDateSlice', $_[1],$_[3]) }
	],
	[#Rule 239
		 'count_key', 1,
sub
#line 612 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQCountKeyExprBibl', $_[1]) }
	],
	[#Rule 240
		 'count_key', 3,
sub
#line 613 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQCountKeyExprToken', $_[1],$_[2],$_[3]) }
	],
	[#Rule 241
		 'count_key', 3,
sub
#line 614 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQCountKeyExprRegex', $_[1],@{$_[3]}) }
	],
	[#Rule 242
		 'count_key', 3,
sub
#line 615 "lib/DDC/PP/yyqparser.yp"
{ $_[2]; }
	],
	[#Rule 243
		 'ck_matchid', 0,
sub
#line 619 "lib/DDC/PP/yyqparser.yp"
{     0 }
	],
	[#Rule 244
		 'ck_matchid', 1,
sub
#line 620 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 245
		 'ck_offset', 0,
sub
#line 624 "lib/DDC/PP/yyqparser.yp"
{      0 }
	],
	[#Rule 246
		 'ck_offset', 1,
sub
#line 625 "lib/DDC/PP/yyqparser.yp"
{  $_[1] }
	],
	[#Rule 247
		 'ck_offset', 2,
sub
#line 626 "lib/DDC/PP/yyqparser.yp"
{  $_[2] }
	],
	[#Rule 248
		 'ck_offset', 2,
sub
#line 627 "lib/DDC/PP/yyqparser.yp"
{ -$_[2] }
	],
	[#Rule 249
		 's_index', 1,
sub
#line 635 "lib/DDC/PP/yyqparser.yp"
{ '' }
	],
	[#Rule 250
		 's_index', 1,
sub
#line 636 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 251
		 's_indextuple_item', 1,
sub
#line 640 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 252
		 's_indextuple_item', 1,
sub
#line 641 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 253
		 's_word', 1,
sub
#line 644 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 254
		 's_semclass', 1,
sub
#line 645 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 255
		 's_lemma', 1,
sub
#line 646 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 256
		 's_chunk', 1,
sub
#line 647 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 257
		 's_filename', 1,
sub
#line 648 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 258
		 's_morphitem', 1,
sub
#line 649 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 259
		 's_subcorpus', 1,
sub
#line 650 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 260
		 's_biblname', 1,
sub
#line 651 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 261
		 's_breakname', 1,
sub
#line 653 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 262
		 's_breakname', 1,
sub
#line 654 "lib/DDC/PP/yyqparser.yp"
{ "file" }
	],
	[#Rule 263
		 'symbol', 1,
sub
#line 662 "lib/DDC/PP/yyqparser.yp"
{ unescape($_[1]) }
	],
	[#Rule 264
		 'symbol', 1,
sub
#line 663 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 265
		 'symbol', 1,
sub
#line 664 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 266
		 'index', 1,
sub
#line 668 "lib/DDC/PP/yyqparser.yp"
{ '' }
	],
	[#Rule 267
		 'index', 1,
sub
#line 669 "lib/DDC/PP/yyqparser.yp"
{ unescape($_[1]) }
	],
	[#Rule 268
		 'sym_str', 1,
sub
#line 672 "lib/DDC/PP/yyqparser.yp"
{ unescape($_[1]) }
	],
	[#Rule 269
		 's_prefix', 1,
sub
#line 674 "lib/DDC/PP/yyqparser.yp"
{ unescape($_[1]) }
	],
	[#Rule 270
		 's_suffix', 1,
sub
#line 675 "lib/DDC/PP/yyqparser.yp"
{ unescape($_[1]) }
	],
	[#Rule 271
		 's_infix', 1,
sub
#line 676 "lib/DDC/PP/yyqparser.yp"
{ unescape($_[1]) }
	],
	[#Rule 272
		 's_expander', 1,
sub
#line 678 "lib/DDC/PP/yyqparser.yp"
{ unescape($_[1]) }
	],
	[#Rule 273
		 'regex', 1,
sub
#line 681 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newre($_[1]) }
	],
	[#Rule 274
		 'regex', 2,
sub
#line 682 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newre($_[1],$_[2]) }
	],
	[#Rule 275
		 'neg_regex', 1,
sub
#line 686 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newre($_[1]) }
	],
	[#Rule 276
		 'neg_regex', 2,
sub
#line 687 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newre($_[1],$_[2]) }
	],
	[#Rule 277
		 'replace_regex', 2,
sub
#line 691 "lib/DDC/PP/yyqparser.yp"
{ [$_[1],$_[2],''] }
	],
	[#Rule 278
		 'replace_regex', 3,
sub
#line 692 "lib/DDC/PP/yyqparser.yp"
{ [$_[1],$_[2],$_[3]] }
	],
	[#Rule 279
		 'int_str', 1,
sub
#line 695 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 280
		 'integer', 1,
sub
#line 697 "lib/DDC/PP/yyqparser.yp"
{ no warnings 'numeric'; ($_[1]+0) }
	],
	[#Rule 281
		 'date', 1,
sub
#line 700 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 282
		 'date', 1,
sub
#line 701 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 283
		 'matchid', 2,
sub
#line 704 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->yybegin('INITIAL'); $_[2] }
	],
	[#Rule 284
		 'matchid_eq', 1,
sub
#line 706 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->yybegin('Q_MATCHID'); $_[1] }
	]
],
                                  @_);
    bless($self,$class);
}

#line 708 "lib/DDC/PP/yyqparser.yp"

##############################################################
# Footer Section
###############################################################

package DDC::PP::yyqparser;
#require Exporter;

## $q = $yyqparser->newq($querySubclass, @queryArgs)
##  + just wraps DDC::PP::CQueryCompiler::newq
sub newq {
  return $_[0]{USER}{qc}->newq(@_[1..$#_]);
}

## $qf = $yyqparser->newf($filterSubclass, @filterArgs)
##  + wraps DDC::PP::CQueryCompiler::newf and pushes filter onto current options' filter-list
sub newf {
  my $f = $_[0]{USER}{qc}->newf(@_[1..$#_]);
  push(@{$_[0]->qopts->{Filters}}, $f);
  return $f;
}

## $cf = $yyqparser->newCFilter($filterSortType, $defaultOffset, \@args)
sub newCFilter {
  my ($qp,$type,$off,$args) = @_;
  #print STDERR "newCFilter: ", Data::Dumper->Dump([@_[1..$#_]]), "\n"; ##-- DEBUG
  $args->[2] = $off if (!defined($args->[2]));
  return $qp->newf('CQFContextSort', $type, @$args);
}

## $qc = $yyqparser->newCountQuery($qSrc, \%qcOpts)
sub newCountQuery {
  my ($qp,$qsrc,$qcopts) = @_;
  $qp->SetQuery($qsrc);
  my $qc = $qp->newq('CQCount', $qsrc);
  foreach my $key (keys %{$qcopts||{}}) {
    $qc->can("set$key")->($qc, $qcopts->{$key}) if ($qc->can("set$key"));
  }
  return $qc;
}

## $qk = $yyqparser->newKeysQuery($qCount, \%qcOpts, $indexTuple)
sub newKeysQuery {
  my ($qp,$qcount,$qcopts,$ituple) = @_;
  return $qp->newq('CQKeys', $qcount, ($qcopts||{})->{Limit}, $ituple);
}

## $re = $yyqparser->newre($regex, $regopt)
##  + wraps DDC::PP::CQueryCompiler::newre
sub newre {
  return $_[0]{USER}{qc}->newre(@_[1..$#_]);
}

## $qo = $yyqparser->qopts()
##  + just wraps DDC::PP::CQueryCompiler::qopts()
sub qopts {
  return $_[0]{USER}{qc}->qopts(@_[1..$#_])
}

## $q = $yyqparser->SetQuery($q)
##  + sets compiler query and assigns its options
sub SetQuery {
  $_[1]->setOptions($_[0]->qopts) if ($_[1]);
  $_[0]->qopts(DDC::PP::CQueryOptions->new);
  $_[0]{USER}{qc}->setQuery($_[1]);
}

## undef = $yyqparser->yycarp($message_template,\%macros)
sub yycarp {
  die($_[0]{USER}{qc}->setError(@_[1..$#_]));
}

## undef = $yyqparser->yybegin($q)
sub yybegin {
  $_[0]{USER}{qc}{lexer}{state} = $_[1];
}

### $esc = $yyqparser->unescape($sym)
###  + wraps DDC::Query::Parser::unescape($sym)
#sub unescape {
#  return $_[0]{USER}{qc}->unescape($_[1]);
#}

1; ##-- be happy

__END__

##========================================================================
## POD DOCUMENTATION, auto-generated by podextract.perl

##========================================================================
## NAME
=pod

=head1 NAME

DDC::PP::yyqparser - low-level Parse::Yapp parser for DDC::Query::Parser [DEPRECATED]

=cut

##========================================================================
## SYNOPSIS
=pod

=head1 SYNOPSIS

 use DDC::PP::yyqparser;

 $q = $yyqparser->newQuery($querySubclass, %queryArgs);
 undef = $yyqparser->yycarp($message_template,\%macros);

 ##... (any Parse::Yapp method) ...

=cut

##========================================================================
## DESCRIPTION
=pod

=head1 DESCRIPTION

B<Caveat Programmor>:
This module is auto-generated with Parse::Yapp.
Do I<NOT> change yyqparser.pm directly, change yyqparser.yp instead!

Use of this module is deprecated in favor of the L<DDC::XS::CQueryCompiler|DDC::XS::CQueryCompiler>
module providing direct access to the underlying C++ libraries.

=cut

##----------------------------------------------------------------
## DESCRIPTION: DDC::PP::yyqparser
=pod

=over 4

=item show_hint

(undocumented)

=item new

(undocumented)

=item newQuery

 $q = $yyqparser->newQuery($querySubclass, %queryArgs);

Just wraps DDC::newQuery.

=item yycarp

 undef = $yyqparser->yycarp($message_template,\%macros);

Error reporting subroutine.

=back

=cut

##========================================================================
## END POD DOCUMENTATION, auto-generated by podextract.perl

##======================================================================
## Footer
##======================================================================

=pod

=head1 ACKNOWLEDGEMENTS

Perl by Larry Wall.


=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011-2017 by Bryan Jurish

This package is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 SEE ALSO

perl(1),
DDC::PP(3perl),
DDC::PP::CQueryCompiler(3perl),
DDC::PP::yyqlexer(3perl).

=cut

1;
