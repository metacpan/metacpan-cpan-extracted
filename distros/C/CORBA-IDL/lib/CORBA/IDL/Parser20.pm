####################################################################
#
#    This file was generated using Parse::Yapp version 1.05.
#
#        Don't edit this file, use source file instead.
#
#             ANY CHANGE MADE HERE WILL BE LOST !
#
####################################################################
package CORBA::IDL::Parser;
use vars qw ( @ISA );
use strict;

@ISA= qw ( Parse::Yapp::Driver );
use Parse::Yapp::Driver;



sub new {
        my($class)=shift;
        ref($class)
    and $class=ref($class);

    my($self)=$class->SUPER::new( yyversion => '1.05',
                                  yystates =>
[
	{#State 0
		ACTIONS => {
			'' => -2,
			'IDENTIFIER' => 22,
			'INTERFACE' => 3,
			'ENUM' => 2,
			'MODULE' => 23,
			'CONST' => 25,
			'STRUCT' => 24,
			'UNION' => 10,
			'TYPEDEF' => 14,
			'EXCEPTION' => 15,
			'error' => 16
		},
		GOTOS => {
			'union_type' => 1,
			'enum_header' => 4,
			'definitions' => 5,
			'definition' => 8,
			'module_header' => 7,
			'struct_type' => 6,
			'union_header' => 9,
			'specification' => 11,
			'except_dcl' => 12,
			'struct_header' => 13,
			'interface' => 17,
			'type_dcl' => 18,
			'module' => 20,
			'interface_header' => 19,
			'enum_type' => 21,
			'forward_dcl' => 27,
			'exception_header' => 26,
			'const_dcl' => 28,
			'interface_dcl' => 29
		}
	},
	{#State 1
		DEFAULT => -97
	},
	{#State 2
		ACTIONS => {
			'IDENTIFIER' => 31,
			'error' => 30
		}
	},
	{#State 3
		ACTIONS => {
			'IDENTIFIER' => 33,
			'error' => 32
		}
	},
	{#State 4
		ACTIONS => {
			"{" => 35,
			'error' => 34
		}
	},
	{#State 5
		DEFAULT => -1
	},
	{#State 6
		DEFAULT => -96
	},
	{#State 7
		ACTIONS => {
			"{" => 37,
			'error' => 36
		}
	},
	{#State 8
		ACTIONS => {
			'IDENTIFIER' => 22,
			'INTERFACE' => 3,
			'ENUM' => 2,
			'MODULE' => 23,
			'CONST' => 25,
			'STRUCT' => 24,
			'UNION' => 10,
			'TYPEDEF' => 14,
			'EXCEPTION' => 15
		},
		DEFAULT => -4,
		GOTOS => {
			'union_type' => 1,
			'enum_header' => 4,
			'definitions' => 38,
			'definition' => 8,
			'module_header' => 7,
			'struct_type' => 6,
			'union_header' => 9,
			'except_dcl' => 12,
			'struct_header' => 13,
			'interface' => 17,
			'type_dcl' => 18,
			'module' => 20,
			'interface_header' => 19,
			'enum_type' => 21,
			'exception_header' => 26,
			'forward_dcl' => 27,
			'const_dcl' => 28,
			'interface_dcl' => 29
		}
	},
	{#State 9
		ACTIONS => {
			'SWITCH' => 39
		}
	},
	{#State 10
		ACTIONS => {
			'IDENTIFIER' => 41,
			'error' => 40
		}
	},
	{#State 11
		ACTIONS => {
			'' => 42
		}
	},
	{#State 12
		ACTIONS => {
			";" => 43,
			'error' => 44
		},
		GOTOS => {
			'check_semicolon' => 45
		}
	},
	{#State 13
		ACTIONS => {
			"{" => 46
		}
	},
	{#State 14
		ACTIONS => {
			"::" => 67,
			'ENUM' => 2,
			'CHAR' => 68,
			'STRING' => 73,
			'OCTET' => 49,
			'UNION' => 10,
			'UNSIGNED' => 51,
			'error' => 75,
			'ANY' => 52,
			'FLOAT' => 77,
			'LONG' => 54,
			'SEQUENCE' => 78,
			'IDENTIFIER' => 58,
			'DOUBLE' => 79,
			'SHORT' => 81,
			'BOOLEAN' => 82,
			'STRUCT' => 24,
			'VOID' => 63
		},
		GOTOS => {
			'union_type' => 47,
			'type_spec' => 69,
			'integer_type' => 70,
			'unsigned_int' => 72,
			'sequence_type' => 71,
			'enum_header' => 4,
			'unsigned_short_int' => 48,
			'struct_type' => 50,
			'union_header' => 9,
			'constr_type_spec' => 74,
			'struct_header' => 13,
			'floating_pt_type' => 76,
			'type_declarator' => 53,
			'enum_type' => 55,
			'any_type' => 56,
			'template_type_spec' => 57,
			'base_type_spec' => 80,
			'unsigned_long_int' => 59,
			'scoped_name' => 60,
			'signed_int' => 83,
			'string_type' => 61,
			'simple_type_spec' => 84,
			'char_type' => 62,
			'signed_long_int' => 64,
			'signed_short_int' => 65,
			'boolean_type' => 85,
			'octet_type' => 66
		}
	},
	{#State 15
		ACTIONS => {
			'IDENTIFIER' => 86,
			'error' => 87
		}
	},
	{#State 16
		DEFAULT => -3
	},
	{#State 17
		ACTIONS => {
			";" => 43,
			'error' => 44
		},
		GOTOS => {
			'check_semicolon' => 88
		}
	},
	{#State 18
		ACTIONS => {
			";" => 43,
			'error' => 44
		},
		GOTOS => {
			'check_semicolon' => 89
		}
	},
	{#State 19
		ACTIONS => {
			"{" => 90
		}
	},
	{#State 20
		ACTIONS => {
			";" => 43,
			'error' => 44
		},
		GOTOS => {
			'check_semicolon' => 91
		}
	},
	{#State 21
		DEFAULT => -98
	},
	{#State 22
		ACTIONS => {
			'error' => 92
		}
	},
	{#State 23
		ACTIONS => {
			'IDENTIFIER' => 93,
			'error' => 94
		}
	},
	{#State 24
		ACTIONS => {
			'IDENTIFIER' => 95
		}
	},
	{#State 25
		ACTIONS => {
			'DOUBLE' => 79,
			"::" => 67,
			'IDENTIFIER' => 58,
			'SHORT' => 81,
			'CHAR' => 68,
			'BOOLEAN' => 82,
			'STRING' => 73,
			'UNSIGNED' => 51,
			'error' => 101,
			'FLOAT' => 77,
			'LONG' => 54
		},
		GOTOS => {
			'integer_type' => 99,
			'unsigned_long_int' => 59,
			'unsigned_int' => 72,
			'scoped_name' => 96,
			'signed_int' => 83,
			'string_type' => 97,
			'unsigned_short_int' => 48,
			'char_type' => 98,
			'signed_long_int' => 64,
			'signed_short_int' => 65,
			'floating_pt_type' => 100,
			'const_type' => 102,
			'boolean_type' => 103
		}
	},
	{#State 26
		ACTIONS => {
			"{" => 105,
			'error' => 104
		}
	},
	{#State 27
		DEFAULT => -21
	},
	{#State 28
		ACTIONS => {
			";" => 43,
			'error' => 44
		},
		GOTOS => {
			'check_semicolon' => 106
		}
	},
	{#State 29
		DEFAULT => -20
	},
	{#State 30
		DEFAULT => -176
	},
	{#State 31
		DEFAULT => -175
	},
	{#State 32
		ACTIONS => {
			"{" => -28
		},
		DEFAULT => -26
	},
	{#State 33
		ACTIONS => {
			":" => 107,
			"{" => -39
		},
		DEFAULT => -25,
		GOTOS => {
			'interface_inheritance_spec' => 108
		}
	},
	{#State 34
		DEFAULT => -174
	},
	{#State 35
		ACTIONS => {
			'IDENTIFIER' => 109,
			'error' => 111
		},
		GOTOS => {
			'enumerators' => 112,
			'enumerator' => 110
		}
	},
	{#State 36
		ACTIONS => {
			"}" => 113
		}
	},
	{#State 37
		ACTIONS => {
			"}" => 114,
			'INTERFACE' => 3,
			'ENUM' => 2,
			'IDENTIFIER' => 22,
			'MODULE' => 23,
			'CONST' => 25,
			'STRUCT' => 24,
			'UNION' => 10,
			'TYPEDEF' => 14,
			'error' => 116,
			'EXCEPTION' => 15
		},
		GOTOS => {
			'union_type' => 1,
			'enum_header' => 4,
			'definitions' => 115,
			'definition' => 8,
			'module_header' => 7,
			'struct_type' => 6,
			'union_header' => 9,
			'except_dcl' => 12,
			'struct_header' => 13,
			'interface' => 17,
			'type_dcl' => 18,
			'module' => 20,
			'interface_header' => 19,
			'enum_type' => 21,
			'forward_dcl' => 27,
			'exception_header' => 26,
			'const_dcl' => 28,
			'interface_dcl' => 29
		}
	},
	{#State 38
		DEFAULT => -5
	},
	{#State 39
		ACTIONS => {
			"(" => 117,
			'error' => 118
		}
	},
	{#State 40
		DEFAULT => -155
	},
	{#State 41
		DEFAULT => -154
	},
	{#State 42
		DEFAULT => 0
	},
	{#State 43
		DEFAULT => -12
	},
	{#State 44
		DEFAULT => -13
	},
	{#State 45
		DEFAULT => -8
	},
	{#State 46
		ACTIONS => {
			"::" => 67,
			'ENUM' => 2,
			'CHAR' => 68,
			'STRING' => 73,
			'OCTET' => 49,
			'UNION' => 10,
			'UNSIGNED' => 51,
			'error' => 122,
			'ANY' => 52,
			'FLOAT' => 77,
			'LONG' => 54,
			'SEQUENCE' => 78,
			'IDENTIFIER' => 58,
			'DOUBLE' => 79,
			'SHORT' => 81,
			'BOOLEAN' => 82,
			'STRUCT' => 24,
			'VOID' => 63
		},
		GOTOS => {
			'union_type' => 47,
			'type_spec' => 121,
			'integer_type' => 70,
			'sequence_type' => 71,
			'unsigned_int' => 72,
			'enum_header' => 4,
			'unsigned_short_int' => 48,
			'struct_type' => 50,
			'union_header' => 9,
			'constr_type_spec' => 74,
			'struct_header' => 13,
			'floating_pt_type' => 76,
			'member_list' => 119,
			'enum_type' => 55,
			'any_type' => 56,
			'template_type_spec' => 57,
			'base_type_spec' => 80,
			'member' => 120,
			'unsigned_long_int' => 59,
			'scoped_name' => 60,
			'signed_int' => 83,
			'string_type' => 61,
			'simple_type_spec' => 84,
			'char_type' => 62,
			'signed_short_int' => 65,
			'signed_long_int' => 64,
			'boolean_type' => 85,
			'octet_type' => 66
		}
	},
	{#State 47
		DEFAULT => -116
	},
	{#State 48
		DEFAULT => -134
	},
	{#State 49
		DEFAULT => -140
	},
	{#State 50
		DEFAULT => -115
	},
	{#State 51
		ACTIONS => {
			'SHORT' => 124,
			'LONG' => 123
		}
	},
	{#State 52
		DEFAULT => -141
	},
	{#State 53
		DEFAULT => -95
	},
	{#State 54
		DEFAULT => -132
	},
	{#State 55
		DEFAULT => -117
	},
	{#State 56
		DEFAULT => -112
	},
	{#State 57
		DEFAULT => -104
	},
	{#State 58
		DEFAULT => -43
	},
	{#State 59
		DEFAULT => -135
	},
	{#State 60
		ACTIONS => {
			"::" => 125
		},
		DEFAULT => -105
	},
	{#State 61
		DEFAULT => -114
	},
	{#State 62
		DEFAULT => -109
	},
	{#State 63
		DEFAULT => -106
	},
	{#State 64
		DEFAULT => -131
	},
	{#State 65
		DEFAULT => -130
	},
	{#State 66
		DEFAULT => -111
	},
	{#State 67
		ACTIONS => {
			'IDENTIFIER' => 126,
			'error' => 127
		}
	},
	{#State 68
		DEFAULT => -138
	},
	{#State 69
		ACTIONS => {
			'IDENTIFIER' => 129,
			'error' => 131
		},
		GOTOS => {
			'declarators' => 132,
			'array_declarator' => 133,
			'simple_declarator' => 128,
			'declarator' => 130,
			'complex_declarator' => 134
		}
	},
	{#State 70
		DEFAULT => -108
	},
	{#State 71
		DEFAULT => -113
	},
	{#State 72
		DEFAULT => -129
	},
	{#State 73
		ACTIONS => {
			"<" => 135
		},
		DEFAULT => -188
	},
	{#State 74
		DEFAULT => -102
	},
	{#State 75
		DEFAULT => -99
	},
	{#State 76
		DEFAULT => -107
	},
	{#State 77
		DEFAULT => -126
	},
	{#State 78
		ACTIONS => {
			"<" => 136,
			'error' => 137
		}
	},
	{#State 79
		DEFAULT => -127
	},
	{#State 80
		DEFAULT => -103
	},
	{#State 81
		DEFAULT => -133
	},
	{#State 82
		DEFAULT => -139
	},
	{#State 83
		DEFAULT => -128
	},
	{#State 84
		DEFAULT => -101
	},
	{#State 85
		DEFAULT => -110
	},
	{#State 86
		DEFAULT => -205
	},
	{#State 87
		DEFAULT => -206
	},
	{#State 88
		DEFAULT => -9
	},
	{#State 89
		DEFAULT => -6
	},
	{#State 90
		ACTIONS => {
			"}" => 138,
			"::" => -212,
			'ENUM' => 2,
			'CHAR' => -212,
			'STRING' => -212,
			'OCTET' => -212,
			'ONEWAY' => 149,
			'UNION' => 10,
			'UNSIGNED' => -212,
			'TYPEDEF' => 14,
			'error' => 152,
			'EXCEPTION' => 15,
			'ANY' => -212,
			'FLOAT' => -212,
			'LONG' => -212,
			'ATTRIBUTE' => -198,
			'SEQUENCE' => -212,
			'IDENTIFIER' => -212,
			'DOUBLE' => -212,
			'SHORT' => -212,
			'BOOLEAN' => -212,
			'STRUCT' => 24,
			'CONST' => 25,
			'READONLY' => 153,
			'VOID' => -212
		},
		GOTOS => {
			'op_header' => 146,
			'union_type' => 1,
			'interface_body' => 147,
			'attr_mod' => 139,
			'enum_header' => 4,
			'op_dcl' => 148,
			'exports' => 151,
			'attr_dcl' => 150,
			'struct_type' => 6,
			'union_header' => 9,
			'except_dcl' => 140,
			'struct_header' => 13,
			'export' => 142,
			'type_dcl' => 141,
			'enum_type' => 21,
			'op_attribute' => 143,
			'op_mod' => 144,
			'exception_header' => 26,
			'const_dcl' => 145
		}
	},
	{#State 91
		DEFAULT => -10
	},
	{#State 92
		ACTIONS => {
			";" => 154
		}
	},
	{#State 93
		DEFAULT => -18
	},
	{#State 94
		DEFAULT => -19
	},
	{#State 95
		DEFAULT => -144
	},
	{#State 96
		ACTIONS => {
			"::" => 125
		},
		DEFAULT => -58
	},
	{#State 97
		DEFAULT => -57
	},
	{#State 98
		DEFAULT => -54
	},
	{#State 99
		DEFAULT => -53
	},
	{#State 100
		DEFAULT => -56
	},
	{#State 101
		DEFAULT => -52
	},
	{#State 102
		ACTIONS => {
			'IDENTIFIER' => 155,
			'error' => 156
		}
	},
	{#State 103
		DEFAULT => -55
	},
	{#State 104
		DEFAULT => -204
	},
	{#State 105
		ACTIONS => {
			"}" => 157,
			"::" => 67,
			'ENUM' => 2,
			'CHAR' => 68,
			'STRING' => 73,
			'OCTET' => 49,
			'UNION' => 10,
			'UNSIGNED' => 51,
			'error' => 159,
			'ANY' => 52,
			'FLOAT' => 77,
			'LONG' => 54,
			'SEQUENCE' => 78,
			'DOUBLE' => 79,
			'IDENTIFIER' => 58,
			'SHORT' => 81,
			'BOOLEAN' => 82,
			'STRUCT' => 24,
			'VOID' => 63
		},
		GOTOS => {
			'union_type' => 47,
			'type_spec' => 121,
			'integer_type' => 70,
			'sequence_type' => 71,
			'unsigned_int' => 72,
			'enum_header' => 4,
			'unsigned_short_int' => 48,
			'struct_type' => 50,
			'union_header' => 9,
			'constr_type_spec' => 74,
			'struct_header' => 13,
			'floating_pt_type' => 76,
			'member_list' => 158,
			'enum_type' => 55,
			'any_type' => 56,
			'template_type_spec' => 57,
			'base_type_spec' => 80,
			'member' => 120,
			'unsigned_long_int' => 59,
			'scoped_name' => 60,
			'signed_int' => 83,
			'string_type' => 61,
			'simple_type_spec' => 84,
			'char_type' => 62,
			'signed_short_int' => 65,
			'signed_long_int' => 64,
			'boolean_type' => 85,
			'octet_type' => 66
		}
	},
	{#State 106
		DEFAULT => -7
	},
	{#State 107
		ACTIONS => {
			"::" => 67,
			'IDENTIFIER' => 58,
			'error' => 161
		},
		GOTOS => {
			'interface_name' => 163,
			'interface_names' => 162,
			'scoped_name' => 160
		}
	},
	{#State 108
		DEFAULT => -27
	},
	{#State 109
		DEFAULT => -181
	},
	{#State 110
		ACTIONS => {
			";" => 164,
			"," => 165
		},
		DEFAULT => -177
	},
	{#State 111
		ACTIONS => {
			"}" => 166
		}
	},
	{#State 112
		ACTIONS => {
			"}" => 167
		}
	},
	{#State 113
		DEFAULT => -17
	},
	{#State 114
		DEFAULT => -16
	},
	{#State 115
		ACTIONS => {
			"}" => 168
		}
	},
	{#State 116
		ACTIONS => {
			"}" => 169
		}
	},
	{#State 117
		ACTIONS => {
			"::" => 67,
			'ENUM' => 2,
			'IDENTIFIER' => 58,
			'SHORT' => 81,
			'CHAR' => 68,
			'BOOLEAN' => 82,
			'UNSIGNED' => 51,
			'error' => 174,
			'LONG' => 54
		},
		GOTOS => {
			'enum_type' => 170,
			'integer_type' => 173,
			'unsigned_long_int' => 59,
			'unsigned_int' => 72,
			'scoped_name' => 171,
			'enum_header' => 4,
			'signed_int' => 83,
			'unsigned_short_int' => 48,
			'char_type' => 172,
			'signed_long_int' => 64,
			'signed_short_int' => 65,
			'boolean_type' => 176,
			'switch_type_spec' => 175
		}
	},
	{#State 118
		DEFAULT => -153
	},
	{#State 119
		ACTIONS => {
			"}" => 177
		}
	},
	{#State 120
		ACTIONS => {
			"::" => 67,
			'ENUM' => 2,
			'CHAR' => 68,
			'STRING' => 73,
			'OCTET' => 49,
			'UNION' => 10,
			'UNSIGNED' => 51,
			'ANY' => 52,
			'FLOAT' => 77,
			'LONG' => 54,
			'SEQUENCE' => 78,
			'IDENTIFIER' => 58,
			'DOUBLE' => 79,
			'SHORT' => 81,
			'BOOLEAN' => 82,
			'STRUCT' => 24,
			'VOID' => 63
		},
		DEFAULT => -146,
		GOTOS => {
			'union_type' => 47,
			'type_spec' => 121,
			'integer_type' => 70,
			'sequence_type' => 71,
			'unsigned_int' => 72,
			'enum_header' => 4,
			'unsigned_short_int' => 48,
			'struct_type' => 50,
			'union_header' => 9,
			'constr_type_spec' => 74,
			'struct_header' => 13,
			'floating_pt_type' => 76,
			'member_list' => 178,
			'enum_type' => 55,
			'any_type' => 56,
			'template_type_spec' => 57,
			'base_type_spec' => 80,
			'member' => 120,
			'unsigned_long_int' => 59,
			'scoped_name' => 60,
			'signed_int' => 83,
			'string_type' => 61,
			'simple_type_spec' => 84,
			'char_type' => 62,
			'signed_short_int' => 65,
			'signed_long_int' => 64,
			'boolean_type' => 85,
			'octet_type' => 66
		}
	},
	{#State 121
		ACTIONS => {
			'IDENTIFIER' => 129,
			'error' => 131
		},
		GOTOS => {
			'declarators' => 179,
			'array_declarator' => 133,
			'simple_declarator' => 128,
			'declarator' => 130,
			'complex_declarator' => 134
		}
	},
	{#State 122
		ACTIONS => {
			"}" => 180
		}
	},
	{#State 123
		DEFAULT => -136
	},
	{#State 124
		DEFAULT => -137
	},
	{#State 125
		ACTIONS => {
			'IDENTIFIER' => 181,
			'error' => 182
		}
	},
	{#State 126
		DEFAULT => -44
	},
	{#State 127
		DEFAULT => -45
	},
	{#State 128
		DEFAULT => -120
	},
	{#State 129
		ACTIONS => {
			"[" => 184
		},
		DEFAULT => -122,
		GOTOS => {
			'fixed_array_sizes' => 183,
			'fixed_array_size' => 185
		}
	},
	{#State 130
		ACTIONS => {
			"," => 186
		},
		DEFAULT => -118
	},
	{#State 131
		ACTIONS => {
			";" => 187,
			"," => 188
		}
	},
	{#State 132
		DEFAULT => -100
	},
	{#State 133
		DEFAULT => -125
	},
	{#State 134
		DEFAULT => -121
	},
	{#State 135
		ACTIONS => {
			"-" => 189,
			"::" => 67,
			'TRUE' => 201,
			'IDENTIFIER' => 58,
			"+" => 202,
			"~" => 190,
			'INTEGER_LITERAL' => 203,
			'FLOATING_PT_LITERAL' => 205,
			"(" => 199,
			'FALSE' => 192,
			'STRING_LITERAL' => 213,
			'error' => 206,
			'CHARACTER_LITERAL' => 207
		},
		GOTOS => {
			'and_expr' => 196,
			'or_expr' => 197,
			'mult_expr' => 208,
			'shift_expr' => 204,
			'scoped_name' => 198,
			'boolean_literal' => 209,
			'add_expr' => 210,
			'literal' => 191,
			'positive_int_const' => 211,
			'primary_expr' => 212,
			'unary_expr' => 200,
			'const_exp' => 193,
			'unary_operator' => 194,
			'xor_expr' => 214,
			'string_literal' => 195
		}
	},
	{#State 136
		ACTIONS => {
			'SEQUENCE' => 78,
			'DOUBLE' => 79,
			"::" => 67,
			'IDENTIFIER' => 58,
			'SHORT' => 81,
			'CHAR' => 68,
			'BOOLEAN' => 82,
			'STRING' => 73,
			'OCTET' => 49,
			'VOID' => 63,
			'UNSIGNED' => 51,
			'error' => 215,
			'ANY' => 52,
			'FLOAT' => 77,
			'LONG' => 54
		},
		GOTOS => {
			'integer_type' => 70,
			'sequence_type' => 71,
			'unsigned_int' => 72,
			'unsigned_short_int' => 48,
			'floating_pt_type' => 76,
			'any_type' => 56,
			'template_type_spec' => 57,
			'base_type_spec' => 80,
			'unsigned_long_int' => 59,
			'scoped_name' => 60,
			'string_type' => 61,
			'signed_int' => 83,
			'simple_type_spec' => 216,
			'char_type' => 62,
			'signed_short_int' => 65,
			'signed_long_int' => 64,
			'boolean_type' => 85,
			'octet_type' => 66
		}
	},
	{#State 137
		DEFAULT => -186
	},
	{#State 138
		DEFAULT => -22
	},
	{#State 139
		ACTIONS => {
			'ATTRIBUTE' => 217
		}
	},
	{#State 140
		ACTIONS => {
			";" => 43,
			'error' => 44
		},
		GOTOS => {
			'check_semicolon' => 218
		}
	},
	{#State 141
		ACTIONS => {
			";" => 43,
			'error' => 44
		},
		GOTOS => {
			'check_semicolon' => 219
		}
	},
	{#State 142
		ACTIONS => {
			"}" => -30,
			'ENUM' => 2,
			'ONEWAY' => 149,
			'UNION' => 10,
			'TYPEDEF' => 14,
			'EXCEPTION' => 15,
			'ATTRIBUTE' => -198,
			'STRUCT' => 24,
			'CONST' => 25,
			'READONLY' => 153
		},
		DEFAULT => -212,
		GOTOS => {
			'op_header' => 146,
			'union_type' => 1,
			'attr_mod' => 139,
			'enum_header' => 4,
			'op_dcl' => 148,
			'exports' => 220,
			'attr_dcl' => 150,
			'struct_type' => 6,
			'union_header' => 9,
			'except_dcl' => 140,
			'struct_header' => 13,
			'export' => 142,
			'type_dcl' => 141,
			'enum_type' => 21,
			'op_attribute' => 143,
			'op_mod' => 144,
			'exception_header' => 26,
			'const_dcl' => 145
		}
	},
	{#State 143
		DEFAULT => -211
	},
	{#State 144
		ACTIONS => {
			'SEQUENCE' => 78,
			'DOUBLE' => 79,
			"::" => 67,
			'IDENTIFIER' => 58,
			'SHORT' => 81,
			'CHAR' => 68,
			'BOOLEAN' => 82,
			'STRING' => 73,
			'OCTET' => 49,
			'VOID' => 223,
			'UNSIGNED' => 51,
			'ANY' => 52,
			'FLOAT' => 77,
			'LONG' => 54
		},
		GOTOS => {
			'integer_type' => 70,
			'unsigned_int' => 72,
			'sequence_type' => 224,
			'op_param_type_spec' => 225,
			'unsigned_short_int' => 48,
			'floating_pt_type' => 76,
			'any_type' => 56,
			'base_type_spec' => 226,
			'unsigned_long_int' => 59,
			'scoped_name' => 221,
			'string_type' => 222,
			'signed_int' => 83,
			'char_type' => 62,
			'signed_short_int' => 65,
			'signed_long_int' => 64,
			'op_type_spec' => 227,
			'boolean_type' => 85,
			'octet_type' => 66
		}
	},
	{#State 145
		ACTIONS => {
			";" => 43,
			'error' => 44
		},
		GOTOS => {
			'check_semicolon' => 228
		}
	},
	{#State 146
		ACTIONS => {
			"(" => 229,
			'error' => 230
		},
		GOTOS => {
			'parameter_dcls' => 231
		}
	},
	{#State 147
		ACTIONS => {
			"}" => 232
		}
	},
	{#State 148
		ACTIONS => {
			";" => 43,
			'error' => 44
		},
		GOTOS => {
			'check_semicolon' => 233
		}
	},
	{#State 149
		DEFAULT => -213
	},
	{#State 150
		ACTIONS => {
			";" => 43,
			'error' => 44
		},
		GOTOS => {
			'check_semicolon' => 234
		}
	},
	{#State 151
		DEFAULT => -29
	},
	{#State 152
		ACTIONS => {
			"}" => 235
		}
	},
	{#State 153
		DEFAULT => -197
	},
	{#State 154
		DEFAULT => -11
	},
	{#State 155
		ACTIONS => {
			'error' => 236,
			"=" => 237
		}
	},
	{#State 156
		DEFAULT => -51
	},
	{#State 157
		DEFAULT => -201
	},
	{#State 158
		ACTIONS => {
			"}" => 238
		}
	},
	{#State 159
		ACTIONS => {
			"}" => 239
		}
	},
	{#State 160
		ACTIONS => {
			"::" => 125
		},
		DEFAULT => -42
	},
	{#State 161
		DEFAULT => -38
	},
	{#State 162
		DEFAULT => -37
	},
	{#State 163
		ACTIONS => {
			"," => 240
		},
		DEFAULT => -40
	},
	{#State 164
		DEFAULT => -180
	},
	{#State 165
		ACTIONS => {
			'IDENTIFIER' => 109
		},
		DEFAULT => -179,
		GOTOS => {
			'enumerators' => 241,
			'enumerator' => 110
		}
	},
	{#State 166
		DEFAULT => -173
	},
	{#State 167
		DEFAULT => -172
	},
	{#State 168
		DEFAULT => -14
	},
	{#State 169
		DEFAULT => -15
	},
	{#State 170
		DEFAULT => -159
	},
	{#State 171
		ACTIONS => {
			"::" => 125
		},
		DEFAULT => -160
	},
	{#State 172
		DEFAULT => -157
	},
	{#State 173
		DEFAULT => -156
	},
	{#State 174
		ACTIONS => {
			")" => 242
		}
	},
	{#State 175
		ACTIONS => {
			")" => 243
		}
	},
	{#State 176
		DEFAULT => -158
	},
	{#State 177
		DEFAULT => -142
	},
	{#State 178
		DEFAULT => -147
	},
	{#State 179
		ACTIONS => {
			";" => 43,
			'error' => 44
		},
		GOTOS => {
			'check_semicolon' => 244
		}
	},
	{#State 180
		ACTIONS => {
			"{" => -145
		},
		DEFAULT => -143
	},
	{#State 181
		DEFAULT => -46
	},
	{#State 182
		DEFAULT => -47
	},
	{#State 183
		DEFAULT => -190
	},
	{#State 184
		ACTIONS => {
			"-" => 189,
			"::" => 67,
			'TRUE' => 201,
			'IDENTIFIER' => 58,
			"+" => 202,
			"~" => 190,
			'INTEGER_LITERAL' => 203,
			'FLOATING_PT_LITERAL' => 205,
			"(" => 199,
			'FALSE' => 192,
			'STRING_LITERAL' => 213,
			'error' => 245,
			'CHARACTER_LITERAL' => 207
		},
		GOTOS => {
			'and_expr' => 196,
			'or_expr' => 197,
			'mult_expr' => 208,
			'shift_expr' => 204,
			'scoped_name' => 198,
			'boolean_literal' => 209,
			'add_expr' => 210,
			'literal' => 191,
			'positive_int_const' => 246,
			'primary_expr' => 212,
			'unary_expr' => 200,
			'const_exp' => 193,
			'unary_operator' => 194,
			'xor_expr' => 214,
			'string_literal' => 195
		}
	},
	{#State 185
		ACTIONS => {
			"[" => 184
		},
		DEFAULT => -191,
		GOTOS => {
			'fixed_array_sizes' => 247,
			'fixed_array_size' => 185
		}
	},
	{#State 186
		ACTIONS => {
			'IDENTIFIER' => 129,
			'error' => 131
		},
		GOTOS => {
			'declarators' => 248,
			'array_declarator' => 133,
			'simple_declarator' => 128,
			'declarator' => 130,
			'complex_declarator' => 134
		}
	},
	{#State 187
		DEFAULT => -124
	},
	{#State 188
		DEFAULT => -123
	},
	{#State 189
		DEFAULT => -78
	},
	{#State 190
		DEFAULT => -80
	},
	{#State 191
		DEFAULT => -82
	},
	{#State 192
		DEFAULT => -93
	},
	{#State 193
		DEFAULT => -94
	},
	{#State 194
		ACTIONS => {
			"::" => 67,
			'TRUE' => 201,
			'IDENTIFIER' => 58,
			'INTEGER_LITERAL' => 203,
			'FLOATING_PT_LITERAL' => 205,
			"(" => 199,
			'FALSE' => 192,
			'STRING_LITERAL' => 213,
			'CHARACTER_LITERAL' => 207
		},
		GOTOS => {
			'literal' => 191,
			'primary_expr' => 249,
			'scoped_name' => 198,
			'boolean_literal' => 209,
			'string_literal' => 195
		}
	},
	{#State 195
		DEFAULT => -86
	},
	{#State 196
		ACTIONS => {
			"&" => 250
		},
		DEFAULT => -62
	},
	{#State 197
		ACTIONS => {
			"|" => 251
		},
		DEFAULT => -59
	},
	{#State 198
		ACTIONS => {
			"::" => 125
		},
		DEFAULT => -81
	},
	{#State 199
		ACTIONS => {
			"-" => 189,
			"::" => 67,
			'TRUE' => 201,
			'IDENTIFIER' => 58,
			"+" => 202,
			"~" => 190,
			'INTEGER_LITERAL' => 203,
			'FLOATING_PT_LITERAL' => 205,
			"(" => 199,
			'FALSE' => 192,
			'STRING_LITERAL' => 213,
			'error' => 253,
			'CHARACTER_LITERAL' => 207
		},
		GOTOS => {
			'and_expr' => 196,
			'or_expr' => 197,
			'mult_expr' => 208,
			'shift_expr' => 204,
			'scoped_name' => 198,
			'boolean_literal' => 209,
			'add_expr' => 210,
			'literal' => 191,
			'primary_expr' => 212,
			'unary_expr' => 200,
			'unary_operator' => 194,
			'const_exp' => 252,
			'xor_expr' => 214,
			'string_literal' => 195
		}
	},
	{#State 200
		DEFAULT => -72
	},
	{#State 201
		DEFAULT => -92
	},
	{#State 202
		DEFAULT => -79
	},
	{#State 203
		DEFAULT => -85
	},
	{#State 204
		ACTIONS => {
			"<<" => 255,
			">>" => 254
		},
		DEFAULT => -64
	},
	{#State 205
		DEFAULT => -88
	},
	{#State 206
		ACTIONS => {
			">" => 256
		}
	},
	{#State 207
		DEFAULT => -87
	},
	{#State 208
		ACTIONS => {
			"%" => 257,
			"*" => 258,
			"/" => 259
		},
		DEFAULT => -69
	},
	{#State 209
		DEFAULT => -89
	},
	{#State 210
		ACTIONS => {
			"-" => 260,
			"+" => 261
		},
		DEFAULT => -66
	},
	{#State 211
		ACTIONS => {
			">" => 262
		}
	},
	{#State 212
		DEFAULT => -77
	},
	{#State 213
		ACTIONS => {
			'STRING_LITERAL' => 213
		},
		DEFAULT => -90,
		GOTOS => {
			'string_literal' => 263
		}
	},
	{#State 214
		ACTIONS => {
			"^" => 264
		},
		DEFAULT => -60
	},
	{#State 215
		ACTIONS => {
			">" => 265
		}
	},
	{#State 216
		ACTIONS => {
			"," => 267,
			">" => 266
		}
	},
	{#State 217
		ACTIONS => {
			"::" => 67,
			'ENUM' => 2,
			'CHAR' => 68,
			'STRING' => 73,
			'OCTET' => 49,
			'UNION' => 10,
			'UNSIGNED' => 51,
			'error' => 273,
			'ANY' => 52,
			'FLOAT' => 77,
			'LONG' => 54,
			'SEQUENCE' => 78,
			'IDENTIFIER' => 58,
			'DOUBLE' => 79,
			'SHORT' => 81,
			'BOOLEAN' => 82,
			'STRUCT' => 24,
			'VOID' => 268
		},
		GOTOS => {
			'union_type' => 47,
			'integer_type' => 70,
			'unsigned_int' => 72,
			'sequence_type' => 270,
			'enum_header' => 4,
			'op_param_type_spec' => 271,
			'unsigned_short_int' => 48,
			'struct_type' => 50,
			'union_header' => 9,
			'constr_type_spec' => 272,
			'struct_header' => 13,
			'floating_pt_type' => 76,
			'enum_type' => 55,
			'any_type' => 56,
			'base_type_spec' => 226,
			'unsigned_long_int' => 59,
			'scoped_name' => 221,
			'signed_int' => 83,
			'string_type' => 222,
			'char_type' => 62,
			'signed_long_int' => 64,
			'signed_short_int' => 65,
			'param_type_spec' => 269,
			'boolean_type' => 85,
			'octet_type' => 66
		}
	},
	{#State 218
		DEFAULT => -34
	},
	{#State 219
		DEFAULT => -32
	},
	{#State 220
		DEFAULT => -31
	},
	{#State 221
		ACTIONS => {
			"::" => 125
		},
		DEFAULT => -250
	},
	{#State 222
		DEFAULT => -249
	},
	{#State 223
		DEFAULT => -215
	},
	{#State 224
		DEFAULT => -216
	},
	{#State 225
		DEFAULT => -214
	},
	{#State 226
		DEFAULT => -248
	},
	{#State 227
		ACTIONS => {
			'IDENTIFIER' => 274,
			'error' => 275
		}
	},
	{#State 228
		DEFAULT => -33
	},
	{#State 229
		ACTIONS => {
			"::" => -230,
			'ENUM' => -230,
			'CHAR' => -230,
			'STRING' => -230,
			'OCTET' => -230,
			'UNION' => -230,
			'UNSIGNED' => -230,
			'error' => 281,
			'ANY' => -230,
			'FLOAT' => -230,
			")" => 282,
			'LONG' => -230,
			'SEQUENCE' => -230,
			'DOUBLE' => -230,
			'IDENTIFIER' => -230,
			'SHORT' => -230,
			'BOOLEAN' => -230,
			'INOUT' => 277,
			"..." => 283,
			'STRUCT' => -230,
			'OUT' => 278,
			'IN' => 284,
			'VOID' => -230
		},
		GOTOS => {
			'param_attribute' => 276,
			'param_dcl' => 279,
			'param_dcls' => 280
		}
	},
	{#State 230
		DEFAULT => -208
	},
	{#State 231
		ACTIONS => {
			'RAISES' => 285
		},
		DEFAULT => -234,
		GOTOS => {
			'raises_expr' => 286
		}
	},
	{#State 232
		DEFAULT => -23
	},
	{#State 233
		DEFAULT => -36
	},
	{#State 234
		DEFAULT => -35
	},
	{#State 235
		DEFAULT => -24
	},
	{#State 236
		DEFAULT => -50
	},
	{#State 237
		ACTIONS => {
			"-" => 189,
			"::" => 67,
			'TRUE' => 201,
			'IDENTIFIER' => 58,
			"+" => 202,
			"~" => 190,
			'INTEGER_LITERAL' => 203,
			'FLOATING_PT_LITERAL' => 205,
			"(" => 199,
			'FALSE' => 192,
			'STRING_LITERAL' => 213,
			'error' => 288,
			'CHARACTER_LITERAL' => 207
		},
		GOTOS => {
			'and_expr' => 196,
			'or_expr' => 197,
			'mult_expr' => 208,
			'shift_expr' => 204,
			'scoped_name' => 198,
			'boolean_literal' => 209,
			'add_expr' => 210,
			'literal' => 191,
			'primary_expr' => 212,
			'unary_expr' => 200,
			'unary_operator' => 194,
			'const_exp' => 287,
			'xor_expr' => 214,
			'string_literal' => 195
		}
	},
	{#State 238
		DEFAULT => -202
	},
	{#State 239
		DEFAULT => -203
	},
	{#State 240
		ACTIONS => {
			"::" => 67,
			'IDENTIFIER' => 58
		},
		GOTOS => {
			'interface_name' => 163,
			'interface_names' => 289,
			'scoped_name' => 160
		}
	},
	{#State 241
		DEFAULT => -178
	},
	{#State 242
		DEFAULT => -152
	},
	{#State 243
		ACTIONS => {
			"{" => 291,
			'error' => 290
		}
	},
	{#State 244
		DEFAULT => -148
	},
	{#State 245
		ACTIONS => {
			"]" => 292
		}
	},
	{#State 246
		ACTIONS => {
			"]" => 293
		}
	},
	{#State 247
		DEFAULT => -192
	},
	{#State 248
		DEFAULT => -119
	},
	{#State 249
		DEFAULT => -76
	},
	{#State 250
		ACTIONS => {
			"-" => 189,
			"::" => 67,
			'TRUE' => 201,
			'IDENTIFIER' => 58,
			"+" => 202,
			"~" => 190,
			'INTEGER_LITERAL' => 203,
			'FLOATING_PT_LITERAL' => 205,
			"(" => 199,
			'FALSE' => 192,
			'STRING_LITERAL' => 213,
			'CHARACTER_LITERAL' => 207
		},
		GOTOS => {
			'mult_expr' => 208,
			'shift_expr' => 294,
			'scoped_name' => 198,
			'boolean_literal' => 209,
			'add_expr' => 210,
			'literal' => 191,
			'primary_expr' => 212,
			'unary_expr' => 200,
			'unary_operator' => 194,
			'string_literal' => 195
		}
	},
	{#State 251
		ACTIONS => {
			"-" => 189,
			"::" => 67,
			'TRUE' => 201,
			'IDENTIFIER' => 58,
			"+" => 202,
			"~" => 190,
			'INTEGER_LITERAL' => 203,
			'FLOATING_PT_LITERAL' => 205,
			"(" => 199,
			'FALSE' => 192,
			'STRING_LITERAL' => 213,
			'CHARACTER_LITERAL' => 207
		},
		GOTOS => {
			'and_expr' => 196,
			'mult_expr' => 208,
			'shift_expr' => 204,
			'scoped_name' => 198,
			'boolean_literal' => 209,
			'add_expr' => 210,
			'literal' => 191,
			'primary_expr' => 212,
			'unary_expr' => 200,
			'unary_operator' => 194,
			'xor_expr' => 295,
			'string_literal' => 195
		}
	},
	{#State 252
		ACTIONS => {
			")" => 296
		}
	},
	{#State 253
		ACTIONS => {
			")" => 297
		}
	},
	{#State 254
		ACTIONS => {
			"-" => 189,
			"::" => 67,
			'TRUE' => 201,
			'IDENTIFIER' => 58,
			"+" => 202,
			"~" => 190,
			'INTEGER_LITERAL' => 203,
			'FLOATING_PT_LITERAL' => 205,
			"(" => 199,
			'FALSE' => 192,
			'STRING_LITERAL' => 213,
			'CHARACTER_LITERAL' => 207
		},
		GOTOS => {
			'mult_expr' => 208,
			'scoped_name' => 198,
			'boolean_literal' => 209,
			'literal' => 191,
			'add_expr' => 298,
			'primary_expr' => 212,
			'unary_expr' => 200,
			'unary_operator' => 194,
			'string_literal' => 195
		}
	},
	{#State 255
		ACTIONS => {
			"-" => 189,
			"::" => 67,
			'TRUE' => 201,
			'IDENTIFIER' => 58,
			"+" => 202,
			"~" => 190,
			'INTEGER_LITERAL' => 203,
			'FLOATING_PT_LITERAL' => 205,
			"(" => 199,
			'FALSE' => 192,
			'STRING_LITERAL' => 213,
			'CHARACTER_LITERAL' => 207
		},
		GOTOS => {
			'mult_expr' => 208,
			'scoped_name' => 198,
			'boolean_literal' => 209,
			'literal' => 191,
			'add_expr' => 299,
			'primary_expr' => 212,
			'unary_expr' => 200,
			'unary_operator' => 194,
			'string_literal' => 195
		}
	},
	{#State 256
		DEFAULT => -189
	},
	{#State 257
		ACTIONS => {
			"-" => 189,
			"::" => 67,
			'TRUE' => 201,
			'IDENTIFIER' => 58,
			"+" => 202,
			"~" => 190,
			'INTEGER_LITERAL' => 203,
			'FLOATING_PT_LITERAL' => 205,
			"(" => 199,
			'FALSE' => 192,
			'STRING_LITERAL' => 213,
			'CHARACTER_LITERAL' => 207
		},
		GOTOS => {
			'literal' => 191,
			'primary_expr' => 212,
			'unary_expr' => 300,
			'unary_operator' => 194,
			'scoped_name' => 198,
			'boolean_literal' => 209,
			'string_literal' => 195
		}
	},
	{#State 258
		ACTIONS => {
			"-" => 189,
			"::" => 67,
			'TRUE' => 201,
			'IDENTIFIER' => 58,
			"+" => 202,
			"~" => 190,
			'INTEGER_LITERAL' => 203,
			'FLOATING_PT_LITERAL' => 205,
			"(" => 199,
			'FALSE' => 192,
			'STRING_LITERAL' => 213,
			'CHARACTER_LITERAL' => 207
		},
		GOTOS => {
			'literal' => 191,
			'primary_expr' => 212,
			'unary_expr' => 301,
			'unary_operator' => 194,
			'scoped_name' => 198,
			'boolean_literal' => 209,
			'string_literal' => 195
		}
	},
	{#State 259
		ACTIONS => {
			"-" => 189,
			"::" => 67,
			'TRUE' => 201,
			'IDENTIFIER' => 58,
			"+" => 202,
			"~" => 190,
			'INTEGER_LITERAL' => 203,
			'FLOATING_PT_LITERAL' => 205,
			"(" => 199,
			'FALSE' => 192,
			'STRING_LITERAL' => 213,
			'CHARACTER_LITERAL' => 207
		},
		GOTOS => {
			'literal' => 191,
			'primary_expr' => 212,
			'unary_expr' => 302,
			'unary_operator' => 194,
			'scoped_name' => 198,
			'boolean_literal' => 209,
			'string_literal' => 195
		}
	},
	{#State 260
		ACTIONS => {
			"-" => 189,
			"::" => 67,
			'TRUE' => 201,
			'IDENTIFIER' => 58,
			"+" => 202,
			"~" => 190,
			'INTEGER_LITERAL' => 203,
			'FLOATING_PT_LITERAL' => 205,
			"(" => 199,
			'FALSE' => 192,
			'STRING_LITERAL' => 213,
			'CHARACTER_LITERAL' => 207
		},
		GOTOS => {
			'mult_expr' => 303,
			'scoped_name' => 198,
			'boolean_literal' => 209,
			'literal' => 191,
			'unary_expr' => 200,
			'primary_expr' => 212,
			'unary_operator' => 194,
			'string_literal' => 195
		}
	},
	{#State 261
		ACTIONS => {
			"-" => 189,
			"::" => 67,
			'TRUE' => 201,
			'IDENTIFIER' => 58,
			"+" => 202,
			"~" => 190,
			'INTEGER_LITERAL' => 203,
			'FLOATING_PT_LITERAL' => 205,
			"(" => 199,
			'FALSE' => 192,
			'STRING_LITERAL' => 213,
			'CHARACTER_LITERAL' => 207
		},
		GOTOS => {
			'mult_expr' => 304,
			'scoped_name' => 198,
			'boolean_literal' => 209,
			'literal' => 191,
			'unary_expr' => 200,
			'primary_expr' => 212,
			'unary_operator' => 194,
			'string_literal' => 195
		}
	},
	{#State 262
		DEFAULT => -187
	},
	{#State 263
		DEFAULT => -91
	},
	{#State 264
		ACTIONS => {
			"-" => 189,
			"::" => 67,
			'TRUE' => 201,
			'IDENTIFIER' => 58,
			"+" => 202,
			"~" => 190,
			'INTEGER_LITERAL' => 203,
			'FLOATING_PT_LITERAL' => 205,
			"(" => 199,
			'FALSE' => 192,
			'STRING_LITERAL' => 213,
			'CHARACTER_LITERAL' => 207
		},
		GOTOS => {
			'and_expr' => 305,
			'mult_expr' => 208,
			'shift_expr' => 204,
			'scoped_name' => 198,
			'boolean_literal' => 209,
			'add_expr' => 210,
			'literal' => 191,
			'primary_expr' => 212,
			'unary_expr' => 200,
			'unary_operator' => 194,
			'string_literal' => 195
		}
	},
	{#State 265
		DEFAULT => -185
	},
	{#State 266
		DEFAULT => -184
	},
	{#State 267
		ACTIONS => {
			"-" => 189,
			"::" => 67,
			'TRUE' => 201,
			'IDENTIFIER' => 58,
			"+" => 202,
			"~" => 190,
			'INTEGER_LITERAL' => 203,
			'FLOATING_PT_LITERAL' => 205,
			"(" => 199,
			'FALSE' => 192,
			'STRING_LITERAL' => 213,
			'error' => 306,
			'CHARACTER_LITERAL' => 207
		},
		GOTOS => {
			'and_expr' => 196,
			'or_expr' => 197,
			'mult_expr' => 208,
			'shift_expr' => 204,
			'scoped_name' => 198,
			'boolean_literal' => 209,
			'add_expr' => 210,
			'literal' => 191,
			'positive_int_const' => 307,
			'primary_expr' => 212,
			'unary_expr' => 200,
			'const_exp' => 193,
			'unary_operator' => 194,
			'xor_expr' => 214,
			'string_literal' => 195
		}
	},
	{#State 268
		DEFAULT => -245
	},
	{#State 269
		ACTIONS => {
			'IDENTIFIER' => 309,
			'error' => 131
		},
		GOTOS => {
			'simple_declarators' => 310,
			'simple_declarator' => 308
		}
	},
	{#State 270
		DEFAULT => -246
	},
	{#State 271
		DEFAULT => -244
	},
	{#State 272
		DEFAULT => -247
	},
	{#State 273
		DEFAULT => -196
	},
	{#State 274
		DEFAULT => -209
	},
	{#State 275
		DEFAULT => -210
	},
	{#State 276
		ACTIONS => {
			"::" => 67,
			'ENUM' => 2,
			'CHAR' => 68,
			'STRING' => 73,
			'OCTET' => 49,
			'UNION' => 10,
			'UNSIGNED' => 51,
			'ANY' => 52,
			'FLOAT' => 77,
			'LONG' => 54,
			'SEQUENCE' => 78,
			'IDENTIFIER' => 58,
			'DOUBLE' => 79,
			'SHORT' => 81,
			'BOOLEAN' => 82,
			'STRUCT' => 24,
			'VOID' => 268
		},
		GOTOS => {
			'union_type' => 47,
			'integer_type' => 70,
			'unsigned_int' => 72,
			'sequence_type' => 270,
			'enum_header' => 4,
			'op_param_type_spec' => 271,
			'unsigned_short_int' => 48,
			'struct_type' => 50,
			'union_header' => 9,
			'constr_type_spec' => 272,
			'struct_header' => 13,
			'floating_pt_type' => 76,
			'enum_type' => 55,
			'any_type' => 56,
			'base_type_spec' => 226,
			'unsigned_long_int' => 59,
			'scoped_name' => 221,
			'signed_int' => 83,
			'string_type' => 222,
			'char_type' => 62,
			'signed_long_int' => 64,
			'signed_short_int' => 65,
			'param_type_spec' => 311,
			'boolean_type' => 85,
			'octet_type' => 66
		}
	},
	{#State 277
		DEFAULT => -229
	},
	{#State 278
		DEFAULT => -228
	},
	{#State 279
		ACTIONS => {
			";" => 312
		},
		DEFAULT => -223
	},
	{#State 280
		ACTIONS => {
			"," => 313,
			")" => 314
		}
	},
	{#State 281
		ACTIONS => {
			")" => 315
		}
	},
	{#State 282
		DEFAULT => -220
	},
	{#State 283
		ACTIONS => {
			")" => 316
		}
	},
	{#State 284
		DEFAULT => -227
	},
	{#State 285
		ACTIONS => {
			"(" => 317,
			'error' => 318
		}
	},
	{#State 286
		ACTIONS => {
			'CONTEXT' => 320
		},
		DEFAULT => -241,
		GOTOS => {
			'context_expr' => 319
		}
	},
	{#State 287
		DEFAULT => -48
	},
	{#State 288
		DEFAULT => -49
	},
	{#State 289
		DEFAULT => -41
	},
	{#State 290
		DEFAULT => -151
	},
	{#State 291
		ACTIONS => {
			'DEFAULT' => 326,
			'error' => 324,
			'CASE' => 321
		},
		GOTOS => {
			'case_label' => 327,
			'switch_body' => 322,
			'case' => 323,
			'case_labels' => 325
		}
	},
	{#State 292
		DEFAULT => -194
	},
	{#State 293
		DEFAULT => -193
	},
	{#State 294
		ACTIONS => {
			"<<" => 255,
			">>" => 254
		},
		DEFAULT => -65
	},
	{#State 295
		ACTIONS => {
			"^" => 264
		},
		DEFAULT => -61
	},
	{#State 296
		DEFAULT => -83
	},
	{#State 297
		DEFAULT => -84
	},
	{#State 298
		ACTIONS => {
			"-" => 260,
			"+" => 261
		},
		DEFAULT => -67
	},
	{#State 299
		ACTIONS => {
			"-" => 260,
			"+" => 261
		},
		DEFAULT => -68
	},
	{#State 300
		DEFAULT => -75
	},
	{#State 301
		DEFAULT => -73
	},
	{#State 302
		DEFAULT => -74
	},
	{#State 303
		ACTIONS => {
			"%" => 257,
			"*" => 258,
			"/" => 259
		},
		DEFAULT => -71
	},
	{#State 304
		ACTIONS => {
			"%" => 257,
			"*" => 258,
			"/" => 259
		},
		DEFAULT => -70
	},
	{#State 305
		ACTIONS => {
			"&" => 250
		},
		DEFAULT => -63
	},
	{#State 306
		ACTIONS => {
			">" => 328
		}
	},
	{#State 307
		ACTIONS => {
			">" => 329
		}
	},
	{#State 308
		ACTIONS => {
			"," => 330
		},
		DEFAULT => -199
	},
	{#State 309
		DEFAULT => -122
	},
	{#State 310
		DEFAULT => -195
	},
	{#State 311
		ACTIONS => {
			'IDENTIFIER' => 309,
			'error' => 131
		},
		GOTOS => {
			'simple_declarator' => 331
		}
	},
	{#State 312
		DEFAULT => -225
	},
	{#State 313
		ACTIONS => {
			")" => 333,
			'INOUT' => 277,
			"..." => 334,
			'OUT' => 278,
			'IN' => 284
		},
		DEFAULT => -230,
		GOTOS => {
			'param_attribute' => 276,
			'param_dcl' => 332
		}
	},
	{#State 314
		DEFAULT => -217
	},
	{#State 315
		DEFAULT => -222
	},
	{#State 316
		DEFAULT => -221
	},
	{#State 317
		ACTIONS => {
			"::" => 67,
			'IDENTIFIER' => 58,
			'error' => 336
		},
		GOTOS => {
			'exception_names' => 337,
			'scoped_name' => 335,
			'exception_name' => 338
		}
	},
	{#State 318
		DEFAULT => -233
	},
	{#State 319
		DEFAULT => -207
	},
	{#State 320
		ACTIONS => {
			"(" => 339,
			'error' => 340
		}
	},
	{#State 321
		ACTIONS => {
			"-" => 189,
			"::" => 67,
			'TRUE' => 201,
			'IDENTIFIER' => 58,
			"+" => 202,
			"~" => 190,
			'INTEGER_LITERAL' => 203,
			'FLOATING_PT_LITERAL' => 205,
			"(" => 199,
			'FALSE' => 192,
			'STRING_LITERAL' => 213,
			'error' => 342,
			'CHARACTER_LITERAL' => 207
		},
		GOTOS => {
			'and_expr' => 196,
			'or_expr' => 197,
			'mult_expr' => 208,
			'shift_expr' => 204,
			'scoped_name' => 198,
			'boolean_literal' => 209,
			'add_expr' => 210,
			'literal' => 191,
			'primary_expr' => 212,
			'unary_expr' => 200,
			'unary_operator' => 194,
			'const_exp' => 341,
			'xor_expr' => 214,
			'string_literal' => 195
		}
	},
	{#State 322
		ACTIONS => {
			"}" => 343
		}
	},
	{#State 323
		ACTIONS => {
			'DEFAULT' => 326,
			'CASE' => 321
		},
		DEFAULT => -161,
		GOTOS => {
			'case_label' => 327,
			'switch_body' => 344,
			'case' => 323,
			'case_labels' => 325
		}
	},
	{#State 324
		ACTIONS => {
			"}" => 345
		}
	},
	{#State 325
		ACTIONS => {
			"::" => 67,
			'ENUM' => 2,
			'CHAR' => 68,
			'STRING' => 73,
			'OCTET' => 49,
			'UNION' => 10,
			'UNSIGNED' => 51,
			'ANY' => 52,
			'FLOAT' => 77,
			'LONG' => 54,
			'SEQUENCE' => 78,
			'IDENTIFIER' => 58,
			'DOUBLE' => 79,
			'SHORT' => 81,
			'BOOLEAN' => 82,
			'STRUCT' => 24,
			'VOID' => 63
		},
		GOTOS => {
			'union_type' => 47,
			'type_spec' => 347,
			'integer_type' => 70,
			'sequence_type' => 71,
			'unsigned_int' => 72,
			'enum_header' => 4,
			'unsigned_short_int' => 48,
			'struct_type' => 50,
			'union_header' => 9,
			'constr_type_spec' => 74,
			'struct_header' => 13,
			'floating_pt_type' => 76,
			'enum_type' => 55,
			'any_type' => 56,
			'template_type_spec' => 57,
			'base_type_spec' => 80,
			'element_spec' => 346,
			'unsigned_long_int' => 59,
			'scoped_name' => 60,
			'signed_int' => 83,
			'string_type' => 61,
			'simple_type_spec' => 84,
			'char_type' => 62,
			'signed_long_int' => 64,
			'signed_short_int' => 65,
			'boolean_type' => 85,
			'octet_type' => 66
		}
	},
	{#State 326
		ACTIONS => {
			":" => 348,
			'error' => 349
		}
	},
	{#State 327
		ACTIONS => {
			'CASE' => 321,
			'DEFAULT' => 326
		},
		DEFAULT => -164,
		GOTOS => {
			'case_label' => 327,
			'case_labels' => 350
		}
	},
	{#State 328
		DEFAULT => -183
	},
	{#State 329
		DEFAULT => -182
	},
	{#State 330
		ACTIONS => {
			'IDENTIFIER' => 309,
			'error' => 131
		},
		GOTOS => {
			'simple_declarators' => 351,
			'simple_declarator' => 308
		}
	},
	{#State 331
		DEFAULT => -226
	},
	{#State 332
		DEFAULT => -224
	},
	{#State 333
		DEFAULT => -219
	},
	{#State 334
		ACTIONS => {
			")" => 352
		}
	},
	{#State 335
		ACTIONS => {
			"::" => 125
		},
		DEFAULT => -237
	},
	{#State 336
		ACTIONS => {
			")" => 353
		}
	},
	{#State 337
		ACTIONS => {
			")" => 354
		}
	},
	{#State 338
		ACTIONS => {
			"," => 355
		},
		DEFAULT => -235
	},
	{#State 339
		ACTIONS => {
			'STRING_LITERAL' => 213,
			'error' => 358
		},
		GOTOS => {
			'string_literals' => 357,
			'string_literal' => 356
		}
	},
	{#State 340
		DEFAULT => -240
	},
	{#State 341
		ACTIONS => {
			":" => 359,
			'error' => 360
		}
	},
	{#State 342
		DEFAULT => -168
	},
	{#State 343
		DEFAULT => -149
	},
	{#State 344
		DEFAULT => -162
	},
	{#State 345
		DEFAULT => -150
	},
	{#State 346
		ACTIONS => {
			";" => 43,
			'error' => 44
		},
		GOTOS => {
			'check_semicolon' => 361
		}
	},
	{#State 347
		ACTIONS => {
			'IDENTIFIER' => 129,
			'error' => 131
		},
		GOTOS => {
			'array_declarator' => 133,
			'simple_declarator' => 128,
			'declarator' => 362,
			'complex_declarator' => 134
		}
	},
	{#State 348
		DEFAULT => -169
	},
	{#State 349
		DEFAULT => -170
	},
	{#State 350
		DEFAULT => -165
	},
	{#State 351
		DEFAULT => -200
	},
	{#State 352
		DEFAULT => -218
	},
	{#State 353
		DEFAULT => -232
	},
	{#State 354
		DEFAULT => -231
	},
	{#State 355
		ACTIONS => {
			"::" => 67,
			'IDENTIFIER' => 58
		},
		GOTOS => {
			'exception_names' => 363,
			'scoped_name' => 335,
			'exception_name' => 338
		}
	},
	{#State 356
		ACTIONS => {
			"," => 364
		},
		DEFAULT => -242
	},
	{#State 357
		ACTIONS => {
			")" => 365
		}
	},
	{#State 358
		ACTIONS => {
			")" => 366
		}
	},
	{#State 359
		DEFAULT => -166
	},
	{#State 360
		DEFAULT => -167
	},
	{#State 361
		DEFAULT => -163
	},
	{#State 362
		DEFAULT => -171
	},
	{#State 363
		DEFAULT => -236
	},
	{#State 364
		ACTIONS => {
			'STRING_LITERAL' => 213
		},
		GOTOS => {
			'string_literals' => 367,
			'string_literal' => 356
		}
	},
	{#State 365
		DEFAULT => -238
	},
	{#State 366
		DEFAULT => -239
	},
	{#State 367
		DEFAULT => -243
	}
],
                                  yyrules  =>
[
	[#Rule 0
		 '$start', 2, undef
	],
	[#Rule 1
		 'specification', 1,
sub
#line 52 "Parser20.yp"
{
            $_[0]->YYData->{root} = new CORBA::IDL::Specification($_[0],
                    'list_decl'         =>  $_[1],
            );
        }
	],
	[#Rule 2
		 'specification', 0,
sub
#line 58 "Parser20.yp"
{
            $_[0]->Error("Empty specification.\n");
        }
	],
	[#Rule 3
		 'specification', 1,
sub
#line 62 "Parser20.yp"
{
            $_[0]->Error("definition declaration expected.\n");
        }
	],
	[#Rule 4
		 'definitions', 1,
sub
#line 69 "Parser20.yp"
{
            [$_[1]->getRef()];
        }
	],
	[#Rule 5
		 'definitions', 2,
sub
#line 73 "Parser20.yp"
{
            unshift @{$_[2]}, $_[1]->getRef();
            $_[2];
        }
	],
	[#Rule 6
		 'definition', 2, undef
	],
	[#Rule 7
		 'definition', 2, undef
	],
	[#Rule 8
		 'definition', 2, undef
	],
	[#Rule 9
		 'definition', 2, undef
	],
	[#Rule 10
		 'definition', 2, undef
	],
	[#Rule 11
		 'definition', 3,
sub
#line 92 "Parser20.yp"
{
            # when IDENTIFIER is a future keyword
            $_[0]->Error("'$_[1]' unexpected.\n");
            $_[0]->YYErrok();
            new CORBA::IDL::Node($_[0],
                    'idf'                   =>  $_[1]
            );
        }
	],
	[#Rule 12
		 'check_semicolon', 1, undef
	],
	[#Rule 13
		 'check_semicolon', 1,
sub
#line 106 "Parser20.yp"
{
            $_[0]->Warning("';' expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 14
		 'module', 4,
sub
#line 115 "Parser20.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
            $_[1]->Configure($_[0],
                    'list_decl'         =>  $_[3]
            ) if (defined $_[1]);
        }
	],
	[#Rule 15
		 'module', 4,
sub
#line 122 "Parser20.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
            $_[0]->Error("definition declaration expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 16
		 'module', 3,
sub
#line 129 "Parser20.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
            $_[0]->Error("Empty module.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 17
		 'module', 3,
sub
#line 136 "Parser20.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
            $_[0]->Error("'\x7b' expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 18
		 'module_header', 2,
sub
#line 146 "Parser20.yp"
{
            new CORBA::IDL::Module($_[0],
                    'idf'               =>  $_[2],
            );
        }
	],
	[#Rule 19
		 'module_header', 2,
sub
#line 152 "Parser20.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 20
		 'interface', 1, undef
	],
	[#Rule 21
		 'interface', 1, undef
	],
	[#Rule 22
		 'interface_dcl', 3,
sub
#line 169 "Parser20.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->YYData->{curr_itf} = undef;
            $_[1]->Configure($_[0],
                    'list_decl'     =>  []
            ) if (defined $_[1]);
        }
	],
	[#Rule 23
		 'interface_dcl', 4,
sub
#line 177 "Parser20.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->YYData->{curr_itf} = undef;
            $_[1]->Configure($_[0],
                    'list_decl'     =>  $_[3]
            ) if (defined $_[1]);
        }
	],
	[#Rule 24
		 'interface_dcl', 4,
sub
#line 185 "Parser20.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->YYData->{curr_itf} = undef;
            $_[0]->Error("export declaration expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 25
		 'forward_dcl', 2,
sub
#line 197 "Parser20.yp"
{
            new CORBA::IDL::ForwardRegularInterface($_[0],
                    'idf'                   =>  $_[2]
            );
        }
	],
	[#Rule 26
		 'forward_dcl', 2,
sub
#line 203 "Parser20.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 27
		 'interface_header', 3,
sub
#line 212 "Parser20.yp"
{
            new CORBA::IDL::RegularInterface($_[0],
                    'idf'                   =>  $_[2],
                    'inheritance'           =>  $_[3]
            );
        }
	],
	[#Rule 28
		 'interface_header', 2,
sub
#line 219 "Parser20.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 29
		 'interface_body', 1, undef
	],
	[#Rule 30
		 'exports', 1,
sub
#line 233 "Parser20.yp"
{
            [$_[1]->getRef()];
        }
	],
	[#Rule 31
		 'exports', 2,
sub
#line 237 "Parser20.yp"
{
            unshift @{$_[2]}, $_[1]->getRef();
            $_[2];
        }
	],
	[#Rule 32
		 'export', 2, undef
	],
	[#Rule 33
		 'export', 2, undef
	],
	[#Rule 34
		 'export', 2, undef
	],
	[#Rule 35
		 'export', 2, undef
	],
	[#Rule 36
		 'export', 2, undef
	],
	[#Rule 37
		 'interface_inheritance_spec', 2,
sub
#line 260 "Parser20.yp"
{
            new CORBA::IDL::InheritanceSpec($_[0],
                    'list_interface'        =>  $_[2]
            );
        }
	],
	[#Rule 38
		 'interface_inheritance_spec', 2,
sub
#line 266 "Parser20.yp"
{
            $_[0]->Error("Interface name expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 39
		 'interface_inheritance_spec', 0, undef
	],
	[#Rule 40
		 'interface_names', 1,
sub
#line 276 "Parser20.yp"
{
            [$_[1]];
        }
	],
	[#Rule 41
		 'interface_names', 3,
sub
#line 280 "Parser20.yp"
{
            unshift @{$_[3]}, $_[1];
            $_[3];
        }
	],
	[#Rule 42
		 'interface_name', 1,
sub
#line 288 "Parser20.yp"
{
                CORBA::IDL::Interface->Lookup($_[0], $_[1]);
        }
	],
	[#Rule 43
		 'scoped_name', 1, undef
	],
	[#Rule 44
		 'scoped_name', 2,
sub
#line 298 "Parser20.yp"
{
            $_[1] . $_[2];
        }
	],
	[#Rule 45
		 'scoped_name', 2,
sub
#line 302 "Parser20.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
            '';
        }
	],
	[#Rule 46
		 'scoped_name', 3,
sub
#line 308 "Parser20.yp"
{
            $_[1] . $_[2] . $_[3];
        }
	],
	[#Rule 47
		 'scoped_name', 3,
sub
#line 312 "Parser20.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 48
		 'const_dcl', 5,
sub
#line 322 "Parser20.yp"
{
            new CORBA::IDL::Constant($_[0],
                    'type'              =>  $_[2],
                    'idf'               =>  $_[3],
                    'list_expr'         =>  $_[5]
            );
        }
	],
	[#Rule 49
		 'const_dcl', 5,
sub
#line 330 "Parser20.yp"
{
            $_[0]->Error("Expression expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 50
		 'const_dcl', 4,
sub
#line 335 "Parser20.yp"
{
            $_[0]->Error("'=' expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 51
		 'const_dcl', 3,
sub
#line 340 "Parser20.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 52
		 'const_dcl', 2,
sub
#line 345 "Parser20.yp"
{
            $_[0]->Error("const_type expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 53
		 'const_type', 1, undef
	],
	[#Rule 54
		 'const_type', 1, undef
	],
	[#Rule 55
		 'const_type', 1, undef
	],
	[#Rule 56
		 'const_type', 1, undef
	],
	[#Rule 57
		 'const_type', 1, undef
	],
	[#Rule 58
		 'const_type', 1,
sub
#line 364 "Parser20.yp"
{
            CORBA::IDL::TypeDeclarator->Lookup($_[0], $_[1]);
        }
	],
	[#Rule 59
		 'const_exp', 1, undef
	],
	[#Rule 60
		 'or_expr', 1, undef
	],
	[#Rule 61
		 'or_expr', 3,
sub
#line 380 "Parser20.yp"
{
            BuildBinop($_[1], $_[2], $_[3]);
        }
	],
	[#Rule 62
		 'xor_expr', 1, undef
	],
	[#Rule 63
		 'xor_expr', 3,
sub
#line 390 "Parser20.yp"
{
            BuildBinop($_[1], $_[2], $_[3]);
        }
	],
	[#Rule 64
		 'and_expr', 1, undef
	],
	[#Rule 65
		 'and_expr', 3,
sub
#line 400 "Parser20.yp"
{
            BuildBinop($_[1], $_[2], $_[3]);
        }
	],
	[#Rule 66
		 'shift_expr', 1, undef
	],
	[#Rule 67
		 'shift_expr', 3,
sub
#line 410 "Parser20.yp"
{
            BuildBinop($_[1], $_[2], $_[3]);
        }
	],
	[#Rule 68
		 'shift_expr', 3,
sub
#line 414 "Parser20.yp"
{
            BuildBinop($_[1], $_[2], $_[3]);
        }
	],
	[#Rule 69
		 'add_expr', 1, undef
	],
	[#Rule 70
		 'add_expr', 3,
sub
#line 424 "Parser20.yp"
{
            BuildBinop($_[1], $_[2], $_[3]);
        }
	],
	[#Rule 71
		 'add_expr', 3,
sub
#line 428 "Parser20.yp"
{
            BuildBinop($_[1], $_[2], $_[3]);
        }
	],
	[#Rule 72
		 'mult_expr', 1, undef
	],
	[#Rule 73
		 'mult_expr', 3,
sub
#line 438 "Parser20.yp"
{
            BuildBinop($_[1], $_[2], $_[3]);
        }
	],
	[#Rule 74
		 'mult_expr', 3,
sub
#line 442 "Parser20.yp"
{
            BuildBinop($_[1], $_[2], $_[3]);
        }
	],
	[#Rule 75
		 'mult_expr', 3,
sub
#line 446 "Parser20.yp"
{
            BuildBinop($_[1], $_[2], $_[3]);
        }
	],
	[#Rule 76
		 'unary_expr', 2,
sub
#line 454 "Parser20.yp"
{
            BuildUnop($_[1], $_[2]);
        }
	],
	[#Rule 77
		 'unary_expr', 1, undef
	],
	[#Rule 78
		 'unary_operator', 1, undef
	],
	[#Rule 79
		 'unary_operator', 1, undef
	],
	[#Rule 80
		 'unary_operator', 1, undef
	],
	[#Rule 81
		 'primary_expr', 1,
sub
#line 474 "Parser20.yp"
{
            [
                CORBA::IDL::Constant->Lookup($_[0], $_[1])
            ];
        }
	],
	[#Rule 82
		 'primary_expr', 1,
sub
#line 480 "Parser20.yp"
{
            [ $_[1] ];
        }
	],
	[#Rule 83
		 'primary_expr', 3,
sub
#line 484 "Parser20.yp"
{
            $_[2];
        }
	],
	[#Rule 84
		 'primary_expr', 3,
sub
#line 488 "Parser20.yp"
{
            $_[0]->Error("Expression expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 85
		 'literal', 1,
sub
#line 497 "Parser20.yp"
{
            new CORBA::IDL::IntegerLiteral($_[0],
                    'value'             =>  $_[1],
                    'lexeme'            =>  $_[0]->YYData->{lexeme}
            );
        }
	],
	[#Rule 86
		 'literal', 1,
sub
#line 504 "Parser20.yp"
{
            new CORBA::IDL::StringLiteral($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 87
		 'literal', 1,
sub
#line 510 "Parser20.yp"
{
            new CORBA::IDL::CharacterLiteral($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 88
		 'literal', 1,
sub
#line 516 "Parser20.yp"
{
            new CORBA::IDL::FloatingPtLiteral($_[0],
                    'value'             =>  $_[1],
                    'lexeme'            =>  $_[0]->YYData->{lexeme}
            );
        }
	],
	[#Rule 89
		 'literal', 1, undef
	],
	[#Rule 90
		 'string_literal', 1, undef
	],
	[#Rule 91
		 'string_literal', 2,
sub
#line 530 "Parser20.yp"
{
            $_[1] . $_[2];
        }
	],
	[#Rule 92
		 'boolean_literal', 1,
sub
#line 538 "Parser20.yp"
{
            new CORBA::IDL::BooleanLiteral($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 93
		 'boolean_literal', 1,
sub
#line 544 "Parser20.yp"
{
            new CORBA::IDL::BooleanLiteral($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 94
		 'positive_int_const', 1,
sub
#line 554 "Parser20.yp"
{
            new CORBA::IDL::Expression($_[0],
                    'list_expr'         =>  $_[1]
            );
        }
	],
	[#Rule 95
		 'type_dcl', 2,
sub
#line 564 "Parser20.yp"
{
            $_[2];
        }
	],
	[#Rule 96
		 'type_dcl', 1, undef
	],
	[#Rule 97
		 'type_dcl', 1, undef
	],
	[#Rule 98
		 'type_dcl', 1, undef
	],
	[#Rule 99
		 'type_dcl', 2,
sub
#line 574 "Parser20.yp"
{
            $_[0]->Error("type_declarator expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 100
		 'type_declarator', 2,
sub
#line 583 "Parser20.yp"
{
            new CORBA::IDL::TypeDeclarators($_[0],
                    'type'              =>  $_[1],
                    'list_expr'         =>  $_[2]
            );
        }
	],
	[#Rule 101
		 'type_spec', 1, undef
	],
	[#Rule 102
		 'type_spec', 1, undef
	],
	[#Rule 103
		 'simple_type_spec', 1, undef
	],
	[#Rule 104
		 'simple_type_spec', 1, undef
	],
	[#Rule 105
		 'simple_type_spec', 1,
sub
#line 606 "Parser20.yp"
{
            CORBA::IDL::TypeDeclarator->Lookup($_[0], $_[1]);
        }
	],
	[#Rule 106
		 'simple_type_spec', 1,
sub
#line 610 "Parser20.yp"
{
            $_[0]->Error("simple_type_spec expected.\n");
            new CORBA::IDL::VoidType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 107
		 'base_type_spec', 1, undef
	],
	[#Rule 108
		 'base_type_spec', 1, undef
	],
	[#Rule 109
		 'base_type_spec', 1, undef
	],
	[#Rule 110
		 'base_type_spec', 1, undef
	],
	[#Rule 111
		 'base_type_spec', 1, undef
	],
	[#Rule 112
		 'base_type_spec', 1, undef
	],
	[#Rule 113
		 'template_type_spec', 1, undef
	],
	[#Rule 114
		 'template_type_spec', 1, undef
	],
	[#Rule 115
		 'constr_type_spec', 1, undef
	],
	[#Rule 116
		 'constr_type_spec', 1, undef
	],
	[#Rule 117
		 'constr_type_spec', 1, undef
	],
	[#Rule 118
		 'declarators', 1,
sub
#line 655 "Parser20.yp"
{
            [$_[1]];
        }
	],
	[#Rule 119
		 'declarators', 3,
sub
#line 659 "Parser20.yp"
{
            unshift @{$_[3]}, $_[1];
            $_[3];
        }
	],
	[#Rule 120
		 'declarator', 1,
sub
#line 668 "Parser20.yp"
{
            [$_[1]];
        }
	],
	[#Rule 121
		 'declarator', 1, undef
	],
	[#Rule 122
		 'simple_declarator', 1, undef
	],
	[#Rule 123
		 'simple_declarator', 2,
sub
#line 680 "Parser20.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 124
		 'simple_declarator', 2,
sub
#line 685 "Parser20.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 125
		 'complex_declarator', 1, undef
	],
	[#Rule 126
		 'floating_pt_type', 1,
sub
#line 700 "Parser20.yp"
{
            new CORBA::IDL::FloatingPtType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 127
		 'floating_pt_type', 1,
sub
#line 706 "Parser20.yp"
{
            new CORBA::IDL::FloatingPtType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 128
		 'integer_type', 1, undef
	],
	[#Rule 129
		 'integer_type', 1, undef
	],
	[#Rule 130
		 'signed_int', 1, undef
	],
	[#Rule 131
		 'signed_int', 1, undef
	],
	[#Rule 132
		 'signed_long_int', 1,
sub
#line 732 "Parser20.yp"
{
            new CORBA::IDL::IntegerType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 133
		 'signed_short_int', 1,
sub
#line 742 "Parser20.yp"
{
            new CORBA::IDL::IntegerType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 134
		 'unsigned_int', 1, undef
	],
	[#Rule 135
		 'unsigned_int', 1, undef
	],
	[#Rule 136
		 'unsigned_long_int', 2,
sub
#line 760 "Parser20.yp"
{
            new CORBA::IDL::IntegerType($_[0],
                    'value'             =>  $_[1] . q{ } . $_[2]
            );
        }
	],
	[#Rule 137
		 'unsigned_short_int', 2,
sub
#line 770 "Parser20.yp"
{
            new CORBA::IDL::IntegerType($_[0],
                    'value'             =>  $_[1] . q{ } . $_[2]
            );
        }
	],
	[#Rule 138
		 'char_type', 1,
sub
#line 780 "Parser20.yp"
{
            new CORBA::IDL::CharType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 139
		 'boolean_type', 1,
sub
#line 790 "Parser20.yp"
{
            new CORBA::IDL::BooleanType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 140
		 'octet_type', 1,
sub
#line 800 "Parser20.yp"
{
            new CORBA::IDL::OctetType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 141
		 'any_type', 1,
sub
#line 810 "Parser20.yp"
{
            new CORBA::IDL::AnyType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 142
		 'struct_type', 4,
sub
#line 820 "Parser20.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[1]->Configure($_[0],
                    'list_expr'         =>  $_[3]
            ) if (defined $_[1]);
        }
	],
	[#Rule 143
		 'struct_type', 4,
sub
#line 827 "Parser20.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->Error("member expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 144
		 'struct_header', 2,
sub
#line 837 "Parser20.yp"
{
            new CORBA::IDL::StructType($_[0],
                    'idf'               =>  $_[2]
            );
        }
	],
	[#Rule 145
		 'struct_header', 4,
sub
#line 843 "Parser20.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->Error("member expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 146
		 'member_list', 1,
sub
#line 853 "Parser20.yp"
{
            [$_[1]];
        }
	],
	[#Rule 147
		 'member_list', 2,
sub
#line 857 "Parser20.yp"
{
            unshift @{$_[2]}, $_[1];
            $_[2];
        }
	],
	[#Rule 148
		 'member', 3,
sub
#line 866 "Parser20.yp"
{
            new CORBA::IDL::Members($_[0],
                    'type'              =>  $_[1],
                    'list_expr'         =>  $_[2]
            );
        }
	],
	[#Rule 149
		 'union_type', 8,
sub
#line 877 "Parser20.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[1]->Configure($_[0],
                    'type'              =>  $_[4],
                    'list_expr'         =>  $_[7]
            ) if (defined $_[1]);
        }
	],
	[#Rule 150
		 'union_type', 8,
sub
#line 885 "Parser20.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->Error("switch_body expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 151
		 'union_type', 6,
sub
#line 892 "Parser20.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->Error("'\x7b' expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 152
		 'union_type', 5,
sub
#line 899 "Parser20.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->Error("switch_type_spec expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 153
		 'union_type', 3,
sub
#line 906 "Parser20.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->Error("'(' expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 154
		 'union_header', 2,
sub
#line 916 "Parser20.yp"
{
            new CORBA::IDL::UnionType($_[0],
                    'idf'               =>  $_[2],
            );
        }
	],
	[#Rule 155
		 'union_header', 2,
sub
#line 922 "Parser20.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 156
		 'switch_type_spec', 1, undef
	],
	[#Rule 157
		 'switch_type_spec', 1, undef
	],
	[#Rule 158
		 'switch_type_spec', 1, undef
	],
	[#Rule 159
		 'switch_type_spec', 1, undef
	],
	[#Rule 160
		 'switch_type_spec', 1,
sub
#line 939 "Parser20.yp"
{
            CORBA::IDL::TypeDeclarator->Lookup($_[0], $_[1]);
        }
	],
	[#Rule 161
		 'switch_body', 1,
sub
#line 947 "Parser20.yp"
{
            [$_[1]];
        }
	],
	[#Rule 162
		 'switch_body', 2,
sub
#line 951 "Parser20.yp"
{
            unshift @{$_[2]}, $_[1];
            $_[2];
        }
	],
	[#Rule 163
		 'case', 3,
sub
#line 960 "Parser20.yp"
{
            new CORBA::IDL::Case($_[0],
                    'list_label'        =>  $_[1],
                    'element'           =>  $_[2]
            );
        }
	],
	[#Rule 164
		 'case_labels', 1,
sub
#line 970 "Parser20.yp"
{
            [$_[1]];
        }
	],
	[#Rule 165
		 'case_labels', 2,
sub
#line 974 "Parser20.yp"
{
            unshift @{$_[2]}, $_[1];
            $_[2];
        }
	],
	[#Rule 166
		 'case_label', 3,
sub
#line 983 "Parser20.yp"
{
            $_[2];                      # here only a expression, type is not known
        }
	],
	[#Rule 167
		 'case_label', 3,
sub
#line 987 "Parser20.yp"
{
            $_[0]->Error("':' expected.\n");
            $_[0]->YYErrok();
            $_[2];
        }
	],
	[#Rule 168
		 'case_label', 2,
sub
#line 993 "Parser20.yp"
{
            $_[0]->Error("Expression expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 169
		 'case_label', 2,
sub
#line 998 "Parser20.yp"
{
            new CORBA::IDL::Default($_[0]);
        }
	],
	[#Rule 170
		 'case_label', 2,
sub
#line 1002 "Parser20.yp"
{
            $_[0]->Error("':' expected.\n");
            $_[0]->YYErrok();
            new CORBA::IDL::Default($_[0]);
        }
	],
	[#Rule 171
		 'element_spec', 2,
sub
#line 1012 "Parser20.yp"
{
            new CORBA::IDL::Element($_[0],
                    'type'          =>  $_[1],
                    'list_expr'     =>  $_[2]
            );
        }
	],
	[#Rule 172
		 'enum_type', 4,
sub
#line 1023 "Parser20.yp"
{
            $_[1]->Configure($_[0],
                    'list_expr'     =>  $_[3]
            ) if (defined $_[1]);
        }
	],
	[#Rule 173
		 'enum_type', 4,
sub
#line 1029 "Parser20.yp"
{
            $_[0]->Error("enumerator expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 174
		 'enum_type', 2,
sub
#line 1035 "Parser20.yp"
{
            $_[0]->Error("'\x7b' expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 175
		 'enum_header', 2,
sub
#line 1044 "Parser20.yp"
{
            new CORBA::IDL::EnumType($_[0],
                    'idf'               =>  $_[2],
            );
        }
	],
	[#Rule 176
		 'enum_header', 2,
sub
#line 1050 "Parser20.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 177
		 'enumerators', 1,
sub
#line 1058 "Parser20.yp"
{
            [$_[1]];
        }
	],
	[#Rule 178
		 'enumerators', 3,
sub
#line 1062 "Parser20.yp"
{
            unshift @{$_[3]}, $_[1];
            $_[3];
        }
	],
	[#Rule 179
		 'enumerators', 2,
sub
#line 1067 "Parser20.yp"
{
            $_[0]->Warning("',' unexpected.\n");
            [$_[1]];
        }
	],
	[#Rule 180
		 'enumerators', 2,
sub
#line 1072 "Parser20.yp"
{
            $_[0]->Error("';' unexpected.\n");
            [$_[1]];
        }
	],
	[#Rule 181
		 'enumerator', 1,
sub
#line 1081 "Parser20.yp"
{
            new CORBA::IDL::Enum($_[0],
                    'idf'               =>  $_[1]
            );
        }
	],
	[#Rule 182
		 'sequence_type', 6,
sub
#line 1091 "Parser20.yp"
{
            new CORBA::IDL::SequenceType($_[0],
                    'value'             =>  $_[1],
                    'type'              =>  $_[3],
                    'max'               =>  $_[5]
            );
        }
	],
	[#Rule 183
		 'sequence_type', 6,
sub
#line 1099 "Parser20.yp"
{
            $_[0]->Error("Expression expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 184
		 'sequence_type', 4,
sub
#line 1104 "Parser20.yp"
{
            new CORBA::IDL::SequenceType($_[0],
                    'value'             =>  $_[1],
                    'type'              =>  $_[3]
            );
        }
	],
	[#Rule 185
		 'sequence_type', 4,
sub
#line 1111 "Parser20.yp"
{
            $_[0]->Error("simple_type_spec expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 186
		 'sequence_type', 2,
sub
#line 1116 "Parser20.yp"
{
            $_[0]->Error("'<' expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 187
		 'string_type', 4,
sub
#line 1125 "Parser20.yp"
{
            new CORBA::IDL::StringType($_[0],
                    'value'             =>  $_[1],
                    'max'               =>  $_[3]
            );
        }
	],
	[#Rule 188
		 'string_type', 1,
sub
#line 1132 "Parser20.yp"
{
            new CORBA::IDL::StringType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 189
		 'string_type', 4,
sub
#line 1138 "Parser20.yp"
{
            $_[0]->Error("Expression expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 190
		 'array_declarator', 2,
sub
#line 1147 "Parser20.yp"
{
            unshift @{$_[2]}, $_[1];
            $_[2];
        }
	],
	[#Rule 191
		 'fixed_array_sizes', 1,
sub
#line 1155 "Parser20.yp"
{
            [$_[1]];
        }
	],
	[#Rule 192
		 'fixed_array_sizes', 2,
sub
#line 1159 "Parser20.yp"
{
            unshift @{$_[2]}, $_[1];
            $_[2];
        }
	],
	[#Rule 193
		 'fixed_array_size', 3,
sub
#line 1168 "Parser20.yp"
{
            $_[2];
        }
	],
	[#Rule 194
		 'fixed_array_size', 3,
sub
#line 1172 "Parser20.yp"
{
            $_[0]->Error("Expression expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 195
		 'attr_dcl', 4,
sub
#line 1181 "Parser20.yp"
{
            new CORBA::IDL::Attributes($_[0],
                    'modifier'          =>  $_[1],
                    'type'              =>  $_[3],
                    'list_expr'         =>  $_[4]
            );
        }
	],
	[#Rule 196
		 'attr_dcl', 3,
sub
#line 1189 "Parser20.yp"
{
            $_[0]->Error("type expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 197
		 'attr_mod', 1, undef
	],
	[#Rule 198
		 'attr_mod', 0, undef
	],
	[#Rule 199
		 'simple_declarators', 1,
sub
#line 1204 "Parser20.yp"
{
            [$_[1]];
        }
	],
	[#Rule 200
		 'simple_declarators', 3,
sub
#line 1208 "Parser20.yp"
{
            unshift @{$_[3]}, $_[1];
            $_[3];
        }
	],
	[#Rule 201
		 'except_dcl', 3,
sub
#line 1217 "Parser20.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[1];
        }
	],
	[#Rule 202
		 'except_dcl', 4,
sub
#line 1222 "Parser20.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[1]->Configure($_[0],
                    'list_expr'         =>  $_[3]
            ) if (defined $_[1]);
        }
	],
	[#Rule 203
		 'except_dcl', 4,
sub
#line 1229 "Parser20.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->Error("'members expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 204
		 'except_dcl', 2,
sub
#line 1236 "Parser20.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->Error("'\x7b' expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 205
		 'exception_header', 2,
sub
#line 1246 "Parser20.yp"
{
            new CORBA::IDL::Exception($_[0],
                    'idf'               =>  $_[2],
            );
        }
	],
	[#Rule 206
		 'exception_header', 2,
sub
#line 1252 "Parser20.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 207
		 'op_dcl', 4,
sub
#line 1261 "Parser20.yp"
{
            delete $_[0]->YYData->{unnamed_symbtab}
                    if (exists $_[0]->YYData->{unnamed_symbtab});
            $_[1]->Configure($_[0],
                    'list_param'    =>  $_[2],
                    'list_raise'    =>  $_[3],
                    'list_context'  =>  $_[4]
            ) if (defined $_[1]);
        }
	],
	[#Rule 208
		 'op_dcl', 2,
sub
#line 1271 "Parser20.yp"
{
            delete $_[0]->YYData->{unnamed_symbtab}
                    if (exists $_[0]->YYData->{unnamed_symbtab});
            $_[0]->Error("parameters declaration expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 209
		 'op_header', 3,
sub
#line 1282 "Parser20.yp"
{
            new CORBA::IDL::Operation($_[0],
                    'modifier'          =>  $_[1],
                    'type'              =>  $_[2],
                    'idf'               =>  $_[3]
            );
        }
	],
	[#Rule 210
		 'op_header', 3,
sub
#line 1290 "Parser20.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 211
		 'op_mod', 1, undef
	],
	[#Rule 212
		 'op_mod', 0, undef
	],
	[#Rule 213
		 'op_attribute', 1, undef
	],
	[#Rule 214
		 'op_type_spec', 1, undef
	],
	[#Rule 215
		 'op_type_spec', 1,
sub
#line 1314 "Parser20.yp"
{
            new CORBA::IDL::VoidType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 216
		 'op_type_spec', 1,
sub
#line 1320 "Parser20.yp"
{
            $_[0]->Error("op_type_spec expected.\n");
            $_[1];                      #default action
        }
	],
	[#Rule 217
		 'parameter_dcls', 3,
sub
#line 1329 "Parser20.yp"
{
            $_[2];
        }
	],
	[#Rule 218
		 'parameter_dcls', 5,
sub
#line 1333 "Parser20.yp"
{
            $_[0]->Error("'...' unexpected.\n");
            $_[2];
        }
	],
	[#Rule 219
		 'parameter_dcls', 4,
sub
#line 1338 "Parser20.yp"
{
            $_[0]->Warning("',' unexpected.\n");
            $_[2];
        }
	],
	[#Rule 220
		 'parameter_dcls', 2,
sub
#line 1343 "Parser20.yp"
{
            undef;
        }
	],
	[#Rule 221
		 'parameter_dcls', 3,
sub
#line 1347 "Parser20.yp"
{
            $_[0]->Error("'...' unexpected.\n");
            undef;
        }
	],
	[#Rule 222
		 'parameter_dcls', 3,
sub
#line 1352 "Parser20.yp"
{
            $_[0]->Error("parameters declaration expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 223
		 'param_dcls', 1,
sub
#line 1360 "Parser20.yp"
{
            [$_[1]];
        }
	],
	[#Rule 224
		 'param_dcls', 3,
sub
#line 1364 "Parser20.yp"
{
            push @{$_[1]}, $_[3];
            $_[1];
        }
	],
	[#Rule 225
		 'param_dcls', 2,
sub
#line 1369 "Parser20.yp"
{
            $_[0]->Error("';' unexpected.\n");
            [$_[1]];
        }
	],
	[#Rule 226
		 'param_dcl', 3,
sub
#line 1378 "Parser20.yp"
{
            new CORBA::IDL::Parameter($_[0],
                    'attr'              =>  $_[1],
                    'type'              =>  $_[2],
                    'idf'               =>  $_[3]
            );
        }
	],
	[#Rule 227
		 'param_attribute', 1, undef
	],
	[#Rule 228
		 'param_attribute', 1, undef
	],
	[#Rule 229
		 'param_attribute', 1, undef
	],
	[#Rule 230
		 'param_attribute', 0,
sub
#line 1396 "Parser20.yp"
{
            $_[0]->Error("(in|out|inout) expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 231
		 'raises_expr', 4,
sub
#line 1405 "Parser20.yp"
{
            $_[3];
        }
	],
	[#Rule 232
		 'raises_expr', 4,
sub
#line 1409 "Parser20.yp"
{
            $_[0]->Error("name expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 233
		 'raises_expr', 2,
sub
#line 1414 "Parser20.yp"
{
            $_[0]->Error("'(' expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 234
		 'raises_expr', 0, undef
	],
	[#Rule 235
		 'exception_names', 1,
sub
#line 1424 "Parser20.yp"
{
            [$_[1]];
        }
	],
	[#Rule 236
		 'exception_names', 3,
sub
#line 1428 "Parser20.yp"
{
            unshift @{$_[3]}, $_[1];
            $_[3];
        }
	],
	[#Rule 237
		 'exception_name', 1,
sub
#line 1436 "Parser20.yp"
{
            CORBA::IDL::Exception->Lookup($_[0], $_[1]);
        }
	],
	[#Rule 238
		 'context_expr', 4,
sub
#line 1444 "Parser20.yp"
{
            $_[3];
        }
	],
	[#Rule 239
		 'context_expr', 4,
sub
#line 1448 "Parser20.yp"
{
            $_[0]->Error("string expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 240
		 'context_expr', 2,
sub
#line 1453 "Parser20.yp"
{
            $_[0]->Error("'(' expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 241
		 'context_expr', 0, undef
	],
	[#Rule 242
		 'string_literals', 1,
sub
#line 1463 "Parser20.yp"
{
            [$_[1]];
        }
	],
	[#Rule 243
		 'string_literals', 3,
sub
#line 1467 "Parser20.yp"
{
            unshift @{$_[3]}, $_[1];
            $_[3];
        }
	],
	[#Rule 244
		 'param_type_spec', 1, undef
	],
	[#Rule 245
		 'param_type_spec', 1,
sub
#line 1478 "Parser20.yp"
{
            $_[0]->Error("param_type_spec expected.\n");
            $_[1];                      #default action
        }
	],
	[#Rule 246
		 'param_type_spec', 1,
sub
#line 1483 "Parser20.yp"
{
            $_[0]->Error("param_type_spec expected.\n");
            $_[1];                      #default action
        }
	],
	[#Rule 247
		 'param_type_spec', 1,
sub
#line 1488 "Parser20.yp"
{
            $_[0]->Error("param_type_spec expected.\n");
            $_[1];                      #default action
        }
	],
	[#Rule 248
		 'op_param_type_spec', 1, undef
	],
	[#Rule 249
		 'op_param_type_spec', 1, undef
	],
	[#Rule 250
		 'op_param_type_spec', 1,
sub
#line 1500 "Parser20.yp"
{
            CORBA::IDL::TypeDeclarator->Lookup($_[0], $_[1]);
        }
	]
],
                                  @_);
    bless($self,$class);
}

#line 1505 "Parser20.yp"


use warnings;

our $VERSION = '2.61';
our $IDL_VERSION = '2.0';

sub BuildUnop
{
    my ($op, $expr) = @_;

    my $node = new CORBA::IDL::UnaryOp($_[0],
            'op'    =>  $op
    );
    push @$expr, $node;
    return $expr;
}

sub BuildBinop
{
    my ($left, $op, $right) = @_;

    my $node = new CORBA::IDL::BinaryOp($_[0],
            'op'    =>  $op
    );
    push @$left, @$right;
    push @$left, $node;
    return $left;
}


1;
