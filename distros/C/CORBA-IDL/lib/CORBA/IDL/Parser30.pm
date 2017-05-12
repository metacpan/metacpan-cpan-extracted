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
			'' => -3,
			'HOME' => 46,
			'INTERFACE' => -39,
			'ENUM' => 47,
			'VALUETYPE' => -88,
			'CUSTOM' => 28,
			'IMPORT' => 52,
			'UNION' => 14,
			'NATIVE' => 34,
			'TYPEDEF' => 3,
			'EXCEPTION' => 4,
			'error' => 15,
			'LOCAL' => 55,
			'IDENTIFIER' => 40,
			'TYPEID' => 56,
			'COMPONENT' => 42,
			'MODULE' => 57,
			'STRUCT' => 8,
			'CONST' => 18,
			'ABSTRACT' => 10,
			'TYPEPREFIX' => 64,
			'EVENTTYPE' => -88
		},
		GOTOS => {
			'union_type' => 25,
			'value_dcl' => 26,
			'value_box_dcl' => 27,
			'enum_header' => 29,
			'struct_type' => 30,
			'union_header' => 31,
			'value_box_header' => 1,
			'except_dcl' => 32,
			'value_header' => 33,
			'interface_mod' => 35,
			'struct_header' => 2,
			'interface' => 36,
			'home_header_spec' => 37,
			'type_dcl' => 5,
			'value_forward_dcl' => 39,
			'interface_header' => 38,
			'value_mod' => 6,
			'enum_type' => 7,
			'value' => 41,
			'event' => 43,
			'value_abs_header' => 9,
			'event_abs_header' => 44,
			'exception_header' => 11,
			'const_dcl' => 45,
			'interface_dcl' => 12,
			'component_header' => 48,
			'definitions' => 49,
			'home_header' => 13,
			'definition' => 51,
			'module_header' => 50,
			'specification' => 53,
			'constr_forward_decl' => 54,
			'module' => 16,
			'imports' => 58,
			'event_abs_dcl' => 17,
			'value_abs_dcl' => 19,
			'import' => 59,
			'home_dcl' => 21,
			'component_dcl' => 20,
			'event_forward_dcl' => 61,
			'component' => 60,
			'event_dcl' => 63,
			'forward_dcl' => 62,
			'component_forward_dcl' => 22,
			'event_header' => 23,
			'type_prefix_dcl' => 24,
			'type_id_dcl' => 65
		}
	},
	{#State 1
		ACTIONS => {
			"::" => 102,
			'ENUM' => 47,
			'CHAR' => 79,
			'OBJECT' => 105,
			'STRING' => 81,
			'OCTET' => 66,
			'WSTRING' => 109,
			'UNION' => 82,
			'UNSIGNED' => 93,
			'ANY' => 67,
			'FLOAT' => 84,
			'LONG' => 68,
			'SEQUENCE' => 111,
			'DOUBLE' => 86,
			'IDENTIFIER' => 95,
			'SHORT' => 112,
			'BOOLEAN' => 113,
			'STRUCT' => 72,
			'VOID' => 98,
			'FIXED' => 115,
			'VALUEBASE' => 116,
			'WCHAR' => 77
		},
		GOTOS => {
			'union_type' => 90,
			'enum_header' => 29,
			'unsigned_short_int' => 91,
			'struct_type' => 92,
			'union_header' => 31,
			'struct_header' => 2,
			'signed_longlong_int' => 69,
			'any_type' => 94,
			'enum_type' => 70,
			'template_type_spec' => 71,
			'unsigned_long_int' => 96,
			'scoped_name' => 73,
			'string_type' => 97,
			'char_type' => 74,
			'fixed_pt_type' => 100,
			'signed_short_int' => 99,
			'signed_long_int' => 75,
			'wide_char_type' => 76,
			'octet_type' => 101,
			'wide_string_type' => 78,
			'object_type' => 103,
			'type_spec' => 104,
			'integer_type' => 80,
			'unsigned_int' => 106,
			'sequence_type' => 107,
			'unsigned_longlong_int' => 108,
			'constr_type_spec' => 110,
			'floating_pt_type' => 83,
			'value_base_type' => 85,
			'base_type_spec' => 87,
			'signed_int' => 114,
			'simple_type_spec' => 88,
			'boolean_type' => 89
		}
	},
	{#State 2
		ACTIONS => {
			"{" => 117
		}
	},
	{#State 3
		ACTIONS => {
			"::" => 102,
			'ENUM' => 47,
			'CHAR' => 79,
			'OBJECT' => 105,
			'STRING' => 81,
			'OCTET' => 66,
			'WSTRING' => 109,
			'UNION' => 82,
			'UNSIGNED' => 93,
			'error' => 118,
			'ANY' => 67,
			'FLOAT' => 84,
			'LONG' => 68,
			'SEQUENCE' => 111,
			'DOUBLE' => 86,
			'IDENTIFIER' => 95,
			'SHORT' => 112,
			'BOOLEAN' => 113,
			'STRUCT' => 72,
			'VOID' => 98,
			'FIXED' => 115,
			'VALUEBASE' => 116,
			'WCHAR' => 77
		},
		GOTOS => {
			'union_type' => 90,
			'enum_header' => 29,
			'unsigned_short_int' => 91,
			'struct_type' => 92,
			'union_header' => 31,
			'struct_header' => 2,
			'type_declarator' => 119,
			'signed_longlong_int' => 69,
			'any_type' => 94,
			'enum_type' => 70,
			'template_type_spec' => 71,
			'unsigned_long_int' => 96,
			'scoped_name' => 73,
			'string_type' => 97,
			'char_type' => 74,
			'fixed_pt_type' => 100,
			'signed_short_int' => 99,
			'signed_long_int' => 75,
			'wide_char_type' => 76,
			'octet_type' => 101,
			'wide_string_type' => 78,
			'object_type' => 103,
			'type_spec' => 120,
			'integer_type' => 80,
			'unsigned_int' => 106,
			'sequence_type' => 107,
			'unsigned_longlong_int' => 108,
			'constr_type_spec' => 110,
			'floating_pt_type' => 83,
			'value_base_type' => 85,
			'base_type_spec' => 87,
			'signed_int' => 114,
			'simple_type_spec' => 88,
			'boolean_type' => 89
		}
	},
	{#State 4
		ACTIONS => {
			'IDENTIFIER' => 122,
			'error' => 121
		}
	},
	{#State 5
		ACTIONS => {
			";" => 125,
			'error' => 123
		},
		GOTOS => {
			'check_semicolon' => 124
		}
	},
	{#State 6
		ACTIONS => {
			'VALUETYPE' => 126,
			'EVENTTYPE' => 127
		}
	},
	{#State 7
		DEFAULT => -176
	},
	{#State 8
		ACTIONS => {
			'IDENTIFIER' => 129,
			'error' => 128
		}
	},
	{#State 9
		ACTIONS => {
			"{" => 130
		}
	},
	{#State 10
		ACTIONS => {
			'INTERFACE' => -37,
			'VALUETYPE' => 131,
			'error' => 133,
			'EVENTTYPE' => 132
		}
	},
	{#State 11
		ACTIONS => {
			"{" => 135,
			'error' => 134
		}
	},
	{#State 12
		DEFAULT => -30
	},
	{#State 13
		ACTIONS => {
			"{" => 136
		},
		GOTOS => {
			'home_body' => 137
		}
	},
	{#State 14
		ACTIONS => {
			'IDENTIFIER' => 139,
			'error' => 138
		}
	},
	{#State 15
		DEFAULT => -4
	},
	{#State 16
		ACTIONS => {
			";" => 125,
			'error' => 123
		},
		GOTOS => {
			'check_semicolon' => 140
		}
	},
	{#State 17
		DEFAULT => -464
	},
	{#State 18
		ACTIONS => {
			"::" => 102,
			'IDENTIFIER' => 95,
			'DOUBLE' => 86,
			'SHORT' => 112,
			'CHAR' => 79,
			'BOOLEAN' => 113,
			'STRING' => 81,
			'OCTET' => 66,
			'WSTRING' => 109,
			'UNSIGNED' => 93,
			'FIXED' => 153,
			'error' => 147,
			'FLOAT' => 84,
			'LONG' => 68,
			'WCHAR' => 77
		},
		GOTOS => {
			'wide_string_type' => 144,
			'integer_type' => 145,
			'unsigned_int' => 106,
			'unsigned_short_int' => 91,
			'unsigned_longlong_int' => 108,
			'floating_pt_type' => 146,
			'const_type' => 151,
			'signed_longlong_int' => 69,
			'unsigned_long_int' => 96,
			'scoped_name' => 141,
			'string_type' => 149,
			'signed_int' => 114,
			'fixed_pt_const_type' => 152,
			'char_type' => 142,
			'signed_long_int' => 75,
			'signed_short_int' => 99,
			'wide_char_type' => 143,
			'boolean_type' => 148,
			'octet_type' => 150
		}
	},
	{#State 19
		DEFAULT => -67
	},
	{#State 20
		DEFAULT => -387
	},
	{#State 21
		ACTIONS => {
			";" => 125,
			'error' => 123
		},
		GOTOS => {
			'check_semicolon' => 154
		}
	},
	{#State 22
		DEFAULT => -388
	},
	{#State 23
		ACTIONS => {
			"{" => 155
		}
	},
	{#State 24
		ACTIONS => {
			";" => 125,
			'error' => 123
		},
		GOTOS => {
			'check_semicolon' => 156
		}
	},
	{#State 25
		DEFAULT => -175
	},
	{#State 26
		DEFAULT => -66
	},
	{#State 27
		DEFAULT => -68
	},
	{#State 28
		DEFAULT => -87
	},
	{#State 29
		ACTIONS => {
			"{" => 158,
			'error' => 157
		}
	},
	{#State 30
		DEFAULT => -174
	},
	{#State 31
		ACTIONS => {
			'SWITCH' => 159
		}
	},
	{#State 32
		ACTIONS => {
			";" => 125,
			'error' => 123
		},
		GOTOS => {
			'check_semicolon' => 160
		}
	},
	{#State 33
		ACTIONS => {
			"{" => 161
		}
	},
	{#State 34
		ACTIONS => {
			'IDENTIFIER' => 164,
			'error' => 162
		},
		GOTOS => {
			'simple_declarator' => 163
		}
	},
	{#State 35
		ACTIONS => {
			'INTERFACE' => 165
		}
	},
	{#State 36
		ACTIONS => {
			";" => 125,
			'error' => 123
		},
		GOTOS => {
			'check_semicolon' => 166
		}
	},
	{#State 37
		ACTIONS => {
			'MANAGES' => 167
		}
	},
	{#State 38
		ACTIONS => {
			"{" => 168
		}
	},
	{#State 39
		DEFAULT => -69
	},
	{#State 40
		ACTIONS => {
			'error' => 169
		}
	},
	{#State 41
		ACTIONS => {
			";" => 125,
			'error' => 123
		},
		GOTOS => {
			'check_semicolon' => 170
		}
	},
	{#State 42
		ACTIONS => {
			'IDENTIFIER' => 172,
			'error' => 171
		}
	},
	{#State 43
		ACTIONS => {
			";" => 125,
			'error' => 123
		},
		GOTOS => {
			'check_semicolon' => 173
		}
	},
	{#State 44
		ACTIONS => {
			"{" => 174
		}
	},
	{#State 45
		ACTIONS => {
			";" => 125,
			'error' => 123
		},
		GOTOS => {
			'check_semicolon' => 175
		}
	},
	{#State 46
		ACTIONS => {
			'IDENTIFIER' => 177,
			'error' => 176
		}
	},
	{#State 47
		ACTIONS => {
			'IDENTIFIER' => 179,
			'error' => 178
		}
	},
	{#State 48
		ACTIONS => {
			"{" => 180
		}
	},
	{#State 49
		DEFAULT => -1
	},
	{#State 50
		ACTIONS => {
			"{" => 182,
			'error' => 181
		}
	},
	{#State 51
		ACTIONS => {
			'HOME' => 46,
			'INTERFACE' => -39,
			'ENUM' => 47,
			'VALUETYPE' => -88,
			'CUSTOM' => 28,
			'IMPORT' => 52,
			'UNION' => 14,
			'NATIVE' => 34,
			'TYPEDEF' => 3,
			'EXCEPTION' => 4,
			'LOCAL' => 55,
			'IDENTIFIER' => 40,
			'TYPEID' => 56,
			'COMPONENT' => 42,
			'MODULE' => 57,
			'STRUCT' => 8,
			'CONST' => 18,
			'ABSTRACT' => 10,
			'TYPEPREFIX' => 64,
			'EVENTTYPE' => -88
		},
		DEFAULT => -7,
		GOTOS => {
			'union_type' => 25,
			'value_dcl' => 26,
			'value_box_dcl' => 27,
			'enum_header' => 29,
			'struct_type' => 30,
			'union_header' => 31,
			'value_box_header' => 1,
			'except_dcl' => 32,
			'value_header' => 33,
			'interface_mod' => 35,
			'struct_header' => 2,
			'interface' => 36,
			'home_header_spec' => 37,
			'type_dcl' => 5,
			'interface_header' => 38,
			'value_forward_dcl' => 39,
			'value_mod' => 6,
			'enum_type' => 7,
			'value' => 41,
			'event' => 43,
			'value_abs_header' => 9,
			'event_abs_header' => 44,
			'exception_header' => 11,
			'const_dcl' => 45,
			'interface_dcl' => 12,
			'component_header' => 48,
			'definitions' => 183,
			'home_header' => 13,
			'definition' => 51,
			'module_header' => 50,
			'constr_forward_decl' => 54,
			'module' => 16,
			'imports' => 184,
			'event_abs_dcl' => 17,
			'value_abs_dcl' => 19,
			'import' => 59,
			'home_dcl' => 21,
			'component_dcl' => 20,
			'component' => 60,
			'event_forward_dcl' => 61,
			'forward_dcl' => 62,
			'event_dcl' => 63,
			'component_forward_dcl' => 22,
			'event_header' => 23,
			'type_prefix_dcl' => 24,
			'type_id_dcl' => 65
		}
	},
	{#State 52
		ACTIONS => {
			"::" => 102,
			'IDENTIFIER' => 95,
			'STRING_LITERAL' => 188,
			'error' => 187
		},
		GOTOS => {
			'imported_scope' => 186,
			'scoped_name' => 185,
			'string_literal' => 189
		}
	},
	{#State 53
		ACTIONS => {
			'' => 190
		}
	},
	{#State 54
		DEFAULT => -178
	},
	{#State 55
		DEFAULT => -38
	},
	{#State 56
		ACTIONS => {
			"::" => 102,
			'IDENTIFIER' => 95,
			'error' => 192
		},
		GOTOS => {
			'scoped_name' => 191
		}
	},
	{#State 57
		ACTIONS => {
			'IDENTIFIER' => 194,
			'error' => 193
		}
	},
	{#State 58
		ACTIONS => {
			'HOME' => 46,
			'INTERFACE' => -39,
			'ENUM' => 47,
			'CUSTOM' => 28,
			'UNION' => 14,
			'NATIVE' => 34,
			'TYPEDEF' => 3,
			'EXCEPTION' => 4,
			'LOCAL' => 55,
			'IDENTIFIER' => 40,
			'TYPEID' => 56,
			'COMPONENT' => 42,
			'MODULE' => 57,
			'STRUCT' => 8,
			'CONST' => 18,
			'ABSTRACT' => 10,
			'TYPEPREFIX' => 64
		},
		DEFAULT => -88,
		GOTOS => {
			'union_type' => 25,
			'value_dcl' => 26,
			'value_box_dcl' => 27,
			'enum_header' => 29,
			'struct_type' => 30,
			'union_header' => 31,
			'value_box_header' => 1,
			'except_dcl' => 32,
			'value_header' => 33,
			'interface_mod' => 35,
			'struct_header' => 2,
			'interface' => 36,
			'home_header_spec' => 37,
			'type_dcl' => 5,
			'interface_header' => 38,
			'value_forward_dcl' => 39,
			'value_mod' => 6,
			'enum_type' => 7,
			'value' => 41,
			'event' => 43,
			'value_abs_header' => 9,
			'event_abs_header' => 44,
			'exception_header' => 11,
			'const_dcl' => 45,
			'interface_dcl' => 12,
			'component_header' => 48,
			'definitions' => 195,
			'home_header' => 13,
			'definition' => 51,
			'module_header' => 50,
			'constr_forward_decl' => 54,
			'module' => 16,
			'event_abs_dcl' => 17,
			'value_abs_dcl' => 19,
			'home_dcl' => 21,
			'component_dcl' => 20,
			'component' => 60,
			'event_forward_dcl' => 61,
			'forward_dcl' => 62,
			'event_dcl' => 63,
			'component_forward_dcl' => 22,
			'event_header' => 23,
			'type_prefix_dcl' => 24,
			'type_id_dcl' => 65
		}
	},
	{#State 59
		ACTIONS => {
			'IMPORT' => 52
		},
		DEFAULT => -5,
		GOTOS => {
			'imports' => 196,
			'import' => 59
		}
	},
	{#State 60
		ACTIONS => {
			";" => 125,
			'error' => 123
		},
		GOTOS => {
			'check_semicolon' => 197
		}
	},
	{#State 61
		DEFAULT => -465
	},
	{#State 62
		DEFAULT => -31
	},
	{#State 63
		DEFAULT => -463
	},
	{#State 64
		ACTIONS => {
			"::" => 200,
			'IDENTIFIER' => 95,
			'error' => 199
		},
		GOTOS => {
			'scoped_name' => 198
		}
	},
	{#State 65
		ACTIONS => {
			";" => 125,
			'error' => 123
		},
		GOTOS => {
			'check_semicolon' => 201
		}
	},
	{#State 66
		DEFAULT => -231
	},
	{#State 67
		DEFAULT => -232
	},
	{#State 68
		ACTIONS => {
			'DOUBLE' => 203,
			'LONG' => 202
		},
		DEFAULT => -220
	},
	{#State 69
		DEFAULT => -218
	},
	{#State 70
		DEFAULT => -202
	},
	{#State 71
		DEFAULT => -184
	},
	{#State 72
		ACTIONS => {
			'IDENTIFIER' => 205,
			'error' => 204
		}
	},
	{#State 73
		ACTIONS => {
			"::" => 206
		},
		DEFAULT => -185
	},
	{#State 74
		DEFAULT => -189
	},
	{#State 75
		DEFAULT => -217
	},
	{#State 76
		DEFAULT => -190
	},
	{#State 77
		DEFAULT => -229
	},
	{#State 78
		DEFAULT => -198
	},
	{#State 79
		DEFAULT => -228
	},
	{#State 80
		DEFAULT => -188
	},
	{#State 81
		ACTIONS => {
			"<" => 207
		},
		DEFAULT => -280
	},
	{#State 82
		ACTIONS => {
			'IDENTIFIER' => 209,
			'error' => 208
		}
	},
	{#State 83
		DEFAULT => -187
	},
	{#State 84
		DEFAULT => -211
	},
	{#State 85
		DEFAULT => -195
	},
	{#State 86
		DEFAULT => -212
	},
	{#State 87
		DEFAULT => -183
	},
	{#State 88
		DEFAULT => -181
	},
	{#State 89
		DEFAULT => -191
	},
	{#State 90
		DEFAULT => -201
	},
	{#State 91
		DEFAULT => -222
	},
	{#State 92
		DEFAULT => -200
	},
	{#State 93
		ACTIONS => {
			'SHORT' => 211,
			'LONG' => 210
		}
	},
	{#State 94
		DEFAULT => -193
	},
	{#State 95
		DEFAULT => -61
	},
	{#State 96
		DEFAULT => -223
	},
	{#State 97
		DEFAULT => -197
	},
	{#State 98
		DEFAULT => -186
	},
	{#State 99
		DEFAULT => -216
	},
	{#State 100
		DEFAULT => -199
	},
	{#State 101
		DEFAULT => -192
	},
	{#State 102
		ACTIONS => {
			'IDENTIFIER' => 213,
			'error' => 212
		}
	},
	{#State 103
		DEFAULT => -194
	},
	{#State 104
		DEFAULT => -72
	},
	{#State 105
		DEFAULT => -233
	},
	{#State 106
		DEFAULT => -215
	},
	{#State 107
		DEFAULT => -196
	},
	{#State 108
		DEFAULT => -224
	},
	{#State 109
		ACTIONS => {
			"<" => 214
		},
		DEFAULT => -283
	},
	{#State 110
		DEFAULT => -182
	},
	{#State 111
		ACTIONS => {
			"<" => 215,
			'error' => 216
		}
	},
	{#State 112
		DEFAULT => -219
	},
	{#State 113
		DEFAULT => -230
	},
	{#State 114
		DEFAULT => -214
	},
	{#State 115
		ACTIONS => {
			"<" => 217,
			'error' => 218
		}
	},
	{#State 116
		DEFAULT => -350
	},
	{#State 117
		ACTIONS => {
			"::" => 102,
			'ENUM' => 47,
			'CHAR' => 79,
			'OBJECT' => 105,
			'STRING' => 81,
			'OCTET' => 66,
			'WSTRING' => 109,
			'UNION' => 82,
			'UNSIGNED' => 93,
			'error' => 220,
			'ANY' => 67,
			'FLOAT' => 84,
			'LONG' => 68,
			'SEQUENCE' => 111,
			'DOUBLE' => 86,
			'IDENTIFIER' => 95,
			'SHORT' => 112,
			'BOOLEAN' => 113,
			'STRUCT' => 72,
			'VOID' => 98,
			'FIXED' => 115,
			'VALUEBASE' => 116,
			'WCHAR' => 77
		},
		GOTOS => {
			'union_type' => 90,
			'enum_header' => 29,
			'unsigned_short_int' => 91,
			'struct_type' => 92,
			'union_header' => 31,
			'struct_header' => 2,
			'member_list' => 221,
			'signed_longlong_int' => 69,
			'any_type' => 94,
			'enum_type' => 70,
			'template_type_spec' => 71,
			'member' => 219,
			'unsigned_long_int' => 96,
			'scoped_name' => 73,
			'string_type' => 97,
			'char_type' => 74,
			'fixed_pt_type' => 100,
			'signed_short_int' => 99,
			'signed_long_int' => 75,
			'wide_char_type' => 76,
			'octet_type' => 101,
			'wide_string_type' => 78,
			'object_type' => 103,
			'type_spec' => 222,
			'integer_type' => 80,
			'unsigned_int' => 106,
			'sequence_type' => 107,
			'unsigned_longlong_int' => 108,
			'constr_type_spec' => 110,
			'floating_pt_type' => 83,
			'value_base_type' => 85,
			'base_type_spec' => 87,
			'signed_int' => 114,
			'simple_type_spec' => 88,
			'boolean_type' => 89
		}
	},
	{#State 118
		DEFAULT => -179
	},
	{#State 119
		DEFAULT => -173
	},
	{#State 120
		ACTIONS => {
			'IDENTIFIER' => 226,
			'error' => 162
		},
		GOTOS => {
			'declarators' => 227,
			'simple_declarator' => 225,
			'array_declarator' => 224,
			'declarator' => 223,
			'complex_declarator' => 228
		}
	},
	{#State 121
		DEFAULT => -297
	},
	{#State 122
		DEFAULT => -296
	},
	{#State 123
		DEFAULT => -23
	},
	{#State 124
		DEFAULT => -10
	},
	{#State 125
		DEFAULT => -22
	},
	{#State 126
		ACTIONS => {
			'IDENTIFIER' => 230,
			'error' => 229
		}
	},
	{#State 127
		ACTIONS => {
			'IDENTIFIER' => 232,
			'error' => 231
		}
	},
	{#State 128
		ACTIONS => {
			"{" => -237
		},
		DEFAULT => -352
	},
	{#State 129
		ACTIONS => {
			"{" => -236
		},
		DEFAULT => -351
	},
	{#State 130
		ACTIONS => {
			"}" => 233,
			'OCTET' => -303,
			'NATIVE' => 34,
			'UNSIGNED' => -303,
			'TYPEDEF' => 3,
			'EXCEPTION' => 4,
			'ANY' => -303,
			'LONG' => -303,
			'IDENTIFIER' => -303,
			'STRUCT' => 8,
			'VOID' => -303,
			'WCHAR' => -303,
			'FACTORY' => 239,
			'ENUM' => 47,
			"::" => -303,
			'PRIVATE' => 240,
			'CHAR' => -303,
			'OBJECT' => -303,
			'ONEWAY' => 242,
			'STRING' => -303,
			'WSTRING' => -303,
			'UNION' => 14,
			'error' => 244,
			'FLOAT' => -303,
			'ATTRIBUTE' => 246,
			'PUBLIC' => 258,
			'SEQUENCE' => -303,
			'DOUBLE' => -303,
			'SHORT' => -303,
			'TYPEID' => 56,
			'BOOLEAN' => -303,
			'CONST' => 18,
			'READONLY' => 248,
			'FIXED' => -303,
			'TYPEPREFIX' => 64,
			'VALUEBASE' => -303
		},
		GOTOS => {
			'union_type' => 25,
			'op_header' => 238,
			'init_header_param' => 255,
			'readonly_attr_spec' => 250,
			'init_header' => 256,
			'enum_header' => 29,
			'op_dcl' => 241,
			'attr_dcl' => 257,
			'struct_type' => 30,
			'exports' => 243,
			'union_header' => 31,
			'except_dcl' => 251,
			'struct_header' => 2,
			'export' => 252,
			'state_member' => 245,
			'type_dcl' => 234,
			'constr_forward_decl' => 54,
			'state_mod' => 247,
			'enum_type' => 7,
			'op_attribute' => 253,
			'op_mod' => 235,
			'_export' => 236,
			'attr_spec' => 237,
			'exception_header' => 11,
			'const_dcl' => 254,
			'type_prefix_dcl' => 249,
			'init_dcl' => 260,
			'type_id_dcl' => 259
		}
	},
	{#State 131
		ACTIONS => {
			'IDENTIFIER' => 262,
			'error' => 261
		}
	},
	{#State 132
		ACTIONS => {
			'IDENTIFIER' => 264,
			'error' => 263
		}
	},
	{#State 133
		DEFAULT => -79
	},
	{#State 134
		DEFAULT => -295
	},
	{#State 135
		ACTIONS => {
			"}" => 265,
			"::" => 102,
			'ENUM' => 47,
			'CHAR' => 79,
			'OBJECT' => 105,
			'STRING' => 81,
			'OCTET' => 66,
			'WSTRING' => 109,
			'UNION' => 82,
			'UNSIGNED' => 93,
			'error' => 266,
			'ANY' => 67,
			'FLOAT' => 84,
			'LONG' => 68,
			'SEQUENCE' => 111,
			'DOUBLE' => 86,
			'IDENTIFIER' => 95,
			'SHORT' => 112,
			'BOOLEAN' => 113,
			'STRUCT' => 72,
			'VOID' => 98,
			'FIXED' => 115,
			'VALUEBASE' => 116,
			'WCHAR' => 77
		},
		GOTOS => {
			'union_type' => 90,
			'enum_header' => 29,
			'unsigned_short_int' => 91,
			'struct_type' => 92,
			'union_header' => 31,
			'struct_header' => 2,
			'member_list' => 267,
			'signed_longlong_int' => 69,
			'any_type' => 94,
			'enum_type' => 70,
			'template_type_spec' => 71,
			'member' => 219,
			'unsigned_long_int' => 96,
			'scoped_name' => 73,
			'string_type' => 97,
			'char_type' => 74,
			'fixed_pt_type' => 100,
			'signed_short_int' => 99,
			'signed_long_int' => 75,
			'wide_char_type' => 76,
			'octet_type' => 101,
			'wide_string_type' => 78,
			'object_type' => 103,
			'type_spec' => 222,
			'integer_type' => 80,
			'unsigned_int' => 106,
			'sequence_type' => 107,
			'unsigned_longlong_int' => 108,
			'constr_type_spec' => 110,
			'floating_pt_type' => 83,
			'value_base_type' => 85,
			'base_type_spec' => 87,
			'signed_int' => 114,
			'simple_type_spec' => 88,
			'boolean_type' => 89
		}
	},
	{#State 136
		ACTIONS => {
			"}" => 268,
			'OCTET' => -303,
			'NATIVE' => 34,
			'UNSIGNED' => -303,
			'TYPEDEF' => 3,
			'FINDER' => 269,
			'EXCEPTION' => 4,
			'ANY' => -303,
			'LONG' => -303,
			'IDENTIFIER' => -303,
			'STRUCT' => 8,
			'VOID' => -303,
			'WCHAR' => -303,
			'FACTORY' => 271,
			'ENUM' => 47,
			"::" => -303,
			'CHAR' => -303,
			'OBJECT' => -303,
			'ONEWAY' => 242,
			'STRING' => -303,
			'WSTRING' => -303,
			'UNION' => 14,
			'error' => 272,
			'FLOAT' => -303,
			'ATTRIBUTE' => 246,
			'SEQUENCE' => -303,
			'DOUBLE' => -303,
			'TYPEID' => 56,
			'SHORT' => -303,
			'BOOLEAN' => -303,
			'CONST' => 18,
			'READONLY' => 248,
			'FIXED' => -303,
			'TYPEPREFIX' => 64,
			'VALUEBASE' => -303
		},
		GOTOS => {
			'union_type' => 25,
			'op_header' => 238,
			'readonly_attr_spec' => 250,
			'enum_header' => 29,
			'op_dcl' => 241,
			'attr_dcl' => 257,
			'struct_type' => 30,
			'union_header' => 31,
			'except_dcl' => 251,
			'finder_header_param' => 277,
			'struct_header' => 2,
			'export' => 275,
			'type_dcl' => 234,
			'constr_forward_decl' => 54,
			'factory_header_param' => 276,
			'enum_type' => 7,
			'home_export' => 279,
			'finder_dcl' => 278,
			'op_attribute' => 253,
			'op_mod' => 235,
			'factory_header' => 273,
			'finder_header' => 280,
			'home_exports' => 270,
			'attr_spec' => 237,
			'exception_header' => 11,
			'const_dcl' => 254,
			'factory_dcl' => 274,
			'type_prefix_dcl' => 249,
			'type_id_dcl' => 259
		}
	},
	{#State 137
		DEFAULT => -430
	},
	{#State 138
		ACTIONS => {
			'SWITCH' => -247
		},
		DEFAULT => -354
	},
	{#State 139
		ACTIONS => {
			'SWITCH' => -246
		},
		DEFAULT => -353
	},
	{#State 140
		DEFAULT => -14
	},
	{#State 141
		ACTIONS => {
			"::" => 206
		},
		DEFAULT => -130
	},
	{#State 142
		DEFAULT => -123
	},
	{#State 143
		DEFAULT => -124
	},
	{#State 144
		DEFAULT => -128
	},
	{#State 145
		DEFAULT => -122
	},
	{#State 146
		DEFAULT => -126
	},
	{#State 147
		DEFAULT => -121
	},
	{#State 148
		DEFAULT => -125
	},
	{#State 149
		DEFAULT => -127
	},
	{#State 150
		DEFAULT => -131
	},
	{#State 151
		ACTIONS => {
			'IDENTIFIER' => 282,
			'error' => 281
		}
	},
	{#State 152
		DEFAULT => -129
	},
	{#State 153
		DEFAULT => -349
	},
	{#State 154
		DEFAULT => -20
	},
	{#State 155
		ACTIONS => {
			"}" => 283,
			'OCTET' => -303,
			'NATIVE' => 34,
			'UNSIGNED' => -303,
			'TYPEDEF' => 3,
			'EXCEPTION' => 4,
			'ANY' => -303,
			'LONG' => -303,
			'IDENTIFIER' => -303,
			'STRUCT' => 8,
			'VOID' => -303,
			'WCHAR' => -303,
			'FACTORY' => 239,
			'ENUM' => 47,
			"::" => -303,
			'PRIVATE' => 240,
			'CHAR' => -303,
			'OBJECT' => -303,
			'ONEWAY' => 242,
			'STRING' => -303,
			'WSTRING' => -303,
			'UNION' => 14,
			'error' => 285,
			'FLOAT' => -303,
			'ATTRIBUTE' => 246,
			'PUBLIC' => 258,
			'SEQUENCE' => -303,
			'DOUBLE' => -303,
			'SHORT' => -303,
			'TYPEID' => 56,
			'BOOLEAN' => -303,
			'CONST' => 18,
			'READONLY' => 248,
			'FIXED' => -303,
			'TYPEPREFIX' => 64,
			'VALUEBASE' => -303
		},
		GOTOS => {
			'union_type' => 25,
			'op_header' => 238,
			'init_header_param' => 255,
			'readonly_attr_spec' => 250,
			'init_header' => 256,
			'enum_header' => 29,
			'op_dcl' => 241,
			'attr_dcl' => 257,
			'struct_type' => 30,
			'union_header' => 31,
			'except_dcl' => 251,
			'struct_header' => 2,
			'export' => 287,
			'state_member' => 286,
			'type_dcl' => 234,
			'constr_forward_decl' => 54,
			'state_mod' => 247,
			'enum_type' => 7,
			'op_attribute' => 253,
			'op_mod' => 235,
			'value_elements' => 288,
			'value_element' => 284,
			'attr_spec' => 237,
			'exception_header' => 11,
			'const_dcl' => 254,
			'type_prefix_dcl' => 249,
			'type_id_dcl' => 259,
			'init_dcl' => 289
		}
	},
	{#State 156
		DEFAULT => -17
	},
	{#State 157
		DEFAULT => -266
	},
	{#State 158
		ACTIONS => {
			'IDENTIFIER' => 292,
			'error' => 291
		},
		GOTOS => {
			'enumerators' => 293,
			'enumerator' => 290
		}
	},
	{#State 159
		ACTIONS => {
			"(" => 295,
			'error' => 294
		}
	},
	{#State 160
		DEFAULT => -12
	},
	{#State 161
		ACTIONS => {
			"}" => 296,
			'OCTET' => -303,
			'NATIVE' => 34,
			'UNSIGNED' => -303,
			'TYPEDEF' => 3,
			'EXCEPTION' => 4,
			'ANY' => -303,
			'LONG' => -303,
			'IDENTIFIER' => -303,
			'STRUCT' => 8,
			'VOID' => -303,
			'WCHAR' => -303,
			'FACTORY' => 239,
			'ENUM' => 47,
			"::" => -303,
			'PRIVATE' => 240,
			'CHAR' => -303,
			'OBJECT' => -303,
			'ONEWAY' => 242,
			'STRING' => -303,
			'WSTRING' => -303,
			'UNION' => 14,
			'error' => 297,
			'FLOAT' => -303,
			'ATTRIBUTE' => 246,
			'PUBLIC' => 258,
			'SEQUENCE' => -303,
			'DOUBLE' => -303,
			'SHORT' => -303,
			'TYPEID' => 56,
			'BOOLEAN' => -303,
			'CONST' => 18,
			'READONLY' => 248,
			'FIXED' => -303,
			'TYPEPREFIX' => 64,
			'VALUEBASE' => -303
		},
		GOTOS => {
			'union_type' => 25,
			'op_header' => 238,
			'init_header_param' => 255,
			'readonly_attr_spec' => 250,
			'init_header' => 256,
			'enum_header' => 29,
			'op_dcl' => 241,
			'attr_dcl' => 257,
			'struct_type' => 30,
			'union_header' => 31,
			'except_dcl' => 251,
			'struct_header' => 2,
			'export' => 287,
			'state_member' => 286,
			'type_dcl' => 234,
			'constr_forward_decl' => 54,
			'state_mod' => 247,
			'enum_type' => 7,
			'op_attribute' => 253,
			'op_mod' => 235,
			'value_elements' => 298,
			'value_element' => 284,
			'attr_spec' => 237,
			'exception_header' => 11,
			'const_dcl' => 254,
			'type_prefix_dcl' => 249,
			'type_id_dcl' => 259,
			'init_dcl' => 289
		}
	},
	{#State 162
		ACTIONS => {
			";" => 300,
			"," => 299
		}
	},
	{#State 163
		DEFAULT => -177
	},
	{#State 164
		DEFAULT => -207
	},
	{#State 165
		ACTIONS => {
			'IDENTIFIER' => 302,
			'error' => 301
		}
	},
	{#State 166
		DEFAULT => -13
	},
	{#State 167
		ACTIONS => {
			"::" => 102,
			'IDENTIFIER' => 95,
			'error' => 304
		},
		GOTOS => {
			'scoped_name' => 303
		}
	},
	{#State 168
		ACTIONS => {
			"}" => 305,
			'OCTET' => -303,
			'NATIVE' => 34,
			'UNSIGNED' => -303,
			'TYPEDEF' => 3,
			'EXCEPTION' => 4,
			'ANY' => -303,
			'LONG' => -303,
			'IDENTIFIER' => -303,
			'STRUCT' => 8,
			'VOID' => -303,
			'WCHAR' => -303,
			'FACTORY' => 239,
			'ENUM' => 47,
			"::" => -303,
			'PRIVATE' => 240,
			'CHAR' => -303,
			'OBJECT' => -303,
			'ONEWAY' => 242,
			'STRING' => -303,
			'WSTRING' => -303,
			'UNION' => 14,
			'error' => 308,
			'FLOAT' => -303,
			'ATTRIBUTE' => 246,
			'PUBLIC' => 258,
			'SEQUENCE' => -303,
			'DOUBLE' => -303,
			'SHORT' => -303,
			'TYPEID' => 56,
			'BOOLEAN' => -303,
			'CONST' => 18,
			'READONLY' => 248,
			'FIXED' => -303,
			'TYPEPREFIX' => 64,
			'VALUEBASE' => -303
		},
		GOTOS => {
			'union_type' => 25,
			'op_header' => 238,
			'interface_body' => 306,
			'init_header_param' => 255,
			'readonly_attr_spec' => 250,
			'init_header' => 256,
			'enum_header' => 29,
			'op_dcl' => 241,
			'attr_dcl' => 257,
			'struct_type' => 30,
			'exports' => 307,
			'union_header' => 31,
			'except_dcl' => 251,
			'struct_header' => 2,
			'export' => 252,
			'state_member' => 245,
			'type_dcl' => 234,
			'constr_forward_decl' => 54,
			'state_mod' => 247,
			'enum_type' => 7,
			'op_attribute' => 253,
			'op_mod' => 235,
			'_export' => 236,
			'attr_spec' => 237,
			'exception_header' => 11,
			'const_dcl' => 254,
			'type_prefix_dcl' => 249,
			'init_dcl' => 260,
			'type_id_dcl' => 259
		}
	},
	{#State 169
		ACTIONS => {
			";" => 309
		}
	},
	{#State 170
		DEFAULT => -15
	},
	{#State 171
		ACTIONS => {
			"{" => -395
		},
		DEFAULT => -390
	},
	{#State 172
		ACTIONS => {
			":" => 310,
			'SUPPORTS' => -401,
			"{" => -401
		},
		DEFAULT => -389,
		GOTOS => {
			'component_inheritance_spec' => 311
		}
	},
	{#State 173
		DEFAULT => -18
	},
	{#State 174
		ACTIONS => {
			"}" => 312,
			'OCTET' => -303,
			'NATIVE' => 34,
			'UNSIGNED' => -303,
			'TYPEDEF' => 3,
			'EXCEPTION' => 4,
			'ANY' => -303,
			'LONG' => -303,
			'IDENTIFIER' => -303,
			'STRUCT' => 8,
			'VOID' => -303,
			'WCHAR' => -303,
			'FACTORY' => 239,
			'ENUM' => 47,
			"::" => -303,
			'PRIVATE' => 240,
			'CHAR' => -303,
			'OBJECT' => -303,
			'ONEWAY' => 242,
			'STRING' => -303,
			'WSTRING' => -303,
			'UNION' => 14,
			'error' => 314,
			'FLOAT' => -303,
			'ATTRIBUTE' => 246,
			'PUBLIC' => 258,
			'SEQUENCE' => -303,
			'DOUBLE' => -303,
			'SHORT' => -303,
			'TYPEID' => 56,
			'BOOLEAN' => -303,
			'CONST' => 18,
			'READONLY' => 248,
			'FIXED' => -303,
			'TYPEPREFIX' => 64,
			'VALUEBASE' => -303
		},
		GOTOS => {
			'union_type' => 25,
			'op_header' => 238,
			'init_header_param' => 255,
			'readonly_attr_spec' => 250,
			'init_header' => 256,
			'enum_header' => 29,
			'op_dcl' => 241,
			'attr_dcl' => 257,
			'struct_type' => 30,
			'exports' => 313,
			'union_header' => 31,
			'except_dcl' => 251,
			'struct_header' => 2,
			'export' => 252,
			'state_member' => 245,
			'type_dcl' => 234,
			'constr_forward_decl' => 54,
			'state_mod' => 247,
			'enum_type' => 7,
			'op_attribute' => 253,
			'op_mod' => 235,
			'_export' => 236,
			'attr_spec' => 237,
			'exception_header' => 11,
			'const_dcl' => 254,
			'type_prefix_dcl' => 249,
			'init_dcl' => 260,
			'type_id_dcl' => 259
		}
	},
	{#State 175
		DEFAULT => -11
	},
	{#State 176
		DEFAULT => -434
	},
	{#State 177
		ACTIONS => {
			":" => 315
		},
		DEFAULT => -437,
		GOTOS => {
			'home_inheritance_spec' => 316
		}
	},
	{#State 178
		DEFAULT => -268
	},
	{#State 179
		DEFAULT => -267
	},
	{#State 180
		ACTIONS => {
			'EMITS' => 330,
			"}" => 317,
			'PROVIDES' => 323,
			'READONLY' => 248,
			'PUBLISHES' => 324,
			'CONSUMES' => 326,
			'error' => 321,
			'USES' => 329,
			'ATTRIBUTE' => 246
		},
		GOTOS => {
			'consumes_dcl' => 318,
			'readonly_attr_spec' => 250,
			'component_exports' => 322,
			'uses_dcl' => 331,
			'emits_dcl' => 319,
			'publishes_dcl' => 332,
			'attr_dcl' => 327,
			'component_body' => 328,
			'attr_spec' => 237,
			'provides_dcl' => 325,
			'component_export' => 320
		}
	},
	{#State 181
		ACTIONS => {
			"}" => 333
		}
	},
	{#State 182
		ACTIONS => {
			'HOME' => 46,
			"}" => 334,
			'INTERFACE' => -39,
			'ENUM' => 47,
			'VALUETYPE' => -88,
			'CUSTOM' => 28,
			'UNION' => 14,
			'NATIVE' => 34,
			'TYPEDEF' => 3,
			'EXCEPTION' => 4,
			'error' => 335,
			'LOCAL' => 55,
			'IDENTIFIER' => 40,
			'TYPEID' => 56,
			'COMPONENT' => 42,
			'MODULE' => 57,
			'STRUCT' => 8,
			'CONST' => 18,
			'ABSTRACT' => 10,
			'TYPEPREFIX' => 64,
			'EVENTTYPE' => -88
		},
		GOTOS => {
			'union_type' => 25,
			'value_dcl' => 26,
			'value_box_dcl' => 27,
			'enum_header' => 29,
			'struct_type' => 30,
			'union_header' => 31,
			'value_box_header' => 1,
			'except_dcl' => 32,
			'value_header' => 33,
			'interface_mod' => 35,
			'struct_header' => 2,
			'interface' => 36,
			'home_header_spec' => 37,
			'type_dcl' => 5,
			'interface_header' => 38,
			'value_forward_dcl' => 39,
			'value_mod' => 6,
			'enum_type' => 7,
			'value' => 41,
			'event' => 43,
			'value_abs_header' => 9,
			'event_abs_header' => 44,
			'exception_header' => 11,
			'const_dcl' => 45,
			'interface_dcl' => 12,
			'component_header' => 48,
			'definitions' => 336,
			'home_header' => 13,
			'definition' => 51,
			'module_header' => 50,
			'constr_forward_decl' => 54,
			'module' => 16,
			'event_abs_dcl' => 17,
			'value_abs_dcl' => 19,
			'home_dcl' => 21,
			'component_dcl' => 20,
			'component' => 60,
			'event_forward_dcl' => 61,
			'forward_dcl' => 62,
			'event_dcl' => 63,
			'component_forward_dcl' => 22,
			'event_header' => 23,
			'type_prefix_dcl' => 24,
			'type_id_dcl' => 65
		}
	},
	{#State 183
		DEFAULT => -8
	},
	{#State 184
		ACTIONS => {
			'HOME' => 46,
			'INTERFACE' => -39,
			'ENUM' => 47,
			'CUSTOM' => 28,
			'UNION' => 14,
			'NATIVE' => 34,
			'TYPEDEF' => 3,
			'EXCEPTION' => 4,
			'LOCAL' => 55,
			'IDENTIFIER' => 40,
			'TYPEID' => 56,
			'COMPONENT' => 42,
			'MODULE' => 57,
			'STRUCT' => 8,
			'CONST' => 18,
			'ABSTRACT' => 10,
			'TYPEPREFIX' => 64
		},
		DEFAULT => -88,
		GOTOS => {
			'union_type' => 25,
			'value_dcl' => 26,
			'value_box_dcl' => 27,
			'enum_header' => 29,
			'struct_type' => 30,
			'union_header' => 31,
			'value_box_header' => 1,
			'except_dcl' => 32,
			'value_header' => 33,
			'interface_mod' => 35,
			'struct_header' => 2,
			'interface' => 36,
			'home_header_spec' => 37,
			'type_dcl' => 5,
			'interface_header' => 38,
			'value_forward_dcl' => 39,
			'value_mod' => 6,
			'enum_type' => 7,
			'value' => 41,
			'event' => 43,
			'value_abs_header' => 9,
			'event_abs_header' => 44,
			'exception_header' => 11,
			'const_dcl' => 45,
			'interface_dcl' => 12,
			'component_header' => 48,
			'definitions' => 337,
			'home_header' => 13,
			'definition' => 51,
			'module_header' => 50,
			'constr_forward_decl' => 54,
			'module' => 16,
			'event_abs_dcl' => 17,
			'value_abs_dcl' => 19,
			'home_dcl' => 21,
			'component_dcl' => 20,
			'component' => 60,
			'event_forward_dcl' => 61,
			'forward_dcl' => 62,
			'event_dcl' => 63,
			'component_forward_dcl' => 22,
			'event_header' => 23,
			'type_prefix_dcl' => 24,
			'type_id_dcl' => 65
		}
	},
	{#State 185
		ACTIONS => {
			"::" => 206
		},
		DEFAULT => -357
	},
	{#State 186
		ACTIONS => {
			";" => 125,
			'error' => 123
		},
		GOTOS => {
			'check_semicolon' => 338
		}
	},
	{#State 187
		DEFAULT => -356
	},
	{#State 188
		ACTIONS => {
			'STRING_LITERAL' => 188
		},
		DEFAULT => -166,
		GOTOS => {
			'string_literal' => 339
		}
	},
	{#State 189
		DEFAULT => -358
	},
	{#State 190
		DEFAULT => 0
	},
	{#State 191
		ACTIONS => {
			"::" => 206,
			'STRING_LITERAL' => 188,
			'error' => 340
		},
		GOTOS => {
			'string_literal' => 341
		}
	},
	{#State 192
		DEFAULT => -361
	},
	{#State 193
		DEFAULT => -29
	},
	{#State 194
		DEFAULT => -28
	},
	{#State 195
		DEFAULT => -2
	},
	{#State 196
		DEFAULT => -6
	},
	{#State 197
		DEFAULT => -19
	},
	{#State 198
		ACTIONS => {
			"::" => 206,
			'STRING_LITERAL' => 188,
			'error' => 342
		},
		GOTOS => {
			'string_literal' => 343
		}
	},
	{#State 199
		DEFAULT => -365
	},
	{#State 200
		ACTIONS => {
			'IDENTIFIER' => 213,
			'STRING_LITERAL' => 188,
			'error' => 212
		},
		GOTOS => {
			'string_literal' => 344
		}
	},
	{#State 201
		DEFAULT => -16
	},
	{#State 202
		DEFAULT => -221
	},
	{#State 203
		DEFAULT => -213
	},
	{#State 204
		DEFAULT => -237
	},
	{#State 205
		DEFAULT => -236
	},
	{#State 206
		ACTIONS => {
			'IDENTIFIER' => 346,
			'error' => 345
		}
	},
	{#State 207
		ACTIONS => {
			"-" => 347,
			"::" => 102,
			'IDENTIFIER' => 95,
			'TRUE' => 353,
			"~" => 362,
			"+" => 354,
			'INTEGER_LITERAL' => 355,
			'FLOATING_PT_LITERAL' => 370,
			"(" => 367,
			'FIXED_PT_LITERAL' => 360,
			'FALSE' => 364,
			'error' => 356,
			'STRING_LITERAL' => 188,
			'WIDE_STRING_LITERAL' => 371,
			'WIDE_CHARACTER_LITERAL' => 368,
			'CHARACTER_LITERAL' => 372
		},
		GOTOS => {
			'shift_expr' => 369,
			'literal' => 363,
			'const_exp' => 365,
			'unary_operator' => 348,
			'string_literal' => 366,
			'and_expr' => 349,
			'or_expr' => 350,
			'mult_expr' => 357,
			'scoped_name' => 351,
			'boolean_literal' => 358,
			'add_expr' => 359,
			'positive_int_const' => 373,
			'primary_expr' => 361,
			'unary_expr' => 352,
			'wide_string_literal' => 374,
			'xor_expr' => 375
		}
	},
	{#State 208
		DEFAULT => -247
	},
	{#State 209
		DEFAULT => -246
	},
	{#State 210
		ACTIONS => {
			'LONG' => 376
		},
		DEFAULT => -226
	},
	{#State 211
		DEFAULT => -225
	},
	{#State 212
		DEFAULT => -63
	},
	{#State 213
		DEFAULT => -62
	},
	{#State 214
		ACTIONS => {
			"-" => 347,
			"::" => 102,
			'IDENTIFIER' => 95,
			'TRUE' => 353,
			"~" => 362,
			"+" => 354,
			'INTEGER_LITERAL' => 355,
			'FLOATING_PT_LITERAL' => 370,
			"(" => 367,
			'FIXED_PT_LITERAL' => 360,
			'FALSE' => 364,
			'error' => 377,
			'STRING_LITERAL' => 188,
			'WIDE_STRING_LITERAL' => 371,
			'WIDE_CHARACTER_LITERAL' => 368,
			'CHARACTER_LITERAL' => 372
		},
		GOTOS => {
			'shift_expr' => 369,
			'literal' => 363,
			'const_exp' => 365,
			'unary_operator' => 348,
			'string_literal' => 366,
			'and_expr' => 349,
			'or_expr' => 350,
			'mult_expr' => 357,
			'scoped_name' => 351,
			'boolean_literal' => 358,
			'add_expr' => 359,
			'positive_int_const' => 378,
			'primary_expr' => 361,
			'unary_expr' => 352,
			'wide_string_literal' => 374,
			'xor_expr' => 375
		}
	},
	{#State 215
		ACTIONS => {
			"::" => 102,
			'CHAR' => 79,
			'OBJECT' => 105,
			'STRING' => 81,
			'OCTET' => 66,
			'WSTRING' => 109,
			'UNSIGNED' => 93,
			'error' => 379,
			'ANY' => 67,
			'FLOAT' => 84,
			'LONG' => 68,
			'SEQUENCE' => 111,
			'DOUBLE' => 86,
			'IDENTIFIER' => 95,
			'SHORT' => 112,
			'BOOLEAN' => 113,
			'VOID' => 98,
			'FIXED' => 115,
			'VALUEBASE' => 116,
			'WCHAR' => 77
		},
		GOTOS => {
			'wide_string_type' => 78,
			'object_type' => 103,
			'integer_type' => 80,
			'sequence_type' => 107,
			'unsigned_int' => 106,
			'unsigned_short_int' => 91,
			'unsigned_longlong_int' => 108,
			'floating_pt_type' => 83,
			'value_base_type' => 85,
			'signed_longlong_int' => 69,
			'template_type_spec' => 71,
			'any_type' => 94,
			'base_type_spec' => 87,
			'unsigned_long_int' => 96,
			'scoped_name' => 73,
			'signed_int' => 114,
			'string_type' => 97,
			'simple_type_spec' => 380,
			'char_type' => 74,
			'fixed_pt_type' => 100,
			'signed_short_int' => 99,
			'signed_long_int' => 75,
			'wide_char_type' => 76,
			'boolean_type' => 89,
			'octet_type' => 101
		}
	},
	{#State 216
		DEFAULT => -278
	},
	{#State 217
		ACTIONS => {
			"-" => 347,
			"::" => 102,
			'IDENTIFIER' => 95,
			'TRUE' => 353,
			"~" => 362,
			"+" => 354,
			'INTEGER_LITERAL' => 355,
			'FLOATING_PT_LITERAL' => 370,
			"(" => 367,
			'FIXED_PT_LITERAL' => 360,
			'FALSE' => 364,
			'error' => 381,
			'STRING_LITERAL' => 188,
			'WIDE_STRING_LITERAL' => 371,
			'WIDE_CHARACTER_LITERAL' => 368,
			'CHARACTER_LITERAL' => 372
		},
		GOTOS => {
			'shift_expr' => 369,
			'literal' => 363,
			'const_exp' => 365,
			'unary_operator' => 348,
			'string_literal' => 366,
			'and_expr' => 349,
			'or_expr' => 350,
			'mult_expr' => 357,
			'scoped_name' => 351,
			'boolean_literal' => 358,
			'add_expr' => 359,
			'positive_int_const' => 382,
			'primary_expr' => 361,
			'unary_expr' => 352,
			'wide_string_literal' => 374,
			'xor_expr' => 375
		}
	},
	{#State 218
		DEFAULT => -348
	},
	{#State 219
		ACTIONS => {
			"::" => 102,
			'ENUM' => 47,
			'CHAR' => 79,
			'OBJECT' => 105,
			'STRING' => 81,
			'OCTET' => 66,
			'WSTRING' => 109,
			'UNION' => 82,
			'UNSIGNED' => 93,
			'ANY' => 67,
			'FLOAT' => 84,
			'LONG' => 68,
			'SEQUENCE' => 111,
			'DOUBLE' => 86,
			'IDENTIFIER' => 95,
			'SHORT' => 112,
			'BOOLEAN' => 113,
			'STRUCT' => 72,
			'VOID' => 98,
			'FIXED' => 115,
			'VALUEBASE' => 116,
			'WCHAR' => 77
		},
		DEFAULT => -238,
		GOTOS => {
			'union_type' => 90,
			'enum_header' => 29,
			'unsigned_short_int' => 91,
			'struct_type' => 92,
			'union_header' => 31,
			'struct_header' => 2,
			'member_list' => 383,
			'signed_longlong_int' => 69,
			'any_type' => 94,
			'enum_type' => 70,
			'template_type_spec' => 71,
			'member' => 219,
			'unsigned_long_int' => 96,
			'scoped_name' => 73,
			'string_type' => 97,
			'char_type' => 74,
			'fixed_pt_type' => 100,
			'signed_short_int' => 99,
			'signed_long_int' => 75,
			'wide_char_type' => 76,
			'octet_type' => 101,
			'wide_string_type' => 78,
			'object_type' => 103,
			'type_spec' => 222,
			'integer_type' => 80,
			'unsigned_int' => 106,
			'sequence_type' => 107,
			'unsigned_longlong_int' => 108,
			'constr_type_spec' => 110,
			'floating_pt_type' => 83,
			'value_base_type' => 85,
			'base_type_spec' => 87,
			'signed_int' => 114,
			'simple_type_spec' => 88,
			'boolean_type' => 89
		}
	},
	{#State 220
		ACTIONS => {
			"}" => 384
		}
	},
	{#State 221
		ACTIONS => {
			"}" => 385
		}
	},
	{#State 222
		ACTIONS => {
			'IDENTIFIER' => 226,
			'error' => 162
		},
		GOTOS => {
			'declarators' => 386,
			'simple_declarator' => 225,
			'array_declarator' => 224,
			'declarator' => 223,
			'complex_declarator' => 228
		}
	},
	{#State 223
		ACTIONS => {
			"," => 387
		},
		DEFAULT => -203
	},
	{#State 224
		DEFAULT => -210
	},
	{#State 225
		DEFAULT => -205
	},
	{#State 226
		ACTIONS => {
			"[" => 389
		},
		DEFAULT => -207,
		GOTOS => {
			'fixed_array_sizes' => 388,
			'fixed_array_size' => 390
		}
	},
	{#State 227
		DEFAULT => -180
	},
	{#State 228
		DEFAULT => -206
	},
	{#State 229
		DEFAULT => -86
	},
	{#State 230
		ACTIONS => {
			":" => 391,
			'SUPPORTS' => 393,
			";" => -70,
			'error' => -70,
			"{" => -398
		},
		DEFAULT => -73,
		GOTOS => {
			'supported_interface_spec' => 392,
			'value_inheritance_spec' => 394
		}
	},
	{#State 231
		DEFAULT => -477
	},
	{#State 232
		ACTIONS => {
			":" => 391,
			'SUPPORTS' => 393,
			"{" => -398
		},
		DEFAULT => -466,
		GOTOS => {
			'supported_interface_spec' => 392,
			'value_inheritance_spec' => 395
		}
	},
	{#State 233
		DEFAULT => -74
	},
	{#State 234
		ACTIONS => {
			";" => 125,
			'error' => 123
		},
		GOTOS => {
			'check_semicolon' => 396
		}
	},
	{#State 235
		ACTIONS => {
			"::" => 102,
			'CHAR' => 79,
			'OBJECT' => 105,
			'STRING' => 81,
			'OCTET' => 66,
			'WSTRING' => 109,
			'UNSIGNED' => 93,
			'ANY' => 67,
			'FLOAT' => 84,
			'LONG' => 68,
			'SEQUENCE' => 111,
			'DOUBLE' => 86,
			'IDENTIFIER' => 95,
			'SHORT' => 112,
			'BOOLEAN' => 113,
			'VOID' => 403,
			'FIXED' => 115,
			'VALUEBASE' => 116,
			'WCHAR' => 77
		},
		GOTOS => {
			'wide_string_type' => 398,
			'object_type' => 103,
			'integer_type' => 80,
			'unsigned_int' => 106,
			'sequence_type' => 405,
			'unsigned_short_int' => 91,
			'op_param_type_spec' => 399,
			'unsigned_longlong_int' => 108,
			'floating_pt_type' => 83,
			'value_base_type' => 85,
			'signed_longlong_int' => 69,
			'any_type' => 94,
			'base_type_spec' => 400,
			'unsigned_long_int' => 96,
			'scoped_name' => 397,
			'signed_int' => 114,
			'string_type' => 402,
			'char_type' => 74,
			'signed_short_int' => 99,
			'fixed_pt_type' => 404,
			'signed_long_int' => 75,
			'op_type_spec' => 401,
			'wide_char_type' => 76,
			'boolean_type' => 89,
			'octet_type' => 101
		}
	},
	{#State 236
		ACTIONS => {
			"}" => -43,
			'NATIVE' => 34,
			'TYPEDEF' => 3,
			'EXCEPTION' => 4,
			'STRUCT' => 8,
			'FACTORY' => 239,
			'ENUM' => 47,
			'PRIVATE' => 240,
			'ONEWAY' => 242,
			'UNION' => 14,
			'ATTRIBUTE' => 246,
			'PUBLIC' => 258,
			'TYPEID' => 56,
			'CONST' => 18,
			'READONLY' => 248,
			'TYPEPREFIX' => 64
		},
		DEFAULT => -303,
		GOTOS => {
			'union_type' => 25,
			'op_header' => 238,
			'init_header_param' => 255,
			'readonly_attr_spec' => 250,
			'init_header' => 256,
			'enum_header' => 29,
			'op_dcl' => 241,
			'attr_dcl' => 257,
			'struct_type' => 30,
			'exports' => 406,
			'union_header' => 31,
			'except_dcl' => 251,
			'struct_header' => 2,
			'export' => 252,
			'state_member' => 245,
			'type_dcl' => 234,
			'constr_forward_decl' => 54,
			'state_mod' => 247,
			'enum_type' => 7,
			'op_attribute' => 253,
			'op_mod' => 235,
			'_export' => 236,
			'attr_spec' => 237,
			'exception_header' => 11,
			'const_dcl' => 254,
			'type_prefix_dcl' => 249,
			'init_dcl' => 260,
			'type_id_dcl' => 259
		}
	},
	{#State 237
		DEFAULT => -291
	},
	{#State 238
		ACTIONS => {
			"(" => 408,
			'error' => 407
		},
		GOTOS => {
			'parameter_dcls' => 409
		}
	},
	{#State 239
		ACTIONS => {
			'IDENTIFIER' => 411,
			'error' => 410
		}
	},
	{#State 240
		DEFAULT => -104
	},
	{#State 241
		ACTIONS => {
			";" => 125,
			'error' => 123
		},
		GOTOS => {
			'check_semicolon' => 412
		}
	},
	{#State 242
		DEFAULT => -304
	},
	{#State 243
		ACTIONS => {
			"}" => 413
		}
	},
	{#State 244
		ACTIONS => {
			"}" => 414
		}
	},
	{#State 245
		DEFAULT => -46
	},
	{#State 246
		ACTIONS => {
			"::" => 102,
			'ENUM' => 47,
			'CHAR' => 79,
			'OBJECT' => 105,
			'STRING' => 81,
			'OCTET' => 66,
			'WSTRING' => 109,
			'UNION' => 82,
			'UNSIGNED' => 93,
			'error' => 416,
			'ANY' => 67,
			'FLOAT' => 84,
			'LONG' => 68,
			'SEQUENCE' => 111,
			'DOUBLE' => 86,
			'IDENTIFIER' => 95,
			'SHORT' => 112,
			'BOOLEAN' => 113,
			'STRUCT' => 72,
			'VOID' => 417,
			'FIXED' => 115,
			'VALUEBASE' => 116,
			'WCHAR' => 77
		},
		GOTOS => {
			'union_type' => 90,
			'enum_header' => 29,
			'unsigned_short_int' => 91,
			'struct_type' => 92,
			'union_header' => 31,
			'struct_header' => 2,
			'signed_longlong_int' => 69,
			'any_type' => 94,
			'enum_type' => 70,
			'unsigned_long_int' => 96,
			'scoped_name' => 397,
			'string_type' => 402,
			'char_type' => 74,
			'param_type_spec' => 419,
			'signed_short_int' => 99,
			'fixed_pt_type' => 418,
			'signed_long_int' => 75,
			'wide_char_type' => 76,
			'octet_type' => 101,
			'wide_string_type' => 398,
			'object_type' => 103,
			'integer_type' => 80,
			'sequence_type' => 420,
			'unsigned_int' => 106,
			'op_param_type_spec' => 415,
			'unsigned_longlong_int' => 108,
			'constr_type_spec' => 421,
			'floating_pt_type' => 83,
			'value_base_type' => 85,
			'base_type_spec' => 400,
			'signed_int' => 114,
			'boolean_type' => 89
		}
	},
	{#State 247
		ACTIONS => {
			"::" => 102,
			'ENUM' => 47,
			'CHAR' => 79,
			'OBJECT' => 105,
			'STRING' => 81,
			'OCTET' => 66,
			'WSTRING' => 109,
			'UNION' => 82,
			'UNSIGNED' => 93,
			'error' => 422,
			'ANY' => 67,
			'FLOAT' => 84,
			'LONG' => 68,
			'SEQUENCE' => 111,
			'DOUBLE' => 86,
			'IDENTIFIER' => 95,
			'SHORT' => 112,
			'BOOLEAN' => 113,
			'STRUCT' => 72,
			'VOID' => 98,
			'FIXED' => 115,
			'VALUEBASE' => 116,
			'WCHAR' => 77
		},
		GOTOS => {
			'union_type' => 90,
			'enum_header' => 29,
			'unsigned_short_int' => 91,
			'struct_type' => 92,
			'union_header' => 31,
			'struct_header' => 2,
			'signed_longlong_int' => 69,
			'any_type' => 94,
			'enum_type' => 70,
			'template_type_spec' => 71,
			'unsigned_long_int' => 96,
			'scoped_name' => 73,
			'string_type' => 97,
			'char_type' => 74,
			'fixed_pt_type' => 100,
			'signed_short_int' => 99,
			'signed_long_int' => 75,
			'wide_char_type' => 76,
			'octet_type' => 101,
			'wide_string_type' => 78,
			'object_type' => 103,
			'type_spec' => 423,
			'integer_type' => 80,
			'unsigned_int' => 106,
			'sequence_type' => 107,
			'unsigned_longlong_int' => 108,
			'constr_type_spec' => 110,
			'floating_pt_type' => 83,
			'value_base_type' => 85,
			'base_type_spec' => 87,
			'signed_int' => 114,
			'simple_type_spec' => 88,
			'boolean_type' => 89
		}
	},
	{#State 248
		ACTIONS => {
			'error' => 424,
			'ATTRIBUTE' => 425
		}
	},
	{#State 249
		ACTIONS => {
			";" => 125,
			'error' => 123
		},
		GOTOS => {
			'check_semicolon' => 426
		}
	},
	{#State 250
		DEFAULT => -290
	},
	{#State 251
		ACTIONS => {
			";" => 125,
			'error' => 123
		},
		GOTOS => {
			'check_semicolon' => 427
		}
	},
	{#State 252
		DEFAULT => -45
	},
	{#State 253
		DEFAULT => -302
	},
	{#State 254
		ACTIONS => {
			";" => 125,
			'error' => 123
		},
		GOTOS => {
			'check_semicolon' => 428
		}
	},
	{#State 255
		ACTIONS => {
			'RAISES' => 429
		},
		DEFAULT => -326,
		GOTOS => {
			'raises_expr' => 430
		}
	},
	{#State 256
		ACTIONS => {
			"(" => 432,
			'error' => 431
		}
	},
	{#State 257
		ACTIONS => {
			";" => 125,
			'error' => 123
		},
		GOTOS => {
			'check_semicolon' => 433
		}
	},
	{#State 258
		DEFAULT => -103
	},
	{#State 259
		ACTIONS => {
			";" => 125,
			'error' => 123
		},
		GOTOS => {
			'check_semicolon' => 434
		}
	},
	{#State 260
		DEFAULT => -47
	},
	{#State 261
		DEFAULT => -78
	},
	{#State 262
		ACTIONS => {
			":" => 391,
			'SUPPORTS' => 393,
			"{" => -398
		},
		DEFAULT => -71,
		GOTOS => {
			'supported_interface_spec' => 392,
			'value_inheritance_spec' => 435
		}
	},
	{#State 263
		DEFAULT => -472
	},
	{#State 264
		ACTIONS => {
			":" => 391,
			'SUPPORTS' => 393,
			"{" => -398
		},
		DEFAULT => -467,
		GOTOS => {
			'supported_interface_spec' => 392,
			'value_inheritance_spec' => 436
		}
	},
	{#State 265
		DEFAULT => -292
	},
	{#State 266
		ACTIONS => {
			"}" => 437
		}
	},
	{#State 267
		ACTIONS => {
			"}" => 438
		}
	},
	{#State 268
		DEFAULT => -441
	},
	{#State 269
		ACTIONS => {
			'IDENTIFIER' => 440,
			'error' => 439
		}
	},
	{#State 270
		ACTIONS => {
			"}" => 441
		}
	},
	{#State 271
		ACTIONS => {
			'IDENTIFIER' => 443,
			'error' => 442
		}
	},
	{#State 272
		ACTIONS => {
			"}" => 444
		}
	},
	{#State 273
		ACTIONS => {
			"(" => 446,
			'error' => 445
		}
	},
	{#State 274
		ACTIONS => {
			";" => 125,
			'error' => 123
		},
		GOTOS => {
			'check_semicolon' => 447
		}
	},
	{#State 275
		DEFAULT => -446
	},
	{#State 276
		ACTIONS => {
			'RAISES' => 429
		},
		DEFAULT => -326,
		GOTOS => {
			'raises_expr' => 448
		}
	},
	{#State 277
		ACTIONS => {
			'RAISES' => 429
		},
		DEFAULT => -326,
		GOTOS => {
			'raises_expr' => 449
		}
	},
	{#State 278
		ACTIONS => {
			";" => 125,
			'error' => 123
		},
		GOTOS => {
			'check_semicolon' => 450
		}
	},
	{#State 279
		ACTIONS => {
			"}" => -444,
			'NATIVE' => 34,
			'TYPEDEF' => 3,
			'FINDER' => 269,
			'EXCEPTION' => 4,
			'STRUCT' => 8,
			'FACTORY' => 271,
			'ENUM' => 47,
			'ONEWAY' => 242,
			'UNION' => 14,
			'ATTRIBUTE' => 246,
			'TYPEID' => 56,
			'CONST' => 18,
			'READONLY' => 248,
			'TYPEPREFIX' => 64
		},
		DEFAULT => -303,
		GOTOS => {
			'union_type' => 25,
			'op_header' => 238,
			'readonly_attr_spec' => 250,
			'enum_header' => 29,
			'op_dcl' => 241,
			'attr_dcl' => 257,
			'struct_type' => 30,
			'union_header' => 31,
			'except_dcl' => 251,
			'finder_header_param' => 277,
			'struct_header' => 2,
			'export' => 275,
			'type_dcl' => 234,
			'constr_forward_decl' => 54,
			'factory_header_param' => 276,
			'enum_type' => 7,
			'home_export' => 279,
			'finder_dcl' => 278,
			'op_attribute' => 253,
			'op_mod' => 235,
			'factory_header' => 273,
			'finder_header' => 280,
			'home_exports' => 451,
			'attr_spec' => 237,
			'exception_header' => 11,
			'const_dcl' => 254,
			'factory_dcl' => 274,
			'type_prefix_dcl' => 249,
			'type_id_dcl' => 259
		}
	},
	{#State 280
		ACTIONS => {
			"(" => 453,
			'error' => 452
		}
	},
	{#State 281
		DEFAULT => -120
	},
	{#State 282
		ACTIONS => {
			'error' => 454,
			"=" => 455
		}
	},
	{#State 283
		DEFAULT => -473
	},
	{#State 284
		ACTIONS => {
			"}" => -83,
			'NATIVE' => 34,
			'TYPEDEF' => 3,
			'EXCEPTION' => 4,
			'STRUCT' => 8,
			'FACTORY' => 239,
			'ENUM' => 47,
			'PRIVATE' => 240,
			'ONEWAY' => 242,
			'UNION' => 14,
			'ATTRIBUTE' => 246,
			'PUBLIC' => 258,
			'TYPEID' => 56,
			'CONST' => 18,
			'READONLY' => 248,
			'TYPEPREFIX' => 64
		},
		DEFAULT => -303,
		GOTOS => {
			'union_type' => 25,
			'op_header' => 238,
			'init_header_param' => 255,
			'readonly_attr_spec' => 250,
			'init_header' => 256,
			'enum_header' => 29,
			'op_dcl' => 241,
			'attr_dcl' => 257,
			'struct_type' => 30,
			'union_header' => 31,
			'except_dcl' => 251,
			'struct_header' => 2,
			'export' => 287,
			'state_member' => 286,
			'type_dcl' => 234,
			'constr_forward_decl' => 54,
			'state_mod' => 247,
			'enum_type' => 7,
			'op_attribute' => 253,
			'op_mod' => 235,
			'value_elements' => 456,
			'value_element' => 284,
			'attr_spec' => 237,
			'exception_header' => 11,
			'const_dcl' => 254,
			'type_prefix_dcl' => 249,
			'type_id_dcl' => 259,
			'init_dcl' => 289
		}
	},
	{#State 285
		ACTIONS => {
			"}" => 457
		}
	},
	{#State 286
		DEFAULT => -98
	},
	{#State 287
		DEFAULT => -97
	},
	{#State 288
		ACTIONS => {
			"}" => 458
		}
	},
	{#State 289
		DEFAULT => -99
	},
	{#State 290
		ACTIONS => {
			";" => 460,
			"," => 459
		},
		DEFAULT => -269
	},
	{#State 291
		ACTIONS => {
			"}" => 461
		}
	},
	{#State 292
		DEFAULT => -273
	},
	{#State 293
		ACTIONS => {
			"}" => 462
		}
	},
	{#State 294
		DEFAULT => -245
	},
	{#State 295
		ACTIONS => {
			"::" => 102,
			'ENUM' => 47,
			'IDENTIFIER' => 95,
			'SHORT' => 112,
			'CHAR' => 79,
			'BOOLEAN' => 113,
			'UNSIGNED' => 93,
			'error' => 468,
			'LONG' => 463
		},
		GOTOS => {
			'signed_longlong_int' => 69,
			'enum_type' => 464,
			'unsigned_long_int' => 96,
			'integer_type' => 467,
			'unsigned_int' => 106,
			'enum_header' => 29,
			'scoped_name' => 465,
			'signed_int' => 114,
			'unsigned_short_int' => 91,
			'unsigned_longlong_int' => 108,
			'char_type' => 466,
			'signed_short_int' => 99,
			'signed_long_int' => 75,
			'boolean_type' => 469,
			'switch_type_spec' => 470
		}
	},
	{#State 296
		DEFAULT => -80
	},
	{#State 297
		ACTIONS => {
			"}" => 471
		}
	},
	{#State 298
		ACTIONS => {
			"}" => 472
		}
	},
	{#State 299
		DEFAULT => -208
	},
	{#State 300
		DEFAULT => -209
	},
	{#State 301
		ACTIONS => {
			"{" => -41
		},
		DEFAULT => -36
	},
	{#State 302
		ACTIONS => {
			":" => 473,
			"{" => -57
		},
		DEFAULT => -35,
		GOTOS => {
			'interface_inheritance_spec' => 474
		}
	},
	{#State 303
		ACTIONS => {
			"::" => 206,
			'PRIMARYKEY' => 475
		},
		DEFAULT => -440,
		GOTOS => {
			'primary_key_spec' => 476
		}
	},
	{#State 304
		DEFAULT => -432
	},
	{#State 305
		DEFAULT => -32
	},
	{#State 306
		ACTIONS => {
			"}" => 477
		}
	},
	{#State 307
		DEFAULT => -42
	},
	{#State 308
		ACTIONS => {
			"}" => 478
		}
	},
	{#State 309
		DEFAULT => -21
	},
	{#State 310
		ACTIONS => {
			"::" => 102,
			'IDENTIFIER' => 95,
			'error' => 480
		},
		GOTOS => {
			'scoped_name' => 479
		}
	},
	{#State 311
		ACTIONS => {
			'SUPPORTS' => 393
		},
		DEFAULT => -398,
		GOTOS => {
			'supported_interface_spec' => 481
		}
	},
	{#State 312
		DEFAULT => -468
	},
	{#State 313
		ACTIONS => {
			"}" => 482
		}
	},
	{#State 314
		ACTIONS => {
			"}" => 483
		}
	},
	{#State 315
		ACTIONS => {
			"::" => 102,
			'IDENTIFIER' => 95,
			'error' => 485
		},
		GOTOS => {
			'scoped_name' => 484
		}
	},
	{#State 316
		ACTIONS => {
			'SUPPORTS' => 393
		},
		DEFAULT => -398,
		GOTOS => {
			'supported_interface_spec' => 486
		}
	},
	{#State 317
		DEFAULT => -391
	},
	{#State 318
		ACTIONS => {
			";" => 125,
			'error' => 123
		},
		GOTOS => {
			'check_semicolon' => 487
		}
	},
	{#State 319
		ACTIONS => {
			";" => 125,
			'error' => 123
		},
		GOTOS => {
			'check_semicolon' => 488
		}
	},
	{#State 320
		ACTIONS => {
			'EMITS' => 330,
			'PROVIDES' => 323,
			'READONLY' => 248,
			'PUBLISHES' => 324,
			'CONSUMES' => 326,
			'USES' => 329,
			'ATTRIBUTE' => 246
		},
		DEFAULT => -403,
		GOTOS => {
			'consumes_dcl' => 318,
			'readonly_attr_spec' => 250,
			'component_exports' => 489,
			'uses_dcl' => 331,
			'emits_dcl' => 319,
			'publishes_dcl' => 332,
			'attr_dcl' => 327,
			'attr_spec' => 237,
			'provides_dcl' => 325,
			'component_export' => 320
		}
	},
	{#State 321
		ACTIONS => {
			"}" => 490
		}
	},
	{#State 322
		DEFAULT => -402
	},
	{#State 323
		ACTIONS => {
			"::" => 102,
			'IDENTIFIER' => 95,
			'error' => 492,
			'OBJECT' => 493
		},
		GOTOS => {
			'interface_type' => 494,
			'scoped_name' => 491
		}
	},
	{#State 324
		ACTIONS => {
			"::" => 102,
			'IDENTIFIER' => 95,
			'error' => 496
		},
		GOTOS => {
			'scoped_name' => 495
		}
	},
	{#State 325
		ACTIONS => {
			";" => 125,
			'error' => 123
		},
		GOTOS => {
			'check_semicolon' => 497
		}
	},
	{#State 326
		ACTIONS => {
			"::" => 102,
			'IDENTIFIER' => 95,
			'error' => 499
		},
		GOTOS => {
			'scoped_name' => 498
		}
	},
	{#State 327
		ACTIONS => {
			";" => 125,
			'error' => 123
		},
		GOTOS => {
			'check_semicolon' => 500
		}
	},
	{#State 328
		ACTIONS => {
			"}" => 501
		}
	},
	{#State 329
		ACTIONS => {
			'MULTIPLE' => 503
		},
		DEFAULT => -420,
		GOTOS => {
			'uses_mod' => 502
		}
	},
	{#State 330
		ACTIONS => {
			"::" => 102,
			'IDENTIFIER' => 95,
			'error' => 505
		},
		GOTOS => {
			'scoped_name' => 504
		}
	},
	{#State 331
		ACTIONS => {
			";" => 125,
			'error' => 123
		},
		GOTOS => {
			'check_semicolon' => 506
		}
	},
	{#State 332
		ACTIONS => {
			";" => 125,
			'error' => 123
		},
		GOTOS => {
			'check_semicolon' => 507
		}
	},
	{#State 333
		DEFAULT => -27
	},
	{#State 334
		DEFAULT => -26
	},
	{#State 335
		ACTIONS => {
			"}" => 508
		}
	},
	{#State 336
		ACTIONS => {
			"}" => 509
		}
	},
	{#State 337
		DEFAULT => -9
	},
	{#State 338
		DEFAULT => -355
	},
	{#State 339
		DEFAULT => -167
	},
	{#State 340
		DEFAULT => -360
	},
	{#State 341
		DEFAULT => -359
	},
	{#State 342
		DEFAULT => -363
	},
	{#State 343
		DEFAULT => -362
	},
	{#State 344
		DEFAULT => -364
	},
	{#State 345
		DEFAULT => -65
	},
	{#State 346
		DEFAULT => -64
	},
	{#State 347
		DEFAULT => -151
	},
	{#State 348
		ACTIONS => {
			"::" => 102,
			'IDENTIFIER' => 95,
			'TRUE' => 353,
			'INTEGER_LITERAL' => 355,
			'FLOATING_PT_LITERAL' => 370,
			'FIXED_PT_LITERAL' => 360,
			"(" => 367,
			'FALSE' => 364,
			'STRING_LITERAL' => 188,
			'WIDE_STRING_LITERAL' => 371,
			'WIDE_CHARACTER_LITERAL' => 368,
			'CHARACTER_LITERAL' => 372
		},
		GOTOS => {
			'literal' => 363,
			'primary_expr' => 510,
			'scoped_name' => 351,
			'wide_string_literal' => 374,
			'string_literal' => 366,
			'boolean_literal' => 358
		}
	},
	{#State 349
		ACTIONS => {
			"&" => 511
		},
		DEFAULT => -135
	},
	{#State 350
		ACTIONS => {
			"|" => 512
		},
		DEFAULT => -132
	},
	{#State 351
		ACTIONS => {
			"::" => 206
		},
		DEFAULT => -154
	},
	{#State 352
		DEFAULT => -145
	},
	{#State 353
		DEFAULT => -170
	},
	{#State 354
		DEFAULT => -152
	},
	{#State 355
		DEFAULT => -158
	},
	{#State 356
		ACTIONS => {
			">" => 513
		}
	},
	{#State 357
		ACTIONS => {
			"%" => 514,
			"*" => 515,
			"/" => 516
		},
		DEFAULT => -142
	},
	{#State 358
		DEFAULT => -165
	},
	{#State 359
		ACTIONS => {
			"-" => 517,
			"+" => 518
		},
		DEFAULT => -139
	},
	{#State 360
		DEFAULT => -163
	},
	{#State 361
		DEFAULT => -150
	},
	{#State 362
		DEFAULT => -153
	},
	{#State 363
		DEFAULT => -155
	},
	{#State 364
		DEFAULT => -171
	},
	{#State 365
		DEFAULT => -172
	},
	{#State 366
		DEFAULT => -159
	},
	{#State 367
		ACTIONS => {
			"-" => 347,
			"::" => 102,
			'IDENTIFIER' => 95,
			'TRUE' => 353,
			"~" => 362,
			"+" => 354,
			'INTEGER_LITERAL' => 355,
			'FLOATING_PT_LITERAL' => 370,
			"(" => 367,
			'FIXED_PT_LITERAL' => 360,
			'FALSE' => 364,
			'error' => 519,
			'STRING_LITERAL' => 188,
			'WIDE_STRING_LITERAL' => 371,
			'WIDE_CHARACTER_LITERAL' => 368,
			'CHARACTER_LITERAL' => 372
		},
		GOTOS => {
			'and_expr' => 349,
			'or_expr' => 350,
			'shift_expr' => 369,
			'mult_expr' => 357,
			'scoped_name' => 351,
			'boolean_literal' => 358,
			'literal' => 363,
			'add_expr' => 359,
			'unary_expr' => 352,
			'primary_expr' => 361,
			'const_exp' => 520,
			'unary_operator' => 348,
			'xor_expr' => 375,
			'wide_string_literal' => 374,
			'string_literal' => 366
		}
	},
	{#State 368
		DEFAULT => -162
	},
	{#State 369
		ACTIONS => {
			"<<" => 522,
			">>" => 521
		},
		DEFAULT => -137
	},
	{#State 370
		DEFAULT => -164
	},
	{#State 371
		ACTIONS => {
			'WIDE_STRING_LITERAL' => 371
		},
		DEFAULT => -168,
		GOTOS => {
			'wide_string_literal' => 523
		}
	},
	{#State 372
		DEFAULT => -161
	},
	{#State 373
		ACTIONS => {
			">" => 524
		}
	},
	{#State 374
		DEFAULT => -160
	},
	{#State 375
		ACTIONS => {
			"^" => 525
		},
		DEFAULT => -133
	},
	{#State 376
		DEFAULT => -227
	},
	{#State 377
		ACTIONS => {
			">" => 526
		}
	},
	{#State 378
		ACTIONS => {
			">" => 527
		}
	},
	{#State 379
		ACTIONS => {
			">" => 528
		}
	},
	{#State 380
		ACTIONS => {
			"," => 529,
			">" => 530
		}
	},
	{#State 381
		ACTIONS => {
			">" => 531
		}
	},
	{#State 382
		ACTIONS => {
			"," => 532
		}
	},
	{#State 383
		DEFAULT => -239
	},
	{#State 384
		DEFAULT => -235
	},
	{#State 385
		DEFAULT => -234
	},
	{#State 386
		ACTIONS => {
			";" => 125,
			'error' => 123
		},
		GOTOS => {
			'check_semicolon' => 533
		}
	},
	{#State 387
		ACTIONS => {
			'IDENTIFIER' => 226,
			'error' => 162
		},
		GOTOS => {
			'declarators' => 534,
			'simple_declarator' => 225,
			'array_declarator' => 224,
			'declarator' => 223,
			'complex_declarator' => 228
		}
	},
	{#State 388
		DEFAULT => -285
	},
	{#State 389
		ACTIONS => {
			"-" => 347,
			"::" => 102,
			'IDENTIFIER' => 95,
			'TRUE' => 353,
			"~" => 362,
			"+" => 354,
			'INTEGER_LITERAL' => 355,
			'FLOATING_PT_LITERAL' => 370,
			"(" => 367,
			'FIXED_PT_LITERAL' => 360,
			'FALSE' => 364,
			'error' => 535,
			'STRING_LITERAL' => 188,
			'WIDE_STRING_LITERAL' => 371,
			'WIDE_CHARACTER_LITERAL' => 368,
			'CHARACTER_LITERAL' => 372
		},
		GOTOS => {
			'shift_expr' => 369,
			'literal' => 363,
			'const_exp' => 365,
			'unary_operator' => 348,
			'string_literal' => 366,
			'and_expr' => 349,
			'or_expr' => 350,
			'mult_expr' => 357,
			'scoped_name' => 351,
			'boolean_literal' => 358,
			'add_expr' => 359,
			'positive_int_const' => 536,
			'primary_expr' => 361,
			'unary_expr' => 352,
			'wide_string_literal' => 374,
			'xor_expr' => 375
		}
	},
	{#State 390
		ACTIONS => {
			"[" => 389
		},
		DEFAULT => -286,
		GOTOS => {
			'fixed_array_sizes' => 537,
			'fixed_array_size' => 390
		}
	},
	{#State 391
		ACTIONS => {
			'TRUNCATABLE' => 538
		},
		DEFAULT => -93,
		GOTOS => {
			'inheritance_mod' => 539
		}
	},
	{#State 392
		DEFAULT => -91
	},
	{#State 393
		ACTIONS => {
			"::" => 102,
			'IDENTIFIER' => 95,
			'error' => 541
		},
		GOTOS => {
			'interface_name' => 543,
			'interface_names' => 542,
			'scoped_name' => 540
		}
	},
	{#State 394
		DEFAULT => -85
	},
	{#State 395
		DEFAULT => -476
	},
	{#State 396
		DEFAULT => -48
	},
	{#State 397
		ACTIONS => {
			"::" => 206
		},
		DEFAULT => -344
	},
	{#State 398
		DEFAULT => -343
	},
	{#State 399
		DEFAULT => -305
	},
	{#State 400
		DEFAULT => -341
	},
	{#State 401
		ACTIONS => {
			'IDENTIFIER' => 545,
			'error' => 544
		}
	},
	{#State 402
		DEFAULT => -342
	},
	{#State 403
		DEFAULT => -306
	},
	{#State 404
		DEFAULT => -308
	},
	{#State 405
		DEFAULT => -307
	},
	{#State 406
		DEFAULT => -44
	},
	{#State 407
		DEFAULT => -299
	},
	{#State 408
		ACTIONS => {
			"::" => -322,
			'ENUM' => -322,
			'CHAR' => -322,
			'OBJECT' => -322,
			'STRING' => -322,
			'OCTET' => -322,
			'WSTRING' => -322,
			'UNION' => -322,
			'UNSIGNED' => -322,
			'error' => 549,
			'ANY' => -322,
			'FLOAT' => -322,
			")" => 550,
			'LONG' => -322,
			'SEQUENCE' => -322,
			'IDENTIFIER' => -322,
			'DOUBLE' => -322,
			'SHORT' => -322,
			'BOOLEAN' => -322,
			'INOUT' => 546,
			"..." => 553,
			'STRUCT' => -322,
			'OUT' => 547,
			'IN' => 554,
			'VOID' => -322,
			'FIXED' => -322,
			'VALUEBASE' => -322,
			'WCHAR' => -322
		},
		GOTOS => {
			'param_attribute' => 551,
			'param_dcl' => 548,
			'param_dcls' => 552
		}
	},
	{#State 409
		ACTIONS => {
			'RAISES' => 429
		},
		DEFAULT => -326,
		GOTOS => {
			'raises_expr' => 555
		}
	},
	{#State 410
		DEFAULT => -111
	},
	{#State 411
		DEFAULT => -110
	},
	{#State 412
		DEFAULT => -52
	},
	{#State 413
		DEFAULT => -75
	},
	{#State 414
		DEFAULT => -76
	},
	{#State 415
		DEFAULT => -336
	},
	{#State 416
		DEFAULT => -374
	},
	{#State 417
		DEFAULT => -337
	},
	{#State 418
		DEFAULT => -339
	},
	{#State 419
		ACTIONS => {
			'IDENTIFIER' => 164,
			'error' => 162
		},
		GOTOS => {
			'simple_declarator' => 557,
			'attr_declarator' => 556
		}
	},
	{#State 420
		DEFAULT => -338
	},
	{#State 421
		DEFAULT => -340
	},
	{#State 422
		ACTIONS => {
			";" => 558
		}
	},
	{#State 423
		ACTIONS => {
			'IDENTIFIER' => 226,
			'error' => 559
		},
		GOTOS => {
			'declarators' => 560,
			'simple_declarator' => 225,
			'array_declarator' => 224,
			'declarator' => 223,
			'complex_declarator' => 228
		}
	},
	{#State 424
		DEFAULT => -368
	},
	{#State 425
		ACTIONS => {
			"::" => 102,
			'ENUM' => 47,
			'CHAR' => 79,
			'OBJECT' => 105,
			'STRING' => 81,
			'OCTET' => 66,
			'WSTRING' => 109,
			'UNION' => 82,
			'UNSIGNED' => 93,
			'error' => 561,
			'ANY' => 67,
			'FLOAT' => 84,
			'LONG' => 68,
			'SEQUENCE' => 111,
			'DOUBLE' => 86,
			'IDENTIFIER' => 95,
			'SHORT' => 112,
			'BOOLEAN' => 113,
			'STRUCT' => 72,
			'VOID' => 417,
			'FIXED' => 115,
			'VALUEBASE' => 116,
			'WCHAR' => 77
		},
		GOTOS => {
			'union_type' => 90,
			'enum_header' => 29,
			'unsigned_short_int' => 91,
			'struct_type' => 92,
			'union_header' => 31,
			'struct_header' => 2,
			'signed_longlong_int' => 69,
			'any_type' => 94,
			'enum_type' => 70,
			'unsigned_long_int' => 96,
			'scoped_name' => 397,
			'string_type' => 402,
			'char_type' => 74,
			'param_type_spec' => 562,
			'signed_short_int' => 99,
			'fixed_pt_type' => 418,
			'signed_long_int' => 75,
			'wide_char_type' => 76,
			'octet_type' => 101,
			'wide_string_type' => 398,
			'object_type' => 103,
			'integer_type' => 80,
			'sequence_type' => 420,
			'unsigned_int' => 106,
			'op_param_type_spec' => 415,
			'unsigned_longlong_int' => 108,
			'constr_type_spec' => 421,
			'floating_pt_type' => 83,
			'value_base_type' => 85,
			'base_type_spec' => 400,
			'signed_int' => 114,
			'boolean_type' => 89
		}
	},
	{#State 426
		DEFAULT => -54
	},
	{#State 427
		DEFAULT => -50
	},
	{#State 428
		DEFAULT => -49
	},
	{#State 429
		ACTIONS => {
			"(" => 564,
			'error' => 563
		}
	},
	{#State 430
		ACTIONS => {
			";" => 125,
			'error' => 123
		},
		GOTOS => {
			'check_semicolon' => 565
		}
	},
	{#State 431
		DEFAULT => -109
	},
	{#State 432
		ACTIONS => {
			'error' => 566,
			")" => 567,
			'IN' => 571
		},
		GOTOS => {
			'init_param_decl' => 570,
			'init_param_decls' => 568,
			'init_param_attribute' => 569
		}
	},
	{#State 433
		DEFAULT => -51
	},
	{#State 434
		DEFAULT => -53
	},
	{#State 435
		DEFAULT => -77
	},
	{#State 436
		DEFAULT => -471
	},
	{#State 437
		DEFAULT => -294
	},
	{#State 438
		DEFAULT => -293
	},
	{#State 439
		DEFAULT => -462
	},
	{#State 440
		DEFAULT => -461
	},
	{#State 441
		DEFAULT => -442
	},
	{#State 442
		DEFAULT => -455
	},
	{#State 443
		DEFAULT => -454
	},
	{#State 444
		DEFAULT => -443
	},
	{#State 445
		DEFAULT => -453
	},
	{#State 446
		ACTIONS => {
			'error' => 572,
			")" => 573,
			'IN' => 571
		},
		GOTOS => {
			'init_param_decl' => 570,
			'init_param_decls' => 574,
			'init_param_attribute' => 569
		}
	},
	{#State 447
		DEFAULT => -447
	},
	{#State 448
		DEFAULT => -449
	},
	{#State 449
		DEFAULT => -456
	},
	{#State 450
		DEFAULT => -448
	},
	{#State 451
		DEFAULT => -445
	},
	{#State 452
		DEFAULT => -460
	},
	{#State 453
		ACTIONS => {
			'error' => 575,
			")" => 576,
			'IN' => 571
		},
		GOTOS => {
			'init_param_decl' => 570,
			'init_param_decls' => 577,
			'init_param_attribute' => 569
		}
	},
	{#State 454
		DEFAULT => -119
	},
	{#State 455
		ACTIONS => {
			"-" => 347,
			"::" => 102,
			'IDENTIFIER' => 95,
			'TRUE' => 353,
			"~" => 362,
			"+" => 354,
			'INTEGER_LITERAL' => 355,
			'FLOATING_PT_LITERAL' => 370,
			"(" => 367,
			'FIXED_PT_LITERAL' => 360,
			'FALSE' => 364,
			'error' => 578,
			'STRING_LITERAL' => 188,
			'WIDE_STRING_LITERAL' => 371,
			'WIDE_CHARACTER_LITERAL' => 368,
			'CHARACTER_LITERAL' => 372
		},
		GOTOS => {
			'and_expr' => 349,
			'or_expr' => 350,
			'shift_expr' => 369,
			'mult_expr' => 357,
			'scoped_name' => 351,
			'boolean_literal' => 358,
			'literal' => 363,
			'add_expr' => 359,
			'unary_expr' => 352,
			'primary_expr' => 361,
			'const_exp' => 579,
			'unary_operator' => 348,
			'xor_expr' => 375,
			'wide_string_literal' => 374,
			'string_literal' => 366
		}
	},
	{#State 456
		DEFAULT => -84
	},
	{#State 457
		DEFAULT => -475
	},
	{#State 458
		DEFAULT => -474
	},
	{#State 459
		ACTIONS => {
			'IDENTIFIER' => 292
		},
		DEFAULT => -271,
		GOTOS => {
			'enumerators' => 580,
			'enumerator' => 290
		}
	},
	{#State 460
		DEFAULT => -272
	},
	{#State 461
		DEFAULT => -265
	},
	{#State 462
		DEFAULT => -264
	},
	{#State 463
		ACTIONS => {
			'LONG' => 202
		},
		DEFAULT => -220
	},
	{#State 464
		DEFAULT => -251
	},
	{#State 465
		ACTIONS => {
			"::" => 206
		},
		DEFAULT => -252
	},
	{#State 466
		DEFAULT => -249
	},
	{#State 467
		DEFAULT => -248
	},
	{#State 468
		ACTIONS => {
			")" => 581
		}
	},
	{#State 469
		DEFAULT => -250
	},
	{#State 470
		ACTIONS => {
			")" => 582
		}
	},
	{#State 471
		DEFAULT => -82
	},
	{#State 472
		DEFAULT => -81
	},
	{#State 473
		ACTIONS => {
			"::" => 102,
			'IDENTIFIER' => 95,
			'error' => 583
		},
		GOTOS => {
			'interface_name' => 543,
			'interface_names' => 584,
			'scoped_name' => 540
		}
	},
	{#State 474
		DEFAULT => -40
	},
	{#State 475
		ACTIONS => {
			"::" => 102,
			'IDENTIFIER' => 95,
			'error' => 586
		},
		GOTOS => {
			'scoped_name' => 585
		}
	},
	{#State 476
		DEFAULT => -431
	},
	{#State 477
		DEFAULT => -33
	},
	{#State 478
		DEFAULT => -34
	},
	{#State 479
		ACTIONS => {
			"::" => 206
		},
		DEFAULT => -399
	},
	{#State 480
		DEFAULT => -400
	},
	{#State 481
		DEFAULT => -394
	},
	{#State 482
		DEFAULT => -469
	},
	{#State 483
		DEFAULT => -470
	},
	{#State 484
		ACTIONS => {
			"::" => 206
		},
		DEFAULT => -435
	},
	{#State 485
		DEFAULT => -436
	},
	{#State 486
		DEFAULT => -433
	},
	{#State 487
		DEFAULT => -409
	},
	{#State 488
		DEFAULT => -407
	},
	{#State 489
		DEFAULT => -404
	},
	{#State 490
		DEFAULT => -393
	},
	{#State 491
		ACTIONS => {
			"::" => 206
		},
		DEFAULT => -414
	},
	{#State 492
		DEFAULT => -413
	},
	{#State 493
		DEFAULT => -415
	},
	{#State 494
		ACTIONS => {
			'IDENTIFIER' => 588,
			'error' => 587
		}
	},
	{#State 495
		ACTIONS => {
			"::" => 206,
			'IDENTIFIER' => 590,
			'error' => 589
		}
	},
	{#State 496
		DEFAULT => -426
	},
	{#State 497
		DEFAULT => -405
	},
	{#State 498
		ACTIONS => {
			"::" => 206,
			'IDENTIFIER' => 592,
			'error' => 591
		}
	},
	{#State 499
		DEFAULT => -429
	},
	{#State 500
		DEFAULT => -410
	},
	{#State 501
		DEFAULT => -392
	},
	{#State 502
		ACTIONS => {
			"::" => 102,
			'IDENTIFIER' => 95,
			'error' => 593,
			'OBJECT' => 493
		},
		GOTOS => {
			'interface_type' => 594,
			'scoped_name' => 491
		}
	},
	{#State 503
		DEFAULT => -419
	},
	{#State 504
		ACTIONS => {
			"::" => 206,
			'IDENTIFIER' => 596,
			'error' => 595
		}
	},
	{#State 505
		DEFAULT => -423
	},
	{#State 506
		DEFAULT => -406
	},
	{#State 507
		DEFAULT => -408
	},
	{#State 508
		DEFAULT => -25
	},
	{#State 509
		DEFAULT => -24
	},
	{#State 510
		DEFAULT => -149
	},
	{#State 511
		ACTIONS => {
			"-" => 347,
			"::" => 102,
			'IDENTIFIER' => 95,
			'TRUE' => 353,
			"~" => 362,
			"+" => 354,
			'INTEGER_LITERAL' => 355,
			'FLOATING_PT_LITERAL' => 370,
			"(" => 367,
			'FIXED_PT_LITERAL' => 360,
			'FALSE' => 364,
			'STRING_LITERAL' => 188,
			'WIDE_STRING_LITERAL' => 371,
			'WIDE_CHARACTER_LITERAL' => 368,
			'CHARACTER_LITERAL' => 372
		},
		GOTOS => {
			'shift_expr' => 597,
			'mult_expr' => 357,
			'scoped_name' => 351,
			'boolean_literal' => 358,
			'add_expr' => 359,
			'literal' => 363,
			'unary_expr' => 352,
			'primary_expr' => 361,
			'unary_operator' => 348,
			'wide_string_literal' => 374,
			'string_literal' => 366
		}
	},
	{#State 512
		ACTIONS => {
			"-" => 347,
			"::" => 102,
			'IDENTIFIER' => 95,
			'TRUE' => 353,
			"~" => 362,
			"+" => 354,
			'INTEGER_LITERAL' => 355,
			'FLOATING_PT_LITERAL' => 370,
			"(" => 367,
			'FIXED_PT_LITERAL' => 360,
			'FALSE' => 364,
			'STRING_LITERAL' => 188,
			'WIDE_STRING_LITERAL' => 371,
			'WIDE_CHARACTER_LITERAL' => 368,
			'CHARACTER_LITERAL' => 372
		},
		GOTOS => {
			'and_expr' => 349,
			'shift_expr' => 369,
			'mult_expr' => 357,
			'scoped_name' => 351,
			'boolean_literal' => 358,
			'literal' => 363,
			'add_expr' => 359,
			'unary_expr' => 352,
			'primary_expr' => 361,
			'unary_operator' => 348,
			'xor_expr' => 598,
			'wide_string_literal' => 374,
			'string_literal' => 366
		}
	},
	{#State 513
		DEFAULT => -281
	},
	{#State 514
		ACTIONS => {
			"-" => 347,
			"::" => 102,
			'IDENTIFIER' => 95,
			'TRUE' => 353,
			"~" => 362,
			"+" => 354,
			'INTEGER_LITERAL' => 355,
			'FLOATING_PT_LITERAL' => 370,
			"(" => 367,
			'FIXED_PT_LITERAL' => 360,
			'FALSE' => 364,
			'STRING_LITERAL' => 188,
			'WIDE_STRING_LITERAL' => 371,
			'WIDE_CHARACTER_LITERAL' => 368,
			'CHARACTER_LITERAL' => 372
		},
		GOTOS => {
			'literal' => 363,
			'primary_expr' => 361,
			'unary_expr' => 599,
			'unary_operator' => 348,
			'scoped_name' => 351,
			'wide_string_literal' => 374,
			'string_literal' => 366,
			'boolean_literal' => 358
		}
	},
	{#State 515
		ACTIONS => {
			"-" => 347,
			"::" => 102,
			'IDENTIFIER' => 95,
			'TRUE' => 353,
			"~" => 362,
			"+" => 354,
			'INTEGER_LITERAL' => 355,
			'FLOATING_PT_LITERAL' => 370,
			"(" => 367,
			'FIXED_PT_LITERAL' => 360,
			'FALSE' => 364,
			'STRING_LITERAL' => 188,
			'WIDE_STRING_LITERAL' => 371,
			'WIDE_CHARACTER_LITERAL' => 368,
			'CHARACTER_LITERAL' => 372
		},
		GOTOS => {
			'literal' => 363,
			'primary_expr' => 361,
			'unary_expr' => 600,
			'unary_operator' => 348,
			'scoped_name' => 351,
			'wide_string_literal' => 374,
			'string_literal' => 366,
			'boolean_literal' => 358
		}
	},
	{#State 516
		ACTIONS => {
			"-" => 347,
			"::" => 102,
			'IDENTIFIER' => 95,
			'TRUE' => 353,
			"~" => 362,
			"+" => 354,
			'INTEGER_LITERAL' => 355,
			'FLOATING_PT_LITERAL' => 370,
			"(" => 367,
			'FIXED_PT_LITERAL' => 360,
			'FALSE' => 364,
			'STRING_LITERAL' => 188,
			'WIDE_STRING_LITERAL' => 371,
			'WIDE_CHARACTER_LITERAL' => 368,
			'CHARACTER_LITERAL' => 372
		},
		GOTOS => {
			'literal' => 363,
			'primary_expr' => 361,
			'unary_expr' => 601,
			'unary_operator' => 348,
			'scoped_name' => 351,
			'wide_string_literal' => 374,
			'string_literal' => 366,
			'boolean_literal' => 358
		}
	},
	{#State 517
		ACTIONS => {
			"-" => 347,
			"::" => 102,
			'IDENTIFIER' => 95,
			'TRUE' => 353,
			"~" => 362,
			"+" => 354,
			'INTEGER_LITERAL' => 355,
			'FLOATING_PT_LITERAL' => 370,
			"(" => 367,
			'FIXED_PT_LITERAL' => 360,
			'FALSE' => 364,
			'STRING_LITERAL' => 188,
			'WIDE_STRING_LITERAL' => 371,
			'WIDE_CHARACTER_LITERAL' => 368,
			'CHARACTER_LITERAL' => 372
		},
		GOTOS => {
			'mult_expr' => 602,
			'scoped_name' => 351,
			'boolean_literal' => 358,
			'literal' => 363,
			'unary_expr' => 352,
			'primary_expr' => 361,
			'unary_operator' => 348,
			'wide_string_literal' => 374,
			'string_literal' => 366
		}
	},
	{#State 518
		ACTIONS => {
			"-" => 347,
			"::" => 102,
			'IDENTIFIER' => 95,
			'TRUE' => 353,
			"~" => 362,
			"+" => 354,
			'INTEGER_LITERAL' => 355,
			'FLOATING_PT_LITERAL' => 370,
			"(" => 367,
			'FIXED_PT_LITERAL' => 360,
			'FALSE' => 364,
			'STRING_LITERAL' => 188,
			'WIDE_STRING_LITERAL' => 371,
			'WIDE_CHARACTER_LITERAL' => 368,
			'CHARACTER_LITERAL' => 372
		},
		GOTOS => {
			'mult_expr' => 603,
			'scoped_name' => 351,
			'boolean_literal' => 358,
			'literal' => 363,
			'unary_expr' => 352,
			'primary_expr' => 361,
			'unary_operator' => 348,
			'wide_string_literal' => 374,
			'string_literal' => 366
		}
	},
	{#State 519
		ACTIONS => {
			")" => 604
		}
	},
	{#State 520
		ACTIONS => {
			")" => 605
		}
	},
	{#State 521
		ACTIONS => {
			"-" => 347,
			"::" => 102,
			'IDENTIFIER' => 95,
			'TRUE' => 353,
			"~" => 362,
			"+" => 354,
			'INTEGER_LITERAL' => 355,
			'FLOATING_PT_LITERAL' => 370,
			"(" => 367,
			'FIXED_PT_LITERAL' => 360,
			'FALSE' => 364,
			'STRING_LITERAL' => 188,
			'WIDE_STRING_LITERAL' => 371,
			'WIDE_CHARACTER_LITERAL' => 368,
			'CHARACTER_LITERAL' => 372
		},
		GOTOS => {
			'mult_expr' => 357,
			'scoped_name' => 351,
			'boolean_literal' => 358,
			'add_expr' => 606,
			'literal' => 363,
			'unary_expr' => 352,
			'primary_expr' => 361,
			'unary_operator' => 348,
			'wide_string_literal' => 374,
			'string_literal' => 366
		}
	},
	{#State 522
		ACTIONS => {
			"-" => 347,
			"::" => 102,
			'IDENTIFIER' => 95,
			'TRUE' => 353,
			"~" => 362,
			"+" => 354,
			'INTEGER_LITERAL' => 355,
			'FLOATING_PT_LITERAL' => 370,
			"(" => 367,
			'FIXED_PT_LITERAL' => 360,
			'FALSE' => 364,
			'STRING_LITERAL' => 188,
			'WIDE_STRING_LITERAL' => 371,
			'WIDE_CHARACTER_LITERAL' => 368,
			'CHARACTER_LITERAL' => 372
		},
		GOTOS => {
			'mult_expr' => 357,
			'scoped_name' => 351,
			'boolean_literal' => 358,
			'add_expr' => 607,
			'literal' => 363,
			'unary_expr' => 352,
			'primary_expr' => 361,
			'unary_operator' => 348,
			'wide_string_literal' => 374,
			'string_literal' => 366
		}
	},
	{#State 523
		DEFAULT => -169
	},
	{#State 524
		DEFAULT => -279
	},
	{#State 525
		ACTIONS => {
			"-" => 347,
			"::" => 102,
			'IDENTIFIER' => 95,
			'TRUE' => 353,
			"~" => 362,
			"+" => 354,
			'INTEGER_LITERAL' => 355,
			'FLOATING_PT_LITERAL' => 370,
			"(" => 367,
			'FIXED_PT_LITERAL' => 360,
			'FALSE' => 364,
			'STRING_LITERAL' => 188,
			'WIDE_STRING_LITERAL' => 371,
			'WIDE_CHARACTER_LITERAL' => 368,
			'CHARACTER_LITERAL' => 372
		},
		GOTOS => {
			'and_expr' => 608,
			'shift_expr' => 369,
			'mult_expr' => 357,
			'scoped_name' => 351,
			'boolean_literal' => 358,
			'literal' => 363,
			'add_expr' => 359,
			'unary_expr' => 352,
			'primary_expr' => 361,
			'unary_operator' => 348,
			'wide_string_literal' => 374,
			'string_literal' => 366
		}
	},
	{#State 526
		DEFAULT => -284
	},
	{#State 527
		DEFAULT => -282
	},
	{#State 528
		DEFAULT => -277
	},
	{#State 529
		ACTIONS => {
			"-" => 347,
			"::" => 102,
			'IDENTIFIER' => 95,
			'TRUE' => 353,
			"~" => 362,
			"+" => 354,
			'INTEGER_LITERAL' => 355,
			'FLOATING_PT_LITERAL' => 370,
			"(" => 367,
			'FIXED_PT_LITERAL' => 360,
			'FALSE' => 364,
			'error' => 609,
			'STRING_LITERAL' => 188,
			'WIDE_STRING_LITERAL' => 371,
			'WIDE_CHARACTER_LITERAL' => 368,
			'CHARACTER_LITERAL' => 372
		},
		GOTOS => {
			'shift_expr' => 369,
			'literal' => 363,
			'const_exp' => 365,
			'unary_operator' => 348,
			'string_literal' => 366,
			'and_expr' => 349,
			'or_expr' => 350,
			'mult_expr' => 357,
			'scoped_name' => 351,
			'boolean_literal' => 358,
			'add_expr' => 359,
			'positive_int_const' => 610,
			'primary_expr' => 361,
			'unary_expr' => 352,
			'wide_string_literal' => 374,
			'xor_expr' => 375
		}
	},
	{#State 530
		DEFAULT => -276
	},
	{#State 531
		DEFAULT => -347
	},
	{#State 532
		ACTIONS => {
			"-" => 347,
			"::" => 102,
			'IDENTIFIER' => 95,
			'TRUE' => 353,
			"~" => 362,
			"+" => 354,
			'INTEGER_LITERAL' => 355,
			'FLOATING_PT_LITERAL' => 370,
			"(" => 367,
			'FIXED_PT_LITERAL' => 360,
			'FALSE' => 364,
			'error' => 611,
			'STRING_LITERAL' => 188,
			'WIDE_STRING_LITERAL' => 371,
			'WIDE_CHARACTER_LITERAL' => 368,
			'CHARACTER_LITERAL' => 372
		},
		GOTOS => {
			'shift_expr' => 369,
			'literal' => 363,
			'const_exp' => 365,
			'unary_operator' => 348,
			'string_literal' => 366,
			'and_expr' => 349,
			'or_expr' => 350,
			'mult_expr' => 357,
			'scoped_name' => 351,
			'boolean_literal' => 358,
			'add_expr' => 359,
			'positive_int_const' => 612,
			'primary_expr' => 361,
			'unary_expr' => 352,
			'wide_string_literal' => 374,
			'xor_expr' => 375
		}
	},
	{#State 533
		DEFAULT => -240
	},
	{#State 534
		DEFAULT => -204
	},
	{#State 535
		ACTIONS => {
			"]" => 613
		}
	},
	{#State 536
		ACTIONS => {
			"]" => 614
		}
	},
	{#State 537
		DEFAULT => -287
	},
	{#State 538
		DEFAULT => -92
	},
	{#State 539
		ACTIONS => {
			"::" => 102,
			'IDENTIFIER' => 95,
			'error' => 617
		},
		GOTOS => {
			'value_name' => 618,
			'value_names' => 615,
			'scoped_name' => 616
		}
	},
	{#State 540
		ACTIONS => {
			"::" => 206
		},
		DEFAULT => -60
	},
	{#State 541
		DEFAULT => -397
	},
	{#State 542
		DEFAULT => -396
	},
	{#State 543
		ACTIONS => {
			"," => 619
		},
		DEFAULT => -58
	},
	{#State 544
		DEFAULT => -301
	},
	{#State 545
		DEFAULT => -300
	},
	{#State 546
		DEFAULT => -321
	},
	{#State 547
		DEFAULT => -320
	},
	{#State 548
		ACTIONS => {
			";" => 620
		},
		DEFAULT => -315
	},
	{#State 549
		ACTIONS => {
			")" => 621
		}
	},
	{#State 550
		DEFAULT => -312
	},
	{#State 551
		ACTIONS => {
			"::" => 102,
			'ENUM' => 47,
			'CHAR' => 79,
			'OBJECT' => 105,
			'STRING' => 81,
			'OCTET' => 66,
			'WSTRING' => 109,
			'UNION' => 82,
			'UNSIGNED' => 93,
			'ANY' => 67,
			'FLOAT' => 84,
			'LONG' => 68,
			'SEQUENCE' => 111,
			'DOUBLE' => 86,
			'IDENTIFIER' => 95,
			'SHORT' => 112,
			'BOOLEAN' => 113,
			'STRUCT' => 72,
			'VOID' => 417,
			'FIXED' => 115,
			'VALUEBASE' => 116,
			'WCHAR' => 77
		},
		GOTOS => {
			'union_type' => 90,
			'enum_header' => 29,
			'unsigned_short_int' => 91,
			'struct_type' => 92,
			'union_header' => 31,
			'struct_header' => 2,
			'signed_longlong_int' => 69,
			'any_type' => 94,
			'enum_type' => 70,
			'unsigned_long_int' => 96,
			'scoped_name' => 397,
			'string_type' => 402,
			'char_type' => 74,
			'param_type_spec' => 622,
			'signed_short_int' => 99,
			'fixed_pt_type' => 418,
			'signed_long_int' => 75,
			'wide_char_type' => 76,
			'octet_type' => 101,
			'wide_string_type' => 398,
			'object_type' => 103,
			'integer_type' => 80,
			'sequence_type' => 420,
			'unsigned_int' => 106,
			'op_param_type_spec' => 415,
			'unsigned_longlong_int' => 108,
			'constr_type_spec' => 421,
			'floating_pt_type' => 83,
			'value_base_type' => 85,
			'base_type_spec' => 400,
			'signed_int' => 114,
			'boolean_type' => 89
		}
	},
	{#State 552
		ACTIONS => {
			"," => 623,
			")" => 624
		}
	},
	{#State 553
		ACTIONS => {
			")" => 625
		}
	},
	{#State 554
		DEFAULT => -319
	},
	{#State 555
		ACTIONS => {
			'CONTEXT' => 627
		},
		DEFAULT => -333,
		GOTOS => {
			'context_expr' => 626
		}
	},
	{#State 556
		DEFAULT => -373
	},
	{#State 557
		ACTIONS => {
			'SETRAISES' => 633,
			'GETRAISES' => 628,
			"," => 629
		},
		DEFAULT => -380,
		GOTOS => {
			'get_except_expr' => 630,
			'attr_raises_expr' => 631,
			'set_except_expr' => 632
		}
	},
	{#State 558
		DEFAULT => -102
	},
	{#State 559
		ACTIONS => {
			";" => 634,
			"," => 299
		}
	},
	{#State 560
		ACTIONS => {
			";" => 125,
			'error' => 123
		},
		GOTOS => {
			'check_semicolon' => 635
		}
	},
	{#State 561
		DEFAULT => -367
	},
	{#State 562
		ACTIONS => {
			'IDENTIFIER' => 164,
			'error' => 162
		},
		GOTOS => {
			'readonly_attr_declarator' => 636,
			'simple_declarator' => 637
		}
	},
	{#State 563
		DEFAULT => -325
	},
	{#State 564
		ACTIONS => {
			"::" => 102,
			'IDENTIFIER' => 95,
			'error' => 639
		},
		GOTOS => {
			'exception_names' => 640,
			'scoped_name' => 638,
			'exception_name' => 641
		}
	},
	{#State 565
		DEFAULT => -105
	},
	{#State 566
		ACTIONS => {
			")" => 642
		}
	},
	{#State 567
		DEFAULT => -106
	},
	{#State 568
		ACTIONS => {
			")" => 643
		}
	},
	{#State 569
		ACTIONS => {
			"::" => 102,
			'ENUM' => 47,
			'CHAR' => 79,
			'OBJECT' => 105,
			'STRING' => 81,
			'OCTET' => 66,
			'WSTRING' => 109,
			'UNION' => 82,
			'UNSIGNED' => 93,
			'error' => 644,
			'ANY' => 67,
			'FLOAT' => 84,
			'LONG' => 68,
			'SEQUENCE' => 111,
			'DOUBLE' => 86,
			'IDENTIFIER' => 95,
			'SHORT' => 112,
			'BOOLEAN' => 113,
			'STRUCT' => 72,
			'VOID' => 417,
			'FIXED' => 115,
			'VALUEBASE' => 116,
			'WCHAR' => 77
		},
		GOTOS => {
			'union_type' => 90,
			'enum_header' => 29,
			'unsigned_short_int' => 91,
			'struct_type' => 92,
			'union_header' => 31,
			'struct_header' => 2,
			'signed_longlong_int' => 69,
			'any_type' => 94,
			'enum_type' => 70,
			'unsigned_long_int' => 96,
			'scoped_name' => 397,
			'string_type' => 402,
			'char_type' => 74,
			'param_type_spec' => 645,
			'signed_short_int' => 99,
			'fixed_pt_type' => 418,
			'signed_long_int' => 75,
			'wide_char_type' => 76,
			'octet_type' => 101,
			'wide_string_type' => 398,
			'object_type' => 103,
			'integer_type' => 80,
			'sequence_type' => 420,
			'unsigned_int' => 106,
			'op_param_type_spec' => 415,
			'unsigned_longlong_int' => 108,
			'constr_type_spec' => 421,
			'floating_pt_type' => 83,
			'value_base_type' => 85,
			'base_type_spec' => 400,
			'signed_int' => 114,
			'boolean_type' => 89
		}
	},
	{#State 570
		ACTIONS => {
			"," => 646
		},
		DEFAULT => -112
	},
	{#State 571
		DEFAULT => -116
	},
	{#State 572
		ACTIONS => {
			")" => 647
		}
	},
	{#State 573
		DEFAULT => -450
	},
	{#State 574
		ACTIONS => {
			")" => 648
		}
	},
	{#State 575
		ACTIONS => {
			")" => 649
		}
	},
	{#State 576
		DEFAULT => -457
	},
	{#State 577
		ACTIONS => {
			")" => 650
		}
	},
	{#State 578
		DEFAULT => -118
	},
	{#State 579
		DEFAULT => -117
	},
	{#State 580
		DEFAULT => -270
	},
	{#State 581
		DEFAULT => -244
	},
	{#State 582
		ACTIONS => {
			"{" => 652,
			'error' => 651
		}
	},
	{#State 583
		DEFAULT => -56
	},
	{#State 584
		DEFAULT => -55
	},
	{#State 585
		ACTIONS => {
			"::" => 206
		},
		DEFAULT => -438
	},
	{#State 586
		DEFAULT => -439
	},
	{#State 587
		DEFAULT => -412
	},
	{#State 588
		DEFAULT => -411
	},
	{#State 589
		DEFAULT => -425
	},
	{#State 590
		DEFAULT => -424
	},
	{#State 591
		DEFAULT => -428
	},
	{#State 592
		DEFAULT => -427
	},
	{#State 593
		DEFAULT => -418
	},
	{#State 594
		ACTIONS => {
			'IDENTIFIER' => 654,
			'error' => 653
		}
	},
	{#State 595
		DEFAULT => -422
	},
	{#State 596
		DEFAULT => -421
	},
	{#State 597
		ACTIONS => {
			"<<" => 522,
			">>" => 521
		},
		DEFAULT => -138
	},
	{#State 598
		ACTIONS => {
			"^" => 525
		},
		DEFAULT => -134
	},
	{#State 599
		DEFAULT => -148
	},
	{#State 600
		DEFAULT => -146
	},
	{#State 601
		DEFAULT => -147
	},
	{#State 602
		ACTIONS => {
			"%" => 514,
			"*" => 515,
			"/" => 516
		},
		DEFAULT => -144
	},
	{#State 603
		ACTIONS => {
			"%" => 514,
			"*" => 515,
			"/" => 516
		},
		DEFAULT => -143
	},
	{#State 604
		DEFAULT => -157
	},
	{#State 605
		DEFAULT => -156
	},
	{#State 606
		ACTIONS => {
			"-" => 517,
			"+" => 518
		},
		DEFAULT => -140
	},
	{#State 607
		ACTIONS => {
			"-" => 517,
			"+" => 518
		},
		DEFAULT => -141
	},
	{#State 608
		ACTIONS => {
			"&" => 511
		},
		DEFAULT => -136
	},
	{#State 609
		ACTIONS => {
			">" => 655
		}
	},
	{#State 610
		ACTIONS => {
			">" => 656
		}
	},
	{#State 611
		ACTIONS => {
			">" => 657
		}
	},
	{#State 612
		ACTIONS => {
			">" => 658
		}
	},
	{#State 613
		DEFAULT => -289
	},
	{#State 614
		DEFAULT => -288
	},
	{#State 615
		ACTIONS => {
			'SUPPORTS' => 393
		},
		DEFAULT => -398,
		GOTOS => {
			'supported_interface_spec' => 659
		}
	},
	{#State 616
		ACTIONS => {
			"::" => 206
		},
		DEFAULT => -96
	},
	{#State 617
		DEFAULT => -90
	},
	{#State 618
		ACTIONS => {
			"," => 660
		},
		DEFAULT => -94
	},
	{#State 619
		ACTIONS => {
			"::" => 102,
			'IDENTIFIER' => 95
		},
		GOTOS => {
			'interface_name' => 543,
			'interface_names' => 661,
			'scoped_name' => 540
		}
	},
	{#State 620
		DEFAULT => -317
	},
	{#State 621
		DEFAULT => -314
	},
	{#State 622
		ACTIONS => {
			'IDENTIFIER' => 164,
			'error' => 162
		},
		GOTOS => {
			'simple_declarator' => 662
		}
	},
	{#State 623
		ACTIONS => {
			")" => 664,
			'INOUT' => 546,
			"..." => 665,
			'OUT' => 547,
			'IN' => 554
		},
		DEFAULT => -322,
		GOTOS => {
			'param_attribute' => 551,
			'param_dcl' => 663
		}
	},
	{#State 624
		DEFAULT => -309
	},
	{#State 625
		DEFAULT => -313
	},
	{#State 626
		DEFAULT => -298
	},
	{#State 627
		ACTIONS => {
			"(" => 667,
			'error' => 666
		}
	},
	{#State 628
		ACTIONS => {
			"(" => 670,
			'error' => 668
		},
		GOTOS => {
			'exception_list' => 669
		}
	},
	{#State 629
		ACTIONS => {
			'IDENTIFIER' => 164,
			'error' => 162
		},
		GOTOS => {
			'simple_declarator' => 672,
			'simple_declarators' => 671
		}
	},
	{#State 630
		ACTIONS => {
			'SETRAISES' => 633
		},
		DEFAULT => -378,
		GOTOS => {
			'set_except_expr' => 673
		}
	},
	{#State 631
		DEFAULT => -375
	},
	{#State 632
		DEFAULT => -379
	},
	{#State 633
		ACTIONS => {
			"(" => 670,
			'error' => 674
		},
		GOTOS => {
			'exception_list' => 675
		}
	},
	{#State 634
		ACTIONS => {
			";" => -209,
			"," => -209,
			'error' => -209
		},
		DEFAULT => -101
	},
	{#State 635
		DEFAULT => -100
	},
	{#State 636
		DEFAULT => -366
	},
	{#State 637
		ACTIONS => {
			'RAISES' => 429,
			"," => 676
		},
		DEFAULT => -326,
		GOTOS => {
			'raises_expr' => 677
		}
	},
	{#State 638
		ACTIONS => {
			"::" => 206
		},
		DEFAULT => -329
	},
	{#State 639
		ACTIONS => {
			")" => 678
		}
	},
	{#State 640
		ACTIONS => {
			")" => 679
		}
	},
	{#State 641
		ACTIONS => {
			"," => 680
		},
		DEFAULT => -327
	},
	{#State 642
		DEFAULT => -108
	},
	{#State 643
		DEFAULT => -107
	},
	{#State 644
		DEFAULT => -115
	},
	{#State 645
		ACTIONS => {
			'IDENTIFIER' => 164,
			'error' => 162
		},
		GOTOS => {
			'simple_declarator' => 681
		}
	},
	{#State 646
		ACTIONS => {
			'IN' => 571
		},
		GOTOS => {
			'init_param_decl' => 570,
			'init_param_decls' => 682,
			'init_param_attribute' => 569
		}
	},
	{#State 647
		DEFAULT => -452
	},
	{#State 648
		DEFAULT => -451
	},
	{#State 649
		DEFAULT => -459
	},
	{#State 650
		DEFAULT => -458
	},
	{#State 651
		DEFAULT => -243
	},
	{#State 652
		ACTIONS => {
			'DEFAULT' => 689,
			'error' => 685,
			'CASE' => 683
		},
		GOTOS => {
			'case_label' => 686,
			'switch_body' => 687,
			'case' => 684,
			'case_labels' => 688
		}
	},
	{#State 653
		DEFAULT => -417
	},
	{#State 654
		DEFAULT => -416
	},
	{#State 655
		DEFAULT => -275
	},
	{#State 656
		DEFAULT => -274
	},
	{#State 657
		DEFAULT => -346
	},
	{#State 658
		DEFAULT => -345
	},
	{#State 659
		DEFAULT => -89
	},
	{#State 660
		ACTIONS => {
			"::" => 102,
			'IDENTIFIER' => 95
		},
		GOTOS => {
			'value_name' => 618,
			'value_names' => 690,
			'scoped_name' => 616
		}
	},
	{#State 661
		DEFAULT => -59
	},
	{#State 662
		DEFAULT => -318
	},
	{#State 663
		DEFAULT => -316
	},
	{#State 664
		DEFAULT => -311
	},
	{#State 665
		ACTIONS => {
			")" => 691
		}
	},
	{#State 666
		DEFAULT => -332
	},
	{#State 667
		ACTIONS => {
			'STRING_LITERAL' => 188,
			'error' => 693
		},
		GOTOS => {
			'string_literals' => 692,
			'string_literal' => 694
		}
	},
	{#State 668
		DEFAULT => -382
	},
	{#State 669
		DEFAULT => -381
	},
	{#State 670
		ACTIONS => {
			"::" => 102,
			'IDENTIFIER' => 95,
			'error' => 695
		},
		GOTOS => {
			'exception_names' => 696,
			'scoped_name' => 638,
			'exception_name' => 641
		}
	},
	{#State 671
		DEFAULT => -376
	},
	{#State 672
		ACTIONS => {
			"," => 697
		},
		DEFAULT => -371
	},
	{#State 673
		DEFAULT => -377
	},
	{#State 674
		DEFAULT => -384
	},
	{#State 675
		DEFAULT => -383
	},
	{#State 676
		ACTIONS => {
			'IDENTIFIER' => 164,
			'error' => 162
		},
		GOTOS => {
			'simple_declarator' => 672,
			'simple_declarators' => 698
		}
	},
	{#State 677
		DEFAULT => -369
	},
	{#State 678
		DEFAULT => -324
	},
	{#State 679
		DEFAULT => -323
	},
	{#State 680
		ACTIONS => {
			"::" => 102,
			'IDENTIFIER' => 95
		},
		GOTOS => {
			'exception_names' => 699,
			'scoped_name' => 638,
			'exception_name' => 641
		}
	},
	{#State 681
		DEFAULT => -114
	},
	{#State 682
		DEFAULT => -113
	},
	{#State 683
		ACTIONS => {
			"-" => 347,
			"::" => 102,
			'IDENTIFIER' => 95,
			'TRUE' => 353,
			"~" => 362,
			"+" => 354,
			'INTEGER_LITERAL' => 355,
			'FLOATING_PT_LITERAL' => 370,
			"(" => 367,
			'FIXED_PT_LITERAL' => 360,
			'FALSE' => 364,
			'error' => 700,
			'STRING_LITERAL' => 188,
			'WIDE_STRING_LITERAL' => 371,
			'WIDE_CHARACTER_LITERAL' => 368,
			'CHARACTER_LITERAL' => 372
		},
		GOTOS => {
			'and_expr' => 349,
			'or_expr' => 350,
			'shift_expr' => 369,
			'mult_expr' => 357,
			'scoped_name' => 351,
			'boolean_literal' => 358,
			'literal' => 363,
			'add_expr' => 359,
			'unary_expr' => 352,
			'primary_expr' => 361,
			'const_exp' => 701,
			'unary_operator' => 348,
			'xor_expr' => 375,
			'wide_string_literal' => 374,
			'string_literal' => 366
		}
	},
	{#State 684
		ACTIONS => {
			'DEFAULT' => 689,
			'CASE' => 683
		},
		DEFAULT => -253,
		GOTOS => {
			'case_label' => 686,
			'switch_body' => 702,
			'case' => 684,
			'case_labels' => 688
		}
	},
	{#State 685
		ACTIONS => {
			"}" => 703
		}
	},
	{#State 686
		ACTIONS => {
			'CASE' => 683,
			'DEFAULT' => 689
		},
		DEFAULT => -256,
		GOTOS => {
			'case_label' => 686,
			'case_labels' => 704
		}
	},
	{#State 687
		ACTIONS => {
			"}" => 705
		}
	},
	{#State 688
		ACTIONS => {
			"::" => 102,
			'ENUM' => 47,
			'CHAR' => 79,
			'OBJECT' => 105,
			'STRING' => 81,
			'OCTET' => 66,
			'WSTRING' => 109,
			'UNION' => 82,
			'UNSIGNED' => 93,
			'ANY' => 67,
			'FLOAT' => 84,
			'LONG' => 68,
			'SEQUENCE' => 111,
			'DOUBLE' => 86,
			'IDENTIFIER' => 95,
			'SHORT' => 112,
			'BOOLEAN' => 113,
			'STRUCT' => 72,
			'VOID' => 98,
			'FIXED' => 115,
			'VALUEBASE' => 116,
			'WCHAR' => 77
		},
		GOTOS => {
			'union_type' => 90,
			'enum_header' => 29,
			'unsigned_short_int' => 91,
			'struct_type' => 92,
			'union_header' => 31,
			'struct_header' => 2,
			'signed_longlong_int' => 69,
			'any_type' => 94,
			'enum_type' => 70,
			'template_type_spec' => 71,
			'element_spec' => 706,
			'unsigned_long_int' => 96,
			'scoped_name' => 73,
			'string_type' => 97,
			'char_type' => 74,
			'fixed_pt_type' => 100,
			'signed_short_int' => 99,
			'signed_long_int' => 75,
			'wide_char_type' => 76,
			'octet_type' => 101,
			'wide_string_type' => 78,
			'object_type' => 103,
			'type_spec' => 707,
			'integer_type' => 80,
			'unsigned_int' => 106,
			'sequence_type' => 107,
			'unsigned_longlong_int' => 108,
			'constr_type_spec' => 110,
			'floating_pt_type' => 83,
			'value_base_type' => 85,
			'base_type_spec' => 87,
			'signed_int' => 114,
			'simple_type_spec' => 88,
			'boolean_type' => 89
		}
	},
	{#State 689
		ACTIONS => {
			":" => 708,
			'error' => 709
		}
	},
	{#State 690
		DEFAULT => -95
	},
	{#State 691
		DEFAULT => -310
	},
	{#State 692
		ACTIONS => {
			")" => 710
		}
	},
	{#State 693
		ACTIONS => {
			")" => 711
		}
	},
	{#State 694
		ACTIONS => {
			"," => 712
		},
		DEFAULT => -334
	},
	{#State 695
		ACTIONS => {
			")" => 713
		}
	},
	{#State 696
		ACTIONS => {
			")" => 714
		}
	},
	{#State 697
		ACTIONS => {
			'IDENTIFIER' => 164,
			'error' => 162
		},
		GOTOS => {
			'simple_declarator' => 672,
			'simple_declarators' => 715
		}
	},
	{#State 698
		DEFAULT => -370
	},
	{#State 699
		DEFAULT => -328
	},
	{#State 700
		DEFAULT => -260
	},
	{#State 701
		ACTIONS => {
			":" => 716,
			'error' => 717
		}
	},
	{#State 702
		DEFAULT => -254
	},
	{#State 703
		DEFAULT => -242
	},
	{#State 704
		DEFAULT => -257
	},
	{#State 705
		DEFAULT => -241
	},
	{#State 706
		ACTIONS => {
			";" => 125,
			'error' => 123
		},
		GOTOS => {
			'check_semicolon' => 718
		}
	},
	{#State 707
		ACTIONS => {
			'IDENTIFIER' => 226,
			'error' => 162
		},
		GOTOS => {
			'simple_declarator' => 225,
			'array_declarator' => 224,
			'declarator' => 719,
			'complex_declarator' => 228
		}
	},
	{#State 708
		DEFAULT => -261
	},
	{#State 709
		DEFAULT => -262
	},
	{#State 710
		DEFAULT => -330
	},
	{#State 711
		DEFAULT => -331
	},
	{#State 712
		ACTIONS => {
			'STRING_LITERAL' => 188
		},
		GOTOS => {
			'string_literals' => 720,
			'string_literal' => 694
		}
	},
	{#State 713
		DEFAULT => -386
	},
	{#State 714
		DEFAULT => -385
	},
	{#State 715
		DEFAULT => -372
	},
	{#State 716
		DEFAULT => -258
	},
	{#State 717
		DEFAULT => -259
	},
	{#State 718
		DEFAULT => -255
	},
	{#State 719
		DEFAULT => -263
	},
	{#State 720
		DEFAULT => -335
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
#line 86 "Parser30.yp"
{
            $_[0]->YYData->{root} = new CORBA::IDL::Specification($_[0],
                    'list_decl'         =>  $_[1],
            );
        }
	],
	[#Rule 2
		 'specification', 2,
sub
#line 92 "Parser30.yp"
{
            $_[0]->YYData->{root} = new CORBA::IDL::Specification($_[0],
                    'list_import'       =>  $_[1],
                    'list_decl'         =>  $_[2],
            );
        }
	],
	[#Rule 3
		 'specification', 0,
sub
#line 99 "Parser30.yp"
{
            $_[0]->Error("Empty specification.\n");
        }
	],
	[#Rule 4
		 'specification', 1,
sub
#line 103 "Parser30.yp"
{
            $_[0]->Error("definition declaration expected.\n");
        }
	],
	[#Rule 5
		 'imports', 1,
sub
#line 110 "Parser30.yp"
{
            [$_[1]];
        }
	],
	[#Rule 6
		 'imports', 2,
sub
#line 114 "Parser30.yp"
{
            unshift @{$_[2]}, $_[1];
            $_[2];
        }
	],
	[#Rule 7
		 'definitions', 1,
sub
#line 122 "Parser30.yp"
{
            [$_[1]->getRef()];
        }
	],
	[#Rule 8
		 'definitions', 2,
sub
#line 126 "Parser30.yp"
{
            unshift @{$_[2]}, $_[1]->getRef();
            $_[2];
        }
	],
	[#Rule 9
		 'definitions', 3,
sub
#line 131 "Parser30.yp"
{
            $_[0]->Error("import after definition.\n");
            unshift @{$_[3]}, $_[1]->getRef();
            $_[3];
        }
	],
	[#Rule 10
		 'definition', 2, undef
	],
	[#Rule 11
		 'definition', 2, undef
	],
	[#Rule 12
		 'definition', 2, undef
	],
	[#Rule 13
		 'definition', 2, undef
	],
	[#Rule 14
		 'definition', 2, undef
	],
	[#Rule 15
		 'definition', 2, undef
	],
	[#Rule 16
		 'definition', 2, undef
	],
	[#Rule 17
		 'definition', 2, undef
	],
	[#Rule 18
		 'definition', 2, undef
	],
	[#Rule 19
		 'definition', 2, undef
	],
	[#Rule 20
		 'definition', 2, undef
	],
	[#Rule 21
		 'definition', 3,
sub
#line 163 "Parser30.yp"
{
            # when IDENTIFIER is a future keyword
            $_[0]->Error("'$_[1]' unexpected.\n");
            $_[0]->YYErrok();
            new CORBA::IDL::Node($_[0],
                    'idf'                   =>  $_[1]
            );
        }
	],
	[#Rule 22
		 'check_semicolon', 1, undef
	],
	[#Rule 23
		 'check_semicolon', 1,
sub
#line 177 "Parser30.yp"
{
            $_[0]->Warning("';' expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 24
		 'module', 4,
sub
#line 186 "Parser30.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
            $_[1]->Configure($_[0],
                    'list_decl'         =>  $_[3]
            ) if (defined $_[1]);
        }
	],
	[#Rule 25
		 'module', 4,
sub
#line 193 "Parser30.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
            $_[0]->Error("definition declaration expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 26
		 'module', 3,
sub
#line 200 "Parser30.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
            $_[0]->Error("Empty module.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 27
		 'module', 3,
sub
#line 207 "Parser30.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
            $_[0]->Error("'\x7b' expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 28
		 'module_header', 2,
sub
#line 217 "Parser30.yp"
{
            new CORBA::IDL::Module($_[0],
                    'idf'               =>  $_[2],
            );
        }
	],
	[#Rule 29
		 'module_header', 2,
sub
#line 223 "Parser30.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 30
		 'interface', 1, undef
	],
	[#Rule 31
		 'interface', 1, undef
	],
	[#Rule 32
		 'interface_dcl', 3,
sub
#line 240 "Parser30.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->YYData->{curr_itf} = undef;
            $_[1]->Configure($_[0],
                    'list_decl'     =>  []
            ) if (defined $_[1]);
        }
	],
	[#Rule 33
		 'interface_dcl', 4,
sub
#line 248 "Parser30.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->YYData->{curr_itf} = undef;
            $_[1]->Configure($_[0],
                    'list_decl'     =>  $_[3]
            ) if (defined $_[1]);
        }
	],
	[#Rule 34
		 'interface_dcl', 4,
sub
#line 256 "Parser30.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->YYData->{curr_itf} = undef;
            $_[0]->Error("export declaration expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 35
		 'forward_dcl', 3,
sub
#line 268 "Parser30.yp"
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
	[#Rule 36
		 'forward_dcl', 3,
sub
#line 286 "Parser30.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 37
		 'interface_mod', 1, undef
	],
	[#Rule 38
		 'interface_mod', 1, undef
	],
	[#Rule 39
		 'interface_mod', 0, undef
	],
	[#Rule 40
		 'interface_header', 4,
sub
#line 304 "Parser30.yp"
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
	[#Rule 41
		 'interface_header', 3,
sub
#line 325 "Parser30.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 42
		 'interface_body', 1, undef
	],
	[#Rule 43
		 'exports', 1,
sub
#line 339 "Parser30.yp"
{
            [$_[1]->getRef()];
        }
	],
	[#Rule 44
		 'exports', 2,
sub
#line 343 "Parser30.yp"
{
            unshift @{$_[2]}, $_[1]->getRef();
            $_[2];
        }
	],
	[#Rule 45
		 '_export', 1, undef
	],
	[#Rule 46
		 '_export', 1,
sub
#line 354 "Parser30.yp"
{
            $_[0]->Error("state member unexpected.\n");
            $_[1];                      #default action
        }
	],
	[#Rule 47
		 '_export', 1,
sub
#line 359 "Parser30.yp"
{
            $_[0]->Error("initializer unexpected.\n");
            $_[1];                      #default action
        }
	],
	[#Rule 48
		 'export', 2, undef
	],
	[#Rule 49
		 'export', 2, undef
	],
	[#Rule 50
		 'export', 2, undef
	],
	[#Rule 51
		 'export', 2, undef
	],
	[#Rule 52
		 'export', 2, undef
	],
	[#Rule 53
		 'export', 2, undef
	],
	[#Rule 54
		 'export', 2, undef
	],
	[#Rule 55
		 'interface_inheritance_spec', 2,
sub
#line 385 "Parser30.yp"
{
            new CORBA::IDL::InheritanceSpec($_[0],
                    'list_interface'        =>  $_[2]
            );
        }
	],
	[#Rule 56
		 'interface_inheritance_spec', 2,
sub
#line 391 "Parser30.yp"
{
            $_[0]->Error("Interface name expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 57
		 'interface_inheritance_spec', 0, undef
	],
	[#Rule 58
		 'interface_names', 1,
sub
#line 401 "Parser30.yp"
{
            [$_[1]];
        }
	],
	[#Rule 59
		 'interface_names', 3,
sub
#line 405 "Parser30.yp"
{
            unshift @{$_[3]}, $_[1];
            $_[3];
        }
	],
	[#Rule 60
		 'interface_name', 1,
sub
#line 414 "Parser30.yp"
{
                CORBA::IDL::Interface->Lookup($_[0], $_[1]);
        }
	],
	[#Rule 61
		 'scoped_name', 1, undef
	],
	[#Rule 62
		 'scoped_name', 2,
sub
#line 424 "Parser30.yp"
{
            $_[1] . $_[2];
        }
	],
	[#Rule 63
		 'scoped_name', 2,
sub
#line 428 "Parser30.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
            '';
        }
	],
	[#Rule 64
		 'scoped_name', 3,
sub
#line 434 "Parser30.yp"
{
            $_[1] . $_[2] . $_[3];
        }
	],
	[#Rule 65
		 'scoped_name', 3,
sub
#line 438 "Parser30.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 66
		 'value', 1, undef
	],
	[#Rule 67
		 'value', 1, undef
	],
	[#Rule 68
		 'value', 1, undef
	],
	[#Rule 69
		 'value', 1, undef
	],
	[#Rule 70
		 'value_forward_dcl', 3,
sub
#line 460 "Parser30.yp"
{
            $_[0]->Warning("CUSTOM unexpected.\n")
                    if (defined $_[1]);
            new CORBA::IDL::ForwardRegularValue($_[0],
                    'idf'               =>  $_[3]
            );
        }
	],
	[#Rule 71
		 'value_forward_dcl', 3,
sub
#line 468 "Parser30.yp"
{
            new CORBA::IDL::ForwardAbstractValue($_[0],
                    'idf'               =>  $_[3]
            );
        }
	],
	[#Rule 72
		 'value_box_dcl', 2,
sub
#line 478 "Parser30.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->YYData->{curr_itf} = undef;
            $_[1]->Configure($_[0],
                    'type'              =>  $_[2]
            ) if (defined $_[1]);
        }
	],
	[#Rule 73
		 'value_box_header', 3,
sub
#line 489 "Parser30.yp"
{
            $_[0]->Warning("CUSTOM unexpected.\n")
                    if (defined $_[1]);
            new CORBA::IDL::BoxedValue($_[0],
                    'idf'               =>  $_[3],
            );
        }
	],
	[#Rule 74
		 'value_abs_dcl', 3,
sub
#line 501 "Parser30.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->YYData->{curr_itf} = undef;
            $_[1]->Configure($_[0],
                    'list_decl'     =>  []
            ) if (defined $_[1]);
        }
	],
	[#Rule 75
		 'value_abs_dcl', 4,
sub
#line 509 "Parser30.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->YYData->{curr_itf} = undef;
            $_[1]->Configure($_[0],
                    'list_decl'     =>  $_[3]
            ) if (defined $_[1]);
        }
	],
	[#Rule 76
		 'value_abs_dcl', 4,
sub
#line 517 "Parser30.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->YYData->{curr_itf} = undef;
            $_[0]->Error("export declaration expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 77
		 'value_abs_header', 4,
sub
#line 528 "Parser30.yp"
{
            new CORBA::IDL::AbstractValue($_[0],
                    'idf'               =>  $_[3],
                    'inheritance'       =>  $_[4]
            );
        }
	],
	[#Rule 78
		 'value_abs_header', 3,
sub
#line 535 "Parser30.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 79
		 'value_abs_header', 2,
sub
#line 540 "Parser30.yp"
{
            $_[0]->Error("'valuetype' expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 80
		 'value_dcl', 3,
sub
#line 549 "Parser30.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->YYData->{curr_itf} = undef;
            $_[1]->Configure($_[0],
                    'list_decl'     =>  []
            ) if (defined $_[1]);
        }
	],
	[#Rule 81
		 'value_dcl', 4,
sub
#line 557 "Parser30.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->YYData->{curr_itf} = undef;
            $_[1]->Configure($_[0],
                    'list_decl'     =>  $_[3]
            ) if (defined $_[1]);
        }
	],
	[#Rule 82
		 'value_dcl', 4,
sub
#line 565 "Parser30.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->YYData->{curr_itf} = undef;
            $_[0]->Error("value_element expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 83
		 'value_elements', 1,
sub
#line 576 "Parser30.yp"
{
            [$_[1]->getRef()];
        }
	],
	[#Rule 84
		 'value_elements', 2,
sub
#line 580 "Parser30.yp"
{
            unshift @{$_[2]}, $_[1]->getRef();
            $_[2];
        }
	],
	[#Rule 85
		 'value_header', 4,
sub
#line 589 "Parser30.yp"
{
            new CORBA::IDL::RegularValue($_[0],
                    'modifier'          =>  $_[1],
                    'idf'               =>  $_[3],
                    'inheritance'       =>  $_[4]
            );
        }
	],
	[#Rule 86
		 'value_header', 3,
sub
#line 597 "Parser30.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 87
		 'value_mod', 1, undef
	],
	[#Rule 88
		 'value_mod', 0, undef
	],
	[#Rule 89
		 'value_inheritance_spec', 4,
sub
#line 613 "Parser30.yp"
{
            new CORBA::IDL::InheritanceSpec($_[0],
                    'modifier'          =>  $_[2],
                    'list_value'        =>  $_[3],
                    'list_interface'    =>  $_[4]
            );
        }
	],
	[#Rule 90
		 'value_inheritance_spec', 3,
sub
#line 621 "Parser30.yp"
{
            $_[0]->Error("value_name expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 91
		 'value_inheritance_spec', 1,
sub
#line 626 "Parser30.yp"
{
            new CORBA::IDL::InheritanceSpec($_[0],
                    'list_interface'    =>  $_[1]
            );
        }
	],
	[#Rule 92
		 'inheritance_mod', 1, undef
	],
	[#Rule 93
		 'inheritance_mod', 0, undef
	],
	[#Rule 94
		 'value_names', 1,
sub
#line 642 "Parser30.yp"
{
            [$_[1]];
        }
	],
	[#Rule 95
		 'value_names', 3,
sub
#line 646 "Parser30.yp"
{
            unshift @{$_[3]}, $_[1];
            $_[3];
        }
	],
	[#Rule 96
		 'value_name', 1,
sub
#line 655 "Parser30.yp"
{
            CORBA::IDL::Value->Lookup($_[0], $_[1]);
        }
	],
	[#Rule 97
		 'value_element', 1, undef
	],
	[#Rule 98
		 'value_element', 1, undef
	],
	[#Rule 99
		 'value_element', 1, undef
	],
	[#Rule 100
		 'state_member', 4,
sub
#line 673 "Parser30.yp"
{
            new CORBA::IDL::StateMembers($_[0],
                    'modifier'          =>  $_[1],
                    'type'              =>  $_[2],
                    'list_expr'         =>  $_[3]
            );
        }
	],
	[#Rule 101
		 'state_member', 4,
sub
#line 681 "Parser30.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 102
		 'state_member', 3,
sub
#line 686 "Parser30.yp"
{
            $_[0]->Error("type_spec expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 103
		 'state_mod', 1, undef
	],
	[#Rule 104
		 'state_mod', 1, undef
	],
	[#Rule 105
		 'init_dcl', 3,
sub
#line 702 "Parser30.yp"
{
            $_[1]->Configure($_[0],
                    'list_raise'    =>  $_[2]
            ) if (defined $_[1]);
        }
	],
	[#Rule 106
		 'init_header_param', 3,
sub
#line 711 "Parser30.yp"
{
            delete $_[0]->YYData->{unnamed_symbtab}
                    if (exists $_[0]->YYData->{unnamed_symbtab});
            $_[1];                      #default action
        }
	],
	[#Rule 107
		 'init_header_param', 4,
sub
#line 717 "Parser30.yp"
{
            delete $_[0]->YYData->{unnamed_symbtab}
                    if (exists $_[0]->YYData->{unnamed_symbtab});
            $_[1]->Configure($_[0],
                    'list_param'    =>  $_[3]
            ) if (defined $_[1]);
        }
	],
	[#Rule 108
		 'init_header_param', 4,
sub
#line 725 "Parser30.yp"
{
            delete $_[0]->YYData->{unnamed_symbtab}
                    if (exists $_[0]->YYData->{unnamed_symbtab});
            $_[0]->Error("init_param_decls expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 109
		 'init_header_param', 2,
sub
#line 733 "Parser30.yp"
{
            delete $_[0]->YYData->{unnamed_symbtab}
                    if (exists $_[0]->YYData->{unnamed_symbtab});
            $_[0]->Error("'(' expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 110
		 'init_header', 2,
sub
#line 744 "Parser30.yp"
{
            new CORBA::IDL::Initializer($_[0],                      # like Operation
                    'idf'               =>  $_[2]
            );
        }
	],
	[#Rule 111
		 'init_header', 2,
sub
#line 750 "Parser30.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 112
		 'init_param_decls', 1,
sub
#line 759 "Parser30.yp"
{
            [$_[1]];
        }
	],
	[#Rule 113
		 'init_param_decls', 3,
sub
#line 763 "Parser30.yp"
{
            unshift @{$_[3]}, $_[1];
            $_[3];
        }
	],
	[#Rule 114
		 'init_param_decl', 3,
sub
#line 772 "Parser30.yp"
{
            new CORBA::IDL::Parameter($_[0],
                    'attr'              =>  $_[1],
                    'type'              =>  $_[2],
                    'idf'               =>  $_[3]
            );
        }
	],
	[#Rule 115
		 'init_param_decl', 2,
sub
#line 780 "Parser30.yp"
{
            $_[0]->Error("Type expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 116
		 'init_param_attribute', 1, undef
	],
	[#Rule 117
		 'const_dcl', 5,
sub
#line 795 "Parser30.yp"
{
            new CORBA::IDL::Constant($_[0],
                    'type'              =>  $_[2],
                    'idf'               =>  $_[3],
                    'list_expr'         =>  $_[5]
            );
        }
	],
	[#Rule 118
		 'const_dcl', 5,
sub
#line 803 "Parser30.yp"
{
            $_[0]->Error("Expression expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 119
		 'const_dcl', 4,
sub
#line 808 "Parser30.yp"
{
            $_[0]->Error("'=' expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 120
		 'const_dcl', 3,
sub
#line 813 "Parser30.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 121
		 'const_dcl', 2,
sub
#line 818 "Parser30.yp"
{
            $_[0]->Error("const_type expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 122
		 'const_type', 1, undef
	],
	[#Rule 123
		 'const_type', 1, undef
	],
	[#Rule 124
		 'const_type', 1, undef
	],
	[#Rule 125
		 'const_type', 1, undef
	],
	[#Rule 126
		 'const_type', 1, undef
	],
	[#Rule 127
		 'const_type', 1, undef
	],
	[#Rule 128
		 'const_type', 1, undef
	],
	[#Rule 129
		 'const_type', 1, undef
	],
	[#Rule 130
		 'const_type', 1,
sub
#line 843 "Parser30.yp"
{
            CORBA::IDL::TypeDeclarator->Lookup($_[0], $_[1]);
        }
	],
	[#Rule 131
		 'const_type', 1, undef
	],
	[#Rule 132
		 'const_exp', 1, undef
	],
	[#Rule 133
		 'or_expr', 1, undef
	],
	[#Rule 134
		 'or_expr', 3,
sub
#line 861 "Parser30.yp"
{
            BuildBinop($_[1], $_[2], $_[3]);
        }
	],
	[#Rule 135
		 'xor_expr', 1, undef
	],
	[#Rule 136
		 'xor_expr', 3,
sub
#line 871 "Parser30.yp"
{
            BuildBinop($_[1], $_[2], $_[3]);
        }
	],
	[#Rule 137
		 'and_expr', 1, undef
	],
	[#Rule 138
		 'and_expr', 3,
sub
#line 881 "Parser30.yp"
{
            BuildBinop($_[1], $_[2], $_[3]);
        }
	],
	[#Rule 139
		 'shift_expr', 1, undef
	],
	[#Rule 140
		 'shift_expr', 3,
sub
#line 891 "Parser30.yp"
{
            BuildBinop($_[1], $_[2], $_[3]);
        }
	],
	[#Rule 141
		 'shift_expr', 3,
sub
#line 895 "Parser30.yp"
{
            BuildBinop($_[1], $_[2], $_[3]);
        }
	],
	[#Rule 142
		 'add_expr', 1, undef
	],
	[#Rule 143
		 'add_expr', 3,
sub
#line 905 "Parser30.yp"
{
            BuildBinop($_[1], $_[2], $_[3]);
        }
	],
	[#Rule 144
		 'add_expr', 3,
sub
#line 909 "Parser30.yp"
{
            BuildBinop($_[1], $_[2], $_[3]);
        }
	],
	[#Rule 145
		 'mult_expr', 1, undef
	],
	[#Rule 146
		 'mult_expr', 3,
sub
#line 919 "Parser30.yp"
{
            BuildBinop($_[1], $_[2], $_[3]);
        }
	],
	[#Rule 147
		 'mult_expr', 3,
sub
#line 923 "Parser30.yp"
{
            BuildBinop($_[1], $_[2], $_[3]);
        }
	],
	[#Rule 148
		 'mult_expr', 3,
sub
#line 927 "Parser30.yp"
{
            BuildBinop($_[1], $_[2], $_[3]);
        }
	],
	[#Rule 149
		 'unary_expr', 2,
sub
#line 935 "Parser30.yp"
{
            BuildUnop($_[1], $_[2]);
        }
	],
	[#Rule 150
		 'unary_expr', 1, undef
	],
	[#Rule 151
		 'unary_operator', 1, undef
	],
	[#Rule 152
		 'unary_operator', 1, undef
	],
	[#Rule 153
		 'unary_operator', 1, undef
	],
	[#Rule 154
		 'primary_expr', 1,
sub
#line 955 "Parser30.yp"
{
            [
                CORBA::IDL::Constant->Lookup($_[0], $_[1])
            ];
        }
	],
	[#Rule 155
		 'primary_expr', 1,
sub
#line 961 "Parser30.yp"
{
            [ $_[1] ];
        }
	],
	[#Rule 156
		 'primary_expr', 3,
sub
#line 965 "Parser30.yp"
{
            $_[2];
        }
	],
	[#Rule 157
		 'primary_expr', 3,
sub
#line 969 "Parser30.yp"
{
            $_[0]->Error("Expression expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 158
		 'literal', 1,
sub
#line 978 "Parser30.yp"
{
            new CORBA::IDL::IntegerLiteral($_[0],
                    'value'             =>  $_[1],
                    'lexeme'            =>  $_[0]->YYData->{lexeme}
            );
        }
	],
	[#Rule 159
		 'literal', 1,
sub
#line 985 "Parser30.yp"
{
            new CORBA::IDL::StringLiteral($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 160
		 'literal', 1,
sub
#line 991 "Parser30.yp"
{
            new CORBA::IDL::WideStringLiteral($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 161
		 'literal', 1,
sub
#line 997 "Parser30.yp"
{
            new CORBA::IDL::CharacterLiteral($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 162
		 'literal', 1,
sub
#line 1003 "Parser30.yp"
{
            new CORBA::IDL::WideCharacterLiteral($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 163
		 'literal', 1,
sub
#line 1009 "Parser30.yp"
{
            new CORBA::IDL::FixedPtLiteral($_[0],
                    'value'             =>  $_[1],
                    'lexeme'            =>  $_[0]->YYData->{lexeme}
            );
        }
	],
	[#Rule 164
		 'literal', 1,
sub
#line 1016 "Parser30.yp"
{
            new CORBA::IDL::FloatingPtLiteral($_[0],
                    'value'             =>  $_[1],
                    'lexeme'            =>  $_[0]->YYData->{lexeme}
            );
        }
	],
	[#Rule 165
		 'literal', 1, undef
	],
	[#Rule 166
		 'string_literal', 1, undef
	],
	[#Rule 167
		 'string_literal', 2,
sub
#line 1030 "Parser30.yp"
{
            $_[1] . $_[2];
        }
	],
	[#Rule 168
		 'wide_string_literal', 1, undef
	],
	[#Rule 169
		 'wide_string_literal', 2,
sub
#line 1039 "Parser30.yp"
{
            $_[1] . $_[2];
        }
	],
	[#Rule 170
		 'boolean_literal', 1,
sub
#line 1047 "Parser30.yp"
{
            new CORBA::IDL::BooleanLiteral($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 171
		 'boolean_literal', 1,
sub
#line 1053 "Parser30.yp"
{
            new CORBA::IDL::BooleanLiteral($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 172
		 'positive_int_const', 1,
sub
#line 1063 "Parser30.yp"
{
            new CORBA::IDL::Expression($_[0],
                    'list_expr'         =>  $_[1]
            );
        }
	],
	[#Rule 173
		 'type_dcl', 2,
sub
#line 1073 "Parser30.yp"
{
            $_[2];
        }
	],
	[#Rule 174
		 'type_dcl', 1, undef
	],
	[#Rule 175
		 'type_dcl', 1, undef
	],
	[#Rule 176
		 'type_dcl', 1, undef
	],
	[#Rule 177
		 'type_dcl', 2,
sub
#line 1083 "Parser30.yp"
{
            new CORBA::IDL::NativeType($_[0],
                    'idf'               =>  $_[2]
            );
        }
	],
	[#Rule 178
		 'type_dcl', 1, undef
	],
	[#Rule 179
		 'type_dcl', 2,
sub
#line 1091 "Parser30.yp"
{
            $_[0]->Error("type_declarator expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 180
		 'type_declarator', 2,
sub
#line 1100 "Parser30.yp"
{
            new CORBA::IDL::TypeDeclarators($_[0],
                    'type'              =>  $_[1],
                    'list_expr'         =>  $_[2]
            );
        }
	],
	[#Rule 181
		 'type_spec', 1, undef
	],
	[#Rule 182
		 'type_spec', 1, undef
	],
	[#Rule 183
		 'simple_type_spec', 1, undef
	],
	[#Rule 184
		 'simple_type_spec', 1, undef
	],
	[#Rule 185
		 'simple_type_spec', 1,
sub
#line 1123 "Parser30.yp"
{
            CORBA::IDL::TypeDeclarator->Lookup($_[0], $_[1]);
        }
	],
	[#Rule 186
		 'simple_type_spec', 1,
sub
#line 1127 "Parser30.yp"
{
            $_[0]->Error("simple_type_spec expected.\n");
            new CORBA::IDL::VoidType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 187
		 'base_type_spec', 1, undef
	],
	[#Rule 188
		 'base_type_spec', 1, undef
	],
	[#Rule 189
		 'base_type_spec', 1, undef
	],
	[#Rule 190
		 'base_type_spec', 1, undef
	],
	[#Rule 191
		 'base_type_spec', 1, undef
	],
	[#Rule 192
		 'base_type_spec', 1, undef
	],
	[#Rule 193
		 'base_type_spec', 1, undef
	],
	[#Rule 194
		 'base_type_spec', 1, undef
	],
	[#Rule 195
		 'base_type_spec', 1, undef
	],
	[#Rule 196
		 'template_type_spec', 1, undef
	],
	[#Rule 197
		 'template_type_spec', 1, undef
	],
	[#Rule 198
		 'template_type_spec', 1, undef
	],
	[#Rule 199
		 'template_type_spec', 1, undef
	],
	[#Rule 200
		 'constr_type_spec', 1, undef
	],
	[#Rule 201
		 'constr_type_spec', 1, undef
	],
	[#Rule 202
		 'constr_type_spec', 1, undef
	],
	[#Rule 203
		 'declarators', 1,
sub
#line 1182 "Parser30.yp"
{
            [$_[1]];
        }
	],
	[#Rule 204
		 'declarators', 3,
sub
#line 1186 "Parser30.yp"
{
            unshift @{$_[3]}, $_[1];
            $_[3];
        }
	],
	[#Rule 205
		 'declarator', 1,
sub
#line 1195 "Parser30.yp"
{
            [$_[1]];
        }
	],
	[#Rule 206
		 'declarator', 1, undef
	],
	[#Rule 207
		 'simple_declarator', 1, undef
	],
	[#Rule 208
		 'simple_declarator', 2,
sub
#line 1207 "Parser30.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 209
		 'simple_declarator', 2,
sub
#line 1212 "Parser30.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 210
		 'complex_declarator', 1, undef
	],
	[#Rule 211
		 'floating_pt_type', 1,
sub
#line 1227 "Parser30.yp"
{
            new CORBA::IDL::FloatingPtType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 212
		 'floating_pt_type', 1,
sub
#line 1233 "Parser30.yp"
{
            new CORBA::IDL::FloatingPtType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 213
		 'floating_pt_type', 2,
sub
#line 1239 "Parser30.yp"
{
            new CORBA::IDL::FloatingPtType($_[0],
                    'value'             =>  $_[1] . q{ } . $_[2]
            );
        }
	],
	[#Rule 214
		 'integer_type', 1, undef
	],
	[#Rule 215
		 'integer_type', 1, undef
	],
	[#Rule 216
		 'signed_int', 1, undef
	],
	[#Rule 217
		 'signed_int', 1, undef
	],
	[#Rule 218
		 'signed_int', 1, undef
	],
	[#Rule 219
		 'signed_short_int', 1,
sub
#line 1267 "Parser30.yp"
{
            new CORBA::IDL::IntegerType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 220
		 'signed_long_int', 1,
sub
#line 1277 "Parser30.yp"
{
            new CORBA::IDL::IntegerType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 221
		 'signed_longlong_int', 2,
sub
#line 1287 "Parser30.yp"
{
            new CORBA::IDL::IntegerType($_[0],
                    'value'             =>  $_[1] . q{ } . $_[2]
            );
        }
	],
	[#Rule 222
		 'unsigned_int', 1, undef
	],
	[#Rule 223
		 'unsigned_int', 1, undef
	],
	[#Rule 224
		 'unsigned_int', 1, undef
	],
	[#Rule 225
		 'unsigned_short_int', 2,
sub
#line 1307 "Parser30.yp"
{
            new CORBA::IDL::IntegerType($_[0],
                    'value'             =>  $_[1] . q{ } . $_[2]
            );
        }
	],
	[#Rule 226
		 'unsigned_long_int', 2,
sub
#line 1317 "Parser30.yp"
{
            new CORBA::IDL::IntegerType($_[0],
                    'value'             =>  $_[1] . q{ } . $_[2]
            );
        }
	],
	[#Rule 227
		 'unsigned_longlong_int', 3,
sub
#line 1327 "Parser30.yp"
{
            new CORBA::IDL::IntegerType($_[0],
                    'value'             =>  $_[1] . q{ } . $_[2] . q{ } . $_[3]
            );
        }
	],
	[#Rule 228
		 'char_type', 1,
sub
#line 1337 "Parser30.yp"
{
            new CORBA::IDL::CharType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 229
		 'wide_char_type', 1,
sub
#line 1347 "Parser30.yp"
{
            new CORBA::IDL::WideCharType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 230
		 'boolean_type', 1,
sub
#line 1357 "Parser30.yp"
{
            new CORBA::IDL::BooleanType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 231
		 'octet_type', 1,
sub
#line 1367 "Parser30.yp"
{
            new CORBA::IDL::OctetType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 232
		 'any_type', 1,
sub
#line 1377 "Parser30.yp"
{
            new CORBA::IDL::AnyType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 233
		 'object_type', 1,
sub
#line 1387 "Parser30.yp"
{
            new CORBA::IDL::ObjectType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 234
		 'struct_type', 4,
sub
#line 1397 "Parser30.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[1]->Configure($_[0],
                    'list_expr'         =>  $_[3]
            ) if (defined $_[1]);
        }
	],
	[#Rule 235
		 'struct_type', 4,
sub
#line 1404 "Parser30.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->Error("member expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 236
		 'struct_header', 2,
sub
#line 1414 "Parser30.yp"
{
            new CORBA::IDL::StructType($_[0],
                    'idf'               =>  $_[2]
            );
        }
	],
	[#Rule 237
		 'struct_header', 2,
sub
#line 1420 "Parser30.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 238
		 'member_list', 1,
sub
#line 1429 "Parser30.yp"
{
            [$_[1]];
        }
	],
	[#Rule 239
		 'member_list', 2,
sub
#line 1433 "Parser30.yp"
{
            unshift @{$_[2]}, $_[1];
            $_[2];
        }
	],
	[#Rule 240
		 'member', 3,
sub
#line 1442 "Parser30.yp"
{
            new CORBA::IDL::Members($_[0],
                    'type'              =>  $_[1],
                    'list_expr'         =>  $_[2]
            );
        }
	],
	[#Rule 241
		 'union_type', 8,
sub
#line 1453 "Parser30.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[1]->Configure($_[0],
                    'type'              =>  $_[4],
                    'list_expr'         =>  $_[7]
            ) if (defined $_[1]);
        }
	],
	[#Rule 242
		 'union_type', 8,
sub
#line 1461 "Parser30.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->Error("switch_body expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 243
		 'union_type', 6,
sub
#line 1468 "Parser30.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->Error("'\x7b' expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 244
		 'union_type', 5,
sub
#line 1475 "Parser30.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->Error("switch_type_spec expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 245
		 'union_type', 3,
sub
#line 1482 "Parser30.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->Error("'(' expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 246
		 'union_header', 2,
sub
#line 1492 "Parser30.yp"
{
            new CORBA::IDL::UnionType($_[0],
                    'idf'               =>  $_[2],
            );
        }
	],
	[#Rule 247
		 'union_header', 2,
sub
#line 1498 "Parser30.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 248
		 'switch_type_spec', 1, undef
	],
	[#Rule 249
		 'switch_type_spec', 1, undef
	],
	[#Rule 250
		 'switch_type_spec', 1, undef
	],
	[#Rule 251
		 'switch_type_spec', 1, undef
	],
	[#Rule 252
		 'switch_type_spec', 1,
sub
#line 1515 "Parser30.yp"
{
            CORBA::IDL::TypeDeclarator->Lookup($_[0], $_[1]);
        }
	],
	[#Rule 253
		 'switch_body', 1,
sub
#line 1523 "Parser30.yp"
{
            [$_[1]];
        }
	],
	[#Rule 254
		 'switch_body', 2,
sub
#line 1527 "Parser30.yp"
{
            unshift @{$_[2]}, $_[1];
            $_[2];
        }
	],
	[#Rule 255
		 'case', 3,
sub
#line 1536 "Parser30.yp"
{
            new CORBA::IDL::Case($_[0],
                    'list_label'        =>  $_[1],
                    'element'           =>  $_[2]
            );
        }
	],
	[#Rule 256
		 'case_labels', 1,
sub
#line 1546 "Parser30.yp"
{
            [$_[1]];
        }
	],
	[#Rule 257
		 'case_labels', 2,
sub
#line 1550 "Parser30.yp"
{
            unshift @{$_[2]}, $_[1];
            $_[2];
        }
	],
	[#Rule 258
		 'case_label', 3,
sub
#line 1559 "Parser30.yp"
{
            $_[2];                      # here only a expression, type is not known
        }
	],
	[#Rule 259
		 'case_label', 3,
sub
#line 1563 "Parser30.yp"
{
            $_[0]->Error("':' expected.\n");
            $_[0]->YYErrok();
            $_[2];
        }
	],
	[#Rule 260
		 'case_label', 2,
sub
#line 1569 "Parser30.yp"
{
            $_[0]->Error("Expression expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 261
		 'case_label', 2,
sub
#line 1574 "Parser30.yp"
{
            new CORBA::IDL::Default($_[0]);
        }
	],
	[#Rule 262
		 'case_label', 2,
sub
#line 1578 "Parser30.yp"
{
            $_[0]->Error("':' expected.\n");
            $_[0]->YYErrok();
            new CORBA::IDL::Default($_[0]);
        }
	],
	[#Rule 263
		 'element_spec', 2,
sub
#line 1588 "Parser30.yp"
{
            new CORBA::IDL::Element($_[0],
                    'type'          =>  $_[1],
                    'list_expr'     =>  $_[2]
            );
        }
	],
	[#Rule 264
		 'enum_type', 4,
sub
#line 1599 "Parser30.yp"
{
            $_[1]->Configure($_[0],
                    'list_expr'     =>  $_[3]
            ) if (defined $_[1]);
        }
	],
	[#Rule 265
		 'enum_type', 4,
sub
#line 1605 "Parser30.yp"
{
            $_[0]->Error("enumerator expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 266
		 'enum_type', 2,
sub
#line 1611 "Parser30.yp"
{
            $_[0]->Error("'\x7b' expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 267
		 'enum_header', 2,
sub
#line 1620 "Parser30.yp"
{
            new CORBA::IDL::EnumType($_[0],
                    'idf'               =>  $_[2],
            );
        }
	],
	[#Rule 268
		 'enum_header', 2,
sub
#line 1626 "Parser30.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 269
		 'enumerators', 1,
sub
#line 1634 "Parser30.yp"
{
            [$_[1]];
        }
	],
	[#Rule 270
		 'enumerators', 3,
sub
#line 1638 "Parser30.yp"
{
            unshift @{$_[3]}, $_[1];
            $_[3];
        }
	],
	[#Rule 271
		 'enumerators', 2,
sub
#line 1643 "Parser30.yp"
{
            $_[0]->Warning("',' unexpected.\n");
            [$_[1]];
        }
	],
	[#Rule 272
		 'enumerators', 2,
sub
#line 1648 "Parser30.yp"
{
            $_[0]->Error("';' unexpected.\n");
            [$_[1]];
        }
	],
	[#Rule 273
		 'enumerator', 1,
sub
#line 1657 "Parser30.yp"
{
            new CORBA::IDL::Enum($_[0],
                    'idf'               =>  $_[1]
            );
        }
	],
	[#Rule 274
		 'sequence_type', 6,
sub
#line 1667 "Parser30.yp"
{
            new CORBA::IDL::SequenceType($_[0],
                    'value'             =>  $_[1],
                    'type'              =>  $_[3],
                    'max'               =>  $_[5]
            );
        }
	],
	[#Rule 275
		 'sequence_type', 6,
sub
#line 1675 "Parser30.yp"
{
            $_[0]->Error("Expression expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 276
		 'sequence_type', 4,
sub
#line 1680 "Parser30.yp"
{
            new CORBA::IDL::SequenceType($_[0],
                    'value'             =>  $_[1],
                    'type'              =>  $_[3]
            );
        }
	],
	[#Rule 277
		 'sequence_type', 4,
sub
#line 1687 "Parser30.yp"
{
            $_[0]->Error("simple_type_spec expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 278
		 'sequence_type', 2,
sub
#line 1692 "Parser30.yp"
{
            $_[0]->Error("'<' expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 279
		 'string_type', 4,
sub
#line 1701 "Parser30.yp"
{
            new CORBA::IDL::StringType($_[0],
                    'value'             =>  $_[1],
                    'max'               =>  $_[3]
            );
        }
	],
	[#Rule 280
		 'string_type', 1,
sub
#line 1708 "Parser30.yp"
{
            new CORBA::IDL::StringType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 281
		 'string_type', 4,
sub
#line 1714 "Parser30.yp"
{
            $_[0]->Error("Expression expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 282
		 'wide_string_type', 4,
sub
#line 1723 "Parser30.yp"
{
            new CORBA::IDL::WideStringType($_[0],
                    'value'             =>  $_[1],
                    'max'               =>  $_[3]
            );
        }
	],
	[#Rule 283
		 'wide_string_type', 1,
sub
#line 1730 "Parser30.yp"
{
            new CORBA::IDL::WideStringType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 284
		 'wide_string_type', 4,
sub
#line 1736 "Parser30.yp"
{
            $_[0]->Error("Expression expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 285
		 'array_declarator', 2,
sub
#line 1745 "Parser30.yp"
{
            unshift @{$_[2]}, $_[1];
            $_[2];
        }
	],
	[#Rule 286
		 'fixed_array_sizes', 1,
sub
#line 1753 "Parser30.yp"
{
            [$_[1]];
        }
	],
	[#Rule 287
		 'fixed_array_sizes', 2,
sub
#line 1757 "Parser30.yp"
{
            unshift @{$_[2]}, $_[1];
            $_[2];
        }
	],
	[#Rule 288
		 'fixed_array_size', 3,
sub
#line 1766 "Parser30.yp"
{
            $_[2];
        }
	],
	[#Rule 289
		 'fixed_array_size', 3,
sub
#line 1770 "Parser30.yp"
{
            $_[0]->Error("Expression expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 290
		 'attr_dcl', 1, undef
	],
	[#Rule 291
		 'attr_dcl', 1, undef
	],
	[#Rule 292
		 'except_dcl', 3,
sub
#line 1787 "Parser30.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[1];
        }
	],
	[#Rule 293
		 'except_dcl', 4,
sub
#line 1792 "Parser30.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[1]->Configure($_[0],
                    'list_expr'         =>  $_[3]
            ) if (defined $_[1]);
        }
	],
	[#Rule 294
		 'except_dcl', 4,
sub
#line 1799 "Parser30.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->Error("'members expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 295
		 'except_dcl', 2,
sub
#line 1806 "Parser30.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->Error("'\x7b' expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 296
		 'exception_header', 2,
sub
#line 1816 "Parser30.yp"
{
            new CORBA::IDL::Exception($_[0],
                    'idf'               =>  $_[2],
            );
        }
	],
	[#Rule 297
		 'exception_header', 2,
sub
#line 1822 "Parser30.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 298
		 'op_dcl', 4,
sub
#line 1831 "Parser30.yp"
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
	[#Rule 299
		 'op_dcl', 2,
sub
#line 1841 "Parser30.yp"
{
            delete $_[0]->YYData->{unnamed_symbtab}
                    if (exists $_[0]->YYData->{unnamed_symbtab});
            $_[0]->Error("parameters declaration expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 300
		 'op_header', 3,
sub
#line 1852 "Parser30.yp"
{
            new CORBA::IDL::Operation($_[0],
                    'modifier'          =>  $_[1],
                    'type'              =>  $_[2],
                    'idf'               =>  $_[3]
            );
        }
	],
	[#Rule 301
		 'op_header', 3,
sub
#line 1860 "Parser30.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 302
		 'op_mod', 1, undef
	],
	[#Rule 303
		 'op_mod', 0, undef
	],
	[#Rule 304
		 'op_attribute', 1, undef
	],
	[#Rule 305
		 'op_type_spec', 1, undef
	],
	[#Rule 306
		 'op_type_spec', 1,
sub
#line 1884 "Parser30.yp"
{
            new CORBA::IDL::VoidType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 307
		 'op_type_spec', 1,
sub
#line 1890 "Parser30.yp"
{
            $_[0]->Error("op_type_spec expected.\n");
            $_[1];                      #default action
        }
	],
	[#Rule 308
		 'op_type_spec', 1,
sub
#line 1895 "Parser30.yp"
{
            $_[0]->Error("op_type_spec expected.\n");
            $_[1];                      #default action
        }
	],
	[#Rule 309
		 'parameter_dcls', 3,
sub
#line 1904 "Parser30.yp"
{
            $_[2];
        }
	],
	[#Rule 310
		 'parameter_dcls', 5,
sub
#line 1908 "Parser30.yp"
{
            $_[0]->Error("'...' unexpected.\n");
            $_[2];
        }
	],
	[#Rule 311
		 'parameter_dcls', 4,
sub
#line 1913 "Parser30.yp"
{
            $_[0]->Warning("',' unexpected.\n");
            $_[2];
        }
	],
	[#Rule 312
		 'parameter_dcls', 2,
sub
#line 1918 "Parser30.yp"
{
            undef;
        }
	],
	[#Rule 313
		 'parameter_dcls', 3,
sub
#line 1922 "Parser30.yp"
{
            $_[0]->Error("'...' unexpected.\n");
            undef;
        }
	],
	[#Rule 314
		 'parameter_dcls', 3,
sub
#line 1927 "Parser30.yp"
{
            $_[0]->Error("parameters declaration expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 315
		 'param_dcls', 1,
sub
#line 1935 "Parser30.yp"
{
            [$_[1]];
        }
	],
	[#Rule 316
		 'param_dcls', 3,
sub
#line 1939 "Parser30.yp"
{
            push @{$_[1]}, $_[3];
            $_[1];
        }
	],
	[#Rule 317
		 'param_dcls', 2,
sub
#line 1944 "Parser30.yp"
{
            $_[0]->Error("';' unexpected.\n");
            [$_[1]];
        }
	],
	[#Rule 318
		 'param_dcl', 3,
sub
#line 1953 "Parser30.yp"
{
            new CORBA::IDL::Parameter($_[0],
                    'attr'              =>  $_[1],
                    'type'              =>  $_[2],
                    'idf'               =>  $_[3]
            );
        }
	],
	[#Rule 319
		 'param_attribute', 1, undef
	],
	[#Rule 320
		 'param_attribute', 1, undef
	],
	[#Rule 321
		 'param_attribute', 1, undef
	],
	[#Rule 322
		 'param_attribute', 0,
sub
#line 1971 "Parser30.yp"
{
            $_[0]->Error("(in|out|inout) expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 323
		 'raises_expr', 4,
sub
#line 1980 "Parser30.yp"
{
            $_[3];
        }
	],
	[#Rule 324
		 'raises_expr', 4,
sub
#line 1984 "Parser30.yp"
{
            $_[0]->Error("name expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 325
		 'raises_expr', 2,
sub
#line 1989 "Parser30.yp"
{
            $_[0]->Error("'(' expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 326
		 'raises_expr', 0, undef
	],
	[#Rule 327
		 'exception_names', 1,
sub
#line 1999 "Parser30.yp"
{
            [$_[1]];
        }
	],
	[#Rule 328
		 'exception_names', 3,
sub
#line 2003 "Parser30.yp"
{
            unshift @{$_[3]}, $_[1];
            $_[3];
        }
	],
	[#Rule 329
		 'exception_name', 1,
sub
#line 2011 "Parser30.yp"
{
            CORBA::IDL::Exception->Lookup($_[0], $_[1]);
        }
	],
	[#Rule 330
		 'context_expr', 4,
sub
#line 2019 "Parser30.yp"
{
            $_[3];
        }
	],
	[#Rule 331
		 'context_expr', 4,
sub
#line 2023 "Parser30.yp"
{
            $_[0]->Error("string expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 332
		 'context_expr', 2,
sub
#line 2028 "Parser30.yp"
{
            $_[0]->Error("'(' expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 333
		 'context_expr', 0, undef
	],
	[#Rule 334
		 'string_literals', 1,
sub
#line 2038 "Parser30.yp"
{
            [$_[1]];
        }
	],
	[#Rule 335
		 'string_literals', 3,
sub
#line 2042 "Parser30.yp"
{
            unshift @{$_[3]}, $_[1];
            $_[3];
        }
	],
	[#Rule 336
		 'param_type_spec', 1, undef
	],
	[#Rule 337
		 'param_type_spec', 1,
sub
#line 2053 "Parser30.yp"
{
            $_[0]->Error("param_type_spec expected.\n");
            $_[1];                      #default action
        }
	],
	[#Rule 338
		 'param_type_spec', 1,
sub
#line 2058 "Parser30.yp"
{
            $_[0]->Error("param_type_spec expected.\n");
            $_[1];                      #default action
        }
	],
	[#Rule 339
		 'param_type_spec', 1,
sub
#line 2063 "Parser30.yp"
{
            $_[0]->Error("param_type_spec expected.\n");
            $_[1];                      #default action
        }
	],
	[#Rule 340
		 'param_type_spec', 1,
sub
#line 2068 "Parser30.yp"
{
            $_[0]->Error("param_type_spec expected.\n");
            $_[1];                      #default action
        }
	],
	[#Rule 341
		 'op_param_type_spec', 1, undef
	],
	[#Rule 342
		 'op_param_type_spec', 1, undef
	],
	[#Rule 343
		 'op_param_type_spec', 1, undef
	],
	[#Rule 344
		 'op_param_type_spec', 1,
sub
#line 2082 "Parser30.yp"
{
            CORBA::IDL::TypeDeclarator->Lookup($_[0], $_[1]);
        }
	],
	[#Rule 345
		 'fixed_pt_type', 6,
sub
#line 2090 "Parser30.yp"
{
            new CORBA::IDL::FixedPtType($_[0],
                    'value'             =>  $_[1],
                    'd'                 =>  $_[3],
                    's'                 =>  $_[5]
            );
        }
	],
	[#Rule 346
		 'fixed_pt_type', 6,
sub
#line 2098 "Parser30.yp"
{
            $_[0]->Error("Expression expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 347
		 'fixed_pt_type', 4,
sub
#line 2103 "Parser30.yp"
{
            $_[0]->Error("Expression expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 348
		 'fixed_pt_type', 2,
sub
#line 2108 "Parser30.yp"
{
            $_[0]->Error("'<' expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 349
		 'fixed_pt_const_type', 1,
sub
#line 2117 "Parser30.yp"
{
            new CORBA::IDL::FixedPtConstType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 350
		 'value_base_type', 1,
sub
#line 2127 "Parser30.yp"
{
            new CORBA::IDL::ValueBaseType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 351
		 'constr_forward_decl', 2,
sub
#line 2137 "Parser30.yp"
{
            new CORBA::IDL::ForwardStructType($_[0],
                    'idf'               =>  $_[2]
            );
        }
	],
	[#Rule 352
		 'constr_forward_decl', 2,
sub
#line 2143 "Parser30.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 353
		 'constr_forward_decl', 2,
sub
#line 2148 "Parser30.yp"
{
            new CORBA::IDL::ForwardUnionType($_[0],
                    'idf'               =>  $_[2]
            );
        }
	],
	[#Rule 354
		 'constr_forward_decl', 2,
sub
#line 2154 "Parser30.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 355
		 'import', 3,
sub
#line 2163 "Parser30.yp"
{
            new CORBA::IDL::Import($_[0],
                    'value'             =>  $_[2]
            );
        }
	],
	[#Rule 356
		 'import', 2,
sub
#line 2169 "Parser30.yp"
{
            $_[0]->Error("Scoped name expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 357
		 'imported_scope', 1, undef
	],
	[#Rule 358
		 'imported_scope', 1, undef
	],
	[#Rule 359
		 'type_id_dcl', 3,
sub
#line 2186 "Parser30.yp"
{
            new CORBA::IDL::TypeId($_[0],
                    'idf'               =>  $_[2],
                    'value'             =>  $_[3]
            );
        }
	],
	[#Rule 360
		 'type_id_dcl', 3,
sub
#line 2193 "Parser30.yp"
{
            $_[0]->Error("String literal expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 361
		 'type_id_dcl', 2,
sub
#line 2198 "Parser30.yp"
{
            $_[0]->Error("Scoped name expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 362
		 'type_prefix_dcl', 3,
sub
#line 2207 "Parser30.yp"
{
            new CORBA::IDL::TypePrefix($_[0],
                    'idf'               =>  $_[2],
                    'value'             =>  $_[3]
            );
        }
	],
	[#Rule 363
		 'type_prefix_dcl', 3,
sub
#line 2214 "Parser30.yp"
{
            $_[0]->Error("String literal expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 364
		 'type_prefix_dcl', 3,
sub
#line 2219 "Parser30.yp"
{
            new CORBA::IDL::TypePrefix($_[0],
                    'idf'               =>  '',
                    'value'             =>  $_[3]
            );
        }
	],
	[#Rule 365
		 'type_prefix_dcl', 2,
sub
#line 2226 "Parser30.yp"
{
            $_[0]->Error("Scoped name expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 366
		 'readonly_attr_spec', 4,
sub
#line 2235 "Parser30.yp"
{
            new CORBA::IDL::Attributes($_[0],
                    'modifier'          =>  $_[1],
                    'type'              =>  $_[3],
                    'list_expr'         =>  $_[4]->{list_expr},
                    'list_getraise'     =>  $_[4]->{list_getraise},
            );
        }
	],
	[#Rule 367
		 'readonly_attr_spec', 3,
sub
#line 2244 "Parser30.yp"
{
            $_[0]->Error("type expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 368
		 'readonly_attr_spec', 2,
sub
#line 2249 "Parser30.yp"
{
            $_[0]->Error("'attribute' expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 369
		 'readonly_attr_declarator', 2,
sub
#line 2258 "Parser30.yp"
{
            {
                'list_expr'         => [$_[1]],
                'list_getraise'     => $_[2]
            };
        }
	],
	[#Rule 370
		 'readonly_attr_declarator', 3,
sub
#line 2265 "Parser30.yp"
{
            unshift @{$_[3]}, $_[1];
            {
                'list_expr'         => $_[3]
            };
        }
	],
	[#Rule 371
		 'simple_declarators', 1,
sub
#line 2275 "Parser30.yp"
{
            [$_[1]];
        }
	],
	[#Rule 372
		 'simple_declarators', 3,
sub
#line 2279 "Parser30.yp"
{
            unshift @{$_[3]}, $_[1];
            $_[3];
        }
	],
	[#Rule 373
		 'attr_spec', 3,
sub
#line 2288 "Parser30.yp"
{
            new CORBA::IDL::Attributes($_[0],
                    'type'              =>  $_[2],
                    'list_expr'         =>  $_[3]->{list_expr},
                    'list_getraise'     =>  $_[3]->{list_getraise},
                    'list_setraise'     =>  $_[3]->{list_setraise},
            );
        }
	],
	[#Rule 374
		 'attr_spec', 2,
sub
#line 2297 "Parser30.yp"
{
            $_[0]->Error("type expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 375
		 'attr_declarator', 2,
sub
#line 2306 "Parser30.yp"
{
            {
                'list_expr'         => [$_[1]],
                'list_getraise'     => $_[2]->{list_getraise},
                'list_setraise'     => $_[2]->{list_setraise}
            };
        }
	],
	[#Rule 376
		 'attr_declarator', 3,
sub
#line 2314 "Parser30.yp"
{
            unshift @{$_[3]}, $_[1];
            {
                'list_expr'         => $_[3]
            };
        }
	],
	[#Rule 377
		 'attr_raises_expr', 2,
sub
#line 2325 "Parser30.yp"
{
            {
                'list_getraise'     => $_[1],
                'list_setraise'     => $_[2]
            };
        }
	],
	[#Rule 378
		 'attr_raises_expr', 1,
sub
#line 2332 "Parser30.yp"
{
            {
                'list_getraise'     => $_[1],
            };
        }
	],
	[#Rule 379
		 'attr_raises_expr', 1,
sub
#line 2338 "Parser30.yp"
{
            {
                'list_setraise'     => $_[1]
            };
        }
	],
	[#Rule 380
		 'attr_raises_expr', 0, undef
	],
	[#Rule 381
		 'get_except_expr', 2,
sub
#line 2350 "Parser30.yp"
{
            $_[2];
        }
	],
	[#Rule 382
		 'get_except_expr', 2,
sub
#line 2354 "Parser30.yp"
{
            $_[0]->Error("'(' expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 383
		 'set_except_expr', 2,
sub
#line 2363 "Parser30.yp"
{
            $_[2];
        }
	],
	[#Rule 384
		 'set_except_expr', 2,
sub
#line 2367 "Parser30.yp"
{
            $_[0]->Error("'(' expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 385
		 'exception_list', 3,
sub
#line 2376 "Parser30.yp"
{
            $_[2];
        }
	],
	[#Rule 386
		 'exception_list', 3,
sub
#line 2380 "Parser30.yp"
{
            $_[0]->Error("name expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 387
		 'component', 1, undef
	],
	[#Rule 388
		 'component', 1, undef
	],
	[#Rule 389
		 'component_forward_dcl', 2,
sub
#line 2397 "Parser30.yp"
{
            new CORBA::IDL::ForwardComponent($_[0],
                    'idf'               =>  $_[2]
            );
        }
	],
	[#Rule 390
		 'component_forward_dcl', 2,
sub
#line 2403 "Parser30.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 391
		 'component_dcl', 3,
sub
#line 2412 "Parser30.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->YYData->{curr_itf} = undef;
            $_[1]->Configure($_[0],
                    'list_decl'     =>  []
            ) if (defined $_[1]);
        }
	],
	[#Rule 392
		 'component_dcl', 4,
sub
#line 2420 "Parser30.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->YYData->{curr_itf} = undef;
            $_[1]->Configure($_[0],
                    'list_decl'     =>  $_[3]
            ) if (defined $_[1]);
        }
	],
	[#Rule 393
		 'component_dcl', 4,
sub
#line 2428 "Parser30.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->YYData->{curr_itf} = undef;
            $_[0]->Error("export declaration expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 394
		 'component_header', 4,
sub
#line 2440 "Parser30.yp"
{
            new CORBA::IDL::Component($_[0],
                    'idf'                   =>  $_[2],
                    'inheritance'           =>  $_[3],
                    'list_support'          =>  $_[4],
            );
        }
	],
	[#Rule 395
		 'component_header', 2,
sub
#line 2448 "Parser30.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 396
		 'supported_interface_spec', 2,
sub
#line 2457 "Parser30.yp"
{
            $_[2];
        }
	],
	[#Rule 397
		 'supported_interface_spec', 2,
sub
#line 2461 "Parser30.yp"
{
            $_[0]->Error("Interface name expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 398
		 'supported_interface_spec', 0, undef
	],
	[#Rule 399
		 'component_inheritance_spec', 2,
sub
#line 2472 "Parser30.yp"
{
            CORBA::IDL::Component->Lookup($_[0], $_[2]);
        }
	],
	[#Rule 400
		 'component_inheritance_spec', 2,
sub
#line 2476 "Parser30.yp"
{
            $_[0]->Error("Scoped name expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 401
		 'component_inheritance_spec', 0, undef
	],
	[#Rule 402
		 'component_body', 1, undef
	],
	[#Rule 403
		 'component_exports', 1,
sub
#line 2492 "Parser30.yp"
{
            [$_[1]->getRef()];
        }
	],
	[#Rule 404
		 'component_exports', 2,
sub
#line 2496 "Parser30.yp"
{
            unshift @{$_[2]}, $_[1]->getRef();
            $_[2];
        }
	],
	[#Rule 405
		 'component_export', 2, undef
	],
	[#Rule 406
		 'component_export', 2, undef
	],
	[#Rule 407
		 'component_export', 2, undef
	],
	[#Rule 408
		 'component_export', 2, undef
	],
	[#Rule 409
		 'component_export', 2, undef
	],
	[#Rule 410
		 'component_export', 2, undef
	],
	[#Rule 411
		 'provides_dcl', 3,
sub
#line 2521 "Parser30.yp"
{
            new CORBA::IDL::Provides($_[0],
                    'idf'                   =>  $_[3],
                    'type'                  =>  $_[2],
            );
        }
	],
	[#Rule 412
		 'provides_dcl', 3,
sub
#line 2528 "Parser30.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 413
		 'provides_dcl', 2,
sub
#line 2533 "Parser30.yp"
{
            $_[0]->Error("Interface type expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 414
		 'interface_type', 1,
sub
#line 2542 "Parser30.yp"
{
            CORBA::IDL::BaseInterface->Lookup($_[0], $_[1]);
        }
	],
	[#Rule 415
		 'interface_type', 1, undef
	],
	[#Rule 416
		 'uses_dcl', 4,
sub
#line 2552 "Parser30.yp"
{
            new CORBA::IDL::Uses($_[0],
                    'modifier'              =>  $_[2],
                    'idf'                   =>  $_[4],
                    'type'                  =>  $_[3],
            );
        }
	],
	[#Rule 417
		 'uses_dcl', 4,
sub
#line 2560 "Parser30.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 418
		 'uses_dcl', 3,
sub
#line 2565 "Parser30.yp"
{
            $_[0]->Error("Interface type expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 419
		 'uses_mod', 1, undef
	],
	[#Rule 420
		 'uses_mod', 0, undef
	],
	[#Rule 421
		 'emits_dcl', 3,
sub
#line 2581 "Parser30.yp"
{
            new CORBA::IDL::Emits($_[0],
                    'idf'                   =>  $_[3],
                    'type'                  =>  CORBA::IDL::Event->Lookup($_[0], $_[2]),
            );
        }
	],
	[#Rule 422
		 'emits_dcl', 3,
sub
#line 2588 "Parser30.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 423
		 'emits_dcl', 2,
sub
#line 2593 "Parser30.yp"
{
            $_[0]->Error("Scoped name expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 424
		 'publishes_dcl', 3,
sub
#line 2602 "Parser30.yp"
{
            new CORBA::IDL::Publishes($_[0],
                    'idf'                   =>  $_[3],
                    'type'                  =>  CORBA::IDL::Event->Lookup($_[0], $_[2]),
            );
        }
	],
	[#Rule 425
		 'publishes_dcl', 3,
sub
#line 2609 "Parser30.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 426
		 'publishes_dcl', 2,
sub
#line 2614 "Parser30.yp"
{
            $_[0]->Error("Scoped name expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 427
		 'consumes_dcl', 3,
sub
#line 2623 "Parser30.yp"
{
            new CORBA::IDL::Consumes($_[0],
                    'idf'                   =>  $_[3],
                    'type'                  =>  CORBA::IDL::Event->Lookup($_[0], $_[2]),
            );
        }
	],
	[#Rule 428
		 'consumes_dcl', 3,
sub
#line 2630 "Parser30.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 429
		 'consumes_dcl', 2,
sub
#line 2635 "Parser30.yp"
{
            $_[0]->Error("Scoped name expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 430
		 'home_dcl', 2,
sub
#line 2644 "Parser30.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->YYData->{curr_itf} = undef;
            $_[1]->Configure($_[0],
                    'list_decl'         =>  $_[2],
            ) if (defined $_[1]);
        }
	],
	[#Rule 431
		 'home_header', 4,
sub
#line 2656 "Parser30.yp"
{
            $_[1]->Configure($_[0],
                    'manage'            =>  CORBA::IDL::Component->Lookup($_[0], $_[3]),
                    'primarykey'        =>  $_[4],
            ) if (defined $_[1]);
        }
	],
	[#Rule 432
		 'home_header', 3,
sub
#line 2663 "Parser30.yp"
{
            $_[0]->Error("Scoped name expected.\n");
            $_[0]->YYErrok();
            $_[1];                      #default action
        }
	],
	[#Rule 433
		 'home_header_spec', 4,
sub
#line 2672 "Parser30.yp"
{
            new CORBA::IDL::Home($_[0],
                    'idf'               =>  $_[2],
                    'inheritance'       =>  $_[3],
                    'list_support'      =>  $_[4],
            );
        }
	],
	[#Rule 434
		 'home_header_spec', 2,
sub
#line 2680 "Parser30.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 435
		 'home_inheritance_spec', 2,
sub
#line 2689 "Parser30.yp"
{
            CORBA::IDL::Home->Lookup($_[0], $_[2]);
        }
	],
	[#Rule 436
		 'home_inheritance_spec', 2,
sub
#line 2693 "Parser30.yp"
{
            $_[0]->Error("Scoped name expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 437
		 'home_inheritance_spec', 0, undef
	],
	[#Rule 438
		 'primary_key_spec', 2,
sub
#line 2704 "Parser30.yp"
{
            CORBA::IDL::Value->Lookup($_[0], $_[2]);
        }
	],
	[#Rule 439
		 'primary_key_spec', 2,
sub
#line 2708 "Parser30.yp"
{
            $_[0]->Error("Scoped name expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 440
		 'primary_key_spec', 0, undef
	],
	[#Rule 441
		 'home_body', 2,
sub
#line 2719 "Parser30.yp"
{
            [];
        }
	],
	[#Rule 442
		 'home_body', 3,
sub
#line 2723 "Parser30.yp"
{
            $_[2];
        }
	],
	[#Rule 443
		 'home_body', 3,
sub
#line 2727 "Parser30.yp"
{
            $_[0]->Error("export declaration expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 444
		 'home_exports', 1,
sub
#line 2735 "Parser30.yp"
{
            [$_[1]->getRef()];
        }
	],
	[#Rule 445
		 'home_exports', 2,
sub
#line 2739 "Parser30.yp"
{
            unshift @{$_[2]}, $_[1]->getRef();
            $_[2];
        }
	],
	[#Rule 446
		 'home_export', 1, undef
	],
	[#Rule 447
		 'home_export', 2, undef
	],
	[#Rule 448
		 'home_export', 2, undef
	],
	[#Rule 449
		 'factory_dcl', 2,
sub
#line 2758 "Parser30.yp"
{
            $_[1]->Configure($_[0],
                    'list_raise'    =>  $_[2]
            ) if (defined $_[1]);
        }
	],
	[#Rule 450
		 'factory_header_param', 3,
sub
#line 2767 "Parser30.yp"
{
            delete $_[0]->YYData->{unnamed_symbtab}
                    if (exists $_[0]->YYData->{unnamed_symbtab});
            $_[1];                      #default action
        }
	],
	[#Rule 451
		 'factory_header_param', 4,
sub
#line 2773 "Parser30.yp"
{
            delete $_[0]->YYData->{unnamed_symbtab}
                    if (exists $_[0]->YYData->{unnamed_symbtab});
            $_[1]->Configure($_[0],
                    'list_param'        =>  $_[2]
            ) if (defined $_[1]);
        }
	],
	[#Rule 452
		 'factory_header_param', 4,
sub
#line 2781 "Parser30.yp"
{
            delete $_[0]->YYData->{unnamed_symbtab}
                    if (exists $_[0]->YYData->{unnamed_symbtab});
            $_[0]->Error("init_param_decls expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 453
		 'factory_header_param', 2,
sub
#line 2789 "Parser30.yp"
{
            delete $_[0]->YYData->{unnamed_symbtab}
                    if (exists $_[0]->YYData->{unnamed_symbtab});
            $_[0]->Error("'(' expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 454
		 'factory_header', 2,
sub
#line 2800 "Parser30.yp"
{
            new CORBA::IDL::Factory($_[0],                          # like Operation
                    'idf'               =>  $_[2],
            );
        }
	],
	[#Rule 455
		 'factory_header', 2,
sub
#line 2806 "Parser30.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 456
		 'finder_dcl', 2,
sub
#line 2815 "Parser30.yp"
{
            $_[1]->Configure($_[0],
                    'list_raise'    =>  $_[2]
            ) if (defined $_[1]);
        }
	],
	[#Rule 457
		 'finder_header_param', 3,
sub
#line 2824 "Parser30.yp"
{
            delete $_[0]->YYData->{unnamed_symbtab}
                    if (exists $_[0]->YYData->{unnamed_symbtab});
            $_[1];                      #default action
        }
	],
	[#Rule 458
		 'finder_header_param', 4,
sub
#line 2830 "Parser30.yp"
{
            delete $_[0]->YYData->{unnamed_symbtab}
                    if (exists $_[0]->YYData->{unnamed_symbtab});
            $_[1]->Configure($_[0],
                    'list_param'        =>  $_[2]
            ) if (defined $_[1]);
        }
	],
	[#Rule 459
		 'finder_header_param', 4,
sub
#line 2838 "Parser30.yp"
{
            delete $_[0]->YYData->{unnamed_symbtab}
                    if (exists $_[0]->YYData->{unnamed_symbtab});
            $_[0]->Error("init_param_decls expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 460
		 'finder_header_param', 2,
sub
#line 2846 "Parser30.yp"
{
            delete $_[0]->YYData->{unnamed_symbtab}
                    if (exists $_[0]->YYData->{unnamed_symbtab});
            $_[0]->Error("'(' expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 461
		 'finder_header', 2,
sub
#line 2857 "Parser30.yp"
{
            new CORBA::IDL::Finder($_[0],                           # like Operation
                    'idf'               =>  $_[2],
            );
        }
	],
	[#Rule 462
		 'finder_header', 2,
sub
#line 2863 "Parser30.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 463
		 'event', 1, undef
	],
	[#Rule 464
		 'event', 1, undef
	],
	[#Rule 465
		 'event', 1, undef
	],
	[#Rule 466
		 'event_forward_dcl', 3,
sub
#line 2882 "Parser30.yp"
{
            $_[0]->Warning("CUSTOM unexpected.\n")
                    if (defined $_[1]);
            new CORBA::IDL::ForwardRegularEvent($_[0],
                    'idf'               =>  $_[3]
            );
        }
	],
	[#Rule 467
		 'event_forward_dcl', 3,
sub
#line 2890 "Parser30.yp"
{
            new CORBA::IDL::ForwardAbstractEvent($_[0],
                    'idf'               =>  $_[3]
            );
        }
	],
	[#Rule 468
		 'event_abs_dcl', 3,
sub
#line 2900 "Parser30.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->YYData->{curr_itf} = undef;
            $_[1]->Configure($_[0],
                    'list_decl'     =>  []
            ) if (defined $_[1]);
        }
	],
	[#Rule 469
		 'event_abs_dcl', 4,
sub
#line 2908 "Parser30.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->YYData->{curr_itf} = undef;
            $_[1]->Configure($_[0],
                    'list_decl'     =>  $_[3]
            ) if (defined $_[1]);
        }
	],
	[#Rule 470
		 'event_abs_dcl', 4,
sub
#line 2916 "Parser30.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->YYData->{curr_itf} = undef;
            $_[0]->Error("export expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 471
		 'event_abs_header', 4,
sub
#line 2927 "Parser30.yp"
{
            new CORBA::IDL::AbstractEvent($_[0],
                    'idf'               =>  $_[3],
                    'inheritance'       =>  $_[4]
            );
        }
	],
	[#Rule 472
		 'event_abs_header', 3,
sub
#line 2934 "Parser30.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 473
		 'event_dcl', 3,
sub
#line 2943 "Parser30.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->YYData->{curr_itf} = undef;
            $_[1]->Configure($_[0],
                    'list_decl'     =>  []
            ) if (defined $_[1]);
        }
	],
	[#Rule 474
		 'event_dcl', 4,
sub
#line 2951 "Parser30.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->YYData->{curr_itf} = undef;
            $_[1]->Configure($_[0],
                    'list_decl'     =>  $_[3]
            ) if (defined $_[1]);
        }
	],
	[#Rule 475
		 'event_dcl', 4,
sub
#line 2959 "Parser30.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->YYData->{curr_itf} = undef;
            $_[0]->Error("value_element expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 476
		 'event_header', 4,
sub
#line 2971 "Parser30.yp"
{
            new CORBA::IDL::RegularEvent($_[0],
                    'modifier'          =>  $_[1],
                    'idf'               =>  $_[3],
                    'inheritance'       =>  $_[4]
            );
        }
	],
	[#Rule 477
		 'event_header', 3,
sub
#line 2979 "Parser30.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	]
],
                                  @_);
    bless($self,$class);
}

#line 2985 "Parser30.yp"


use warnings;

our $VERSION = '2.61';
our $IDL_VERSION = '3.0';

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
