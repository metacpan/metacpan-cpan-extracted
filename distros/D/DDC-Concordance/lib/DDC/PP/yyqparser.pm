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
			"!" => 63,
			"^" => 65,
			'COUNT' => 66,
			'SYMBOL' => 1,
			'INFIX' => 23,
			'REGEX' => 2,
			'SUFFIX' => 3,
			"\$" => 26,
			'COLON_LBRACE' => 38,
			'DOLLAR_DOT' => 49,
			'INDEX' => 29,
			"\"" => 48,
			"{" => 47,
			'NEAR' => 54,
			'PREFIX' => 55,
			"[" => 70,
			'KEYS' => 8,
			"<" => 52,
			'INTEGER' => 21,
			'DATE' => 57,
			"%" => 58,
			'NEG_REGEX' => 61,
			"\@" => 37,
			"*" => 17,
			'AT_LBRACE' => 71,
			"(" => 35,
			'STAR_LBRACE' => 36
		},
		GOTOS => {
			'qw_chunk' => 5,
			'qw_prefix_set' => 4,
			'qw_anchor' => 40,
			's_infix' => 6,
			's_index' => 39,
			'qw_lemma' => 42,
			'qw_set_exact' => 43,
			'qw_exact' => 41,
			'qw_matchid' => 45,
			'qw_suffix_set' => 46,
			'symbol' => 44,
			'qw_thesaurus' => 7,
			'qw_prefix' => 50,
			'qwk_indextuple' => 9,
			'qc_tokens' => 51,
			'qc_matchid' => 14,
			's_word' => 11,
			'query' => 10,
			'query_conditions' => 13,
			'qw_withor' => 12,
			'qw_infix' => 53,
			'qc_concat' => 15,
			'qc_basic' => 18,
			'qw_with' => 16,
			'qc_near' => 19,
			'qw_any' => 20,
			'count_query' => 59,
			's_prefix' => 56,
			'qw_bareword' => 22,
			'qw_keys' => 62,
			'qw_regex' => 60,
			'index' => 24,
			'q_clause' => 25,
			'qc_phrase' => 27,
			'qc_boolean' => 64,
			'regex' => 28,
			's_suffix' => 67,
			'neg_regex' => 68,
			'qw_suffix' => 69,
			'qw_without' => 30,
			'qw_listfile' => 32,
			'qw_morph' => 31,
			'qc_word' => 33,
			'qw_set_infl' => 34,
			'qw_infix_set' => 72
		}
	},
	{#State 1
		DEFAULT => -259
	},
	{#State 2
		ACTIONS => {
			'REGOPT' => 73
		},
		DEFAULT => -269
	},
	{#State 3
		DEFAULT => -266
	},
	{#State 4
		DEFAULT => -146
	},
	{#State 5
		DEFAULT => -152
	},
	{#State 6
		DEFAULT => -179
	},
	{#State 7
		DEFAULT => -149
	},
	{#State 8
		ACTIONS => {
			"(" => 74
		}
	},
	{#State 9
		ACTIONS => {
			"=" => 75
		}
	},
	{#State 10
		ACTIONS => {
			'' => 76
		}
	},
	{#State 11
		DEFAULT => -221,
		GOTOS => {
			'l_txchain' => 77
		}
	},
	{#State 12
		DEFAULT => -157
	},
	{#State 13
		DEFAULT => -1
	},
	{#State 14
		DEFAULT => -116
	},
	{#State 15
		ACTIONS => {
			'KEYS' => 8,
			"*" => 17,
			'INTEGER' => 21,
			'SUFFIX' => 3,
			'REGEX' => 2,
			'SYMBOL' => 1,
			'STAR_LBRACE' => 36,
			"(" => 78,
			"\@" => 37,
			"\$" => 26,
			'INFIX' => 23,
			'INDEX' => 29,
			"<" => 52,
			'PREFIX' => 55,
			'NEAR' => 54,
			'NEG_REGEX' => 61,
			'DATE' => 57,
			"%" => 58,
			'COLON_LBRACE' => 38,
			"{" => 47,
			"\"" => 48,
			'DOLLAR_DOT' => 49,
			"[" => 70,
			'AT_LBRACE' => 71,
			"^" => 65
		},
		DEFAULT => -115,
		GOTOS => {
			's_prefix' => 56,
			'qw_keys' => 62,
			'qw_bareword' => 22,
			'qw_regex' => 60,
			'qc_basic' => 79,
			'qw_with' => 16,
			'qc_near' => 19,
			'qw_any' => 20,
			'qw_infix' => 53,
			'qwk_indextuple' => 9,
			'qc_tokens' => 51,
			's_word' => 11,
			'qw_withor' => 12,
			'qw_prefix' => 50,
			'symbol' => 44,
			'qw_suffix_set' => 46,
			'qw_matchid' => 45,
			'qw_thesaurus' => 7,
			'qw_anchor' => 40,
			's_index' => 39,
			's_infix' => 6,
			'qw_set_exact' => 43,
			'qw_exact' => 41,
			'qw_lemma' => 42,
			'qw_prefix_set' => 4,
			'qw_chunk' => 5,
			'qw_infix_set' => 72,
			'qw_set_infl' => 34,
			'qw_listfile' => 32,
			'qw_morph' => 31,
			'qc_word' => 33,
			'qw_suffix' => 69,
			'qw_without' => 30,
			'neg_regex' => 68,
			's_suffix' => 67,
			'regex' => 28,
			'qc_phrase' => 27,
			'index' => 24
		}
	},
	{#State 16
		DEFAULT => -155
	},
	{#State 17
		DEFAULT => -169
	},
	{#State 18
		ACTIONS => {
			"*" => 17,
			'INTEGER' => 21,
			'KEYS' => 8,
			'SUFFIX' => 3,
			'REGEX' => 2,
			'SYMBOL' => 1,
			'STAR_LBRACE' => 36,
			"(" => 78,
			"\@" => 37,
			'INDEX' => 29,
			"\$" => 26,
			'INFIX' => 23,
			'NEG_REGEX' => 61,
			'DATE' => 57,
			"%" => 58,
			"<" => 52,
			'NEAR' => 54,
			'PREFIX' => 55,
			"{" => 47,
			"\"" => 48,
			'DOLLAR_DOT' => 49,
			'COLON_LBRACE' => 38,
			'AT_LBRACE' => 71,
			"[" => 70,
			"^" => 65
		},
		DEFAULT => -113,
		GOTOS => {
			'qc_word' => 33,
			'qw_morph' => 31,
			'qw_listfile' => 32,
			'qw_suffix' => 69,
			'qw_without' => 30,
			'neg_regex' => 68,
			'qw_infix_set' => 72,
			'qw_set_infl' => 34,
			'qc_phrase' => 27,
			'index' => 24,
			's_suffix' => 67,
			'regex' => 28,
			'qw_infix' => 53,
			's_word' => 11,
			'qw_withor' => 12,
			'qc_tokens' => 51,
			'qwk_indextuple' => 9,
			'qw_regex' => 60,
			'qw_bareword' => 22,
			'qw_keys' => 62,
			's_prefix' => 56,
			'qw_any' => 20,
			'qc_basic' => 80,
			'qw_with' => 16,
			'qc_near' => 19,
			'qw_set_exact' => 43,
			'qw_exact' => 41,
			'qw_lemma' => 42,
			's_infix' => 6,
			's_index' => 39,
			'qw_anchor' => 40,
			'qw_prefix_set' => 4,
			'qw_chunk' => 5,
			'qw_prefix' => 50,
			'qw_thesaurus' => 7,
			'qw_suffix_set' => 46,
			'qw_matchid' => 45,
			'symbol' => 44
		}
	},
	{#State 19
		ACTIONS => {
			"=" => 82
		},
		DEFAULT => -127,
		GOTOS => {
			'matchid_eq' => 83,
			'matchid' => 81
		}
	},
	{#State 20
		DEFAULT => -140
	},
	{#State 21
		DEFAULT => -260
	},
	{#State 22
		DEFAULT => -137
	},
	{#State 23
		DEFAULT => -267
	},
	{#State 24
		DEFAULT => -246
	},
	{#State 25
		ACTIONS => {
			"=" => 82,
			'OP_BOOL_AND' => 86,
			'OP_BOOL_OR' => 84
		},
		DEFAULT => -29,
		GOTOS => {
			'matchid' => 87,
			'q_filters' => 85,
			'matchid_eq' => 83
		}
	},
	{#State 26
		ACTIONS => {
			"(" => 88
		},
		DEFAULT => -245
	},
	{#State 27
		DEFAULT => -133
	},
	{#State 28
		DEFAULT => -165
	},
	{#State 29
		DEFAULT => -263
	},
	{#State 30
		DEFAULT => -156
	},
	{#State 31
		DEFAULT => -150
	},
	{#State 32
		DEFAULT => -154
	},
	{#State 33
		ACTIONS => {
			'WITHOR' => 89,
			"=" => 82,
			'WITHOUT' => 92,
			'WITH' => 91
		},
		DEFAULT => -132,
		GOTOS => {
			'matchid_eq' => 83,
			'matchid' => 90
		}
	},
	{#State 34
		DEFAULT => -141
	},
	{#State 35
		ACTIONS => {
			'STAR_LBRACE' => 36,
			'AT_LBRACE' => 71,
			"(" => 35,
			"*" => 17,
			"\@" => 37,
			'NEG_REGEX' => 61,
			"%" => 58,
			'DATE' => 57,
			'INTEGER' => 21,
			'KEYS' => 8,
			"<" => 52,
			"[" => 70,
			'PREFIX' => 55,
			'NEAR' => 54,
			"{" => 47,
			"\"" => 48,
			'INDEX' => 29,
			'DOLLAR_DOT' => 49,
			'COLON_LBRACE' => 38,
			"\$" => 26,
			'SUFFIX' => 3,
			'REGEX' => 2,
			'INFIX' => 23,
			'SYMBOL' => 1,
			"^" => 65,
			"!" => 63
		},
		GOTOS => {
			'q_clause' => 95,
			'index' => 24,
			'qc_boolean' => 99,
			'qc_phrase' => 94,
			'regex' => 28,
			's_suffix' => 67,
			'neg_regex' => 68,
			'qw_without' => 30,
			'qw_suffix' => 69,
			'qc_word' => 93,
			'qw_listfile' => 32,
			'qw_morph' => 31,
			'qw_set_infl' => 34,
			'qw_infix_set' => 72,
			'qw_chunk' => 5,
			'qw_prefix_set' => 4,
			'qw_set_exact' => 43,
			'qw_lemma' => 42,
			'qw_exact' => 41,
			'qw_anchor' => 40,
			's_index' => 39,
			's_infix' => 6,
			'qw_matchid' => 45,
			'qw_suffix_set' => 46,
			'symbol' => 44,
			'qw_thesaurus' => 7,
			'qw_prefix' => 50,
			'qc_matchid' => 98,
			's_word' => 11,
			'qw_withor' => 12,
			'qwk_indextuple' => 9,
			'qc_tokens' => 51,
			'qc_concat' => 97,
			'qw_infix' => 53,
			'qw_any' => 20,
			'qc_basic' => 18,
			'qw_with' => 16,
			'qc_near' => 96,
			'qw_keys' => 62,
			'qw_bareword' => 22,
			'qw_regex' => 60,
			's_prefix' => 56
		}
	},
	{#State 36
		DEFAULT => -208,
		GOTOS => {
			'l_set' => 100
		}
	},
	{#State 37
		ACTIONS => {
			'DATE' => 57,
			'INTEGER' => 21,
			'SYMBOL' => 1
		},
		GOTOS => {
			's_word' => 101,
			'symbol' => 44
		}
	},
	{#State 38
		ACTIONS => {
			'INTEGER' => 21,
			'DATE' => 57,
			'SYMBOL' => 1
		},
		GOTOS => {
			's_semclass' => 103,
			'symbol' => 102
		}
	},
	{#State 39
		ACTIONS => {
			"=" => 104
		}
	},
	{#State 40
		DEFAULT => -153
	},
	{#State 41
		DEFAULT => -138
	},
	{#State 42
		DEFAULT => -151
	},
	{#State 43
		DEFAULT => -142
	},
	{#State 44
		DEFAULT => -249
	},
	{#State 45
		DEFAULT => -159
	},
	{#State 46
		DEFAULT => -148
	},
	{#State 47
		DEFAULT => -208,
		GOTOS => {
			'l_set' => 105
		}
	},
	{#State 48
		ACTIONS => {
			'REGEX' => 2,
			'SYMBOL' => 1,
			'INFIX' => 23,
			"\$" => 26,
			'COLON_LBRACE' => 38,
			'SUFFIX' => 3,
			"^" => 65,
			"{" => 47,
			'INDEX' => 29,
			'DOLLAR_DOT' => 49,
			'KEYS' => 8,
			"<" => 52,
			'PREFIX' => 55,
			"[" => 70,
			"*" => 17,
			'STAR_LBRACE' => 36,
			'AT_LBRACE' => 71,
			"(" => 107,
			"%" => 58,
			'DATE' => 57,
			'INTEGER' => 21,
			"\@" => 37,
			'NEG_REGEX' => 61
		},
		GOTOS => {
			'qw_lemma' => 42,
			'qw_set_exact' => 43,
			'qw_exact' => 41,
			's_infix' => 6,
			's_index' => 39,
			'qw_anchor' => 40,
			'qw_prefix_set' => 4,
			'qw_chunk' => 5,
			'qw_prefix' => 50,
			'qw_thesaurus' => 7,
			'qw_suffix_set' => 46,
			'qw_matchid' => 45,
			'symbol' => 44,
			'qw_infix' => 53,
			'qw_withor' => 12,
			's_word' => 11,
			'qwk_indextuple' => 9,
			'qw_regex' => 60,
			'qw_keys' => 62,
			'qw_bareword' => 22,
			's_prefix' => 56,
			'qw_any' => 20,
			'qw_with' => 16,
			'l_phrase' => 108,
			'index' => 24,
			's_suffix' => 67,
			'regex' => 28,
			'qc_word' => 106,
			'qw_morph' => 31,
			'qw_listfile' => 32,
			'qw_without' => 30,
			'neg_regex' => 68,
			'qw_suffix' => 69,
			'qw_infix_set' => 72,
			'qw_set_infl' => 34
		}
	},
	{#State 49
		ACTIONS => {
			"=" => 109,
			'SYMBOL' => 1,
			'INTEGER' => 21,
			'DATE' => 57
		},
		GOTOS => {
			'symbol' => 110
		}
	},
	{#State 50
		DEFAULT => -145
	},
	{#State 51
		ACTIONS => {
			"=" => 82
		},
		DEFAULT => -126,
		GOTOS => {
			'matchid' => 111,
			'matchid_eq' => 83
		}
	},
	{#State 52
		ACTIONS => {
			'DATE' => 57,
			'INTEGER' => 21,
			'SYMBOL' => 1
		},
		GOTOS => {
			'symbol' => 112,
			's_filename' => 113
		}
	},
	{#State 53
		DEFAULT => -143
	},
	{#State 54
		ACTIONS => {
			"(" => 114
		}
	},
	{#State 55
		DEFAULT => -265
	},
	{#State 56
		DEFAULT => -175
	},
	{#State 57
		DEFAULT => -261
	},
	{#State 58
		ACTIONS => {
			'SYMBOL' => 1,
			'INTEGER' => 21,
			'DATE' => 57
		},
		GOTOS => {
			'symbol' => 116,
			's_lemma' => 115
		}
	},
	{#State 59
		DEFAULT => -2
	},
	{#State 60
		DEFAULT => -139
	},
	{#State 61
		ACTIONS => {
			'REGOPT' => 117
		},
		DEFAULT => -271
	},
	{#State 62
		DEFAULT => -158
	},
	{#State 63
		ACTIONS => {
			"\@" => 37,
			'NEG_REGEX' => 61,
			'INTEGER' => 21,
			'DATE' => 57,
			"%" => 58,
			"(" => 35,
			'AT_LBRACE' => 71,
			'STAR_LBRACE' => 36,
			"*" => 17,
			"[" => 70,
			'NEAR' => 54,
			'PREFIX' => 55,
			'KEYS' => 8,
			"<" => 52,
			'DOLLAR_DOT' => 49,
			'INDEX' => 29,
			"\"" => 48,
			"{" => 47,
			"^" => 65,
			"!" => 63,
			'SUFFIX' => 3,
			'COLON_LBRACE' => 38,
			"\$" => 26,
			'SYMBOL' => 1,
			'INFIX' => 23,
			'REGEX' => 2
		},
		GOTOS => {
			's_suffix' => 67,
			'regex' => 28,
			'qc_phrase' => 27,
			'qc_boolean' => 64,
			'index' => 24,
			'q_clause' => 118,
			'qw_infix_set' => 72,
			'qw_set_infl' => 34,
			'qw_morph' => 31,
			'qw_listfile' => 32,
			'qc_word' => 33,
			'qw_suffix' => 69,
			'qw_without' => 30,
			'neg_regex' => 68,
			'qw_prefix' => 50,
			'qw_thesaurus' => 7,
			'qw_suffix_set' => 46,
			'qw_matchid' => 45,
			'symbol' => 44,
			's_index' => 39,
			's_infix' => 6,
			'qw_anchor' => 40,
			'qw_exact' => 41,
			'qw_lemma' => 42,
			'qw_set_exact' => 43,
			'qw_prefix_set' => 4,
			'qw_chunk' => 5,
			's_prefix' => 56,
			'qw_regex' => 60,
			'qw_keys' => 62,
			'qw_bareword' => 22,
			'qw_with' => 16,
			'qc_near' => 19,
			'qc_basic' => 18,
			'qw_any' => 20,
			'qw_infix' => 53,
			'qc_concat' => 15,
			'qc_tokens' => 51,
			'qwk_indextuple' => 9,
			's_word' => 11,
			'qw_withor' => 12,
			'qc_matchid' => 14
		}
	},
	{#State 64
		DEFAULT => -114
	},
	{#State 65
		ACTIONS => {
			'SYMBOL' => 1,
			'DATE' => 57,
			'INTEGER' => 21
		},
		GOTOS => {
			'symbol' => 120,
			's_chunk' => 119
		}
	},
	{#State 66
		ACTIONS => {
			"(" => 121
		}
	},
	{#State 67
		DEFAULT => -177
	},
	{#State 68
		DEFAULT => -167
	},
	{#State 69
		DEFAULT => -147
	},
	{#State 70
		DEFAULT => -211,
		GOTOS => {
			'l_morph' => 122
		}
	},
	{#State 71
		DEFAULT => -208,
		GOTOS => {
			'l_set' => 123
		}
	},
	{#State 72
		DEFAULT => -144
	},
	{#State 73
		DEFAULT => -270
	},
	{#State 74
		ACTIONS => {
			'SYMBOL' => 1,
			'INFIX' => 23,
			'REGEX' => 2,
			'SUFFIX' => 3,
			"\$" => 26,
			'COLON_LBRACE' => 38,
			"!" => 63,
			"^" => 65,
			'COUNT' => 66,
			"\"" => 48,
			"{" => 47,
			'DOLLAR_DOT' => 49,
			'INDEX' => 29,
			"<" => 52,
			'KEYS' => 8,
			'NEAR' => 54,
			'PREFIX' => 55,
			"[" => 70,
			"*" => 17,
			'AT_LBRACE' => 71,
			"(" => 35,
			'STAR_LBRACE' => 36,
			'INTEGER' => 21,
			'DATE' => 57,
			"%" => 58,
			'NEG_REGEX' => 61,
			"\@" => 37
		},
		GOTOS => {
			'qwk_indextuple' => 9,
			'qc_tokens' => 51,
			'qc_matchid' => 14,
			'query_conditions' => 124,
			'qw_withor' => 12,
			's_word' => 11,
			'qc_concat' => 15,
			'qw_infix' => 53,
			'qc_basic' => 18,
			'qc_near' => 19,
			'qw_with' => 16,
			'qw_any' => 20,
			'count_query' => 126,
			's_prefix' => 56,
			'qw_keys' => 62,
			'qw_bareword' => 22,
			'qw_regex' => 60,
			'qw_prefix_set' => 4,
			'qw_chunk' => 5,
			'qw_anchor' => 40,
			's_infix' => 6,
			's_index' => 39,
			'qw_set_exact' => 43,
			'qw_exact' => 41,
			'qw_lemma' => 42,
			'qw_matchid' => 45,
			'symbol' => 44,
			'qw_suffix_set' => 46,
			'qw_thesaurus' => 7,
			'qw_prefix' => 50,
			'qw_without' => 30,
			'qw_suffix' => 69,
			'neg_regex' => 68,
			'qw_listfile' => 32,
			'qw_morph' => 31,
			'qc_word' => 33,
			'qw_set_infl' => 34,
			'qw_infix_set' => 72,
			'index' => 24,
			'q_clause' => 25,
			'qc_phrase' => 27,
			'qwk_countsrc' => 125,
			'qc_boolean' => 64,
			'regex' => 28,
			's_suffix' => 67
		}
	},
	{#State 75
		ACTIONS => {
			'KEYS' => 127
		}
	},
	{#State 76
		DEFAULT => 0
	},
	{#State 77
		ACTIONS => {
			'EXPANDER' => 129
		},
		DEFAULT => -161,
		GOTOS => {
			's_expander' => 128
		}
	},
	{#State 78
		ACTIONS => {
			'SYMBOL' => 1,
			'INFIX' => 23,
			'REGEX' => 2,
			'SUFFIX' => 3,
			'COLON_LBRACE' => 38,
			"\$" => 26,
			"^" => 65,
			"\"" => 48,
			"{" => 47,
			'DOLLAR_DOT' => 49,
			'INDEX' => 29,
			'KEYS' => 8,
			"<" => 52,
			'PREFIX' => 55,
			'NEAR' => 54,
			"[" => 70,
			"*" => 17,
			'AT_LBRACE' => 71,
			"(" => 78,
			'STAR_LBRACE' => 36,
			'INTEGER' => 21,
			"%" => 58,
			'DATE' => 57,
			'NEG_REGEX' => 61,
			"\@" => 37
		},
		GOTOS => {
			'qc_phrase' => 130,
			'index' => 24,
			's_suffix' => 67,
			'regex' => 28,
			'qw_morph' => 31,
			'qw_listfile' => 32,
			'qc_word' => 131,
			'qw_suffix' => 69,
			'neg_regex' => 68,
			'qw_without' => 30,
			'qw_infix_set' => 72,
			'qw_set_infl' => 34,
			's_infix' => 6,
			's_index' => 39,
			'qw_anchor' => 40,
			'qw_set_exact' => 43,
			'qw_lemma' => 42,
			'qw_exact' => 41,
			'qw_prefix_set' => 4,
			'qw_chunk' => 5,
			'qw_prefix' => 50,
			'qw_thesaurus' => 7,
			'qw_suffix_set' => 46,
			'symbol' => 44,
			'qw_matchid' => 45,
			'qw_infix' => 53,
			'qwk_indextuple' => 9,
			's_word' => 11,
			'qw_withor' => 12,
			's_prefix' => 56,
			'qw_regex' => 60,
			'qw_keys' => 62,
			'qw_bareword' => 22,
			'qc_near' => 132,
			'qw_with' => 16,
			'qw_any' => 20
		}
	},
	{#State 79
		DEFAULT => -124
	},
	{#State 80
		DEFAULT => -123
	},
	{#State 81
		DEFAULT => -130
	},
	{#State 82
		DEFAULT => -280
	},
	{#State 83
		ACTIONS => {
			'INTEGER' => 133
		},
		GOTOS => {
			'int_str' => 135,
			'integer' => 134
		}
	},
	{#State 84
		ACTIONS => {
			'KEYS' => 8,
			"<" => 52,
			"[" => 70,
			'PREFIX' => 55,
			'NEAR' => 54,
			'STAR_LBRACE' => 36,
			"(" => 35,
			'AT_LBRACE' => 71,
			"*" => 17,
			"\@" => 37,
			'NEG_REGEX' => 61,
			"%" => 58,
			'DATE' => 57,
			'INTEGER' => 21,
			'COLON_LBRACE' => 38,
			"\$" => 26,
			'SUFFIX' => 3,
			'REGEX' => 2,
			'INFIX' => 23,
			'SYMBOL' => 1,
			"^" => 65,
			"!" => 63,
			"{" => 47,
			"\"" => 48,
			'INDEX' => 29,
			'DOLLAR_DOT' => 49
		},
		GOTOS => {
			'qw_infix' => 53,
			'qc_concat' => 15,
			'qw_withor' => 12,
			's_word' => 11,
			'qc_matchid' => 14,
			'qc_tokens' => 51,
			'qwk_indextuple' => 9,
			'qw_regex' => 60,
			'qw_bareword' => 22,
			'qw_keys' => 62,
			's_prefix' => 56,
			'qw_any' => 20,
			'qw_with' => 16,
			'qc_near' => 19,
			'qc_basic' => 18,
			'qw_exact' => 41,
			'qw_lemma' => 42,
			'qw_set_exact' => 43,
			's_infix' => 6,
			's_index' => 39,
			'qw_anchor' => 40,
			'qw_chunk' => 5,
			'qw_prefix_set' => 4,
			'qw_prefix' => 50,
			'qw_thesaurus' => 7,
			'symbol' => 44,
			'qw_matchid' => 45,
			'qw_suffix_set' => 46,
			'qc_word' => 33,
			'qw_morph' => 31,
			'qw_listfile' => 32,
			'qw_without' => 30,
			'neg_regex' => 68,
			'qw_suffix' => 69,
			'qw_infix_set' => 72,
			'qw_set_infl' => 34,
			'qc_boolean' => 64,
			'qc_phrase' => 27,
			'q_clause' => 136,
			'index' => 24,
			's_suffix' => 67,
			'regex' => 28
		}
	},
	{#State 85
		ACTIONS => {
			'FILENAMES_ONLY' => 138,
			'DEBUG_RANK' => 157,
			'LESS_BY_RIGHT' => 156,
			'GREATER_BY_DATE' => 159,
			'LESS_BY_SIZE' => 160,
			'NOSEPARATE_HITS' => 161,
			'GREATER_BY_MIDDLE' => 145,
			'GREATER_BY_SIZE' => 158,
			'RANDOM' => 139,
			'LESS_BY' => 140,
			'WITHIN' => 141,
			'IS_DATE' => 142,
			'LESS_BY_RANK' => 143,
			'CNTXT' => 146,
			"!" => 168,
			'GREATER_BY' => 169,
			'LESS_BY_LEFT' => 147,
			'GREATER_BY_LEFT' => 163,
			'IS_SIZE' => 164,
			'LESS_BY_DATE' => 165,
			'HAS_FIELD' => 166,
			":" => 150,
			'GREATER_BY_RIGHT' => 152,
			'SEPARATE_HITS' => 153,
			'GREATER_BY_RANK' => 155,
			'LESS_BY_MIDDLE' => 171
		},
		DEFAULT => -28,
		GOTOS => {
			'q_flag' => 167,
			'qf_bibl_sort' => 151,
			'qf_has_field' => 148,
			'qf_random_sort' => 162,
			'qf_date_sort' => 170,
			'qf_size_sort' => 154,
			'qf_rank_sort' => 144,
			'qf_context_sort' => 137,
			'q_filter' => 149
		}
	},
	{#State 86
		ACTIONS => {
			"\"" => 48,
			"{" => 47,
			'DOLLAR_DOT' => 49,
			'INDEX' => 29,
			'SUFFIX' => 3,
			"\$" => 26,
			'COLON_LBRACE' => 38,
			'INFIX' => 23,
			'SYMBOL' => 1,
			'REGEX' => 2,
			"^" => 65,
			"!" => 63,
			'AT_LBRACE' => 71,
			"(" => 35,
			'STAR_LBRACE' => 36,
			"*" => 17,
			'NEG_REGEX' => 61,
			"\@" => 37,
			'INTEGER' => 21,
			'DATE' => 57,
			"%" => 58,
			'KEYS' => 8,
			"<" => 52,
			"[" => 70,
			'PREFIX' => 55,
			'NEAR' => 54
		},
		GOTOS => {
			'qw_set_exact' => 43,
			'qw_lemma' => 42,
			'qw_exact' => 41,
			's_infix' => 6,
			's_index' => 39,
			'qw_anchor' => 40,
			'qw_prefix_set' => 4,
			'qw_chunk' => 5,
			'qw_prefix' => 50,
			'qw_thesaurus' => 7,
			'qw_matchid' => 45,
			'qw_suffix_set' => 46,
			'symbol' => 44,
			'qc_concat' => 15,
			'qw_infix' => 53,
			'qw_withor' => 12,
			's_word' => 11,
			'qc_matchid' => 14,
			'qc_tokens' => 51,
			'qwk_indextuple' => 9,
			'qw_regex' => 60,
			'qw_bareword' => 22,
			'qw_keys' => 62,
			's_prefix' => 56,
			'qw_any' => 20,
			'qw_with' => 16,
			'qc_basic' => 18,
			'qc_near' => 19,
			'qc_boolean' => 64,
			'qc_phrase' => 27,
			'q_clause' => 172,
			'index' => 24,
			's_suffix' => 67,
			'regex' => 28,
			'qc_word' => 33,
			'qw_morph' => 31,
			'qw_listfile' => 32,
			'neg_regex' => 68,
			'qw_suffix' => 69,
			'qw_without' => 30,
			'qw_infix_set' => 72,
			'qw_set_infl' => 34
		}
	},
	{#State 87
		DEFAULT => -117
	},
	{#State 88
		ACTIONS => {
			'SYMBOL' => 1,
			"\$" => 173,
			'INTEGER' => 21,
			'INDEX' => 29,
			'DATE' => 57
		},
		DEFAULT => -226,
		GOTOS => {
			's_index' => 175,
			'symbol' => 174,
			'l_indextuple' => 176,
			'index' => 24,
			's_indextuple_item' => 177
		}
	},
	{#State 89
		ACTIONS => {
			"[" => 70,
			'PREFIX' => 55,
			'KEYS' => 8,
			"<" => 52,
			'NEG_REGEX' => 61,
			"\@" => 37,
			"%" => 58,
			'DATE' => 57,
			'INTEGER' => 21,
			'STAR_LBRACE' => 36,
			'AT_LBRACE' => 71,
			"(" => 107,
			"*" => 17,
			"^" => 65,
			'COLON_LBRACE' => 38,
			"\$" => 26,
			'SUFFIX' => 3,
			'REGEX' => 2,
			'INFIX' => 23,
			'SYMBOL' => 1,
			'INDEX' => 29,
			'DOLLAR_DOT' => 49,
			"{" => 47
		},
		GOTOS => {
			'qw_with' => 16,
			'qw_any' => 20,
			's_prefix' => 56,
			'qw_regex' => 60,
			'qw_bareword' => 22,
			'qw_keys' => 62,
			'qwk_indextuple' => 9,
			's_word' => 11,
			'qw_withor' => 12,
			'qw_infix' => 53,
			'qw_thesaurus' => 7,
			'qw_suffix_set' => 46,
			'symbol' => 44,
			'qw_matchid' => 45,
			'qw_prefix' => 50,
			'qw_prefix_set' => 4,
			'qw_chunk' => 5,
			's_index' => 39,
			's_infix' => 6,
			'qw_anchor' => 40,
			'qw_exact' => 41,
			'qw_set_exact' => 43,
			'qw_lemma' => 42,
			'qw_set_infl' => 34,
			'qw_infix_set' => 72,
			'qw_suffix' => 69,
			'neg_regex' => 68,
			'qw_without' => 30,
			'qw_morph' => 31,
			'qw_listfile' => 32,
			'qc_word' => 178,
			'regex' => 28,
			's_suffix' => 67,
			'index' => 24
		}
	},
	{#State 90
		DEFAULT => -207
	},
	{#State 91
		ACTIONS => {
			'SUFFIX' => 3,
			"\$" => 26,
			'COLON_LBRACE' => 38,
			'INFIX' => 23,
			'SYMBOL' => 1,
			'REGEX' => 2,
			"^" => 65,
			"{" => 47,
			'DOLLAR_DOT' => 49,
			'INDEX' => 29,
			"<" => 52,
			'KEYS' => 8,
			"[" => 70,
			'PREFIX' => 55,
			"(" => 107,
			'AT_LBRACE' => 71,
			'STAR_LBRACE' => 36,
			"*" => 17,
			'NEG_REGEX' => 61,
			"\@" => 37,
			'INTEGER' => 21,
			"%" => 58,
			'DATE' => 57
		},
		GOTOS => {
			'qw_prefix_set' => 4,
			'qw_chunk' => 5,
			'qw_lemma' => 42,
			'qw_exact' => 41,
			'qw_set_exact' => 43,
			's_index' => 39,
			's_infix' => 6,
			'qw_anchor' => 40,
			'qw_thesaurus' => 7,
			'qw_suffix_set' => 46,
			'symbol' => 44,
			'qw_matchid' => 45,
			'qw_prefix' => 50,
			'qw_withor' => 12,
			's_word' => 11,
			'qwk_indextuple' => 9,
			'qw_infix' => 53,
			'qw_any' => 20,
			'qw_with' => 16,
			'qw_regex' => 60,
			'qw_bareword' => 22,
			'qw_keys' => 62,
			's_prefix' => 56,
			'index' => 24,
			'regex' => 28,
			's_suffix' => 67,
			'qw_without' => 30,
			'qw_suffix' => 69,
			'neg_regex' => 68,
			'qc_word' => 179,
			'qw_morph' => 31,
			'qw_listfile' => 32,
			'qw_set_infl' => 34,
			'qw_infix_set' => 72
		}
	},
	{#State 92
		ACTIONS => {
			'DATE' => 57,
			"%" => 58,
			'INTEGER' => 21,
			"\@" => 37,
			'NEG_REGEX' => 61,
			"*" => 17,
			'STAR_LBRACE' => 36,
			"(" => 107,
			'AT_LBRACE' => 71,
			'PREFIX' => 55,
			"[" => 70,
			"<" => 52,
			'KEYS' => 8,
			'INDEX' => 29,
			'DOLLAR_DOT' => 49,
			"{" => 47,
			"^" => 65,
			'REGEX' => 2,
			'INFIX' => 23,
			'SYMBOL' => 1,
			'COLON_LBRACE' => 38,
			"\$" => 26,
			'SUFFIX' => 3
		},
		GOTOS => {
			'index' => 24,
			's_suffix' => 67,
			'regex' => 28,
			'qc_word' => 180,
			'qw_listfile' => 32,
			'qw_morph' => 31,
			'neg_regex' => 68,
			'qw_without' => 30,
			'qw_suffix' => 69,
			'qw_infix_set' => 72,
			'qw_set_infl' => 34,
			'qw_set_exact' => 43,
			'qw_exact' => 41,
			'qw_lemma' => 42,
			'qw_anchor' => 40,
			's_index' => 39,
			's_infix' => 6,
			'qw_chunk' => 5,
			'qw_prefix_set' => 4,
			'qw_prefix' => 50,
			'qw_matchid' => 45,
			'qw_suffix_set' => 46,
			'symbol' => 44,
			'qw_thesaurus' => 7,
			'qw_infix' => 53,
			's_word' => 11,
			'qw_withor' => 12,
			'qwk_indextuple' => 9,
			'qw_keys' => 62,
			'qw_bareword' => 22,
			'qw_regex' => 60,
			's_prefix' => 56,
			'qw_any' => 20,
			'qw_with' => 16
		}
	},
	{#State 93
		ACTIONS => {
			'WITHOUT' => 92,
			'WITH' => 91,
			'WITHOR' => 89,
			")" => 181,
			"=" => 82
		},
		DEFAULT => -132,
		GOTOS => {
			'matchid_eq' => 83,
			'matchid' => 90
		}
	},
	{#State 94
		ACTIONS => {
			")" => 182
		},
		DEFAULT => -133
	},
	{#State 95
		ACTIONS => {
			'OP_BOOL_AND' => 86,
			'OP_BOOL_OR' => 84,
			"=" => 82
		},
		GOTOS => {
			'matchid_eq' => 83,
			'matchid' => 87
		}
	},
	{#State 96
		ACTIONS => {
			")" => 183,
			"=" => 82
		},
		DEFAULT => -127,
		GOTOS => {
			'matchid' => 81,
			'matchid_eq' => 83
		}
	},
	{#State 97
		ACTIONS => {
			'REGEX' => 2,
			'SYMBOL' => 1,
			'INFIX' => 23,
			"\$" => 26,
			'COLON_LBRACE' => 38,
			'SUFFIX' => 3,
			"^" => 65,
			"\"" => 48,
			"{" => 47,
			")" => 184,
			'INDEX' => 29,
			'DOLLAR_DOT' => 49,
			"<" => 52,
			'KEYS' => 8,
			'NEAR' => 54,
			'PREFIX' => 55,
			"[" => 70,
			"*" => 17,
			'STAR_LBRACE' => 36,
			"(" => 78,
			'AT_LBRACE' => 71,
			'DATE' => 57,
			"%" => 58,
			'INTEGER' => 21,
			"\@" => 37,
			'NEG_REGEX' => 61
		},
		DEFAULT => -115,
		GOTOS => {
			'index' => 24,
			'qc_phrase' => 27,
			'regex' => 28,
			's_suffix' => 67,
			'qw_suffix' => 69,
			'neg_regex' => 68,
			'qw_without' => 30,
			'qw_morph' => 31,
			'qw_listfile' => 32,
			'qc_word' => 33,
			'qw_set_infl' => 34,
			'qw_infix_set' => 72,
			'qw_chunk' => 5,
			'qw_prefix_set' => 4,
			's_infix' => 6,
			's_index' => 39,
			'qw_anchor' => 40,
			'qw_set_exact' => 43,
			'qw_exact' => 41,
			'qw_lemma' => 42,
			'qw_thesaurus' => 7,
			'qw_suffix_set' => 46,
			'symbol' => 44,
			'qw_matchid' => 45,
			'qw_prefix' => 50,
			'qc_tokens' => 51,
			'qwk_indextuple' => 9,
			'qw_withor' => 12,
			's_word' => 11,
			'qw_infix' => 53,
			'qc_basic' => 79,
			'qw_with' => 16,
			'qc_near' => 19,
			'qw_any' => 20,
			's_prefix' => 56,
			'qw_regex' => 60,
			'qw_keys' => 62,
			'qw_bareword' => 22
		}
	},
	{#State 98
		ACTIONS => {
			")" => 185
		},
		DEFAULT => -116
	},
	{#State 99
		ACTIONS => {
			")" => 186
		},
		DEFAULT => -114
	},
	{#State 100
		ACTIONS => {
			"," => 189,
			'SYMBOL' => 1,
			'RBRACE_STAR' => 190,
			"}" => 188,
			'INTEGER' => 21,
			'DATE' => 57
		},
		GOTOS => {
			'symbol' => 44,
			's_word' => 187
		}
	},
	{#State 101
		DEFAULT => -163
	},
	{#State 102
		DEFAULT => -250
	},
	{#State 103
		ACTIONS => {
			"}" => 191
		}
	},
	{#State 104
		ACTIONS => {
			"{" => 199,
			"^" => 203,
			'SUFFIX' => 3,
			'INFIX' => 23,
			'SYMBOL' => 1,
			'REGEX' => 2,
			"\@" => 197,
			'NEG_REGEX' => 61,
			'INTEGER' => 21,
			'DATE' => 57,
			"%" => 202,
			'AT_LBRACE' => 207,
			'STAR_LBRACE' => 198,
			"*" => 194,
			"[" => 205,
			'PREFIX' => 55,
			":" => 196,
			"<" => 200
		},
		GOTOS => {
			's_suffix' => 204,
			's_prefix' => 201,
			's_infix' => 192,
			's_word' => 193,
			'neg_regex' => 206,
			'regex' => 195,
			'symbol' => 44
		}
	},
	{#State 105
		ACTIONS => {
			"}" => 209,
			'INTEGER' => 21,
			'DATE' => 57,
			'SYMBOL' => 1,
			"," => 189,
			'RBRACE_STAR' => 208
		},
		GOTOS => {
			'symbol' => 44,
			's_word' => 187
		}
	},
	{#State 106
		ACTIONS => {
			'WITHOUT' => 92,
			'WITHOR' => 89,
			'WITH' => 91,
			"=" => 82
		},
		DEFAULT => -215,
		GOTOS => {
			'matchid_eq' => 83,
			'matchid' => 90
		}
	},
	{#State 107
		ACTIONS => {
			'NEG_REGEX' => 61,
			"\@" => 37,
			"%" => 58,
			'DATE' => 57,
			'INTEGER' => 21,
			'STAR_LBRACE' => 36,
			"(" => 107,
			'AT_LBRACE' => 71,
			"*" => 17,
			"[" => 70,
			'PREFIX' => 55,
			'KEYS' => 8,
			"<" => 52,
			'INDEX' => 29,
			'DOLLAR_DOT' => 49,
			"{" => 47,
			"^" => 65,
			'COLON_LBRACE' => 38,
			"\$" => 26,
			'SUFFIX' => 3,
			'REGEX' => 2,
			'INFIX' => 23,
			'SYMBOL' => 1
		},
		GOTOS => {
			'index' => 24,
			's_suffix' => 67,
			'regex' => 28,
			'qc_word' => 131,
			'qw_morph' => 31,
			'qw_listfile' => 32,
			'qw_suffix' => 69,
			'neg_regex' => 68,
			'qw_without' => 30,
			'qw_infix_set' => 72,
			'qw_set_infl' => 34,
			'qw_lemma' => 42,
			'qw_exact' => 41,
			'qw_set_exact' => 43,
			's_infix' => 6,
			's_index' => 39,
			'qw_anchor' => 40,
			'qw_chunk' => 5,
			'qw_prefix_set' => 4,
			'qw_prefix' => 50,
			'qw_thesaurus' => 7,
			'qw_suffix_set' => 46,
			'qw_matchid' => 45,
			'symbol' => 44,
			'qw_infix' => 53,
			's_word' => 11,
			'qw_withor' => 12,
			'qwk_indextuple' => 9,
			'qw_regex' => 60,
			'qw_bareword' => 22,
			'qw_keys' => 62,
			's_prefix' => 56,
			'qw_any' => 20,
			'qw_with' => 16
		}
	},
	{#State 108
		ACTIONS => {
			'HASH_LESS' => 211,
			"%" => 58,
			'DATE' => 57,
			'INTEGER' => 21,
			'NEG_REGEX' => 61,
			"\@" => 37,
			"*" => 17,
			'STAR_LBRACE' => 36,
			"#" => 210,
			"(" => 107,
			'AT_LBRACE' => 71,
			'PREFIX' => 55,
			'HASH_GREATER' => 215,
			"[" => 70,
			'KEYS' => 8,
			"<" => 52,
			'INDEX' => 29,
			'DOLLAR_DOT' => 49,
			"\"" => 212,
			"{" => 47,
			"^" => 65,
			'HASH_EQUAL' => 213,
			'REGEX' => 2,
			'INFIX' => 23,
			'SYMBOL' => 1,
			"\$" => 26,
			'COLON_LBRACE' => 38,
			'SUFFIX' => 3
		},
		GOTOS => {
			'index' => 24,
			'regex' => 28,
			's_suffix' => 67,
			'qw_without' => 30,
			'qw_suffix' => 69,
			'neg_regex' => 68,
			'qc_word' => 214,
			'qw_morph' => 31,
			'qw_listfile' => 32,
			'qw_set_infl' => 34,
			'qw_infix_set' => 72,
			'qw_chunk' => 5,
			'qw_prefix_set' => 4,
			'qw_set_exact' => 43,
			'qw_lemma' => 42,
			'qw_exact' => 41,
			's_index' => 39,
			's_infix' => 6,
			'qw_anchor' => 40,
			'qw_thesaurus' => 7,
			'qw_matchid' => 45,
			'qw_suffix_set' => 46,
			'symbol' => 44,
			'qw_prefix' => 50,
			's_word' => 11,
			'qw_withor' => 12,
			'qwk_indextuple' => 9,
			'qw_infix' => 53,
			'qw_any' => 20,
			'qw_with' => 16,
			'qw_regex' => 60,
			'qw_bareword' => 22,
			'qw_keys' => 62,
			's_prefix' => 56
		}
	},
	{#State 109
		ACTIONS => {
			'INTEGER' => 133
		},
		GOTOS => {
			'int_str' => 216
		}
	},
	{#State 110
		ACTIONS => {
			"=" => 217
		}
	},
	{#State 111
		DEFAULT => -134
	},
	{#State 112
		DEFAULT => -253
	},
	{#State 113
		DEFAULT => -197
	},
	{#State 114
		ACTIONS => {
			'SYMBOL' => 1,
			'INFIX' => 23,
			'REGEX' => 2,
			'SUFFIX' => 3,
			"\$" => 26,
			'COLON_LBRACE' => 38,
			"^" => 65,
			"\"" => 48,
			"{" => 47,
			'DOLLAR_DOT' => 49,
			'INDEX' => 29,
			"<" => 52,
			'KEYS' => 8,
			'PREFIX' => 55,
			"[" => 70,
			"*" => 17,
			'AT_LBRACE' => 71,
			"(" => 218,
			'STAR_LBRACE' => 36,
			'INTEGER' => 21,
			"%" => 58,
			'DATE' => 57,
			'NEG_REGEX' => 61,
			"\@" => 37
		},
		GOTOS => {
			's_suffix' => 67,
			'regex' => 28,
			'qc_phrase' => 27,
			'index' => 24,
			'qw_infix_set' => 72,
			'qw_set_infl' => 34,
			'qc_word' => 33,
			'qw_morph' => 31,
			'qw_listfile' => 32,
			'neg_regex' => 68,
			'qw_without' => 30,
			'qw_suffix' => 69,
			'qw_prefix' => 50,
			'qw_thesaurus' => 7,
			'qw_suffix_set' => 46,
			'qw_matchid' => 45,
			'symbol' => 44,
			'qw_set_exact' => 43,
			'qw_lemma' => 42,
			'qw_exact' => 41,
			's_infix' => 6,
			's_index' => 39,
			'qw_anchor' => 40,
			'qw_chunk' => 5,
			'qw_prefix_set' => 4,
			'qw_regex' => 60,
			'qw_bareword' => 22,
			'qw_keys' => 62,
			's_prefix' => 56,
			'qw_any' => 20,
			'qw_with' => 16,
			'qw_infix' => 53,
			'qw_withor' => 12,
			's_word' => 11,
			'qc_tokens' => 219,
			'qwk_indextuple' => 9
		}
	},
	{#State 115
		DEFAULT => -191
	},
	{#State 116
		DEFAULT => -251
	},
	{#State 117
		DEFAULT => -272
	},
	{#State 118
		ACTIONS => {
			"=" => 82
		},
		DEFAULT => -121,
		GOTOS => {
			'matchid' => 87,
			'matchid_eq' => 83
		}
	},
	{#State 119
		DEFAULT => -193
	},
	{#State 120
		DEFAULT => -252
	},
	{#State 121
		ACTIONS => {
			"{" => 47,
			"\"" => 48,
			'DOLLAR_DOT' => 49,
			'INDEX' => 29,
			'SYMBOL' => 1,
			'INFIX' => 23,
			'REGEX' => 2,
			'SUFFIX' => 3,
			"\$" => 26,
			'COLON_LBRACE' => 38,
			"!" => 63,
			"^" => 65,
			"*" => 17,
			'AT_LBRACE' => 71,
			"(" => 35,
			'STAR_LBRACE' => 36,
			'INTEGER' => 21,
			'DATE' => 57,
			"%" => 58,
			'NEG_REGEX' => 61,
			"\@" => 37,
			'KEYS' => 8,
			"<" => 52,
			'NEAR' => 54,
			'PREFIX' => 55,
			"[" => 70
		},
		GOTOS => {
			'qwk_indextuple' => 9,
			'qc_tokens' => 51,
			'qc_matchid' => 14,
			's_word' => 11,
			'query_conditions' => 220,
			'qw_withor' => 12,
			'qc_concat' => 15,
			'qw_infix' => 53,
			'qc_basic' => 18,
			'qw_with' => 16,
			'qc_near' => 19,
			'qw_any' => 20,
			's_prefix' => 56,
			'qw_bareword' => 22,
			'qw_keys' => 62,
			'qw_regex' => 60,
			'qw_prefix_set' => 4,
			'qw_chunk' => 5,
			'qw_anchor' => 40,
			's_index' => 39,
			's_infix' => 6,
			'qw_set_exact' => 43,
			'qw_lemma' => 42,
			'qw_exact' => 41,
			'qw_suffix_set' => 46,
			'qw_matchid' => 45,
			'symbol' => 44,
			'qw_thesaurus' => 7,
			'qw_prefix' => 50,
			'qw_suffix' => 69,
			'qw_without' => 30,
			'neg_regex' => 68,
			'qw_listfile' => 32,
			'qw_morph' => 31,
			'qc_word' => 33,
			'qw_set_infl' => 34,
			'qw_infix_set' => 72,
			'index' => 24,
			'q_clause' => 25,
			'qc_phrase' => 27,
			'qc_boolean' => 64,
			'regex' => 28,
			's_suffix' => 67
		}
	},
	{#State 122
		ACTIONS => {
			"]" => 221,
			'DATE' => 57,
			'INTEGER' => 21,
			";" => 225,
			"," => 222,
			'SYMBOL' => 1
		},
		GOTOS => {
			'symbol' => 223,
			's_morphitem' => 224
		}
	},
	{#State 123
		ACTIONS => {
			'INTEGER' => 21,
			"}" => 226,
			'DATE' => 57,
			"," => 189,
			'SYMBOL' => 1
		},
		GOTOS => {
			'symbol' => 44,
			's_word' => 187
		}
	},
	{#State 124
		DEFAULT => -4,
		GOTOS => {
			'count_filters' => 227
		}
	},
	{#State 125
		ACTIONS => {
			")" => 228
		}
	},
	{#State 126
		DEFAULT => -205
	},
	{#State 127
		ACTIONS => {
			"(" => 229
		}
	},
	{#State 128
		DEFAULT => -222
	},
	{#State 129
		DEFAULT => -268
	},
	{#State 130
		ACTIONS => {
			")" => 182
		}
	},
	{#State 131
		ACTIONS => {
			'WITHOUT' => 92,
			"=" => 82,
			'WITHOR' => 89,
			")" => 181,
			'WITH' => 91
		},
		GOTOS => {
			'matchid_eq' => 83,
			'matchid' => 90
		}
	},
	{#State 132
		ACTIONS => {
			")" => 183,
			"=" => 82
		},
		GOTOS => {
			'matchid_eq' => 83,
			'matchid' => 81
		}
	},
	{#State 133
		DEFAULT => -275
	},
	{#State 134
		DEFAULT => -279
	},
	{#State 135
		DEFAULT => -276
	},
	{#State 136
		ACTIONS => {
			"=" => 82
		},
		DEFAULT => -120,
		GOTOS => {
			'matchid_eq' => 83,
			'matchid' => 87
		}
	},
	{#State 137
		DEFAULT => -47
	},
	{#State 138
		DEFAULT => -38
	},
	{#State 139
		ACTIONS => {
			"[" => 230
		},
		DEFAULT => -74
	},
	{#State 140
		ACTIONS => {
			"[" => 231
		}
	},
	{#State 141
		ACTIONS => {
			'SYMBOL' => 1,
			'DATE' => 57,
			'INTEGER' => 21,
			'KW_FILENAME' => 233
		},
		GOTOS => {
			'symbol' => 232,
			's_breakname' => 234
		}
	},
	{#State 142
		ACTIONS => {
			"[" => 235
		}
	},
	{#State 143
		DEFAULT => -61
	},
	{#State 144
		DEFAULT => -46
	},
	{#State 145
		ACTIONS => {
			"[" => 236
		},
		DEFAULT => -102,
		GOTOS => {
			'qfb_ctxsort' => 237
		}
	},
	{#State 146
		ACTIONS => {
			'INTEGER' => 133,
			"[" => 238
		},
		GOTOS => {
			'integer' => 239,
			'int_str' => 135
		}
	},
	{#State 147
		ACTIONS => {
			"[" => 236
		},
		DEFAULT => -102,
		GOTOS => {
			'qfb_ctxsort' => 240
		}
	},
	{#State 148
		DEFAULT => -45
	},
	{#State 149
		DEFAULT => -31
	},
	{#State 150
		ACTIONS => {
			'SYMBOL' => 1,
			'DATE' => 57,
			'INTEGER' => 21
		},
		DEFAULT => -42,
		GOTOS => {
			'symbol' => 242,
			's_subcorpus' => 243,
			'qf_subcorpora' => 241
		}
	},
	{#State 151
		DEFAULT => -50
	},
	{#State 152
		ACTIONS => {
			"[" => 236
		},
		DEFAULT => -102,
		GOTOS => {
			'qfb_ctxsort' => 244
		}
	},
	{#State 153
		DEFAULT => -36
	},
	{#State 154
		DEFAULT => -48
	},
	{#State 155
		DEFAULT => -60
	},
	{#State 156
		ACTIONS => {
			"[" => 236
		},
		DEFAULT => -102,
		GOTOS => {
			'qfb_ctxsort' => 245
		}
	},
	{#State 157
		DEFAULT => -40
	},
	{#State 158
		ACTIONS => {
			"[" => 246
		},
		DEFAULT => -81,
		GOTOS => {
			'qfb_int' => 247
		}
	},
	{#State 159
		ACTIONS => {
			"[" => 249
		},
		DEFAULT => -88,
		GOTOS => {
			'qfb_date' => 248
		}
	},
	{#State 160
		ACTIONS => {
			"[" => 246
		},
		DEFAULT => -81,
		GOTOS => {
			'qfb_int' => 250
		}
	},
	{#State 161
		DEFAULT => -37
	},
	{#State 162
		DEFAULT => -51
	},
	{#State 163
		ACTIONS => {
			"[" => 236
		},
		DEFAULT => -102,
		GOTOS => {
			'qfb_ctxsort' => 251
		}
	},
	{#State 164
		ACTIONS => {
			"[" => 252
		}
	},
	{#State 165
		ACTIONS => {
			"[" => 249
		},
		DEFAULT => -88,
		GOTOS => {
			'qfb_date' => 253
		}
	},
	{#State 166
		ACTIONS => {
			"[" => 254
		}
	},
	{#State 167
		DEFAULT => -30
	},
	{#State 168
		ACTIONS => {
			'HAS_FIELD' => 166,
			'DEBUG_RANK' => 255,
			"!" => 256,
			'FILENAMES_ONLY' => 257
		},
		GOTOS => {
			'qf_has_field' => 258
		}
	},
	{#State 169
		ACTIONS => {
			"[" => 259
		}
	},
	{#State 170
		DEFAULT => -49
	},
	{#State 171
		ACTIONS => {
			"[" => 236
		},
		DEFAULT => -102,
		GOTOS => {
			'qfb_ctxsort' => 260
		}
	},
	{#State 172
		ACTIONS => {
			"=" => 82
		},
		DEFAULT => -119,
		GOTOS => {
			'matchid' => 87,
			'matchid_eq' => 83
		}
	},
	{#State 173
		DEFAULT => -245
	},
	{#State 174
		DEFAULT => -248
	},
	{#State 175
		DEFAULT => -247
	},
	{#State 176
		ACTIONS => {
			")" => 262,
			"," => 261
		}
	},
	{#State 177
		DEFAULT => -227
	},
	{#State 178
		ACTIONS => {
			"=" => 82
		},
		DEFAULT => -201,
		GOTOS => {
			'matchid_eq' => 83,
			'matchid' => 90
		}
	},
	{#State 179
		ACTIONS => {
			"=" => 82
		},
		DEFAULT => -199,
		GOTOS => {
			'matchid_eq' => 83,
			'matchid' => 90
		}
	},
	{#State 180
		ACTIONS => {
			"=" => 82
		},
		DEFAULT => -200,
		GOTOS => {
			'matchid' => 90,
			'matchid_eq' => 83
		}
	},
	{#State 181
		DEFAULT => -160
	},
	{#State 182
		DEFAULT => -136
	},
	{#State 183
		DEFAULT => -131
	},
	{#State 184
		DEFAULT => -125
	},
	{#State 185
		DEFAULT => -118
	},
	{#State 186
		DEFAULT => -122
	},
	{#State 187
		DEFAULT => -209
	},
	{#State 188
		DEFAULT => -185
	},
	{#State 189
		DEFAULT => -210
	},
	{#State 190
		DEFAULT => -181
	},
	{#State 191
		DEFAULT => -187
	},
	{#State 192
		DEFAULT => -180
	},
	{#State 193
		DEFAULT => -221,
		GOTOS => {
			'l_txchain' => 263
		}
	},
	{#State 194
		DEFAULT => -170
	},
	{#State 195
		DEFAULT => -166
	},
	{#State 196
		ACTIONS => {
			"{" => 264
		}
	},
	{#State 197
		ACTIONS => {
			'SYMBOL' => 1,
			'DATE' => 57,
			'INTEGER' => 21
		},
		GOTOS => {
			's_word' => 265,
			'symbol' => 44
		}
	},
	{#State 198
		DEFAULT => -208,
		GOTOS => {
			'l_set' => 266
		}
	},
	{#State 199
		DEFAULT => -208,
		GOTOS => {
			'l_set' => 267
		}
	},
	{#State 200
		ACTIONS => {
			'SYMBOL' => 1,
			'DATE' => 57,
			'INTEGER' => 21
		},
		GOTOS => {
			'symbol' => 112,
			's_filename' => 268
		}
	},
	{#State 201
		DEFAULT => -176
	},
	{#State 202
		ACTIONS => {
			'SYMBOL' => 1,
			'DATE' => 57,
			'INTEGER' => 21
		},
		GOTOS => {
			'symbol' => 116,
			's_lemma' => 269
		}
	},
	{#State 203
		ACTIONS => {
			'DATE' => 57,
			'INTEGER' => 21,
			'SYMBOL' => 1
		},
		GOTOS => {
			'symbol' => 120,
			's_chunk' => 270
		}
	},
	{#State 204
		DEFAULT => -178
	},
	{#State 205
		DEFAULT => -211,
		GOTOS => {
			'l_morph' => 271
		}
	},
	{#State 206
		DEFAULT => -168
	},
	{#State 207
		DEFAULT => -208,
		GOTOS => {
			'l_set' => 272
		}
	},
	{#State 208
		DEFAULT => -183
	},
	{#State 209
		DEFAULT => -221,
		GOTOS => {
			'l_txchain' => 273
		}
	},
	{#State 210
		ACTIONS => {
			'INTEGER' => 133
		},
		GOTOS => {
			'integer' => 274,
			'int_str' => 135
		}
	},
	{#State 211
		ACTIONS => {
			'INTEGER' => 133
		},
		GOTOS => {
			'integer' => 275,
			'int_str' => 135
		}
	},
	{#State 212
		DEFAULT => -135
	},
	{#State 213
		ACTIONS => {
			'INTEGER' => 133
		},
		GOTOS => {
			'int_str' => 135,
			'integer' => 276
		}
	},
	{#State 214
		ACTIONS => {
			"=" => 82,
			'WITHOUT' => 92,
			'WITHOR' => 89,
			'WITH' => 91
		},
		DEFAULT => -216,
		GOTOS => {
			'matchid_eq' => 83,
			'matchid' => 90
		}
	},
	{#State 215
		ACTIONS => {
			'INTEGER' => 133
		},
		GOTOS => {
			'integer' => 277,
			'int_str' => 135
		}
	},
	{#State 216
		DEFAULT => -195
	},
	{#State 217
		ACTIONS => {
			'INTEGER' => 133
		},
		GOTOS => {
			'int_str' => 278
		}
	},
	{#State 218
		ACTIONS => {
			'REGEX' => 2,
			'SYMBOL' => 1,
			'INFIX' => 23,
			'COLON_LBRACE' => 38,
			"\$" => 26,
			'SUFFIX' => 3,
			"^" => 65,
			"{" => 47,
			"\"" => 48,
			'INDEX' => 29,
			'DOLLAR_DOT' => 49,
			"<" => 52,
			'KEYS' => 8,
			'PREFIX' => 55,
			"[" => 70,
			"*" => 17,
			'STAR_LBRACE' => 36,
			'AT_LBRACE' => 71,
			"(" => 218,
			"%" => 58,
			'DATE' => 57,
			'INTEGER' => 21,
			'NEG_REGEX' => 61,
			"\@" => 37
		},
		GOTOS => {
			'qw_infix_set' => 72,
			'qw_set_infl' => 34,
			'qw_listfile' => 32,
			'qw_morph' => 31,
			'qc_word' => 131,
			'qw_without' => 30,
			'neg_regex' => 68,
			'qw_suffix' => 69,
			's_suffix' => 67,
			'regex' => 28,
			'qc_phrase' => 130,
			'index' => 24,
			's_prefix' => 56,
			'qw_bareword' => 22,
			'qw_keys' => 62,
			'qw_regex' => 60,
			'qw_with' => 16,
			'qw_any' => 20,
			'qw_infix' => 53,
			'qwk_indextuple' => 9,
			's_word' => 11,
			'qw_withor' => 12,
			'qw_prefix' => 50,
			'qw_suffix_set' => 46,
			'qw_matchid' => 45,
			'symbol' => 44,
			'qw_thesaurus' => 7,
			'qw_anchor' => 40,
			's_infix' => 6,
			's_index' => 39,
			'qw_set_exact' => 43,
			'qw_exact' => 41,
			'qw_lemma' => 42,
			'qw_prefix_set' => 4,
			'qw_chunk' => 5
		}
	},
	{#State 219
		ACTIONS => {
			"=" => 82,
			"," => 279
		},
		GOTOS => {
			'matchid_eq' => 83,
			'matchid' => 111
		}
	},
	{#State 220
		DEFAULT => -4,
		GOTOS => {
			'count_filters' => 280
		}
	},
	{#State 221
		DEFAULT => -189
	},
	{#State 222
		DEFAULT => -213
	},
	{#State 223
		DEFAULT => -254
	},
	{#State 224
		DEFAULT => -212
	},
	{#State 225
		DEFAULT => -214
	},
	{#State 226
		DEFAULT => -171
	},
	{#State 227
		ACTIONS => {
			'CLIMIT' => 290,
			'BY' => 282,
			'GREATER_BY_COUNT' => 284,
			'SAMPLE' => 287,
			'GREATER_BY_KEY' => 285,
			'LESS_BY_KEY' => 288,
			'LESS_BY_COUNT' => 291
		},
		DEFAULT => -206,
		GOTOS => {
			'count_sample' => 283,
			'count_limit' => 289,
			'count_sort' => 286,
			'count_by' => 292,
			'count_filter' => 293,
			'count_sort_op' => 281
		}
	},
	{#State 228
		DEFAULT => -202
	},
	{#State 229
		ACTIONS => {
			"!" => 63,
			"^" => 65,
			'COUNT' => 66,
			'SYMBOL' => 1,
			'INFIX' => 23,
			'REGEX' => 2,
			'SUFFIX' => 3,
			"\$" => 26,
			'COLON_LBRACE' => 38,
			'DOLLAR_DOT' => 49,
			'INDEX' => 29,
			"\"" => 48,
			"{" => 47,
			'PREFIX' => 55,
			'NEAR' => 54,
			"[" => 70,
			"<" => 52,
			'KEYS' => 8,
			'INTEGER' => 21,
			'DATE' => 57,
			"%" => 58,
			"\@" => 37,
			'NEG_REGEX' => 61,
			"*" => 17,
			'AT_LBRACE' => 71,
			"(" => 35,
			'STAR_LBRACE' => 36
		},
		GOTOS => {
			'index' => 24,
			'q_clause' => 25,
			'qc_phrase' => 27,
			'qc_boolean' => 64,
			'qwk_countsrc' => 294,
			'regex' => 28,
			's_suffix' => 67,
			'qw_suffix' => 69,
			'qw_without' => 30,
			'neg_regex' => 68,
			'qw_morph' => 31,
			'qw_listfile' => 32,
			'qc_word' => 33,
			'qw_set_infl' => 34,
			'qw_infix_set' => 72,
			'qw_prefix_set' => 4,
			'qw_chunk' => 5,
			's_infix' => 6,
			's_index' => 39,
			'qw_anchor' => 40,
			'qw_set_exact' => 43,
			'qw_lemma' => 42,
			'qw_exact' => 41,
			'qw_thesaurus' => 7,
			'symbol' => 44,
			'qw_matchid' => 45,
			'qw_suffix_set' => 46,
			'qw_prefix' => 50,
			'qc_tokens' => 51,
			'qwk_indextuple' => 9,
			's_word' => 11,
			'qw_withor' => 12,
			'query_conditions' => 124,
			'qc_matchid' => 14,
			'qw_infix' => 53,
			'qc_concat' => 15,
			'qc_near' => 19,
			'qc_basic' => 18,
			'qw_with' => 16,
			'qw_any' => 20,
			's_prefix' => 56,
			'count_query' => 126,
			'qw_regex' => 60,
			'qw_bareword' => 22,
			'qw_keys' => 62
		}
	},
	{#State 230
		ACTIONS => {
			"]" => 296,
			'INTEGER' => 133
		},
		GOTOS => {
			'int_str' => 295
		}
	},
	{#State 231
		ACTIONS => {
			'SYMBOL' => 1,
			'KW_DATE' => 297,
			'INTEGER' => 21,
			'DATE' => 57
		},
		GOTOS => {
			's_biblname' => 298,
			'symbol' => 299
		}
	},
	{#State 232
		DEFAULT => -257
	},
	{#State 233
		DEFAULT => -258
	},
	{#State 234
		DEFAULT => -35
	},
	{#State 235
		ACTIONS => {
			'INTEGER' => 301,
			'DATE' => 302
		},
		GOTOS => {
			'date' => 300
		}
	},
	{#State 236
		ACTIONS => {
			"=" => 82,
			'SYMBOL' => 307
		},
		DEFAULT => -107,
		GOTOS => {
			'sym_str' => 306,
			'qfbc_matchref' => 304,
			'matchid_eq' => 83,
			'qfb_ctxkey' => 303,
			'matchid' => 305
		}
	},
	{#State 237
		DEFAULT => -67
	},
	{#State 238
		ACTIONS => {
			'INTEGER' => 133
		},
		GOTOS => {
			'int_str' => 135,
			'integer' => 308
		}
	},
	{#State 239
		DEFAULT => -33
	},
	{#State 240
		DEFAULT => -62
	},
	{#State 241
		ACTIONS => {
			"," => 309
		},
		DEFAULT => -32
	},
	{#State 242
		DEFAULT => -255
	},
	{#State 243
		DEFAULT => -43
	},
	{#State 244
		DEFAULT => -65
	},
	{#State 245
		DEFAULT => -64
	},
	{#State 246
		ACTIONS => {
			"," => 311,
			'INTEGER' => 133,
			"]" => 310
		},
		GOTOS => {
			'int_str' => 312
		}
	},
	{#State 247
		DEFAULT => -69
	},
	{#State 248
		DEFAULT => -72
	},
	{#State 249
		ACTIONS => {
			"," => 314,
			'INTEGER' => 301,
			'DATE' => 302,
			"]" => 313
		},
		GOTOS => {
			'date' => 315
		}
	},
	{#State 250
		DEFAULT => -68
	},
	{#State 251
		DEFAULT => -63
	},
	{#State 252
		ACTIONS => {
			'INTEGER' => 133
		},
		GOTOS => {
			'int_str' => 316
		}
	},
	{#State 253
		DEFAULT => -71
	},
	{#State 254
		ACTIONS => {
			'DATE' => 57,
			'INTEGER' => 21,
			'SYMBOL' => 1
		},
		GOTOS => {
			's_biblname' => 317,
			'symbol' => 299
		}
	},
	{#State 255
		DEFAULT => -41
	},
	{#State 256
		ACTIONS => {
			'HAS_FIELD' => 166,
			"!" => 256
		},
		GOTOS => {
			'qf_has_field' => 258
		}
	},
	{#State 257
		DEFAULT => -39
	},
	{#State 258
		DEFAULT => -59
	},
	{#State 259
		ACTIONS => {
			'INTEGER' => 21,
			'DATE' => 57,
			'SYMBOL' => 1,
			'KW_DATE' => 318
		},
		GOTOS => {
			's_biblname' => 319,
			'symbol' => 299
		}
	},
	{#State 260
		DEFAULT => -66
	},
	{#State 261
		ACTIONS => {
			'SYMBOL' => 1,
			"\$" => 173,
			'INDEX' => 29,
			'DATE' => 57,
			'INTEGER' => 21
		},
		GOTOS => {
			's_index' => 175,
			's_indextuple_item' => 320,
			'symbol' => 174,
			'index' => 24
		}
	},
	{#State 262
		DEFAULT => -204
	},
	{#State 263
		ACTIONS => {
			'EXPANDER' => 129
		},
		DEFAULT => -162,
		GOTOS => {
			's_expander' => 128
		}
	},
	{#State 264
		ACTIONS => {
			'DATE' => 57,
			'INTEGER' => 21,
			'SYMBOL' => 1
		},
		GOTOS => {
			's_semclass' => 321,
			'symbol' => 102
		}
	},
	{#State 265
		DEFAULT => -164
	},
	{#State 266
		ACTIONS => {
			'RBRACE_STAR' => 323,
			"," => 189,
			'SYMBOL' => 1,
			'DATE' => 57,
			'INTEGER' => 21,
			"}" => 322
		},
		GOTOS => {
			's_word' => 187,
			'symbol' => 44
		}
	},
	{#State 267
		ACTIONS => {
			'INTEGER' => 21,
			"}" => 324,
			'DATE' => 57,
			"," => 189,
			'SYMBOL' => 1,
			'RBRACE_STAR' => 325
		},
		GOTOS => {
			's_word' => 187,
			'symbol' => 44
		}
	},
	{#State 268
		DEFAULT => -198
	},
	{#State 269
		DEFAULT => -192
	},
	{#State 270
		DEFAULT => -194
	},
	{#State 271
		ACTIONS => {
			'INTEGER' => 21,
			'DATE' => 57,
			"]" => 326,
			"," => 222,
			'SYMBOL' => 1,
			";" => 225
		},
		GOTOS => {
			'symbol' => 223,
			's_morphitem' => 224
		}
	},
	{#State 272
		ACTIONS => {
			'INTEGER' => 21,
			"}" => 327,
			'DATE' => 57,
			'SYMBOL' => 1,
			"," => 189
		},
		GOTOS => {
			'symbol' => 44,
			's_word' => 187
		}
	},
	{#State 273
		ACTIONS => {
			'EXPANDER' => 129
		},
		DEFAULT => -173,
		GOTOS => {
			's_expander' => 128
		}
	},
	{#State 274
		ACTIONS => {
			'DOLLAR_DOT' => 49,
			'INDEX' => 29,
			"{" => 47,
			"^" => 65,
			'SUFFIX' => 3,
			'COLON_LBRACE' => 38,
			"\$" => 26,
			'SYMBOL' => 1,
			'INFIX' => 23,
			'REGEX' => 2,
			"\@" => 37,
			'NEG_REGEX' => 61,
			'INTEGER' => 21,
			"%" => 58,
			'DATE' => 57,
			"(" => 107,
			'AT_LBRACE' => 71,
			'STAR_LBRACE' => 36,
			"*" => 17,
			"[" => 70,
			'PREFIX' => 55,
			'KEYS' => 8,
			"<" => 52
		},
		GOTOS => {
			's_word' => 11,
			'qw_withor' => 12,
			'qwk_indextuple' => 9,
			'qw_infix' => 53,
			'qw_any' => 20,
			'qw_with' => 16,
			'qw_bareword' => 22,
			'qw_keys' => 62,
			'qw_regex' => 60,
			's_prefix' => 56,
			'qw_prefix_set' => 4,
			'qw_chunk' => 5,
			'qw_lemma' => 42,
			'qw_set_exact' => 43,
			'qw_exact' => 41,
			'qw_anchor' => 40,
			's_infix' => 6,
			's_index' => 39,
			'qw_suffix_set' => 46,
			'qw_matchid' => 45,
			'symbol' => 44,
			'qw_thesaurus' => 7,
			'qw_prefix' => 50,
			'qw_without' => 30,
			'neg_regex' => 68,
			'qw_suffix' => 69,
			'qc_word' => 328,
			'qw_listfile' => 32,
			'qw_morph' => 31,
			'qw_set_infl' => 34,
			'qw_infix_set' => 72,
			'index' => 24,
			'regex' => 28,
			's_suffix' => 67
		}
	},
	{#State 275
		ACTIONS => {
			"{" => 47,
			'INDEX' => 29,
			'DOLLAR_DOT' => 49,
			'REGEX' => 2,
			'INFIX' => 23,
			'SYMBOL' => 1,
			"\$" => 26,
			'COLON_LBRACE' => 38,
			'SUFFIX' => 3,
			"^" => 65,
			"*" => 17,
			'STAR_LBRACE' => 36,
			'AT_LBRACE' => 71,
			"(" => 107,
			'DATE' => 57,
			"%" => 58,
			'INTEGER' => 21,
			'NEG_REGEX' => 61,
			"\@" => 37,
			'KEYS' => 8,
			"<" => 52,
			'PREFIX' => 55,
			"[" => 70
		},
		GOTOS => {
			's_prefix' => 56,
			'qw_keys' => 62,
			'qw_bareword' => 22,
			'qw_regex' => 60,
			'qw_with' => 16,
			'qw_any' => 20,
			'qw_infix' => 53,
			'qwk_indextuple' => 9,
			's_word' => 11,
			'qw_withor' => 12,
			'qw_prefix' => 50,
			'qw_suffix_set' => 46,
			'qw_matchid' => 45,
			'symbol' => 44,
			'qw_thesaurus' => 7,
			'qw_anchor' => 40,
			's_infix' => 6,
			's_index' => 39,
			'qw_set_exact' => 43,
			'qw_exact' => 41,
			'qw_lemma' => 42,
			'qw_prefix_set' => 4,
			'qw_chunk' => 5,
			'qw_infix_set' => 72,
			'qw_set_infl' => 34,
			'qw_listfile' => 32,
			'qw_morph' => 31,
			'qc_word' => 329,
			'neg_regex' => 68,
			'qw_without' => 30,
			'qw_suffix' => 69,
			's_suffix' => 67,
			'regex' => 28,
			'index' => 24
		}
	},
	{#State 276
		ACTIONS => {
			'INDEX' => 29,
			'DOLLAR_DOT' => 49,
			"{" => 47,
			"^" => 65,
			'REGEX' => 2,
			'INFIX' => 23,
			'SYMBOL' => 1,
			'COLON_LBRACE' => 38,
			"\$" => 26,
			'SUFFIX' => 3,
			"%" => 58,
			'DATE' => 57,
			'INTEGER' => 21,
			"\@" => 37,
			'NEG_REGEX' => 61,
			"*" => 17,
			'STAR_LBRACE' => 36,
			'AT_LBRACE' => 71,
			"(" => 107,
			'PREFIX' => 55,
			"[" => 70,
			'KEYS' => 8,
			"<" => 52
		},
		GOTOS => {
			'index' => 24,
			'regex' => 28,
			's_suffix' => 67,
			'neg_regex' => 68,
			'qw_without' => 30,
			'qw_suffix' => 69,
			'qw_listfile' => 32,
			'qw_morph' => 31,
			'qc_word' => 330,
			'qw_set_infl' => 34,
			'qw_infix_set' => 72,
			'qw_prefix_set' => 4,
			'qw_chunk' => 5,
			'qw_anchor' => 40,
			's_index' => 39,
			's_infix' => 6,
			'qw_set_exact' => 43,
			'qw_exact' => 41,
			'qw_lemma' => 42,
			'symbol' => 44,
			'qw_suffix_set' => 46,
			'qw_matchid' => 45,
			'qw_thesaurus' => 7,
			'qw_prefix' => 50,
			'qwk_indextuple' => 9,
			'qw_withor' => 12,
			's_word' => 11,
			'qw_infix' => 53,
			'qw_with' => 16,
			'qw_any' => 20,
			's_prefix' => 56,
			'qw_keys' => 62,
			'qw_bareword' => 22,
			'qw_regex' => 60
		}
	},
	{#State 277
		ACTIONS => {
			'DOLLAR_DOT' => 49,
			'INDEX' => 29,
			"{" => 47,
			"^" => 65,
			'SUFFIX' => 3,
			"\$" => 26,
			'COLON_LBRACE' => 38,
			'INFIX' => 23,
			'SYMBOL' => 1,
			'REGEX' => 2,
			'NEG_REGEX' => 61,
			"\@" => 37,
			'INTEGER' => 21,
			'DATE' => 57,
			"%" => 58,
			'AT_LBRACE' => 71,
			"(" => 107,
			'STAR_LBRACE' => 36,
			"*" => 17,
			"[" => 70,
			'PREFIX' => 55,
			'KEYS' => 8,
			"<" => 52
		},
		GOTOS => {
			'index' => 24,
			's_suffix' => 67,
			'regex' => 28,
			'qw_morph' => 31,
			'qw_listfile' => 32,
			'qc_word' => 331,
			'qw_without' => 30,
			'neg_regex' => 68,
			'qw_suffix' => 69,
			'qw_infix_set' => 72,
			'qw_set_infl' => 34,
			's_index' => 39,
			's_infix' => 6,
			'qw_anchor' => 40,
			'qw_exact' => 41,
			'qw_set_exact' => 43,
			'qw_lemma' => 42,
			'qw_chunk' => 5,
			'qw_prefix_set' => 4,
			'qw_prefix' => 50,
			'qw_thesaurus' => 7,
			'qw_suffix_set' => 46,
			'symbol' => 44,
			'qw_matchid' => 45,
			'qw_infix' => 53,
			'qwk_indextuple' => 9,
			's_word' => 11,
			'qw_withor' => 12,
			's_prefix' => 56,
			'qw_regex' => 60,
			'qw_keys' => 62,
			'qw_bareword' => 22,
			'qw_with' => 16,
			'qw_any' => 20
		}
	},
	{#State 278
		DEFAULT => -196
	},
	{#State 279
		ACTIONS => {
			"{" => 47,
			"\"" => 48,
			'DOLLAR_DOT' => 49,
			'INDEX' => 29,
			'SUFFIX' => 3,
			"\$" => 26,
			'COLON_LBRACE' => 38,
			'SYMBOL' => 1,
			'INFIX' => 23,
			'REGEX' => 2,
			"^" => 65,
			'AT_LBRACE' => 71,
			"(" => 218,
			'STAR_LBRACE' => 36,
			"*" => 17,
			"\@" => 37,
			'NEG_REGEX' => 61,
			'INTEGER' => 21,
			"%" => 58,
			'DATE' => 57,
			'KEYS' => 8,
			"<" => 52,
			"[" => 70,
			'PREFIX' => 55
		},
		GOTOS => {
			'qw_thesaurus' => 7,
			'qw_suffix_set' => 46,
			'symbol' => 44,
			'qw_matchid' => 45,
			'qw_prefix' => 50,
			'qw_chunk' => 5,
			'qw_prefix_set' => 4,
			's_infix' => 6,
			's_index' => 39,
			'qw_anchor' => 40,
			'qw_set_exact' => 43,
			'qw_lemma' => 42,
			'qw_exact' => 41,
			'qw_with' => 16,
			'qw_any' => 20,
			's_prefix' => 56,
			'qw_regex' => 60,
			'qw_keys' => 62,
			'qw_bareword' => 22,
			'qc_tokens' => 332,
			'qwk_indextuple' => 9,
			'qw_withor' => 12,
			's_word' => 11,
			'qw_infix' => 53,
			'regex' => 28,
			's_suffix' => 67,
			'index' => 24,
			'qc_phrase' => 27,
			'qw_set_infl' => 34,
			'qw_infix_set' => 72,
			'qw_suffix' => 69,
			'neg_regex' => 68,
			'qw_without' => 30,
			'qw_morph' => 31,
			'qw_listfile' => 32,
			'qc_word' => 33
		}
	},
	{#State 280
		ACTIONS => {
			'CLIMIT' => 290,
			'BY' => 282,
			'GREATER_BY_COUNT' => 284,
			'SAMPLE' => 287,
			")" => 333,
			'GREATER_BY_KEY' => 285,
			'LESS_BY_KEY' => 288,
			'LESS_BY_COUNT' => 291
		},
		GOTOS => {
			'count_sample' => 283,
			'count_limit' => 289,
			'count_sort' => 286,
			'count_sort_op' => 281,
			'count_filter' => 293,
			'count_by' => 292
		}
	},
	{#State 281
		ACTIONS => {
			"[" => 335
		},
		DEFAULT => -21,
		GOTOS => {
			'count_sort_minmax' => 334
		}
	},
	{#State 282
		ACTIONS => {
			'SYMBOL' => 1,
			'KW_DATE' => 337,
			"\$" => 173,
			'INDEX' => 29,
			'KW_FILENAME' => 343,
			'KW_FILEID' => 345,
			"[" => 346,
			"*" => 336,
			"(" => 338,
			'DATE' => 57,
			'INTEGER' => 21,
			"\@" => 341
		},
		DEFAULT => -223,
		GOTOS => {
			'index' => 24,
			'symbol' => 299,
			's_biblname' => 339,
			'l_countkeys' => 340,
			's_index' => 344,
			'count_key' => 342
		}
	},
	{#State 283
		DEFAULT => -7
	},
	{#State 284
		DEFAULT => -20
	},
	{#State 285
		DEFAULT => -18
	},
	{#State 286
		DEFAULT => -9
	},
	{#State 287
		ACTIONS => {
			'INTEGER' => 133,
			"[" => 347
		},
		GOTOS => {
			'integer' => 348,
			'int_str' => 135
		}
	},
	{#State 288
		DEFAULT => -17
	},
	{#State 289
		DEFAULT => -8
	},
	{#State 290
		ACTIONS => {
			"[" => 350,
			'INTEGER' => 133
		},
		GOTOS => {
			'integer' => 349,
			'int_str' => 135
		}
	},
	{#State 291
		DEFAULT => -19
	},
	{#State 292
		DEFAULT => -6
	},
	{#State 293
		DEFAULT => -5
	},
	{#State 294
		ACTIONS => {
			")" => 351
		}
	},
	{#State 295
		ACTIONS => {
			"]" => 352
		}
	},
	{#State 296
		DEFAULT => -75
	},
	{#State 297
		ACTIONS => {
			"," => 354
		},
		DEFAULT => -94,
		GOTOS => {
			'qfb_bibl_ne' => 353,
			'qfb_bibl' => 355
		}
	},
	{#State 298
		ACTIONS => {
			"," => 354
		},
		DEFAULT => -94,
		GOTOS => {
			'qfb_bibl_ne' => 353,
			'qfb_bibl' => 356
		}
	},
	{#State 299
		DEFAULT => -256
	},
	{#State 300
		ACTIONS => {
			"]" => 357
		}
	},
	{#State 301
		DEFAULT => -278
	},
	{#State 302
		DEFAULT => -277
	},
	{#State 303
		ACTIONS => {
			"," => 354,
			"]" => 359
		},
		GOTOS => {
			'qfb_bibl_ne' => 358
		}
	},
	{#State 304
		ACTIONS => {
			"-" => 363,
			'INTEGER' => 133,
			"+" => 360
		},
		DEFAULT => -109,
		GOTOS => {
			'integer' => 362,
			'qfbc_offset' => 361,
			'int_str' => 135
		}
	},
	{#State 305
		DEFAULT => -108
	},
	{#State 306
		ACTIONS => {
			"=" => 82
		},
		DEFAULT => -107,
		GOTOS => {
			'matchid' => 305,
			'qfbc_matchref' => 364,
			'matchid_eq' => 83
		}
	},
	{#State 307
		DEFAULT => -264
	},
	{#State 308
		ACTIONS => {
			"]" => 365
		}
	},
	{#State 309
		ACTIONS => {
			'DATE' => 57,
			'INTEGER' => 21,
			'SYMBOL' => 1
		},
		GOTOS => {
			'symbol' => 242,
			's_subcorpus' => 366
		}
	},
	{#State 310
		DEFAULT => -82
	},
	{#State 311
		ACTIONS => {
			"]" => 368,
			'INTEGER' => 133
		},
		GOTOS => {
			'int_str' => 367
		}
	},
	{#State 312
		ACTIONS => {
			"]" => 370,
			"," => 369
		}
	},
	{#State 313
		DEFAULT => -89
	},
	{#State 314
		ACTIONS => {
			'DATE' => 302,
			'INTEGER' => 301
		},
		GOTOS => {
			'date' => 371
		}
	},
	{#State 315
		ACTIONS => {
			"," => 373,
			"]" => 372
		}
	},
	{#State 316
		ACTIONS => {
			"]" => 374
		}
	},
	{#State 317
		ACTIONS => {
			"," => 375
		}
	},
	{#State 318
		ACTIONS => {
			"," => 354
		},
		DEFAULT => -94,
		GOTOS => {
			'qfb_bibl_ne' => 353,
			'qfb_bibl' => 376
		}
	},
	{#State 319
		ACTIONS => {
			"," => 354
		},
		DEFAULT => -94,
		GOTOS => {
			'qfb_bibl' => 377,
			'qfb_bibl_ne' => 353
		}
	},
	{#State 320
		DEFAULT => -228
	},
	{#State 321
		ACTIONS => {
			"}" => 378
		}
	},
	{#State 322
		DEFAULT => -186
	},
	{#State 323
		DEFAULT => -182
	},
	{#State 324
		DEFAULT => -221,
		GOTOS => {
			'l_txchain' => 379
		}
	},
	{#State 325
		DEFAULT => -184
	},
	{#State 326
		DEFAULT => -190
	},
	{#State 327
		DEFAULT => -172
	},
	{#State 328
		ACTIONS => {
			'WITH' => 91,
			'WITHOR' => 89,
			'WITHOUT' => 92,
			"=" => 82
		},
		DEFAULT => -217,
		GOTOS => {
			'matchid_eq' => 83,
			'matchid' => 90
		}
	},
	{#State 329
		ACTIONS => {
			"=" => 82,
			'WITH' => 91,
			'WITHOR' => 89,
			'WITHOUT' => 92
		},
		DEFAULT => -218,
		GOTOS => {
			'matchid' => 90,
			'matchid_eq' => 83
		}
	},
	{#State 330
		ACTIONS => {
			'WITHOR' => 89,
			'WITH' => 91,
			'WITHOUT' => 92,
			"=" => 82
		},
		DEFAULT => -220,
		GOTOS => {
			'matchid_eq' => 83,
			'matchid' => 90
		}
	},
	{#State 331
		ACTIONS => {
			"=" => 82,
			'WITHOUT' => 92,
			'WITHOR' => 89,
			'WITH' => 91
		},
		DEFAULT => -219,
		GOTOS => {
			'matchid' => 90,
			'matchid_eq' => 83
		}
	},
	{#State 332
		ACTIONS => {
			"," => 380,
			"=" => 82
		},
		GOTOS => {
			'matchid' => 111,
			'matchid_eq' => 83
		}
	},
	{#State 333
		DEFAULT => -4,
		GOTOS => {
			'count_filters' => 381
		}
	},
	{#State 334
		DEFAULT => -16
	},
	{#State 335
		ACTIONS => {
			"," => 383,
			'SYMBOL' => 1,
			"]" => 382,
			'DATE' => 57,
			'INTEGER' => 21
		},
		GOTOS => {
			'symbol' => 384
		}
	},
	{#State 336
		DEFAULT => -229
	},
	{#State 337
		ACTIONS => {
			"/" => 385
		},
		DEFAULT => -233
	},
	{#State 338
		ACTIONS => {
			'KW_FILEID' => 345,
			"\$" => 173,
			'KW_DATE' => 337,
			'SYMBOL' => 1,
			"\@" => 341,
			'KW_FILENAME' => 343,
			'INTEGER' => 21,
			'DATE' => 57,
			'INDEX' => 29,
			"(" => 338,
			"*" => 336
		},
		GOTOS => {
			's_biblname' => 339,
			'symbol' => 299,
			'index' => 24,
			'count_key' => 386,
			's_index' => 344
		}
	},
	{#State 339
		DEFAULT => -235
	},
	{#State 340
		ACTIONS => {
			"," => 387
		},
		DEFAULT => -10
	},
	{#State 341
		ACTIONS => {
			'SYMBOL' => 1,
			'DATE' => 57,
			'INTEGER' => 21
		},
		GOTOS => {
			'symbol' => 388
		}
	},
	{#State 342
		ACTIONS => {
			"~" => 389
		},
		DEFAULT => -224
	},
	{#State 343
		DEFAULT => -232
	},
	{#State 344
		ACTIONS => {
			"=" => 82
		},
		DEFAULT => -239,
		GOTOS => {
			'matchid_eq' => 83,
			'matchid' => 391,
			'ck_matchid' => 390
		}
	},
	{#State 345
		DEFAULT => -231
	},
	{#State 346
		ACTIONS => {
			'KW_FILEID' => 345,
			'KW_DATE' => 337,
			"\$" => 173,
			'SYMBOL' => 1,
			"\@" => 341,
			'KW_FILENAME' => 343,
			'INTEGER' => 21,
			'INDEX' => 29,
			'DATE' => 57,
			"(" => 338,
			"*" => 336
		},
		DEFAULT => -223,
		GOTOS => {
			'count_key' => 342,
			's_index' => 344,
			'l_countkeys' => 392,
			's_biblname' => 339,
			'symbol' => 299,
			'index' => 24
		}
	},
	{#State 347
		ACTIONS => {
			'INTEGER' => 133
		},
		GOTOS => {
			'integer' => 393,
			'int_str' => 135
		}
	},
	{#State 348
		DEFAULT => -12
	},
	{#State 349
		DEFAULT => -14
	},
	{#State 350
		ACTIONS => {
			'INTEGER' => 133
		},
		GOTOS => {
			'int_str' => 135,
			'integer' => 394
		}
	},
	{#State 351
		DEFAULT => -203
	},
	{#State 352
		DEFAULT => -76
	},
	{#State 353
		DEFAULT => -95
	},
	{#State 354
		ACTIONS => {
			'INTEGER' => 21,
			'DATE' => 57,
			"," => 395,
			'SYMBOL' => 1
		},
		DEFAULT => -96,
		GOTOS => {
			'symbol' => 396
		}
	},
	{#State 355
		ACTIONS => {
			"]" => 397
		}
	},
	{#State 356
		ACTIONS => {
			"]" => 398
		}
	},
	{#State 357
		DEFAULT => -73
	},
	{#State 358
		ACTIONS => {
			"]" => 399
		}
	},
	{#State 359
		DEFAULT => -103
	},
	{#State 360
		ACTIONS => {
			'INTEGER' => 133
		},
		GOTOS => {
			'integer' => 400,
			'int_str' => 135
		}
	},
	{#State 361
		DEFAULT => -106
	},
	{#State 362
		DEFAULT => -110
	},
	{#State 363
		ACTIONS => {
			'INTEGER' => 133
		},
		GOTOS => {
			'integer' => 401,
			'int_str' => 135
		}
	},
	{#State 364
		ACTIONS => {
			'INTEGER' => 133,
			"-" => 363,
			"+" => 360
		},
		DEFAULT => -109,
		GOTOS => {
			'integer' => 362,
			'qfbc_offset' => 402,
			'int_str' => 135
		}
	},
	{#State 365
		DEFAULT => -34
	},
	{#State 366
		DEFAULT => -44
	},
	{#State 367
		ACTIONS => {
			"]" => 403
		}
	},
	{#State 368
		DEFAULT => -83
	},
	{#State 369
		ACTIONS => {
			'INTEGER' => 133,
			"]" => 405
		},
		GOTOS => {
			'int_str' => 404
		}
	},
	{#State 370
		DEFAULT => -84
	},
	{#State 371
		ACTIONS => {
			"]" => 406
		}
	},
	{#State 372
		DEFAULT => -90
	},
	{#State 373
		ACTIONS => {
			'INTEGER' => 301,
			'DATE' => 302,
			"]" => 408
		},
		GOTOS => {
			'date' => 407
		}
	},
	{#State 374
		DEFAULT => -70
	},
	{#State 375
		ACTIONS => {
			"{" => 412,
			'NEG_REGEX' => 61,
			'INTEGER' => 21,
			'DATE' => 57,
			'SUFFIX' => 3,
			'SYMBOL' => 1,
			'INFIX' => 23,
			'REGEX' => 2,
			'PREFIX' => 55
		},
		GOTOS => {
			's_infix' => 409,
			's_prefix' => 413,
			's_suffix' => 414,
			'regex' => 410,
			'symbol' => 411,
			'neg_regex' => 415
		}
	},
	{#State 376
		ACTIONS => {
			"]" => 416
		}
	},
	{#State 377
		ACTIONS => {
			"]" => 417
		}
	},
	{#State 378
		DEFAULT => -188
	},
	{#State 379
		ACTIONS => {
			'EXPANDER' => 129
		},
		DEFAULT => -174,
		GOTOS => {
			's_expander' => 128
		}
	},
	{#State 380
		ACTIONS => {
			'PREFIX' => 55,
			"[" => 70,
			"<" => 52,
			'KEYS' => 8,
			'INTEGER' => 420,
			"%" => 58,
			'DATE' => 57,
			"\@" => 37,
			'NEG_REGEX' => 61,
			"*" => 17,
			"(" => 218,
			'AT_LBRACE' => 71,
			'STAR_LBRACE' => 36,
			"^" => 65,
			'SYMBOL' => 1,
			'INFIX' => 23,
			'REGEX' => 2,
			'SUFFIX' => 3,
			"\$" => 26,
			'COLON_LBRACE' => 38,
			'DOLLAR_DOT' => 49,
			'INDEX' => 29,
			"\"" => 48,
			"{" => 47
		},
		GOTOS => {
			's_prefix' => 56,
			'qw_keys' => 62,
			'qw_bareword' => 22,
			'qw_regex' => 60,
			'qw_with' => 16,
			'qw_any' => 20,
			'qw_infix' => 53,
			'qwk_indextuple' => 9,
			'qc_tokens' => 418,
			'qw_withor' => 12,
			's_word' => 11,
			'qw_prefix' => 50,
			'symbol' => 44,
			'qw_matchid' => 45,
			'qw_suffix_set' => 46,
			'qw_thesaurus' => 7,
			'qw_anchor' => 40,
			's_index' => 39,
			's_infix' => 6,
			'int_str' => 135,
			'qw_exact' => 41,
			'qw_set_exact' => 43,
			'qw_lemma' => 42,
			'qw_chunk' => 5,
			'qw_prefix_set' => 4,
			'qw_infix_set' => 72,
			'qw_set_infl' => 34,
			'qw_listfile' => 32,
			'qw_morph' => 31,
			'qc_word' => 33,
			'neg_regex' => 68,
			'qw_suffix' => 69,
			'qw_without' => 30,
			's_suffix' => 67,
			'regex' => 28,
			'qc_phrase' => 27,
			'integer' => 419,
			'index' => 24
		}
	},
	{#State 381
		ACTIONS => {
			'CLIMIT' => 290,
			'SAMPLE' => 287,
			'BY' => 282,
			'GREATER_BY_COUNT' => 284,
			'LESS_BY_KEY' => 288,
			'GREATER_BY_KEY' => 285,
			'LESS_BY_COUNT' => 291
		},
		DEFAULT => -3,
		GOTOS => {
			'count_sort' => 286,
			'count_limit' => 289,
			'count_sample' => 283,
			'count_by' => 292,
			'count_filter' => 293,
			'count_sort_op' => 281
		}
	},
	{#State 382
		DEFAULT => -22
	},
	{#State 383
		ACTIONS => {
			'SYMBOL' => 1,
			'DATE' => 57,
			'INTEGER' => 21,
			"]" => 422
		},
		GOTOS => {
			'symbol' => 421
		}
	},
	{#State 384
		ACTIONS => {
			"," => 423,
			"]" => 424
		}
	},
	{#State 385
		ACTIONS => {
			'INTEGER' => 133
		},
		GOTOS => {
			'int_str' => 135,
			'integer' => 425
		}
	},
	{#State 386
		ACTIONS => {
			")" => 426,
			"~" => 389
		}
	},
	{#State 387
		ACTIONS => {
			"*" => 336,
			"(" => 338,
			'INTEGER' => 21,
			'INDEX' => 29,
			'DATE' => 57,
			"\@" => 341,
			'KW_FILENAME' => 343,
			'SYMBOL' => 1,
			'KW_FILEID' => 345,
			"\$" => 173,
			'KW_DATE' => 337
		},
		GOTOS => {
			'index' => 24,
			'symbol' => 299,
			's_biblname' => 339,
			's_index' => 344,
			'count_key' => 427
		}
	},
	{#State 388
		DEFAULT => -230
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
			"-" => 430,
			"+" => 432,
			'INTEGER' => 133
		},
		DEFAULT => -241,
		GOTOS => {
			'int_str' => 135,
			'integer' => 433,
			'ck_offset' => 431
		}
	},
	{#State 391
		DEFAULT => -240
	},
	{#State 392
		ACTIONS => {
			"]" => 434,
			"," => 387
		}
	},
	{#State 393
		ACTIONS => {
			"]" => 435
		}
	},
	{#State 394
		ACTIONS => {
			"]" => 436
		}
	},
	{#State 395
		ACTIONS => {
			'DATE' => 57,
			'INTEGER' => 21,
			'SYMBOL' => 1
		},
		DEFAULT => -97,
		GOTOS => {
			'symbol' => 437
		}
	},
	{#State 396
		ACTIONS => {
			"," => 438
		},
		DEFAULT => -98
	},
	{#State 397
		DEFAULT => -77
	},
	{#State 398
		DEFAULT => -79
	},
	{#State 399
		DEFAULT => -104
	},
	{#State 400
		DEFAULT => -111
	},
	{#State 401
		DEFAULT => -112
	},
	{#State 402
		DEFAULT => -105
	},
	{#State 403
		DEFAULT => -87
	},
	{#State 404
		ACTIONS => {
			"]" => 439
		}
	},
	{#State 405
		DEFAULT => -85
	},
	{#State 406
		DEFAULT => -93
	},
	{#State 407
		ACTIONS => {
			"]" => 440
		}
	},
	{#State 408
		DEFAULT => -91
	},
	{#State 409
		ACTIONS => {
			"]" => 441
		}
	},
	{#State 410
		ACTIONS => {
			"]" => 442
		}
	},
	{#State 411
		ACTIONS => {
			"]" => 443
		}
	},
	{#State 412
		DEFAULT => -208,
		GOTOS => {
			'l_set' => 444
		}
	},
	{#State 413
		ACTIONS => {
			"]" => 445
		}
	},
	{#State 414
		ACTIONS => {
			"]" => 446
		}
	},
	{#State 415
		ACTIONS => {
			"]" => 447
		}
	},
	{#State 416
		DEFAULT => -78
	},
	{#State 417
		DEFAULT => -80
	},
	{#State 418
		ACTIONS => {
			"," => 448,
			"=" => 82
		},
		GOTOS => {
			'matchid_eq' => 83,
			'matchid' => 111
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
			"]" => 450
		}
	},
	{#State 422
		DEFAULT => -23
	},
	{#State 423
		ACTIONS => {
			'SYMBOL' => 1,
			'INTEGER' => 21,
			'DATE' => 57,
			"]" => 451
		},
		GOTOS => {
			'symbol' => 452
		}
	},
	{#State 424
		DEFAULT => -24
	},
	{#State 425
		DEFAULT => -234
	},
	{#State 426
		DEFAULT => -238
	},
	{#State 427
		ACTIONS => {
			"~" => 389
		},
		DEFAULT => -225
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
		ACTIONS => {
			'INTEGER' => 133
		},
		GOTOS => {
			'integer' => 454,
			'int_str' => 135
		}
	},
	{#State 431
		DEFAULT => -236
	},
	{#State 432
		ACTIONS => {
			'INTEGER' => 133
		},
		GOTOS => {
			'int_str' => 135,
			'integer' => 455
		}
	},
	{#State 433
		DEFAULT => -242
	},
	{#State 434
		DEFAULT => -11
	},
	{#State 435
		DEFAULT => -13
	},
	{#State 436
		DEFAULT => -15
	},
	{#State 437
		DEFAULT => -100
	},
	{#State 438
		ACTIONS => {
			'SYMBOL' => 1,
			'INTEGER' => 21,
			'DATE' => 57
		},
		DEFAULT => -99,
		GOTOS => {
			'symbol' => 456
		}
	},
	{#State 439
		DEFAULT => -86
	},
	{#State 440
		DEFAULT => -92
	},
	{#State 441
		DEFAULT => -57
	},
	{#State 442
		DEFAULT => -53
	},
	{#State 443
		DEFAULT => -52
	},
	{#State 444
		ACTIONS => {
			'INTEGER' => 21,
			"}" => 457,
			'DATE' => 57,
			'SYMBOL' => 1,
			"," => 189
		},
		GOTOS => {
			's_word' => 187,
			'symbol' => 44
		}
	},
	{#State 445
		DEFAULT => -55
	},
	{#State 446
		DEFAULT => -56
	},
	{#State 447
		DEFAULT => -54
	},
	{#State 448
		ACTIONS => {
			'INTEGER' => 133
		},
		GOTOS => {
			'int_str' => 135,
			'integer' => 458
		}
	},
	{#State 449
		DEFAULT => -128
	},
	{#State 450
		DEFAULT => -26
	},
	{#State 451
		DEFAULT => -25
	},
	{#State 452
		ACTIONS => {
			"]" => 459
		}
	},
	{#State 453
		ACTIONS => {
			'REGOPT' => 460
		},
		DEFAULT => -273
	},
	{#State 454
		DEFAULT => -244
	},
	{#State 455
		DEFAULT => -243
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
{ $_[0]->newq('CQAndImplicit', $_[1],$_[2]) }
	],
	[#Rule 124
		 'qc_concat', 2,
sub
#line 361 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQAndImplicit', $_[1],$_[2]) }
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
