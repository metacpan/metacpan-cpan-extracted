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
			'REGEX' => 37,
			'INDEX' => 23,
			"\$" => 5,
			'DATE' => 4,
			'INTEGER' => 40,
			'STAR_LBRACE' => 42,
			'NEG_REGEX' => 7,
			'SUFFIX' => 26,
			"!" => 8,
			"\@" => 28,
			'KEYS' => 9,
			'INFIX' => 10,
			"(" => 59,
			'COUNT' => 31,
			'AT_LBRACE' => 11,
			"[" => 47,
			'DOLLAR_DOT' => 12,
			"\"" => 62,
			"{" => 64,
			'SYMBOL' => 66,
			'COLON_LBRACE' => 52,
			"^" => 68,
			"%" => 35,
			"<" => 20,
			'PREFIX' => 70,
			"*" => 36,
			'NEAR' => 72
		},
		GOTOS => {
			'qc_near' => 21,
			'qw_keys' => 54,
			'neg_regex' => 18,
			'query_conditions' => 53,
			'qw_with' => 19,
			'count_query' => 17,
			'qw_infix' => 16,
			'qw_any' => 15,
			'qw_matchid' => 49,
			's_infix' => 14,
			'qc_word' => 50,
			'qw_lemma' => 51,
			'qw_set_exact' => 48,
			'qw_bareword' => 13,
			'qw_infix_set' => 46,
			'qw_listfile' => 45,
			'qw_exact' => 44,
			'regex' => 43,
			'qw_prefix' => 41,
			'qw_chunk' => 6,
			'query' => 38,
			'qw_prefix_set' => 39,
			'qw_set_infl' => 2,
			'qc_boolean' => 1,
			'qw_suffix_set' => 3,
			's_word' => 71,
			's_index' => 69,
			'qw_suffix' => 34,
			'qw_morph' => 67,
			'qc_concat' => 65,
			'symbol' => 33,
			's_prefix' => 61,
			'qc_phrase' => 63,
			'qc_basic' => 32,
			'qc_matchid' => 58,
			'q_clause' => 30,
			'qw_without' => 60,
			'qw_withor' => 29,
			's_suffix' => 57,
			'index' => 25,
			'qw_thesaurus' => 27,
			'qw_regex' => 24,
			'qc_tokens' => 56,
			'qwk_indextuple' => 55,
			'qw_anchor' => 22
		}
	},
	{#State 1
		DEFAULT => -114
	},
	{#State 2
		DEFAULT => -141
	},
	{#State 3
		DEFAULT => -148
	},
	{#State 4
		DEFAULT => -261
	},
	{#State 5
		ACTIONS => {
			"(" => 73
		},
		DEFAULT => -245
	},
	{#State 6
		DEFAULT => -152
	},
	{#State 7
		ACTIONS => {
			'REGOPT' => 74
		},
		DEFAULT => -271
	},
	{#State 8
		ACTIONS => {
			"\@" => 28,
			'KEYS' => 9,
			'INFIX' => 10,
			"(" => 59,
			'AT_LBRACE' => 11,
			"[" => 47,
			'DOLLAR_DOT' => 12,
			"\"" => 62,
			'REGEX' => 37,
			'INDEX' => 23,
			'DATE' => 4,
			"\$" => 5,
			'INTEGER' => 40,
			'STAR_LBRACE' => 42,
			'NEG_REGEX' => 7,
			'SUFFIX' => 26,
			"!" => 8,
			"%" => 35,
			"<" => 20,
			'PREFIX' => 70,
			"*" => 36,
			'NEAR' => 72,
			"{" => 64,
			'SYMBOL' => 66,
			'COLON_LBRACE' => 52,
			"^" => 68
		},
		GOTOS => {
			'neg_regex' => 18,
			'qw_with' => 19,
			'qw_infix' => 16,
			's_infix' => 14,
			'qc_word' => 50,
			'qw_matchid' => 49,
			'qw_any' => 15,
			'qw_lemma' => 51,
			'qc_near' => 21,
			'qw_keys' => 54,
			'regex' => 43,
			'qw_prefix' => 41,
			'qw_chunk' => 6,
			'qw_prefix_set' => 39,
			'qc_boolean' => 1,
			'qw_set_infl' => 2,
			'qw_suffix_set' => 3,
			'qw_bareword' => 13,
			'qw_set_exact' => 48,
			'qw_infix_set' => 46,
			'qw_listfile' => 45,
			'qw_exact' => 44,
			'qw_morph' => 67,
			'qw_suffix' => 34,
			'qc_concat' => 65,
			'symbol' => 33,
			's_word' => 71,
			's_index' => 69,
			'index' => 25,
			'qw_thesaurus' => 27,
			'qw_regex' => 24,
			'qc_tokens' => 56,
			'qwk_indextuple' => 55,
			'qw_anchor' => 22,
			'qc_basic' => 32,
			's_prefix' => 61,
			'qc_phrase' => 63,
			'qc_matchid' => 58,
			'qw_without' => 60,
			'q_clause' => 75,
			'qw_withor' => 29,
			's_suffix' => 57
		}
	},
	{#State 9
		ACTIONS => {
			"(" => 76
		}
	},
	{#State 10
		DEFAULT => -267
	},
	{#State 11
		DEFAULT => -208,
		GOTOS => {
			'l_set' => 77
		}
	},
	{#State 12
		ACTIONS => {
			'DATE' => 4,
			'SYMBOL' => 66,
			'INTEGER' => 40,
			"=" => 78
		},
		GOTOS => {
			'symbol' => 79
		}
	},
	{#State 13
		DEFAULT => -137
	},
	{#State 14
		DEFAULT => -179
	},
	{#State 15
		DEFAULT => -140
	},
	{#State 16
		DEFAULT => -143
	},
	{#State 17
		DEFAULT => -2
	},
	{#State 18
		DEFAULT => -167
	},
	{#State 19
		DEFAULT => -155
	},
	{#State 20
		ACTIONS => {
			'DATE' => 4,
			'SYMBOL' => 66,
			'INTEGER' => 40
		},
		GOTOS => {
			'symbol' => 81,
			's_filename' => 80
		}
	},
	{#State 21
		ACTIONS => {
			"=" => 82
		},
		DEFAULT => -127,
		GOTOS => {
			'matchid_eq' => 83,
			'matchid' => 84
		}
	},
	{#State 22
		DEFAULT => -153
	},
	{#State 23
		DEFAULT => -263
	},
	{#State 24
		DEFAULT => -139
	},
	{#State 25
		DEFAULT => -246
	},
	{#State 26
		DEFAULT => -266
	},
	{#State 27
		DEFAULT => -149
	},
	{#State 28
		ACTIONS => {
			'SYMBOL' => 66,
			'INTEGER' => 40,
			'DATE' => 4
		},
		GOTOS => {
			's_word' => 85,
			'symbol' => 33
		}
	},
	{#State 29
		DEFAULT => -157
	},
	{#State 30
		ACTIONS => {
			'OP_BOOL_OR' => 88,
			"=" => 82,
			'OP_BOOL_AND' => 86
		},
		DEFAULT => -29,
		GOTOS => {
			'q_filters' => 89,
			'matchid_eq' => 83,
			'matchid' => 87
		}
	},
	{#State 31
		ACTIONS => {
			"(" => 90
		}
	},
	{#State 32
		ACTIONS => {
			"<" => 20,
			'DOLLAR_DOT' => 12,
			'AT_LBRACE' => 11,
			'INFIX' => 10,
			'KEYS' => 9,
			'NEG_REGEX' => 7,
			"\$" => 5,
			'DATE' => 4,
			"*" => 36,
			"%" => 35,
			"\@" => 28,
			'SUFFIX' => 26,
			'INDEX' => 23,
			'COLON_LBRACE' => 52,
			"[" => 47,
			'STAR_LBRACE' => 42,
			'INTEGER' => 40,
			'REGEX' => 37,
			'NEAR' => 72,
			'PREFIX' => 70,
			"^" => 68,
			'SYMBOL' => 66,
			"{" => 64,
			"\"" => 62,
			"(" => 92
		},
		DEFAULT => -113,
		GOTOS => {
			'index' => 25,
			'qw_thesaurus' => 27,
			'qw_regex' => 24,
			'qc_tokens' => 56,
			'qwk_indextuple' => 55,
			'qw_anchor' => 22,
			'qc_phrase' => 63,
			's_prefix' => 61,
			'qc_basic' => 91,
			'qw_without' => 60,
			'qw_withor' => 29,
			's_suffix' => 57,
			'qw_morph' => 67,
			'qw_suffix' => 34,
			'symbol' => 33,
			's_word' => 71,
			's_index' => 69,
			'regex' => 43,
			'qw_chunk' => 6,
			'qw_prefix' => 41,
			'qw_prefix_set' => 39,
			'qw_set_infl' => 2,
			'qw_suffix_set' => 3,
			'qw_bareword' => 13,
			'qw_set_exact' => 48,
			'qw_infix_set' => 46,
			'qw_listfile' => 45,
			'qw_exact' => 44,
			'neg_regex' => 18,
			'qw_with' => 19,
			'qw_infix' => 16,
			'qw_any' => 15,
			's_infix' => 14,
			'qw_matchid' => 49,
			'qc_word' => 50,
			'qw_lemma' => 51,
			'qc_near' => 21,
			'qw_keys' => 54
		}
	},
	{#State 33
		DEFAULT => -249
	},
	{#State 34
		DEFAULT => -147
	},
	{#State 35
		ACTIONS => {
			'SYMBOL' => 66,
			'INTEGER' => 40,
			'DATE' => 4
		},
		GOTOS => {
			'symbol' => 94,
			's_lemma' => 93
		}
	},
	{#State 36
		DEFAULT => -169
	},
	{#State 37
		ACTIONS => {
			'REGOPT' => 95
		},
		DEFAULT => -269
	},
	{#State 38
		ACTIONS => {
			'' => 96
		}
	},
	{#State 39
		DEFAULT => -146
	},
	{#State 40
		DEFAULT => -260
	},
	{#State 41
		DEFAULT => -145
	},
	{#State 42
		DEFAULT => -208,
		GOTOS => {
			'l_set' => 97
		}
	},
	{#State 43
		DEFAULT => -165
	},
	{#State 44
		DEFAULT => -138
	},
	{#State 45
		DEFAULT => -154
	},
	{#State 46
		DEFAULT => -144
	},
	{#State 47
		DEFAULT => -211,
		GOTOS => {
			'l_morph' => 98
		}
	},
	{#State 48
		DEFAULT => -142
	},
	{#State 49
		DEFAULT => -159
	},
	{#State 50
		ACTIONS => {
			'WITH' => 100,
			'WITHOUT' => 99,
			'WITHOR' => 101,
			"=" => 82
		},
		DEFAULT => -132,
		GOTOS => {
			'matchid_eq' => 83,
			'matchid' => 102
		}
	},
	{#State 51
		DEFAULT => -151
	},
	{#State 52
		ACTIONS => {
			'INTEGER' => 40,
			'SYMBOL' => 66,
			'DATE' => 4
		},
		GOTOS => {
			's_semclass' => 103,
			'symbol' => 104
		}
	},
	{#State 53
		DEFAULT => -1
	},
	{#State 54
		DEFAULT => -158
	},
	{#State 55
		ACTIONS => {
			"=" => 105
		}
	},
	{#State 56
		ACTIONS => {
			"=" => 82
		},
		DEFAULT => -126,
		GOTOS => {
			'matchid' => 106,
			'matchid_eq' => 83
		}
	},
	{#State 57
		DEFAULT => -177
	},
	{#State 58
		DEFAULT => -116
	},
	{#State 59
		ACTIONS => {
			'COLON_LBRACE' => 52,
			"^" => 68,
			"{" => 64,
			'SYMBOL' => 66,
			'PREFIX' => 70,
			"*" => 36,
			'NEAR' => 72,
			"%" => 35,
			"<" => 20,
			'STAR_LBRACE' => 42,
			'NEG_REGEX' => 7,
			'SUFFIX' => 26,
			"!" => 8,
			'REGEX' => 37,
			"\$" => 5,
			'INDEX' => 23,
			'DATE' => 4,
			'INTEGER' => 40,
			'AT_LBRACE' => 11,
			'DOLLAR_DOT' => 12,
			"[" => 47,
			"\"" => 62,
			"\@" => 28,
			'KEYS' => 9,
			'INFIX' => 10,
			"(" => 59
		},
		GOTOS => {
			'qw_any' => 15,
			's_infix' => 14,
			'qw_matchid' => 49,
			'qc_word' => 110,
			'qw_lemma' => 51,
			'qw_infix' => 16,
			'neg_regex' => 18,
			'qw_with' => 19,
			'qc_near' => 107,
			'qw_keys' => 54,
			'qc_boolean' => 108,
			'qw_set_infl' => 2,
			'qw_suffix_set' => 3,
			'qw_prefix_set' => 39,
			'qw_prefix' => 41,
			'qw_chunk' => 6,
			'regex' => 43,
			'qw_exact' => 44,
			'qw_listfile' => 45,
			'qw_infix_set' => 46,
			'qw_set_exact' => 48,
			'qw_bareword' => 13,
			'symbol' => 33,
			'qc_concat' => 111,
			'qw_morph' => 67,
			'qw_suffix' => 34,
			's_index' => 69,
			's_word' => 71,
			'qwk_indextuple' => 55,
			'qw_anchor' => 22,
			'qw_regex' => 24,
			'qc_tokens' => 56,
			'index' => 25,
			'qw_thesaurus' => 27,
			'qw_withor' => 29,
			's_suffix' => 57,
			'qc_matchid' => 112,
			'q_clause' => 109,
			'qw_without' => 60,
			'qc_basic' => 32,
			'qc_phrase' => 113,
			's_prefix' => 61
		}
	},
	{#State 60
		DEFAULT => -156
	},
	{#State 61
		DEFAULT => -175
	},
	{#State 62
		ACTIONS => {
			'COLON_LBRACE' => 52,
			"^" => 68,
			"{" => 64,
			'SYMBOL' => 66,
			"*" => 36,
			'PREFIX' => 70,
			"%" => 35,
			"<" => 20,
			'NEG_REGEX' => 7,
			'STAR_LBRACE' => 42,
			'SUFFIX' => 26,
			'REGEX' => 37,
			'INTEGER' => 40,
			"\$" => 5,
			'DATE' => 4,
			'INDEX' => 23,
			'AT_LBRACE' => 11,
			"[" => 47,
			'DOLLAR_DOT' => 12,
			'KEYS' => 9,
			"\@" => 28,
			"(" => 114,
			'INFIX' => 10
		},
		GOTOS => {
			'qw_set_infl' => 2,
			'qw_suffix_set' => 3,
			'qw_prefix_set' => 39,
			'qw_chunk' => 6,
			'qw_prefix' => 41,
			'regex' => 43,
			'qw_listfile' => 45,
			'qw_exact' => 44,
			'qw_infix_set' => 46,
			'qw_bareword' => 13,
			'qw_set_exact' => 48,
			'qc_word' => 115,
			'qw_any' => 15,
			'qw_matchid' => 49,
			's_infix' => 14,
			'qw_lemma' => 51,
			'qw_infix' => 16,
			'neg_regex' => 18,
			'qw_with' => 19,
			'qw_keys' => 54,
			'qwk_indextuple' => 55,
			'qw_anchor' => 22,
			'qw_regex' => 24,
			'index' => 25,
			'qw_thesaurus' => 27,
			'qw_withor' => 29,
			's_suffix' => 57,
			'qw_without' => 60,
			'l_phrase' => 116,
			's_prefix' => 61,
			'symbol' => 33,
			'qw_suffix' => 34,
			'qw_morph' => 67,
			's_index' => 69,
			's_word' => 71
		}
	},
	{#State 63
		DEFAULT => -133
	},
	{#State 64
		DEFAULT => -208,
		GOTOS => {
			'l_set' => 117
		}
	},
	{#State 65
		ACTIONS => {
			'COLON_LBRACE' => 52,
			'INTEGER' => 40,
			'REGEX' => 37,
			'STAR_LBRACE' => 42,
			"[" => 47,
			'SYMBOL' => 66,
			"{" => 64,
			"^" => 68,
			'NEAR' => 72,
			'PREFIX' => 70,
			"(" => 92,
			"\"" => 62,
			"<" => 20,
			"\$" => 5,
			'DATE' => 4,
			'NEG_REGEX' => 7,
			'INFIX' => 10,
			'KEYS' => 9,
			'DOLLAR_DOT' => 12,
			'AT_LBRACE' => 11,
			"%" => 35,
			"*" => 36,
			'INDEX' => 23,
			'SUFFIX' => 26,
			"\@" => 28
		},
		DEFAULT => -115,
		GOTOS => {
			's_word' => 71,
			's_index' => 69,
			'qw_suffix' => 34,
			'qw_morph' => 67,
			'symbol' => 33,
			's_prefix' => 61,
			'qc_basic' => 118,
			'qc_phrase' => 63,
			'qw_without' => 60,
			'qw_withor' => 29,
			's_suffix' => 57,
			'index' => 25,
			'qw_thesaurus' => 27,
			'qw_regex' => 24,
			'qc_tokens' => 56,
			'qwk_indextuple' => 55,
			'qw_anchor' => 22,
			'qc_near' => 21,
			'qw_keys' => 54,
			'neg_regex' => 18,
			'qw_with' => 19,
			'qw_infix' => 16,
			'qw_matchid' => 49,
			's_infix' => 14,
			'qc_word' => 50,
			'qw_any' => 15,
			'qw_lemma' => 51,
			'qw_bareword' => 13,
			'qw_set_exact' => 48,
			'qw_infix_set' => 46,
			'qw_exact' => 44,
			'qw_listfile' => 45,
			'regex' => 43,
			'qw_chunk' => 6,
			'qw_prefix' => 41,
			'qw_prefix_set' => 39,
			'qw_set_infl' => 2,
			'qw_suffix_set' => 3
		}
	},
	{#State 66
		DEFAULT => -259
	},
	{#State 67
		DEFAULT => -150
	},
	{#State 68
		ACTIONS => {
			'DATE' => 4,
			'SYMBOL' => 66,
			'INTEGER' => 40
		},
		GOTOS => {
			's_chunk' => 120,
			'symbol' => 119
		}
	},
	{#State 69
		ACTIONS => {
			"=" => 121
		}
	},
	{#State 70
		DEFAULT => -265
	},
	{#State 71
		DEFAULT => -221,
		GOTOS => {
			'l_txchain' => 122
		}
	},
	{#State 72
		ACTIONS => {
			"(" => 123
		}
	},
	{#State 73
		ACTIONS => {
			'INTEGER' => 40,
			'SYMBOL' => 66,
			'INDEX' => 23,
			'DATE' => 4,
			"\$" => 128
		},
		DEFAULT => -226,
		GOTOS => {
			's_index' => 125,
			'symbol' => 127,
			'index' => 25,
			'l_indextuple' => 126,
			's_indextuple_item' => 124
		}
	},
	{#State 74
		DEFAULT => -272
	},
	{#State 75
		ACTIONS => {
			"=" => 82
		},
		DEFAULT => -121,
		GOTOS => {
			'matchid_eq' => 83,
			'matchid' => 87
		}
	},
	{#State 76
		ACTIONS => {
			'INFIX' => 10,
			'COUNT' => 31,
			"(" => 59,
			"\@" => 28,
			'KEYS' => 9,
			"[" => 47,
			'DOLLAR_DOT' => 12,
			"\"" => 62,
			'AT_LBRACE' => 11,
			'INDEX' => 23,
			"\$" => 5,
			'DATE' => 4,
			'INTEGER' => 40,
			'REGEX' => 37,
			'SUFFIX' => 26,
			"!" => 8,
			'STAR_LBRACE' => 42,
			'NEG_REGEX' => 7,
			"<" => 20,
			"%" => 35,
			'NEAR' => 72,
			'PREFIX' => 70,
			"*" => 36,
			'SYMBOL' => 66,
			"{" => 64,
			"^" => 68,
			'COLON_LBRACE' => 52
		},
		GOTOS => {
			'qw_listfile' => 45,
			'qw_exact' => 44,
			'qw_infix_set' => 46,
			'qw_bareword' => 13,
			'qw_set_exact' => 48,
			'qw_suffix_set' => 3,
			'qc_boolean' => 1,
			'qw_set_infl' => 2,
			'qw_prefix_set' => 39,
			'qw_chunk' => 6,
			'qw_prefix' => 41,
			'regex' => 43,
			'qw_keys' => 54,
			'qc_near' => 21,
			'qw_lemma' => 51,
			'qc_word' => 50,
			'qw_matchid' => 49,
			's_infix' => 14,
			'qw_any' => 15,
			'qw_infix' => 16,
			'count_query' => 129,
			'qw_with' => 19,
			'query_conditions' => 131,
			'neg_regex' => 18,
			's_suffix' => 57,
			'qw_withor' => 29,
			'q_clause' => 30,
			'qw_without' => 60,
			'qc_matchid' => 58,
			's_prefix' => 61,
			'qc_phrase' => 63,
			'qc_basic' => 32,
			'qw_anchor' => 22,
			'qwk_indextuple' => 55,
			'qc_tokens' => 56,
			'qw_regex' => 24,
			'qw_thesaurus' => 27,
			'index' => 25,
			's_index' => 69,
			's_word' => 71,
			'qwk_countsrc' => 130,
			'symbol' => 33,
			'qc_concat' => 65,
			'qw_suffix' => 34,
			'qw_morph' => 67
		}
	},
	{#State 77
		ACTIONS => {
			"}" => 134,
			"," => 132,
			'SYMBOL' => 66,
			'INTEGER' => 40,
			'DATE' => 4
		},
		GOTOS => {
			'symbol' => 33,
			's_word' => 133
		}
	},
	{#State 78
		ACTIONS => {
			'INTEGER' => 135
		},
		GOTOS => {
			'int_str' => 136
		}
	},
	{#State 79
		ACTIONS => {
			"=" => 137
		}
	},
	{#State 80
		DEFAULT => -197
	},
	{#State 81
		DEFAULT => -253
	},
	{#State 82
		DEFAULT => -280
	},
	{#State 83
		ACTIONS => {
			'INTEGER' => 135
		},
		GOTOS => {
			'int_str' => 139,
			'integer' => 138
		}
	},
	{#State 84
		DEFAULT => -130
	},
	{#State 85
		DEFAULT => -163
	},
	{#State 86
		ACTIONS => {
			'PREFIX' => 70,
			"*" => 36,
			'NEAR' => 72,
			"%" => 35,
			"<" => 20,
			'COLON_LBRACE' => 52,
			"^" => 68,
			"{" => 64,
			'SYMBOL' => 66,
			'AT_LBRACE' => 11,
			'DOLLAR_DOT' => 12,
			"[" => 47,
			"\"" => 62,
			"\@" => 28,
			'KEYS' => 9,
			'INFIX' => 10,
			"(" => 59,
			'STAR_LBRACE' => 42,
			'NEG_REGEX' => 7,
			'SUFFIX' => 26,
			"!" => 8,
			'REGEX' => 37,
			"\$" => 5,
			'DATE' => 4,
			'INDEX' => 23,
			'INTEGER' => 40
		},
		GOTOS => {
			'qw_bareword' => 13,
			'qw_set_exact' => 48,
			'qw_listfile' => 45,
			'qw_exact' => 44,
			'qw_infix_set' => 46,
			'qw_prefix' => 41,
			'qw_chunk' => 6,
			'regex' => 43,
			'qw_set_infl' => 2,
			'qc_boolean' => 1,
			'qw_suffix_set' => 3,
			'qw_prefix_set' => 39,
			'qc_near' => 21,
			'qw_keys' => 54,
			'neg_regex' => 18,
			'qw_with' => 19,
			'qw_matchid' => 49,
			'qc_word' => 50,
			'qw_any' => 15,
			's_infix' => 14,
			'qw_lemma' => 51,
			'qw_infix' => 16,
			'qc_phrase' => 63,
			's_prefix' => 61,
			'qc_basic' => 32,
			'qw_withor' => 29,
			's_suffix' => 57,
			'qc_matchid' => 58,
			'q_clause' => 140,
			'qw_without' => 60,
			'index' => 25,
			'qw_thesaurus' => 27,
			'qwk_indextuple' => 55,
			'qw_anchor' => 22,
			'qw_regex' => 24,
			'qc_tokens' => 56,
			's_word' => 71,
			's_index' => 69,
			'qw_morph' => 67,
			'qw_suffix' => 34,
			'symbol' => 33,
			'qc_concat' => 65
		}
	},
	{#State 87
		DEFAULT => -117
	},
	{#State 88
		ACTIONS => {
			"^" => 68,
			'COLON_LBRACE' => 52,
			'SYMBOL' => 66,
			"{" => 64,
			'NEAR' => 72,
			"*" => 36,
			'PREFIX' => 70,
			"<" => 20,
			"%" => 35,
			"!" => 8,
			'SUFFIX' => 26,
			'NEG_REGEX' => 7,
			'STAR_LBRACE' => 42,
			'INTEGER' => 40,
			'DATE' => 4,
			"\$" => 5,
			'INDEX' => 23,
			'REGEX' => 37,
			"\"" => 62,
			"[" => 47,
			'DOLLAR_DOT' => 12,
			'AT_LBRACE' => 11,
			"(" => 59,
			'INFIX' => 10,
			'KEYS' => 9,
			"\@" => 28
		},
		GOTOS => {
			'qc_near' => 21,
			'qw_keys' => 54,
			'neg_regex' => 18,
			'qw_with' => 19,
			'qw_matchid' => 49,
			'qc_word' => 50,
			's_infix' => 14,
			'qw_any' => 15,
			'qw_lemma' => 51,
			'qw_infix' => 16,
			'qw_set_exact' => 48,
			'qw_bareword' => 13,
			'qw_exact' => 44,
			'qw_listfile' => 45,
			'qw_infix_set' => 46,
			'qw_prefix' => 41,
			'qw_chunk' => 6,
			'regex' => 43,
			'qw_set_infl' => 2,
			'qc_boolean' => 1,
			'qw_suffix_set' => 3,
			'qw_prefix_set' => 39,
			's_word' => 71,
			's_index' => 69,
			'qw_suffix' => 34,
			'qw_morph' => 67,
			'symbol' => 33,
			'qc_concat' => 65,
			'qc_basic' => 32,
			's_prefix' => 61,
			'qc_phrase' => 63,
			'qw_withor' => 29,
			's_suffix' => 57,
			'qc_matchid' => 58,
			'q_clause' => 141,
			'qw_without' => 60,
			'index' => 25,
			'qw_thesaurus' => 27,
			'qwk_indextuple' => 55,
			'qw_anchor' => 22,
			'qw_regex' => 24,
			'qc_tokens' => 56
		}
	},
	{#State 89
		ACTIONS => {
			":" => 163,
			'GREATER_BY_MIDDLE' => 162,
			'GREATER_BY_RANK' => 161,
			'CNTXT' => 142,
			'GREATER_BY_RIGHT' => 159,
			'WITHIN' => 144,
			'HAS_FIELD' => 168,
			'LESS_BY_RANK' => 169,
			'GREATER_BY_SIZE' => 166,
			'GREATER_BY_LEFT' => 164,
			'GREATER_BY_DATE' => 151,
			'LESS_BY' => 152,
			'LESS_BY_LEFT' => 153,
			'NOSEPARATE_HITS' => 154,
			'LESS_BY_MIDDLE' => 172,
			'LESS_BY_RIGHT' => 171,
			'SEPARATE_HITS' => 170,
			"!" => 147,
			'IS_DATE' => 148,
			'IS_SIZE' => 150,
			'RANDOM' => 156,
			'DEBUG_RANK' => 158,
			'GREATER_BY' => 157,
			'LESS_BY_SIZE' => 155,
			'LESS_BY_DATE' => 175,
			'FILENAMES_ONLY' => 174
		},
		DEFAULT => -28,
		GOTOS => {
			'qf_rank_sort' => 176,
			'q_filter' => 149,
			'qf_size_sort' => 173,
			'qf_has_field' => 165,
			'q_flag' => 143,
			'qf_bibl_sort' => 167,
			'qf_random_sort' => 145,
			'qf_context_sort' => 146,
			'qf_date_sort' => 160
		}
	},
	{#State 90
		ACTIONS => {
			'AT_LBRACE' => 11,
			'DOLLAR_DOT' => 12,
			"[" => 47,
			"\"" => 62,
			"\@" => 28,
			'KEYS' => 9,
			'INFIX' => 10,
			"(" => 59,
			'STAR_LBRACE' => 42,
			'NEG_REGEX' => 7,
			'SUFFIX' => 26,
			"!" => 8,
			'REGEX' => 37,
			"\$" => 5,
			'DATE' => 4,
			'INDEX' => 23,
			'INTEGER' => 40,
			'PREFIX' => 70,
			"*" => 36,
			'NEAR' => 72,
			"%" => 35,
			"<" => 20,
			'COLON_LBRACE' => 52,
			"^" => 68,
			"{" => 64,
			'SYMBOL' => 66
		},
		GOTOS => {
			'qw_bareword' => 13,
			'qw_set_exact' => 48,
			'qw_infix_set' => 46,
			'qw_exact' => 44,
			'qw_listfile' => 45,
			'regex' => 43,
			'qw_chunk' => 6,
			'qw_prefix' => 41,
			'qw_prefix_set' => 39,
			'qc_boolean' => 1,
			'qw_set_infl' => 2,
			'qw_suffix_set' => 3,
			'qc_near' => 21,
			'qw_keys' => 54,
			'query_conditions' => 177,
			'neg_regex' => 18,
			'qw_with' => 19,
			'qw_infix' => 16,
			's_infix' => 14,
			'qc_word' => 50,
			'qw_matchid' => 49,
			'qw_any' => 15,
			'qw_lemma' => 51,
			's_prefix' => 61,
			'qc_phrase' => 63,
			'qc_basic' => 32,
			'qc_matchid' => 58,
			'qw_without' => 60,
			'q_clause' => 30,
			'qw_withor' => 29,
			's_suffix' => 57,
			'index' => 25,
			'qw_thesaurus' => 27,
			'qw_regex' => 24,
			'qc_tokens' => 56,
			'qwk_indextuple' => 55,
			'qw_anchor' => 22,
			's_word' => 71,
			's_index' => 69,
			'qw_morph' => 67,
			'qw_suffix' => 34,
			'qc_concat' => 65,
			'symbol' => 33
		}
	},
	{#State 91
		DEFAULT => -123
	},
	{#State 92
		ACTIONS => {
			'DOLLAR_DOT' => 12,
			"[" => 47,
			"\"" => 62,
			'AT_LBRACE' => 11,
			'INFIX' => 10,
			"(" => 92,
			"\@" => 28,
			'KEYS' => 9,
			'SUFFIX' => 26,
			'STAR_LBRACE' => 42,
			'NEG_REGEX' => 7,
			"\$" => 5,
			'INDEX' => 23,
			'DATE' => 4,
			'INTEGER' => 40,
			'REGEX' => 37,
			'NEAR' => 72,
			'PREFIX' => 70,
			"*" => 36,
			"<" => 20,
			"%" => 35,
			"^" => 68,
			'COLON_LBRACE' => 52,
			'SYMBOL' => 66,
			"{" => 64
		},
		GOTOS => {
			'qw_set_infl' => 2,
			'qw_suffix_set' => 3,
			'qw_prefix_set' => 39,
			'qw_prefix' => 41,
			'qw_chunk' => 6,
			'regex' => 43,
			'qw_exact' => 44,
			'qw_listfile' => 45,
			'qw_infix_set' => 46,
			'qw_bareword' => 13,
			'qw_set_exact' => 48,
			'qw_any' => 15,
			'qc_word' => 179,
			's_infix' => 14,
			'qw_matchid' => 49,
			'qw_lemma' => 51,
			'qw_infix' => 16,
			'neg_regex' => 18,
			'qw_with' => 19,
			'qc_near' => 178,
			'qw_keys' => 54,
			'qwk_indextuple' => 55,
			'qw_anchor' => 22,
			'qw_regex' => 24,
			'index' => 25,
			'qw_thesaurus' => 27,
			'qw_withor' => 29,
			's_suffix' => 57,
			'qw_without' => 60,
			'qc_phrase' => 180,
			's_prefix' => 61,
			'symbol' => 33,
			'qw_morph' => 67,
			'qw_suffix' => 34,
			's_index' => 69,
			's_word' => 71
		}
	},
	{#State 93
		DEFAULT => -191
	},
	{#State 94
		DEFAULT => -251
	},
	{#State 95
		DEFAULT => -270
	},
	{#State 96
		DEFAULT => 0
	},
	{#State 97
		ACTIONS => {
			"}" => 182,
			'RBRACE_STAR' => 181,
			'DATE' => 4,
			'SYMBOL' => 66,
			"," => 132,
			'INTEGER' => 40
		},
		GOTOS => {
			's_word' => 133,
			'symbol' => 33
		}
	},
	{#State 98
		ACTIONS => {
			";" => 187,
			'SYMBOL' => 66,
			'INTEGER' => 40,
			"," => 186,
			'DATE' => 4,
			"]" => 184
		},
		GOTOS => {
			'symbol' => 183,
			's_morphitem' => 185
		}
	},
	{#State 99
		ACTIONS => {
			'STAR_LBRACE' => 42,
			'NEG_REGEX' => 7,
			'SUFFIX' => 26,
			'REGEX' => 37,
			'DATE' => 4,
			"\$" => 5,
			'INDEX' => 23,
			'INTEGER' => 40,
			'AT_LBRACE' => 11,
			"[" => 47,
			'DOLLAR_DOT' => 12,
			"\@" => 28,
			'KEYS' => 9,
			'INFIX' => 10,
			"(" => 114,
			'COLON_LBRACE' => 52,
			"^" => 68,
			"{" => 64,
			'SYMBOL' => 66,
			'PREFIX' => 70,
			"*" => 36,
			"%" => 35,
			"<" => 20
		},
		GOTOS => {
			'qw_bareword' => 13,
			'qw_set_exact' => 48,
			'qw_infix_set' => 46,
			'qw_exact' => 44,
			'qw_listfile' => 45,
			'regex' => 43,
			'qw_prefix' => 41,
			'qw_chunk' => 6,
			'qw_prefix_set' => 39,
			'qw_suffix_set' => 3,
			'qw_set_infl' => 2,
			'qw_keys' => 54,
			'qw_with' => 19,
			'neg_regex' => 18,
			'qw_infix' => 16,
			'qw_lemma' => 51,
			'qc_word' => 188,
			'qw_matchid' => 49,
			's_infix' => 14,
			'qw_any' => 15,
			's_prefix' => 61,
			'qw_without' => 60,
			's_suffix' => 57,
			'qw_withor' => 29,
			'qw_thesaurus' => 27,
			'index' => 25,
			'qw_regex' => 24,
			'qw_anchor' => 22,
			'qwk_indextuple' => 55,
			's_word' => 71,
			's_index' => 69,
			'qw_morph' => 67,
			'qw_suffix' => 34,
			'symbol' => 33
		}
	},
	{#State 100
		ACTIONS => {
			"[" => 47,
			'DOLLAR_DOT' => 12,
			'AT_LBRACE' => 11,
			'INFIX' => 10,
			"(" => 114,
			"\@" => 28,
			'KEYS' => 9,
			'SUFFIX' => 26,
			'STAR_LBRACE' => 42,
			'NEG_REGEX' => 7,
			"\$" => 5,
			'INDEX' => 23,
			'DATE' => 4,
			'INTEGER' => 40,
			'REGEX' => 37,
			'PREFIX' => 70,
			"*" => 36,
			"<" => 20,
			"%" => 35,
			"^" => 68,
			'COLON_LBRACE' => 52,
			'SYMBOL' => 66,
			"{" => 64
		},
		GOTOS => {
			'neg_regex' => 18,
			'qw_with' => 19,
			'qw_infix' => 16,
			'qc_word' => 189,
			'qw_matchid' => 49,
			'qw_any' => 15,
			's_infix' => 14,
			'qw_lemma' => 51,
			'qw_keys' => 54,
			'regex' => 43,
			'qw_chunk' => 6,
			'qw_prefix' => 41,
			'qw_prefix_set' => 39,
			'qw_set_infl' => 2,
			'qw_suffix_set' => 3,
			'qw_set_exact' => 48,
			'qw_bareword' => 13,
			'qw_infix_set' => 46,
			'qw_listfile' => 45,
			'qw_exact' => 44,
			'qw_suffix' => 34,
			'qw_morph' => 67,
			'symbol' => 33,
			's_word' => 71,
			's_index' => 69,
			'index' => 25,
			'qw_thesaurus' => 27,
			'qw_regex' => 24,
			'qwk_indextuple' => 55,
			'qw_anchor' => 22,
			's_prefix' => 61,
			'qw_without' => 60,
			'qw_withor' => 29,
			's_suffix' => 57
		}
	},
	{#State 101
		ACTIONS => {
			'COLON_LBRACE' => 52,
			"^" => 68,
			"{" => 64,
			'SYMBOL' => 66,
			'PREFIX' => 70,
			"*" => 36,
			"%" => 35,
			"<" => 20,
			'STAR_LBRACE' => 42,
			'NEG_REGEX' => 7,
			'SUFFIX' => 26,
			'REGEX' => 37,
			'DATE' => 4,
			"\$" => 5,
			'INDEX' => 23,
			'INTEGER' => 40,
			'AT_LBRACE' => 11,
			"[" => 47,
			'DOLLAR_DOT' => 12,
			"\@" => 28,
			'KEYS' => 9,
			'INFIX' => 10,
			"(" => 114
		},
		GOTOS => {
			's_word' => 71,
			's_index' => 69,
			'qw_suffix' => 34,
			'qw_morph' => 67,
			'symbol' => 33,
			's_prefix' => 61,
			's_suffix' => 57,
			'qw_withor' => 29,
			'qw_without' => 60,
			'qw_thesaurus' => 27,
			'index' => 25,
			'qw_anchor' => 22,
			'qwk_indextuple' => 55,
			'qw_regex' => 24,
			'qw_keys' => 54,
			'qw_with' => 19,
			'neg_regex' => 18,
			'qw_lemma' => 51,
			'qw_matchid' => 49,
			'qc_word' => 190,
			's_infix' => 14,
			'qw_any' => 15,
			'qw_infix' => 16,
			'qw_set_exact' => 48,
			'qw_bareword' => 13,
			'qw_exact' => 44,
			'qw_listfile' => 45,
			'qw_infix_set' => 46,
			'qw_prefix' => 41,
			'qw_chunk' => 6,
			'regex' => 43,
			'qw_suffix_set' => 3,
			'qw_set_infl' => 2,
			'qw_prefix_set' => 39
		}
	},
	{#State 102
		DEFAULT => -207
	},
	{#State 103
		ACTIONS => {
			"}" => 191
		}
	},
	{#State 104
		DEFAULT => -250
	},
	{#State 105
		ACTIONS => {
			'KEYS' => 192
		}
	},
	{#State 106
		DEFAULT => -134
	},
	{#State 107
		ACTIONS => {
			"=" => 82,
			")" => 193
		},
		DEFAULT => -127,
		GOTOS => {
			'matchid_eq' => 83,
			'matchid' => 84
		}
	},
	{#State 108
		ACTIONS => {
			")" => 194
		},
		DEFAULT => -114
	},
	{#State 109
		ACTIONS => {
			'OP_BOOL_OR' => 88,
			"=" => 82,
			'OP_BOOL_AND' => 86
		},
		GOTOS => {
			'matchid' => 87,
			'matchid_eq' => 83
		}
	},
	{#State 110
		ACTIONS => {
			"=" => 82,
			'WITHOUT' => 99,
			'WITH' => 100,
			'WITHOR' => 101,
			")" => 195
		},
		DEFAULT => -132,
		GOTOS => {
			'matchid' => 102,
			'matchid_eq' => 83
		}
	},
	{#State 111
		ACTIONS => {
			'NEAR' => 72,
			'PREFIX' => 70,
			"*" => 36,
			"<" => 20,
			"%" => 35,
			"^" => 68,
			'COLON_LBRACE' => 52,
			'SYMBOL' => 66,
			")" => 196,
			"{" => 64,
			"[" => 47,
			'DOLLAR_DOT' => 12,
			"\"" => 62,
			'AT_LBRACE' => 11,
			'INFIX' => 10,
			"(" => 92,
			"\@" => 28,
			'KEYS' => 9,
			'SUFFIX' => 26,
			'STAR_LBRACE' => 42,
			'NEG_REGEX' => 7,
			'INDEX' => 23,
			"\$" => 5,
			'DATE' => 4,
			'INTEGER' => 40,
			'REGEX' => 37
		},
		DEFAULT => -115,
		GOTOS => {
			'qw_keys' => 54,
			'qc_near' => 21,
			'qw_lemma' => 51,
			'qw_matchid' => 49,
			'qw_any' => 15,
			's_infix' => 14,
			'qc_word' => 50,
			'qw_infix' => 16,
			'qw_with' => 19,
			'neg_regex' => 18,
			'qw_listfile' => 45,
			'qw_exact' => 44,
			'qw_infix_set' => 46,
			'qw_set_exact' => 48,
			'qw_bareword' => 13,
			'qw_suffix_set' => 3,
			'qw_set_infl' => 2,
			'qw_prefix_set' => 39,
			'qw_chunk' => 6,
			'qw_prefix' => 41,
			'regex' => 43,
			's_index' => 69,
			's_word' => 71,
			'symbol' => 33,
			'qw_morph' => 67,
			'qw_suffix' => 34,
			's_suffix' => 57,
			'qw_withor' => 29,
			'qw_without' => 60,
			'qc_phrase' => 63,
			'qc_basic' => 118,
			's_prefix' => 61,
			'qw_anchor' => 22,
			'qwk_indextuple' => 55,
			'qc_tokens' => 56,
			'qw_regex' => 24,
			'qw_thesaurus' => 27,
			'index' => 25
		}
	},
	{#State 112
		ACTIONS => {
			")" => 197
		},
		DEFAULT => -116
	},
	{#State 113
		ACTIONS => {
			")" => 198
		},
		DEFAULT => -133
	},
	{#State 114
		ACTIONS => {
			"%" => 35,
			"<" => 20,
			'PREFIX' => 70,
			"*" => 36,
			"{" => 64,
			'SYMBOL' => 66,
			'COLON_LBRACE' => 52,
			"^" => 68,
			"\@" => 28,
			'KEYS' => 9,
			'INFIX' => 10,
			"(" => 114,
			'AT_LBRACE' => 11,
			"[" => 47,
			'DOLLAR_DOT' => 12,
			'REGEX' => 37,
			'INDEX' => 23,
			'DATE' => 4,
			"\$" => 5,
			'INTEGER' => 40,
			'STAR_LBRACE' => 42,
			'NEG_REGEX' => 7,
			'SUFFIX' => 26
		},
		GOTOS => {
			's_word' => 71,
			's_index' => 69,
			'qw_suffix' => 34,
			'qw_morph' => 67,
			'symbol' => 33,
			's_prefix' => 61,
			'qw_without' => 60,
			'qw_withor' => 29,
			's_suffix' => 57,
			'index' => 25,
			'qw_thesaurus' => 27,
			'qw_regex' => 24,
			'qwk_indextuple' => 55,
			'qw_anchor' => 22,
			'qw_keys' => 54,
			'neg_regex' => 18,
			'qw_with' => 19,
			'qw_infix' => 16,
			'qw_matchid' => 49,
			'qc_word' => 179,
			'qw_any' => 15,
			's_infix' => 14,
			'qw_lemma' => 51,
			'qw_bareword' => 13,
			'qw_set_exact' => 48,
			'qw_infix_set' => 46,
			'qw_listfile' => 45,
			'qw_exact' => 44,
			'regex' => 43,
			'qw_prefix' => 41,
			'qw_chunk' => 6,
			'qw_prefix_set' => 39,
			'qw_set_infl' => 2,
			'qw_suffix_set' => 3
		}
	},
	{#State 115
		ACTIONS => {
			'WITHOR' => 101,
			'WITH' => 100,
			'WITHOUT' => 99,
			"=" => 82
		},
		DEFAULT => -215,
		GOTOS => {
			'matchid' => 102,
			'matchid_eq' => 83
		}
	},
	{#State 116
		ACTIONS => {
			"\"" => 202,
			'DOLLAR_DOT' => 12,
			"[" => 47,
			'AT_LBRACE' => 11,
			"#" => 203,
			"(" => 114,
			'INFIX' => 10,
			'HASH_LESS' => 200,
			'KEYS' => 9,
			"\@" => 28,
			'HASH_GREATER' => 199,
			'SUFFIX' => 26,
			'HASH_EQUAL' => 201,
			'NEG_REGEX' => 7,
			'STAR_LBRACE' => 42,
			'INTEGER' => 40,
			'INDEX' => 23,
			"\$" => 5,
			'DATE' => 4,
			'REGEX' => 37,
			"*" => 36,
			'PREFIX' => 70,
			"<" => 20,
			"%" => 35,
			"^" => 68,
			'COLON_LBRACE' => 52,
			'SYMBOL' => 66,
			"{" => 64
		},
		GOTOS => {
			'qw_prefix_set' => 39,
			'qw_set_infl' => 2,
			'qw_suffix_set' => 3,
			'regex' => 43,
			'qw_prefix' => 41,
			'qw_chunk' => 6,
			'qw_infix_set' => 46,
			'qw_listfile' => 45,
			'qw_exact' => 44,
			'qw_set_exact' => 48,
			'qw_bareword' => 13,
			'qw_infix' => 16,
			'qw_any' => 15,
			'qc_word' => 204,
			's_infix' => 14,
			'qw_matchid' => 49,
			'qw_lemma' => 51,
			'neg_regex' => 18,
			'qw_with' => 19,
			'qw_keys' => 54,
			'qw_regex' => 24,
			'qwk_indextuple' => 55,
			'qw_anchor' => 22,
			'index' => 25,
			'qw_thesaurus' => 27,
			'qw_without' => 60,
			'qw_withor' => 29,
			's_suffix' => 57,
			's_prefix' => 61,
			'symbol' => 33,
			'qw_suffix' => 34,
			'qw_morph' => 67,
			's_index' => 69,
			's_word' => 71
		}
	},
	{#State 117
		ACTIONS => {
			"}" => 206,
			'DATE' => 4,
			'RBRACE_STAR' => 205,
			'SYMBOL' => 66,
			"," => 132,
			'INTEGER' => 40
		},
		GOTOS => {
			's_word' => 133,
			'symbol' => 33
		}
	},
	{#State 118
		DEFAULT => -124
	},
	{#State 119
		DEFAULT => -252
	},
	{#State 120
		DEFAULT => -193
	},
	{#State 121
		ACTIONS => {
			'REGEX' => 37,
			'DATE' => 4,
			'INTEGER' => 40,
			'STAR_LBRACE' => 209,
			'NEG_REGEX' => 7,
			'SUFFIX' => 26,
			"\@" => 222,
			'INFIX' => 10,
			":" => 214,
			'AT_LBRACE' => 219,
			"[" => 207,
			"{" => 212,
			'SYMBOL' => 66,
			"^" => 211,
			"%" => 221,
			"<" => 216,
			'PREFIX' => 70,
			"*" => 220
		},
		GOTOS => {
			's_word' => 210,
			'neg_regex' => 217,
			'regex' => 208,
			's_prefix' => 213,
			's_infix' => 218,
			'symbol' => 33,
			's_suffix' => 215
		}
	},
	{#State 122
		ACTIONS => {
			'EXPANDER' => 224
		},
		DEFAULT => -161,
		GOTOS => {
			's_expander' => 223
		}
	},
	{#State 123
		ACTIONS => {
			'COLON_LBRACE' => 52,
			"^" => 68,
			"{" => 64,
			'SYMBOL' => 66,
			'PREFIX' => 70,
			"*" => 36,
			"%" => 35,
			"<" => 20,
			'STAR_LBRACE' => 42,
			'NEG_REGEX' => 7,
			'SUFFIX' => 26,
			'REGEX' => 37,
			'INDEX' => 23,
			'DATE' => 4,
			"\$" => 5,
			'INTEGER' => 40,
			'AT_LBRACE' => 11,
			"[" => 47,
			'DOLLAR_DOT' => 12,
			"\"" => 62,
			"\@" => 28,
			'KEYS' => 9,
			'INFIX' => 10,
			"(" => 226
		},
		GOTOS => {
			'symbol' => 33,
			'qw_morph' => 67,
			'qw_suffix' => 34,
			's_index' => 69,
			's_word' => 71,
			'qwk_indextuple' => 55,
			'qw_anchor' => 22,
			'qw_regex' => 24,
			'qc_tokens' => 225,
			'index' => 25,
			'qw_thesaurus' => 27,
			'qw_withor' => 29,
			's_suffix' => 57,
			'qw_without' => 60,
			's_prefix' => 61,
			'qc_phrase' => 63,
			's_infix' => 14,
			'qc_word' => 50,
			'qw_any' => 15,
			'qw_matchid' => 49,
			'qw_lemma' => 51,
			'qw_infix' => 16,
			'neg_regex' => 18,
			'qw_with' => 19,
			'qw_keys' => 54,
			'qw_set_infl' => 2,
			'qw_suffix_set' => 3,
			'qw_prefix_set' => 39,
			'qw_chunk' => 6,
			'qw_prefix' => 41,
			'regex' => 43,
			'qw_exact' => 44,
			'qw_listfile' => 45,
			'qw_infix_set' => 46,
			'qw_bareword' => 13,
			'qw_set_exact' => 48
		}
	},
	{#State 124
		DEFAULT => -227
	},
	{#State 125
		DEFAULT => -247
	},
	{#State 126
		ACTIONS => {
			")" => 227,
			"," => 228
		}
	},
	{#State 127
		DEFAULT => -248
	},
	{#State 128
		DEFAULT => -245
	},
	{#State 129
		DEFAULT => -205
	},
	{#State 130
		ACTIONS => {
			")" => 229
		}
	},
	{#State 131
		DEFAULT => -4,
		GOTOS => {
			'count_filters' => 230
		}
	},
	{#State 132
		DEFAULT => -210
	},
	{#State 133
		DEFAULT => -209
	},
	{#State 134
		DEFAULT => -171
	},
	{#State 135
		DEFAULT => -275
	},
	{#State 136
		DEFAULT => -195
	},
	{#State 137
		ACTIONS => {
			'INTEGER' => 135
		},
		GOTOS => {
			'int_str' => 231
		}
	},
	{#State 138
		DEFAULT => -279
	},
	{#State 139
		DEFAULT => -276
	},
	{#State 140
		ACTIONS => {
			"=" => 82
		},
		DEFAULT => -119,
		GOTOS => {
			'matchid_eq' => 83,
			'matchid' => 87
		}
	},
	{#State 141
		ACTIONS => {
			"=" => 82
		},
		DEFAULT => -120,
		GOTOS => {
			'matchid' => 87,
			'matchid_eq' => 83
		}
	},
	{#State 142
		ACTIONS => {
			'INTEGER' => 135,
			"[" => 232
		},
		GOTOS => {
			'integer' => 233,
			'int_str' => 139
		}
	},
	{#State 143
		DEFAULT => -30
	},
	{#State 144
		ACTIONS => {
			'KW_FILENAME' => 235,
			'DATE' => 4,
			'INTEGER' => 40,
			'SYMBOL' => 66
		},
		GOTOS => {
			's_breakname' => 234,
			'symbol' => 236
		}
	},
	{#State 145
		DEFAULT => -51
	},
	{#State 146
		DEFAULT => -47
	},
	{#State 147
		ACTIONS => {
			'FILENAMES_ONLY' => 239,
			"!" => 237,
			'DEBUG_RANK' => 238,
			'HAS_FIELD' => 168
		},
		GOTOS => {
			'qf_has_field' => 240
		}
	},
	{#State 148
		ACTIONS => {
			"[" => 241
		}
	},
	{#State 149
		DEFAULT => -31
	},
	{#State 150
		ACTIONS => {
			"[" => 242
		}
	},
	{#State 151
		ACTIONS => {
			"[" => 244
		},
		DEFAULT => -88,
		GOTOS => {
			'qfb_date' => 243
		}
	},
	{#State 152
		ACTIONS => {
			"[" => 245
		}
	},
	{#State 153
		ACTIONS => {
			"[" => 247
		},
		DEFAULT => -102,
		GOTOS => {
			'qfb_ctxsort' => 246
		}
	},
	{#State 154
		DEFAULT => -37
	},
	{#State 155
		ACTIONS => {
			"[" => 249
		},
		DEFAULT => -81,
		GOTOS => {
			'qfb_int' => 248
		}
	},
	{#State 156
		ACTIONS => {
			"[" => 250
		},
		DEFAULT => -74
	},
	{#State 157
		ACTIONS => {
			"[" => 251
		}
	},
	{#State 158
		DEFAULT => -40
	},
	{#State 159
		ACTIONS => {
			"[" => 247
		},
		DEFAULT => -102,
		GOTOS => {
			'qfb_ctxsort' => 252
		}
	},
	{#State 160
		DEFAULT => -49
	},
	{#State 161
		DEFAULT => -60
	},
	{#State 162
		ACTIONS => {
			"[" => 247
		},
		DEFAULT => -102,
		GOTOS => {
			'qfb_ctxsort' => 253
		}
	},
	{#State 163
		ACTIONS => {
			'SYMBOL' => 66,
			'INTEGER' => 40,
			'DATE' => 4
		},
		DEFAULT => -42,
		GOTOS => {
			'qf_subcorpora' => 255,
			's_subcorpus' => 254,
			'symbol' => 256
		}
	},
	{#State 164
		ACTIONS => {
			"[" => 247
		},
		DEFAULT => -102,
		GOTOS => {
			'qfb_ctxsort' => 257
		}
	},
	{#State 165
		DEFAULT => -45
	},
	{#State 166
		ACTIONS => {
			"[" => 249
		},
		DEFAULT => -81,
		GOTOS => {
			'qfb_int' => 258
		}
	},
	{#State 167
		DEFAULT => -50
	},
	{#State 168
		ACTIONS => {
			"[" => 259
		}
	},
	{#State 169
		DEFAULT => -61
	},
	{#State 170
		DEFAULT => -36
	},
	{#State 171
		ACTIONS => {
			"[" => 247
		},
		DEFAULT => -102,
		GOTOS => {
			'qfb_ctxsort' => 260
		}
	},
	{#State 172
		ACTIONS => {
			"[" => 247
		},
		DEFAULT => -102,
		GOTOS => {
			'qfb_ctxsort' => 261
		}
	},
	{#State 173
		DEFAULT => -48
	},
	{#State 174
		DEFAULT => -38
	},
	{#State 175
		ACTIONS => {
			"[" => 244
		},
		DEFAULT => -88,
		GOTOS => {
			'qfb_date' => 262
		}
	},
	{#State 176
		DEFAULT => -46
	},
	{#State 177
		DEFAULT => -4,
		GOTOS => {
			'count_filters' => 263
		}
	},
	{#State 178
		ACTIONS => {
			")" => 193,
			"=" => 82
		},
		GOTOS => {
			'matchid_eq' => 83,
			'matchid' => 84
		}
	},
	{#State 179
		ACTIONS => {
			")" => 195,
			'WITHOUT' => 99,
			"=" => 82,
			'WITHOR' => 101,
			'WITH' => 100
		},
		GOTOS => {
			'matchid_eq' => 83,
			'matchid' => 102
		}
	},
	{#State 180
		ACTIONS => {
			")" => 198
		}
	},
	{#State 181
		DEFAULT => -181
	},
	{#State 182
		DEFAULT => -185
	},
	{#State 183
		DEFAULT => -254
	},
	{#State 184
		DEFAULT => -189
	},
	{#State 185
		DEFAULT => -212
	},
	{#State 186
		DEFAULT => -213
	},
	{#State 187
		DEFAULT => -214
	},
	{#State 188
		ACTIONS => {
			"=" => 82
		},
		DEFAULT => -200,
		GOTOS => {
			'matchid_eq' => 83,
			'matchid' => 102
		}
	},
	{#State 189
		ACTIONS => {
			"=" => 82
		},
		DEFAULT => -199,
		GOTOS => {
			'matchid' => 102,
			'matchid_eq' => 83
		}
	},
	{#State 190
		ACTIONS => {
			"=" => 82
		},
		DEFAULT => -201,
		GOTOS => {
			'matchid_eq' => 83,
			'matchid' => 102
		}
	},
	{#State 191
		DEFAULT => -187
	},
	{#State 192
		ACTIONS => {
			"(" => 264
		}
	},
	{#State 193
		DEFAULT => -131
	},
	{#State 194
		DEFAULT => -122
	},
	{#State 195
		DEFAULT => -160
	},
	{#State 196
		DEFAULT => -125
	},
	{#State 197
		DEFAULT => -118
	},
	{#State 198
		DEFAULT => -136
	},
	{#State 199
		ACTIONS => {
			'INTEGER' => 135
		},
		GOTOS => {
			'int_str' => 139,
			'integer' => 265
		}
	},
	{#State 200
		ACTIONS => {
			'INTEGER' => 135
		},
		GOTOS => {
			'int_str' => 139,
			'integer' => 266
		}
	},
	{#State 201
		ACTIONS => {
			'INTEGER' => 135
		},
		GOTOS => {
			'int_str' => 139,
			'integer' => 267
		}
	},
	{#State 202
		DEFAULT => -135
	},
	{#State 203
		ACTIONS => {
			'INTEGER' => 135
		},
		GOTOS => {
			'int_str' => 139,
			'integer' => 268
		}
	},
	{#State 204
		ACTIONS => {
			"=" => 82,
			'WITHOUT' => 99,
			'WITH' => 100,
			'WITHOR' => 101
		},
		DEFAULT => -216,
		GOTOS => {
			'matchid' => 102,
			'matchid_eq' => 83
		}
	},
	{#State 205
		DEFAULT => -183
	},
	{#State 206
		DEFAULT => -221,
		GOTOS => {
			'l_txchain' => 269
		}
	},
	{#State 207
		DEFAULT => -211,
		GOTOS => {
			'l_morph' => 270
		}
	},
	{#State 208
		DEFAULT => -166
	},
	{#State 209
		DEFAULT => -208,
		GOTOS => {
			'l_set' => 271
		}
	},
	{#State 210
		DEFAULT => -221,
		GOTOS => {
			'l_txchain' => 272
		}
	},
	{#State 211
		ACTIONS => {
			'DATE' => 4,
			'SYMBOL' => 66,
			'INTEGER' => 40
		},
		GOTOS => {
			's_chunk' => 273,
			'symbol' => 119
		}
	},
	{#State 212
		DEFAULT => -208,
		GOTOS => {
			'l_set' => 274
		}
	},
	{#State 213
		DEFAULT => -176
	},
	{#State 214
		ACTIONS => {
			"{" => 275
		}
	},
	{#State 215
		DEFAULT => -178
	},
	{#State 216
		ACTIONS => {
			'DATE' => 4,
			'INTEGER' => 40,
			'SYMBOL' => 66
		},
		GOTOS => {
			's_filename' => 276,
			'symbol' => 81
		}
	},
	{#State 217
		DEFAULT => -168
	},
	{#State 218
		DEFAULT => -180
	},
	{#State 219
		DEFAULT => -208,
		GOTOS => {
			'l_set' => 277
		}
	},
	{#State 220
		DEFAULT => -170
	},
	{#State 221
		ACTIONS => {
			'INTEGER' => 40,
			'SYMBOL' => 66,
			'DATE' => 4
		},
		GOTOS => {
			's_lemma' => 278,
			'symbol' => 94
		}
	},
	{#State 222
		ACTIONS => {
			'DATE' => 4,
			'SYMBOL' => 66,
			'INTEGER' => 40
		},
		GOTOS => {
			'symbol' => 33,
			's_word' => 279
		}
	},
	{#State 223
		DEFAULT => -222
	},
	{#State 224
		DEFAULT => -268
	},
	{#State 225
		ACTIONS => {
			"," => 280,
			"=" => 82
		},
		GOTOS => {
			'matchid_eq' => 83,
			'matchid' => 106
		}
	},
	{#State 226
		ACTIONS => {
			"*" => 36,
			'PREFIX' => 70,
			"<" => 20,
			"%" => 35,
			"^" => 68,
			'COLON_LBRACE' => 52,
			'SYMBOL' => 66,
			"{" => 64,
			"\"" => 62,
			"[" => 47,
			'DOLLAR_DOT' => 12,
			'AT_LBRACE' => 11,
			"(" => 226,
			'INFIX' => 10,
			'KEYS' => 9,
			"\@" => 28,
			'SUFFIX' => 26,
			'NEG_REGEX' => 7,
			'STAR_LBRACE' => 42,
			'INTEGER' => 40,
			'INDEX' => 23,
			'DATE' => 4,
			"\$" => 5,
			'REGEX' => 37
		},
		GOTOS => {
			's_word' => 71,
			's_index' => 69,
			'qw_suffix' => 34,
			'qw_morph' => 67,
			'symbol' => 33,
			's_prefix' => 61,
			'qc_phrase' => 180,
			'qw_withor' => 29,
			's_suffix' => 57,
			'qw_without' => 60,
			'index' => 25,
			'qw_thesaurus' => 27,
			'qwk_indextuple' => 55,
			'qw_anchor' => 22,
			'qw_regex' => 24,
			'qw_keys' => 54,
			'neg_regex' => 18,
			'qw_with' => 19,
			's_infix' => 14,
			'qc_word' => 179,
			'qw_any' => 15,
			'qw_matchid' => 49,
			'qw_lemma' => 51,
			'qw_infix' => 16,
			'qw_bareword' => 13,
			'qw_set_exact' => 48,
			'qw_listfile' => 45,
			'qw_exact' => 44,
			'qw_infix_set' => 46,
			'qw_prefix' => 41,
			'qw_chunk' => 6,
			'regex' => 43,
			'qw_set_infl' => 2,
			'qw_suffix_set' => 3,
			'qw_prefix_set' => 39
		}
	},
	{#State 227
		DEFAULT => -204
	},
	{#State 228
		ACTIONS => {
			'DATE' => 4,
			"\$" => 128,
			'INDEX' => 23,
			'INTEGER' => 40,
			'SYMBOL' => 66
		},
		GOTOS => {
			'symbol' => 127,
			's_index' => 125,
			'index' => 25,
			's_indextuple_item' => 281
		}
	},
	{#State 229
		DEFAULT => -202
	},
	{#State 230
		ACTIONS => {
			'LESS_BY_COUNT' => 287,
			'SAMPLE' => 286,
			'BY' => 290,
			'CLIMIT' => 291,
			'GREATER_BY_KEY' => 285,
			'LESS_BY_KEY' => 293,
			'GREATER_BY_COUNT' => 294
		},
		DEFAULT => -206,
		GOTOS => {
			'count_sample' => 282,
			'count_by' => 292,
			'count_sort_op' => 284,
			'count_filter' => 283,
			'count_limit' => 288,
			'count_sort' => 289
		}
	},
	{#State 231
		DEFAULT => -196
	},
	{#State 232
		ACTIONS => {
			'INTEGER' => 135
		},
		GOTOS => {
			'integer' => 295,
			'int_str' => 139
		}
	},
	{#State 233
		DEFAULT => -33
	},
	{#State 234
		DEFAULT => -35
	},
	{#State 235
		DEFAULT => -258
	},
	{#State 236
		DEFAULT => -257
	},
	{#State 237
		ACTIONS => {
			"!" => 237,
			'HAS_FIELD' => 168
		},
		GOTOS => {
			'qf_has_field' => 240
		}
	},
	{#State 238
		DEFAULT => -41
	},
	{#State 239
		DEFAULT => -39
	},
	{#State 240
		DEFAULT => -59
	},
	{#State 241
		ACTIONS => {
			'DATE' => 297,
			'INTEGER' => 296
		},
		GOTOS => {
			'date' => 298
		}
	},
	{#State 242
		ACTIONS => {
			'INTEGER' => 135
		},
		GOTOS => {
			'int_str' => 299
		}
	},
	{#State 243
		DEFAULT => -72
	},
	{#State 244
		ACTIONS => {
			"]" => 301,
			'INTEGER' => 296,
			"," => 300,
			'DATE' => 297
		},
		GOTOS => {
			'date' => 302
		}
	},
	{#State 245
		ACTIONS => {
			'INTEGER' => 40,
			'SYMBOL' => 66,
			'DATE' => 4,
			'KW_DATE' => 304
		},
		GOTOS => {
			'symbol' => 303,
			's_biblname' => 305
		}
	},
	{#State 246
		DEFAULT => -62
	},
	{#State 247
		ACTIONS => {
			"=" => 82,
			'SYMBOL' => 308
		},
		DEFAULT => -107,
		GOTOS => {
			'matchid_eq' => 83,
			'qfb_ctxkey' => 306,
			'sym_str' => 307,
			'qfbc_matchref' => 310,
			'matchid' => 309
		}
	},
	{#State 248
		DEFAULT => -68
	},
	{#State 249
		ACTIONS => {
			"," => 313,
			'INTEGER' => 135,
			"]" => 312
		},
		GOTOS => {
			'int_str' => 311
		}
	},
	{#State 250
		ACTIONS => {
			'INTEGER' => 135,
			"]" => 314
		},
		GOTOS => {
			'int_str' => 315
		}
	},
	{#State 251
		ACTIONS => {
			'INTEGER' => 40,
			'SYMBOL' => 66,
			'DATE' => 4,
			'KW_DATE' => 316
		},
		GOTOS => {
			's_biblname' => 317,
			'symbol' => 303
		}
	},
	{#State 252
		DEFAULT => -65
	},
	{#State 253
		DEFAULT => -67
	},
	{#State 254
		DEFAULT => -43
	},
	{#State 255
		ACTIONS => {
			"," => 318
		},
		DEFAULT => -32
	},
	{#State 256
		DEFAULT => -255
	},
	{#State 257
		DEFAULT => -63
	},
	{#State 258
		DEFAULT => -69
	},
	{#State 259
		ACTIONS => {
			'SYMBOL' => 66,
			'INTEGER' => 40,
			'DATE' => 4
		},
		GOTOS => {
			'symbol' => 303,
			's_biblname' => 319
		}
	},
	{#State 260
		DEFAULT => -64
	},
	{#State 261
		DEFAULT => -66
	},
	{#State 262
		DEFAULT => -71
	},
	{#State 263
		ACTIONS => {
			'CLIMIT' => 291,
			'GREATER_BY_KEY' => 285,
			'LESS_BY_KEY' => 293,
			'GREATER_BY_COUNT' => 294,
			'LESS_BY_COUNT' => 287,
			'SAMPLE' => 286,
			")" => 320,
			'BY' => 290
		},
		GOTOS => {
			'count_sample' => 282,
			'count_by' => 292,
			'count_sort' => 289,
			'count_filter' => 283,
			'count_sort_op' => 284,
			'count_limit' => 288
		}
	},
	{#State 264
		ACTIONS => {
			"%" => 35,
			"<" => 20,
			'PREFIX' => 70,
			"*" => 36,
			'NEAR' => 72,
			"{" => 64,
			'SYMBOL' => 66,
			'COLON_LBRACE' => 52,
			"^" => 68,
			"\@" => 28,
			'KEYS' => 9,
			'INFIX' => 10,
			"(" => 59,
			'COUNT' => 31,
			'AT_LBRACE' => 11,
			"[" => 47,
			'DOLLAR_DOT' => 12,
			"\"" => 62,
			'REGEX' => 37,
			'INDEX' => 23,
			'DATE' => 4,
			"\$" => 5,
			'INTEGER' => 40,
			'STAR_LBRACE' => 42,
			'NEG_REGEX' => 7,
			'SUFFIX' => 26,
			"!" => 8
		},
		GOTOS => {
			'qw_keys' => 54,
			'qc_near' => 21,
			'qw_lemma' => 51,
			'qc_word' => 50,
			'qw_matchid' => 49,
			'qw_any' => 15,
			's_infix' => 14,
			'qw_infix' => 16,
			'count_query' => 129,
			'qw_with' => 19,
			'neg_regex' => 18,
			'query_conditions' => 131,
			'qw_exact' => 44,
			'qw_listfile' => 45,
			'qw_infix_set' => 46,
			'qw_set_exact' => 48,
			'qw_bareword' => 13,
			'qw_suffix_set' => 3,
			'qw_set_infl' => 2,
			'qc_boolean' => 1,
			'qw_prefix_set' => 39,
			'qw_prefix' => 41,
			'qw_chunk' => 6,
			'regex' => 43,
			's_index' => 69,
			's_word' => 71,
			'qwk_countsrc' => 321,
			'symbol' => 33,
			'qc_concat' => 65,
			'qw_suffix' => 34,
			'qw_morph' => 67,
			's_suffix' => 57,
			'qw_withor' => 29,
			'q_clause' => 30,
			'qw_without' => 60,
			'qc_matchid' => 58,
			's_prefix' => 61,
			'qc_basic' => 32,
			'qc_phrase' => 63,
			'qw_anchor' => 22,
			'qwk_indextuple' => 55,
			'qc_tokens' => 56,
			'qw_regex' => 24,
			'qw_thesaurus' => 27,
			'index' => 25
		}
	},
	{#State 265
		ACTIONS => {
			'INTEGER' => 40,
			'INDEX' => 23,
			'DATE' => 4,
			"\$" => 5,
			'REGEX' => 37,
			'SUFFIX' => 26,
			'NEG_REGEX' => 7,
			'STAR_LBRACE' => 42,
			"(" => 114,
			'INFIX' => 10,
			'KEYS' => 9,
			"\@" => 28,
			"[" => 47,
			'DOLLAR_DOT' => 12,
			'AT_LBRACE' => 11,
			'SYMBOL' => 66,
			"{" => 64,
			"^" => 68,
			'COLON_LBRACE' => 52,
			"<" => 20,
			"%" => 35,
			"*" => 36,
			'PREFIX' => 70
		},
		GOTOS => {
			'regex' => 43,
			'qw_prefix' => 41,
			'qw_chunk' => 6,
			'qw_prefix_set' => 39,
			'qw_set_infl' => 2,
			'qw_suffix_set' => 3,
			'qw_set_exact' => 48,
			'qw_bareword' => 13,
			'qw_infix_set' => 46,
			'qw_listfile' => 45,
			'qw_exact' => 44,
			'neg_regex' => 18,
			'qw_with' => 19,
			'qw_infix' => 16,
			'qw_matchid' => 49,
			's_infix' => 14,
			'qw_any' => 15,
			'qc_word' => 322,
			'qw_lemma' => 51,
			'qw_keys' => 54,
			'index' => 25,
			'qw_thesaurus' => 27,
			'qw_regex' => 24,
			'qwk_indextuple' => 55,
			'qw_anchor' => 22,
			's_prefix' => 61,
			'qw_without' => 60,
			'qw_withor' => 29,
			's_suffix' => 57,
			'qw_morph' => 67,
			'qw_suffix' => 34,
			'symbol' => 33,
			's_word' => 71,
			's_index' => 69
		}
	},
	{#State 266
		ACTIONS => {
			'SYMBOL' => 66,
			"{" => 64,
			"^" => 68,
			'COLON_LBRACE' => 52,
			"<" => 20,
			"%" => 35,
			'PREFIX' => 70,
			"*" => 36,
			"\$" => 5,
			'INDEX' => 23,
			'DATE' => 4,
			'INTEGER' => 40,
			'REGEX' => 37,
			'SUFFIX' => 26,
			'STAR_LBRACE' => 42,
			'NEG_REGEX' => 7,
			'INFIX' => 10,
			"(" => 114,
			"\@" => 28,
			'KEYS' => 9,
			"[" => 47,
			'DOLLAR_DOT' => 12,
			'AT_LBRACE' => 11
		},
		GOTOS => {
			'qw_set_exact' => 48,
			'qw_bareword' => 13,
			'qw_infix_set' => 46,
			'qw_exact' => 44,
			'qw_listfile' => 45,
			'regex' => 43,
			'qw_prefix' => 41,
			'qw_chunk' => 6,
			'qw_prefix_set' => 39,
			'qw_set_infl' => 2,
			'qw_suffix_set' => 3,
			'qw_keys' => 54,
			'neg_regex' => 18,
			'qw_with' => 19,
			'qw_infix' => 16,
			'qc_word' => 323,
			'qw_matchid' => 49,
			'qw_any' => 15,
			's_infix' => 14,
			'qw_lemma' => 51,
			's_prefix' => 61,
			'qw_without' => 60,
			'qw_withor' => 29,
			's_suffix' => 57,
			'index' => 25,
			'qw_thesaurus' => 27,
			'qw_regex' => 24,
			'qwk_indextuple' => 55,
			'qw_anchor' => 22,
			's_word' => 71,
			's_index' => 69,
			'qw_suffix' => 34,
			'qw_morph' => 67,
			'symbol' => 33
		}
	},
	{#State 267
		ACTIONS => {
			'NEG_REGEX' => 7,
			'STAR_LBRACE' => 42,
			'SUFFIX' => 26,
			'REGEX' => 37,
			'INTEGER' => 40,
			"\$" => 5,
			'DATE' => 4,
			'INDEX' => 23,
			'AT_LBRACE' => 11,
			"[" => 47,
			'DOLLAR_DOT' => 12,
			'KEYS' => 9,
			"\@" => 28,
			"(" => 114,
			'INFIX' => 10,
			'COLON_LBRACE' => 52,
			"^" => 68,
			"{" => 64,
			'SYMBOL' => 66,
			"*" => 36,
			'PREFIX' => 70,
			"%" => 35,
			"<" => 20
		},
		GOTOS => {
			'qw_with' => 19,
			'neg_regex' => 18,
			'qw_lemma' => 51,
			'qw_any' => 15,
			'qw_matchid' => 49,
			's_infix' => 14,
			'qc_word' => 324,
			'qw_infix' => 16,
			'qw_keys' => 54,
			'qw_chunk' => 6,
			'qw_prefix' => 41,
			'regex' => 43,
			'qw_suffix_set' => 3,
			'qw_set_infl' => 2,
			'qw_prefix_set' => 39,
			'qw_set_exact' => 48,
			'qw_bareword' => 13,
			'qw_exact' => 44,
			'qw_listfile' => 45,
			'qw_infix_set' => 46,
			'qw_suffix' => 34,
			'qw_morph' => 67,
			'symbol' => 33,
			's_word' => 71,
			's_index' => 69,
			'qw_thesaurus' => 27,
			'index' => 25,
			'qw_anchor' => 22,
			'qwk_indextuple' => 55,
			'qw_regex' => 24,
			's_prefix' => 61,
			's_suffix' => 57,
			'qw_withor' => 29,
			'qw_without' => 60
		}
	},
	{#State 268
		ACTIONS => {
			"(" => 114,
			'INFIX' => 10,
			'KEYS' => 9,
			"\@" => 28,
			"[" => 47,
			'DOLLAR_DOT' => 12,
			'AT_LBRACE' => 11,
			'INTEGER' => 40,
			"\$" => 5,
			'DATE' => 4,
			'INDEX' => 23,
			'REGEX' => 37,
			'SUFFIX' => 26,
			'NEG_REGEX' => 7,
			'STAR_LBRACE' => 42,
			"<" => 20,
			"%" => 35,
			"*" => 36,
			'PREFIX' => 70,
			'SYMBOL' => 66,
			"{" => 64,
			"^" => 68,
			'COLON_LBRACE' => 52
		},
		GOTOS => {
			'qw_regex' => 24,
			'qw_anchor' => 22,
			'qwk_indextuple' => 55,
			'qw_thesaurus' => 27,
			'index' => 25,
			'qw_without' => 60,
			's_suffix' => 57,
			'qw_withor' => 29,
			's_prefix' => 61,
			'symbol' => 33,
			'qw_morph' => 67,
			'qw_suffix' => 34,
			's_index' => 69,
			's_word' => 71,
			'qw_prefix_set' => 39,
			'qw_suffix_set' => 3,
			'qw_set_infl' => 2,
			'regex' => 43,
			'qw_chunk' => 6,
			'qw_prefix' => 41,
			'qw_infix_set' => 46,
			'qw_listfile' => 45,
			'qw_exact' => 44,
			'qw_set_exact' => 48,
			'qw_bareword' => 13,
			'qw_infix' => 16,
			'qw_lemma' => 51,
			'qw_any' => 15,
			's_infix' => 14,
			'qc_word' => 325,
			'qw_matchid' => 49,
			'qw_with' => 19,
			'neg_regex' => 18,
			'qw_keys' => 54
		}
	},
	{#State 269
		ACTIONS => {
			'EXPANDER' => 224
		},
		DEFAULT => -173,
		GOTOS => {
			's_expander' => 223
		}
	},
	{#State 270
		ACTIONS => {
			"]" => 326,
			'DATE' => 4,
			"," => 186,
			'SYMBOL' => 66,
			'INTEGER' => 40,
			";" => 187
		},
		GOTOS => {
			's_morphitem' => 185,
			'symbol' => 183
		}
	},
	{#State 271
		ACTIONS => {
			'DATE' => 4,
			'RBRACE_STAR' => 328,
			'INTEGER' => 40,
			"," => 132,
			'SYMBOL' => 66,
			"}" => 327
		},
		GOTOS => {
			'symbol' => 33,
			's_word' => 133
		}
	},
	{#State 272
		ACTIONS => {
			'EXPANDER' => 224
		},
		DEFAULT => -162,
		GOTOS => {
			's_expander' => 223
		}
	},
	{#State 273
		DEFAULT => -194
	},
	{#State 274
		ACTIONS => {
			"}" => 329,
			'DATE' => 4,
			'RBRACE_STAR' => 330,
			"," => 132,
			'SYMBOL' => 66,
			'INTEGER' => 40
		},
		GOTOS => {
			's_word' => 133,
			'symbol' => 33
		}
	},
	{#State 275
		ACTIONS => {
			'SYMBOL' => 66,
			'INTEGER' => 40,
			'DATE' => 4
		},
		GOTOS => {
			's_semclass' => 331,
			'symbol' => 104
		}
	},
	{#State 276
		DEFAULT => -198
	},
	{#State 277
		ACTIONS => {
			"," => 132,
			'INTEGER' => 40,
			'SYMBOL' => 66,
			'DATE' => 4,
			"}" => 332
		},
		GOTOS => {
			'symbol' => 33,
			's_word' => 133
		}
	},
	{#State 278
		DEFAULT => -192
	},
	{#State 279
		DEFAULT => -164
	},
	{#State 280
		ACTIONS => {
			"*" => 36,
			'PREFIX' => 70,
			"%" => 35,
			"<" => 20,
			'COLON_LBRACE' => 52,
			"^" => 68,
			"{" => 64,
			'SYMBOL' => 66,
			'AT_LBRACE' => 11,
			"\"" => 62,
			"[" => 47,
			'DOLLAR_DOT' => 12,
			'KEYS' => 9,
			"\@" => 28,
			"(" => 226,
			'INFIX' => 10,
			'NEG_REGEX' => 7,
			'STAR_LBRACE' => 42,
			'SUFFIX' => 26,
			'REGEX' => 37,
			'INTEGER' => 40,
			"\$" => 5,
			'INDEX' => 23,
			'DATE' => 4
		},
		GOTOS => {
			'qw_bareword' => 13,
			'qw_set_exact' => 48,
			'qw_listfile' => 45,
			'qw_exact' => 44,
			'qw_infix_set' => 46,
			'qw_prefix' => 41,
			'qw_chunk' => 6,
			'regex' => 43,
			'qw_set_infl' => 2,
			'qw_suffix_set' => 3,
			'qw_prefix_set' => 39,
			'qw_keys' => 54,
			'neg_regex' => 18,
			'qw_with' => 19,
			'qw_matchid' => 49,
			's_infix' => 14,
			'qw_any' => 15,
			'qc_word' => 50,
			'qw_lemma' => 51,
			'qw_infix' => 16,
			'qc_phrase' => 63,
			's_prefix' => 61,
			'qw_withor' => 29,
			's_suffix' => 57,
			'qw_without' => 60,
			'index' => 25,
			'qw_thesaurus' => 27,
			'qwk_indextuple' => 55,
			'qw_anchor' => 22,
			'qw_regex' => 24,
			'qc_tokens' => 333,
			's_word' => 71,
			's_index' => 69,
			'qw_morph' => 67,
			'qw_suffix' => 34,
			'symbol' => 33
		}
	},
	{#State 281
		DEFAULT => -228
	},
	{#State 282
		DEFAULT => -7
	},
	{#State 283
		DEFAULT => -5
	},
	{#State 284
		ACTIONS => {
			"[" => 335
		},
		DEFAULT => -21,
		GOTOS => {
			'count_sort_minmax' => 334
		}
	},
	{#State 285
		DEFAULT => -18
	},
	{#State 286
		ACTIONS => {
			"[" => 336,
			'INTEGER' => 135
		},
		GOTOS => {
			'integer' => 337,
			'int_str' => 139
		}
	},
	{#State 287
		DEFAULT => -19
	},
	{#State 288
		DEFAULT => -8
	},
	{#State 289
		DEFAULT => -9
	},
	{#State 290
		ACTIONS => {
			"*" => 341,
			'KW_FILENAME' => 340,
			'SYMBOL' => 66,
			'KW_DATE' => 347,
			"[" => 343,
			"(" => 346,
			"\@" => 339,
			'KW_FILEID' => 345,
			'INTEGER' => 40,
			'DATE' => 4,
			'INDEX' => 23,
			"\$" => 128
		},
		DEFAULT => -223,
		GOTOS => {
			's_index' => 348,
			'symbol' => 303,
			'count_key' => 344,
			'l_countkeys' => 338,
			'index' => 25,
			's_biblname' => 342
		}
	},
	{#State 291
		ACTIONS => {
			"[" => 349,
			'INTEGER' => 135
		},
		GOTOS => {
			'int_str' => 139,
			'integer' => 350
		}
	},
	{#State 292
		DEFAULT => -6
	},
	{#State 293
		DEFAULT => -17
	},
	{#State 294
		DEFAULT => -20
	},
	{#State 295
		ACTIONS => {
			"]" => 351
		}
	},
	{#State 296
		DEFAULT => -278
	},
	{#State 297
		DEFAULT => -277
	},
	{#State 298
		ACTIONS => {
			"]" => 352
		}
	},
	{#State 299
		ACTIONS => {
			"]" => 353
		}
	},
	{#State 300
		ACTIONS => {
			'INTEGER' => 296,
			'DATE' => 297
		},
		GOTOS => {
			'date' => 354
		}
	},
	{#State 301
		DEFAULT => -89
	},
	{#State 302
		ACTIONS => {
			"]" => 355,
			"," => 356
		}
	},
	{#State 303
		DEFAULT => -256
	},
	{#State 304
		ACTIONS => {
			"," => 359
		},
		DEFAULT => -94,
		GOTOS => {
			'qfb_bibl_ne' => 357,
			'qfb_bibl' => 358
		}
	},
	{#State 305
		ACTIONS => {
			"," => 359
		},
		DEFAULT => -94,
		GOTOS => {
			'qfb_bibl_ne' => 357,
			'qfb_bibl' => 360
		}
	},
	{#State 306
		ACTIONS => {
			"," => 359,
			"]" => 362
		},
		GOTOS => {
			'qfb_bibl_ne' => 361
		}
	},
	{#State 307
		ACTIONS => {
			"=" => 82
		},
		DEFAULT => -107,
		GOTOS => {
			'matchid_eq' => 83,
			'qfbc_matchref' => 363,
			'matchid' => 309
		}
	},
	{#State 308
		DEFAULT => -264
	},
	{#State 309
		DEFAULT => -108
	},
	{#State 310
		ACTIONS => {
			"+" => 366,
			'INTEGER' => 135,
			"-" => 365
		},
		DEFAULT => -109,
		GOTOS => {
			'int_str' => 139,
			'integer' => 364,
			'qfbc_offset' => 367
		}
	},
	{#State 311
		ACTIONS => {
			"]" => 369,
			"," => 368
		}
	},
	{#State 312
		DEFAULT => -82
	},
	{#State 313
		ACTIONS => {
			"]" => 371,
			'INTEGER' => 135
		},
		GOTOS => {
			'int_str' => 370
		}
	},
	{#State 314
		DEFAULT => -75
	},
	{#State 315
		ACTIONS => {
			"]" => 372
		}
	},
	{#State 316
		ACTIONS => {
			"," => 359
		},
		DEFAULT => -94,
		GOTOS => {
			'qfb_bibl' => 373,
			'qfb_bibl_ne' => 357
		}
	},
	{#State 317
		ACTIONS => {
			"," => 359
		},
		DEFAULT => -94,
		GOTOS => {
			'qfb_bibl' => 374,
			'qfb_bibl_ne' => 357
		}
	},
	{#State 318
		ACTIONS => {
			'SYMBOL' => 66,
			'INTEGER' => 40,
			'DATE' => 4
		},
		GOTOS => {
			's_subcorpus' => 375,
			'symbol' => 256
		}
	},
	{#State 319
		ACTIONS => {
			"," => 376
		}
	},
	{#State 320
		DEFAULT => -4,
		GOTOS => {
			'count_filters' => 377
		}
	},
	{#State 321
		ACTIONS => {
			")" => 378
		}
	},
	{#State 322
		ACTIONS => {
			'WITHOUT' => 99,
			"=" => 82,
			'WITHOR' => 101,
			'WITH' => 100
		},
		DEFAULT => -219,
		GOTOS => {
			'matchid_eq' => 83,
			'matchid' => 102
		}
	},
	{#State 323
		ACTIONS => {
			'WITH' => 100,
			'WITHOR' => 101,
			"=" => 82,
			'WITHOUT' => 99
		},
		DEFAULT => -218,
		GOTOS => {
			'matchid' => 102,
			'matchid_eq' => 83
		}
	},
	{#State 324
		ACTIONS => {
			'WITHOR' => 101,
			'WITH' => 100,
			'WITHOUT' => 99,
			"=" => 82
		},
		DEFAULT => -220,
		GOTOS => {
			'matchid_eq' => 83,
			'matchid' => 102
		}
	},
	{#State 325
		ACTIONS => {
			'WITH' => 100,
			'WITHOR' => 101,
			"=" => 82,
			'WITHOUT' => 99
		},
		DEFAULT => -217,
		GOTOS => {
			'matchid_eq' => 83,
			'matchid' => 102
		}
	},
	{#State 326
		DEFAULT => -190
	},
	{#State 327
		DEFAULT => -186
	},
	{#State 328
		DEFAULT => -182
	},
	{#State 329
		DEFAULT => -221,
		GOTOS => {
			'l_txchain' => 379
		}
	},
	{#State 330
		DEFAULT => -184
	},
	{#State 331
		ACTIONS => {
			"}" => 380
		}
	},
	{#State 332
		DEFAULT => -172
	},
	{#State 333
		ACTIONS => {
			"=" => 82,
			"," => 381
		},
		GOTOS => {
			'matchid' => 106,
			'matchid_eq' => 83
		}
	},
	{#State 334
		DEFAULT => -16
	},
	{#State 335
		ACTIONS => {
			'SYMBOL' => 66,
			'INTEGER' => 40,
			"," => 384,
			'DATE' => 4,
			"]" => 383
		},
		GOTOS => {
			'symbol' => 382
		}
	},
	{#State 336
		ACTIONS => {
			'INTEGER' => 135
		},
		GOTOS => {
			'int_str' => 139,
			'integer' => 385
		}
	},
	{#State 337
		DEFAULT => -12
	},
	{#State 338
		ACTIONS => {
			"," => 386
		},
		DEFAULT => -10
	},
	{#State 339
		ACTIONS => {
			'DATE' => 4,
			'INTEGER' => 40,
			'SYMBOL' => 66
		},
		GOTOS => {
			'symbol' => 387
		}
	},
	{#State 340
		DEFAULT => -232
	},
	{#State 341
		DEFAULT => -229
	},
	{#State 342
		DEFAULT => -235
	},
	{#State 343
		ACTIONS => {
			"\@" => 339,
			"(" => 346,
			'KW_FILENAME' => 340,
			"*" => 341,
			'KW_DATE' => 347,
			'INTEGER' => 40,
			'SYMBOL' => 66,
			"\$" => 128,
			'DATE' => 4,
			'INDEX' => 23,
			'KW_FILEID' => 345
		},
		DEFAULT => -223,
		GOTOS => {
			's_index' => 348,
			'symbol' => 303,
			'count_key' => 344,
			'l_countkeys' => 388,
			'index' => 25,
			's_biblname' => 342
		}
	},
	{#State 344
		ACTIONS => {
			"~" => 389
		},
		DEFAULT => -224
	},
	{#State 345
		DEFAULT => -231
	},
	{#State 346
		ACTIONS => {
			"*" => 341,
			'KW_FILENAME' => 340,
			"(" => 346,
			"\@" => 339,
			'KW_FILEID' => 345,
			'SYMBOL' => 66,
			'INTEGER' => 40,
			"\$" => 128,
			'DATE' => 4,
			'INDEX' => 23,
			'KW_DATE' => 347
		},
		GOTOS => {
			's_index' => 348,
			'symbol' => 303,
			'count_key' => 390,
			's_biblname' => 342,
			'index' => 25
		}
	},
	{#State 347
		ACTIONS => {
			"/" => 391
		},
		DEFAULT => -233
	},
	{#State 348
		ACTIONS => {
			"=" => 82
		},
		DEFAULT => -239,
		GOTOS => {
			'matchid_eq' => 83,
			'matchid' => 393,
			'ck_matchid' => 392
		}
	},
	{#State 349
		ACTIONS => {
			'INTEGER' => 135
		},
		GOTOS => {
			'int_str' => 139,
			'integer' => 394
		}
	},
	{#State 350
		DEFAULT => -14
	},
	{#State 351
		DEFAULT => -34
	},
	{#State 352
		DEFAULT => -73
	},
	{#State 353
		DEFAULT => -70
	},
	{#State 354
		ACTIONS => {
			"]" => 395
		}
	},
	{#State 355
		DEFAULT => -90
	},
	{#State 356
		ACTIONS => {
			"]" => 397,
			'DATE' => 297,
			'INTEGER' => 296
		},
		GOTOS => {
			'date' => 396
		}
	},
	{#State 357
		DEFAULT => -95
	},
	{#State 358
		ACTIONS => {
			"]" => 398
		}
	},
	{#State 359
		ACTIONS => {
			'DATE' => 4,
			"," => 399,
			'SYMBOL' => 66,
			'INTEGER' => 40
		},
		DEFAULT => -96,
		GOTOS => {
			'symbol' => 400
		}
	},
	{#State 360
		ACTIONS => {
			"]" => 401
		}
	},
	{#State 361
		ACTIONS => {
			"]" => 402
		}
	},
	{#State 362
		DEFAULT => -103
	},
	{#State 363
		ACTIONS => {
			"+" => 366,
			"-" => 365,
			'INTEGER' => 135
		},
		DEFAULT => -109,
		GOTOS => {
			'integer' => 364,
			'qfbc_offset' => 403,
			'int_str' => 139
		}
	},
	{#State 364
		DEFAULT => -110
	},
	{#State 365
		ACTIONS => {
			'INTEGER' => 135
		},
		GOTOS => {
			'int_str' => 139,
			'integer' => 404
		}
	},
	{#State 366
		ACTIONS => {
			'INTEGER' => 135
		},
		GOTOS => {
			'integer' => 405,
			'int_str' => 139
		}
	},
	{#State 367
		DEFAULT => -106
	},
	{#State 368
		ACTIONS => {
			"]" => 407,
			'INTEGER' => 135
		},
		GOTOS => {
			'int_str' => 406
		}
	},
	{#State 369
		DEFAULT => -84
	},
	{#State 370
		ACTIONS => {
			"]" => 408
		}
	},
	{#State 371
		DEFAULT => -83
	},
	{#State 372
		DEFAULT => -76
	},
	{#State 373
		ACTIONS => {
			"]" => 409
		}
	},
	{#State 374
		ACTIONS => {
			"]" => 410
		}
	},
	{#State 375
		DEFAULT => -44
	},
	{#State 376
		ACTIONS => {
			'PREFIX' => 70,
			'INFIX' => 10,
			'NEG_REGEX' => 7,
			'SUFFIX' => 26,
			"{" => 414,
			'REGEX' => 37,
			'SYMBOL' => 66,
			'INTEGER' => 40,
			'DATE' => 4
		},
		GOTOS => {
			's_suffix' => 416,
			'symbol' => 411,
			's_infix' => 413,
			's_prefix' => 415,
			'regex' => 417,
			'neg_regex' => 412
		}
	},
	{#State 377
		ACTIONS => {
			'CLIMIT' => 291,
			'GREATER_BY_COUNT' => 294,
			'LESS_BY_KEY' => 293,
			'GREATER_BY_KEY' => 285,
			'LESS_BY_COUNT' => 287,
			'SAMPLE' => 286,
			'BY' => 290
		},
		DEFAULT => -3,
		GOTOS => {
			'count_sort' => 289,
			'count_filter' => 283,
			'count_sort_op' => 284,
			'count_limit' => 288,
			'count_sample' => 282,
			'count_by' => 292
		}
	},
	{#State 378
		DEFAULT => -203
	},
	{#State 379
		ACTIONS => {
			'EXPANDER' => 224
		},
		DEFAULT => -174,
		GOTOS => {
			's_expander' => 223
		}
	},
	{#State 380
		DEFAULT => -188
	},
	{#State 381
		ACTIONS => {
			"<" => 20,
			"%" => 35,
			"*" => 36,
			'PREFIX' => 70,
			'SYMBOL' => 66,
			"{" => 64,
			"^" => 68,
			'COLON_LBRACE' => 52,
			"(" => 226,
			'INFIX' => 10,
			'KEYS' => 9,
			"\@" => 28,
			"\"" => 62,
			'DOLLAR_DOT' => 12,
			"[" => 47,
			'AT_LBRACE' => 11,
			'INTEGER' => 420,
			"\$" => 5,
			'DATE' => 4,
			'INDEX' => 23,
			'REGEX' => 37,
			'SUFFIX' => 26,
			'NEG_REGEX' => 7,
			'STAR_LBRACE' => 42
		},
		GOTOS => {
			'qw_keys' => 54,
			'neg_regex' => 18,
			'qw_with' => 19,
			'qw_infix' => 16,
			's_infix' => 14,
			'qc_word' => 50,
			'qw_matchid' => 49,
			'qw_any' => 15,
			'qw_lemma' => 51,
			'qw_set_exact' => 48,
			'qw_bareword' => 13,
			'qw_infix_set' => 46,
			'qw_listfile' => 45,
			'qw_exact' => 44,
			'regex' => 43,
			'qw_prefix' => 41,
			'qw_chunk' => 6,
			'qw_prefix_set' => 39,
			'qw_set_infl' => 2,
			'qw_suffix_set' => 3,
			's_word' => 71,
			's_index' => 69,
			'qw_morph' => 67,
			'qw_suffix' => 34,
			'symbol' => 33,
			'qc_phrase' => 63,
			's_prefix' => 61,
			'qw_without' => 60,
			'qw_withor' => 29,
			's_suffix' => 57,
			'index' => 25,
			'qw_thesaurus' => 27,
			'qw_regex' => 24,
			'int_str' => 139,
			'qc_tokens' => 418,
			'qwk_indextuple' => 55,
			'integer' => 419,
			'qw_anchor' => 22
		}
	},
	{#State 382
		ACTIONS => {
			"]" => 422,
			"," => 421
		}
	},
	{#State 383
		DEFAULT => -22
	},
	{#State 384
		ACTIONS => {
			'DATE' => 4,
			'SYMBOL' => 66,
			'INTEGER' => 40,
			"]" => 423
		},
		GOTOS => {
			'symbol' => 424
		}
	},
	{#State 385
		ACTIONS => {
			"]" => 425
		}
	},
	{#State 386
		ACTIONS => {
			"(" => 346,
			"\@" => 339,
			"*" => 341,
			'KW_FILENAME' => 340,
			"\$" => 128,
			'INDEX' => 23,
			'DATE' => 4,
			'INTEGER' => 40,
			'SYMBOL' => 66,
			'KW_DATE' => 347,
			'KW_FILEID' => 345
		},
		GOTOS => {
			'index' => 25,
			's_biblname' => 342,
			'count_key' => 426,
			'symbol' => 303,
			's_index' => 348
		}
	},
	{#State 387
		DEFAULT => -230
	},
	{#State 388
		ACTIONS => {
			"," => 386,
			"]" => 427
		}
	},
	{#State 389
		ACTIONS => {
			'REGEX_SEARCH' => 429
		},
		GOTOS => {
			'replace_regex' => 428
		}
	},
	{#State 390
		ACTIONS => {
			")" => 430,
			"~" => 389
		}
	},
	{#State 391
		ACTIONS => {
			'INTEGER' => 135
		},
		GOTOS => {
			'int_str' => 139,
			'integer' => 431
		}
	},
	{#State 392
		ACTIONS => {
			'INTEGER' => 135,
			"+" => 433,
			"-" => 434
		},
		DEFAULT => -241,
		GOTOS => {
			'ck_offset' => 432,
			'integer' => 435,
			'int_str' => 139
		}
	},
	{#State 393
		DEFAULT => -240
	},
	{#State 394
		ACTIONS => {
			"]" => 436
		}
	},
	{#State 395
		DEFAULT => -93
	},
	{#State 396
		ACTIONS => {
			"]" => 437
		}
	},
	{#State 397
		DEFAULT => -91
	},
	{#State 398
		DEFAULT => -77
	},
	{#State 399
		ACTIONS => {
			'DATE' => 4,
			'SYMBOL' => 66,
			'INTEGER' => 40
		},
		DEFAULT => -97,
		GOTOS => {
			'symbol' => 438
		}
	},
	{#State 400
		ACTIONS => {
			"," => 439
		},
		DEFAULT => -98
	},
	{#State 401
		DEFAULT => -79
	},
	{#State 402
		DEFAULT => -104
	},
	{#State 403
		DEFAULT => -105
	},
	{#State 404
		DEFAULT => -112
	},
	{#State 405
		DEFAULT => -111
	},
	{#State 406
		ACTIONS => {
			"]" => 440
		}
	},
	{#State 407
		DEFAULT => -85
	},
	{#State 408
		DEFAULT => -87
	},
	{#State 409
		DEFAULT => -78
	},
	{#State 410
		DEFAULT => -80
	},
	{#State 411
		ACTIONS => {
			"]" => 441
		}
	},
	{#State 412
		ACTIONS => {
			"]" => 442
		}
	},
	{#State 413
		ACTIONS => {
			"]" => 443
		}
	},
	{#State 414
		DEFAULT => -208,
		GOTOS => {
			'l_set' => 444
		}
	},
	{#State 415
		ACTIONS => {
			"]" => 445
		}
	},
	{#State 416
		ACTIONS => {
			"]" => 446
		}
	},
	{#State 417
		ACTIONS => {
			"]" => 447
		}
	},
	{#State 418
		ACTIONS => {
			"," => 448,
			"=" => 82
		},
		GOTOS => {
			'matchid_eq' => 83,
			'matchid' => 106
		}
	},
	{#State 419
		ACTIONS => {
			")" => 449
		}
	},
	{#State 420
		ACTIONS => {
			")" => -275
		},
		DEFAULT => -260
	},
	{#State 421
		ACTIONS => {
			"]" => 450,
			'INTEGER' => 40,
			'SYMBOL' => 66,
			'DATE' => 4
		},
		GOTOS => {
			'symbol' => 451
		}
	},
	{#State 422
		DEFAULT => -24
	},
	{#State 423
		DEFAULT => -23
	},
	{#State 424
		ACTIONS => {
			"]" => 452
		}
	},
	{#State 425
		DEFAULT => -13
	},
	{#State 426
		ACTIONS => {
			"~" => 389
		},
		DEFAULT => -225
	},
	{#State 427
		DEFAULT => -11
	},
	{#State 428
		DEFAULT => -237
	},
	{#State 429
		ACTIONS => {
			'REGEX_REPLACE' => 453
		}
	},
	{#State 430
		DEFAULT => -238
	},
	{#State 431
		DEFAULT => -234
	},
	{#State 432
		DEFAULT => -236
	},
	{#State 433
		ACTIONS => {
			'INTEGER' => 135
		},
		GOTOS => {
			'int_str' => 139,
			'integer' => 454
		}
	},
	{#State 434
		ACTIONS => {
			'INTEGER' => 135
		},
		GOTOS => {
			'int_str' => 139,
			'integer' => 455
		}
	},
	{#State 435
		DEFAULT => -242
	},
	{#State 436
		DEFAULT => -15
	},
	{#State 437
		DEFAULT => -92
	},
	{#State 438
		DEFAULT => -100
	},
	{#State 439
		ACTIONS => {
			'DATE' => 4,
			'INTEGER' => 40,
			'SYMBOL' => 66
		},
		DEFAULT => -99,
		GOTOS => {
			'symbol' => 456
		}
	},
	{#State 440
		DEFAULT => -86
	},
	{#State 441
		DEFAULT => -52
	},
	{#State 442
		DEFAULT => -54
	},
	{#State 443
		DEFAULT => -57
	},
	{#State 444
		ACTIONS => {
			"}" => 457,
			'SYMBOL' => 66,
			"," => 132,
			'INTEGER' => 40,
			'DATE' => 4
		},
		GOTOS => {
			's_word' => 133,
			'symbol' => 33
		}
	},
	{#State 445
		DEFAULT => -55
	},
	{#State 446
		DEFAULT => -56
	},
	{#State 447
		DEFAULT => -53
	},
	{#State 448
		ACTIONS => {
			'INTEGER' => 135
		},
		GOTOS => {
			'int_str' => 139,
			'integer' => 458
		}
	},
	{#State 449
		DEFAULT => -128
	},
	{#State 450
		DEFAULT => -25
	},
	{#State 451
		ACTIONS => {
			"]" => 459
		}
	},
	{#State 452
		DEFAULT => -26
	},
	{#State 453
		ACTIONS => {
			'REGOPT' => 460
		},
		DEFAULT => -273
	},
	{#State 454
		DEFAULT => -243
	},
	{#State 455
		DEFAULT => -244
	},
	{#State 456
		DEFAULT => -101
	},
	{#State 457
		ACTIONS => {
			"]" => 461
		}
	},
	{#State 458
		ACTIONS => {
			")" => 462
		}
	},
	{#State 459
		DEFAULT => -27
	},
	{#State 460
		DEFAULT => -274
	},
	{#State 461
		DEFAULT => -58
	},
	{#State 462
		DEFAULT => -129
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
		 'count_by', 2,
sub
#line 132 "lib/DDC/PP/yyqparser.yp"
{ {Keys=>$_[2]} }
	],
	[#Rule 11
		 'count_by', 4,
sub
#line 133 "lib/DDC/PP/yyqparser.yp"
{ {Keys=>$_[3]} }
	],
	[#Rule 12
		 'count_sample', 2,
sub
#line 137 "lib/DDC/PP/yyqparser.yp"
{ {Sample=>$_[2]} }
	],
	[#Rule 13
		 'count_sample', 4,
sub
#line 138 "lib/DDC/PP/yyqparser.yp"
{ {Sample=>$_[3]} }
	],
	[#Rule 14
		 'count_limit', 2,
sub
#line 143 "lib/DDC/PP/yyqparser.yp"
{ {Limit=>$_[2]} }
	],
	[#Rule 15
		 'count_limit', 4,
sub
#line 144 "lib/DDC/PP/yyqparser.yp"
{ {Limit=>$_[3]} }
	],
	[#Rule 16
		 'count_sort', 2,
sub
#line 148 "lib/DDC/PP/yyqparser.yp"
{ $_[2]->{Sort}=$_[1]; $_[2] }
	],
	[#Rule 17
		 'count_sort_op', 1,
sub
#line 152 "lib/DDC/PP/yyqparser.yp"
{ DDC::PP::LessByCountKey }
	],
	[#Rule 18
		 'count_sort_op', 1,
sub
#line 153 "lib/DDC/PP/yyqparser.yp"
{ DDC::PP::GreaterByCountKey }
	],
	[#Rule 19
		 'count_sort_op', 1,
sub
#line 154 "lib/DDC/PP/yyqparser.yp"
{ DDC::PP::LessByCountValue }
	],
	[#Rule 20
		 'count_sort_op', 1,
sub
#line 155 "lib/DDC/PP/yyqparser.yp"
{ DDC::PP::GreaterByCountValue }
	],
	[#Rule 21
		 'count_sort_minmax', 0,
sub
#line 159 "lib/DDC/PP/yyqparser.yp"
{ {} }
	],
	[#Rule 22
		 'count_sort_minmax', 2,
sub
#line 160 "lib/DDC/PP/yyqparser.yp"
{ {} }
	],
	[#Rule 23
		 'count_sort_minmax', 3,
sub
#line 161 "lib/DDC/PP/yyqparser.yp"
{ {} }
	],
	[#Rule 24
		 'count_sort_minmax', 3,
sub
#line 162 "lib/DDC/PP/yyqparser.yp"
{ {Lo=>$_[2]} }
	],
	[#Rule 25
		 'count_sort_minmax', 4,
sub
#line 163 "lib/DDC/PP/yyqparser.yp"
{ {Lo=>$_[2]} }
	],
	[#Rule 26
		 'count_sort_minmax', 4,
sub
#line 164 "lib/DDC/PP/yyqparser.yp"
{ {Hi=>$_[3]} }
	],
	[#Rule 27
		 'count_sort_minmax', 5,
sub
#line 165 "lib/DDC/PP/yyqparser.yp"
{ {Lo=>$_[2],Hi=>$_[4]} }
	],
	[#Rule 28
		 'query_conditions', 2,
sub
#line 172 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 29
		 'q_filters', 0,
sub
#line 178 "lib/DDC/PP/yyqparser.yp"
{ undef }
	],
	[#Rule 30
		 'q_filters', 2,
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
		 'q_flag', 2,
sub
#line 184 "lib/DDC/PP/yyqparser.yp"
{ undef }
	],
	[#Rule 33
		 'q_flag', 2,
sub
#line 185 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->qopts->{ContextSentencesCount} = $_[2]; undef }
	],
	[#Rule 34
		 'q_flag', 4,
sub
#line 186 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->qopts->{ContextSentencesCount} = $_[3]; undef }
	],
	[#Rule 35
		 'q_flag', 2,
sub
#line 187 "lib/DDC/PP/yyqparser.yp"
{ push(@{$_[0]->qopts->{Within}}, $_[2]); undef }
	],
	[#Rule 36
		 'q_flag', 1,
sub
#line 188 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->qopts->{SeparateHits} = 1; undef }
	],
	[#Rule 37
		 'q_flag', 1,
sub
#line 189 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->qopts->{SeparateHits} = 0; undef }
	],
	[#Rule 38
		 'q_flag', 1,
sub
#line 190 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->qopts->{EnableBibliography} = 0; undef }
	],
	[#Rule 39
		 'q_flag', 2,
sub
#line 191 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->qopts->{EnableBibliography} = 1; undef }
	],
	[#Rule 40
		 'q_flag', 1,
sub
#line 192 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->qopts->{DebugRank} = 1; undef }
	],
	[#Rule 41
		 'q_flag', 2,
sub
#line 193 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->qopts->{DebugRank} = 0; undef }
	],
	[#Rule 42
		 'qf_subcorpora', 0,
sub
#line 198 "lib/DDC/PP/yyqparser.yp"
{ undef }
	],
	[#Rule 43
		 'qf_subcorpora', 1,
sub
#line 199 "lib/DDC/PP/yyqparser.yp"
{ push(@{$_[0]->qopts->{Subcorpora}}, $_[1]); undef }
	],
	[#Rule 44
		 'qf_subcorpora', 3,
sub
#line 200 "lib/DDC/PP/yyqparser.yp"
{ push(@{$_[0]->qopts->{Subcorpora}}, $_[3]); undef }
	],
	[#Rule 45
		 'q_filter', 1,
sub
#line 204 "lib/DDC/PP/yyqparser.yp"
{ $_[1]; }
	],
	[#Rule 46
		 'q_filter', 1,
sub
#line 205 "lib/DDC/PP/yyqparser.yp"
{ $_[1]; }
	],
	[#Rule 47
		 'q_filter', 1,
sub
#line 206 "lib/DDC/PP/yyqparser.yp"
{ $_[1]; }
	],
	[#Rule 48
		 'q_filter', 1,
sub
#line 207 "lib/DDC/PP/yyqparser.yp"
{ $_[1]; }
	],
	[#Rule 49
		 'q_filter', 1,
sub
#line 208 "lib/DDC/PP/yyqparser.yp"
{ $_[1]; }
	],
	[#Rule 50
		 'q_filter', 1,
sub
#line 209 "lib/DDC/PP/yyqparser.yp"
{ $_[1]; }
	],
	[#Rule 51
		 'q_filter', 1,
sub
#line 210 "lib/DDC/PP/yyqparser.yp"
{ $_[1]; }
	],
	[#Rule 52
		 'qf_has_field', 6,
sub
#line 214 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newf('CQFHasFieldValue', $_[3], $_[5]) }
	],
	[#Rule 53
		 'qf_has_field', 6,
sub
#line 215 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newf('CQFHasFieldRegex', $_[3], $_[5]) }
	],
	[#Rule 54
		 'qf_has_field', 6,
sub
#line 216 "lib/DDC/PP/yyqparser.yp"
{ (my $f=$_[0]->newf('CQFHasFieldRegex', $_[3], $_[5]))->Negate(); $f }
	],
	[#Rule 55
		 'qf_has_field', 6,
sub
#line 217 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newf('CQFHasFieldPrefix', $_[3],$_[5]) }
	],
	[#Rule 56
		 'qf_has_field', 6,
sub
#line 218 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newf('CQFHasFieldSuffix', $_[3],$_[5]) }
	],
	[#Rule 57
		 'qf_has_field', 6,
sub
#line 219 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newf('CQFHasFieldInfix', $_[3],$_[5]) }
	],
	[#Rule 58
		 'qf_has_field', 8,
sub
#line 220 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newf('CQFHasFieldSet', $_[3], $_[6]) }
	],
	[#Rule 59
		 'qf_has_field', 2,
sub
#line 221 "lib/DDC/PP/yyqparser.yp"
{ $_[2]->Negate; $_[2] }
	],
	[#Rule 60
		 'qf_rank_sort', 1,
sub
#line 225 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newf('CQFRankSort', DDC::PP::GreaterByRank) }
	],
	[#Rule 61
		 'qf_rank_sort', 1,
sub
#line 226 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newf('CQFRankSort', DDC::PP::LessByRank) }
	],
	[#Rule 62
		 'qf_context_sort', 2,
sub
#line 230 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newCFilter(DDC::PP::LessByLeftContext,      -1, $_[2]) }
	],
	[#Rule 63
		 'qf_context_sort', 2,
sub
#line 231 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newCFilter(DDC::PP::GreaterByLeftContext,   -1, $_[2]) }
	],
	[#Rule 64
		 'qf_context_sort', 2,
sub
#line 232 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newCFilter(DDC::PP::LessByRightContext,      1, $_[2]) }
	],
	[#Rule 65
		 'qf_context_sort', 2,
sub
#line 233 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newCFilter(DDC::PP::GreaterByRightContext,   1, $_[2]) }
	],
	[#Rule 66
		 'qf_context_sort', 2,
sub
#line 234 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newCFilter(DDC::PP::LessByMiddleContext,     0, $_[2]) }
	],
	[#Rule 67
		 'qf_context_sort', 2,
sub
#line 235 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newCFilter(DDC::PP::GreaterByMiddleContext,  0, $_[2]) }
	],
	[#Rule 68
		 'qf_size_sort', 2,
sub
#line 239 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newf('CQFSizeSort', DDC::PP::LessBySize,    @{$_[2]}) }
	],
	[#Rule 69
		 'qf_size_sort', 2,
sub
#line 240 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newf('CQFSizeSort', DDC::PP::GreaterBySize, @{$_[2]}) }
	],
	[#Rule 70
		 'qf_size_sort', 4,
sub
#line 241 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newf('CQFSizeSort', DDC::PP::LessBySize,    $_[3],$_[3]) }
	],
	[#Rule 71
		 'qf_date_sort', 2,
sub
#line 245 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newf('CQFDateSort', DDC::PP::LessByDate,    @{$_[2]}) }
	],
	[#Rule 72
		 'qf_date_sort', 2,
sub
#line 246 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newf('CQFDateSort', DDC::PP::GreaterByDate, @{$_[2]}) }
	],
	[#Rule 73
		 'qf_date_sort', 4,
sub
#line 247 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newf('CQFDateSort', DDC::PP::LessByDate,    $_[3],$_[3]) }
	],
	[#Rule 74
		 'qf_random_sort', 1,
sub
#line 251 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newf('CQFRandomSort') }
	],
	[#Rule 75
		 'qf_random_sort', 3,
sub
#line 252 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newf('CQFRandomSort') }
	],
	[#Rule 76
		 'qf_random_sort', 4,
sub
#line 253 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newf('CQFRandomSort',$_[3]) }
	],
	[#Rule 77
		 'qf_bibl_sort', 5,
sub
#line 257 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newf('CQFDateSort', DDC::PP::LessByDate,    @{$_[4]}) }
	],
	[#Rule 78
		 'qf_bibl_sort', 5,
sub
#line 258 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newf('CQFDateSort', DDC::PP::GreaterByDate, @{$_[4]}) }
	],
	[#Rule 79
		 'qf_bibl_sort', 5,
sub
#line 259 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newf('CQFBiblSort', DDC::PP::LessByFreeBiblField, $_[3], @{$_[4]}) }
	],
	[#Rule 80
		 'qf_bibl_sort', 5,
sub
#line 260 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newf('CQFBiblSort', DDC::PP::LessByFreeBiblField, $_[3], @{$_[4]}) }
	],
	[#Rule 81
		 'qfb_int', 0,
sub
#line 268 "lib/DDC/PP/yyqparser.yp"
{ [] }
	],
	[#Rule 82
		 'qfb_int', 2,
sub
#line 269 "lib/DDC/PP/yyqparser.yp"
{ [] }
	],
	[#Rule 83
		 'qfb_int', 3,
sub
#line 270 "lib/DDC/PP/yyqparser.yp"
{ [] }
	],
	[#Rule 84
		 'qfb_int', 3,
sub
#line 271 "lib/DDC/PP/yyqparser.yp"
{ [$_[2]] }
	],
	[#Rule 85
		 'qfb_int', 4,
sub
#line 272 "lib/DDC/PP/yyqparser.yp"
{ [$_[2]] }
	],
	[#Rule 86
		 'qfb_int', 5,
sub
#line 273 "lib/DDC/PP/yyqparser.yp"
{ [$_[2],$_[4]] }
	],
	[#Rule 87
		 'qfb_int', 4,
sub
#line 274 "lib/DDC/PP/yyqparser.yp"
{ [undef,$_[3]] }
	],
	[#Rule 88
		 'qfb_date', 0,
sub
#line 279 "lib/DDC/PP/yyqparser.yp"
{ [] }
	],
	[#Rule 89
		 'qfb_date', 2,
sub
#line 280 "lib/DDC/PP/yyqparser.yp"
{ [] }
	],
	[#Rule 90
		 'qfb_date', 3,
sub
#line 281 "lib/DDC/PP/yyqparser.yp"
{ [$_[2]] }
	],
	[#Rule 91
		 'qfb_date', 4,
sub
#line 282 "lib/DDC/PP/yyqparser.yp"
{ [$_[2]] }
	],
	[#Rule 92
		 'qfb_date', 5,
sub
#line 283 "lib/DDC/PP/yyqparser.yp"
{ [$_[2],$_[4]] }
	],
	[#Rule 93
		 'qfb_date', 4,
sub
#line 284 "lib/DDC/PP/yyqparser.yp"
{ [undef,$_[3]] }
	],
	[#Rule 94
		 'qfb_bibl', 0,
sub
#line 289 "lib/DDC/PP/yyqparser.yp"
{ [] }
	],
	[#Rule 95
		 'qfb_bibl', 1,
sub
#line 290 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 96
		 'qfb_bibl_ne', 1,
sub
#line 296 "lib/DDC/PP/yyqparser.yp"
{ [] }
	],
	[#Rule 97
		 'qfb_bibl_ne', 2,
sub
#line 297 "lib/DDC/PP/yyqparser.yp"
{ [] }
	],
	[#Rule 98
		 'qfb_bibl_ne', 2,
sub
#line 298 "lib/DDC/PP/yyqparser.yp"
{ [$_[2]] }
	],
	[#Rule 99
		 'qfb_bibl_ne', 3,
sub
#line 299 "lib/DDC/PP/yyqparser.yp"
{ [$_[2]] }
	],
	[#Rule 100
		 'qfb_bibl_ne', 3,
sub
#line 300 "lib/DDC/PP/yyqparser.yp"
{ [undef,$_[3]] }
	],
	[#Rule 101
		 'qfb_bibl_ne', 4,
sub
#line 301 "lib/DDC/PP/yyqparser.yp"
{ [$_[2],$_[4]] }
	],
	[#Rule 102
		 'qfb_ctxsort', 0,
sub
#line 306 "lib/DDC/PP/yyqparser.yp"
{ [] }
	],
	[#Rule 103
		 'qfb_ctxsort', 3,
sub
#line 307 "lib/DDC/PP/yyqparser.yp"
{ $_[2] }
	],
	[#Rule 104
		 'qfb_ctxsort', 4,
sub
#line 308 "lib/DDC/PP/yyqparser.yp"
{ [@{$_[2]}, @{$_[3]}] }
	],
	[#Rule 105
		 'qfb_ctxkey', 3,
sub
#line 313 "lib/DDC/PP/yyqparser.yp"
{ [$_[1],$_[2],$_[3]] }
	],
	[#Rule 106
		 'qfb_ctxkey', 2,
sub
#line 314 "lib/DDC/PP/yyqparser.yp"
{ [undef,$_[1],$_[2]] }
	],
	[#Rule 107
		 'qfbc_matchref', 0,
sub
#line 319 "lib/DDC/PP/yyqparser.yp"
{ 0 }
	],
	[#Rule 108
		 'qfbc_matchref', 1,
sub
#line 320 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 109
		 'qfbc_offset', 0,
sub
#line 325 "lib/DDC/PP/yyqparser.yp"
{  undef }
	],
	[#Rule 110
		 'qfbc_offset', 1,
sub
#line 326 "lib/DDC/PP/yyqparser.yp"
{  $_[1] }
	],
	[#Rule 111
		 'qfbc_offset', 2,
sub
#line 327 "lib/DDC/PP/yyqparser.yp"
{  $_[2] }
	],
	[#Rule 112
		 'qfbc_offset', 2,
sub
#line 328 "lib/DDC/PP/yyqparser.yp"
{ -$_[2] }
	],
	[#Rule 113
		 'q_clause', 1,
sub
#line 336 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 114
		 'q_clause', 1,
sub
#line 337 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 115
		 'q_clause', 1,
sub
#line 338 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 116
		 'q_clause', 1,
sub
#line 339 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 117
		 'qc_matchid', 2,
sub
#line 343 "lib/DDC/PP/yyqparser.yp"
{ $_[1]->SetMatchId($_[2]); $_[1] }
	],
	[#Rule 118
		 'qc_matchid', 3,
sub
#line 344 "lib/DDC/PP/yyqparser.yp"
{ $_[2] }
	],
	[#Rule 119
		 'qc_boolean', 3,
sub
#line 351 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQAnd', $_[1],$_[3]) }
	],
	[#Rule 120
		 'qc_boolean', 3,
sub
#line 352 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQOr', $_[1],$_[3]) }
	],
	[#Rule 121
		 'qc_boolean', 2,
sub
#line 353 "lib/DDC/PP/yyqparser.yp"
{ $_[2]->Negate; $_[2] }
	],
	[#Rule 122
		 'qc_boolean', 3,
sub
#line 354 "lib/DDC/PP/yyqparser.yp"
{ $_[2] }
	],
	[#Rule 123
		 'qc_concat', 2,
sub
#line 360 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQAnd', $_[1],$_[2]) }
	],
	[#Rule 124
		 'qc_concat', 2,
sub
#line 361 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQAnd', $_[1],$_[2]) }
	],
	[#Rule 125
		 'qc_concat', 3,
sub
#line 362 "lib/DDC/PP/yyqparser.yp"
{ $_[2] }
	],
	[#Rule 126
		 'qc_basic', 1,
sub
#line 370 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 127
		 'qc_basic', 1,
sub
#line 371 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 128
		 'qc_near', 8,
sub
#line 375 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQNear', $_[7],$_[3],$_[5]) }
	],
	[#Rule 129
		 'qc_near', 10,
sub
#line 376 "lib/DDC/PP/yyqparser.yp"
{  $_[0]->newq('CQNear', $_[9],$_[3],$_[5],$_[7]) }
	],
	[#Rule 130
		 'qc_near', 2,
sub
#line 377 "lib/DDC/PP/yyqparser.yp"
{ $_[1]->SetMatchId($_[2]); $_[1] }
	],
	[#Rule 131
		 'qc_near', 3,
sub
#line 378 "lib/DDC/PP/yyqparser.yp"
{ $_[2] }
	],
	[#Rule 132
		 'qc_tokens', 1,
sub
#line 386 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 133
		 'qc_tokens', 1,
sub
#line 387 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 134
		 'qc_tokens', 2,
sub
#line 388 "lib/DDC/PP/yyqparser.yp"
{ $_[1]->SetMatchId($_[2]); $_[1] }
	],
	[#Rule 135
		 'qc_phrase', 3,
sub
#line 392 "lib/DDC/PP/yyqparser.yp"
{ $_[2] }
	],
	[#Rule 136
		 'qc_phrase', 3,
sub
#line 393 "lib/DDC/PP/yyqparser.yp"
{ $_[2] }
	],
	[#Rule 137
		 'qc_word', 1,
sub
#line 401 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 138
		 'qc_word', 1,
sub
#line 402 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 139
		 'qc_word', 1,
sub
#line 403 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 140
		 'qc_word', 1,
sub
#line 404 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 141
		 'qc_word', 1,
sub
#line 405 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 142
		 'qc_word', 1,
sub
#line 406 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 143
		 'qc_word', 1,
sub
#line 407 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 144
		 'qc_word', 1,
sub
#line 408 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 145
		 'qc_word', 1,
sub
#line 409 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 146
		 'qc_word', 1,
sub
#line 410 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 147
		 'qc_word', 1,
sub
#line 411 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 148
		 'qc_word', 1,
sub
#line 412 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 149
		 'qc_word', 1,
sub
#line 413 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 150
		 'qc_word', 1,
sub
#line 414 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 151
		 'qc_word', 1,
sub
#line 415 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 152
		 'qc_word', 1,
sub
#line 416 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 153
		 'qc_word', 1,
sub
#line 417 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 154
		 'qc_word', 1,
sub
#line 418 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 155
		 'qc_word', 1,
sub
#line 419 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 156
		 'qc_word', 1,
sub
#line 420 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 157
		 'qc_word', 1,
sub
#line 421 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 158
		 'qc_word', 1,
sub
#line 422 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 159
		 'qc_word', 1,
sub
#line 423 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 160
		 'qc_word', 3,
sub
#line 424 "lib/DDC/PP/yyqparser.yp"
{ $_[2] }
	],
	[#Rule 161
		 'qw_bareword', 2,
sub
#line 428 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokInfl', "", $_[1], $_[2]) }
	],
	[#Rule 162
		 'qw_bareword', 4,
sub
#line 429 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokInfl', $_[1], $_[3], $_[4]) }
	],
	[#Rule 163
		 'qw_exact', 2,
sub
#line 433 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokExact', "", $_[2]) }
	],
	[#Rule 164
		 'qw_exact', 4,
sub
#line 434 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokExact', $_[1], $_[4]) }
	],
	[#Rule 165
		 'qw_regex', 1,
sub
#line 438 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokRegex', "",   $_[1]) }
	],
	[#Rule 166
		 'qw_regex', 3,
sub
#line 439 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokRegex', $_[1],$_[3]) }
	],
	[#Rule 167
		 'qw_regex', 1,
sub
#line 440 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokRegex', "",    $_[1], 1) }
	],
	[#Rule 168
		 'qw_regex', 3,
sub
#line 441 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokRegex', $_[1], $_[3], 1) }
	],
	[#Rule 169
		 'qw_any', 1,
sub
#line 445 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokAny') }
	],
	[#Rule 170
		 'qw_any', 3,
sub
#line 446 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokAny',$_[1]) }
	],
	[#Rule 171
		 'qw_set_exact', 3,
sub
#line 450 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokSet', "",    undef, $_[2]) }
	],
	[#Rule 172
		 'qw_set_exact', 5,
sub
#line 451 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokSet', $_[1], undef, $_[2]) }
	],
	[#Rule 173
		 'qw_set_infl', 4,
sub
#line 455 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokSetInfl', "",    $_[2], $_[4]) }
	],
	[#Rule 174
		 'qw_set_infl', 6,
sub
#line 456 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokSetInfl', $_[1], $_[4], $_[6]) }
	],
	[#Rule 175
		 'qw_prefix', 1,
sub
#line 460 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokPrefix', "",    $_[1]) }
	],
	[#Rule 176
		 'qw_prefix', 3,
sub
#line 461 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokPrefix', $_[1], $_[3]) }
	],
	[#Rule 177
		 'qw_suffix', 1,
sub
#line 465 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokSuffix', "",    $_[1]) }
	],
	[#Rule 178
		 'qw_suffix', 3,
sub
#line 466 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokSuffix', $_[1], $_[3]) }
	],
	[#Rule 179
		 'qw_infix', 1,
sub
#line 470 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokInfix', "",    $_[1]) }
	],
	[#Rule 180
		 'qw_infix', 3,
sub
#line 471 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokInfix', $_[1], $_[3]) }
	],
	[#Rule 181
		 'qw_infix_set', 3,
sub
#line 475 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokInfixSet', "", $_[2]) }
	],
	[#Rule 182
		 'qw_infix_set', 5,
sub
#line 476 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokInfixSet', $_[1], $_[4]) }
	],
	[#Rule 183
		 'qw_prefix_set', 3,
sub
#line 480 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokPrefixSet',"", $_[2]) }
	],
	[#Rule 184
		 'qw_prefix_set', 5,
sub
#line 481 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokPrefixSet',$_[1], $_[4]) }
	],
	[#Rule 185
		 'qw_suffix_set', 3,
sub
#line 485 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokSuffixSet',"", $_[2]) }
	],
	[#Rule 186
		 'qw_suffix_set', 5,
sub
#line 486 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokSuffixSet',$_[1], $_[4]) }
	],
	[#Rule 187
		 'qw_thesaurus', 3,
sub
#line 490 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokThes', "Thes",$_[2]) }
	],
	[#Rule 188
		 'qw_thesaurus', 6,
sub
#line 491 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokThes', $_[1], $_[5]) }
	],
	[#Rule 189
		 'qw_morph', 3,
sub
#line 495 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokMorph', "MorphPattern", $_[2]) }
	],
	[#Rule 190
		 'qw_morph', 5,
sub
#line 496 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokMorph', $_[1], $_[4]) }
	],
	[#Rule 191
		 'qw_lemma', 2,
sub
#line 500 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokLemma', "Lemma", $_[2]) }
	],
	[#Rule 192
		 'qw_lemma', 4,
sub
#line 501 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokLemma', $_[1], $_[4]) }
	],
	[#Rule 193
		 'qw_chunk', 2,
sub
#line 505 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokChunk', "", $_[2]) }
	],
	[#Rule 194
		 'qw_chunk', 4,
sub
#line 506 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokChunk', $_[1], $_[4]) }
	],
	[#Rule 195
		 'qw_anchor', 3,
sub
#line 510 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokAnchor', "",    $_[3]) }
	],
	[#Rule 196
		 'qw_anchor', 4,
sub
#line 511 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokAnchor', $_[2], $_[4]) }
	],
	[#Rule 197
		 'qw_listfile', 2,
sub
#line 515 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokFile', "",    $_[2]) }
	],
	[#Rule 198
		 'qw_listfile', 4,
sub
#line 516 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokFile', $_[1], $_[4]) }
	],
	[#Rule 199
		 'qw_with', 3,
sub
#line 520 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQWith', $_[1],$_[3]) }
	],
	[#Rule 200
		 'qw_without', 3,
sub
#line 524 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQWithout', $_[1],$_[3]) }
	],
	[#Rule 201
		 'qw_withor', 3,
sub
#line 528 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQWithor', $_[1],$_[3]) }
	],
	[#Rule 202
		 'qw_keys', 4,
sub
#line 532 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newKeysQuery($_[3][0], $_[3][1]); }
	],
	[#Rule 203
		 'qw_keys', 6,
sub
#line 533 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newKeysQuery($_[5][0], $_[5][1], $_[1]); }
	],
	[#Rule 204
		 'qwk_indextuple', 4,
sub
#line 537 "lib/DDC/PP/yyqparser.yp"
{ $_[3] }
	],
	[#Rule 205
		 'qwk_countsrc', 1,
sub
#line 542 "lib/DDC/PP/yyqparser.yp"
{ [$_[1], {}] }
	],
	[#Rule 206
		 'qwk_countsrc', 2,
sub
#line 543 "lib/DDC/PP/yyqparser.yp"
{ [$_[0]->newCountQuery($_[1], $_[2]), $_[2]] }
	],
	[#Rule 207
		 'qw_matchid', 2,
sub
#line 547 "lib/DDC/PP/yyqparser.yp"
{ $_[1]->SetMatchId($_[2]); $_[1] }
	],
	[#Rule 208
		 'l_set', 0,
sub
#line 555 "lib/DDC/PP/yyqparser.yp"
{ [] }
	],
	[#Rule 209
		 'l_set', 2,
sub
#line 556 "lib/DDC/PP/yyqparser.yp"
{ push(@{$_[1]}, $_[2]); $_[1] }
	],
	[#Rule 210
		 'l_set', 2,
sub
#line 557 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 211
		 'l_morph', 0,
sub
#line 562 "lib/DDC/PP/yyqparser.yp"
{ [] }
	],
	[#Rule 212
		 'l_morph', 2,
sub
#line 563 "lib/DDC/PP/yyqparser.yp"
{ push(@{$_[1]}, $_[2]); $_[1] }
	],
	[#Rule 213
		 'l_morph', 2,
sub
#line 564 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 214
		 'l_morph', 2,
sub
#line 565 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 215
		 'l_phrase', 1,
sub
#line 569 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQSeq', [$_[1]]) }
	],
	[#Rule 216
		 'l_phrase', 2,
sub
#line 570 "lib/DDC/PP/yyqparser.yp"
{ $_[1]->Append($_[2]); $_[1] }
	],
	[#Rule 217
		 'l_phrase', 4,
sub
#line 571 "lib/DDC/PP/yyqparser.yp"
{ $_[1]->Append($_[4], $_[3]); $_[1] }
	],
	[#Rule 218
		 'l_phrase', 4,
sub
#line 572 "lib/DDC/PP/yyqparser.yp"
{ $_[1]->Append($_[4], $_[3], '<'); $_[1] }
	],
	[#Rule 219
		 'l_phrase', 4,
sub
#line 573 "lib/DDC/PP/yyqparser.yp"
{ $_[1]->Append($_[4], $_[3], '>'); $_[1] }
	],
	[#Rule 220
		 'l_phrase', 4,
sub
#line 574 "lib/DDC/PP/yyqparser.yp"
{ $_[1]->Append($_[4], $_[3], '='); $_[1] }
	],
	[#Rule 221
		 'l_txchain', 0,
sub
#line 578 "lib/DDC/PP/yyqparser.yp"
{ []; }
	],
	[#Rule 222
		 'l_txchain', 2,
sub
#line 579 "lib/DDC/PP/yyqparser.yp"
{ push(@{$_[1]}, $_[2]); $_[1] }
	],
	[#Rule 223
		 'l_countkeys', 0,
sub
#line 584 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQCountKeyExprList') }
	],
	[#Rule 224
		 'l_countkeys', 1,
sub
#line 585 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQCountKeyExprList', Exprs=>[$_[1]]) }
	],
	[#Rule 225
		 'l_countkeys', 3,
sub
#line 586 "lib/DDC/PP/yyqparser.yp"
{ $_[1]->PushKey($_[3]); $_[1] }
	],
	[#Rule 226
		 'l_indextuple', 0,
sub
#line 590 "lib/DDC/PP/yyqparser.yp"
{ [] }
	],
	[#Rule 227
		 'l_indextuple', 1,
sub
#line 591 "lib/DDC/PP/yyqparser.yp"
{ [$_[1]] }
	],
	[#Rule 228
		 'l_indextuple', 3,
sub
#line 592 "lib/DDC/PP/yyqparser.yp"
{ push(@{$_[1]},$_[3]); $_[1] }
	],
	[#Rule 229
		 'count_key', 1,
sub
#line 599 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQCountKeyExprConstant', "*") }
	],
	[#Rule 230
		 'count_key', 2,
sub
#line 600 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQCountKeyExprConstant', $_[2]) }
	],
	[#Rule 231
		 'count_key', 1,
sub
#line 601 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQCountKeyExprFileId', $_[1]) }
	],
	[#Rule 232
		 'count_key', 1,
sub
#line 602 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQCountKeyExprFileName', $_[1]) }
	],
	[#Rule 233
		 'count_key', 1,
sub
#line 603 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQCountKeyExprDate', $_[1]) }
	],
	[#Rule 234
		 'count_key', 3,
sub
#line 604 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQCountKeyExprDateSlice', $_[1],$_[3]) }
	],
	[#Rule 235
		 'count_key', 1,
sub
#line 605 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQCountKeyExprBibl', $_[1]) }
	],
	[#Rule 236
		 'count_key', 3,
sub
#line 606 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQCountKeyExprToken', $_[1],$_[2],$_[3]) }
	],
	[#Rule 237
		 'count_key', 3,
sub
#line 607 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQCountKeyExprRegex', $_[1],@{$_[3]}) }
	],
	[#Rule 238
		 'count_key', 3,
sub
#line 608 "lib/DDC/PP/yyqparser.yp"
{ $_[2]; }
	],
	[#Rule 239
		 'ck_matchid', 0,
sub
#line 612 "lib/DDC/PP/yyqparser.yp"
{     0 }
	],
	[#Rule 240
		 'ck_matchid', 1,
sub
#line 613 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 241
		 'ck_offset', 0,
sub
#line 617 "lib/DDC/PP/yyqparser.yp"
{      0 }
	],
	[#Rule 242
		 'ck_offset', 1,
sub
#line 618 "lib/DDC/PP/yyqparser.yp"
{  $_[1] }
	],
	[#Rule 243
		 'ck_offset', 2,
sub
#line 619 "lib/DDC/PP/yyqparser.yp"
{  $_[2] }
	],
	[#Rule 244
		 'ck_offset', 2,
sub
#line 620 "lib/DDC/PP/yyqparser.yp"
{ -$_[2] }
	],
	[#Rule 245
		 's_index', 1,
sub
#line 628 "lib/DDC/PP/yyqparser.yp"
{ '' }
	],
	[#Rule 246
		 's_index', 1,
sub
#line 629 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 247
		 's_indextuple_item', 1,
sub
#line 633 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 248
		 's_indextuple_item', 1,
sub
#line 634 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 249
		 's_word', 1,
sub
#line 637 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 250
		 's_semclass', 1,
sub
#line 638 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 251
		 's_lemma', 1,
sub
#line 639 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 252
		 's_chunk', 1,
sub
#line 640 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 253
		 's_filename', 1,
sub
#line 641 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 254
		 's_morphitem', 1,
sub
#line 642 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 255
		 's_subcorpus', 1,
sub
#line 643 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 256
		 's_biblname', 1,
sub
#line 644 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 257
		 's_breakname', 1,
sub
#line 646 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 258
		 's_breakname', 1,
sub
#line 647 "lib/DDC/PP/yyqparser.yp"
{ "file" }
	],
	[#Rule 259
		 'symbol', 1,
sub
#line 655 "lib/DDC/PP/yyqparser.yp"
{ unescape($_[1]) }
	],
	[#Rule 260
		 'symbol', 1,
sub
#line 656 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 261
		 'symbol', 1,
sub
#line 657 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 262
		 'index', 1,
sub
#line 661 "lib/DDC/PP/yyqparser.yp"
{ '' }
	],
	[#Rule 263
		 'index', 1,
sub
#line 662 "lib/DDC/PP/yyqparser.yp"
{ unescape($_[1]) }
	],
	[#Rule 264
		 'sym_str', 1,
sub
#line 665 "lib/DDC/PP/yyqparser.yp"
{ unescape($_[1]) }
	],
	[#Rule 265
		 's_prefix', 1,
sub
#line 667 "lib/DDC/PP/yyqparser.yp"
{ unescape($_[1]) }
	],
	[#Rule 266
		 's_suffix', 1,
sub
#line 668 "lib/DDC/PP/yyqparser.yp"
{ unescape($_[1]) }
	],
	[#Rule 267
		 's_infix', 1,
sub
#line 669 "lib/DDC/PP/yyqparser.yp"
{ unescape($_[1]) }
	],
	[#Rule 268
		 's_expander', 1,
sub
#line 671 "lib/DDC/PP/yyqparser.yp"
{ unescape($_[1]) }
	],
	[#Rule 269
		 'regex', 1,
sub
#line 674 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newre($_[1]) }
	],
	[#Rule 270
		 'regex', 2,
sub
#line 675 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newre($_[1],$_[2]) }
	],
	[#Rule 271
		 'neg_regex', 1,
sub
#line 679 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newre($_[1]) }
	],
	[#Rule 272
		 'neg_regex', 2,
sub
#line 680 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newre($_[1],$_[2]) }
	],
	[#Rule 273
		 'replace_regex', 2,
sub
#line 684 "lib/DDC/PP/yyqparser.yp"
{ [$_[1],$_[2],''] }
	],
	[#Rule 274
		 'replace_regex', 3,
sub
#line 685 "lib/DDC/PP/yyqparser.yp"
{ [$_[1],$_[2],$_[3]] }
	],
	[#Rule 275
		 'int_str', 1,
sub
#line 688 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 276
		 'integer', 1,
sub
#line 690 "lib/DDC/PP/yyqparser.yp"
{ no warnings 'numeric'; ($_[1]+0) }
	],
	[#Rule 277
		 'date', 1,
sub
#line 693 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 278
		 'date', 1,
sub
#line 694 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 279
		 'matchid', 2,
sub
#line 697 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->yybegin('INITIAL'); $_[2] }
	],
	[#Rule 280
		 'matchid_eq', 1,
sub
#line 699 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->yybegin('Q_MATCHID'); $_[1] }
	]
],
                                  @_);
    bless($self,$class);
}

#line 701 "lib/DDC/PP/yyqparser.yp"

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
  print STDERR "newCFilter: ", Data::Dumper->Dump([@_[1..$#_]]), "\n";
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
