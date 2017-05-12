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
		DEFAULT => -105
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
		DEFAULT => -104
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
			"::" => 72,
			'ENUM' => 2,
			'CHAR' => 73,
			'OBJECT' => 77,
			'STRING' => 80,
			'OCTET' => 49,
			'WSTRING' => 82,
			'UNION' => 10,
			'UNSIGNED' => 51,
			'error' => 84,
			'ANY' => 52,
			'FLOAT' => 86,
			'LONG' => 54,
			'SEQUENCE' => 87,
			'IDENTIFIER' => 59,
			'DOUBLE' => 88,
			'SHORT' => 89,
			'BOOLEAN' => 91,
			'STRUCT' => 24,
			'VOID' => 64,
			'FIXED' => 94,
			'WCHAR' => 69
		},
		GOTOS => {
			'union_type' => 47,
			'enum_header' => 4,
			'unsigned_short_int' => 48,
			'struct_type' => 50,
			'union_header' => 9,
			'struct_header' => 13,
			'type_declarator' => 53,
			'signed_longlong_int' => 55,
			'enum_type' => 56,
			'any_type' => 57,
			'template_type_spec' => 58,
			'unsigned_long_int' => 60,
			'scoped_name' => 61,
			'string_type' => 62,
			'char_type' => 63,
			'fixed_pt_type' => 67,
			'signed_short_int' => 66,
			'signed_long_int' => 65,
			'wide_char_type' => 68,
			'octet_type' => 70,
			'wide_string_type' => 71,
			'object_type' => 74,
			'type_spec' => 75,
			'integer_type' => 76,
			'sequence_type' => 78,
			'unsigned_int' => 79,
			'unsigned_longlong_int' => 81,
			'constr_type_spec' => 83,
			'floating_pt_type' => 85,
			'base_type_spec' => 90,
			'signed_int' => 92,
			'simple_type_spec' => 93,
			'boolean_type' => 95
		}
	},
	{#State 15
		ACTIONS => {
			'IDENTIFIER' => 96,
			'error' => 97
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
			'check_semicolon' => 98
		}
	},
	{#State 18
		ACTIONS => {
			";" => 43,
			'error' => 44
		},
		GOTOS => {
			'check_semicolon' => 99
		}
	},
	{#State 19
		ACTIONS => {
			"{" => 100
		}
	},
	{#State 20
		ACTIONS => {
			";" => 43,
			'error' => 44
		},
		GOTOS => {
			'check_semicolon' => 101
		}
	},
	{#State 21
		DEFAULT => -106
	},
	{#State 22
		ACTIONS => {
			'error' => 102
		}
	},
	{#State 23
		ACTIONS => {
			'IDENTIFIER' => 103,
			'error' => 104
		}
	},
	{#State 24
		ACTIONS => {
			'IDENTIFIER' => 105,
			'error' => 106
		}
	},
	{#State 25
		ACTIONS => {
			'DOUBLE' => 88,
			"::" => 72,
			'IDENTIFIER' => 59,
			'SHORT' => 89,
			'CHAR' => 73,
			'BOOLEAN' => 91,
			'STRING' => 80,
			'WSTRING' => 82,
			'UNSIGNED' => 51,
			'FIXED' => 117,
			'error' => 114,
			'FLOAT' => 86,
			'LONG' => 54,
			'WCHAR' => 69
		},
		GOTOS => {
			'wide_string_type' => 111,
			'integer_type' => 112,
			'unsigned_int' => 79,
			'unsigned_short_int' => 48,
			'unsigned_longlong_int' => 81,
			'floating_pt_type' => 113,
			'const_type' => 115,
			'signed_longlong_int' => 55,
			'unsigned_long_int' => 60,
			'scoped_name' => 107,
			'string_type' => 108,
			'signed_int' => 92,
			'fixed_pt_const_type' => 116,
			'char_type' => 109,
			'signed_short_int' => 66,
			'signed_long_int' => 65,
			'boolean_type' => 118,
			'wide_char_type' => 110
		}
	},
	{#State 26
		ACTIONS => {
			"{" => 120,
			'error' => 119
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
			'check_semicolon' => 121
		}
	},
	{#State 29
		DEFAULT => -20
	},
	{#State 30
		DEFAULT => -195
	},
	{#State 31
		DEFAULT => -194
	},
	{#State 32
		ACTIONS => {
			"{" => -28
		},
		DEFAULT => -26
	},
	{#State 33
		ACTIONS => {
			":" => 122,
			"{" => -39
		},
		DEFAULT => -25,
		GOTOS => {
			'interface_inheritance_spec' => 123
		}
	},
	{#State 34
		DEFAULT => -193
	},
	{#State 35
		ACTIONS => {
			'IDENTIFIER' => 124,
			'error' => 126
		},
		GOTOS => {
			'enumerators' => 127,
			'enumerator' => 125
		}
	},
	{#State 36
		ACTIONS => {
			"}" => 128
		}
	},
	{#State 37
		ACTIONS => {
			"}" => 129,
			'INTERFACE' => 3,
			'ENUM' => 2,
			'IDENTIFIER' => 22,
			'MODULE' => 23,
			'CONST' => 25,
			'STRUCT' => 24,
			'UNION' => 10,
			'TYPEDEF' => 14,
			'error' => 131,
			'EXCEPTION' => 15
		},
		GOTOS => {
			'union_type' => 1,
			'enum_header' => 4,
			'definitions' => 130,
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
			"(" => 132,
			'error' => 133
		}
	},
	{#State 40
		DEFAULT => -174
	},
	{#State 41
		DEFAULT => -173
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
			"::" => 72,
			'ENUM' => 2,
			'CHAR' => 73,
			'OBJECT' => 77,
			'STRING' => 80,
			'OCTET' => 49,
			'WSTRING' => 82,
			'UNION' => 10,
			'UNSIGNED' => 51,
			'error' => 137,
			'ANY' => 52,
			'FLOAT' => 86,
			'LONG' => 54,
			'SEQUENCE' => 87,
			'IDENTIFIER' => 59,
			'DOUBLE' => 88,
			'SHORT' => 89,
			'BOOLEAN' => 91,
			'STRUCT' => 24,
			'VOID' => 64,
			'FIXED' => 94,
			'WCHAR' => 69
		},
		GOTOS => {
			'union_type' => 47,
			'enum_header' => 4,
			'unsigned_short_int' => 48,
			'struct_type' => 50,
			'union_header' => 9,
			'struct_header' => 13,
			'member_list' => 134,
			'signed_longlong_int' => 55,
			'enum_type' => 56,
			'any_type' => 57,
			'template_type_spec' => 58,
			'member' => 135,
			'unsigned_long_int' => 60,
			'scoped_name' => 61,
			'string_type' => 62,
			'char_type' => 63,
			'fixed_pt_type' => 67,
			'signed_short_int' => 66,
			'signed_long_int' => 65,
			'wide_char_type' => 68,
			'octet_type' => 70,
			'wide_string_type' => 71,
			'object_type' => 74,
			'type_spec' => 136,
			'integer_type' => 76,
			'unsigned_int' => 79,
			'sequence_type' => 78,
			'unsigned_longlong_int' => 81,
			'constr_type_spec' => 83,
			'floating_pt_type' => 85,
			'base_type_spec' => 90,
			'signed_int' => 92,
			'simple_type_spec' => 93,
			'boolean_type' => 95
		}
	},
	{#State 47
		DEFAULT => -128
	},
	{#State 48
		DEFAULT => -149
	},
	{#State 49
		DEFAULT => -158
	},
	{#State 50
		DEFAULT => -127
	},
	{#State 51
		ACTIONS => {
			'SHORT' => 139,
			'LONG' => 138
		}
	},
	{#State 52
		DEFAULT => -159
	},
	{#State 53
		DEFAULT => -103
	},
	{#State 54
		ACTIONS => {
			'DOUBLE' => 141,
			'LONG' => 140
		},
		DEFAULT => -147
	},
	{#State 55
		DEFAULT => -145
	},
	{#State 56
		DEFAULT => -129
	},
	{#State 57
		DEFAULT => -121
	},
	{#State 58
		DEFAULT => -112
	},
	{#State 59
		DEFAULT => -43
	},
	{#State 60
		DEFAULT => -150
	},
	{#State 61
		ACTIONS => {
			"::" => 142
		},
		DEFAULT => -113
	},
	{#State 62
		DEFAULT => -124
	},
	{#State 63
		DEFAULT => -117
	},
	{#State 64
		DEFAULT => -114
	},
	{#State 65
		DEFAULT => -144
	},
	{#State 66
		DEFAULT => -143
	},
	{#State 67
		DEFAULT => -126
	},
	{#State 68
		DEFAULT => -118
	},
	{#State 69
		DEFAULT => -156
	},
	{#State 70
		DEFAULT => -120
	},
	{#State 71
		DEFAULT => -125
	},
	{#State 72
		ACTIONS => {
			'IDENTIFIER' => 143,
			'error' => 144
		}
	},
	{#State 73
		DEFAULT => -155
	},
	{#State 74
		DEFAULT => -122
	},
	{#State 75
		ACTIONS => {
			'IDENTIFIER' => 146,
			'error' => 148
		},
		GOTOS => {
			'declarators' => 149,
			'array_declarator' => 150,
			'simple_declarator' => 145,
			'declarator' => 147,
			'complex_declarator' => 151
		}
	},
	{#State 76
		DEFAULT => -116
	},
	{#State 77
		DEFAULT => -160
	},
	{#State 78
		DEFAULT => -123
	},
	{#State 79
		DEFAULT => -142
	},
	{#State 80
		ACTIONS => {
			"<" => 152
		},
		DEFAULT => -207
	},
	{#State 81
		DEFAULT => -151
	},
	{#State 82
		ACTIONS => {
			"<" => 153
		},
		DEFAULT => -210
	},
	{#State 83
		DEFAULT => -110
	},
	{#State 84
		DEFAULT => -107
	},
	{#State 85
		DEFAULT => -115
	},
	{#State 86
		DEFAULT => -138
	},
	{#State 87
		ACTIONS => {
			"<" => 154,
			'error' => 155
		}
	},
	{#State 88
		DEFAULT => -139
	},
	{#State 89
		DEFAULT => -146
	},
	{#State 90
		DEFAULT => -111
	},
	{#State 91
		DEFAULT => -157
	},
	{#State 92
		DEFAULT => -141
	},
	{#State 93
		DEFAULT => -109
	},
	{#State 94
		ACTIONS => {
			"<" => 156,
			'error' => 157
		}
	},
	{#State 95
		DEFAULT => -119
	},
	{#State 96
		DEFAULT => -227
	},
	{#State 97
		DEFAULT => -228
	},
	{#State 98
		DEFAULT => -9
	},
	{#State 99
		DEFAULT => -6
	},
	{#State 100
		ACTIONS => {
			"}" => 158,
			"::" => -234,
			'ENUM' => 2,
			'CHAR' => -234,
			'OBJECT' => -234,
			'STRING' => -234,
			'OCTET' => -234,
			'ONEWAY' => 169,
			'WSTRING' => -234,
			'UNION' => 10,
			'UNSIGNED' => -234,
			'TYPEDEF' => 14,
			'error' => 172,
			'EXCEPTION' => 15,
			'ANY' => -234,
			'FLOAT' => -234,
			'LONG' => -234,
			'ATTRIBUTE' => -220,
			'SEQUENCE' => -234,
			'IDENTIFIER' => -234,
			'DOUBLE' => -234,
			'SHORT' => -234,
			'BOOLEAN' => -234,
			'STRUCT' => 24,
			'CONST' => 25,
			'READONLY' => 173,
			'VOID' => -234,
			'FIXED' => -234,
			'WCHAR' => -234
		},
		GOTOS => {
			'op_header' => 166,
			'union_type' => 1,
			'interface_body' => 167,
			'attr_mod' => 159,
			'enum_header' => 4,
			'op_dcl' => 168,
			'exports' => 171,
			'attr_dcl' => 170,
			'struct_type' => 6,
			'union_header' => 9,
			'except_dcl' => 160,
			'struct_header' => 13,
			'export' => 162,
			'type_dcl' => 161,
			'enum_type' => 21,
			'op_attribute' => 163,
			'op_mod' => 164,
			'exception_header' => 26,
			'const_dcl' => 165
		}
	},
	{#State 101
		DEFAULT => -10
	},
	{#State 102
		ACTIONS => {
			";" => 174
		}
	},
	{#State 103
		DEFAULT => -18
	},
	{#State 104
		DEFAULT => -19
	},
	{#State 105
		DEFAULT => -163
	},
	{#State 106
		DEFAULT => -164
	},
	{#State 107
		ACTIONS => {
			"::" => 142
		},
		DEFAULT => -61
	},
	{#State 108
		DEFAULT => -58
	},
	{#State 109
		DEFAULT => -54
	},
	{#State 110
		DEFAULT => -55
	},
	{#State 111
		DEFAULT => -59
	},
	{#State 112
		DEFAULT => -53
	},
	{#State 113
		DEFAULT => -57
	},
	{#State 114
		DEFAULT => -52
	},
	{#State 115
		ACTIONS => {
			'IDENTIFIER' => 175,
			'error' => 176
		}
	},
	{#State 116
		DEFAULT => -60
	},
	{#State 117
		DEFAULT => -279
	},
	{#State 118
		DEFAULT => -56
	},
	{#State 119
		DEFAULT => -226
	},
	{#State 120
		ACTIONS => {
			"}" => 177,
			"::" => 72,
			'ENUM' => 2,
			'CHAR' => 73,
			'OBJECT' => 77,
			'STRING' => 80,
			'OCTET' => 49,
			'WSTRING' => 82,
			'UNION' => 10,
			'UNSIGNED' => 51,
			'error' => 179,
			'ANY' => 52,
			'FLOAT' => 86,
			'LONG' => 54,
			'SEQUENCE' => 87,
			'DOUBLE' => 88,
			'IDENTIFIER' => 59,
			'SHORT' => 89,
			'BOOLEAN' => 91,
			'STRUCT' => 24,
			'VOID' => 64,
			'FIXED' => 94,
			'WCHAR' => 69
		},
		GOTOS => {
			'union_type' => 47,
			'enum_header' => 4,
			'unsigned_short_int' => 48,
			'struct_type' => 50,
			'union_header' => 9,
			'struct_header' => 13,
			'member_list' => 178,
			'signed_longlong_int' => 55,
			'enum_type' => 56,
			'any_type' => 57,
			'template_type_spec' => 58,
			'member' => 135,
			'unsigned_long_int' => 60,
			'scoped_name' => 61,
			'string_type' => 62,
			'char_type' => 63,
			'fixed_pt_type' => 67,
			'signed_short_int' => 66,
			'signed_long_int' => 65,
			'wide_char_type' => 68,
			'octet_type' => 70,
			'wide_string_type' => 71,
			'object_type' => 74,
			'type_spec' => 136,
			'integer_type' => 76,
			'unsigned_int' => 79,
			'sequence_type' => 78,
			'unsigned_longlong_int' => 81,
			'constr_type_spec' => 83,
			'floating_pt_type' => 85,
			'base_type_spec' => 90,
			'signed_int' => 92,
			'simple_type_spec' => 93,
			'boolean_type' => 95
		}
	},
	{#State 121
		DEFAULT => -7
	},
	{#State 122
		ACTIONS => {
			"::" => 72,
			'IDENTIFIER' => 59,
			'error' => 181
		},
		GOTOS => {
			'interface_name' => 183,
			'interface_names' => 182,
			'scoped_name' => 180
		}
	},
	{#State 123
		DEFAULT => -27
	},
	{#State 124
		DEFAULT => -200
	},
	{#State 125
		ACTIONS => {
			";" => 184,
			"," => 185
		},
		DEFAULT => -196
	},
	{#State 126
		ACTIONS => {
			"}" => 186
		}
	},
	{#State 127
		ACTIONS => {
			"}" => 187
		}
	},
	{#State 128
		DEFAULT => -17
	},
	{#State 129
		DEFAULT => -16
	},
	{#State 130
		ACTIONS => {
			"}" => 188
		}
	},
	{#State 131
		ACTIONS => {
			"}" => 189
		}
	},
	{#State 132
		ACTIONS => {
			"::" => 72,
			'ENUM' => 2,
			'IDENTIFIER' => 59,
			'SHORT' => 89,
			'CHAR' => 73,
			'BOOLEAN' => 91,
			'UNSIGNED' => 51,
			'error' => 195,
			'LONG' => 190
		},
		GOTOS => {
			'signed_longlong_int' => 55,
			'enum_type' => 191,
			'integer_type' => 194,
			'unsigned_long_int' => 60,
			'unsigned_int' => 79,
			'scoped_name' => 192,
			'enum_header' => 4,
			'signed_int' => 92,
			'unsigned_short_int' => 48,
			'unsigned_longlong_int' => 81,
			'char_type' => 193,
			'signed_long_int' => 65,
			'signed_short_int' => 66,
			'boolean_type' => 197,
			'switch_type_spec' => 196
		}
	},
	{#State 133
		DEFAULT => -172
	},
	{#State 134
		ACTIONS => {
			"}" => 198
		}
	},
	{#State 135
		ACTIONS => {
			"::" => 72,
			'ENUM' => 2,
			'CHAR' => 73,
			'OBJECT' => 77,
			'STRING' => 80,
			'OCTET' => 49,
			'WSTRING' => 82,
			'UNION' => 10,
			'UNSIGNED' => 51,
			'ANY' => 52,
			'FLOAT' => 86,
			'LONG' => 54,
			'SEQUENCE' => 87,
			'DOUBLE' => 88,
			'IDENTIFIER' => 59,
			'SHORT' => 89,
			'BOOLEAN' => 91,
			'STRUCT' => 24,
			'VOID' => 64,
			'FIXED' => 94,
			'WCHAR' => 69
		},
		DEFAULT => -165,
		GOTOS => {
			'union_type' => 47,
			'enum_header' => 4,
			'unsigned_short_int' => 48,
			'struct_type' => 50,
			'union_header' => 9,
			'struct_header' => 13,
			'member_list' => 199,
			'signed_longlong_int' => 55,
			'enum_type' => 56,
			'any_type' => 57,
			'template_type_spec' => 58,
			'member' => 135,
			'unsigned_long_int' => 60,
			'scoped_name' => 61,
			'string_type' => 62,
			'char_type' => 63,
			'fixed_pt_type' => 67,
			'signed_short_int' => 66,
			'signed_long_int' => 65,
			'wide_char_type' => 68,
			'octet_type' => 70,
			'wide_string_type' => 71,
			'object_type' => 74,
			'type_spec' => 136,
			'integer_type' => 76,
			'unsigned_int' => 79,
			'sequence_type' => 78,
			'unsigned_longlong_int' => 81,
			'constr_type_spec' => 83,
			'floating_pt_type' => 85,
			'base_type_spec' => 90,
			'signed_int' => 92,
			'simple_type_spec' => 93,
			'boolean_type' => 95
		}
	},
	{#State 136
		ACTIONS => {
			'IDENTIFIER' => 146,
			'error' => 148
		},
		GOTOS => {
			'declarators' => 200,
			'array_declarator' => 150,
			'simple_declarator' => 145,
			'declarator' => 147,
			'complex_declarator' => 151
		}
	},
	{#State 137
		ACTIONS => {
			"}" => 201
		}
	},
	{#State 138
		ACTIONS => {
			'LONG' => 202
		},
		DEFAULT => -153
	},
	{#State 139
		DEFAULT => -152
	},
	{#State 140
		DEFAULT => -148
	},
	{#State 141
		DEFAULT => -140
	},
	{#State 142
		ACTIONS => {
			'IDENTIFIER' => 203,
			'error' => 204
		}
	},
	{#State 143
		DEFAULT => -44
	},
	{#State 144
		DEFAULT => -45
	},
	{#State 145
		DEFAULT => -132
	},
	{#State 146
		ACTIONS => {
			"[" => 206
		},
		DEFAULT => -134,
		GOTOS => {
			'fixed_array_sizes' => 205,
			'fixed_array_size' => 207
		}
	},
	{#State 147
		ACTIONS => {
			"," => 208
		},
		DEFAULT => -130
	},
	{#State 148
		ACTIONS => {
			";" => 209,
			"," => 210
		}
	},
	{#State 149
		DEFAULT => -108
	},
	{#State 150
		DEFAULT => -137
	},
	{#State 151
		DEFAULT => -133
	},
	{#State 152
		ACTIONS => {
			"-" => 211,
			"::" => 72,
			'TRUE' => 224,
			"+" => 225,
			"~" => 212,
			'INTEGER_LITERAL' => 226,
			'FLOATING_PT_LITERAL' => 228,
			'FALSE' => 214,
			'error' => 229,
			'WIDE_STRING_LITERAL' => 230,
			'CHARACTER_LITERAL' => 231,
			'IDENTIFIER' => 59,
			"(" => 221,
			'FIXED_PT_LITERAL' => 235,
			'STRING_LITERAL' => 238,
			'WIDE_CHARACTER_LITERAL' => 223
		},
		GOTOS => {
			'shift_expr' => 227,
			'literal' => 213,
			'const_exp' => 215,
			'unary_operator' => 216,
			'string_literal' => 217,
			'and_expr' => 218,
			'or_expr' => 219,
			'mult_expr' => 232,
			'scoped_name' => 220,
			'boolean_literal' => 233,
			'add_expr' => 234,
			'positive_int_const' => 236,
			'unary_expr' => 222,
			'primary_expr' => 237,
			'wide_string_literal' => 239,
			'xor_expr' => 240
		}
	},
	{#State 153
		ACTIONS => {
			"-" => 211,
			"::" => 72,
			'TRUE' => 224,
			"+" => 225,
			"~" => 212,
			'INTEGER_LITERAL' => 226,
			'FLOATING_PT_LITERAL' => 228,
			'FALSE' => 214,
			'error' => 241,
			'WIDE_STRING_LITERAL' => 230,
			'CHARACTER_LITERAL' => 231,
			'IDENTIFIER' => 59,
			"(" => 221,
			'FIXED_PT_LITERAL' => 235,
			'STRING_LITERAL' => 238,
			'WIDE_CHARACTER_LITERAL' => 223
		},
		GOTOS => {
			'shift_expr' => 227,
			'literal' => 213,
			'const_exp' => 215,
			'unary_operator' => 216,
			'string_literal' => 217,
			'and_expr' => 218,
			'or_expr' => 219,
			'mult_expr' => 232,
			'scoped_name' => 220,
			'boolean_literal' => 233,
			'add_expr' => 234,
			'positive_int_const' => 242,
			'unary_expr' => 222,
			'primary_expr' => 237,
			'wide_string_literal' => 239,
			'xor_expr' => 240
		}
	},
	{#State 154
		ACTIONS => {
			"::" => 72,
			'CHAR' => 73,
			'OBJECT' => 77,
			'STRING' => 80,
			'OCTET' => 49,
			'WSTRING' => 82,
			'UNSIGNED' => 51,
			'error' => 243,
			'ANY' => 52,
			'FLOAT' => 86,
			'LONG' => 54,
			'SEQUENCE' => 87,
			'IDENTIFIER' => 59,
			'DOUBLE' => 88,
			'SHORT' => 89,
			'BOOLEAN' => 91,
			'VOID' => 64,
			'FIXED' => 94,
			'WCHAR' => 69
		},
		GOTOS => {
			'wide_string_type' => 71,
			'object_type' => 74,
			'integer_type' => 76,
			'sequence_type' => 78,
			'unsigned_int' => 79,
			'unsigned_short_int' => 48,
			'unsigned_longlong_int' => 81,
			'floating_pt_type' => 85,
			'signed_longlong_int' => 55,
			'any_type' => 57,
			'template_type_spec' => 58,
			'base_type_spec' => 90,
			'unsigned_long_int' => 60,
			'scoped_name' => 61,
			'signed_int' => 92,
			'string_type' => 62,
			'simple_type_spec' => 244,
			'char_type' => 63,
			'signed_short_int' => 66,
			'signed_long_int' => 65,
			'fixed_pt_type' => 67,
			'boolean_type' => 95,
			'wide_char_type' => 68,
			'octet_type' => 70
		}
	},
	{#State 155
		DEFAULT => -205
	},
	{#State 156
		ACTIONS => {
			"-" => 211,
			"::" => 72,
			'TRUE' => 224,
			"+" => 225,
			"~" => 212,
			'INTEGER_LITERAL' => 226,
			'FLOATING_PT_LITERAL' => 228,
			'FALSE' => 214,
			'error' => 245,
			'WIDE_STRING_LITERAL' => 230,
			'CHARACTER_LITERAL' => 231,
			'IDENTIFIER' => 59,
			"(" => 221,
			'FIXED_PT_LITERAL' => 235,
			'STRING_LITERAL' => 238,
			'WIDE_CHARACTER_LITERAL' => 223
		},
		GOTOS => {
			'shift_expr' => 227,
			'literal' => 213,
			'const_exp' => 215,
			'unary_operator' => 216,
			'string_literal' => 217,
			'and_expr' => 218,
			'or_expr' => 219,
			'mult_expr' => 232,
			'scoped_name' => 220,
			'boolean_literal' => 233,
			'add_expr' => 234,
			'positive_int_const' => 246,
			'unary_expr' => 222,
			'primary_expr' => 237,
			'wide_string_literal' => 239,
			'xor_expr' => 240
		}
	},
	{#State 157
		DEFAULT => -278
	},
	{#State 158
		DEFAULT => -22
	},
	{#State 159
		ACTIONS => {
			'ATTRIBUTE' => 247
		}
	},
	{#State 160
		ACTIONS => {
			";" => 43,
			'error' => 44
		},
		GOTOS => {
			'check_semicolon' => 248
		}
	},
	{#State 161
		ACTIONS => {
			";" => 43,
			'error' => 44
		},
		GOTOS => {
			'check_semicolon' => 249
		}
	},
	{#State 162
		ACTIONS => {
			"}" => -30,
			'ENUM' => 2,
			'ONEWAY' => 169,
			'UNION' => 10,
			'TYPEDEF' => 14,
			'EXCEPTION' => 15,
			'ATTRIBUTE' => -220,
			'STRUCT' => 24,
			'CONST' => 25,
			'READONLY' => 173
		},
		DEFAULT => -234,
		GOTOS => {
			'op_header' => 166,
			'union_type' => 1,
			'attr_mod' => 159,
			'enum_header' => 4,
			'op_dcl' => 168,
			'exports' => 250,
			'attr_dcl' => 170,
			'struct_type' => 6,
			'union_header' => 9,
			'except_dcl' => 160,
			'struct_header' => 13,
			'export' => 162,
			'type_dcl' => 161,
			'enum_type' => 21,
			'op_attribute' => 163,
			'op_mod' => 164,
			'exception_header' => 26,
			'const_dcl' => 165
		}
	},
	{#State 163
		DEFAULT => -233
	},
	{#State 164
		ACTIONS => {
			"::" => 72,
			'CHAR' => 73,
			'OBJECT' => 77,
			'STRING' => 80,
			'OCTET' => 49,
			'WSTRING' => 82,
			'UNSIGNED' => 51,
			'ANY' => 52,
			'FLOAT' => 86,
			'LONG' => 54,
			'SEQUENCE' => 87,
			'IDENTIFIER' => 59,
			'DOUBLE' => 88,
			'SHORT' => 89,
			'BOOLEAN' => 91,
			'VOID' => 253,
			'FIXED' => 94,
			'WCHAR' => 69
		},
		GOTOS => {
			'wide_string_type' => 255,
			'object_type' => 74,
			'integer_type' => 76,
			'unsigned_int' => 79,
			'sequence_type' => 256,
			'op_param_type_spec' => 257,
			'unsigned_short_int' => 48,
			'unsigned_longlong_int' => 81,
			'floating_pt_type' => 85,
			'signed_longlong_int' => 55,
			'any_type' => 57,
			'base_type_spec' => 258,
			'unsigned_long_int' => 60,
			'scoped_name' => 251,
			'signed_int' => 92,
			'string_type' => 252,
			'char_type' => 63,
			'signed_long_int' => 65,
			'fixed_pt_type' => 254,
			'signed_short_int' => 66,
			'op_type_spec' => 259,
			'boolean_type' => 95,
			'wide_char_type' => 68,
			'octet_type' => 70
		}
	},
	{#State 165
		ACTIONS => {
			";" => 43,
			'error' => 44
		},
		GOTOS => {
			'check_semicolon' => 260
		}
	},
	{#State 166
		ACTIONS => {
			"(" => 261,
			'error' => 262
		},
		GOTOS => {
			'parameter_dcls' => 263
		}
	},
	{#State 167
		ACTIONS => {
			"}" => 264
		}
	},
	{#State 168
		ACTIONS => {
			";" => 43,
			'error' => 44
		},
		GOTOS => {
			'check_semicolon' => 265
		}
	},
	{#State 169
		DEFAULT => -235
	},
	{#State 170
		ACTIONS => {
			";" => 43,
			'error' => 44
		},
		GOTOS => {
			'check_semicolon' => 266
		}
	},
	{#State 171
		DEFAULT => -29
	},
	{#State 172
		ACTIONS => {
			"}" => 267
		}
	},
	{#State 173
		DEFAULT => -219
	},
	{#State 174
		DEFAULT => -11
	},
	{#State 175
		ACTIONS => {
			'error' => 268,
			"=" => 269
		}
	},
	{#State 176
		DEFAULT => -51
	},
	{#State 177
		DEFAULT => -223
	},
	{#State 178
		ACTIONS => {
			"}" => 270
		}
	},
	{#State 179
		ACTIONS => {
			"}" => 271
		}
	},
	{#State 180
		ACTIONS => {
			"::" => 142
		},
		DEFAULT => -42
	},
	{#State 181
		DEFAULT => -38
	},
	{#State 182
		DEFAULT => -37
	},
	{#State 183
		ACTIONS => {
			"," => 272
		},
		DEFAULT => -40
	},
	{#State 184
		DEFAULT => -199
	},
	{#State 185
		ACTIONS => {
			'IDENTIFIER' => 124
		},
		DEFAULT => -198,
		GOTOS => {
			'enumerators' => 273,
			'enumerator' => 125
		}
	},
	{#State 186
		DEFAULT => -192
	},
	{#State 187
		DEFAULT => -191
	},
	{#State 188
		DEFAULT => -14
	},
	{#State 189
		DEFAULT => -15
	},
	{#State 190
		ACTIONS => {
			'LONG' => 140
		},
		DEFAULT => -147
	},
	{#State 191
		DEFAULT => -178
	},
	{#State 192
		ACTIONS => {
			"::" => 142
		},
		DEFAULT => -179
	},
	{#State 193
		DEFAULT => -176
	},
	{#State 194
		DEFAULT => -175
	},
	{#State 195
		ACTIONS => {
			")" => 274
		}
	},
	{#State 196
		ACTIONS => {
			")" => 275
		}
	},
	{#State 197
		DEFAULT => -177
	},
	{#State 198
		DEFAULT => -161
	},
	{#State 199
		DEFAULT => -166
	},
	{#State 200
		ACTIONS => {
			";" => 43,
			'error' => 44
		},
		GOTOS => {
			'check_semicolon' => 276
		}
	},
	{#State 201
		DEFAULT => -162
	},
	{#State 202
		DEFAULT => -154
	},
	{#State 203
		DEFAULT => -46
	},
	{#State 204
		DEFAULT => -47
	},
	{#State 205
		DEFAULT => -212
	},
	{#State 206
		ACTIONS => {
			"-" => 211,
			"::" => 72,
			'TRUE' => 224,
			"+" => 225,
			"~" => 212,
			'INTEGER_LITERAL' => 226,
			'FLOATING_PT_LITERAL' => 228,
			'FALSE' => 214,
			'error' => 277,
			'WIDE_STRING_LITERAL' => 230,
			'CHARACTER_LITERAL' => 231,
			'IDENTIFIER' => 59,
			"(" => 221,
			'FIXED_PT_LITERAL' => 235,
			'STRING_LITERAL' => 238,
			'WIDE_CHARACTER_LITERAL' => 223
		},
		GOTOS => {
			'shift_expr' => 227,
			'literal' => 213,
			'const_exp' => 215,
			'unary_operator' => 216,
			'string_literal' => 217,
			'and_expr' => 218,
			'or_expr' => 219,
			'mult_expr' => 232,
			'scoped_name' => 220,
			'boolean_literal' => 233,
			'add_expr' => 234,
			'positive_int_const' => 278,
			'unary_expr' => 222,
			'primary_expr' => 237,
			'wide_string_literal' => 239,
			'xor_expr' => 240
		}
	},
	{#State 207
		ACTIONS => {
			"[" => 206
		},
		DEFAULT => -213,
		GOTOS => {
			'fixed_array_sizes' => 279,
			'fixed_array_size' => 207
		}
	},
	{#State 208
		ACTIONS => {
			'IDENTIFIER' => 146,
			'error' => 148
		},
		GOTOS => {
			'declarators' => 280,
			'array_declarator' => 150,
			'simple_declarator' => 145,
			'declarator' => 147,
			'complex_declarator' => 151
		}
	},
	{#State 209
		DEFAULT => -136
	},
	{#State 210
		DEFAULT => -135
	},
	{#State 211
		DEFAULT => -81
	},
	{#State 212
		DEFAULT => -83
	},
	{#State 213
		DEFAULT => -85
	},
	{#State 214
		DEFAULT => -101
	},
	{#State 215
		DEFAULT => -102
	},
	{#State 216
		ACTIONS => {
			"::" => 72,
			'TRUE' => 224,
			'IDENTIFIER' => 59,
			'INTEGER_LITERAL' => 226,
			'FLOATING_PT_LITERAL' => 228,
			'FIXED_PT_LITERAL' => 235,
			"(" => 221,
			'FALSE' => 214,
			'STRING_LITERAL' => 238,
			'WIDE_CHARACTER_LITERAL' => 223,
			'WIDE_STRING_LITERAL' => 230,
			'CHARACTER_LITERAL' => 231
		},
		GOTOS => {
			'literal' => 213,
			'primary_expr' => 281,
			'scoped_name' => 220,
			'wide_string_literal' => 239,
			'boolean_literal' => 233,
			'string_literal' => 217
		}
	},
	{#State 217
		DEFAULT => -89
	},
	{#State 218
		ACTIONS => {
			"&" => 282
		},
		DEFAULT => -65
	},
	{#State 219
		ACTIONS => {
			"|" => 283
		},
		DEFAULT => -62
	},
	{#State 220
		ACTIONS => {
			"::" => 142
		},
		DEFAULT => -84
	},
	{#State 221
		ACTIONS => {
			"-" => 211,
			"::" => 72,
			'TRUE' => 224,
			"+" => 225,
			"~" => 212,
			'INTEGER_LITERAL' => 226,
			'FLOATING_PT_LITERAL' => 228,
			'FALSE' => 214,
			'error' => 285,
			'WIDE_STRING_LITERAL' => 230,
			'CHARACTER_LITERAL' => 231,
			'IDENTIFIER' => 59,
			"(" => 221,
			'FIXED_PT_LITERAL' => 235,
			'STRING_LITERAL' => 238,
			'WIDE_CHARACTER_LITERAL' => 223
		},
		GOTOS => {
			'and_expr' => 218,
			'or_expr' => 219,
			'mult_expr' => 232,
			'shift_expr' => 227,
			'scoped_name' => 220,
			'boolean_literal' => 233,
			'add_expr' => 234,
			'literal' => 213,
			'primary_expr' => 237,
			'unary_expr' => 222,
			'unary_operator' => 216,
			'const_exp' => 284,
			'xor_expr' => 240,
			'wide_string_literal' => 239,
			'string_literal' => 217
		}
	},
	{#State 222
		DEFAULT => -75
	},
	{#State 223
		DEFAULT => -92
	},
	{#State 224
		DEFAULT => -100
	},
	{#State 225
		DEFAULT => -82
	},
	{#State 226
		DEFAULT => -88
	},
	{#State 227
		ACTIONS => {
			"<<" => 287,
			">>" => 286
		},
		DEFAULT => -67
	},
	{#State 228
		DEFAULT => -94
	},
	{#State 229
		ACTIONS => {
			">" => 288
		}
	},
	{#State 230
		ACTIONS => {
			'WIDE_STRING_LITERAL' => 230
		},
		DEFAULT => -98,
		GOTOS => {
			'wide_string_literal' => 289
		}
	},
	{#State 231
		DEFAULT => -91
	},
	{#State 232
		ACTIONS => {
			"%" => 290,
			"*" => 291,
			"/" => 292
		},
		DEFAULT => -72
	},
	{#State 233
		DEFAULT => -95
	},
	{#State 234
		ACTIONS => {
			"-" => 293,
			"+" => 294
		},
		DEFAULT => -69
	},
	{#State 235
		DEFAULT => -93
	},
	{#State 236
		ACTIONS => {
			">" => 295
		}
	},
	{#State 237
		DEFAULT => -80
	},
	{#State 238
		ACTIONS => {
			'STRING_LITERAL' => 238
		},
		DEFAULT => -96,
		GOTOS => {
			'string_literal' => 296
		}
	},
	{#State 239
		DEFAULT => -90
	},
	{#State 240
		ACTIONS => {
			"^" => 297
		},
		DEFAULT => -63
	},
	{#State 241
		ACTIONS => {
			">" => 298
		}
	},
	{#State 242
		ACTIONS => {
			">" => 299
		}
	},
	{#State 243
		ACTIONS => {
			">" => 300
		}
	},
	{#State 244
		ACTIONS => {
			"," => 302,
			">" => 301
		}
	},
	{#State 245
		ACTIONS => {
			">" => 303
		}
	},
	{#State 246
		ACTIONS => {
			"," => 304
		}
	},
	{#State 247
		ACTIONS => {
			"::" => 72,
			'ENUM' => 2,
			'CHAR' => 73,
			'OBJECT' => 77,
			'STRING' => 80,
			'OCTET' => 49,
			'WSTRING' => 82,
			'UNION' => 10,
			'UNSIGNED' => 51,
			'error' => 310,
			'ANY' => 52,
			'FLOAT' => 86,
			'LONG' => 54,
			'SEQUENCE' => 87,
			'IDENTIFIER' => 59,
			'DOUBLE' => 88,
			'SHORT' => 89,
			'BOOLEAN' => 91,
			'STRUCT' => 24,
			'VOID' => 305,
			'FIXED' => 94,
			'WCHAR' => 69
		},
		GOTOS => {
			'wide_string_type' => 255,
			'union_type' => 47,
			'object_type' => 74,
			'integer_type' => 76,
			'unsigned_int' => 79,
			'sequence_type' => 307,
			'enum_header' => 4,
			'op_param_type_spec' => 308,
			'unsigned_short_int' => 48,
			'unsigned_longlong_int' => 81,
			'struct_type' => 50,
			'union_header' => 9,
			'constr_type_spec' => 309,
			'struct_header' => 13,
			'floating_pt_type' => 85,
			'signed_longlong_int' => 55,
			'enum_type' => 56,
			'any_type' => 57,
			'base_type_spec' => 258,
			'unsigned_long_int' => 60,
			'scoped_name' => 251,
			'signed_int' => 92,
			'string_type' => 252,
			'char_type' => 63,
			'param_type_spec' => 306,
			'fixed_pt_type' => 254,
			'signed_long_int' => 65,
			'signed_short_int' => 66,
			'boolean_type' => 95,
			'wide_char_type' => 68,
			'octet_type' => 70
		}
	},
	{#State 248
		DEFAULT => -34
	},
	{#State 249
		DEFAULT => -32
	},
	{#State 250
		DEFAULT => -31
	},
	{#State 251
		ACTIONS => {
			"::" => 142
		},
		DEFAULT => -274
	},
	{#State 252
		DEFAULT => -271
	},
	{#State 253
		DEFAULT => -237
	},
	{#State 254
		DEFAULT => -273
	},
	{#State 255
		DEFAULT => -272
	},
	{#State 256
		DEFAULT => -238
	},
	{#State 257
		DEFAULT => -236
	},
	{#State 258
		DEFAULT => -270
	},
	{#State 259
		ACTIONS => {
			'IDENTIFIER' => 311,
			'error' => 312
		}
	},
	{#State 260
		DEFAULT => -33
	},
	{#State 261
		ACTIONS => {
			"::" => -252,
			'ENUM' => -252,
			'CHAR' => -252,
			'OBJECT' => -252,
			'STRING' => -252,
			'OCTET' => -252,
			'WSTRING' => -252,
			'UNION' => -252,
			'UNSIGNED' => -252,
			'error' => 318,
			'ANY' => -252,
			'FLOAT' => -252,
			")" => 319,
			'LONG' => -252,
			'SEQUENCE' => -252,
			'IDENTIFIER' => -252,
			'DOUBLE' => -252,
			'SHORT' => -252,
			'BOOLEAN' => -252,
			'INOUT' => 314,
			"..." => 320,
			'STRUCT' => -252,
			'OUT' => 315,
			'IN' => 321,
			'VOID' => -252,
			'FIXED' => -252,
			'WCHAR' => -252
		},
		GOTOS => {
			'param_attribute' => 313,
			'param_dcl' => 316,
			'param_dcls' => 317
		}
	},
	{#State 262
		DEFAULT => -230
	},
	{#State 263
		ACTIONS => {
			'RAISES' => 322
		},
		DEFAULT => -256,
		GOTOS => {
			'raises_expr' => 323
		}
	},
	{#State 264
		DEFAULT => -23
	},
	{#State 265
		DEFAULT => -36
	},
	{#State 266
		DEFAULT => -35
	},
	{#State 267
		DEFAULT => -24
	},
	{#State 268
		DEFAULT => -50
	},
	{#State 269
		ACTIONS => {
			"-" => 211,
			"::" => 72,
			'TRUE' => 224,
			"+" => 225,
			"~" => 212,
			'INTEGER_LITERAL' => 226,
			'FLOATING_PT_LITERAL' => 228,
			'FALSE' => 214,
			'error' => 325,
			'WIDE_STRING_LITERAL' => 230,
			'CHARACTER_LITERAL' => 231,
			'IDENTIFIER' => 59,
			"(" => 221,
			'FIXED_PT_LITERAL' => 235,
			'STRING_LITERAL' => 238,
			'WIDE_CHARACTER_LITERAL' => 223
		},
		GOTOS => {
			'and_expr' => 218,
			'or_expr' => 219,
			'mult_expr' => 232,
			'shift_expr' => 227,
			'scoped_name' => 220,
			'boolean_literal' => 233,
			'add_expr' => 234,
			'literal' => 213,
			'primary_expr' => 237,
			'unary_expr' => 222,
			'unary_operator' => 216,
			'const_exp' => 324,
			'xor_expr' => 240,
			'wide_string_literal' => 239,
			'string_literal' => 217
		}
	},
	{#State 270
		DEFAULT => -224
	},
	{#State 271
		DEFAULT => -225
	},
	{#State 272
		ACTIONS => {
			"::" => 72,
			'IDENTIFIER' => 59
		},
		GOTOS => {
			'interface_name' => 183,
			'interface_names' => 326,
			'scoped_name' => 180
		}
	},
	{#State 273
		DEFAULT => -197
	},
	{#State 274
		DEFAULT => -171
	},
	{#State 275
		ACTIONS => {
			"{" => 328,
			'error' => 327
		}
	},
	{#State 276
		DEFAULT => -167
	},
	{#State 277
		ACTIONS => {
			"]" => 329
		}
	},
	{#State 278
		ACTIONS => {
			"]" => 330
		}
	},
	{#State 279
		DEFAULT => -214
	},
	{#State 280
		DEFAULT => -131
	},
	{#State 281
		DEFAULT => -79
	},
	{#State 282
		ACTIONS => {
			"-" => 211,
			"::" => 72,
			'TRUE' => 224,
			'IDENTIFIER' => 59,
			"+" => 225,
			"~" => 212,
			'INTEGER_LITERAL' => 226,
			'FLOATING_PT_LITERAL' => 228,
			'FIXED_PT_LITERAL' => 235,
			"(" => 221,
			'FALSE' => 214,
			'STRING_LITERAL' => 238,
			'WIDE_STRING_LITERAL' => 230,
			'WIDE_CHARACTER_LITERAL' => 223,
			'CHARACTER_LITERAL' => 231
		},
		GOTOS => {
			'mult_expr' => 232,
			'shift_expr' => 331,
			'scoped_name' => 220,
			'boolean_literal' => 233,
			'add_expr' => 234,
			'literal' => 213,
			'primary_expr' => 237,
			'unary_expr' => 222,
			'unary_operator' => 216,
			'wide_string_literal' => 239,
			'string_literal' => 217
		}
	},
	{#State 283
		ACTIONS => {
			"-" => 211,
			"::" => 72,
			'TRUE' => 224,
			'IDENTIFIER' => 59,
			"+" => 225,
			"~" => 212,
			'INTEGER_LITERAL' => 226,
			'FLOATING_PT_LITERAL' => 228,
			'FIXED_PT_LITERAL' => 235,
			"(" => 221,
			'FALSE' => 214,
			'STRING_LITERAL' => 238,
			'WIDE_STRING_LITERAL' => 230,
			'WIDE_CHARACTER_LITERAL' => 223,
			'CHARACTER_LITERAL' => 231
		},
		GOTOS => {
			'and_expr' => 218,
			'mult_expr' => 232,
			'shift_expr' => 227,
			'scoped_name' => 220,
			'boolean_literal' => 233,
			'add_expr' => 234,
			'literal' => 213,
			'primary_expr' => 237,
			'unary_expr' => 222,
			'unary_operator' => 216,
			'xor_expr' => 332,
			'wide_string_literal' => 239,
			'string_literal' => 217
		}
	},
	{#State 284
		ACTIONS => {
			")" => 333
		}
	},
	{#State 285
		ACTIONS => {
			")" => 334
		}
	},
	{#State 286
		ACTIONS => {
			"-" => 211,
			"::" => 72,
			'TRUE' => 224,
			'IDENTIFIER' => 59,
			"+" => 225,
			"~" => 212,
			'INTEGER_LITERAL' => 226,
			'FLOATING_PT_LITERAL' => 228,
			'FIXED_PT_LITERAL' => 235,
			"(" => 221,
			'FALSE' => 214,
			'STRING_LITERAL' => 238,
			'WIDE_STRING_LITERAL' => 230,
			'WIDE_CHARACTER_LITERAL' => 223,
			'CHARACTER_LITERAL' => 231
		},
		GOTOS => {
			'mult_expr' => 232,
			'scoped_name' => 220,
			'boolean_literal' => 233,
			'literal' => 213,
			'add_expr' => 335,
			'primary_expr' => 237,
			'unary_expr' => 222,
			'unary_operator' => 216,
			'wide_string_literal' => 239,
			'string_literal' => 217
		}
	},
	{#State 287
		ACTIONS => {
			"-" => 211,
			"::" => 72,
			'TRUE' => 224,
			'IDENTIFIER' => 59,
			"+" => 225,
			"~" => 212,
			'INTEGER_LITERAL' => 226,
			'FLOATING_PT_LITERAL' => 228,
			'FIXED_PT_LITERAL' => 235,
			"(" => 221,
			'FALSE' => 214,
			'STRING_LITERAL' => 238,
			'WIDE_STRING_LITERAL' => 230,
			'WIDE_CHARACTER_LITERAL' => 223,
			'CHARACTER_LITERAL' => 231
		},
		GOTOS => {
			'mult_expr' => 232,
			'scoped_name' => 220,
			'boolean_literal' => 233,
			'literal' => 213,
			'add_expr' => 336,
			'primary_expr' => 237,
			'unary_expr' => 222,
			'unary_operator' => 216,
			'wide_string_literal' => 239,
			'string_literal' => 217
		}
	},
	{#State 288
		DEFAULT => -208
	},
	{#State 289
		DEFAULT => -99
	},
	{#State 290
		ACTIONS => {
			"-" => 211,
			"::" => 72,
			'TRUE' => 224,
			'IDENTIFIER' => 59,
			"+" => 225,
			"~" => 212,
			'INTEGER_LITERAL' => 226,
			'FLOATING_PT_LITERAL' => 228,
			'FIXED_PT_LITERAL' => 235,
			"(" => 221,
			'FALSE' => 214,
			'STRING_LITERAL' => 238,
			'WIDE_STRING_LITERAL' => 230,
			'WIDE_CHARACTER_LITERAL' => 223,
			'CHARACTER_LITERAL' => 231
		},
		GOTOS => {
			'literal' => 213,
			'primary_expr' => 237,
			'unary_expr' => 337,
			'unary_operator' => 216,
			'scoped_name' => 220,
			'wide_string_literal' => 239,
			'boolean_literal' => 233,
			'string_literal' => 217
		}
	},
	{#State 291
		ACTIONS => {
			"-" => 211,
			"::" => 72,
			'TRUE' => 224,
			'IDENTIFIER' => 59,
			"+" => 225,
			"~" => 212,
			'INTEGER_LITERAL' => 226,
			'FLOATING_PT_LITERAL' => 228,
			'FIXED_PT_LITERAL' => 235,
			"(" => 221,
			'FALSE' => 214,
			'STRING_LITERAL' => 238,
			'WIDE_STRING_LITERAL' => 230,
			'WIDE_CHARACTER_LITERAL' => 223,
			'CHARACTER_LITERAL' => 231
		},
		GOTOS => {
			'literal' => 213,
			'primary_expr' => 237,
			'unary_expr' => 338,
			'unary_operator' => 216,
			'scoped_name' => 220,
			'wide_string_literal' => 239,
			'boolean_literal' => 233,
			'string_literal' => 217
		}
	},
	{#State 292
		ACTIONS => {
			"-" => 211,
			"::" => 72,
			'TRUE' => 224,
			'IDENTIFIER' => 59,
			"+" => 225,
			"~" => 212,
			'INTEGER_LITERAL' => 226,
			'FLOATING_PT_LITERAL' => 228,
			'FIXED_PT_LITERAL' => 235,
			"(" => 221,
			'FALSE' => 214,
			'STRING_LITERAL' => 238,
			'WIDE_STRING_LITERAL' => 230,
			'WIDE_CHARACTER_LITERAL' => 223,
			'CHARACTER_LITERAL' => 231
		},
		GOTOS => {
			'literal' => 213,
			'primary_expr' => 237,
			'unary_expr' => 339,
			'unary_operator' => 216,
			'scoped_name' => 220,
			'wide_string_literal' => 239,
			'boolean_literal' => 233,
			'string_literal' => 217
		}
	},
	{#State 293
		ACTIONS => {
			"-" => 211,
			"::" => 72,
			'TRUE' => 224,
			'IDENTIFIER' => 59,
			"+" => 225,
			"~" => 212,
			'INTEGER_LITERAL' => 226,
			'FLOATING_PT_LITERAL' => 228,
			'FIXED_PT_LITERAL' => 235,
			"(" => 221,
			'FALSE' => 214,
			'STRING_LITERAL' => 238,
			'WIDE_STRING_LITERAL' => 230,
			'WIDE_CHARACTER_LITERAL' => 223,
			'CHARACTER_LITERAL' => 231
		},
		GOTOS => {
			'mult_expr' => 340,
			'scoped_name' => 220,
			'boolean_literal' => 233,
			'literal' => 213,
			'unary_expr' => 222,
			'primary_expr' => 237,
			'unary_operator' => 216,
			'wide_string_literal' => 239,
			'string_literal' => 217
		}
	},
	{#State 294
		ACTIONS => {
			"-" => 211,
			"::" => 72,
			'TRUE' => 224,
			'IDENTIFIER' => 59,
			"+" => 225,
			"~" => 212,
			'INTEGER_LITERAL' => 226,
			'FLOATING_PT_LITERAL' => 228,
			'FIXED_PT_LITERAL' => 235,
			"(" => 221,
			'FALSE' => 214,
			'STRING_LITERAL' => 238,
			'WIDE_STRING_LITERAL' => 230,
			'WIDE_CHARACTER_LITERAL' => 223,
			'CHARACTER_LITERAL' => 231
		},
		GOTOS => {
			'mult_expr' => 341,
			'scoped_name' => 220,
			'boolean_literal' => 233,
			'literal' => 213,
			'unary_expr' => 222,
			'primary_expr' => 237,
			'unary_operator' => 216,
			'wide_string_literal' => 239,
			'string_literal' => 217
		}
	},
	{#State 295
		DEFAULT => -206
	},
	{#State 296
		DEFAULT => -97
	},
	{#State 297
		ACTIONS => {
			"-" => 211,
			"::" => 72,
			'TRUE' => 224,
			'IDENTIFIER' => 59,
			"+" => 225,
			"~" => 212,
			'INTEGER_LITERAL' => 226,
			'FLOATING_PT_LITERAL' => 228,
			'FIXED_PT_LITERAL' => 235,
			"(" => 221,
			'FALSE' => 214,
			'STRING_LITERAL' => 238,
			'WIDE_STRING_LITERAL' => 230,
			'WIDE_CHARACTER_LITERAL' => 223,
			'CHARACTER_LITERAL' => 231
		},
		GOTOS => {
			'and_expr' => 342,
			'mult_expr' => 232,
			'shift_expr' => 227,
			'scoped_name' => 220,
			'boolean_literal' => 233,
			'add_expr' => 234,
			'literal' => 213,
			'primary_expr' => 237,
			'unary_expr' => 222,
			'unary_operator' => 216,
			'wide_string_literal' => 239,
			'string_literal' => 217
		}
	},
	{#State 298
		DEFAULT => -211
	},
	{#State 299
		DEFAULT => -209
	},
	{#State 300
		DEFAULT => -204
	},
	{#State 301
		DEFAULT => -203
	},
	{#State 302
		ACTIONS => {
			"-" => 211,
			"::" => 72,
			'TRUE' => 224,
			"+" => 225,
			"~" => 212,
			'INTEGER_LITERAL' => 226,
			'FLOATING_PT_LITERAL' => 228,
			'FALSE' => 214,
			'error' => 343,
			'WIDE_STRING_LITERAL' => 230,
			'CHARACTER_LITERAL' => 231,
			'IDENTIFIER' => 59,
			"(" => 221,
			'FIXED_PT_LITERAL' => 235,
			'STRING_LITERAL' => 238,
			'WIDE_CHARACTER_LITERAL' => 223
		},
		GOTOS => {
			'shift_expr' => 227,
			'literal' => 213,
			'const_exp' => 215,
			'unary_operator' => 216,
			'string_literal' => 217,
			'and_expr' => 218,
			'or_expr' => 219,
			'mult_expr' => 232,
			'scoped_name' => 220,
			'boolean_literal' => 233,
			'add_expr' => 234,
			'positive_int_const' => 344,
			'unary_expr' => 222,
			'primary_expr' => 237,
			'wide_string_literal' => 239,
			'xor_expr' => 240
		}
	},
	{#State 303
		DEFAULT => -277
	},
	{#State 304
		ACTIONS => {
			"-" => 211,
			"::" => 72,
			'TRUE' => 224,
			"+" => 225,
			"~" => 212,
			'INTEGER_LITERAL' => 226,
			'FLOATING_PT_LITERAL' => 228,
			'FALSE' => 214,
			'error' => 345,
			'WIDE_STRING_LITERAL' => 230,
			'CHARACTER_LITERAL' => 231,
			'IDENTIFIER' => 59,
			"(" => 221,
			'FIXED_PT_LITERAL' => 235,
			'STRING_LITERAL' => 238,
			'WIDE_CHARACTER_LITERAL' => 223
		},
		GOTOS => {
			'shift_expr' => 227,
			'literal' => 213,
			'const_exp' => 215,
			'unary_operator' => 216,
			'string_literal' => 217,
			'and_expr' => 218,
			'or_expr' => 219,
			'mult_expr' => 232,
			'scoped_name' => 220,
			'boolean_literal' => 233,
			'add_expr' => 234,
			'positive_int_const' => 346,
			'unary_expr' => 222,
			'primary_expr' => 237,
			'wide_string_literal' => 239,
			'xor_expr' => 240
		}
	},
	{#State 305
		DEFAULT => -267
	},
	{#State 306
		ACTIONS => {
			'IDENTIFIER' => 348,
			'error' => 148
		},
		GOTOS => {
			'simple_declarators' => 349,
			'simple_declarator' => 347
		}
	},
	{#State 307
		DEFAULT => -268
	},
	{#State 308
		DEFAULT => -266
	},
	{#State 309
		DEFAULT => -269
	},
	{#State 310
		DEFAULT => -218
	},
	{#State 311
		DEFAULT => -231
	},
	{#State 312
		DEFAULT => -232
	},
	{#State 313
		ACTIONS => {
			"::" => 72,
			'ENUM' => 2,
			'CHAR' => 73,
			'OBJECT' => 77,
			'STRING' => 80,
			'OCTET' => 49,
			'WSTRING' => 82,
			'UNION' => 10,
			'UNSIGNED' => 51,
			'ANY' => 52,
			'FLOAT' => 86,
			'LONG' => 54,
			'SEQUENCE' => 87,
			'IDENTIFIER' => 59,
			'DOUBLE' => 88,
			'SHORT' => 89,
			'BOOLEAN' => 91,
			'STRUCT' => 24,
			'VOID' => 305,
			'FIXED' => 94,
			'WCHAR' => 69
		},
		GOTOS => {
			'wide_string_type' => 255,
			'union_type' => 47,
			'object_type' => 74,
			'integer_type' => 76,
			'unsigned_int' => 79,
			'sequence_type' => 307,
			'enum_header' => 4,
			'op_param_type_spec' => 308,
			'unsigned_short_int' => 48,
			'unsigned_longlong_int' => 81,
			'struct_type' => 50,
			'union_header' => 9,
			'constr_type_spec' => 309,
			'struct_header' => 13,
			'floating_pt_type' => 85,
			'signed_longlong_int' => 55,
			'enum_type' => 56,
			'any_type' => 57,
			'base_type_spec' => 258,
			'unsigned_long_int' => 60,
			'scoped_name' => 251,
			'signed_int' => 92,
			'string_type' => 252,
			'char_type' => 63,
			'param_type_spec' => 350,
			'fixed_pt_type' => 254,
			'signed_long_int' => 65,
			'signed_short_int' => 66,
			'boolean_type' => 95,
			'wide_char_type' => 68,
			'octet_type' => 70
		}
	},
	{#State 314
		DEFAULT => -251
	},
	{#State 315
		DEFAULT => -250
	},
	{#State 316
		ACTIONS => {
			";" => 351
		},
		DEFAULT => -245
	},
	{#State 317
		ACTIONS => {
			"," => 352,
			")" => 353
		}
	},
	{#State 318
		ACTIONS => {
			")" => 354
		}
	},
	{#State 319
		DEFAULT => -242
	},
	{#State 320
		ACTIONS => {
			")" => 355
		}
	},
	{#State 321
		DEFAULT => -249
	},
	{#State 322
		ACTIONS => {
			"(" => 356,
			'error' => 357
		}
	},
	{#State 323
		ACTIONS => {
			'CONTEXT' => 359
		},
		DEFAULT => -263,
		GOTOS => {
			'context_expr' => 358
		}
	},
	{#State 324
		DEFAULT => -48
	},
	{#State 325
		DEFAULT => -49
	},
	{#State 326
		DEFAULT => -41
	},
	{#State 327
		DEFAULT => -170
	},
	{#State 328
		ACTIONS => {
			'DEFAULT' => 365,
			'error' => 363,
			'CASE' => 360
		},
		GOTOS => {
			'case_label' => 366,
			'switch_body' => 361,
			'case' => 362,
			'case_labels' => 364
		}
	},
	{#State 329
		DEFAULT => -216
	},
	{#State 330
		DEFAULT => -215
	},
	{#State 331
		ACTIONS => {
			"<<" => 287,
			">>" => 286
		},
		DEFAULT => -68
	},
	{#State 332
		ACTIONS => {
			"^" => 297
		},
		DEFAULT => -64
	},
	{#State 333
		DEFAULT => -86
	},
	{#State 334
		DEFAULT => -87
	},
	{#State 335
		ACTIONS => {
			"-" => 293,
			"+" => 294
		},
		DEFAULT => -70
	},
	{#State 336
		ACTIONS => {
			"-" => 293,
			"+" => 294
		},
		DEFAULT => -71
	},
	{#State 337
		DEFAULT => -78
	},
	{#State 338
		DEFAULT => -76
	},
	{#State 339
		DEFAULT => -77
	},
	{#State 340
		ACTIONS => {
			"%" => 290,
			"*" => 291,
			"/" => 292
		},
		DEFAULT => -74
	},
	{#State 341
		ACTIONS => {
			"%" => 290,
			"*" => 291,
			"/" => 292
		},
		DEFAULT => -73
	},
	{#State 342
		ACTIONS => {
			"&" => 282
		},
		DEFAULT => -66
	},
	{#State 343
		ACTIONS => {
			">" => 367
		}
	},
	{#State 344
		ACTIONS => {
			">" => 368
		}
	},
	{#State 345
		ACTIONS => {
			">" => 369
		}
	},
	{#State 346
		ACTIONS => {
			">" => 370
		}
	},
	{#State 347
		ACTIONS => {
			"," => 371
		},
		DEFAULT => -221
	},
	{#State 348
		DEFAULT => -134
	},
	{#State 349
		DEFAULT => -217
	},
	{#State 350
		ACTIONS => {
			'IDENTIFIER' => 348,
			'error' => 148
		},
		GOTOS => {
			'simple_declarator' => 372
		}
	},
	{#State 351
		DEFAULT => -247
	},
	{#State 352
		ACTIONS => {
			")" => 374,
			'INOUT' => 314,
			"..." => 375,
			'OUT' => 315,
			'IN' => 321
		},
		DEFAULT => -252,
		GOTOS => {
			'param_attribute' => 313,
			'param_dcl' => 373
		}
	},
	{#State 353
		DEFAULT => -239
	},
	{#State 354
		DEFAULT => -244
	},
	{#State 355
		DEFAULT => -243
	},
	{#State 356
		ACTIONS => {
			"::" => 72,
			'IDENTIFIER' => 59,
			'error' => 377
		},
		GOTOS => {
			'exception_names' => 378,
			'scoped_name' => 376,
			'exception_name' => 379
		}
	},
	{#State 357
		DEFAULT => -255
	},
	{#State 358
		DEFAULT => -229
	},
	{#State 359
		ACTIONS => {
			"(" => 380,
			'error' => 381
		}
	},
	{#State 360
		ACTIONS => {
			"-" => 211,
			"::" => 72,
			'TRUE' => 224,
			"+" => 225,
			"~" => 212,
			'INTEGER_LITERAL' => 226,
			'FLOATING_PT_LITERAL' => 228,
			'FALSE' => 214,
			'error' => 383,
			'WIDE_STRING_LITERAL' => 230,
			'CHARACTER_LITERAL' => 231,
			'IDENTIFIER' => 59,
			"(" => 221,
			'FIXED_PT_LITERAL' => 235,
			'STRING_LITERAL' => 238,
			'WIDE_CHARACTER_LITERAL' => 223
		},
		GOTOS => {
			'and_expr' => 218,
			'or_expr' => 219,
			'mult_expr' => 232,
			'shift_expr' => 227,
			'scoped_name' => 220,
			'boolean_literal' => 233,
			'add_expr' => 234,
			'literal' => 213,
			'primary_expr' => 237,
			'unary_expr' => 222,
			'unary_operator' => 216,
			'const_exp' => 382,
			'xor_expr' => 240,
			'wide_string_literal' => 239,
			'string_literal' => 217
		}
	},
	{#State 361
		ACTIONS => {
			"}" => 384
		}
	},
	{#State 362
		ACTIONS => {
			'DEFAULT' => 365,
			'CASE' => 360
		},
		DEFAULT => -180,
		GOTOS => {
			'case_label' => 366,
			'switch_body' => 385,
			'case' => 362,
			'case_labels' => 364
		}
	},
	{#State 363
		ACTIONS => {
			"}" => 386
		}
	},
	{#State 364
		ACTIONS => {
			"::" => 72,
			'ENUM' => 2,
			'CHAR' => 73,
			'OBJECT' => 77,
			'STRING' => 80,
			'OCTET' => 49,
			'WSTRING' => 82,
			'UNION' => 10,
			'UNSIGNED' => 51,
			'ANY' => 52,
			'FLOAT' => 86,
			'LONG' => 54,
			'SEQUENCE' => 87,
			'IDENTIFIER' => 59,
			'DOUBLE' => 88,
			'SHORT' => 89,
			'BOOLEAN' => 91,
			'STRUCT' => 24,
			'VOID' => 64,
			'FIXED' => 94,
			'WCHAR' => 69
		},
		GOTOS => {
			'union_type' => 47,
			'enum_header' => 4,
			'unsigned_short_int' => 48,
			'struct_type' => 50,
			'union_header' => 9,
			'struct_header' => 13,
			'signed_longlong_int' => 55,
			'enum_type' => 56,
			'any_type' => 57,
			'template_type_spec' => 58,
			'element_spec' => 387,
			'unsigned_long_int' => 60,
			'scoped_name' => 61,
			'string_type' => 62,
			'char_type' => 63,
			'fixed_pt_type' => 67,
			'signed_short_int' => 66,
			'signed_long_int' => 65,
			'wide_char_type' => 68,
			'octet_type' => 70,
			'wide_string_type' => 71,
			'object_type' => 74,
			'type_spec' => 388,
			'integer_type' => 76,
			'unsigned_int' => 79,
			'sequence_type' => 78,
			'unsigned_longlong_int' => 81,
			'constr_type_spec' => 83,
			'floating_pt_type' => 85,
			'base_type_spec' => 90,
			'signed_int' => 92,
			'simple_type_spec' => 93,
			'boolean_type' => 95
		}
	},
	{#State 365
		ACTIONS => {
			":" => 389,
			'error' => 390
		}
	},
	{#State 366
		ACTIONS => {
			'CASE' => 360,
			'DEFAULT' => 365
		},
		DEFAULT => -183,
		GOTOS => {
			'case_label' => 366,
			'case_labels' => 391
		}
	},
	{#State 367
		DEFAULT => -202
	},
	{#State 368
		DEFAULT => -201
	},
	{#State 369
		DEFAULT => -276
	},
	{#State 370
		DEFAULT => -275
	},
	{#State 371
		ACTIONS => {
			'IDENTIFIER' => 348,
			'error' => 148
		},
		GOTOS => {
			'simple_declarators' => 392,
			'simple_declarator' => 347
		}
	},
	{#State 372
		DEFAULT => -248
	},
	{#State 373
		DEFAULT => -246
	},
	{#State 374
		DEFAULT => -241
	},
	{#State 375
		ACTIONS => {
			")" => 393
		}
	},
	{#State 376
		ACTIONS => {
			"::" => 142
		},
		DEFAULT => -259
	},
	{#State 377
		ACTIONS => {
			")" => 394
		}
	},
	{#State 378
		ACTIONS => {
			")" => 395
		}
	},
	{#State 379
		ACTIONS => {
			"," => 396
		},
		DEFAULT => -257
	},
	{#State 380
		ACTIONS => {
			'STRING_LITERAL' => 238,
			'error' => 399
		},
		GOTOS => {
			'string_literals' => 398,
			'string_literal' => 397
		}
	},
	{#State 381
		DEFAULT => -262
	},
	{#State 382
		ACTIONS => {
			":" => 400,
			'error' => 401
		}
	},
	{#State 383
		DEFAULT => -187
	},
	{#State 384
		DEFAULT => -168
	},
	{#State 385
		DEFAULT => -181
	},
	{#State 386
		DEFAULT => -169
	},
	{#State 387
		ACTIONS => {
			";" => 43,
			'error' => 44
		},
		GOTOS => {
			'check_semicolon' => 402
		}
	},
	{#State 388
		ACTIONS => {
			'IDENTIFIER' => 146,
			'error' => 148
		},
		GOTOS => {
			'array_declarator' => 150,
			'simple_declarator' => 145,
			'declarator' => 403,
			'complex_declarator' => 151
		}
	},
	{#State 389
		DEFAULT => -188
	},
	{#State 390
		DEFAULT => -189
	},
	{#State 391
		DEFAULT => -184
	},
	{#State 392
		DEFAULT => -222
	},
	{#State 393
		DEFAULT => -240
	},
	{#State 394
		DEFAULT => -254
	},
	{#State 395
		DEFAULT => -253
	},
	{#State 396
		ACTIONS => {
			"::" => 72,
			'IDENTIFIER' => 59
		},
		GOTOS => {
			'exception_names' => 404,
			'scoped_name' => 376,
			'exception_name' => 379
		}
	},
	{#State 397
		ACTIONS => {
			"," => 405
		},
		DEFAULT => -264
	},
	{#State 398
		ACTIONS => {
			")" => 406
		}
	},
	{#State 399
		ACTIONS => {
			")" => 407
		}
	},
	{#State 400
		DEFAULT => -185
	},
	{#State 401
		DEFAULT => -186
	},
	{#State 402
		DEFAULT => -182
	},
	{#State 403
		DEFAULT => -190
	},
	{#State 404
		DEFAULT => -258
	},
	{#State 405
		ACTIONS => {
			'STRING_LITERAL' => 238
		},
		GOTOS => {
			'string_literals' => 408,
			'string_literal' => 397
		}
	},
	{#State 406
		DEFAULT => -260
	},
	{#State 407
		DEFAULT => -261
	},
	{#State 408
		DEFAULT => -265
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
#line 59 "Parser21.yp"
{
            $_[0]->YYData->{root} = new CORBA::IDL::Specification($_[0],
                    'list_decl'         =>  $_[1],
            );
        }
	],
	[#Rule 2
		 'specification', 0,
sub
#line 65 "Parser21.yp"
{
            $_[0]->Error("Empty specification.\n");
        }
	],
	[#Rule 3
		 'specification', 1,
sub
#line 69 "Parser21.yp"
{
            $_[0]->Error("definition declaration expected.\n");
        }
	],
	[#Rule 4
		 'definitions', 1,
sub
#line 76 "Parser21.yp"
{
            [$_[1]->getRef()];
        }
	],
	[#Rule 5
		 'definitions', 2,
sub
#line 80 "Parser21.yp"
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
#line 99 "Parser21.yp"
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
#line 113 "Parser21.yp"
{
            $_[0]->Warning("';' expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 14
		 'module', 4,
sub
#line 122 "Parser21.yp"
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
#line 129 "Parser21.yp"
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
#line 136 "Parser21.yp"
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
#line 143 "Parser21.yp"
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
#line 153 "Parser21.yp"
{
            new CORBA::IDL::Module($_[0],
                    'idf'               =>  $_[2],
            );
        }
	],
	[#Rule 19
		 'module_header', 2,
sub
#line 159 "Parser21.yp"
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
#line 176 "Parser21.yp"
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
#line 184 "Parser21.yp"
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
#line 192 "Parser21.yp"
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
#line 204 "Parser21.yp"
{
            new CORBA::IDL::ForwardRegularInterface($_[0],
                    'idf'                   =>  $_[2]
            );
        }
	],
	[#Rule 26
		 'forward_dcl', 2,
sub
#line 210 "Parser21.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 27
		 'interface_header', 3,
sub
#line 219 "Parser21.yp"
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
#line 226 "Parser21.yp"
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
#line 240 "Parser21.yp"
{
            [$_[1]->getRef()];
        }
	],
	[#Rule 31
		 'exports', 2,
sub
#line 244 "Parser21.yp"
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
#line 267 "Parser21.yp"
{
            new CORBA::IDL::InheritanceSpec($_[0],
                    'list_interface'        =>  $_[2]
            );
        }
	],
	[#Rule 38
		 'interface_inheritance_spec', 2,
sub
#line 273 "Parser21.yp"
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
#line 283 "Parser21.yp"
{
            [$_[1]];
        }
	],
	[#Rule 41
		 'interface_names', 3,
sub
#line 287 "Parser21.yp"
{
            unshift @{$_[3]}, $_[1];
            $_[3];
        }
	],
	[#Rule 42
		 'interface_name', 1,
sub
#line 295 "Parser21.yp"
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
#line 305 "Parser21.yp"
{
            $_[1] . $_[2];
        }
	],
	[#Rule 45
		 'scoped_name', 2,
sub
#line 309 "Parser21.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
            '';
        }
	],
	[#Rule 46
		 'scoped_name', 3,
sub
#line 315 "Parser21.yp"
{
            $_[1] . $_[2] . $_[3];
        }
	],
	[#Rule 47
		 'scoped_name', 3,
sub
#line 319 "Parser21.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 48
		 'const_dcl', 5,
sub
#line 329 "Parser21.yp"
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
#line 337 "Parser21.yp"
{
            $_[0]->Error("Expression expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 50
		 'const_dcl', 4,
sub
#line 342 "Parser21.yp"
{
            $_[0]->Error("'=' expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 51
		 'const_dcl', 3,
sub
#line 347 "Parser21.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 52
		 'const_dcl', 2,
sub
#line 352 "Parser21.yp"
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
#line 377 "Parser21.yp"
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
#line 393 "Parser21.yp"
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
#line 403 "Parser21.yp"
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
#line 413 "Parser21.yp"
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
#line 423 "Parser21.yp"
{
            BuildBinop($_[1], $_[2], $_[3]);
        }
	],
	[#Rule 71
		 'shift_expr', 3,
sub
#line 427 "Parser21.yp"
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
#line 437 "Parser21.yp"
{
            BuildBinop($_[1], $_[2], $_[3]);
        }
	],
	[#Rule 74
		 'add_expr', 3,
sub
#line 441 "Parser21.yp"
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
#line 451 "Parser21.yp"
{
            BuildBinop($_[1], $_[2], $_[3]);
        }
	],
	[#Rule 77
		 'mult_expr', 3,
sub
#line 455 "Parser21.yp"
{
            BuildBinop($_[1], $_[2], $_[3]);
        }
	],
	[#Rule 78
		 'mult_expr', 3,
sub
#line 459 "Parser21.yp"
{
            BuildBinop($_[1], $_[2], $_[3]);
        }
	],
	[#Rule 79
		 'unary_expr', 2,
sub
#line 467 "Parser21.yp"
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
#line 487 "Parser21.yp"
{
            [
                CORBA::IDL::Constant->Lookup($_[0], $_[1])
            ];
        }
	],
	[#Rule 85
		 'primary_expr', 1,
sub
#line 493 "Parser21.yp"
{
            [ $_[1] ];
        }
	],
	[#Rule 86
		 'primary_expr', 3,
sub
#line 497 "Parser21.yp"
{
            $_[2];
        }
	],
	[#Rule 87
		 'primary_expr', 3,
sub
#line 501 "Parser21.yp"
{
            $_[0]->Error("Expression expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 88
		 'literal', 1,
sub
#line 510 "Parser21.yp"
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
#line 517 "Parser21.yp"
{
            new CORBA::IDL::StringLiteral($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 90
		 'literal', 1,
sub
#line 523 "Parser21.yp"
{
            new CORBA::IDL::WideStringLiteral($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 91
		 'literal', 1,
sub
#line 529 "Parser21.yp"
{
            new CORBA::IDL::CharacterLiteral($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 92
		 'literal', 1,
sub
#line 535 "Parser21.yp"
{
            new CORBA::IDL::WideCharacterLiteral($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 93
		 'literal', 1,
sub
#line 541 "Parser21.yp"
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
#line 548 "Parser21.yp"
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
#line 562 "Parser21.yp"
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
#line 571 "Parser21.yp"
{
            $_[1] . $_[2];
        }
	],
	[#Rule 100
		 'boolean_literal', 1,
sub
#line 579 "Parser21.yp"
{
            new CORBA::IDL::BooleanLiteral($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 101
		 'boolean_literal', 1,
sub
#line 585 "Parser21.yp"
{
            new CORBA::IDL::BooleanLiteral($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 102
		 'positive_int_const', 1,
sub
#line 595 "Parser21.yp"
{
            new CORBA::IDL::Expression($_[0],
                    'list_expr'         =>  $_[1]
            );
        }
	],
	[#Rule 103
		 'type_dcl', 2,
sub
#line 605 "Parser21.yp"
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
#line 615 "Parser21.yp"
{
            $_[0]->Error("type_declarator expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 108
		 'type_declarator', 2,
sub
#line 624 "Parser21.yp"
{
            new CORBA::IDL::TypeDeclarators($_[0],
                    'type'              =>  $_[1],
                    'list_expr'         =>  $_[2]
            );
        }
	],
	[#Rule 109
		 'type_spec', 1, undef
	],
	[#Rule 110
		 'type_spec', 1, undef
	],
	[#Rule 111
		 'simple_type_spec', 1, undef
	],
	[#Rule 112
		 'simple_type_spec', 1, undef
	],
	[#Rule 113
		 'simple_type_spec', 1,
sub
#line 647 "Parser21.yp"
{
            CORBA::IDL::TypeDeclarator->Lookup($_[0], $_[1]);
        }
	],
	[#Rule 114
		 'simple_type_spec', 1,
sub
#line 651 "Parser21.yp"
{
            $_[0]->Error("simple_type_spec expected.\n");
            new CORBA::IDL::VoidType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 115
		 'base_type_spec', 1, undef
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
		 'template_type_spec', 1, undef
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
		 'constr_type_spec', 1, undef
	],
	[#Rule 128
		 'constr_type_spec', 1, undef
	],
	[#Rule 129
		 'constr_type_spec', 1, undef
	],
	[#Rule 130
		 'declarators', 1,
sub
#line 704 "Parser21.yp"
{
            [$_[1]];
        }
	],
	[#Rule 131
		 'declarators', 3,
sub
#line 708 "Parser21.yp"
{
            unshift @{$_[3]}, $_[1];
            $_[3];
        }
	],
	[#Rule 132
		 'declarator', 1,
sub
#line 717 "Parser21.yp"
{
            [$_[1]];
        }
	],
	[#Rule 133
		 'declarator', 1, undef
	],
	[#Rule 134
		 'simple_declarator', 1, undef
	],
	[#Rule 135
		 'simple_declarator', 2,
sub
#line 729 "Parser21.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 136
		 'simple_declarator', 2,
sub
#line 734 "Parser21.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 137
		 'complex_declarator', 1, undef
	],
	[#Rule 138
		 'floating_pt_type', 1,
sub
#line 749 "Parser21.yp"
{
            new CORBA::IDL::FloatingPtType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 139
		 'floating_pt_type', 1,
sub
#line 755 "Parser21.yp"
{
            new CORBA::IDL::FloatingPtType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 140
		 'floating_pt_type', 2,
sub
#line 761 "Parser21.yp"
{
            new CORBA::IDL::FloatingPtType($_[0],
                    'value'             =>  $_[1] . q{ } . $_[2]
            );
        }
	],
	[#Rule 141
		 'integer_type', 1, undef
	],
	[#Rule 142
		 'integer_type', 1, undef
	],
	[#Rule 143
		 'signed_int', 1, undef
	],
	[#Rule 144
		 'signed_int', 1, undef
	],
	[#Rule 145
		 'signed_int', 1, undef
	],
	[#Rule 146
		 'signed_short_int', 1,
sub
#line 789 "Parser21.yp"
{
            new CORBA::IDL::IntegerType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 147
		 'signed_long_int', 1,
sub
#line 799 "Parser21.yp"
{
            new CORBA::IDL::IntegerType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 148
		 'signed_longlong_int', 2,
sub
#line 809 "Parser21.yp"
{
            new CORBA::IDL::IntegerType($_[0],
                    'value'             =>  $_[1] . q{ } . $_[2]
            );
        }
	],
	[#Rule 149
		 'unsigned_int', 1, undef
	],
	[#Rule 150
		 'unsigned_int', 1, undef
	],
	[#Rule 151
		 'unsigned_int', 1, undef
	],
	[#Rule 152
		 'unsigned_short_int', 2,
sub
#line 829 "Parser21.yp"
{
            new CORBA::IDL::IntegerType($_[0],
                    'value'             =>  $_[1] . q{ } . $_[2]
            );
        }
	],
	[#Rule 153
		 'unsigned_long_int', 2,
sub
#line 839 "Parser21.yp"
{
            new CORBA::IDL::IntegerType($_[0],
                    'value'             =>  $_[1] . q{ } . $_[2]
            );
        }
	],
	[#Rule 154
		 'unsigned_longlong_int', 3,
sub
#line 849 "Parser21.yp"
{
            new CORBA::IDL::IntegerType($_[0],
                    'value'             =>  $_[1] . q{ } . $_[2] . q{ } . $_[3]
            );
        }
	],
	[#Rule 155
		 'char_type', 1,
sub
#line 859 "Parser21.yp"
{
            new CORBA::IDL::CharType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 156
		 'wide_char_type', 1,
sub
#line 869 "Parser21.yp"
{
            new CORBA::IDL::WideCharType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 157
		 'boolean_type', 1,
sub
#line 879 "Parser21.yp"
{
            new CORBA::IDL::BooleanType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 158
		 'octet_type', 1,
sub
#line 889 "Parser21.yp"
{
            new CORBA::IDL::OctetType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 159
		 'any_type', 1,
sub
#line 899 "Parser21.yp"
{
            new CORBA::IDL::AnyType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 160
		 'object_type', 1,
sub
#line 909 "Parser21.yp"
{
            new CORBA::IDL::ObjectType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 161
		 'struct_type', 4,
sub
#line 919 "Parser21.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[1]->Configure($_[0],
                    'list_expr'         =>  $_[3]
            ) if (defined $_[1]);
        }
	],
	[#Rule 162
		 'struct_type', 4,
sub
#line 926 "Parser21.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->Error("member expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 163
		 'struct_header', 2,
sub
#line 936 "Parser21.yp"
{
            new CORBA::IDL::StructType($_[0],
                    'idf'               =>  $_[2]
            );
        }
	],
	[#Rule 164
		 'struct_header', 2,
sub
#line 942 "Parser21.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 165
		 'member_list', 1,
sub
#line 951 "Parser21.yp"
{
            [$_[1]];
        }
	],
	[#Rule 166
		 'member_list', 2,
sub
#line 955 "Parser21.yp"
{
            unshift @{$_[2]}, $_[1];
            $_[2];
        }
	],
	[#Rule 167
		 'member', 3,
sub
#line 964 "Parser21.yp"
{
            new CORBA::IDL::Members($_[0],
                    'type'              =>  $_[1],
                    'list_expr'         =>  $_[2]
            );
        }
	],
	[#Rule 168
		 'union_type', 8,
sub
#line 975 "Parser21.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[1]->Configure($_[0],
                    'type'              =>  $_[4],
                    'list_expr'         =>  $_[7]
            ) if (defined $_[1]);
        }
	],
	[#Rule 169
		 'union_type', 8,
sub
#line 983 "Parser21.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->Error("switch_body expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 170
		 'union_type', 6,
sub
#line 990 "Parser21.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->Error("'\x7b' expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 171
		 'union_type', 5,
sub
#line 997 "Parser21.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->Error("switch_type_spec expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 172
		 'union_type', 3,
sub
#line 1004 "Parser21.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->Error("'(' expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 173
		 'union_header', 2,
sub
#line 1014 "Parser21.yp"
{
            new CORBA::IDL::UnionType($_[0],
                    'idf'               =>  $_[2],
            );
        }
	],
	[#Rule 174
		 'union_header', 2,
sub
#line 1020 "Parser21.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 175
		 'switch_type_spec', 1, undef
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
		 'switch_type_spec', 1,
sub
#line 1037 "Parser21.yp"
{
            CORBA::IDL::TypeDeclarator->Lookup($_[0], $_[1]);
        }
	],
	[#Rule 180
		 'switch_body', 1,
sub
#line 1045 "Parser21.yp"
{
            [$_[1]];
        }
	],
	[#Rule 181
		 'switch_body', 2,
sub
#line 1049 "Parser21.yp"
{
            unshift @{$_[2]}, $_[1];
            $_[2];
        }
	],
	[#Rule 182
		 'case', 3,
sub
#line 1058 "Parser21.yp"
{
            new CORBA::IDL::Case($_[0],
                    'list_label'        =>  $_[1],
                    'element'           =>  $_[2]
            );
        }
	],
	[#Rule 183
		 'case_labels', 1,
sub
#line 1068 "Parser21.yp"
{
            [$_[1]];
        }
	],
	[#Rule 184
		 'case_labels', 2,
sub
#line 1072 "Parser21.yp"
{
            unshift @{$_[2]}, $_[1];
            $_[2];
        }
	],
	[#Rule 185
		 'case_label', 3,
sub
#line 1081 "Parser21.yp"
{
            $_[2];                      # here only a expression, type is not known
        }
	],
	[#Rule 186
		 'case_label', 3,
sub
#line 1085 "Parser21.yp"
{
            $_[0]->Error("':' expected.\n");
            $_[0]->YYErrok();
            $_[2];
        }
	],
	[#Rule 187
		 'case_label', 2,
sub
#line 1091 "Parser21.yp"
{
            $_[0]->Error("Expression expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 188
		 'case_label', 2,
sub
#line 1096 "Parser21.yp"
{
            new CORBA::IDL::Default($_[0]);
        }
	],
	[#Rule 189
		 'case_label', 2,
sub
#line 1100 "Parser21.yp"
{
            $_[0]->Error("':' expected.\n");
            $_[0]->YYErrok();
            new CORBA::IDL::Default($_[0]);
        }
	],
	[#Rule 190
		 'element_spec', 2,
sub
#line 1110 "Parser21.yp"
{
            new CORBA::IDL::Element($_[0],
                    'type'          =>  $_[1],
                    'list_expr'     =>  $_[2]
            );
        }
	],
	[#Rule 191
		 'enum_type', 4,
sub
#line 1121 "Parser21.yp"
{
            $_[1]->Configure($_[0],
                    'list_expr'     =>  $_[3]
            ) if (defined $_[1]);
        }
	],
	[#Rule 192
		 'enum_type', 4,
sub
#line 1127 "Parser21.yp"
{
            $_[0]->Error("enumerator expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 193
		 'enum_type', 2,
sub
#line 1133 "Parser21.yp"
{
            $_[0]->Error("'\x7b' expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 194
		 'enum_header', 2,
sub
#line 1142 "Parser21.yp"
{
            new CORBA::IDL::EnumType($_[0],
                    'idf'               =>  $_[2],
            );
        }
	],
	[#Rule 195
		 'enum_header', 2,
sub
#line 1148 "Parser21.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 196
		 'enumerators', 1,
sub
#line 1156 "Parser21.yp"
{
            [$_[1]];
        }
	],
	[#Rule 197
		 'enumerators', 3,
sub
#line 1160 "Parser21.yp"
{
            unshift @{$_[3]}, $_[1];
            $_[3];
        }
	],
	[#Rule 198
		 'enumerators', 2,
sub
#line 1165 "Parser21.yp"
{
            $_[0]->Warning("',' unexpected.\n");
            [$_[1]];
        }
	],
	[#Rule 199
		 'enumerators', 2,
sub
#line 1170 "Parser21.yp"
{
            $_[0]->Error("';' unexpected.\n");
            [$_[1]];
        }
	],
	[#Rule 200
		 'enumerator', 1,
sub
#line 1179 "Parser21.yp"
{
            new CORBA::IDL::Enum($_[0],
                    'idf'               =>  $_[1]
            );
        }
	],
	[#Rule 201
		 'sequence_type', 6,
sub
#line 1189 "Parser21.yp"
{
            new CORBA::IDL::SequenceType($_[0],
                    'value'             =>  $_[1],
                    'type'              =>  $_[3],
                    'max'               =>  $_[5]
            );
        }
	],
	[#Rule 202
		 'sequence_type', 6,
sub
#line 1197 "Parser21.yp"
{
            $_[0]->Error("Expression expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 203
		 'sequence_type', 4,
sub
#line 1202 "Parser21.yp"
{
            new CORBA::IDL::SequenceType($_[0],
                    'value'             =>  $_[1],
                    'type'              =>  $_[3]
            );
        }
	],
	[#Rule 204
		 'sequence_type', 4,
sub
#line 1209 "Parser21.yp"
{
            $_[0]->Error("simple_type_spec expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 205
		 'sequence_type', 2,
sub
#line 1214 "Parser21.yp"
{
            $_[0]->Error("'<' expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 206
		 'string_type', 4,
sub
#line 1223 "Parser21.yp"
{
            new CORBA::IDL::StringType($_[0],
                    'value'             =>  $_[1],
                    'max'               =>  $_[3]
            );
        }
	],
	[#Rule 207
		 'string_type', 1,
sub
#line 1230 "Parser21.yp"
{
            new CORBA::IDL::StringType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 208
		 'string_type', 4,
sub
#line 1236 "Parser21.yp"
{
            $_[0]->Error("Expression expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 209
		 'wide_string_type', 4,
sub
#line 1245 "Parser21.yp"
{
            new CORBA::IDL::WideStringType($_[0],
                    'value'             =>  $_[1],
                    'max'               =>  $_[3]
            );
        }
	],
	[#Rule 210
		 'wide_string_type', 1,
sub
#line 1252 "Parser21.yp"
{
            new CORBA::IDL::WideStringType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 211
		 'wide_string_type', 4,
sub
#line 1258 "Parser21.yp"
{
            $_[0]->Error("Expression expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 212
		 'array_declarator', 2,
sub
#line 1267 "Parser21.yp"
{
            unshift @{$_[2]}, $_[1];
            $_[2];
        }
	],
	[#Rule 213
		 'fixed_array_sizes', 1,
sub
#line 1275 "Parser21.yp"
{
            [$_[1]];
        }
	],
	[#Rule 214
		 'fixed_array_sizes', 2,
sub
#line 1279 "Parser21.yp"
{
            unshift @{$_[2]}, $_[1];
            $_[2];
        }
	],
	[#Rule 215
		 'fixed_array_size', 3,
sub
#line 1288 "Parser21.yp"
{
            $_[2];
        }
	],
	[#Rule 216
		 'fixed_array_size', 3,
sub
#line 1292 "Parser21.yp"
{
            $_[0]->Error("Expression expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 217
		 'attr_dcl', 4,
sub
#line 1301 "Parser21.yp"
{
            new CORBA::IDL::Attributes($_[0],
                    'modifier'          =>  $_[1],
                    'type'              =>  $_[3],
                    'list_expr'         =>  $_[4]
            );
        }
	],
	[#Rule 218
		 'attr_dcl', 3,
sub
#line 1309 "Parser21.yp"
{
            $_[0]->Error("type expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 219
		 'attr_mod', 1, undef
	],
	[#Rule 220
		 'attr_mod', 0, undef
	],
	[#Rule 221
		 'simple_declarators', 1,
sub
#line 1324 "Parser21.yp"
{
            [$_[1]];
        }
	],
	[#Rule 222
		 'simple_declarators', 3,
sub
#line 1328 "Parser21.yp"
{
            unshift @{$_[3]}, $_[1];
            $_[3];
        }
	],
	[#Rule 223
		 'except_dcl', 3,
sub
#line 1337 "Parser21.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[1];
        }
	],
	[#Rule 224
		 'except_dcl', 4,
sub
#line 1342 "Parser21.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[1]->Configure($_[0],
                    'list_expr'         =>  $_[3]
            ) if (defined $_[1]);
        }
	],
	[#Rule 225
		 'except_dcl', 4,
sub
#line 1349 "Parser21.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->Error("'members expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 226
		 'except_dcl', 2,
sub
#line 1356 "Parser21.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->Error("'\x7b' expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 227
		 'exception_header', 2,
sub
#line 1366 "Parser21.yp"
{
            new CORBA::IDL::Exception($_[0],
                    'idf'               =>  $_[2],
            );
        }
	],
	[#Rule 228
		 'exception_header', 2,
sub
#line 1372 "Parser21.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 229
		 'op_dcl', 4,
sub
#line 1381 "Parser21.yp"
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
	[#Rule 230
		 'op_dcl', 2,
sub
#line 1391 "Parser21.yp"
{
            delete $_[0]->YYData->{unnamed_symbtab}
                    if (exists $_[0]->YYData->{unnamed_symbtab});
            $_[0]->Error("parameters declaration expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 231
		 'op_header', 3,
sub
#line 1402 "Parser21.yp"
{
            new CORBA::IDL::Operation($_[0],
                    'modifier'          =>  $_[1],
                    'type'              =>  $_[2],
                    'idf'               =>  $_[3]
            );
        }
	],
	[#Rule 232
		 'op_header', 3,
sub
#line 1410 "Parser21.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 233
		 'op_mod', 1, undef
	],
	[#Rule 234
		 'op_mod', 0, undef
	],
	[#Rule 235
		 'op_attribute', 1, undef
	],
	[#Rule 236
		 'op_type_spec', 1, undef
	],
	[#Rule 237
		 'op_type_spec', 1,
sub
#line 1434 "Parser21.yp"
{
            new CORBA::IDL::VoidType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 238
		 'op_type_spec', 1,
sub
#line 1440 "Parser21.yp"
{
            $_[0]->Error("op_type_spec expected.\n");
            $_[1];                      #default action
        }
	],
	[#Rule 239
		 'parameter_dcls', 3,
sub
#line 1449 "Parser21.yp"
{
            $_[2];
        }
	],
	[#Rule 240
		 'parameter_dcls', 5,
sub
#line 1453 "Parser21.yp"
{
            $_[0]->Error("'...' unexpected.\n");
            $_[2];
        }
	],
	[#Rule 241
		 'parameter_dcls', 4,
sub
#line 1458 "Parser21.yp"
{
            $_[0]->Warning("',' unexpected.\n");
            $_[2];
        }
	],
	[#Rule 242
		 'parameter_dcls', 2,
sub
#line 1463 "Parser21.yp"
{
            undef;
        }
	],
	[#Rule 243
		 'parameter_dcls', 3,
sub
#line 1467 "Parser21.yp"
{
            $_[0]->Error("'...' unexpected.\n");
            undef;
        }
	],
	[#Rule 244
		 'parameter_dcls', 3,
sub
#line 1472 "Parser21.yp"
{
            $_[0]->Error("parameters declaration expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 245
		 'param_dcls', 1,
sub
#line 1480 "Parser21.yp"
{
            [$_[1]];
        }
	],
	[#Rule 246
		 'param_dcls', 3,
sub
#line 1484 "Parser21.yp"
{
            push @{$_[1]}, $_[3];
            $_[1];
        }
	],
	[#Rule 247
		 'param_dcls', 2,
sub
#line 1489 "Parser21.yp"
{
            $_[0]->Error("';' unexpected.\n");
            [$_[1]];
        }
	],
	[#Rule 248
		 'param_dcl', 3,
sub
#line 1498 "Parser21.yp"
{
            new CORBA::IDL::Parameter($_[0],
                    'attr'              =>  $_[1],
                    'type'              =>  $_[2],
                    'idf'               =>  $_[3]
            );
        }
	],
	[#Rule 249
		 'param_attribute', 1, undef
	],
	[#Rule 250
		 'param_attribute', 1, undef
	],
	[#Rule 251
		 'param_attribute', 1, undef
	],
	[#Rule 252
		 'param_attribute', 0,
sub
#line 1516 "Parser21.yp"
{
            $_[0]->Error("(in|out|inout) expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 253
		 'raises_expr', 4,
sub
#line 1525 "Parser21.yp"
{
            $_[3];
        }
	],
	[#Rule 254
		 'raises_expr', 4,
sub
#line 1529 "Parser21.yp"
{
            $_[0]->Error("name expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 255
		 'raises_expr', 2,
sub
#line 1534 "Parser21.yp"
{
            $_[0]->Error("'(' expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 256
		 'raises_expr', 0, undef
	],
	[#Rule 257
		 'exception_names', 1,
sub
#line 1544 "Parser21.yp"
{
            [$_[1]];
        }
	],
	[#Rule 258
		 'exception_names', 3,
sub
#line 1548 "Parser21.yp"
{
            unshift @{$_[3]}, $_[1];
            $_[3];
        }
	],
	[#Rule 259
		 'exception_name', 1,
sub
#line 1556 "Parser21.yp"
{
            CORBA::IDL::Exception->Lookup($_[0], $_[1]);
        }
	],
	[#Rule 260
		 'context_expr', 4,
sub
#line 1564 "Parser21.yp"
{
            $_[3];
        }
	],
	[#Rule 261
		 'context_expr', 4,
sub
#line 1568 "Parser21.yp"
{
            $_[0]->Error("string expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 262
		 'context_expr', 2,
sub
#line 1573 "Parser21.yp"
{
            $_[0]->Error("'(' expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 263
		 'context_expr', 0, undef
	],
	[#Rule 264
		 'string_literals', 1,
sub
#line 1583 "Parser21.yp"
{
            [$_[1]];
        }
	],
	[#Rule 265
		 'string_literals', 3,
sub
#line 1587 "Parser21.yp"
{
            unshift @{$_[3]}, $_[1];
            $_[3];
        }
	],
	[#Rule 266
		 'param_type_spec', 1, undef
	],
	[#Rule 267
		 'param_type_spec', 1,
sub
#line 1598 "Parser21.yp"
{
            $_[0]->Error("param_type_spec expected.\n");
            $_[1];                      #default action
        }
	],
	[#Rule 268
		 'param_type_spec', 1,
sub
#line 1603 "Parser21.yp"
{
            $_[0]->Error("param_type_spec expected.\n");
            $_[1];                      #default action
        }
	],
	[#Rule 269
		 'param_type_spec', 1,
sub
#line 1608 "Parser21.yp"
{
            $_[0]->Error("param_type_spec expected.\n");
            $_[1];                      #default action
        }
	],
	[#Rule 270
		 'op_param_type_spec', 1, undef
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
		 'op_param_type_spec', 1,
sub
#line 1624 "Parser21.yp"
{
            CORBA::IDL::TypeDeclarator->Lookup($_[0], $_[1]);
        }
	],
	[#Rule 275
		 'fixed_pt_type', 6,
sub
#line 1632 "Parser21.yp"
{
            new CORBA::IDL::FixedPtType($_[0],
                    'value'             =>  $_[1],
                    'd'                 =>  $_[3],
                    's'                 =>  $_[5]
            );
        }
	],
	[#Rule 276
		 'fixed_pt_type', 6,
sub
#line 1640 "Parser21.yp"
{
            $_[0]->Error("Expression expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 277
		 'fixed_pt_type', 4,
sub
#line 1645 "Parser21.yp"
{
            $_[0]->Error("Expression expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 278
		 'fixed_pt_type', 2,
sub
#line 1650 "Parser21.yp"
{
            $_[0]->Error("'<' expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 279
		 'fixed_pt_const_type', 1,
sub
#line 1659 "Parser21.yp"
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

#line 1666 "Parser21.yp"


use warnings;

our $VERSION = '2.61';
our $IDL_VERSION = '2.1';

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
