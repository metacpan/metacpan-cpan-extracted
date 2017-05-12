%{
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

#define YYPARSE_PARAM	yyparse_param
#define YYLEX_PARAM		yyparse_param

#define YYDEBUG 0
#define YYERROR_VERBOSE

#if 0 || (YYDEBUG != 0)
#define yylex(lvalp, yypp) yylex_verbose(lvalp, yypp)
#else
#define yylex(lvalp, yypp) yylex(lvalp, yypp)
#endif

#define Z1		NULL
#define Z2		Z1, NULL
#define Z3		Z2, NULL
#define Z4		Z3, NULL
#define Z5		Z4, NULL
#define Z6		Z5, NULL

#define N_A0(t)					yyparse_node(t,               Z6)
#define N_A1(t,a0)				yyparse_node(t,a0,            Z5)
#define N_A2(t,a0,a1)			yyparse_node(t,a0,a1,         Z4)
#define N_A3(t,a0,a1,a2)		yyparse_node(t,a0,a1,a2,      Z3)
#define N_A4(t,a0,a1,a2,a3)		yyparse_node(t,a0,a1,a2,a3,   Z2)
#define N_A5(t,a0,a1,a2,a3,a4)	yyparse_node(t,a0,a1,a2,a3,a4,Z1)

#define N_A0R(t,r)					yyparse_node(t,            Z5,r)
#define N_A1R(t,a0,r)				yyparse_node(t,a0,         Z4,r)
#define N_A2R(t,a0,a1,r)			yyparse_node(t,a0,a1,      Z3,r)
#define N_A3R(t,a0,a1,a2,r)			yyparse_node(t,a0,a1,a2,   Z2,r)
#define N_A4R(t,a0,a1,a2,a3,r)		yyparse_node(t,a0,a1,a2,a3,Z1,r)
#define N_A5R(t,a0,a1,a2,a3,a4,r)	yyparse_node(t,a0,a1,a2,a3,a4,r)

static SV *
yyparse_node(char *type,
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
yyparse_type(const char *type, SV *stars)
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
yyparse_variable(SV *name, const char *type, SV *stars, SV *mods)
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

	newtype = yyparse_type(type, stars);

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
yyparse_method(SV *name, const char *type, SV *stars,
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

	newtype = yyparse_type(type, stars);

	// printf("Start of yyparse_method\n");

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

	// printf("End of yyparse_method\n");

	return node;
}

static void
yyparse_method_add_code(SV *method, SV *code)
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
yyparse_program_apply(amd_parse_param_t *param,
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

%}

%token L_BREAK L_CASE L_CATCH L_CLASS L_CONTINUE L_DEFAULT L_DO
%token L_EFUN L_ELSE L_FOR L_FOREACH L_IF L_IN L_INHERIT L_NEW
%token L_NIL L_RETURN L_RLIMITS L_SWITCH L_SSCANF L_TRY L_WHILE

%token L_MAP_START L_MAP_END
%token L_ARRAY_START L_ARRAY_END
%token L_FUNCTION_START L_FUNCTION_END
%token L_PARAMETER L_IDENTIFIER L_NIL L_STRING L_CHARACTER
%token L_INTEGER L_HEXINTEGER
%token L_BASIC_TYPE L_TYPE_MODIFIER L_STATIC

%token L_INHERIT L_COLONCOLON
%token L_IF L_DO L_WHILE L_FOR L_FOREACH L_IN L_RLIMITS
%token L_TRY L_CATCH
%token L_SWITCH L_CASE L_BREAK
%token L_CONTINUE L_RETURN L_ELSE

%token L_VOID L_ELLIPSIS
%token L_ARROW L_RANGE

%nonassoc LOWER_THAN_ELSE
%nonassoc L_ELSE

/* Strictly these can be %token */
%nonassoc L_PLUS_EQ L_MINUS_EQ L_DIV_EQ L_TIMES_EQ
%nonassoc L_MOD_EQ L_AND_EQ L_OR_EQ L_XOR_EQ L_DOT_EQ
	/* Is this the right place? */
%nonassoc L_LOR_EQ L_LAND_EQ

/* %left CONST */
%right '?'
%left L_LOR
%left L_LAND
%left '|'
%left '^'
%left '&'
%left L_EQ L_NE
%left L_GE L_LE '<' '>'
%left L_LSH L_RSH
%left '.'
%left '+' '-'
%left '*' '%' '/'
%right '!' '~'
%nonassoc L_INC L_DEC

/* These aren't strictly necessary, but they help debugging. */

%token '{' '}' ',' ';' ':' '(' ')' '[' ']' '=' '$'

	/* I should have a new type 'node' in here for blessed objects
	 * which are specifically parse nodes. */
	/* It is very very tempting to expand this to say 12 bytes
	 * to save on the use of AVs for type declarators. */
%union {
	int			 number;
	const char	*str;
	SV			*sv;
	SV			*obj;
	AV			*av;
	struct _assoc_t {
		SV	*key;
		SV	*value;
	} 			 assoc;
}

%{
	/* This declares either yylex or yylex_verbose, according to
	 * the macros above. This is a bit obscure and occasionally
	 * highly fucked up. */
int yylex(YYSTYPE *yylval, amd_parse_param_t *param);
%}

	/* %TYPES */

%type <av> function_declarator
%type <av> argument_list arguments
%type <sv> argument
%type <sv> function_prologue

%type <av> variable_declarator variable_declarator_list
%type <av> variable_declarator_init variable_declarator_list_init

%type <str> L_VOID L_BASIC_TYPE
	/* This might point into an SvPV in the type cache. */
%type <str> type_specifier
	/* An SvPV. */
%type <sv> star_list
%type <number> opt_endrange
%type <number> type_modifier_list L_TYPE_MODIFIER

%type <av> class_member_list class_member

%type <number> L_PARAMETER
%type <number> integer L_INTEGER L_HEXINTEGER L_CHARACTER
%type <sv> L_STRING string string_const
%type <sv> L_IDENTIFIER identifier
%type <obj> function_name

%type <assoc> assoc_exp
%type <av> arg_list opt_arg_list opt_arg_list_comma
%type <av> assoc_arg_list opt_assoc_arg_list_comma
%type <av> array mapping

%type <obj> lvalue
%type <av> lvalue_list

%type <obj> block
%type <av> local_decls local_decl

%type <obj> statement
%type <av> statement_list
%type <obj> opt_else

%type <obj> list_exp exp cond_exp logical_exp compare_exp arith_exp
%type <obj> prefix_exp postfix_exp array_exp basic_exp
%type <obj> opt_nv_list_exp nv_list_exp opt_list_exp

%type <obj> closure

%pure_parser
%token_table

%start program

%%

program
		: program definition
		|	/* empty */
	;

definition
		: inheritance
		| global_decl
		| type_decl
		| function
		| prototype
	;

inheritance
		: L_INHERIT string_const ';'
		{
			/* printf("Inheriting %s\n", SvPVX($2)); */
			SvREFCNT_dec(
				yyparse_program_apply(yyparse_param,
						"inherit", &PL_sv_undef, $2));
		}
		| L_INHERIT identifier string_const ';'
		{
			printf("Inheriting %s as %s\n", SvPVX($3), SvPVX($2));
			SvREFCNT_dec(
				yyparse_program_apply(yyparse_param,
						"inherit", $2, $3));
		}
	;

identifier
		: L_IDENTIFIER
		{
			$$ = $1;
		}
	;

function_declarator
		: star_list identifier '(' arguments ')'
		{
			$$ = newAV();
			av_push($$, $1);
			av_push($$, $2);
			av_push($$, newRV_noinc((SV *)($4)));
		}
	;

variable_declarator
		: star_list identifier
		{
			$$ = newAV();
			av_push($$, $1);
			av_push($$, $2);
		}
	;

variable_declarator_list
		: variable_declarator
		{
			$$ = newAV();
			av_push($$, newRV_noinc((SV *)($1)));
		}
		| variable_declarator_list ',' variable_declarator
		{
			$$ = $1;
			av_push($$, newRV_noinc((SV *)($3)));
		}
	;

variable_declarator_init
		: variable_declarator
		{
			$$ = $1;
		}
		| variable_declarator '=' exp
		{
			av_push($1, $3);
			$$ = $1;
		}
	;

variable_declarator_list_init
		: variable_declarator_init
		{
			$$ = newAV();
			av_push($$, newRV_noinc((SV *)($1)));
		}
		| variable_declarator_list_init ',' variable_declarator_init
		{
			$$ = $1;
			av_push($$, newRV_noinc((SV *)($3)));
		}
	;

	/* This isn't quite the way it ought to be done since it doesn't
	 * let me mix declarator types between function and data. */
	/* The return value from this rule has an extra ref from
	 * yyparse_program_apply(). */
function_prologue
		: type_modifier_list type_specifier function_declarator
		{
			SV	*method;
			const char	*type;
			SV	*stars;
			SV	*name;
			SV	*args;
			SV	*mods;

			type = $2;
			stars = *( av_fetch($3, 0, FALSE) );
			name = *( av_fetch($3, 1, FALSE) );
			args = *( av_fetch($3, 2, FALSE) );
			mods = newSViv($1);

			method = yyparse_method(name, type, stars, args, mods);

			/* Check that this is the empty list. */
			SvREFCNT_dec(
				yyparse_program_apply(yyparse_param,
								"method", name, method));

			$$ = method;
		}
	;

prototype
		: function_prologue ';'
		{
			SvREFCNT_dec($1);
		}
	;

function
		: function_prologue block
		{
			/* $1->code($2); */
			yyparse_method_add_code($1, $2);
			SvREFCNT_dec($1);
		}
	;

block
		: '{' local_decls statement_list '}'
		{
			$$ = N_A2("Block",
					newRV_noinc((SV *)($2)),
					newRV_noinc((SV *)($3)));
			// amd_dump("Block locals", sv_2mortal(newRV_noinc((SV *)($2))));
		}
	;

statement_list
		:	/* empty */
		{
			$$ = newAV();
		}
		| statement_list statement
		{
			av_push($1, $2);
			$$ = $1;
		}
	;

statement
		: list_exp ';'
		{
			$$ = N_A1("StmtExp", $1);
		}
		| block
		{
			$$ = $1;
		}
		| L_IF '(' nv_list_exp ')' statement opt_else
		{
			/* if ($6 == &PL_sv_undef) - use StmtIfElse */
			$$ = N_A3("StmtIf", $3, $5, $6);
		}
		| L_DO statement L_WHILE '(' nv_list_exp ')' ';'
		{
			$$ = N_A2("StmtDo", $5, $2);
		}
		| L_WHILE '(' nv_list_exp ')' statement
		{
			$$ = N_A2("StmtWhile", $3, $5);
		}
		| L_FOR '(' opt_list_exp ';'
					opt_nv_list_exp ';'
					opt_list_exp ')'
						statement
		{
			$$ = N_A4("StmtFor", $3, $5, $7, $9);
		}
		| L_FOREACH '(' lvalue L_IN exp ')' statement
		{
			$$ = N_A4("StmtForeach", $3, &PL_sv_undef, $5, $7);
		}
		| L_FOREACH '(' lvalue ',' lvalue L_IN exp ')' statement
		{
			$$ = N_A4("StmtForeach", $3, $5, $7, $9);
		}
		| L_RLIMITS '(' nv_list_exp ';' nv_list_exp ')' block
		{
			$$ = N_A3("StmtRlimits", $3, $5, $7);
		}
		| L_TRY block L_CATCH '(' lvalue ')' block
		{
			$$ = N_A3("StmtTry", $2, $5, $7);
		}
		| L_CATCH block
		{
			/* A MudOS hack */
			$$ = N_A1("StmtCatch", $2);
		}
		| L_SWITCH '(' nv_list_exp ')' block
		{
			$$ = N_A2("StmtSwitch", $3, $5);
		}
		| L_CASE exp ':'
		{
			$$ = N_A2("StmtCase", $2, &PL_sv_undef);
		}
		/*
		| L_CASE exp L_RANGE exp ':'
		{
			$$ = N_A2("StmtCase", $2, $4);
		}
		*/
		| L_DEFAULT ':'
		{
			$$ = N_A0("StmtDefault");
		}
		| L_BREAK ';'
		{
			$$ = N_A0("StmtBreak");
		}
		| L_CONTINUE ';'
		{
			$$ = N_A0("StmtContinue");
		}
		| L_RETURN opt_nv_list_exp ';'
		{
			$$ = N_A1("StmtReturn", $2);
		}
		| ';'
		{
			$$ = N_A0("StmtNull");
		}
		| error ';'
		{
			$$ = N_A0("StmtNull");
		}
	;

opt_else
		: %prec LOWER_THAN_ELSE
		{
			$$ = &PL_sv_undef;
		}
		| L_ELSE statement
		{
			$$ = $2;
		}
	;

list_exp
		: exp
		{
			$$ = $1;
		}
		| list_exp ',' exp
		{
			$$ = N_A2("ExpComma", $1, $3);
		}
	;

opt_list_exp
		:	/* empty */
		{
			$$ = &PL_sv_undef;
		}
		| list_exp
		{
			$$ = $1;
		}
	;

nv_list_exp	/* XXX This is wrong, but ... */
		: exp	/* Check nonvoid */
	;

opt_nv_list_exp
		:
		{
			$$ = &PL_sv_undef;
		}
		| nv_list_exp
		{
			$$ = $1;
		}
	;

arg_list
		: exp
		{
			$$ = newAV();
			av_push($$, $1);
		}
		| arg_list ',' exp
		{
			av_push($1, $3);
			$$ = $1;
		}
	;

opt_arg_list
		:	/* empty */
		{
			$$ = newAV();
		}
		| arg_list
			/* default */
	;

opt_arg_list_comma
		:	/* empty */
		{
			$$ = newAV();
		}
		| arg_list
			/* default */
		| arg_list ','
			/* default */
	;

assoc_exp
		: exp ':' exp	/* Check nonvoid */
		{
			$$.key = $1;
			$$.value = $3;
			/*
			AV	*av;
			av = newAV();
			av_push(av, $1);
			av_push(av, $3);
			$$ = newRV_noinc((SV *)av);
			*/
		}
	;

assoc_arg_list
		: assoc_exp
		{
			$$ = newAV();
			av_push($$, $1.key);
			av_push($$, $1.value);
		}
		| assoc_arg_list ',' assoc_exp
		{
			av_push($1, $3.key);
			av_push($1, $3.value);
			$$ = $1;
		}
	;

opt_assoc_arg_list_comma
		:	/* empty */
		{
			$$ = newAV();
		}
		| assoc_arg_list
			/* default */
		| assoc_arg_list ','
			/* default */
	;

function_name
		: identifier
		{
			$$ = yyparse_program_apply(yyparse_param,
							"method", $1, NULL);
		}
		| L_COLONCOLON identifier
		{
			SV	*name;
			name = newSVpv("::", 2);
			sv_catsv(name, $2);
			$$ = yyparse_program_apply(yyparse_param,
							"method", sv_2mortal(name), NULL);
		}
		| identifier L_COLONCOLON identifier
		{
			SV	*name;
			name = newSVsv($1);
			sv_catpv(name, "::");
			sv_catsv(name, $3);
			$$ = yyparse_program_apply(yyparse_param,
							"method", sv_2mortal(name), NULL);
		}
		| L_EFUN L_COLONCOLON identifier
		{
			SV	*name;
			name = newSVpv("efun::", 6);
			sv_catsv(name, $3);
			$$ = yyparse_program_apply(yyparse_param,
							"method", sv_2mortal(name), NULL);
		}
	;

lvalue
		: array_exp	/* Check lvalue */
		{
			$$ = $1;
		}
	;

exp
		: cond_exp
		{
			$$ = $1;
		}
		| lvalue '=' exp
		{
			$$ = N_A2("Assign", $1, $3);
		}
		| lvalue L_PLUS_EQ exp
		{
			$$ = N_A2("AddEq", $1, $3);
		}
		| lvalue L_MINUS_EQ exp
		{
			$$ = N_A2("SubEq", $1, $3);
		}
		| lvalue L_DIV_EQ exp
		{
			$$ = N_A2("DivEq", $1, $3);
		}
		| lvalue L_TIMES_EQ exp
		{
			$$ = N_A2("MulEq", $1, $3);
		}
		| lvalue L_MOD_EQ exp
		{
			$$ = N_A2("ModEq", $1, $3);
		}
		| lvalue L_AND_EQ exp
		{
			$$ = N_A2("AndEq", $1, $3);
		}
		| lvalue L_OR_EQ exp
		{
			$$ = N_A2("OrEq", $1, $3);
		}
		| lvalue L_XOR_EQ exp
		{
			$$ = N_A2("XorEq", $1, $3);
		}
		| lvalue L_DOT_EQ exp
		{
			$$ = N_A2("StrAddEq", $1, $3);
		}
		| lvalue L_LOR_EQ exp
		{
			$$ = N_A2("LogOrEq", $1, $3);
		}
		| lvalue L_LAND_EQ exp
		{
			$$ = N_A2("LogAndEq", $1, $3);
		}
	;

cond_exp
		: logical_exp
		{
			$$ = $1;
		}
		| logical_exp '?' list_exp ':' cond_exp %prec '?'
		{
			$$ = N_A3("ExpCond", $1, $3, $5);
		}
	;

logical_exp
		: compare_exp
		{
			$$ = $1;
		}
		| logical_exp L_LOR logical_exp
		{
			$$ = N_A2("LogOr", $1, $3);
		}
		| logical_exp L_LAND logical_exp
		{
			$$ = N_A2("LogAnd", $1, $3);
		}
		| logical_exp '|' logical_exp
		{
			$$ = N_A2("Or", $1, $3);
		}
		| logical_exp '^' logical_exp
		{
			$$ = N_A2("Xor", $1, $3);
		}
		| logical_exp '&' logical_exp
		{
			$$ = N_A2("And", $1, $3);
		}
	;

	/* I could swap some of these operands around to save code */
compare_exp
		: arith_exp
		{
			$$ = $1;
		}
		| compare_exp L_EQ compare_exp
		{
			$$ = N_A2("Eq", $1, $3);
		}
		| compare_exp L_NE compare_exp
		{
			$$ = N_A2("Ne", $1, $3);
		}
		| compare_exp '<' compare_exp
		{
			$$ = N_A2("Lt", $1, $3);
		}
		| compare_exp '>' compare_exp
		{
			$$ = N_A2("Gt", $1, $3);
		}
		| compare_exp L_LE compare_exp
		{
			$$ = N_A2("Le", $1, $3);
		}
		| compare_exp L_GE compare_exp
		{
			$$ = N_A2("Ge", $1, $3);
		}
	;

arith_exp
		: prefix_exp
		{
			$$ = $1;
		}
		| arith_exp L_LSH arith_exp
		{
			$$ = N_A2("Lsh", $1, $3);
		}
		| arith_exp L_RSH arith_exp
		{
			$$ = N_A2("Rsh", $1, $3);
		}
		| arith_exp '.' arith_exp
		{
			$$ = N_A2("StrAdd", $1, $3);
		}
		| arith_exp '+' arith_exp
		{
			$$ = N_A2("Add", $1, $3);
		}
		| arith_exp '-' arith_exp
		{
			$$ = N_A2("Sub", $1, $3);
		}
		| arith_exp '*' arith_exp
		{
			$$ = N_A2("Mul", $1, $3);
		}
		| arith_exp '/' arith_exp
		{
			$$ = N_A2("Div", $1, $3);
		}
		| arith_exp '%' arith_exp
		{
			$$ = N_A2("Mod", $1, $3);
		}
	;

prefix_exp
		: postfix_exp
		{
			$$ = $1;
		}
		| L_INC prefix_exp
		{
			$$ = N_A1("Preinc", $2);
		}
		| L_DEC prefix_exp
		{
			$$ = N_A1("Predec", $2);
		}
		| '!' prefix_exp
		{
			$$ = N_A1("Unot", $2);
		}
		| '~' prefix_exp
		{
			$$ = N_A1("Tilde", $2);
		}
		| '+' prefix_exp
		{
			$$ = N_A1("Plus", $2);
		}
		| '-' prefix_exp
		{
			$$ = N_A1("Minus", $2);
		}
	;

postfix_exp
		: array_exp
		{
			$$ = $1;
		}
		| postfix_exp L_INC
		{
			$$ = N_A1("Postinc", $1);
		}
		| postfix_exp L_DEC
		{
			$$ = N_A1("Postdec", $1);
		}
	;

array_exp
		: basic_exp
		{
			$$ = $1;
		}
		| array_exp '[' opt_endrange nv_list_exp close_square
		{
			$$ = N_A3("Index", $1, $4, newSViv($3));
		}
		| array_exp '[' opt_endrange nv_list_exp
							L_RANGE
						opt_endrange nv_list_exp close_square
		{
			$$ = N_A5("Range", $1, $4, $7, newSViv($3), newSViv($6));
		}
	;

close_square
		: ']'
		| L_MAP_END
		{
			yyunput_map_end();
		}
	;

opt_endrange
		:	/* empty */
		{
			$$ = 0;
		}
		| '<'
		{
			$$ = 1;
		}
	;

basic_exp
		: L_NIL
		{
			$$ = N_A0("Nil");
		}
		| string
		{
			$$ = N_A1("String", $1);
		}
		| integer
		{
			$$ = N_A1("Integer", newSViv($1));
		}
		| array
		{
			$$ = N_A0R("Array", $1);
		}
		| mapping
		{
			$$ = N_A0R("Mapping", $1);
		}
		| closure
		{
			$$ = N_A1("Closure", $1);
		}
		| identifier
		{
			$$ = N_A1("Variable", $1);
		}
		| L_PARAMETER
		{
			$$ = N_A1("Parameter", newSViv($1));
		}
		| '$' '(' list_exp ')'
		{
			$$ = N_A1("Parameter", $3);
		}
		| '(' list_exp ')'
		{
			$$ = $2;
		}
		| function_name '(' opt_arg_list ')'
		{
			$$ = N_A1R("Funcall", $1, $3);
		}
		| L_SSCANF '(' exp lvalue_list ')'
		{
			$$ = N_A1R("Sscanf", $3, $4);
		}
		| L_CATCH '(' list_exp ')'
		{
			$$ = N_A1("Catch", $3);
		}
		| L_NEW '(' L_CLASS identifier ')'
		{
			$$ = N_A1("New", $4);
		}
		| array_exp L_ARROW identifier '(' opt_arg_list ')'
		{
			$$ = N_A2R("CallOther", $1, $3, $5);
		}
		| array_exp L_ARROW identifier
		{
			$$ = N_A2("Member", $1, $3);
		}
	;

lvalue_list
		:	/* empty */
		{
			$$ = newAV();
		}
		| lvalue_list ',' lvalue
		{
			av_push($1, $3);
			$$ = $1;
		}
	;



global_decl
		: type_modifier_list type_specifier variable_declarator_list ';'
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

			type = $2;
			vdl = $3;
			len = av_len(vdl);

			for (i = 0; i <= len; i++) {
				svp = av_fetch(vdl, i, FALSE);
				if (!svp) continue;

				/* The AV returned from variable_declarator */
				vd = (AV *)SvRV(*svp);

				/* These two should be guaranteed dereferencable */
				stars = *( av_fetch(vd, 0, FALSE) );
				name = *( av_fetch(vd, 1, FALSE) );
				var = yyparse_variable(name, type, stars, newSViv($1));

				/* XXX Check global modifiers, and possibly make these
				 * variables static. */

				if ($1 & M_STATIC) {
					SvREFCNT_dec(
						yyparse_program_apply(yyparse_param,
										"static", name, var));
				}
				else {
					SvREFCNT_dec(
						yyparse_program_apply(yyparse_param,
										"global", name, var));
				}
			}

			/* See local_decl for memory management notes. */
		}
	;

local_decls
		:	/* empty */
		{
			$$ = newAV();
		}
		| local_decls local_decl
		{
			SV		**svp;
			int		 len;
			int		 i;

			len = av_len($2);
			av_extend($1, av_len($1) + av_len($2) + 1);

			for (i = 0; i <= len; i++) {
				svp = av_fetch($2, i, FALSE);
				if (svp)
					av_push($1, *svp);
				else
					av_push($1, &PL_sv_undef);
			}

			$$ = $1;
		}
	;

local_decl
		: type_specifier variable_declarator_list_init ';'
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

			$$ = newAV();

			type = $1;
			vdl = $2;
			len = av_len(vdl);

			for (i = 0; i <= len; i++) {
				svp = av_fetch(vdl, i, FALSE);
				if (!svp) continue;

				/* The AV returned from variable_declarator_init */
				vd = (AV *)SvRV(*svp);

				/* These two should be guaranteed dereferencable */
				stars = *( av_fetch(vd, 0, FALSE) );
				name = *( av_fetch(vd, 1, FALSE) );
				var = yyparse_variable(name, type, stars, &PL_sv_undef);

				av_push($$, var);
			}

			/* All of these break things badly. */
			// SvREFCNT_dec($1);
			// SvREFCNT_dec($2);
			// av_clear($2);

			// amd_peek("local_decl", sv_2mortal(newRV_noinc((SV *)($$))));
		}
	;

	/* The type_modifier_list is expected to be empty but
	 * avoids a shift-reduce conflict at top level. */
type_decl
		: type_modifier_list L_CLASS identifier
				'{' class_member_list '}'
		{
			/* XXX Make a class object */
			SvREFCNT_dec(
				yyparse_program_apply(yyparse_param,
								"class", $3, newRV_noinc((SV *)$5)));
		}
	;

class_member_list
		:	/* empty */
		{
			$$ = newAV();
		}
		| class_member_list class_member
		{
			SV	*sv;
			int	 len;
			int	 i;

			len = av_len($2);
			for (i = 0; i <= len; i++) {
				sv = *( av_fetch($2, i, FALSE) );
				av_push($1, sv);
			}
		 	/* XXX Lose ((AV)($2))! */
			$$ = $1;
		}
	;

class_member
		: type_specifier variable_declarator_list ';'
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

			$$ = newAV();

			type = $1;
			vdl = $2;
			len = av_len(vdl);

			for (i = 0; i <= len; i++) {
				svp = av_fetch(vdl, i, FALSE);
				if (!svp) continue;

				/* The AV returned from variable_declarator */
				vd = (AV *)SvRV(*svp);

				/* These two should be guaranteed dereferencable */
				stars = *( av_fetch(vd, 0, FALSE) );
				name = *( av_fetch(vd, 1, FALSE) );
				var = yyparse_variable(name, type, stars, &PL_sv_undef);

				av_push($$, var);
			}

			/* See local_decl for memory management notes. */
		}
	;

arguments
		:	/* empty */
		{
			$$ = newAV();
		}
		| L_VOID
		{
			$$ = newAV();
		}
		| argument_list
		{
			$$ = $1;
		}
		| argument_list L_ELLIPSIS
		{
			av_push($1, &PL_sv_undef);	/* XXX Fix L_ELLIPSIS */
			$$ = $1;
		}
	;

argument_list
		: argument
		{
			$$ = newAV();
			av_push($$, $1);
		}
		| argument_list ',' argument
		{
			av_push($1, $3);
			$$ = $1;
		}
	;

argument
		: type_specifier variable_declarator
		{
			const char	*type;
			SV	*stars;
			SV	*name;

			type = $1;
			stars = *( av_fetch($2, 0, FALSE) );
			name = *( av_fetch($2, 1, FALSE) );

			$$ = yyparse_variable(name, type, stars, &PL_sv_undef);
		}
	;

type_modifier_list
		:
		{
			$$ = 0;
		}
		| L_TYPE_MODIFIER type_modifier_list
		{
			$$ = $1 | $2;
		}
	;

	/*
		opt_static
				:
				| L_STATIC
			;
	 */

	/* XXX IMMEDIATE: Make this return a const char * all the
	 * way up to yyparse_type */
type_specifier
		: L_BASIC_TYPE
		{
			$$ = $1;
		}
		| L_VOID
		{
			$$ = $1;
		}
		| L_CLASS identifier
		{
			// $$ = "{}";
			/* As long as I don't free the underlying SV,
			 * I could just use SvPV here. We can't free the
			 * original type since it'll be in the type cache.
			 * Don't free the type cache while in the parser.
			 * Do the apply, then call SvPV_nolen(SvRV(x)) on it.
			 */
			SV	*ct;
			ct = yyparse_program_apply(yyparse_param,
								"class_type", $2, &PL_sv_undef);
			$$ = SvPV_nolen(SvRV(ct));
		}
	;

star_list
		:	/* empty */
		{
			/* Work on using PL_sv_undef here instead. */
			$$ = newSVpv("", 0);;
		}
		| star_list '*'
		{
			STRLEN	 len;
			char	*v;

			v = SvPV($1, len);
			sv_setpv($1, "*");
			sv_catpvn($1, v, len);

			$$ = $1;
		}
		| star_list '#'
		{
			STRLEN	 len;
			char	*v;

			v = SvPV($1, len);
			sv_setpv($1, "#");
			sv_catpvn($1, v, len);

			$$ = $1;
		}
	;

string_const
		: string
			/* default */
		| string_const '.' string_const
		{
			/* Coercion should NOT be necessary. */
			sv_catpv($1, SvPVX($3));
			SvREFCNT_dec($3);
			$$ = $1;
		}
		| string_const '+' string_const
		{
			sv_catpv($1, SvPVX($3));
			SvREFCNT_dec($3);
			$$ = $1;
		}
		| integer	/* Is this my extension? */
		{
			char	 buf[64];
			snprintf(buf, 64, "%d", $1);
			$$ = newSVpv(buf, 0);
		}
	;

string
		: L_STRING
			/* default */
		| string L_STRING
		{
			sv_catpv($1, SvPVX($2));
			SvREFCNT_dec($2);
			$$ = $1;
		}
	;

integer
		: L_INTEGER
		| L_CHARACTER
	;

array
		: L_ARRAY_START opt_arg_list_comma L_ARRAY_END
		{
			$$ = $2;
		}
	;

mapping
		: L_MAP_START opt_assoc_arg_list_comma L_MAP_END
		{
			/* This doesn't expand the pairs into a single list.
			 * There is a hack elsewhere. */
			$$ = $2;
		}
	;

		/* Also things like (: foo :) ? */
closure
		: L_FUNCTION_START list_exp L_FUNCTION_END
		{
			$$ = $2;
		}
	;

%%

const char *
yytokname(int i)
{
	return yytname[YYTRANSLATE(i)];
}

int
yyparser_parse(SV *program, const char *str)
{
	amd_parse_param_t	 param;
	int					 ret;

	// fprintf(stderr, "Start of yyparser_parse\n");
	// fflush(stderr);

	memset(&param, 0, sizeof(param));
	param.program = program;
	param.symtab = newHV();

	yylex_init(str);
#if YYDEBUG != 0
	yydebug = 1;
#endif

	ret = yyparse((void *)(&param));

	/* Delete the HV but not the contents. */
	hv_undef(param.symtab);

	return ret;
}
