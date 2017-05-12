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
			'INTERFACE' => -30,
			'ENUM' => 30,
			'VALUETYPE' => -77,
			'CUSTOM' => 3,
			'UNION' => 34,
			'NATIVE' => 10,
			'TYPEDEF' => 13,
			'error' => 36,
			'EXCEPTION' => 15,
			'LOCAL' => 39,
			'IDENTIFIER' => 22,
			'MODULE' => 40,
			'STRUCT' => 24,
			'CONST' => 41,
			'ABSTRACT' => 26
		},
		GOTOS => {
			'union_type' => 1,
			'value_dcl' => 2,
			'value_box_dcl' => 4,
			'enum_header' => 5,
			'definitions' => 31,
			'module_header' => 33,
			'definition' => 32,
			'struct_type' => 6,
			'union_header' => 7,
			'value_box_header' => 8,
			'specification' => 35,
			'except_dcl' => 9,
			'value_header' => 11,
			'interface_mod' => 14,
			'struct_header' => 12,
			'interface' => 16,
			'type_dcl' => 17,
			'constr_forward_decl' => 37,
			'module' => 38,
			'interface_header' => 19,
			'value_forward_dcl' => 18,
			'value_mod' => 20,
			'enum_type' => 21,
			'value' => 23,
			'value_abs_dcl' => 42,
			'value_abs_header' => 25,
			'forward_dcl' => 43,
			'exception_header' => 27,
			'const_dcl' => 28,
			'interface_dcl' => 29
		}
	},
	{#State 1
		DEFAULT => -167
	},
	{#State 2
		DEFAULT => -55
	},
	{#State 3
		DEFAULT => -76
	},
	{#State 4
		DEFAULT => -57
	},
	{#State 5
		ACTIONS => {
			"{" => 45,
			'error' => 44
		}
	},
	{#State 6
		DEFAULT => -166
	},
	{#State 7
		ACTIONS => {
			'SWITCH' => 46
		}
	},
	{#State 8
		ACTIONS => {
			"::" => 72,
			'ENUM' => 30,
			'CHAR' => 73,
			'OBJECT' => 77,
			'STRING' => 80,
			'OCTET' => 49,
			'WSTRING' => 82,
			'UNION' => 83,
			'UNSIGNED' => 51,
			'ANY' => 52,
			'FLOAT' => 86,
			'LONG' => 53,
			'SEQUENCE' => 88,
			'IDENTIFIER' => 58,
			'DOUBLE' => 89,
			'SHORT' => 90,
			'BOOLEAN' => 92,
			'STRUCT' => 60,
			'VOID' => 64,
			'FIXED' => 95,
			'VALUEBASE' => 97,
			'WCHAR' => 69
		},
		GOTOS => {
			'union_type' => 47,
			'enum_header' => 5,
			'unsigned_short_int' => 48,
			'struct_type' => 50,
			'union_header' => 7,
			'struct_header' => 12,
			'signed_longlong_int' => 54,
			'enum_type' => 55,
			'any_type' => 56,
			'template_type_spec' => 57,
			'unsigned_long_int' => 59,
			'scoped_name' => 61,
			'string_type' => 62,
			'char_type' => 63,
			'fixed_pt_type' => 67,
			'signed_long_int' => 65,
			'signed_short_int' => 66,
			'wide_char_type' => 68,
			'octet_type' => 70,
			'wide_string_type' => 71,
			'object_type' => 74,
			'type_spec' => 75,
			'integer_type' => 76,
			'unsigned_int' => 78,
			'sequence_type' => 79,
			'unsigned_longlong_int' => 81,
			'constr_type_spec' => 84,
			'floating_pt_type' => 85,
			'value_base_type' => 87,
			'base_type_spec' => 91,
			'signed_int' => 93,
			'simple_type_spec' => 94,
			'boolean_type' => 96
		}
	},
	{#State 9
		ACTIONS => {
			";" => 99,
			'error' => 100
		},
		GOTOS => {
			'check_semicolon' => 98
		}
	},
	{#State 10
		ACTIONS => {
			'IDENTIFIER' => 102,
			'error' => 103
		},
		GOTOS => {
			'simple_declarator' => 101
		}
	},
	{#State 11
		ACTIONS => {
			"{" => 104
		}
	},
	{#State 12
		ACTIONS => {
			"{" => 105
		}
	},
	{#State 13
		ACTIONS => {
			"::" => 72,
			'ENUM' => 30,
			'CHAR' => 73,
			'OBJECT' => 77,
			'STRING' => 80,
			'OCTET' => 49,
			'WSTRING' => 82,
			'UNION' => 83,
			'UNSIGNED' => 51,
			'error' => 108,
			'ANY' => 52,
			'FLOAT' => 86,
			'LONG' => 53,
			'SEQUENCE' => 88,
			'IDENTIFIER' => 58,
			'DOUBLE' => 89,
			'SHORT' => 90,
			'BOOLEAN' => 92,
			'STRUCT' => 60,
			'VOID' => 64,
			'FIXED' => 95,
			'VALUEBASE' => 97,
			'WCHAR' => 69
		},
		GOTOS => {
			'union_type' => 47,
			'enum_header' => 5,
			'unsigned_short_int' => 48,
			'struct_type' => 50,
			'union_header' => 7,
			'struct_header' => 12,
			'type_declarator' => 106,
			'signed_longlong_int' => 54,
			'enum_type' => 55,
			'any_type' => 56,
			'template_type_spec' => 57,
			'unsigned_long_int' => 59,
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
			'type_spec' => 107,
			'integer_type' => 76,
			'unsigned_int' => 78,
			'sequence_type' => 79,
			'unsigned_longlong_int' => 81,
			'constr_type_spec' => 84,
			'floating_pt_type' => 85,
			'value_base_type' => 87,
			'base_type_spec' => 91,
			'signed_int' => 93,
			'simple_type_spec' => 94,
			'boolean_type' => 96
		}
	},
	{#State 14
		ACTIONS => {
			'INTERFACE' => 109
		}
	},
	{#State 15
		ACTIONS => {
			'IDENTIFIER' => 110,
			'error' => 111
		}
	},
	{#State 16
		ACTIONS => {
			";" => 99,
			'error' => 100
		},
		GOTOS => {
			'check_semicolon' => 112
		}
	},
	{#State 17
		ACTIONS => {
			";" => 99,
			'error' => 100
		},
		GOTOS => {
			'check_semicolon' => 113
		}
	},
	{#State 18
		DEFAULT => -58
	},
	{#State 19
		ACTIONS => {
			"{" => 114
		}
	},
	{#State 20
		ACTIONS => {
			'VALUETYPE' => 115
		}
	},
	{#State 21
		DEFAULT => -168
	},
	{#State 22
		ACTIONS => {
			'error' => 116
		}
	},
	{#State 23
		ACTIONS => {
			";" => 99,
			'error' => 100
		},
		GOTOS => {
			'check_semicolon' => 117
		}
	},
	{#State 24
		ACTIONS => {
			'IDENTIFIER' => 118,
			'error' => 119
		}
	},
	{#State 25
		ACTIONS => {
			"{" => 120
		}
	},
	{#State 26
		ACTIONS => {
			'INTERFACE' => -28,
			'VALUETYPE' => 121,
			'error' => 122
		}
	},
	{#State 27
		ACTIONS => {
			"{" => 124,
			'error' => 123
		}
	},
	{#State 28
		ACTIONS => {
			";" => 99,
			'error' => 100
		},
		GOTOS => {
			'check_semicolon' => 125
		}
	},
	{#State 29
		DEFAULT => -21
	},
	{#State 30
		ACTIONS => {
			'IDENTIFIER' => 126,
			'error' => 127
		}
	},
	{#State 31
		DEFAULT => -1
	},
	{#State 32
		ACTIONS => {
			'INTERFACE' => -30,
			'ENUM' => 30,
			'VALUETYPE' => -77,
			'CUSTOM' => 3,
			'UNION' => 34,
			'NATIVE' => 10,
			'TYPEDEF' => 13,
			'EXCEPTION' => 15,
			'LOCAL' => 39,
			'IDENTIFIER' => 22,
			'MODULE' => 40,
			'STRUCT' => 24,
			'CONST' => 41,
			'ABSTRACT' => 26
		},
		DEFAULT => -4,
		GOTOS => {
			'union_type' => 1,
			'value_dcl' => 2,
			'value_box_dcl' => 4,
			'enum_header' => 5,
			'definitions' => 128,
			'definition' => 32,
			'module_header' => 33,
			'struct_type' => 6,
			'union_header' => 7,
			'value_box_header' => 8,
			'except_dcl' => 9,
			'value_header' => 11,
			'interface_mod' => 14,
			'struct_header' => 12,
			'interface' => 16,
			'type_dcl' => 17,
			'constr_forward_decl' => 37,
			'module' => 38,
			'interface_header' => 19,
			'value_forward_dcl' => 18,
			'value_mod' => 20,
			'enum_type' => 21,
			'value' => 23,
			'value_abs_dcl' => 42,
			'value_abs_header' => 25,
			'forward_dcl' => 43,
			'exception_header' => 27,
			'const_dcl' => 28,
			'interface_dcl' => 29
		}
	},
	{#State 33
		ACTIONS => {
			"{" => 130,
			'error' => 129
		}
	},
	{#State 34
		ACTIONS => {
			'IDENTIFIER' => 131,
			'error' => 132
		}
	},
	{#State 35
		ACTIONS => {
			'' => 133
		}
	},
	{#State 36
		DEFAULT => -3
	},
	{#State 37
		DEFAULT => -170
	},
	{#State 38
		ACTIONS => {
			";" => 99,
			'error' => 100
		},
		GOTOS => {
			'check_semicolon' => 134
		}
	},
	{#State 39
		DEFAULT => -29
	},
	{#State 40
		ACTIONS => {
			'IDENTIFIER' => 135,
			'error' => 136
		}
	},
	{#State 41
		ACTIONS => {
			'DOUBLE' => 89,
			"::" => 72,
			'IDENTIFIER' => 58,
			'SHORT' => 90,
			'CHAR' => 73,
			'BOOLEAN' => 92,
			'STRING' => 80,
			'OCTET' => 49,
			'WSTRING' => 82,
			'UNSIGNED' => 51,
			'FIXED' => 148,
			'error' => 145,
			'FLOAT' => 86,
			'LONG' => 53,
			'WCHAR' => 69
		},
		GOTOS => {
			'wide_string_type' => 142,
			'integer_type' => 143,
			'unsigned_int' => 78,
			'unsigned_short_int' => 48,
			'unsigned_longlong_int' => 81,
			'floating_pt_type' => 144,
			'const_type' => 146,
			'signed_longlong_int' => 54,
			'unsigned_long_int' => 59,
			'scoped_name' => 137,
			'string_type' => 138,
			'signed_int' => 93,
			'fixed_pt_const_type' => 147,
			'char_type' => 139,
			'signed_short_int' => 66,
			'signed_long_int' => 65,
			'boolean_type' => 149,
			'wide_char_type' => 140,
			'octet_type' => 141
		}
	},
	{#State 42
		DEFAULT => -56
	},
	{#State 43
		DEFAULT => -22
	},
	{#State 44
		DEFAULT => -258
	},
	{#State 45
		ACTIONS => {
			'IDENTIFIER' => 150,
			'error' => 152
		},
		GOTOS => {
			'enumerators' => 153,
			'enumerator' => 151
		}
	},
	{#State 46
		ACTIONS => {
			"(" => 154,
			'error' => 155
		}
	},
	{#State 47
		DEFAULT => -193
	},
	{#State 48
		DEFAULT => -214
	},
	{#State 49
		DEFAULT => -223
	},
	{#State 50
		DEFAULT => -192
	},
	{#State 51
		ACTIONS => {
			'SHORT' => 157,
			'LONG' => 156
		}
	},
	{#State 52
		DEFAULT => -224
	},
	{#State 53
		ACTIONS => {
			'DOUBLE' => 159,
			'LONG' => 158
		},
		DEFAULT => -212
	},
	{#State 54
		DEFAULT => -210
	},
	{#State 55
		DEFAULT => -194
	},
	{#State 56
		DEFAULT => -185
	},
	{#State 57
		DEFAULT => -176
	},
	{#State 58
		DEFAULT => -50
	},
	{#State 59
		DEFAULT => -215
	},
	{#State 60
		ACTIONS => {
			'IDENTIFIER' => 160,
			'error' => 161
		}
	},
	{#State 61
		ACTIONS => {
			"::" => 162
		},
		DEFAULT => -177
	},
	{#State 62
		DEFAULT => -189
	},
	{#State 63
		DEFAULT => -181
	},
	{#State 64
		DEFAULT => -178
	},
	{#State 65
		DEFAULT => -209
	},
	{#State 66
		DEFAULT => -208
	},
	{#State 67
		DEFAULT => -191
	},
	{#State 68
		DEFAULT => -182
	},
	{#State 69
		DEFAULT => -221
	},
	{#State 70
		DEFAULT => -184
	},
	{#State 71
		DEFAULT => -190
	},
	{#State 72
		ACTIONS => {
			'IDENTIFIER' => 163,
			'error' => 164
		}
	},
	{#State 73
		DEFAULT => -220
	},
	{#State 74
		DEFAULT => -186
	},
	{#State 75
		DEFAULT => -61
	},
	{#State 76
		DEFAULT => -180
	},
	{#State 77
		DEFAULT => -225
	},
	{#State 78
		DEFAULT => -207
	},
	{#State 79
		DEFAULT => -188
	},
	{#State 80
		ACTIONS => {
			"<" => 165
		},
		DEFAULT => -272
	},
	{#State 81
		DEFAULT => -216
	},
	{#State 82
		ACTIONS => {
			"<" => 166
		},
		DEFAULT => -275
	},
	{#State 83
		ACTIONS => {
			'IDENTIFIER' => 167,
			'error' => 168
		}
	},
	{#State 84
		DEFAULT => -174
	},
	{#State 85
		DEFAULT => -179
	},
	{#State 86
		DEFAULT => -203
	},
	{#State 87
		DEFAULT => -187
	},
	{#State 88
		ACTIONS => {
			"<" => 169,
			'error' => 170
		}
	},
	{#State 89
		DEFAULT => -204
	},
	{#State 90
		DEFAULT => -211
	},
	{#State 91
		DEFAULT => -175
	},
	{#State 92
		DEFAULT => -222
	},
	{#State 93
		DEFAULT => -206
	},
	{#State 94
		DEFAULT => -173
	},
	{#State 95
		ACTIONS => {
			"<" => 171,
			'error' => 172
		}
	},
	{#State 96
		DEFAULT => -183
	},
	{#State 97
		DEFAULT => -346
	},
	{#State 98
		DEFAULT => -8
	},
	{#State 99
		DEFAULT => -13
	},
	{#State 100
		DEFAULT => -14
	},
	{#State 101
		DEFAULT => -169
	},
	{#State 102
		DEFAULT => -199
	},
	{#State 103
		ACTIONS => {
			";" => 173,
			"," => 174
		}
	},
	{#State 104
		ACTIONS => {
			"}" => 175,
			'OCTET' => -299,
			'NATIVE' => 10,
			'UNSIGNED' => -299,
			'TYPEDEF' => 13,
			'EXCEPTION' => 15,
			'ANY' => -299,
			'LONG' => -299,
			'IDENTIFIER' => -299,
			'STRUCT' => 24,
			'VOID' => -299,
			'WCHAR' => -299,
			'ENUM' => 30,
			'FACTORY' => 185,
			"::" => -299,
			'PRIVATE' => 187,
			'CHAR' => -299,
			'OBJECT' => -299,
			'ONEWAY' => 190,
			'STRING' => -299,
			'WSTRING' => -299,
			'UNION' => 34,
			'error' => 192,
			'FLOAT' => -299,
			'ATTRIBUTE' => -285,
			'PUBLIC' => 195,
			'SEQUENCE' => -299,
			'DOUBLE' => -299,
			'SHORT' => -299,
			'BOOLEAN' => -299,
			'CONST' => 41,
			'READONLY' => 196,
			'FIXED' => -299,
			'VALUEBASE' => -299
		},
		GOTOS => {
			'op_header' => 184,
			'union_type' => 1,
			'attr_mod' => 176,
			'init_header_param' => 186,
			'init_header' => 188,
			'enum_header' => 5,
			'op_dcl' => 189,
			'attr_dcl' => 191,
			'struct_type' => 6,
			'union_header' => 7,
			'except_dcl' => 177,
			'struct_header' => 12,
			'state_member' => 193,
			'type_dcl' => 179,
			'export' => 178,
			'constr_forward_decl' => 37,
			'state_mod' => 194,
			'enum_type' => 21,
			'op_attribute' => 180,
			'op_mod' => 181,
			'value_elements' => 197,
			'value_element' => 182,
			'exception_header' => 27,
			'const_dcl' => 183,
			'init_dcl' => 198
		}
	},
	{#State 105
		ACTIONS => {
			"::" => 72,
			'ENUM' => 30,
			'CHAR' => 73,
			'OBJECT' => 77,
			'STRING' => 80,
			'OCTET' => 49,
			'WSTRING' => 82,
			'UNION' => 83,
			'UNSIGNED' => 51,
			'error' => 202,
			'ANY' => 52,
			'FLOAT' => 86,
			'LONG' => 53,
			'SEQUENCE' => 88,
			'IDENTIFIER' => 58,
			'DOUBLE' => 89,
			'SHORT' => 90,
			'BOOLEAN' => 92,
			'STRUCT' => 60,
			'VOID' => 64,
			'FIXED' => 95,
			'VALUEBASE' => 97,
			'WCHAR' => 69
		},
		GOTOS => {
			'union_type' => 47,
			'enum_header' => 5,
			'unsigned_short_int' => 48,
			'struct_type' => 50,
			'union_header' => 7,
			'struct_header' => 12,
			'member_list' => 199,
			'signed_longlong_int' => 54,
			'enum_type' => 55,
			'any_type' => 56,
			'template_type_spec' => 57,
			'member' => 200,
			'unsigned_long_int' => 59,
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
			'type_spec' => 201,
			'integer_type' => 76,
			'unsigned_int' => 78,
			'sequence_type' => 79,
			'unsigned_longlong_int' => 81,
			'constr_type_spec' => 84,
			'floating_pt_type' => 85,
			'value_base_type' => 87,
			'base_type_spec' => 91,
			'signed_int' => 93,
			'simple_type_spec' => 94,
			'boolean_type' => 96
		}
	},
	{#State 106
		DEFAULT => -165
	},
	{#State 107
		ACTIONS => {
			'IDENTIFIER' => 204,
			'error' => 103
		},
		GOTOS => {
			'declarators' => 206,
			'array_declarator' => 207,
			'simple_declarator' => 203,
			'declarator' => 205,
			'complex_declarator' => 208
		}
	},
	{#State 108
		DEFAULT => -171
	},
	{#State 109
		ACTIONS => {
			'IDENTIFIER' => 209,
			'error' => 210
		}
	},
	{#State 110
		DEFAULT => -292
	},
	{#State 111
		DEFAULT => -293
	},
	{#State 112
		DEFAULT => -9
	},
	{#State 113
		DEFAULT => -6
	},
	{#State 114
		ACTIONS => {
			"}" => 211,
			'OCTET' => -299,
			'NATIVE' => 10,
			'UNSIGNED' => -299,
			'TYPEDEF' => 13,
			'EXCEPTION' => 15,
			'ANY' => -299,
			'LONG' => -299,
			'IDENTIFIER' => -299,
			'STRUCT' => 24,
			'VOID' => -299,
			'WCHAR' => -299,
			'ENUM' => 30,
			'FACTORY' => 185,
			"::" => -299,
			'PRIVATE' => 187,
			'CHAR' => -299,
			'OBJECT' => -299,
			'ONEWAY' => 190,
			'STRING' => -299,
			'WSTRING' => -299,
			'UNION' => 34,
			'error' => 216,
			'FLOAT' => -299,
			'ATTRIBUTE' => -285,
			'PUBLIC' => 195,
			'SEQUENCE' => -299,
			'DOUBLE' => -299,
			'SHORT' => -299,
			'BOOLEAN' => -299,
			'CONST' => 41,
			'READONLY' => 196,
			'FIXED' => -299,
			'VALUEBASE' => -299
		},
		GOTOS => {
			'op_header' => 184,
			'union_type' => 1,
			'interface_body' => 214,
			'attr_mod' => 176,
			'init_header_param' => 186,
			'init_header' => 188,
			'enum_header' => 5,
			'op_dcl' => 189,
			'exports' => 215,
			'attr_dcl' => 191,
			'struct_type' => 6,
			'union_header' => 7,
			'except_dcl' => 177,
			'struct_header' => 12,
			'state_member' => 217,
			'export' => 212,
			'type_dcl' => 179,
			'constr_forward_decl' => 37,
			'state_mod' => 194,
			'enum_type' => 21,
			'op_attribute' => 180,
			'op_mod' => 181,
			'_export' => 213,
			'exception_header' => 27,
			'const_dcl' => 183,
			'init_dcl' => 218
		}
	},
	{#State 115
		ACTIONS => {
			'IDENTIFIER' => 219,
			'error' => 220
		}
	},
	{#State 116
		ACTIONS => {
			";" => 221
		}
	},
	{#State 117
		DEFAULT => -11
	},
	{#State 118
		ACTIONS => {
			"{" => -228
		},
		DEFAULT => -347
	},
	{#State 119
		ACTIONS => {
			"{" => -229
		},
		DEFAULT => -348
	},
	{#State 120
		ACTIONS => {
			"}" => 222,
			'OCTET' => -299,
			'NATIVE' => 10,
			'UNSIGNED' => -299,
			'TYPEDEF' => 13,
			'EXCEPTION' => 15,
			'ANY' => -299,
			'LONG' => -299,
			'IDENTIFIER' => -299,
			'STRUCT' => 24,
			'VOID' => -299,
			'WCHAR' => -299,
			'ENUM' => 30,
			'FACTORY' => 185,
			"::" => -299,
			'PRIVATE' => 187,
			'CHAR' => -299,
			'OBJECT' => -299,
			'ONEWAY' => 190,
			'STRING' => -299,
			'WSTRING' => -299,
			'UNION' => 34,
			'error' => 224,
			'FLOAT' => -299,
			'ATTRIBUTE' => -285,
			'PUBLIC' => 195,
			'SEQUENCE' => -299,
			'DOUBLE' => -299,
			'SHORT' => -299,
			'BOOLEAN' => -299,
			'CONST' => 41,
			'READONLY' => 196,
			'FIXED' => -299,
			'VALUEBASE' => -299
		},
		GOTOS => {
			'op_header' => 184,
			'union_type' => 1,
			'attr_mod' => 176,
			'init_header_param' => 186,
			'init_header' => 188,
			'enum_header' => 5,
			'op_dcl' => 189,
			'exports' => 223,
			'attr_dcl' => 191,
			'struct_type' => 6,
			'union_header' => 7,
			'except_dcl' => 177,
			'struct_header' => 12,
			'state_member' => 217,
			'export' => 212,
			'type_dcl' => 179,
			'constr_forward_decl' => 37,
			'state_mod' => 194,
			'enum_type' => 21,
			'op_attribute' => 180,
			'op_mod' => 181,
			'_export' => 213,
			'exception_header' => 27,
			'const_dcl' => 183,
			'init_dcl' => 218
		}
	},
	{#State 121
		ACTIONS => {
			'IDENTIFIER' => 225,
			'error' => 226
		}
	},
	{#State 122
		DEFAULT => -68
	},
	{#State 123
		DEFAULT => -291
	},
	{#State 124
		ACTIONS => {
			"}" => 227,
			"::" => 72,
			'ENUM' => 30,
			'CHAR' => 73,
			'OBJECT' => 77,
			'STRING' => 80,
			'OCTET' => 49,
			'WSTRING' => 82,
			'UNION' => 83,
			'UNSIGNED' => 51,
			'error' => 229,
			'ANY' => 52,
			'FLOAT' => 86,
			'LONG' => 53,
			'SEQUENCE' => 88,
			'DOUBLE' => 89,
			'IDENTIFIER' => 58,
			'SHORT' => 90,
			'BOOLEAN' => 92,
			'STRUCT' => 60,
			'VOID' => 64,
			'FIXED' => 95,
			'VALUEBASE' => 97,
			'WCHAR' => 69
		},
		GOTOS => {
			'union_type' => 47,
			'enum_header' => 5,
			'unsigned_short_int' => 48,
			'struct_type' => 50,
			'union_header' => 7,
			'struct_header' => 12,
			'member_list' => 228,
			'signed_longlong_int' => 54,
			'enum_type' => 55,
			'any_type' => 56,
			'template_type_spec' => 57,
			'member' => 200,
			'unsigned_long_int' => 59,
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
			'type_spec' => 201,
			'integer_type' => 76,
			'unsigned_int' => 78,
			'sequence_type' => 79,
			'unsigned_longlong_int' => 81,
			'constr_type_spec' => 84,
			'floating_pt_type' => 85,
			'value_base_type' => 87,
			'base_type_spec' => 91,
			'signed_int' => 93,
			'simple_type_spec' => 94,
			'boolean_type' => 96
		}
	},
	{#State 125
		DEFAULT => -7
	},
	{#State 126
		DEFAULT => -259
	},
	{#State 127
		DEFAULT => -260
	},
	{#State 128
		DEFAULT => -5
	},
	{#State 129
		ACTIONS => {
			"}" => 230
		}
	},
	{#State 130
		ACTIONS => {
			"}" => 231,
			'INTERFACE' => -30,
			'ENUM' => 30,
			'VALUETYPE' => -77,
			'CUSTOM' => 3,
			'UNION' => 34,
			'NATIVE' => 10,
			'TYPEDEF' => 13,
			'error' => 233,
			'EXCEPTION' => 15,
			'LOCAL' => 39,
			'IDENTIFIER' => 22,
			'MODULE' => 40,
			'STRUCT' => 24,
			'CONST' => 41,
			'ABSTRACT' => 26
		},
		GOTOS => {
			'union_type' => 1,
			'value_dcl' => 2,
			'value_box_dcl' => 4,
			'enum_header' => 5,
			'definitions' => 232,
			'definition' => 32,
			'module_header' => 33,
			'struct_type' => 6,
			'union_header' => 7,
			'value_box_header' => 8,
			'except_dcl' => 9,
			'value_header' => 11,
			'interface_mod' => 14,
			'struct_header' => 12,
			'interface' => 16,
			'type_dcl' => 17,
			'constr_forward_decl' => 37,
			'module' => 38,
			'interface_header' => 19,
			'value_forward_dcl' => 18,
			'value_mod' => 20,
			'enum_type' => 21,
			'value' => 23,
			'value_abs_dcl' => 42,
			'value_abs_header' => 25,
			'forward_dcl' => 43,
			'exception_header' => 27,
			'const_dcl' => 28,
			'interface_dcl' => 29
		}
	},
	{#State 131
		ACTIONS => {
			'SWITCH' => -238
		},
		DEFAULT => -349
	},
	{#State 132
		ACTIONS => {
			'SWITCH' => -239
		},
		DEFAULT => -350
	},
	{#State 133
		DEFAULT => 0
	},
	{#State 134
		DEFAULT => -10
	},
	{#State 135
		DEFAULT => -19
	},
	{#State 136
		DEFAULT => -20
	},
	{#State 137
		ACTIONS => {
			"::" => 162
		},
		DEFAULT => -122
	},
	{#State 138
		DEFAULT => -119
	},
	{#State 139
		DEFAULT => -115
	},
	{#State 140
		DEFAULT => -116
	},
	{#State 141
		DEFAULT => -123
	},
	{#State 142
		DEFAULT => -120
	},
	{#State 143
		DEFAULT => -114
	},
	{#State 144
		DEFAULT => -118
	},
	{#State 145
		DEFAULT => -113
	},
	{#State 146
		ACTIONS => {
			'IDENTIFIER' => 234,
			'error' => 235
		}
	},
	{#State 147
		DEFAULT => -121
	},
	{#State 148
		DEFAULT => -345
	},
	{#State 149
		DEFAULT => -117
	},
	{#State 150
		DEFAULT => -265
	},
	{#State 151
		ACTIONS => {
			";" => 236,
			"," => 237
		},
		DEFAULT => -261
	},
	{#State 152
		ACTIONS => {
			"}" => 238
		}
	},
	{#State 153
		ACTIONS => {
			"}" => 239
		}
	},
	{#State 154
		ACTIONS => {
			"::" => 72,
			'ENUM' => 30,
			'IDENTIFIER' => 58,
			'SHORT' => 90,
			'CHAR' => 73,
			'BOOLEAN' => 92,
			'UNSIGNED' => 51,
			'error' => 245,
			'LONG' => 240
		},
		GOTOS => {
			'signed_longlong_int' => 54,
			'enum_type' => 241,
			'integer_type' => 244,
			'unsigned_long_int' => 59,
			'unsigned_int' => 78,
			'scoped_name' => 242,
			'enum_header' => 5,
			'signed_int' => 93,
			'unsigned_short_int' => 48,
			'unsigned_longlong_int' => 81,
			'char_type' => 243,
			'signed_long_int' => 65,
			'signed_short_int' => 66,
			'boolean_type' => 247,
			'switch_type_spec' => 246
		}
	},
	{#State 155
		DEFAULT => -237
	},
	{#State 156
		ACTIONS => {
			'LONG' => 248
		},
		DEFAULT => -218
	},
	{#State 157
		DEFAULT => -217
	},
	{#State 158
		DEFAULT => -213
	},
	{#State 159
		DEFAULT => -205
	},
	{#State 160
		DEFAULT => -228
	},
	{#State 161
		DEFAULT => -229
	},
	{#State 162
		ACTIONS => {
			'IDENTIFIER' => 249,
			'error' => 250
		}
	},
	{#State 163
		DEFAULT => -51
	},
	{#State 164
		DEFAULT => -52
	},
	{#State 165
		ACTIONS => {
			"-" => 251,
			"::" => 72,
			'TRUE' => 264,
			"+" => 265,
			"~" => 252,
			'INTEGER_LITERAL' => 266,
			'FLOATING_PT_LITERAL' => 268,
			'FALSE' => 254,
			'error' => 269,
			'WIDE_STRING_LITERAL' => 270,
			'CHARACTER_LITERAL' => 271,
			'IDENTIFIER' => 58,
			"(" => 261,
			'FIXED_PT_LITERAL' => 275,
			'STRING_LITERAL' => 278,
			'WIDE_CHARACTER_LITERAL' => 263
		},
		GOTOS => {
			'shift_expr' => 267,
			'literal' => 253,
			'const_exp' => 255,
			'unary_operator' => 256,
			'string_literal' => 257,
			'and_expr' => 258,
			'or_expr' => 259,
			'mult_expr' => 272,
			'scoped_name' => 260,
			'boolean_literal' => 273,
			'add_expr' => 274,
			'positive_int_const' => 276,
			'unary_expr' => 262,
			'primary_expr' => 277,
			'wide_string_literal' => 279,
			'xor_expr' => 280
		}
	},
	{#State 166
		ACTIONS => {
			"-" => 251,
			"::" => 72,
			'TRUE' => 264,
			"+" => 265,
			"~" => 252,
			'INTEGER_LITERAL' => 266,
			'FLOATING_PT_LITERAL' => 268,
			'FALSE' => 254,
			'error' => 281,
			'WIDE_STRING_LITERAL' => 270,
			'CHARACTER_LITERAL' => 271,
			'IDENTIFIER' => 58,
			"(" => 261,
			'FIXED_PT_LITERAL' => 275,
			'STRING_LITERAL' => 278,
			'WIDE_CHARACTER_LITERAL' => 263
		},
		GOTOS => {
			'shift_expr' => 267,
			'literal' => 253,
			'const_exp' => 255,
			'unary_operator' => 256,
			'string_literal' => 257,
			'and_expr' => 258,
			'or_expr' => 259,
			'mult_expr' => 272,
			'scoped_name' => 260,
			'boolean_literal' => 273,
			'add_expr' => 274,
			'positive_int_const' => 282,
			'unary_expr' => 262,
			'primary_expr' => 277,
			'wide_string_literal' => 279,
			'xor_expr' => 280
		}
	},
	{#State 167
		DEFAULT => -238
	},
	{#State 168
		DEFAULT => -239
	},
	{#State 169
		ACTIONS => {
			"::" => 72,
			'CHAR' => 73,
			'OBJECT' => 77,
			'STRING' => 80,
			'OCTET' => 49,
			'WSTRING' => 82,
			'UNSIGNED' => 51,
			'error' => 283,
			'ANY' => 52,
			'FLOAT' => 86,
			'LONG' => 53,
			'SEQUENCE' => 88,
			'IDENTIFIER' => 58,
			'DOUBLE' => 89,
			'SHORT' => 90,
			'BOOLEAN' => 92,
			'VOID' => 64,
			'FIXED' => 95,
			'VALUEBASE' => 97,
			'WCHAR' => 69
		},
		GOTOS => {
			'wide_string_type' => 71,
			'object_type' => 74,
			'integer_type' => 76,
			'sequence_type' => 79,
			'unsigned_int' => 78,
			'unsigned_short_int' => 48,
			'unsigned_longlong_int' => 81,
			'floating_pt_type' => 85,
			'value_base_type' => 87,
			'signed_longlong_int' => 54,
			'any_type' => 56,
			'template_type_spec' => 57,
			'base_type_spec' => 91,
			'unsigned_long_int' => 59,
			'scoped_name' => 61,
			'signed_int' => 93,
			'string_type' => 62,
			'simple_type_spec' => 284,
			'char_type' => 63,
			'signed_short_int' => 66,
			'signed_long_int' => 65,
			'fixed_pt_type' => 67,
			'boolean_type' => 96,
			'wide_char_type' => 68,
			'octet_type' => 70
		}
	},
	{#State 170
		DEFAULT => -270
	},
	{#State 171
		ACTIONS => {
			"-" => 251,
			"::" => 72,
			'TRUE' => 264,
			"+" => 265,
			"~" => 252,
			'INTEGER_LITERAL' => 266,
			'FLOATING_PT_LITERAL' => 268,
			'FALSE' => 254,
			'error' => 285,
			'WIDE_STRING_LITERAL' => 270,
			'CHARACTER_LITERAL' => 271,
			'IDENTIFIER' => 58,
			"(" => 261,
			'FIXED_PT_LITERAL' => 275,
			'STRING_LITERAL' => 278,
			'WIDE_CHARACTER_LITERAL' => 263
		},
		GOTOS => {
			'shift_expr' => 267,
			'literal' => 253,
			'const_exp' => 255,
			'unary_operator' => 256,
			'string_literal' => 257,
			'and_expr' => 258,
			'or_expr' => 259,
			'mult_expr' => 272,
			'scoped_name' => 260,
			'boolean_literal' => 273,
			'add_expr' => 274,
			'positive_int_const' => 286,
			'unary_expr' => 262,
			'primary_expr' => 277,
			'wide_string_literal' => 279,
			'xor_expr' => 280
		}
	},
	{#State 172
		DEFAULT => -344
	},
	{#State 173
		DEFAULT => -201
	},
	{#State 174
		DEFAULT => -200
	},
	{#State 175
		DEFAULT => -69
	},
	{#State 176
		ACTIONS => {
			'ATTRIBUTE' => 287
		}
	},
	{#State 177
		ACTIONS => {
			";" => 99,
			'error' => 100
		},
		GOTOS => {
			'check_semicolon' => 288
		}
	},
	{#State 178
		DEFAULT => -89
	},
	{#State 179
		ACTIONS => {
			";" => 99,
			'error' => 100
		},
		GOTOS => {
			'check_semicolon' => 289
		}
	},
	{#State 180
		DEFAULT => -298
	},
	{#State 181
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
			'LONG' => 53,
			'SEQUENCE' => 88,
			'IDENTIFIER' => 58,
			'DOUBLE' => 89,
			'SHORT' => 90,
			'BOOLEAN' => 92,
			'VOID' => 292,
			'FIXED' => 95,
			'VALUEBASE' => 97,
			'WCHAR' => 69
		},
		GOTOS => {
			'wide_string_type' => 294,
			'object_type' => 74,
			'integer_type' => 76,
			'unsigned_int' => 78,
			'sequence_type' => 295,
			'op_param_type_spec' => 296,
			'unsigned_short_int' => 48,
			'unsigned_longlong_int' => 81,
			'floating_pt_type' => 85,
			'value_base_type' => 87,
			'signed_longlong_int' => 54,
			'any_type' => 56,
			'base_type_spec' => 297,
			'unsigned_long_int' => 59,
			'scoped_name' => 290,
			'signed_int' => 93,
			'string_type' => 291,
			'char_type' => 63,
			'signed_long_int' => 65,
			'fixed_pt_type' => 293,
			'signed_short_int' => 66,
			'op_type_spec' => 298,
			'boolean_type' => 96,
			'wide_char_type' => 68,
			'octet_type' => 70
		}
	},
	{#State 182
		ACTIONS => {
			"}" => -72,
			'NATIVE' => 10,
			'TYPEDEF' => 13,
			'EXCEPTION' => 15,
			'STRUCT' => 24,
			'ENUM' => 30,
			'FACTORY' => 185,
			'PRIVATE' => 187,
			'ONEWAY' => 190,
			'UNION' => 34,
			'ATTRIBUTE' => -285,
			'PUBLIC' => 195,
			'CONST' => 41,
			'READONLY' => 196
		},
		DEFAULT => -299,
		GOTOS => {
			'op_header' => 184,
			'union_type' => 1,
			'attr_mod' => 176,
			'init_header_param' => 186,
			'init_header' => 188,
			'enum_header' => 5,
			'op_dcl' => 189,
			'attr_dcl' => 191,
			'struct_type' => 6,
			'union_header' => 7,
			'except_dcl' => 177,
			'struct_header' => 12,
			'state_member' => 193,
			'type_dcl' => 179,
			'export' => 178,
			'constr_forward_decl' => 37,
			'state_mod' => 194,
			'enum_type' => 21,
			'op_attribute' => 180,
			'op_mod' => 181,
			'value_elements' => 299,
			'value_element' => 182,
			'exception_header' => 27,
			'const_dcl' => 183,
			'init_dcl' => 198
		}
	},
	{#State 183
		ACTIONS => {
			";" => 99,
			'error' => 100
		},
		GOTOS => {
			'check_semicolon' => 300
		}
	},
	{#State 184
		ACTIONS => {
			"(" => 301,
			'error' => 302
		},
		GOTOS => {
			'parameter_dcls' => 303
		}
	},
	{#State 185
		ACTIONS => {
			'IDENTIFIER' => 304,
			'error' => 305
		}
	},
	{#State 186
		ACTIONS => {
			";" => 99,
			'error' => 100
		},
		GOTOS => {
			'check_semicolon' => 306
		}
	},
	{#State 187
		DEFAULT => -96
	},
	{#State 188
		ACTIONS => {
			"(" => 307,
			'error' => 308
		}
	},
	{#State 189
		ACTIONS => {
			";" => 99,
			'error' => 100
		},
		GOTOS => {
			'check_semicolon' => 309
		}
	},
	{#State 190
		DEFAULT => -300
	},
	{#State 191
		ACTIONS => {
			";" => 99,
			'error' => 100
		},
		GOTOS => {
			'check_semicolon' => 310
		}
	},
	{#State 192
		ACTIONS => {
			"}" => 311
		}
	},
	{#State 193
		DEFAULT => -90
	},
	{#State 194
		ACTIONS => {
			"::" => 72,
			'ENUM' => 30,
			'CHAR' => 73,
			'OBJECT' => 77,
			'STRING' => 80,
			'OCTET' => 49,
			'WSTRING' => 82,
			'UNION' => 83,
			'UNSIGNED' => 51,
			'error' => 313,
			'ANY' => 52,
			'FLOAT' => 86,
			'LONG' => 53,
			'SEQUENCE' => 88,
			'IDENTIFIER' => 58,
			'DOUBLE' => 89,
			'SHORT' => 90,
			'BOOLEAN' => 92,
			'STRUCT' => 60,
			'VOID' => 64,
			'FIXED' => 95,
			'VALUEBASE' => 97,
			'WCHAR' => 69
		},
		GOTOS => {
			'union_type' => 47,
			'enum_header' => 5,
			'unsigned_short_int' => 48,
			'struct_type' => 50,
			'union_header' => 7,
			'struct_header' => 12,
			'signed_longlong_int' => 54,
			'enum_type' => 55,
			'any_type' => 56,
			'template_type_spec' => 57,
			'unsigned_long_int' => 59,
			'scoped_name' => 61,
			'string_type' => 62,
			'char_type' => 63,
			'fixed_pt_type' => 67,
			'signed_long_int' => 65,
			'signed_short_int' => 66,
			'wide_char_type' => 68,
			'octet_type' => 70,
			'wide_string_type' => 71,
			'object_type' => 74,
			'type_spec' => 312,
			'integer_type' => 76,
			'unsigned_int' => 78,
			'sequence_type' => 79,
			'unsigned_longlong_int' => 81,
			'constr_type_spec' => 84,
			'floating_pt_type' => 85,
			'value_base_type' => 87,
			'base_type_spec' => 91,
			'signed_int' => 93,
			'simple_type_spec' => 94,
			'boolean_type' => 96
		}
	},
	{#State 195
		DEFAULT => -95
	},
	{#State 196
		DEFAULT => -284
	},
	{#State 197
		ACTIONS => {
			"}" => 314
		}
	},
	{#State 198
		DEFAULT => -91
	},
	{#State 199
		ACTIONS => {
			"}" => 315
		}
	},
	{#State 200
		ACTIONS => {
			"::" => 72,
			'ENUM' => 30,
			'CHAR' => 73,
			'OBJECT' => 77,
			'STRING' => 80,
			'OCTET' => 49,
			'WSTRING' => 82,
			'UNION' => 83,
			'UNSIGNED' => 51,
			'ANY' => 52,
			'FLOAT' => 86,
			'LONG' => 53,
			'SEQUENCE' => 88,
			'DOUBLE' => 89,
			'IDENTIFIER' => 58,
			'SHORT' => 90,
			'BOOLEAN' => 92,
			'STRUCT' => 60,
			'VOID' => 64,
			'FIXED' => 95,
			'VALUEBASE' => 97,
			'WCHAR' => 69
		},
		DEFAULT => -230,
		GOTOS => {
			'union_type' => 47,
			'enum_header' => 5,
			'unsigned_short_int' => 48,
			'struct_type' => 50,
			'union_header' => 7,
			'struct_header' => 12,
			'member_list' => 316,
			'signed_longlong_int' => 54,
			'enum_type' => 55,
			'any_type' => 56,
			'template_type_spec' => 57,
			'member' => 200,
			'unsigned_long_int' => 59,
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
			'type_spec' => 201,
			'integer_type' => 76,
			'unsigned_int' => 78,
			'sequence_type' => 79,
			'unsigned_longlong_int' => 81,
			'constr_type_spec' => 84,
			'floating_pt_type' => 85,
			'value_base_type' => 87,
			'base_type_spec' => 91,
			'signed_int' => 93,
			'simple_type_spec' => 94,
			'boolean_type' => 96
		}
	},
	{#State 201
		ACTIONS => {
			'IDENTIFIER' => 204,
			'error' => 103
		},
		GOTOS => {
			'declarators' => 317,
			'array_declarator' => 207,
			'simple_declarator' => 203,
			'declarator' => 205,
			'complex_declarator' => 208
		}
	},
	{#State 202
		ACTIONS => {
			"}" => 318
		}
	},
	{#State 203
		DEFAULT => -197
	},
	{#State 204
		ACTIONS => {
			"[" => 320
		},
		DEFAULT => -199,
		GOTOS => {
			'fixed_array_sizes' => 319,
			'fixed_array_size' => 321
		}
	},
	{#State 205
		ACTIONS => {
			"," => 322
		},
		DEFAULT => -195
	},
	{#State 206
		DEFAULT => -172
	},
	{#State 207
		DEFAULT => -202
	},
	{#State 208
		DEFAULT => -198
	},
	{#State 209
		ACTIONS => {
			":" => 323,
			"{" => -46
		},
		DEFAULT => -26,
		GOTOS => {
			'interface_inheritance_spec' => 324
		}
	},
	{#State 210
		ACTIONS => {
			"{" => -32
		},
		DEFAULT => -27
	},
	{#State 211
		DEFAULT => -23
	},
	{#State 212
		DEFAULT => -36
	},
	{#State 213
		ACTIONS => {
			"}" => -34,
			'NATIVE' => 10,
			'TYPEDEF' => 13,
			'EXCEPTION' => 15,
			'STRUCT' => 24,
			'ENUM' => 30,
			'FACTORY' => 185,
			'PRIVATE' => 187,
			'ONEWAY' => 190,
			'UNION' => 34,
			'ATTRIBUTE' => -285,
			'PUBLIC' => 195,
			'CONST' => 41,
			'READONLY' => 196
		},
		DEFAULT => -299,
		GOTOS => {
			'op_header' => 184,
			'union_type' => 1,
			'attr_mod' => 176,
			'init_header_param' => 186,
			'init_header' => 188,
			'enum_header' => 5,
			'op_dcl' => 189,
			'exports' => 325,
			'attr_dcl' => 191,
			'struct_type' => 6,
			'union_header' => 7,
			'except_dcl' => 177,
			'struct_header' => 12,
			'state_member' => 217,
			'export' => 212,
			'type_dcl' => 179,
			'constr_forward_decl' => 37,
			'state_mod' => 194,
			'enum_type' => 21,
			'op_attribute' => 180,
			'op_mod' => 181,
			'_export' => 213,
			'exception_header' => 27,
			'const_dcl' => 183,
			'init_dcl' => 218
		}
	},
	{#State 214
		ACTIONS => {
			"}" => 326
		}
	},
	{#State 215
		DEFAULT => -33
	},
	{#State 216
		ACTIONS => {
			"}" => 327
		}
	},
	{#State 217
		DEFAULT => -37
	},
	{#State 218
		DEFAULT => -38
	},
	{#State 219
		ACTIONS => {
			":" => 328,
			'SUPPORTS' => 329,
			";" => -59,
			'error' => -59,
			"{" => -87
		},
		DEFAULT => -62,
		GOTOS => {
			'supported_interface_spec' => 331,
			'value_inheritance_spec' => 330
		}
	},
	{#State 220
		DEFAULT => -75
	},
	{#State 221
		DEFAULT => -12
	},
	{#State 222
		DEFAULT => -63
	},
	{#State 223
		ACTIONS => {
			"}" => 332
		}
	},
	{#State 224
		ACTIONS => {
			"}" => 333
		}
	},
	{#State 225
		ACTIONS => {
			":" => 328,
			'SUPPORTS' => 329,
			"{" => -87
		},
		DEFAULT => -60,
		GOTOS => {
			'supported_interface_spec' => 331,
			'value_inheritance_spec' => 334
		}
	},
	{#State 226
		DEFAULT => -67
	},
	{#State 227
		DEFAULT => -288
	},
	{#State 228
		ACTIONS => {
			"}" => 335
		}
	},
	{#State 229
		ACTIONS => {
			"}" => 336
		}
	},
	{#State 230
		DEFAULT => -18
	},
	{#State 231
		DEFAULT => -17
	},
	{#State 232
		ACTIONS => {
			"}" => 337
		}
	},
	{#State 233
		ACTIONS => {
			"}" => 338
		}
	},
	{#State 234
		ACTIONS => {
			'error' => 339,
			"=" => 340
		}
	},
	{#State 235
		DEFAULT => -112
	},
	{#State 236
		DEFAULT => -264
	},
	{#State 237
		ACTIONS => {
			'IDENTIFIER' => 150
		},
		DEFAULT => -263,
		GOTOS => {
			'enumerators' => 341,
			'enumerator' => 151
		}
	},
	{#State 238
		DEFAULT => -257
	},
	{#State 239
		DEFAULT => -256
	},
	{#State 240
		ACTIONS => {
			'LONG' => 158
		},
		DEFAULT => -212
	},
	{#State 241
		DEFAULT => -243
	},
	{#State 242
		ACTIONS => {
			"::" => 162
		},
		DEFAULT => -244
	},
	{#State 243
		DEFAULT => -241
	},
	{#State 244
		DEFAULT => -240
	},
	{#State 245
		ACTIONS => {
			")" => 342
		}
	},
	{#State 246
		ACTIONS => {
			")" => 343
		}
	},
	{#State 247
		DEFAULT => -242
	},
	{#State 248
		DEFAULT => -219
	},
	{#State 249
		DEFAULT => -53
	},
	{#State 250
		DEFAULT => -54
	},
	{#State 251
		DEFAULT => -143
	},
	{#State 252
		DEFAULT => -145
	},
	{#State 253
		DEFAULT => -147
	},
	{#State 254
		DEFAULT => -163
	},
	{#State 255
		DEFAULT => -164
	},
	{#State 256
		ACTIONS => {
			"::" => 72,
			'TRUE' => 264,
			'IDENTIFIER' => 58,
			'INTEGER_LITERAL' => 266,
			'FLOATING_PT_LITERAL' => 268,
			'FIXED_PT_LITERAL' => 275,
			"(" => 261,
			'FALSE' => 254,
			'STRING_LITERAL' => 278,
			'WIDE_CHARACTER_LITERAL' => 263,
			'WIDE_STRING_LITERAL' => 270,
			'CHARACTER_LITERAL' => 271
		},
		GOTOS => {
			'literal' => 253,
			'primary_expr' => 344,
			'scoped_name' => 260,
			'wide_string_literal' => 279,
			'boolean_literal' => 273,
			'string_literal' => 257
		}
	},
	{#State 257
		DEFAULT => -151
	},
	{#State 258
		ACTIONS => {
			"&" => 345
		},
		DEFAULT => -127
	},
	{#State 259
		ACTIONS => {
			"|" => 346
		},
		DEFAULT => -124
	},
	{#State 260
		ACTIONS => {
			"::" => 162
		},
		DEFAULT => -146
	},
	{#State 261
		ACTIONS => {
			"-" => 251,
			"::" => 72,
			'TRUE' => 264,
			"+" => 265,
			"~" => 252,
			'INTEGER_LITERAL' => 266,
			'FLOATING_PT_LITERAL' => 268,
			'FALSE' => 254,
			'error' => 348,
			'WIDE_STRING_LITERAL' => 270,
			'CHARACTER_LITERAL' => 271,
			'IDENTIFIER' => 58,
			"(" => 261,
			'FIXED_PT_LITERAL' => 275,
			'STRING_LITERAL' => 278,
			'WIDE_CHARACTER_LITERAL' => 263
		},
		GOTOS => {
			'and_expr' => 258,
			'or_expr' => 259,
			'mult_expr' => 272,
			'shift_expr' => 267,
			'scoped_name' => 260,
			'boolean_literal' => 273,
			'add_expr' => 274,
			'literal' => 253,
			'primary_expr' => 277,
			'unary_expr' => 262,
			'unary_operator' => 256,
			'const_exp' => 347,
			'xor_expr' => 280,
			'wide_string_literal' => 279,
			'string_literal' => 257
		}
	},
	{#State 262
		DEFAULT => -137
	},
	{#State 263
		DEFAULT => -154
	},
	{#State 264
		DEFAULT => -162
	},
	{#State 265
		DEFAULT => -144
	},
	{#State 266
		DEFAULT => -150
	},
	{#State 267
		ACTIONS => {
			"<<" => 350,
			">>" => 349
		},
		DEFAULT => -129
	},
	{#State 268
		DEFAULT => -156
	},
	{#State 269
		ACTIONS => {
			">" => 351
		}
	},
	{#State 270
		ACTIONS => {
			'WIDE_STRING_LITERAL' => 270
		},
		DEFAULT => -160,
		GOTOS => {
			'wide_string_literal' => 352
		}
	},
	{#State 271
		DEFAULT => -153
	},
	{#State 272
		ACTIONS => {
			"%" => 353,
			"*" => 354,
			"/" => 355
		},
		DEFAULT => -134
	},
	{#State 273
		DEFAULT => -157
	},
	{#State 274
		ACTIONS => {
			"-" => 356,
			"+" => 357
		},
		DEFAULT => -131
	},
	{#State 275
		DEFAULT => -155
	},
	{#State 276
		ACTIONS => {
			">" => 358
		}
	},
	{#State 277
		DEFAULT => -142
	},
	{#State 278
		ACTIONS => {
			'STRING_LITERAL' => 278
		},
		DEFAULT => -158,
		GOTOS => {
			'string_literal' => 359
		}
	},
	{#State 279
		DEFAULT => -152
	},
	{#State 280
		ACTIONS => {
			"^" => 360
		},
		DEFAULT => -125
	},
	{#State 281
		ACTIONS => {
			">" => 361
		}
	},
	{#State 282
		ACTIONS => {
			">" => 362
		}
	},
	{#State 283
		ACTIONS => {
			">" => 363
		}
	},
	{#State 284
		ACTIONS => {
			"," => 365,
			">" => 364
		}
	},
	{#State 285
		ACTIONS => {
			">" => 366
		}
	},
	{#State 286
		ACTIONS => {
			"," => 367
		}
	},
	{#State 287
		ACTIONS => {
			"::" => 72,
			'ENUM' => 30,
			'CHAR' => 73,
			'OBJECT' => 77,
			'STRING' => 80,
			'OCTET' => 49,
			'WSTRING' => 82,
			'UNION' => 83,
			'UNSIGNED' => 51,
			'error' => 374,
			'ANY' => 52,
			'FLOAT' => 86,
			'LONG' => 53,
			'SEQUENCE' => 88,
			'IDENTIFIER' => 58,
			'DOUBLE' => 89,
			'SHORT' => 90,
			'BOOLEAN' => 92,
			'STRUCT' => 60,
			'VOID' => 368,
			'FIXED' => 95,
			'VALUEBASE' => 97,
			'WCHAR' => 69
		},
		GOTOS => {
			'union_type' => 47,
			'enum_header' => 5,
			'unsigned_short_int' => 48,
			'struct_type' => 50,
			'union_header' => 7,
			'struct_header' => 12,
			'signed_longlong_int' => 54,
			'enum_type' => 55,
			'any_type' => 56,
			'unsigned_long_int' => 59,
			'scoped_name' => 290,
			'string_type' => 291,
			'char_type' => 63,
			'param_type_spec' => 370,
			'fixed_pt_type' => 369,
			'signed_long_int' => 65,
			'signed_short_int' => 66,
			'wide_char_type' => 68,
			'octet_type' => 70,
			'wide_string_type' => 294,
			'object_type' => 74,
			'integer_type' => 76,
			'sequence_type' => 371,
			'unsigned_int' => 78,
			'op_param_type_spec' => 372,
			'unsigned_longlong_int' => 81,
			'constr_type_spec' => 373,
			'floating_pt_type' => 85,
			'value_base_type' => 87,
			'base_type_spec' => 297,
			'signed_int' => 93,
			'boolean_type' => 96
		}
	},
	{#State 288
		DEFAULT => -41
	},
	{#State 289
		DEFAULT => -39
	},
	{#State 290
		ACTIONS => {
			"::" => 162
		},
		DEFAULT => -340
	},
	{#State 291
		DEFAULT => -338
	},
	{#State 292
		DEFAULT => -302
	},
	{#State 293
		DEFAULT => -304
	},
	{#State 294
		DEFAULT => -339
	},
	{#State 295
		DEFAULT => -303
	},
	{#State 296
		DEFAULT => -301
	},
	{#State 297
		DEFAULT => -337
	},
	{#State 298
		ACTIONS => {
			'IDENTIFIER' => 375,
			'error' => 376
		}
	},
	{#State 299
		DEFAULT => -73
	},
	{#State 300
		DEFAULT => -40
	},
	{#State 301
		ACTIONS => {
			'ENUM' => -318,
			"::" => -318,
			'CHAR' => -318,
			'OBJECT' => -318,
			'STRING' => -318,
			'OCTET' => -318,
			'WSTRING' => -318,
			'UNION' => -318,
			'UNSIGNED' => -318,
			'error' => 382,
			'ANY' => -318,
			'FLOAT' => -318,
			")" => 383,
			'LONG' => -318,
			'SEQUENCE' => -318,
			'IDENTIFIER' => -318,
			'DOUBLE' => -318,
			'SHORT' => -318,
			'BOOLEAN' => -318,
			'INOUT' => 378,
			"..." => 384,
			'STRUCT' => -318,
			'OUT' => 379,
			'IN' => 385,
			'VOID' => -318,
			'FIXED' => -318,
			'VALUEBASE' => -318,
			'WCHAR' => -318
		},
		GOTOS => {
			'param_attribute' => 377,
			'param_dcl' => 380,
			'param_dcls' => 381
		}
	},
	{#State 302
		DEFAULT => -295
	},
	{#State 303
		ACTIONS => {
			'RAISES' => 386
		},
		DEFAULT => -322,
		GOTOS => {
			'raises_expr' => 387
		}
	},
	{#State 304
		DEFAULT => -102
	},
	{#State 305
		DEFAULT => -103
	},
	{#State 306
		DEFAULT => -97
	},
	{#State 307
		ACTIONS => {
			'error' => 390,
			")" => 391,
			'IN' => 393
		},
		GOTOS => {
			'init_param_decl' => 389,
			'init_param_decls' => 392,
			'init_param_attribute' => 388
		}
	},
	{#State 308
		DEFAULT => -101
	},
	{#State 309
		DEFAULT => -43
	},
	{#State 310
		DEFAULT => -42
	},
	{#State 311
		DEFAULT => -71
	},
	{#State 312
		ACTIONS => {
			'IDENTIFIER' => 204,
			'error' => 394
		},
		GOTOS => {
			'declarators' => 395,
			'array_declarator' => 207,
			'simple_declarator' => 203,
			'declarator' => 205,
			'complex_declarator' => 208
		}
	},
	{#State 313
		ACTIONS => {
			";" => 396
		}
	},
	{#State 314
		DEFAULT => -70
	},
	{#State 315
		DEFAULT => -226
	},
	{#State 316
		DEFAULT => -231
	},
	{#State 317
		ACTIONS => {
			";" => 99,
			'error' => 100
		},
		GOTOS => {
			'check_semicolon' => 397
		}
	},
	{#State 318
		DEFAULT => -227
	},
	{#State 319
		DEFAULT => -277
	},
	{#State 320
		ACTIONS => {
			"-" => 251,
			"::" => 72,
			'TRUE' => 264,
			"+" => 265,
			"~" => 252,
			'INTEGER_LITERAL' => 266,
			'FLOATING_PT_LITERAL' => 268,
			'FALSE' => 254,
			'error' => 398,
			'WIDE_STRING_LITERAL' => 270,
			'CHARACTER_LITERAL' => 271,
			'IDENTIFIER' => 58,
			"(" => 261,
			'FIXED_PT_LITERAL' => 275,
			'STRING_LITERAL' => 278,
			'WIDE_CHARACTER_LITERAL' => 263
		},
		GOTOS => {
			'shift_expr' => 267,
			'literal' => 253,
			'const_exp' => 255,
			'unary_operator' => 256,
			'string_literal' => 257,
			'and_expr' => 258,
			'or_expr' => 259,
			'mult_expr' => 272,
			'scoped_name' => 260,
			'boolean_literal' => 273,
			'add_expr' => 274,
			'positive_int_const' => 399,
			'unary_expr' => 262,
			'primary_expr' => 277,
			'wide_string_literal' => 279,
			'xor_expr' => 280
		}
	},
	{#State 321
		ACTIONS => {
			"[" => 320
		},
		DEFAULT => -278,
		GOTOS => {
			'fixed_array_sizes' => 400,
			'fixed_array_size' => 321
		}
	},
	{#State 322
		ACTIONS => {
			'IDENTIFIER' => 204,
			'error' => 103
		},
		GOTOS => {
			'declarators' => 401,
			'array_declarator' => 207,
			'simple_declarator' => 203,
			'declarator' => 205,
			'complex_declarator' => 208
		}
	},
	{#State 323
		ACTIONS => {
			"::" => 72,
			'IDENTIFIER' => 58,
			'error' => 403
		},
		GOTOS => {
			'interface_name' => 405,
			'interface_names' => 404,
			'scoped_name' => 402
		}
	},
	{#State 324
		DEFAULT => -31
	},
	{#State 325
		DEFAULT => -35
	},
	{#State 326
		DEFAULT => -24
	},
	{#State 327
		DEFAULT => -25
	},
	{#State 328
		ACTIONS => {
			'TRUNCATABLE' => 407
		},
		DEFAULT => -82,
		GOTOS => {
			'inheritance_mod' => 406
		}
	},
	{#State 329
		ACTIONS => {
			"::" => 72,
			'IDENTIFIER' => 58,
			'error' => 408
		},
		GOTOS => {
			'interface_name' => 405,
			'interface_names' => 409,
			'scoped_name' => 402
		}
	},
	{#State 330
		DEFAULT => -74
	},
	{#State 331
		DEFAULT => -80
	},
	{#State 332
		DEFAULT => -64
	},
	{#State 333
		DEFAULT => -65
	},
	{#State 334
		DEFAULT => -66
	},
	{#State 335
		DEFAULT => -289
	},
	{#State 336
		DEFAULT => -290
	},
	{#State 337
		DEFAULT => -15
	},
	{#State 338
		DEFAULT => -16
	},
	{#State 339
		DEFAULT => -111
	},
	{#State 340
		ACTIONS => {
			"-" => 251,
			"::" => 72,
			'TRUE' => 264,
			"+" => 265,
			"~" => 252,
			'INTEGER_LITERAL' => 266,
			'FLOATING_PT_LITERAL' => 268,
			'FALSE' => 254,
			'error' => 411,
			'WIDE_STRING_LITERAL' => 270,
			'CHARACTER_LITERAL' => 271,
			'IDENTIFIER' => 58,
			"(" => 261,
			'FIXED_PT_LITERAL' => 275,
			'STRING_LITERAL' => 278,
			'WIDE_CHARACTER_LITERAL' => 263
		},
		GOTOS => {
			'and_expr' => 258,
			'or_expr' => 259,
			'mult_expr' => 272,
			'shift_expr' => 267,
			'scoped_name' => 260,
			'boolean_literal' => 273,
			'add_expr' => 274,
			'literal' => 253,
			'primary_expr' => 277,
			'unary_expr' => 262,
			'unary_operator' => 256,
			'const_exp' => 410,
			'xor_expr' => 280,
			'wide_string_literal' => 279,
			'string_literal' => 257
		}
	},
	{#State 341
		DEFAULT => -262
	},
	{#State 342
		DEFAULT => -236
	},
	{#State 343
		ACTIONS => {
			"{" => 413,
			'error' => 412
		}
	},
	{#State 344
		DEFAULT => -141
	},
	{#State 345
		ACTIONS => {
			"-" => 251,
			"::" => 72,
			'TRUE' => 264,
			'IDENTIFIER' => 58,
			"+" => 265,
			"~" => 252,
			'INTEGER_LITERAL' => 266,
			'FLOATING_PT_LITERAL' => 268,
			'FIXED_PT_LITERAL' => 275,
			"(" => 261,
			'FALSE' => 254,
			'STRING_LITERAL' => 278,
			'WIDE_STRING_LITERAL' => 270,
			'WIDE_CHARACTER_LITERAL' => 263,
			'CHARACTER_LITERAL' => 271
		},
		GOTOS => {
			'mult_expr' => 272,
			'shift_expr' => 414,
			'scoped_name' => 260,
			'boolean_literal' => 273,
			'add_expr' => 274,
			'literal' => 253,
			'primary_expr' => 277,
			'unary_expr' => 262,
			'unary_operator' => 256,
			'wide_string_literal' => 279,
			'string_literal' => 257
		}
	},
	{#State 346
		ACTIONS => {
			"-" => 251,
			"::" => 72,
			'TRUE' => 264,
			'IDENTIFIER' => 58,
			"+" => 265,
			"~" => 252,
			'INTEGER_LITERAL' => 266,
			'FLOATING_PT_LITERAL' => 268,
			'FIXED_PT_LITERAL' => 275,
			"(" => 261,
			'FALSE' => 254,
			'STRING_LITERAL' => 278,
			'WIDE_STRING_LITERAL' => 270,
			'WIDE_CHARACTER_LITERAL' => 263,
			'CHARACTER_LITERAL' => 271
		},
		GOTOS => {
			'and_expr' => 258,
			'mult_expr' => 272,
			'shift_expr' => 267,
			'scoped_name' => 260,
			'boolean_literal' => 273,
			'add_expr' => 274,
			'literal' => 253,
			'primary_expr' => 277,
			'unary_expr' => 262,
			'unary_operator' => 256,
			'xor_expr' => 415,
			'wide_string_literal' => 279,
			'string_literal' => 257
		}
	},
	{#State 347
		ACTIONS => {
			")" => 416
		}
	},
	{#State 348
		ACTIONS => {
			")" => 417
		}
	},
	{#State 349
		ACTIONS => {
			"-" => 251,
			"::" => 72,
			'TRUE' => 264,
			'IDENTIFIER' => 58,
			"+" => 265,
			"~" => 252,
			'INTEGER_LITERAL' => 266,
			'FLOATING_PT_LITERAL' => 268,
			'FIXED_PT_LITERAL' => 275,
			"(" => 261,
			'FALSE' => 254,
			'STRING_LITERAL' => 278,
			'WIDE_STRING_LITERAL' => 270,
			'WIDE_CHARACTER_LITERAL' => 263,
			'CHARACTER_LITERAL' => 271
		},
		GOTOS => {
			'mult_expr' => 272,
			'scoped_name' => 260,
			'boolean_literal' => 273,
			'literal' => 253,
			'add_expr' => 418,
			'primary_expr' => 277,
			'unary_expr' => 262,
			'unary_operator' => 256,
			'wide_string_literal' => 279,
			'string_literal' => 257
		}
	},
	{#State 350
		ACTIONS => {
			"-" => 251,
			"::" => 72,
			'TRUE' => 264,
			'IDENTIFIER' => 58,
			"+" => 265,
			"~" => 252,
			'INTEGER_LITERAL' => 266,
			'FLOATING_PT_LITERAL' => 268,
			'FIXED_PT_LITERAL' => 275,
			"(" => 261,
			'FALSE' => 254,
			'STRING_LITERAL' => 278,
			'WIDE_STRING_LITERAL' => 270,
			'WIDE_CHARACTER_LITERAL' => 263,
			'CHARACTER_LITERAL' => 271
		},
		GOTOS => {
			'mult_expr' => 272,
			'scoped_name' => 260,
			'boolean_literal' => 273,
			'literal' => 253,
			'add_expr' => 419,
			'primary_expr' => 277,
			'unary_expr' => 262,
			'unary_operator' => 256,
			'wide_string_literal' => 279,
			'string_literal' => 257
		}
	},
	{#State 351
		DEFAULT => -273
	},
	{#State 352
		DEFAULT => -161
	},
	{#State 353
		ACTIONS => {
			"-" => 251,
			"::" => 72,
			'TRUE' => 264,
			'IDENTIFIER' => 58,
			"+" => 265,
			"~" => 252,
			'INTEGER_LITERAL' => 266,
			'FLOATING_PT_LITERAL' => 268,
			'FIXED_PT_LITERAL' => 275,
			"(" => 261,
			'FALSE' => 254,
			'STRING_LITERAL' => 278,
			'WIDE_STRING_LITERAL' => 270,
			'WIDE_CHARACTER_LITERAL' => 263,
			'CHARACTER_LITERAL' => 271
		},
		GOTOS => {
			'literal' => 253,
			'primary_expr' => 277,
			'unary_expr' => 420,
			'unary_operator' => 256,
			'scoped_name' => 260,
			'wide_string_literal' => 279,
			'boolean_literal' => 273,
			'string_literal' => 257
		}
	},
	{#State 354
		ACTIONS => {
			"-" => 251,
			"::" => 72,
			'TRUE' => 264,
			'IDENTIFIER' => 58,
			"+" => 265,
			"~" => 252,
			'INTEGER_LITERAL' => 266,
			'FLOATING_PT_LITERAL' => 268,
			'FIXED_PT_LITERAL' => 275,
			"(" => 261,
			'FALSE' => 254,
			'STRING_LITERAL' => 278,
			'WIDE_STRING_LITERAL' => 270,
			'WIDE_CHARACTER_LITERAL' => 263,
			'CHARACTER_LITERAL' => 271
		},
		GOTOS => {
			'literal' => 253,
			'primary_expr' => 277,
			'unary_expr' => 421,
			'unary_operator' => 256,
			'scoped_name' => 260,
			'wide_string_literal' => 279,
			'boolean_literal' => 273,
			'string_literal' => 257
		}
	},
	{#State 355
		ACTIONS => {
			"-" => 251,
			"::" => 72,
			'TRUE' => 264,
			'IDENTIFIER' => 58,
			"+" => 265,
			"~" => 252,
			'INTEGER_LITERAL' => 266,
			'FLOATING_PT_LITERAL' => 268,
			'FIXED_PT_LITERAL' => 275,
			"(" => 261,
			'FALSE' => 254,
			'STRING_LITERAL' => 278,
			'WIDE_STRING_LITERAL' => 270,
			'WIDE_CHARACTER_LITERAL' => 263,
			'CHARACTER_LITERAL' => 271
		},
		GOTOS => {
			'literal' => 253,
			'primary_expr' => 277,
			'unary_expr' => 422,
			'unary_operator' => 256,
			'scoped_name' => 260,
			'wide_string_literal' => 279,
			'boolean_literal' => 273,
			'string_literal' => 257
		}
	},
	{#State 356
		ACTIONS => {
			"-" => 251,
			"::" => 72,
			'TRUE' => 264,
			'IDENTIFIER' => 58,
			"+" => 265,
			"~" => 252,
			'INTEGER_LITERAL' => 266,
			'FLOATING_PT_LITERAL' => 268,
			'FIXED_PT_LITERAL' => 275,
			"(" => 261,
			'FALSE' => 254,
			'STRING_LITERAL' => 278,
			'WIDE_STRING_LITERAL' => 270,
			'WIDE_CHARACTER_LITERAL' => 263,
			'CHARACTER_LITERAL' => 271
		},
		GOTOS => {
			'mult_expr' => 423,
			'scoped_name' => 260,
			'boolean_literal' => 273,
			'literal' => 253,
			'unary_expr' => 262,
			'primary_expr' => 277,
			'unary_operator' => 256,
			'wide_string_literal' => 279,
			'string_literal' => 257
		}
	},
	{#State 357
		ACTIONS => {
			"-" => 251,
			"::" => 72,
			'TRUE' => 264,
			'IDENTIFIER' => 58,
			"+" => 265,
			"~" => 252,
			'INTEGER_LITERAL' => 266,
			'FLOATING_PT_LITERAL' => 268,
			'FIXED_PT_LITERAL' => 275,
			"(" => 261,
			'FALSE' => 254,
			'STRING_LITERAL' => 278,
			'WIDE_STRING_LITERAL' => 270,
			'WIDE_CHARACTER_LITERAL' => 263,
			'CHARACTER_LITERAL' => 271
		},
		GOTOS => {
			'mult_expr' => 424,
			'scoped_name' => 260,
			'boolean_literal' => 273,
			'literal' => 253,
			'unary_expr' => 262,
			'primary_expr' => 277,
			'unary_operator' => 256,
			'wide_string_literal' => 279,
			'string_literal' => 257
		}
	},
	{#State 358
		DEFAULT => -271
	},
	{#State 359
		DEFAULT => -159
	},
	{#State 360
		ACTIONS => {
			"-" => 251,
			"::" => 72,
			'TRUE' => 264,
			'IDENTIFIER' => 58,
			"+" => 265,
			"~" => 252,
			'INTEGER_LITERAL' => 266,
			'FLOATING_PT_LITERAL' => 268,
			'FIXED_PT_LITERAL' => 275,
			"(" => 261,
			'FALSE' => 254,
			'STRING_LITERAL' => 278,
			'WIDE_STRING_LITERAL' => 270,
			'WIDE_CHARACTER_LITERAL' => 263,
			'CHARACTER_LITERAL' => 271
		},
		GOTOS => {
			'and_expr' => 425,
			'mult_expr' => 272,
			'shift_expr' => 267,
			'scoped_name' => 260,
			'boolean_literal' => 273,
			'add_expr' => 274,
			'literal' => 253,
			'primary_expr' => 277,
			'unary_expr' => 262,
			'unary_operator' => 256,
			'wide_string_literal' => 279,
			'string_literal' => 257
		}
	},
	{#State 361
		DEFAULT => -276
	},
	{#State 362
		DEFAULT => -274
	},
	{#State 363
		DEFAULT => -269
	},
	{#State 364
		DEFAULT => -268
	},
	{#State 365
		ACTIONS => {
			"-" => 251,
			"::" => 72,
			'TRUE' => 264,
			"+" => 265,
			"~" => 252,
			'INTEGER_LITERAL' => 266,
			'FLOATING_PT_LITERAL' => 268,
			'FALSE' => 254,
			'error' => 426,
			'WIDE_STRING_LITERAL' => 270,
			'CHARACTER_LITERAL' => 271,
			'IDENTIFIER' => 58,
			"(" => 261,
			'FIXED_PT_LITERAL' => 275,
			'STRING_LITERAL' => 278,
			'WIDE_CHARACTER_LITERAL' => 263
		},
		GOTOS => {
			'shift_expr' => 267,
			'literal' => 253,
			'const_exp' => 255,
			'unary_operator' => 256,
			'string_literal' => 257,
			'and_expr' => 258,
			'or_expr' => 259,
			'mult_expr' => 272,
			'scoped_name' => 260,
			'boolean_literal' => 273,
			'add_expr' => 274,
			'positive_int_const' => 427,
			'unary_expr' => 262,
			'primary_expr' => 277,
			'wide_string_literal' => 279,
			'xor_expr' => 280
		}
	},
	{#State 366
		DEFAULT => -343
	},
	{#State 367
		ACTIONS => {
			"-" => 251,
			"::" => 72,
			'TRUE' => 264,
			"+" => 265,
			"~" => 252,
			'INTEGER_LITERAL' => 266,
			'FLOATING_PT_LITERAL' => 268,
			'FALSE' => 254,
			'error' => 428,
			'WIDE_STRING_LITERAL' => 270,
			'CHARACTER_LITERAL' => 271,
			'IDENTIFIER' => 58,
			"(" => 261,
			'FIXED_PT_LITERAL' => 275,
			'STRING_LITERAL' => 278,
			'WIDE_CHARACTER_LITERAL' => 263
		},
		GOTOS => {
			'shift_expr' => 267,
			'literal' => 253,
			'const_exp' => 255,
			'unary_operator' => 256,
			'string_literal' => 257,
			'and_expr' => 258,
			'or_expr' => 259,
			'mult_expr' => 272,
			'scoped_name' => 260,
			'boolean_literal' => 273,
			'add_expr' => 274,
			'positive_int_const' => 429,
			'unary_expr' => 262,
			'primary_expr' => 277,
			'wide_string_literal' => 279,
			'xor_expr' => 280
		}
	},
	{#State 368
		DEFAULT => -333
	},
	{#State 369
		DEFAULT => -335
	},
	{#State 370
		ACTIONS => {
			'IDENTIFIER' => 102,
			'error' => 103
		},
		GOTOS => {
			'simple_declarators' => 431,
			'simple_declarator' => 430
		}
	},
	{#State 371
		DEFAULT => -334
	},
	{#State 372
		DEFAULT => -332
	},
	{#State 373
		DEFAULT => -336
	},
	{#State 374
		DEFAULT => -283
	},
	{#State 375
		DEFAULT => -296
	},
	{#State 376
		DEFAULT => -297
	},
	{#State 377
		ACTIONS => {
			"::" => 72,
			'ENUM' => 30,
			'CHAR' => 73,
			'OBJECT' => 77,
			'STRING' => 80,
			'OCTET' => 49,
			'WSTRING' => 82,
			'UNION' => 83,
			'UNSIGNED' => 51,
			'ANY' => 52,
			'FLOAT' => 86,
			'LONG' => 53,
			'SEQUENCE' => 88,
			'IDENTIFIER' => 58,
			'DOUBLE' => 89,
			'SHORT' => 90,
			'BOOLEAN' => 92,
			'STRUCT' => 60,
			'VOID' => 368,
			'FIXED' => 95,
			'VALUEBASE' => 97,
			'WCHAR' => 69
		},
		GOTOS => {
			'union_type' => 47,
			'enum_header' => 5,
			'unsigned_short_int' => 48,
			'struct_type' => 50,
			'union_header' => 7,
			'struct_header' => 12,
			'signed_longlong_int' => 54,
			'enum_type' => 55,
			'any_type' => 56,
			'unsigned_long_int' => 59,
			'scoped_name' => 290,
			'string_type' => 291,
			'char_type' => 63,
			'param_type_spec' => 432,
			'fixed_pt_type' => 369,
			'signed_long_int' => 65,
			'signed_short_int' => 66,
			'wide_char_type' => 68,
			'octet_type' => 70,
			'wide_string_type' => 294,
			'object_type' => 74,
			'integer_type' => 76,
			'sequence_type' => 371,
			'unsigned_int' => 78,
			'op_param_type_spec' => 372,
			'unsigned_longlong_int' => 81,
			'constr_type_spec' => 373,
			'floating_pt_type' => 85,
			'value_base_type' => 87,
			'base_type_spec' => 297,
			'signed_int' => 93,
			'boolean_type' => 96
		}
	},
	{#State 378
		DEFAULT => -317
	},
	{#State 379
		DEFAULT => -316
	},
	{#State 380
		ACTIONS => {
			";" => 433
		},
		DEFAULT => -311
	},
	{#State 381
		ACTIONS => {
			"," => 434,
			")" => 435
		}
	},
	{#State 382
		ACTIONS => {
			")" => 436
		}
	},
	{#State 383
		DEFAULT => -308
	},
	{#State 384
		ACTIONS => {
			")" => 437
		}
	},
	{#State 385
		DEFAULT => -315
	},
	{#State 386
		ACTIONS => {
			"(" => 438,
			'error' => 439
		}
	},
	{#State 387
		ACTIONS => {
			'CONTEXT' => 441
		},
		DEFAULT => -329,
		GOTOS => {
			'context_expr' => 440
		}
	},
	{#State 388
		ACTIONS => {
			"::" => 72,
			'ENUM' => 30,
			'CHAR' => 73,
			'OBJECT' => 77,
			'STRING' => 80,
			'OCTET' => 49,
			'WSTRING' => 82,
			'UNION' => 83,
			'UNSIGNED' => 51,
			'error' => 443,
			'ANY' => 52,
			'FLOAT' => 86,
			'LONG' => 53,
			'SEQUENCE' => 88,
			'IDENTIFIER' => 58,
			'DOUBLE' => 89,
			'SHORT' => 90,
			'BOOLEAN' => 92,
			'STRUCT' => 60,
			'VOID' => 368,
			'FIXED' => 95,
			'VALUEBASE' => 97,
			'WCHAR' => 69
		},
		GOTOS => {
			'union_type' => 47,
			'enum_header' => 5,
			'unsigned_short_int' => 48,
			'struct_type' => 50,
			'union_header' => 7,
			'struct_header' => 12,
			'signed_longlong_int' => 54,
			'enum_type' => 55,
			'any_type' => 56,
			'unsigned_long_int' => 59,
			'scoped_name' => 290,
			'string_type' => 291,
			'char_type' => 63,
			'param_type_spec' => 442,
			'fixed_pt_type' => 369,
			'signed_long_int' => 65,
			'signed_short_int' => 66,
			'wide_char_type' => 68,
			'octet_type' => 70,
			'wide_string_type' => 294,
			'object_type' => 74,
			'integer_type' => 76,
			'sequence_type' => 371,
			'unsigned_int' => 78,
			'op_param_type_spec' => 372,
			'unsigned_longlong_int' => 81,
			'constr_type_spec' => 373,
			'floating_pt_type' => 85,
			'value_base_type' => 87,
			'base_type_spec' => 297,
			'signed_int' => 93,
			'boolean_type' => 96
		}
	},
	{#State 389
		ACTIONS => {
			"," => 444
		},
		DEFAULT => -104
	},
	{#State 390
		ACTIONS => {
			")" => 445
		}
	},
	{#State 391
		DEFAULT => -98
	},
	{#State 392
		ACTIONS => {
			")" => 446
		}
	},
	{#State 393
		DEFAULT => -108
	},
	{#State 394
		ACTIONS => {
			";" => 447,
			"," => 174
		}
	},
	{#State 395
		ACTIONS => {
			";" => 99,
			'error' => 100
		},
		GOTOS => {
			'check_semicolon' => 448
		}
	},
	{#State 396
		DEFAULT => -94
	},
	{#State 397
		DEFAULT => -232
	},
	{#State 398
		ACTIONS => {
			"]" => 449
		}
	},
	{#State 399
		ACTIONS => {
			"]" => 450
		}
	},
	{#State 400
		DEFAULT => -279
	},
	{#State 401
		DEFAULT => -196
	},
	{#State 402
		ACTIONS => {
			"::" => 162
		},
		DEFAULT => -49
	},
	{#State 403
		DEFAULT => -45
	},
	{#State 404
		DEFAULT => -44
	},
	{#State 405
		ACTIONS => {
			"," => 451
		},
		DEFAULT => -47
	},
	{#State 406
		ACTIONS => {
			"::" => 72,
			'IDENTIFIER' => 58,
			'error' => 455
		},
		GOTOS => {
			'value_name' => 452,
			'value_names' => 453,
			'scoped_name' => 454
		}
	},
	{#State 407
		DEFAULT => -81
	},
	{#State 408
		DEFAULT => -86
	},
	{#State 409
		DEFAULT => -85
	},
	{#State 410
		DEFAULT => -109
	},
	{#State 411
		DEFAULT => -110
	},
	{#State 412
		DEFAULT => -235
	},
	{#State 413
		ACTIONS => {
			'DEFAULT' => 461,
			'error' => 459,
			'CASE' => 456
		},
		GOTOS => {
			'case_label' => 462,
			'switch_body' => 457,
			'case' => 458,
			'case_labels' => 460
		}
	},
	{#State 414
		ACTIONS => {
			"<<" => 350,
			">>" => 349
		},
		DEFAULT => -130
	},
	{#State 415
		ACTIONS => {
			"^" => 360
		},
		DEFAULT => -126
	},
	{#State 416
		DEFAULT => -148
	},
	{#State 417
		DEFAULT => -149
	},
	{#State 418
		ACTIONS => {
			"-" => 356,
			"+" => 357
		},
		DEFAULT => -132
	},
	{#State 419
		ACTIONS => {
			"-" => 356,
			"+" => 357
		},
		DEFAULT => -133
	},
	{#State 420
		DEFAULT => -140
	},
	{#State 421
		DEFAULT => -138
	},
	{#State 422
		DEFAULT => -139
	},
	{#State 423
		ACTIONS => {
			"%" => 353,
			"*" => 354,
			"/" => 355
		},
		DEFAULT => -136
	},
	{#State 424
		ACTIONS => {
			"%" => 353,
			"*" => 354,
			"/" => 355
		},
		DEFAULT => -135
	},
	{#State 425
		ACTIONS => {
			"&" => 345
		},
		DEFAULT => -128
	},
	{#State 426
		ACTIONS => {
			">" => 463
		}
	},
	{#State 427
		ACTIONS => {
			">" => 464
		}
	},
	{#State 428
		ACTIONS => {
			">" => 465
		}
	},
	{#State 429
		ACTIONS => {
			">" => 466
		}
	},
	{#State 430
		ACTIONS => {
			"," => 467
		},
		DEFAULT => -286
	},
	{#State 431
		DEFAULT => -282
	},
	{#State 432
		ACTIONS => {
			'IDENTIFIER' => 102,
			'error' => 103
		},
		GOTOS => {
			'simple_declarator' => 468
		}
	},
	{#State 433
		DEFAULT => -313
	},
	{#State 434
		ACTIONS => {
			")" => 470,
			'INOUT' => 378,
			"..." => 471,
			'OUT' => 379,
			'IN' => 385
		},
		DEFAULT => -318,
		GOTOS => {
			'param_attribute' => 377,
			'param_dcl' => 469
		}
	},
	{#State 435
		DEFAULT => -305
	},
	{#State 436
		DEFAULT => -310
	},
	{#State 437
		DEFAULT => -309
	},
	{#State 438
		ACTIONS => {
			"::" => 72,
			'IDENTIFIER' => 58,
			'error' => 473
		},
		GOTOS => {
			'exception_names' => 474,
			'scoped_name' => 472,
			'exception_name' => 475
		}
	},
	{#State 439
		DEFAULT => -321
	},
	{#State 440
		DEFAULT => -294
	},
	{#State 441
		ACTIONS => {
			"(" => 476,
			'error' => 477
		}
	},
	{#State 442
		ACTIONS => {
			'IDENTIFIER' => 102,
			'error' => 103
		},
		GOTOS => {
			'simple_declarator' => 478
		}
	},
	{#State 443
		DEFAULT => -107
	},
	{#State 444
		ACTIONS => {
			'IN' => 393
		},
		GOTOS => {
			'init_param_decl' => 389,
			'init_param_decls' => 479,
			'init_param_attribute' => 388
		}
	},
	{#State 445
		DEFAULT => -100
	},
	{#State 446
		DEFAULT => -99
	},
	{#State 447
		ACTIONS => {
			";" => -201,
			"," => -201,
			'error' => -201
		},
		DEFAULT => -93
	},
	{#State 448
		DEFAULT => -92
	},
	{#State 449
		DEFAULT => -281
	},
	{#State 450
		DEFAULT => -280
	},
	{#State 451
		ACTIONS => {
			"::" => 72,
			'IDENTIFIER' => 58
		},
		GOTOS => {
			'interface_name' => 405,
			'interface_names' => 480,
			'scoped_name' => 402
		}
	},
	{#State 452
		ACTIONS => {
			"," => 481
		},
		DEFAULT => -83
	},
	{#State 453
		ACTIONS => {
			'SUPPORTS' => 329
		},
		DEFAULT => -87,
		GOTOS => {
			'supported_interface_spec' => 482
		}
	},
	{#State 454
		ACTIONS => {
			"::" => 162
		},
		DEFAULT => -88
	},
	{#State 455
		DEFAULT => -79
	},
	{#State 456
		ACTIONS => {
			"-" => 251,
			"::" => 72,
			'TRUE' => 264,
			"+" => 265,
			"~" => 252,
			'INTEGER_LITERAL' => 266,
			'FLOATING_PT_LITERAL' => 268,
			'FALSE' => 254,
			'error' => 484,
			'WIDE_STRING_LITERAL' => 270,
			'CHARACTER_LITERAL' => 271,
			'IDENTIFIER' => 58,
			"(" => 261,
			'FIXED_PT_LITERAL' => 275,
			'STRING_LITERAL' => 278,
			'WIDE_CHARACTER_LITERAL' => 263
		},
		GOTOS => {
			'and_expr' => 258,
			'or_expr' => 259,
			'mult_expr' => 272,
			'shift_expr' => 267,
			'scoped_name' => 260,
			'boolean_literal' => 273,
			'add_expr' => 274,
			'literal' => 253,
			'primary_expr' => 277,
			'unary_expr' => 262,
			'unary_operator' => 256,
			'const_exp' => 483,
			'xor_expr' => 280,
			'wide_string_literal' => 279,
			'string_literal' => 257
		}
	},
	{#State 457
		ACTIONS => {
			"}" => 485
		}
	},
	{#State 458
		ACTIONS => {
			'DEFAULT' => 461,
			'CASE' => 456
		},
		DEFAULT => -245,
		GOTOS => {
			'case_label' => 462,
			'switch_body' => 486,
			'case' => 458,
			'case_labels' => 460
		}
	},
	{#State 459
		ACTIONS => {
			"}" => 487
		}
	},
	{#State 460
		ACTIONS => {
			"::" => 72,
			'ENUM' => 30,
			'CHAR' => 73,
			'OBJECT' => 77,
			'STRING' => 80,
			'OCTET' => 49,
			'WSTRING' => 82,
			'UNION' => 83,
			'UNSIGNED' => 51,
			'ANY' => 52,
			'FLOAT' => 86,
			'LONG' => 53,
			'SEQUENCE' => 88,
			'IDENTIFIER' => 58,
			'DOUBLE' => 89,
			'SHORT' => 90,
			'BOOLEAN' => 92,
			'STRUCT' => 60,
			'VOID' => 64,
			'FIXED' => 95,
			'VALUEBASE' => 97,
			'WCHAR' => 69
		},
		GOTOS => {
			'union_type' => 47,
			'enum_header' => 5,
			'unsigned_short_int' => 48,
			'struct_type' => 50,
			'union_header' => 7,
			'struct_header' => 12,
			'signed_longlong_int' => 54,
			'enum_type' => 55,
			'any_type' => 56,
			'template_type_spec' => 57,
			'element_spec' => 488,
			'unsigned_long_int' => 59,
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
			'type_spec' => 489,
			'integer_type' => 76,
			'unsigned_int' => 78,
			'sequence_type' => 79,
			'unsigned_longlong_int' => 81,
			'constr_type_spec' => 84,
			'floating_pt_type' => 85,
			'value_base_type' => 87,
			'base_type_spec' => 91,
			'signed_int' => 93,
			'simple_type_spec' => 94,
			'boolean_type' => 96
		}
	},
	{#State 461
		ACTIONS => {
			":" => 490,
			'error' => 491
		}
	},
	{#State 462
		ACTIONS => {
			'CASE' => 456,
			'DEFAULT' => 461
		},
		DEFAULT => -248,
		GOTOS => {
			'case_label' => 462,
			'case_labels' => 492
		}
	},
	{#State 463
		DEFAULT => -267
	},
	{#State 464
		DEFAULT => -266
	},
	{#State 465
		DEFAULT => -342
	},
	{#State 466
		DEFAULT => -341
	},
	{#State 467
		ACTIONS => {
			'IDENTIFIER' => 102,
			'error' => 103
		},
		GOTOS => {
			'simple_declarators' => 493,
			'simple_declarator' => 430
		}
	},
	{#State 468
		DEFAULT => -314
	},
	{#State 469
		DEFAULT => -312
	},
	{#State 470
		DEFAULT => -307
	},
	{#State 471
		ACTIONS => {
			")" => 494
		}
	},
	{#State 472
		ACTIONS => {
			"::" => 162
		},
		DEFAULT => -325
	},
	{#State 473
		ACTIONS => {
			")" => 495
		}
	},
	{#State 474
		ACTIONS => {
			")" => 496
		}
	},
	{#State 475
		ACTIONS => {
			"," => 497
		},
		DEFAULT => -323
	},
	{#State 476
		ACTIONS => {
			'STRING_LITERAL' => 278,
			'error' => 500
		},
		GOTOS => {
			'string_literals' => 499,
			'string_literal' => 498
		}
	},
	{#State 477
		DEFAULT => -328
	},
	{#State 478
		DEFAULT => -106
	},
	{#State 479
		DEFAULT => -105
	},
	{#State 480
		DEFAULT => -48
	},
	{#State 481
		ACTIONS => {
			"::" => 72,
			'IDENTIFIER' => 58
		},
		GOTOS => {
			'value_name' => 452,
			'value_names' => 501,
			'scoped_name' => 454
		}
	},
	{#State 482
		DEFAULT => -78
	},
	{#State 483
		ACTIONS => {
			":" => 502,
			'error' => 503
		}
	},
	{#State 484
		DEFAULT => -252
	},
	{#State 485
		DEFAULT => -233
	},
	{#State 486
		DEFAULT => -246
	},
	{#State 487
		DEFAULT => -234
	},
	{#State 488
		ACTIONS => {
			";" => 99,
			'error' => 100
		},
		GOTOS => {
			'check_semicolon' => 504
		}
	},
	{#State 489
		ACTIONS => {
			'IDENTIFIER' => 204,
			'error' => 103
		},
		GOTOS => {
			'array_declarator' => 207,
			'simple_declarator' => 203,
			'declarator' => 505,
			'complex_declarator' => 208
		}
	},
	{#State 490
		DEFAULT => -253
	},
	{#State 491
		DEFAULT => -254
	},
	{#State 492
		DEFAULT => -249
	},
	{#State 493
		DEFAULT => -287
	},
	{#State 494
		DEFAULT => -306
	},
	{#State 495
		DEFAULT => -320
	},
	{#State 496
		DEFAULT => -319
	},
	{#State 497
		ACTIONS => {
			"::" => 72,
			'IDENTIFIER' => 58
		},
		GOTOS => {
			'exception_names' => 506,
			'scoped_name' => 472,
			'exception_name' => 475
		}
	},
	{#State 498
		ACTIONS => {
			"," => 507
		},
		DEFAULT => -330
	},
	{#State 499
		ACTIONS => {
			")" => 508
		}
	},
	{#State 500
		ACTIONS => {
			")" => 509
		}
	},
	{#State 501
		DEFAULT => -84
	},
	{#State 502
		DEFAULT => -250
	},
	{#State 503
		DEFAULT => -251
	},
	{#State 504
		DEFAULT => -247
	},
	{#State 505
		DEFAULT => -255
	},
	{#State 506
		DEFAULT => -324
	},
	{#State 507
		ACTIONS => {
			'STRING_LITERAL' => 278
		},
		GOTOS => {
			'string_literals' => 510,
			'string_literal' => 498
		}
	},
	{#State 508
		DEFAULT => -326
	},
	{#State 509
		DEFAULT => -327
	},
	{#State 510
		DEFAULT => -331
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
#line 70 "Parser24.yp"
{
            $_[0]->YYData->{root} = new CORBA::IDL::Specification($_[0],
                    'list_decl'         =>  $_[1],
            );
        }
	],
	[#Rule 2
		 'specification', 0,
sub
#line 76 "Parser24.yp"
{
            $_[0]->Error("Empty specification.\n");
        }
	],
	[#Rule 3
		 'specification', 1,
sub
#line 80 "Parser24.yp"
{
            $_[0]->Error("definition declaration expected.\n");
        }
	],
	[#Rule 4
		 'definitions', 1,
sub
#line 87 "Parser24.yp"
{
            [$_[1]->getRef()];
        }
	],
	[#Rule 5
		 'definitions', 2,
sub
#line 91 "Parser24.yp"
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
		 'definition', 2, undef
	],
	[#Rule 12
		 'definition', 3,
sub
#line 112 "Parser24.yp"
{
            # when IDENTIFIER is a future keyword
            $_[0]->Error("'$_[1]' unexpected.\n");
            $_[0]->YYErrok();
            new CORBA::IDL::Node($_[0],
                    'idf'                   =>  $_[1]
            );
        }
	],
	[#Rule 13
		 'check_semicolon', 1, undef
	],
	[#Rule 14
		 'check_semicolon', 1,
sub
#line 126 "Parser24.yp"
{
            $_[0]->Warning("';' expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 15
		 'module', 4,
sub
#line 135 "Parser24.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
            $_[1]->Configure($_[0],
                    'list_decl'         =>  $_[3]
            ) if (defined $_[1]);
        }
	],
	[#Rule 16
		 'module', 4,
sub
#line 142 "Parser24.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
            $_[0]->Error("definition declaration expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 17
		 'module', 3,
sub
#line 149 "Parser24.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
            $_[0]->Error("Empty module.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 18
		 'module', 3,
sub
#line 156 "Parser24.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
            $_[0]->Error("'\x7b' expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 19
		 'module_header', 2,
sub
#line 166 "Parser24.yp"
{
            new CORBA::IDL::Module($_[0],
                    'idf'               =>  $_[2],
            );
        }
	],
	[#Rule 20
		 'module_header', 2,
sub
#line 172 "Parser24.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 21
		 'interface', 1, undef
	],
	[#Rule 22
		 'interface', 1, undef
	],
	[#Rule 23
		 'interface_dcl', 3,
sub
#line 189 "Parser24.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->YYData->{curr_itf} = undef;
            $_[1]->Configure($_[0],
                    'list_decl'     =>  []
            ) if (defined $_[1]);
        }
	],
	[#Rule 24
		 'interface_dcl', 4,
sub
#line 197 "Parser24.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->YYData->{curr_itf} = undef;
            $_[1]->Configure($_[0],
                    'list_decl'     =>  $_[3]
            ) if (defined $_[1]);
        }
	],
	[#Rule 25
		 'interface_dcl', 4,
sub
#line 205 "Parser24.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->YYData->{curr_itf} = undef;
            $_[0]->Error("export declaration expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 26
		 'forward_dcl', 3,
sub
#line 217 "Parser24.yp"
{
            if (defined $_[1] and $_[1] eq 'abstract') {
                new CORBA::IDL::ForwardAbstractInterface($_[0],
                        'idf'                   =>  $_[3]
                );
            }
            elsif (defined $_[1] and $_[1] eq 'local') {
                new CORBA::IDL::ForwardLocalInterface($_[0],
                        'idf'                   =>  $_[3]
                );
            }
            else {
                new CORBA::IDL::ForwardRegularInterface($_[0],
                        'idf'                   =>  $_[3]
                );
            }
        }
	],
	[#Rule 27
		 'forward_dcl', 3,
sub
#line 235 "Parser24.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 28
		 'interface_mod', 1, undef
	],
	[#Rule 29
		 'interface_mod', 1, undef
	],
	[#Rule 30
		 'interface_mod', 0, undef
	],
	[#Rule 31
		 'interface_header', 4,
sub
#line 253 "Parser24.yp"
{
            if (defined $_[1] and $_[1] eq 'abstract') {
                new CORBA::IDL::AbstractInterface($_[0],
                        'idf'                   =>  $_[3],
                        'inheritance'           =>  $_[4]
                );
            }
            elsif (defined $_[1] and $_[1] eq 'local') {
                new CORBA::IDL::LocalInterface($_[0],
                        'idf'                   =>  $_[3],
                        'inheritance'           =>  $_[4]
                );
            }
            else {
                new CORBA::IDL::RegularInterface($_[0],
                        'idf'                   =>  $_[3],
                        'inheritance'           =>  $_[4]
                );
            }
        }
	],
	[#Rule 32
		 'interface_header', 3,
sub
#line 274 "Parser24.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 33
		 'interface_body', 1, undef
	],
	[#Rule 34
		 'exports', 1,
sub
#line 288 "Parser24.yp"
{
            [$_[1]->getRef()];
        }
	],
	[#Rule 35
		 'exports', 2,
sub
#line 292 "Parser24.yp"
{
            unshift @{$_[2]}, $_[1]->getRef();
            $_[2];
        }
	],
	[#Rule 36
		 '_export', 1, undef
	],
	[#Rule 37
		 '_export', 1,
sub
#line 303 "Parser24.yp"
{
            $_[0]->Error("state member unexpected.\n");
            $_[1];                      #default action
        }
	],
	[#Rule 38
		 '_export', 1,
sub
#line 308 "Parser24.yp"
{
            $_[0]->Error("initializer unexpected.\n");
            $_[1];                      #default action
        }
	],
	[#Rule 39
		 'export', 2, undef
	],
	[#Rule 40
		 'export', 2, undef
	],
	[#Rule 41
		 'export', 2, undef
	],
	[#Rule 42
		 'export', 2, undef
	],
	[#Rule 43
		 'export', 2, undef
	],
	[#Rule 44
		 'interface_inheritance_spec', 2,
sub
#line 330 "Parser24.yp"
{
            new CORBA::IDL::InheritanceSpec($_[0],
                    'list_interface'        =>  $_[2]
            );
        }
	],
	[#Rule 45
		 'interface_inheritance_spec', 2,
sub
#line 336 "Parser24.yp"
{
            $_[0]->Error("Interface name expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 46
		 'interface_inheritance_spec', 0, undef
	],
	[#Rule 47
		 'interface_names', 1,
sub
#line 346 "Parser24.yp"
{
            [$_[1]];
        }
	],
	[#Rule 48
		 'interface_names', 3,
sub
#line 350 "Parser24.yp"
{
            unshift @{$_[3]}, $_[1];
            $_[3];
        }
	],
	[#Rule 49
		 'interface_name', 1,
sub
#line 359 "Parser24.yp"
{
                CORBA::IDL::Interface->Lookup($_[0], $_[1]);
        }
	],
	[#Rule 50
		 'scoped_name', 1, undef
	],
	[#Rule 51
		 'scoped_name', 2,
sub
#line 369 "Parser24.yp"
{
            $_[1] . $_[2];
        }
	],
	[#Rule 52
		 'scoped_name', 2,
sub
#line 373 "Parser24.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
            '';
        }
	],
	[#Rule 53
		 'scoped_name', 3,
sub
#line 379 "Parser24.yp"
{
            $_[1] . $_[2] . $_[3];
        }
	],
	[#Rule 54
		 'scoped_name', 3,
sub
#line 383 "Parser24.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 55
		 'value', 1, undef
	],
	[#Rule 56
		 'value', 1, undef
	],
	[#Rule 57
		 'value', 1, undef
	],
	[#Rule 58
		 'value', 1, undef
	],
	[#Rule 59
		 'value_forward_dcl', 3,
sub
#line 405 "Parser24.yp"
{
            $_[0]->Warning("CUSTOM unexpected.\n")
                    if (defined $_[1]);
            new CORBA::IDL::ForwardRegularValue($_[0],
                    'idf'               =>  $_[3]
            );
        }
	],
	[#Rule 60
		 'value_forward_dcl', 3,
sub
#line 413 "Parser24.yp"
{
            new CORBA::IDL::ForwardAbstractValue($_[0],
                    'idf'               =>  $_[3]
            );
        }
	],
	[#Rule 61
		 'value_box_dcl', 2,
sub
#line 423 "Parser24.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->YYData->{curr_itf} = undef;
            $_[1]->Configure($_[0],
                    'type'              =>  $_[2]
            ) if (defined $_[1]);
        }
	],
	[#Rule 62
		 'value_box_header', 3,
sub
#line 434 "Parser24.yp"
{
            $_[0]->Warning("CUSTOM unexpected.\n")
                    if (defined $_[1]);
            new CORBA::IDL::BoxedValue($_[0],
                    'idf'               =>  $_[3],
            );
        }
	],
	[#Rule 63
		 'value_abs_dcl', 3,
sub
#line 446 "Parser24.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->YYData->{curr_itf} = undef;
            $_[1]->Configure($_[0],
                    'list_decl'     =>  []
            ) if (defined $_[1]);
        }
	],
	[#Rule 64
		 'value_abs_dcl', 4,
sub
#line 454 "Parser24.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->YYData->{curr_itf} = undef;
            $_[1]->Configure($_[0],
                    'list_decl'     =>  $_[3]
            ) if (defined $_[1]);
        }
	],
	[#Rule 65
		 'value_abs_dcl', 4,
sub
#line 462 "Parser24.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->YYData->{curr_itf} = undef;
            $_[0]->Error("export declaration expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 66
		 'value_abs_header', 4,
sub
#line 473 "Parser24.yp"
{
            new CORBA::IDL::AbstractValue($_[0],
                    'idf'               =>  $_[3],
                    'inheritance'       =>  $_[4]
            );
        }
	],
	[#Rule 67
		 'value_abs_header', 3,
sub
#line 480 "Parser24.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 68
		 'value_abs_header', 2,
sub
#line 485 "Parser24.yp"
{
            $_[0]->Error("'valuetype' expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 69
		 'value_dcl', 3,
sub
#line 494 "Parser24.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->YYData->{curr_itf} = undef;
            $_[1]->Configure($_[0],
                    'list_decl'     =>  []
            ) if (defined $_[1]);
        }
	],
	[#Rule 70
		 'value_dcl', 4,
sub
#line 502 "Parser24.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->YYData->{curr_itf} = undef;
            $_[1]->Configure($_[0],
                    'list_decl'     =>  $_[3]
            ) if (defined $_[1]);
        }
	],
	[#Rule 71
		 'value_dcl', 4,
sub
#line 510 "Parser24.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->YYData->{curr_itf} = undef;
            $_[0]->Error("value_element expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 72
		 'value_elements', 1,
sub
#line 521 "Parser24.yp"
{
            [$_[1]->getRef()];
        }
	],
	[#Rule 73
		 'value_elements', 2,
sub
#line 525 "Parser24.yp"
{
            unshift @{$_[2]}, $_[1]->getRef();
            $_[2];
        }
	],
	[#Rule 74
		 'value_header', 4,
sub
#line 534 "Parser24.yp"
{
            new CORBA::IDL::RegularValue($_[0],
                    'modifier'          =>  $_[1],
                    'idf'               =>  $_[3],
                    'inheritance'       =>  $_[4]
            );
        }
	],
	[#Rule 75
		 'value_header', 3,
sub
#line 542 "Parser24.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 76
		 'value_mod', 1, undef
	],
	[#Rule 77
		 'value_mod', 0, undef
	],
	[#Rule 78
		 'value_inheritance_spec', 4,
sub
#line 558 "Parser24.yp"
{
            new CORBA::IDL::InheritanceSpec($_[0],
                    'modifier'          =>  $_[2],
                    'list_value'        =>  $_[3],
                    'list_interface'    =>  $_[4]
            );
        }
	],
	[#Rule 79
		 'value_inheritance_spec', 3,
sub
#line 566 "Parser24.yp"
{
            $_[0]->Error("value_name expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 80
		 'value_inheritance_spec', 1,
sub
#line 571 "Parser24.yp"
{
            new CORBA::IDL::InheritanceSpec($_[0],
                    'list_interface'    =>  $_[1]
            );
        }
	],
	[#Rule 81
		 'inheritance_mod', 1, undef
	],
	[#Rule 82
		 'inheritance_mod', 0, undef
	],
	[#Rule 83
		 'value_names', 1,
sub
#line 587 "Parser24.yp"
{
            [$_[1]];
        }
	],
	[#Rule 84
		 'value_names', 3,
sub
#line 591 "Parser24.yp"
{
            unshift @{$_[3]}, $_[1];
            $_[3];
        }
	],
	[#Rule 85
		 'supported_interface_spec', 2,
sub
#line 599 "Parser24.yp"
{
            $_[2];
        }
	],
	[#Rule 86
		 'supported_interface_spec', 2,
sub
#line 603 "Parser24.yp"
{
            $_[0]->Error("Interface name expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 87
		 'supported_interface_spec', 0, undef
	],
	[#Rule 88
		 'value_name', 1,
sub
#line 614 "Parser24.yp"
{
            CORBA::IDL::Value->Lookup($_[0], $_[1]);
        }
	],
	[#Rule 89
		 'value_element', 1, undef
	],
	[#Rule 90
		 'value_element', 1, undef
	],
	[#Rule 91
		 'value_element', 1, undef
	],
	[#Rule 92
		 'state_member', 4,
sub
#line 632 "Parser24.yp"
{
            new CORBA::IDL::StateMembers($_[0],
                    'modifier'          =>  $_[1],
                    'type'              =>  $_[2],
                    'list_expr'         =>  $_[3]
            );
        }
	],
	[#Rule 93
		 'state_member', 4,
sub
#line 640 "Parser24.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 94
		 'state_member', 3,
sub
#line 645 "Parser24.yp"
{
            $_[0]->Error("type_spec expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 95
		 'state_mod', 1, undef
	],
	[#Rule 96
		 'state_mod', 1, undef
	],
	[#Rule 97
		 'init_dcl', 2, undef
	],
	[#Rule 98
		 'init_header_param', 3,
sub
#line 666 "Parser24.yp"
{
            delete $_[0]->YYData->{unnamed_symbtab}
                    if (exists $_[0]->YYData->{unnamed_symbtab});
            $_[1];                      #default action
        }
	],
	[#Rule 99
		 'init_header_param', 4,
sub
#line 672 "Parser24.yp"
{
            delete $_[0]->YYData->{unnamed_symbtab}
                    if (exists $_[0]->YYData->{unnamed_symbtab});
            $_[1]->Configure($_[0],
                    'list_param'    =>  $_[3]
            ) if (defined $_[1]);
        }
	],
	[#Rule 100
		 'init_header_param', 4,
sub
#line 680 "Parser24.yp"
{
            delete $_[0]->YYData->{unnamed_symbtab}
                    if (exists $_[0]->YYData->{unnamed_symbtab});
            $_[0]->Error("init_param_decls expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 101
		 'init_header_param', 2,
sub
#line 688 "Parser24.yp"
{
            delete $_[0]->YYData->{unnamed_symbtab}
                    if (exists $_[0]->YYData->{unnamed_symbtab});
            $_[0]->Error("'(' expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 102
		 'init_header', 2,
sub
#line 699 "Parser24.yp"
{
            new CORBA::IDL::Initializer($_[0],                      # like Operation
                    'idf'               =>  $_[2]
            );
        }
	],
	[#Rule 103
		 'init_header', 2,
sub
#line 705 "Parser24.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 104
		 'init_param_decls', 1,
sub
#line 714 "Parser24.yp"
{
            [$_[1]];
        }
	],
	[#Rule 105
		 'init_param_decls', 3,
sub
#line 718 "Parser24.yp"
{
            unshift @{$_[3]}, $_[1];
            $_[3];
        }
	],
	[#Rule 106
		 'init_param_decl', 3,
sub
#line 727 "Parser24.yp"
{
            new CORBA::IDL::Parameter($_[0],
                    'attr'              =>  $_[1],
                    'type'              =>  $_[2],
                    'idf'               =>  $_[3]
            );
        }
	],
	[#Rule 107
		 'init_param_decl', 2,
sub
#line 735 "Parser24.yp"
{
            $_[0]->Error("Type expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 108
		 'init_param_attribute', 1, undef
	],
	[#Rule 109
		 'const_dcl', 5,
sub
#line 750 "Parser24.yp"
{
            new CORBA::IDL::Constant($_[0],
                    'type'              =>  $_[2],
                    'idf'               =>  $_[3],
                    'list_expr'         =>  $_[5]
            );
        }
	],
	[#Rule 110
		 'const_dcl', 5,
sub
#line 758 "Parser24.yp"
{
            $_[0]->Error("Expression expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 111
		 'const_dcl', 4,
sub
#line 763 "Parser24.yp"
{
            $_[0]->Error("'=' expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 112
		 'const_dcl', 3,
sub
#line 768 "Parser24.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 113
		 'const_dcl', 2,
sub
#line 773 "Parser24.yp"
{
            $_[0]->Error("const_type expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 114
		 'const_type', 1, undef
	],
	[#Rule 115
		 'const_type', 1, undef
	],
	[#Rule 116
		 'const_type', 1, undef
	],
	[#Rule 117
		 'const_type', 1, undef
	],
	[#Rule 118
		 'const_type', 1, undef
	],
	[#Rule 119
		 'const_type', 1, undef
	],
	[#Rule 120
		 'const_type', 1, undef
	],
	[#Rule 121
		 'const_type', 1, undef
	],
	[#Rule 122
		 'const_type', 1,
sub
#line 798 "Parser24.yp"
{
            CORBA::IDL::TypeDeclarator->Lookup($_[0], $_[1]);
        }
	],
	[#Rule 123
		 'const_type', 1, undef
	],
	[#Rule 124
		 'const_exp', 1, undef
	],
	[#Rule 125
		 'or_expr', 1, undef
	],
	[#Rule 126
		 'or_expr', 3,
sub
#line 816 "Parser24.yp"
{
            BuildBinop($_[1], $_[2], $_[3]);
        }
	],
	[#Rule 127
		 'xor_expr', 1, undef
	],
	[#Rule 128
		 'xor_expr', 3,
sub
#line 826 "Parser24.yp"
{
            BuildBinop($_[1], $_[2], $_[3]);
        }
	],
	[#Rule 129
		 'and_expr', 1, undef
	],
	[#Rule 130
		 'and_expr', 3,
sub
#line 836 "Parser24.yp"
{
            BuildBinop($_[1], $_[2], $_[3]);
        }
	],
	[#Rule 131
		 'shift_expr', 1, undef
	],
	[#Rule 132
		 'shift_expr', 3,
sub
#line 846 "Parser24.yp"
{
            BuildBinop($_[1], $_[2], $_[3]);
        }
	],
	[#Rule 133
		 'shift_expr', 3,
sub
#line 850 "Parser24.yp"
{
            BuildBinop($_[1], $_[2], $_[3]);
        }
	],
	[#Rule 134
		 'add_expr', 1, undef
	],
	[#Rule 135
		 'add_expr', 3,
sub
#line 860 "Parser24.yp"
{
            BuildBinop($_[1], $_[2], $_[3]);
        }
	],
	[#Rule 136
		 'add_expr', 3,
sub
#line 864 "Parser24.yp"
{
            BuildBinop($_[1], $_[2], $_[3]);
        }
	],
	[#Rule 137
		 'mult_expr', 1, undef
	],
	[#Rule 138
		 'mult_expr', 3,
sub
#line 874 "Parser24.yp"
{
            BuildBinop($_[1], $_[2], $_[3]);
        }
	],
	[#Rule 139
		 'mult_expr', 3,
sub
#line 878 "Parser24.yp"
{
            BuildBinop($_[1], $_[2], $_[3]);
        }
	],
	[#Rule 140
		 'mult_expr', 3,
sub
#line 882 "Parser24.yp"
{
            BuildBinop($_[1], $_[2], $_[3]);
        }
	],
	[#Rule 141
		 'unary_expr', 2,
sub
#line 890 "Parser24.yp"
{
            BuildUnop($_[1], $_[2]);
        }
	],
	[#Rule 142
		 'unary_expr', 1, undef
	],
	[#Rule 143
		 'unary_operator', 1, undef
	],
	[#Rule 144
		 'unary_operator', 1, undef
	],
	[#Rule 145
		 'unary_operator', 1, undef
	],
	[#Rule 146
		 'primary_expr', 1,
sub
#line 910 "Parser24.yp"
{
            [
                CORBA::IDL::Constant->Lookup($_[0], $_[1])
            ];
        }
	],
	[#Rule 147
		 'primary_expr', 1,
sub
#line 916 "Parser24.yp"
{
            [ $_[1] ];
        }
	],
	[#Rule 148
		 'primary_expr', 3,
sub
#line 920 "Parser24.yp"
{
            $_[2];
        }
	],
	[#Rule 149
		 'primary_expr', 3,
sub
#line 924 "Parser24.yp"
{
            $_[0]->Error("Expression expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 150
		 'literal', 1,
sub
#line 933 "Parser24.yp"
{
            new CORBA::IDL::IntegerLiteral($_[0],
                    'value'             =>  $_[1],
                    'lexeme'            =>  $_[0]->YYData->{lexeme}
            );
        }
	],
	[#Rule 151
		 'literal', 1,
sub
#line 940 "Parser24.yp"
{
            new CORBA::IDL::StringLiteral($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 152
		 'literal', 1,
sub
#line 946 "Parser24.yp"
{
            new CORBA::IDL::WideStringLiteral($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 153
		 'literal', 1,
sub
#line 952 "Parser24.yp"
{
            new CORBA::IDL::CharacterLiteral($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 154
		 'literal', 1,
sub
#line 958 "Parser24.yp"
{
            new CORBA::IDL::WideCharacterLiteral($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 155
		 'literal', 1,
sub
#line 964 "Parser24.yp"
{
            new CORBA::IDL::FixedPtLiteral($_[0],
                    'value'             =>  $_[1],
                    'lexeme'            =>  $_[0]->YYData->{lexeme}
            );
        }
	],
	[#Rule 156
		 'literal', 1,
sub
#line 971 "Parser24.yp"
{
            new CORBA::IDL::FloatingPtLiteral($_[0],
                    'value'             =>  $_[1],
                    'lexeme'            =>  $_[0]->YYData->{lexeme}
            );
        }
	],
	[#Rule 157
		 'literal', 1, undef
	],
	[#Rule 158
		 'string_literal', 1, undef
	],
	[#Rule 159
		 'string_literal', 2,
sub
#line 985 "Parser24.yp"
{
            $_[1] . $_[2];
        }
	],
	[#Rule 160
		 'wide_string_literal', 1, undef
	],
	[#Rule 161
		 'wide_string_literal', 2,
sub
#line 994 "Parser24.yp"
{
            $_[1] . $_[2];
        }
	],
	[#Rule 162
		 'boolean_literal', 1,
sub
#line 1002 "Parser24.yp"
{
            new CORBA::IDL::BooleanLiteral($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 163
		 'boolean_literal', 1,
sub
#line 1008 "Parser24.yp"
{
            new CORBA::IDL::BooleanLiteral($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 164
		 'positive_int_const', 1,
sub
#line 1018 "Parser24.yp"
{
            new CORBA::IDL::Expression($_[0],
                    'list_expr'         =>  $_[1]
            );
        }
	],
	[#Rule 165
		 'type_dcl', 2,
sub
#line 1028 "Parser24.yp"
{
            $_[2];
        }
	],
	[#Rule 166
		 'type_dcl', 1, undef
	],
	[#Rule 167
		 'type_dcl', 1, undef
	],
	[#Rule 168
		 'type_dcl', 1, undef
	],
	[#Rule 169
		 'type_dcl', 2,
sub
#line 1038 "Parser24.yp"
{
            new CORBA::IDL::NativeType($_[0],
                    'idf'               =>  $_[2]
            );
        }
	],
	[#Rule 170
		 'type_dcl', 1, undef
	],
	[#Rule 171
		 'type_dcl', 2,
sub
#line 1046 "Parser24.yp"
{
            $_[0]->Error("type_declarator expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 172
		 'type_declarator', 2,
sub
#line 1055 "Parser24.yp"
{
            new CORBA::IDL::TypeDeclarators($_[0],
                    'type'              =>  $_[1],
                    'list_expr'         =>  $_[2]
            );
        }
	],
	[#Rule 173
		 'type_spec', 1, undef
	],
	[#Rule 174
		 'type_spec', 1, undef
	],
	[#Rule 175
		 'simple_type_spec', 1, undef
	],
	[#Rule 176
		 'simple_type_spec', 1, undef
	],
	[#Rule 177
		 'simple_type_spec', 1,
sub
#line 1078 "Parser24.yp"
{
            CORBA::IDL::TypeDeclarator->Lookup($_[0], $_[1]);
        }
	],
	[#Rule 178
		 'simple_type_spec', 1,
sub
#line 1082 "Parser24.yp"
{
            $_[0]->Error("simple_type_spec expected.\n");
            new CORBA::IDL::VoidType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 179
		 'base_type_spec', 1, undef
	],
	[#Rule 180
		 'base_type_spec', 1, undef
	],
	[#Rule 181
		 'base_type_spec', 1, undef
	],
	[#Rule 182
		 'base_type_spec', 1, undef
	],
	[#Rule 183
		 'base_type_spec', 1, undef
	],
	[#Rule 184
		 'base_type_spec', 1, undef
	],
	[#Rule 185
		 'base_type_spec', 1, undef
	],
	[#Rule 186
		 'base_type_spec', 1, undef
	],
	[#Rule 187
		 'base_type_spec', 1, undef
	],
	[#Rule 188
		 'template_type_spec', 1, undef
	],
	[#Rule 189
		 'template_type_spec', 1, undef
	],
	[#Rule 190
		 'template_type_spec', 1, undef
	],
	[#Rule 191
		 'template_type_spec', 1, undef
	],
	[#Rule 192
		 'constr_type_spec', 1, undef
	],
	[#Rule 193
		 'constr_type_spec', 1, undef
	],
	[#Rule 194
		 'constr_type_spec', 1, undef
	],
	[#Rule 195
		 'declarators', 1,
sub
#line 1137 "Parser24.yp"
{
            [$_[1]];
        }
	],
	[#Rule 196
		 'declarators', 3,
sub
#line 1141 "Parser24.yp"
{
            unshift @{$_[3]}, $_[1];
            $_[3];
        }
	],
	[#Rule 197
		 'declarator', 1,
sub
#line 1150 "Parser24.yp"
{
            [$_[1]];
        }
	],
	[#Rule 198
		 'declarator', 1, undef
	],
	[#Rule 199
		 'simple_declarator', 1, undef
	],
	[#Rule 200
		 'simple_declarator', 2,
sub
#line 1162 "Parser24.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 201
		 'simple_declarator', 2,
sub
#line 1167 "Parser24.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 202
		 'complex_declarator', 1, undef
	],
	[#Rule 203
		 'floating_pt_type', 1,
sub
#line 1182 "Parser24.yp"
{
            new CORBA::IDL::FloatingPtType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 204
		 'floating_pt_type', 1,
sub
#line 1188 "Parser24.yp"
{
            new CORBA::IDL::FloatingPtType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 205
		 'floating_pt_type', 2,
sub
#line 1194 "Parser24.yp"
{
            new CORBA::IDL::FloatingPtType($_[0],
                    'value'             =>  $_[1] . q{ } . $_[2]
            );
        }
	],
	[#Rule 206
		 'integer_type', 1, undef
	],
	[#Rule 207
		 'integer_type', 1, undef
	],
	[#Rule 208
		 'signed_int', 1, undef
	],
	[#Rule 209
		 'signed_int', 1, undef
	],
	[#Rule 210
		 'signed_int', 1, undef
	],
	[#Rule 211
		 'signed_short_int', 1,
sub
#line 1222 "Parser24.yp"
{
            new CORBA::IDL::IntegerType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 212
		 'signed_long_int', 1,
sub
#line 1232 "Parser24.yp"
{
            new CORBA::IDL::IntegerType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 213
		 'signed_longlong_int', 2,
sub
#line 1242 "Parser24.yp"
{
            new CORBA::IDL::IntegerType($_[0],
                    'value'             =>  $_[1] . q{ } . $_[2]
            );
        }
	],
	[#Rule 214
		 'unsigned_int', 1, undef
	],
	[#Rule 215
		 'unsigned_int', 1, undef
	],
	[#Rule 216
		 'unsigned_int', 1, undef
	],
	[#Rule 217
		 'unsigned_short_int', 2,
sub
#line 1262 "Parser24.yp"
{
            new CORBA::IDL::IntegerType($_[0],
                    'value'             =>  $_[1] . q{ } . $_[2]
            );
        }
	],
	[#Rule 218
		 'unsigned_long_int', 2,
sub
#line 1272 "Parser24.yp"
{
            new CORBA::IDL::IntegerType($_[0],
                    'value'             =>  $_[1] . q{ } . $_[2]
            );
        }
	],
	[#Rule 219
		 'unsigned_longlong_int', 3,
sub
#line 1282 "Parser24.yp"
{
            new CORBA::IDL::IntegerType($_[0],
                    'value'             =>  $_[1] . q{ } . $_[2] . q{ } . $_[3]
            );
        }
	],
	[#Rule 220
		 'char_type', 1,
sub
#line 1292 "Parser24.yp"
{
            new CORBA::IDL::CharType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 221
		 'wide_char_type', 1,
sub
#line 1302 "Parser24.yp"
{
            new CORBA::IDL::WideCharType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 222
		 'boolean_type', 1,
sub
#line 1312 "Parser24.yp"
{
            new CORBA::IDL::BooleanType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 223
		 'octet_type', 1,
sub
#line 1322 "Parser24.yp"
{
            new CORBA::IDL::OctetType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 224
		 'any_type', 1,
sub
#line 1332 "Parser24.yp"
{
            new CORBA::IDL::AnyType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 225
		 'object_type', 1,
sub
#line 1342 "Parser24.yp"
{
            new CORBA::IDL::ObjectType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 226
		 'struct_type', 4,
sub
#line 1352 "Parser24.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[1]->Configure($_[0],
                    'list_expr'         =>  $_[3]
            ) if (defined $_[1]);
        }
	],
	[#Rule 227
		 'struct_type', 4,
sub
#line 1359 "Parser24.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->Error("member expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 228
		 'struct_header', 2,
sub
#line 1369 "Parser24.yp"
{
            new CORBA::IDL::StructType($_[0],
                    'idf'               =>  $_[2]
            );
        }
	],
	[#Rule 229
		 'struct_header', 2,
sub
#line 1375 "Parser24.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 230
		 'member_list', 1,
sub
#line 1384 "Parser24.yp"
{
            [$_[1]];
        }
	],
	[#Rule 231
		 'member_list', 2,
sub
#line 1388 "Parser24.yp"
{
            unshift @{$_[2]}, $_[1];
            $_[2];
        }
	],
	[#Rule 232
		 'member', 3,
sub
#line 1397 "Parser24.yp"
{
            new CORBA::IDL::Members($_[0],
                    'type'              =>  $_[1],
                    'list_expr'         =>  $_[2]
            );
        }
	],
	[#Rule 233
		 'union_type', 8,
sub
#line 1408 "Parser24.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[1]->Configure($_[0],
                    'type'              =>  $_[4],
                    'list_expr'         =>  $_[7]
            ) if (defined $_[1]);
        }
	],
	[#Rule 234
		 'union_type', 8,
sub
#line 1416 "Parser24.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->Error("switch_body expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 235
		 'union_type', 6,
sub
#line 1423 "Parser24.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->Error("'\x7b' expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 236
		 'union_type', 5,
sub
#line 1430 "Parser24.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->Error("switch_type_spec expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 237
		 'union_type', 3,
sub
#line 1437 "Parser24.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->Error("'(' expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 238
		 'union_header', 2,
sub
#line 1447 "Parser24.yp"
{
            new CORBA::IDL::UnionType($_[0],
                    'idf'               =>  $_[2],
            );
        }
	],
	[#Rule 239
		 'union_header', 2,
sub
#line 1453 "Parser24.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 240
		 'switch_type_spec', 1, undef
	],
	[#Rule 241
		 'switch_type_spec', 1, undef
	],
	[#Rule 242
		 'switch_type_spec', 1, undef
	],
	[#Rule 243
		 'switch_type_spec', 1, undef
	],
	[#Rule 244
		 'switch_type_spec', 1,
sub
#line 1470 "Parser24.yp"
{
            CORBA::IDL::TypeDeclarator->Lookup($_[0], $_[1]);
        }
	],
	[#Rule 245
		 'switch_body', 1,
sub
#line 1478 "Parser24.yp"
{
            [$_[1]];
        }
	],
	[#Rule 246
		 'switch_body', 2,
sub
#line 1482 "Parser24.yp"
{
            unshift @{$_[2]}, $_[1];
            $_[2];
        }
	],
	[#Rule 247
		 'case', 3,
sub
#line 1491 "Parser24.yp"
{
            new CORBA::IDL::Case($_[0],
                    'list_label'        =>  $_[1],
                    'element'           =>  $_[2]
            );
        }
	],
	[#Rule 248
		 'case_labels', 1,
sub
#line 1501 "Parser24.yp"
{
            [$_[1]];
        }
	],
	[#Rule 249
		 'case_labels', 2,
sub
#line 1505 "Parser24.yp"
{
            unshift @{$_[2]}, $_[1];
            $_[2];
        }
	],
	[#Rule 250
		 'case_label', 3,
sub
#line 1514 "Parser24.yp"
{
            $_[2];                      # here only a expression, type is not known
        }
	],
	[#Rule 251
		 'case_label', 3,
sub
#line 1518 "Parser24.yp"
{
            $_[0]->Error("':' expected.\n");
            $_[0]->YYErrok();
            $_[2];
        }
	],
	[#Rule 252
		 'case_label', 2,
sub
#line 1524 "Parser24.yp"
{
            $_[0]->Error("Expression expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 253
		 'case_label', 2,
sub
#line 1529 "Parser24.yp"
{
            new CORBA::IDL::Default($_[0]);
        }
	],
	[#Rule 254
		 'case_label', 2,
sub
#line 1533 "Parser24.yp"
{
            $_[0]->Error("':' expected.\n");
            $_[0]->YYErrok();
            new CORBA::IDL::Default($_[0]);
        }
	],
	[#Rule 255
		 'element_spec', 2,
sub
#line 1543 "Parser24.yp"
{
            new CORBA::IDL::Element($_[0],
                    'type'          =>  $_[1],
                    'list_expr'     =>  $_[2]
            );
        }
	],
	[#Rule 256
		 'enum_type', 4,
sub
#line 1554 "Parser24.yp"
{
            $_[1]->Configure($_[0],
                    'list_expr'     =>  $_[3]
            ) if (defined $_[1]);
        }
	],
	[#Rule 257
		 'enum_type', 4,
sub
#line 1560 "Parser24.yp"
{
            $_[0]->Error("enumerator expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 258
		 'enum_type', 2,
sub
#line 1566 "Parser24.yp"
{
            $_[0]->Error("'\x7b' expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 259
		 'enum_header', 2,
sub
#line 1575 "Parser24.yp"
{
            new CORBA::IDL::EnumType($_[0],
                    'idf'               =>  $_[2],
            );
        }
	],
	[#Rule 260
		 'enum_header', 2,
sub
#line 1581 "Parser24.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 261
		 'enumerators', 1,
sub
#line 1589 "Parser24.yp"
{
            [$_[1]];
        }
	],
	[#Rule 262
		 'enumerators', 3,
sub
#line 1593 "Parser24.yp"
{
            unshift @{$_[3]}, $_[1];
            $_[3];
        }
	],
	[#Rule 263
		 'enumerators', 2,
sub
#line 1598 "Parser24.yp"
{
            $_[0]->Warning("',' unexpected.\n");
            [$_[1]];
        }
	],
	[#Rule 264
		 'enumerators', 2,
sub
#line 1603 "Parser24.yp"
{
            $_[0]->Error("';' unexpected.\n");
            [$_[1]];
        }
	],
	[#Rule 265
		 'enumerator', 1,
sub
#line 1612 "Parser24.yp"
{
            new CORBA::IDL::Enum($_[0],
                    'idf'               =>  $_[1]
            );
        }
	],
	[#Rule 266
		 'sequence_type', 6,
sub
#line 1622 "Parser24.yp"
{
            new CORBA::IDL::SequenceType($_[0],
                    'value'             =>  $_[1],
                    'type'              =>  $_[3],
                    'max'               =>  $_[5]
            );
        }
	],
	[#Rule 267
		 'sequence_type', 6,
sub
#line 1630 "Parser24.yp"
{
            $_[0]->Error("Expression expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 268
		 'sequence_type', 4,
sub
#line 1635 "Parser24.yp"
{
            new CORBA::IDL::SequenceType($_[0],
                    'value'             =>  $_[1],
                    'type'              =>  $_[3]
            );
        }
	],
	[#Rule 269
		 'sequence_type', 4,
sub
#line 1642 "Parser24.yp"
{
            $_[0]->Error("simple_type_spec expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 270
		 'sequence_type', 2,
sub
#line 1647 "Parser24.yp"
{
            $_[0]->Error("'<' expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 271
		 'string_type', 4,
sub
#line 1656 "Parser24.yp"
{
            new CORBA::IDL::StringType($_[0],
                    'value'             =>  $_[1],
                    'max'               =>  $_[3]
            );
        }
	],
	[#Rule 272
		 'string_type', 1,
sub
#line 1663 "Parser24.yp"
{
            new CORBA::IDL::StringType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 273
		 'string_type', 4,
sub
#line 1669 "Parser24.yp"
{
            $_[0]->Error("Expression expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 274
		 'wide_string_type', 4,
sub
#line 1678 "Parser24.yp"
{
            new CORBA::IDL::WideStringType($_[0],
                    'value'             =>  $_[1],
                    'max'               =>  $_[3]
            );
        }
	],
	[#Rule 275
		 'wide_string_type', 1,
sub
#line 1685 "Parser24.yp"
{
            new CORBA::IDL::WideStringType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 276
		 'wide_string_type', 4,
sub
#line 1691 "Parser24.yp"
{
            $_[0]->Error("Expression expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 277
		 'array_declarator', 2,
sub
#line 1700 "Parser24.yp"
{
            unshift @{$_[2]}, $_[1];
            $_[2];
        }
	],
	[#Rule 278
		 'fixed_array_sizes', 1,
sub
#line 1708 "Parser24.yp"
{
            [$_[1]];
        }
	],
	[#Rule 279
		 'fixed_array_sizes', 2,
sub
#line 1712 "Parser24.yp"
{
            unshift @{$_[2]}, $_[1];
            $_[2];
        }
	],
	[#Rule 280
		 'fixed_array_size', 3,
sub
#line 1721 "Parser24.yp"
{
            $_[2];
        }
	],
	[#Rule 281
		 'fixed_array_size', 3,
sub
#line 1725 "Parser24.yp"
{
            $_[0]->Error("Expression expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 282
		 'attr_dcl', 4,
sub
#line 1734 "Parser24.yp"
{
            new CORBA::IDL::Attributes($_[0],
                    'modifier'          =>  $_[1],
                    'type'              =>  $_[3],
                    'list_expr'         =>  $_[4]
            );
        }
	],
	[#Rule 283
		 'attr_dcl', 3,
sub
#line 1742 "Parser24.yp"
{
            $_[0]->Error("type expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 284
		 'attr_mod', 1, undef
	],
	[#Rule 285
		 'attr_mod', 0, undef
	],
	[#Rule 286
		 'simple_declarators', 1,
sub
#line 1757 "Parser24.yp"
{
            [$_[1]];
        }
	],
	[#Rule 287
		 'simple_declarators', 3,
sub
#line 1761 "Parser24.yp"
{
            unshift @{$_[3]}, $_[1];
            $_[3];
        }
	],
	[#Rule 288
		 'except_dcl', 3,
sub
#line 1770 "Parser24.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[1];
        }
	],
	[#Rule 289
		 'except_dcl', 4,
sub
#line 1775 "Parser24.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[1]->Configure($_[0],
                    'list_expr'         =>  $_[3]
            ) if (defined $_[1]);
        }
	],
	[#Rule 290
		 'except_dcl', 4,
sub
#line 1782 "Parser24.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->Error("'members expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 291
		 'except_dcl', 2,
sub
#line 1789 "Parser24.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->Error("'\x7b' expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 292
		 'exception_header', 2,
sub
#line 1799 "Parser24.yp"
{
            new CORBA::IDL::Exception($_[0],
                    'idf'               =>  $_[2],
            );
        }
	],
	[#Rule 293
		 'exception_header', 2,
sub
#line 1805 "Parser24.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 294
		 'op_dcl', 4,
sub
#line 1814 "Parser24.yp"
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
	[#Rule 295
		 'op_dcl', 2,
sub
#line 1824 "Parser24.yp"
{
            delete $_[0]->YYData->{unnamed_symbtab}
                    if (exists $_[0]->YYData->{unnamed_symbtab});
            $_[0]->Error("parameters declaration expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 296
		 'op_header', 3,
sub
#line 1835 "Parser24.yp"
{
            new CORBA::IDL::Operation($_[0],
                    'modifier'          =>  $_[1],
                    'type'              =>  $_[2],
                    'idf'               =>  $_[3]
            );
        }
	],
	[#Rule 297
		 'op_header', 3,
sub
#line 1843 "Parser24.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 298
		 'op_mod', 1, undef
	],
	[#Rule 299
		 'op_mod', 0, undef
	],
	[#Rule 300
		 'op_attribute', 1, undef
	],
	[#Rule 301
		 'op_type_spec', 1, undef
	],
	[#Rule 302
		 'op_type_spec', 1,
sub
#line 1867 "Parser24.yp"
{
            new CORBA::IDL::VoidType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 303
		 'op_type_spec', 1,
sub
#line 1873 "Parser24.yp"
{
            $_[0]->Error("op_type_spec expected.\n");
            $_[1];                      #default action
        }
	],
	[#Rule 304
		 'op_type_spec', 1,
sub
#line 1878 "Parser24.yp"
{
            $_[0]->Error("op_type_spec expected.\n");
            $_[1];                      #default action
        }
	],
	[#Rule 305
		 'parameter_dcls', 3,
sub
#line 1887 "Parser24.yp"
{
            $_[2];
        }
	],
	[#Rule 306
		 'parameter_dcls', 5,
sub
#line 1891 "Parser24.yp"
{
            $_[0]->Error("'...' unexpected.\n");
            $_[2];
        }
	],
	[#Rule 307
		 'parameter_dcls', 4,
sub
#line 1896 "Parser24.yp"
{
            $_[0]->Warning("',' unexpected.\n");
            $_[2];
        }
	],
	[#Rule 308
		 'parameter_dcls', 2,
sub
#line 1901 "Parser24.yp"
{
            undef;
        }
	],
	[#Rule 309
		 'parameter_dcls', 3,
sub
#line 1905 "Parser24.yp"
{
            $_[0]->Error("'...' unexpected.\n");
            undef;
        }
	],
	[#Rule 310
		 'parameter_dcls', 3,
sub
#line 1910 "Parser24.yp"
{
            $_[0]->Error("parameters declaration expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 311
		 'param_dcls', 1,
sub
#line 1918 "Parser24.yp"
{
            [$_[1]];
        }
	],
	[#Rule 312
		 'param_dcls', 3,
sub
#line 1922 "Parser24.yp"
{
            push @{$_[1]}, $_[3];
            $_[1];
        }
	],
	[#Rule 313
		 'param_dcls', 2,
sub
#line 1927 "Parser24.yp"
{
            $_[0]->Error("';' unexpected.\n");
            [$_[1]];
        }
	],
	[#Rule 314
		 'param_dcl', 3,
sub
#line 1936 "Parser24.yp"
{
            new CORBA::IDL::Parameter($_[0],
                    'attr'              =>  $_[1],
                    'type'              =>  $_[2],
                    'idf'               =>  $_[3]
            );
        }
	],
	[#Rule 315
		 'param_attribute', 1, undef
	],
	[#Rule 316
		 'param_attribute', 1, undef
	],
	[#Rule 317
		 'param_attribute', 1, undef
	],
	[#Rule 318
		 'param_attribute', 0,
sub
#line 1954 "Parser24.yp"
{
            $_[0]->Error("(in|out|inout) expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 319
		 'raises_expr', 4,
sub
#line 1963 "Parser24.yp"
{
            $_[3];
        }
	],
	[#Rule 320
		 'raises_expr', 4,
sub
#line 1967 "Parser24.yp"
{
            $_[0]->Error("name expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 321
		 'raises_expr', 2,
sub
#line 1972 "Parser24.yp"
{
            $_[0]->Error("'(' expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 322
		 'raises_expr', 0, undef
	],
	[#Rule 323
		 'exception_names', 1,
sub
#line 1982 "Parser24.yp"
{
            [$_[1]];
        }
	],
	[#Rule 324
		 'exception_names', 3,
sub
#line 1986 "Parser24.yp"
{
            unshift @{$_[3]}, $_[1];
            $_[3];
        }
	],
	[#Rule 325
		 'exception_name', 1,
sub
#line 1994 "Parser24.yp"
{
            CORBA::IDL::Exception->Lookup($_[0], $_[1]);
        }
	],
	[#Rule 326
		 'context_expr', 4,
sub
#line 2002 "Parser24.yp"
{
            $_[3];
        }
	],
	[#Rule 327
		 'context_expr', 4,
sub
#line 2006 "Parser24.yp"
{
            $_[0]->Error("string expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 328
		 'context_expr', 2,
sub
#line 2011 "Parser24.yp"
{
            $_[0]->Error("'(' expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 329
		 'context_expr', 0, undef
	],
	[#Rule 330
		 'string_literals', 1,
sub
#line 2021 "Parser24.yp"
{
            [$_[1]];
        }
	],
	[#Rule 331
		 'string_literals', 3,
sub
#line 2025 "Parser24.yp"
{
            unshift @{$_[3]}, $_[1];
            $_[3];
        }
	],
	[#Rule 332
		 'param_type_spec', 1, undef
	],
	[#Rule 333
		 'param_type_spec', 1,
sub
#line 2036 "Parser24.yp"
{
            $_[0]->Error("param_type_spec expected.\n");
            $_[1];                      #default action
        }
	],
	[#Rule 334
		 'param_type_spec', 1,
sub
#line 2041 "Parser24.yp"
{
            $_[0]->Error("param_type_spec expected.\n");
            $_[1];                      #default action
        }
	],
	[#Rule 335
		 'param_type_spec', 1,
sub
#line 2046 "Parser24.yp"
{
            $_[0]->Error("param_type_spec expected.\n");
            $_[1];                      #default action
        }
	],
	[#Rule 336
		 'param_type_spec', 1,
sub
#line 2051 "Parser24.yp"
{
            $_[0]->Error("param_type_spec expected.\n");
            $_[1];                      #default action
        }
	],
	[#Rule 337
		 'op_param_type_spec', 1, undef
	],
	[#Rule 338
		 'op_param_type_spec', 1, undef
	],
	[#Rule 339
		 'op_param_type_spec', 1, undef
	],
	[#Rule 340
		 'op_param_type_spec', 1,
sub
#line 2065 "Parser24.yp"
{
            CORBA::IDL::TypeDeclarator->Lookup($_[0], $_[1]);
        }
	],
	[#Rule 341
		 'fixed_pt_type', 6,
sub
#line 2073 "Parser24.yp"
{
            new CORBA::IDL::FixedPtType($_[0],
                    'value'             =>  $_[1],
                    'd'                 =>  $_[3],
                    's'                 =>  $_[5]
            );
        }
	],
	[#Rule 342
		 'fixed_pt_type', 6,
sub
#line 2081 "Parser24.yp"
{
            $_[0]->Error("Expression expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 343
		 'fixed_pt_type', 4,
sub
#line 2086 "Parser24.yp"
{
            $_[0]->Error("Expression expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 344
		 'fixed_pt_type', 2,
sub
#line 2091 "Parser24.yp"
{
            $_[0]->Error("'<' expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 345
		 'fixed_pt_const_type', 1,
sub
#line 2100 "Parser24.yp"
{
            new CORBA::IDL::FixedPtConstType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 346
		 'value_base_type', 1,
sub
#line 2110 "Parser24.yp"
{
            new CORBA::IDL::ValueBaseType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 347
		 'constr_forward_decl', 2,
sub
#line 2120 "Parser24.yp"
{
            new CORBA::IDL::ForwardStructType($_[0],
                    'idf'               =>  $_[2]
            );
        }
	],
	[#Rule 348
		 'constr_forward_decl', 2,
sub
#line 2126 "Parser24.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 349
		 'constr_forward_decl', 2,
sub
#line 2131 "Parser24.yp"
{
            new CORBA::IDL::ForwardUnionType($_[0],
                    'idf'               =>  $_[2]
            );
        }
	],
	[#Rule 350
		 'constr_forward_decl', 2,
sub
#line 2137 "Parser24.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	]
],
                                  @_);
    bless($self,$class);
}

#line 2143 "Parser24.yp"


use warnings;

our $VERSION = '2.61';
our $IDL_VERSION = '2.4';

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
