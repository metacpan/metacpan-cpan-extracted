####################################################################
#
#    This file was generated using Parse::Yapp version 1.21.
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

    my($self)=$class->SUPER::new( yyversion => '1.21',
                                  yystates =>
[
	{#State 0
		ACTIONS => {
			"!" => 1,
			"\"" => 2,
			"\$" => 3,
			"%" => 4,
			"(" => 5,
			"*" => 6,
			"<" => 7,
			"\@" => 8,
			"[" => 9,
			"^" => 10,
			"{" => 11,
			'AT_LBRACE' => 12,
			'COLON_LBRACE' => 13,
			'COUNT' => 14,
			'DATE' => 15,
			'DOLLAR_DOT' => 16,
			'INDEX' => 17,
			'INFIX' => 18,
			'INTEGER' => 19,
			'KEYS' => 20,
			'NEAR' => 21,
			'NEG_REGEX' => 22,
			'PREFIX' => 23,
			'REGEX' => 24,
			'STAR_LBRACE' => 25,
			'SUFFIX' => 26,
			'SYMBOL' => 27
		},
		GOTOS => {
			'count_query' => 28,
			'index' => 29,
			'neg_regex' => 30,
			'q_clause' => 31,
			'qc_basic' => 32,
			'qc_boolean' => 33,
			'qc_concat' => 34,
			'qc_matchid' => 35,
			'qc_near' => 36,
			'qc_phrase' => 37,
			'qc_tokens' => 38,
			'qc_word' => 39,
			'query' => 40,
			'query_conditions' => 41,
			'qw_anchor' => 42,
			'qw_any' => 43,
			'qw_bareword' => 44,
			'qw_chunk' => 45,
			'qw_exact' => 46,
			'qw_infix' => 47,
			'qw_infix_set' => 48,
			'qw_keys' => 49,
			'qw_lemma' => 50,
			'qw_listfile' => 51,
			'qw_matchid' => 52,
			'qw_morph' => 53,
			'qw_prefix' => 54,
			'qw_prefix_set' => 55,
			'qw_regex' => 56,
			'qw_set_exact' => 57,
			'qw_set_infl' => 58,
			'qw_suffix' => 59,
			'qw_suffix_set' => 60,
			'qw_thesaurus' => 61,
			'qw_with' => 62,
			'qw_withor' => 63,
			'qw_without' => 64,
			'qwk_indextuple' => 65,
			'regex' => 66,
			's_index' => 67,
			's_infix' => 68,
			's_prefix' => 69,
			's_suffix' => 70,
			's_word' => 71,
			'symbol' => 72
		}
	},
	{#State 1
		ACTIONS => {
			"!" => 1,
			"\"" => 2,
			"\$" => 3,
			"%" => 4,
			"(" => 5,
			"*" => 6,
			"<" => 7,
			"\@" => 8,
			"[" => 9,
			"^" => 10,
			"{" => 11,
			'AT_LBRACE' => 12,
			'COLON_LBRACE' => 13,
			'DATE' => 15,
			'DOLLAR_DOT' => 16,
			'INDEX' => 17,
			'INFIX' => 18,
			'INTEGER' => 19,
			'KEYS' => 20,
			'NEAR' => 21,
			'NEG_REGEX' => 22,
			'PREFIX' => 23,
			'REGEX' => 24,
			'STAR_LBRACE' => 25,
			'SUFFIX' => 26,
			'SYMBOL' => 27
		},
		GOTOS => {
			'index' => 29,
			'neg_regex' => 30,
			'q_clause' => 73,
			'qc_basic' => 32,
			'qc_boolean' => 33,
			'qc_concat' => 34,
			'qc_matchid' => 35,
			'qc_near' => 36,
			'qc_phrase' => 37,
			'qc_tokens' => 38,
			'qc_word' => 39,
			'qw_anchor' => 42,
			'qw_any' => 43,
			'qw_bareword' => 44,
			'qw_chunk' => 45,
			'qw_exact' => 46,
			'qw_infix' => 47,
			'qw_infix_set' => 48,
			'qw_keys' => 49,
			'qw_lemma' => 50,
			'qw_listfile' => 51,
			'qw_matchid' => 52,
			'qw_morph' => 53,
			'qw_prefix' => 54,
			'qw_prefix_set' => 55,
			'qw_regex' => 56,
			'qw_set_exact' => 57,
			'qw_set_infl' => 58,
			'qw_suffix' => 59,
			'qw_suffix_set' => 60,
			'qw_thesaurus' => 61,
			'qw_with' => 62,
			'qw_withor' => 63,
			'qw_without' => 64,
			'qwk_indextuple' => 65,
			'regex' => 66,
			's_index' => 67,
			's_infix' => 68,
			's_prefix' => 69,
			's_suffix' => 70,
			's_word' => 71,
			'symbol' => 72
		}
	},
	{#State 2
		ACTIONS => {
			"\$" => 3,
			"%" => 4,
			"(" => 74,
			"*" => 6,
			"<" => 7,
			"\@" => 8,
			"[" => 9,
			"^" => 10,
			"{" => 11,
			'AT_LBRACE' => 12,
			'COLON_LBRACE' => 13,
			'DATE' => 15,
			'DOLLAR_DOT' => 16,
			'INDEX' => 17,
			'INFIX' => 18,
			'INTEGER' => 19,
			'KEYS' => 20,
			'NEG_REGEX' => 22,
			'PREFIX' => 23,
			'REGEX' => 24,
			'STAR_LBRACE' => 25,
			'SUFFIX' => 26,
			'SYMBOL' => 27
		},
		GOTOS => {
			'index' => 29,
			'l_phrase' => 75,
			'neg_regex' => 30,
			'qc_word' => 76,
			'qw_anchor' => 42,
			'qw_any' => 43,
			'qw_bareword' => 44,
			'qw_chunk' => 45,
			'qw_exact' => 46,
			'qw_infix' => 47,
			'qw_infix_set' => 48,
			'qw_keys' => 49,
			'qw_lemma' => 50,
			'qw_listfile' => 51,
			'qw_matchid' => 52,
			'qw_morph' => 53,
			'qw_prefix' => 54,
			'qw_prefix_set' => 55,
			'qw_regex' => 56,
			'qw_set_exact' => 57,
			'qw_set_infl' => 58,
			'qw_suffix' => 59,
			'qw_suffix_set' => 60,
			'qw_thesaurus' => 61,
			'qw_with' => 62,
			'qw_withor' => 63,
			'qw_without' => 64,
			'qwk_indextuple' => 65,
			'regex' => 66,
			's_index' => 67,
			's_infix' => 68,
			's_prefix' => 69,
			's_suffix' => 70,
			's_word' => 71,
			'symbol' => 72
		}
	},
	{#State 3
		ACTIONS => {
			"(" => 77
		},
		DEFAULT => -265
	},
	{#State 4
		ACTIONS => {
			'DATE' => 15,
			'INTEGER' => 19,
			'SYMBOL' => 27
		},
		GOTOS => {
			's_lemma' => 78,
			'symbol' => 79
		}
	},
	{#State 5
		ACTIONS => {
			"!" => 1,
			"\"" => 2,
			"\$" => 3,
			"%" => 4,
			"(" => 5,
			"*" => 6,
			"<" => 7,
			"\@" => 8,
			"[" => 9,
			"^" => 10,
			"{" => 11,
			'AT_LBRACE' => 12,
			'COLON_LBRACE' => 13,
			'DATE' => 15,
			'DOLLAR_DOT' => 16,
			'INDEX' => 17,
			'INFIX' => 18,
			'INTEGER' => 19,
			'KEYS' => 20,
			'NEAR' => 21,
			'NEG_REGEX' => 22,
			'PREFIX' => 23,
			'REGEX' => 24,
			'STAR_LBRACE' => 25,
			'SUFFIX' => 26,
			'SYMBOL' => 27
		},
		GOTOS => {
			'index' => 29,
			'neg_regex' => 30,
			'q_clause' => 80,
			'qc_basic' => 32,
			'qc_boolean' => 81,
			'qc_concat' => 82,
			'qc_matchid' => 83,
			'qc_near' => 84,
			'qc_phrase' => 85,
			'qc_tokens' => 38,
			'qc_word' => 86,
			'qw_anchor' => 42,
			'qw_any' => 43,
			'qw_bareword' => 44,
			'qw_chunk' => 45,
			'qw_exact' => 46,
			'qw_infix' => 47,
			'qw_infix_set' => 48,
			'qw_keys' => 49,
			'qw_lemma' => 50,
			'qw_listfile' => 51,
			'qw_matchid' => 52,
			'qw_morph' => 53,
			'qw_prefix' => 54,
			'qw_prefix_set' => 55,
			'qw_regex' => 56,
			'qw_set_exact' => 57,
			'qw_set_infl' => 58,
			'qw_suffix' => 59,
			'qw_suffix_set' => 60,
			'qw_thesaurus' => 61,
			'qw_with' => 62,
			'qw_withor' => 63,
			'qw_without' => 64,
			'qwk_indextuple' => 65,
			'regex' => 66,
			's_index' => 67,
			's_infix' => 68,
			's_prefix' => 69,
			's_suffix' => 70,
			's_word' => 71,
			'symbol' => 72
		}
	},
	{#State 6
		DEFAULT => -176
	},
	{#State 7
		ACTIONS => {
			'DATE' => 15,
			'INTEGER' => 19,
			'SYMBOL' => 27
		},
		GOTOS => {
			's_filename' => 87,
			'symbol' => 88
		}
	},
	{#State 8
		ACTIONS => {
			'DATE' => 15,
			'INTEGER' => 19,
			'SYMBOL' => 27
		},
		GOTOS => {
			's_word' => 89,
			'symbol' => 72
		}
	},
	{#State 9
		DEFAULT => -218,
		GOTOS => {
			'l_morph' => 90
		}
	},
	{#State 10
		ACTIONS => {
			'DATE' => 15,
			'INTEGER' => 19,
			'SYMBOL' => 27
		},
		GOTOS => {
			's_chunk' => 91,
			'symbol' => 92
		}
	},
	{#State 11
		DEFAULT => -215,
		GOTOS => {
			'l_set' => 93
		}
	},
	{#State 12
		DEFAULT => -215,
		GOTOS => {
			'l_set' => 94
		}
	},
	{#State 13
		ACTIONS => {
			'DATE' => 15,
			'INTEGER' => 19,
			'SYMBOL' => 27
		},
		GOTOS => {
			's_semclass' => 95,
			'symbol' => 96
		}
	},
	{#State 14
		ACTIONS => {
			"(" => 97
		}
	},
	{#State 15
		DEFAULT => -281
	},
	{#State 16
		ACTIONS => {
			"=" => 98,
			'DATE' => 15,
			'INTEGER' => 19,
			'SYMBOL' => 27
		},
		GOTOS => {
			'symbol' => 99
		}
	},
	{#State 17
		DEFAULT => -283
	},
	{#State 18
		DEFAULT => -287
	},
	{#State 19
		DEFAULT => -280
	},
	{#State 20
		ACTIONS => {
			"(" => 100
		}
	},
	{#State 21
		ACTIONS => {
			"(" => 101
		}
	},
	{#State 22
		ACTIONS => {
			'REGOPT' => 102
		},
		DEFAULT => -291
	},
	{#State 23
		DEFAULT => -285
	},
	{#State 24
		ACTIONS => {
			'REGOPT' => 103
		},
		DEFAULT => -289
	},
	{#State 25
		DEFAULT => -215,
		GOTOS => {
			'l_set' => 104
		}
	},
	{#State 26
		DEFAULT => -286
	},
	{#State 27
		DEFAULT => -279
	},
	{#State 28
		DEFAULT => -116,
		GOTOS => {
			'q_directives' => 105
		}
	},
	{#State 29
		DEFAULT => -266
	},
	{#State 30
		DEFAULT => -174
	},
	{#State 31
		ACTIONS => {
			"=" => 106,
			'OP_BOOL_AND' => 107,
			'OP_BOOL_OR' => 108
		},
		DEFAULT => -30,
		GOTOS => {
			'matchid' => 109,
			'matchid_eq' => 110,
			'q_filters' => 111
		}
	},
	{#State 32
		ACTIONS => {
			"\"" => 2,
			"\$" => 3,
			"%" => 4,
			"(" => 112,
			"*" => 6,
			"<" => 7,
			"\@" => 8,
			"[" => 9,
			"^" => 10,
			"{" => 11,
			'AT_LBRACE' => 12,
			'COLON_LBRACE' => 13,
			'DATE' => 15,
			'DOLLAR_DOT' => 16,
			'INDEX' => 17,
			'INFIX' => 18,
			'INTEGER' => 19,
			'KEYS' => 20,
			'NEAR' => 21,
			'NEG_REGEX' => 22,
			'PREFIX' => 23,
			'REGEX' => 24,
			'STAR_LBRACE' => 25,
			'SUFFIX' => 26,
			'SYMBOL' => 27
		},
		DEFAULT => -120,
		GOTOS => {
			'index' => 29,
			'neg_regex' => 30,
			'qc_basic' => 113,
			'qc_near' => 36,
			'qc_phrase' => 37,
			'qc_tokens' => 38,
			'qc_word' => 39,
			'qw_anchor' => 42,
			'qw_any' => 43,
			'qw_bareword' => 44,
			'qw_chunk' => 45,
			'qw_exact' => 46,
			'qw_infix' => 47,
			'qw_infix_set' => 48,
			'qw_keys' => 49,
			'qw_lemma' => 50,
			'qw_listfile' => 51,
			'qw_matchid' => 52,
			'qw_morph' => 53,
			'qw_prefix' => 54,
			'qw_prefix_set' => 55,
			'qw_regex' => 56,
			'qw_set_exact' => 57,
			'qw_set_infl' => 58,
			'qw_suffix' => 59,
			'qw_suffix_set' => 60,
			'qw_thesaurus' => 61,
			'qw_with' => 62,
			'qw_withor' => 63,
			'qw_without' => 64,
			'qwk_indextuple' => 65,
			'regex' => 66,
			's_index' => 67,
			's_infix' => 68,
			's_prefix' => 69,
			's_suffix' => 70,
			's_word' => 71,
			'symbol' => 72
		}
	},
	{#State 33
		DEFAULT => -121
	},
	{#State 34
		ACTIONS => {
			"\"" => 2,
			"\$" => 3,
			"%" => 4,
			"(" => 112,
			"*" => 6,
			"<" => 7,
			"\@" => 8,
			"[" => 9,
			"^" => 10,
			"{" => 11,
			'AT_LBRACE' => 12,
			'COLON_LBRACE' => 13,
			'DATE' => 15,
			'DOLLAR_DOT' => 16,
			'INDEX' => 17,
			'INFIX' => 18,
			'INTEGER' => 19,
			'KEYS' => 20,
			'NEAR' => 21,
			'NEG_REGEX' => 22,
			'PREFIX' => 23,
			'REGEX' => 24,
			'STAR_LBRACE' => 25,
			'SUFFIX' => 26,
			'SYMBOL' => 27
		},
		DEFAULT => -122,
		GOTOS => {
			'index' => 29,
			'neg_regex' => 30,
			'qc_basic' => 114,
			'qc_near' => 36,
			'qc_phrase' => 37,
			'qc_tokens' => 38,
			'qc_word' => 39,
			'qw_anchor' => 42,
			'qw_any' => 43,
			'qw_bareword' => 44,
			'qw_chunk' => 45,
			'qw_exact' => 46,
			'qw_infix' => 47,
			'qw_infix_set' => 48,
			'qw_keys' => 49,
			'qw_lemma' => 50,
			'qw_listfile' => 51,
			'qw_matchid' => 52,
			'qw_morph' => 53,
			'qw_prefix' => 54,
			'qw_prefix_set' => 55,
			'qw_regex' => 56,
			'qw_set_exact' => 57,
			'qw_set_infl' => 58,
			'qw_suffix' => 59,
			'qw_suffix_set' => 60,
			'qw_thesaurus' => 61,
			'qw_with' => 62,
			'qw_withor' => 63,
			'qw_without' => 64,
			'qwk_indextuple' => 65,
			'regex' => 66,
			's_index' => 67,
			's_infix' => 68,
			's_prefix' => 69,
			's_suffix' => 70,
			's_word' => 71,
			'symbol' => 72
		}
	},
	{#State 35
		DEFAULT => -123
	},
	{#State 36
		ACTIONS => {
			"=" => 106
		},
		DEFAULT => -134,
		GOTOS => {
			'matchid' => 115,
			'matchid_eq' => 110
		}
	},
	{#State 37
		DEFAULT => -140
	},
	{#State 38
		ACTIONS => {
			"=" => 106
		},
		DEFAULT => -133,
		GOTOS => {
			'matchid' => 116,
			'matchid_eq' => 110
		}
	},
	{#State 39
		ACTIONS => {
			"=" => 106,
			'WITH' => 117,
			'WITHOR' => 118,
			'WITHOUT' => 119
		},
		DEFAULT => -139,
		GOTOS => {
			'matchid' => 120,
			'matchid_eq' => 110
		}
	},
	{#State 40
		ACTIONS => {
			'' => 121
		}
	},
	{#State 41
		DEFAULT => -116,
		GOTOS => {
			'q_directives' => 122
		}
	},
	{#State 42
		DEFAULT => -160
	},
	{#State 43
		DEFAULT => -147
	},
	{#State 44
		DEFAULT => -144
	},
	{#State 45
		DEFAULT => -159
	},
	{#State 46
		DEFAULT => -145
	},
	{#State 47
		DEFAULT => -150
	},
	{#State 48
		DEFAULT => -151
	},
	{#State 49
		DEFAULT => -165
	},
	{#State 50
		DEFAULT => -158
	},
	{#State 51
		DEFAULT => -161
	},
	{#State 52
		DEFAULT => -166
	},
	{#State 53
		DEFAULT => -157
	},
	{#State 54
		DEFAULT => -152
	},
	{#State 55
		DEFAULT => -153
	},
	{#State 56
		DEFAULT => -146
	},
	{#State 57
		DEFAULT => -149
	},
	{#State 58
		DEFAULT => -148
	},
	{#State 59
		DEFAULT => -154
	},
	{#State 60
		DEFAULT => -155
	},
	{#State 61
		DEFAULT => -156
	},
	{#State 62
		DEFAULT => -162
	},
	{#State 63
		DEFAULT => -164
	},
	{#State 64
		DEFAULT => -163
	},
	{#State 65
		ACTIONS => {
			"=" => 123
		}
	},
	{#State 66
		DEFAULT => -172
	},
	{#State 67
		ACTIONS => {
			"=" => 124
		}
	},
	{#State 68
		DEFAULT => -186
	},
	{#State 69
		DEFAULT => -182
	},
	{#State 70
		DEFAULT => -184
	},
	{#State 71
		DEFAULT => -228,
		GOTOS => {
			'l_txchain' => 125
		}
	},
	{#State 72
		DEFAULT => -269
	},
	{#State 73
		ACTIONS => {
			"=" => 106
		},
		DEFAULT => -128,
		GOTOS => {
			'matchid' => 109,
			'matchid_eq' => 110
		}
	},
	{#State 74
		ACTIONS => {
			"\$" => 3,
			"%" => 4,
			"(" => 74,
			"*" => 6,
			"<" => 7,
			"\@" => 8,
			"[" => 9,
			"^" => 10,
			"{" => 11,
			'AT_LBRACE' => 12,
			'COLON_LBRACE' => 13,
			'DATE' => 15,
			'DOLLAR_DOT' => 16,
			'INDEX' => 17,
			'INFIX' => 18,
			'INTEGER' => 19,
			'KEYS' => 20,
			'NEG_REGEX' => 22,
			'PREFIX' => 23,
			'REGEX' => 24,
			'STAR_LBRACE' => 25,
			'SUFFIX' => 26,
			'SYMBOL' => 27
		},
		GOTOS => {
			'index' => 29,
			'neg_regex' => 30,
			'qc_word' => 126,
			'qw_anchor' => 42,
			'qw_any' => 43,
			'qw_bareword' => 44,
			'qw_chunk' => 45,
			'qw_exact' => 46,
			'qw_infix' => 47,
			'qw_infix_set' => 48,
			'qw_keys' => 49,
			'qw_lemma' => 50,
			'qw_listfile' => 51,
			'qw_matchid' => 52,
			'qw_morph' => 53,
			'qw_prefix' => 54,
			'qw_prefix_set' => 55,
			'qw_regex' => 56,
			'qw_set_exact' => 57,
			'qw_set_infl' => 58,
			'qw_suffix' => 59,
			'qw_suffix_set' => 60,
			'qw_thesaurus' => 61,
			'qw_with' => 62,
			'qw_withor' => 63,
			'qw_without' => 64,
			'qwk_indextuple' => 65,
			'regex' => 66,
			's_index' => 67,
			's_infix' => 68,
			's_prefix' => 69,
			's_suffix' => 70,
			's_word' => 71,
			'symbol' => 72
		}
	},
	{#State 75
		ACTIONS => {
			"\"" => 127,
			"#" => 128,
			"\$" => 3,
			"%" => 4,
			"(" => 74,
			"*" => 6,
			"<" => 7,
			"\@" => 8,
			"[" => 9,
			"^" => 10,
			"{" => 11,
			'AT_LBRACE' => 12,
			'COLON_LBRACE' => 13,
			'DATE' => 15,
			'DOLLAR_DOT' => 16,
			'HASH_EQUAL' => 129,
			'HASH_GREATER' => 130,
			'HASH_LESS' => 131,
			'INDEX' => 17,
			'INFIX' => 18,
			'INTEGER' => 19,
			'KEYS' => 20,
			'NEG_REGEX' => 22,
			'PREFIX' => 23,
			'REGEX' => 24,
			'STAR_LBRACE' => 25,
			'SUFFIX' => 26,
			'SYMBOL' => 27
		},
		GOTOS => {
			'index' => 29,
			'neg_regex' => 30,
			'qc_word' => 132,
			'qw_anchor' => 42,
			'qw_any' => 43,
			'qw_bareword' => 44,
			'qw_chunk' => 45,
			'qw_exact' => 46,
			'qw_infix' => 47,
			'qw_infix_set' => 48,
			'qw_keys' => 49,
			'qw_lemma' => 50,
			'qw_listfile' => 51,
			'qw_matchid' => 52,
			'qw_morph' => 53,
			'qw_prefix' => 54,
			'qw_prefix_set' => 55,
			'qw_regex' => 56,
			'qw_set_exact' => 57,
			'qw_set_infl' => 58,
			'qw_suffix' => 59,
			'qw_suffix_set' => 60,
			'qw_thesaurus' => 61,
			'qw_with' => 62,
			'qw_withor' => 63,
			'qw_without' => 64,
			'qwk_indextuple' => 65,
			'regex' => 66,
			's_index' => 67,
			's_infix' => 68,
			's_prefix' => 69,
			's_suffix' => 70,
			's_word' => 71,
			'symbol' => 72
		}
	},
	{#State 76
		ACTIONS => {
			"=" => 106,
			'WITH' => 117,
			'WITHOR' => 118,
			'WITHOUT' => 119
		},
		DEFAULT => -222,
		GOTOS => {
			'matchid' => 120,
			'matchid_eq' => 110
		}
	},
	{#State 77
		ACTIONS => {
			"\$" => 133,
			'DATE' => 15,
			'INDEX' => 17,
			'INTEGER' => 19,
			'SYMBOL' => 27
		},
		DEFAULT => -236,
		GOTOS => {
			'index' => 29,
			'l_indextuple' => 134,
			's_index' => 135,
			's_indextuple_item' => 136,
			'symbol' => 137
		}
	},
	{#State 78
		DEFAULT => -198
	},
	{#State 79
		DEFAULT => -271
	},
	{#State 80
		ACTIONS => {
			"=" => 106,
			'OP_BOOL_AND' => 107,
			'OP_BOOL_OR' => 108
		},
		GOTOS => {
			'matchid' => 109,
			'matchid_eq' => 110
		}
	},
	{#State 81
		ACTIONS => {
			")" => 138
		},
		DEFAULT => -121
	},
	{#State 82
		ACTIONS => {
			"\"" => 2,
			"\$" => 3,
			"%" => 4,
			"(" => 112,
			")" => 139,
			"*" => 6,
			"<" => 7,
			"\@" => 8,
			"[" => 9,
			"^" => 10,
			"{" => 11,
			'AT_LBRACE' => 12,
			'COLON_LBRACE' => 13,
			'DATE' => 15,
			'DOLLAR_DOT' => 16,
			'INDEX' => 17,
			'INFIX' => 18,
			'INTEGER' => 19,
			'KEYS' => 20,
			'NEAR' => 21,
			'NEG_REGEX' => 22,
			'PREFIX' => 23,
			'REGEX' => 24,
			'STAR_LBRACE' => 25,
			'SUFFIX' => 26,
			'SYMBOL' => 27
		},
		DEFAULT => -122,
		GOTOS => {
			'index' => 29,
			'neg_regex' => 30,
			'qc_basic' => 114,
			'qc_near' => 36,
			'qc_phrase' => 37,
			'qc_tokens' => 38,
			'qc_word' => 39,
			'qw_anchor' => 42,
			'qw_any' => 43,
			'qw_bareword' => 44,
			'qw_chunk' => 45,
			'qw_exact' => 46,
			'qw_infix' => 47,
			'qw_infix_set' => 48,
			'qw_keys' => 49,
			'qw_lemma' => 50,
			'qw_listfile' => 51,
			'qw_matchid' => 52,
			'qw_morph' => 53,
			'qw_prefix' => 54,
			'qw_prefix_set' => 55,
			'qw_regex' => 56,
			'qw_set_exact' => 57,
			'qw_set_infl' => 58,
			'qw_suffix' => 59,
			'qw_suffix_set' => 60,
			'qw_thesaurus' => 61,
			'qw_with' => 62,
			'qw_withor' => 63,
			'qw_without' => 64,
			'qwk_indextuple' => 65,
			'regex' => 66,
			's_index' => 67,
			's_infix' => 68,
			's_prefix' => 69,
			's_suffix' => 70,
			's_word' => 71,
			'symbol' => 72
		}
	},
	{#State 83
		ACTIONS => {
			")" => 140
		},
		DEFAULT => -123
	},
	{#State 84
		ACTIONS => {
			")" => 141,
			"=" => 106
		},
		DEFAULT => -134,
		GOTOS => {
			'matchid' => 115,
			'matchid_eq' => 110
		}
	},
	{#State 85
		ACTIONS => {
			")" => 142
		},
		DEFAULT => -140
	},
	{#State 86
		ACTIONS => {
			")" => 143,
			"=" => 106,
			'WITH' => 117,
			'WITHOR' => 118,
			'WITHOUT' => 119
		},
		DEFAULT => -139,
		GOTOS => {
			'matchid' => 120,
			'matchid_eq' => 110
		}
	},
	{#State 87
		DEFAULT => -204
	},
	{#State 88
		DEFAULT => -273
	},
	{#State 89
		DEFAULT => -170
	},
	{#State 90
		ACTIONS => {
			"," => 144,
			";" => 145,
			"]" => 146,
			'DATE' => 15,
			'INTEGER' => 19,
			'SYMBOL' => 27
		},
		GOTOS => {
			's_morphitem' => 147,
			'symbol' => 148
		}
	},
	{#State 91
		DEFAULT => -200
	},
	{#State 92
		DEFAULT => -272
	},
	{#State 93
		ACTIONS => {
			"," => 149,
			"}" => 150,
			'DATE' => 15,
			'INTEGER' => 19,
			'RBRACE_STAR' => 151,
			'SYMBOL' => 27
		},
		GOTOS => {
			's_word' => 152,
			'symbol' => 72
		}
	},
	{#State 94
		ACTIONS => {
			"," => 149,
			"}" => 153,
			'DATE' => 15,
			'INTEGER' => 19,
			'SYMBOL' => 27
		},
		GOTOS => {
			's_word' => 152,
			'symbol' => 72
		}
	},
	{#State 95
		ACTIONS => {
			"}" => 154
		}
	},
	{#State 96
		DEFAULT => -270
	},
	{#State 97
		ACTIONS => {
			"!" => 1,
			"\"" => 2,
			"\$" => 3,
			"%" => 4,
			"(" => 5,
			"*" => 6,
			"<" => 7,
			"\@" => 8,
			"[" => 9,
			"^" => 10,
			"{" => 11,
			'AT_LBRACE' => 12,
			'COLON_LBRACE' => 13,
			'DATE' => 15,
			'DOLLAR_DOT' => 16,
			'INDEX' => 17,
			'INFIX' => 18,
			'INTEGER' => 19,
			'KEYS' => 20,
			'NEAR' => 21,
			'NEG_REGEX' => 22,
			'PREFIX' => 23,
			'REGEX' => 24,
			'STAR_LBRACE' => 25,
			'SUFFIX' => 26,
			'SYMBOL' => 27
		},
		GOTOS => {
			'index' => 29,
			'neg_regex' => 30,
			'q_clause' => 31,
			'qc_basic' => 32,
			'qc_boolean' => 33,
			'qc_concat' => 34,
			'qc_matchid' => 35,
			'qc_near' => 36,
			'qc_phrase' => 37,
			'qc_tokens' => 38,
			'qc_word' => 39,
			'query_conditions' => 155,
			'qw_anchor' => 42,
			'qw_any' => 43,
			'qw_bareword' => 44,
			'qw_chunk' => 45,
			'qw_exact' => 46,
			'qw_infix' => 47,
			'qw_infix_set' => 48,
			'qw_keys' => 49,
			'qw_lemma' => 50,
			'qw_listfile' => 51,
			'qw_matchid' => 52,
			'qw_morph' => 53,
			'qw_prefix' => 54,
			'qw_prefix_set' => 55,
			'qw_regex' => 56,
			'qw_set_exact' => 57,
			'qw_set_infl' => 58,
			'qw_suffix' => 59,
			'qw_suffix_set' => 60,
			'qw_thesaurus' => 61,
			'qw_with' => 62,
			'qw_withor' => 63,
			'qw_without' => 64,
			'qwk_indextuple' => 65,
			'regex' => 66,
			's_index' => 67,
			's_infix' => 68,
			's_prefix' => 69,
			's_suffix' => 70,
			's_word' => 71,
			'symbol' => 72
		}
	},
	{#State 98
		ACTIONS => {
			'INTEGER' => 156
		},
		GOTOS => {
			'int_str' => 157
		}
	},
	{#State 99
		ACTIONS => {
			"=" => 158
		}
	},
	{#State 100
		ACTIONS => {
			"!" => 1,
			"\"" => 2,
			"\$" => 3,
			"%" => 4,
			"(" => 5,
			"*" => 6,
			"<" => 7,
			"\@" => 8,
			"[" => 9,
			"^" => 10,
			"{" => 11,
			'AT_LBRACE' => 12,
			'COLON_LBRACE' => 13,
			'COUNT' => 14,
			'DATE' => 15,
			'DOLLAR_DOT' => 16,
			'INDEX' => 17,
			'INFIX' => 18,
			'INTEGER' => 19,
			'KEYS' => 20,
			'NEAR' => 21,
			'NEG_REGEX' => 22,
			'PREFIX' => 23,
			'REGEX' => 24,
			'STAR_LBRACE' => 25,
			'SUFFIX' => 26,
			'SYMBOL' => 27
		},
		GOTOS => {
			'count_query' => 159,
			'index' => 29,
			'neg_regex' => 30,
			'q_clause' => 31,
			'qc_basic' => 32,
			'qc_boolean' => 33,
			'qc_concat' => 34,
			'qc_matchid' => 35,
			'qc_near' => 36,
			'qc_phrase' => 37,
			'qc_tokens' => 38,
			'qc_word' => 39,
			'query_conditions' => 160,
			'qw_anchor' => 42,
			'qw_any' => 43,
			'qw_bareword' => 44,
			'qw_chunk' => 45,
			'qw_exact' => 46,
			'qw_infix' => 47,
			'qw_infix_set' => 48,
			'qw_keys' => 49,
			'qw_lemma' => 50,
			'qw_listfile' => 51,
			'qw_matchid' => 52,
			'qw_morph' => 53,
			'qw_prefix' => 54,
			'qw_prefix_set' => 55,
			'qw_regex' => 56,
			'qw_set_exact' => 57,
			'qw_set_infl' => 58,
			'qw_suffix' => 59,
			'qw_suffix_set' => 60,
			'qw_thesaurus' => 61,
			'qw_with' => 62,
			'qw_withor' => 63,
			'qw_without' => 64,
			'qwk_countsrc' => 161,
			'qwk_indextuple' => 65,
			'regex' => 66,
			's_index' => 67,
			's_infix' => 68,
			's_prefix' => 69,
			's_suffix' => 70,
			's_word' => 71,
			'symbol' => 72
		}
	},
	{#State 101
		ACTIONS => {
			"\"" => 2,
			"\$" => 3,
			"%" => 4,
			"(" => 162,
			"*" => 6,
			"<" => 7,
			"\@" => 8,
			"[" => 9,
			"^" => 10,
			"{" => 11,
			'AT_LBRACE' => 12,
			'COLON_LBRACE' => 13,
			'DATE' => 15,
			'DOLLAR_DOT' => 16,
			'INDEX' => 17,
			'INFIX' => 18,
			'INTEGER' => 19,
			'KEYS' => 20,
			'NEG_REGEX' => 22,
			'PREFIX' => 23,
			'REGEX' => 24,
			'STAR_LBRACE' => 25,
			'SUFFIX' => 26,
			'SYMBOL' => 27
		},
		GOTOS => {
			'index' => 29,
			'neg_regex' => 30,
			'qc_phrase' => 37,
			'qc_tokens' => 163,
			'qc_word' => 39,
			'qw_anchor' => 42,
			'qw_any' => 43,
			'qw_bareword' => 44,
			'qw_chunk' => 45,
			'qw_exact' => 46,
			'qw_infix' => 47,
			'qw_infix_set' => 48,
			'qw_keys' => 49,
			'qw_lemma' => 50,
			'qw_listfile' => 51,
			'qw_matchid' => 52,
			'qw_morph' => 53,
			'qw_prefix' => 54,
			'qw_prefix_set' => 55,
			'qw_regex' => 56,
			'qw_set_exact' => 57,
			'qw_set_infl' => 58,
			'qw_suffix' => 59,
			'qw_suffix_set' => 60,
			'qw_thesaurus' => 61,
			'qw_with' => 62,
			'qw_withor' => 63,
			'qw_without' => 64,
			'qwk_indextuple' => 65,
			'regex' => 66,
			's_index' => 67,
			's_infix' => 68,
			's_prefix' => 69,
			's_suffix' => 70,
			's_word' => 71,
			'symbol' => 72
		}
	},
	{#State 102
		DEFAULT => -292
	},
	{#State 103
		DEFAULT => -290
	},
	{#State 104
		ACTIONS => {
			"," => 149,
			"}" => 164,
			'DATE' => 15,
			'INTEGER' => 19,
			'RBRACE_STAR' => 165,
			'SYMBOL' => 27
		},
		GOTOS => {
			's_word' => 152,
			'symbol' => 72
		}
	},
	{#State 105
		ACTIONS => {
			":" => 166
		},
		DEFAULT => -2,
		GOTOS => {
			'qd_subcorpora' => 167
		}
	},
	{#State 106
		DEFAULT => -300
	},
	{#State 107
		ACTIONS => {
			"!" => 1,
			"\"" => 2,
			"\$" => 3,
			"%" => 4,
			"(" => 5,
			"*" => 6,
			"<" => 7,
			"\@" => 8,
			"[" => 9,
			"^" => 10,
			"{" => 11,
			'AT_LBRACE' => 12,
			'COLON_LBRACE' => 13,
			'DATE' => 15,
			'DOLLAR_DOT' => 16,
			'INDEX' => 17,
			'INFIX' => 18,
			'INTEGER' => 19,
			'KEYS' => 20,
			'NEAR' => 21,
			'NEG_REGEX' => 22,
			'PREFIX' => 23,
			'REGEX' => 24,
			'STAR_LBRACE' => 25,
			'SUFFIX' => 26,
			'SYMBOL' => 27
		},
		GOTOS => {
			'index' => 29,
			'neg_regex' => 30,
			'q_clause' => 168,
			'qc_basic' => 32,
			'qc_boolean' => 33,
			'qc_concat' => 34,
			'qc_matchid' => 35,
			'qc_near' => 36,
			'qc_phrase' => 37,
			'qc_tokens' => 38,
			'qc_word' => 39,
			'qw_anchor' => 42,
			'qw_any' => 43,
			'qw_bareword' => 44,
			'qw_chunk' => 45,
			'qw_exact' => 46,
			'qw_infix' => 47,
			'qw_infix_set' => 48,
			'qw_keys' => 49,
			'qw_lemma' => 50,
			'qw_listfile' => 51,
			'qw_matchid' => 52,
			'qw_morph' => 53,
			'qw_prefix' => 54,
			'qw_prefix_set' => 55,
			'qw_regex' => 56,
			'qw_set_exact' => 57,
			'qw_set_infl' => 58,
			'qw_suffix' => 59,
			'qw_suffix_set' => 60,
			'qw_thesaurus' => 61,
			'qw_with' => 62,
			'qw_withor' => 63,
			'qw_without' => 64,
			'qwk_indextuple' => 65,
			'regex' => 66,
			's_index' => 67,
			's_infix' => 68,
			's_prefix' => 69,
			's_suffix' => 70,
			's_word' => 71,
			'symbol' => 72
		}
	},
	{#State 108
		ACTIONS => {
			"!" => 1,
			"\"" => 2,
			"\$" => 3,
			"%" => 4,
			"(" => 5,
			"*" => 6,
			"<" => 7,
			"\@" => 8,
			"[" => 9,
			"^" => 10,
			"{" => 11,
			'AT_LBRACE' => 12,
			'COLON_LBRACE' => 13,
			'DATE' => 15,
			'DOLLAR_DOT' => 16,
			'INDEX' => 17,
			'INFIX' => 18,
			'INTEGER' => 19,
			'KEYS' => 20,
			'NEAR' => 21,
			'NEG_REGEX' => 22,
			'PREFIX' => 23,
			'REGEX' => 24,
			'STAR_LBRACE' => 25,
			'SUFFIX' => 26,
			'SYMBOL' => 27
		},
		GOTOS => {
			'index' => 29,
			'neg_regex' => 30,
			'q_clause' => 169,
			'qc_basic' => 32,
			'qc_boolean' => 33,
			'qc_concat' => 34,
			'qc_matchid' => 35,
			'qc_near' => 36,
			'qc_phrase' => 37,
			'qc_tokens' => 38,
			'qc_word' => 39,
			'qw_anchor' => 42,
			'qw_any' => 43,
			'qw_bareword' => 44,
			'qw_chunk' => 45,
			'qw_exact' => 46,
			'qw_infix' => 47,
			'qw_infix_set' => 48,
			'qw_keys' => 49,
			'qw_lemma' => 50,
			'qw_listfile' => 51,
			'qw_matchid' => 52,
			'qw_morph' => 53,
			'qw_prefix' => 54,
			'qw_prefix_set' => 55,
			'qw_regex' => 56,
			'qw_set_exact' => 57,
			'qw_set_infl' => 58,
			'qw_suffix' => 59,
			'qw_suffix_set' => 60,
			'qw_thesaurus' => 61,
			'qw_with' => 62,
			'qw_withor' => 63,
			'qw_without' => 64,
			'qwk_indextuple' => 65,
			'regex' => 66,
			's_index' => 67,
			's_infix' => 68,
			's_prefix' => 69,
			's_suffix' => 70,
			's_word' => 71,
			'symbol' => 72
		}
	},
	{#State 109
		DEFAULT => -124
	},
	{#State 110
		ACTIONS => {
			'INTEGER' => 156
		},
		GOTOS => {
			'int_str' => 170,
			'integer' => 171
		}
	},
	{#State 111
		ACTIONS => {
			"!" => 172,
			'CNTXT' => 173,
			'DEBUG_RANK' => 174,
			'FILENAMES_ONLY' => 175,
			'GREATER_BY' => 176,
			'GREATER_BY_DATE' => 177,
			'GREATER_BY_LEFT' => 178,
			'GREATER_BY_MIDDLE' => 179,
			'GREATER_BY_RANK' => 180,
			'GREATER_BY_RIGHT' => 181,
			'GREATER_BY_SIZE' => 182,
			'HAS_FIELD' => 183,
			'IS_DATE' => 184,
			'IS_SIZE' => 185,
			'KW_COMMENT' => 186,
			'LESS_BY' => 187,
			'LESS_BY_DATE' => 188,
			'LESS_BY_LEFT' => 189,
			'LESS_BY_MIDDLE' => 190,
			'LESS_BY_RANK' => 191,
			'LESS_BY_RIGHT' => 192,
			'LESS_BY_SIZE' => 193,
			'NOSEPARATE_HITS' => 194,
			'PRUNE_ASC' => 195,
			'PRUNE_DESC' => 196,
			'RANDOM' => 197,
			'SEPARATE_HITS' => 198,
			'WITHIN' => 199
		},
		DEFAULT => -29,
		GOTOS => {
			'q_comment' => 200,
			'q_filter' => 201,
			'q_flag' => 202,
			'qf_bibl_sort' => 203,
			'qf_context_sort' => 204,
			'qf_date_sort' => 205,
			'qf_has_field' => 206,
			'qf_prune_sort' => 207,
			'qf_random_sort' => 208,
			'qf_rank_sort' => 209,
			'qf_size_sort' => 210
		}
	},
	{#State 112
		ACTIONS => {
			"\"" => 2,
			"\$" => 3,
			"%" => 4,
			"(" => 112,
			"*" => 6,
			"<" => 7,
			"\@" => 8,
			"[" => 9,
			"^" => 10,
			"{" => 11,
			'AT_LBRACE' => 12,
			'COLON_LBRACE' => 13,
			'DATE' => 15,
			'DOLLAR_DOT' => 16,
			'INDEX' => 17,
			'INFIX' => 18,
			'INTEGER' => 19,
			'KEYS' => 20,
			'NEAR' => 21,
			'NEG_REGEX' => 22,
			'PREFIX' => 23,
			'REGEX' => 24,
			'STAR_LBRACE' => 25,
			'SUFFIX' => 26,
			'SYMBOL' => 27
		},
		GOTOS => {
			'index' => 29,
			'neg_regex' => 30,
			'qc_near' => 211,
			'qc_phrase' => 212,
			'qc_word' => 126,
			'qw_anchor' => 42,
			'qw_any' => 43,
			'qw_bareword' => 44,
			'qw_chunk' => 45,
			'qw_exact' => 46,
			'qw_infix' => 47,
			'qw_infix_set' => 48,
			'qw_keys' => 49,
			'qw_lemma' => 50,
			'qw_listfile' => 51,
			'qw_matchid' => 52,
			'qw_morph' => 53,
			'qw_prefix' => 54,
			'qw_prefix_set' => 55,
			'qw_regex' => 56,
			'qw_set_exact' => 57,
			'qw_set_infl' => 58,
			'qw_suffix' => 59,
			'qw_suffix_set' => 60,
			'qw_thesaurus' => 61,
			'qw_with' => 62,
			'qw_withor' => 63,
			'qw_without' => 64,
			'qwk_indextuple' => 65,
			'regex' => 66,
			's_index' => 67,
			's_infix' => 68,
			's_prefix' => 69,
			's_suffix' => 70,
			's_word' => 71,
			'symbol' => 72
		}
	},
	{#State 113
		DEFAULT => -130
	},
	{#State 114
		DEFAULT => -131
	},
	{#State 115
		DEFAULT => -137
	},
	{#State 116
		DEFAULT => -141
	},
	{#State 117
		ACTIONS => {
			"\$" => 3,
			"%" => 4,
			"(" => 74,
			"*" => 6,
			"<" => 7,
			"\@" => 8,
			"[" => 9,
			"^" => 10,
			"{" => 11,
			'AT_LBRACE' => 12,
			'COLON_LBRACE' => 13,
			'DATE' => 15,
			'DOLLAR_DOT' => 16,
			'INDEX' => 17,
			'INFIX' => 18,
			'INTEGER' => 19,
			'KEYS' => 20,
			'NEG_REGEX' => 22,
			'PREFIX' => 23,
			'REGEX' => 24,
			'STAR_LBRACE' => 25,
			'SUFFIX' => 26,
			'SYMBOL' => 27
		},
		GOTOS => {
			'index' => 29,
			'neg_regex' => 30,
			'qc_word' => 213,
			'qw_anchor' => 42,
			'qw_any' => 43,
			'qw_bareword' => 44,
			'qw_chunk' => 45,
			'qw_exact' => 46,
			'qw_infix' => 47,
			'qw_infix_set' => 48,
			'qw_keys' => 49,
			'qw_lemma' => 50,
			'qw_listfile' => 51,
			'qw_matchid' => 52,
			'qw_morph' => 53,
			'qw_prefix' => 54,
			'qw_prefix_set' => 55,
			'qw_regex' => 56,
			'qw_set_exact' => 57,
			'qw_set_infl' => 58,
			'qw_suffix' => 59,
			'qw_suffix_set' => 60,
			'qw_thesaurus' => 61,
			'qw_with' => 62,
			'qw_withor' => 63,
			'qw_without' => 64,
			'qwk_indextuple' => 65,
			'regex' => 66,
			's_index' => 67,
			's_infix' => 68,
			's_prefix' => 69,
			's_suffix' => 70,
			's_word' => 71,
			'symbol' => 72
		}
	},
	{#State 118
		ACTIONS => {
			"\$" => 3,
			"%" => 4,
			"(" => 74,
			"*" => 6,
			"<" => 7,
			"\@" => 8,
			"[" => 9,
			"^" => 10,
			"{" => 11,
			'AT_LBRACE' => 12,
			'COLON_LBRACE' => 13,
			'DATE' => 15,
			'DOLLAR_DOT' => 16,
			'INDEX' => 17,
			'INFIX' => 18,
			'INTEGER' => 19,
			'KEYS' => 20,
			'NEG_REGEX' => 22,
			'PREFIX' => 23,
			'REGEX' => 24,
			'STAR_LBRACE' => 25,
			'SUFFIX' => 26,
			'SYMBOL' => 27
		},
		GOTOS => {
			'index' => 29,
			'neg_regex' => 30,
			'qc_word' => 214,
			'qw_anchor' => 42,
			'qw_any' => 43,
			'qw_bareword' => 44,
			'qw_chunk' => 45,
			'qw_exact' => 46,
			'qw_infix' => 47,
			'qw_infix_set' => 48,
			'qw_keys' => 49,
			'qw_lemma' => 50,
			'qw_listfile' => 51,
			'qw_matchid' => 52,
			'qw_morph' => 53,
			'qw_prefix' => 54,
			'qw_prefix_set' => 55,
			'qw_regex' => 56,
			'qw_set_exact' => 57,
			'qw_set_infl' => 58,
			'qw_suffix' => 59,
			'qw_suffix_set' => 60,
			'qw_thesaurus' => 61,
			'qw_with' => 62,
			'qw_withor' => 63,
			'qw_without' => 64,
			'qwk_indextuple' => 65,
			'regex' => 66,
			's_index' => 67,
			's_infix' => 68,
			's_prefix' => 69,
			's_suffix' => 70,
			's_word' => 71,
			'symbol' => 72
		}
	},
	{#State 119
		ACTIONS => {
			"\$" => 3,
			"%" => 4,
			"(" => 74,
			"*" => 6,
			"<" => 7,
			"\@" => 8,
			"[" => 9,
			"^" => 10,
			"{" => 11,
			'AT_LBRACE' => 12,
			'COLON_LBRACE' => 13,
			'DATE' => 15,
			'DOLLAR_DOT' => 16,
			'INDEX' => 17,
			'INFIX' => 18,
			'INTEGER' => 19,
			'KEYS' => 20,
			'NEG_REGEX' => 22,
			'PREFIX' => 23,
			'REGEX' => 24,
			'STAR_LBRACE' => 25,
			'SUFFIX' => 26,
			'SYMBOL' => 27
		},
		GOTOS => {
			'index' => 29,
			'neg_regex' => 30,
			'qc_word' => 215,
			'qw_anchor' => 42,
			'qw_any' => 43,
			'qw_bareword' => 44,
			'qw_chunk' => 45,
			'qw_exact' => 46,
			'qw_infix' => 47,
			'qw_infix_set' => 48,
			'qw_keys' => 49,
			'qw_lemma' => 50,
			'qw_listfile' => 51,
			'qw_matchid' => 52,
			'qw_morph' => 53,
			'qw_prefix' => 54,
			'qw_prefix_set' => 55,
			'qw_regex' => 56,
			'qw_set_exact' => 57,
			'qw_set_infl' => 58,
			'qw_suffix' => 59,
			'qw_suffix_set' => 60,
			'qw_thesaurus' => 61,
			'qw_with' => 62,
			'qw_withor' => 63,
			'qw_without' => 64,
			'qwk_indextuple' => 65,
			'regex' => 66,
			's_index' => 67,
			's_infix' => 68,
			's_prefix' => 69,
			's_suffix' => 70,
			's_word' => 71,
			'symbol' => 72
		}
	},
	{#State 120
		DEFAULT => -214
	},
	{#State 121
		DEFAULT => 0
	},
	{#State 122
		ACTIONS => {
			":" => 166
		},
		DEFAULT => -1,
		GOTOS => {
			'qd_subcorpora' => 167
		}
	},
	{#State 123
		ACTIONS => {
			'KEYS' => 216
		}
	},
	{#State 124
		ACTIONS => {
			"%" => 217,
			"*" => 218,
			":" => 219,
			"<" => 220,
			"\@" => 221,
			"[" => 222,
			"^" => 223,
			"{" => 224,
			'AT_LBRACE' => 225,
			'DATE' => 15,
			'INFIX' => 18,
			'INTEGER' => 19,
			'NEG_REGEX' => 22,
			'PREFIX' => 23,
			'REGEX' => 24,
			'STAR_LBRACE' => 226,
			'SUFFIX' => 26,
			'SYMBOL' => 27
		},
		GOTOS => {
			'neg_regex' => 227,
			'regex' => 228,
			's_infix' => 229,
			's_prefix' => 230,
			's_suffix' => 231,
			's_word' => 232,
			'symbol' => 72
		}
	},
	{#State 125
		ACTIONS => {
			'EXPANDER' => 233
		},
		DEFAULT => -168,
		GOTOS => {
			's_expander' => 234
		}
	},
	{#State 126
		ACTIONS => {
			")" => 143,
			"=" => 106,
			'WITH' => 117,
			'WITHOR' => 118,
			'WITHOUT' => 119
		},
		GOTOS => {
			'matchid' => 120,
			'matchid_eq' => 110
		}
	},
	{#State 127
		DEFAULT => -142
	},
	{#State 128
		ACTIONS => {
			'INTEGER' => 156
		},
		GOTOS => {
			'int_str' => 170,
			'integer' => 235
		}
	},
	{#State 129
		ACTIONS => {
			'INTEGER' => 156
		},
		GOTOS => {
			'int_str' => 170,
			'integer' => 236
		}
	},
	{#State 130
		ACTIONS => {
			'INTEGER' => 156
		},
		GOTOS => {
			'int_str' => 170,
			'integer' => 237
		}
	},
	{#State 131
		ACTIONS => {
			'INTEGER' => 156
		},
		GOTOS => {
			'int_str' => 170,
			'integer' => 238
		}
	},
	{#State 132
		ACTIONS => {
			"=" => 106,
			'WITH' => 117,
			'WITHOR' => 118,
			'WITHOUT' => 119
		},
		DEFAULT => -223,
		GOTOS => {
			'matchid' => 120,
			'matchid_eq' => 110
		}
	},
	{#State 133
		DEFAULT => -265
	},
	{#State 134
		ACTIONS => {
			")" => 239,
			"," => 240
		}
	},
	{#State 135
		DEFAULT => -267
	},
	{#State 136
		DEFAULT => -237
	},
	{#State 137
		DEFAULT => -268
	},
	{#State 138
		DEFAULT => -129
	},
	{#State 139
		DEFAULT => -132
	},
	{#State 140
		DEFAULT => -125
	},
	{#State 141
		DEFAULT => -138
	},
	{#State 142
		DEFAULT => -143
	},
	{#State 143
		DEFAULT => -167
	},
	{#State 144
		DEFAULT => -220
	},
	{#State 145
		DEFAULT => -221
	},
	{#State 146
		DEFAULT => -196
	},
	{#State 147
		DEFAULT => -219
	},
	{#State 148
		DEFAULT => -274
	},
	{#State 149
		DEFAULT => -217
	},
	{#State 150
		DEFAULT => -228,
		GOTOS => {
			'l_txchain' => 241
		}
	},
	{#State 151
		DEFAULT => -190
	},
	{#State 152
		DEFAULT => -216
	},
	{#State 153
		DEFAULT => -178
	},
	{#State 154
		DEFAULT => -194
	},
	{#State 155
		DEFAULT => -4,
		GOTOS => {
			'count_filters' => 242
		}
	},
	{#State 156
		DEFAULT => -295
	},
	{#State 157
		DEFAULT => -202
	},
	{#State 158
		ACTIONS => {
			'INTEGER' => 156
		},
		GOTOS => {
			'int_str' => 243
		}
	},
	{#State 159
		DEFAULT => -212
	},
	{#State 160
		DEFAULT => -4,
		GOTOS => {
			'count_filters' => 244
		}
	},
	{#State 161
		ACTIONS => {
			")" => 245
		}
	},
	{#State 162
		ACTIONS => {
			"\"" => 2,
			"\$" => 3,
			"%" => 4,
			"(" => 162,
			"*" => 6,
			"<" => 7,
			"\@" => 8,
			"[" => 9,
			"^" => 10,
			"{" => 11,
			'AT_LBRACE' => 12,
			'COLON_LBRACE' => 13,
			'DATE' => 15,
			'DOLLAR_DOT' => 16,
			'INDEX' => 17,
			'INFIX' => 18,
			'INTEGER' => 19,
			'KEYS' => 20,
			'NEG_REGEX' => 22,
			'PREFIX' => 23,
			'REGEX' => 24,
			'STAR_LBRACE' => 25,
			'SUFFIX' => 26,
			'SYMBOL' => 27
		},
		GOTOS => {
			'index' => 29,
			'neg_regex' => 30,
			'qc_phrase' => 212,
			'qc_word' => 126,
			'qw_anchor' => 42,
			'qw_any' => 43,
			'qw_bareword' => 44,
			'qw_chunk' => 45,
			'qw_exact' => 46,
			'qw_infix' => 47,
			'qw_infix_set' => 48,
			'qw_keys' => 49,
			'qw_lemma' => 50,
			'qw_listfile' => 51,
			'qw_matchid' => 52,
			'qw_morph' => 53,
			'qw_prefix' => 54,
			'qw_prefix_set' => 55,
			'qw_regex' => 56,
			'qw_set_exact' => 57,
			'qw_set_infl' => 58,
			'qw_suffix' => 59,
			'qw_suffix_set' => 60,
			'qw_thesaurus' => 61,
			'qw_with' => 62,
			'qw_withor' => 63,
			'qw_without' => 64,
			'qwk_indextuple' => 65,
			'regex' => 66,
			's_index' => 67,
			's_infix' => 68,
			's_prefix' => 69,
			's_suffix' => 70,
			's_word' => 71,
			'symbol' => 72
		}
	},
	{#State 163
		ACTIONS => {
			"," => 246,
			"=" => 106
		},
		GOTOS => {
			'matchid' => 116,
			'matchid_eq' => 110
		}
	},
	{#State 164
		DEFAULT => -192
	},
	{#State 165
		DEFAULT => -188
	},
	{#State 166
		DEFAULT => -118,
		GOTOS => {
			'@1-1' => 247
		}
	},
	{#State 167
		DEFAULT => -117
	},
	{#State 168
		ACTIONS => {
			"=" => 106
		},
		DEFAULT => -126,
		GOTOS => {
			'matchid' => 109,
			'matchid_eq' => 110
		}
	},
	{#State 169
		ACTIONS => {
			"=" => 106
		},
		DEFAULT => -127,
		GOTOS => {
			'matchid' => 109,
			'matchid_eq' => 110
		}
	},
	{#State 170
		DEFAULT => -296
	},
	{#State 171
		DEFAULT => -299
	},
	{#State 172
		ACTIONS => {
			"!" => 248,
			'DEBUG_RANK' => 249,
			'FILENAMES_ONLY' => 250,
			'HAS_FIELD' => 183
		},
		GOTOS => {
			'qf_has_field' => 251
		}
	},
	{#State 173
		ACTIONS => {
			"[" => 252,
			'INTEGER' => 156
		},
		GOTOS => {
			'int_str' => 170,
			'integer' => 253
		}
	},
	{#State 174
		DEFAULT => -43
	},
	{#State 175
		DEFAULT => -41
	},
	{#State 176
		ACTIONS => {
			"[" => 254
		}
	},
	{#State 177
		ACTIONS => {
			"[" => 255
		},
		DEFAULT => -91,
		GOTOS => {
			'qfb_date' => 256
		}
	},
	{#State 178
		ACTIONS => {
			"[" => 257
		},
		DEFAULT => -105,
		GOTOS => {
			'qfb_ctxsort' => 258
		}
	},
	{#State 179
		ACTIONS => {
			"[" => 257
		},
		DEFAULT => -105,
		GOTOS => {
			'qfb_ctxsort' => 259
		}
	},
	{#State 180
		DEFAULT => -61
	},
	{#State 181
		ACTIONS => {
			"[" => 257
		},
		DEFAULT => -105,
		GOTOS => {
			'qfb_ctxsort' => 260
		}
	},
	{#State 182
		ACTIONS => {
			"[" => 261
		},
		DEFAULT => -84,
		GOTOS => {
			'qfb_int' => 262
		}
	},
	{#State 183
		ACTIONS => {
			"[" => 263
		}
	},
	{#State 184
		ACTIONS => {
			"[" => 264
		}
	},
	{#State 185
		ACTIONS => {
			"[" => 265
		}
	},
	{#State 186
		ACTIONS => {
			"[" => 266,
			'DATE' => 15,
			'INTEGER' => 19,
			'SYMBOL' => 27
		},
		GOTOS => {
			'symbol' => 267
		}
	},
	{#State 187
		ACTIONS => {
			"[" => 268
		}
	},
	{#State 188
		ACTIONS => {
			"[" => 255
		},
		DEFAULT => -91,
		GOTOS => {
			'qfb_date' => 269
		}
	},
	{#State 189
		ACTIONS => {
			"[" => 257
		},
		DEFAULT => -105,
		GOTOS => {
			'qfb_ctxsort' => 270
		}
	},
	{#State 190
		ACTIONS => {
			"[" => 257
		},
		DEFAULT => -105,
		GOTOS => {
			'qfb_ctxsort' => 271
		}
	},
	{#State 191
		DEFAULT => -62
	},
	{#State 192
		ACTIONS => {
			"[" => 257
		},
		DEFAULT => -105,
		GOTOS => {
			'qfb_ctxsort' => 272
		}
	},
	{#State 193
		ACTIONS => {
			"[" => 261
		},
		DEFAULT => -84,
		GOTOS => {
			'qfb_int' => 273
		}
	},
	{#State 194
		DEFAULT => -40
	},
	{#State 195
		ACTIONS => {
			"[" => 274
		}
	},
	{#State 196
		ACTIONS => {
			"[" => 275
		}
	},
	{#State 197
		ACTIONS => {
			"[" => 276
		},
		DEFAULT => -75
	},
	{#State 198
		DEFAULT => -39
	},
	{#State 199
		ACTIONS => {
			'DATE' => 15,
			'INTEGER' => 19,
			'KW_FILENAME' => 277,
			'SYMBOL' => 27
		},
		GOTOS => {
			's_breakname' => 278,
			'symbol' => 279
		}
	},
	{#State 200
		DEFAULT => -31
	},
	{#State 201
		DEFAULT => -33
	},
	{#State 202
		DEFAULT => -32
	},
	{#State 203
		DEFAULT => -50
	},
	{#State 204
		DEFAULT => -47
	},
	{#State 205
		DEFAULT => -49
	},
	{#State 206
		DEFAULT => -45
	},
	{#State 207
		DEFAULT => -52
	},
	{#State 208
		DEFAULT => -51
	},
	{#State 209
		DEFAULT => -46
	},
	{#State 210
		DEFAULT => -48
	},
	{#State 211
		ACTIONS => {
			")" => 141,
			"=" => 106
		},
		GOTOS => {
			'matchid' => 115,
			'matchid_eq' => 110
		}
	},
	{#State 212
		ACTIONS => {
			")" => 142
		}
	},
	{#State 213
		ACTIONS => {
			"=" => 106
		},
		DEFAULT => -206,
		GOTOS => {
			'matchid' => 120,
			'matchid_eq' => 110
		}
	},
	{#State 214
		ACTIONS => {
			"=" => 106
		},
		DEFAULT => -208,
		GOTOS => {
			'matchid' => 120,
			'matchid_eq' => 110
		}
	},
	{#State 215
		ACTIONS => {
			"=" => 106
		},
		DEFAULT => -207,
		GOTOS => {
			'matchid' => 120,
			'matchid_eq' => 110
		}
	},
	{#State 216
		ACTIONS => {
			"(" => 280
		}
	},
	{#State 217
		ACTIONS => {
			'DATE' => 15,
			'INTEGER' => 19,
			'SYMBOL' => 27
		},
		GOTOS => {
			's_lemma' => 281,
			'symbol' => 79
		}
	},
	{#State 218
		DEFAULT => -177
	},
	{#State 219
		ACTIONS => {
			"{" => 282
		}
	},
	{#State 220
		ACTIONS => {
			'DATE' => 15,
			'INTEGER' => 19,
			'SYMBOL' => 27
		},
		GOTOS => {
			's_filename' => 283,
			'symbol' => 88
		}
	},
	{#State 221
		ACTIONS => {
			'DATE' => 15,
			'INTEGER' => 19,
			'SYMBOL' => 27
		},
		GOTOS => {
			's_word' => 284,
			'symbol' => 72
		}
	},
	{#State 222
		DEFAULT => -218,
		GOTOS => {
			'l_morph' => 285
		}
	},
	{#State 223
		ACTIONS => {
			'DATE' => 15,
			'INTEGER' => 19,
			'SYMBOL' => 27
		},
		GOTOS => {
			's_chunk' => 286,
			'symbol' => 92
		}
	},
	{#State 224
		DEFAULT => -215,
		GOTOS => {
			'l_set' => 287
		}
	},
	{#State 225
		DEFAULT => -215,
		GOTOS => {
			'l_set' => 288
		}
	},
	{#State 226
		DEFAULT => -215,
		GOTOS => {
			'l_set' => 289
		}
	},
	{#State 227
		DEFAULT => -175
	},
	{#State 228
		DEFAULT => -173
	},
	{#State 229
		DEFAULT => -187
	},
	{#State 230
		DEFAULT => -183
	},
	{#State 231
		DEFAULT => -185
	},
	{#State 232
		DEFAULT => -228,
		GOTOS => {
			'l_txchain' => 290
		}
	},
	{#State 233
		DEFAULT => -288
	},
	{#State 234
		DEFAULT => -229
	},
	{#State 235
		ACTIONS => {
			"\$" => 3,
			"%" => 4,
			"(" => 74,
			"*" => 6,
			"<" => 7,
			"\@" => 8,
			"[" => 9,
			"^" => 10,
			"{" => 11,
			'AT_LBRACE' => 12,
			'COLON_LBRACE' => 13,
			'DATE' => 15,
			'DOLLAR_DOT' => 16,
			'INDEX' => 17,
			'INFIX' => 18,
			'INTEGER' => 19,
			'KEYS' => 20,
			'NEG_REGEX' => 22,
			'PREFIX' => 23,
			'REGEX' => 24,
			'STAR_LBRACE' => 25,
			'SUFFIX' => 26,
			'SYMBOL' => 27
		},
		GOTOS => {
			'index' => 29,
			'neg_regex' => 30,
			'qc_word' => 291,
			'qw_anchor' => 42,
			'qw_any' => 43,
			'qw_bareword' => 44,
			'qw_chunk' => 45,
			'qw_exact' => 46,
			'qw_infix' => 47,
			'qw_infix_set' => 48,
			'qw_keys' => 49,
			'qw_lemma' => 50,
			'qw_listfile' => 51,
			'qw_matchid' => 52,
			'qw_morph' => 53,
			'qw_prefix' => 54,
			'qw_prefix_set' => 55,
			'qw_regex' => 56,
			'qw_set_exact' => 57,
			'qw_set_infl' => 58,
			'qw_suffix' => 59,
			'qw_suffix_set' => 60,
			'qw_thesaurus' => 61,
			'qw_with' => 62,
			'qw_withor' => 63,
			'qw_without' => 64,
			'qwk_indextuple' => 65,
			'regex' => 66,
			's_index' => 67,
			's_infix' => 68,
			's_prefix' => 69,
			's_suffix' => 70,
			's_word' => 71,
			'symbol' => 72
		}
	},
	{#State 236
		ACTIONS => {
			"\$" => 3,
			"%" => 4,
			"(" => 74,
			"*" => 6,
			"<" => 7,
			"\@" => 8,
			"[" => 9,
			"^" => 10,
			"{" => 11,
			'AT_LBRACE' => 12,
			'COLON_LBRACE' => 13,
			'DATE' => 15,
			'DOLLAR_DOT' => 16,
			'INDEX' => 17,
			'INFIX' => 18,
			'INTEGER' => 19,
			'KEYS' => 20,
			'NEG_REGEX' => 22,
			'PREFIX' => 23,
			'REGEX' => 24,
			'STAR_LBRACE' => 25,
			'SUFFIX' => 26,
			'SYMBOL' => 27
		},
		GOTOS => {
			'index' => 29,
			'neg_regex' => 30,
			'qc_word' => 292,
			'qw_anchor' => 42,
			'qw_any' => 43,
			'qw_bareword' => 44,
			'qw_chunk' => 45,
			'qw_exact' => 46,
			'qw_infix' => 47,
			'qw_infix_set' => 48,
			'qw_keys' => 49,
			'qw_lemma' => 50,
			'qw_listfile' => 51,
			'qw_matchid' => 52,
			'qw_morph' => 53,
			'qw_prefix' => 54,
			'qw_prefix_set' => 55,
			'qw_regex' => 56,
			'qw_set_exact' => 57,
			'qw_set_infl' => 58,
			'qw_suffix' => 59,
			'qw_suffix_set' => 60,
			'qw_thesaurus' => 61,
			'qw_with' => 62,
			'qw_withor' => 63,
			'qw_without' => 64,
			'qwk_indextuple' => 65,
			'regex' => 66,
			's_index' => 67,
			's_infix' => 68,
			's_prefix' => 69,
			's_suffix' => 70,
			's_word' => 71,
			'symbol' => 72
		}
	},
	{#State 237
		ACTIONS => {
			"\$" => 3,
			"%" => 4,
			"(" => 74,
			"*" => 6,
			"<" => 7,
			"\@" => 8,
			"[" => 9,
			"^" => 10,
			"{" => 11,
			'AT_LBRACE' => 12,
			'COLON_LBRACE' => 13,
			'DATE' => 15,
			'DOLLAR_DOT' => 16,
			'INDEX' => 17,
			'INFIX' => 18,
			'INTEGER' => 19,
			'KEYS' => 20,
			'NEG_REGEX' => 22,
			'PREFIX' => 23,
			'REGEX' => 24,
			'STAR_LBRACE' => 25,
			'SUFFIX' => 26,
			'SYMBOL' => 27
		},
		GOTOS => {
			'index' => 29,
			'neg_regex' => 30,
			'qc_word' => 293,
			'qw_anchor' => 42,
			'qw_any' => 43,
			'qw_bareword' => 44,
			'qw_chunk' => 45,
			'qw_exact' => 46,
			'qw_infix' => 47,
			'qw_infix_set' => 48,
			'qw_keys' => 49,
			'qw_lemma' => 50,
			'qw_listfile' => 51,
			'qw_matchid' => 52,
			'qw_morph' => 53,
			'qw_prefix' => 54,
			'qw_prefix_set' => 55,
			'qw_regex' => 56,
			'qw_set_exact' => 57,
			'qw_set_infl' => 58,
			'qw_suffix' => 59,
			'qw_suffix_set' => 60,
			'qw_thesaurus' => 61,
			'qw_with' => 62,
			'qw_withor' => 63,
			'qw_without' => 64,
			'qwk_indextuple' => 65,
			'regex' => 66,
			's_index' => 67,
			's_infix' => 68,
			's_prefix' => 69,
			's_suffix' => 70,
			's_word' => 71,
			'symbol' => 72
		}
	},
	{#State 238
		ACTIONS => {
			"\$" => 3,
			"%" => 4,
			"(" => 74,
			"*" => 6,
			"<" => 7,
			"\@" => 8,
			"[" => 9,
			"^" => 10,
			"{" => 11,
			'AT_LBRACE' => 12,
			'COLON_LBRACE' => 13,
			'DATE' => 15,
			'DOLLAR_DOT' => 16,
			'INDEX' => 17,
			'INFIX' => 18,
			'INTEGER' => 19,
			'KEYS' => 20,
			'NEG_REGEX' => 22,
			'PREFIX' => 23,
			'REGEX' => 24,
			'STAR_LBRACE' => 25,
			'SUFFIX' => 26,
			'SYMBOL' => 27
		},
		GOTOS => {
			'index' => 29,
			'neg_regex' => 30,
			'qc_word' => 294,
			'qw_anchor' => 42,
			'qw_any' => 43,
			'qw_bareword' => 44,
			'qw_chunk' => 45,
			'qw_exact' => 46,
			'qw_infix' => 47,
			'qw_infix_set' => 48,
			'qw_keys' => 49,
			'qw_lemma' => 50,
			'qw_listfile' => 51,
			'qw_matchid' => 52,
			'qw_morph' => 53,
			'qw_prefix' => 54,
			'qw_prefix_set' => 55,
			'qw_regex' => 56,
			'qw_set_exact' => 57,
			'qw_set_infl' => 58,
			'qw_suffix' => 59,
			'qw_suffix_set' => 60,
			'qw_thesaurus' => 61,
			'qw_with' => 62,
			'qw_withor' => 63,
			'qw_without' => 64,
			'qwk_indextuple' => 65,
			'regex' => 66,
			's_index' => 67,
			's_infix' => 68,
			's_prefix' => 69,
			's_suffix' => 70,
			's_word' => 71,
			'symbol' => 72
		}
	},
	{#State 239
		DEFAULT => -211
	},
	{#State 240
		ACTIONS => {
			"\$" => 133,
			'DATE' => 15,
			'INDEX' => 17,
			'INTEGER' => 19,
			'SYMBOL' => 27
		},
		GOTOS => {
			'index' => 29,
			's_index' => 135,
			's_indextuple_item' => 295,
			'symbol' => 137
		}
	},
	{#State 241
		ACTIONS => {
			'EXPANDER' => 233
		},
		DEFAULT => -180,
		GOTOS => {
			's_expander' => 234
		}
	},
	{#State 242
		ACTIONS => {
			")" => 296,
			'BY' => 297,
			'CLIMIT' => 298,
			'GREATER_BY_COUNT' => 299,
			'GREATER_BY_KEY' => 300,
			'KW_COMMENT' => 186,
			'LESS_BY_COUNT' => 301,
			'LESS_BY_KEY' => 302,
			'SAMPLE' => 303
		},
		GOTOS => {
			'count_by' => 304,
			'count_filter' => 305,
			'count_limit' => 306,
			'count_sample' => 307,
			'count_sort' => 308,
			'count_sort_op' => 309,
			'q_comment' => 310
		}
	},
	{#State 243
		DEFAULT => -203
	},
	{#State 244
		ACTIONS => {
			'BY' => 297,
			'CLIMIT' => 298,
			'GREATER_BY_COUNT' => 299,
			'GREATER_BY_KEY' => 300,
			'KW_COMMENT' => 186,
			'LESS_BY_COUNT' => 301,
			'LESS_BY_KEY' => 302,
			'SAMPLE' => 303
		},
		DEFAULT => -213,
		GOTOS => {
			'count_by' => 304,
			'count_filter' => 305,
			'count_limit' => 306,
			'count_sample' => 307,
			'count_sort' => 308,
			'count_sort_op' => 309,
			'q_comment' => 310
		}
	},
	{#State 245
		DEFAULT => -209
	},
	{#State 246
		ACTIONS => {
			"\"" => 2,
			"\$" => 3,
			"%" => 4,
			"(" => 162,
			"*" => 6,
			"<" => 7,
			"\@" => 8,
			"[" => 9,
			"^" => 10,
			"{" => 11,
			'AT_LBRACE' => 12,
			'COLON_LBRACE' => 13,
			'DATE' => 15,
			'DOLLAR_DOT' => 16,
			'INDEX' => 17,
			'INFIX' => 18,
			'INTEGER' => 19,
			'KEYS' => 20,
			'NEG_REGEX' => 22,
			'PREFIX' => 23,
			'REGEX' => 24,
			'STAR_LBRACE' => 25,
			'SUFFIX' => 26,
			'SYMBOL' => 27
		},
		GOTOS => {
			'index' => 29,
			'neg_regex' => 30,
			'qc_phrase' => 37,
			'qc_tokens' => 311,
			'qc_word' => 39,
			'qw_anchor' => 42,
			'qw_any' => 43,
			'qw_bareword' => 44,
			'qw_chunk' => 45,
			'qw_exact' => 46,
			'qw_infix' => 47,
			'qw_infix_set' => 48,
			'qw_keys' => 49,
			'qw_lemma' => 50,
			'qw_listfile' => 51,
			'qw_matchid' => 52,
			'qw_morph' => 53,
			'qw_prefix' => 54,
			'qw_prefix_set' => 55,
			'qw_regex' => 56,
			'qw_set_exact' => 57,
			'qw_set_infl' => 58,
			'qw_suffix' => 59,
			'qw_suffix_set' => 60,
			'qw_thesaurus' => 61,
			'qw_with' => 62,
			'qw_withor' => 63,
			'qw_without' => 64,
			'qwk_indextuple' => 65,
			'regex' => 66,
			's_index' => 67,
			's_infix' => 68,
			's_prefix' => 69,
			's_suffix' => 70,
			's_word' => 71,
			'symbol' => 72
		}
	},
	{#State 247
		ACTIONS => {
			'DATE' => 15,
			'INTEGER' => 19,
			'SYMBOL' => 27
		},
		DEFAULT => -239,
		GOTOS => {
			'l_subcorpora' => 312,
			's_subcorpus' => 313,
			'symbol' => 314
		}
	},
	{#State 248
		ACTIONS => {
			"!" => 248,
			'HAS_FIELD' => 183
		},
		GOTOS => {
			'qf_has_field' => 251
		}
	},
	{#State 249
		DEFAULT => -44
	},
	{#State 250
		DEFAULT => -42
	},
	{#State 251
		DEFAULT => -60
	},
	{#State 252
		ACTIONS => {
			'INTEGER' => 156
		},
		GOTOS => {
			'int_str' => 170,
			'integer' => 315
		}
	},
	{#State 253
		DEFAULT => -36
	},
	{#State 254
		ACTIONS => {
			'DATE' => 15,
			'INTEGER' => 19,
			'KW_DATE' => 316,
			'SYMBOL' => 27
		},
		GOTOS => {
			's_biblname' => 317,
			'symbol' => 318
		}
	},
	{#State 255
		ACTIONS => {
			"," => 319,
			"]" => 320,
			'DATE' => 321,
			'INTEGER' => 322
		},
		GOTOS => {
			'date' => 323
		}
	},
	{#State 256
		DEFAULT => -73
	},
	{#State 257
		ACTIONS => {
			"=" => 106,
			'SYMBOL' => 324
		},
		DEFAULT => -110,
		GOTOS => {
			'matchid' => 325,
			'matchid_eq' => 110,
			'qfb_ctxkey' => 326,
			'qfbc_matchref' => 327,
			'sym_str' => 328
		}
	},
	{#State 258
		DEFAULT => -64
	},
	{#State 259
		DEFAULT => -68
	},
	{#State 260
		DEFAULT => -66
	},
	{#State 261
		ACTIONS => {
			"," => 329,
			"]" => 330,
			'INTEGER' => 156
		},
		GOTOS => {
			'int_str' => 331
		}
	},
	{#State 262
		DEFAULT => -70
	},
	{#State 263
		ACTIONS => {
			'DATE' => 15,
			'INTEGER' => 19,
			'SYMBOL' => 27
		},
		GOTOS => {
			's_biblname' => 332,
			'symbol' => 318
		}
	},
	{#State 264
		ACTIONS => {
			'DATE' => 321,
			'INTEGER' => 322
		},
		GOTOS => {
			'date' => 333
		}
	},
	{#State 265
		ACTIONS => {
			'INTEGER' => 156
		},
		GOTOS => {
			'int_str' => 334
		}
	},
	{#State 266
		ACTIONS => {
			'DATE' => 15,
			'INTEGER' => 19,
			'SYMBOL' => 27
		},
		GOTOS => {
			'symbol' => 335
		}
	},
	{#State 267
		DEFAULT => -34
	},
	{#State 268
		ACTIONS => {
			'DATE' => 15,
			'INTEGER' => 19,
			'KW_DATE' => 336,
			'SYMBOL' => 27
		},
		GOTOS => {
			's_biblname' => 337,
			'symbol' => 318
		}
	},
	{#State 269
		DEFAULT => -72
	},
	{#State 270
		DEFAULT => -63
	},
	{#State 271
		DEFAULT => -67
	},
	{#State 272
		DEFAULT => -65
	},
	{#State 273
		DEFAULT => -69
	},
	{#State 274
		ACTIONS => {
			'INTEGER' => 156
		},
		GOTOS => {
			'int_str' => 338
		}
	},
	{#State 275
		ACTIONS => {
			'INTEGER' => 156
		},
		GOTOS => {
			'int_str' => 339
		}
	},
	{#State 276
		ACTIONS => {
			"]" => 340,
			'INTEGER' => 156
		},
		GOTOS => {
			'int_str' => 341
		}
	},
	{#State 277
		DEFAULT => -278
	},
	{#State 278
		DEFAULT => -38
	},
	{#State 279
		DEFAULT => -277
	},
	{#State 280
		ACTIONS => {
			"!" => 1,
			"\"" => 2,
			"\$" => 3,
			"%" => 4,
			"(" => 5,
			"*" => 6,
			"<" => 7,
			"\@" => 8,
			"[" => 9,
			"^" => 10,
			"{" => 11,
			'AT_LBRACE' => 12,
			'COLON_LBRACE' => 13,
			'COUNT' => 14,
			'DATE' => 15,
			'DOLLAR_DOT' => 16,
			'INDEX' => 17,
			'INFIX' => 18,
			'INTEGER' => 19,
			'KEYS' => 20,
			'NEAR' => 21,
			'NEG_REGEX' => 22,
			'PREFIX' => 23,
			'REGEX' => 24,
			'STAR_LBRACE' => 25,
			'SUFFIX' => 26,
			'SYMBOL' => 27
		},
		GOTOS => {
			'count_query' => 159,
			'index' => 29,
			'neg_regex' => 30,
			'q_clause' => 31,
			'qc_basic' => 32,
			'qc_boolean' => 33,
			'qc_concat' => 34,
			'qc_matchid' => 35,
			'qc_near' => 36,
			'qc_phrase' => 37,
			'qc_tokens' => 38,
			'qc_word' => 39,
			'query_conditions' => 160,
			'qw_anchor' => 42,
			'qw_any' => 43,
			'qw_bareword' => 44,
			'qw_chunk' => 45,
			'qw_exact' => 46,
			'qw_infix' => 47,
			'qw_infix_set' => 48,
			'qw_keys' => 49,
			'qw_lemma' => 50,
			'qw_listfile' => 51,
			'qw_matchid' => 52,
			'qw_morph' => 53,
			'qw_prefix' => 54,
			'qw_prefix_set' => 55,
			'qw_regex' => 56,
			'qw_set_exact' => 57,
			'qw_set_infl' => 58,
			'qw_suffix' => 59,
			'qw_suffix_set' => 60,
			'qw_thesaurus' => 61,
			'qw_with' => 62,
			'qw_withor' => 63,
			'qw_without' => 64,
			'qwk_countsrc' => 342,
			'qwk_indextuple' => 65,
			'regex' => 66,
			's_index' => 67,
			's_infix' => 68,
			's_prefix' => 69,
			's_suffix' => 70,
			's_word' => 71,
			'symbol' => 72
		}
	},
	{#State 281
		DEFAULT => -199
	},
	{#State 282
		ACTIONS => {
			'DATE' => 15,
			'INTEGER' => 19,
			'SYMBOL' => 27
		},
		GOTOS => {
			's_semclass' => 343,
			'symbol' => 96
		}
	},
	{#State 283
		DEFAULT => -205
	},
	{#State 284
		DEFAULT => -171
	},
	{#State 285
		ACTIONS => {
			"," => 144,
			";" => 145,
			"]" => 344,
			'DATE' => 15,
			'INTEGER' => 19,
			'SYMBOL' => 27
		},
		GOTOS => {
			's_morphitem' => 147,
			'symbol' => 148
		}
	},
	{#State 286
		DEFAULT => -201
	},
	{#State 287
		ACTIONS => {
			"," => 149,
			"}" => 345,
			'DATE' => 15,
			'INTEGER' => 19,
			'RBRACE_STAR' => 346,
			'SYMBOL' => 27
		},
		GOTOS => {
			's_word' => 152,
			'symbol' => 72
		}
	},
	{#State 288
		ACTIONS => {
			"," => 149,
			"}" => 347,
			'DATE' => 15,
			'INTEGER' => 19,
			'SYMBOL' => 27
		},
		GOTOS => {
			's_word' => 152,
			'symbol' => 72
		}
	},
	{#State 289
		ACTIONS => {
			"," => 149,
			"}" => 348,
			'DATE' => 15,
			'INTEGER' => 19,
			'RBRACE_STAR' => 349,
			'SYMBOL' => 27
		},
		GOTOS => {
			's_word' => 152,
			'symbol' => 72
		}
	},
	{#State 290
		ACTIONS => {
			'EXPANDER' => 233
		},
		DEFAULT => -169,
		GOTOS => {
			's_expander' => 234
		}
	},
	{#State 291
		ACTIONS => {
			"=" => 106,
			'WITH' => 117,
			'WITHOR' => 118,
			'WITHOUT' => 119
		},
		DEFAULT => -224,
		GOTOS => {
			'matchid' => 120,
			'matchid_eq' => 110
		}
	},
	{#State 292
		ACTIONS => {
			"=" => 106,
			'WITH' => 117,
			'WITHOR' => 118,
			'WITHOUT' => 119
		},
		DEFAULT => -227,
		GOTOS => {
			'matchid' => 120,
			'matchid_eq' => 110
		}
	},
	{#State 293
		ACTIONS => {
			"=" => 106,
			'WITH' => 117,
			'WITHOR' => 118,
			'WITHOUT' => 119
		},
		DEFAULT => -226,
		GOTOS => {
			'matchid' => 120,
			'matchid_eq' => 110
		}
	},
	{#State 294
		ACTIONS => {
			"=" => 106,
			'WITH' => 117,
			'WITHOR' => 118,
			'WITHOUT' => 119
		},
		DEFAULT => -225,
		GOTOS => {
			'matchid' => 120,
			'matchid_eq' => 110
		}
	},
	{#State 295
		DEFAULT => -238
	},
	{#State 296
		DEFAULT => -4,
		GOTOS => {
			'count_filters' => 350
		}
	},
	{#State 297
		ACTIONS => {
			"\$" => 133,
			"(" => 351,
			"*" => 352,
			"\@" => 353,
			"[" => 354,
			'DATE' => 15,
			'INDEX' => 17,
			'INTEGER' => 19,
			'KW_DATE' => 355,
			'KW_FILEID' => 356,
			'KW_FILENAME' => 357,
			'SYMBOL' => 27
		},
		DEFAULT => -230,
		GOTOS => {
			'count_key' => 358,
			'count_key_const' => 359,
			'count_key_meta' => 360,
			'count_key_token' => 361,
			'index' => 29,
			'l_countkeys' => 362,
			's_biblname' => 363,
			's_index' => 364,
			'symbol' => 318
		}
	},
	{#State 298
		ACTIONS => {
			"[" => 365,
			'INTEGER' => 156
		},
		GOTOS => {
			'int_str' => 170,
			'integer' => 366
		}
	},
	{#State 299
		DEFAULT => -21
	},
	{#State 300
		DEFAULT => -19
	},
	{#State 301
		DEFAULT => -20
	},
	{#State 302
		DEFAULT => -18
	},
	{#State 303
		ACTIONS => {
			"[" => 367,
			'INTEGER' => 156
		},
		GOTOS => {
			'int_str' => 170,
			'integer' => 368
		}
	},
	{#State 304
		DEFAULT => -6
	},
	{#State 305
		DEFAULT => -5
	},
	{#State 306
		DEFAULT => -8
	},
	{#State 307
		DEFAULT => -7
	},
	{#State 308
		DEFAULT => -9
	},
	{#State 309
		ACTIONS => {
			"[" => 369
		},
		DEFAULT => -22,
		GOTOS => {
			'count_sort_minmax' => 370
		}
	},
	{#State 310
		DEFAULT => -10
	},
	{#State 311
		ACTIONS => {
			"," => 371,
			"=" => 106
		},
		GOTOS => {
			'matchid' => 116,
			'matchid_eq' => 110
		}
	},
	{#State 312
		ACTIONS => {
			"," => 372
		},
		DEFAULT => -119
	},
	{#State 313
		DEFAULT => -240
	},
	{#State 314
		DEFAULT => -275
	},
	{#State 315
		ACTIONS => {
			"]" => 373
		}
	},
	{#State 316
		ACTIONS => {
			"," => 374
		},
		DEFAULT => -97,
		GOTOS => {
			'qfb_bibl' => 375,
			'qfb_bibl_ne' => 376
		}
	},
	{#State 317
		ACTIONS => {
			"," => 374
		},
		DEFAULT => -97,
		GOTOS => {
			'qfb_bibl' => 377,
			'qfb_bibl_ne' => 376
		}
	},
	{#State 318
		DEFAULT => -276
	},
	{#State 319
		ACTIONS => {
			'DATE' => 321,
			'INTEGER' => 322
		},
		GOTOS => {
			'date' => 378
		}
	},
	{#State 320
		DEFAULT => -92
	},
	{#State 321
		DEFAULT => -297
	},
	{#State 322
		DEFAULT => -298
	},
	{#State 323
		ACTIONS => {
			"," => 379,
			"]" => 380
		}
	},
	{#State 324
		DEFAULT => -284
	},
	{#State 325
		DEFAULT => -111
	},
	{#State 326
		ACTIONS => {
			"," => 374,
			"]" => 381
		},
		GOTOS => {
			'qfb_bibl_ne' => 382
		}
	},
	{#State 327
		ACTIONS => {
			"+" => 383,
			"-" => 384,
			'INTEGER' => 156
		},
		DEFAULT => -112,
		GOTOS => {
			'int_str' => 170,
			'integer' => 385,
			'qfbc_offset' => 386
		}
	},
	{#State 328
		ACTIONS => {
			"=" => 106
		},
		DEFAULT => -110,
		GOTOS => {
			'matchid' => 325,
			'matchid_eq' => 110,
			'qfbc_matchref' => 387
		}
	},
	{#State 329
		ACTIONS => {
			"]" => 388,
			'INTEGER' => 156
		},
		GOTOS => {
			'int_str' => 389
		}
	},
	{#State 330
		DEFAULT => -85
	},
	{#State 331
		ACTIONS => {
			"," => 390,
			"]" => 391
		}
	},
	{#State 332
		ACTIONS => {
			"," => 392
		}
	},
	{#State 333
		ACTIONS => {
			"]" => 393
		}
	},
	{#State 334
		ACTIONS => {
			"]" => 394
		}
	},
	{#State 335
		ACTIONS => {
			"]" => 395
		}
	},
	{#State 336
		ACTIONS => {
			"," => 374
		},
		DEFAULT => -97,
		GOTOS => {
			'qfb_bibl' => 396,
			'qfb_bibl_ne' => 376
		}
	},
	{#State 337
		ACTIONS => {
			"," => 374
		},
		DEFAULT => -97,
		GOTOS => {
			'qfb_bibl' => 397,
			'qfb_bibl_ne' => 376
		}
	},
	{#State 338
		ACTIONS => {
			"(" => 398,
			"*" => 352,
			"\@" => 353,
			'DATE' => 15,
			'INTEGER' => 19,
			'KW_DATE' => 355,
			'KW_FILEID' => 356,
			'KW_FILENAME' => 357,
			'SYMBOL' => 27
		},
		DEFAULT => -233,
		GOTOS => {
			'count_key_const' => 399,
			'count_key_meta' => 400,
			'l_prunekeys' => 401,
			'prune_key' => 402,
			's_biblname' => 363,
			'symbol' => 318
		}
	},
	{#State 339
		ACTIONS => {
			"(" => 398,
			"*" => 352,
			"\@" => 353,
			'DATE' => 15,
			'INTEGER' => 19,
			'KW_DATE' => 355,
			'KW_FILEID' => 356,
			'KW_FILENAME' => 357,
			'SYMBOL' => 27
		},
		DEFAULT => -233,
		GOTOS => {
			'count_key_const' => 399,
			'count_key_meta' => 400,
			'l_prunekeys' => 403,
			'prune_key' => 402,
			's_biblname' => 363,
			'symbol' => 318
		}
	},
	{#State 340
		DEFAULT => -76
	},
	{#State 341
		ACTIONS => {
			"]" => 404
		}
	},
	{#State 342
		ACTIONS => {
			")" => 405
		}
	},
	{#State 343
		ACTIONS => {
			"}" => 406
		}
	},
	{#State 344
		DEFAULT => -197
	},
	{#State 345
		DEFAULT => -228,
		GOTOS => {
			'l_txchain' => 407
		}
	},
	{#State 346
		DEFAULT => -191
	},
	{#State 347
		DEFAULT => -179
	},
	{#State 348
		DEFAULT => -193
	},
	{#State 349
		DEFAULT => -189
	},
	{#State 350
		ACTIONS => {
			'BY' => 297,
			'CLIMIT' => 298,
			'GREATER_BY_COUNT' => 299,
			'GREATER_BY_KEY' => 300,
			'KW_COMMENT' => 186,
			'LESS_BY_COUNT' => 301,
			'LESS_BY_KEY' => 302,
			'SAMPLE' => 303
		},
		DEFAULT => -3,
		GOTOS => {
			'count_by' => 304,
			'count_filter' => 305,
			'count_limit' => 306,
			'count_sample' => 307,
			'count_sort' => 308,
			'count_sort_op' => 309,
			'q_comment' => 310
		}
	},
	{#State 351
		ACTIONS => {
			"\$" => 133,
			"(" => 351,
			"*" => 352,
			"\@" => 353,
			'DATE' => 15,
			'INDEX' => 17,
			'INTEGER' => 19,
			'KW_DATE' => 355,
			'KW_FILEID' => 356,
			'KW_FILENAME' => 357,
			'SYMBOL' => 27
		},
		GOTOS => {
			'count_key' => 408,
			'count_key_const' => 359,
			'count_key_meta' => 360,
			'count_key_token' => 361,
			'index' => 29,
			's_biblname' => 363,
			's_index' => 364,
			'symbol' => 318
		}
	},
	{#State 352
		DEFAULT => -251
	},
	{#State 353
		ACTIONS => {
			'DATE' => 15,
			'INTEGER' => 19,
			'SYMBOL' => 27
		},
		GOTOS => {
			'symbol' => 409
		}
	},
	{#State 354
		ACTIONS => {
			"\$" => 133,
			"(" => 351,
			"*" => 352,
			"\@" => 353,
			'DATE' => 15,
			'INDEX' => 17,
			'INTEGER' => 19,
			'KW_DATE' => 355,
			'KW_FILEID' => 356,
			'KW_FILENAME' => 357,
			'SYMBOL' => 27
		},
		DEFAULT => -230,
		GOTOS => {
			'count_key' => 358,
			'count_key_const' => 359,
			'count_key_meta' => 360,
			'count_key_token' => 361,
			'index' => 29,
			'l_countkeys' => 410,
			's_biblname' => 363,
			's_index' => 364,
			'symbol' => 318
		}
	},
	{#State 355
		ACTIONS => {
			"/" => 411
		},
		DEFAULT => -255
	},
	{#State 356
		DEFAULT => -253
	},
	{#State 357
		DEFAULT => -254
	},
	{#State 358
		ACTIONS => {
			"~" => 412
		},
		DEFAULT => -231
	},
	{#State 359
		DEFAULT => -242
	},
	{#State 360
		DEFAULT => -243
	},
	{#State 361
		DEFAULT => -244
	},
	{#State 362
		ACTIONS => {
			"," => 413
		},
		DEFAULT => -11
	},
	{#State 363
		DEFAULT => -257
	},
	{#State 364
		ACTIONS => {
			"=" => 106
		},
		DEFAULT => -259,
		GOTOS => {
			'ck_matchid' => 414,
			'matchid' => 415,
			'matchid_eq' => 110
		}
	},
	{#State 365
		ACTIONS => {
			'INTEGER' => 156
		},
		GOTOS => {
			'int_str' => 170,
			'integer' => 416
		}
	},
	{#State 366
		DEFAULT => -15
	},
	{#State 367
		ACTIONS => {
			'INTEGER' => 156
		},
		GOTOS => {
			'int_str' => 170,
			'integer' => 417
		}
	},
	{#State 368
		DEFAULT => -13
	},
	{#State 369
		ACTIONS => {
			"," => 418,
			"]" => 419,
			'DATE' => 15,
			'INTEGER' => 19,
			'SYMBOL' => 27
		},
		GOTOS => {
			'symbol' => 420
		}
	},
	{#State 370
		DEFAULT => -17
	},
	{#State 371
		ACTIONS => {
			"\"" => 2,
			"\$" => 3,
			"%" => 4,
			"(" => 162,
			"*" => 6,
			"<" => 7,
			"\@" => 8,
			"[" => 9,
			"^" => 10,
			"{" => 11,
			'AT_LBRACE' => 12,
			'COLON_LBRACE' => 13,
			'DATE' => 15,
			'DOLLAR_DOT' => 16,
			'INDEX' => 17,
			'INFIX' => 18,
			'INTEGER' => 421,
			'KEYS' => 20,
			'NEG_REGEX' => 22,
			'PREFIX' => 23,
			'REGEX' => 24,
			'STAR_LBRACE' => 25,
			'SUFFIX' => 26,
			'SYMBOL' => 27
		},
		GOTOS => {
			'index' => 29,
			'int_str' => 170,
			'integer' => 422,
			'neg_regex' => 30,
			'qc_phrase' => 37,
			'qc_tokens' => 423,
			'qc_word' => 39,
			'qw_anchor' => 42,
			'qw_any' => 43,
			'qw_bareword' => 44,
			'qw_chunk' => 45,
			'qw_exact' => 46,
			'qw_infix' => 47,
			'qw_infix_set' => 48,
			'qw_keys' => 49,
			'qw_lemma' => 50,
			'qw_listfile' => 51,
			'qw_matchid' => 52,
			'qw_morph' => 53,
			'qw_prefix' => 54,
			'qw_prefix_set' => 55,
			'qw_regex' => 56,
			'qw_set_exact' => 57,
			'qw_set_infl' => 58,
			'qw_suffix' => 59,
			'qw_suffix_set' => 60,
			'qw_thesaurus' => 61,
			'qw_with' => 62,
			'qw_withor' => 63,
			'qw_without' => 64,
			'qwk_indextuple' => 65,
			'regex' => 66,
			's_index' => 67,
			's_infix' => 68,
			's_prefix' => 69,
			's_suffix' => 70,
			's_word' => 71,
			'symbol' => 72
		}
	},
	{#State 372
		ACTIONS => {
			'DATE' => 15,
			'INTEGER' => 19,
			'SYMBOL' => 27
		},
		GOTOS => {
			's_subcorpus' => 424,
			'symbol' => 314
		}
	},
	{#State 373
		DEFAULT => -37
	},
	{#State 374
		ACTIONS => {
			"," => 425,
			'DATE' => 15,
			'INTEGER' => 19,
			'SYMBOL' => 27
		},
		DEFAULT => -99,
		GOTOS => {
			'symbol' => 426
		}
	},
	{#State 375
		ACTIONS => {
			"]" => 427
		}
	},
	{#State 376
		DEFAULT => -98
	},
	{#State 377
		ACTIONS => {
			"]" => 428
		}
	},
	{#State 378
		ACTIONS => {
			"]" => 429
		}
	},
	{#State 379
		ACTIONS => {
			"]" => 430,
			'DATE' => 321,
			'INTEGER' => 322
		},
		GOTOS => {
			'date' => 431
		}
	},
	{#State 380
		DEFAULT => -93
	},
	{#State 381
		DEFAULT => -106
	},
	{#State 382
		ACTIONS => {
			"]" => 432
		}
	},
	{#State 383
		ACTIONS => {
			'INTEGER' => 156
		},
		GOTOS => {
			'int_str' => 170,
			'integer' => 433
		}
	},
	{#State 384
		ACTIONS => {
			'INTEGER' => 156
		},
		GOTOS => {
			'int_str' => 170,
			'integer' => 434
		}
	},
	{#State 385
		DEFAULT => -113
	},
	{#State 386
		DEFAULT => -109
	},
	{#State 387
		ACTIONS => {
			"+" => 383,
			"-" => 384,
			'INTEGER' => 156
		},
		DEFAULT => -112,
		GOTOS => {
			'int_str' => 170,
			'integer' => 385,
			'qfbc_offset' => 435
		}
	},
	{#State 388
		DEFAULT => -86
	},
	{#State 389
		ACTIONS => {
			"]" => 436
		}
	},
	{#State 390
		ACTIONS => {
			"]" => 437,
			'INTEGER' => 156
		},
		GOTOS => {
			'int_str' => 438
		}
	},
	{#State 391
		DEFAULT => -87
	},
	{#State 392
		ACTIONS => {
			"{" => 439,
			'DATE' => 15,
			'INFIX' => 18,
			'INTEGER' => 19,
			'NEG_REGEX' => 22,
			'PREFIX' => 23,
			'REGEX' => 24,
			'SUFFIX' => 26,
			'SYMBOL' => 27
		},
		GOTOS => {
			'neg_regex' => 440,
			'regex' => 441,
			's_infix' => 442,
			's_prefix' => 443,
			's_suffix' => 444,
			'symbol' => 445
		}
	},
	{#State 393
		DEFAULT => -74
	},
	{#State 394
		DEFAULT => -71
	},
	{#State 395
		DEFAULT => -35
	},
	{#State 396
		ACTIONS => {
			"]" => 446
		}
	},
	{#State 397
		ACTIONS => {
			"]" => 447
		}
	},
	{#State 398
		ACTIONS => {
			"(" => 398,
			"*" => 352,
			"\@" => 353,
			'DATE' => 15,
			'INTEGER' => 19,
			'KW_DATE' => 355,
			'KW_FILEID' => 356,
			'KW_FILENAME' => 357,
			'SYMBOL' => 27
		},
		GOTOS => {
			'count_key_const' => 399,
			'count_key_meta' => 400,
			'prune_key' => 448,
			's_biblname' => 363,
			'symbol' => 318
		}
	},
	{#State 399
		DEFAULT => -247
	},
	{#State 400
		DEFAULT => -248
	},
	{#State 401
		ACTIONS => {
			"," => 449,
			"]" => 450
		}
	},
	{#State 402
		ACTIONS => {
			"~" => 451
		},
		DEFAULT => -234
	},
	{#State 403
		ACTIONS => {
			"," => 449,
			"]" => 452
		}
	},
	{#State 404
		DEFAULT => -77
	},
	{#State 405
		DEFAULT => -210
	},
	{#State 406
		DEFAULT => -195
	},
	{#State 407
		ACTIONS => {
			'EXPANDER' => 233
		},
		DEFAULT => -181,
		GOTOS => {
			's_expander' => 234
		}
	},
	{#State 408
		ACTIONS => {
			")" => 453,
			"~" => 412
		}
	},
	{#State 409
		DEFAULT => -252
	},
	{#State 410
		ACTIONS => {
			"," => 413,
			"]" => 454
		}
	},
	{#State 411
		ACTIONS => {
			'INTEGER' => 156
		},
		GOTOS => {
			'int_str' => 170,
			'integer' => 455
		}
	},
	{#State 412
		ACTIONS => {
			'REGEX_SEARCH' => 456
		},
		GOTOS => {
			'replace_regex' => 457
		}
	},
	{#State 413
		ACTIONS => {
			"\$" => 133,
			"(" => 351,
			"*" => 352,
			"\@" => 353,
			'DATE' => 15,
			'INDEX' => 17,
			'INTEGER' => 19,
			'KW_DATE' => 355,
			'KW_FILEID' => 356,
			'KW_FILENAME' => 357,
			'SYMBOL' => 27
		},
		GOTOS => {
			'count_key' => 458,
			'count_key_const' => 359,
			'count_key_meta' => 360,
			'count_key_token' => 361,
			'index' => 29,
			's_biblname' => 363,
			's_index' => 364,
			'symbol' => 318
		}
	},
	{#State 414
		ACTIONS => {
			"+" => 459,
			"-" => 460,
			'INTEGER' => 156
		},
		DEFAULT => -261,
		GOTOS => {
			'ck_offset' => 461,
			'int_str' => 170,
			'integer' => 462
		}
	},
	{#State 415
		DEFAULT => -260
	},
	{#State 416
		ACTIONS => {
			"]" => 463
		}
	},
	{#State 417
		ACTIONS => {
			"]" => 464
		}
	},
	{#State 418
		ACTIONS => {
			"]" => 465,
			'DATE' => 15,
			'INTEGER' => 19,
			'SYMBOL' => 27
		},
		GOTOS => {
			'symbol' => 466
		}
	},
	{#State 419
		DEFAULT => -23
	},
	{#State 420
		ACTIONS => {
			"," => 467,
			"]" => 468
		}
	},
	{#State 421
		ACTIONS => {
			")" => -295
		},
		DEFAULT => -280
	},
	{#State 422
		ACTIONS => {
			")" => 469
		}
	},
	{#State 423
		ACTIONS => {
			"," => 470,
			"=" => 106
		},
		GOTOS => {
			'matchid' => 116,
			'matchid_eq' => 110
		}
	},
	{#State 424
		DEFAULT => -241
	},
	{#State 425
		ACTIONS => {
			'DATE' => 15,
			'INTEGER' => 19,
			'SYMBOL' => 27
		},
		DEFAULT => -100,
		GOTOS => {
			'symbol' => 471
		}
	},
	{#State 426
		ACTIONS => {
			"," => 472
		},
		DEFAULT => -101
	},
	{#State 427
		DEFAULT => -79
	},
	{#State 428
		DEFAULT => -81
	},
	{#State 429
		DEFAULT => -96
	},
	{#State 430
		DEFAULT => -94
	},
	{#State 431
		ACTIONS => {
			"]" => 473
		}
	},
	{#State 432
		DEFAULT => -107
	},
	{#State 433
		DEFAULT => -114
	},
	{#State 434
		DEFAULT => -115
	},
	{#State 435
		DEFAULT => -108
	},
	{#State 436
		DEFAULT => -90
	},
	{#State 437
		DEFAULT => -88
	},
	{#State 438
		ACTIONS => {
			"]" => 474
		}
	},
	{#State 439
		DEFAULT => -215,
		GOTOS => {
			'l_set' => 475
		}
	},
	{#State 440
		ACTIONS => {
			"]" => 476
		}
	},
	{#State 441
		ACTIONS => {
			"]" => 477
		}
	},
	{#State 442
		ACTIONS => {
			"]" => 478
		}
	},
	{#State 443
		ACTIONS => {
			"]" => 479
		}
	},
	{#State 444
		ACTIONS => {
			"]" => 480
		}
	},
	{#State 445
		ACTIONS => {
			"]" => 481
		}
	},
	{#State 446
		DEFAULT => -78
	},
	{#State 447
		DEFAULT => -80
	},
	{#State 448
		ACTIONS => {
			")" => 482,
			"~" => 451
		}
	},
	{#State 449
		ACTIONS => {
			"(" => 398,
			"*" => 352,
			"\@" => 353,
			'DATE' => 15,
			'INTEGER' => 19,
			'KW_DATE' => 355,
			'KW_FILEID' => 356,
			'KW_FILENAME' => 357,
			'SYMBOL' => 27
		},
		GOTOS => {
			'count_key_const' => 399,
			'count_key_meta' => 400,
			'prune_key' => 483,
			's_biblname' => 363,
			'symbol' => 318
		}
	},
	{#State 450
		DEFAULT => -82
	},
	{#State 451
		ACTIONS => {
			'REGEX_SEARCH' => 456
		},
		GOTOS => {
			'replace_regex' => 484
		}
	},
	{#State 452
		DEFAULT => -83
	},
	{#State 453
		DEFAULT => -246
	},
	{#State 454
		DEFAULT => -12
	},
	{#State 455
		DEFAULT => -256
	},
	{#State 456
		ACTIONS => {
			'REGEX_REPLACE' => 485
		}
	},
	{#State 457
		DEFAULT => -245
	},
	{#State 458
		ACTIONS => {
			"~" => 412
		},
		DEFAULT => -232
	},
	{#State 459
		ACTIONS => {
			'INTEGER' => 156
		},
		GOTOS => {
			'int_str' => 170,
			'integer' => 486
		}
	},
	{#State 460
		ACTIONS => {
			'INTEGER' => 156
		},
		GOTOS => {
			'int_str' => 170,
			'integer' => 487
		}
	},
	{#State 461
		DEFAULT => -258
	},
	{#State 462
		DEFAULT => -262
	},
	{#State 463
		DEFAULT => -16
	},
	{#State 464
		DEFAULT => -14
	},
	{#State 465
		DEFAULT => -24
	},
	{#State 466
		ACTIONS => {
			"]" => 488
		}
	},
	{#State 467
		ACTIONS => {
			"]" => 489,
			'DATE' => 15,
			'INTEGER' => 19,
			'SYMBOL' => 27
		},
		GOTOS => {
			'symbol' => 490
		}
	},
	{#State 468
		DEFAULT => -25
	},
	{#State 469
		DEFAULT => -135
	},
	{#State 470
		ACTIONS => {
			'INTEGER' => 156
		},
		GOTOS => {
			'int_str' => 170,
			'integer' => 491
		}
	},
	{#State 471
		DEFAULT => -103
	},
	{#State 472
		ACTIONS => {
			'DATE' => 15,
			'INTEGER' => 19,
			'SYMBOL' => 27
		},
		DEFAULT => -102,
		GOTOS => {
			'symbol' => 492
		}
	},
	{#State 473
		DEFAULT => -95
	},
	{#State 474
		DEFAULT => -89
	},
	{#State 475
		ACTIONS => {
			"," => 149,
			"}" => 493,
			'DATE' => 15,
			'INTEGER' => 19,
			'SYMBOL' => 27
		},
		GOTOS => {
			's_word' => 152,
			'symbol' => 72
		}
	},
	{#State 476
		DEFAULT => -55
	},
	{#State 477
		DEFAULT => -54
	},
	{#State 478
		DEFAULT => -58
	},
	{#State 479
		DEFAULT => -56
	},
	{#State 480
		DEFAULT => -57
	},
	{#State 481
		DEFAULT => -53
	},
	{#State 482
		DEFAULT => -250
	},
	{#State 483
		ACTIONS => {
			"~" => 451
		},
		DEFAULT => -235
	},
	{#State 484
		DEFAULT => -249
	},
	{#State 485
		ACTIONS => {
			'REGOPT' => 494
		},
		DEFAULT => -293
	},
	{#State 486
		DEFAULT => -263
	},
	{#State 487
		DEFAULT => -264
	},
	{#State 488
		DEFAULT => -27
	},
	{#State 489
		DEFAULT => -26
	},
	{#State 490
		ACTIONS => {
			"]" => 495
		}
	},
	{#State 491
		ACTIONS => {
			")" => 496
		}
	},
	{#State 492
		DEFAULT => -104
	},
	{#State 493
		ACTIONS => {
			"]" => 497
		}
	},
	{#State 494
		DEFAULT => -294
	},
	{#State 495
		DEFAULT => -28
	},
	{#State 496
		DEFAULT => -136
	},
	{#State 497
		DEFAULT => -59
	}
],
                                  yyrules  =>
[
	[#Rule 0
		 '$start', 2, undef
	],
	[#Rule 1
		 'query', 2,
sub
#line 105 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->SetQuery($_[1]) }
	],
	[#Rule 2
		 'query', 2,
sub
#line 106 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->SetQuery($_[1]) }
	],
	[#Rule 3
		 'count_query', 6,
sub
#line 113 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newCountQuery($_[3], {%{$_[4]}, %{$_[6]}}) }
	],
	[#Rule 4
		 'count_filters', 0,
sub
#line 118 "lib/DDC/PP/yyqparser.yp"
{ {} }
	],
	[#Rule 5
		 'count_filters', 2,
sub
#line 119 "lib/DDC/PP/yyqparser.yp"
{ my $tmp={%{$_[1]}, %{$_[2]}}; $tmp }
	],
	[#Rule 6
		 'count_filter', 1,
sub
#line 124 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 7
		 'count_filter', 1,
sub
#line 125 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 8
		 'count_filter', 1,
sub
#line 126 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 9
		 'count_filter', 1,
sub
#line 127 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 10
		 'count_filter', 1,
sub
#line 128 "lib/DDC/PP/yyqparser.yp"
{ {}    }
	],
	[#Rule 11
		 'count_by', 2,
sub
#line 132 "lib/DDC/PP/yyqparser.yp"
{ {Keys=>$_[2]} }
	],
	[#Rule 12
		 'count_by', 4,
sub
#line 133 "lib/DDC/PP/yyqparser.yp"
{ {Keys=>$_[3]} }
	],
	[#Rule 13
		 'count_sample', 2,
sub
#line 137 "lib/DDC/PP/yyqparser.yp"
{ {Sample=>$_[2]} }
	],
	[#Rule 14
		 'count_sample', 4,
sub
#line 138 "lib/DDC/PP/yyqparser.yp"
{ {Sample=>$_[3]} }
	],
	[#Rule 15
		 'count_limit', 2,
sub
#line 143 "lib/DDC/PP/yyqparser.yp"
{ {Limit=>$_[2]} }
	],
	[#Rule 16
		 'count_limit', 4,
sub
#line 144 "lib/DDC/PP/yyqparser.yp"
{ {Limit=>$_[3]} }
	],
	[#Rule 17
		 'count_sort', 2,
sub
#line 148 "lib/DDC/PP/yyqparser.yp"
{ $_[2]->{Sort}=$_[1]; $_[2] }
	],
	[#Rule 18
		 'count_sort_op', 1,
sub
#line 152 "lib/DDC/PP/yyqparser.yp"
{ DDC::PP::LessByCountKey }
	],
	[#Rule 19
		 'count_sort_op', 1,
sub
#line 153 "lib/DDC/PP/yyqparser.yp"
{ DDC::PP::GreaterByCountKey }
	],
	[#Rule 20
		 'count_sort_op', 1,
sub
#line 154 "lib/DDC/PP/yyqparser.yp"
{ DDC::PP::LessByCountValue }
	],
	[#Rule 21
		 'count_sort_op', 1,
sub
#line 155 "lib/DDC/PP/yyqparser.yp"
{ DDC::PP::GreaterByCountValue }
	],
	[#Rule 22
		 'count_sort_minmax', 0,
sub
#line 159 "lib/DDC/PP/yyqparser.yp"
{ {} }
	],
	[#Rule 23
		 'count_sort_minmax', 2,
sub
#line 160 "lib/DDC/PP/yyqparser.yp"
{ {} }
	],
	[#Rule 24
		 'count_sort_minmax', 3,
sub
#line 161 "lib/DDC/PP/yyqparser.yp"
{ {} }
	],
	[#Rule 25
		 'count_sort_minmax', 3,
sub
#line 162 "lib/DDC/PP/yyqparser.yp"
{ {Lo=>$_[2]} }
	],
	[#Rule 26
		 'count_sort_minmax', 4,
sub
#line 163 "lib/DDC/PP/yyqparser.yp"
{ {Lo=>$_[2]} }
	],
	[#Rule 27
		 'count_sort_minmax', 4,
sub
#line 164 "lib/DDC/PP/yyqparser.yp"
{ {Hi=>$_[3]} }
	],
	[#Rule 28
		 'count_sort_minmax', 5,
sub
#line 165 "lib/DDC/PP/yyqparser.yp"
{ {Lo=>$_[2],Hi=>$_[4]} }
	],
	[#Rule 29
		 'query_conditions', 2,
sub
#line 172 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 30
		 'q_filters', 0,
sub
#line 178 "lib/DDC/PP/yyqparser.yp"
{ undef }
	],
	[#Rule 31
		 'q_filters', 2,
sub
#line 179 "lib/DDC/PP/yyqparser.yp"
{ undef }
	],
	[#Rule 32
		 'q_filters', 2,
sub
#line 180 "lib/DDC/PP/yyqparser.yp"
{ undef }
	],
	[#Rule 33
		 'q_filters', 2,
sub
#line 181 "lib/DDC/PP/yyqparser.yp"
{ undef }
	],
	[#Rule 34
		 'q_comment', 2,
sub
#line 185 "lib/DDC/PP/yyqparser.yp"
{ push(@{$_[0]->qopts->{Comments}}, $_[2]); undef }
	],
	[#Rule 35
		 'q_comment', 4,
sub
#line 186 "lib/DDC/PP/yyqparser.yp"
{ push(@{$_[0]->qopts->{Comments}}, $_[3]); undef }
	],
	[#Rule 36
		 'q_flag', 2,
sub
#line 190 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->qopts->{ContextSentencesCount} = $_[2]; undef }
	],
	[#Rule 37
		 'q_flag', 4,
sub
#line 191 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->qopts->{ContextSentencesCount} = $_[3]; undef }
	],
	[#Rule 38
		 'q_flag', 2,
sub
#line 192 "lib/DDC/PP/yyqparser.yp"
{ push(@{$_[0]->qopts->{Within}}, $_[2]); undef }
	],
	[#Rule 39
		 'q_flag', 1,
sub
#line 193 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->qopts->{SeparateHits} = 1; undef }
	],
	[#Rule 40
		 'q_flag', 1,
sub
#line 194 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->qopts->{SeparateHits} = 0; undef }
	],
	[#Rule 41
		 'q_flag', 1,
sub
#line 195 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->qopts->{EnableBibliography} = 0; undef }
	],
	[#Rule 42
		 'q_flag', 2,
sub
#line 196 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->qopts->{EnableBibliography} = 1; undef }
	],
	[#Rule 43
		 'q_flag', 1,
sub
#line 197 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->qopts->{DebugRank} = 1; undef }
	],
	[#Rule 44
		 'q_flag', 2,
sub
#line 198 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->qopts->{DebugRank} = 0; undef }
	],
	[#Rule 45
		 'q_filter', 1,
sub
#line 203 "lib/DDC/PP/yyqparser.yp"
{ $_[1]; }
	],
	[#Rule 46
		 'q_filter', 1,
sub
#line 204 "lib/DDC/PP/yyqparser.yp"
{ $_[1]; }
	],
	[#Rule 47
		 'q_filter', 1,
sub
#line 205 "lib/DDC/PP/yyqparser.yp"
{ $_[1]; }
	],
	[#Rule 48
		 'q_filter', 1,
sub
#line 206 "lib/DDC/PP/yyqparser.yp"
{ $_[1]; }
	],
	[#Rule 49
		 'q_filter', 1,
sub
#line 207 "lib/DDC/PP/yyqparser.yp"
{ $_[1]; }
	],
	[#Rule 50
		 'q_filter', 1,
sub
#line 208 "lib/DDC/PP/yyqparser.yp"
{ $_[1]; }
	],
	[#Rule 51
		 'q_filter', 1,
sub
#line 209 "lib/DDC/PP/yyqparser.yp"
{ $_[1]; }
	],
	[#Rule 52
		 'q_filter', 1,
sub
#line 210 "lib/DDC/PP/yyqparser.yp"
{ $_[1]; }
	],
	[#Rule 53
		 'qf_has_field', 6,
sub
#line 214 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newf('CQFHasFieldValue', $_[3], $_[5]) }
	],
	[#Rule 54
		 'qf_has_field', 6,
sub
#line 215 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newf('CQFHasFieldRegex', $_[3], $_[5]) }
	],
	[#Rule 55
		 'qf_has_field', 6,
sub
#line 216 "lib/DDC/PP/yyqparser.yp"
{ (my $f=$_[0]->newf('CQFHasFieldRegex', $_[3], $_[5]))->Negate(); $f }
	],
	[#Rule 56
		 'qf_has_field', 6,
sub
#line 217 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newf('CQFHasFieldPrefix', $_[3],$_[5]) }
	],
	[#Rule 57
		 'qf_has_field', 6,
sub
#line 218 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newf('CQFHasFieldSuffix', $_[3],$_[5]) }
	],
	[#Rule 58
		 'qf_has_field', 6,
sub
#line 219 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newf('CQFHasFieldInfix', $_[3],$_[5]) }
	],
	[#Rule 59
		 'qf_has_field', 8,
sub
#line 220 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newf('CQFHasFieldSet', $_[3], $_[6]) }
	],
	[#Rule 60
		 'qf_has_field', 2,
sub
#line 221 "lib/DDC/PP/yyqparser.yp"
{ $_[2]->Negate; $_[2] }
	],
	[#Rule 61
		 'qf_rank_sort', 1,
sub
#line 225 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newf('CQFRankSort', DDC::PP::GreaterByRank) }
	],
	[#Rule 62
		 'qf_rank_sort', 1,
sub
#line 226 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newf('CQFRankSort', DDC::PP::LessByRank) }
	],
	[#Rule 63
		 'qf_context_sort', 2,
sub
#line 230 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newCFilter(DDC::PP::LessByLeftContext,      -1, $_[2]) }
	],
	[#Rule 64
		 'qf_context_sort', 2,
sub
#line 231 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newCFilter(DDC::PP::GreaterByLeftContext,   -1, $_[2]) }
	],
	[#Rule 65
		 'qf_context_sort', 2,
sub
#line 232 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newCFilter(DDC::PP::LessByRightContext,      1, $_[2]) }
	],
	[#Rule 66
		 'qf_context_sort', 2,
sub
#line 233 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newCFilter(DDC::PP::GreaterByRightContext,   1, $_[2]) }
	],
	[#Rule 67
		 'qf_context_sort', 2,
sub
#line 234 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newCFilter(DDC::PP::LessByMiddleContext,     0, $_[2]) }
	],
	[#Rule 68
		 'qf_context_sort', 2,
sub
#line 235 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newCFilter(DDC::PP::GreaterByMiddleContext,  0, $_[2]) }
	],
	[#Rule 69
		 'qf_size_sort', 2,
sub
#line 239 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newf('CQFSizeSort', DDC::PP::LessBySize,    @{$_[2]}) }
	],
	[#Rule 70
		 'qf_size_sort', 2,
sub
#line 240 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newf('CQFSizeSort', DDC::PP::GreaterBySize, @{$_[2]}) }
	],
	[#Rule 71
		 'qf_size_sort', 4,
sub
#line 241 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newf('CQFSizeSort', DDC::PP::LessBySize,    $_[3],$_[3]) }
	],
	[#Rule 72
		 'qf_date_sort', 2,
sub
#line 245 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newf('CQFDateSort', DDC::PP::LessByDate,    @{$_[2]}) }
	],
	[#Rule 73
		 'qf_date_sort', 2,
sub
#line 246 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newf('CQFDateSort', DDC::PP::GreaterByDate, @{$_[2]}) }
	],
	[#Rule 74
		 'qf_date_sort', 4,
sub
#line 247 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newf('CQFDateSort', DDC::PP::LessByDate,    $_[3],$_[3]) }
	],
	[#Rule 75
		 'qf_random_sort', 1,
sub
#line 251 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newf('CQFRandomSort') }
	],
	[#Rule 76
		 'qf_random_sort', 3,
sub
#line 252 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newf('CQFRandomSort') }
	],
	[#Rule 77
		 'qf_random_sort', 4,
sub
#line 253 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newf('CQFRandomSort',$_[3]) }
	],
	[#Rule 78
		 'qf_bibl_sort', 5,
sub
#line 257 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newf('CQFDateSort', DDC::PP::LessByDate,    @{$_[4]}) }
	],
	[#Rule 79
		 'qf_bibl_sort', 5,
sub
#line 258 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newf('CQFDateSort', DDC::PP::GreaterByDate, @{$_[4]}) }
	],
	[#Rule 80
		 'qf_bibl_sort', 5,
sub
#line 259 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newf('CQFBiblSort', DDC::PP::LessByFreeBiblField, $_[3], @{$_[4]}) }
	],
	[#Rule 81
		 'qf_bibl_sort', 5,
sub
#line 260 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newf('CQFBiblSort', DDC::PP::LessByFreeBiblField, $_[3], @{$_[4]}) }
	],
	[#Rule 82
		 'qf_prune_sort', 5,
sub
#line 264 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newf('CQFPrune', DDC::PP::LessByPruneKey,    $_[3], $_[4]); }
	],
	[#Rule 83
		 'qf_prune_sort', 5,
sub
#line 265 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newf('CQFPrune', DDC::PP::GreaterByPruneKey, $_[3], $_[4]); }
	],
	[#Rule 84
		 'qfb_int', 0,
sub
#line 273 "lib/DDC/PP/yyqparser.yp"
{ [] }
	],
	[#Rule 85
		 'qfb_int', 2,
sub
#line 274 "lib/DDC/PP/yyqparser.yp"
{ [] }
	],
	[#Rule 86
		 'qfb_int', 3,
sub
#line 275 "lib/DDC/PP/yyqparser.yp"
{ [] }
	],
	[#Rule 87
		 'qfb_int', 3,
sub
#line 276 "lib/DDC/PP/yyqparser.yp"
{ [$_[2]] }
	],
	[#Rule 88
		 'qfb_int', 4,
sub
#line 277 "lib/DDC/PP/yyqparser.yp"
{ [$_[2]] }
	],
	[#Rule 89
		 'qfb_int', 5,
sub
#line 278 "lib/DDC/PP/yyqparser.yp"
{ [$_[2],$_[4]] }
	],
	[#Rule 90
		 'qfb_int', 4,
sub
#line 279 "lib/DDC/PP/yyqparser.yp"
{ [undef,$_[3]] }
	],
	[#Rule 91
		 'qfb_date', 0,
sub
#line 284 "lib/DDC/PP/yyqparser.yp"
{ [] }
	],
	[#Rule 92
		 'qfb_date', 2,
sub
#line 285 "lib/DDC/PP/yyqparser.yp"
{ [] }
	],
	[#Rule 93
		 'qfb_date', 3,
sub
#line 286 "lib/DDC/PP/yyqparser.yp"
{ [$_[2]] }
	],
	[#Rule 94
		 'qfb_date', 4,
sub
#line 287 "lib/DDC/PP/yyqparser.yp"
{ [$_[2]] }
	],
	[#Rule 95
		 'qfb_date', 5,
sub
#line 288 "lib/DDC/PP/yyqparser.yp"
{ [$_[2],$_[4]] }
	],
	[#Rule 96
		 'qfb_date', 4,
sub
#line 289 "lib/DDC/PP/yyqparser.yp"
{ [undef,$_[3]] }
	],
	[#Rule 97
		 'qfb_bibl', 0,
sub
#line 294 "lib/DDC/PP/yyqparser.yp"
{ [] }
	],
	[#Rule 98
		 'qfb_bibl', 1,
sub
#line 295 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 99
		 'qfb_bibl_ne', 1,
sub
#line 301 "lib/DDC/PP/yyqparser.yp"
{ [] }
	],
	[#Rule 100
		 'qfb_bibl_ne', 2,
sub
#line 302 "lib/DDC/PP/yyqparser.yp"
{ [] }
	],
	[#Rule 101
		 'qfb_bibl_ne', 2,
sub
#line 303 "lib/DDC/PP/yyqparser.yp"
{ [$_[2]] }
	],
	[#Rule 102
		 'qfb_bibl_ne', 3,
sub
#line 304 "lib/DDC/PP/yyqparser.yp"
{ [$_[2]] }
	],
	[#Rule 103
		 'qfb_bibl_ne', 3,
sub
#line 305 "lib/DDC/PP/yyqparser.yp"
{ [undef,$_[3]] }
	],
	[#Rule 104
		 'qfb_bibl_ne', 4,
sub
#line 306 "lib/DDC/PP/yyqparser.yp"
{ [$_[2],$_[4]] }
	],
	[#Rule 105
		 'qfb_ctxsort', 0,
sub
#line 311 "lib/DDC/PP/yyqparser.yp"
{ [] }
	],
	[#Rule 106
		 'qfb_ctxsort', 3,
sub
#line 312 "lib/DDC/PP/yyqparser.yp"
{ $_[2] }
	],
	[#Rule 107
		 'qfb_ctxsort', 4,
sub
#line 313 "lib/DDC/PP/yyqparser.yp"
{ [@{$_[2]}, @{$_[3]}] }
	],
	[#Rule 108
		 'qfb_ctxkey', 3,
sub
#line 318 "lib/DDC/PP/yyqparser.yp"
{ [$_[1],$_[2],$_[3]] }
	],
	[#Rule 109
		 'qfb_ctxkey', 2,
sub
#line 319 "lib/DDC/PP/yyqparser.yp"
{ [undef,$_[1],$_[2]] }
	],
	[#Rule 110
		 'qfbc_matchref', 0,
sub
#line 324 "lib/DDC/PP/yyqparser.yp"
{ 0 }
	],
	[#Rule 111
		 'qfbc_matchref', 1,
sub
#line 325 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 112
		 'qfbc_offset', 0,
sub
#line 330 "lib/DDC/PP/yyqparser.yp"
{  undef }
	],
	[#Rule 113
		 'qfbc_offset', 1,
sub
#line 331 "lib/DDC/PP/yyqparser.yp"
{  $_[1] }
	],
	[#Rule 114
		 'qfbc_offset', 2,
sub
#line 332 "lib/DDC/PP/yyqparser.yp"
{  $_[2] }
	],
	[#Rule 115
		 'qfbc_offset', 2,
sub
#line 333 "lib/DDC/PP/yyqparser.yp"
{ -$_[2] }
	],
	[#Rule 116
		 'q_directives', 0,
sub
#line 341 "lib/DDC/PP/yyqparser.yp"
{ undef }
	],
	[#Rule 117
		 'q_directives', 2,
sub
#line 342 "lib/DDC/PP/yyqparser.yp"
{ undef }
	],
	[#Rule 118
		 '@1-1', 0,
sub
#line 346 "lib/DDC/PP/yyqparser.yp"
{ @{$_[0]->qopts->{Subcorpora}}=qw(); }
	],
	[#Rule 119
		 'qd_subcorpora', 3,
sub
#line 346 "lib/DDC/PP/yyqparser.yp"
{ undef }
	],
	[#Rule 120
		 'q_clause', 1,
sub
#line 354 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 121
		 'q_clause', 1,
sub
#line 355 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 122
		 'q_clause', 1,
sub
#line 356 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 123
		 'q_clause', 1,
sub
#line 357 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 124
		 'qc_matchid', 2,
sub
#line 361 "lib/DDC/PP/yyqparser.yp"
{ $_[1]->SetMatchId($_[2]); $_[1] }
	],
	[#Rule 125
		 'qc_matchid', 3,
sub
#line 362 "lib/DDC/PP/yyqparser.yp"
{ $_[2] }
	],
	[#Rule 126
		 'qc_boolean', 3,
sub
#line 369 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQAnd', $_[1],$_[3]) }
	],
	[#Rule 127
		 'qc_boolean', 3,
sub
#line 370 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQOr', $_[1],$_[3]) }
	],
	[#Rule 128
		 'qc_boolean', 2,
sub
#line 371 "lib/DDC/PP/yyqparser.yp"
{ $_[2]->Negate; $_[2] }
	],
	[#Rule 129
		 'qc_boolean', 3,
sub
#line 372 "lib/DDC/PP/yyqparser.yp"
{ $_[2] }
	],
	[#Rule 130
		 'qc_concat', 2,
sub
#line 378 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQAndImplicit', $_[1],$_[2]) }
	],
	[#Rule 131
		 'qc_concat', 2,
sub
#line 379 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQAndImplicit', $_[1],$_[2]) }
	],
	[#Rule 132
		 'qc_concat', 3,
sub
#line 380 "lib/DDC/PP/yyqparser.yp"
{ $_[2] }
	],
	[#Rule 133
		 'qc_basic', 1,
sub
#line 388 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 134
		 'qc_basic', 1,
sub
#line 389 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 135
		 'qc_near', 8,
sub
#line 393 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQNear', $_[7],$_[3],$_[5]) }
	],
	[#Rule 136
		 'qc_near', 10,
sub
#line 394 "lib/DDC/PP/yyqparser.yp"
{  $_[0]->newq('CQNear', $_[9],$_[3],$_[5],$_[7]) }
	],
	[#Rule 137
		 'qc_near', 2,
sub
#line 395 "lib/DDC/PP/yyqparser.yp"
{ $_[1]->SetMatchId($_[2]); $_[1] }
	],
	[#Rule 138
		 'qc_near', 3,
sub
#line 396 "lib/DDC/PP/yyqparser.yp"
{ $_[2] }
	],
	[#Rule 139
		 'qc_tokens', 1,
sub
#line 404 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 140
		 'qc_tokens', 1,
sub
#line 405 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 141
		 'qc_tokens', 2,
sub
#line 406 "lib/DDC/PP/yyqparser.yp"
{ $_[1]->SetMatchId($_[2]); $_[1] }
	],
	[#Rule 142
		 'qc_phrase', 3,
sub
#line 410 "lib/DDC/PP/yyqparser.yp"
{ $_[2] }
	],
	[#Rule 143
		 'qc_phrase', 3,
sub
#line 411 "lib/DDC/PP/yyqparser.yp"
{ $_[2] }
	],
	[#Rule 144
		 'qc_word', 1,
sub
#line 419 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 145
		 'qc_word', 1,
sub
#line 420 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 146
		 'qc_word', 1,
sub
#line 421 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 147
		 'qc_word', 1,
sub
#line 422 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 148
		 'qc_word', 1,
sub
#line 423 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 149
		 'qc_word', 1,
sub
#line 424 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 150
		 'qc_word', 1,
sub
#line 425 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 151
		 'qc_word', 1,
sub
#line 426 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 152
		 'qc_word', 1,
sub
#line 427 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 153
		 'qc_word', 1,
sub
#line 428 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 154
		 'qc_word', 1,
sub
#line 429 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 155
		 'qc_word', 1,
sub
#line 430 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 156
		 'qc_word', 1,
sub
#line 431 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 157
		 'qc_word', 1,
sub
#line 432 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 158
		 'qc_word', 1,
sub
#line 433 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 159
		 'qc_word', 1,
sub
#line 434 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 160
		 'qc_word', 1,
sub
#line 435 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 161
		 'qc_word', 1,
sub
#line 436 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 162
		 'qc_word', 1,
sub
#line 437 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 163
		 'qc_word', 1,
sub
#line 438 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 164
		 'qc_word', 1,
sub
#line 439 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 165
		 'qc_word', 1,
sub
#line 440 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 166
		 'qc_word', 1,
sub
#line 441 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 167
		 'qc_word', 3,
sub
#line 442 "lib/DDC/PP/yyqparser.yp"
{ $_[2] }
	],
	[#Rule 168
		 'qw_bareword', 2,
sub
#line 446 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokInfl', "", $_[1], $_[2]) }
	],
	[#Rule 169
		 'qw_bareword', 4,
sub
#line 447 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokInfl', $_[1], $_[3], $_[4]) }
	],
	[#Rule 170
		 'qw_exact', 2,
sub
#line 451 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokExact', "", $_[2]) }
	],
	[#Rule 171
		 'qw_exact', 4,
sub
#line 452 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokExact', $_[1], $_[4]) }
	],
	[#Rule 172
		 'qw_regex', 1,
sub
#line 456 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokRegex', "",   $_[1]) }
	],
	[#Rule 173
		 'qw_regex', 3,
sub
#line 457 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokRegex', $_[1],$_[3]) }
	],
	[#Rule 174
		 'qw_regex', 1,
sub
#line 458 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokRegex', "",    $_[1], 1) }
	],
	[#Rule 175
		 'qw_regex', 3,
sub
#line 459 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokRegex', $_[1], $_[3], 1) }
	],
	[#Rule 176
		 'qw_any', 1,
sub
#line 463 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokAny') }
	],
	[#Rule 177
		 'qw_any', 3,
sub
#line 464 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokAny',$_[1]) }
	],
	[#Rule 178
		 'qw_set_exact', 3,
sub
#line 468 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokSet', "",    undef, $_[2]) }
	],
	[#Rule 179
		 'qw_set_exact', 5,
sub
#line 469 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokSet', $_[1], undef, $_[2]) }
	],
	[#Rule 180
		 'qw_set_infl', 4,
sub
#line 473 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokSetInfl', "",    $_[2], $_[4]) }
	],
	[#Rule 181
		 'qw_set_infl', 6,
sub
#line 474 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokSetInfl', $_[1], $_[4], $_[6]) }
	],
	[#Rule 182
		 'qw_prefix', 1,
sub
#line 478 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokPrefix', "",    $_[1]) }
	],
	[#Rule 183
		 'qw_prefix', 3,
sub
#line 479 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokPrefix', $_[1], $_[3]) }
	],
	[#Rule 184
		 'qw_suffix', 1,
sub
#line 483 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokSuffix', "",    $_[1]) }
	],
	[#Rule 185
		 'qw_suffix', 3,
sub
#line 484 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokSuffix', $_[1], $_[3]) }
	],
	[#Rule 186
		 'qw_infix', 1,
sub
#line 488 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokInfix', "",    $_[1]) }
	],
	[#Rule 187
		 'qw_infix', 3,
sub
#line 489 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokInfix', $_[1], $_[3]) }
	],
	[#Rule 188
		 'qw_infix_set', 3,
sub
#line 493 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokInfixSet', "", $_[2]) }
	],
	[#Rule 189
		 'qw_infix_set', 5,
sub
#line 494 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokInfixSet', $_[1], $_[4]) }
	],
	[#Rule 190
		 'qw_prefix_set', 3,
sub
#line 498 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokPrefixSet',"", $_[2]) }
	],
	[#Rule 191
		 'qw_prefix_set', 5,
sub
#line 499 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokPrefixSet',$_[1], $_[4]) }
	],
	[#Rule 192
		 'qw_suffix_set', 3,
sub
#line 503 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokSuffixSet',"", $_[2]) }
	],
	[#Rule 193
		 'qw_suffix_set', 5,
sub
#line 504 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokSuffixSet',$_[1], $_[4]) }
	],
	[#Rule 194
		 'qw_thesaurus', 3,
sub
#line 508 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokThes', "Thes",$_[2]) }
	],
	[#Rule 195
		 'qw_thesaurus', 6,
sub
#line 509 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokThes', $_[1], $_[5]) }
	],
	[#Rule 196
		 'qw_morph', 3,
sub
#line 513 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokMorph', "MorphPattern", $_[2]) }
	],
	[#Rule 197
		 'qw_morph', 5,
sub
#line 514 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokMorph', $_[1], $_[4]) }
	],
	[#Rule 198
		 'qw_lemma', 2,
sub
#line 518 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokLemma', "Lemma", $_[2]) }
	],
	[#Rule 199
		 'qw_lemma', 4,
sub
#line 519 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokLemma', $_[1], $_[4]) }
	],
	[#Rule 200
		 'qw_chunk', 2,
sub
#line 523 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokChunk', "", $_[2]) }
	],
	[#Rule 201
		 'qw_chunk', 4,
sub
#line 524 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokChunk', $_[1], $_[4]) }
	],
	[#Rule 202
		 'qw_anchor', 3,
sub
#line 528 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokAnchor', "",    $_[3]) }
	],
	[#Rule 203
		 'qw_anchor', 4,
sub
#line 529 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokAnchor', $_[2], $_[4]) }
	],
	[#Rule 204
		 'qw_listfile', 2,
sub
#line 533 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokFile', "",    $_[2]) }
	],
	[#Rule 205
		 'qw_listfile', 4,
sub
#line 534 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQTokFile', $_[1], $_[4]) }
	],
	[#Rule 206
		 'qw_with', 3,
sub
#line 538 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQWith', $_[1],$_[3]) }
	],
	[#Rule 207
		 'qw_without', 3,
sub
#line 542 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQWithout', $_[1],$_[3]) }
	],
	[#Rule 208
		 'qw_withor', 3,
sub
#line 546 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQWithor', $_[1],$_[3]) }
	],
	[#Rule 209
		 'qw_keys', 4,
sub
#line 550 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newKeysQuery($_[3][0], $_[3][1]); }
	],
	[#Rule 210
		 'qw_keys', 6,
sub
#line 551 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newKeysQuery($_[5][0], $_[5][1], $_[1]); }
	],
	[#Rule 211
		 'qwk_indextuple', 4,
sub
#line 555 "lib/DDC/PP/yyqparser.yp"
{ $_[3] }
	],
	[#Rule 212
		 'qwk_countsrc', 1,
sub
#line 560 "lib/DDC/PP/yyqparser.yp"
{ [$_[1], {}] }
	],
	[#Rule 213
		 'qwk_countsrc', 2,
sub
#line 561 "lib/DDC/PP/yyqparser.yp"
{ [$_[0]->newCountQuery($_[1], $_[2]), $_[2]] }
	],
	[#Rule 214
		 'qw_matchid', 2,
sub
#line 565 "lib/DDC/PP/yyqparser.yp"
{ $_[1]->SetMatchId($_[2]); $_[1] }
	],
	[#Rule 215
		 'l_set', 0,
sub
#line 573 "lib/DDC/PP/yyqparser.yp"
{ [] }
	],
	[#Rule 216
		 'l_set', 2,
sub
#line 574 "lib/DDC/PP/yyqparser.yp"
{ push(@{$_[1]}, $_[2]); $_[1] }
	],
	[#Rule 217
		 'l_set', 2,
sub
#line 575 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 218
		 'l_morph', 0,
sub
#line 580 "lib/DDC/PP/yyqparser.yp"
{ [] }
	],
	[#Rule 219
		 'l_morph', 2,
sub
#line 581 "lib/DDC/PP/yyqparser.yp"
{ push(@{$_[1]}, $_[2]); $_[1] }
	],
	[#Rule 220
		 'l_morph', 2,
sub
#line 582 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 221
		 'l_morph', 2,
sub
#line 583 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 222
		 'l_phrase', 1,
sub
#line 587 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQSeq', [$_[1]]) }
	],
	[#Rule 223
		 'l_phrase', 2,
sub
#line 588 "lib/DDC/PP/yyqparser.yp"
{ $_[1]->Append($_[2]); $_[1] }
	],
	[#Rule 224
		 'l_phrase', 4,
sub
#line 589 "lib/DDC/PP/yyqparser.yp"
{ $_[1]->Append($_[4], $_[3]); $_[1] }
	],
	[#Rule 225
		 'l_phrase', 4,
sub
#line 590 "lib/DDC/PP/yyqparser.yp"
{ $_[1]->Append($_[4], $_[3], '<'); $_[1] }
	],
	[#Rule 226
		 'l_phrase', 4,
sub
#line 591 "lib/DDC/PP/yyqparser.yp"
{ $_[1]->Append($_[4], $_[3], '>'); $_[1] }
	],
	[#Rule 227
		 'l_phrase', 4,
sub
#line 592 "lib/DDC/PP/yyqparser.yp"
{ $_[1]->Append($_[4], $_[3], '='); $_[1] }
	],
	[#Rule 228
		 'l_txchain', 0,
sub
#line 596 "lib/DDC/PP/yyqparser.yp"
{ []; }
	],
	[#Rule 229
		 'l_txchain', 2,
sub
#line 597 "lib/DDC/PP/yyqparser.yp"
{ push(@{$_[1]}, $_[2]); $_[1] }
	],
	[#Rule 230
		 'l_countkeys', 0,
sub
#line 602 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQCountKeyExprList') }
	],
	[#Rule 231
		 'l_countkeys', 1,
sub
#line 603 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQCountKeyExprList', Exprs=>[$_[1]]) }
	],
	[#Rule 232
		 'l_countkeys', 3,
sub
#line 604 "lib/DDC/PP/yyqparser.yp"
{ $_[1]->PushKey($_[3]); $_[1] }
	],
	[#Rule 233
		 'l_prunekeys', 0,
sub
#line 609 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQCountKeyExprList') }
	],
	[#Rule 234
		 'l_prunekeys', 1,
sub
#line 610 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQCountKeyExprList', Exprs=>[$_[1]]) }
	],
	[#Rule 235
		 'l_prunekeys', 3,
sub
#line 611 "lib/DDC/PP/yyqparser.yp"
{ $_[1]->PushKey($_[3]); $_[1] }
	],
	[#Rule 236
		 'l_indextuple', 0,
sub
#line 615 "lib/DDC/PP/yyqparser.yp"
{ [] }
	],
	[#Rule 237
		 'l_indextuple', 1,
sub
#line 616 "lib/DDC/PP/yyqparser.yp"
{ [$_[1]] }
	],
	[#Rule 238
		 'l_indextuple', 3,
sub
#line 617 "lib/DDC/PP/yyqparser.yp"
{ push(@{$_[1]},$_[3]); $_[1] }
	],
	[#Rule 239
		 'l_subcorpora', 0,
sub
#line 621 "lib/DDC/PP/yyqparser.yp"
{ undef }
	],
	[#Rule 240
		 'l_subcorpora', 1,
sub
#line 622 "lib/DDC/PP/yyqparser.yp"
{ push(@{$_[0]->qopts->{Subcorpora}}, $_[1]); undef }
	],
	[#Rule 241
		 'l_subcorpora', 3,
sub
#line 623 "lib/DDC/PP/yyqparser.yp"
{ push(@{$_[0]->qopts->{Subcorpora}}, $_[3]); undef }
	],
	[#Rule 242
		 'count_key', 1,
sub
#line 630 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 243
		 'count_key', 1,
sub
#line 631 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 244
		 'count_key', 1,
sub
#line 632 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 245
		 'count_key', 3,
sub
#line 633 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQCountKeyExprRegex', $_[1],@{$_[3]}) }
	],
	[#Rule 246
		 'count_key', 3,
sub
#line 634 "lib/DDC/PP/yyqparser.yp"
{ $_[2] }
	],
	[#Rule 247
		 'prune_key', 1,
sub
#line 638 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 248
		 'prune_key', 1,
sub
#line 639 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 249
		 'prune_key', 3,
sub
#line 640 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQCountKeyExprRegex', $_[1],@{$_[3]}) }
	],
	[#Rule 250
		 'prune_key', 3,
sub
#line 641 "lib/DDC/PP/yyqparser.yp"
{ $_[2] }
	],
	[#Rule 251
		 'count_key_const', 1,
sub
#line 645 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQCountKeyExprConstant', "*") }
	],
	[#Rule 252
		 'count_key_const', 2,
sub
#line 646 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQCountKeyExprConstant', $_[2]) }
	],
	[#Rule 253
		 'count_key_meta', 1,
sub
#line 650 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQCountKeyExprFileId', $_[1]) }
	],
	[#Rule 254
		 'count_key_meta', 1,
sub
#line 651 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQCountKeyExprFileName', $_[1]) }
	],
	[#Rule 255
		 'count_key_meta', 1,
sub
#line 652 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQCountKeyExprDate', $_[1]) }
	],
	[#Rule 256
		 'count_key_meta', 3,
sub
#line 653 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQCountKeyExprDateSlice', $_[1],$_[3]) }
	],
	[#Rule 257
		 'count_key_meta', 1,
sub
#line 654 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQCountKeyExprBibl', $_[1]) }
	],
	[#Rule 258
		 'count_key_token', 3,
sub
#line 658 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newq('CQCountKeyExprToken', $_[1],$_[2],$_[3]) }
	],
	[#Rule 259
		 'ck_matchid', 0,
sub
#line 662 "lib/DDC/PP/yyqparser.yp"
{     0 }
	],
	[#Rule 260
		 'ck_matchid', 1,
sub
#line 663 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 261
		 'ck_offset', 0,
sub
#line 667 "lib/DDC/PP/yyqparser.yp"
{      0 }
	],
	[#Rule 262
		 'ck_offset', 1,
sub
#line 668 "lib/DDC/PP/yyqparser.yp"
{  $_[1] }
	],
	[#Rule 263
		 'ck_offset', 2,
sub
#line 669 "lib/DDC/PP/yyqparser.yp"
{  $_[2] }
	],
	[#Rule 264
		 'ck_offset', 2,
sub
#line 670 "lib/DDC/PP/yyqparser.yp"
{ -$_[2] }
	],
	[#Rule 265
		 's_index', 1,
sub
#line 678 "lib/DDC/PP/yyqparser.yp"
{ '' }
	],
	[#Rule 266
		 's_index', 1,
sub
#line 679 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 267
		 's_indextuple_item', 1,
sub
#line 683 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 268
		 's_indextuple_item', 1,
sub
#line 684 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 269
		 's_word', 1,
sub
#line 687 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 270
		 's_semclass', 1,
sub
#line 688 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 271
		 's_lemma', 1,
sub
#line 689 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 272
		 's_chunk', 1,
sub
#line 690 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 273
		 's_filename', 1,
sub
#line 691 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 274
		 's_morphitem', 1,
sub
#line 692 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 275
		 's_subcorpus', 1,
sub
#line 693 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 276
		 's_biblname', 1,
sub
#line 694 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 277
		 's_breakname', 1,
sub
#line 696 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 278
		 's_breakname', 1,
sub
#line 697 "lib/DDC/PP/yyqparser.yp"
{ "file" }
	],
	[#Rule 279
		 'symbol', 1,
sub
#line 705 "lib/DDC/PP/yyqparser.yp"
{ unescape($_[1]) }
	],
	[#Rule 280
		 'symbol', 1,
sub
#line 706 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 281
		 'symbol', 1,
sub
#line 707 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 282
		 'index', 1,
sub
#line 711 "lib/DDC/PP/yyqparser.yp"
{ '' }
	],
	[#Rule 283
		 'index', 1,
sub
#line 712 "lib/DDC/PP/yyqparser.yp"
{ unescape($_[1]) }
	],
	[#Rule 284
		 'sym_str', 1,
sub
#line 715 "lib/DDC/PP/yyqparser.yp"
{ unescape($_[1]) }
	],
	[#Rule 285
		 's_prefix', 1,
sub
#line 717 "lib/DDC/PP/yyqparser.yp"
{ unescape($_[1]) }
	],
	[#Rule 286
		 's_suffix', 1,
sub
#line 718 "lib/DDC/PP/yyqparser.yp"
{ unescape($_[1]) }
	],
	[#Rule 287
		 's_infix', 1,
sub
#line 719 "lib/DDC/PP/yyqparser.yp"
{ unescape($_[1]) }
	],
	[#Rule 288
		 's_expander', 1,
sub
#line 721 "lib/DDC/PP/yyqparser.yp"
{ unescape($_[1]) }
	],
	[#Rule 289
		 'regex', 1,
sub
#line 724 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newre($_[1]) }
	],
	[#Rule 290
		 'regex', 2,
sub
#line 725 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newre($_[1],$_[2]) }
	],
	[#Rule 291
		 'neg_regex', 1,
sub
#line 729 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newre($_[1]) }
	],
	[#Rule 292
		 'neg_regex', 2,
sub
#line 730 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->newre($_[1],$_[2]) }
	],
	[#Rule 293
		 'replace_regex', 2,
sub
#line 734 "lib/DDC/PP/yyqparser.yp"
{ [$_[1],$_[2],''] }
	],
	[#Rule 294
		 'replace_regex', 3,
sub
#line 735 "lib/DDC/PP/yyqparser.yp"
{ [$_[1],$_[2],$_[3]] }
	],
	[#Rule 295
		 'int_str', 1,
sub
#line 738 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 296
		 'integer', 1,
sub
#line 740 "lib/DDC/PP/yyqparser.yp"
{ no warnings 'numeric'; ($_[1]+0) }
	],
	[#Rule 297
		 'date', 1,
sub
#line 743 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 298
		 'date', 1,
sub
#line 744 "lib/DDC/PP/yyqparser.yp"
{ $_[1] }
	],
	[#Rule 299
		 'matchid', 2,
sub
#line 747 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->yybegin('INITIAL'); $_[2] }
	],
	[#Rule 300
		 'matchid_eq', 1,
sub
#line 749 "lib/DDC/PP/yyqparser.yp"
{ $_[0]->yybegin('Q_MATCHID'); $_[1] }
	]
],
                                  @_);
    bless($self,$class);
}

#line 751 "lib/DDC/PP/yyqparser.yp"

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
