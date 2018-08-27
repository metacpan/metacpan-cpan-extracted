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
			'AT_LBRACE' => 37,
			'KEYS' => 71,
			"!" => 18,
			"(" => 56,
			'SYMBOL' => 11,
			'INDEX' => 12,
			'PREFIX' => 33,
			'REGEX' => 14,
			"[" => 13,
			"\"" => 30,
			'DATE' => 69,
			'SUFFIX' => 31,
			'STAR_LBRACE' => 29,
			"%" => 51,
			"{" => 24,
			'COLON_LBRACE' => 47,
			"<" => 65,
			'COUNT' => 61,
			"*" => 44,
			"\$" => 23,
			"\@" => 45,
			'NEAR' => 60,
			'INTEGER' => 42,
			'INFIX' => 59,
			'NEG_REGEX' => 39,
			"^" => 1,
			'DOLLAR_DOT' => 20
		},
		GOTOS => {
			'count_query' => 55,
			'qw_without' => 17,
			'qw_bareword' => 57,
			'qw_set_exact' => 16,
			'qw_prefix' => 15,
			'qw_suffix_set' => 54,
			'regex' => 52,
			'qw_morph' => 53,
			'qw_infix_set' => 10,
			'qw_prefix_set' => 9,
			'qc_tokens' => 50,
			'qc_concat' => 49,
			'query_conditions' => 48,
			'qw_infix' => 8,
			'qwk_indextuple' => 7,
			'qw_suffix' => 46,
			's_infix' => 5,
			'qw_chunk' => 6,
			'qw_with' => 3,
			'symbol' => 4,
			'qw_any' => 2,
			'qc_near' => 43,
			'qw_regex' => 40,
			'qw_anchor' => 41,
			'q_clause' => 38,
			'qc_basic' => 72,
			'qw_matchid' => 70,
			'neg_regex' => 36,
			'qw_listfile' => 32,
			'query' => 34,
			's_word' => 35,
			'qc_phrase' => 67,
			'qw_exact' => 68,
			'qw_keys' => 66,
			's_suffix' => 28,
			's_index' => 25,
			'qw_set_infl' => 27,
			'qc_boolean' => 26,
			'index' => 63,
			'qw_lemma' => 64,
			'qw_withor' => 62,
			'qc_word' => 22,
			's_prefix' => 58,
			'qw_thesaurus' => 21,
			'qc_matchid' => 19
		}
	},
	{#State 1
		ACTIONS => {
			'INTEGER' => 42,
			'DATE' => 69,
			'SYMBOL' => 11
		},
		GOTOS => {
			'symbol' => 73,
			's_chunk' => 74
		}
	},
	{#State 2
		DEFAULT => -144
	},
	{#State 3
		DEFAULT => -159
	},
	{#State 4
		DEFAULT => -253
	},
	{#State 5
		DEFAULT => -183
	},
	{#State 6
		DEFAULT => -156
	},
	{#State 7
		ACTIONS => {
			"=" => 75
		}
	},
	{#State 8
		DEFAULT => -147
	},
	{#State 9
		DEFAULT => -150
	},
	{#State 10
		DEFAULT => -148
	},
	{#State 11
		DEFAULT => -263
	},
	{#State 12
		DEFAULT => -267
	},
	{#State 13
		DEFAULT => -215,
		GOTOS => {
			'l_morph' => 76
		}
	},
	{#State 14
		ACTIONS => {
			'REGOPT' => 77
		},
		DEFAULT => -273
	},
	{#State 15
		DEFAULT => -149
	},
	{#State 16
		DEFAULT => -146
	},
	{#State 17
		DEFAULT => -160
	},
	{#State 18
		ACTIONS => {
			"\"" => 30,
			'DATE' => 69,
			'SUFFIX' => 31,
			'STAR_LBRACE' => 29,
			"%" => 51,
			'KEYS' => 71,
			'AT_LBRACE' => 37,
			"!" => 18,
			"(" => 56,
			'PREFIX' => 33,
			'INDEX' => 12,
			'SYMBOL' => 11,
			"[" => 13,
			'REGEX' => 14,
			'NEAR' => 60,
			'INFIX' => 59,
			'INTEGER' => 42,
			'NEG_REGEX' => 39,
			"^" => 1,
			'DOLLAR_DOT' => 20,
			"{" => 24,
			"<" => 65,
			'COLON_LBRACE' => 47,
			"*" => 44,
			"\$" => 23,
			"\@" => 45
		},
		GOTOS => {
			'qc_boolean' => 26,
			'qw_set_infl' => 27,
			's_index' => 25,
			'index' => 63,
			'qw_lemma' => 64,
			'qw_withor' => 62,
			'qc_word' => 22,
			's_prefix' => 58,
			'qw_thesaurus' => 21,
			'qc_matchid' => 19,
			'qc_basic' => 72,
			'q_clause' => 78,
			'qw_matchid' => 70,
			'neg_regex' => 36,
			's_word' => 35,
			'qw_listfile' => 32,
			'qw_exact' => 68,
			'qc_phrase' => 67,
			's_suffix' => 28,
			'qw_keys' => 66,
			'qw_infix' => 8,
			'qwk_indextuple' => 7,
			'qw_suffix' => 46,
			'qw_chunk' => 6,
			's_infix' => 5,
			'symbol' => 4,
			'qw_with' => 3,
			'qc_near' => 43,
			'qw_any' => 2,
			'qw_regex' => 40,
			'qw_anchor' => 41,
			'qw_bareword' => 57,
			'qw_without' => 17,
			'qw_set_exact' => 16,
			'qw_prefix' => 15,
			'qw_suffix_set' => 54,
			'qw_morph' => 53,
			'qw_infix_set' => 10,
			'regex' => 52,
			'qw_prefix_set' => 9,
			'qc_tokens' => 50,
			'qc_concat' => 49
		}
	},
	{#State 19
		DEFAULT => -120
	},
	{#State 20
		ACTIONS => {
			'SYMBOL' => 11,
			"=" => 80,
			'INTEGER' => 42,
			'DATE' => 69
		},
		GOTOS => {
			'symbol' => 79
		}
	},
	{#State 21
		DEFAULT => -153
	},
	{#State 22
		ACTIONS => {
			'WITH' => 83,
			'WITHOUT' => 81,
			"=" => 86,
			'WITHOR' => 85
		},
		DEFAULT => -136,
		GOTOS => {
			'matchid_eq' => 84,
			'matchid' => 82
		}
	},
	{#State 23
		ACTIONS => {
			"(" => 87
		},
		DEFAULT => -249
	},
	{#State 24
		DEFAULT => -212,
		GOTOS => {
			'l_set' => 88
		}
	},
	{#State 25
		ACTIONS => {
			"=" => 89
		}
	},
	{#State 26
		DEFAULT => -118
	},
	{#State 27
		DEFAULT => -145
	},
	{#State 28
		DEFAULT => -181
	},
	{#State 29
		DEFAULT => -212,
		GOTOS => {
			'l_set' => 90
		}
	},
	{#State 30
		ACTIONS => {
			'DOLLAR_DOT' => 20,
			'NEG_REGEX' => 39,
			"^" => 1,
			'INTEGER' => 42,
			'INFIX' => 59,
			"\@" => 45,
			"\$" => 23,
			"*" => 44,
			"<" => 65,
			'COLON_LBRACE' => 47,
			"{" => 24,
			"%" => 51,
			'STAR_LBRACE' => 29,
			'SUFFIX' => 31,
			'DATE' => 69,
			'REGEX' => 14,
			"[" => 13,
			'PREFIX' => 33,
			'SYMBOL' => 11,
			'INDEX' => 12,
			"(" => 91,
			'AT_LBRACE' => 37,
			'KEYS' => 71
		},
		GOTOS => {
			'qw_exact' => 68,
			'qw_keys' => 66,
			's_suffix' => 28,
			'neg_regex' => 36,
			'qw_matchid' => 70,
			'qw_listfile' => 32,
			's_word' => 35,
			'qc_word' => 92,
			's_prefix' => 58,
			'qw_thesaurus' => 21,
			's_index' => 25,
			'qw_set_infl' => 27,
			'index' => 63,
			'qw_lemma' => 64,
			'qw_withor' => 62,
			'regex' => 52,
			'qw_infix_set' => 10,
			'qw_morph' => 53,
			'qw_prefix_set' => 9,
			'l_phrase' => 93,
			'qw_without' => 17,
			'qw_bareword' => 57,
			'qw_set_exact' => 16,
			'qw_prefix' => 15,
			'qw_suffix_set' => 54,
			'qw_with' => 3,
			'symbol' => 4,
			'qw_any' => 2,
			'qw_regex' => 40,
			'qw_anchor' => 41,
			'qw_infix' => 8,
			'qwk_indextuple' => 7,
			'qw_suffix' => 46,
			'qw_chunk' => 6,
			's_infix' => 5
		}
	},
	{#State 31
		DEFAULT => -270
	},
	{#State 32
		DEFAULT => -158
	},
	{#State 33
		DEFAULT => -269
	},
	{#State 34
		ACTIONS => {
			'' => 94
		}
	},
	{#State 35
		DEFAULT => -225,
		GOTOS => {
			'l_txchain' => 95
		}
	},
	{#State 36
		DEFAULT => -171
	},
	{#State 37
		DEFAULT => -212,
		GOTOS => {
			'l_set' => 96
		}
	},
	{#State 38
		ACTIONS => {
			'OP_BOOL_AND' => 97,
			"=" => 86,
			'OP_BOOL_OR' => 98
		},
		DEFAULT => -30,
		GOTOS => {
			'matchid_eq' => 84,
			'q_filters' => 99,
			'matchid' => 100
		}
	},
	{#State 39
		ACTIONS => {
			'REGOPT' => 101
		},
		DEFAULT => -275
	},
	{#State 40
		DEFAULT => -143
	},
	{#State 41
		DEFAULT => -157
	},
	{#State 42
		DEFAULT => -264
	},
	{#State 43
		ACTIONS => {
			"=" => 86
		},
		DEFAULT => -131,
		GOTOS => {
			'matchid' => 102,
			'matchid_eq' => 84
		}
	},
	{#State 44
		DEFAULT => -173
	},
	{#State 45
		ACTIONS => {
			'SYMBOL' => 11,
			'INTEGER' => 42,
			'DATE' => 69
		},
		GOTOS => {
			'symbol' => 4,
			's_word' => 103
		}
	},
	{#State 46
		DEFAULT => -151
	},
	{#State 47
		ACTIONS => {
			'INTEGER' => 42,
			'DATE' => 69,
			'SYMBOL' => 11
		},
		GOTOS => {
			's_semclass' => 104,
			'symbol' => 105
		}
	},
	{#State 48
		DEFAULT => -1
	},
	{#State 49
		ACTIONS => {
			"<" => 65,
			'NEAR' => 60,
			'INFIX' => 59,
			'KEYS' => 71,
			'DATE' => 69,
			"\@" => 45,
			"*" => 44,
			'COLON_LBRACE' => 47,
			'NEG_REGEX' => 39,
			'INTEGER' => 42,
			"(" => 106,
			"%" => 51,
			"\$" => 23,
			"{" => 24,
			'DOLLAR_DOT' => 20,
			'PREFIX' => 33,
			'AT_LBRACE' => 37,
			'STAR_LBRACE' => 29,
			'SUFFIX' => 31,
			"\"" => 30,
			"^" => 1,
			"[" => 13,
			'REGEX' => 14,
			'SYMBOL' => 11,
			'INDEX' => 12
		},
		DEFAULT => -119,
		GOTOS => {
			'qw_keys' => 66,
			's_suffix' => 28,
			'qc_phrase' => 67,
			'qw_exact' => 68,
			'qw_listfile' => 32,
			's_word' => 35,
			'neg_regex' => 36,
			'qw_matchid' => 70,
			'qc_basic' => 107,
			'qw_thesaurus' => 21,
			's_prefix' => 58,
			'qc_word' => 22,
			'qw_withor' => 62,
			'index' => 63,
			'qw_lemma' => 64,
			's_index' => 25,
			'qw_set_infl' => 27,
			'qc_tokens' => 50,
			'qw_prefix_set' => 9,
			'regex' => 52,
			'qw_morph' => 53,
			'qw_infix_set' => 10,
			'qw_suffix_set' => 54,
			'qw_prefix' => 15,
			'qw_set_exact' => 16,
			'qw_without' => 17,
			'qw_bareword' => 57,
			'qw_regex' => 40,
			'qw_anchor' => 41,
			'qw_any' => 2,
			'qc_near' => 43,
			'qw_with' => 3,
			'symbol' => 4,
			'qw_chunk' => 6,
			's_infix' => 5,
			'qw_suffix' => 46,
			'qwk_indextuple' => 7,
			'qw_infix' => 8
		}
	},
	{#State 50
		ACTIONS => {
			"=" => 86
		},
		DEFAULT => -130,
		GOTOS => {
			'matchid' => 108,
			'matchid_eq' => 84
		}
	},
	{#State 51
		ACTIONS => {
			'DATE' => 69,
			'INTEGER' => 42,
			'SYMBOL' => 11
		},
		GOTOS => {
			's_lemma' => 110,
			'symbol' => 109
		}
	},
	{#State 52
		DEFAULT => -169
	},
	{#State 53
		DEFAULT => -154
	},
	{#State 54
		DEFAULT => -152
	},
	{#State 55
		DEFAULT => -2
	},
	{#State 56
		ACTIONS => {
			"\"" => 30,
			'DATE' => 69,
			'SUFFIX' => 31,
			'STAR_LBRACE' => 29,
			"%" => 51,
			'AT_LBRACE' => 37,
			'KEYS' => 71,
			"!" => 18,
			"(" => 56,
			'INDEX' => 12,
			'SYMBOL' => 11,
			'PREFIX' => 33,
			"[" => 13,
			'REGEX' => 14,
			'NEAR' => 60,
			'INTEGER' => 42,
			'INFIX' => 59,
			"^" => 1,
			'NEG_REGEX' => 39,
			'DOLLAR_DOT' => 20,
			"{" => 24,
			'COLON_LBRACE' => 47,
			"<" => 65,
			"*" => 44,
			"\@" => 45,
			"\$" => 23
		},
		GOTOS => {
			'qw_suffix_set' => 54,
			'qw_prefix' => 15,
			'qw_set_exact' => 16,
			'qw_bareword' => 57,
			'qw_without' => 17,
			'qc_concat' => 117,
			'qc_tokens' => 50,
			'qw_prefix_set' => 9,
			'qw_morph' => 53,
			'qw_infix_set' => 10,
			'regex' => 52,
			's_infix' => 5,
			'qw_chunk' => 6,
			'qw_suffix' => 46,
			'qwk_indextuple' => 7,
			'qw_infix' => 8,
			'qw_anchor' => 41,
			'qw_regex' => 40,
			'qc_near' => 116,
			'qw_any' => 2,
			'symbol' => 4,
			'qw_with' => 3,
			's_word' => 35,
			'qw_listfile' => 32,
			'qw_matchid' => 70,
			'neg_regex' => 36,
			'qc_basic' => 72,
			'q_clause' => 114,
			's_suffix' => 28,
			'qw_keys' => 66,
			'qw_exact' => 68,
			'qc_phrase' => 115,
			'qw_withor' => 62,
			'qw_lemma' => 64,
			'index' => 63,
			'qw_set_infl' => 27,
			'qc_boolean' => 113,
			's_index' => 25,
			'qc_matchid' => 112,
			'qw_thesaurus' => 21,
			's_prefix' => 58,
			'qc_word' => 111
		}
	},
	{#State 57
		DEFAULT => -141
	},
	{#State 58
		DEFAULT => -179
	},
	{#State 59
		DEFAULT => -271
	},
	{#State 60
		ACTIONS => {
			"(" => 118
		}
	},
	{#State 61
		ACTIONS => {
			"(" => 119
		}
	},
	{#State 62
		DEFAULT => -161
	},
	{#State 63
		DEFAULT => -250
	},
	{#State 64
		DEFAULT => -155
	},
	{#State 65
		ACTIONS => {
			'SYMBOL' => 11,
			'INTEGER' => 42,
			'DATE' => 69
		},
		GOTOS => {
			's_filename' => 120,
			'symbol' => 121
		}
	},
	{#State 66
		DEFAULT => -162
	},
	{#State 67
		DEFAULT => -137
	},
	{#State 68
		DEFAULT => -142
	},
	{#State 69
		DEFAULT => -265
	},
	{#State 70
		DEFAULT => -163
	},
	{#State 71
		ACTIONS => {
			"(" => 122
		}
	},
	{#State 72
		ACTIONS => {
			'DOLLAR_DOT' => 20,
			"{" => 24,
			"\$" => 23,
			'SUFFIX' => 31,
			"\"" => 30,
			'STAR_LBRACE' => 29,
			'AT_LBRACE' => 37,
			'PREFIX' => 33,
			"^" => 1,
			'REGEX' => 14,
			"[" => 13,
			'INDEX' => 12,
			'SYMBOL' => 11,
			'INFIX' => 59,
			'NEAR' => 60,
			"<" => 65,
			'DATE' => 69,
			'KEYS' => 71,
			'INTEGER' => 42,
			'NEG_REGEX' => 39,
			'COLON_LBRACE' => 47,
			"\@" => 45,
			"*" => 44,
			"%" => 51,
			"(" => 106
		},
		DEFAULT => -117,
		GOTOS => {
			'qw_morph' => 53,
			'qw_infix_set' => 10,
			'regex' => 52,
			'qw_prefix_set' => 9,
			'qc_tokens' => 50,
			'qw_bareword' => 57,
			'qw_without' => 17,
			'qw_set_exact' => 16,
			'qw_prefix' => 15,
			'qw_suffix_set' => 54,
			'symbol' => 4,
			'qw_with' => 3,
			'qc_near' => 43,
			'qw_any' => 2,
			'qw_anchor' => 41,
			'qw_regex' => 40,
			'qw_infix' => 8,
			'qwk_indextuple' => 7,
			'qw_suffix' => 46,
			'qw_chunk' => 6,
			's_infix' => 5,
			'qw_exact' => 68,
			'qc_phrase' => 67,
			's_suffix' => 28,
			'qw_keys' => 66,
			'qc_basic' => 123,
			'neg_regex' => 36,
			'qw_matchid' => 70,
			's_word' => 35,
			'qw_listfile' => 32,
			'qc_word' => 22,
			's_prefix' => 58,
			'qw_thesaurus' => 21,
			'qw_set_infl' => 27,
			's_index' => 25,
			'qw_lemma' => 64,
			'index' => 63,
			'qw_withor' => 62
		}
	},
	{#State 73
		DEFAULT => -256
	},
	{#State 74
		DEFAULT => -197
	},
	{#State 75
		ACTIONS => {
			'KEYS' => 124
		}
	},
	{#State 76
		ACTIONS => {
			'SYMBOL' => 11,
			"," => 128,
			";" => 125,
			'INTEGER' => 42,
			"]" => 129,
			'DATE' => 69
		},
		GOTOS => {
			'symbol' => 126,
			's_morphitem' => 127
		}
	},
	{#State 77
		DEFAULT => -274
	},
	{#State 78
		ACTIONS => {
			"=" => 86
		},
		DEFAULT => -125,
		GOTOS => {
			'matchid_eq' => 84,
			'matchid' => 100
		}
	},
	{#State 79
		ACTIONS => {
			"=" => 130
		}
	},
	{#State 80
		ACTIONS => {
			'INTEGER' => 132
		},
		GOTOS => {
			'int_str' => 131
		}
	},
	{#State 81
		ACTIONS => {
			'AT_LBRACE' => 37,
			'KEYS' => 71,
			"(" => 91,
			'PREFIX' => 33,
			'SYMBOL' => 11,
			'INDEX' => 12,
			"[" => 13,
			'REGEX' => 14,
			'DATE' => 69,
			'SUFFIX' => 31,
			'STAR_LBRACE' => 29,
			"%" => 51,
			"{" => 24,
			"<" => 65,
			'COLON_LBRACE' => 47,
			"*" => 44,
			"\$" => 23,
			"\@" => 45,
			'INTEGER' => 42,
			'INFIX' => 59,
			'NEG_REGEX' => 39,
			"^" => 1,
			'DOLLAR_DOT' => 20
		},
		GOTOS => {
			'qw_thesaurus' => 21,
			's_prefix' => 58,
			'qc_word' => 133,
			'qw_withor' => 62,
			'index' => 63,
			'qw_lemma' => 64,
			's_index' => 25,
			'qw_set_infl' => 27,
			'qw_keys' => 66,
			's_suffix' => 28,
			'qw_exact' => 68,
			'qw_listfile' => 32,
			's_word' => 35,
			'neg_regex' => 36,
			'qw_matchid' => 70,
			'qw_anchor' => 41,
			'qw_regex' => 40,
			'qw_any' => 2,
			'qw_with' => 3,
			'symbol' => 4,
			's_infix' => 5,
			'qw_chunk' => 6,
			'qw_suffix' => 46,
			'qwk_indextuple' => 7,
			'qw_infix' => 8,
			'qw_prefix_set' => 9,
			'regex' => 52,
			'qw_morph' => 53,
			'qw_infix_set' => 10,
			'qw_suffix_set' => 54,
			'qw_prefix' => 15,
			'qw_set_exact' => 16,
			'qw_without' => 17,
			'qw_bareword' => 57
		}
	},
	{#State 82
		DEFAULT => -211
	},
	{#State 83
		ACTIONS => {
			"\$" => 23,
			"\@" => 45,
			"*" => 44,
			"<" => 65,
			'COLON_LBRACE' => 47,
			"{" => 24,
			'DOLLAR_DOT' => 20,
			"^" => 1,
			'NEG_REGEX' => 39,
			'INTEGER' => 42,
			'INFIX' => 59,
			'REGEX' => 14,
			"[" => 13,
			'INDEX' => 12,
			'SYMBOL' => 11,
			'PREFIX' => 33,
			"(" => 91,
			'KEYS' => 71,
			'AT_LBRACE' => 37,
			"%" => 51,
			'STAR_LBRACE' => 29,
			'SUFFIX' => 31,
			'DATE' => 69
		},
		GOTOS => {
			'qw_withor' => 62,
			'qw_lemma' => 64,
			'index' => 63,
			'qw_set_infl' => 27,
			's_index' => 25,
			'qw_thesaurus' => 21,
			's_prefix' => 58,
			'qc_word' => 134,
			's_word' => 35,
			'qw_listfile' => 32,
			'qw_matchid' => 70,
			'neg_regex' => 36,
			's_suffix' => 28,
			'qw_keys' => 66,
			'qw_exact' => 68,
			'qw_chunk' => 6,
			's_infix' => 5,
			'qw_suffix' => 46,
			'qwk_indextuple' => 7,
			'qw_infix' => 8,
			'qw_anchor' => 41,
			'qw_regex' => 40,
			'qw_any' => 2,
			'symbol' => 4,
			'qw_with' => 3,
			'qw_suffix_set' => 54,
			'qw_prefix' => 15,
			'qw_set_exact' => 16,
			'qw_bareword' => 57,
			'qw_without' => 17,
			'qw_prefix_set' => 9,
			'qw_infix_set' => 10,
			'qw_morph' => 53,
			'regex' => 52
		}
	},
	{#State 84
		ACTIONS => {
			'INTEGER' => 132
		},
		GOTOS => {
			'int_str' => 135,
			'integer' => 136
		}
	},
	{#State 85
		ACTIONS => {
			'INTEGER' => 42,
			'INFIX' => 59,
			'DOLLAR_DOT' => 20,
			'NEG_REGEX' => 39,
			"^" => 1,
			"<" => 65,
			'COLON_LBRACE' => 47,
			"{" => 24,
			"\@" => 45,
			"\$" => 23,
			"*" => 44,
			'SUFFIX' => 31,
			'DATE' => 69,
			"%" => 51,
			'STAR_LBRACE' => 29,
			"(" => 91,
			'KEYS' => 71,
			'AT_LBRACE' => 37,
			'REGEX' => 14,
			"[" => 13,
			'PREFIX' => 33,
			'INDEX' => 12,
			'SYMBOL' => 11
		},
		GOTOS => {
			'qc_word' => 137,
			's_prefix' => 58,
			'qw_thesaurus' => 21,
			's_index' => 25,
			'qw_set_infl' => 27,
			'index' => 63,
			'qw_lemma' => 64,
			'qw_withor' => 62,
			'qw_exact' => 68,
			'qw_keys' => 66,
			's_suffix' => 28,
			'neg_regex' => 36,
			'qw_matchid' => 70,
			'qw_listfile' => 32,
			's_word' => 35,
			'qw_with' => 3,
			'symbol' => 4,
			'qw_any' => 2,
			'qw_anchor' => 41,
			'qw_regex' => 40,
			'qw_infix' => 8,
			'qwk_indextuple' => 7,
			'qw_suffix' => 46,
			'qw_chunk' => 6,
			's_infix' => 5,
			'regex' => 52,
			'qw_morph' => 53,
			'qw_infix_set' => 10,
			'qw_prefix_set' => 9,
			'qw_without' => 17,
			'qw_bareword' => 57,
			'qw_set_exact' => 16,
			'qw_prefix' => 15,
			'qw_suffix_set' => 54
		}
	},
	{#State 86
		DEFAULT => -284
	},
	{#State 87
		ACTIONS => {
			'DATE' => 69,
			'INTEGER' => 42,
			"\$" => 142,
			'INDEX' => 12,
			'SYMBOL' => 11
		},
		DEFAULT => -230,
		GOTOS => {
			'l_indextuple' => 138,
			's_indextuple_item' => 139,
			'symbol' => 140,
			's_index' => 141,
			'index' => 63
		}
	},
	{#State 88
		ACTIONS => {
			'INTEGER' => 42,
			'RBRACE_STAR' => 143,
			'DATE' => 69,
			'SYMBOL' => 11,
			"," => 145,
			"}" => 146
		},
		GOTOS => {
			'symbol' => 4,
			's_word' => 144
		}
	},
	{#State 89
		ACTIONS => {
			"%" => 150,
			'STAR_LBRACE' => 153,
			'SUFFIX' => 31,
			'DATE' => 69,
			'REGEX' => 14,
			"[" => 160,
			'SYMBOL' => 11,
			'PREFIX' => 33,
			":" => 159,
			'AT_LBRACE' => 155,
			'NEG_REGEX' => 39,
			"^" => 161,
			'INTEGER' => 42,
			'INFIX' => 59,
			"\@" => 151,
			"*" => 152,
			"<" => 148,
			"{" => 158
		},
		GOTOS => {
			'symbol' => 4,
			'regex' => 149,
			's_prefix' => 147,
			'neg_regex' => 156,
			's_suffix' => 154,
			's_word' => 157,
			's_infix' => 162
		}
	},
	{#State 90
		ACTIONS => {
			"}" => 163,
			"," => 145,
			'SYMBOL' => 11,
			'DATE' => 69,
			'RBRACE_STAR' => 164,
			'INTEGER' => 42
		},
		GOTOS => {
			's_word' => 144,
			'symbol' => 4
		}
	},
	{#State 91
		ACTIONS => {
			'DOLLAR_DOT' => 20,
			"^" => 1,
			'NEG_REGEX' => 39,
			'INTEGER' => 42,
			'INFIX' => 59,
			"\@" => 45,
			"\$" => 23,
			"*" => 44,
			'COLON_LBRACE' => 47,
			"<" => 65,
			"{" => 24,
			"%" => 51,
			'STAR_LBRACE' => 29,
			'SUFFIX' => 31,
			'DATE' => 69,
			"[" => 13,
			'REGEX' => 14,
			'PREFIX' => 33,
			'INDEX' => 12,
			'SYMBOL' => 11,
			"(" => 91,
			'AT_LBRACE' => 37,
			'KEYS' => 71
		},
		GOTOS => {
			'qc_word' => 165,
			's_prefix' => 58,
			'qw_thesaurus' => 21,
			'qw_set_infl' => 27,
			's_index' => 25,
			'index' => 63,
			'qw_lemma' => 64,
			'qw_withor' => 62,
			'qw_exact' => 68,
			's_suffix' => 28,
			'qw_keys' => 66,
			'qw_matchid' => 70,
			'neg_regex' => 36,
			's_word' => 35,
			'qw_listfile' => 32,
			'symbol' => 4,
			'qw_with' => 3,
			'qw_any' => 2,
			'qw_anchor' => 41,
			'qw_regex' => 40,
			'qw_infix' => 8,
			'qwk_indextuple' => 7,
			'qw_suffix' => 46,
			'qw_chunk' => 6,
			's_infix' => 5,
			'qw_infix_set' => 10,
			'qw_morph' => 53,
			'regex' => 52,
			'qw_prefix_set' => 9,
			'qw_bareword' => 57,
			'qw_without' => 17,
			'qw_set_exact' => 16,
			'qw_prefix' => 15,
			'qw_suffix_set' => 54
		}
	},
	{#State 92
		ACTIONS => {
			'WITHOUT' => 81,
			'WITH' => 83,
			"=" => 86,
			'WITHOR' => 85
		},
		DEFAULT => -219,
		GOTOS => {
			'matchid' => 82,
			'matchid_eq' => 84
		}
	},
	{#State 93
		ACTIONS => {
			'INFIX' => 59,
			'INTEGER' => 42,
			"#" => 170,
			"^" => 1,
			'NEG_REGEX' => 39,
			'DOLLAR_DOT' => 20,
			"{" => 24,
			"<" => 65,
			'COLON_LBRACE' => 47,
			"*" => 44,
			"\@" => 45,
			"\$" => 23,
			"\"" => 167,
			'HASH_EQUAL' => 169,
			'SUFFIX' => 31,
			'DATE' => 69,
			'STAR_LBRACE' => 29,
			'HASH_LESS' => 171,
			"%" => 51,
			'KEYS' => 71,
			'AT_LBRACE' => 37,
			'HASH_GREATER' => 166,
			"(" => 91,
			'INDEX' => 12,
			'SYMBOL' => 11,
			'PREFIX' => 33,
			"[" => 13,
			'REGEX' => 14
		},
		GOTOS => {
			's_word' => 35,
			'qw_listfile' => 32,
			'qw_matchid' => 70,
			'neg_regex' => 36,
			's_suffix' => 28,
			'qw_keys' => 66,
			'qw_exact' => 68,
			'qw_withor' => 62,
			'index' => 63,
			'qw_lemma' => 64,
			'qw_set_infl' => 27,
			's_index' => 25,
			'qw_thesaurus' => 21,
			's_prefix' => 58,
			'qc_word' => 168,
			'qw_suffix_set' => 54,
			'qw_prefix' => 15,
			'qw_set_exact' => 16,
			'qw_bareword' => 57,
			'qw_without' => 17,
			'qw_prefix_set' => 9,
			'qw_morph' => 53,
			'qw_infix_set' => 10,
			'regex' => 52,
			's_infix' => 5,
			'qw_chunk' => 6,
			'qw_suffix' => 46,
			'qwk_indextuple' => 7,
			'qw_infix' => 8,
			'qw_regex' => 40,
			'qw_anchor' => 41,
			'qw_any' => 2,
			'symbol' => 4,
			'qw_with' => 3
		}
	},
	{#State 94
		DEFAULT => 0
	},
	{#State 95
		ACTIONS => {
			'EXPANDER' => 173
		},
		DEFAULT => -165,
		GOTOS => {
			's_expander' => 172
		}
	},
	{#State 96
		ACTIONS => {
			'SYMBOL' => 11,
			"," => 145,
			"}" => 174,
			'INTEGER' => 42,
			'DATE' => 69
		},
		GOTOS => {
			's_word' => 144,
			'symbol' => 4
		}
	},
	{#State 97
		ACTIONS => {
			'DOLLAR_DOT' => 20,
			"^" => 1,
			'NEG_REGEX' => 39,
			'NEAR' => 60,
			'INTEGER' => 42,
			'INFIX' => 59,
			"\@" => 45,
			"\$" => 23,
			"*" => 44,
			'COLON_LBRACE' => 47,
			"<" => 65,
			"{" => 24,
			"%" => 51,
			'STAR_LBRACE' => 29,
			'SUFFIX' => 31,
			'DATE' => 69,
			"\"" => 30,
			'REGEX' => 14,
			"[" => 13,
			'INDEX' => 12,
			'SYMBOL' => 11,
			'PREFIX' => 33,
			"(" => 56,
			"!" => 18,
			'KEYS' => 71,
			'AT_LBRACE' => 37
		},
		GOTOS => {
			'qc_concat' => 49,
			'qc_tokens' => 50,
			'qw_prefix_set' => 9,
			'regex' => 52,
			'qw_infix_set' => 10,
			'qw_morph' => 53,
			'qw_suffix_set' => 54,
			'qw_prefix' => 15,
			'qw_set_exact' => 16,
			'qw_without' => 17,
			'qw_bareword' => 57,
			'qw_regex' => 40,
			'qw_anchor' => 41,
			'qw_any' => 2,
			'qc_near' => 43,
			'qw_with' => 3,
			'symbol' => 4,
			's_infix' => 5,
			'qw_chunk' => 6,
			'qw_suffix' => 46,
			'qwk_indextuple' => 7,
			'qw_infix' => 8,
			'qw_keys' => 66,
			's_suffix' => 28,
			'qc_phrase' => 67,
			'qw_exact' => 68,
			'qw_listfile' => 32,
			's_word' => 35,
			'qw_matchid' => 70,
			'neg_regex' => 36,
			'q_clause' => 175,
			'qc_basic' => 72,
			'qc_matchid' => 19,
			'qw_thesaurus' => 21,
			's_prefix' => 58,
			'qc_word' => 22,
			'qw_withor' => 62,
			'qw_lemma' => 64,
			'index' => 63,
			's_index' => 25,
			'qc_boolean' => 26,
			'qw_set_infl' => 27
		}
	},
	{#State 98
		ACTIONS => {
			'NEAR' => 60,
			'INTEGER' => 42,
			'INFIX' => 59,
			'DOLLAR_DOT' => 20,
			"^" => 1,
			'NEG_REGEX' => 39,
			"<" => 65,
			'COLON_LBRACE' => 47,
			"{" => 24,
			"\@" => 45,
			"\$" => 23,
			"*" => 44,
			'DATE' => 69,
			'SUFFIX' => 31,
			"\"" => 30,
			"%" => 51,
			'STAR_LBRACE' => 29,
			"!" => 18,
			"(" => 56,
			'AT_LBRACE' => 37,
			'KEYS' => 71,
			"[" => 13,
			'REGEX' => 14,
			'PREFIX' => 33,
			'INDEX' => 12,
			'SYMBOL' => 11
		},
		GOTOS => {
			'qwk_indextuple' => 7,
			'qw_infix' => 8,
			's_infix' => 5,
			'qw_chunk' => 6,
			'qw_suffix' => 46,
			'qc_near' => 43,
			'qw_any' => 2,
			'symbol' => 4,
			'qw_with' => 3,
			'qw_regex' => 40,
			'qw_anchor' => 41,
			'qw_set_exact' => 16,
			'qw_bareword' => 57,
			'qw_without' => 17,
			'qw_suffix_set' => 54,
			'qw_prefix' => 15,
			'qw_prefix_set' => 9,
			'qw_morph' => 53,
			'qw_infix_set' => 10,
			'regex' => 52,
			'qc_concat' => 49,
			'qc_tokens' => 50,
			'index' => 63,
			'qw_lemma' => 64,
			'qw_set_infl' => 27,
			'qc_boolean' => 26,
			's_index' => 25,
			'qw_withor' => 62,
			's_prefix' => 58,
			'qc_word' => 22,
			'qc_matchid' => 19,
			'qw_thesaurus' => 21,
			'qc_basic' => 72,
			'q_clause' => 176,
			's_word' => 35,
			'qw_listfile' => 32,
			'neg_regex' => 36,
			'qw_matchid' => 70,
			's_suffix' => 28,
			'qw_keys' => 66,
			'qw_exact' => 68,
			'qc_phrase' => 67
		}
	},
	{#State 99
		ACTIONS => {
			'LESS_BY_DATE' => 199,
			":" => 198,
			'LESS_BY_LEFT' => 178,
			"!" => 200,
			'GREATER_BY_LEFT' => 179,
			'GREATER_BY_DATE' => 202,
			'GREATER_BY_RANK' => 180,
			'LESS_BY_MIDDLE' => 203,
			'LESS_BY_SIZE' => 204,
			'GREATER_BY_MIDDLE' => 181,
			'WITHIN' => 183,
			'CNTXT' => 182,
			'GREATER_BY' => 205,
			'IS_DATE' => 184,
			'LESS_BY' => 206,
			'GREATER_BY_RIGHT' => 207,
			'KW_COMMENT' => 210,
			'HAS_FIELD' => 185,
			'RANDOM' => 211,
			'LESS_BY_RANK' => 186,
			'GREATER_BY_SIZE' => 188,
			'NOSEPARATE_HITS' => 191,
			'IS_SIZE' => 192,
			'FILENAMES_ONLY' => 212,
			'SEPARATE_HITS' => 195,
			'LESS_BY_RIGHT' => 213,
			'DEBUG_RANK' => 197
		},
		DEFAULT => -29,
		GOTOS => {
			'q_flag' => 177,
			'qf_has_field' => 193,
			'q_filter' => 201,
			'qf_bibl_sort' => 209,
			'qf_random_sort' => 194,
			'qf_context_sort' => 196,
			'q_comment' => 208,
			'qf_rank_sort' => 187,
			'qf_size_sort' => 190,
			'qf_date_sort' => 189
		}
	},
	{#State 100
		DEFAULT => -121
	},
	{#State 101
		DEFAULT => -276
	},
	{#State 102
		DEFAULT => -134
	},
	{#State 103
		DEFAULT => -167
	},
	{#State 104
		ACTIONS => {
			"}" => 214
		}
	},
	{#State 105
		DEFAULT => -254
	},
	{#State 106
		ACTIONS => {
			'INTEGER' => 42,
			'NEAR' => 60,
			'INFIX' => 59,
			'DOLLAR_DOT' => 20,
			"^" => 1,
			'NEG_REGEX' => 39,
			"<" => 65,
			'COLON_LBRACE' => 47,
			"{" => 24,
			"\@" => 45,
			"\$" => 23,
			"*" => 44,
			'SUFFIX' => 31,
			'DATE' => 69,
			"\"" => 30,
			"%" => 51,
			'STAR_LBRACE' => 29,
			"(" => 106,
			'AT_LBRACE' => 37,
			'KEYS' => 71,
			'REGEX' => 14,
			"[" => 13,
			'INDEX' => 12,
			'SYMBOL' => 11,
			'PREFIX' => 33
		},
		GOTOS => {
			'qw_suffix_set' => 54,
			'qw_prefix' => 15,
			'qw_set_exact' => 16,
			'qw_without' => 17,
			'qw_bareword' => 57,
			'qw_prefix_set' => 9,
			'regex' => 52,
			'qw_morph' => 53,
			'qw_infix_set' => 10,
			's_infix' => 5,
			'qw_chunk' => 6,
			'qw_suffix' => 46,
			'qwk_indextuple' => 7,
			'qw_infix' => 8,
			'qw_anchor' => 41,
			'qw_regex' => 40,
			'qw_any' => 2,
			'qc_near' => 216,
			'qw_with' => 3,
			'symbol' => 4,
			'qw_listfile' => 32,
			's_word' => 35,
			'qw_matchid' => 70,
			'neg_regex' => 36,
			'qw_keys' => 66,
			's_suffix' => 28,
			'qc_phrase' => 215,
			'qw_exact' => 68,
			'qw_withor' => 62,
			'index' => 63,
			'qw_lemma' => 64,
			's_index' => 25,
			'qw_set_infl' => 27,
			'qw_thesaurus' => 21,
			's_prefix' => 58,
			'qc_word' => 165
		}
	},
	{#State 107
		DEFAULT => -128
	},
	{#State 108
		DEFAULT => -138
	},
	{#State 109
		DEFAULT => -255
	},
	{#State 110
		DEFAULT => -195
	},
	{#State 111
		ACTIONS => {
			"=" => 86,
			'WITH' => 83,
			")" => 217,
			'WITHOR' => 85,
			'WITHOUT' => 81
		},
		DEFAULT => -136,
		GOTOS => {
			'matchid' => 82,
			'matchid_eq' => 84
		}
	},
	{#State 112
		ACTIONS => {
			")" => 218
		},
		DEFAULT => -120
	},
	{#State 113
		ACTIONS => {
			")" => 219
		},
		DEFAULT => -118
	},
	{#State 114
		ACTIONS => {
			"=" => 86,
			'OP_BOOL_AND' => 97,
			'OP_BOOL_OR' => 98
		},
		GOTOS => {
			'matchid' => 100,
			'matchid_eq' => 84
		}
	},
	{#State 115
		ACTIONS => {
			")" => 220
		},
		DEFAULT => -137
	},
	{#State 116
		ACTIONS => {
			")" => 221,
			"=" => 86
		},
		DEFAULT => -131,
		GOTOS => {
			'matchid' => 102,
			'matchid_eq' => 84
		}
	},
	{#State 117
		ACTIONS => {
			"{" => 24,
			"<" => 65,
			'COLON_LBRACE' => 47,
			")" => 222,
			"*" => 44,
			"\@" => 45,
			"\$" => 23,
			'INFIX' => 59,
			'NEAR' => 60,
			'INTEGER' => 42,
			"^" => 1,
			'NEG_REGEX' => 39,
			'DOLLAR_DOT' => 20,
			'AT_LBRACE' => 37,
			'KEYS' => 71,
			"(" => 106,
			'PREFIX' => 33,
			'SYMBOL' => 11,
			'INDEX' => 12,
			'REGEX' => 14,
			"[" => 13,
			"\"" => 30,
			'DATE' => 69,
			'SUFFIX' => 31,
			'STAR_LBRACE' => 29,
			"%" => 51
		},
		DEFAULT => -119,
		GOTOS => {
			'qw_listfile' => 32,
			's_word' => 35,
			'qw_matchid' => 70,
			'neg_regex' => 36,
			'qc_basic' => 107,
			'qw_keys' => 66,
			's_suffix' => 28,
			'qc_phrase' => 67,
			'qw_exact' => 68,
			'qw_withor' => 62,
			'qw_lemma' => 64,
			'index' => 63,
			's_index' => 25,
			'qw_set_infl' => 27,
			'qw_thesaurus' => 21,
			's_prefix' => 58,
			'qc_word' => 22,
			'qw_suffix_set' => 54,
			'qw_prefix' => 15,
			'qw_set_exact' => 16,
			'qw_without' => 17,
			'qw_bareword' => 57,
			'qc_tokens' => 50,
			'qw_prefix_set' => 9,
			'regex' => 52,
			'qw_morph' => 53,
			'qw_infix_set' => 10,
			's_infix' => 5,
			'qw_chunk' => 6,
			'qw_suffix' => 46,
			'qwk_indextuple' => 7,
			'qw_infix' => 8,
			'qw_regex' => 40,
			'qw_anchor' => 41,
			'qw_any' => 2,
			'qc_near' => 43,
			'qw_with' => 3,
			'symbol' => 4
		}
	},
	{#State 118
		ACTIONS => {
			'INTEGER' => 42,
			'INFIX' => 59,
			"^" => 1,
			'NEG_REGEX' => 39,
			'DOLLAR_DOT' => 20,
			"{" => 24,
			'COLON_LBRACE' => 47,
			"<" => 65,
			"*" => 44,
			"\$" => 23,
			"\@" => 45,
			"\"" => 30,
			'DATE' => 69,
			'SUFFIX' => 31,
			'STAR_LBRACE' => 29,
			"%" => 51,
			'KEYS' => 71,
			'AT_LBRACE' => 37,
			"(" => 223,
			'SYMBOL' => 11,
			'INDEX' => 12,
			'PREFIX' => 33,
			"[" => 13,
			'REGEX' => 14
		},
		GOTOS => {
			'qw_set_infl' => 27,
			's_index' => 25,
			'index' => 63,
			'qw_lemma' => 64,
			'qw_withor' => 62,
			'qc_word' => 22,
			's_prefix' => 58,
			'qw_thesaurus' => 21,
			'qw_matchid' => 70,
			'neg_regex' => 36,
			's_word' => 35,
			'qw_listfile' => 32,
			'qw_exact' => 68,
			'qc_phrase' => 67,
			's_suffix' => 28,
			'qw_keys' => 66,
			'qw_infix' => 8,
			'qwk_indextuple' => 7,
			'qw_suffix' => 46,
			'qw_chunk' => 6,
			's_infix' => 5,
			'symbol' => 4,
			'qw_with' => 3,
			'qw_any' => 2,
			'qw_regex' => 40,
			'qw_anchor' => 41,
			'qw_bareword' => 57,
			'qw_without' => 17,
			'qw_set_exact' => 16,
			'qw_prefix' => 15,
			'qw_suffix_set' => 54,
			'qw_morph' => 53,
			'qw_infix_set' => 10,
			'regex' => 52,
			'qw_prefix_set' => 9,
			'qc_tokens' => 224
		}
	},
	{#State 119
		ACTIONS => {
			"{" => 24,
			'COLON_LBRACE' => 47,
			"<" => 65,
			"*" => 44,
			"\@" => 45,
			"\$" => 23,
			'NEAR' => 60,
			'INTEGER' => 42,
			'INFIX' => 59,
			"^" => 1,
			'NEG_REGEX' => 39,
			'DOLLAR_DOT' => 20,
			'AT_LBRACE' => 37,
			'KEYS' => 71,
			"!" => 18,
			"(" => 56,
			'INDEX' => 12,
			'SYMBOL' => 11,
			'PREFIX' => 33,
			"[" => 13,
			'REGEX' => 14,
			"\"" => 30,
			'SUFFIX' => 31,
			'DATE' => 69,
			'STAR_LBRACE' => 29,
			"%" => 51
		},
		GOTOS => {
			'qw_lemma' => 64,
			'index' => 63,
			'qc_boolean' => 26,
			'qw_set_infl' => 27,
			's_index' => 25,
			'qw_withor' => 62,
			's_prefix' => 58,
			'qc_word' => 22,
			'qc_matchid' => 19,
			'qw_thesaurus' => 21,
			'qc_basic' => 72,
			'q_clause' => 38,
			's_word' => 35,
			'qw_listfile' => 32,
			'qw_matchid' => 70,
			'neg_regex' => 36,
			's_suffix' => 28,
			'qw_keys' => 66,
			'qw_exact' => 68,
			'qc_phrase' => 67,
			'qwk_indextuple' => 7,
			'qw_infix' => 8,
			'qw_chunk' => 6,
			's_infix' => 5,
			'qw_suffix' => 46,
			'qc_near' => 43,
			'qw_any' => 2,
			'symbol' => 4,
			'qw_with' => 3,
			'qw_anchor' => 41,
			'qw_regex' => 40,
			'qw_set_exact' => 16,
			'qw_bareword' => 57,
			'qw_without' => 17,
			'qw_suffix_set' => 54,
			'qw_prefix' => 15,
			'qw_prefix_set' => 9,
			'qw_morph' => 53,
			'qw_infix_set' => 10,
			'regex' => 52,
			'query_conditions' => 225,
			'qc_concat' => 49,
			'qc_tokens' => 50
		}
	},
	{#State 120
		DEFAULT => -201
	},
	{#State 121
		DEFAULT => -257
	},
	{#State 122
		ACTIONS => {
			"(" => 56,
			"!" => 18,
			'AT_LBRACE' => 37,
			'KEYS' => 71,
			"[" => 13,
			'REGEX' => 14,
			'PREFIX' => 33,
			'INDEX' => 12,
			'SYMBOL' => 11,
			'DATE' => 69,
			'SUFFIX' => 31,
			"\"" => 30,
			"%" => 51,
			'STAR_LBRACE' => 29,
			'COLON_LBRACE' => 47,
			"<" => 65,
			"{" => 24,
			"\@" => 45,
			"\$" => 23,
			'COUNT' => 61,
			"*" => 44,
			'INFIX' => 59,
			'NEAR' => 60,
			'INTEGER' => 42,
			'DOLLAR_DOT' => 20,
			'NEG_REGEX' => 39,
			"^" => 1
		},
		GOTOS => {
			'qw_with' => 3,
			'symbol' => 4,
			'qw_any' => 2,
			'qc_near' => 43,
			'qw_regex' => 40,
			'qw_anchor' => 41,
			'qw_infix' => 8,
			'qwk_indextuple' => 7,
			'qw_suffix' => 46,
			's_infix' => 5,
			'qw_chunk' => 6,
			'regex' => 52,
			'qw_infix_set' => 10,
			'qw_morph' => 53,
			'qw_prefix_set' => 9,
			'qc_tokens' => 50,
			'query_conditions' => 228,
			'qc_concat' => 49,
			'qw_without' => 17,
			'count_query' => 227,
			'qw_bareword' => 57,
			'qw_set_exact' => 16,
			'qw_prefix' => 15,
			'qw_suffix_set' => 54,
			'qc_word' => 22,
			's_prefix' => 58,
			'qw_thesaurus' => 21,
			'qc_matchid' => 19,
			's_index' => 25,
			'qc_boolean' => 26,
			'qw_set_infl' => 27,
			'index' => 63,
			'qw_lemma' => 64,
			'qw_withor' => 62,
			'qwk_countsrc' => 226,
			'qc_phrase' => 67,
			'qw_exact' => 68,
			'qw_keys' => 66,
			's_suffix' => 28,
			'q_clause' => 38,
			'qc_basic' => 72,
			'neg_regex' => 36,
			'qw_matchid' => 70,
			'qw_listfile' => 32,
			's_word' => 35
		}
	},
	{#State 123
		DEFAULT => -127
	},
	{#State 124
		ACTIONS => {
			"(" => 229
		}
	},
	{#State 125
		DEFAULT => -218
	},
	{#State 126
		DEFAULT => -258
	},
	{#State 127
		DEFAULT => -216
	},
	{#State 128
		DEFAULT => -217
	},
	{#State 129
		DEFAULT => -193
	},
	{#State 130
		ACTIONS => {
			'INTEGER' => 132
		},
		GOTOS => {
			'int_str' => 230
		}
	},
	{#State 131
		DEFAULT => -199
	},
	{#State 132
		DEFAULT => -279
	},
	{#State 133
		ACTIONS => {
			"=" => 86
		},
		DEFAULT => -204,
		GOTOS => {
			'matchid' => 82,
			'matchid_eq' => 84
		}
	},
	{#State 134
		ACTIONS => {
			"=" => 86
		},
		DEFAULT => -203,
		GOTOS => {
			'matchid' => 82,
			'matchid_eq' => 84
		}
	},
	{#State 135
		DEFAULT => -280
	},
	{#State 136
		DEFAULT => -283
	},
	{#State 137
		ACTIONS => {
			"=" => 86
		},
		DEFAULT => -205,
		GOTOS => {
			'matchid_eq' => 84,
			'matchid' => 82
		}
	},
	{#State 138
		ACTIONS => {
			"," => 231,
			")" => 232
		}
	},
	{#State 139
		DEFAULT => -231
	},
	{#State 140
		DEFAULT => -252
	},
	{#State 141
		DEFAULT => -251
	},
	{#State 142
		DEFAULT => -249
	},
	{#State 143
		DEFAULT => -187
	},
	{#State 144
		DEFAULT => -213
	},
	{#State 145
		DEFAULT => -214
	},
	{#State 146
		DEFAULT => -225,
		GOTOS => {
			'l_txchain' => 233
		}
	},
	{#State 147
		DEFAULT => -180
	},
	{#State 148
		ACTIONS => {
			'SYMBOL' => 11,
			'DATE' => 69,
			'INTEGER' => 42
		},
		GOTOS => {
			'symbol' => 121,
			's_filename' => 234
		}
	},
	{#State 149
		DEFAULT => -170
	},
	{#State 150
		ACTIONS => {
			'INTEGER' => 42,
			'DATE' => 69,
			'SYMBOL' => 11
		},
		GOTOS => {
			'symbol' => 109,
			's_lemma' => 235
		}
	},
	{#State 151
		ACTIONS => {
			'SYMBOL' => 11,
			'DATE' => 69,
			'INTEGER' => 42
		},
		GOTOS => {
			'symbol' => 4,
			's_word' => 236
		}
	},
	{#State 152
		DEFAULT => -174
	},
	{#State 153
		DEFAULT => -212,
		GOTOS => {
			'l_set' => 237
		}
	},
	{#State 154
		DEFAULT => -182
	},
	{#State 155
		DEFAULT => -212,
		GOTOS => {
			'l_set' => 238
		}
	},
	{#State 156
		DEFAULT => -172
	},
	{#State 157
		DEFAULT => -225,
		GOTOS => {
			'l_txchain' => 239
		}
	},
	{#State 158
		DEFAULT => -212,
		GOTOS => {
			'l_set' => 240
		}
	},
	{#State 159
		ACTIONS => {
			"{" => 241
		}
	},
	{#State 160
		DEFAULT => -215,
		GOTOS => {
			'l_morph' => 242
		}
	},
	{#State 161
		ACTIONS => {
			'SYMBOL' => 11,
			'INTEGER' => 42,
			'DATE' => 69
		},
		GOTOS => {
			's_chunk' => 243,
			'symbol' => 73
		}
	},
	{#State 162
		DEFAULT => -184
	},
	{#State 163
		DEFAULT => -189
	},
	{#State 164
		DEFAULT => -185
	},
	{#State 165
		ACTIONS => {
			"=" => 86,
			")" => 217,
			'WITHOUT' => 81,
			'WITH' => 83,
			'WITHOR' => 85
		},
		GOTOS => {
			'matchid_eq' => 84,
			'matchid' => 82
		}
	},
	{#State 166
		ACTIONS => {
			'INTEGER' => 132
		},
		GOTOS => {
			'int_str' => 135,
			'integer' => 244
		}
	},
	{#State 167
		DEFAULT => -139
	},
	{#State 168
		ACTIONS => {
			'WITHOR' => 85,
			"=" => 86,
			'WITH' => 83,
			'WITHOUT' => 81
		},
		DEFAULT => -220,
		GOTOS => {
			'matchid' => 82,
			'matchid_eq' => 84
		}
	},
	{#State 169
		ACTIONS => {
			'INTEGER' => 132
		},
		GOTOS => {
			'int_str' => 135,
			'integer' => 245
		}
	},
	{#State 170
		ACTIONS => {
			'INTEGER' => 132
		},
		GOTOS => {
			'int_str' => 135,
			'integer' => 246
		}
	},
	{#State 171
		ACTIONS => {
			'INTEGER' => 132
		},
		GOTOS => {
			'integer' => 247,
			'int_str' => 135
		}
	},
	{#State 172
		DEFAULT => -226
	},
	{#State 173
		DEFAULT => -272
	},
	{#State 174
		DEFAULT => -175
	},
	{#State 175
		ACTIONS => {
			"=" => 86
		},
		DEFAULT => -123,
		GOTOS => {
			'matchid_eq' => 84,
			'matchid' => 100
		}
	},
	{#State 176
		ACTIONS => {
			"=" => 86
		},
		DEFAULT => -124,
		GOTOS => {
			'matchid' => 100,
			'matchid_eq' => 84
		}
	},
	{#State 177
		DEFAULT => -32
	},
	{#State 178
		ACTIONS => {
			"[" => 248
		},
		DEFAULT => -106,
		GOTOS => {
			'qfb_ctxsort' => 249
		}
	},
	{#State 179
		ACTIONS => {
			"[" => 248
		},
		DEFAULT => -106,
		GOTOS => {
			'qfb_ctxsort' => 250
		}
	},
	{#State 180
		DEFAULT => -64
	},
	{#State 181
		ACTIONS => {
			"[" => 248
		},
		DEFAULT => -106,
		GOTOS => {
			'qfb_ctxsort' => 251
		}
	},
	{#State 182
		ACTIONS => {
			"[" => 253,
			'INTEGER' => 132
		},
		GOTOS => {
			'int_str' => 135,
			'integer' => 252
		}
	},
	{#State 183
		ACTIONS => {
			'INTEGER' => 42,
			'DATE' => 69,
			'SYMBOL' => 11,
			'KW_FILENAME' => 255
		},
		GOTOS => {
			's_breakname' => 256,
			'symbol' => 254
		}
	},
	{#State 184
		ACTIONS => {
			"[" => 257
		}
	},
	{#State 185
		ACTIONS => {
			"[" => 258
		}
	},
	{#State 186
		DEFAULT => -65
	},
	{#State 187
		DEFAULT => -50
	},
	{#State 188
		ACTIONS => {
			"[" => 260
		},
		DEFAULT => -85,
		GOTOS => {
			'qfb_int' => 259
		}
	},
	{#State 189
		DEFAULT => -53
	},
	{#State 190
		DEFAULT => -52
	},
	{#State 191
		DEFAULT => -41
	},
	{#State 192
		ACTIONS => {
			"[" => 261
		}
	},
	{#State 193
		DEFAULT => -49
	},
	{#State 194
		DEFAULT => -55
	},
	{#State 195
		DEFAULT => -40
	},
	{#State 196
		DEFAULT => -51
	},
	{#State 197
		DEFAULT => -44
	},
	{#State 198
		ACTIONS => {
			'DATE' => 69,
			'SYMBOL' => 11,
			'INTEGER' => 42
		},
		DEFAULT => -46,
		GOTOS => {
			's_subcorpus' => 263,
			'qf_subcorpora' => 264,
			'symbol' => 262
		}
	},
	{#State 199
		ACTIONS => {
			"[" => 265
		},
		DEFAULT => -92,
		GOTOS => {
			'qfb_date' => 266
		}
	},
	{#State 200
		ACTIONS => {
			'HAS_FIELD' => 185,
			'DEBUG_RANK' => 267,
			"!" => 270,
			'FILENAMES_ONLY' => 269
		},
		GOTOS => {
			'qf_has_field' => 268
		}
	},
	{#State 201
		DEFAULT => -33
	},
	{#State 202
		ACTIONS => {
			"[" => 265
		},
		DEFAULT => -92,
		GOTOS => {
			'qfb_date' => 271
		}
	},
	{#State 203
		ACTIONS => {
			"[" => 248
		},
		DEFAULT => -106,
		GOTOS => {
			'qfb_ctxsort' => 272
		}
	},
	{#State 204
		ACTIONS => {
			"[" => 260
		},
		DEFAULT => -85,
		GOTOS => {
			'qfb_int' => 273
		}
	},
	{#State 205
		ACTIONS => {
			"[" => 274
		}
	},
	{#State 206
		ACTIONS => {
			"[" => 275
		}
	},
	{#State 207
		ACTIONS => {
			"[" => 248
		},
		DEFAULT => -106,
		GOTOS => {
			'qfb_ctxsort' => 276
		}
	},
	{#State 208
		DEFAULT => -31
	},
	{#State 209
		DEFAULT => -54
	},
	{#State 210
		ACTIONS => {
			'DATE' => 69,
			'INTEGER' => 42,
			"[" => 278,
			'SYMBOL' => 11
		},
		GOTOS => {
			'symbol' => 277
		}
	},
	{#State 211
		ACTIONS => {
			"[" => 279
		},
		DEFAULT => -78
	},
	{#State 212
		DEFAULT => -42
	},
	{#State 213
		ACTIONS => {
			"[" => 248
		},
		DEFAULT => -106,
		GOTOS => {
			'qfb_ctxsort' => 280
		}
	},
	{#State 214
		DEFAULT => -191
	},
	{#State 215
		ACTIONS => {
			")" => 220
		}
	},
	{#State 216
		ACTIONS => {
			")" => 221,
			"=" => 86
		},
		GOTOS => {
			'matchid_eq' => 84,
			'matchid' => 102
		}
	},
	{#State 217
		DEFAULT => -164
	},
	{#State 218
		DEFAULT => -122
	},
	{#State 219
		DEFAULT => -126
	},
	{#State 220
		DEFAULT => -140
	},
	{#State 221
		DEFAULT => -135
	},
	{#State 222
		DEFAULT => -129
	},
	{#State 223
		ACTIONS => {
			'INTEGER' => 42,
			'INFIX' => 59,
			'DOLLAR_DOT' => 20,
			'NEG_REGEX' => 39,
			"^" => 1,
			'COLON_LBRACE' => 47,
			"<" => 65,
			"{" => 24,
			"\@" => 45,
			"\$" => 23,
			"*" => 44,
			'SUFFIX' => 31,
			'DATE' => 69,
			"\"" => 30,
			"%" => 51,
			'STAR_LBRACE' => 29,
			"(" => 223,
			'AT_LBRACE' => 37,
			'KEYS' => 71,
			"[" => 13,
			'REGEX' => 14,
			'SYMBOL' => 11,
			'INDEX' => 12,
			'PREFIX' => 33
		},
		GOTOS => {
			'qw_thesaurus' => 21,
			's_prefix' => 58,
			'qc_word' => 165,
			'qw_withor' => 62,
			'index' => 63,
			'qw_lemma' => 64,
			'qw_set_infl' => 27,
			's_index' => 25,
			's_suffix' => 28,
			'qw_keys' => 66,
			'qw_exact' => 68,
			'qc_phrase' => 215,
			's_word' => 35,
			'qw_listfile' => 32,
			'neg_regex' => 36,
			'qw_matchid' => 70,
			'qw_regex' => 40,
			'qw_anchor' => 41,
			'qw_any' => 2,
			'symbol' => 4,
			'qw_with' => 3,
			's_infix' => 5,
			'qw_chunk' => 6,
			'qw_suffix' => 46,
			'qwk_indextuple' => 7,
			'qw_infix' => 8,
			'qw_prefix_set' => 9,
			'qw_infix_set' => 10,
			'qw_morph' => 53,
			'regex' => 52,
			'qw_suffix_set' => 54,
			'qw_prefix' => 15,
			'qw_set_exact' => 16,
			'qw_bareword' => 57,
			'qw_without' => 17
		}
	},
	{#State 224
		ACTIONS => {
			"," => 281,
			"=" => 86
		},
		GOTOS => {
			'matchid_eq' => 84,
			'matchid' => 108
		}
	},
	{#State 225
		DEFAULT => -4,
		GOTOS => {
			'count_filters' => 282
		}
	},
	{#State 226
		ACTIONS => {
			")" => 283
		}
	},
	{#State 227
		DEFAULT => -209
	},
	{#State 228
		DEFAULT => -4,
		GOTOS => {
			'count_filters' => 284
		}
	},
	{#State 229
		ACTIONS => {
			"\"" => 30,
			'DATE' => 69,
			'SUFFIX' => 31,
			'STAR_LBRACE' => 29,
			"%" => 51,
			'KEYS' => 71,
			'AT_LBRACE' => 37,
			"(" => 56,
			"!" => 18,
			'PREFIX' => 33,
			'SYMBOL' => 11,
			'INDEX' => 12,
			'REGEX' => 14,
			"[" => 13,
			'INTEGER' => 42,
			'INFIX' => 59,
			'NEAR' => 60,
			'NEG_REGEX' => 39,
			"^" => 1,
			'DOLLAR_DOT' => 20,
			"{" => 24,
			"<" => 65,
			'COLON_LBRACE' => 47,
			'COUNT' => 61,
			"*" => 44,
			"\$" => 23,
			"\@" => 45
		},
		GOTOS => {
			'q_clause' => 38,
			'qc_basic' => 72,
			'qw_matchid' => 70,
			'neg_regex' => 36,
			'qw_listfile' => 32,
			's_word' => 35,
			'qwk_countsrc' => 285,
			'qc_phrase' => 67,
			'qw_exact' => 68,
			'qw_keys' => 66,
			's_suffix' => 28,
			's_index' => 25,
			'qc_boolean' => 26,
			'qw_set_infl' => 27,
			'qw_lemma' => 64,
			'index' => 63,
			'qw_withor' => 62,
			'qc_word' => 22,
			's_prefix' => 58,
			'qw_thesaurus' => 21,
			'qc_matchid' => 19,
			'count_query' => 227,
			'qw_without' => 17,
			'qw_bareword' => 57,
			'qw_set_exact' => 16,
			'qw_prefix' => 15,
			'qw_suffix_set' => 54,
			'regex' => 52,
			'qw_infix_set' => 10,
			'qw_morph' => 53,
			'qw_prefix_set' => 9,
			'qc_tokens' => 50,
			'qc_concat' => 49,
			'query_conditions' => 228,
			'qw_infix' => 8,
			'qwk_indextuple' => 7,
			'qw_suffix' => 46,
			'qw_chunk' => 6,
			's_infix' => 5,
			'qw_with' => 3,
			'symbol' => 4,
			'qw_any' => 2,
			'qc_near' => 43,
			'qw_anchor' => 41,
			'qw_regex' => 40
		}
	},
	{#State 230
		DEFAULT => -200
	},
	{#State 231
		ACTIONS => {
			'DATE' => 69,
			'INTEGER' => 42,
			"\$" => 142,
			'SYMBOL' => 11,
			'INDEX' => 12
		},
		GOTOS => {
			'index' => 63,
			'symbol' => 140,
			's_indextuple_item' => 286,
			's_index' => 141
		}
	},
	{#State 232
		DEFAULT => -208
	},
	{#State 233
		ACTIONS => {
			'EXPANDER' => 173
		},
		DEFAULT => -177,
		GOTOS => {
			's_expander' => 172
		}
	},
	{#State 234
		DEFAULT => -202
	},
	{#State 235
		DEFAULT => -196
	},
	{#State 236
		DEFAULT => -168
	},
	{#State 237
		ACTIONS => {
			'SYMBOL' => 11,
			"," => 145,
			"}" => 288,
			'INTEGER' => 42,
			'RBRACE_STAR' => 287,
			'DATE' => 69
		},
		GOTOS => {
			's_word' => 144,
			'symbol' => 4
		}
	},
	{#State 238
		ACTIONS => {
			'SYMBOL' => 11,
			"," => 145,
			"}" => 289,
			'INTEGER' => 42,
			'DATE' => 69
		},
		GOTOS => {
			's_word' => 144,
			'symbol' => 4
		}
	},
	{#State 239
		ACTIONS => {
			'EXPANDER' => 173
		},
		DEFAULT => -166,
		GOTOS => {
			's_expander' => 172
		}
	},
	{#State 240
		ACTIONS => {
			'DATE' => 69,
			'INTEGER' => 42,
			'RBRACE_STAR' => 290,
			"," => 145,
			"}" => 291,
			'SYMBOL' => 11
		},
		GOTOS => {
			'symbol' => 4,
			's_word' => 144
		}
	},
	{#State 241
		ACTIONS => {
			'DATE' => 69,
			'INTEGER' => 42,
			'SYMBOL' => 11
		},
		GOTOS => {
			'symbol' => 105,
			's_semclass' => 292
		}
	},
	{#State 242
		ACTIONS => {
			'DATE' => 69,
			'INTEGER' => 42,
			"]" => 293,
			"," => 128,
			";" => 125,
			'SYMBOL' => 11
		},
		GOTOS => {
			'symbol' => 126,
			's_morphitem' => 127
		}
	},
	{#State 243
		DEFAULT => -198
	},
	{#State 244
		ACTIONS => {
			"%" => 51,
			'STAR_LBRACE' => 29,
			'SUFFIX' => 31,
			'DATE' => 69,
			"[" => 13,
			'REGEX' => 14,
			'SYMBOL' => 11,
			'INDEX' => 12,
			'PREFIX' => 33,
			"(" => 91,
			'AT_LBRACE' => 37,
			'KEYS' => 71,
			'DOLLAR_DOT' => 20,
			"^" => 1,
			'NEG_REGEX' => 39,
			'INFIX' => 59,
			'INTEGER' => 42,
			"\@" => 45,
			"\$" => 23,
			"*" => 44,
			'COLON_LBRACE' => 47,
			"<" => 65,
			"{" => 24
		},
		GOTOS => {
			'qw_chunk' => 6,
			's_infix' => 5,
			'qw_suffix' => 46,
			'qwk_indextuple' => 7,
			'qw_infix' => 8,
			'qw_anchor' => 41,
			'qw_regex' => 40,
			'qw_any' => 2,
			'symbol' => 4,
			'qw_with' => 3,
			'qw_suffix_set' => 54,
			'qw_prefix' => 15,
			'qw_set_exact' => 16,
			'qw_bareword' => 57,
			'qw_without' => 17,
			'qw_prefix_set' => 9,
			'qw_infix_set' => 10,
			'qw_morph' => 53,
			'regex' => 52,
			'qw_withor' => 62,
			'index' => 63,
			'qw_lemma' => 64,
			'qw_set_infl' => 27,
			's_index' => 25,
			'qw_thesaurus' => 21,
			's_prefix' => 58,
			'qc_word' => 294,
			's_word' => 35,
			'qw_listfile' => 32,
			'neg_regex' => 36,
			'qw_matchid' => 70,
			's_suffix' => 28,
			'qw_keys' => 66,
			'qw_exact' => 68
		}
	},
	{#State 245
		ACTIONS => {
			'STAR_LBRACE' => 29,
			"%" => 51,
			'SUFFIX' => 31,
			'DATE' => 69,
			'INDEX' => 12,
			'SYMBOL' => 11,
			'PREFIX' => 33,
			'REGEX' => 14,
			"[" => 13,
			'AT_LBRACE' => 37,
			'KEYS' => 71,
			"(" => 91,
			"^" => 1,
			'NEG_REGEX' => 39,
			'DOLLAR_DOT' => 20,
			'INFIX' => 59,
			'INTEGER' => 42,
			"*" => 44,
			"\@" => 45,
			"\$" => 23,
			"{" => 24,
			"<" => 65,
			'COLON_LBRACE' => 47
		},
		GOTOS => {
			'qw_chunk' => 6,
			's_infix' => 5,
			'qw_suffix' => 46,
			'qwk_indextuple' => 7,
			'qw_infix' => 8,
			'qw_regex' => 40,
			'qw_anchor' => 41,
			'qw_any' => 2,
			'symbol' => 4,
			'qw_with' => 3,
			'qw_suffix_set' => 54,
			'qw_prefix' => 15,
			'qw_set_exact' => 16,
			'qw_bareword' => 57,
			'qw_without' => 17,
			'qw_prefix_set' => 9,
			'qw_morph' => 53,
			'qw_infix_set' => 10,
			'regex' => 52,
			'qw_withor' => 62,
			'index' => 63,
			'qw_lemma' => 64,
			'qw_set_infl' => 27,
			's_index' => 25,
			'qw_thesaurus' => 21,
			's_prefix' => 58,
			'qc_word' => 295,
			's_word' => 35,
			'qw_listfile' => 32,
			'qw_matchid' => 70,
			'neg_regex' => 36,
			's_suffix' => 28,
			'qw_keys' => 66,
			'qw_exact' => 68
		}
	},
	{#State 246
		ACTIONS => {
			"(" => 91,
			'KEYS' => 71,
			'AT_LBRACE' => 37,
			"[" => 13,
			'REGEX' => 14,
			'PREFIX' => 33,
			'SYMBOL' => 11,
			'INDEX' => 12,
			'SUFFIX' => 31,
			'DATE' => 69,
			"%" => 51,
			'STAR_LBRACE' => 29,
			'COLON_LBRACE' => 47,
			"<" => 65,
			"{" => 24,
			"\@" => 45,
			"\$" => 23,
			"*" => 44,
			'INFIX' => 59,
			'INTEGER' => 42,
			'DOLLAR_DOT' => 20,
			"^" => 1,
			'NEG_REGEX' => 39
		},
		GOTOS => {
			'qw_exact' => 68,
			's_suffix' => 28,
			'qw_keys' => 66,
			'qw_matchid' => 70,
			'neg_regex' => 36,
			's_word' => 35,
			'qw_listfile' => 32,
			'qw_thesaurus' => 21,
			'qc_word' => 296,
			's_prefix' => 58,
			'qw_withor' => 62,
			'qw_set_infl' => 27,
			's_index' => 25,
			'qw_lemma' => 64,
			'index' => 63,
			'qw_morph' => 53,
			'qw_infix_set' => 10,
			'regex' => 52,
			'qw_prefix_set' => 9,
			'qw_prefix' => 15,
			'qw_suffix_set' => 54,
			'qw_bareword' => 57,
			'qw_without' => 17,
			'qw_set_exact' => 16,
			'qw_anchor' => 41,
			'qw_regex' => 40,
			'symbol' => 4,
			'qw_with' => 3,
			'qw_any' => 2,
			'qw_suffix' => 46,
			'qw_chunk' => 6,
			's_infix' => 5,
			'qw_infix' => 8,
			'qwk_indextuple' => 7
		}
	},
	{#State 247
		ACTIONS => {
			'STAR_LBRACE' => 29,
			"%" => 51,
			'SUFFIX' => 31,
			'DATE' => 69,
			'SYMBOL' => 11,
			'INDEX' => 12,
			'PREFIX' => 33,
			'REGEX' => 14,
			"[" => 13,
			'KEYS' => 71,
			'AT_LBRACE' => 37,
			"(" => 91,
			"^" => 1,
			'NEG_REGEX' => 39,
			'DOLLAR_DOT' => 20,
			'INTEGER' => 42,
			'INFIX' => 59,
			"*" => 44,
			"\$" => 23,
			"\@" => 45,
			"{" => 24,
			'COLON_LBRACE' => 47,
			"<" => 65
		},
		GOTOS => {
			'qw_suffix' => 46,
			's_infix' => 5,
			'qw_chunk' => 6,
			'qw_infix' => 8,
			'qwk_indextuple' => 7,
			'qw_anchor' => 41,
			'qw_regex' => 40,
			'qw_with' => 3,
			'symbol' => 4,
			'qw_any' => 2,
			'qw_prefix' => 15,
			'qw_suffix_set' => 54,
			'qw_without' => 17,
			'qw_bareword' => 57,
			'qw_set_exact' => 16,
			'regex' => 52,
			'qw_morph' => 53,
			'qw_infix_set' => 10,
			'qw_prefix_set' => 9,
			'qw_withor' => 62,
			's_index' => 25,
			'qw_set_infl' => 27,
			'index' => 63,
			'qw_lemma' => 64,
			'qw_thesaurus' => 21,
			'qc_word' => 297,
			's_prefix' => 58,
			'qw_matchid' => 70,
			'neg_regex' => 36,
			'qw_listfile' => 32,
			's_word' => 35,
			'qw_exact' => 68,
			'qw_keys' => 66,
			's_suffix' => 28
		}
	},
	{#State 248
		ACTIONS => {
			'SYMBOL' => 298,
			"=" => 86
		},
		DEFAULT => -111,
		GOTOS => {
			'qfbc_matchref' => 300,
			'matchid_eq' => 84,
			'sym_str' => 302,
			'qfb_ctxkey' => 301,
			'matchid' => 299
		}
	},
	{#State 249
		DEFAULT => -66
	},
	{#State 250
		DEFAULT => -67
	},
	{#State 251
		DEFAULT => -71
	},
	{#State 252
		DEFAULT => -37
	},
	{#State 253
		ACTIONS => {
			'INTEGER' => 132
		},
		GOTOS => {
			'int_str' => 135,
			'integer' => 303
		}
	},
	{#State 254
		DEFAULT => -261
	},
	{#State 255
		DEFAULT => -262
	},
	{#State 256
		DEFAULT => -39
	},
	{#State 257
		ACTIONS => {
			'INTEGER' => 304,
			'DATE' => 305
		},
		GOTOS => {
			'date' => 306
		}
	},
	{#State 258
		ACTIONS => {
			'SYMBOL' => 11,
			'INTEGER' => 42,
			'DATE' => 69
		},
		GOTOS => {
			'symbol' => 307,
			's_biblname' => 308
		}
	},
	{#State 259
		DEFAULT => -73
	},
	{#State 260
		ACTIONS => {
			"," => 310,
			'INTEGER' => 132,
			"]" => 309
		},
		GOTOS => {
			'int_str' => 311
		}
	},
	{#State 261
		ACTIONS => {
			'INTEGER' => 132
		},
		GOTOS => {
			'int_str' => 312
		}
	},
	{#State 262
		DEFAULT => -259
	},
	{#State 263
		DEFAULT => -47
	},
	{#State 264
		ACTIONS => {
			"," => 313
		},
		DEFAULT => -36
	},
	{#State 265
		ACTIONS => {
			"," => 314,
			"]" => 316,
			'INTEGER' => 304,
			'DATE' => 305
		},
		GOTOS => {
			'date' => 315
		}
	},
	{#State 266
		DEFAULT => -75
	},
	{#State 267
		DEFAULT => -45
	},
	{#State 268
		DEFAULT => -63
	},
	{#State 269
		DEFAULT => -43
	},
	{#State 270
		ACTIONS => {
			'HAS_FIELD' => 185,
			"!" => 270
		},
		GOTOS => {
			'qf_has_field' => 268
		}
	},
	{#State 271
		DEFAULT => -76
	},
	{#State 272
		DEFAULT => -70
	},
	{#State 273
		DEFAULT => -72
	},
	{#State 274
		ACTIONS => {
			'KW_DATE' => 317,
			'SYMBOL' => 11,
			'DATE' => 69,
			'INTEGER' => 42
		},
		GOTOS => {
			'symbol' => 307,
			's_biblname' => 318
		}
	},
	{#State 275
		ACTIONS => {
			'KW_DATE' => 320,
			'SYMBOL' => 11,
			'DATE' => 69,
			'INTEGER' => 42
		},
		GOTOS => {
			's_biblname' => 319,
			'symbol' => 307
		}
	},
	{#State 276
		DEFAULT => -69
	},
	{#State 277
		DEFAULT => -34
	},
	{#State 278
		ACTIONS => {
			'INTEGER' => 42,
			'DATE' => 69,
			'SYMBOL' => 11
		},
		GOTOS => {
			'symbol' => 321
		}
	},
	{#State 279
		ACTIONS => {
			'INTEGER' => 132,
			"]" => 322
		},
		GOTOS => {
			'int_str' => 323
		}
	},
	{#State 280
		DEFAULT => -68
	},
	{#State 281
		ACTIONS => {
			'INFIX' => 59,
			'INTEGER' => 42,
			'DOLLAR_DOT' => 20,
			'NEG_REGEX' => 39,
			"^" => 1,
			'COLON_LBRACE' => 47,
			"<" => 65,
			"{" => 24,
			"\$" => 23,
			"\@" => 45,
			"*" => 44,
			'SUFFIX' => 31,
			'DATE' => 69,
			"\"" => 30,
			"%" => 51,
			'STAR_LBRACE' => 29,
			"(" => 223,
			'AT_LBRACE' => 37,
			'KEYS' => 71,
			'REGEX' => 14,
			"[" => 13,
			'INDEX' => 12,
			'SYMBOL' => 11,
			'PREFIX' => 33
		},
		GOTOS => {
			'qwk_indextuple' => 7,
			'qw_infix' => 8,
			's_infix' => 5,
			'qw_chunk' => 6,
			'qw_suffix' => 46,
			'qw_any' => 2,
			'qw_with' => 3,
			'symbol' => 4,
			'qw_anchor' => 41,
			'qw_regex' => 40,
			'qw_set_exact' => 16,
			'qw_without' => 17,
			'qw_bareword' => 57,
			'qw_suffix_set' => 54,
			'qw_prefix' => 15,
			'qw_prefix_set' => 9,
			'regex' => 52,
			'qw_infix_set' => 10,
			'qw_morph' => 53,
			'qc_tokens' => 324,
			'qw_lemma' => 64,
			'index' => 63,
			's_index' => 25,
			'qw_set_infl' => 27,
			'qw_withor' => 62,
			's_prefix' => 58,
			'qc_word' => 22,
			'qw_thesaurus' => 21,
			'qw_listfile' => 32,
			's_word' => 35,
			'qw_matchid' => 70,
			'neg_regex' => 36,
			'qw_keys' => 66,
			's_suffix' => 28,
			'qc_phrase' => 67,
			'qw_exact' => 68
		}
	},
	{#State 282
		ACTIONS => {
			'KW_COMMENT' => 210,
			")" => 333,
			'LESS_BY_COUNT' => 326,
			'LESS_BY_KEY' => 325,
			'CLIMIT' => 329,
			'SAMPLE' => 334,
			'BY' => 338,
			'GREATER_BY_KEY' => 332,
			'GREATER_BY_COUNT' => 337
		},
		GOTOS => {
			'count_sample' => 336,
			'count_limit' => 330,
			'q_comment' => 335,
			'count_sort_op' => 339,
			'count_sort' => 328,
			'count_filter' => 331,
			'count_by' => 327
		}
	},
	{#State 283
		DEFAULT => -206
	},
	{#State 284
		ACTIONS => {
			'CLIMIT' => 329,
			'GREATER_BY_KEY' => 332,
			'GREATER_BY_COUNT' => 337,
			'SAMPLE' => 334,
			'BY' => 338,
			'KW_COMMENT' => 210,
			'LESS_BY_COUNT' => 326,
			'LESS_BY_KEY' => 325
		},
		DEFAULT => -210,
		GOTOS => {
			'count_sort_op' => 339,
			'count_by' => 327,
			'count_filter' => 331,
			'count_sort' => 328,
			'count_limit' => 330,
			'count_sample' => 336,
			'q_comment' => 335
		}
	},
	{#State 285
		ACTIONS => {
			")" => 340
		}
	},
	{#State 286
		DEFAULT => -232
	},
	{#State 287
		DEFAULT => -186
	},
	{#State 288
		DEFAULT => -190
	},
	{#State 289
		DEFAULT => -176
	},
	{#State 290
		DEFAULT => -188
	},
	{#State 291
		DEFAULT => -225,
		GOTOS => {
			'l_txchain' => 341
		}
	},
	{#State 292
		ACTIONS => {
			"}" => 342
		}
	},
	{#State 293
		DEFAULT => -194
	},
	{#State 294
		ACTIONS => {
			'WITHOR' => 85,
			"=" => 86,
			'WITH' => 83,
			'WITHOUT' => 81
		},
		DEFAULT => -223,
		GOTOS => {
			'matchid_eq' => 84,
			'matchid' => 82
		}
	},
	{#State 295
		ACTIONS => {
			'WITHOUT' => 81,
			'WITHOR' => 85,
			"=" => 86,
			'WITH' => 83
		},
		DEFAULT => -224,
		GOTOS => {
			'matchid_eq' => 84,
			'matchid' => 82
		}
	},
	{#State 296
		ACTIONS => {
			'WITH' => 83,
			"=" => 86,
			'WITHOR' => 85,
			'WITHOUT' => 81
		},
		DEFAULT => -221,
		GOTOS => {
			'matchid' => 82,
			'matchid_eq' => 84
		}
	},
	{#State 297
		ACTIONS => {
			'WITHOUT' => 81,
			'WITHOR' => 85,
			"=" => 86,
			'WITH' => 83
		},
		DEFAULT => -222,
		GOTOS => {
			'matchid_eq' => 84,
			'matchid' => 82
		}
	},
	{#State 298
		DEFAULT => -268
	},
	{#State 299
		DEFAULT => -112
	},
	{#State 300
		ACTIONS => {
			'INTEGER' => 132,
			"+" => 345,
			"-" => 343
		},
		DEFAULT => -113,
		GOTOS => {
			'qfbc_offset' => 344,
			'int_str' => 135,
			'integer' => 346
		}
	},
	{#State 301
		ACTIONS => {
			"]" => 349,
			"," => 347
		},
		GOTOS => {
			'qfb_bibl_ne' => 348
		}
	},
	{#State 302
		ACTIONS => {
			"=" => 86
		},
		DEFAULT => -111,
		GOTOS => {
			'matchid' => 299,
			'qfbc_matchref' => 350,
			'matchid_eq' => 84
		}
	},
	{#State 303
		ACTIONS => {
			"]" => 351
		}
	},
	{#State 304
		DEFAULT => -282
	},
	{#State 305
		DEFAULT => -281
	},
	{#State 306
		ACTIONS => {
			"]" => 352
		}
	},
	{#State 307
		DEFAULT => -260
	},
	{#State 308
		ACTIONS => {
			"," => 353
		}
	},
	{#State 309
		DEFAULT => -86
	},
	{#State 310
		ACTIONS => {
			"]" => 354,
			'INTEGER' => 132
		},
		GOTOS => {
			'int_str' => 355
		}
	},
	{#State 311
		ACTIONS => {
			"," => 357,
			"]" => 356
		}
	},
	{#State 312
		ACTIONS => {
			"]" => 358
		}
	},
	{#State 313
		ACTIONS => {
			'SYMBOL' => 11,
			'DATE' => 69,
			'INTEGER' => 42
		},
		GOTOS => {
			'symbol' => 262,
			's_subcorpus' => 359
		}
	},
	{#State 314
		ACTIONS => {
			'DATE' => 305,
			'INTEGER' => 304
		},
		GOTOS => {
			'date' => 360
		}
	},
	{#State 315
		ACTIONS => {
			"," => 361,
			"]" => 362
		}
	},
	{#State 316
		DEFAULT => -93
	},
	{#State 317
		ACTIONS => {
			"," => 347
		},
		DEFAULT => -98,
		GOTOS => {
			'qfb_bibl_ne' => 363,
			'qfb_bibl' => 364
		}
	},
	{#State 318
		ACTIONS => {
			"," => 347
		},
		DEFAULT => -98,
		GOTOS => {
			'qfb_bibl' => 365,
			'qfb_bibl_ne' => 363
		}
	},
	{#State 319
		ACTIONS => {
			"," => 347
		},
		DEFAULT => -98,
		GOTOS => {
			'qfb_bibl' => 366,
			'qfb_bibl_ne' => 363
		}
	},
	{#State 320
		ACTIONS => {
			"," => 347
		},
		DEFAULT => -98,
		GOTOS => {
			'qfb_bibl_ne' => 363,
			'qfb_bibl' => 367
		}
	},
	{#State 321
		ACTIONS => {
			"]" => 368
		}
	},
	{#State 322
		DEFAULT => -79
	},
	{#State 323
		ACTIONS => {
			"]" => 369
		}
	},
	{#State 324
		ACTIONS => {
			"=" => 86,
			"," => 370
		},
		GOTOS => {
			'matchid' => 108,
			'matchid_eq' => 84
		}
	},
	{#State 325
		DEFAULT => -18
	},
	{#State 326
		DEFAULT => -20
	},
	{#State 327
		DEFAULT => -6
	},
	{#State 328
		DEFAULT => -9
	},
	{#State 329
		ACTIONS => {
			"[" => 372,
			'INTEGER' => 132
		},
		GOTOS => {
			'integer' => 371,
			'int_str' => 135
		}
	},
	{#State 330
		DEFAULT => -8
	},
	{#State 331
		DEFAULT => -5
	},
	{#State 332
		DEFAULT => -19
	},
	{#State 333
		DEFAULT => -4,
		GOTOS => {
			'count_filters' => 373
		}
	},
	{#State 334
		ACTIONS => {
			'INTEGER' => 132,
			"[" => 374
		},
		GOTOS => {
			'integer' => 375,
			'int_str' => 135
		}
	},
	{#State 335
		DEFAULT => -10
	},
	{#State 336
		DEFAULT => -7
	},
	{#State 337
		DEFAULT => -21
	},
	{#State 338
		ACTIONS => {
			'INTEGER' => 42,
			"*" => 378,
			"\@" => 379,
			"\$" => 142,
			'KW_FILENAME' => 383,
			'KW_FILEID' => 384,
			'DATE' => 69,
			'KW_DATE' => 377,
			"(" => 380,
			'INDEX' => 12,
			'SYMBOL' => 11,
			"[" => 386
		},
		DEFAULT => -227,
		GOTOS => {
			'count_key' => 382,
			'l_countkeys' => 376,
			'index' => 63,
			's_index' => 381,
			's_biblname' => 385,
			'symbol' => 307
		}
	},
	{#State 339
		ACTIONS => {
			"[" => 388
		},
		DEFAULT => -22,
		GOTOS => {
			'count_sort_minmax' => 387
		}
	},
	{#State 340
		DEFAULT => -207
	},
	{#State 341
		ACTIONS => {
			'EXPANDER' => 173
		},
		DEFAULT => -178,
		GOTOS => {
			's_expander' => 172
		}
	},
	{#State 342
		DEFAULT => -192
	},
	{#State 343
		ACTIONS => {
			'INTEGER' => 132
		},
		GOTOS => {
			'integer' => 389,
			'int_str' => 135
		}
	},
	{#State 344
		DEFAULT => -110
	},
	{#State 345
		ACTIONS => {
			'INTEGER' => 132
		},
		GOTOS => {
			'int_str' => 135,
			'integer' => 390
		}
	},
	{#State 346
		DEFAULT => -114
	},
	{#State 347
		ACTIONS => {
			"," => 391,
			'SYMBOL' => 11,
			'DATE' => 69,
			'INTEGER' => 42
		},
		DEFAULT => -100,
		GOTOS => {
			'symbol' => 392
		}
	},
	{#State 348
		ACTIONS => {
			"]" => 393
		}
	},
	{#State 349
		DEFAULT => -107
	},
	{#State 350
		ACTIONS => {
			'INTEGER' => 132,
			"+" => 345,
			"-" => 343
		},
		DEFAULT => -113,
		GOTOS => {
			'integer' => 346,
			'int_str' => 135,
			'qfbc_offset' => 394
		}
	},
	{#State 351
		DEFAULT => -38
	},
	{#State 352
		DEFAULT => -77
	},
	{#State 353
		ACTIONS => {
			"{" => 397,
			'SYMBOL' => 11,
			'PREFIX' => 33,
			'REGEX' => 14,
			'INTEGER' => 42,
			'INFIX' => 59,
			'SUFFIX' => 31,
			'DATE' => 69,
			'NEG_REGEX' => 39
		},
		GOTOS => {
			's_suffix' => 396,
			's_infix' => 398,
			'neg_regex' => 395,
			's_prefix' => 400,
			'symbol' => 399,
			'regex' => 401
		}
	},
	{#State 354
		DEFAULT => -87
	},
	{#State 355
		ACTIONS => {
			"]" => 402
		}
	},
	{#State 356
		DEFAULT => -88
	},
	{#State 357
		ACTIONS => {
			"]" => 404,
			'INTEGER' => 132
		},
		GOTOS => {
			'int_str' => 403
		}
	},
	{#State 358
		DEFAULT => -74
	},
	{#State 359
		DEFAULT => -48
	},
	{#State 360
		ACTIONS => {
			"]" => 405
		}
	},
	{#State 361
		ACTIONS => {
			"]" => 406,
			'INTEGER' => 304,
			'DATE' => 305
		},
		GOTOS => {
			'date' => 407
		}
	},
	{#State 362
		DEFAULT => -94
	},
	{#State 363
		DEFAULT => -99
	},
	{#State 364
		ACTIONS => {
			"]" => 408
		}
	},
	{#State 365
		ACTIONS => {
			"]" => 409
		}
	},
	{#State 366
		ACTIONS => {
			"]" => 410
		}
	},
	{#State 367
		ACTIONS => {
			"]" => 411
		}
	},
	{#State 368
		DEFAULT => -35
	},
	{#State 369
		DEFAULT => -80
	},
	{#State 370
		ACTIONS => {
			"{" => 24,
			'COLON_LBRACE' => 47,
			"<" => 65,
			"*" => 44,
			"\@" => 45,
			"\$" => 23,
			'INFIX' => 59,
			'INTEGER' => 413,
			'NEG_REGEX' => 39,
			"^" => 1,
			'DOLLAR_DOT' => 20,
			'AT_LBRACE' => 37,
			'KEYS' => 71,
			"(" => 223,
			'PREFIX' => 33,
			'INDEX' => 12,
			'SYMBOL' => 11,
			"[" => 13,
			'REGEX' => 14,
			"\"" => 30,
			'SUFFIX' => 31,
			'DATE' => 69,
			'STAR_LBRACE' => 29,
			"%" => 51
		},
		GOTOS => {
			'qc_phrase' => 67,
			'qw_exact' => 68,
			'qw_keys' => 66,
			's_suffix' => 28,
			'integer' => 412,
			'qw_matchid' => 70,
			'neg_regex' => 36,
			'qw_listfile' => 32,
			's_word' => 35,
			'qc_word' => 22,
			's_prefix' => 58,
			'qw_thesaurus' => 21,
			's_index' => 25,
			'qw_set_infl' => 27,
			'index' => 63,
			'qw_lemma' => 64,
			'qw_withor' => 62,
			'regex' => 52,
			'qw_infix_set' => 10,
			'qw_morph' => 53,
			'qw_prefix_set' => 9,
			'qc_tokens' => 414,
			'qw_without' => 17,
			'qw_bareword' => 57,
			'int_str' => 135,
			'qw_set_exact' => 16,
			'qw_prefix' => 15,
			'qw_suffix_set' => 54,
			'qw_with' => 3,
			'symbol' => 4,
			'qw_any' => 2,
			'qw_anchor' => 41,
			'qw_regex' => 40,
			'qw_infix' => 8,
			'qwk_indextuple' => 7,
			'qw_suffix' => 46,
			'qw_chunk' => 6,
			's_infix' => 5
		}
	},
	{#State 371
		DEFAULT => -15
	},
	{#State 372
		ACTIONS => {
			'INTEGER' => 132
		},
		GOTOS => {
			'integer' => 415,
			'int_str' => 135
		}
	},
	{#State 373
		ACTIONS => {
			'KW_COMMENT' => 210,
			'LESS_BY_COUNT' => 326,
			'LESS_BY_KEY' => 325,
			'CLIMIT' => 329,
			'BY' => 338,
			'SAMPLE' => 334,
			'GREATER_BY_KEY' => 332,
			'GREATER_BY_COUNT' => 337
		},
		DEFAULT => -3,
		GOTOS => {
			'q_comment' => 335,
			'count_sample' => 336,
			'count_limit' => 330,
			'count_filter' => 331,
			'count_sort' => 328,
			'count_by' => 327,
			'count_sort_op' => 339
		}
	},
	{#State 374
		ACTIONS => {
			'INTEGER' => 132
		},
		GOTOS => {
			'int_str' => 135,
			'integer' => 416
		}
	},
	{#State 375
		DEFAULT => -13
	},
	{#State 376
		ACTIONS => {
			"," => 417
		},
		DEFAULT => -11
	},
	{#State 377
		ACTIONS => {
			"/" => 418
		},
		DEFAULT => -237
	},
	{#State 378
		DEFAULT => -233
	},
	{#State 379
		ACTIONS => {
			'DATE' => 69,
			'INTEGER' => 42,
			'SYMBOL' => 11
		},
		GOTOS => {
			'symbol' => 419
		}
	},
	{#State 380
		ACTIONS => {
			"(" => 380,
			'SYMBOL' => 11,
			"*" => 378,
			'INDEX' => 12,
			"\@" => 379,
			"\$" => 142,
			'KW_FILENAME' => 383,
			'INTEGER' => 42,
			'KW_FILEID' => 384,
			'DATE' => 69,
			'KW_DATE' => 377
		},
		GOTOS => {
			's_index' => 381,
			's_biblname' => 385,
			'symbol' => 307,
			'index' => 63,
			'count_key' => 420
		}
	},
	{#State 381
		ACTIONS => {
			"=" => 86
		},
		DEFAULT => -243,
		GOTOS => {
			'matchid_eq' => 84,
			'matchid' => 422,
			'ck_matchid' => 421
		}
	},
	{#State 382
		ACTIONS => {
			"~" => 423
		},
		DEFAULT => -228
	},
	{#State 383
		DEFAULT => -236
	},
	{#State 384
		DEFAULT => -235
	},
	{#State 385
		DEFAULT => -239
	},
	{#State 386
		ACTIONS => {
			'DATE' => 69,
			'KW_FILEID' => 384,
			'INTEGER' => 42,
			'KW_DATE' => 377,
			"(" => 380,
			'KW_FILENAME' => 383,
			"\@" => 379,
			"\$" => 142,
			'INDEX' => 12,
			"*" => 378,
			'SYMBOL' => 11
		},
		DEFAULT => -227,
		GOTOS => {
			'count_key' => 382,
			's_index' => 381,
			's_biblname' => 385,
			'symbol' => 307,
			'l_countkeys' => 424,
			'index' => 63
		}
	},
	{#State 387
		DEFAULT => -17
	},
	{#State 388
		ACTIONS => {
			'DATE' => 69,
			'INTEGER' => 42,
			"]" => 425,
			"," => 427,
			'SYMBOL' => 11
		},
		GOTOS => {
			'symbol' => 426
		}
	},
	{#State 389
		DEFAULT => -116
	},
	{#State 390
		DEFAULT => -115
	},
	{#State 391
		ACTIONS => {
			'SYMBOL' => 11,
			'DATE' => 69,
			'INTEGER' => 42
		},
		DEFAULT => -101,
		GOTOS => {
			'symbol' => 428
		}
	},
	{#State 392
		ACTIONS => {
			"," => 429
		},
		DEFAULT => -102
	},
	{#State 393
		DEFAULT => -108
	},
	{#State 394
		DEFAULT => -109
	},
	{#State 395
		ACTIONS => {
			"]" => 430
		}
	},
	{#State 396
		ACTIONS => {
			"]" => 431
		}
	},
	{#State 397
		DEFAULT => -212,
		GOTOS => {
			'l_set' => 432
		}
	},
	{#State 398
		ACTIONS => {
			"]" => 433
		}
	},
	{#State 399
		ACTIONS => {
			"]" => 434
		}
	},
	{#State 400
		ACTIONS => {
			"]" => 435
		}
	},
	{#State 401
		ACTIONS => {
			"]" => 436
		}
	},
	{#State 402
		DEFAULT => -91
	},
	{#State 403
		ACTIONS => {
			"]" => 437
		}
	},
	{#State 404
		DEFAULT => -89
	},
	{#State 405
		DEFAULT => -97
	},
	{#State 406
		DEFAULT => -95
	},
	{#State 407
		ACTIONS => {
			"]" => 438
		}
	},
	{#State 408
		DEFAULT => -82
	},
	{#State 409
		DEFAULT => -84
	},
	{#State 410
		DEFAULT => -83
	},
	{#State 411
		DEFAULT => -81
	},
	{#State 412
		ACTIONS => {
			")" => 439
		}
	},
	{#State 413
		ACTIONS => {
			")" => -279
		},
		DEFAULT => -264
	},
	{#State 414
		ACTIONS => {
			"=" => 86,
			"," => 440
		},
		GOTOS => {
			'matchid_eq' => 84,
			'matchid' => 108
		}
	},
	{#State 415
		ACTIONS => {
			"]" => 441
		}
	},
	{#State 416
		ACTIONS => {
			"]" => 442
		}
	},
	{#State 417
		ACTIONS => {
			"(" => 380,
			'INDEX' => 12,
			'SYMBOL' => 11,
			"*" => 378,
			"\$" => 142,
			"\@" => 379,
			'KW_FILENAME' => 383,
			'INTEGER' => 42,
			'KW_FILEID' => 384,
			'DATE' => 69,
			'KW_DATE' => 377
		},
		GOTOS => {
			'index' => 63,
			's_biblname' => 385,
			'symbol' => 307,
			's_index' => 381,
			'count_key' => 443
		}
	},
	{#State 418
		ACTIONS => {
			'INTEGER' => 132
		},
		GOTOS => {
			'integer' => 444,
			'int_str' => 135
		}
	},
	{#State 419
		DEFAULT => -234
	},
	{#State 420
		ACTIONS => {
			")" => 445,
			"~" => 423
		}
	},
	{#State 421
		ACTIONS => {
			"+" => 447,
			"-" => 448,
			'INTEGER' => 132
		},
		DEFAULT => -245,
		GOTOS => {
			'int_str' => 135,
			'ck_offset' => 446,
			'integer' => 449
		}
	},
	{#State 422
		DEFAULT => -244
	},
	{#State 423
		ACTIONS => {
			'REGEX_SEARCH' => 451
		},
		GOTOS => {
			'replace_regex' => 450
		}
	},
	{#State 424
		ACTIONS => {
			"," => 417,
			"]" => 452
		}
	},
	{#State 425
		DEFAULT => -23
	},
	{#State 426
		ACTIONS => {
			"," => 454,
			"]" => 453
		}
	},
	{#State 427
		ACTIONS => {
			'DATE' => 69,
			'INTEGER' => 42,
			"]" => 456,
			'SYMBOL' => 11
		},
		GOTOS => {
			'symbol' => 455
		}
	},
	{#State 428
		DEFAULT => -104
	},
	{#State 429
		ACTIONS => {
			'DATE' => 69,
			'INTEGER' => 42,
			'SYMBOL' => 11
		},
		DEFAULT => -103,
		GOTOS => {
			'symbol' => 457
		}
	},
	{#State 430
		DEFAULT => -58
	},
	{#State 431
		DEFAULT => -60
	},
	{#State 432
		ACTIONS => {
			'DATE' => 69,
			'INTEGER' => 42,
			"}" => 458,
			"," => 145,
			'SYMBOL' => 11
		},
		GOTOS => {
			'symbol' => 4,
			's_word' => 144
		}
	},
	{#State 433
		DEFAULT => -61
	},
	{#State 434
		DEFAULT => -56
	},
	{#State 435
		DEFAULT => -59
	},
	{#State 436
		DEFAULT => -57
	},
	{#State 437
		DEFAULT => -90
	},
	{#State 438
		DEFAULT => -96
	},
	{#State 439
		DEFAULT => -132
	},
	{#State 440
		ACTIONS => {
			'INTEGER' => 132
		},
		GOTOS => {
			'int_str' => 135,
			'integer' => 459
		}
	},
	{#State 441
		DEFAULT => -16
	},
	{#State 442
		DEFAULT => -14
	},
	{#State 443
		ACTIONS => {
			"~" => 423
		},
		DEFAULT => -229
	},
	{#State 444
		DEFAULT => -238
	},
	{#State 445
		DEFAULT => -242
	},
	{#State 446
		DEFAULT => -240
	},
	{#State 447
		ACTIONS => {
			'INTEGER' => 132
		},
		GOTOS => {
			'integer' => 460,
			'int_str' => 135
		}
	},
	{#State 448
		ACTIONS => {
			'INTEGER' => 132
		},
		GOTOS => {
			'int_str' => 135,
			'integer' => 461
		}
	},
	{#State 449
		DEFAULT => -246
	},
	{#State 450
		DEFAULT => -241
	},
	{#State 451
		ACTIONS => {
			'REGEX_REPLACE' => 462
		}
	},
	{#State 452
		DEFAULT => -12
	},
	{#State 453
		DEFAULT => -25
	},
	{#State 454
		ACTIONS => {
			'SYMBOL' => 11,
			'DATE' => 69,
			"]" => 464,
			'INTEGER' => 42
		},
		GOTOS => {
			'symbol' => 463
		}
	},
	{#State 455
		ACTIONS => {
			"]" => 465
		}
	},
	{#State 456
		DEFAULT => -24
	},
	{#State 457
		DEFAULT => -105
	},
	{#State 458
		ACTIONS => {
			"]" => 466
		}
	},
	{#State 459
		ACTIONS => {
			")" => 467
		}
	},
	{#State 460
		DEFAULT => -247
	},
	{#State 461
		DEFAULT => -248
	},
	{#State 462
		ACTIONS => {
			'REGOPT' => 468
		},
		DEFAULT => -277
	},
	{#State 463
		ACTIONS => {
			"]" => 469
		}
	},
	{#State 464
		DEFAULT => -26
	},
	{#State 465
		DEFAULT => -27
	},
	{#State 466
		DEFAULT => -62
	},
	{#State 467
		DEFAULT => -133
	},
	{#State 468
		DEFAULT => -278
	},
	{#State 469
		DEFAULT => -28
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
