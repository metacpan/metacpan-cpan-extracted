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
			'IDENTIFIER' => 23,
			'INTERFACE' => 3,
			'ENUM' => 2,
			'MODULE' => 24,
			'CONST' => 26,
			'STRUCT' => 25,
			'UNION' => 10,
			'NATIVE' => 13,
			'TYPEDEF' => 15,
			'EXCEPTION' => 16,
			'error' => 17
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
			'struct_header' => 14,
			'interface' => 18,
			'type_dcl' => 19,
			'module' => 21,
			'interface_header' => 20,
			'enum_type' => 22,
			'forward_dcl' => 28,
			'exception_header' => 27,
			'const_dcl' => 29,
			'interface_dcl' => 30
		}
	},
	{#State 1
		DEFAULT => -105
	},
	{#State 2
		ACTIONS => {
			'IDENTIFIER' => 32,
			'error' => 31
		}
	},
	{#State 3
		ACTIONS => {
			'IDENTIFIER' => 34,
			'error' => 33
		}
	},
	{#State 4
		ACTIONS => {
			"{" => 36,
			'error' => 35
		}
	},
	{#State 5
		DEFAULT => -1
	},
	{#State 6
		DEFAULT => -104
	},
	{#State 7
		ACTIONS => {
			"{" => 38,
			'error' => 37
		}
	},
	{#State 8
		ACTIONS => {
			'IDENTIFIER' => 23,
			'INTERFACE' => 3,
			'ENUM' => 2,
			'MODULE' => 24,
			'CONST' => 26,
			'STRUCT' => 25,
			'UNION' => 10,
			'NATIVE' => 13,
			'TYPEDEF' => 15,
			'EXCEPTION' => 16
		},
		DEFAULT => -4,
		GOTOS => {
			'union_type' => 1,
			'enum_header' => 4,
			'definitions' => 39,
			'definition' => 8,
			'module_header' => 7,
			'struct_type' => 6,
			'union_header' => 9,
			'except_dcl' => 12,
			'struct_header' => 14,
			'interface' => 18,
			'type_dcl' => 19,
			'module' => 21,
			'interface_header' => 20,
			'enum_type' => 22,
			'exception_header' => 27,
			'forward_dcl' => 28,
			'const_dcl' => 29,
			'interface_dcl' => 30
		}
	},
	{#State 9
		ACTIONS => {
			'SWITCH' => 40
		}
	},
	{#State 10
		ACTIONS => {
			'IDENTIFIER' => 42,
			'error' => 41
		}
	},
	{#State 11
		ACTIONS => {
			'' => 43
		}
	},
	{#State 12
		ACTIONS => {
			";" => 44,
			'error' => 45
		},
		GOTOS => {
			'check_semicolon' => 46
		}
	},
	{#State 13
		ACTIONS => {
			'IDENTIFIER' => 49,
			'error' => 48
		},
		GOTOS => {
			'simple_declarator' => 47
		}
	},
	{#State 14
		ACTIONS => {
			"{" => 50
		}
	},
	{#State 15
		ACTIONS => {
			"::" => 76,
			'ENUM' => 2,
			'CHAR' => 77,
			'OBJECT' => 81,
			'STRING' => 84,
			'OCTET' => 53,
			'WSTRING' => 86,
			'UNION' => 10,
			'UNSIGNED' => 55,
			'error' => 88,
			'ANY' => 56,
			'FLOAT' => 90,
			'LONG' => 58,
			'SEQUENCE' => 91,
			'IDENTIFIER' => 63,
			'DOUBLE' => 92,
			'SHORT' => 93,
			'BOOLEAN' => 95,
			'STRUCT' => 25,
			'VOID' => 68,
			'FIXED' => 98,
			'WCHAR' => 73
		},
		GOTOS => {
			'union_type' => 51,
			'enum_header' => 4,
			'unsigned_short_int' => 52,
			'struct_type' => 54,
			'union_header' => 9,
			'struct_header' => 14,
			'type_declarator' => 57,
			'signed_longlong_int' => 59,
			'enum_type' => 60,
			'any_type' => 61,
			'template_type_spec' => 62,
			'unsigned_long_int' => 64,
			'scoped_name' => 65,
			'string_type' => 66,
			'char_type' => 67,
			'fixed_pt_type' => 71,
			'signed_short_int' => 70,
			'signed_long_int' => 69,
			'wide_char_type' => 72,
			'octet_type' => 74,
			'wide_string_type' => 75,
			'object_type' => 78,
			'type_spec' => 79,
			'integer_type' => 80,
			'sequence_type' => 82,
			'unsigned_int' => 83,
			'unsigned_longlong_int' => 85,
			'constr_type_spec' => 87,
			'floating_pt_type' => 89,
			'base_type_spec' => 94,
			'signed_int' => 96,
			'simple_type_spec' => 97,
			'boolean_type' => 99
		}
	},
	{#State 16
		ACTIONS => {
			'IDENTIFIER' => 100,
			'error' => 101
		}
	},
	{#State 17
		DEFAULT => -3
	},
	{#State 18
		ACTIONS => {
			";" => 44,
			'error' => 45
		},
		GOTOS => {
			'check_semicolon' => 102
		}
	},
	{#State 19
		ACTIONS => {
			";" => 44,
			'error' => 45
		},
		GOTOS => {
			'check_semicolon' => 103
		}
	},
	{#State 20
		ACTIONS => {
			"{" => 104
		}
	},
	{#State 21
		ACTIONS => {
			";" => 44,
			'error' => 45
		},
		GOTOS => {
			'check_semicolon' => 105
		}
	},
	{#State 22
		DEFAULT => -106
	},
	{#State 23
		ACTIONS => {
			'error' => 106
		}
	},
	{#State 24
		ACTIONS => {
			'IDENTIFIER' => 107,
			'error' => 108
		}
	},
	{#State 25
		ACTIONS => {
			'IDENTIFIER' => 109,
			'error' => 110
		}
	},
	{#State 26
		ACTIONS => {
			'DOUBLE' => 92,
			"::" => 76,
			'IDENTIFIER' => 63,
			'SHORT' => 93,
			'CHAR' => 77,
			'BOOLEAN' => 95,
			'STRING' => 84,
			'WSTRING' => 86,
			'UNSIGNED' => 55,
			'FIXED' => 121,
			'error' => 118,
			'FLOAT' => 90,
			'LONG' => 58,
			'WCHAR' => 73
		},
		GOTOS => {
			'wide_string_type' => 115,
			'integer_type' => 116,
			'unsigned_int' => 83,
			'unsigned_short_int' => 52,
			'unsigned_longlong_int' => 85,
			'floating_pt_type' => 117,
			'const_type' => 119,
			'signed_longlong_int' => 59,
			'unsigned_long_int' => 64,
			'scoped_name' => 111,
			'string_type' => 112,
			'signed_int' => 96,
			'fixed_pt_const_type' => 120,
			'char_type' => 113,
			'signed_short_int' => 70,
			'signed_long_int' => 69,
			'boolean_type' => 122,
			'wide_char_type' => 114
		}
	},
	{#State 27
		ACTIONS => {
			"{" => 124,
			'error' => 123
		}
	},
	{#State 28
		DEFAULT => -21
	},
	{#State 29
		ACTIONS => {
			";" => 44,
			'error' => 45
		},
		GOTOS => {
			'check_semicolon' => 125
		}
	},
	{#State 30
		DEFAULT => -20
	},
	{#State 31
		DEFAULT => -196
	},
	{#State 32
		DEFAULT => -195
	},
	{#State 33
		ACTIONS => {
			"{" => -28
		},
		DEFAULT => -26
	},
	{#State 34
		ACTIONS => {
			":" => 126,
			"{" => -39
		},
		DEFAULT => -25,
		GOTOS => {
			'interface_inheritance_spec' => 127
		}
	},
	{#State 35
		DEFAULT => -194
	},
	{#State 36
		ACTIONS => {
			'IDENTIFIER' => 128,
			'error' => 130
		},
		GOTOS => {
			'enumerators' => 131,
			'enumerator' => 129
		}
	},
	{#State 37
		ACTIONS => {
			"}" => 132
		}
	},
	{#State 38
		ACTIONS => {
			"}" => 133,
			'INTERFACE' => 3,
			'ENUM' => 2,
			'IDENTIFIER' => 23,
			'MODULE' => 24,
			'CONST' => 26,
			'STRUCT' => 25,
			'UNION' => 10,
			'NATIVE' => 13,
			'TYPEDEF' => 15,
			'error' => 135,
			'EXCEPTION' => 16
		},
		GOTOS => {
			'union_type' => 1,
			'enum_header' => 4,
			'definitions' => 134,
			'definition' => 8,
			'module_header' => 7,
			'struct_type' => 6,
			'union_header' => 9,
			'except_dcl' => 12,
			'struct_header' => 14,
			'interface' => 18,
			'type_dcl' => 19,
			'module' => 21,
			'interface_header' => 20,
			'enum_type' => 22,
			'forward_dcl' => 28,
			'exception_header' => 27,
			'const_dcl' => 29,
			'interface_dcl' => 30
		}
	},
	{#State 39
		DEFAULT => -5
	},
	{#State 40
		ACTIONS => {
			"(" => 136,
			'error' => 137
		}
	},
	{#State 41
		DEFAULT => -175
	},
	{#State 42
		DEFAULT => -174
	},
	{#State 43
		DEFAULT => 0
	},
	{#State 44
		DEFAULT => -12
	},
	{#State 45
		DEFAULT => -13
	},
	{#State 46
		DEFAULT => -8
	},
	{#State 47
		DEFAULT => -107
	},
	{#State 48
		ACTIONS => {
			";" => 138,
			"," => 139
		}
	},
	{#State 49
		DEFAULT => -135
	},
	{#State 50
		ACTIONS => {
			"::" => 76,
			'ENUM' => 2,
			'CHAR' => 77,
			'OBJECT' => 81,
			'STRING' => 84,
			'OCTET' => 53,
			'WSTRING' => 86,
			'UNION' => 10,
			'UNSIGNED' => 55,
			'error' => 143,
			'ANY' => 56,
			'FLOAT' => 90,
			'LONG' => 58,
			'SEQUENCE' => 91,
			'IDENTIFIER' => 63,
			'DOUBLE' => 92,
			'SHORT' => 93,
			'BOOLEAN' => 95,
			'STRUCT' => 25,
			'VOID' => 68,
			'FIXED' => 98,
			'WCHAR' => 73
		},
		GOTOS => {
			'union_type' => 51,
			'enum_header' => 4,
			'unsigned_short_int' => 52,
			'struct_type' => 54,
			'union_header' => 9,
			'struct_header' => 14,
			'member_list' => 140,
			'signed_longlong_int' => 59,
			'enum_type' => 60,
			'any_type' => 61,
			'template_type_spec' => 62,
			'member' => 141,
			'unsigned_long_int' => 64,
			'scoped_name' => 65,
			'string_type' => 66,
			'char_type' => 67,
			'fixed_pt_type' => 71,
			'signed_short_int' => 70,
			'signed_long_int' => 69,
			'wide_char_type' => 72,
			'octet_type' => 74,
			'wide_string_type' => 75,
			'object_type' => 78,
			'type_spec' => 142,
			'integer_type' => 80,
			'unsigned_int' => 83,
			'sequence_type' => 82,
			'unsigned_longlong_int' => 85,
			'constr_type_spec' => 87,
			'floating_pt_type' => 89,
			'base_type_spec' => 94,
			'signed_int' => 96,
			'simple_type_spec' => 97,
			'boolean_type' => 99
		}
	},
	{#State 51
		DEFAULT => -129
	},
	{#State 52
		DEFAULT => -150
	},
	{#State 53
		DEFAULT => -159
	},
	{#State 54
		DEFAULT => -128
	},
	{#State 55
		ACTIONS => {
			'SHORT' => 145,
			'LONG' => 144
		}
	},
	{#State 56
		DEFAULT => -160
	},
	{#State 57
		DEFAULT => -103
	},
	{#State 58
		ACTIONS => {
			'DOUBLE' => 147,
			'LONG' => 146
		},
		DEFAULT => -148
	},
	{#State 59
		DEFAULT => -146
	},
	{#State 60
		DEFAULT => -130
	},
	{#State 61
		DEFAULT => -122
	},
	{#State 62
		DEFAULT => -113
	},
	{#State 63
		DEFAULT => -43
	},
	{#State 64
		DEFAULT => -151
	},
	{#State 65
		ACTIONS => {
			"::" => 148
		},
		DEFAULT => -114
	},
	{#State 66
		DEFAULT => -125
	},
	{#State 67
		DEFAULT => -118
	},
	{#State 68
		DEFAULT => -115
	},
	{#State 69
		DEFAULT => -145
	},
	{#State 70
		DEFAULT => -144
	},
	{#State 71
		DEFAULT => -127
	},
	{#State 72
		DEFAULT => -119
	},
	{#State 73
		DEFAULT => -157
	},
	{#State 74
		DEFAULT => -121
	},
	{#State 75
		DEFAULT => -126
	},
	{#State 76
		ACTIONS => {
			'IDENTIFIER' => 149,
			'error' => 150
		}
	},
	{#State 77
		DEFAULT => -156
	},
	{#State 78
		DEFAULT => -123
	},
	{#State 79
		ACTIONS => {
			'IDENTIFIER' => 152,
			'error' => 48
		},
		GOTOS => {
			'declarators' => 154,
			'array_declarator' => 155,
			'simple_declarator' => 151,
			'declarator' => 153,
			'complex_declarator' => 156
		}
	},
	{#State 80
		DEFAULT => -117
	},
	{#State 81
		DEFAULT => -161
	},
	{#State 82
		DEFAULT => -124
	},
	{#State 83
		DEFAULT => -143
	},
	{#State 84
		ACTIONS => {
			"<" => 157
		},
		DEFAULT => -208
	},
	{#State 85
		DEFAULT => -152
	},
	{#State 86
		ACTIONS => {
			"<" => 158
		},
		DEFAULT => -211
	},
	{#State 87
		DEFAULT => -111
	},
	{#State 88
		DEFAULT => -108
	},
	{#State 89
		DEFAULT => -116
	},
	{#State 90
		DEFAULT => -139
	},
	{#State 91
		ACTIONS => {
			"<" => 159,
			'error' => 160
		}
	},
	{#State 92
		DEFAULT => -140
	},
	{#State 93
		DEFAULT => -147
	},
	{#State 94
		DEFAULT => -112
	},
	{#State 95
		DEFAULT => -158
	},
	{#State 96
		DEFAULT => -142
	},
	{#State 97
		DEFAULT => -110
	},
	{#State 98
		ACTIONS => {
			"<" => 161,
			'error' => 162
		}
	},
	{#State 99
		DEFAULT => -120
	},
	{#State 100
		DEFAULT => -228
	},
	{#State 101
		DEFAULT => -229
	},
	{#State 102
		DEFAULT => -9
	},
	{#State 103
		DEFAULT => -6
	},
	{#State 104
		ACTIONS => {
			"}" => 163,
			"::" => -235,
			'ENUM' => 2,
			'CHAR' => -235,
			'OBJECT' => -235,
			'STRING' => -235,
			'OCTET' => -235,
			'ONEWAY' => 174,
			'WSTRING' => -235,
			'UNION' => 10,
			'NATIVE' => 13,
			'UNSIGNED' => -235,
			'TYPEDEF' => 15,
			'error' => 177,
			'EXCEPTION' => 16,
			'ANY' => -235,
			'FLOAT' => -235,
			'LONG' => -235,
			'ATTRIBUTE' => -221,
			'SEQUENCE' => -235,
			'IDENTIFIER' => -235,
			'DOUBLE' => -235,
			'SHORT' => -235,
			'BOOLEAN' => -235,
			'STRUCT' => 25,
			'CONST' => 26,
			'READONLY' => 178,
			'VOID' => -235,
			'FIXED' => -235,
			'WCHAR' => -235
		},
		GOTOS => {
			'op_header' => 171,
			'union_type' => 1,
			'interface_body' => 172,
			'attr_mod' => 164,
			'enum_header' => 4,
			'op_dcl' => 173,
			'exports' => 176,
			'attr_dcl' => 175,
			'struct_type' => 6,
			'union_header' => 9,
			'except_dcl' => 165,
			'struct_header' => 14,
			'export' => 167,
			'type_dcl' => 166,
			'enum_type' => 22,
			'op_attribute' => 168,
			'op_mod' => 169,
			'exception_header' => 27,
			'const_dcl' => 170
		}
	},
	{#State 105
		DEFAULT => -10
	},
	{#State 106
		ACTIONS => {
			";" => 179
		}
	},
	{#State 107
		DEFAULT => -18
	},
	{#State 108
		DEFAULT => -19
	},
	{#State 109
		DEFAULT => -164
	},
	{#State 110
		DEFAULT => -165
	},
	{#State 111
		ACTIONS => {
			"::" => 148
		},
		DEFAULT => -61
	},
	{#State 112
		DEFAULT => -58
	},
	{#State 113
		DEFAULT => -54
	},
	{#State 114
		DEFAULT => -55
	},
	{#State 115
		DEFAULT => -59
	},
	{#State 116
		DEFAULT => -53
	},
	{#State 117
		DEFAULT => -57
	},
	{#State 118
		DEFAULT => -52
	},
	{#State 119
		ACTIONS => {
			'IDENTIFIER' => 180,
			'error' => 181
		}
	},
	{#State 120
		DEFAULT => -60
	},
	{#State 121
		DEFAULT => -280
	},
	{#State 122
		DEFAULT => -56
	},
	{#State 123
		DEFAULT => -227
	},
	{#State 124
		ACTIONS => {
			"}" => 182,
			"::" => 76,
			'ENUM' => 2,
			'CHAR' => 77,
			'OBJECT' => 81,
			'STRING' => 84,
			'OCTET' => 53,
			'WSTRING' => 86,
			'UNION' => 10,
			'UNSIGNED' => 55,
			'error' => 184,
			'ANY' => 56,
			'FLOAT' => 90,
			'LONG' => 58,
			'SEQUENCE' => 91,
			'DOUBLE' => 92,
			'IDENTIFIER' => 63,
			'SHORT' => 93,
			'BOOLEAN' => 95,
			'STRUCT' => 25,
			'VOID' => 68,
			'FIXED' => 98,
			'WCHAR' => 73
		},
		GOTOS => {
			'union_type' => 51,
			'enum_header' => 4,
			'unsigned_short_int' => 52,
			'struct_type' => 54,
			'union_header' => 9,
			'struct_header' => 14,
			'member_list' => 183,
			'signed_longlong_int' => 59,
			'enum_type' => 60,
			'any_type' => 61,
			'template_type_spec' => 62,
			'member' => 141,
			'unsigned_long_int' => 64,
			'scoped_name' => 65,
			'string_type' => 66,
			'char_type' => 67,
			'fixed_pt_type' => 71,
			'signed_short_int' => 70,
			'signed_long_int' => 69,
			'wide_char_type' => 72,
			'octet_type' => 74,
			'wide_string_type' => 75,
			'object_type' => 78,
			'type_spec' => 142,
			'integer_type' => 80,
			'unsigned_int' => 83,
			'sequence_type' => 82,
			'unsigned_longlong_int' => 85,
			'constr_type_spec' => 87,
			'floating_pt_type' => 89,
			'base_type_spec' => 94,
			'signed_int' => 96,
			'simple_type_spec' => 97,
			'boolean_type' => 99
		}
	},
	{#State 125
		DEFAULT => -7
	},
	{#State 126
		ACTIONS => {
			"::" => 76,
			'IDENTIFIER' => 63,
			'error' => 186
		},
		GOTOS => {
			'interface_name' => 188,
			'interface_names' => 187,
			'scoped_name' => 185
		}
	},
	{#State 127
		DEFAULT => -27
	},
	{#State 128
		DEFAULT => -201
	},
	{#State 129
		ACTIONS => {
			";" => 189,
			"," => 190
		},
		DEFAULT => -197
	},
	{#State 130
		ACTIONS => {
			"}" => 191
		}
	},
	{#State 131
		ACTIONS => {
			"}" => 192
		}
	},
	{#State 132
		DEFAULT => -17
	},
	{#State 133
		DEFAULT => -16
	},
	{#State 134
		ACTIONS => {
			"}" => 193
		}
	},
	{#State 135
		ACTIONS => {
			"}" => 194
		}
	},
	{#State 136
		ACTIONS => {
			"::" => 76,
			'ENUM' => 2,
			'IDENTIFIER' => 63,
			'SHORT' => 93,
			'CHAR' => 77,
			'BOOLEAN' => 95,
			'UNSIGNED' => 55,
			'error' => 200,
			'LONG' => 195
		},
		GOTOS => {
			'signed_longlong_int' => 59,
			'enum_type' => 196,
			'integer_type' => 199,
			'unsigned_long_int' => 64,
			'unsigned_int' => 83,
			'scoped_name' => 197,
			'enum_header' => 4,
			'signed_int' => 96,
			'unsigned_short_int' => 52,
			'unsigned_longlong_int' => 85,
			'char_type' => 198,
			'signed_long_int' => 69,
			'signed_short_int' => 70,
			'boolean_type' => 202,
			'switch_type_spec' => 201
		}
	},
	{#State 137
		DEFAULT => -173
	},
	{#State 138
		DEFAULT => -137
	},
	{#State 139
		DEFAULT => -136
	},
	{#State 140
		ACTIONS => {
			"}" => 203
		}
	},
	{#State 141
		ACTIONS => {
			"::" => 76,
			'ENUM' => 2,
			'CHAR' => 77,
			'OBJECT' => 81,
			'STRING' => 84,
			'OCTET' => 53,
			'WSTRING' => 86,
			'UNION' => 10,
			'UNSIGNED' => 55,
			'ANY' => 56,
			'FLOAT' => 90,
			'LONG' => 58,
			'SEQUENCE' => 91,
			'DOUBLE' => 92,
			'IDENTIFIER' => 63,
			'SHORT' => 93,
			'BOOLEAN' => 95,
			'STRUCT' => 25,
			'VOID' => 68,
			'FIXED' => 98,
			'WCHAR' => 73
		},
		DEFAULT => -166,
		GOTOS => {
			'union_type' => 51,
			'enum_header' => 4,
			'unsigned_short_int' => 52,
			'struct_type' => 54,
			'union_header' => 9,
			'struct_header' => 14,
			'member_list' => 204,
			'signed_longlong_int' => 59,
			'enum_type' => 60,
			'any_type' => 61,
			'template_type_spec' => 62,
			'member' => 141,
			'unsigned_long_int' => 64,
			'scoped_name' => 65,
			'string_type' => 66,
			'char_type' => 67,
			'fixed_pt_type' => 71,
			'signed_short_int' => 70,
			'signed_long_int' => 69,
			'wide_char_type' => 72,
			'octet_type' => 74,
			'wide_string_type' => 75,
			'object_type' => 78,
			'type_spec' => 142,
			'integer_type' => 80,
			'unsigned_int' => 83,
			'sequence_type' => 82,
			'unsigned_longlong_int' => 85,
			'constr_type_spec' => 87,
			'floating_pt_type' => 89,
			'base_type_spec' => 94,
			'signed_int' => 96,
			'simple_type_spec' => 97,
			'boolean_type' => 99
		}
	},
	{#State 142
		ACTIONS => {
			'IDENTIFIER' => 152,
			'error' => 48
		},
		GOTOS => {
			'declarators' => 205,
			'array_declarator' => 155,
			'simple_declarator' => 151,
			'declarator' => 153,
			'complex_declarator' => 156
		}
	},
	{#State 143
		ACTIONS => {
			"}" => 206
		}
	},
	{#State 144
		ACTIONS => {
			'LONG' => 207
		},
		DEFAULT => -154
	},
	{#State 145
		DEFAULT => -153
	},
	{#State 146
		DEFAULT => -149
	},
	{#State 147
		DEFAULT => -141
	},
	{#State 148
		ACTIONS => {
			'IDENTIFIER' => 208,
			'error' => 209
		}
	},
	{#State 149
		DEFAULT => -44
	},
	{#State 150
		DEFAULT => -45
	},
	{#State 151
		DEFAULT => -133
	},
	{#State 152
		ACTIONS => {
			"[" => 211
		},
		DEFAULT => -135,
		GOTOS => {
			'fixed_array_sizes' => 210,
			'fixed_array_size' => 212
		}
	},
	{#State 153
		ACTIONS => {
			"," => 213
		},
		DEFAULT => -131
	},
	{#State 154
		DEFAULT => -109
	},
	{#State 155
		DEFAULT => -138
	},
	{#State 156
		DEFAULT => -134
	},
	{#State 157
		ACTIONS => {
			"-" => 214,
			"::" => 76,
			'TRUE' => 227,
			"+" => 228,
			"~" => 215,
			'INTEGER_LITERAL' => 229,
			'FLOATING_PT_LITERAL' => 231,
			'FALSE' => 217,
			'error' => 232,
			'WIDE_STRING_LITERAL' => 233,
			'CHARACTER_LITERAL' => 234,
			'IDENTIFIER' => 63,
			"(" => 224,
			'FIXED_PT_LITERAL' => 238,
			'STRING_LITERAL' => 241,
			'WIDE_CHARACTER_LITERAL' => 226
		},
		GOTOS => {
			'shift_expr' => 230,
			'literal' => 216,
			'const_exp' => 218,
			'unary_operator' => 219,
			'string_literal' => 220,
			'and_expr' => 221,
			'or_expr' => 222,
			'mult_expr' => 235,
			'scoped_name' => 223,
			'boolean_literal' => 236,
			'add_expr' => 237,
			'positive_int_const' => 239,
			'unary_expr' => 225,
			'primary_expr' => 240,
			'wide_string_literal' => 242,
			'xor_expr' => 243
		}
	},
	{#State 158
		ACTIONS => {
			"-" => 214,
			"::" => 76,
			'TRUE' => 227,
			"+" => 228,
			"~" => 215,
			'INTEGER_LITERAL' => 229,
			'FLOATING_PT_LITERAL' => 231,
			'FALSE' => 217,
			'error' => 244,
			'WIDE_STRING_LITERAL' => 233,
			'CHARACTER_LITERAL' => 234,
			'IDENTIFIER' => 63,
			"(" => 224,
			'FIXED_PT_LITERAL' => 238,
			'STRING_LITERAL' => 241,
			'WIDE_CHARACTER_LITERAL' => 226
		},
		GOTOS => {
			'shift_expr' => 230,
			'literal' => 216,
			'const_exp' => 218,
			'unary_operator' => 219,
			'string_literal' => 220,
			'and_expr' => 221,
			'or_expr' => 222,
			'mult_expr' => 235,
			'scoped_name' => 223,
			'boolean_literal' => 236,
			'add_expr' => 237,
			'positive_int_const' => 245,
			'unary_expr' => 225,
			'primary_expr' => 240,
			'wide_string_literal' => 242,
			'xor_expr' => 243
		}
	},
	{#State 159
		ACTIONS => {
			"::" => 76,
			'CHAR' => 77,
			'OBJECT' => 81,
			'STRING' => 84,
			'OCTET' => 53,
			'WSTRING' => 86,
			'UNSIGNED' => 55,
			'error' => 246,
			'ANY' => 56,
			'FLOAT' => 90,
			'LONG' => 58,
			'SEQUENCE' => 91,
			'IDENTIFIER' => 63,
			'DOUBLE' => 92,
			'SHORT' => 93,
			'BOOLEAN' => 95,
			'VOID' => 68,
			'FIXED' => 98,
			'WCHAR' => 73
		},
		GOTOS => {
			'wide_string_type' => 75,
			'object_type' => 78,
			'integer_type' => 80,
			'sequence_type' => 82,
			'unsigned_int' => 83,
			'unsigned_short_int' => 52,
			'unsigned_longlong_int' => 85,
			'floating_pt_type' => 89,
			'signed_longlong_int' => 59,
			'any_type' => 61,
			'template_type_spec' => 62,
			'base_type_spec' => 94,
			'unsigned_long_int' => 64,
			'scoped_name' => 65,
			'signed_int' => 96,
			'string_type' => 66,
			'simple_type_spec' => 247,
			'char_type' => 67,
			'signed_short_int' => 70,
			'signed_long_int' => 69,
			'fixed_pt_type' => 71,
			'boolean_type' => 99,
			'wide_char_type' => 72,
			'octet_type' => 74
		}
	},
	{#State 160
		DEFAULT => -206
	},
	{#State 161
		ACTIONS => {
			"-" => 214,
			"::" => 76,
			'TRUE' => 227,
			"+" => 228,
			"~" => 215,
			'INTEGER_LITERAL' => 229,
			'FLOATING_PT_LITERAL' => 231,
			'FALSE' => 217,
			'error' => 248,
			'WIDE_STRING_LITERAL' => 233,
			'CHARACTER_LITERAL' => 234,
			'IDENTIFIER' => 63,
			"(" => 224,
			'FIXED_PT_LITERAL' => 238,
			'STRING_LITERAL' => 241,
			'WIDE_CHARACTER_LITERAL' => 226
		},
		GOTOS => {
			'shift_expr' => 230,
			'literal' => 216,
			'const_exp' => 218,
			'unary_operator' => 219,
			'string_literal' => 220,
			'and_expr' => 221,
			'or_expr' => 222,
			'mult_expr' => 235,
			'scoped_name' => 223,
			'boolean_literal' => 236,
			'add_expr' => 237,
			'positive_int_const' => 249,
			'unary_expr' => 225,
			'primary_expr' => 240,
			'wide_string_literal' => 242,
			'xor_expr' => 243
		}
	},
	{#State 162
		DEFAULT => -279
	},
	{#State 163
		DEFAULT => -22
	},
	{#State 164
		ACTIONS => {
			'ATTRIBUTE' => 250
		}
	},
	{#State 165
		ACTIONS => {
			";" => 44,
			'error' => 45
		},
		GOTOS => {
			'check_semicolon' => 251
		}
	},
	{#State 166
		ACTIONS => {
			";" => 44,
			'error' => 45
		},
		GOTOS => {
			'check_semicolon' => 252
		}
	},
	{#State 167
		ACTIONS => {
			"}" => -30,
			'ENUM' => 2,
			'ONEWAY' => 174,
			'UNION' => 10,
			'NATIVE' => 13,
			'TYPEDEF' => 15,
			'EXCEPTION' => 16,
			'ATTRIBUTE' => -221,
			'STRUCT' => 25,
			'CONST' => 26,
			'READONLY' => 178
		},
		DEFAULT => -235,
		GOTOS => {
			'op_header' => 171,
			'union_type' => 1,
			'attr_mod' => 164,
			'enum_header' => 4,
			'op_dcl' => 173,
			'exports' => 253,
			'attr_dcl' => 175,
			'struct_type' => 6,
			'union_header' => 9,
			'except_dcl' => 165,
			'struct_header' => 14,
			'export' => 167,
			'type_dcl' => 166,
			'enum_type' => 22,
			'op_attribute' => 168,
			'op_mod' => 169,
			'exception_header' => 27,
			'const_dcl' => 170
		}
	},
	{#State 168
		DEFAULT => -234
	},
	{#State 169
		ACTIONS => {
			"::" => 76,
			'CHAR' => 77,
			'OBJECT' => 81,
			'STRING' => 84,
			'OCTET' => 53,
			'WSTRING' => 86,
			'UNSIGNED' => 55,
			'ANY' => 56,
			'FLOAT' => 90,
			'LONG' => 58,
			'SEQUENCE' => 91,
			'IDENTIFIER' => 63,
			'DOUBLE' => 92,
			'SHORT' => 93,
			'BOOLEAN' => 95,
			'VOID' => 256,
			'FIXED' => 98,
			'WCHAR' => 73
		},
		GOTOS => {
			'wide_string_type' => 258,
			'object_type' => 78,
			'integer_type' => 80,
			'unsigned_int' => 83,
			'sequence_type' => 259,
			'op_param_type_spec' => 260,
			'unsigned_short_int' => 52,
			'unsigned_longlong_int' => 85,
			'floating_pt_type' => 89,
			'signed_longlong_int' => 59,
			'any_type' => 61,
			'base_type_spec' => 261,
			'unsigned_long_int' => 64,
			'scoped_name' => 254,
			'signed_int' => 96,
			'string_type' => 255,
			'char_type' => 67,
			'signed_long_int' => 69,
			'fixed_pt_type' => 257,
			'signed_short_int' => 70,
			'op_type_spec' => 262,
			'boolean_type' => 99,
			'wide_char_type' => 72,
			'octet_type' => 74
		}
	},
	{#State 170
		ACTIONS => {
			";" => 44,
			'error' => 45
		},
		GOTOS => {
			'check_semicolon' => 263
		}
	},
	{#State 171
		ACTIONS => {
			"(" => 264,
			'error' => 265
		},
		GOTOS => {
			'parameter_dcls' => 266
		}
	},
	{#State 172
		ACTIONS => {
			"}" => 267
		}
	},
	{#State 173
		ACTIONS => {
			";" => 44,
			'error' => 45
		},
		GOTOS => {
			'check_semicolon' => 268
		}
	},
	{#State 174
		DEFAULT => -236
	},
	{#State 175
		ACTIONS => {
			";" => 44,
			'error' => 45
		},
		GOTOS => {
			'check_semicolon' => 269
		}
	},
	{#State 176
		DEFAULT => -29
	},
	{#State 177
		ACTIONS => {
			"}" => 270
		}
	},
	{#State 178
		DEFAULT => -220
	},
	{#State 179
		DEFAULT => -11
	},
	{#State 180
		ACTIONS => {
			'error' => 271,
			"=" => 272
		}
	},
	{#State 181
		DEFAULT => -51
	},
	{#State 182
		DEFAULT => -224
	},
	{#State 183
		ACTIONS => {
			"}" => 273
		}
	},
	{#State 184
		ACTIONS => {
			"}" => 274
		}
	},
	{#State 185
		ACTIONS => {
			"::" => 148
		},
		DEFAULT => -42
	},
	{#State 186
		DEFAULT => -38
	},
	{#State 187
		DEFAULT => -37
	},
	{#State 188
		ACTIONS => {
			"," => 275
		},
		DEFAULT => -40
	},
	{#State 189
		DEFAULT => -200
	},
	{#State 190
		ACTIONS => {
			'IDENTIFIER' => 128
		},
		DEFAULT => -199,
		GOTOS => {
			'enumerators' => 276,
			'enumerator' => 129
		}
	},
	{#State 191
		DEFAULT => -193
	},
	{#State 192
		DEFAULT => -192
	},
	{#State 193
		DEFAULT => -14
	},
	{#State 194
		DEFAULT => -15
	},
	{#State 195
		ACTIONS => {
			'LONG' => 146
		},
		DEFAULT => -148
	},
	{#State 196
		DEFAULT => -179
	},
	{#State 197
		ACTIONS => {
			"::" => 148
		},
		DEFAULT => -180
	},
	{#State 198
		DEFAULT => -177
	},
	{#State 199
		DEFAULT => -176
	},
	{#State 200
		ACTIONS => {
			")" => 277
		}
	},
	{#State 201
		ACTIONS => {
			")" => 278
		}
	},
	{#State 202
		DEFAULT => -178
	},
	{#State 203
		DEFAULT => -162
	},
	{#State 204
		DEFAULT => -167
	},
	{#State 205
		ACTIONS => {
			";" => 44,
			'error' => 45
		},
		GOTOS => {
			'check_semicolon' => 279
		}
	},
	{#State 206
		DEFAULT => -163
	},
	{#State 207
		DEFAULT => -155
	},
	{#State 208
		DEFAULT => -46
	},
	{#State 209
		DEFAULT => -47
	},
	{#State 210
		DEFAULT => -213
	},
	{#State 211
		ACTIONS => {
			"-" => 214,
			"::" => 76,
			'TRUE' => 227,
			"+" => 228,
			"~" => 215,
			'INTEGER_LITERAL' => 229,
			'FLOATING_PT_LITERAL' => 231,
			'FALSE' => 217,
			'error' => 280,
			'WIDE_STRING_LITERAL' => 233,
			'CHARACTER_LITERAL' => 234,
			'IDENTIFIER' => 63,
			"(" => 224,
			'FIXED_PT_LITERAL' => 238,
			'STRING_LITERAL' => 241,
			'WIDE_CHARACTER_LITERAL' => 226
		},
		GOTOS => {
			'shift_expr' => 230,
			'literal' => 216,
			'const_exp' => 218,
			'unary_operator' => 219,
			'string_literal' => 220,
			'and_expr' => 221,
			'or_expr' => 222,
			'mult_expr' => 235,
			'scoped_name' => 223,
			'boolean_literal' => 236,
			'add_expr' => 237,
			'positive_int_const' => 281,
			'unary_expr' => 225,
			'primary_expr' => 240,
			'wide_string_literal' => 242,
			'xor_expr' => 243
		}
	},
	{#State 212
		ACTIONS => {
			"[" => 211
		},
		DEFAULT => -214,
		GOTOS => {
			'fixed_array_sizes' => 282,
			'fixed_array_size' => 212
		}
	},
	{#State 213
		ACTIONS => {
			'IDENTIFIER' => 152,
			'error' => 48
		},
		GOTOS => {
			'declarators' => 283,
			'array_declarator' => 155,
			'simple_declarator' => 151,
			'declarator' => 153,
			'complex_declarator' => 156
		}
	},
	{#State 214
		DEFAULT => -81
	},
	{#State 215
		DEFAULT => -83
	},
	{#State 216
		DEFAULT => -85
	},
	{#State 217
		DEFAULT => -101
	},
	{#State 218
		DEFAULT => -102
	},
	{#State 219
		ACTIONS => {
			"::" => 76,
			'TRUE' => 227,
			'IDENTIFIER' => 63,
			'INTEGER_LITERAL' => 229,
			'FLOATING_PT_LITERAL' => 231,
			'FIXED_PT_LITERAL' => 238,
			"(" => 224,
			'FALSE' => 217,
			'STRING_LITERAL' => 241,
			'WIDE_CHARACTER_LITERAL' => 226,
			'WIDE_STRING_LITERAL' => 233,
			'CHARACTER_LITERAL' => 234
		},
		GOTOS => {
			'literal' => 216,
			'primary_expr' => 284,
			'scoped_name' => 223,
			'wide_string_literal' => 242,
			'boolean_literal' => 236,
			'string_literal' => 220
		}
	},
	{#State 220
		DEFAULT => -89
	},
	{#State 221
		ACTIONS => {
			"&" => 285
		},
		DEFAULT => -65
	},
	{#State 222
		ACTIONS => {
			"|" => 286
		},
		DEFAULT => -62
	},
	{#State 223
		ACTIONS => {
			"::" => 148
		},
		DEFAULT => -84
	},
	{#State 224
		ACTIONS => {
			"-" => 214,
			"::" => 76,
			'TRUE' => 227,
			"+" => 228,
			"~" => 215,
			'INTEGER_LITERAL' => 229,
			'FLOATING_PT_LITERAL' => 231,
			'FALSE' => 217,
			'error' => 288,
			'WIDE_STRING_LITERAL' => 233,
			'CHARACTER_LITERAL' => 234,
			'IDENTIFIER' => 63,
			"(" => 224,
			'FIXED_PT_LITERAL' => 238,
			'STRING_LITERAL' => 241,
			'WIDE_CHARACTER_LITERAL' => 226
		},
		GOTOS => {
			'and_expr' => 221,
			'or_expr' => 222,
			'mult_expr' => 235,
			'shift_expr' => 230,
			'scoped_name' => 223,
			'boolean_literal' => 236,
			'add_expr' => 237,
			'literal' => 216,
			'primary_expr' => 240,
			'unary_expr' => 225,
			'unary_operator' => 219,
			'const_exp' => 287,
			'xor_expr' => 243,
			'wide_string_literal' => 242,
			'string_literal' => 220
		}
	},
	{#State 225
		DEFAULT => -75
	},
	{#State 226
		DEFAULT => -92
	},
	{#State 227
		DEFAULT => -100
	},
	{#State 228
		DEFAULT => -82
	},
	{#State 229
		DEFAULT => -88
	},
	{#State 230
		ACTIONS => {
			"<<" => 290,
			">>" => 289
		},
		DEFAULT => -67
	},
	{#State 231
		DEFAULT => -94
	},
	{#State 232
		ACTIONS => {
			">" => 291
		}
	},
	{#State 233
		ACTIONS => {
			'WIDE_STRING_LITERAL' => 233
		},
		DEFAULT => -98,
		GOTOS => {
			'wide_string_literal' => 292
		}
	},
	{#State 234
		DEFAULT => -91
	},
	{#State 235
		ACTIONS => {
			"%" => 293,
			"*" => 294,
			"/" => 295
		},
		DEFAULT => -72
	},
	{#State 236
		DEFAULT => -95
	},
	{#State 237
		ACTIONS => {
			"-" => 296,
			"+" => 297
		},
		DEFAULT => -69
	},
	{#State 238
		DEFAULT => -93
	},
	{#State 239
		ACTIONS => {
			">" => 298
		}
	},
	{#State 240
		DEFAULT => -80
	},
	{#State 241
		ACTIONS => {
			'STRING_LITERAL' => 241
		},
		DEFAULT => -96,
		GOTOS => {
			'string_literal' => 299
		}
	},
	{#State 242
		DEFAULT => -90
	},
	{#State 243
		ACTIONS => {
			"^" => 300
		},
		DEFAULT => -63
	},
	{#State 244
		ACTIONS => {
			">" => 301
		}
	},
	{#State 245
		ACTIONS => {
			">" => 302
		}
	},
	{#State 246
		ACTIONS => {
			">" => 303
		}
	},
	{#State 247
		ACTIONS => {
			"," => 305,
			">" => 304
		}
	},
	{#State 248
		ACTIONS => {
			">" => 306
		}
	},
	{#State 249
		ACTIONS => {
			"," => 307
		}
	},
	{#State 250
		ACTIONS => {
			"::" => 76,
			'ENUM' => 2,
			'CHAR' => 77,
			'OBJECT' => 81,
			'STRING' => 84,
			'OCTET' => 53,
			'WSTRING' => 86,
			'UNION' => 10,
			'UNSIGNED' => 55,
			'error' => 313,
			'ANY' => 56,
			'FLOAT' => 90,
			'LONG' => 58,
			'SEQUENCE' => 91,
			'IDENTIFIER' => 63,
			'DOUBLE' => 92,
			'SHORT' => 93,
			'BOOLEAN' => 95,
			'STRUCT' => 25,
			'VOID' => 308,
			'FIXED' => 98,
			'WCHAR' => 73
		},
		GOTOS => {
			'wide_string_type' => 258,
			'union_type' => 51,
			'object_type' => 78,
			'integer_type' => 80,
			'unsigned_int' => 83,
			'sequence_type' => 310,
			'enum_header' => 4,
			'op_param_type_spec' => 311,
			'unsigned_short_int' => 52,
			'unsigned_longlong_int' => 85,
			'struct_type' => 54,
			'union_header' => 9,
			'constr_type_spec' => 312,
			'struct_header' => 14,
			'floating_pt_type' => 89,
			'signed_longlong_int' => 59,
			'enum_type' => 60,
			'any_type' => 61,
			'base_type_spec' => 261,
			'unsigned_long_int' => 64,
			'scoped_name' => 254,
			'signed_int' => 96,
			'string_type' => 255,
			'char_type' => 67,
			'param_type_spec' => 309,
			'fixed_pt_type' => 257,
			'signed_long_int' => 69,
			'signed_short_int' => 70,
			'boolean_type' => 99,
			'wide_char_type' => 72,
			'octet_type' => 74
		}
	},
	{#State 251
		DEFAULT => -34
	},
	{#State 252
		DEFAULT => -32
	},
	{#State 253
		DEFAULT => -31
	},
	{#State 254
		ACTIONS => {
			"::" => 148
		},
		DEFAULT => -275
	},
	{#State 255
		DEFAULT => -272
	},
	{#State 256
		DEFAULT => -238
	},
	{#State 257
		DEFAULT => -274
	},
	{#State 258
		DEFAULT => -273
	},
	{#State 259
		DEFAULT => -239
	},
	{#State 260
		DEFAULT => -237
	},
	{#State 261
		DEFAULT => -271
	},
	{#State 262
		ACTIONS => {
			'IDENTIFIER' => 314,
			'error' => 315
		}
	},
	{#State 263
		DEFAULT => -33
	},
	{#State 264
		ACTIONS => {
			"::" => -253,
			'ENUM' => -253,
			'CHAR' => -253,
			'OBJECT' => -253,
			'STRING' => -253,
			'OCTET' => -253,
			'WSTRING' => -253,
			'UNION' => -253,
			'UNSIGNED' => -253,
			'error' => 321,
			'ANY' => -253,
			'FLOAT' => -253,
			")" => 322,
			'LONG' => -253,
			'SEQUENCE' => -253,
			'IDENTIFIER' => -253,
			'DOUBLE' => -253,
			'SHORT' => -253,
			'BOOLEAN' => -253,
			'INOUT' => 317,
			"..." => 323,
			'STRUCT' => -253,
			'OUT' => 318,
			'IN' => 324,
			'VOID' => -253,
			'FIXED' => -253,
			'WCHAR' => -253
		},
		GOTOS => {
			'param_attribute' => 316,
			'param_dcl' => 319,
			'param_dcls' => 320
		}
	},
	{#State 265
		DEFAULT => -231
	},
	{#State 266
		ACTIONS => {
			'RAISES' => 325
		},
		DEFAULT => -257,
		GOTOS => {
			'raises_expr' => 326
		}
	},
	{#State 267
		DEFAULT => -23
	},
	{#State 268
		DEFAULT => -36
	},
	{#State 269
		DEFAULT => -35
	},
	{#State 270
		DEFAULT => -24
	},
	{#State 271
		DEFAULT => -50
	},
	{#State 272
		ACTIONS => {
			"-" => 214,
			"::" => 76,
			'TRUE' => 227,
			"+" => 228,
			"~" => 215,
			'INTEGER_LITERAL' => 229,
			'FLOATING_PT_LITERAL' => 231,
			'FALSE' => 217,
			'error' => 328,
			'WIDE_STRING_LITERAL' => 233,
			'CHARACTER_LITERAL' => 234,
			'IDENTIFIER' => 63,
			"(" => 224,
			'FIXED_PT_LITERAL' => 238,
			'STRING_LITERAL' => 241,
			'WIDE_CHARACTER_LITERAL' => 226
		},
		GOTOS => {
			'and_expr' => 221,
			'or_expr' => 222,
			'mult_expr' => 235,
			'shift_expr' => 230,
			'scoped_name' => 223,
			'boolean_literal' => 236,
			'add_expr' => 237,
			'literal' => 216,
			'primary_expr' => 240,
			'unary_expr' => 225,
			'unary_operator' => 219,
			'const_exp' => 327,
			'xor_expr' => 243,
			'wide_string_literal' => 242,
			'string_literal' => 220
		}
	},
	{#State 273
		DEFAULT => -225
	},
	{#State 274
		DEFAULT => -226
	},
	{#State 275
		ACTIONS => {
			"::" => 76,
			'IDENTIFIER' => 63
		},
		GOTOS => {
			'interface_name' => 188,
			'interface_names' => 329,
			'scoped_name' => 185
		}
	},
	{#State 276
		DEFAULT => -198
	},
	{#State 277
		DEFAULT => -172
	},
	{#State 278
		ACTIONS => {
			"{" => 331,
			'error' => 330
		}
	},
	{#State 279
		DEFAULT => -168
	},
	{#State 280
		ACTIONS => {
			"]" => 332
		}
	},
	{#State 281
		ACTIONS => {
			"]" => 333
		}
	},
	{#State 282
		DEFAULT => -215
	},
	{#State 283
		DEFAULT => -132
	},
	{#State 284
		DEFAULT => -79
	},
	{#State 285
		ACTIONS => {
			"-" => 214,
			"::" => 76,
			'TRUE' => 227,
			'IDENTIFIER' => 63,
			"+" => 228,
			"~" => 215,
			'INTEGER_LITERAL' => 229,
			'FLOATING_PT_LITERAL' => 231,
			'FIXED_PT_LITERAL' => 238,
			"(" => 224,
			'FALSE' => 217,
			'STRING_LITERAL' => 241,
			'WIDE_STRING_LITERAL' => 233,
			'WIDE_CHARACTER_LITERAL' => 226,
			'CHARACTER_LITERAL' => 234
		},
		GOTOS => {
			'mult_expr' => 235,
			'shift_expr' => 334,
			'scoped_name' => 223,
			'boolean_literal' => 236,
			'add_expr' => 237,
			'literal' => 216,
			'primary_expr' => 240,
			'unary_expr' => 225,
			'unary_operator' => 219,
			'wide_string_literal' => 242,
			'string_literal' => 220
		}
	},
	{#State 286
		ACTIONS => {
			"-" => 214,
			"::" => 76,
			'TRUE' => 227,
			'IDENTIFIER' => 63,
			"+" => 228,
			"~" => 215,
			'INTEGER_LITERAL' => 229,
			'FLOATING_PT_LITERAL' => 231,
			'FIXED_PT_LITERAL' => 238,
			"(" => 224,
			'FALSE' => 217,
			'STRING_LITERAL' => 241,
			'WIDE_STRING_LITERAL' => 233,
			'WIDE_CHARACTER_LITERAL' => 226,
			'CHARACTER_LITERAL' => 234
		},
		GOTOS => {
			'and_expr' => 221,
			'mult_expr' => 235,
			'shift_expr' => 230,
			'scoped_name' => 223,
			'boolean_literal' => 236,
			'add_expr' => 237,
			'literal' => 216,
			'primary_expr' => 240,
			'unary_expr' => 225,
			'unary_operator' => 219,
			'xor_expr' => 335,
			'wide_string_literal' => 242,
			'string_literal' => 220
		}
	},
	{#State 287
		ACTIONS => {
			")" => 336
		}
	},
	{#State 288
		ACTIONS => {
			")" => 337
		}
	},
	{#State 289
		ACTIONS => {
			"-" => 214,
			"::" => 76,
			'TRUE' => 227,
			'IDENTIFIER' => 63,
			"+" => 228,
			"~" => 215,
			'INTEGER_LITERAL' => 229,
			'FLOATING_PT_LITERAL' => 231,
			'FIXED_PT_LITERAL' => 238,
			"(" => 224,
			'FALSE' => 217,
			'STRING_LITERAL' => 241,
			'WIDE_STRING_LITERAL' => 233,
			'WIDE_CHARACTER_LITERAL' => 226,
			'CHARACTER_LITERAL' => 234
		},
		GOTOS => {
			'mult_expr' => 235,
			'scoped_name' => 223,
			'boolean_literal' => 236,
			'literal' => 216,
			'add_expr' => 338,
			'primary_expr' => 240,
			'unary_expr' => 225,
			'unary_operator' => 219,
			'wide_string_literal' => 242,
			'string_literal' => 220
		}
	},
	{#State 290
		ACTIONS => {
			"-" => 214,
			"::" => 76,
			'TRUE' => 227,
			'IDENTIFIER' => 63,
			"+" => 228,
			"~" => 215,
			'INTEGER_LITERAL' => 229,
			'FLOATING_PT_LITERAL' => 231,
			'FIXED_PT_LITERAL' => 238,
			"(" => 224,
			'FALSE' => 217,
			'STRING_LITERAL' => 241,
			'WIDE_STRING_LITERAL' => 233,
			'WIDE_CHARACTER_LITERAL' => 226,
			'CHARACTER_LITERAL' => 234
		},
		GOTOS => {
			'mult_expr' => 235,
			'scoped_name' => 223,
			'boolean_literal' => 236,
			'literal' => 216,
			'add_expr' => 339,
			'primary_expr' => 240,
			'unary_expr' => 225,
			'unary_operator' => 219,
			'wide_string_literal' => 242,
			'string_literal' => 220
		}
	},
	{#State 291
		DEFAULT => -209
	},
	{#State 292
		DEFAULT => -99
	},
	{#State 293
		ACTIONS => {
			"-" => 214,
			"::" => 76,
			'TRUE' => 227,
			'IDENTIFIER' => 63,
			"+" => 228,
			"~" => 215,
			'INTEGER_LITERAL' => 229,
			'FLOATING_PT_LITERAL' => 231,
			'FIXED_PT_LITERAL' => 238,
			"(" => 224,
			'FALSE' => 217,
			'STRING_LITERAL' => 241,
			'WIDE_STRING_LITERAL' => 233,
			'WIDE_CHARACTER_LITERAL' => 226,
			'CHARACTER_LITERAL' => 234
		},
		GOTOS => {
			'literal' => 216,
			'primary_expr' => 240,
			'unary_expr' => 340,
			'unary_operator' => 219,
			'scoped_name' => 223,
			'wide_string_literal' => 242,
			'boolean_literal' => 236,
			'string_literal' => 220
		}
	},
	{#State 294
		ACTIONS => {
			"-" => 214,
			"::" => 76,
			'TRUE' => 227,
			'IDENTIFIER' => 63,
			"+" => 228,
			"~" => 215,
			'INTEGER_LITERAL' => 229,
			'FLOATING_PT_LITERAL' => 231,
			'FIXED_PT_LITERAL' => 238,
			"(" => 224,
			'FALSE' => 217,
			'STRING_LITERAL' => 241,
			'WIDE_STRING_LITERAL' => 233,
			'WIDE_CHARACTER_LITERAL' => 226,
			'CHARACTER_LITERAL' => 234
		},
		GOTOS => {
			'literal' => 216,
			'primary_expr' => 240,
			'unary_expr' => 341,
			'unary_operator' => 219,
			'scoped_name' => 223,
			'wide_string_literal' => 242,
			'boolean_literal' => 236,
			'string_literal' => 220
		}
	},
	{#State 295
		ACTIONS => {
			"-" => 214,
			"::" => 76,
			'TRUE' => 227,
			'IDENTIFIER' => 63,
			"+" => 228,
			"~" => 215,
			'INTEGER_LITERAL' => 229,
			'FLOATING_PT_LITERAL' => 231,
			'FIXED_PT_LITERAL' => 238,
			"(" => 224,
			'FALSE' => 217,
			'STRING_LITERAL' => 241,
			'WIDE_STRING_LITERAL' => 233,
			'WIDE_CHARACTER_LITERAL' => 226,
			'CHARACTER_LITERAL' => 234
		},
		GOTOS => {
			'literal' => 216,
			'primary_expr' => 240,
			'unary_expr' => 342,
			'unary_operator' => 219,
			'scoped_name' => 223,
			'wide_string_literal' => 242,
			'boolean_literal' => 236,
			'string_literal' => 220
		}
	},
	{#State 296
		ACTIONS => {
			"-" => 214,
			"::" => 76,
			'TRUE' => 227,
			'IDENTIFIER' => 63,
			"+" => 228,
			"~" => 215,
			'INTEGER_LITERAL' => 229,
			'FLOATING_PT_LITERAL' => 231,
			'FIXED_PT_LITERAL' => 238,
			"(" => 224,
			'FALSE' => 217,
			'STRING_LITERAL' => 241,
			'WIDE_STRING_LITERAL' => 233,
			'WIDE_CHARACTER_LITERAL' => 226,
			'CHARACTER_LITERAL' => 234
		},
		GOTOS => {
			'mult_expr' => 343,
			'scoped_name' => 223,
			'boolean_literal' => 236,
			'literal' => 216,
			'unary_expr' => 225,
			'primary_expr' => 240,
			'unary_operator' => 219,
			'wide_string_literal' => 242,
			'string_literal' => 220
		}
	},
	{#State 297
		ACTIONS => {
			"-" => 214,
			"::" => 76,
			'TRUE' => 227,
			'IDENTIFIER' => 63,
			"+" => 228,
			"~" => 215,
			'INTEGER_LITERAL' => 229,
			'FLOATING_PT_LITERAL' => 231,
			'FIXED_PT_LITERAL' => 238,
			"(" => 224,
			'FALSE' => 217,
			'STRING_LITERAL' => 241,
			'WIDE_STRING_LITERAL' => 233,
			'WIDE_CHARACTER_LITERAL' => 226,
			'CHARACTER_LITERAL' => 234
		},
		GOTOS => {
			'mult_expr' => 344,
			'scoped_name' => 223,
			'boolean_literal' => 236,
			'literal' => 216,
			'unary_expr' => 225,
			'primary_expr' => 240,
			'unary_operator' => 219,
			'wide_string_literal' => 242,
			'string_literal' => 220
		}
	},
	{#State 298
		DEFAULT => -207
	},
	{#State 299
		DEFAULT => -97
	},
	{#State 300
		ACTIONS => {
			"-" => 214,
			"::" => 76,
			'TRUE' => 227,
			'IDENTIFIER' => 63,
			"+" => 228,
			"~" => 215,
			'INTEGER_LITERAL' => 229,
			'FLOATING_PT_LITERAL' => 231,
			'FIXED_PT_LITERAL' => 238,
			"(" => 224,
			'FALSE' => 217,
			'STRING_LITERAL' => 241,
			'WIDE_STRING_LITERAL' => 233,
			'WIDE_CHARACTER_LITERAL' => 226,
			'CHARACTER_LITERAL' => 234
		},
		GOTOS => {
			'and_expr' => 345,
			'mult_expr' => 235,
			'shift_expr' => 230,
			'scoped_name' => 223,
			'boolean_literal' => 236,
			'add_expr' => 237,
			'literal' => 216,
			'primary_expr' => 240,
			'unary_expr' => 225,
			'unary_operator' => 219,
			'wide_string_literal' => 242,
			'string_literal' => 220
		}
	},
	{#State 301
		DEFAULT => -212
	},
	{#State 302
		DEFAULT => -210
	},
	{#State 303
		DEFAULT => -205
	},
	{#State 304
		DEFAULT => -204
	},
	{#State 305
		ACTIONS => {
			"-" => 214,
			"::" => 76,
			'TRUE' => 227,
			"+" => 228,
			"~" => 215,
			'INTEGER_LITERAL' => 229,
			'FLOATING_PT_LITERAL' => 231,
			'FALSE' => 217,
			'error' => 346,
			'WIDE_STRING_LITERAL' => 233,
			'CHARACTER_LITERAL' => 234,
			'IDENTIFIER' => 63,
			"(" => 224,
			'FIXED_PT_LITERAL' => 238,
			'STRING_LITERAL' => 241,
			'WIDE_CHARACTER_LITERAL' => 226
		},
		GOTOS => {
			'shift_expr' => 230,
			'literal' => 216,
			'const_exp' => 218,
			'unary_operator' => 219,
			'string_literal' => 220,
			'and_expr' => 221,
			'or_expr' => 222,
			'mult_expr' => 235,
			'scoped_name' => 223,
			'boolean_literal' => 236,
			'add_expr' => 237,
			'positive_int_const' => 347,
			'unary_expr' => 225,
			'primary_expr' => 240,
			'wide_string_literal' => 242,
			'xor_expr' => 243
		}
	},
	{#State 306
		DEFAULT => -278
	},
	{#State 307
		ACTIONS => {
			"-" => 214,
			"::" => 76,
			'TRUE' => 227,
			"+" => 228,
			"~" => 215,
			'INTEGER_LITERAL' => 229,
			'FLOATING_PT_LITERAL' => 231,
			'FALSE' => 217,
			'error' => 348,
			'WIDE_STRING_LITERAL' => 233,
			'CHARACTER_LITERAL' => 234,
			'IDENTIFIER' => 63,
			"(" => 224,
			'FIXED_PT_LITERAL' => 238,
			'STRING_LITERAL' => 241,
			'WIDE_CHARACTER_LITERAL' => 226
		},
		GOTOS => {
			'shift_expr' => 230,
			'literal' => 216,
			'const_exp' => 218,
			'unary_operator' => 219,
			'string_literal' => 220,
			'and_expr' => 221,
			'or_expr' => 222,
			'mult_expr' => 235,
			'scoped_name' => 223,
			'boolean_literal' => 236,
			'add_expr' => 237,
			'positive_int_const' => 349,
			'unary_expr' => 225,
			'primary_expr' => 240,
			'wide_string_literal' => 242,
			'xor_expr' => 243
		}
	},
	{#State 308
		DEFAULT => -268
	},
	{#State 309
		ACTIONS => {
			'IDENTIFIER' => 49,
			'error' => 48
		},
		GOTOS => {
			'simple_declarators' => 351,
			'simple_declarator' => 350
		}
	},
	{#State 310
		DEFAULT => -269
	},
	{#State 311
		DEFAULT => -267
	},
	{#State 312
		DEFAULT => -270
	},
	{#State 313
		DEFAULT => -219
	},
	{#State 314
		DEFAULT => -232
	},
	{#State 315
		DEFAULT => -233
	},
	{#State 316
		ACTIONS => {
			"::" => 76,
			'ENUM' => 2,
			'CHAR' => 77,
			'OBJECT' => 81,
			'STRING' => 84,
			'OCTET' => 53,
			'WSTRING' => 86,
			'UNION' => 10,
			'UNSIGNED' => 55,
			'ANY' => 56,
			'FLOAT' => 90,
			'LONG' => 58,
			'SEQUENCE' => 91,
			'IDENTIFIER' => 63,
			'DOUBLE' => 92,
			'SHORT' => 93,
			'BOOLEAN' => 95,
			'STRUCT' => 25,
			'VOID' => 308,
			'FIXED' => 98,
			'WCHAR' => 73
		},
		GOTOS => {
			'wide_string_type' => 258,
			'union_type' => 51,
			'object_type' => 78,
			'integer_type' => 80,
			'unsigned_int' => 83,
			'sequence_type' => 310,
			'enum_header' => 4,
			'op_param_type_spec' => 311,
			'unsigned_short_int' => 52,
			'unsigned_longlong_int' => 85,
			'struct_type' => 54,
			'union_header' => 9,
			'constr_type_spec' => 312,
			'struct_header' => 14,
			'floating_pt_type' => 89,
			'signed_longlong_int' => 59,
			'enum_type' => 60,
			'any_type' => 61,
			'base_type_spec' => 261,
			'unsigned_long_int' => 64,
			'scoped_name' => 254,
			'signed_int' => 96,
			'string_type' => 255,
			'char_type' => 67,
			'param_type_spec' => 352,
			'fixed_pt_type' => 257,
			'signed_long_int' => 69,
			'signed_short_int' => 70,
			'boolean_type' => 99,
			'wide_char_type' => 72,
			'octet_type' => 74
		}
	},
	{#State 317
		DEFAULT => -252
	},
	{#State 318
		DEFAULT => -251
	},
	{#State 319
		ACTIONS => {
			";" => 353
		},
		DEFAULT => -246
	},
	{#State 320
		ACTIONS => {
			"," => 354,
			")" => 355
		}
	},
	{#State 321
		ACTIONS => {
			")" => 356
		}
	},
	{#State 322
		DEFAULT => -243
	},
	{#State 323
		ACTIONS => {
			")" => 357
		}
	},
	{#State 324
		DEFAULT => -250
	},
	{#State 325
		ACTIONS => {
			"(" => 358,
			'error' => 359
		}
	},
	{#State 326
		ACTIONS => {
			'CONTEXT' => 361
		},
		DEFAULT => -264,
		GOTOS => {
			'context_expr' => 360
		}
	},
	{#State 327
		DEFAULT => -48
	},
	{#State 328
		DEFAULT => -49
	},
	{#State 329
		DEFAULT => -41
	},
	{#State 330
		DEFAULT => -171
	},
	{#State 331
		ACTIONS => {
			'DEFAULT' => 367,
			'error' => 365,
			'CASE' => 362
		},
		GOTOS => {
			'case_label' => 368,
			'switch_body' => 363,
			'case' => 364,
			'case_labels' => 366
		}
	},
	{#State 332
		DEFAULT => -217
	},
	{#State 333
		DEFAULT => -216
	},
	{#State 334
		ACTIONS => {
			"<<" => 290,
			">>" => 289
		},
		DEFAULT => -68
	},
	{#State 335
		ACTIONS => {
			"^" => 300
		},
		DEFAULT => -64
	},
	{#State 336
		DEFAULT => -86
	},
	{#State 337
		DEFAULT => -87
	},
	{#State 338
		ACTIONS => {
			"-" => 296,
			"+" => 297
		},
		DEFAULT => -70
	},
	{#State 339
		ACTIONS => {
			"-" => 296,
			"+" => 297
		},
		DEFAULT => -71
	},
	{#State 340
		DEFAULT => -78
	},
	{#State 341
		DEFAULT => -76
	},
	{#State 342
		DEFAULT => -77
	},
	{#State 343
		ACTIONS => {
			"%" => 293,
			"*" => 294,
			"/" => 295
		},
		DEFAULT => -74
	},
	{#State 344
		ACTIONS => {
			"%" => 293,
			"*" => 294,
			"/" => 295
		},
		DEFAULT => -73
	},
	{#State 345
		ACTIONS => {
			"&" => 285
		},
		DEFAULT => -66
	},
	{#State 346
		ACTIONS => {
			">" => 369
		}
	},
	{#State 347
		ACTIONS => {
			">" => 370
		}
	},
	{#State 348
		ACTIONS => {
			">" => 371
		}
	},
	{#State 349
		ACTIONS => {
			">" => 372
		}
	},
	{#State 350
		ACTIONS => {
			"," => 373
		},
		DEFAULT => -222
	},
	{#State 351
		DEFAULT => -218
	},
	{#State 352
		ACTIONS => {
			'IDENTIFIER' => 49,
			'error' => 48
		},
		GOTOS => {
			'simple_declarator' => 374
		}
	},
	{#State 353
		DEFAULT => -248
	},
	{#State 354
		ACTIONS => {
			")" => 376,
			'INOUT' => 317,
			"..." => 377,
			'OUT' => 318,
			'IN' => 324
		},
		DEFAULT => -253,
		GOTOS => {
			'param_attribute' => 316,
			'param_dcl' => 375
		}
	},
	{#State 355
		DEFAULT => -240
	},
	{#State 356
		DEFAULT => -245
	},
	{#State 357
		DEFAULT => -244
	},
	{#State 358
		ACTIONS => {
			"::" => 76,
			'IDENTIFIER' => 63,
			'error' => 379
		},
		GOTOS => {
			'exception_names' => 380,
			'scoped_name' => 378,
			'exception_name' => 381
		}
	},
	{#State 359
		DEFAULT => -256
	},
	{#State 360
		DEFAULT => -230
	},
	{#State 361
		ACTIONS => {
			"(" => 382,
			'error' => 383
		}
	},
	{#State 362
		ACTIONS => {
			"-" => 214,
			"::" => 76,
			'TRUE' => 227,
			"+" => 228,
			"~" => 215,
			'INTEGER_LITERAL' => 229,
			'FLOATING_PT_LITERAL' => 231,
			'FALSE' => 217,
			'error' => 385,
			'WIDE_STRING_LITERAL' => 233,
			'CHARACTER_LITERAL' => 234,
			'IDENTIFIER' => 63,
			"(" => 224,
			'FIXED_PT_LITERAL' => 238,
			'STRING_LITERAL' => 241,
			'WIDE_CHARACTER_LITERAL' => 226
		},
		GOTOS => {
			'and_expr' => 221,
			'or_expr' => 222,
			'mult_expr' => 235,
			'shift_expr' => 230,
			'scoped_name' => 223,
			'boolean_literal' => 236,
			'add_expr' => 237,
			'literal' => 216,
			'primary_expr' => 240,
			'unary_expr' => 225,
			'unary_operator' => 219,
			'const_exp' => 384,
			'xor_expr' => 243,
			'wide_string_literal' => 242,
			'string_literal' => 220
		}
	},
	{#State 363
		ACTIONS => {
			"}" => 386
		}
	},
	{#State 364
		ACTIONS => {
			'DEFAULT' => 367,
			'CASE' => 362
		},
		DEFAULT => -181,
		GOTOS => {
			'case_label' => 368,
			'switch_body' => 387,
			'case' => 364,
			'case_labels' => 366
		}
	},
	{#State 365
		ACTIONS => {
			"}" => 388
		}
	},
	{#State 366
		ACTIONS => {
			"::" => 76,
			'ENUM' => 2,
			'CHAR' => 77,
			'OBJECT' => 81,
			'STRING' => 84,
			'OCTET' => 53,
			'WSTRING' => 86,
			'UNION' => 10,
			'UNSIGNED' => 55,
			'ANY' => 56,
			'FLOAT' => 90,
			'LONG' => 58,
			'SEQUENCE' => 91,
			'IDENTIFIER' => 63,
			'DOUBLE' => 92,
			'SHORT' => 93,
			'BOOLEAN' => 95,
			'STRUCT' => 25,
			'VOID' => 68,
			'FIXED' => 98,
			'WCHAR' => 73
		},
		GOTOS => {
			'union_type' => 51,
			'enum_header' => 4,
			'unsigned_short_int' => 52,
			'struct_type' => 54,
			'union_header' => 9,
			'struct_header' => 14,
			'signed_longlong_int' => 59,
			'enum_type' => 60,
			'any_type' => 61,
			'template_type_spec' => 62,
			'element_spec' => 389,
			'unsigned_long_int' => 64,
			'scoped_name' => 65,
			'string_type' => 66,
			'char_type' => 67,
			'fixed_pt_type' => 71,
			'signed_short_int' => 70,
			'signed_long_int' => 69,
			'wide_char_type' => 72,
			'octet_type' => 74,
			'wide_string_type' => 75,
			'object_type' => 78,
			'type_spec' => 390,
			'integer_type' => 80,
			'unsigned_int' => 83,
			'sequence_type' => 82,
			'unsigned_longlong_int' => 85,
			'constr_type_spec' => 87,
			'floating_pt_type' => 89,
			'base_type_spec' => 94,
			'signed_int' => 96,
			'simple_type_spec' => 97,
			'boolean_type' => 99
		}
	},
	{#State 367
		ACTIONS => {
			":" => 391,
			'error' => 392
		}
	},
	{#State 368
		ACTIONS => {
			'CASE' => 362,
			'DEFAULT' => 367
		},
		DEFAULT => -184,
		GOTOS => {
			'case_label' => 368,
			'case_labels' => 393
		}
	},
	{#State 369
		DEFAULT => -203
	},
	{#State 370
		DEFAULT => -202
	},
	{#State 371
		DEFAULT => -277
	},
	{#State 372
		DEFAULT => -276
	},
	{#State 373
		ACTIONS => {
			'IDENTIFIER' => 49,
			'error' => 48
		},
		GOTOS => {
			'simple_declarators' => 394,
			'simple_declarator' => 350
		}
	},
	{#State 374
		DEFAULT => -249
	},
	{#State 375
		DEFAULT => -247
	},
	{#State 376
		DEFAULT => -242
	},
	{#State 377
		ACTIONS => {
			")" => 395
		}
	},
	{#State 378
		ACTIONS => {
			"::" => 148
		},
		DEFAULT => -260
	},
	{#State 379
		ACTIONS => {
			")" => 396
		}
	},
	{#State 380
		ACTIONS => {
			")" => 397
		}
	},
	{#State 381
		ACTIONS => {
			"," => 398
		},
		DEFAULT => -258
	},
	{#State 382
		ACTIONS => {
			'STRING_LITERAL' => 241,
			'error' => 401
		},
		GOTOS => {
			'string_literals' => 400,
			'string_literal' => 399
		}
	},
	{#State 383
		DEFAULT => -263
	},
	{#State 384
		ACTIONS => {
			":" => 402,
			'error' => 403
		}
	},
	{#State 385
		DEFAULT => -188
	},
	{#State 386
		DEFAULT => -169
	},
	{#State 387
		DEFAULT => -182
	},
	{#State 388
		DEFAULT => -170
	},
	{#State 389
		ACTIONS => {
			";" => 44,
			'error' => 45
		},
		GOTOS => {
			'check_semicolon' => 404
		}
	},
	{#State 390
		ACTIONS => {
			'IDENTIFIER' => 152,
			'error' => 48
		},
		GOTOS => {
			'array_declarator' => 155,
			'simple_declarator' => 151,
			'declarator' => 405,
			'complex_declarator' => 156
		}
	},
	{#State 391
		DEFAULT => -189
	},
	{#State 392
		DEFAULT => -190
	},
	{#State 393
		DEFAULT => -185
	},
	{#State 394
		DEFAULT => -223
	},
	{#State 395
		DEFAULT => -241
	},
	{#State 396
		DEFAULT => -255
	},
	{#State 397
		DEFAULT => -254
	},
	{#State 398
		ACTIONS => {
			"::" => 76,
			'IDENTIFIER' => 63
		},
		GOTOS => {
			'exception_names' => 406,
			'scoped_name' => 378,
			'exception_name' => 381
		}
	},
	{#State 399
		ACTIONS => {
			"," => 407
		},
		DEFAULT => -265
	},
	{#State 400
		ACTIONS => {
			")" => 408
		}
	},
	{#State 401
		ACTIONS => {
			")" => 409
		}
	},
	{#State 402
		DEFAULT => -186
	},
	{#State 403
		DEFAULT => -187
	},
	{#State 404
		DEFAULT => -183
	},
	{#State 405
		DEFAULT => -191
	},
	{#State 406
		DEFAULT => -259
	},
	{#State 407
		ACTIONS => {
			'STRING_LITERAL' => 241
		},
		GOTOS => {
			'string_literals' => 410,
			'string_literal' => 399
		}
	},
	{#State 408
		DEFAULT => -261
	},
	{#State 409
		DEFAULT => -262
	},
	{#State 410
		DEFAULT => -266
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
#line 60 "Parser22.yp"
{
            $_[0]->YYData->{root} = new CORBA::IDL::Specification($_[0],
                    'list_decl'         =>  $_[1],
            );
        }
	],
	[#Rule 2
		 'specification', 0,
sub
#line 66 "Parser22.yp"
{
            $_[0]->Error("Empty specification.\n");
        }
	],
	[#Rule 3
		 'specification', 1,
sub
#line 70 "Parser22.yp"
{
            $_[0]->Error("definition declaration expected.\n");
        }
	],
	[#Rule 4
		 'definitions', 1,
sub
#line 77 "Parser22.yp"
{
            [$_[1]->getRef()];
        }
	],
	[#Rule 5
		 'definitions', 2,
sub
#line 81 "Parser22.yp"
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
#line 100 "Parser22.yp"
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
#line 114 "Parser22.yp"
{
            $_[0]->Warning("';' expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 14
		 'module', 4,
sub
#line 123 "Parser22.yp"
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
#line 130 "Parser22.yp"
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
#line 137 "Parser22.yp"
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
#line 144 "Parser22.yp"
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
#line 154 "Parser22.yp"
{
            new CORBA::IDL::Module($_[0],
                    'idf'               =>  $_[2],
            );
        }
	],
	[#Rule 19
		 'module_header', 2,
sub
#line 160 "Parser22.yp"
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
#line 177 "Parser22.yp"
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
#line 185 "Parser22.yp"
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
#line 193 "Parser22.yp"
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
#line 205 "Parser22.yp"
{
            new CORBA::IDL::ForwardRegularInterface($_[0],
                    'idf'                   =>  $_[2]
            );
        }
	],
	[#Rule 26
		 'forward_dcl', 2,
sub
#line 211 "Parser22.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 27
		 'interface_header', 3,
sub
#line 220 "Parser22.yp"
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
#line 227 "Parser22.yp"
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
#line 241 "Parser22.yp"
{
            [$_[1]->getRef()];
        }
	],
	[#Rule 31
		 'exports', 2,
sub
#line 245 "Parser22.yp"
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
#line 268 "Parser22.yp"
{
            new CORBA::IDL::InheritanceSpec($_[0],
                    'list_interface'        =>  $_[2]
            );
        }
	],
	[#Rule 38
		 'interface_inheritance_spec', 2,
sub
#line 274 "Parser22.yp"
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
#line 284 "Parser22.yp"
{
            [$_[1]];
        }
	],
	[#Rule 41
		 'interface_names', 3,
sub
#line 288 "Parser22.yp"
{
            unshift @{$_[3]}, $_[1];
            $_[3];
        }
	],
	[#Rule 42
		 'interface_name', 1,
sub
#line 296 "Parser22.yp"
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
#line 306 "Parser22.yp"
{
            $_[1] . $_[2];
        }
	],
	[#Rule 45
		 'scoped_name', 2,
sub
#line 310 "Parser22.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
            '';
        }
	],
	[#Rule 46
		 'scoped_name', 3,
sub
#line 316 "Parser22.yp"
{
            $_[1] . $_[2] . $_[3];
        }
	],
	[#Rule 47
		 'scoped_name', 3,
sub
#line 320 "Parser22.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 48
		 'const_dcl', 5,
sub
#line 330 "Parser22.yp"
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
#line 338 "Parser22.yp"
{
            $_[0]->Error("Expression expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 50
		 'const_dcl', 4,
sub
#line 343 "Parser22.yp"
{
            $_[0]->Error("'=' expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 51
		 'const_dcl', 3,
sub
#line 348 "Parser22.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 52
		 'const_dcl', 2,
sub
#line 353 "Parser22.yp"
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
		 'const_type', 1, undef
	],
	[#Rule 59
		 'const_type', 1, undef
	],
	[#Rule 60
		 'const_type', 1, undef
	],
	[#Rule 61
		 'const_type', 1,
sub
#line 378 "Parser22.yp"
{
            CORBA::IDL::TypeDeclarator->Lookup($_[0], $_[1]);
        }
	],
	[#Rule 62
		 'const_exp', 1, undef
	],
	[#Rule 63
		 'or_expr', 1, undef
	],
	[#Rule 64
		 'or_expr', 3,
sub
#line 394 "Parser22.yp"
{
            BuildBinop($_[1], $_[2], $_[3]);
        }
	],
	[#Rule 65
		 'xor_expr', 1, undef
	],
	[#Rule 66
		 'xor_expr', 3,
sub
#line 404 "Parser22.yp"
{
            BuildBinop($_[1], $_[2], $_[3]);
        }
	],
	[#Rule 67
		 'and_expr', 1, undef
	],
	[#Rule 68
		 'and_expr', 3,
sub
#line 414 "Parser22.yp"
{
            BuildBinop($_[1], $_[2], $_[3]);
        }
	],
	[#Rule 69
		 'shift_expr', 1, undef
	],
	[#Rule 70
		 'shift_expr', 3,
sub
#line 424 "Parser22.yp"
{
            BuildBinop($_[1], $_[2], $_[3]);
        }
	],
	[#Rule 71
		 'shift_expr', 3,
sub
#line 428 "Parser22.yp"
{
            BuildBinop($_[1], $_[2], $_[3]);
        }
	],
	[#Rule 72
		 'add_expr', 1, undef
	],
	[#Rule 73
		 'add_expr', 3,
sub
#line 438 "Parser22.yp"
{
            BuildBinop($_[1], $_[2], $_[3]);
        }
	],
	[#Rule 74
		 'add_expr', 3,
sub
#line 442 "Parser22.yp"
{
            BuildBinop($_[1], $_[2], $_[3]);
        }
	],
	[#Rule 75
		 'mult_expr', 1, undef
	],
	[#Rule 76
		 'mult_expr', 3,
sub
#line 452 "Parser22.yp"
{
            BuildBinop($_[1], $_[2], $_[3]);
        }
	],
	[#Rule 77
		 'mult_expr', 3,
sub
#line 456 "Parser22.yp"
{
            BuildBinop($_[1], $_[2], $_[3]);
        }
	],
	[#Rule 78
		 'mult_expr', 3,
sub
#line 460 "Parser22.yp"
{
            BuildBinop($_[1], $_[2], $_[3]);
        }
	],
	[#Rule 79
		 'unary_expr', 2,
sub
#line 468 "Parser22.yp"
{
            BuildUnop($_[1], $_[2]);
        }
	],
	[#Rule 80
		 'unary_expr', 1, undef
	],
	[#Rule 81
		 'unary_operator', 1, undef
	],
	[#Rule 82
		 'unary_operator', 1, undef
	],
	[#Rule 83
		 'unary_operator', 1, undef
	],
	[#Rule 84
		 'primary_expr', 1,
sub
#line 488 "Parser22.yp"
{
            [
                CORBA::IDL::Constant->Lookup($_[0], $_[1])
            ];
        }
	],
	[#Rule 85
		 'primary_expr', 1,
sub
#line 494 "Parser22.yp"
{
            [ $_[1] ];
        }
	],
	[#Rule 86
		 'primary_expr', 3,
sub
#line 498 "Parser22.yp"
{
            $_[2];
        }
	],
	[#Rule 87
		 'primary_expr', 3,
sub
#line 502 "Parser22.yp"
{
            $_[0]->Error("Expression expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 88
		 'literal', 1,
sub
#line 511 "Parser22.yp"
{
            new CORBA::IDL::IntegerLiteral($_[0],
                    'value'             =>  $_[1],
                    'lexeme'            =>  $_[0]->YYData->{lexeme}
            );
        }
	],
	[#Rule 89
		 'literal', 1,
sub
#line 518 "Parser22.yp"
{
            new CORBA::IDL::StringLiteral($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 90
		 'literal', 1,
sub
#line 524 "Parser22.yp"
{
            new CORBA::IDL::WideStringLiteral($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 91
		 'literal', 1,
sub
#line 530 "Parser22.yp"
{
            new CORBA::IDL::CharacterLiteral($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 92
		 'literal', 1,
sub
#line 536 "Parser22.yp"
{
            new CORBA::IDL::WideCharacterLiteral($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 93
		 'literal', 1,
sub
#line 542 "Parser22.yp"
{
            new CORBA::IDL::FixedPtLiteral($_[0],
                    'value'             =>  $_[1],
                    'lexeme'            =>  $_[0]->YYData->{lexeme}
            );
        }
	],
	[#Rule 94
		 'literal', 1,
sub
#line 549 "Parser22.yp"
{
            new CORBA::IDL::FloatingPtLiteral($_[0],
                    'value'             =>  $_[1],
                    'lexeme'            =>  $_[0]->YYData->{lexeme}
            );
        }
	],
	[#Rule 95
		 'literal', 1, undef
	],
	[#Rule 96
		 'string_literal', 1, undef
	],
	[#Rule 97
		 'string_literal', 2,
sub
#line 563 "Parser22.yp"
{
            $_[1] . $_[2];
        }
	],
	[#Rule 98
		 'wide_string_literal', 1, undef
	],
	[#Rule 99
		 'wide_string_literal', 2,
sub
#line 572 "Parser22.yp"
{
            $_[1] . $_[2];
        }
	],
	[#Rule 100
		 'boolean_literal', 1,
sub
#line 580 "Parser22.yp"
{
            new CORBA::IDL::BooleanLiteral($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 101
		 'boolean_literal', 1,
sub
#line 586 "Parser22.yp"
{
            new CORBA::IDL::BooleanLiteral($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 102
		 'positive_int_const', 1,
sub
#line 596 "Parser22.yp"
{
            new CORBA::IDL::Expression($_[0],
                    'list_expr'         =>  $_[1]
            );
        }
	],
	[#Rule 103
		 'type_dcl', 2,
sub
#line 606 "Parser22.yp"
{
            $_[2];
        }
	],
	[#Rule 104
		 'type_dcl', 1, undef
	],
	[#Rule 105
		 'type_dcl', 1, undef
	],
	[#Rule 106
		 'type_dcl', 1, undef
	],
	[#Rule 107
		 'type_dcl', 2,
sub
#line 616 "Parser22.yp"
{
            new CORBA::IDL::NativeType($_[0],
                    'idf'               =>  $_[2]
            );
        }
	],
	[#Rule 108
		 'type_dcl', 2,
sub
#line 622 "Parser22.yp"
{
            $_[0]->Error("type_declarator expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 109
		 'type_declarator', 2,
sub
#line 631 "Parser22.yp"
{
            new CORBA::IDL::TypeDeclarators($_[0],
                    'type'              =>  $_[1],
                    'list_expr'         =>  $_[2]
            );
        }
	],
	[#Rule 110
		 'type_spec', 1, undef
	],
	[#Rule 111
		 'type_spec', 1, undef
	],
	[#Rule 112
		 'simple_type_spec', 1, undef
	],
	[#Rule 113
		 'simple_type_spec', 1, undef
	],
	[#Rule 114
		 'simple_type_spec', 1,
sub
#line 654 "Parser22.yp"
{
            CORBA::IDL::TypeDeclarator->Lookup($_[0], $_[1]);
        }
	],
	[#Rule 115
		 'simple_type_spec', 1,
sub
#line 658 "Parser22.yp"
{
            $_[0]->Error("simple_type_spec expected.\n");
            new CORBA::IDL::VoidType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 116
		 'base_type_spec', 1, undef
	],
	[#Rule 117
		 'base_type_spec', 1, undef
	],
	[#Rule 118
		 'base_type_spec', 1, undef
	],
	[#Rule 119
		 'base_type_spec', 1, undef
	],
	[#Rule 120
		 'base_type_spec', 1, undef
	],
	[#Rule 121
		 'base_type_spec', 1, undef
	],
	[#Rule 122
		 'base_type_spec', 1, undef
	],
	[#Rule 123
		 'base_type_spec', 1, undef
	],
	[#Rule 124
		 'template_type_spec', 1, undef
	],
	[#Rule 125
		 'template_type_spec', 1, undef
	],
	[#Rule 126
		 'template_type_spec', 1, undef
	],
	[#Rule 127
		 'template_type_spec', 1, undef
	],
	[#Rule 128
		 'constr_type_spec', 1, undef
	],
	[#Rule 129
		 'constr_type_spec', 1, undef
	],
	[#Rule 130
		 'constr_type_spec', 1, undef
	],
	[#Rule 131
		 'declarators', 1,
sub
#line 711 "Parser22.yp"
{
            [$_[1]];
        }
	],
	[#Rule 132
		 'declarators', 3,
sub
#line 715 "Parser22.yp"
{
            unshift @{$_[3]}, $_[1];
            $_[3];
        }
	],
	[#Rule 133
		 'declarator', 1,
sub
#line 724 "Parser22.yp"
{
            [$_[1]];
        }
	],
	[#Rule 134
		 'declarator', 1, undef
	],
	[#Rule 135
		 'simple_declarator', 1, undef
	],
	[#Rule 136
		 'simple_declarator', 2,
sub
#line 736 "Parser22.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 137
		 'simple_declarator', 2,
sub
#line 741 "Parser22.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 138
		 'complex_declarator', 1, undef
	],
	[#Rule 139
		 'floating_pt_type', 1,
sub
#line 756 "Parser22.yp"
{
            new CORBA::IDL::FloatingPtType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 140
		 'floating_pt_type', 1,
sub
#line 762 "Parser22.yp"
{
            new CORBA::IDL::FloatingPtType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 141
		 'floating_pt_type', 2,
sub
#line 768 "Parser22.yp"
{
            new CORBA::IDL::FloatingPtType($_[0],
                    'value'             =>  $_[1] . q{ } . $_[2]
            );
        }
	],
	[#Rule 142
		 'integer_type', 1, undef
	],
	[#Rule 143
		 'integer_type', 1, undef
	],
	[#Rule 144
		 'signed_int', 1, undef
	],
	[#Rule 145
		 'signed_int', 1, undef
	],
	[#Rule 146
		 'signed_int', 1, undef
	],
	[#Rule 147
		 'signed_short_int', 1,
sub
#line 796 "Parser22.yp"
{
            new CORBA::IDL::IntegerType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 148
		 'signed_long_int', 1,
sub
#line 806 "Parser22.yp"
{
            new CORBA::IDL::IntegerType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 149
		 'signed_longlong_int', 2,
sub
#line 816 "Parser22.yp"
{
            new CORBA::IDL::IntegerType($_[0],
                    'value'             =>  $_[1] . q{ } . $_[2]
            );
        }
	],
	[#Rule 150
		 'unsigned_int', 1, undef
	],
	[#Rule 151
		 'unsigned_int', 1, undef
	],
	[#Rule 152
		 'unsigned_int', 1, undef
	],
	[#Rule 153
		 'unsigned_short_int', 2,
sub
#line 836 "Parser22.yp"
{
            new CORBA::IDL::IntegerType($_[0],
                    'value'             =>  $_[1] . q{ } . $_[2]
            );
        }
	],
	[#Rule 154
		 'unsigned_long_int', 2,
sub
#line 846 "Parser22.yp"
{
            new CORBA::IDL::IntegerType($_[0],
                    'value'             =>  $_[1] . q{ } . $_[2]
            );
        }
	],
	[#Rule 155
		 'unsigned_longlong_int', 3,
sub
#line 856 "Parser22.yp"
{
            new CORBA::IDL::IntegerType($_[0],
                    'value'             =>  $_[1] . q{ } . $_[2] . q{ } . $_[3]
            );
        }
	],
	[#Rule 156
		 'char_type', 1,
sub
#line 866 "Parser22.yp"
{
            new CORBA::IDL::CharType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 157
		 'wide_char_type', 1,
sub
#line 876 "Parser22.yp"
{
            new CORBA::IDL::WideCharType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 158
		 'boolean_type', 1,
sub
#line 886 "Parser22.yp"
{
            new CORBA::IDL::BooleanType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 159
		 'octet_type', 1,
sub
#line 896 "Parser22.yp"
{
            new CORBA::IDL::OctetType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 160
		 'any_type', 1,
sub
#line 906 "Parser22.yp"
{
            new CORBA::IDL::AnyType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 161
		 'object_type', 1,
sub
#line 916 "Parser22.yp"
{
            new CORBA::IDL::ObjectType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 162
		 'struct_type', 4,
sub
#line 926 "Parser22.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[1]->Configure($_[0],
                    'list_expr'         =>  $_[3]
            ) if (defined $_[1]);
        }
	],
	[#Rule 163
		 'struct_type', 4,
sub
#line 933 "Parser22.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->Error("member expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 164
		 'struct_header', 2,
sub
#line 943 "Parser22.yp"
{
            new CORBA::IDL::StructType($_[0],
                    'idf'               =>  $_[2]
            );
        }
	],
	[#Rule 165
		 'struct_header', 2,
sub
#line 949 "Parser22.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 166
		 'member_list', 1,
sub
#line 958 "Parser22.yp"
{
            [$_[1]];
        }
	],
	[#Rule 167
		 'member_list', 2,
sub
#line 962 "Parser22.yp"
{
            unshift @{$_[2]}, $_[1];
            $_[2];
        }
	],
	[#Rule 168
		 'member', 3,
sub
#line 971 "Parser22.yp"
{
            new CORBA::IDL::Members($_[0],
                    'type'              =>  $_[1],
                    'list_expr'         =>  $_[2]
            );
        }
	],
	[#Rule 169
		 'union_type', 8,
sub
#line 982 "Parser22.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[1]->Configure($_[0],
                    'type'              =>  $_[4],
                    'list_expr'         =>  $_[7]
            ) if (defined $_[1]);
        }
	],
	[#Rule 170
		 'union_type', 8,
sub
#line 990 "Parser22.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->Error("switch_body expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 171
		 'union_type', 6,
sub
#line 997 "Parser22.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->Error("'\x7b' expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 172
		 'union_type', 5,
sub
#line 1004 "Parser22.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->Error("switch_type_spec expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 173
		 'union_type', 3,
sub
#line 1011 "Parser22.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->Error("'(' expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 174
		 'union_header', 2,
sub
#line 1021 "Parser22.yp"
{
            new CORBA::IDL::UnionType($_[0],
                    'idf'               =>  $_[2],
            );
        }
	],
	[#Rule 175
		 'union_header', 2,
sub
#line 1027 "Parser22.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 176
		 'switch_type_spec', 1, undef
	],
	[#Rule 177
		 'switch_type_spec', 1, undef
	],
	[#Rule 178
		 'switch_type_spec', 1, undef
	],
	[#Rule 179
		 'switch_type_spec', 1, undef
	],
	[#Rule 180
		 'switch_type_spec', 1,
sub
#line 1044 "Parser22.yp"
{
            CORBA::IDL::TypeDeclarator->Lookup($_[0], $_[1]);
        }
	],
	[#Rule 181
		 'switch_body', 1,
sub
#line 1052 "Parser22.yp"
{
            [$_[1]];
        }
	],
	[#Rule 182
		 'switch_body', 2,
sub
#line 1056 "Parser22.yp"
{
            unshift @{$_[2]}, $_[1];
            $_[2];
        }
	],
	[#Rule 183
		 'case', 3,
sub
#line 1065 "Parser22.yp"
{
            new CORBA::IDL::Case($_[0],
                    'list_label'        =>  $_[1],
                    'element'           =>  $_[2]
            );
        }
	],
	[#Rule 184
		 'case_labels', 1,
sub
#line 1075 "Parser22.yp"
{
            [$_[1]];
        }
	],
	[#Rule 185
		 'case_labels', 2,
sub
#line 1079 "Parser22.yp"
{
            unshift @{$_[2]}, $_[1];
            $_[2];
        }
	],
	[#Rule 186
		 'case_label', 3,
sub
#line 1088 "Parser22.yp"
{
            $_[2];                      # here only a expression, type is not known
        }
	],
	[#Rule 187
		 'case_label', 3,
sub
#line 1092 "Parser22.yp"
{
            $_[0]->Error("':' expected.\n");
            $_[0]->YYErrok();
            $_[2];
        }
	],
	[#Rule 188
		 'case_label', 2,
sub
#line 1098 "Parser22.yp"
{
            $_[0]->Error("Expression expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 189
		 'case_label', 2,
sub
#line 1103 "Parser22.yp"
{
            new CORBA::IDL::Default($_[0]);
        }
	],
	[#Rule 190
		 'case_label', 2,
sub
#line 1107 "Parser22.yp"
{
            $_[0]->Error("':' expected.\n");
            $_[0]->YYErrok();
            new CORBA::IDL::Default($_[0]);
        }
	],
	[#Rule 191
		 'element_spec', 2,
sub
#line 1117 "Parser22.yp"
{
            new CORBA::IDL::Element($_[0],
                    'type'          =>  $_[1],
                    'list_expr'     =>  $_[2]
            );
        }
	],
	[#Rule 192
		 'enum_type', 4,
sub
#line 1128 "Parser22.yp"
{
            $_[1]->Configure($_[0],
                    'list_expr'     =>  $_[3]
            ) if (defined $_[1]);
        }
	],
	[#Rule 193
		 'enum_type', 4,
sub
#line 1134 "Parser22.yp"
{
            $_[0]->Error("enumerator expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 194
		 'enum_type', 2,
sub
#line 1140 "Parser22.yp"
{
            $_[0]->Error("'\x7b' expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 195
		 'enum_header', 2,
sub
#line 1149 "Parser22.yp"
{
            new CORBA::IDL::EnumType($_[0],
                    'idf'               =>  $_[2],
            );
        }
	],
	[#Rule 196
		 'enum_header', 2,
sub
#line 1155 "Parser22.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 197
		 'enumerators', 1,
sub
#line 1163 "Parser22.yp"
{
            [$_[1]];
        }
	],
	[#Rule 198
		 'enumerators', 3,
sub
#line 1167 "Parser22.yp"
{
            unshift @{$_[3]}, $_[1];
            $_[3];
        }
	],
	[#Rule 199
		 'enumerators', 2,
sub
#line 1172 "Parser22.yp"
{
            $_[0]->Warning("',' unexpected.\n");
            [$_[1]];
        }
	],
	[#Rule 200
		 'enumerators', 2,
sub
#line 1177 "Parser22.yp"
{
            $_[0]->Error("';' unexpected.\n");
            [$_[1]];
        }
	],
	[#Rule 201
		 'enumerator', 1,
sub
#line 1186 "Parser22.yp"
{
            new CORBA::IDL::Enum($_[0],
                    'idf'               =>  $_[1]
            );
        }
	],
	[#Rule 202
		 'sequence_type', 6,
sub
#line 1196 "Parser22.yp"
{
            new CORBA::IDL::SequenceType($_[0],
                    'value'             =>  $_[1],
                    'type'              =>  $_[3],
                    'max'               =>  $_[5]
            );
        }
	],
	[#Rule 203
		 'sequence_type', 6,
sub
#line 1204 "Parser22.yp"
{
            $_[0]->Error("Expression expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 204
		 'sequence_type', 4,
sub
#line 1209 "Parser22.yp"
{
            new CORBA::IDL::SequenceType($_[0],
                    'value'             =>  $_[1],
                    'type'              =>  $_[3]
            );
        }
	],
	[#Rule 205
		 'sequence_type', 4,
sub
#line 1216 "Parser22.yp"
{
            $_[0]->Error("simple_type_spec expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 206
		 'sequence_type', 2,
sub
#line 1221 "Parser22.yp"
{
            $_[0]->Error("'<' expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 207
		 'string_type', 4,
sub
#line 1230 "Parser22.yp"
{
            new CORBA::IDL::StringType($_[0],
                    'value'             =>  $_[1],
                    'max'               =>  $_[3]
            );
        }
	],
	[#Rule 208
		 'string_type', 1,
sub
#line 1237 "Parser22.yp"
{
            new CORBA::IDL::StringType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 209
		 'string_type', 4,
sub
#line 1243 "Parser22.yp"
{
            $_[0]->Error("Expression expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 210
		 'wide_string_type', 4,
sub
#line 1252 "Parser22.yp"
{
            new CORBA::IDL::WideStringType($_[0],
                    'value'             =>  $_[1],
                    'max'               =>  $_[3]
            );
        }
	],
	[#Rule 211
		 'wide_string_type', 1,
sub
#line 1259 "Parser22.yp"
{
            new CORBA::IDL::WideStringType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 212
		 'wide_string_type', 4,
sub
#line 1265 "Parser22.yp"
{
            $_[0]->Error("Expression expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 213
		 'array_declarator', 2,
sub
#line 1274 "Parser22.yp"
{
            unshift @{$_[2]}, $_[1];
            $_[2];
        }
	],
	[#Rule 214
		 'fixed_array_sizes', 1,
sub
#line 1282 "Parser22.yp"
{
            [$_[1]];
        }
	],
	[#Rule 215
		 'fixed_array_sizes', 2,
sub
#line 1286 "Parser22.yp"
{
            unshift @{$_[2]}, $_[1];
            $_[2];
        }
	],
	[#Rule 216
		 'fixed_array_size', 3,
sub
#line 1295 "Parser22.yp"
{
            $_[2];
        }
	],
	[#Rule 217
		 'fixed_array_size', 3,
sub
#line 1299 "Parser22.yp"
{
            $_[0]->Error("Expression expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 218
		 'attr_dcl', 4,
sub
#line 1308 "Parser22.yp"
{
            new CORBA::IDL::Attributes($_[0],
                    'modifier'          =>  $_[1],
                    'type'              =>  $_[3],
                    'list_expr'         =>  $_[4]
            );
        }
	],
	[#Rule 219
		 'attr_dcl', 3,
sub
#line 1316 "Parser22.yp"
{
            $_[0]->Error("type expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 220
		 'attr_mod', 1, undef
	],
	[#Rule 221
		 'attr_mod', 0, undef
	],
	[#Rule 222
		 'simple_declarators', 1,
sub
#line 1331 "Parser22.yp"
{
            [$_[1]];
        }
	],
	[#Rule 223
		 'simple_declarators', 3,
sub
#line 1335 "Parser22.yp"
{
            unshift @{$_[3]}, $_[1];
            $_[3];
        }
	],
	[#Rule 224
		 'except_dcl', 3,
sub
#line 1344 "Parser22.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[1];
        }
	],
	[#Rule 225
		 'except_dcl', 4,
sub
#line 1349 "Parser22.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[1]->Configure($_[0],
                    'list_expr'         =>  $_[3]
            ) if (defined $_[1]);
        }
	],
	[#Rule 226
		 'except_dcl', 4,
sub
#line 1356 "Parser22.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->Error("'members expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 227
		 'except_dcl', 2,
sub
#line 1363 "Parser22.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->Error("'\x7b' expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 228
		 'exception_header', 2,
sub
#line 1373 "Parser22.yp"
{
            new CORBA::IDL::Exception($_[0],
                    'idf'               =>  $_[2],
            );
        }
	],
	[#Rule 229
		 'exception_header', 2,
sub
#line 1379 "Parser22.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 230
		 'op_dcl', 4,
sub
#line 1388 "Parser22.yp"
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
	[#Rule 231
		 'op_dcl', 2,
sub
#line 1398 "Parser22.yp"
{
            delete $_[0]->YYData->{unnamed_symbtab}
                    if (exists $_[0]->YYData->{unnamed_symbtab});
            $_[0]->Error("parameters declaration expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 232
		 'op_header', 3,
sub
#line 1409 "Parser22.yp"
{
            new CORBA::IDL::Operation($_[0],
                    'modifier'          =>  $_[1],
                    'type'              =>  $_[2],
                    'idf'               =>  $_[3]
            );
        }
	],
	[#Rule 233
		 'op_header', 3,
sub
#line 1417 "Parser22.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 234
		 'op_mod', 1, undef
	],
	[#Rule 235
		 'op_mod', 0, undef
	],
	[#Rule 236
		 'op_attribute', 1, undef
	],
	[#Rule 237
		 'op_type_spec', 1, undef
	],
	[#Rule 238
		 'op_type_spec', 1,
sub
#line 1441 "Parser22.yp"
{
            new CORBA::IDL::VoidType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 239
		 'op_type_spec', 1,
sub
#line 1447 "Parser22.yp"
{
            $_[0]->Error("op_type_spec expected.\n");
            $_[1];                      #default action
        }
	],
	[#Rule 240
		 'parameter_dcls', 3,
sub
#line 1456 "Parser22.yp"
{
            $_[2];
        }
	],
	[#Rule 241
		 'parameter_dcls', 5,
sub
#line 1460 "Parser22.yp"
{
            $_[0]->Error("'...' unexpected.\n");
            $_[2];
        }
	],
	[#Rule 242
		 'parameter_dcls', 4,
sub
#line 1465 "Parser22.yp"
{
            $_[0]->Warning("',' unexpected.\n");
            $_[2];
        }
	],
	[#Rule 243
		 'parameter_dcls', 2,
sub
#line 1470 "Parser22.yp"
{
            undef;
        }
	],
	[#Rule 244
		 'parameter_dcls', 3,
sub
#line 1474 "Parser22.yp"
{
            $_[0]->Error("'...' unexpected.\n");
            undef;
        }
	],
	[#Rule 245
		 'parameter_dcls', 3,
sub
#line 1479 "Parser22.yp"
{
            $_[0]->Error("parameters declaration expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 246
		 'param_dcls', 1,
sub
#line 1487 "Parser22.yp"
{
            [$_[1]];
        }
	],
	[#Rule 247
		 'param_dcls', 3,
sub
#line 1491 "Parser22.yp"
{
            push @{$_[1]}, $_[3];
            $_[1];
        }
	],
	[#Rule 248
		 'param_dcls', 2,
sub
#line 1496 "Parser22.yp"
{
            $_[0]->Error("';' unexpected.\n");
            [$_[1]];
        }
	],
	[#Rule 249
		 'param_dcl', 3,
sub
#line 1505 "Parser22.yp"
{
            new CORBA::IDL::Parameter($_[0],
                    'attr'              =>  $_[1],
                    'type'              =>  $_[2],
                    'idf'               =>  $_[3]
            );
        }
	],
	[#Rule 250
		 'param_attribute', 1, undef
	],
	[#Rule 251
		 'param_attribute', 1, undef
	],
	[#Rule 252
		 'param_attribute', 1, undef
	],
	[#Rule 253
		 'param_attribute', 0,
sub
#line 1523 "Parser22.yp"
{
            $_[0]->Error("(in|out|inout) expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 254
		 'raises_expr', 4,
sub
#line 1532 "Parser22.yp"
{
            $_[3];
        }
	],
	[#Rule 255
		 'raises_expr', 4,
sub
#line 1536 "Parser22.yp"
{
            $_[0]->Error("name expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 256
		 'raises_expr', 2,
sub
#line 1541 "Parser22.yp"
{
            $_[0]->Error("'(' expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 257
		 'raises_expr', 0, undef
	],
	[#Rule 258
		 'exception_names', 1,
sub
#line 1551 "Parser22.yp"
{
            [$_[1]];
        }
	],
	[#Rule 259
		 'exception_names', 3,
sub
#line 1555 "Parser22.yp"
{
            unshift @{$_[3]}, $_[1];
            $_[3];
        }
	],
	[#Rule 260
		 'exception_name', 1,
sub
#line 1563 "Parser22.yp"
{
            CORBA::IDL::Exception->Lookup($_[0], $_[1]);
        }
	],
	[#Rule 261
		 'context_expr', 4,
sub
#line 1571 "Parser22.yp"
{
            $_[3];
        }
	],
	[#Rule 262
		 'context_expr', 4,
sub
#line 1575 "Parser22.yp"
{
            $_[0]->Error("string expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 263
		 'context_expr', 2,
sub
#line 1580 "Parser22.yp"
{
            $_[0]->Error("'(' expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 264
		 'context_expr', 0, undef
	],
	[#Rule 265
		 'string_literals', 1,
sub
#line 1590 "Parser22.yp"
{
            [$_[1]];
        }
	],
	[#Rule 266
		 'string_literals', 3,
sub
#line 1594 "Parser22.yp"
{
            unshift @{$_[3]}, $_[1];
            $_[3];
        }
	],
	[#Rule 267
		 'param_type_spec', 1, undef
	],
	[#Rule 268
		 'param_type_spec', 1,
sub
#line 1605 "Parser22.yp"
{
            $_[0]->Error("param_type_spec expected.\n");
            $_[1];                      #default action
        }
	],
	[#Rule 269
		 'param_type_spec', 1,
sub
#line 1610 "Parser22.yp"
{
            $_[0]->Error("param_type_spec expected.\n");
            $_[1];                      #default action
        }
	],
	[#Rule 270
		 'param_type_spec', 1,
sub
#line 1615 "Parser22.yp"
{
            $_[0]->Error("param_type_spec expected.\n");
            $_[1];                      #default action
        }
	],
	[#Rule 271
		 'op_param_type_spec', 1, undef
	],
	[#Rule 272
		 'op_param_type_spec', 1, undef
	],
	[#Rule 273
		 'op_param_type_spec', 1, undef
	],
	[#Rule 274
		 'op_param_type_spec', 1, undef
	],
	[#Rule 275
		 'op_param_type_spec', 1,
sub
#line 1631 "Parser22.yp"
{
            CORBA::IDL::TypeDeclarator->Lookup($_[0], $_[1]);
        }
	],
	[#Rule 276
		 'fixed_pt_type', 6,
sub
#line 1639 "Parser22.yp"
{
            new CORBA::IDL::FixedPtType($_[0],
                    'value'             =>  $_[1],
                    'd'                 =>  $_[3],
                    's'                 =>  $_[5]
            );
        }
	],
	[#Rule 277
		 'fixed_pt_type', 6,
sub
#line 1647 "Parser22.yp"
{
            $_[0]->Error("Expression expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 278
		 'fixed_pt_type', 4,
sub
#line 1652 "Parser22.yp"
{
            $_[0]->Error("Expression expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 279
		 'fixed_pt_type', 2,
sub
#line 1657 "Parser22.yp"
{
            $_[0]->Error("'<' expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 280
		 'fixed_pt_const_type', 1,
sub
#line 1666 "Parser22.yp"
{
            new CORBA::IDL::FixedPtConstType($_[0],
                    'value'             =>  $_[1]
            );
        }
	]
],
                                  @_);
    bless($self,$class);
}

#line 1673 "Parser22.yp"


use warnings;

our $VERSION = '2.61';
our $IDL_VERSION = '2.2';

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
