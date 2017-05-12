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
			'ENUM' => -394,
			'INTERFACE' => -394,
			'VALUETYPE' => -394,
			'CUSTOM' => -394,
			'IMPORT' => 21,
			'UNION' => -394,
			'NATIVE' => -394,
			'CODE_FRAGMENT' => -394,
			'TYPEDEF' => -394,
			'EXCEPTION' => -394,
			'error' => 23,
			"[" => -394,
			'LOCAL' => -394,
			'IDENTIFIER' => 12,
			'TYPEID' => 25,
			'MODULE' => -394,
			'STRUCT' => -394,
			'CONST' => -394,
			'ABSTRACT' => -394,
			'DECLSPEC' => 29,
			'TYPEPREFIX' => 31
		},
		GOTOS => {
			'value_dcl' => 1,
			'code_frag' => 2,
			'value_box_dcl' => 3,
			'definitions' => 18,
			'module_header' => 20,
			'definition' => 19,
			'value_box_header' => 4,
			'specification' => 22,
			'declspec' => 5,
			'except_dcl' => 6,
			'value_header' => 7,
			'interface' => 8,
			'type_dcl' => 9,
			'module' => 24,
			'interface_header' => 11,
			'value_forward_dcl' => 10,
			'imports' => 26,
			'value' => 13,
			'value_abs_dcl' => 27,
			'import' => 28,
			'value_abs_header' => 14,
			'forward_dcl' => 30,
			'exception_header' => 15,
			'const_dcl' => 16,
			'type_prefix_dcl' => 32,
			'interface_dcl' => 17,
			'type_id_dcl' => 33
		}
	},
	{#State 1
		DEFAULT => -65
	},
	{#State 2
		DEFAULT => -18
	},
	{#State 3
		DEFAULT => -67
	},
	{#State 4
		ACTIONS => {
			"::" => 63,
			'CHAR' => 64,
			'OBJECT' => 68,
			'STRING' => 71,
			'OCTET' => 37,
			'WSTRING' => 73,
			'UNSIGNED' => 41,
			"[" => 42,
			'ANY' => 43,
			'FLOAT' => 76,
			'LONG' => 44,
			'SEQUENCE' => 78,
			'DOUBLE' => 79,
			'IDENTIFIER' => 49,
			'SHORT' => 80,
			'BOOLEAN' => 82,
			'VOID' => 55,
			'FIXED' => 85,
			'VALUEBASE' => 87,
			'WCHAR' => 60
		},
		DEFAULT => -396,
		GOTOS => {
			'union_type' => 34,
			'enum_header' => 35,
			'unsigned_short_int' => 36,
			'struct_type' => 38,
			'union_header' => 39,
			'struct_header' => 40,
			'signed_longlong_int' => 45,
			'enum_type' => 46,
			'any_type' => 47,
			'template_type_spec' => 48,
			'unsigned_long_int' => 50,
			'scoped_name' => 51,
			'string_type' => 52,
			'props' => 53,
			'char_type' => 54,
			'fixed_pt_type' => 58,
			'signed_short_int' => 57,
			'signed_long_int' => 56,
			'wide_char_type' => 59,
			'octet_type' => 61,
			'wide_string_type' => 62,
			'object_type' => 65,
			'type_spec' => 66,
			'integer_type' => 67,
			'unsigned_int' => 69,
			'sequence_type' => 70,
			'unsigned_longlong_int' => 72,
			'constr_type_spec' => 74,
			'floating_pt_type' => 75,
			'value_base_type' => 77,
			'base_type_spec' => 81,
			'signed_int' => 83,
			'simple_type_spec' => 84,
			'boolean_type' => 86
		}
	},
	{#State 5
		ACTIONS => {
			'MODULE' => 96,
			'CONST' => 97,
			'CODE_FRAGMENT' => 90,
			'EXCEPTION' => 91,
			"[" => 42
		},
		DEFAULT => -396,
		GOTOS => {
			'union_type' => 88,
			'enum_type' => 92,
			'enum_header' => 35,
			'type_dcl_def' => 93,
			'struct_type' => 89,
			'union_header' => 39,
			'props' => 94,
			'struct_header' => 40,
			'constr_forward_decl' => 95
		}
	},
	{#State 6
		ACTIONS => {
			";" => 99,
			'error' => 100
		},
		GOTOS => {
			'check_semicolon' => 98
		}
	},
	{#State 7
		ACTIONS => {
			"{" => 101
		}
	},
	{#State 8
		ACTIONS => {
			";" => 99,
			'error' => 100
		},
		GOTOS => {
			'check_semicolon' => 102
		}
	},
	{#State 9
		ACTIONS => {
			";" => 99,
			'error' => 100
		},
		GOTOS => {
			'check_semicolon' => 103
		}
	},
	{#State 10
		DEFAULT => -68
	},
	{#State 11
		ACTIONS => {
			"{" => 104
		}
	},
	{#State 12
		ACTIONS => {
			'error' => 105
		}
	},
	{#State 13
		ACTIONS => {
			";" => 99,
			'error' => 100
		},
		GOTOS => {
			'check_semicolon' => 106
		}
	},
	{#State 14
		ACTIONS => {
			"{" => 107
		}
	},
	{#State 15
		ACTIONS => {
			"{" => 109,
			'error' => 108
		}
	},
	{#State 16
		ACTIONS => {
			";" => 99,
			'error' => 100
		},
		GOTOS => {
			'check_semicolon' => 110
		}
	},
	{#State 17
		DEFAULT => -28
	},
	{#State 18
		DEFAULT => -1
	},
	{#State 19
		ACTIONS => {
			'' => -7,
			"}" => -7,
			'IMPORT' => 21,
			'IDENTIFIER' => 12,
			'TYPEID' => 25,
			'DECLSPEC' => 29,
			'TYPEPREFIX' => 31
		},
		DEFAULT => -394,
		GOTOS => {
			'value_dcl' => 1,
			'code_frag' => 2,
			'value_box_dcl' => 3,
			'definitions' => 111,
			'definition' => 19,
			'module_header' => 20,
			'value_box_header' => 4,
			'declspec' => 5,
			'except_dcl' => 6,
			'value_header' => 7,
			'interface' => 8,
			'type_dcl' => 9,
			'module' => 24,
			'interface_header' => 11,
			'value_forward_dcl' => 10,
			'imports' => 112,
			'value' => 13,
			'value_abs_dcl' => 27,
			'import' => 28,
			'value_abs_header' => 14,
			'forward_dcl' => 30,
			'exception_header' => 15,
			'const_dcl' => 16,
			'type_prefix_dcl' => 32,
			'interface_dcl' => 17,
			'type_id_dcl' => 33
		}
	},
	{#State 20
		ACTIONS => {
			"{" => 114,
			'error' => 113
		}
	},
	{#State 21
		ACTIONS => {
			"::" => 63,
			'IDENTIFIER' => 49,
			'STRING_LITERAL' => 119,
			'error' => 118
		},
		GOTOS => {
			'imported_scope' => 117,
			'scoped_name' => 116,
			'string_literal' => 115
		}
	},
	{#State 22
		ACTIONS => {
			'' => 120
		}
	},
	{#State 23
		DEFAULT => -4
	},
	{#State 24
		ACTIONS => {
			";" => 99,
			'error' => 100
		},
		GOTOS => {
			'check_semicolon' => 121
		}
	},
	{#State 25
		ACTIONS => {
			"::" => 63,
			'IDENTIFIER' => 49,
			'error' => 123
		},
		GOTOS => {
			'scoped_name' => 122
		}
	},
	{#State 26
		ACTIONS => {
			'IDENTIFIER' => 12,
			'TYPEID' => 25,
			'DECLSPEC' => 29,
			'TYPEPREFIX' => 31
		},
		DEFAULT => -394,
		GOTOS => {
			'value_dcl' => 1,
			'code_frag' => 2,
			'value_box_dcl' => 3,
			'definitions' => 124,
			'definition' => 19,
			'module_header' => 20,
			'value_box_header' => 4,
			'declspec' => 5,
			'except_dcl' => 6,
			'value_header' => 7,
			'interface' => 8,
			'type_dcl' => 9,
			'module' => 24,
			'interface_header' => 11,
			'value_forward_dcl' => 10,
			'value' => 13,
			'value_abs_dcl' => 27,
			'value_abs_header' => 14,
			'forward_dcl' => 30,
			'exception_header' => 15,
			'const_dcl' => 16,
			'type_prefix_dcl' => 32,
			'interface_dcl' => 17,
			'type_id_dcl' => 33
		}
	},
	{#State 27
		DEFAULT => -66
	},
	{#State 28
		ACTIONS => {
			'IMPORT' => 21
		},
		DEFAULT => -5,
		GOTOS => {
			'imports' => 125,
			'import' => 28
		}
	},
	{#State 29
		DEFAULT => -395
	},
	{#State 30
		DEFAULT => -29
	},
	{#State 31
		ACTIONS => {
			"::" => 127,
			'IDENTIFIER' => 49,
			'error' => 128
		},
		GOTOS => {
			'scoped_name' => 126
		}
	},
	{#State 32
		ACTIONS => {
			";" => 99,
			'error' => 100
		},
		GOTOS => {
			'check_semicolon' => 129
		}
	},
	{#State 33
		ACTIONS => {
			";" => 99,
			'error' => 100
		},
		GOTOS => {
			'check_semicolon' => 130
		}
	},
	{#State 34
		DEFAULT => -206
	},
	{#State 35
		ACTIONS => {
			"{" => 132,
			'error' => 131
		}
	},
	{#State 36
		DEFAULT => -227
	},
	{#State 37
		DEFAULT => -236
	},
	{#State 38
		DEFAULT => -205
	},
	{#State 39
		ACTIONS => {
			'SWITCH' => 133
		}
	},
	{#State 40
		ACTIONS => {
			"{" => 134
		}
	},
	{#State 41
		ACTIONS => {
			'SHORT' => 136,
			'LONG' => 135
		}
	},
	{#State 42
		DEFAULT => -397,
		GOTOS => {
			'@2-1' => 137
		}
	},
	{#State 43
		DEFAULT => -237
	},
	{#State 44
		ACTIONS => {
			'DOUBLE' => 139,
			'LONG' => 138
		},
		DEFAULT => -225
	},
	{#State 45
		DEFAULT => -223
	},
	{#State 46
		DEFAULT => -207
	},
	{#State 47
		DEFAULT => -198
	},
	{#State 48
		DEFAULT => -189
	},
	{#State 49
		DEFAULT => -60
	},
	{#State 50
		DEFAULT => -228
	},
	{#State 51
		ACTIONS => {
			"::" => 140
		},
		DEFAULT => -190
	},
	{#State 52
		DEFAULT => -202
	},
	{#State 53
		ACTIONS => {
			'UNION' => 143,
			'ENUM' => 142,
			'STRUCT' => 141
		}
	},
	{#State 54
		DEFAULT => -194
	},
	{#State 55
		DEFAULT => -191
	},
	{#State 56
		DEFAULT => -222
	},
	{#State 57
		DEFAULT => -221
	},
	{#State 58
		DEFAULT => -204
	},
	{#State 59
		DEFAULT => -195
	},
	{#State 60
		DEFAULT => -234
	},
	{#State 61
		DEFAULT => -197
	},
	{#State 62
		DEFAULT => -203
	},
	{#State 63
		ACTIONS => {
			'IDENTIFIER' => 144,
			'error' => 145
		}
	},
	{#State 64
		DEFAULT => -233
	},
	{#State 65
		DEFAULT => -199
	},
	{#State 66
		DEFAULT => -71
	},
	{#State 67
		DEFAULT => -193
	},
	{#State 68
		DEFAULT => -238
	},
	{#State 69
		DEFAULT => -220
	},
	{#State 70
		DEFAULT => -201
	},
	{#State 71
		ACTIONS => {
			"<" => 146
		},
		DEFAULT => -287
	},
	{#State 72
		DEFAULT => -229
	},
	{#State 73
		ACTIONS => {
			"<" => 147
		},
		DEFAULT => -290
	},
	{#State 74
		DEFAULT => -187
	},
	{#State 75
		DEFAULT => -192
	},
	{#State 76
		DEFAULT => -216
	},
	{#State 77
		DEFAULT => -200
	},
	{#State 78
		ACTIONS => {
			"<" => 148,
			'error' => 149
		}
	},
	{#State 79
		DEFAULT => -217
	},
	{#State 80
		DEFAULT => -224
	},
	{#State 81
		DEFAULT => -188
	},
	{#State 82
		DEFAULT => -235
	},
	{#State 83
		DEFAULT => -219
	},
	{#State 84
		DEFAULT => -186
	},
	{#State 85
		ACTIONS => {
			"<" => 150,
			'error' => 151
		}
	},
	{#State 86
		DEFAULT => -196
	},
	{#State 87
		DEFAULT => -356
	},
	{#State 88
		DEFAULT => -178
	},
	{#State 89
		DEFAULT => -177
	},
	{#State 90
		DEFAULT => -393
	},
	{#State 91
		ACTIONS => {
			'IDENTIFIER' => 152,
			'error' => 153
		}
	},
	{#State 92
		DEFAULT => -179
	},
	{#State 93
		DEFAULT => -175
	},
	{#State 94
		ACTIONS => {
			'ENUM' => 142,
			'VALUETYPE' => -87,
			'CUSTOM' => 154,
			'STRUCT' => 159,
			'ABSTRACT' => 160,
			'UNION' => 161,
			'NATIVE' => 155,
			'TYPEDEF' => 156,
			'LOCAL' => 162
		},
		DEFAULT => -37,
		GOTOS => {
			'value_mod' => 158,
			'interface_mod' => 157
		}
	},
	{#State 95
		DEFAULT => -183
	},
	{#State 96
		ACTIONS => {
			'IDENTIFIER' => 163,
			'error' => 164
		}
	},
	{#State 97
		ACTIONS => {
			'DOUBLE' => 79,
			"::" => 63,
			'IDENTIFIER' => 49,
			'SHORT' => 80,
			'CHAR' => 64,
			'BOOLEAN' => 82,
			'STRING' => 71,
			'OCTET' => 37,
			'WSTRING' => 73,
			'UNSIGNED' => 41,
			'FIXED' => 176,
			'error' => 173,
			'FLOAT' => 76,
			'LONG' => 44,
			'WCHAR' => 60
		},
		GOTOS => {
			'wide_string_type' => 170,
			'integer_type' => 171,
			'unsigned_int' => 69,
			'unsigned_short_int' => 36,
			'unsigned_longlong_int' => 72,
			'floating_pt_type' => 172,
			'const_type' => 174,
			'signed_longlong_int' => 45,
			'unsigned_long_int' => 50,
			'scoped_name' => 165,
			'string_type' => 166,
			'signed_int' => 83,
			'fixed_pt_const_type' => 175,
			'char_type' => 167,
			'signed_short_int' => 57,
			'signed_long_int' => 56,
			'boolean_type' => 177,
			'wide_char_type' => 168,
			'octet_type' => 169
		}
	},
	{#State 98
		DEFAULT => -12
	},
	{#State 99
		DEFAULT => -20
	},
	{#State 100
		DEFAULT => -21
	},
	{#State 101
		ACTIONS => {
			"}" => 178,
			'OCTET' => -394,
			'NATIVE' => -394,
			'UNSIGNED' => -394,
			'CODE_FRAGMENT' => -394,
			'TYPEDEF' => -394,
			'EXCEPTION' => -394,
			"[" => -394,
			'ANY' => -394,
			'LONG' => -394,
			'IDENTIFIER' => -394,
			'STRUCT' => -394,
			'VOID' => -394,
			'WCHAR' => -394,
			'FACTORY' => -394,
			'ENUM' => -394,
			"::" => -394,
			'PRIVATE' => -394,
			'CHAR' => -394,
			'OBJECT' => -394,
			'ONEWAY' => -394,
			'STRING' => -394,
			'WSTRING' => -394,
			'UNION' => -394,
			'error' => 193,
			'FLOAT' => -394,
			'ATTRIBUTE' => -394,
			'PUBLIC' => -394,
			'SEQUENCE' => -394,
			'DOUBLE' => -394,
			'SHORT' => -394,
			'TYPEID' => 25,
			'BOOLEAN' => -394,
			'CONST' => -394,
			'READONLY' => -394,
			'DECLSPEC' => 29,
			'FIXED' => -394,
			'TYPEPREFIX' => 31,
			'VALUEBASE' => -394
		},
		GOTOS => {
			'op_header' => 188,
			'init_header_param' => 189,
			'code_frag' => 179,
			'readonly_attr_spec' => 180,
			'init_header' => 190,
			'op_dcl' => 191,
			'attr_dcl' => 192,
			'declspec' => 181,
			'except_dcl' => 182,
			'state_member' => 194,
			'export' => 183,
			'type_dcl' => 184,
			'value_elements' => 195,
			'value_element' => 185,
			'exception_header' => 15,
			'attr_spec' => 186,
			'const_dcl' => 187,
			'type_prefix_dcl' => 196,
			'type_id_dcl' => 198,
			'init_dcl' => 197
		}
	},
	{#State 102
		DEFAULT => -13
	},
	{#State 103
		DEFAULT => -10
	},
	{#State 104
		ACTIONS => {
			"}" => 199,
			'OCTET' => -394,
			'NATIVE' => -394,
			'UNSIGNED' => -394,
			'CODE_FRAGMENT' => -394,
			'TYPEDEF' => -394,
			'EXCEPTION' => -394,
			"[" => -394,
			'ANY' => -394,
			'LONG' => -394,
			'IDENTIFIER' => -394,
			'STRUCT' => -394,
			'VOID' => -394,
			'WCHAR' => -394,
			'FACTORY' => -394,
			'ENUM' => -394,
			"::" => -394,
			'PRIVATE' => -394,
			'CHAR' => -394,
			'OBJECT' => -394,
			'ONEWAY' => -394,
			'STRING' => -394,
			'WSTRING' => -394,
			'UNION' => -394,
			'error' => 204,
			'FLOAT' => -394,
			'ATTRIBUTE' => -394,
			'PUBLIC' => -394,
			'SEQUENCE' => -394,
			'DOUBLE' => -394,
			'SHORT' => -394,
			'TYPEID' => 25,
			'BOOLEAN' => -394,
			'CONST' => -394,
			'READONLY' => -394,
			'DECLSPEC' => 29,
			'FIXED' => -394,
			'TYPEPREFIX' => 31,
			'VALUEBASE' => -394
		},
		GOTOS => {
			'op_header' => 188,
			'interface_body' => 202,
			'init_header_param' => 189,
			'code_frag' => 179,
			'readonly_attr_spec' => 180,
			'init_header' => 190,
			'op_dcl' => 191,
			'exports' => 203,
			'attr_dcl' => 192,
			'declspec' => 181,
			'except_dcl' => 182,
			'state_member' => 205,
			'type_dcl' => 184,
			'export' => 200,
			'_export' => 201,
			'exception_header' => 15,
			'attr_spec' => 186,
			'const_dcl' => 187,
			'type_prefix_dcl' => 196,
			'init_dcl' => 206,
			'type_id_dcl' => 198
		}
	},
	{#State 105
		ACTIONS => {
			";" => 207
		}
	},
	{#State 106
		DEFAULT => -15
	},
	{#State 107
		ACTIONS => {
			"}" => 208,
			'OCTET' => -394,
			'NATIVE' => -394,
			'UNSIGNED' => -394,
			'CODE_FRAGMENT' => -394,
			'TYPEDEF' => -394,
			'EXCEPTION' => -394,
			"[" => -394,
			'ANY' => -394,
			'LONG' => -394,
			'IDENTIFIER' => -394,
			'STRUCT' => -394,
			'VOID' => -394,
			'WCHAR' => -394,
			'FACTORY' => -394,
			'ENUM' => -394,
			"::" => -394,
			'PRIVATE' => -394,
			'CHAR' => -394,
			'OBJECT' => -394,
			'ONEWAY' => -394,
			'STRING' => -394,
			'WSTRING' => -394,
			'UNION' => -394,
			'error' => 210,
			'FLOAT' => -394,
			'ATTRIBUTE' => -394,
			'PUBLIC' => -394,
			'SEQUENCE' => -394,
			'DOUBLE' => -394,
			'SHORT' => -394,
			'TYPEID' => 25,
			'BOOLEAN' => -394,
			'CONST' => -394,
			'READONLY' => -394,
			'DECLSPEC' => 29,
			'FIXED' => -394,
			'TYPEPREFIX' => 31,
			'VALUEBASE' => -394
		},
		GOTOS => {
			'op_header' => 188,
			'init_header_param' => 189,
			'code_frag' => 179,
			'readonly_attr_spec' => 180,
			'init_header' => 190,
			'op_dcl' => 191,
			'exports' => 209,
			'attr_dcl' => 192,
			'declspec' => 181,
			'except_dcl' => 182,
			'state_member' => 205,
			'type_dcl' => 184,
			'export' => 200,
			'_export' => 201,
			'exception_header' => 15,
			'attr_spec' => 186,
			'const_dcl' => 187,
			'type_prefix_dcl' => 196,
			'init_dcl' => 206,
			'type_id_dcl' => 198
		}
	},
	{#State 108
		DEFAULT => -302
	},
	{#State 109
		ACTIONS => {
			"}" => 211,
			"::" => -396,
			'ENUM' => -396,
			'CHAR' => -396,
			'OBJECT' => -396,
			'STRING' => -396,
			'OCTET' => -396,
			'WSTRING' => -396,
			'UNION' => -396,
			'UNSIGNED' => -396,
			'error' => 216,
			"[" => 42,
			'ANY' => -396,
			'FLOAT' => -396,
			'LONG' => -396,
			'SEQUENCE' => -396,
			'DOUBLE' => -396,
			'IDENTIFIER' => -396,
			'SHORT' => -396,
			'BOOLEAN' => -396,
			'STRUCT' => -396,
			'VOID' => -396,
			'FIXED' => -396,
			'VALUEBASE' => -396,
			'WCHAR' => -396
		},
		GOTOS => {
			'union_type' => 34,
			'enum_type' => 46,
			'member' => 213,
			'enum_header' => 35,
			'struct_type' => 38,
			'union_header' => 39,
			'constr_type_spec' => 215,
			'props' => 214,
			'struct_header' => 40,
			'member_list' => 212
		}
	},
	{#State 110
		DEFAULT => -11
	},
	{#State 111
		DEFAULT => -8
	},
	{#State 112
		ACTIONS => {
			'IDENTIFIER' => 12,
			'TYPEID' => 25,
			'DECLSPEC' => 29,
			'TYPEPREFIX' => 31
		},
		DEFAULT => -394,
		GOTOS => {
			'value_dcl' => 1,
			'code_frag' => 2,
			'value_box_dcl' => 3,
			'definitions' => 217,
			'definition' => 19,
			'module_header' => 20,
			'value_box_header' => 4,
			'declspec' => 5,
			'except_dcl' => 6,
			'value_header' => 7,
			'interface' => 8,
			'type_dcl' => 9,
			'module' => 24,
			'interface_header' => 11,
			'value_forward_dcl' => 10,
			'value' => 13,
			'value_abs_dcl' => 27,
			'value_abs_header' => 14,
			'forward_dcl' => 30,
			'exception_header' => 15,
			'const_dcl' => 16,
			'type_prefix_dcl' => 32,
			'interface_dcl' => 17,
			'type_id_dcl' => 33
		}
	},
	{#State 113
		ACTIONS => {
			"}" => 218
		}
	},
	{#State 114
		ACTIONS => {
			"}" => 219,
			'ENUM' => -394,
			'INTERFACE' => -394,
			'VALUETYPE' => -394,
			'CUSTOM' => -394,
			'UNION' => -394,
			'NATIVE' => -394,
			'CODE_FRAGMENT' => -394,
			'TYPEDEF' => -394,
			'EXCEPTION' => -394,
			'error' => 221,
			"[" => -394,
			'LOCAL' => -394,
			'IDENTIFIER' => 12,
			'TYPEID' => 25,
			'MODULE' => -394,
			'STRUCT' => -394,
			'CONST' => -394,
			'ABSTRACT' => -394,
			'DECLSPEC' => 29,
			'TYPEPREFIX' => 31
		},
		GOTOS => {
			'value_dcl' => 1,
			'code_frag' => 2,
			'value_box_dcl' => 3,
			'definitions' => 220,
			'definition' => 19,
			'module_header' => 20,
			'value_box_header' => 4,
			'declspec' => 5,
			'except_dcl' => 6,
			'value_header' => 7,
			'interface' => 8,
			'type_dcl' => 9,
			'module' => 24,
			'interface_header' => 11,
			'value_forward_dcl' => 10,
			'value' => 13,
			'value_abs_dcl' => 27,
			'value_abs_header' => 14,
			'forward_dcl' => 30,
			'exception_header' => 15,
			'const_dcl' => 16,
			'type_prefix_dcl' => 32,
			'interface_dcl' => 17,
			'type_id_dcl' => 33
		}
	},
	{#State 115
		DEFAULT => -364
	},
	{#State 116
		ACTIONS => {
			"::" => 140
		},
		DEFAULT => -363
	},
	{#State 117
		ACTIONS => {
			";" => 99,
			'error' => 100
		},
		GOTOS => {
			'check_semicolon' => 222
		}
	},
	{#State 118
		DEFAULT => -362
	},
	{#State 119
		ACTIONS => {
			'STRING_LITERAL' => 119
		},
		DEFAULT => -168,
		GOTOS => {
			'string_literal' => 223
		}
	},
	{#State 120
		DEFAULT => 0
	},
	{#State 121
		DEFAULT => -14
	},
	{#State 122
		ACTIONS => {
			"::" => 140,
			'STRING_LITERAL' => 119,
			'error' => 225
		},
		GOTOS => {
			'string_literal' => 224
		}
	},
	{#State 123
		DEFAULT => -367
	},
	{#State 124
		DEFAULT => -2
	},
	{#State 125
		DEFAULT => -6
	},
	{#State 126
		ACTIONS => {
			"::" => 140,
			'STRING_LITERAL' => 119,
			'error' => 227
		},
		GOTOS => {
			'string_literal' => 226
		}
	},
	{#State 127
		ACTIONS => {
			'IDENTIFIER' => 144,
			'STRING_LITERAL' => 119,
			'error' => 145
		},
		GOTOS => {
			'string_literal' => 228
		}
	},
	{#State 128
		DEFAULT => -371
	},
	{#State 129
		DEFAULT => -17
	},
	{#State 130
		DEFAULT => -16
	},
	{#State 131
		DEFAULT => -273
	},
	{#State 132
		ACTIONS => {
			'IDENTIFIER' => 229,
			'error' => 231
		},
		GOTOS => {
			'enumerators' => 232,
			'enumerator' => 230
		}
	},
	{#State 133
		ACTIONS => {
			"(" => 233,
			'error' => 234
		}
	},
	{#State 134
		ACTIONS => {
			"::" => -396,
			'ENUM' => -396,
			'CHAR' => -396,
			'OBJECT' => -396,
			'STRING' => -396,
			'OCTET' => -396,
			'WSTRING' => -396,
			'UNION' => -396,
			'UNSIGNED' => -396,
			'error' => 236,
			"[" => 42,
			'ANY' => -396,
			'FLOAT' => -396,
			'LONG' => -396,
			'SEQUENCE' => -396,
			'DOUBLE' => -396,
			'IDENTIFIER' => -396,
			'SHORT' => -396,
			'BOOLEAN' => -396,
			'STRUCT' => -396,
			'VOID' => -396,
			'FIXED' => -396,
			'VALUEBASE' => -396,
			'WCHAR' => -396
		},
		GOTOS => {
			'union_type' => 34,
			'enum_type' => 46,
			'member' => 213,
			'enum_header' => 35,
			'struct_type' => 38,
			'union_header' => 39,
			'constr_type_spec' => 215,
			'props' => 214,
			'struct_header' => 40,
			'member_list' => 235
		}
	},
	{#State 135
		ACTIONS => {
			'LONG' => 237
		},
		DEFAULT => -231
	},
	{#State 136
		DEFAULT => -230
	},
	{#State 137
		ACTIONS => {
			'PROP_KEY' => 238
		},
		GOTOS => {
			'prop_list' => 239
		}
	},
	{#State 138
		DEFAULT => -226
	},
	{#State 139
		DEFAULT => -218
	},
	{#State 140
		ACTIONS => {
			'IDENTIFIER' => 240,
			'error' => 241
		}
	},
	{#State 141
		ACTIONS => {
			'IDENTIFIER' => 242,
			'error' => 243
		}
	},
	{#State 142
		ACTIONS => {
			'IDENTIFIER' => 244,
			'error' => 245
		}
	},
	{#State 143
		ACTIONS => {
			'IDENTIFIER' => 246,
			'error' => 247
		}
	},
	{#State 144
		DEFAULT => -61
	},
	{#State 145
		DEFAULT => -62
	},
	{#State 146
		ACTIONS => {
			"-" => 248,
			"::" => 63,
			'TRUE' => 261,
			"+" => 262,
			"~" => 249,
			'INTEGER_LITERAL' => 263,
			'FLOATING_PT_LITERAL' => 265,
			'FALSE' => 251,
			'error' => 266,
			'WIDE_STRING_LITERAL' => 267,
			'CHARACTER_LITERAL' => 268,
			'IDENTIFIER' => 49,
			"(" => 258,
			'FIXED_PT_LITERAL' => 272,
			'STRING_LITERAL' => 119,
			'WIDE_CHARACTER_LITERAL' => 260
		},
		GOTOS => {
			'shift_expr' => 264,
			'literal' => 250,
			'const_exp' => 252,
			'unary_operator' => 253,
			'string_literal' => 254,
			'and_expr' => 255,
			'or_expr' => 256,
			'mult_expr' => 269,
			'scoped_name' => 257,
			'boolean_literal' => 270,
			'add_expr' => 271,
			'positive_int_const' => 273,
			'unary_expr' => 259,
			'primary_expr' => 274,
			'wide_string_literal' => 275,
			'xor_expr' => 276
		}
	},
	{#State 147
		ACTIONS => {
			"-" => 248,
			"::" => 63,
			'TRUE' => 261,
			"+" => 262,
			"~" => 249,
			'INTEGER_LITERAL' => 263,
			'FLOATING_PT_LITERAL' => 265,
			'FALSE' => 251,
			'error' => 277,
			'WIDE_STRING_LITERAL' => 267,
			'CHARACTER_LITERAL' => 268,
			'IDENTIFIER' => 49,
			"(" => 258,
			'FIXED_PT_LITERAL' => 272,
			'STRING_LITERAL' => 119,
			'WIDE_CHARACTER_LITERAL' => 260
		},
		GOTOS => {
			'shift_expr' => 264,
			'literal' => 250,
			'const_exp' => 252,
			'unary_operator' => 253,
			'string_literal' => 254,
			'and_expr' => 255,
			'or_expr' => 256,
			'mult_expr' => 269,
			'scoped_name' => 257,
			'boolean_literal' => 270,
			'add_expr' => 271,
			'positive_int_const' => 278,
			'unary_expr' => 259,
			'primary_expr' => 274,
			'wide_string_literal' => 275,
			'xor_expr' => 276
		}
	},
	{#State 148
		ACTIONS => {
			"::" => 63,
			'CHAR' => 64,
			'OBJECT' => 68,
			'STRING' => 71,
			'OCTET' => 37,
			'WSTRING' => 73,
			'UNSIGNED' => 41,
			'error' => 279,
			'ANY' => 43,
			'FLOAT' => 76,
			'LONG' => 44,
			'SEQUENCE' => 78,
			'IDENTIFIER' => 49,
			'DOUBLE' => 79,
			'SHORT' => 80,
			'BOOLEAN' => 82,
			'VOID' => 55,
			'FIXED' => 85,
			'VALUEBASE' => 87,
			'WCHAR' => 60
		},
		GOTOS => {
			'wide_string_type' => 62,
			'object_type' => 65,
			'integer_type' => 67,
			'sequence_type' => 70,
			'unsigned_int' => 69,
			'unsigned_short_int' => 36,
			'unsigned_longlong_int' => 72,
			'floating_pt_type' => 75,
			'value_base_type' => 77,
			'signed_longlong_int' => 45,
			'any_type' => 47,
			'template_type_spec' => 48,
			'base_type_spec' => 81,
			'unsigned_long_int' => 50,
			'scoped_name' => 51,
			'signed_int' => 83,
			'string_type' => 52,
			'simple_type_spec' => 280,
			'char_type' => 54,
			'signed_short_int' => 57,
			'signed_long_int' => 56,
			'fixed_pt_type' => 58,
			'boolean_type' => 86,
			'wide_char_type' => 59,
			'octet_type' => 61
		}
	},
	{#State 149
		DEFAULT => -285
	},
	{#State 150
		ACTIONS => {
			"-" => 248,
			"::" => 63,
			'TRUE' => 261,
			"+" => 262,
			"~" => 249,
			'INTEGER_LITERAL' => 263,
			'FLOATING_PT_LITERAL' => 265,
			'FALSE' => 251,
			'error' => 281,
			'WIDE_STRING_LITERAL' => 267,
			'CHARACTER_LITERAL' => 268,
			'IDENTIFIER' => 49,
			"(" => 258,
			'FIXED_PT_LITERAL' => 272,
			'STRING_LITERAL' => 119,
			'WIDE_CHARACTER_LITERAL' => 260
		},
		GOTOS => {
			'shift_expr' => 264,
			'literal' => 250,
			'const_exp' => 252,
			'unary_operator' => 253,
			'string_literal' => 254,
			'and_expr' => 255,
			'or_expr' => 256,
			'mult_expr' => 269,
			'scoped_name' => 257,
			'boolean_literal' => 270,
			'add_expr' => 271,
			'positive_int_const' => 282,
			'unary_expr' => 259,
			'primary_expr' => 274,
			'wide_string_literal' => 275,
			'xor_expr' => 276
		}
	},
	{#State 151
		DEFAULT => -354
	},
	{#State 152
		DEFAULT => -303
	},
	{#State 153
		DEFAULT => -304
	},
	{#State 154
		DEFAULT => -86
	},
	{#State 155
		ACTIONS => {
			'IDENTIFIER' => 284,
			'error' => 285
		},
		GOTOS => {
			'simple_declarator' => 283
		}
	},
	{#State 156
		ACTIONS => {
			'ENUM' => -396,
			"::" => 63,
			'CHAR' => 64,
			'OBJECT' => 68,
			'STRING' => 71,
			'OCTET' => 37,
			'WSTRING' => 73,
			'UNION' => -396,
			'UNSIGNED' => 41,
			'error' => 288,
			"[" => 42,
			'ANY' => 43,
			'FLOAT' => 76,
			'LONG' => 44,
			'SEQUENCE' => 78,
			'DOUBLE' => 79,
			'IDENTIFIER' => 49,
			'SHORT' => 80,
			'BOOLEAN' => 82,
			'STRUCT' => -396,
			'VOID' => 55,
			'FIXED' => 85,
			'VALUEBASE' => 87,
			'WCHAR' => 60
		},
		GOTOS => {
			'union_type' => 34,
			'enum_header' => 35,
			'unsigned_short_int' => 36,
			'struct_type' => 38,
			'union_header' => 39,
			'struct_header' => 40,
			'type_declarator' => 286,
			'signed_longlong_int' => 45,
			'enum_type' => 46,
			'any_type' => 47,
			'template_type_spec' => 48,
			'unsigned_long_int' => 50,
			'scoped_name' => 51,
			'string_type' => 52,
			'props' => 53,
			'char_type' => 54,
			'fixed_pt_type' => 58,
			'signed_short_int' => 57,
			'signed_long_int' => 56,
			'wide_char_type' => 59,
			'octet_type' => 61,
			'wide_string_type' => 62,
			'object_type' => 65,
			'type_spec' => 287,
			'integer_type' => 67,
			'unsigned_int' => 69,
			'sequence_type' => 70,
			'unsigned_longlong_int' => 72,
			'constr_type_spec' => 74,
			'floating_pt_type' => 75,
			'value_base_type' => 77,
			'base_type_spec' => 81,
			'signed_int' => 83,
			'simple_type_spec' => 84,
			'boolean_type' => 86
		}
	},
	{#State 157
		ACTIONS => {
			'INTERFACE' => 289
		}
	},
	{#State 158
		ACTIONS => {
			'VALUETYPE' => 290
		}
	},
	{#State 159
		ACTIONS => {
			'IDENTIFIER' => 291,
			'error' => 292
		}
	},
	{#State 160
		ACTIONS => {
			'INTERFACE' => -35,
			'VALUETYPE' => 293,
			'error' => 294
		}
	},
	{#State 161
		ACTIONS => {
			'IDENTIFIER' => 295,
			'error' => 296
		}
	},
	{#State 162
		DEFAULT => -36
	},
	{#State 163
		DEFAULT => -26
	},
	{#State 164
		DEFAULT => -27
	},
	{#State 165
		ACTIONS => {
			"::" => 140
		},
		DEFAULT => -132
	},
	{#State 166
		DEFAULT => -129
	},
	{#State 167
		DEFAULT => -125
	},
	{#State 168
		DEFAULT => -126
	},
	{#State 169
		DEFAULT => -133
	},
	{#State 170
		DEFAULT => -130
	},
	{#State 171
		DEFAULT => -124
	},
	{#State 172
		DEFAULT => -128
	},
	{#State 173
		DEFAULT => -123
	},
	{#State 174
		ACTIONS => {
			'IDENTIFIER' => 297,
			'error' => 298
		}
	},
	{#State 175
		DEFAULT => -131
	},
	{#State 176
		DEFAULT => -355
	},
	{#State 177
		DEFAULT => -127
	},
	{#State 178
		DEFAULT => -79
	},
	{#State 179
		DEFAULT => -53
	},
	{#State 180
		DEFAULT => -297
	},
	{#State 181
		ACTIONS => {
			'CODE_FRAGMENT' => 90,
			'EXCEPTION' => 91,
			"[" => 42,
			'CONST' => 97
		},
		DEFAULT => -396,
		GOTOS => {
			'union_type' => 88,
			'enum_type' => 92,
			'enum_header' => 35,
			'type_dcl_def' => 93,
			'struct_type' => 89,
			'union_header' => 39,
			'props' => 299,
			'struct_header' => 40,
			'constr_forward_decl' => 95
		}
	},
	{#State 182
		ACTIONS => {
			";" => 99,
			'error' => 100
		},
		GOTOS => {
			'check_semicolon' => 300
		}
	},
	{#State 183
		DEFAULT => -99
	},
	{#State 184
		ACTIONS => {
			";" => 99,
			'error' => 100
		},
		GOTOS => {
			'check_semicolon' => 301
		}
	},
	{#State 185
		ACTIONS => {
			"}" => -82,
			'TYPEID' => 25,
			'DECLSPEC' => 29,
			'TYPEPREFIX' => 31
		},
		DEFAULT => -394,
		GOTOS => {
			'op_header' => 188,
			'init_header_param' => 189,
			'code_frag' => 179,
			'readonly_attr_spec' => 180,
			'init_header' => 190,
			'op_dcl' => 191,
			'attr_dcl' => 192,
			'declspec' => 181,
			'except_dcl' => 182,
			'state_member' => 194,
			'export' => 183,
			'type_dcl' => 184,
			'value_elements' => 302,
			'value_element' => 185,
			'exception_header' => 15,
			'attr_spec' => 186,
			'const_dcl' => 187,
			'type_prefix_dcl' => 196,
			'type_id_dcl' => 198,
			'init_dcl' => 197
		}
	},
	{#State 186
		DEFAULT => -298
	},
	{#State 187
		ACTIONS => {
			";" => 99,
			'error' => 100
		},
		GOTOS => {
			'check_semicolon' => 303
		}
	},
	{#State 188
		ACTIONS => {
			"(" => 304,
			'error' => 305
		},
		GOTOS => {
			'parameter_dcls' => 306
		}
	},
	{#State 189
		ACTIONS => {
			'RAISES' => 307
		},
		DEFAULT => -333,
		GOTOS => {
			'raises_expr' => 308
		}
	},
	{#State 190
		ACTIONS => {
			"(" => 309,
			'error' => 310
		}
	},
	{#State 191
		ACTIONS => {
			";" => 99,
			'error' => 100
		},
		GOTOS => {
			'check_semicolon' => 311
		}
	},
	{#State 192
		ACTIONS => {
			";" => 99,
			'error' => 100
		},
		GOTOS => {
			'check_semicolon' => 312
		}
	},
	{#State 193
		ACTIONS => {
			"}" => 313
		}
	},
	{#State 194
		DEFAULT => -100
	},
	{#State 195
		ACTIONS => {
			"}" => 314
		}
	},
	{#State 196
		ACTIONS => {
			";" => 99,
			'error' => 100
		},
		GOTOS => {
			'check_semicolon' => 315
		}
	},
	{#State 197
		DEFAULT => -101
	},
	{#State 198
		ACTIONS => {
			";" => 99,
			'error' => 100
		},
		GOTOS => {
			'check_semicolon' => 316
		}
	},
	{#State 199
		DEFAULT => -30
	},
	{#State 200
		DEFAULT => -43
	},
	{#State 201
		ACTIONS => {
			"}" => -41,
			'TYPEID' => 25,
			'DECLSPEC' => 29,
			'TYPEPREFIX' => 31
		},
		DEFAULT => -394,
		GOTOS => {
			'op_header' => 188,
			'init_header_param' => 189,
			'code_frag' => 179,
			'readonly_attr_spec' => 180,
			'init_header' => 190,
			'op_dcl' => 191,
			'exports' => 317,
			'attr_dcl' => 192,
			'declspec' => 181,
			'except_dcl' => 182,
			'state_member' => 205,
			'type_dcl' => 184,
			'export' => 200,
			'_export' => 201,
			'exception_header' => 15,
			'attr_spec' => 186,
			'const_dcl' => 187,
			'type_prefix_dcl' => 196,
			'init_dcl' => 206,
			'type_id_dcl' => 198
		}
	},
	{#State 202
		ACTIONS => {
			"}" => 318
		}
	},
	{#State 203
		DEFAULT => -40
	},
	{#State 204
		ACTIONS => {
			"}" => 319
		}
	},
	{#State 205
		DEFAULT => -44
	},
	{#State 206
		DEFAULT => -45
	},
	{#State 207
		DEFAULT => -19
	},
	{#State 208
		DEFAULT => -73
	},
	{#State 209
		ACTIONS => {
			"}" => 320
		}
	},
	{#State 210
		ACTIONS => {
			"}" => 321
		}
	},
	{#State 211
		DEFAULT => -299
	},
	{#State 212
		ACTIONS => {
			"}" => 322
		}
	},
	{#State 213
		ACTIONS => {
			"}" => -243,
			"[" => 42
		},
		DEFAULT => -396,
		GOTOS => {
			'union_type' => 34,
			'enum_type' => 46,
			'member' => 213,
			'enum_header' => 35,
			'struct_type' => 38,
			'union_header' => 39,
			'constr_type_spec' => 215,
			'props' => 214,
			'struct_header' => 40,
			'member_list' => 323
		}
	},
	{#State 214
		ACTIONS => {
			'ENUM' => 142,
			"::" => 63,
			'CHAR' => 64,
			'OBJECT' => 68,
			'STRING' => 71,
			'OCTET' => 37,
			'WSTRING' => 73,
			'UNION' => 143,
			'UNSIGNED' => 41,
			'ANY' => 43,
			'FLOAT' => 76,
			'LONG' => 44,
			'SEQUENCE' => 78,
			'IDENTIFIER' => 49,
			'DOUBLE' => 79,
			'SHORT' => 80,
			'BOOLEAN' => 82,
			'STRUCT' => 141,
			'VOID' => 55,
			'FIXED' => 85,
			'VALUEBASE' => 87,
			'WCHAR' => 60
		},
		GOTOS => {
			'wide_string_type' => 62,
			'object_type' => 65,
			'integer_type' => 67,
			'sequence_type' => 70,
			'unsigned_int' => 69,
			'unsigned_short_int' => 36,
			'unsigned_longlong_int' => 72,
			'floating_pt_type' => 75,
			'value_base_type' => 77,
			'signed_longlong_int' => 45,
			'any_type' => 47,
			'template_type_spec' => 48,
			'base_type_spec' => 81,
			'unsigned_long_int' => 50,
			'scoped_name' => 51,
			'signed_int' => 83,
			'string_type' => 52,
			'simple_type_spec' => 324,
			'char_type' => 54,
			'signed_short_int' => 57,
			'signed_long_int' => 56,
			'fixed_pt_type' => 58,
			'boolean_type' => 86,
			'wide_char_type' => 59,
			'octet_type' => 61
		}
	},
	{#State 215
		ACTIONS => {
			'IDENTIFIER' => 326,
			'error' => 285
		},
		GOTOS => {
			'declarators' => 328,
			'array_declarator' => 329,
			'simple_declarator' => 325,
			'declarator' => 327,
			'complex_declarator' => 330
		}
	},
	{#State 216
		ACTIONS => {
			"}" => 331
		}
	},
	{#State 217
		DEFAULT => -9
	},
	{#State 218
		DEFAULT => -25
	},
	{#State 219
		DEFAULT => -24
	},
	{#State 220
		ACTIONS => {
			"}" => 332
		}
	},
	{#State 221
		ACTIONS => {
			"}" => 333
		}
	},
	{#State 222
		DEFAULT => -361
	},
	{#State 223
		DEFAULT => -169
	},
	{#State 224
		DEFAULT => -365
	},
	{#State 225
		DEFAULT => -366
	},
	{#State 226
		DEFAULT => -368
	},
	{#State 227
		DEFAULT => -369
	},
	{#State 228
		DEFAULT => -370
	},
	{#State 229
		DEFAULT => -280
	},
	{#State 230
		ACTIONS => {
			";" => 334,
			"," => 335
		},
		DEFAULT => -276
	},
	{#State 231
		ACTIONS => {
			"}" => 336
		}
	},
	{#State 232
		ACTIONS => {
			"}" => 337
		}
	},
	{#State 233
		ACTIONS => {
			'ENUM' => -396,
			"::" => 63,
			'IDENTIFIER' => 49,
			'SHORT' => 80,
			'CHAR' => 64,
			'BOOLEAN' => 82,
			'UNSIGNED' => 41,
			'error' => 344,
			"[" => 42,
			'LONG' => 338
		},
		GOTOS => {
			'signed_longlong_int' => 45,
			'enum_type' => 339,
			'integer_type' => 343,
			'unsigned_long_int' => 50,
			'unsigned_int' => 69,
			'scoped_name' => 340,
			'enum_header' => 35,
			'signed_int' => 83,
			'unsigned_short_int' => 36,
			'unsigned_longlong_int' => 72,
			'props' => 341,
			'char_type' => 342,
			'signed_short_int' => 57,
			'signed_long_int' => 56,
			'boolean_type' => 346,
			'switch_type_spec' => 345
		}
	},
	{#State 234
		DEFAULT => -251
	},
	{#State 235
		ACTIONS => {
			"}" => 347
		}
	},
	{#State 236
		ACTIONS => {
			"}" => 348
		}
	},
	{#State 237
		DEFAULT => -232
	},
	{#State 238
		ACTIONS => {
			'PROP_VALUE' => 349
		},
		DEFAULT => -401
	},
	{#State 239
		ACTIONS => {
			"," => 351,
			"]" => 350
		}
	},
	{#State 240
		DEFAULT => -63
	},
	{#State 241
		DEFAULT => -64
	},
	{#State 242
		DEFAULT => -241
	},
	{#State 243
		DEFAULT => -242
	},
	{#State 244
		DEFAULT => -274
	},
	{#State 245
		DEFAULT => -275
	},
	{#State 246
		DEFAULT => -252
	},
	{#State 247
		DEFAULT => -253
	},
	{#State 248
		DEFAULT => -153
	},
	{#State 249
		DEFAULT => -155
	},
	{#State 250
		DEFAULT => -157
	},
	{#State 251
		DEFAULT => -173
	},
	{#State 252
		DEFAULT => -174
	},
	{#State 253
		ACTIONS => {
			"::" => 63,
			'TRUE' => 261,
			'IDENTIFIER' => 49,
			'INTEGER_LITERAL' => 263,
			'FLOATING_PT_LITERAL' => 265,
			'FIXED_PT_LITERAL' => 272,
			"(" => 258,
			'FALSE' => 251,
			'STRING_LITERAL' => 119,
			'WIDE_CHARACTER_LITERAL' => 260,
			'WIDE_STRING_LITERAL' => 267,
			'CHARACTER_LITERAL' => 268
		},
		GOTOS => {
			'literal' => 250,
			'primary_expr' => 352,
			'scoped_name' => 257,
			'wide_string_literal' => 275,
			'boolean_literal' => 270,
			'string_literal' => 254
		}
	},
	{#State 254
		DEFAULT => -161
	},
	{#State 255
		ACTIONS => {
			"&" => 353
		},
		DEFAULT => -137
	},
	{#State 256
		ACTIONS => {
			"|" => 354
		},
		DEFAULT => -134
	},
	{#State 257
		ACTIONS => {
			"::" => 140
		},
		DEFAULT => -156
	},
	{#State 258
		ACTIONS => {
			"-" => 248,
			"::" => 63,
			'TRUE' => 261,
			"+" => 262,
			"~" => 249,
			'INTEGER_LITERAL' => 263,
			'FLOATING_PT_LITERAL' => 265,
			'FALSE' => 251,
			'error' => 356,
			'WIDE_STRING_LITERAL' => 267,
			'CHARACTER_LITERAL' => 268,
			'IDENTIFIER' => 49,
			"(" => 258,
			'FIXED_PT_LITERAL' => 272,
			'STRING_LITERAL' => 119,
			'WIDE_CHARACTER_LITERAL' => 260
		},
		GOTOS => {
			'and_expr' => 255,
			'or_expr' => 256,
			'mult_expr' => 269,
			'shift_expr' => 264,
			'scoped_name' => 257,
			'boolean_literal' => 270,
			'add_expr' => 271,
			'literal' => 250,
			'primary_expr' => 274,
			'unary_expr' => 259,
			'unary_operator' => 253,
			'const_exp' => 355,
			'xor_expr' => 276,
			'wide_string_literal' => 275,
			'string_literal' => 254
		}
	},
	{#State 259
		DEFAULT => -147
	},
	{#State 260
		DEFAULT => -164
	},
	{#State 261
		DEFAULT => -172
	},
	{#State 262
		DEFAULT => -154
	},
	{#State 263
		DEFAULT => -160
	},
	{#State 264
		ACTIONS => {
			"<<" => 358,
			">>" => 357
		},
		DEFAULT => -139
	},
	{#State 265
		DEFAULT => -166
	},
	{#State 266
		ACTIONS => {
			">" => 359
		}
	},
	{#State 267
		ACTIONS => {
			'WIDE_STRING_LITERAL' => 267
		},
		DEFAULT => -170,
		GOTOS => {
			'wide_string_literal' => 360
		}
	},
	{#State 268
		DEFAULT => -163
	},
	{#State 269
		ACTIONS => {
			"%" => 361,
			"*" => 362,
			"/" => 363
		},
		DEFAULT => -144
	},
	{#State 270
		DEFAULT => -167
	},
	{#State 271
		ACTIONS => {
			"-" => 364,
			"+" => 365
		},
		DEFAULT => -141
	},
	{#State 272
		DEFAULT => -165
	},
	{#State 273
		ACTIONS => {
			">" => 366
		}
	},
	{#State 274
		DEFAULT => -152
	},
	{#State 275
		DEFAULT => -162
	},
	{#State 276
		ACTIONS => {
			"^" => 367
		},
		DEFAULT => -135
	},
	{#State 277
		ACTIONS => {
			">" => 368
		}
	},
	{#State 278
		ACTIONS => {
			">" => 369
		}
	},
	{#State 279
		ACTIONS => {
			">" => 370
		}
	},
	{#State 280
		ACTIONS => {
			"," => 372,
			">" => 371
		}
	},
	{#State 281
		ACTIONS => {
			">" => 373
		}
	},
	{#State 282
		ACTIONS => {
			"," => 374
		}
	},
	{#State 283
		ACTIONS => {
			"(" => 375
		},
		DEFAULT => -180
	},
	{#State 284
		DEFAULT => -212
	},
	{#State 285
		ACTIONS => {
			";" => 376,
			"," => 377
		}
	},
	{#State 286
		DEFAULT => -176
	},
	{#State 287
		ACTIONS => {
			'IDENTIFIER' => 326,
			'error' => 285
		},
		GOTOS => {
			'declarators' => 378,
			'array_declarator' => 329,
			'simple_declarator' => 325,
			'declarator' => 327,
			'complex_declarator' => 330
		}
	},
	{#State 288
		DEFAULT => -184
	},
	{#State 289
		ACTIONS => {
			'IDENTIFIER' => 379,
			'error' => 380
		}
	},
	{#State 290
		ACTIONS => {
			'IDENTIFIER' => 381,
			'error' => 382
		}
	},
	{#State 291
		ACTIONS => {
			"{" => -241
		},
		DEFAULT => -357
	},
	{#State 292
		ACTIONS => {
			"{" => -242
		},
		DEFAULT => -358
	},
	{#State 293
		ACTIONS => {
			'IDENTIFIER' => 383,
			'error' => 384
		}
	},
	{#State 294
		DEFAULT => -78
	},
	{#State 295
		ACTIONS => {
			'SWITCH' => -252
		},
		DEFAULT => -359
	},
	{#State 296
		ACTIONS => {
			'SWITCH' => -253
		},
		DEFAULT => -360
	},
	{#State 297
		ACTIONS => {
			'error' => 385,
			"=" => 386
		}
	},
	{#State 298
		DEFAULT => -122
	},
	{#State 299
		ACTIONS => {
			'FACTORY' => 389,
			'ENUM' => 142,
			'PRIVATE' => 390,
			'ONEWAY' => 391,
			'UNION' => 161,
			'NATIVE' => 155,
			'TYPEDEF' => 156,
			'ATTRIBUTE' => 392,
			'PUBLIC' => 394,
			'STRUCT' => 159,
			'READONLY' => 395
		},
		DEFAULT => -310,
		GOTOS => {
			'op_mod' => 388,
			'op_attribute' => 387,
			'state_mod' => 393
		}
	},
	{#State 300
		DEFAULT => -48
	},
	{#State 301
		DEFAULT => -46
	},
	{#State 302
		DEFAULT => -83
	},
	{#State 303
		DEFAULT => -47
	},
	{#State 304
		ACTIONS => {
			"::" => -396,
			'CHAR' => -396,
			'OBJECT' => -396,
			'STRING' => -396,
			'OCTET' => -396,
			'WSTRING' => -396,
			'UNSIGNED' => -396,
			'error' => 399,
			"[" => 42,
			'ANY' => -396,
			'FLOAT' => -396,
			")" => 400,
			'LONG' => -396,
			'SEQUENCE' => -396,
			'DOUBLE' => -396,
			'IDENTIFIER' => -396,
			'SHORT' => -396,
			'BOOLEAN' => -396,
			'INOUT' => -396,
			"..." => 401,
			'OUT' => -396,
			'IN' => -396,
			'VOID' => -396,
			'FIXED' => -396,
			'VALUEBASE' => -396,
			'WCHAR' => -396
		},
		GOTOS => {
			'props' => 397,
			'param_dcl' => 396,
			'param_dcls' => 398
		}
	},
	{#State 305
		DEFAULT => -306
	},
	{#State 306
		ACTIONS => {
			'RAISES' => 307
		},
		DEFAULT => -333,
		GOTOS => {
			'raises_expr' => 402
		}
	},
	{#State 307
		ACTIONS => {
			"(" => 403,
			'error' => 404
		}
	},
	{#State 308
		ACTIONS => {
			";" => 99,
			'error' => 100
		},
		GOTOS => {
			'check_semicolon' => 405
		}
	},
	{#State 309
		ACTIONS => {
			'error' => 408,
			")" => 409,
			'IN' => 411
		},
		GOTOS => {
			'init_param_decl' => 407,
			'init_param_decls' => 410,
			'init_param_attribute' => 406
		}
	},
	{#State 310
		DEFAULT => -111
	},
	{#State 311
		DEFAULT => -50
	},
	{#State 312
		DEFAULT => -49
	},
	{#State 313
		DEFAULT => -81
	},
	{#State 314
		DEFAULT => -80
	},
	{#State 315
		DEFAULT => -52
	},
	{#State 316
		DEFAULT => -51
	},
	{#State 317
		DEFAULT => -42
	},
	{#State 318
		DEFAULT => -31
	},
	{#State 319
		DEFAULT => -32
	},
	{#State 320
		DEFAULT => -74
	},
	{#State 321
		DEFAULT => -75
	},
	{#State 322
		DEFAULT => -300
	},
	{#State 323
		DEFAULT => -244
	},
	{#State 324
		ACTIONS => {
			'IDENTIFIER' => 326,
			'error' => 285
		},
		GOTOS => {
			'declarators' => 412,
			'array_declarator' => 329,
			'simple_declarator' => 325,
			'declarator' => 327,
			'complex_declarator' => 330
		}
	},
	{#State 325
		DEFAULT => -210
	},
	{#State 326
		ACTIONS => {
			"[" => 414
		},
		DEFAULT => -212,
		GOTOS => {
			'fixed_array_sizes' => 413,
			'fixed_array_size' => 415
		}
	},
	{#State 327
		ACTIONS => {
			"," => 416
		},
		DEFAULT => -208
	},
	{#State 328
		ACTIONS => {
			";" => 99,
			'error' => 100
		},
		GOTOS => {
			'check_semicolon' => 417
		}
	},
	{#State 329
		DEFAULT => -215
	},
	{#State 330
		DEFAULT => -211
	},
	{#State 331
		DEFAULT => -301
	},
	{#State 332
		DEFAULT => -22
	},
	{#State 333
		DEFAULT => -23
	},
	{#State 334
		DEFAULT => -279
	},
	{#State 335
		ACTIONS => {
			'IDENTIFIER' => 229
		},
		DEFAULT => -278,
		GOTOS => {
			'enumerators' => 418,
			'enumerator' => 230
		}
	},
	{#State 336
		DEFAULT => -272
	},
	{#State 337
		DEFAULT => -271
	},
	{#State 338
		ACTIONS => {
			'LONG' => 138
		},
		DEFAULT => -225
	},
	{#State 339
		DEFAULT => -257
	},
	{#State 340
		ACTIONS => {
			"::" => 140
		},
		DEFAULT => -258
	},
	{#State 341
		ACTIONS => {
			'ENUM' => 142
		}
	},
	{#State 342
		DEFAULT => -255
	},
	{#State 343
		DEFAULT => -254
	},
	{#State 344
		ACTIONS => {
			")" => 419
		}
	},
	{#State 345
		ACTIONS => {
			")" => 420
		}
	},
	{#State 346
		DEFAULT => -256
	},
	{#State 347
		DEFAULT => -239
	},
	{#State 348
		DEFAULT => -240
	},
	{#State 349
		DEFAULT => -399
	},
	{#State 350
		DEFAULT => -398
	},
	{#State 351
		ACTIONS => {
			'PROP_KEY' => 421
		}
	},
	{#State 352
		DEFAULT => -151
	},
	{#State 353
		ACTIONS => {
			"-" => 248,
			"::" => 63,
			'TRUE' => 261,
			'IDENTIFIER' => 49,
			"+" => 262,
			"~" => 249,
			'INTEGER_LITERAL' => 263,
			'FLOATING_PT_LITERAL' => 265,
			'FIXED_PT_LITERAL' => 272,
			"(" => 258,
			'FALSE' => 251,
			'STRING_LITERAL' => 119,
			'WIDE_STRING_LITERAL' => 267,
			'WIDE_CHARACTER_LITERAL' => 260,
			'CHARACTER_LITERAL' => 268
		},
		GOTOS => {
			'mult_expr' => 269,
			'shift_expr' => 422,
			'scoped_name' => 257,
			'boolean_literal' => 270,
			'add_expr' => 271,
			'literal' => 250,
			'primary_expr' => 274,
			'unary_expr' => 259,
			'unary_operator' => 253,
			'wide_string_literal' => 275,
			'string_literal' => 254
		}
	},
	{#State 354
		ACTIONS => {
			"-" => 248,
			"::" => 63,
			'TRUE' => 261,
			'IDENTIFIER' => 49,
			"+" => 262,
			"~" => 249,
			'INTEGER_LITERAL' => 263,
			'FLOATING_PT_LITERAL' => 265,
			'FIXED_PT_LITERAL' => 272,
			"(" => 258,
			'FALSE' => 251,
			'STRING_LITERAL' => 119,
			'WIDE_STRING_LITERAL' => 267,
			'WIDE_CHARACTER_LITERAL' => 260,
			'CHARACTER_LITERAL' => 268
		},
		GOTOS => {
			'and_expr' => 255,
			'mult_expr' => 269,
			'shift_expr' => 264,
			'scoped_name' => 257,
			'boolean_literal' => 270,
			'add_expr' => 271,
			'literal' => 250,
			'primary_expr' => 274,
			'unary_expr' => 259,
			'unary_operator' => 253,
			'xor_expr' => 423,
			'wide_string_literal' => 275,
			'string_literal' => 254
		}
	},
	{#State 355
		ACTIONS => {
			")" => 424
		}
	},
	{#State 356
		ACTIONS => {
			")" => 425
		}
	},
	{#State 357
		ACTIONS => {
			"-" => 248,
			"::" => 63,
			'TRUE' => 261,
			'IDENTIFIER' => 49,
			"+" => 262,
			"~" => 249,
			'INTEGER_LITERAL' => 263,
			'FLOATING_PT_LITERAL' => 265,
			'FIXED_PT_LITERAL' => 272,
			"(" => 258,
			'FALSE' => 251,
			'STRING_LITERAL' => 119,
			'WIDE_STRING_LITERAL' => 267,
			'WIDE_CHARACTER_LITERAL' => 260,
			'CHARACTER_LITERAL' => 268
		},
		GOTOS => {
			'mult_expr' => 269,
			'scoped_name' => 257,
			'boolean_literal' => 270,
			'literal' => 250,
			'add_expr' => 426,
			'primary_expr' => 274,
			'unary_expr' => 259,
			'unary_operator' => 253,
			'wide_string_literal' => 275,
			'string_literal' => 254
		}
	},
	{#State 358
		ACTIONS => {
			"-" => 248,
			"::" => 63,
			'TRUE' => 261,
			'IDENTIFIER' => 49,
			"+" => 262,
			"~" => 249,
			'INTEGER_LITERAL' => 263,
			'FLOATING_PT_LITERAL' => 265,
			'FIXED_PT_LITERAL' => 272,
			"(" => 258,
			'FALSE' => 251,
			'STRING_LITERAL' => 119,
			'WIDE_STRING_LITERAL' => 267,
			'WIDE_CHARACTER_LITERAL' => 260,
			'CHARACTER_LITERAL' => 268
		},
		GOTOS => {
			'mult_expr' => 269,
			'scoped_name' => 257,
			'boolean_literal' => 270,
			'literal' => 250,
			'add_expr' => 427,
			'primary_expr' => 274,
			'unary_expr' => 259,
			'unary_operator' => 253,
			'wide_string_literal' => 275,
			'string_literal' => 254
		}
	},
	{#State 359
		DEFAULT => -288
	},
	{#State 360
		DEFAULT => -171
	},
	{#State 361
		ACTIONS => {
			"-" => 248,
			"::" => 63,
			'TRUE' => 261,
			'IDENTIFIER' => 49,
			"+" => 262,
			"~" => 249,
			'INTEGER_LITERAL' => 263,
			'FLOATING_PT_LITERAL' => 265,
			'FIXED_PT_LITERAL' => 272,
			"(" => 258,
			'FALSE' => 251,
			'STRING_LITERAL' => 119,
			'WIDE_STRING_LITERAL' => 267,
			'WIDE_CHARACTER_LITERAL' => 260,
			'CHARACTER_LITERAL' => 268
		},
		GOTOS => {
			'literal' => 250,
			'primary_expr' => 274,
			'unary_expr' => 428,
			'unary_operator' => 253,
			'scoped_name' => 257,
			'wide_string_literal' => 275,
			'boolean_literal' => 270,
			'string_literal' => 254
		}
	},
	{#State 362
		ACTIONS => {
			"-" => 248,
			"::" => 63,
			'TRUE' => 261,
			'IDENTIFIER' => 49,
			"+" => 262,
			"~" => 249,
			'INTEGER_LITERAL' => 263,
			'FLOATING_PT_LITERAL' => 265,
			'FIXED_PT_LITERAL' => 272,
			"(" => 258,
			'FALSE' => 251,
			'STRING_LITERAL' => 119,
			'WIDE_STRING_LITERAL' => 267,
			'WIDE_CHARACTER_LITERAL' => 260,
			'CHARACTER_LITERAL' => 268
		},
		GOTOS => {
			'literal' => 250,
			'primary_expr' => 274,
			'unary_expr' => 429,
			'unary_operator' => 253,
			'scoped_name' => 257,
			'wide_string_literal' => 275,
			'boolean_literal' => 270,
			'string_literal' => 254
		}
	},
	{#State 363
		ACTIONS => {
			"-" => 248,
			"::" => 63,
			'TRUE' => 261,
			'IDENTIFIER' => 49,
			"+" => 262,
			"~" => 249,
			'INTEGER_LITERAL' => 263,
			'FLOATING_PT_LITERAL' => 265,
			'FIXED_PT_LITERAL' => 272,
			"(" => 258,
			'FALSE' => 251,
			'STRING_LITERAL' => 119,
			'WIDE_STRING_LITERAL' => 267,
			'WIDE_CHARACTER_LITERAL' => 260,
			'CHARACTER_LITERAL' => 268
		},
		GOTOS => {
			'literal' => 250,
			'primary_expr' => 274,
			'unary_expr' => 430,
			'unary_operator' => 253,
			'scoped_name' => 257,
			'wide_string_literal' => 275,
			'boolean_literal' => 270,
			'string_literal' => 254
		}
	},
	{#State 364
		ACTIONS => {
			"-" => 248,
			"::" => 63,
			'TRUE' => 261,
			'IDENTIFIER' => 49,
			"+" => 262,
			"~" => 249,
			'INTEGER_LITERAL' => 263,
			'FLOATING_PT_LITERAL' => 265,
			'FIXED_PT_LITERAL' => 272,
			"(" => 258,
			'FALSE' => 251,
			'STRING_LITERAL' => 119,
			'WIDE_STRING_LITERAL' => 267,
			'WIDE_CHARACTER_LITERAL' => 260,
			'CHARACTER_LITERAL' => 268
		},
		GOTOS => {
			'mult_expr' => 431,
			'scoped_name' => 257,
			'boolean_literal' => 270,
			'literal' => 250,
			'unary_expr' => 259,
			'primary_expr' => 274,
			'unary_operator' => 253,
			'wide_string_literal' => 275,
			'string_literal' => 254
		}
	},
	{#State 365
		ACTIONS => {
			"-" => 248,
			"::" => 63,
			'TRUE' => 261,
			'IDENTIFIER' => 49,
			"+" => 262,
			"~" => 249,
			'INTEGER_LITERAL' => 263,
			'FLOATING_PT_LITERAL' => 265,
			'FIXED_PT_LITERAL' => 272,
			"(" => 258,
			'FALSE' => 251,
			'STRING_LITERAL' => 119,
			'WIDE_STRING_LITERAL' => 267,
			'WIDE_CHARACTER_LITERAL' => 260,
			'CHARACTER_LITERAL' => 268
		},
		GOTOS => {
			'mult_expr' => 432,
			'scoped_name' => 257,
			'boolean_literal' => 270,
			'literal' => 250,
			'unary_expr' => 259,
			'primary_expr' => 274,
			'unary_operator' => 253,
			'wide_string_literal' => 275,
			'string_literal' => 254
		}
	},
	{#State 366
		DEFAULT => -286
	},
	{#State 367
		ACTIONS => {
			"-" => 248,
			"::" => 63,
			'TRUE' => 261,
			'IDENTIFIER' => 49,
			"+" => 262,
			"~" => 249,
			'INTEGER_LITERAL' => 263,
			'FLOATING_PT_LITERAL' => 265,
			'FIXED_PT_LITERAL' => 272,
			"(" => 258,
			'FALSE' => 251,
			'STRING_LITERAL' => 119,
			'WIDE_STRING_LITERAL' => 267,
			'WIDE_CHARACTER_LITERAL' => 260,
			'CHARACTER_LITERAL' => 268
		},
		GOTOS => {
			'and_expr' => 433,
			'mult_expr' => 269,
			'shift_expr' => 264,
			'scoped_name' => 257,
			'boolean_literal' => 270,
			'add_expr' => 271,
			'literal' => 250,
			'primary_expr' => 274,
			'unary_expr' => 259,
			'unary_operator' => 253,
			'wide_string_literal' => 275,
			'string_literal' => 254
		}
	},
	{#State 368
		DEFAULT => -291
	},
	{#State 369
		DEFAULT => -289
	},
	{#State 370
		DEFAULT => -284
	},
	{#State 371
		DEFAULT => -283
	},
	{#State 372
		ACTIONS => {
			"-" => 248,
			"::" => 63,
			'TRUE' => 261,
			"+" => 262,
			"~" => 249,
			'INTEGER_LITERAL' => 263,
			'FLOATING_PT_LITERAL' => 265,
			'FALSE' => 251,
			'error' => 434,
			'WIDE_STRING_LITERAL' => 267,
			'CHARACTER_LITERAL' => 268,
			'IDENTIFIER' => 49,
			"(" => 258,
			'FIXED_PT_LITERAL' => 272,
			'STRING_LITERAL' => 119,
			'WIDE_CHARACTER_LITERAL' => 260
		},
		GOTOS => {
			'shift_expr' => 264,
			'literal' => 250,
			'const_exp' => 252,
			'unary_operator' => 253,
			'string_literal' => 254,
			'and_expr' => 255,
			'or_expr' => 256,
			'mult_expr' => 269,
			'scoped_name' => 257,
			'boolean_literal' => 270,
			'add_expr' => 271,
			'positive_int_const' => 435,
			'unary_expr' => 259,
			'primary_expr' => 274,
			'wide_string_literal' => 275,
			'xor_expr' => 276
		}
	},
	{#State 373
		DEFAULT => -353
	},
	{#State 374
		ACTIONS => {
			"-" => 248,
			"::" => 63,
			'TRUE' => 261,
			"+" => 262,
			"~" => 249,
			'INTEGER_LITERAL' => 263,
			'FLOATING_PT_LITERAL' => 265,
			'FALSE' => 251,
			'error' => 436,
			'WIDE_STRING_LITERAL' => 267,
			'CHARACTER_LITERAL' => 268,
			'IDENTIFIER' => 49,
			"(" => 258,
			'FIXED_PT_LITERAL' => 272,
			'STRING_LITERAL' => 119,
			'WIDE_CHARACTER_LITERAL' => 260
		},
		GOTOS => {
			'shift_expr' => 264,
			'literal' => 250,
			'const_exp' => 252,
			'unary_operator' => 253,
			'string_literal' => 254,
			'and_expr' => 255,
			'or_expr' => 256,
			'mult_expr' => 269,
			'scoped_name' => 257,
			'boolean_literal' => 270,
			'add_expr' => 271,
			'positive_int_const' => 437,
			'unary_expr' => 259,
			'primary_expr' => 274,
			'wide_string_literal' => 275,
			'xor_expr' => 276
		}
	},
	{#State 375
		DEFAULT => -181,
		GOTOS => {
			'@1-4' => 438
		}
	},
	{#State 376
		DEFAULT => -214
	},
	{#State 377
		DEFAULT => -213
	},
	{#State 378
		DEFAULT => -185
	},
	{#State 379
		ACTIONS => {
			":" => 439,
			"{" => -56
		},
		DEFAULT => -33,
		GOTOS => {
			'interface_inheritance_spec' => 440
		}
	},
	{#State 380
		ACTIONS => {
			"{" => -39
		},
		DEFAULT => -34
	},
	{#State 381
		ACTIONS => {
			":" => 441,
			'SUPPORTS' => 442,
			";" => -69,
			'error' => -69,
			"{" => -97
		},
		DEFAULT => -72,
		GOTOS => {
			'supported_interface_spec' => 444,
			'value_inheritance_spec' => 443
		}
	},
	{#State 382
		DEFAULT => -85
	},
	{#State 383
		ACTIONS => {
			":" => 441,
			'SUPPORTS' => 442,
			"{" => -97
		},
		DEFAULT => -70,
		GOTOS => {
			'supported_interface_spec' => 444,
			'value_inheritance_spec' => 445
		}
	},
	{#State 384
		DEFAULT => -77
	},
	{#State 385
		DEFAULT => -121
	},
	{#State 386
		ACTIONS => {
			"-" => 248,
			"::" => 63,
			'TRUE' => 261,
			"+" => 262,
			"~" => 249,
			'INTEGER_LITERAL' => 263,
			'FLOATING_PT_LITERAL' => 265,
			'FALSE' => 251,
			'error' => 447,
			'WIDE_STRING_LITERAL' => 267,
			'CHARACTER_LITERAL' => 268,
			'IDENTIFIER' => 49,
			"(" => 258,
			'FIXED_PT_LITERAL' => 272,
			'STRING_LITERAL' => 119,
			'WIDE_CHARACTER_LITERAL' => 260
		},
		GOTOS => {
			'and_expr' => 255,
			'or_expr' => 256,
			'mult_expr' => 269,
			'shift_expr' => 264,
			'scoped_name' => 257,
			'boolean_literal' => 270,
			'add_expr' => 271,
			'literal' => 250,
			'primary_expr' => 274,
			'unary_expr' => 259,
			'unary_operator' => 253,
			'const_exp' => 446,
			'xor_expr' => 276,
			'wide_string_literal' => 275,
			'string_literal' => 254
		}
	},
	{#State 387
		DEFAULT => -309
	},
	{#State 388
		ACTIONS => {
			"::" => 63,
			'CHAR' => 64,
			'OBJECT' => 68,
			'STRING' => 71,
			'OCTET' => 37,
			'WSTRING' => 73,
			'UNSIGNED' => 41,
			'ANY' => 43,
			'FLOAT' => 76,
			'LONG' => 44,
			'SEQUENCE' => 78,
			'IDENTIFIER' => 49,
			'DOUBLE' => 79,
			'SHORT' => 80,
			'BOOLEAN' => 82,
			'VOID' => 450,
			'FIXED' => 85,
			'VALUEBASE' => 87,
			'WCHAR' => 60
		},
		GOTOS => {
			'wide_string_type' => 452,
			'object_type' => 65,
			'integer_type' => 67,
			'unsigned_int' => 69,
			'sequence_type' => 453,
			'op_param_type_spec' => 454,
			'unsigned_short_int' => 36,
			'unsigned_longlong_int' => 72,
			'floating_pt_type' => 75,
			'value_base_type' => 77,
			'signed_longlong_int' => 45,
			'any_type' => 47,
			'base_type_spec' => 455,
			'unsigned_long_int' => 50,
			'scoped_name' => 448,
			'signed_int' => 83,
			'string_type' => 449,
			'char_type' => 54,
			'signed_long_int' => 56,
			'fixed_pt_type' => 451,
			'signed_short_int' => 57,
			'op_type_spec' => 456,
			'boolean_type' => 86,
			'wide_char_type' => 59,
			'octet_type' => 61
		}
	},
	{#State 389
		ACTIONS => {
			'IDENTIFIER' => 457,
			'error' => 458
		}
	},
	{#State 390
		DEFAULT => -106
	},
	{#State 391
		DEFAULT => -311
	},
	{#State 392
		ACTIONS => {
			"::" => 63,
			'CHAR' => 64,
			'OBJECT' => 68,
			'STRING' => 71,
			'OCTET' => 37,
			'WSTRING' => 73,
			'UNSIGNED' => 41,
			'error' => 464,
			'ANY' => 43,
			'FLOAT' => 76,
			'LONG' => 44,
			'SEQUENCE' => 78,
			'IDENTIFIER' => 49,
			'DOUBLE' => 79,
			'SHORT' => 80,
			'BOOLEAN' => 82,
			'VOID' => 459,
			'FIXED' => 85,
			'VALUEBASE' => 87,
			'WCHAR' => 60
		},
		GOTOS => {
			'wide_string_type' => 452,
			'object_type' => 65,
			'integer_type' => 67,
			'unsigned_int' => 69,
			'sequence_type' => 462,
			'op_param_type_spec' => 463,
			'unsigned_short_int' => 36,
			'unsigned_longlong_int' => 72,
			'floating_pt_type' => 75,
			'value_base_type' => 77,
			'signed_longlong_int' => 45,
			'any_type' => 47,
			'base_type_spec' => 455,
			'unsigned_long_int' => 50,
			'scoped_name' => 448,
			'signed_int' => 83,
			'string_type' => 449,
			'char_type' => 54,
			'signed_long_int' => 56,
			'fixed_pt_type' => 460,
			'signed_short_int' => 57,
			'param_type_spec' => 461,
			'boolean_type' => 86,
			'wide_char_type' => 59,
			'octet_type' => 61
		}
	},
	{#State 393
		ACTIONS => {
			'ENUM' => -396,
			"::" => 63,
			'CHAR' => 64,
			'OBJECT' => 68,
			'STRING' => 71,
			'OCTET' => 37,
			'WSTRING' => 73,
			'UNION' => -396,
			'UNSIGNED' => 41,
			'error' => 466,
			"[" => 42,
			'ANY' => 43,
			'FLOAT' => 76,
			'LONG' => 44,
			'SEQUENCE' => 78,
			'DOUBLE' => 79,
			'IDENTIFIER' => 49,
			'SHORT' => 80,
			'BOOLEAN' => 82,
			'STRUCT' => -396,
			'VOID' => 55,
			'FIXED' => 85,
			'VALUEBASE' => 87,
			'WCHAR' => 60
		},
		GOTOS => {
			'union_type' => 34,
			'enum_header' => 35,
			'unsigned_short_int' => 36,
			'struct_type' => 38,
			'union_header' => 39,
			'struct_header' => 40,
			'signed_longlong_int' => 45,
			'enum_type' => 46,
			'any_type' => 47,
			'template_type_spec' => 48,
			'unsigned_long_int' => 50,
			'scoped_name' => 51,
			'string_type' => 52,
			'props' => 53,
			'char_type' => 54,
			'fixed_pt_type' => 58,
			'signed_short_int' => 57,
			'signed_long_int' => 56,
			'wide_char_type' => 59,
			'octet_type' => 61,
			'wide_string_type' => 62,
			'object_type' => 65,
			'type_spec' => 465,
			'integer_type' => 67,
			'unsigned_int' => 69,
			'sequence_type' => 70,
			'unsigned_longlong_int' => 72,
			'constr_type_spec' => 74,
			'floating_pt_type' => 75,
			'value_base_type' => 77,
			'base_type_spec' => 81,
			'signed_int' => 83,
			'simple_type_spec' => 84,
			'boolean_type' => 86
		}
	},
	{#State 394
		DEFAULT => -105
	},
	{#State 395
		ACTIONS => {
			'error' => 467,
			'ATTRIBUTE' => 468
		}
	},
	{#State 396
		ACTIONS => {
			";" => 469
		},
		DEFAULT => -322
	},
	{#State 397
		ACTIONS => {
			'INOUT' => 471,
			'OUT' => 472,
			'IN' => 473
		},
		DEFAULT => -329,
		GOTOS => {
			'param_attribute' => 470
		}
	},
	{#State 398
		ACTIONS => {
			"," => 474,
			")" => 475
		}
	},
	{#State 399
		ACTIONS => {
			")" => 476
		}
	},
	{#State 400
		DEFAULT => -319
	},
	{#State 401
		ACTIONS => {
			")" => 477
		}
	},
	{#State 402
		ACTIONS => {
			'CONTEXT' => 479
		},
		DEFAULT => -340,
		GOTOS => {
			'context_expr' => 478
		}
	},
	{#State 403
		ACTIONS => {
			"::" => 63,
			'IDENTIFIER' => 49,
			'error' => 481
		},
		GOTOS => {
			'exception_names' => 482,
			'scoped_name' => 480,
			'exception_name' => 483
		}
	},
	{#State 404
		DEFAULT => -332
	},
	{#State 405
		DEFAULT => -107
	},
	{#State 406
		ACTIONS => {
			"::" => 63,
			'CHAR' => 64,
			'OBJECT' => 68,
			'STRING' => 71,
			'OCTET' => 37,
			'WSTRING' => 73,
			'UNSIGNED' => 41,
			'error' => 485,
			'ANY' => 43,
			'FLOAT' => 76,
			'LONG' => 44,
			'SEQUENCE' => 78,
			'IDENTIFIER' => 49,
			'DOUBLE' => 79,
			'SHORT' => 80,
			'BOOLEAN' => 82,
			'VOID' => 459,
			'FIXED' => 85,
			'VALUEBASE' => 87,
			'WCHAR' => 60
		},
		GOTOS => {
			'wide_string_type' => 452,
			'object_type' => 65,
			'integer_type' => 67,
			'unsigned_int' => 69,
			'sequence_type' => 462,
			'op_param_type_spec' => 463,
			'unsigned_short_int' => 36,
			'unsigned_longlong_int' => 72,
			'floating_pt_type' => 75,
			'value_base_type' => 77,
			'signed_longlong_int' => 45,
			'any_type' => 47,
			'base_type_spec' => 455,
			'unsigned_long_int' => 50,
			'scoped_name' => 448,
			'signed_int' => 83,
			'string_type' => 449,
			'char_type' => 54,
			'signed_long_int' => 56,
			'fixed_pt_type' => 460,
			'signed_short_int' => 57,
			'param_type_spec' => 484,
			'boolean_type' => 86,
			'wide_char_type' => 59,
			'octet_type' => 61
		}
	},
	{#State 407
		ACTIONS => {
			"," => 486
		},
		DEFAULT => -114
	},
	{#State 408
		ACTIONS => {
			")" => 487
		}
	},
	{#State 409
		DEFAULT => -108
	},
	{#State 410
		ACTIONS => {
			")" => 488
		}
	},
	{#State 411
		DEFAULT => -118
	},
	{#State 412
		ACTIONS => {
			";" => 99,
			'error' => 100
		},
		GOTOS => {
			'check_semicolon' => 489
		}
	},
	{#State 413
		DEFAULT => -292
	},
	{#State 414
		ACTIONS => {
			"-" => 248,
			"::" => 63,
			'TRUE' => 261,
			"+" => 262,
			"~" => 249,
			'INTEGER_LITERAL' => 263,
			'FLOATING_PT_LITERAL' => 265,
			'FALSE' => 251,
			'error' => 490,
			'WIDE_STRING_LITERAL' => 267,
			'CHARACTER_LITERAL' => 268,
			'IDENTIFIER' => 49,
			"(" => 258,
			'FIXED_PT_LITERAL' => 272,
			'STRING_LITERAL' => 119,
			'WIDE_CHARACTER_LITERAL' => 260
		},
		GOTOS => {
			'shift_expr' => 264,
			'literal' => 250,
			'const_exp' => 252,
			'unary_operator' => 253,
			'string_literal' => 254,
			'and_expr' => 255,
			'or_expr' => 256,
			'mult_expr' => 269,
			'scoped_name' => 257,
			'boolean_literal' => 270,
			'add_expr' => 271,
			'positive_int_const' => 491,
			'unary_expr' => 259,
			'primary_expr' => 274,
			'wide_string_literal' => 275,
			'xor_expr' => 276
		}
	},
	{#State 415
		ACTIONS => {
			"[" => 414
		},
		DEFAULT => -293,
		GOTOS => {
			'fixed_array_sizes' => 492,
			'fixed_array_size' => 415
		}
	},
	{#State 416
		ACTIONS => {
			'IDENTIFIER' => 326,
			'error' => 285
		},
		GOTOS => {
			'declarators' => 493,
			'array_declarator' => 329,
			'simple_declarator' => 325,
			'declarator' => 327,
			'complex_declarator' => 330
		}
	},
	{#State 417
		DEFAULT => -246
	},
	{#State 418
		DEFAULT => -277
	},
	{#State 419
		DEFAULT => -250
	},
	{#State 420
		ACTIONS => {
			"{" => 495,
			'error' => 494
		}
	},
	{#State 421
		ACTIONS => {
			'PROP_VALUE' => 496
		},
		DEFAULT => -402
	},
	{#State 422
		ACTIONS => {
			"<<" => 358,
			">>" => 357
		},
		DEFAULT => -140
	},
	{#State 423
		ACTIONS => {
			"^" => 367
		},
		DEFAULT => -136
	},
	{#State 424
		DEFAULT => -158
	},
	{#State 425
		DEFAULT => -159
	},
	{#State 426
		ACTIONS => {
			"-" => 364,
			"+" => 365
		},
		DEFAULT => -142
	},
	{#State 427
		ACTIONS => {
			"-" => 364,
			"+" => 365
		},
		DEFAULT => -143
	},
	{#State 428
		DEFAULT => -150
	},
	{#State 429
		DEFAULT => -148
	},
	{#State 430
		DEFAULT => -149
	},
	{#State 431
		ACTIONS => {
			"%" => 361,
			"*" => 362,
			"/" => 363
		},
		DEFAULT => -146
	},
	{#State 432
		ACTIONS => {
			"%" => 361,
			"*" => 362,
			"/" => 363
		},
		DEFAULT => -145
	},
	{#State 433
		ACTIONS => {
			"&" => 353
		},
		DEFAULT => -138
	},
	{#State 434
		ACTIONS => {
			">" => 497
		}
	},
	{#State 435
		ACTIONS => {
			">" => 498
		}
	},
	{#State 436
		ACTIONS => {
			">" => 499
		}
	},
	{#State 437
		ACTIONS => {
			">" => 500
		}
	},
	{#State 438
		ACTIONS => {
			'NATIVE_TYPE' => 501
		}
	},
	{#State 439
		ACTIONS => {
			"::" => 63,
			'IDENTIFIER' => 49,
			'error' => 503
		},
		GOTOS => {
			'interface_name' => 505,
			'interface_names' => 504,
			'scoped_name' => 502
		}
	},
	{#State 440
		DEFAULT => -38
	},
	{#State 441
		ACTIONS => {
			'TRUNCATABLE' => 507
		},
		DEFAULT => -92,
		GOTOS => {
			'inheritance_mod' => 506
		}
	},
	{#State 442
		ACTIONS => {
			"::" => 63,
			'IDENTIFIER' => 49,
			'error' => 508
		},
		GOTOS => {
			'interface_name' => 505,
			'interface_names' => 509,
			'scoped_name' => 502
		}
	},
	{#State 443
		DEFAULT => -84
	},
	{#State 444
		DEFAULT => -90
	},
	{#State 445
		DEFAULT => -76
	},
	{#State 446
		DEFAULT => -119
	},
	{#State 447
		DEFAULT => -120
	},
	{#State 448
		ACTIONS => {
			"::" => 140
		},
		DEFAULT => -350
	},
	{#State 449
		DEFAULT => -348
	},
	{#State 450
		DEFAULT => -313
	},
	{#State 451
		DEFAULT => -315
	},
	{#State 452
		DEFAULT => -349
	},
	{#State 453
		DEFAULT => -314
	},
	{#State 454
		DEFAULT => -312
	},
	{#State 455
		DEFAULT => -347
	},
	{#State 456
		ACTIONS => {
			'IDENTIFIER' => 510,
			'error' => 511
		}
	},
	{#State 457
		DEFAULT => -112
	},
	{#State 458
		DEFAULT => -113
	},
	{#State 459
		DEFAULT => -344
	},
	{#State 460
		DEFAULT => -346
	},
	{#State 461
		ACTIONS => {
			'IDENTIFIER' => 284,
			'error' => 285
		},
		GOTOS => {
			'attr_declarator' => 513,
			'simple_declarator' => 512
		}
	},
	{#State 462
		DEFAULT => -345
	},
	{#State 463
		DEFAULT => -343
	},
	{#State 464
		DEFAULT => -380
	},
	{#State 465
		ACTIONS => {
			'IDENTIFIER' => 326,
			'error' => 514
		},
		GOTOS => {
			'declarators' => 515,
			'array_declarator' => 329,
			'simple_declarator' => 325,
			'declarator' => 327,
			'complex_declarator' => 330
		}
	},
	{#State 466
		ACTIONS => {
			";" => 516
		}
	},
	{#State 467
		DEFAULT => -374
	},
	{#State 468
		ACTIONS => {
			"::" => 63,
			'CHAR' => 64,
			'OBJECT' => 68,
			'STRING' => 71,
			'OCTET' => 37,
			'WSTRING' => 73,
			'UNSIGNED' => 41,
			'error' => 518,
			'ANY' => 43,
			'FLOAT' => 76,
			'LONG' => 44,
			'SEQUENCE' => 78,
			'IDENTIFIER' => 49,
			'DOUBLE' => 79,
			'SHORT' => 80,
			'BOOLEAN' => 82,
			'VOID' => 459,
			'FIXED' => 85,
			'VALUEBASE' => 87,
			'WCHAR' => 60
		},
		GOTOS => {
			'wide_string_type' => 452,
			'object_type' => 65,
			'integer_type' => 67,
			'unsigned_int' => 69,
			'sequence_type' => 462,
			'op_param_type_spec' => 463,
			'unsigned_short_int' => 36,
			'unsigned_longlong_int' => 72,
			'floating_pt_type' => 75,
			'value_base_type' => 77,
			'signed_longlong_int' => 45,
			'any_type' => 47,
			'base_type_spec' => 455,
			'unsigned_long_int' => 50,
			'scoped_name' => 448,
			'signed_int' => 83,
			'string_type' => 449,
			'char_type' => 54,
			'signed_long_int' => 56,
			'fixed_pt_type' => 460,
			'signed_short_int' => 57,
			'param_type_spec' => 517,
			'boolean_type' => 86,
			'wide_char_type' => 59,
			'octet_type' => 61
		}
	},
	{#State 469
		DEFAULT => -324
	},
	{#State 470
		ACTIONS => {
			"::" => 63,
			'CHAR' => 64,
			'OBJECT' => 68,
			'STRING' => 71,
			'OCTET' => 37,
			'WSTRING' => 73,
			'UNSIGNED' => 41,
			'ANY' => 43,
			'FLOAT' => 76,
			'LONG' => 44,
			'SEQUENCE' => 78,
			'IDENTIFIER' => 49,
			'DOUBLE' => 79,
			'SHORT' => 80,
			'BOOLEAN' => 82,
			'VOID' => 459,
			'FIXED' => 85,
			'VALUEBASE' => 87,
			'WCHAR' => 60
		},
		GOTOS => {
			'wide_string_type' => 452,
			'object_type' => 65,
			'integer_type' => 67,
			'unsigned_int' => 69,
			'sequence_type' => 462,
			'op_param_type_spec' => 463,
			'unsigned_short_int' => 36,
			'unsigned_longlong_int' => 72,
			'floating_pt_type' => 75,
			'value_base_type' => 77,
			'signed_longlong_int' => 45,
			'any_type' => 47,
			'base_type_spec' => 455,
			'unsigned_long_int' => 50,
			'scoped_name' => 448,
			'signed_int' => 83,
			'string_type' => 449,
			'char_type' => 54,
			'signed_long_int' => 56,
			'fixed_pt_type' => 460,
			'signed_short_int' => 57,
			'param_type_spec' => 519,
			'boolean_type' => 86,
			'wide_char_type' => 59,
			'octet_type' => 61
		}
	},
	{#State 471
		DEFAULT => -328
	},
	{#State 472
		DEFAULT => -327
	},
	{#State 473
		DEFAULT => -326
	},
	{#State 474
		ACTIONS => {
			"[" => 42,
			")" => 521,
			"..." => 522
		},
		DEFAULT => -396,
		GOTOS => {
			'props' => 397,
			'param_dcl' => 520
		}
	},
	{#State 475
		DEFAULT => -316
	},
	{#State 476
		DEFAULT => -321
	},
	{#State 477
		DEFAULT => -320
	},
	{#State 478
		DEFAULT => -305
	},
	{#State 479
		ACTIONS => {
			"(" => 523,
			'error' => 524
		}
	},
	{#State 480
		ACTIONS => {
			"::" => 140
		},
		DEFAULT => -336
	},
	{#State 481
		ACTIONS => {
			")" => 525
		}
	},
	{#State 482
		ACTIONS => {
			")" => 526
		}
	},
	{#State 483
		ACTIONS => {
			"," => 527
		},
		DEFAULT => -334
	},
	{#State 484
		ACTIONS => {
			'IDENTIFIER' => 284,
			'error' => 285
		},
		GOTOS => {
			'simple_declarator' => 528
		}
	},
	{#State 485
		DEFAULT => -117
	},
	{#State 486
		ACTIONS => {
			'IN' => 411
		},
		GOTOS => {
			'init_param_decl' => 407,
			'init_param_decls' => 529,
			'init_param_attribute' => 406
		}
	},
	{#State 487
		DEFAULT => -110
	},
	{#State 488
		DEFAULT => -109
	},
	{#State 489
		DEFAULT => -245
	},
	{#State 490
		ACTIONS => {
			"]" => 530
		}
	},
	{#State 491
		ACTIONS => {
			"]" => 531
		}
	},
	{#State 492
		DEFAULT => -294
	},
	{#State 493
		DEFAULT => -209
	},
	{#State 494
		DEFAULT => -249
	},
	{#State 495
		ACTIONS => {
			'DEFAULT' => 537,
			'error' => 535,
			'CASE' => 532
		},
		GOTOS => {
			'case_label' => 538,
			'switch_body' => 533,
			'case' => 534,
			'case_labels' => 536
		}
	},
	{#State 496
		DEFAULT => -400
	},
	{#State 497
		DEFAULT => -282
	},
	{#State 498
		DEFAULT => -281
	},
	{#State 499
		DEFAULT => -352
	},
	{#State 500
		DEFAULT => -351
	},
	{#State 501
		DEFAULT => -182
	},
	{#State 502
		ACTIONS => {
			"::" => 140
		},
		DEFAULT => -59
	},
	{#State 503
		DEFAULT => -55
	},
	{#State 504
		DEFAULT => -54
	},
	{#State 505
		ACTIONS => {
			"," => 539
		},
		DEFAULT => -57
	},
	{#State 506
		ACTIONS => {
			"::" => 63,
			'IDENTIFIER' => 49,
			'error' => 543
		},
		GOTOS => {
			'value_name' => 540,
			'value_names' => 541,
			'scoped_name' => 542
		}
	},
	{#State 507
		DEFAULT => -91
	},
	{#State 508
		DEFAULT => -96
	},
	{#State 509
		DEFAULT => -95
	},
	{#State 510
		DEFAULT => -307
	},
	{#State 511
		DEFAULT => -308
	},
	{#State 512
		ACTIONS => {
			'SETRAISES' => 549,
			'GETRAISES' => 545,
			"," => 546
		},
		DEFAULT => -386,
		GOTOS => {
			'get_except_expr' => 547,
			'attr_raises_expr' => 544,
			'set_except_expr' => 548
		}
	},
	{#State 513
		DEFAULT => -379
	},
	{#State 514
		ACTIONS => {
			";" => 550,
			"," => 377
		}
	},
	{#State 515
		ACTIONS => {
			";" => 99,
			'error' => 100
		},
		GOTOS => {
			'check_semicolon' => 551
		}
	},
	{#State 516
		DEFAULT => -104
	},
	{#State 517
		ACTIONS => {
			'IDENTIFIER' => 284,
			'error' => 285
		},
		GOTOS => {
			'readonly_attr_declarator' => 552,
			'simple_declarator' => 553
		}
	},
	{#State 518
		DEFAULT => -373
	},
	{#State 519
		ACTIONS => {
			'IDENTIFIER' => 284,
			'error' => 285
		},
		GOTOS => {
			'simple_declarator' => 554
		}
	},
	{#State 520
		DEFAULT => -323
	},
	{#State 521
		DEFAULT => -318
	},
	{#State 522
		ACTIONS => {
			")" => 555
		}
	},
	{#State 523
		ACTIONS => {
			'STRING_LITERAL' => 119,
			'error' => 558
		},
		GOTOS => {
			'string_literals' => 557,
			'string_literal' => 556
		}
	},
	{#State 524
		DEFAULT => -339
	},
	{#State 525
		DEFAULT => -331
	},
	{#State 526
		DEFAULT => -330
	},
	{#State 527
		ACTIONS => {
			"::" => 63,
			'IDENTIFIER' => 49
		},
		GOTOS => {
			'exception_names' => 559,
			'scoped_name' => 480,
			'exception_name' => 483
		}
	},
	{#State 528
		DEFAULT => -116
	},
	{#State 529
		DEFAULT => -115
	},
	{#State 530
		DEFAULT => -296
	},
	{#State 531
		DEFAULT => -295
	},
	{#State 532
		ACTIONS => {
			"-" => 248,
			"::" => 63,
			'TRUE' => 261,
			"+" => 262,
			"~" => 249,
			'INTEGER_LITERAL' => 263,
			'FLOATING_PT_LITERAL' => 265,
			'FALSE' => 251,
			'error' => 561,
			'WIDE_STRING_LITERAL' => 267,
			'CHARACTER_LITERAL' => 268,
			'IDENTIFIER' => 49,
			"(" => 258,
			'FIXED_PT_LITERAL' => 272,
			'STRING_LITERAL' => 119,
			'WIDE_CHARACTER_LITERAL' => 260
		},
		GOTOS => {
			'and_expr' => 255,
			'or_expr' => 256,
			'mult_expr' => 269,
			'shift_expr' => 264,
			'scoped_name' => 257,
			'boolean_literal' => 270,
			'add_expr' => 271,
			'literal' => 250,
			'primary_expr' => 274,
			'unary_expr' => 259,
			'unary_operator' => 253,
			'const_exp' => 560,
			'xor_expr' => 276,
			'wide_string_literal' => 275,
			'string_literal' => 254
		}
	},
	{#State 533
		ACTIONS => {
			"}" => 562
		}
	},
	{#State 534
		ACTIONS => {
			'DEFAULT' => 537,
			'CASE' => 532
		},
		DEFAULT => -259,
		GOTOS => {
			'case_label' => 538,
			'switch_body' => 563,
			'case' => 534,
			'case_labels' => 536
		}
	},
	{#State 535
		ACTIONS => {
			"}" => 564
		}
	},
	{#State 536
		ACTIONS => {
			"[" => 42
		},
		DEFAULT => -396,
		GOTOS => {
			'union_type' => 34,
			'enum_type' => 46,
			'element_spec' => 565,
			'enum_header' => 35,
			'struct_type' => 38,
			'union_header' => 39,
			'constr_type_spec' => 567,
			'props' => 566,
			'struct_header' => 40
		}
	},
	{#State 537
		ACTIONS => {
			":" => 568,
			'error' => 569
		}
	},
	{#State 538
		ACTIONS => {
			'CASE' => 532,
			'DEFAULT' => 537
		},
		DEFAULT => -262,
		GOTOS => {
			'case_label' => 538,
			'case_labels' => 570
		}
	},
	{#State 539
		ACTIONS => {
			"::" => 63,
			'IDENTIFIER' => 49
		},
		GOTOS => {
			'interface_name' => 505,
			'interface_names' => 571,
			'scoped_name' => 502
		}
	},
	{#State 540
		ACTIONS => {
			"," => 572
		},
		DEFAULT => -93
	},
	{#State 541
		ACTIONS => {
			'SUPPORTS' => 442
		},
		DEFAULT => -97,
		GOTOS => {
			'supported_interface_spec' => 573
		}
	},
	{#State 542
		ACTIONS => {
			"::" => 140
		},
		DEFAULT => -98
	},
	{#State 543
		DEFAULT => -89
	},
	{#State 544
		DEFAULT => -381
	},
	{#State 545
		ACTIONS => {
			"(" => 575,
			'error' => 576
		},
		GOTOS => {
			'exception_list' => 574
		}
	},
	{#State 546
		ACTIONS => {
			'IDENTIFIER' => 284,
			'error' => 285
		},
		GOTOS => {
			'simple_declarators' => 578,
			'simple_declarator' => 577
		}
	},
	{#State 547
		ACTIONS => {
			'SETRAISES' => 549
		},
		DEFAULT => -384,
		GOTOS => {
			'set_except_expr' => 579
		}
	},
	{#State 548
		DEFAULT => -385
	},
	{#State 549
		ACTIONS => {
			"(" => 575,
			'error' => 581
		},
		GOTOS => {
			'exception_list' => 580
		}
	},
	{#State 550
		ACTIONS => {
			";" => -214,
			"," => -214,
			'error' => -214
		},
		DEFAULT => -103
	},
	{#State 551
		DEFAULT => -102
	},
	{#State 552
		DEFAULT => -372
	},
	{#State 553
		ACTIONS => {
			'RAISES' => 307,
			"," => 582
		},
		DEFAULT => -333,
		GOTOS => {
			'raises_expr' => 583
		}
	},
	{#State 554
		DEFAULT => -325
	},
	{#State 555
		DEFAULT => -317
	},
	{#State 556
		ACTIONS => {
			"," => 584
		},
		DEFAULT => -341
	},
	{#State 557
		ACTIONS => {
			")" => 585
		}
	},
	{#State 558
		ACTIONS => {
			")" => 586
		}
	},
	{#State 559
		DEFAULT => -335
	},
	{#State 560
		ACTIONS => {
			":" => 587,
			'error' => 588
		}
	},
	{#State 561
		DEFAULT => -266
	},
	{#State 562
		DEFAULT => -247
	},
	{#State 563
		DEFAULT => -260
	},
	{#State 564
		DEFAULT => -248
	},
	{#State 565
		ACTIONS => {
			";" => 99,
			'error' => 100
		},
		GOTOS => {
			'check_semicolon' => 589
		}
	},
	{#State 566
		ACTIONS => {
			'ENUM' => 142,
			"::" => 63,
			'CHAR' => 64,
			'OBJECT' => 68,
			'STRING' => 71,
			'OCTET' => 37,
			'WSTRING' => 73,
			'UNION' => 143,
			'UNSIGNED' => 41,
			'ANY' => 43,
			'FLOAT' => 76,
			'LONG' => 44,
			'SEQUENCE' => 78,
			'IDENTIFIER' => 49,
			'DOUBLE' => 79,
			'SHORT' => 80,
			'BOOLEAN' => 82,
			'STRUCT' => 141,
			'VOID' => 55,
			'FIXED' => 85,
			'VALUEBASE' => 87,
			'WCHAR' => 60
		},
		GOTOS => {
			'wide_string_type' => 62,
			'object_type' => 65,
			'integer_type' => 67,
			'sequence_type' => 70,
			'unsigned_int' => 69,
			'unsigned_short_int' => 36,
			'unsigned_longlong_int' => 72,
			'floating_pt_type' => 75,
			'value_base_type' => 77,
			'signed_longlong_int' => 45,
			'any_type' => 47,
			'template_type_spec' => 48,
			'base_type_spec' => 81,
			'unsigned_long_int' => 50,
			'scoped_name' => 51,
			'signed_int' => 83,
			'string_type' => 52,
			'simple_type_spec' => 590,
			'char_type' => 54,
			'signed_short_int' => 57,
			'signed_long_int' => 56,
			'fixed_pt_type' => 58,
			'boolean_type' => 86,
			'wide_char_type' => 59,
			'octet_type' => 61
		}
	},
	{#State 567
		ACTIONS => {
			'IDENTIFIER' => 326,
			'error' => 285
		},
		GOTOS => {
			'array_declarator' => 329,
			'simple_declarator' => 325,
			'declarator' => 591,
			'complex_declarator' => 330
		}
	},
	{#State 568
		DEFAULT => -267
	},
	{#State 569
		DEFAULT => -268
	},
	{#State 570
		DEFAULT => -263
	},
	{#State 571
		DEFAULT => -58
	},
	{#State 572
		ACTIONS => {
			"::" => 63,
			'IDENTIFIER' => 49
		},
		GOTOS => {
			'value_name' => 540,
			'value_names' => 592,
			'scoped_name' => 542
		}
	},
	{#State 573
		DEFAULT => -88
	},
	{#State 574
		DEFAULT => -387
	},
	{#State 575
		ACTIONS => {
			"::" => 63,
			'IDENTIFIER' => 49,
			'error' => 593
		},
		GOTOS => {
			'exception_names' => 594,
			'scoped_name' => 480,
			'exception_name' => 483
		}
	},
	{#State 576
		DEFAULT => -388
	},
	{#State 577
		ACTIONS => {
			"," => 595
		},
		DEFAULT => -377
	},
	{#State 578
		DEFAULT => -382
	},
	{#State 579
		DEFAULT => -383
	},
	{#State 580
		DEFAULT => -389
	},
	{#State 581
		DEFAULT => -390
	},
	{#State 582
		ACTIONS => {
			'IDENTIFIER' => 284,
			'error' => 285
		},
		GOTOS => {
			'simple_declarators' => 596,
			'simple_declarator' => 577
		}
	},
	{#State 583
		DEFAULT => -375
	},
	{#State 584
		ACTIONS => {
			'STRING_LITERAL' => 119
		},
		GOTOS => {
			'string_literals' => 597,
			'string_literal' => 556
		}
	},
	{#State 585
		DEFAULT => -337
	},
	{#State 586
		DEFAULT => -338
	},
	{#State 587
		DEFAULT => -264
	},
	{#State 588
		DEFAULT => -265
	},
	{#State 589
		DEFAULT => -261
	},
	{#State 590
		ACTIONS => {
			'IDENTIFIER' => 326,
			'error' => 285
		},
		GOTOS => {
			'array_declarator' => 329,
			'simple_declarator' => 325,
			'declarator' => 598,
			'complex_declarator' => 330
		}
	},
	{#State 591
		DEFAULT => -270
	},
	{#State 592
		DEFAULT => -94
	},
	{#State 593
		ACTIONS => {
			")" => 599
		}
	},
	{#State 594
		ACTIONS => {
			")" => 600
		}
	},
	{#State 595
		ACTIONS => {
			'IDENTIFIER' => 284,
			'error' => 285
		},
		GOTOS => {
			'simple_declarators' => 601,
			'simple_declarator' => 577
		}
	},
	{#State 596
		DEFAULT => -376
	},
	{#State 597
		DEFAULT => -342
	},
	{#State 598
		DEFAULT => -269
	},
	{#State 599
		DEFAULT => -392
	},
	{#State 600
		DEFAULT => -391
	},
	{#State 601
		DEFAULT => -378
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
#line 79 "ParserXp.yp"
{
            $_[0]->YYData->{root} = new CORBA::IDL::Specification($_[0],
                    'list_decl'         =>  $_[1],
            );
        }
	],
	[#Rule 2
		 'specification', 2,
sub
#line 85 "ParserXp.yp"
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
#line 92 "ParserXp.yp"
{
            $_[0]->Error("Empty specification.\n");
        }
	],
	[#Rule 4
		 'specification', 1,
sub
#line 96 "ParserXp.yp"
{
            $_[0]->Error("definition declaration expected.\n");
        }
	],
	[#Rule 5
		 'imports', 1,
sub
#line 103 "ParserXp.yp"
{
            [$_[1]];
        }
	],
	[#Rule 6
		 'imports', 2,
sub
#line 107 "ParserXp.yp"
{
            unshift @{$_[2]}, $_[1];
            $_[2];
        }
	],
	[#Rule 7
		 'definitions', 1,
sub
#line 115 "ParserXp.yp"
{
            [$_[1]->getRef()];
        }
	],
	[#Rule 8
		 'definitions', 2,
sub
#line 119 "ParserXp.yp"
{
            unshift @{$_[2]}, $_[1]->getRef();
            $_[2];
        }
	],
	[#Rule 9
		 'definitions', 3,
sub
#line 124 "ParserXp.yp"
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
		 'definition', 1, undef
	],
	[#Rule 19
		 'definition', 3,
sub
#line 152 "ParserXp.yp"
{
            # when IDENTIFIER is a future keyword
            $_[0]->Error("'$_[1]' unexpected.\n");
            $_[0]->YYErrok();
            new CORBA::IDL::Node($_[0],
                    'idf'                   =>  $_[1]
            );
        }
	],
	[#Rule 20
		 'check_semicolon', 1, undef
	],
	[#Rule 21
		 'check_semicolon', 1,
sub
#line 166 "ParserXp.yp"
{
            $_[0]->Warning("';' expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 22
		 'module', 4,
sub
#line 175 "ParserXp.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
            $_[1]->Configure($_[0],
                    'list_decl'         =>  $_[3]
            ) if (defined $_[1]);
        }
	],
	[#Rule 23
		 'module', 4,
sub
#line 182 "ParserXp.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
            $_[0]->Error("definition declaration expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 24
		 'module', 3,
sub
#line 189 "ParserXp.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
            $_[0]->Error("Empty module.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 25
		 'module', 3,
sub
#line 196 "ParserXp.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
            $_[0]->Error("'\x7b' expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 26
		 'module_header', 3,
sub
#line 206 "ParserXp.yp"
{
            new CORBA::IDL::Module($_[0],
                    'declspec'          =>  $_[1],
                    'idf'               =>  $_[3],
            );
        }
	],
	[#Rule 27
		 'module_header', 3,
sub
#line 213 "ParserXp.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 28
		 'interface', 1, undef
	],
	[#Rule 29
		 'interface', 1, undef
	],
	[#Rule 30
		 'interface_dcl', 3,
sub
#line 230 "ParserXp.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->YYData->{curr_itf} = undef;
            $_[1]->Configure($_[0],
                    'list_decl'     =>  []
            ) if (defined $_[1]);
        }
	],
	[#Rule 31
		 'interface_dcl', 4,
sub
#line 238 "ParserXp.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->YYData->{curr_itf} = undef;
            $_[1]->Configure($_[0],
                    'list_decl'     =>  $_[3]
            ) if (defined $_[1]);
        }
	],
	[#Rule 32
		 'interface_dcl', 4,
sub
#line 246 "ParserXp.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->YYData->{curr_itf} = undef;
            $_[0]->Error("export declaration expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 33
		 'forward_dcl', 5,
sub
#line 258 "ParserXp.yp"
{
            $_[0]->Warning("Ignoring properties for forward declaration.\n")
                    if (defined $_[2]);
            if (defined $_[3] and $_[3] eq 'abstract') {
                new CORBA::IDL::ForwardAbstractInterface($_[0],
                        'declspec'              =>  $_[1],
                        'idf'                   =>  $_[5]
                );
            }
            elsif (defined $_[3] and $_[3] eq 'local') {
                new CORBA::IDL::ForwardLocalInterface($_[0],
                        'declspec'              =>  $_[1],
                        'idf'                   =>  $_[5]
                );
            }
            else {
                new CORBA::IDL::ForwardRegularInterface($_[0],
                        'declspec'              =>  $_[1],
                        'idf'                   =>  $_[5]
                );
            }
        }
	],
	[#Rule 34
		 'forward_dcl', 5,
sub
#line 281 "ParserXp.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 35
		 'interface_mod', 1, undef
	],
	[#Rule 36
		 'interface_mod', 1, undef
	],
	[#Rule 37
		 'interface_mod', 0, undef
	],
	[#Rule 38
		 'interface_header', 6,
sub
#line 299 "ParserXp.yp"
{
            if (defined $_[3] and $_[3] eq 'abstract') {
                new CORBA::IDL::AbstractInterface($_[0],
                        'declspec'              =>  $_[1],
                        'props'                 =>  $_[2],
                        'idf'                   =>  $_[5],
                        'inheritance'           =>  $_[6]
                );
            }
            elsif (defined $_[3] and $_[3] eq 'local') {
                new CORBA::IDL::LocalInterface($_[0],
                        'declspec'              =>  $_[1],
                        'props'                 =>  $_[2],
                        'idf'                   =>  $_[5],
                        'inheritance'           =>  $_[6]
                );
            }
            else {
                new CORBA::IDL::RegularInterface($_[0],
                        'declspec'              =>  $_[1],
                        'props'                 =>  $_[2],
                        'idf'                   =>  $_[5],
                        'inheritance'           =>  $_[6]
                );
            }
        }
	],
	[#Rule 39
		 'interface_header', 5,
sub
#line 326 "ParserXp.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 40
		 'interface_body', 1, undef
	],
	[#Rule 41
		 'exports', 1,
sub
#line 340 "ParserXp.yp"
{
            [$_[1]->getRef()];
        }
	],
	[#Rule 42
		 'exports', 2,
sub
#line 344 "ParserXp.yp"
{
            unshift @{$_[2]}, $_[1]->getRef();
            $_[2];
        }
	],
	[#Rule 43
		 '_export', 1, undef
	],
	[#Rule 44
		 '_export', 1,
sub
#line 355 "ParserXp.yp"
{
            $_[0]->Error("state member unexpected.\n");
            $_[1];                      #default action
        }
	],
	[#Rule 45
		 '_export', 1,
sub
#line 360 "ParserXp.yp"
{
            $_[0]->Error("initializer unexpected.\n");
            $_[1];                      #default action
        }
	],
	[#Rule 46
		 'export', 2, undef
	],
	[#Rule 47
		 'export', 2, undef
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
		 'export', 1, undef
	],
	[#Rule 54
		 'interface_inheritance_spec', 2,
sub
#line 388 "ParserXp.yp"
{
            new CORBA::IDL::InheritanceSpec($_[0],
                    'list_interface'        =>  $_[2]
            );
        }
	],
	[#Rule 55
		 'interface_inheritance_spec', 2,
sub
#line 394 "ParserXp.yp"
{
            $_[0]->Error("Interface name expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 56
		 'interface_inheritance_spec', 0, undef
	],
	[#Rule 57
		 'interface_names', 1,
sub
#line 404 "ParserXp.yp"
{
            [$_[1]];
        }
	],
	[#Rule 58
		 'interface_names', 3,
sub
#line 408 "ParserXp.yp"
{
            unshift @{$_[3]}, $_[1];
            $_[3];
        }
	],
	[#Rule 59
		 'interface_name', 1,
sub
#line 417 "ParserXp.yp"
{
                CORBA::IDL::Interface->Lookup($_[0], $_[1]);
        }
	],
	[#Rule 60
		 'scoped_name', 1, undef
	],
	[#Rule 61
		 'scoped_name', 2,
sub
#line 427 "ParserXp.yp"
{
            $_[1] . $_[2];
        }
	],
	[#Rule 62
		 'scoped_name', 2,
sub
#line 431 "ParserXp.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
            '';
        }
	],
	[#Rule 63
		 'scoped_name', 3,
sub
#line 437 "ParserXp.yp"
{
            $_[1] . $_[2] . $_[3];
        }
	],
	[#Rule 64
		 'scoped_name', 3,
sub
#line 441 "ParserXp.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 65
		 'value', 1, undef
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
		 'value_forward_dcl', 5,
sub
#line 463 "ParserXp.yp"
{
            $_[0]->Warning("Ignoring properties for forward declaration.\n")
                    if (defined $_[2]);
            $_[0]->Warning("CUSTOM unexpected.\n")
                    if (defined $_[3]);
            new CORBA::IDL::ForwardRegularValue($_[0],
                    'declspec'          =>  $_[1],
                    'idf'               =>  $_[4]
            );
        }
	],
	[#Rule 70
		 'value_forward_dcl', 5,
sub
#line 474 "ParserXp.yp"
{
            $_[0]->Warning("Ignoring properties for forward declaration.\n")
                    if (defined $_[2]);
            new CORBA::IDL::ForwardAbstractValue($_[0],
                    'declspec'          =>  $_[1],
                    'idf'               =>  $_[5]
            );
        }
	],
	[#Rule 71
		 'value_box_dcl', 2,
sub
#line 487 "ParserXp.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->YYData->{curr_itf} = undef;
            $_[1]->Configure($_[0],
                    'type'              =>  $_[2]
            ) if (defined $_[1]);
        }
	],
	[#Rule 72
		 'value_box_header', 5,
sub
#line 498 "ParserXp.yp"
{
            $_[0]->Warning("CUSTOM unexpected.\n")
                    if (defined $_[3]);
            new CORBA::IDL::BoxedValue($_[0],
                    'declspec'          =>  $_[1],
                    'props'             =>  $_[2],
                    'idf'               =>  $_[4],
            );
        }
	],
	[#Rule 73
		 'value_abs_dcl', 3,
sub
#line 512 "ParserXp.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->YYData->{curr_itf} = undef;
            $_[1]->Configure($_[0],
                    'list_decl'     =>  []
            ) if (defined $_[1]);
        }
	],
	[#Rule 74
		 'value_abs_dcl', 4,
sub
#line 520 "ParserXp.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->YYData->{curr_itf} = undef;
            $_[1]->Configure($_[0],
                    'list_decl'     =>  $_[3]
            ) if (defined $_[1]);
        }
	],
	[#Rule 75
		 'value_abs_dcl', 4,
sub
#line 528 "ParserXp.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->YYData->{curr_itf} = undef;
            $_[0]->Error("export declaration expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 76
		 'value_abs_header', 6,
sub
#line 539 "ParserXp.yp"
{
            new CORBA::IDL::AbstractValue($_[0],
                    'declspec'          =>  $_[1],
                    'props'             =>  $_[2],
                    'idf'               =>  $_[5],
                    'inheritance'       =>  $_[6]
            );
        }
	],
	[#Rule 77
		 'value_abs_header', 5,
sub
#line 548 "ParserXp.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 78
		 'value_abs_header', 4,
sub
#line 553 "ParserXp.yp"
{
            $_[0]->Error("'valuetype' expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 79
		 'value_dcl', 3,
sub
#line 562 "ParserXp.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->YYData->{curr_itf} = undef;
            $_[1]->Configure($_[0],
                    'list_decl'     =>  []
            ) if (defined $_[1]);
        }
	],
	[#Rule 80
		 'value_dcl', 4,
sub
#line 570 "ParserXp.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->YYData->{curr_itf} = undef;
            $_[1]->Configure($_[0],
                    'list_decl'     =>  $_[3]
            ) if (defined $_[1]);
        }
	],
	[#Rule 81
		 'value_dcl', 4,
sub
#line 578 "ParserXp.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->YYData->{curr_itf} = undef;
            $_[0]->Error("value_element expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 82
		 'value_elements', 1,
sub
#line 589 "ParserXp.yp"
{
            [$_[1]->getRef()];
        }
	],
	[#Rule 83
		 'value_elements', 2,
sub
#line 593 "ParserXp.yp"
{
            unshift @{$_[2]}, $_[1]->getRef();
            $_[2];
        }
	],
	[#Rule 84
		 'value_header', 6,
sub
#line 602 "ParserXp.yp"
{
            new CORBA::IDL::RegularValue($_[0],
                    'declspec'          =>  $_[1],
                    'props'             =>  $_[2],
                    'modifier'          =>  $_[3],
                    'idf'               =>  $_[5],
                    'inheritance'       =>  $_[6]
            );
        }
	],
	[#Rule 85
		 'value_header', 5,
sub
#line 612 "ParserXp.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 86
		 'value_mod', 1, undef
	],
	[#Rule 87
		 'value_mod', 0, undef
	],
	[#Rule 88
		 'value_inheritance_spec', 4,
sub
#line 628 "ParserXp.yp"
{
            new CORBA::IDL::InheritanceSpec($_[0],
                    'modifier'          =>  $_[2],
                    'list_value'        =>  $_[3],
                    'list_interface'    =>  $_[4]
            );
        }
	],
	[#Rule 89
		 'value_inheritance_spec', 3,
sub
#line 636 "ParserXp.yp"
{
            $_[0]->Error("value_name expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 90
		 'value_inheritance_spec', 1,
sub
#line 641 "ParserXp.yp"
{
            new CORBA::IDL::InheritanceSpec($_[0],
                    'list_interface'    =>  $_[1]
            );
        }
	],
	[#Rule 91
		 'inheritance_mod', 1, undef
	],
	[#Rule 92
		 'inheritance_mod', 0, undef
	],
	[#Rule 93
		 'value_names', 1,
sub
#line 657 "ParserXp.yp"
{
            [$_[1]];
        }
	],
	[#Rule 94
		 'value_names', 3,
sub
#line 661 "ParserXp.yp"
{
            unshift @{$_[3]}, $_[1];
            $_[3];
        }
	],
	[#Rule 95
		 'supported_interface_spec', 2,
sub
#line 669 "ParserXp.yp"
{
            $_[2];
        }
	],
	[#Rule 96
		 'supported_interface_spec', 2,
sub
#line 673 "ParserXp.yp"
{
            $_[0]->Error("Interface name expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 97
		 'supported_interface_spec', 0, undef
	],
	[#Rule 98
		 'value_name', 1,
sub
#line 684 "ParserXp.yp"
{
            CORBA::IDL::Value->Lookup($_[0], $_[1]);
        }
	],
	[#Rule 99
		 'value_element', 1, undef
	],
	[#Rule 100
		 'value_element', 1, undef
	],
	[#Rule 101
		 'value_element', 1, undef
	],
	[#Rule 102
		 'state_member', 6,
sub
#line 702 "ParserXp.yp"
{
            new CORBA::IDL::StateMembers($_[0],
                    'declspec'          =>  $_[1],
                    'props'             =>  $_[2],
                    'modifier'          =>  $_[3],
                    'type'              =>  $_[4],
                    'list_expr'         =>  $_[5]
            );
        }
	],
	[#Rule 103
		 'state_member', 6,
sub
#line 712 "ParserXp.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 104
		 'state_member', 5,
sub
#line 717 "ParserXp.yp"
{
            $_[0]->Error("type_spec expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 105
		 'state_mod', 1, undef
	],
	[#Rule 106
		 'state_mod', 1, undef
	],
	[#Rule 107
		 'init_dcl', 3,
sub
#line 733 "ParserXp.yp"
{
            $_[1]->Configure($_[0],
                    'list_raise'    =>  $_[2]
            ) if (defined $_[1]);
        }
	],
	[#Rule 108
		 'init_header_param', 3,
sub
#line 742 "ParserXp.yp"
{
            delete $_[0]->YYData->{unnamed_symbtab}
                    if (exists $_[0]->YYData->{unnamed_symbtab});
            $_[1];                      #default action
        }
	],
	[#Rule 109
		 'init_header_param', 4,
sub
#line 748 "ParserXp.yp"
{
            delete $_[0]->YYData->{unnamed_symbtab}
                    if (exists $_[0]->YYData->{unnamed_symbtab});
            $_[1]->Configure($_[0],
                    'list_param'    =>  $_[3]
            ) if (defined $_[1]);
        }
	],
	[#Rule 110
		 'init_header_param', 4,
sub
#line 756 "ParserXp.yp"
{
            delete $_[0]->YYData->{unnamed_symbtab}
                    if (exists $_[0]->YYData->{unnamed_symbtab});
            $_[0]->Error("init_param_decls expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 111
		 'init_header_param', 2,
sub
#line 764 "ParserXp.yp"
{
            delete $_[0]->YYData->{unnamed_symbtab}
                    if (exists $_[0]->YYData->{unnamed_symbtab});
            $_[0]->Error("'(' expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 112
		 'init_header', 4,
sub
#line 775 "ParserXp.yp"
{
            new CORBA::IDL::Initializer($_[0],                      # like Operation
                    'declspec'          =>  $_[1],
                    'props'             =>  $_[2],
                    'idf'               =>  $_[4]
            );
        }
	],
	[#Rule 113
		 'init_header', 4,
sub
#line 783 "ParserXp.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 114
		 'init_param_decls', 1,
sub
#line 792 "ParserXp.yp"
{
            [$_[1]];
        }
	],
	[#Rule 115
		 'init_param_decls', 3,
sub
#line 796 "ParserXp.yp"
{
            unshift @{$_[3]}, $_[1];
            $_[3];
        }
	],
	[#Rule 116
		 'init_param_decl', 3,
sub
#line 805 "ParserXp.yp"
{
            new CORBA::IDL::Parameter($_[0],
                    'attr'              =>  $_[1],
                    'type'              =>  $_[2],
                    'idf'               =>  $_[3]
            );
        }
	],
	[#Rule 117
		 'init_param_decl', 2,
sub
#line 813 "ParserXp.yp"
{
            $_[0]->Error("Type expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 118
		 'init_param_attribute', 1, undef
	],
	[#Rule 119
		 'const_dcl', 6,
sub
#line 828 "ParserXp.yp"
{
            new CORBA::IDL::Constant($_[0],
                    'declspec'          =>  $_[1],
                    'type'              =>  $_[3],
                    'idf'               =>  $_[4],
                    'list_expr'         =>  $_[6]
            );
        }
	],
	[#Rule 120
		 'const_dcl', 6,
sub
#line 837 "ParserXp.yp"
{
            $_[0]->Error("Expression expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 121
		 'const_dcl', 5,
sub
#line 842 "ParserXp.yp"
{
            $_[0]->Error("'=' expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 122
		 'const_dcl', 4,
sub
#line 847 "ParserXp.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 123
		 'const_dcl', 3,
sub
#line 852 "ParserXp.yp"
{
            $_[0]->Error("const_type expected.\n");
            $_[0]->YYErrok();
        }
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
		 'const_type', 1, undef
	],
	[#Rule 131
		 'const_type', 1, undef
	],
	[#Rule 132
		 'const_type', 1,
sub
#line 877 "ParserXp.yp"
{
            CORBA::IDL::TypeDeclarator->Lookup($_[0], $_[1]);
        }
	],
	[#Rule 133
		 'const_type', 1, undef
	],
	[#Rule 134
		 'const_exp', 1, undef
	],
	[#Rule 135
		 'or_expr', 1, undef
	],
	[#Rule 136
		 'or_expr', 3,
sub
#line 895 "ParserXp.yp"
{
            BuildBinop($_[1], $_[2], $_[3]);
        }
	],
	[#Rule 137
		 'xor_expr', 1, undef
	],
	[#Rule 138
		 'xor_expr', 3,
sub
#line 905 "ParserXp.yp"
{
            BuildBinop($_[1], $_[2], $_[3]);
        }
	],
	[#Rule 139
		 'and_expr', 1, undef
	],
	[#Rule 140
		 'and_expr', 3,
sub
#line 915 "ParserXp.yp"
{
            BuildBinop($_[1], $_[2], $_[3]);
        }
	],
	[#Rule 141
		 'shift_expr', 1, undef
	],
	[#Rule 142
		 'shift_expr', 3,
sub
#line 925 "ParserXp.yp"
{
            BuildBinop($_[1], $_[2], $_[3]);
        }
	],
	[#Rule 143
		 'shift_expr', 3,
sub
#line 929 "ParserXp.yp"
{
            BuildBinop($_[1], $_[2], $_[3]);
        }
	],
	[#Rule 144
		 'add_expr', 1, undef
	],
	[#Rule 145
		 'add_expr', 3,
sub
#line 939 "ParserXp.yp"
{
            BuildBinop($_[1], $_[2], $_[3]);
        }
	],
	[#Rule 146
		 'add_expr', 3,
sub
#line 943 "ParserXp.yp"
{
            BuildBinop($_[1], $_[2], $_[3]);
        }
	],
	[#Rule 147
		 'mult_expr', 1, undef
	],
	[#Rule 148
		 'mult_expr', 3,
sub
#line 953 "ParserXp.yp"
{
            BuildBinop($_[1], $_[2], $_[3]);
        }
	],
	[#Rule 149
		 'mult_expr', 3,
sub
#line 957 "ParserXp.yp"
{
            BuildBinop($_[1], $_[2], $_[3]);
        }
	],
	[#Rule 150
		 'mult_expr', 3,
sub
#line 961 "ParserXp.yp"
{
            BuildBinop($_[1], $_[2], $_[3]);
        }
	],
	[#Rule 151
		 'unary_expr', 2,
sub
#line 969 "ParserXp.yp"
{
            BuildUnop($_[1], $_[2]);
        }
	],
	[#Rule 152
		 'unary_expr', 1, undef
	],
	[#Rule 153
		 'unary_operator', 1, undef
	],
	[#Rule 154
		 'unary_operator', 1, undef
	],
	[#Rule 155
		 'unary_operator', 1, undef
	],
	[#Rule 156
		 'primary_expr', 1,
sub
#line 989 "ParserXp.yp"
{
            [
                CORBA::IDL::Constant->Lookup($_[0], $_[1])
            ];
        }
	],
	[#Rule 157
		 'primary_expr', 1,
sub
#line 995 "ParserXp.yp"
{
            [ $_[1] ];
        }
	],
	[#Rule 158
		 'primary_expr', 3,
sub
#line 999 "ParserXp.yp"
{
            $_[2];
        }
	],
	[#Rule 159
		 'primary_expr', 3,
sub
#line 1003 "ParserXp.yp"
{
            $_[0]->Error("Expression expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 160
		 'literal', 1,
sub
#line 1012 "ParserXp.yp"
{
            new CORBA::IDL::IntegerLiteral($_[0],
                    'value'             =>  $_[1],
                    'lexeme'            =>  $_[0]->YYData->{lexeme}
            );
        }
	],
	[#Rule 161
		 'literal', 1,
sub
#line 1019 "ParserXp.yp"
{
            new CORBA::IDL::StringLiteral($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 162
		 'literal', 1,
sub
#line 1025 "ParserXp.yp"
{
            new CORBA::IDL::WideStringLiteral($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 163
		 'literal', 1,
sub
#line 1031 "ParserXp.yp"
{
            new CORBA::IDL::CharacterLiteral($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 164
		 'literal', 1,
sub
#line 1037 "ParserXp.yp"
{
            new CORBA::IDL::WideCharacterLiteral($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 165
		 'literal', 1,
sub
#line 1043 "ParserXp.yp"
{
            new CORBA::IDL::FixedPtLiteral($_[0],
                    'value'             =>  $_[1],
                    'lexeme'            =>  $_[0]->YYData->{lexeme}
            );
        }
	],
	[#Rule 166
		 'literal', 1,
sub
#line 1050 "ParserXp.yp"
{
            new CORBA::IDL::FloatingPtLiteral($_[0],
                    'value'             =>  $_[1],
                    'lexeme'            =>  $_[0]->YYData->{lexeme}
            );
        }
	],
	[#Rule 167
		 'literal', 1, undef
	],
	[#Rule 168
		 'string_literal', 1, undef
	],
	[#Rule 169
		 'string_literal', 2,
sub
#line 1064 "ParserXp.yp"
{
            $_[1] . $_[2];
        }
	],
	[#Rule 170
		 'wide_string_literal', 1, undef
	],
	[#Rule 171
		 'wide_string_literal', 2,
sub
#line 1073 "ParserXp.yp"
{
            $_[1] . $_[2];
        }
	],
	[#Rule 172
		 'boolean_literal', 1,
sub
#line 1081 "ParserXp.yp"
{
            new CORBA::IDL::BooleanLiteral($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 173
		 'boolean_literal', 1,
sub
#line 1087 "ParserXp.yp"
{
            new CORBA::IDL::BooleanLiteral($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 174
		 'positive_int_const', 1,
sub
#line 1097 "ParserXp.yp"
{
            new CORBA::IDL::Expression($_[0],
                    'list_expr'         =>  $_[1]
            );
        }
	],
	[#Rule 175
		 'type_dcl', 2,
sub
#line 1107 "ParserXp.yp"
{
            $_[2]->Configure($_[0],
                    'declspec'          =>  $_[1]
            ) if ($_[2]);
        }
	],
	[#Rule 176
		 'type_dcl_def', 3,
sub
#line 1116 "ParserXp.yp"
{
            $_[3]->Configure($_[0],
                    'props'             =>  $_[1]
            );
        }
	],
	[#Rule 177
		 'type_dcl_def', 1, undef
	],
	[#Rule 178
		 'type_dcl_def', 1, undef
	],
	[#Rule 179
		 'type_dcl_def', 1, undef
	],
	[#Rule 180
		 'type_dcl_def', 3,
sub
#line 1128 "ParserXp.yp"
{
            new CORBA::IDL::NativeType($_[0],
                    'props'             =>  $_[1],
                    'idf'               =>  $_[3],
            );
        }
	],
	[#Rule 181
		 '@1-4', 0,
sub
#line 1135 "ParserXp.yp"
{
            $_[0]->YYData->{native} = 1;
        }
	],
	[#Rule 182
		 'type_dcl_def', 6,
sub
#line 1139 "ParserXp.yp"
{
            $_[0]->YYData->{native} = 0;
            new CORBA::IDL::NativeType($_[0],
                    'props'             =>  $_[1],
                    'idf'               =>  $_[3],
                    'native'            =>  $_[6],
            );
        }
	],
	[#Rule 183
		 'type_dcl_def', 1, undef
	],
	[#Rule 184
		 'type_dcl_def', 3,
sub
#line 1150 "ParserXp.yp"
{
            $_[0]->Error("type_declarator expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 185
		 'type_declarator', 2,
sub
#line 1159 "ParserXp.yp"
{
            new CORBA::IDL::TypeDeclarators($_[0],
                    'type'              =>  $_[1],
                    'list_expr'         =>  $_[2]
            );
        }
	],
	[#Rule 186
		 'type_spec', 1, undef
	],
	[#Rule 187
		 'type_spec', 1, undef
	],
	[#Rule 188
		 'simple_type_spec', 1, undef
	],
	[#Rule 189
		 'simple_type_spec', 1, undef
	],
	[#Rule 190
		 'simple_type_spec', 1,
sub
#line 1182 "ParserXp.yp"
{
            CORBA::IDL::TypeDeclarator->Lookup($_[0], $_[1]);
        }
	],
	[#Rule 191
		 'simple_type_spec', 1,
sub
#line 1186 "ParserXp.yp"
{
            $_[0]->Error("simple_type_spec expected.\n");
            new CORBA::IDL::VoidType($_[0],
                    'value'             =>  $_[1]
            );
        }
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
		 'base_type_spec', 1, undef
	],
	[#Rule 197
		 'base_type_spec', 1, undef
	],
	[#Rule 198
		 'base_type_spec', 1, undef
	],
	[#Rule 199
		 'base_type_spec', 1, undef
	],
	[#Rule 200
		 'base_type_spec', 1, undef
	],
	[#Rule 201
		 'template_type_spec', 1, undef
	],
	[#Rule 202
		 'template_type_spec', 1, undef
	],
	[#Rule 203
		 'template_type_spec', 1, undef
	],
	[#Rule 204
		 'template_type_spec', 1, undef
	],
	[#Rule 205
		 'constr_type_spec', 1, undef
	],
	[#Rule 206
		 'constr_type_spec', 1, undef
	],
	[#Rule 207
		 'constr_type_spec', 1, undef
	],
	[#Rule 208
		 'declarators', 1,
sub
#line 1241 "ParserXp.yp"
{
            [$_[1]];
        }
	],
	[#Rule 209
		 'declarators', 3,
sub
#line 1245 "ParserXp.yp"
{
            unshift @{$_[3]}, $_[1];
            $_[3];
        }
	],
	[#Rule 210
		 'declarator', 1,
sub
#line 1254 "ParserXp.yp"
{
            [$_[1]];
        }
	],
	[#Rule 211
		 'declarator', 1, undef
	],
	[#Rule 212
		 'simple_declarator', 1, undef
	],
	[#Rule 213
		 'simple_declarator', 2,
sub
#line 1266 "ParserXp.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 214
		 'simple_declarator', 2,
sub
#line 1271 "ParserXp.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 215
		 'complex_declarator', 1, undef
	],
	[#Rule 216
		 'floating_pt_type', 1,
sub
#line 1286 "ParserXp.yp"
{
            new CORBA::IDL::FloatingPtType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 217
		 'floating_pt_type', 1,
sub
#line 1292 "ParserXp.yp"
{
            new CORBA::IDL::FloatingPtType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 218
		 'floating_pt_type', 2,
sub
#line 1298 "ParserXp.yp"
{
            new CORBA::IDL::FloatingPtType($_[0],
                    'value'             =>  $_[1] . q{ } . $_[2]
            );
        }
	],
	[#Rule 219
		 'integer_type', 1, undef
	],
	[#Rule 220
		 'integer_type', 1, undef
	],
	[#Rule 221
		 'signed_int', 1, undef
	],
	[#Rule 222
		 'signed_int', 1, undef
	],
	[#Rule 223
		 'signed_int', 1, undef
	],
	[#Rule 224
		 'signed_short_int', 1,
sub
#line 1326 "ParserXp.yp"
{
            new CORBA::IDL::IntegerType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 225
		 'signed_long_int', 1,
sub
#line 1336 "ParserXp.yp"
{
            new CORBA::IDL::IntegerType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 226
		 'signed_longlong_int', 2,
sub
#line 1346 "ParserXp.yp"
{
            new CORBA::IDL::IntegerType($_[0],
                    'value'             =>  $_[1] . q{ } . $_[2]
            );
        }
	],
	[#Rule 227
		 'unsigned_int', 1, undef
	],
	[#Rule 228
		 'unsigned_int', 1, undef
	],
	[#Rule 229
		 'unsigned_int', 1, undef
	],
	[#Rule 230
		 'unsigned_short_int', 2,
sub
#line 1366 "ParserXp.yp"
{
            new CORBA::IDL::IntegerType($_[0],
                    'value'             =>  $_[1] . q{ } . $_[2]
            );
        }
	],
	[#Rule 231
		 'unsigned_long_int', 2,
sub
#line 1376 "ParserXp.yp"
{
            new CORBA::IDL::IntegerType($_[0],
                    'value'             =>  $_[1] . q{ } . $_[2]
            );
        }
	],
	[#Rule 232
		 'unsigned_longlong_int', 3,
sub
#line 1386 "ParserXp.yp"
{
            new CORBA::IDL::IntegerType($_[0],
                    'value'             =>  $_[1] . q{ } . $_[2] . q{ } . $_[3]
            );
        }
	],
	[#Rule 233
		 'char_type', 1,
sub
#line 1396 "ParserXp.yp"
{
            new CORBA::IDL::CharType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 234
		 'wide_char_type', 1,
sub
#line 1406 "ParserXp.yp"
{
            new CORBA::IDL::WideCharType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 235
		 'boolean_type', 1,
sub
#line 1416 "ParserXp.yp"
{
            new CORBA::IDL::BooleanType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 236
		 'octet_type', 1,
sub
#line 1426 "ParserXp.yp"
{
            new CORBA::IDL::OctetType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 237
		 'any_type', 1,
sub
#line 1436 "ParserXp.yp"
{
            new CORBA::IDL::AnyType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 238
		 'object_type', 1,
sub
#line 1446 "ParserXp.yp"
{
            new CORBA::IDL::ObjectType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 239
		 'struct_type', 4,
sub
#line 1456 "ParserXp.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[1]->Configure($_[0],
                    'list_expr'         =>  $_[3]
            ) if (defined $_[1]);
        }
	],
	[#Rule 240
		 'struct_type', 4,
sub
#line 1463 "ParserXp.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->Error("member expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 241
		 'struct_header', 3,
sub
#line 1473 "ParserXp.yp"
{
            new CORBA::IDL::StructType($_[0],
                    'props'             =>  $_[1],
                    'idf'               =>  $_[3]
            );
        }
	],
	[#Rule 242
		 'struct_header', 3,
sub
#line 1480 "ParserXp.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 243
		 'member_list', 1,
sub
#line 1489 "ParserXp.yp"
{
            [$_[1]];
        }
	],
	[#Rule 244
		 'member_list', 2,
sub
#line 1493 "ParserXp.yp"
{
            unshift @{$_[2]}, $_[1];
            $_[2];
        }
	],
	[#Rule 245
		 'member', 4,
sub
#line 1502 "ParserXp.yp"
{
            new CORBA::IDL::Members($_[0],
                    'props'             =>  $_[1],
                    'type'              =>  $_[2],
                    'list_expr'         =>  $_[3]
            );
        }
	],
	[#Rule 246
		 'member', 3,
sub
#line 1510 "ParserXp.yp"
{
            new CORBA::IDL::Members($_[0],
                    'type'              =>  $_[1],
                    'list_expr'         =>  $_[2]
            );
        }
	],
	[#Rule 247
		 'union_type', 8,
sub
#line 1521 "ParserXp.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[1]->Configure($_[0],
                    'type'              =>  $_[4],
                    'list_expr'         =>  $_[7]
            ) if (defined $_[1]);
        }
	],
	[#Rule 248
		 'union_type', 8,
sub
#line 1529 "ParserXp.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->Error("switch_body expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 249
		 'union_type', 6,
sub
#line 1536 "ParserXp.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->Error("'\x7b' expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 250
		 'union_type', 5,
sub
#line 1543 "ParserXp.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->Error("switch_type_spec expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 251
		 'union_type', 3,
sub
#line 1550 "ParserXp.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->Error("'(' expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 252
		 'union_header', 3,
sub
#line 1560 "ParserXp.yp"
{
            new CORBA::IDL::UnionType($_[0],
                    'props'             =>  $_[1],
                    'idf'               =>  $_[3],
            );
        }
	],
	[#Rule 253
		 'union_header', 3,
sub
#line 1567 "ParserXp.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 254
		 'switch_type_spec', 1, undef
	],
	[#Rule 255
		 'switch_type_spec', 1, undef
	],
	[#Rule 256
		 'switch_type_spec', 1, undef
	],
	[#Rule 257
		 'switch_type_spec', 1, undef
	],
	[#Rule 258
		 'switch_type_spec', 1,
sub
#line 1584 "ParserXp.yp"
{
            CORBA::IDL::TypeDeclarator->Lookup($_[0], $_[1]);
        }
	],
	[#Rule 259
		 'switch_body', 1,
sub
#line 1592 "ParserXp.yp"
{
            [$_[1]];
        }
	],
	[#Rule 260
		 'switch_body', 2,
sub
#line 1596 "ParserXp.yp"
{
            unshift @{$_[2]}, $_[1];
            $_[2];
        }
	],
	[#Rule 261
		 'case', 3,
sub
#line 1605 "ParserXp.yp"
{
            new CORBA::IDL::Case($_[0],
                    'list_label'        =>  $_[1],
                    'element'           =>  $_[2]
            );
        }
	],
	[#Rule 262
		 'case_labels', 1,
sub
#line 1615 "ParserXp.yp"
{
            [$_[1]];
        }
	],
	[#Rule 263
		 'case_labels', 2,
sub
#line 1619 "ParserXp.yp"
{
            unshift @{$_[2]}, $_[1];
            $_[2];
        }
	],
	[#Rule 264
		 'case_label', 3,
sub
#line 1628 "ParserXp.yp"
{
            $_[2];                      # here only a expression, type is not known
        }
	],
	[#Rule 265
		 'case_label', 3,
sub
#line 1632 "ParserXp.yp"
{
            $_[0]->Error("':' expected.\n");
            $_[0]->YYErrok();
            $_[2];
        }
	],
	[#Rule 266
		 'case_label', 2,
sub
#line 1638 "ParserXp.yp"
{
            $_[0]->Error("Expression expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 267
		 'case_label', 2,
sub
#line 1643 "ParserXp.yp"
{
            new CORBA::IDL::Default($_[0]);
        }
	],
	[#Rule 268
		 'case_label', 2,
sub
#line 1647 "ParserXp.yp"
{
            $_[0]->Error("':' expected.\n");
            $_[0]->YYErrok();
            new CORBA::IDL::Default($_[0]);
        }
	],
	[#Rule 269
		 'element_spec', 3,
sub
#line 1657 "ParserXp.yp"
{
            new CORBA::IDL::Element($_[0],
                    'props'         =>  $_[1],
                    'type'          =>  $_[2],
                    'list_expr'     =>  $_[3]
            );
        }
	],
	[#Rule 270
		 'element_spec', 2,
sub
#line 1665 "ParserXp.yp"
{
            new CORBA::IDL::Element($_[0],
                    'type'          =>  $_[1],
                    'list_expr'     =>  $_[2]
            );
        }
	],
	[#Rule 271
		 'enum_type', 4,
sub
#line 1676 "ParserXp.yp"
{
            $_[1]->Configure($_[0],
                    'list_expr'     =>  $_[3]
            ) if (defined $_[1]);
        }
	],
	[#Rule 272
		 'enum_type', 4,
sub
#line 1682 "ParserXp.yp"
{
            $_[0]->Error("enumerator expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 273
		 'enum_type', 2,
sub
#line 1688 "ParserXp.yp"
{
            $_[0]->Error("'\x7b' expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 274
		 'enum_header', 3,
sub
#line 1697 "ParserXp.yp"
{
            new CORBA::IDL::EnumType($_[0],
                    'props'             =>  $_[1],
                    'idf'               =>  $_[3],
            );
        }
	],
	[#Rule 275
		 'enum_header', 3,
sub
#line 1704 "ParserXp.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 276
		 'enumerators', 1,
sub
#line 1712 "ParserXp.yp"
{
            [$_[1]];
        }
	],
	[#Rule 277
		 'enumerators', 3,
sub
#line 1716 "ParserXp.yp"
{
            unshift @{$_[3]}, $_[1];
            $_[3];
        }
	],
	[#Rule 278
		 'enumerators', 2,
sub
#line 1721 "ParserXp.yp"
{
            $_[0]->Warning("',' unexpected.\n");
            [$_[1]];
        }
	],
	[#Rule 279
		 'enumerators', 2,
sub
#line 1726 "ParserXp.yp"
{
            $_[0]->Error("';' unexpected.\n");
            [$_[1]];
        }
	],
	[#Rule 280
		 'enumerator', 1,
sub
#line 1735 "ParserXp.yp"
{
            new CORBA::IDL::Enum($_[0],
                    'idf'               =>  $_[1]
            );
        }
	],
	[#Rule 281
		 'sequence_type', 6,
sub
#line 1745 "ParserXp.yp"
{
            new CORBA::IDL::SequenceType($_[0],
                    'value'             =>  $_[1],
                    'type'              =>  $_[3],
                    'max'               =>  $_[5]
            );
        }
	],
	[#Rule 282
		 'sequence_type', 6,
sub
#line 1753 "ParserXp.yp"
{
            $_[0]->Error("Expression expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 283
		 'sequence_type', 4,
sub
#line 1758 "ParserXp.yp"
{
            new CORBA::IDL::SequenceType($_[0],
                    'value'             =>  $_[1],
                    'type'              =>  $_[3]
            );
        }
	],
	[#Rule 284
		 'sequence_type', 4,
sub
#line 1765 "ParserXp.yp"
{
            $_[0]->Error("simple_type_spec expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 285
		 'sequence_type', 2,
sub
#line 1770 "ParserXp.yp"
{
            $_[0]->Error("'<' expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 286
		 'string_type', 4,
sub
#line 1779 "ParserXp.yp"
{
            new CORBA::IDL::StringType($_[0],
                    'value'             =>  $_[1],
                    'max'               =>  $_[3]
            );
        }
	],
	[#Rule 287
		 'string_type', 1,
sub
#line 1786 "ParserXp.yp"
{
            new CORBA::IDL::StringType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 288
		 'string_type', 4,
sub
#line 1792 "ParserXp.yp"
{
            $_[0]->Error("Expression expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 289
		 'wide_string_type', 4,
sub
#line 1801 "ParserXp.yp"
{
            new CORBA::IDL::WideStringType($_[0],
                    'value'             =>  $_[1],
                    'max'               =>  $_[3]
            );
        }
	],
	[#Rule 290
		 'wide_string_type', 1,
sub
#line 1808 "ParserXp.yp"
{
            new CORBA::IDL::WideStringType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 291
		 'wide_string_type', 4,
sub
#line 1814 "ParserXp.yp"
{
            $_[0]->Error("Expression expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 292
		 'array_declarator', 2,
sub
#line 1823 "ParserXp.yp"
{
            unshift @{$_[2]}, $_[1];
            $_[2];
        }
	],
	[#Rule 293
		 'fixed_array_sizes', 1,
sub
#line 1831 "ParserXp.yp"
{
            [$_[1]];
        }
	],
	[#Rule 294
		 'fixed_array_sizes', 2,
sub
#line 1835 "ParserXp.yp"
{
            unshift @{$_[2]}, $_[1];
            $_[2];
        }
	],
	[#Rule 295
		 'fixed_array_size', 3,
sub
#line 1844 "ParserXp.yp"
{
            $_[2];
        }
	],
	[#Rule 296
		 'fixed_array_size', 3,
sub
#line 1848 "ParserXp.yp"
{
            $_[0]->Error("Expression expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 297
		 'attr_dcl', 1, undef
	],
	[#Rule 298
		 'attr_dcl', 1, undef
	],
	[#Rule 299
		 'except_dcl', 3,
sub
#line 1865 "ParserXp.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[1];
        }
	],
	[#Rule 300
		 'except_dcl', 4,
sub
#line 1870 "ParserXp.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[1]->Configure($_[0],
                    'list_expr'         =>  $_[3]
            ) if (defined $_[1]);
        }
	],
	[#Rule 301
		 'except_dcl', 4,
sub
#line 1877 "ParserXp.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->Error("'members expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 302
		 'except_dcl', 2,
sub
#line 1884 "ParserXp.yp"
{
            $_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
            $_[0]->Error("'\x7b' expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 303
		 'exception_header', 3,
sub
#line 1894 "ParserXp.yp"
{
            new CORBA::IDL::Exception($_[0],
                    'declspec'          =>  $_[1],
                    'idf'               =>  $_[3],
            );
        }
	],
	[#Rule 304
		 'exception_header', 3,
sub
#line 1901 "ParserXp.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 305
		 'op_dcl', 4,
sub
#line 1910 "ParserXp.yp"
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
	[#Rule 306
		 'op_dcl', 2,
sub
#line 1920 "ParserXp.yp"
{
            delete $_[0]->YYData->{unnamed_symbtab}
                    if (exists $_[0]->YYData->{unnamed_symbtab});
            $_[0]->Error("parameters declaration expected.\n");
            $_[0]->YYErrok();
            $_[1];
        }
	],
	[#Rule 307
		 'op_header', 5,
sub
#line 1931 "ParserXp.yp"
{
            new CORBA::IDL::Operation($_[0],
                    'declspec'          =>  $_[1],
                    'props'             =>  $_[2],
                    'modifier'          =>  $_[3],
                    'type'              =>  $_[4],
                    'idf'               =>  $_[5]
            );
        }
	],
	[#Rule 308
		 'op_header', 5,
sub
#line 1941 "ParserXp.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 309
		 'op_mod', 1, undef
	],
	[#Rule 310
		 'op_mod', 0, undef
	],
	[#Rule 311
		 'op_attribute', 1, undef
	],
	[#Rule 312
		 'op_type_spec', 1, undef
	],
	[#Rule 313
		 'op_type_spec', 1,
sub
#line 1965 "ParserXp.yp"
{
            new CORBA::IDL::VoidType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 314
		 'op_type_spec', 1,
sub
#line 1971 "ParserXp.yp"
{
            $_[0]->Error("op_type_spec expected.\n");
            $_[1];                      #default action
        }
	],
	[#Rule 315
		 'op_type_spec', 1,
sub
#line 1976 "ParserXp.yp"
{
            $_[0]->Error("op_type_spec expected.\n");
            $_[1];                      #default action
        }
	],
	[#Rule 316
		 'parameter_dcls', 3,
sub
#line 1985 "ParserXp.yp"
{
            $_[2];
        }
	],
	[#Rule 317
		 'parameter_dcls', 5,
sub
#line 1989 "ParserXp.yp"
{
            push @{$_[2]}, new CORBA::IDL::Ellipsis($_[0]);
            $_[2];
        }
	],
	[#Rule 318
		 'parameter_dcls', 4,
sub
#line 1994 "ParserXp.yp"
{
            $_[0]->Warning("',' unexpected.\n");
            $_[2];
        }
	],
	[#Rule 319
		 'parameter_dcls', 2,
sub
#line 1999 "ParserXp.yp"
{
            undef;
        }
	],
	[#Rule 320
		 'parameter_dcls', 3,
sub
#line 2003 "ParserXp.yp"
{
            $_[0]->Error("'...' unexpected.\n");
            undef;
        }
	],
	[#Rule 321
		 'parameter_dcls', 3,
sub
#line 2008 "ParserXp.yp"
{
            new CORBA::IDL::Ellipsis($_[0]);
        }
	],
	[#Rule 322
		 'param_dcls', 1,
sub
#line 2015 "ParserXp.yp"
{
            [$_[1]];
        }
	],
	[#Rule 323
		 'param_dcls', 3,
sub
#line 2019 "ParserXp.yp"
{
            push @{$_[1]}, $_[3];
            $_[1];
        }
	],
	[#Rule 324
		 'param_dcls', 2,
sub
#line 2024 "ParserXp.yp"
{
            $_[0]->Error("';' unexpected.\n");
            [$_[1]];
        }
	],
	[#Rule 325
		 'param_dcl', 4,
sub
#line 2033 "ParserXp.yp"
{
            new CORBA::IDL::Parameter($_[0],
                    'props'             =>  $_[1],
                    'attr'              =>  $_[2],
                    'type'              =>  $_[3],
                    'idf'               =>  $_[4]
            );
        }
	],
	[#Rule 326
		 'param_attribute', 1, undef
	],
	[#Rule 327
		 'param_attribute', 1, undef
	],
	[#Rule 328
		 'param_attribute', 1, undef
	],
	[#Rule 329
		 'param_attribute', 0,
sub
#line 2052 "ParserXp.yp"
{
            $_[0]->Error("(in|out|inout) expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 330
		 'raises_expr', 4,
sub
#line 2061 "ParserXp.yp"
{
            $_[3];
        }
	],
	[#Rule 331
		 'raises_expr', 4,
sub
#line 2065 "ParserXp.yp"
{
            $_[0]->Error("name expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 332
		 'raises_expr', 2,
sub
#line 2070 "ParserXp.yp"
{
            $_[0]->Error("'(' expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 333
		 'raises_expr', 0, undef
	],
	[#Rule 334
		 'exception_names', 1,
sub
#line 2080 "ParserXp.yp"
{
            [$_[1]];
        }
	],
	[#Rule 335
		 'exception_names', 3,
sub
#line 2084 "ParserXp.yp"
{
            unshift @{$_[3]}, $_[1];
            $_[3];
        }
	],
	[#Rule 336
		 'exception_name', 1,
sub
#line 2092 "ParserXp.yp"
{
            CORBA::IDL::Interface->Lookup($_[0], $_[1], 1);
        }
	],
	[#Rule 337
		 'context_expr', 4,
sub
#line 2100 "ParserXp.yp"
{
            $_[3];
        }
	],
	[#Rule 338
		 'context_expr', 4,
sub
#line 2104 "ParserXp.yp"
{
            $_[0]->Error("string expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 339
		 'context_expr', 2,
sub
#line 2109 "ParserXp.yp"
{
            $_[0]->Error("'(' expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 340
		 'context_expr', 0, undef
	],
	[#Rule 341
		 'string_literals', 1,
sub
#line 2119 "ParserXp.yp"
{
            [$_[1]];
        }
	],
	[#Rule 342
		 'string_literals', 3,
sub
#line 2123 "ParserXp.yp"
{
            unshift @{$_[3]}, $_[1];
            $_[3];
        }
	],
	[#Rule 343
		 'param_type_spec', 1, undef
	],
	[#Rule 344
		 'param_type_spec', 1,
sub
#line 2134 "ParserXp.yp"
{
            $_[0]->Error("param_type_spec expected.\n");
            $_[1];                      #default action
        }
	],
	[#Rule 345
		 'param_type_spec', 1,
sub
#line 2139 "ParserXp.yp"
{
            $_[0]->Error("param_type_spec expected.\n");
            $_[1];                      #default action
        }
	],
	[#Rule 346
		 'param_type_spec', 1,
sub
#line 2144 "ParserXp.yp"
{
            $_[0]->Error("param_type_spec expected.\n");
            $_[1];                      #default action
        }
	],
	[#Rule 347
		 'op_param_type_spec', 1, undef
	],
	[#Rule 348
		 'op_param_type_spec', 1, undef
	],
	[#Rule 349
		 'op_param_type_spec', 1, undef
	],
	[#Rule 350
		 'op_param_type_spec', 1,
sub
#line 2158 "ParserXp.yp"
{
            CORBA::IDL::TypeDeclarator->Lookup($_[0], $_[1]);
        }
	],
	[#Rule 351
		 'fixed_pt_type', 6,
sub
#line 2166 "ParserXp.yp"
{
            new CORBA::IDL::FixedPtType($_[0],
                    'value'             =>  $_[1],
                    'd'                 =>  $_[3],
                    's'                 =>  $_[5]
            );
        }
	],
	[#Rule 352
		 'fixed_pt_type', 6,
sub
#line 2174 "ParserXp.yp"
{
            $_[0]->Error("Expression expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 353
		 'fixed_pt_type', 4,
sub
#line 2179 "ParserXp.yp"
{
            $_[0]->Error("Expression expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 354
		 'fixed_pt_type', 2,
sub
#line 2184 "ParserXp.yp"
{
            $_[0]->Error("'<' expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 355
		 'fixed_pt_const_type', 1,
sub
#line 2193 "ParserXp.yp"
{
            new CORBA::IDL::FixedPtConstType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 356
		 'value_base_type', 1,
sub
#line 2203 "ParserXp.yp"
{
            new CORBA::IDL::ValueBaseType($_[0],
                    'value'             =>  $_[1]
            );
        }
	],
	[#Rule 357
		 'constr_forward_decl', 3,
sub
#line 2213 "ParserXp.yp"
{
            $_[0]->Warning("Ignoring properties for forward declaration.\n")
                    if (defined $_[1]);
            new CORBA::IDL::ForwardStructType($_[0],
                    'idf'               =>  $_[3]
            );
        }
	],
	[#Rule 358
		 'constr_forward_decl', 3,
sub
#line 2221 "ParserXp.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 359
		 'constr_forward_decl', 3,
sub
#line 2226 "ParserXp.yp"
{
            $_[0]->Warning("Ignoring properties for forward declaration.\n")
                    if (defined $_[1]);
            new CORBA::IDL::ForwardUnionType($_[0],
                    'idf'               =>  $_[3]
            );
        }
	],
	[#Rule 360
		 'constr_forward_decl', 3,
sub
#line 2234 "ParserXp.yp"
{
            $_[0]->Error("Identifier expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 361
		 'import', 3,
sub
#line 2243 "ParserXp.yp"
{
            new CORBA::IDL::Import($_[0],
                    'value'             =>  $_[2]
            );
        }
	],
	[#Rule 362
		 'import', 2,
sub
#line 2249 "ParserXp.yp"
{
            $_[0]->Error("Scoped name expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 363
		 'imported_scope', 1, undef
	],
	[#Rule 364
		 'imported_scope', 1, undef
	],
	[#Rule 365
		 'type_id_dcl', 3,
sub
#line 2266 "ParserXp.yp"
{
            new CORBA::IDL::TypeId($_[0],
                    'idf'               =>  $_[2],
                    'value'             =>  $_[3]
            );
        }
	],
	[#Rule 366
		 'type_id_dcl', 3,
sub
#line 2273 "ParserXp.yp"
{
            $_[0]->Error("String literal expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 367
		 'type_id_dcl', 2,
sub
#line 2278 "ParserXp.yp"
{
            $_[0]->Error("Scoped name expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 368
		 'type_prefix_dcl', 3,
sub
#line 2287 "ParserXp.yp"
{
            new CORBA::IDL::TypePrefix($_[0],
                    'idf'               =>  $_[2],
                    'value'             =>  $_[3]
            );
        }
	],
	[#Rule 369
		 'type_prefix_dcl', 3,
sub
#line 2294 "ParserXp.yp"
{
            $_[0]->Error("String literal expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 370
		 'type_prefix_dcl', 3,
sub
#line 2299 "ParserXp.yp"
{
            new CORBA::IDL::TypePrefix($_[0],
                    'idf'               =>  '',
                    'value'             =>  $_[3]
            );
        }
	],
	[#Rule 371
		 'type_prefix_dcl', 2,
sub
#line 2306 "ParserXp.yp"
{
            $_[0]->Error("Scoped name expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 372
		 'readonly_attr_spec', 6,
sub
#line 2315 "ParserXp.yp"
{
            new CORBA::IDL::Attributes($_[0],
                    'declspec'          =>  $_[1],
                    'props'             =>  $_[2],
                    'modifier'          =>  $_[3],
                    'type'              =>  $_[5],
                    'list_expr'         =>  $_[6]->{list_expr},
                    'list_getraise'     =>  $_[6]->{list_getraise},
            );
        }
	],
	[#Rule 373
		 'readonly_attr_spec', 5,
sub
#line 2326 "ParserXp.yp"
{
            $_[0]->Error("type expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 374
		 'readonly_attr_spec', 4,
sub
#line 2331 "ParserXp.yp"
{
            $_[0]->Error("'attribute' expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 375
		 'readonly_attr_declarator', 2,
sub
#line 2340 "ParserXp.yp"
{
            {
                'list_expr'         => [$_[1]],
                'list_getraise'     => $_[2]
            };
        }
	],
	[#Rule 376
		 'readonly_attr_declarator', 3,
sub
#line 2347 "ParserXp.yp"
{
            unshift @{$_[3]}, $_[1];
            {
                'list_expr'         => $_[3]
            };
        }
	],
	[#Rule 377
		 'simple_declarators', 1,
sub
#line 2357 "ParserXp.yp"
{
            [$_[1]];
        }
	],
	[#Rule 378
		 'simple_declarators', 3,
sub
#line 2361 "ParserXp.yp"
{
            unshift @{$_[3]}, $_[1];
            $_[3];
        }
	],
	[#Rule 379
		 'attr_spec', 5,
sub
#line 2370 "ParserXp.yp"
{
            new CORBA::IDL::Attributes($_[0],
                    'declspec'          =>  $_[1],
                    'props'             =>  $_[2],
                    'type'              =>  $_[4],
                    'list_expr'         =>  $_[5]->{list_expr},
                    'list_getraise'     =>  $_[5]->{list_getraise},
                    'list_setraise'     =>  $_[5]->{list_setraise},
            );
        }
	],
	[#Rule 380
		 'attr_spec', 4,
sub
#line 2381 "ParserXp.yp"
{
            $_[0]->Error("type expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 381
		 'attr_declarator', 2,
sub
#line 2390 "ParserXp.yp"
{
            {
                'list_expr'         => [$_[1]],
                'list_getraise'     => $_[2]->{list_getraise},
                'list_setraise'     => $_[2]->{list_setraise}
            };
        }
	],
	[#Rule 382
		 'attr_declarator', 3,
sub
#line 2398 "ParserXp.yp"
{
            unshift @{$_[3]}, $_[1];
            {
                'list_expr'         => $_[3]
            };
        }
	],
	[#Rule 383
		 'attr_raises_expr', 2,
sub
#line 2409 "ParserXp.yp"
{
            {
                'list_getraise'     => $_[1],
                'list_setraise'     => $_[2]
            };
        }
	],
	[#Rule 384
		 'attr_raises_expr', 1,
sub
#line 2416 "ParserXp.yp"
{
            {
                'list_getraise'     => $_[1],
            };
        }
	],
	[#Rule 385
		 'attr_raises_expr', 1,
sub
#line 2422 "ParserXp.yp"
{
            {
                'list_setraise'     => $_[1]
            };
        }
	],
	[#Rule 386
		 'attr_raises_expr', 0, undef
	],
	[#Rule 387
		 'get_except_expr', 2,
sub
#line 2434 "ParserXp.yp"
{
            $_[2];
        }
	],
	[#Rule 388
		 'get_except_expr', 2,
sub
#line 2438 "ParserXp.yp"
{
            $_[0]->Error("'(' expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 389
		 'set_except_expr', 2,
sub
#line 2447 "ParserXp.yp"
{
            $_[2];
        }
	],
	[#Rule 390
		 'set_except_expr', 2,
sub
#line 2451 "ParserXp.yp"
{
            $_[0]->Error("'(' expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 391
		 'exception_list', 3,
sub
#line 2460 "ParserXp.yp"
{
            $_[2];
        }
	],
	[#Rule 392
		 'exception_list', 3,
sub
#line 2464 "ParserXp.yp"
{
            $_[0]->Error("name expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 393
		 'code_frag', 2,
sub
#line 2474 "ParserXp.yp"
{
            new CORBA::IDL::CodeFragment($_[0],
                    'declspec'          =>  $_[1],
                    'value'             =>  $_[2],
            );
        }
	],
	[#Rule 394
		 'declspec', 0, undef
	],
	[#Rule 395
		 'declspec', 1, undef
	],
	[#Rule 396
		 'props', 0, undef
	],
	[#Rule 397
		 '@2-1', 0,
sub
#line 2493 "ParserXp.yp"
{
            $_[0]->YYData->{prop} = 1;
        }
	],
	[#Rule 398
		 'props', 4,
sub
#line 2497 "ParserXp.yp"
{
            $_[0]->YYData->{prop} = 0;
            $_[3];
        }
	],
	[#Rule 399
		 'prop_list', 2,
sub
#line 2505 "ParserXp.yp"
{
            my $hash = {};
            $hash->{$_[1]} = $_[2];
            $hash;
        }
	],
	[#Rule 400
		 'prop_list', 4,
sub
#line 2511 "ParserXp.yp"
{
            $_[1]->{$_[3]} = $_[4];
            $_[1];
        }
	],
	[#Rule 401
		 'prop_list', 1,
sub
#line 2516 "ParserXp.yp"
{
            my $hash = {};
            $hash->{$_[1]} = undef;
            $hash;
        }
	],
	[#Rule 402
		 'prop_list', 3,
sub
#line 2522 "ParserXp.yp"
{
            $_[1]->{$_[3]} = undef;
            $_[1];
        }
	]
],
                                  @_);
    bless($self,$class);
}

#line 2528 "ParserXp.yp"


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
