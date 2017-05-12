
/*  A Bison parser, made from parser.y
    by GNU Bison version 1.28  */

#define YYBISON 1  /* Identify Bison output.  */

#define	L_BREAK	257
#define	L_CASE	258
#define	L_CATCH	259
#define	L_CLASS	260
#define	L_CONTINUE	261
#define	L_DEFAULT	262
#define	L_DO	263
#define	L_EFUN	264
#define	L_ELSE	265
#define	L_FOR	266
#define	L_FOREACH	267
#define	L_IF	268
#define	L_IN	269
#define	L_INHERIT	270
#define	L_NEW	271
#define	L_NIL	272
#define	L_RETURN	273
#define	L_RLIMITS	274
#define	L_SWITCH	275
#define	L_SSCANF	276
#define	L_TRY	277
#define	L_WHILE	278
#define	L_MAP_START	279
#define	L_MAP_END	280
#define	L_ARRAY_START	281
#define	L_ARRAY_END	282
#define	L_FUNCTION_START	283
#define	L_FUNCTION_END	284
#define	L_PARAMETER	285
#define	L_IDENTIFIER	286
#define	L_STRING	287
#define	L_CHARACTER	288
#define	L_INTEGER	289
#define	L_HEXINTEGER	290
#define	L_BASIC_TYPE	291
#define	L_TYPE_MODIFIER	292
#define	L_STATIC	293
#define	L_COLONCOLON	294
#define	L_VOID	295
#define	L_ELLIPSIS	296
#define	L_ARROW	297
#define	L_RANGE	298
#define	LOWER_THAN_ELSE	299
#define	L_PLUS_EQ	300
#define	L_MINUS_EQ	301
#define	L_DIV_EQ	302
#define	L_TIMES_EQ	303
#define	L_MOD_EQ	304
#define	L_AND_EQ	305
#define	L_OR_EQ	306
#define	L_XOR_EQ	307
#define	L_DOT_EQ	308
#define	L_LOR_EQ	309
#define	L_LAND_EQ	310
#define	L_LOR	311
#define	L_LAND	312
#define	L_EQ	313
#define	L_NE	314
#define	L_GE	315
#define	L_LE	316
#define	L_LSH	317
#define	L_RSH	318
#define	L_INC	319
#define	L_DEC	320

#line 1 "parser.y"

#if 0
L_BREAK L_CASE L_CATCH L_CLASS L_CONTINUE L_DEFAULT L_DO L_EFUN L_ELSE L_FOR L_FOREACH L_IF L_IN L_INHERIT L_NEW L_NIL L_RETURN L_RLIMITS L_SWITCH L_SSCANF L_TRY L_WHILE

T_BOOL, T_CLOSURE, T_INTEGER, T_MAPPING, T_MIXED, T_OBJECT, T_STRING, T_VOID,

M_NOMASK, M_NOSAVE, M_PRIVATE, M_PROTECTED, M_PUBLIC, M_VARARGS,

L_PLUS_EQ L_MINUS_EQ L_DIV_EQ L_TIMES_EQ L_MOD_EQ L_AND_EQ L_OR_EQ L_XOR_EQ L_DOT_EQ

L_EQ L_NE L_LE L_GE L_LOR L_LAND L_INC L_DEC L_RSH L_LSH

L_MAP_START L_MAP_END L_ARRAY_START L_ARRAY_END L_FUNCTION_START L_FUNCTION_END

L_COLONCOLON L_ARROW L_RANGE L_ELLIPSIS
#endif

#include "compiler.h"
#include "../Type/type.h"

#define YYPARSE_PARAM	amd_yyparse_param
#define YYLEX_PARAM		amd_yyparse_param

#define YYDEBUG 0
#define YYERROR_VERBOSE

#if 0 || (YYDEBUG != 0)
#define amd_yylex(lvalp, amd_yypp) amd_yylex_verbose(lvalp, amd_yypp)
#else
#define amd_yylex(lvalp, amd_yypp) amd_yylex(lvalp, amd_yypp)
#endif

#define Z1		NULL
#define Z2		Z1, NULL
#define Z3		Z2, NULL
#define Z4		Z3, NULL
#define Z5		Z4, NULL
#define Z6		Z5, NULL

#define N_A0(t)					amd_yyparse_node(t,               Z6)
#define N_A1(t,a0)				amd_yyparse_node(t,a0,            Z5)
#define N_A2(t,a0,a1)			amd_yyparse_node(t,a0,a1,         Z4)
#define N_A3(t,a0,a1,a2)		amd_yyparse_node(t,a0,a1,a2,      Z3)
#define N_A4(t,a0,a1,a2,a3)		amd_yyparse_node(t,a0,a1,a2,a3,   Z2)
#define N_A5(t,a0,a1,a2,a3,a4)	amd_yyparse_node(t,a0,a1,a2,a3,a4,Z1)

#define N_A0R(t,r)					amd_yyparse_node(t,            Z5,r)
#define N_A1R(t,a0,r)				amd_yyparse_node(t,a0,         Z4,r)
#define N_A2R(t,a0,a1,r)			amd_yyparse_node(t,a0,a1,      Z3,r)
#define N_A3R(t,a0,a1,a2,r)			amd_yyparse_node(t,a0,a1,a2,   Z2,r)
#define N_A4R(t,a0,a1,a2,a3,r)		amd_yyparse_node(t,a0,a1,a2,a3,Z1,r)
#define N_A5R(t,a0,a1,a2,a3,a4,r)	amd_yyparse_node(t,a0,a1,a2,a3,a4,r)

static SV *
amd_yyparse_node(char *type,
				SV *arg0, SV *arg1, SV *arg2, SV *arg3, SV *arg4,
				AV *rest)
{
	dSP;
	int		 count;
	SV		*node;
	char	 buf[512];
	SV		*class;
	SV		**svp;
	int		 len;
	int		 i;

	strcpy(buf, _AMD "::Compiler::Node::");
	strcat(buf, type);
	class = sv_2mortal(newSVpv(buf, 0));

	ENTER;
	SAVETMPS;
	PUSHMARK(SP);

	XPUSHs(class);
	/* This unconventional formatting pushes the first few of argN
	 * which are not NULL. */
	if (arg0) { XPUSHs(arg0);
	if (arg1) { XPUSHs(arg1);
	if (arg2) { XPUSHs(arg2);
	if (arg3) { XPUSHs(arg3);
	if (arg4) { XPUSHs(arg4);
								} } } } }

	if (rest) {
		len = av_len(rest);
		for (i = 0; i <= len; i++) {
			svp = av_fetch(rest, i, FALSE);
			if (svp)
				XPUSHs(*svp);
		}
	}

	PUTBACK;
	count = call_method("new", G_SCALAR);
	SPAGAIN;
	if (count != 1)
		croak("Didn't get a return value from constructing %s\n", type);
	node = POPs;
	PUTBACK;

	SvREFCNT_inc(node);

	FREETMPS;
	LEAVE;

	// sv_2mortal(node);	/* This segfaults it at the moment. */

	return node;
}

/* We have to make sure that 'type' coming into here is PV not RV */
static SV *
amd_yyparse_type(const char *type, SV *stars)
{
	static SV	*class = NULL;
	SV			*sv;
	dSP;
	int			 count;
	SV			*node;

	if (!class) {
		class = newSVpv(_AMD "::Compiler::Type", 0);
	}

	// fprintf(stderr, "Type is %s, stars is %s\n", type, SvPV_nolen(stars));

	/* XXX It's quite likely that we own the only ref to 'stars' here.
	 */
	sv = newSVsv(stars);
	sv_catpv(sv, type);

	ENTER;
	SAVETMPS;
	PUSHMARK(SP);

	XPUSHs(class);
	XPUSHs(sv);		/* Does this get freed? */

	PUTBACK;
	count = call_method("new", G_SCALAR);
	SPAGAIN;
	if (count != 1)
		croak("Didn't get a return value from constructing Type\n");
	node = POPs;
	PUTBACK;

	SvREFCNT_inc(node);

	FREETMPS;
	LEAVE;

	/* In the outer scope. Let's hope this doesn't get dested. */
	sv_2mortal(node);

	return node;

#if 0
	return sv_bless(newRV_noinc(stars),
			gv_stashpv(_AMD "::Compiler::Type", TRUE));
#endif
}

/* Can I pass mods as a primitive integer, and not bother if they
 * are zero? This applies to functions as well. */
static SV *
amd_yyparse_variable(SV *name, const char *type, SV *stars, SV *mods)
{
	static SV	*class = NULL;
	static SV	*k_type = NULL;
	static SV	*k_name = NULL;
	static SV	*k_flags = NULL;
	SV			*newtype;
	dSP;
	int			 count;
	SV			*node;

	if (!class) {
		class = newSVpv(_AMD "::Program::Variable", 0);
		k_type = newSVpv("Type", 0);
		k_name = newSVpv("Name", 0);
		k_flags = newSVpv("Flags", 0);
	}

	newtype = amd_yyparse_type(type, stars);

	ENTER;
	SAVETMPS;
	PUSHMARK(SP);

	XPUSHs(class);
	XPUSHs(k_type);
	XPUSHs(newtype);
	XPUSHs(k_name);
	XPUSHs(name);
	XPUSHs(k_flags);
	XPUSHs(mods);

	PUTBACK;
	count = call_method("new", G_SCALAR);
	SPAGAIN;
	if (count != 1)
		croak("Didn't get a return value from constructing Variable\n");
	node = POPs;
	PUTBACK;

	SvREFCNT_inc(node);

	FREETMPS;
	LEAVE;

	return node;
}

static SV *
amd_yyparse_method(SV *name, const char *type, SV *stars,
				SV *args, SV *mods)
{
	static SV	*class = NULL;
	static SV	*k_type = NULL;
	static SV	*k_name = NULL;
	static SV	*k_args = NULL;
	static SV	*k_flags = NULL;
	SV			*newtype;
	dSP;
	int			 count;
	SV			*node;

	if (!class) {
		class = newSVpv(_AMD "::Program::Method", 0);
		k_type = newSVpv("Type", 0);
		k_name = newSVpv("Name", 0);
		k_args = newSVpv("Args", 0);
		k_flags = newSVpv("Flags", 0);
	}

	newtype = amd_yyparse_type(type, stars);

	// printf("Start of amd_yyparse_method\n");

	ENTER;
	SAVETMPS;
	PUSHMARK(SP);

	XPUSHs(class);
	XPUSHs(k_type);
	XPUSHs(newtype);
	XPUSHs(k_name);
	XPUSHs(name);
	XPUSHs(k_args);
	XPUSHs(args);
	XPUSHs(k_flags);
	XPUSHs(mods);

	PUTBACK;
	count = call_method("new", G_SCALAR);
	SPAGAIN;
	if (count != 1)
		croak("Didn't get a return value from constructing Method\n");
	node = POPs;
	PUTBACK;

	SvREFCNT_inc(node);

	FREETMPS;
	LEAVE;

	// printf("End of amd_yyparse_method\n");

	return node;
}

static void
amd_yyparse_method_add_code(SV *method, SV *code)
{
	dSP;
	int			 count;

	ENTER;
	SAVETMPS;
	PUSHMARK(SP);

	XPUSHs(method);
	XPUSHs(code);

	PUTBACK;
	count = call_method("code", G_DISCARD);
	SPAGAIN;
	if (count != 0)
		croak("Got a return value from method->code()\n");
	PUTBACK;
	FREETMPS;
	LEAVE;
}

static SV *
amd_yyparse_program_apply(amd_parse_param_t *param,
				const char *func, SV *arg0, SV *arg1)
{
	dSP;
	int		 count;
	SV		*node;

	// printf("Apply %s\n", func);

	ENTER;
	SAVETMPS;
	PUSHMARK(SP);

	XPUSHs(param->program);
	if (arg0) XPUSHs(arg0);
	if (arg1) XPUSHs(arg1);

	PUTBACK;
	count = call_method(func, G_SCALAR);
	SPAGAIN;
	if (count != 1)
		croak("No returned value from apply %s\n", func);
	node = POPs;

	SvREFCNT_inc(node);

	PUTBACK;
	FREETMPS;
	LEAVE;

	return node;
}


#line 386 "parser.y"
typedef union {
	int			 number;
	const char	*str;
	SV			*sv;
	SV			*obj;
	AV			*av;
	struct _assoc_t {
		SV	*key;
		SV	*value;
	} 			 assoc;
} AMD_YYSTYPE;
#line 398 "parser.y"

	/* This declares either amd_yylex or amd_yylex_verbose, according to
	 * the macros above. This is a bit obscure and occasionally
	 * highly fucked up. */
int amd_yylex(AMD_YYSTYPE *amd_yylval, amd_parse_param_t *param);
#include <stdio.h>

#ifndef __cplusplus
#ifndef __STDC__
#define const
#endif
#endif



#define	YYFINAL		342
#define	YYFLAG		-32768
#define	YYNTBASE	93

#define YYTRANSLATE(x) ((unsigned)(x) <= 320 ? amd_yytranslate[x] : 151)

static const char amd_yytranslate[] = {     0,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,    77,     2,    92,    91,    75,    62,     2,    86,
    87,    74,    72,    83,    73,    71,    76,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,    85,    84,    67,
    90,    68,    57,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
    88,     2,    89,    61,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,    81,    60,    82,    78,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     1,     3,     4,     5,     6,
     7,     8,     9,    10,    11,    12,    13,    14,    15,    16,
    17,    18,    19,    20,    21,    22,    23,    24,    25,    26,
    27,    28,    29,    30,    31,    32,    33,    34,    35,    36,
    37,    38,    39,    40,    41,    42,    43,    44,    45,    46,
    47,    48,    49,    50,    51,    52,    53,    54,    55,    56,
    58,    59,    63,    64,    65,    66,    69,    70,    79,    80
};

#if YYDEBUG != 0
static const short amd_yyprhs[] = {     0,
     0,     3,     4,     6,     8,    10,    12,    14,    18,    23,
    25,    31,    34,    36,    40,    42,    46,    48,    52,    56,
    59,    62,    67,    68,    71,    74,    76,    83,    91,    97,
   107,   115,   125,   133,   141,   144,   150,   154,   157,   160,
   163,   167,   169,   172,   173,   176,   178,   182,   183,   185,
   187,   188,   190,   192,   196,   197,   199,   200,   202,   205,
   209,   211,   215,   216,   218,   221,   223,   226,   230,   234,
   236,   238,   242,   246,   250,   254,   258,   262,   266,   270,
   274,   278,   282,   286,   288,   294,   296,   300,   304,   308,
   312,   316,   318,   322,   326,   330,   334,   338,   342,   344,
   348,   352,   356,   360,   364,   368,   372,   376,   378,   381,
   384,   387,   390,   393,   396,   398,   401,   404,   406,   412,
   421,   423,   425,   426,   428,   430,   432,   434,   436,   438,
   440,   442,   444,   449,   453,   458,   464,   469,   475,   482,
   486,   487,   491,   496,   497,   500,   504,   511,   512,   515,
   519,   520,   522,   524,   527,   529,   533,   536,   537,   540,
   542,   544,   547,   548,   551,   554,   556,   560,   564,   566,
   568,   571,   573,   575,   579,   583
};

static const short amd_yyrhs[] = {    93,
    94,     0,     0,    95,     0,   133,     0,   136,     0,   104,
     0,   103,     0,    16,   145,    84,     0,    16,    96,   145,
    84,     0,    32,     0,   144,    96,    86,   139,    87,     0,
   144,    96,     0,    98,     0,    99,    83,    98,     0,    98,
     0,    98,    90,   121,     0,   100,     0,   101,    83,   100,
     0,   142,   143,    97,     0,   102,    84,     0,   102,   105,
     0,    81,   134,   106,    82,     0,     0,   106,   107,     0,
   109,    84,     0,   105,     0,    14,    86,   111,    87,   107,
   108,     0,     9,   107,    24,    86,   111,    87,    84,     0,
    24,    86,   111,    87,   107,     0,    12,    86,   110,    84,
   112,    84,   110,    87,   107,     0,    13,    86,   120,    15,
   121,    87,   107,     0,    13,    86,   120,    83,   120,    15,
   121,    87,   107,     0,    20,    86,   111,    84,   111,    87,
   105,     0,    23,   105,     5,    86,   120,    87,   105,     0,
     5,   105,     0,    21,    86,   111,    87,   105,     0,     4,
   121,    85,     0,     8,    85,     0,     3,    84,     0,     7,
    84,     0,    19,   112,    84,     0,    84,     0,     1,    84,
     0,     0,    11,   107,     0,   121,     0,   109,    83,   121,
     0,     0,   109,     0,   121,     0,     0,   111,     0,   121,
     0,   113,    83,   121,     0,     0,   113,     0,     0,   113,
     0,   113,    83,     0,   121,    85,   121,     0,   116,     0,
   117,    83,   116,     0,     0,   117,     0,   117,    83,     0,
    96,     0,    40,    96,     0,    96,    40,    96,     0,    10,
    40,    96,     0,   128,     0,   122,     0,   120,    90,   121,
     0,   120,    46,   121,     0,   120,    47,   121,     0,   120,
    48,   121,     0,   120,    49,   121,     0,   120,    50,   121,
     0,   120,    51,   121,     0,   120,    52,   121,     0,   120,
    53,   121,     0,   120,    54,   121,     0,   120,    55,   121,
     0,   120,    56,   121,     0,   123,     0,   123,    57,   109,
    85,   122,     0,   124,     0,   123,    58,   123,     0,   123,
    59,   123,     0,   123,    60,   123,     0,   123,    61,   123,
     0,   123,    62,   123,     0,   125,     0,   124,    63,   124,
     0,   124,    64,   124,     0,   124,    67,   124,     0,   124,
    68,   124,     0,   124,    66,   124,     0,   124,    65,   124,
     0,   126,     0,   125,    69,   125,     0,   125,    70,   125,
     0,   125,    71,   125,     0,   125,    72,   125,     0,   125,
    73,   125,     0,   125,    74,   125,     0,   125,    76,   125,
     0,   125,    75,   125,     0,   127,     0,    79,   126,     0,
    80,   126,     0,    77,   126,     0,    78,   126,     0,    72,
   126,     0,    73,   126,     0,   128,     0,   127,    79,     0,
   127,    80,     0,   131,     0,   128,    88,   130,   111,   129,
     0,   128,    88,   130,   111,    44,   130,   111,   129,     0,
    89,     0,    26,     0,     0,    67,     0,    18,     0,   146,
     0,   147,     0,   148,     0,   149,     0,   150,     0,    96,
     0,    31,     0,    91,    86,   109,    87,     0,    86,   109,
    87,     0,   119,    86,   114,    87,     0,    22,    86,   121,
   132,    87,     0,     5,    86,   109,    87,     0,    17,    86,
     6,    96,    87,     0,   128,    43,    96,    86,   114,    87,
     0,   128,    43,    96,     0,     0,   132,    83,   120,     0,
   142,   143,    99,    84,     0,     0,   134,   135,     0,   143,
   101,    84,     0,   142,     6,    96,    81,   137,    82,     0,
     0,   137,   138,     0,   143,    99,    84,     0,     0,    41,
     0,   140,     0,   140,    42,     0,   141,     0,   140,    83,
   141,     0,   143,    98,     0,     0,    38,   142,     0,    37,
     0,    41,     0,     6,    96,     0,     0,   144,    74,     0,
   144,    92,     0,   146,     0,   145,    71,   145,     0,   145,
    72,   145,     0,   147,     0,    33,     0,   146,    33,     0,
    35,     0,    34,     0,    27,   115,    28,     0,    25,   118,
    26,     0,    29,   109,    30,     0
};

#endif

#if YYDEBUG != 0
static const short amd_yyrline[] = { 0,
   460,   461,   465,   466,   467,   468,   469,   473,   480,   490,
   497,   507,   516,   521,   529,   533,   541,   546,   558,   585,
   592,   601,   611,   615,   623,   627,   631,   636,   640,   644,
   651,   655,   659,   663,   667,   672,   676,   686,   690,   694,
   698,   702,   706,   713,   717,   724,   728,   735,   739,   746,
   750,   754,   761,   766,   774,   778,   783,   787,   789,   794,
   809,   815,   824,   828,   830,   835,   840,   848,   857,   868,
   875,   879,   883,   887,   891,   895,   899,   903,   907,   911,
   915,   919,   923,   930,   934,   941,   945,   949,   953,   957,
   961,   969,   973,   977,   981,   985,   989,   993,  1000,  1004,
  1008,  1012,  1016,  1020,  1024,  1028,  1032,  1039,  1043,  1047,
  1051,  1055,  1059,  1063,  1070,  1074,  1078,  1085,  1089,  1093,
  1102,  1103,  1110,  1114,  1121,  1125,  1129,  1133,  1137,  1141,
  1145,  1149,  1153,  1157,  1161,  1165,  1169,  1173,  1177,  1181,
  1188,  1192,  1202,  1250,  1254,  1276,  1321,  1332,  1336,  1353,
  1391,  1395,  1399,  1403,  1411,  1416,  1424,  1439,  1443,  1459,
  1463,  1467,  1484,  1489,  1500,  1514,  1516,  1523,  1529,  1538,
  1540,  1549,  1550,  1554,  1561,  1571
};
#endif

#define YYNTOKENS 93
#define YYNNTS 58
#define YYNRULES 176
#define YYNSTATES 343
#define YYMAXUTOK 320

static const char * const amd_yytname[] = {   "$","error","$undefined.","L_BREAK",
"L_CASE","L_CATCH","L_CLASS","L_CONTINUE","L_DEFAULT","L_DO","L_EFUN","L_ELSE",
"L_FOR","L_FOREACH","L_IF","L_IN","L_INHERIT","L_NEW","L_NIL","L_RETURN","L_RLIMITS",
"L_SWITCH","L_SSCANF","L_TRY","L_WHILE","L_MAP_START","L_MAP_END","L_ARRAY_START",
"L_ARRAY_END","L_FUNCTION_START","L_FUNCTION_END","L_PARAMETER","L_IDENTIFIER",
"L_STRING","L_CHARACTER","L_INTEGER","L_HEXINTEGER","L_BASIC_TYPE","L_TYPE_MODIFIER",
"L_STATIC","L_COLONCOLON","L_VOID","L_ELLIPSIS","L_ARROW","L_RANGE","LOWER_THAN_ELSE",
"L_PLUS_EQ","L_MINUS_EQ","L_DIV_EQ","L_TIMES_EQ","L_MOD_EQ","L_AND_EQ","L_OR_EQ",
"L_XOR_EQ","L_DOT_EQ","L_LOR_EQ","L_LAND_EQ","'?'","L_LOR","L_LAND","'|'","'^'",
"'&'","L_EQ","L_NE","L_GE","L_LE","'<'","'>'","L_LSH","L_RSH","'.'","'+'","'-'",
"'*'","'%'","'/'","'!'","'~'","L_INC","L_DEC","'{'","'}'","','","';'","':'",
"'('","')'","'['","']'","'='","'$'","'#'","program","definition","inheritance",
"identifier","function_declarator","variable_declarator","variable_declarator_list",
"variable_declarator_init","variable_declarator_list_init","function_prologue",
"prototype","function","block","statement_list","statement","opt_else","list_exp",
"opt_list_exp","nv_list_exp","opt_nv_list_exp","arg_list","opt_arg_list","opt_arg_list_comma",
"assoc_exp","assoc_arg_list","opt_assoc_arg_list_comma","function_name","lvalue",
"exp","cond_exp","logical_exp","compare_exp","arith_exp","prefix_exp","postfix_exp",
"array_exp","close_square","opt_endrange","basic_exp","lvalue_list","global_decl",
"local_decls","local_decl","type_decl","class_member_list","class_member","arguments",
"argument_list","argument","type_modifier_list","type_specifier","star_list",
"string_const","string","integer","array","mapping","closure", NULL
};
static const short amd_yytoknum[] = { 0,
   256,     2,   257,   258,   259,   260,   261,   262,   263,   264,
   265,   266,   267,   268,   269,   270,   271,   272,   273,   274,
   275,   276,   277,   278,   279,   280,   281,   282,   283,   284,
   285,   286,   287,   288,   289,   290,   291,   292,   293,   294,
   295,   296,   297,   298,   299,   300,   301,   302,   303,   304,
   305,   306,   307,   308,   309,   310,    63,   311,   312,   124,
    94,    38,   313,   314,   315,   316,    60,    62,   317,   318,
    46,    43,    45,    42,    37,    47,    33,   126,   319,   320,
   123,   125,    44,    59,    58,    40,    41,    91,    93,    61,
    36,    35,     0
};

static const short amd_yyr1[] = {     0,
    93,    93,    94,    94,    94,    94,    94,    95,    95,    96,
    97,    98,    99,    99,   100,   100,   101,   101,   102,   103,
   104,   105,   106,   106,   107,   107,   107,   107,   107,   107,
   107,   107,   107,   107,   107,   107,   107,   107,   107,   107,
   107,   107,   107,   108,   108,   109,   109,   110,   110,   111,
   112,   112,   113,   113,   114,   114,   115,   115,   115,   116,
   117,   117,   118,   118,   118,   119,   119,   119,   119,   120,
   121,   121,   121,   121,   121,   121,   121,   121,   121,   121,
   121,   121,   121,   122,   122,   123,   123,   123,   123,   123,
   123,   124,   124,   124,   124,   124,   124,   124,   125,   125,
   125,   125,   125,   125,   125,   125,   125,   126,   126,   126,
   126,   126,   126,   126,   127,   127,   127,   128,   128,   128,
   129,   129,   130,   130,   131,   131,   131,   131,   131,   131,
   131,   131,   131,   131,   131,   131,   131,   131,   131,   131,
   132,   132,   133,   134,   134,   135,   136,   137,   137,   138,
   139,   139,   139,   139,   140,   140,   141,   142,   142,   143,
   143,   143,   144,   144,   144,   145,   145,   145,   145,   146,
   146,   147,   147,   148,   149,   150
};

static const short amd_yyr2[] = {     0,
     2,     0,     1,     1,     1,     1,     1,     3,     4,     1,
     5,     2,     1,     3,     1,     3,     1,     3,     3,     2,
     2,     4,     0,     2,     2,     1,     6,     7,     5,     9,
     7,     9,     7,     7,     2,     5,     3,     2,     2,     2,
     3,     1,     2,     0,     2,     1,     3,     0,     1,     1,
     0,     1,     1,     3,     0,     1,     0,     1,     2,     3,
     1,     3,     0,     1,     2,     1,     2,     3,     3,     1,
     1,     3,     3,     3,     3,     3,     3,     3,     3,     3,
     3,     3,     3,     1,     5,     1,     3,     3,     3,     3,
     3,     1,     3,     3,     3,     3,     3,     3,     1,     3,
     3,     3,     3,     3,     3,     3,     3,     1,     2,     2,
     2,     2,     2,     2,     1,     2,     2,     1,     5,     8,
     1,     1,     0,     1,     1,     1,     1,     1,     1,     1,
     1,     1,     4,     3,     4,     5,     4,     5,     6,     3,
     0,     3,     4,     0,     2,     3,     6,     0,     2,     3,
     0,     1,     1,     2,     1,     3,     2,     0,     2,     1,
     1,     2,     0,     2,     2,     1,     3,     3,     1,     1,
     2,     1,     1,     3,     3,     3
};

static const short amd_yydefact[] = {     2,
   158,     0,   158,     1,     3,     0,     7,     6,     4,     5,
     0,    10,   170,   173,   172,     0,     0,   166,   169,   159,
   144,    20,    21,     0,   160,   161,   163,     0,     0,     0,
     8,   171,    23,   162,    19,    13,     0,     0,     9,   167,
   168,     0,     0,   145,   163,   148,   163,   143,   164,   165,
    12,   162,     0,     0,     0,     0,     0,     0,     0,     0,
     0,     0,     0,     0,   125,    51,     0,     0,     0,     0,
     0,    63,    57,     0,   132,     0,     0,     0,     0,     0,
     0,     0,    22,    42,     0,     0,   131,    26,    24,     0,
     0,     0,    46,    71,    84,    86,    92,    99,   108,   115,
   118,   126,   127,   128,   129,   130,    15,    17,     0,     0,
     0,    14,   151,    43,    39,     0,     0,     0,    35,    40,
    38,     0,     0,    48,     0,     0,     0,    52,     0,    50,
     0,     0,     0,     0,     0,    61,    64,     0,     0,    58,
     0,    53,     0,    67,   113,   115,   114,   111,   112,   109,
   110,     0,     0,     0,     0,    25,    55,     0,     0,     0,
     0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
     0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
     0,     0,     0,     0,     0,     0,     0,     0,     0,   116,
   117,     0,   123,     0,   163,   146,    12,   147,   149,   163,
   161,     0,   153,   155,   163,    37,     0,     0,    69,    49,
     0,     0,    70,     0,     0,    41,     0,     0,   141,     0,
     0,    65,   175,     0,    59,   174,   176,   134,     0,    68,
    47,    56,     0,    73,    74,    75,    76,    77,    78,    79,
    80,    81,    82,    83,    72,     0,    87,    88,    89,    90,
    91,    93,    94,    98,    97,    95,    96,   100,   101,   102,
   103,   104,   105,   107,   106,   140,   124,     0,    16,    18,
     0,    11,   154,     0,   157,   137,     0,    51,     0,     0,
     0,     0,     0,     0,     0,     0,     0,    62,    60,    54,
   133,     0,   135,     0,    55,     0,   150,   156,     0,     0,
     0,     0,    44,   138,     0,    36,     0,   136,     0,    29,
    85,     0,   122,   123,   121,   119,     0,    48,     0,     0,
     0,    27,     0,   142,     0,   139,     0,    28,     0,    31,
     0,    45,    33,    34,     0,     0,     0,   120,    30,    32,
     0,     0
};

static const short amd_yydefgoto[] = {     1,
     4,     5,    87,    35,    36,    37,   108,   109,     6,     7,
     8,    88,    43,    89,   322,    90,   211,   128,   129,   232,
   233,   141,   136,   137,   138,    91,    92,    93,    94,    95,
    96,    97,    98,    99,   100,   316,   268,   101,   285,     9,
    33,    44,    10,   111,   199,   202,   203,   204,    11,   205,
   110,    17,   102,   103,   104,   105,   106
};

static const short amd_yypact[] = {-32768,
    23,   134,   -12,-32768,-32768,    73,-32768,-32768,-32768,-32768,
    19,-32768,-32768,-32768,-32768,   165,   -36,     4,-32768,-32768,
-32768,-32768,-32768,    13,-32768,-32768,-32768,    18,   165,   165,
-32768,-32768,    21,   -27,-32768,-32768,    37,    -4,-32768,    -1,
-32768,    13,   280,-32768,-32768,-32768,-32768,-32768,-32768,-32768,
    -8,-32768,    60,    67,   400,   -35,    69,    75,   369,   107,
    88,   121,   123,   129,-32768,   400,   147,   153,   159,    74,
   162,   400,   400,   400,-32768,    13,   400,   400,   400,   400,
   400,   400,-32768,-32768,   400,   172,   -23,-32768,-32768,   104,
   174,   290,-32768,-32768,   120,   348,    22,-32768,    84,   275,
-32768,     4,-32768,-32768,-32768,-32768,   115,-32768,   145,    -4,
     3,-32768,    32,-32768,-32768,   177,   181,   400,-32768,-32768,
-32768,   220,    13,   400,   179,   400,   241,-32768,   183,-32768,
   400,   400,   400,   256,   400,-32768,   186,   245,   188,   191,
   248,-32768,   -15,-32768,-32768,   -21,-32768,-32768,-32768,-32768,
-32768,   -40,   400,    13,   400,-32768,   400,   400,   400,   400,
   400,   400,   400,   400,   400,   400,   400,   400,   400,   400,
   400,   400,   400,   400,   400,   400,   400,   400,   400,   400,
   400,   400,   400,   400,   400,   400,   400,   400,   400,-32768,
-32768,    13,   210,   400,-32768,-32768,-32768,-32768,-32768,-32768,
   195,   199,   -24,-32768,-32768,-32768,   -30,   205,-32768,   213,
   222,    -7,   -21,   221,    13,-32768,   226,   229,-32768,   268,
   269,   400,-32768,   400,   400,-32768,-32768,-32768,    62,-32768,
-32768,   272,   288,-32768,-32768,-32768,-32768,-32768,-32768,-32768,
-32768,-32768,-32768,-32768,-32768,   100,   161,   175,   156,   322,
-32768,   267,   267,-32768,-32768,-32768,-32768,   390,   390,   119,
   293,   293,-32768,-32768,-32768,   299,-32768,   400,-32768,-32768,
   158,-32768,-32768,    21,-32768,-32768,   400,   400,   400,   179,
   369,   308,   400,    74,    63,   179,   369,-32768,-32768,-32768,
-32768,   400,-32768,   400,   400,    -2,-32768,-32768,   310,   315,
   319,   392,   397,-32768,   332,-32768,   179,-32768,   333,-32768,
-32768,   334,-32768,   210,-32768,-32768,   339,   400,   369,   400,
   369,-32768,    74,-32768,    74,-32768,   400,-32768,   337,-32768,
   341,-32768,-32768,-32768,   -14,   369,   369,-32768,-32768,-32768,
   426,-32768
};

static const short amd_yypgoto[] = {-32768,
-32768,-32768,    80,-32768,   -34,   230,   242,-32768,-32768,-32768,
-32768,    -6,-32768,   -57,-32768,   -69,   118,  -125,   160,   366,
   148,-32768,   223,-32768,-32768,-32768,  -121,   -52,   150,   176,
   316,    68,   421,-32768,   -48,   116,   138,-32768,-32768,-32768,
-32768,-32768,-32768,-32768,-32768,-32768,-32768,   180,   453,     8,
   430,    36,    70,   146,-32768,-32768,-32768
};


#define	YYLAST		503


static const short amd_yytable[] = {    23,
   214,   122,   117,   212,   143,   217,   218,   279,    42,   221,
   107,   313,   112,   130,   227,   152,   154,   273,    27,   139,
   142,   192,   341,   313,    24,     3,    42,    12,   146,   146,
   146,   146,   146,   146,    29,    30,    32,    42,     2,    25,
    45,   314,   155,    26,    12,    21,   228,    31,   207,   119,
   118,    28,   155,    46,   210,    25,   276,    25,   274,    26,
     3,    26,   -66,   134,    40,    41,   193,   155,    25,    49,
    30,    18,   201,   130,   315,   280,   213,   113,   130,   130,
   219,    16,   130,   229,   198,    18,   315,    50,    29,    30,
   182,   183,   184,   185,   186,   187,   188,   189,    18,    18,
   246,    39,   231,    34,   142,   234,   235,   236,   237,   238,
   239,   240,   241,   242,   243,   244,   245,    51,   200,    47,
    48,    52,   146,   146,   146,   146,   146,   146,   146,   146,
   146,   146,   146,   146,   146,   146,   146,   146,   146,   146,
   146,   269,   296,   114,   155,   307,   123,    19,   291,   308,
   115,   299,   120,    21,    21,   144,    22,   305,   302,   121,
   107,    19,   190,   191,   309,    12,    13,    14,    15,   139,
   275,   289,   290,   124,    19,    19,   170,   171,   172,   173,
   174,   175,   155,   116,   294,   324,   155,   156,    60,   197,
   185,   186,   187,   188,   189,    64,    65,    13,    14,    15,
    69,   335,   209,    72,   194,    73,   125,    74,   126,    75,
    12,    13,    14,    15,   127,   130,   174,   175,    76,   172,
   173,   174,   175,   303,   130,   130,   301,   195,   196,   310,
   130,   213,   131,   230,   173,   174,   175,   213,   132,   290,
    47,   297,   142,   208,   133,   146,   215,   135,   210,   258,
   259,   260,   261,   262,   263,   264,   265,   153,   213,   157,
   220,   330,   118,   332,    85,   206,   216,   331,   222,    86,
   223,   266,   224,   225,   130,   226,   267,   306,   339,   340,
    53,  -152,    54,    55,    56,   272,    57,    58,    59,    60,
   277,    61,    62,    63,   282,   155,    64,    65,    66,    67,
    68,    69,    70,    71,    72,   278,    73,   281,    74,   283,
    75,    12,    13,    14,    15,   284,   333,   192,   334,    76,
   -70,   -70,   -70,   -70,   -70,   -70,   -70,   -70,   -70,   -70,
   -70,   178,   179,   180,   181,   158,   159,   160,   161,   162,
   163,   164,   165,   166,   167,   168,   247,   248,   249,   250,
   251,    77,    78,   286,   292,   287,    79,    80,    81,    82,
    21,    83,   193,    84,   -70,    85,   187,   188,   189,    53,
    86,    54,    55,    56,   293,    57,    58,    59,    60,   169,
    61,    62,    63,   175,   295,    64,    65,    66,    67,    68,
    69,    70,    71,    72,   304,    73,   317,    74,   318,    75,
    12,    13,    14,    15,   116,   319,   320,   321,    76,    60,
   176,   177,   178,   179,   180,   181,    64,    65,   323,   325,
   326,    69,   328,   336,    72,   342,    73,   337,    74,   271,
    75,    12,    13,    14,    15,   329,   270,   300,   140,    76,
    77,    78,   312,   311,   288,    79,    80,    81,    82,    21,
   338,   327,    84,   298,    85,    20,    38,     0,     0,    86,
   184,   185,   186,   187,   188,   189,     0,     0,     0,     0,
     0,    77,    78,     0,     0,     0,    79,    80,    81,    82,
     0,     0,     0,     0,     0,    85,     0,     0,     0,     0,
    86,   252,   253,   254,   255,   256,   257,   145,   147,   148,
   149,   150,   151
};

static const short amd_yycheck[] = {     6,
   126,    59,    55,   125,    74,   131,   132,    15,     6,   135,
    45,    26,    47,    66,    30,    85,    40,    42,    11,    72,
    73,    43,     0,    26,     6,    38,     6,    32,    77,    78,
    79,    80,    81,    82,    71,    72,    33,     6,    16,    37,
    33,    44,    83,    41,    32,    81,    87,    84,   118,    56,
    86,    16,    83,    81,   124,    37,    87,    37,    83,    41,
    38,    41,    86,    70,    29,    30,    88,    83,    37,    74,
    72,     2,    41,   126,    89,    83,   125,    86,   131,   132,
   133,     2,   135,   153,    82,    16,    89,    92,    71,    72,
    69,    70,    71,    72,    73,    74,    75,    76,    29,    30,
   170,    84,   155,    24,   157,   158,   159,   160,   161,   162,
   163,   164,   165,   166,   167,   168,   169,    38,   111,    83,
    84,    42,   171,   172,   173,   174,   175,   176,   177,   178,
   179,   180,   181,   182,   183,   184,   185,   186,   187,   188,
   189,   194,   268,    84,    83,    83,    40,     2,    87,    87,
    84,   277,    84,    81,    81,    76,    84,   283,   280,    85,
   195,    16,    79,    80,   286,    32,    33,    34,    35,   222,
   205,   224,   225,    86,    29,    30,    57,    58,    59,    60,
    61,    62,    83,     5,    85,   307,    83,    84,    10,   110,
    72,    73,    74,    75,    76,    17,    18,    33,    34,    35,
    22,   327,   123,    25,    90,    27,    86,    29,    86,    31,
    32,    33,    34,    35,    86,   268,    61,    62,    40,    59,
    60,    61,    62,   281,   277,   278,   279,    83,    84,   287,
   283,   280,    86,   154,    60,    61,    62,   286,    86,   292,
    83,    84,   295,    24,    86,   294,     6,    86,   318,   182,
   183,   184,   185,   186,   187,   188,   189,    86,   307,    86,
     5,   319,    86,   321,    86,    85,    84,   320,    83,    91,
    26,   192,    85,    83,   327,    28,    67,   284,   336,   337,
     1,    87,     3,     4,     5,    87,     7,     8,     9,    10,
    86,    12,    13,    14,   215,    83,    17,    18,    19,    20,
    21,    22,    23,    24,    25,    84,    27,    87,    29,    84,
    31,    32,    33,    34,    35,    87,   323,    43,   325,    40,
    46,    47,    48,    49,    50,    51,    52,    53,    54,    55,
    56,    65,    66,    67,    68,    46,    47,    48,    49,    50,
    51,    52,    53,    54,    55,    56,   171,   172,   173,   174,
   175,    72,    73,    86,    83,    87,    77,    78,    79,    80,
    81,    82,    88,    84,    90,    86,    74,    75,    76,     1,
    91,     3,     4,     5,    87,     7,     8,     9,    10,    90,
    12,    13,    14,    62,    86,    17,    18,    19,    20,    21,
    22,    23,    24,    25,    87,    27,    87,    29,    84,    31,
    32,    33,    34,    35,     5,    87,    15,    11,    40,    10,
    63,    64,    65,    66,    67,    68,    17,    18,    87,    87,
    87,    22,    84,    87,    25,     0,    27,    87,    29,   200,
    31,    32,    33,    34,    35,   318,   195,   278,    73,    40,
    72,    73,   295,   294,   222,    77,    78,    79,    80,    81,
   335,   314,    84,   274,    86,     3,    27,    -1,    -1,    91,
    71,    72,    73,    74,    75,    76,    -1,    -1,    -1,    -1,
    -1,    72,    73,    -1,    -1,    -1,    77,    78,    79,    80,
    -1,    -1,    -1,    -1,    -1,    86,    -1,    -1,    -1,    -1,
    91,   176,   177,   178,   179,   180,   181,    77,    78,    79,
    80,    81,    82
};
#define YYPURE 1

/* -*-C-*-  Note some compilers choke on comments on `#line' lines.  */
#line 3 "/usr/share/bison.simple"
/* This file comes from bison-1.28.  */

/* Skeleton output parser for bison,
   Copyright (C) 1984, 1989, 1990 Free Software Foundation, Inc.

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2, or (at your option)
   any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place - Suite 330,
   Boston, MA 02111-1307, USA.  */

/* As a special exception, when this file is copied by Bison into a
   Bison output file, you may use that output file without restriction.
   This special exception was added by the Free Software Foundation
   in version 1.24 of Bison.  */

/* This is the parser code that is written into each bison parser
  when the %semantic_parser declaration is not specified in the grammar.
  It was written by Richard Stallman by simplifying the hairy parser
  used when %semantic_parser is specified.  */

#ifndef YYPARSE_RETURN_TYPE
#define YYPARSE_RETURN_TYPE int
#endif


#ifndef YYSTACK_USE_ALLOCA
#ifdef alloca
#define YYSTACK_USE_ALLOCA
#else /* alloca not defined */
#ifdef __GNUC__
#define YYSTACK_USE_ALLOCA
#define alloca __builtin_alloca
#else /* not GNU C.  */
#if (!defined (__STDC__) && defined (sparc)) || defined (__sparc__) || defined (__sparc) || defined (__sgi) || (defined (__sun) && defined (__i386))
#define YYSTACK_USE_ALLOCA
#include <alloca.h>
#else /* not sparc */
/* We think this test detects Watcom and Microsoft C.  */
/* This used to test MSDOS, but that is a bad idea
   since that symbol is in the user namespace.  */
#if (defined (_MSDOS) || defined (_MSDOS_)) && !defined (__TURBOC__)
#if 0 /* No need for malloc.h, which pollutes the namespace;
	 instead, just don't use alloca.  */
#include <malloc.h>
#endif
#else /* not MSDOS, or __TURBOC__ */
#if defined(_AIX)
/* I don't know what this was needed for, but it pollutes the namespace.
   So I turned it off.   rms, 2 May 1997.  */
/* #include <malloc.h>  */
 #pragma alloca
#define YYSTACK_USE_ALLOCA
#else /* not MSDOS, or __TURBOC__, or _AIX */
#if 0
#ifdef __hpux /* haible@ilog.fr says this works for HPUX 9.05 and up,
		 and on HPUX 10.  Eventually we can turn this on.  */
#define YYSTACK_USE_ALLOCA
#define alloca __builtin_alloca
#endif /* __hpux */
#endif
#endif /* not _AIX */
#endif /* not MSDOS, or __TURBOC__ */
#endif /* not sparc */
#endif /* not GNU C */
#endif /* alloca not defined */
#endif /* YYSTACK_USE_ALLOCA not defined */

#ifdef YYSTACK_USE_ALLOCA
#define YYSTACK_ALLOC alloca
#else
#define YYSTACK_ALLOC malloc
#endif

/* Note: there must be only one dollar sign in this file.
   It is replaced by the list of actions, each action
   as one case of the switch.  */

#define amd_yyerrok		(amd_yyerrstatus = 0)
#define amd_yyclearin	(amd_yychar = YYEMPTY)
#define YYEMPTY		-2
#define YYEOF		0
#define YYACCEPT	goto amd_yyacceptlab
#define YYABORT 	goto amd_yyabortlab
#define YYERROR		goto amd_yyerrlab1
/* Like YYERROR except do call amd_yyerror.
   This remains here temporarily to ease the
   transition to the new meaning of YYERROR, for GCC.
   Once GCC version 2 has supplanted version 1, this can go.  */
#define YYFAIL		goto amd_yyerrlab
#define YYRECOVERING()  (!!amd_yyerrstatus)
#define YYBACKUP(token, value) \
do								\
  if (amd_yychar == YYEMPTY && amd_yylen == 1)				\
    { amd_yychar = (token), amd_yylval = (value);			\
      amd_yychar1 = YYTRANSLATE (amd_yychar);				\
      YYPOPSTACK;						\
      goto amd_yybackup;						\
    }								\
  else								\
    { amd_yyerror ("syntax error: cannot back up"); YYERROR; }	\
while (0)

#define YYTERROR	1
#define YYERRCODE	256

#ifndef YYPURE
#define YYLEX		amd_yylex()
#endif

#ifdef YYPURE
#ifdef YYLSP_NEEDED
#ifdef YYLEX_PARAM
#define YYLEX		amd_yylex(&amd_yylval, &amd_yylloc, YYLEX_PARAM)
#else
#define YYLEX		amd_yylex(&amd_yylval, &amd_yylloc)
#endif
#else /* not YYLSP_NEEDED */
#ifdef YYLEX_PARAM
#define YYLEX		amd_yylex(&amd_yylval, YYLEX_PARAM)
#else
#define YYLEX		amd_yylex(&amd_yylval)
#endif
#endif /* not YYLSP_NEEDED */
#endif

/* If nonreentrant, generate the variables here */

#ifndef YYPURE

int	amd_yychar;			/*  the lookahead symbol		*/
AMD_YYSTYPE	amd_yylval;			/*  the semantic value of the		*/
				/*  lookahead symbol			*/

#ifdef YYLSP_NEEDED
YYLTYPE amd_yylloc;			/*  location data for the lookahead	*/
				/*  symbol				*/
#endif

int amd_yynerrs;			/*  number of parse errors so far       */
#endif  /* not YYPURE */

#if YYDEBUG != 0
int amd_yydebug;			/*  nonzero means print parse trace	*/
/* Since this is uninitialized, it does not stop multiple parsers
   from coexisting.  */
#endif

/*  YYINITDEPTH indicates the initial size of the parser's stacks	*/

#ifndef	YYINITDEPTH
#define YYINITDEPTH 200
#endif

/*  YYMAXDEPTH is the maximum size the stacks can grow to
    (effective only if the built-in stack extension method is used).  */

#if YYMAXDEPTH == 0
#undef YYMAXDEPTH
#endif

#ifndef YYMAXDEPTH
#define YYMAXDEPTH 10000
#endif

/* Define __yy_memcpy.  Note that the size argument
   should be passed with type unsigned int, because that is what the non-GCC
   definitions require.  With GCC, __builtin_memcpy takes an arg
   of type size_t, but it can handle unsigned int.  */

#if __GNUC__ > 1		/* GNU C and GNU C++ define this.  */
#define __yy_memcpy(TO,FROM,COUNT)	__builtin_memcpy(TO,FROM,COUNT)
#else				/* not GNU C or C++ */
#ifndef __cplusplus

/* This is the most reliable way to avoid incompatibilities
   in available built-in functions on various systems.  */
static void
__yy_memcpy (to, from, count)
     char *to;
     char *from;
     unsigned int count;
{
  register char *f = from;
  register char *t = to;
  register int i = count;

  while (i-- > 0)
    *t++ = *f++;
}

#else /* __cplusplus */

/* This is the most reliable way to avoid incompatibilities
   in available built-in functions on various systems.  */
static void
__yy_memcpy (char *to, char *from, unsigned int count)
{
  register char *t = to;
  register char *f = from;
  register int i = count;

  while (i-- > 0)
    *t++ = *f++;
}

#endif
#endif

#line 222 "/usr/share/bison.simple"

/* The user can define YYPARSE_PARAM as the name of an argument to be passed
   into amd_yyparse.  The argument should have type void *.
   It should actually point to an object.
   Grammar actions can access the variable by casting it
   to the proper pointer type.  */

#ifdef YYPARSE_PARAM
#ifdef __cplusplus
#define YYPARSE_PARAM_ARG void *YYPARSE_PARAM
#define YYPARSE_PARAM_DECL
#else /* not __cplusplus */
#define YYPARSE_PARAM_ARG YYPARSE_PARAM
#define YYPARSE_PARAM_DECL void *YYPARSE_PARAM;
#endif /* not __cplusplus */
#else /* not YYPARSE_PARAM */
#define YYPARSE_PARAM_ARG
#define YYPARSE_PARAM_DECL
#endif /* not YYPARSE_PARAM */

/* Prevent warning if -Wstrict-prototypes.  */
#ifdef __GNUC__
#ifdef YYPARSE_PARAM
YYPARSE_RETURN_TYPE
amd_yyparse (void *);
#else
YYPARSE_RETURN_TYPE
amd_yyparse (void);
#endif
#endif

YYPARSE_RETURN_TYPE
amd_yyparse(YYPARSE_PARAM_ARG)
     YYPARSE_PARAM_DECL
{
  register int amd_yystate;
  register int amd_yyn;
  register short *amd_yyssp;
  register AMD_YYSTYPE *amd_yyvsp;
  int amd_yyerrstatus;	/*  number of tokens to shift before error messages enabled */
  int amd_yychar1 = 0;		/*  lookahead token as an internal (translated) token number */

  short	amd_yyssa[YYINITDEPTH];	/*  the state stack			*/
  AMD_YYSTYPE amd_yyvsa[YYINITDEPTH];	/*  the semantic value stack		*/

  short *amd_yyss = amd_yyssa;		/*  refer to the stacks thru separate pointers */
  AMD_YYSTYPE *amd_yyvs = amd_yyvsa;	/*  to allow amd_yyoverflow to reallocate them elsewhere */

#ifdef YYLSP_NEEDED
  YYLTYPE amd_yylsa[YYINITDEPTH];	/*  the location stack			*/
  YYLTYPE *amd_yyls = amd_yylsa;
  YYLTYPE *amd_yylsp;

#define YYPOPSTACK   (amd_yyvsp--, amd_yyssp--, amd_yylsp--)
#else
#define YYPOPSTACK   (amd_yyvsp--, amd_yyssp--)
#endif

  int amd_yystacksize = YYINITDEPTH;
#ifndef YYSTACK_USE_ALLOCA
  int amd_yyfree_stacks = 0;
#endif

#ifdef YYPURE
  int amd_yychar;
  AMD_YYSTYPE amd_yylval;
  int amd_yynerrs;
#ifdef YYLSP_NEEDED
  YYLTYPE amd_yylloc;
#endif
#endif

  AMD_YYSTYPE amd_yyval;		/*  the variable used to return		*/
				/*  semantic values from the action	*/
				/*  routines				*/

  int amd_yylen;

#if YYDEBUG != 0
  if (amd_yydebug)
    fprintf(stderr, "Starting parse\n");
#endif

  amd_yystate = 0;
  amd_yyerrstatus = 0;
  amd_yynerrs = 0;
  amd_yychar = YYEMPTY;		/* Cause a token to be read.  */

  /* Initialize stack pointers.
     Waste one element of value and location stack
     so that they stay on the same level as the state stack.
     The wasted elements are never initialized.  */

  amd_yyssp = amd_yyss - 1;
  amd_yyvsp = amd_yyvs;
#ifdef YYLSP_NEEDED
  amd_yylsp = amd_yyls;
#endif

/* Push a new state, which is found in  amd_yystate  .  */
/* In all cases, when you get here, the value and location stacks
   have just been pushed. so pushing a state here evens the stacks.  */
amd_yynewstate:

  *++amd_yyssp = amd_yystate;

  if (amd_yyssp >= amd_yyss + amd_yystacksize - 1)
    {
      /* Give user a chance to reallocate the stack */
      /* Use copies of these so that the &'s don't force the real ones into memory. */
      AMD_YYSTYPE *amd_yyvs1 = amd_yyvs;
      short *amd_yyss1 = amd_yyss;
#ifdef YYLSP_NEEDED
      YYLTYPE *amd_yyls1 = amd_yyls;
#endif

      /* Get the current used size of the three stacks, in elements.  */
      int size = amd_yyssp - amd_yyss + 1;

#ifdef amd_yyoverflow
      /* Each stack pointer address is followed by the size of
	 the data in use in that stack, in bytes.  */
#ifdef YYLSP_NEEDED
      /* This used to be a conditional around just the two extra args,
	 but that might be undefined if amd_yyoverflow is a macro.  */
      amd_yyoverflow("parser stack overflow",
		 &amd_yyss1, size * sizeof (*amd_yyssp),
		 &amd_yyvs1, size * sizeof (*amd_yyvsp),
		 &amd_yyls1, size * sizeof (*amd_yylsp),
		 &amd_yystacksize);
#else
      amd_yyoverflow("parser stack overflow",
		 &amd_yyss1, size * sizeof (*amd_yyssp),
		 &amd_yyvs1, size * sizeof (*amd_yyvsp),
		 &amd_yystacksize);
#endif

      amd_yyss = amd_yyss1; amd_yyvs = amd_yyvs1;
#ifdef YYLSP_NEEDED
      amd_yyls = amd_yyls1;
#endif
#else /* no amd_yyoverflow */
      /* Extend the stack our own way.  */
      if (amd_yystacksize >= YYMAXDEPTH)
	{
	  amd_yyerror("parser stack overflow");
#ifndef YYSTACK_USE_ALLOCA
	  if (amd_yyfree_stacks)
	    {
	      free (amd_yyss);
	      free (amd_yyvs);
#ifdef YYLSP_NEEDED
	      free (amd_yyls);
#endif
	    }
#endif	    
	  return 2;
	}
      amd_yystacksize *= 2;
      if (amd_yystacksize > YYMAXDEPTH)
	amd_yystacksize = YYMAXDEPTH;
#ifndef YYSTACK_USE_ALLOCA
      amd_yyfree_stacks = 1;
#endif
      amd_yyss = (short *) YYSTACK_ALLOC (amd_yystacksize * sizeof (*amd_yyssp));
      __yy_memcpy ((char *)amd_yyss, (char *)amd_yyss1,
		   size * (unsigned int) sizeof (*amd_yyssp));
      amd_yyvs = (AMD_YYSTYPE *) YYSTACK_ALLOC (amd_yystacksize * sizeof (*amd_yyvsp));
      __yy_memcpy ((char *)amd_yyvs, (char *)amd_yyvs1,
		   size * (unsigned int) sizeof (*amd_yyvsp));
#ifdef YYLSP_NEEDED
      amd_yyls = (YYLTYPE *) YYSTACK_ALLOC (amd_yystacksize * sizeof (*amd_yylsp));
      __yy_memcpy ((char *)amd_yyls, (char *)amd_yyls1,
		   size * (unsigned int) sizeof (*amd_yylsp));
#endif
#endif /* no amd_yyoverflow */

      amd_yyssp = amd_yyss + size - 1;
      amd_yyvsp = amd_yyvs + size - 1;
#ifdef YYLSP_NEEDED
      amd_yylsp = amd_yyls + size - 1;
#endif

#if YYDEBUG != 0
      if (amd_yydebug)
	fprintf(stderr, "Stack size increased to %d\n", amd_yystacksize);
#endif

      if (amd_yyssp >= amd_yyss + amd_yystacksize - 1)
	YYABORT;
    }

#if YYDEBUG != 0
  if (amd_yydebug)
    fprintf(stderr, "Entering state %d\n", amd_yystate);
#endif

  goto amd_yybackup;
 amd_yybackup:

/* Do appropriate processing given the current state.  */
/* Read a lookahead token if we need one and don't already have one.  */
/* amd_yyresume: */

  /* First try to decide what to do without reference to lookahead token.  */

  amd_yyn = amd_yypact[amd_yystate];
  if (amd_yyn == YYFLAG)
    goto amd_yydefault;

  /* Not known => get a lookahead token if don't already have one.  */

  /* amd_yychar is either YYEMPTY or YYEOF
     or a valid token in external form.  */

  if (amd_yychar == YYEMPTY)
    {
#if YYDEBUG != 0
      if (amd_yydebug)
	fprintf(stderr, "Reading a token: ");
#endif
      amd_yychar = YYLEX;
    }

  /* Convert token to internal form (in amd_yychar1) for indexing tables with */

  if (amd_yychar <= 0)		/* This means end of input. */
    {
      amd_yychar1 = 0;
      amd_yychar = YYEOF;		/* Don't call YYLEX any more */

#if YYDEBUG != 0
      if (amd_yydebug)
	fprintf(stderr, "Now at end of input.\n");
#endif
    }
  else
    {
      amd_yychar1 = YYTRANSLATE(amd_yychar);

#if YYDEBUG != 0
      if (amd_yydebug)
	{
	  fprintf (stderr, "Next token is %d (%s", amd_yychar, amd_yytname[amd_yychar1]);
	  /* Give the individual parser a way to print the precise meaning
	     of a token, for further debugging info.  */
#ifdef YYPRINT
	  YYPRINT (stderr, amd_yychar, amd_yylval);
#endif
	  fprintf (stderr, ")\n");
	}
#endif
    }

  amd_yyn += amd_yychar1;
  if (amd_yyn < 0 || amd_yyn > YYLAST || amd_yycheck[amd_yyn] != amd_yychar1)
    goto amd_yydefault;

  amd_yyn = amd_yytable[amd_yyn];

  /* amd_yyn is what to do for this token type in this state.
     Negative => reduce, -amd_yyn is rule number.
     Positive => shift, amd_yyn is new state.
       New state is final state => don't bother to shift,
       just return success.
     0, or most negative number => error.  */

  if (amd_yyn < 0)
    {
      if (amd_yyn == YYFLAG)
	goto amd_yyerrlab;
      amd_yyn = -amd_yyn;
      goto amd_yyreduce;
    }
  else if (amd_yyn == 0)
    goto amd_yyerrlab;

  if (amd_yyn == YYFINAL)
    YYACCEPT;

  /* Shift the lookahead token.  */

#if YYDEBUG != 0
  if (amd_yydebug)
    fprintf(stderr, "Shifting token %d (%s), ", amd_yychar, amd_yytname[amd_yychar1]);
#endif

  /* Discard the token being shifted unless it is eof.  */
  if (amd_yychar != YYEOF)
    amd_yychar = YYEMPTY;

  *++amd_yyvsp = amd_yylval;
#ifdef YYLSP_NEEDED
  *++amd_yylsp = amd_yylloc;
#endif

  /* count tokens shifted since error; after three, turn off error status.  */
  if (amd_yyerrstatus) amd_yyerrstatus--;

  amd_yystate = amd_yyn;
  goto amd_yynewstate;

/* Do the default action for the current state.  */
amd_yydefault:

  amd_yyn = amd_yydefact[amd_yystate];
  if (amd_yyn == 0)
    goto amd_yyerrlab;

/* Do a reduction.  amd_yyn is the number of a rule to reduce with.  */
amd_yyreduce:
  amd_yylen = amd_yyr2[amd_yyn];
  if (amd_yylen > 0)
    amd_yyval = amd_yyvsp[1-amd_yylen]; /* implement default value of the action */

#if YYDEBUG != 0
  if (amd_yydebug)
    {
      int i;

      fprintf (stderr, "Reducing via rule %d (line %d), ",
	       amd_yyn, amd_yyrline[amd_yyn]);

      /* Print the symbols being reduced, and their result.  */
      for (i = amd_yyprhs[amd_yyn]; amd_yyrhs[i] > 0; i++)
	fprintf (stderr, "%s ", amd_yytname[amd_yyrhs[i]]);
      fprintf (stderr, " -> %s\n", amd_yytname[amd_yyr1[amd_yyn]]);
    }
#endif


  switch (amd_yyn) {

case 8:
#line 474 "parser.y"
{
			/* printf("Inheriting %s\n", SvPVX($2)); */
			SvREFCNT_dec(
				amd_yyparse_program_apply(amd_yyparse_param,
						"inherit", &PL_sv_undef, amd_yyvsp[-1].sv));
		;
    break;}
case 9:
#line 481 "parser.y"
{
			printf("Inheriting %s as %s\n", SvPVX(amd_yyvsp[-1].sv), SvPVX(amd_yyvsp[-2].sv));
			SvREFCNT_dec(
				amd_yyparse_program_apply(amd_yyparse_param,
						"inherit", amd_yyvsp[-2].sv, amd_yyvsp[-1].sv));
		;
    break;}
case 10:
#line 491 "parser.y"
{
			amd_yyval.sv = amd_yyvsp[0].sv;
		;
    break;}
case 11:
#line 498 "parser.y"
{
			amd_yyval.av = newAV();
			av_push(amd_yyval.av, amd_yyvsp[-4].sv);
			av_push(amd_yyval.av, amd_yyvsp[-3].sv);
			av_push(amd_yyval.av, newRV_noinc((SV *)(amd_yyvsp[-1].av)));
		;
    break;}
case 12:
#line 508 "parser.y"
{
			amd_yyval.av = newAV();
			av_push(amd_yyval.av, amd_yyvsp[-1].sv);
			av_push(amd_yyval.av, amd_yyvsp[0].sv);
		;
    break;}
case 13:
#line 517 "parser.y"
{
			amd_yyval.av = newAV();
			av_push(amd_yyval.av, newRV_noinc((SV *)(amd_yyvsp[0].av)));
		;
    break;}
case 14:
#line 522 "parser.y"
{
			amd_yyval.av = amd_yyvsp[-2].av;
			av_push(amd_yyval.av, newRV_noinc((SV *)(amd_yyvsp[0].av)));
		;
    break;}
case 15:
#line 530 "parser.y"
{
			amd_yyval.av = amd_yyvsp[0].av;
		;
    break;}
case 16:
#line 534 "parser.y"
{
			av_push(amd_yyvsp[-2].av, amd_yyvsp[0].obj);
			amd_yyval.av = amd_yyvsp[-2].av;
		;
    break;}
case 17:
#line 542 "parser.y"
{
			amd_yyval.av = newAV();
			av_push(amd_yyval.av, newRV_noinc((SV *)(amd_yyvsp[0].av)));
		;
    break;}
case 18:
#line 547 "parser.y"
{
			amd_yyval.av = amd_yyvsp[-2].av;
			av_push(amd_yyval.av, newRV_noinc((SV *)(amd_yyvsp[0].av)));
		;
    break;}
case 19:
#line 559 "parser.y"
{
			SV	*method;
			const char	*type;
			SV	*stars;
			SV	*name;
			SV	*args;
			SV	*mods;

			type = amd_yyvsp[-1].str;
			stars = *( av_fetch(amd_yyvsp[0].av, 0, FALSE) );
			name = *( av_fetch(amd_yyvsp[0].av, 1, FALSE) );
			args = *( av_fetch(amd_yyvsp[0].av, 2, FALSE) );
			mods = newSViv(amd_yyvsp[-2].number);

			method = amd_yyparse_method(name, type, stars, args, mods);

			/* Check that this is the empty list. */
			SvREFCNT_dec(
				amd_yyparse_program_apply(amd_yyparse_param,
								"method", name, method));

			amd_yyval.sv = method;
		;
    break;}
case 20:
#line 586 "parser.y"
{
			SvREFCNT_dec(amd_yyvsp[-1].sv);
		;
    break;}
case 21:
#line 593 "parser.y"
{
			/* $1->code($2); */
			amd_yyparse_method_add_code(amd_yyvsp[-1].sv, amd_yyvsp[0].obj);
			SvREFCNT_dec(amd_yyvsp[-1].sv);
		;
    break;}
case 22:
#line 602 "parser.y"
{
			amd_yyval.obj = N_A2("Block",
					newRV_noinc((SV *)(amd_yyvsp[-2].av)),
					newRV_noinc((SV *)(amd_yyvsp[-1].av)));
			// amd_dump("Block locals", sv_2mortal(newRV_noinc((SV *)($2))));
		;
    break;}
case 23:
#line 612 "parser.y"
{
			amd_yyval.av = newAV();
		;
    break;}
case 24:
#line 616 "parser.y"
{
			av_push(amd_yyvsp[-1].av, amd_yyvsp[0].obj);
			amd_yyval.av = amd_yyvsp[-1].av;
		;
    break;}
case 25:
#line 624 "parser.y"
{
			amd_yyval.obj = N_A1("StmtExp", amd_yyvsp[-1].obj);
		;
    break;}
case 26:
#line 628 "parser.y"
{
			amd_yyval.obj = amd_yyvsp[0].obj;
		;
    break;}
case 27:
#line 632 "parser.y"
{
			/* if ($6 == &PL_sv_undef) - use StmtIfElse */
			amd_yyval.obj = N_A3("StmtIf", amd_yyvsp[-3].obj, amd_yyvsp[-1].obj, amd_yyvsp[0].obj);
		;
    break;}
case 28:
#line 637 "parser.y"
{
			amd_yyval.obj = N_A2("StmtDo", amd_yyvsp[-2].obj, amd_yyvsp[-5].obj);
		;
    break;}
case 29:
#line 641 "parser.y"
{
			amd_yyval.obj = N_A2("StmtWhile", amd_yyvsp[-2].obj, amd_yyvsp[0].obj);
		;
    break;}
case 30:
#line 648 "parser.y"
{
			amd_yyval.obj = N_A4("StmtFor", amd_yyvsp[-6].obj, amd_yyvsp[-4].obj, amd_yyvsp[-2].obj, amd_yyvsp[0].obj);
		;
    break;}
case 31:
#line 652 "parser.y"
{
			amd_yyval.obj = N_A4("StmtForeach", amd_yyvsp[-4].obj, &PL_sv_undef, amd_yyvsp[-2].obj, amd_yyvsp[0].obj);
		;
    break;}
case 32:
#line 656 "parser.y"
{
			amd_yyval.obj = N_A4("StmtForeach", amd_yyvsp[-6].obj, amd_yyvsp[-4].obj, amd_yyvsp[-2].obj, amd_yyvsp[0].obj);
		;
    break;}
case 33:
#line 660 "parser.y"
{
			amd_yyval.obj = N_A3("StmtRlimits", amd_yyvsp[-4].obj, amd_yyvsp[-2].obj, amd_yyvsp[0].obj);
		;
    break;}
case 34:
#line 664 "parser.y"
{
			amd_yyval.obj = N_A3("StmtTry", amd_yyvsp[-5].obj, amd_yyvsp[-2].obj, amd_yyvsp[0].obj);
		;
    break;}
case 35:
#line 668 "parser.y"
{
			/* A MudOS hack */
			amd_yyval.obj = N_A1("StmtCatch", amd_yyvsp[0].obj);
		;
    break;}
case 36:
#line 673 "parser.y"
{
			amd_yyval.obj = N_A2("StmtSwitch", amd_yyvsp[-2].obj, amd_yyvsp[0].obj);
		;
    break;}
case 37:
#line 677 "parser.y"
{
			amd_yyval.obj = N_A2("StmtCase", amd_yyvsp[-1].obj, &PL_sv_undef);
		;
    break;}
case 38:
#line 687 "parser.y"
{
			amd_yyval.obj = N_A0("StmtDefault");
		;
    break;}
case 39:
#line 691 "parser.y"
{
			amd_yyval.obj = N_A0("StmtBreak");
		;
    break;}
case 40:
#line 695 "parser.y"
{
			amd_yyval.obj = N_A0("StmtContinue");
		;
    break;}
case 41:
#line 699 "parser.y"
{
			amd_yyval.obj = N_A1("StmtReturn", amd_yyvsp[-1].obj);
		;
    break;}
case 42:
#line 703 "parser.y"
{
			amd_yyval.obj = N_A0("StmtNull");
		;
    break;}
case 43:
#line 707 "parser.y"
{
			amd_yyval.obj = N_A0("StmtNull");
		;
    break;}
case 44:
#line 714 "parser.y"
{
			amd_yyval.obj = &PL_sv_undef;
		;
    break;}
case 45:
#line 718 "parser.y"
{
			amd_yyval.obj = amd_yyvsp[0].obj;
		;
    break;}
case 46:
#line 725 "parser.y"
{
			amd_yyval.obj = amd_yyvsp[0].obj;
		;
    break;}
case 47:
#line 729 "parser.y"
{
			amd_yyval.obj = N_A2("ExpComma", amd_yyvsp[-2].obj, amd_yyvsp[0].obj);
		;
    break;}
case 48:
#line 736 "parser.y"
{
			amd_yyval.obj = &PL_sv_undef;
		;
    break;}
case 49:
#line 740 "parser.y"
{
			amd_yyval.obj = amd_yyvsp[0].obj;
		;
    break;}
case 51:
#line 751 "parser.y"
{
			amd_yyval.obj = &PL_sv_undef;
		;
    break;}
case 52:
#line 755 "parser.y"
{
			amd_yyval.obj = amd_yyvsp[0].obj;
		;
    break;}
case 53:
#line 762 "parser.y"
{
			amd_yyval.av = newAV();
			av_push(amd_yyval.av, amd_yyvsp[0].obj);
		;
    break;}
case 54:
#line 767 "parser.y"
{
			av_push(amd_yyvsp[-2].av, amd_yyvsp[0].obj);
			amd_yyval.av = amd_yyvsp[-2].av;
		;
    break;}
case 55:
#line 775 "parser.y"
{
			amd_yyval.av = newAV();
		;
    break;}
case 57:
#line 784 "parser.y"
{
			amd_yyval.av = newAV();
		;
    break;}
case 60:
#line 795 "parser.y"
{
			amd_yyval.assoc.key = amd_yyvsp[-2].obj;
			amd_yyval.assoc.value = amd_yyvsp[0].obj;
			/*
			AV	*av;
			av = newAV();
			av_push(av, $1);
			av_push(av, $3);
			$$ = newRV_noinc((SV *)av);
			*/
		;
    break;}
case 61:
#line 810 "parser.y"
{
			amd_yyval.av = newAV();
			av_push(amd_yyval.av, amd_yyvsp[0].assoc.key);
			av_push(amd_yyval.av, amd_yyvsp[0].assoc.value);
		;
    break;}
case 62:
#line 816 "parser.y"
{
			av_push(amd_yyvsp[-2].av, amd_yyvsp[0].assoc.key);
			av_push(amd_yyvsp[-2].av, amd_yyvsp[0].assoc.value);
			amd_yyval.av = amd_yyvsp[-2].av;
		;
    break;}
case 63:
#line 825 "parser.y"
{
			amd_yyval.av = newAV();
		;
    break;}
case 66:
#line 836 "parser.y"
{
			amd_yyval.obj = amd_yyparse_program_apply(amd_yyparse_param,
							"method", amd_yyvsp[0].sv, NULL);
		;
    break;}
case 67:
#line 841 "parser.y"
{
			SV	*name;
			name = newSVpv("::", 2);
			sv_catsv(name, amd_yyvsp[0].sv);
			amd_yyval.obj = amd_yyparse_program_apply(amd_yyparse_param,
							"method", sv_2mortal(name), NULL);
		;
    break;}
case 68:
#line 849 "parser.y"
{
			SV	*name;
			name = newSVsv(amd_yyvsp[-2].sv);
			sv_catpv(name, "::");
			sv_catsv(name, amd_yyvsp[0].sv);
			amd_yyval.obj = amd_yyparse_program_apply(amd_yyparse_param,
							"method", sv_2mortal(name), NULL);
		;
    break;}
case 69:
#line 858 "parser.y"
{
			SV	*name;
			name = newSVpv("efun::", 6);
			sv_catsv(name, amd_yyvsp[0].sv);
			amd_yyval.obj = amd_yyparse_program_apply(amd_yyparse_param,
							"method", sv_2mortal(name), NULL);
		;
    break;}
case 70:
#line 869 "parser.y"
{
			amd_yyval.obj = amd_yyvsp[0].obj;
		;
    break;}
case 71:
#line 876 "parser.y"
{
			amd_yyval.obj = amd_yyvsp[0].obj;
		;
    break;}
case 72:
#line 880 "parser.y"
{
			amd_yyval.obj = N_A2("Assign", amd_yyvsp[-2].obj, amd_yyvsp[0].obj);
		;
    break;}
case 73:
#line 884 "parser.y"
{
			amd_yyval.obj = N_A2("AddEq", amd_yyvsp[-2].obj, amd_yyvsp[0].obj);
		;
    break;}
case 74:
#line 888 "parser.y"
{
			amd_yyval.obj = N_A2("SubEq", amd_yyvsp[-2].obj, amd_yyvsp[0].obj);
		;
    break;}
case 75:
#line 892 "parser.y"
{
			amd_yyval.obj = N_A2("DivEq", amd_yyvsp[-2].obj, amd_yyvsp[0].obj);
		;
    break;}
case 76:
#line 896 "parser.y"
{
			amd_yyval.obj = N_A2("MulEq", amd_yyvsp[-2].obj, amd_yyvsp[0].obj);
		;
    break;}
case 77:
#line 900 "parser.y"
{
			amd_yyval.obj = N_A2("ModEq", amd_yyvsp[-2].obj, amd_yyvsp[0].obj);
		;
    break;}
case 78:
#line 904 "parser.y"
{
			amd_yyval.obj = N_A2("AndEq", amd_yyvsp[-2].obj, amd_yyvsp[0].obj);
		;
    break;}
case 79:
#line 908 "parser.y"
{
			amd_yyval.obj = N_A2("OrEq", amd_yyvsp[-2].obj, amd_yyvsp[0].obj);
		;
    break;}
case 80:
#line 912 "parser.y"
{
			amd_yyval.obj = N_A2("XorEq", amd_yyvsp[-2].obj, amd_yyvsp[0].obj);
		;
    break;}
case 81:
#line 916 "parser.y"
{
			amd_yyval.obj = N_A2("StrAddEq", amd_yyvsp[-2].obj, amd_yyvsp[0].obj);
		;
    break;}
case 82:
#line 920 "parser.y"
{
			amd_yyval.obj = N_A2("LogOrEq", amd_yyvsp[-2].obj, amd_yyvsp[0].obj);
		;
    break;}
case 83:
#line 924 "parser.y"
{
			amd_yyval.obj = N_A2("LogAndEq", amd_yyvsp[-2].obj, amd_yyvsp[0].obj);
		;
    break;}
case 84:
#line 931 "parser.y"
{
			amd_yyval.obj = amd_yyvsp[0].obj;
		;
    break;}
case 85:
#line 935 "parser.y"
{
			amd_yyval.obj = N_A3("ExpCond", amd_yyvsp[-4].obj, amd_yyvsp[-2].obj, amd_yyvsp[0].obj);
		;
    break;}
case 86:
#line 942 "parser.y"
{
			amd_yyval.obj = amd_yyvsp[0].obj;
		;
    break;}
case 87:
#line 946 "parser.y"
{
			amd_yyval.obj = N_A2("LogOr", amd_yyvsp[-2].obj, amd_yyvsp[0].obj);
		;
    break;}
case 88:
#line 950 "parser.y"
{
			amd_yyval.obj = N_A2("LogAnd", amd_yyvsp[-2].obj, amd_yyvsp[0].obj);
		;
    break;}
case 89:
#line 954 "parser.y"
{
			amd_yyval.obj = N_A2("Or", amd_yyvsp[-2].obj, amd_yyvsp[0].obj);
		;
    break;}
case 90:
#line 958 "parser.y"
{
			amd_yyval.obj = N_A2("Xor", amd_yyvsp[-2].obj, amd_yyvsp[0].obj);
		;
    break;}
case 91:
#line 962 "parser.y"
{
			amd_yyval.obj = N_A2("And", amd_yyvsp[-2].obj, amd_yyvsp[0].obj);
		;
    break;}
case 92:
#line 970 "parser.y"
{
			amd_yyval.obj = amd_yyvsp[0].obj;
		;
    break;}
case 93:
#line 974 "parser.y"
{
			amd_yyval.obj = N_A2("Eq", amd_yyvsp[-2].obj, amd_yyvsp[0].obj);
		;
    break;}
case 94:
#line 978 "parser.y"
{
			amd_yyval.obj = N_A2("Ne", amd_yyvsp[-2].obj, amd_yyvsp[0].obj);
		;
    break;}
case 95:
#line 982 "parser.y"
{
			amd_yyval.obj = N_A2("Lt", amd_yyvsp[-2].obj, amd_yyvsp[0].obj);
		;
    break;}
case 96:
#line 986 "parser.y"
{
			amd_yyval.obj = N_A2("Gt", amd_yyvsp[-2].obj, amd_yyvsp[0].obj);
		;
    break;}
case 97:
#line 990 "parser.y"
{
			amd_yyval.obj = N_A2("Le", amd_yyvsp[-2].obj, amd_yyvsp[0].obj);
		;
    break;}
case 98:
#line 994 "parser.y"
{
			amd_yyval.obj = N_A2("Ge", amd_yyvsp[-2].obj, amd_yyvsp[0].obj);
		;
    break;}
case 99:
#line 1001 "parser.y"
{
			amd_yyval.obj = amd_yyvsp[0].obj;
		;
    break;}
case 100:
#line 1005 "parser.y"
{
			amd_yyval.obj = N_A2("Lsh", amd_yyvsp[-2].obj, amd_yyvsp[0].obj);
		;
    break;}
case 101:
#line 1009 "parser.y"
{
			amd_yyval.obj = N_A2("Rsh", amd_yyvsp[-2].obj, amd_yyvsp[0].obj);
		;
    break;}
case 102:
#line 1013 "parser.y"
{
			amd_yyval.obj = N_A2("StrAdd", amd_yyvsp[-2].obj, amd_yyvsp[0].obj);
		;
    break;}
case 103:
#line 1017 "parser.y"
{
			amd_yyval.obj = N_A2("Add", amd_yyvsp[-2].obj, amd_yyvsp[0].obj);
		;
    break;}
case 104:
#line 1021 "parser.y"
{
			amd_yyval.obj = N_A2("Sub", amd_yyvsp[-2].obj, amd_yyvsp[0].obj);
		;
    break;}
case 105:
#line 1025 "parser.y"
{
			amd_yyval.obj = N_A2("Mul", amd_yyvsp[-2].obj, amd_yyvsp[0].obj);
		;
    break;}
case 106:
#line 1029 "parser.y"
{
			amd_yyval.obj = N_A2("Div", amd_yyvsp[-2].obj, amd_yyvsp[0].obj);
		;
    break;}
case 107:
#line 1033 "parser.y"
{
			amd_yyval.obj = N_A2("Mod", amd_yyvsp[-2].obj, amd_yyvsp[0].obj);
		;
    break;}
case 108:
#line 1040 "parser.y"
{
			amd_yyval.obj = amd_yyvsp[0].obj;
		;
    break;}
case 109:
#line 1044 "parser.y"
{
			amd_yyval.obj = N_A1("Preinc", amd_yyvsp[0].obj);
		;
    break;}
case 110:
#line 1048 "parser.y"
{
			amd_yyval.obj = N_A1("Predec", amd_yyvsp[0].obj);
		;
    break;}
case 111:
#line 1052 "parser.y"
{
			amd_yyval.obj = N_A1("Unot", amd_yyvsp[0].obj);
		;
    break;}
case 112:
#line 1056 "parser.y"
{
			amd_yyval.obj = N_A1("Tilde", amd_yyvsp[0].obj);
		;
    break;}
case 113:
#line 1060 "parser.y"
{
			amd_yyval.obj = N_A1("Plus", amd_yyvsp[0].obj);
		;
    break;}
case 114:
#line 1064 "parser.y"
{
			amd_yyval.obj = N_A1("Minus", amd_yyvsp[0].obj);
		;
    break;}
case 115:
#line 1071 "parser.y"
{
			amd_yyval.obj = amd_yyvsp[0].obj;
		;
    break;}
case 116:
#line 1075 "parser.y"
{
			amd_yyval.obj = N_A1("Postinc", amd_yyvsp[-1].obj);
		;
    break;}
case 117:
#line 1079 "parser.y"
{
			amd_yyval.obj = N_A1("Postdec", amd_yyvsp[-1].obj);
		;
    break;}
case 118:
#line 1086 "parser.y"
{
			amd_yyval.obj = amd_yyvsp[0].obj;
		;
    break;}
case 119:
#line 1090 "parser.y"
{
			amd_yyval.obj = N_A3("Index", amd_yyvsp[-4].obj, amd_yyvsp[-1].obj, newSViv(amd_yyvsp[-2].number));
		;
    break;}
case 120:
#line 1096 "parser.y"
{
			amd_yyval.obj = N_A5("Range", amd_yyvsp[-7].obj, amd_yyvsp[-4].obj, amd_yyvsp[-1].obj, newSViv(amd_yyvsp[-5].number), newSViv(amd_yyvsp[-2].number));
		;
    break;}
case 122:
#line 1104 "parser.y"
{
			amd_yyunput_map_end();
		;
    break;}
case 123:
#line 1111 "parser.y"
{
			amd_yyval.number = 0;
		;
    break;}
case 124:
#line 1115 "parser.y"
{
			amd_yyval.number = 1;
		;
    break;}
case 125:
#line 1122 "parser.y"
{
			amd_yyval.obj = N_A0("Nil");
		;
    break;}
case 126:
#line 1126 "parser.y"
{
			amd_yyval.obj = N_A1("String", amd_yyvsp[0].sv);
		;
    break;}
case 127:
#line 1130 "parser.y"
{
			amd_yyval.obj = N_A1("Integer", newSViv(amd_yyvsp[0].number));
		;
    break;}
case 128:
#line 1134 "parser.y"
{
			amd_yyval.obj = N_A0R("Array", amd_yyvsp[0].av);
		;
    break;}
case 129:
#line 1138 "parser.y"
{
			amd_yyval.obj = N_A0R("Mapping", amd_yyvsp[0].av);
		;
    break;}
case 130:
#line 1142 "parser.y"
{
			amd_yyval.obj = N_A1("Closure", amd_yyvsp[0].obj);
		;
    break;}
case 131:
#line 1146 "parser.y"
{
			amd_yyval.obj = N_A1("Variable", amd_yyvsp[0].sv);
		;
    break;}
case 132:
#line 1150 "parser.y"
{
			amd_yyval.obj = N_A1("Parameter", newSViv(amd_yyvsp[0].number));
		;
    break;}
case 133:
#line 1154 "parser.y"
{
			amd_yyval.obj = N_A1("Parameter", amd_yyvsp[-1].obj);
		;
    break;}
case 134:
#line 1158 "parser.y"
{
			amd_yyval.obj = amd_yyvsp[-1].obj;
		;
    break;}
case 135:
#line 1162 "parser.y"
{
			amd_yyval.obj = N_A1R("Funcall", amd_yyvsp[-3].obj, amd_yyvsp[-1].av);
		;
    break;}
case 136:
#line 1166 "parser.y"
{
			amd_yyval.obj = N_A1R("Sscanf", amd_yyvsp[-2].obj, amd_yyvsp[-1].av);
		;
    break;}
case 137:
#line 1170 "parser.y"
{
			amd_yyval.obj = N_A1("Catch", amd_yyvsp[-1].obj);
		;
    break;}
case 138:
#line 1174 "parser.y"
{
			amd_yyval.obj = N_A1("New", amd_yyvsp[-1].sv);
		;
    break;}
case 139:
#line 1178 "parser.y"
{
			amd_yyval.obj = N_A2R("CallOther", amd_yyvsp[-5].obj, amd_yyvsp[-3].sv, amd_yyvsp[-1].av);
		;
    break;}
case 140:
#line 1182 "parser.y"
{
			amd_yyval.obj = N_A2("Member", amd_yyvsp[-2].obj, amd_yyvsp[0].sv);
		;
    break;}
case 141:
#line 1189 "parser.y"
{
			amd_yyval.av = newAV();
		;
    break;}
case 142:
#line 1193 "parser.y"
{
			av_push(amd_yyvsp[-2].av, amd_yyvsp[0].obj);
			amd_yyval.av = amd_yyvsp[-2].av;
		;
    break;}
case 143:
#line 1203 "parser.y"
{
			int		 len;
			int		 i;
			SV		**svp;
			AV		*vdl;
			AV		*vd;
			SV		*name;
			const char		*type;
			SV		*stars;
			SV		*var;

			type = amd_yyvsp[-2].str;
			vdl = amd_yyvsp[-1].av;
			len = av_len(vdl);

			for (i = 0; i <= len; i++) {
				svp = av_fetch(vdl, i, FALSE);
				if (!svp) continue;

				/* The AV returned from variable_declarator */
				vd = (AV *)SvRV(*svp);

				/* These two should be guaranteed dereferencable */
				stars = *( av_fetch(vd, 0, FALSE) );
				name = *( av_fetch(vd, 1, FALSE) );
				var = amd_yyparse_variable(name, type, stars, newSViv(amd_yyvsp[-3].number));

				/* XXX Check global modifiers, and possibly make these
				 * variables static. */

				if (amd_yyvsp[-3].number & M_STATIC) {
					SvREFCNT_dec(
						amd_yyparse_program_apply(amd_yyparse_param,
										"static", name, var));
				}
				else {
					SvREFCNT_dec(
						amd_yyparse_program_apply(amd_yyparse_param,
										"global", name, var));
				}
			}

			/* See local_decl for memory management notes. */
		;
    break;}
case 144:
#line 1251 "parser.y"
{
			amd_yyval.av = newAV();
		;
    break;}
case 145:
#line 1255 "parser.y"
{
			SV		**svp;
			int		 len;
			int		 i;

			len = av_len(amd_yyvsp[0].av);
			av_extend(amd_yyvsp[-1].av, av_len(amd_yyvsp[-1].av) + av_len(amd_yyvsp[0].av) + 1);

			for (i = 0; i <= len; i++) {
				svp = av_fetch(amd_yyvsp[0].av, i, FALSE);
				if (svp)
					av_push(amd_yyvsp[-1].av, *svp);
				else
					av_push(amd_yyvsp[-1].av, &PL_sv_undef);
			}

			amd_yyval.av = amd_yyvsp[-1].av;
		;
    break;}
case 146:
#line 1277 "parser.y"
{
			int		 len;
			int		 i;
			SV		**svp;
			AV		*vdl;
			AV		*vd;
			SV		*name;
			const char		*type;
			SV		*stars;
			SV		*var;

			amd_yyval.av = newAV();

			type = amd_yyvsp[-2].str;
			vdl = amd_yyvsp[-1].av;
			len = av_len(vdl);

			for (i = 0; i <= len; i++) {
				svp = av_fetch(vdl, i, FALSE);
				if (!svp) continue;

				/* The AV returned from variable_declarator_init */
				vd = (AV *)SvRV(*svp);

				/* These two should be guaranteed dereferencable */
				stars = *( av_fetch(vd, 0, FALSE) );
				name = *( av_fetch(vd, 1, FALSE) );
				var = amd_yyparse_variable(name, type, stars, &PL_sv_undef);

				av_push(amd_yyval.av, var);
			}

			/* All of these break things badly. */
			// SvREFCNT_dec($1);
			// SvREFCNT_dec($2);
			// av_clear($2);

			// amd_peek("local_decl", sv_2mortal(newRV_noinc((SV *)($$))));
		;
    break;}
case 147:
#line 1323 "parser.y"
{
			/* XXX Make a class object */
			SvREFCNT_dec(
				amd_yyparse_program_apply(amd_yyparse_param,
								"class", amd_yyvsp[-3].sv, newRV_noinc((SV *)amd_yyvsp[-1].av)));
		;
    break;}
case 148:
#line 1333 "parser.y"
{
			amd_yyval.av = newAV();
		;
    break;}
case 149:
#line 1337 "parser.y"
{
			SV	*sv;
			int	 len;
			int	 i;

			len = av_len(amd_yyvsp[0].av);
			for (i = 0; i <= len; i++) {
				sv = *( av_fetch(amd_yyvsp[0].av, i, FALSE) );
				av_push(amd_yyvsp[-1].av, sv);
			}
		 	/* XXX Lose ((AV)($2))! */
			amd_yyval.av = amd_yyvsp[-1].av;
		;
    break;}
case 150:
#line 1354 "parser.y"
{
			int		 len;
			int		 i;
			SV		**svp;
			AV		*vdl;
			AV		*vd;
			SV		*name;
			const char		*type;
			SV		*stars;
			SV		*var;

			amd_yyval.av = newAV();

			type = amd_yyvsp[-2].str;
			vdl = amd_yyvsp[-1].av;
			len = av_len(vdl);

			for (i = 0; i <= len; i++) {
				svp = av_fetch(vdl, i, FALSE);
				if (!svp) continue;

				/* The AV returned from variable_declarator */
				vd = (AV *)SvRV(*svp);

				/* These two should be guaranteed dereferencable */
				stars = *( av_fetch(vd, 0, FALSE) );
				name = *( av_fetch(vd, 1, FALSE) );
				var = amd_yyparse_variable(name, type, stars, &PL_sv_undef);

				av_push(amd_yyval.av, var);
			}

			/* See local_decl for memory management notes. */
		;
    break;}
case 151:
#line 1392 "parser.y"
{
			amd_yyval.av = newAV();
		;
    break;}
case 152:
#line 1396 "parser.y"
{
			amd_yyval.av = newAV();
		;
    break;}
case 153:
#line 1400 "parser.y"
{
			amd_yyval.av = amd_yyvsp[0].av;
		;
    break;}
case 154:
#line 1404 "parser.y"
{
			av_push(amd_yyvsp[-1].av, &PL_sv_undef);	/* XXX Fix L_ELLIPSIS */
			amd_yyval.av = amd_yyvsp[-1].av;
		;
    break;}
case 155:
#line 1412 "parser.y"
{
			amd_yyval.av = newAV();
			av_push(amd_yyval.av, amd_yyvsp[0].sv);
		;
    break;}
case 156:
#line 1417 "parser.y"
{
			av_push(amd_yyvsp[-2].av, amd_yyvsp[0].sv);
			amd_yyval.av = amd_yyvsp[-2].av;
		;
    break;}
case 157:
#line 1425 "parser.y"
{
			const char	*type;
			SV	*stars;
			SV	*name;

			type = amd_yyvsp[-1].str;
			stars = *( av_fetch(amd_yyvsp[0].av, 0, FALSE) );
			name = *( av_fetch(amd_yyvsp[0].av, 1, FALSE) );

			amd_yyval.sv = amd_yyparse_variable(name, type, stars, &PL_sv_undef);
		;
    break;}
case 158:
#line 1440 "parser.y"
{
			amd_yyval.number = 0;
		;
    break;}
case 159:
#line 1444 "parser.y"
{
			amd_yyval.number = amd_yyvsp[-1].number | amd_yyvsp[0].number;
		;
    break;}
case 160:
#line 1460 "parser.y"
{
			amd_yyval.str = amd_yyvsp[0].str;
		;
    break;}
case 161:
#line 1464 "parser.y"
{
			amd_yyval.str = amd_yyvsp[0].str;
		;
    break;}
case 162:
#line 1468 "parser.y"
{
			// $$ = "{}";
			/* As long as I don't free the underlying SV,
			 * I could just use SvPV here. We can't free the
			 * original type since it'll be in the type cache.
			 * Don't free the type cache while in the parser.
			 * Do the apply, then call SvPV_nolen(SvRV(x)) on it.
			 */
			SV	*ct;
			ct = amd_yyparse_program_apply(amd_yyparse_param,
								"class_type", amd_yyvsp[0].sv, &PL_sv_undef);
			amd_yyval.str = SvPV_nolen(SvRV(ct));
		;
    break;}
case 163:
#line 1485 "parser.y"
{
			/* Work on using PL_sv_undef here instead. */
			amd_yyval.sv = newSVpv("", 0);;
		;
    break;}
case 164:
#line 1490 "parser.y"
{
			STRLEN	 len;
			char	*v;

			v = SvPV(amd_yyvsp[-1].sv, len);
			sv_setpv(amd_yyvsp[-1].sv, "*");
			sv_catpvn(amd_yyvsp[-1].sv, v, len);

			amd_yyval.sv = amd_yyvsp[-1].sv;
		;
    break;}
case 165:
#line 1501 "parser.y"
{
			STRLEN	 len;
			char	*v;

			v = SvPV(amd_yyvsp[-1].sv, len);
			sv_setpv(amd_yyvsp[-1].sv, "#");
			sv_catpvn(amd_yyvsp[-1].sv, v, len);

			amd_yyval.sv = amd_yyvsp[-1].sv;
		;
    break;}
case 167:
#line 1517 "parser.y"
{
			/* Coercion should NOT be necessary. */
			sv_catpv(amd_yyvsp[-2].sv, SvPVX(amd_yyvsp[0].sv));
			SvREFCNT_dec(amd_yyvsp[0].sv);
			amd_yyval.sv = amd_yyvsp[-2].sv;
		;
    break;}
case 168:
#line 1524 "parser.y"
{
			sv_catpv(amd_yyvsp[-2].sv, SvPVX(amd_yyvsp[0].sv));
			SvREFCNT_dec(amd_yyvsp[0].sv);
			amd_yyval.sv = amd_yyvsp[-2].sv;
		;
    break;}
case 169:
#line 1530 "parser.y"
{
			char	 buf[64];
			snprintf(buf, 64, "%d", amd_yyvsp[0].number);
			amd_yyval.sv = newSVpv(buf, 0);
		;
    break;}
case 171:
#line 1541 "parser.y"
{
			sv_catpv(amd_yyvsp[-1].sv, SvPVX(amd_yyvsp[0].sv));
			SvREFCNT_dec(amd_yyvsp[0].sv);
			amd_yyval.sv = amd_yyvsp[-1].sv;
		;
    break;}
case 174:
#line 1555 "parser.y"
{
			amd_yyval.av = amd_yyvsp[-1].av;
		;
    break;}
case 175:
#line 1562 "parser.y"
{
			/* This doesn't expand the pairs into a single list.
			 * There is a hack elsewhere. */
			amd_yyval.av = amd_yyvsp[-1].av;
		;
    break;}
case 176:
#line 1572 "parser.y"
{
			amd_yyval.obj = amd_yyvsp[-1].obj;
		;
    break;}
}
   /* the action file gets copied in in place of this dollarsign */
#line 554 "/usr/share/bison.simple"

  amd_yyvsp -= amd_yylen;
  amd_yyssp -= amd_yylen;
#ifdef YYLSP_NEEDED
  amd_yylsp -= amd_yylen;
#endif

#if YYDEBUG != 0
  if (amd_yydebug)
    {
      short *ssp1 = amd_yyss - 1;
      fprintf (stderr, "state stack now");
      while (ssp1 != amd_yyssp)
	fprintf (stderr, " %d", *++ssp1);
      fprintf (stderr, "\n");
    }
#endif

  *++amd_yyvsp = amd_yyval;

#ifdef YYLSP_NEEDED
  amd_yylsp++;
  if (amd_yylen == 0)
    {
      amd_yylsp->first_line = amd_yylloc.first_line;
      amd_yylsp->first_column = amd_yylloc.first_column;
      amd_yylsp->last_line = (amd_yylsp-1)->last_line;
      amd_yylsp->last_column = (amd_yylsp-1)->last_column;
      amd_yylsp->text = 0;
    }
  else
    {
      amd_yylsp->last_line = (amd_yylsp+amd_yylen-1)->last_line;
      amd_yylsp->last_column = (amd_yylsp+amd_yylen-1)->last_column;
    }
#endif

  /* Now "shift" the result of the reduction.
     Determine what state that goes to,
     based on the state we popped back to
     and the rule number reduced by.  */

  amd_yyn = amd_yyr1[amd_yyn];

  amd_yystate = amd_yypgoto[amd_yyn - YYNTBASE] + *amd_yyssp;
  if (amd_yystate >= 0 && amd_yystate <= YYLAST && amd_yycheck[amd_yystate] == *amd_yyssp)
    amd_yystate = amd_yytable[amd_yystate];
  else
    amd_yystate = amd_yydefgoto[amd_yyn - YYNTBASE];

  goto amd_yynewstate;

amd_yyerrlab:   /* here on detecting error */

  if (! amd_yyerrstatus)
    /* If not already recovering from an error, report this error.  */
    {
      ++amd_yynerrs;

#ifdef YYERROR_VERBOSE
      amd_yyn = amd_yypact[amd_yystate];

      if (amd_yyn > YYFLAG && amd_yyn < YYLAST)
	{
	  int size = 0;
	  char *msg;
	  int x, count;

	  count = 0;
	  /* Start X at -amd_yyn if nec to avoid negative indexes in amd_yycheck.  */
	  for (x = (amd_yyn < 0 ? -amd_yyn : 0);
	       x < (sizeof(amd_yytname) / sizeof(char *)); x++)
	    if (amd_yycheck[x + amd_yyn] == x)
	      size += strlen(amd_yytname[x]) + 15, count++;
	  msg = (char *) malloc(size + 15);
	  if (msg != 0)
	    {
	      strcpy(msg, "parse error");

	      if (count < 5)
		{
		  count = 0;
		  for (x = (amd_yyn < 0 ? -amd_yyn : 0);
		       x < (sizeof(amd_yytname) / sizeof(char *)); x++)
		    if (amd_yycheck[x + amd_yyn] == x)
		      {
			strcat(msg, count == 0 ? ", expecting `" : " or `");
			strcat(msg, amd_yytname[x]);
			strcat(msg, "'");
			count++;
		      }
		}
	      amd_yyerror(msg);
	      free(msg);
	    }
	  else
	    amd_yyerror ("parse error; also virtual memory exceeded");
	}
      else
#endif /* YYERROR_VERBOSE */
	amd_yyerror("parse error");
    }

  goto amd_yyerrlab1;
amd_yyerrlab1:   /* here on error raised explicitly by an action */

  if (amd_yyerrstatus == 3)
    {
      /* if just tried and failed to reuse lookahead token after an error, discard it.  */

      /* return failure if at end of input */
      if (amd_yychar == YYEOF)
	YYABORT;

#if YYDEBUG != 0
      if (amd_yydebug)
	fprintf(stderr, "Discarding token %d (%s).\n", amd_yychar, amd_yytname[amd_yychar1]);
#endif

      amd_yychar = YYEMPTY;
    }

  /* Else will try to reuse lookahead token
     after shifting the error token.  */

  amd_yyerrstatus = 3;		/* Each real token shifted decrements this */

  goto amd_yyerrhandle;

amd_yyerrdefault:  /* current state does not do anything special for the error token. */

#if 0
  /* This is wrong; only states that explicitly want error tokens
     should shift them.  */
  amd_yyn = amd_yydefact[amd_yystate];  /* If its default is to accept any token, ok.  Otherwise pop it.*/
  if (amd_yyn) goto amd_yydefault;
#endif

amd_yyerrpop:   /* pop the current state because it cannot handle the error token */

  if (amd_yyssp == amd_yyss) YYABORT;
  amd_yyvsp--;
  amd_yystate = *--amd_yyssp;
#ifdef YYLSP_NEEDED
  amd_yylsp--;
#endif

#if YYDEBUG != 0
  if (amd_yydebug)
    {
      short *ssp1 = amd_yyss - 1;
      fprintf (stderr, "Error: state stack now");
      while (ssp1 != amd_yyssp)
	fprintf (stderr, " %d", *++ssp1);
      fprintf (stderr, "\n");
    }
#endif

amd_yyerrhandle:

  amd_yyn = amd_yypact[amd_yystate];
  if (amd_yyn == YYFLAG)
    goto amd_yyerrdefault;

  amd_yyn += YYTERROR;
  if (amd_yyn < 0 || amd_yyn > YYLAST || amd_yycheck[amd_yyn] != YYTERROR)
    goto amd_yyerrdefault;

  amd_yyn = amd_yytable[amd_yyn];
  if (amd_yyn < 0)
    {
      if (amd_yyn == YYFLAG)
	goto amd_yyerrpop;
      amd_yyn = -amd_yyn;
      goto amd_yyreduce;
    }
  else if (amd_yyn == 0)
    goto amd_yyerrpop;

  if (amd_yyn == YYFINAL)
    YYACCEPT;

#if YYDEBUG != 0
  if (amd_yydebug)
    fprintf(stderr, "Shifting error token, ");
#endif

  *++amd_yyvsp = amd_yylval;
#ifdef YYLSP_NEEDED
  *++amd_yylsp = amd_yylloc;
#endif

  amd_yystate = amd_yyn;
  goto amd_yynewstate;

 amd_yyacceptlab:
  /* YYACCEPT comes here.  */
#ifndef YYSTACK_USE_ALLOCA
  if (amd_yyfree_stacks)
    {
      free (amd_yyss);
      free (amd_yyvs);
#ifdef YYLSP_NEEDED
      free (amd_yyls);
#endif
    }
#endif
  return 0;

 amd_yyabortlab:
  /* YYABORT comes here.  */
#ifndef YYSTACK_USE_ALLOCA
  if (amd_yyfree_stacks)
    {
      free (amd_yyss);
      free (amd_yyvs);
#ifdef YYLSP_NEEDED
      free (amd_yyls);
#endif
    }
#endif    
  return 1;
}
#line 1577 "parser.y"


const char *
amd_yytokname(int i)
{
	return amd_yytname[YYTRANSLATE(i)];
}

int
amd_yyparser_parse(SV *program, const char *str)
{
	amd_parse_param_t	 param;
	int					 ret;

	// fprintf(stderr, "Start of amd_yyparser_parse\n");
	// fflush(stderr);

	memset(&param, 0, sizeof(param));
	param.program = program;
	param.symtab = newHV();

	amd_yylex_init(str);
#if YYDEBUG != 0
	amd_yydebug = 1;
#endif

	ret = amd_yyparse((void *)(&param));

	/* Delete the HV but not the contents. */
	hv_undef(param.symtab);

	return ret;
}
