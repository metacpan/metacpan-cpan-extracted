/*
 * 'sparse' library helper routines.
 *
 * Copyright (C) 2003 Transmeta Corp.
 *               2003-2004 Linus Torvalds
 *
 *  Licensed under the Open Software License version 1.1
 */
#include <ctype.h>
#include <fcntl.h>
#include <stdarg.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <assert.h>

#include <sys/types.h>

#include "lib.h"
#include "allocate.h"
#include "token.h"
#include "parse.h"
#include "symbol.h"
#include "expression.h"
#include "scope.h"
#include "linearize.h"
#include "target.h"
#include "version.h"

#ifndef DO_CTX
int verbose, optimize, optimize_size, preprocessing;
int die_if_error = 0;
#endif

#ifndef DO_CTX
/* def in ctx.h */
int gcc_major = __GNUC__;
int gcc_minor = __GNUC_MINOR__;
int gcc_patchlevel = __GNUC_PATCHLEVEL__;
struct token *pp_tokenlist = NULL;

static const char *gcc_base_dir = GCC_BASE;
int ppnoopt = 0, ppisinit = 0;
#endif

struct token *skip_to(SCTX_ struct token *token, int op)
{
	while (!match_op(token, op) && !eof_token(token))
		token = token->next;
	return token;
}

struct token *expect(SCTX_ struct token *token, int op, const char *where)
{
	if (!match_op(token, op)) {
		static struct token bad_token;
		if (token != &bad_token) {
			bad_token.next = token;
			sparse_error(sctx_ token->pos, "Expected %s %s", show_special(sctx_ op), where);
			sparse_error(sctx_ token->pos, "got %s", show_token(sctx_ token));
		}
		if (op == ';')
			return skip_to(sctx_ token, op);
		return &bad_token;
	}
	return token->next;
}

unsigned int hexval(SCTX_ unsigned int c)
{
	int retval = 256;
	switch (c) {
	case '0'...'9':
		retval = c - '0';
		break;
	case 'a'...'f':
		retval = c - 'a' + 10;
		break;
	case 'A'...'F':
		retval = c - 'A' + 10;
		break;
	}
	return retval;
}

static void do_warn(SCTX_ const char *type, struct position pos, const char * fmt, va_list args)
{
	static char buffer[512];
	const char *name;

	vsprintf(buffer, fmt, args);	
	name = stream_name(sctx_ pos.stream);
		
	fprintf(stderr, "%s:%d:%d: %s%s\n",
		name, pos.line, pos.pos, type, buffer);
}

#ifndef DO_CTX
static int max_warnings = 100;
static int show_info = 1;
#endif

void info(SCTX_ struct position pos, const char * fmt, ...)
{
	va_list args;

	if (!sctxp show_info)
		return;
	va_start(args, fmt);
	do_warn(sctx_ "", pos, fmt, args);
	va_end(args);
}

void warning(SCTX_ struct position pos, const char * fmt, ...)
{
	va_list args;

	if (!sctxp max_warnings) {
		sctxp show_info = 0;
		return;
	}

	if (!--sctxp max_warnings) {
		sctxp show_info = 0;
		fmt = "too many warnings";
	}

	va_start(args, fmt);
	do_warn(sctx_ "warning: ", pos, fmt, args);
	va_end(args);
}	

static void do_error(SCTX_ struct position pos, const char * fmt, va_list args)
{
	static int errors = 0;
        sctxp die_if_error = 1;
	sctxp show_info = 1;
	/* Shut up warnings after an error */
	sctxp max_warnings = 0;
	if (errors > 100) {
		static int once = 0;
		sctxp show_info = 0;
		if (once)
			return;
		fmt = "too many errors";
		once = 1;
	}

	do_warn(sctx_ "error: ", pos, fmt, args);
	errors++;
}	

void sparse_error(SCTX_ struct position pos, const char * fmt, ...)
{
	va_list args;
	va_start(args, fmt);
	do_error(sctx_ pos, fmt, args);
	va_end(args);
}

void expression_error(SCTX_ struct expression *expr, const char *fmt, ...)
{
	va_list args;
	va_start(args, fmt);
	do_error(sctx_ expr->pos->pos, fmt, args);
	va_end(args);
	expr->ctype = &sctxp bad_ctype;
}

void error_die(SCTX_ struct position pos, const char * fmt, ...) 
{
	va_list args;
	va_start(args, fmt);
	do_warn(sctx_ "error: ", pos, fmt, args);
	va_end(args);
	exit(1);
}

void sparse_die(SCTX_ const char *fmt, ...) 
{
	va_list args;
	static char buffer[512];

	va_start(args, fmt);
	vsnprintf(buffer, sizeof(buffer), fmt, args);
	va_end(args);

	fprintf(stderr, "%s\n", buffer);
	exit(1);
}

#ifndef DO_CTX
static struct token *pre_buffer_begin = NULL;
static struct token *pre_buffer_end = NULL;

int Waddress_space = 1;
int Wbitwise = 0;
int Wcast_to_as = 0;
int Wcast_truncate = 1;
int Wcontext = 1;
int Wdecl = 1;
int Wdeclarationafterstatement = -1;
int Wdefault_bitfield_sign = 0;
int Wdesignated_init = 1;
int Wdo_while = 0;
int Winit_cstring = 0;
int Wenum_mismatch = 1;
int Wnon_pointer_null = 1;
int Wold_initializer = 1;
int Wone_bit_signed_bitfield = 1;
int Wparen_string = 0;
int Wptr_subtraction_blows = 0;
int Wreturn_void = 0;
int Wshadow = 0;
int Wtransparent_union = 0;
int Wtypesign = 0;
int Wundef = 0;
int Wuninitialized = 1;
int Wvla = 1;

int dbg_entry = 0;
int dbg_dead = 0;

int preprocess_only;

enum standard_enum standard = STANDARD_GNU89;

#endif

/* ctx.h:
#ifdef __x86_64__
#define ARCH_M64_DEFAULT 1
#else
#define ARCH_M64_DEFAULT 0
#endif
*/

#ifndef DO_CTX
int arch_m64 = ARCH_M64_DEFAULT;
int arch_msize_long = 0;

/*#define CMDLINE_INCLUDE 20*//*ctx.h*/
static int cmdline_include_nr = 0;
static char *cmdline_include[CMDLINE_INCLUDE];
#endif 


void add_pre_buffer(SCTX_ int idx, const char *fmt, ...)
{
	va_list args;
	unsigned int size;
	struct token *begin, *end;
	char buffer[4096];
	struct expansion *e;

	va_start(args, fmt);
	size = vsnprintf(buffer, sizeof(buffer), fmt, args);
	va_end(args);
	e = tokenize_buffer(sctx_ buffer, idx, size, &end);
	begin = e->s;
	if (!sctxp pre_buffer_begin)
		sctxp pre_buffer_begin = begin;
	if (sctxp pre_buffer_end)
		sctxp pre_buffer_end->next = begin;
	sctxp pre_buffer_end = end;
}

static char **handle_switch_D(SCTX_ char *arg, char **next)
{
	const char *name = arg + 1;
	const char *value = "1";

	if (!*name || isspace(*name))
		sparse_die(sctx_ "argument to `-D' is missing");

	for (;;) {
		char c;
		c = *++arg;
		if (!c)
			break;
		if (isspace((unsigned char)c) || c == '=') {
			*arg = '\0';
			value = arg + 1;
			break;
		}
	}
	add_pre_buffer(sctx_ sctxp stream_sc->id, "#define %s %s\n", name, value);
	return next;
}

static char **handle_switch_E(SCTX_ char *arg, char **next)
{
	if (arg[1] == '\0')
		sctxp preprocess_only = 1;
	return next;
}

static char **handle_switch_I(SCTX_ char *arg, char **next)
{
	char *path = arg+1;

	switch (arg[1]) {
	case '-':
		add_pre_buffer(sctx_ sctxp stream_sc->id, "#split_include\n");
		break;

	case '\0':	/* Plain "-I" */
		path = *++next;
		if (!path)
			sparse_die(sctx_ "missing argument for -I option");
		/* Fall through */
	default:
		add_pre_buffer(sctx_ sctxp stream_sc->id, "#add_include \"%s/\"\n", path);
	}
	return next;
}

static void add_cmdline_include(SCTX_ char *filename)
{
	if (sctxp cmdline_include_nr >= CMDLINE_INCLUDE)
		sparse_die(sctx_ "too many include files for %s\n", filename);
	sctxp cmdline_include[sctxp cmdline_include_nr++] = filename;
}

static char **handle_switch_i(SCTX_ char *arg, char **next)
{
	if (*next && !strcmp(arg, "include"))
		add_cmdline_include(sctx_ *++next);
	else if (*next && !strcmp(arg, "imacros"))
		add_cmdline_include(sctx_ *++next);
	else if (*next && !strcmp(arg, "isystem")) {
		char *path = *++next;
		if (!path)
			sparse_die(sctx_ "missing argument for -isystem option");
		add_pre_buffer(sctx_ sctxp stream_sc->id, "#add_isystem \"%s/\"\n", path);
	} else if (*next && !strcmp(arg, "idirafter")) {
		char *path = *++next;
		if (!path)
			sparse_die(sctx_ "missing argument for -idirafter option");
		add_pre_buffer(sctx_ sctxp stream_sc->id, "#add_dirafter \"%s/\"\n", path);
	}
	return next;
}

static char **handle_switch_M(SCTX_ char *arg, char **next)
{
	if (!strcmp(arg, "MF") || !strcmp(arg,"MQ") || !strcmp(arg,"MT")) {
		if (!*next)
			sparse_die(sctx_ "missing argument for -%s option", arg);
		return next + 1;
	}
	return next;
}

static char **handle_switch_m(SCTX_ char *arg, char **next)
{
	if (!strcmp(arg, "m64")) {
		sctxp arch_m64 = 1;
	} else if (!strcmp(arg, "m32")) {
		sctxp arch_m64 = 0;
	} else if (!strcmp(arg, "msize-long")) {
		sctxp arch_msize_long = 1;
	}
	return next;
}

static void handle_arch_m64_finalize(SCTX)
{
	if (sctxp arch_m64) {
		sctxp bits_in_long = 64;
		sctxp max_int_alignment = 8;
		sctxp bits_in_pointer = 64;
		sctxp pointer_alignment = 8;
		sctxp size_t_ctype = &sctxp ulong_ctype;
		sctxp ssize_t_ctype = &sctxp long_ctype;
#ifdef __x86_64__
		add_pre_buffer(sctx_ sctxp stream_sb->id, "#weak_define __x86_64__ 1\n");
#endif
	}
}

static void handle_arch_msize_long_finalize(SCTX)
{
	if (sctxp arch_msize_long) {
		sctxp size_t_ctype = &sctxp ulong_ctype;
		sctxp ssize_t_ctype = &sctxp long_ctype;
	}
}

static void handle_arch_finalize(SCTX)
{
	handle_arch_m64_finalize(sctx );
	handle_arch_msize_long_finalize(sctx );
}


static char **handle_switch_o(SCTX_ char *arg, char **next)
{
	if (!strcmp (arg, "o")) {       // "-o foo"
		if (!*++next)
			sparse_die(sctx_ "argument to '-o' is missing");
	}
	// else "-ofoo"

	return next;
}

#ifndef DO_CTX
static const struct warning warnings[WCNT] = {
	{ "address-space", &Waddress_space },
	{ "bitwise", &Wbitwise },
	{ "cast-to-as", &Wcast_to_as },
	{ "cast-truncate", &Wcast_truncate },
	{ "context", &Wcontext },
	{ "decl", &Wdecl },
	{ "declaration-after-statement", &Wdeclarationafterstatement },
	{ "default-bitfield-sign", &Wdefault_bitfield_sign },
	{ "designated-init", &Wdesignated_init },
	{ "do-while", &Wdo_while },
	{ "enum-mismatch", &Wenum_mismatch },
	{ "init-cstring", &Winit_cstring },
	{ "non-pointer-null", &Wnon_pointer_null },
	{ "old-initializer", &Wold_initializer },
	{ "one-bit-signed-bitfield", &Wone_bit_signed_bitfield },
	{ "paren-string", &Wparen_string },
	{ "ptr-subtraction-blows", &Wptr_subtraction_blows },
	{ "return-void", &Wreturn_void },
	{ "shadow", &Wshadow },
	{ "transparent-union", &Wtransparent_union },
	{ "typesign", &Wtypesign },
	{ "undef", &Wundef },
	{ "uninitialized", &Wuninitialized },
	{ "vla", &Wvla },
};
#endif 

enum {
	WARNING_OFF,
	WARNING_ON,
	WARNING_FORCE_OFF
};


static char **handle_onoff_switch(SCTX_ char *arg, char **next, const struct warning *warnings, int n)
{
	int flag = WARNING_ON;
	char *p = arg + 1;
	unsigned i;

	if (!strcmp(p, "sparse-all")) {
		for (i = 0; i < n; i++) {
			if (*warnings[i].flag != WARNING_FORCE_OFF)
				*warnings[i].flag = WARNING_ON;
		}
	}

	// Prefixes "no" and "no-" mean to turn warning off.
	if (p[0] == 'n' && p[1] == 'o') {
		p += 2;
		if (p[0] == '-')
			p++;
		flag = WARNING_FORCE_OFF;
	}

	for (i = 0; i < n; i++) {
		if (!strcmp(p,warnings[i].name)) {
			*warnings[i].flag = flag;
			return next;
		}
	}

	// Unknown.
	return NULL;
}

static char **handle_switch_W(SCTX_ char *arg, char **next)
{
	char ** ret = handle_onoff_switch(sctx_ arg, next, sctxp warnings, WCNT /*ARRAY_SIZE(warnings)*/);
	if (ret)
		return ret;

	// Unknown.
	return next;
}

#ifndef DO_CTX
static struct warning debugs[] = {
	{ "entry", &dbg_entry},
	{ "dead", &dbg_dead},
};
#endif

static char **handle_switch_v(SCTX_ char *arg, char **next)
{
	char ** ret = handle_onoff_switch(sctx_ arg, next, sctxp debugs, DCNT /*ARRAY_SIZE(debugs)*/);
	if (ret)
		return ret;

	// Unknown.
	do {
		sctxp verbose++;
	} while (*++arg == 'v');
	return next;
}


static void handle_onoff_switch_finalize(SCTX_ const struct warning *warnings, int n)
{
	unsigned i;

	for (i = 0; i < n; i++) {
		if (*(warnings[i].flag) == WARNING_FORCE_OFF)
			*(warnings[i].flag) = WARNING_OFF;
	}
}

static void handle_switch_W_finalize(SCTX)
{
	handle_onoff_switch_finalize(sctx_ sctxp warnings, WCNT /*ÜARRAY_SIZE(warnings)*/);

	/* default Wdeclarationafterstatement based on the C dialect */
	if (-1 == sctxp Wdeclarationafterstatement)
	{
		switch (sctxp standard)
		{
			case STANDARD_C89:
			case STANDARD_C94:
				sctxp Wdeclarationafterstatement = 1;
				break;

			case STANDARD_C99:
			case STANDARD_GNU89:
			case STANDARD_GNU99:
				sctxp Wdeclarationafterstatement = 0;
				break;

			default:
				assert (0);
		}

	}
}

static void handle_switch_v_finalize(SCTX)
{
	handle_onoff_switch_finalize(sctx_ sctxp debugs, DCNT /*ARRAY_SIZE(debugs)*/);
}

static char **handle_switch_U(SCTX_ char *arg, char **next)
{
	const char *name = arg + 1;
	add_pre_buffer (sctx_ sctxp stream_sc->id, "#undef %s\n", name);
	return next;
}

static char **handle_switch_O(SCTX_ char *arg, char **next)
{
	int level = 1;
	if (arg[1] >= '0' && arg[1] <= '9')
		level = arg[1] - '0';
	sctxp optimize = level;
	sctxp optimize_size = arg[1] == 's';
	return next;
}

static char **handle_switch_ftabstop(SCTX_ char *arg, char **next)
{
	char *end;
	unsigned long val;

	if (*arg == '\0')
		sparse_die(sctx_ "error: missing argument to \"-ftabstop=\"");

	/* we silently ignore silly values */
	val = strtoul(arg, &end, 10);
	if (*end == '\0' && 1 <= val && val <= 100)
		sctxp tabstop = val;

	return next;
}

static char **handle_switch_f(SCTX_ char *arg, char **next)
{
	arg++;

	if (!strncmp(arg, "tabstop=", 8))
		return handle_switch_ftabstop(sctx_ arg+8, next);

	/* handle switches w/ arguments above, boolean and only boolean below */

	if (!strncmp(arg, "no-", 3)) {
		arg += 3;
	}
	/* handle switch here.. */
	return next;
}

static char **handle_switch_G(SCTX_ char *arg, char **next)
{
	if (!strcmp (arg, "G") && *next)
		return next + 1; // "-G 0"
	else
		return next;     // "-G0" or (bogus) terminal "-G"
}

static char **handle_switch_a(SCTX_ char *arg, char **next)
{
	if (!strcmp (arg, "ansi"))
		sctxp standard = STANDARD_C89;

	return next;
}

static char **handle_switch_s(SCTX_ char *arg, char **next)
{
	if (!strncmp (arg, "std=", 4))
	{
		arg += 4;

		if (!strcmp (arg, "c89") ||
		    !strcmp (arg, "iso9899:1990"))
			sctxp standard = STANDARD_C89;

		else if (!strcmp (arg, "iso9899:199409"))
			sctxp standard = STANDARD_C94;

		else if (!strcmp (arg, "c99") ||
			 !strcmp (arg, "c9x") ||
			 !strcmp (arg, "iso9899:1999") ||
			 !strcmp (arg, "iso9899:199x"))
			sctxp standard = STANDARD_C99;

		else if (!strcmp (arg, "gnu89"))
			sctxp standard = STANDARD_GNU89;

		else if (!strcmp (arg, "gnu99") || !strcmp (arg, "gnu9x"))
			sctxp standard = STANDARD_GNU99;

		else
			sparse_die (sctx_ "Unsupported C dialect");
	}

	return next;
}

static char **handle_nostdinc_lib(SCTX_ char *arg, char **next)
{
	add_pre_buffer(sctx_ sctxp stream_sc->id, "#nostdinc\n");
	return next;
}

static char **handle_base_dir(SCTX_ char *arg, char **next)
{
	sctxp gcc_base_dir = *++next;
	if (!sctxp gcc_base_dir)
		sparse_die(sctx_ "missing argument for -gcc-base-dir option");
	return next;
}

static char **handle_version(SCTX_ char *arg, char **next)
{
	printf("%s\n", SPARSE_VERSION);
	exit(0);
}

struct switches {
	const char *name;
	char **(*fn)(SCTX_ char *, char **);
};

static char **handle_long_options(SCTX_ char *arg, char **next)
{
	static struct switches cmd[] = {
		{ "version", handle_version },
		{ NULL, NULL }
	};
	struct switches *s = cmd;

	while (s->name) {
		if (!strcmp(s->name, arg))
			return s->fn(sctx_ arg, next);
		s++;
	}
	return next;

}

static char **handle_switch(SCTX_ char *arg, char **next)
{
	static struct switches cmd[] = {
		{ "nostdinc", handle_nostdinc_lib },
		{ "gcc-base-dir", handle_base_dir},
		{ NULL, NULL }
	};
	struct switches *s;

	switch (*arg) {
	case 'D': return handle_switch_D(sctx_ arg, next);
	case 'E': return handle_switch_E(sctx_ arg, next);
	case 'I': return handle_switch_I(sctx_ arg, next);
	case 'i': return handle_switch_i(sctx_ arg, next);
	case 'M': return handle_switch_M(sctx_ arg, next);
	case 'm': return handle_switch_m(sctx_ arg, next);
	case 'o': return handle_switch_o(sctx_ arg, next);
	case 'U': return handle_switch_U(sctx_ arg, next);
	case 'v': return handle_switch_v(sctx_ arg, next);
	case 'W': return handle_switch_W(sctx_ arg, next);
	case 'O': return handle_switch_O(sctx_ arg, next);
	case 'f': return handle_switch_f(sctx_ arg, next);
	case 'G': return handle_switch_G(sctx_ arg, next);
	case 'a': return handle_switch_a(sctx_ arg, next);
	case 's': return handle_switch_s(sctx_ arg, next);
	case '-': return handle_long_options(sctx_ arg + 1, next);
	default:
		break;
	}

	s = cmd;
	while (s->name) {
		if (!strcmp(s->name, arg))
			return s->fn(sctx_ arg, next);
		s++;
	}

	/*
	 * Ignore unknown command line options:
	 * they're probably gcc switches
	 */
	return next;
}

void declare_builtin_functions(SCTX)
{
	/* Gaah. gcc knows tons of builtin <string.h> functions */
	add_pre_buffer(sctx_ sctxp stream_sb->id, "extern void *__builtin_memcpy(void *, const void *, __SIZE_TYPE__);\n");
	add_pre_buffer(sctx_ sctxp stream_sb->id, "extern void *__builtin_mempcpy(void *, const void *, __SIZE_TYPE__);\n");
	add_pre_buffer(sctx_ sctxp stream_sb->id, "extern void *__builtin_memset(void *, int, __SIZE_TYPE__);\n");
	add_pre_buffer(sctx_ sctxp stream_sb->id, "extern int __builtin_memcmp(const void *, const void *, __SIZE_TYPE__);\n");
	add_pre_buffer(sctx_ sctxp stream_sb->id, "extern char *__builtin_strcat(char *, const char *);\n");
	add_pre_buffer(sctx_ sctxp stream_sb->id, "extern char *__builtin_strncat(char *, const char *, __SIZE_TYPE__);\n");
	add_pre_buffer(sctx_ sctxp stream_sb->id, "extern int __builtin_strcmp(const char *, const char *);\n");
	add_pre_buffer(sctx_ sctxp stream_sb->id, "extern char *__builtin_strchr(const char *, int);\n");
	add_pre_buffer(sctx_ sctxp stream_sb->id, "extern char *__builtin_strcpy(char *, const char *);\n");
	add_pre_buffer(sctx_ sctxp stream_sb->id, "extern char *__builtin_strncpy(char *, const char *, __SIZE_TYPE__);\n");
	add_pre_buffer(sctx_ sctxp stream_sb->id, "extern __SIZE_TYPE__ __builtin_strspn(const char *, const char *);\n");
	add_pre_buffer(sctx_ sctxp stream_sb->id, "extern __SIZE_TYPE__ __builtin_strcspn(const char *, const char *);\n");
	add_pre_buffer(sctx_ sctxp stream_sb->id, "extern char * __builtin_strpbrk(const char *, const char *);\n");
	add_pre_buffer(sctx_ sctxp stream_sb->id, "extern char* __builtin_stpcpy(const char *, const char*);\n");
	add_pre_buffer(sctx_ sctxp stream_sb->id, "extern __SIZE_TYPE__ __builtin_strlen(const char *);\n");

	/* And bitwise operations.. */
	add_pre_buffer(sctx_ sctxp stream_sb->id, "extern int __builtin_clz(int);\n");
	add_pre_buffer(sctx_ sctxp stream_sb->id, "extern int __builtin_clzl(long);\n");
	add_pre_buffer(sctx_ sctxp stream_sb->id, "extern int __builtin_clzll(long long);\n");
	add_pre_buffer(sctx_ sctxp stream_sb->id, "extern int __builtin_ctz(int);\n");
	add_pre_buffer(sctx_ sctxp stream_sb->id, "extern int __builtin_ctzl(long);\n");
	add_pre_buffer(sctx_ sctxp stream_sb->id, "extern int __builtin_ctzll(long long);\n");
	add_pre_buffer(sctx_ sctxp stream_sb->id, "extern int __builtin_ffs(int);\n");
	add_pre_buffer(sctx_ sctxp stream_sb->id, "extern int __builtin_ffsl(long);\n");
	add_pre_buffer(sctx_ sctxp stream_sb->id, "extern int __builtin_ffsll(long long);\n");
	add_pre_buffer(sctx_ sctxp stream_sb->id, "extern int __builtin_popcount(unsigned int);\n");
	add_pre_buffer(sctx_ sctxp stream_sb->id, "extern int __builtin_popcountl(unsigned long);\n");
	add_pre_buffer(sctx_ sctxp stream_sb->id, "extern int __builtin_popcountll(unsigned long long);\n");

	/* And byte swaps.. */
	add_pre_buffer(sctx_ sctxp stream_sb->id, "extern unsigned short __builtin_bswap16(unsigned short);\n");
	add_pre_buffer(sctx_ sctxp stream_sb->id, "extern unsigned int __builtin_bswap32(unsigned int);\n");
	add_pre_buffer(sctx_ sctxp stream_sb->id, "extern unsigned long long __builtin_bswap64(unsigned long long);\n");

	/* And some random ones.. */
	add_pre_buffer(sctx_ sctxp stream_sb->id, "extern void *__builtin_return_address(unsigned int);\n");
	add_pre_buffer(sctx_ sctxp stream_sb->id, "extern void *__builtin_extract_return_addr(void *);\n");
	add_pre_buffer(sctx_ sctxp stream_sb->id, "extern void *__builtin_frame_address(unsigned int);\n");
	add_pre_buffer(sctx_ sctxp stream_sb->id, "extern void __builtin_trap(void);\n");
	add_pre_buffer(sctx_ sctxp stream_sb->id, "extern void *__builtin_alloca(__SIZE_TYPE__);\n");
	add_pre_buffer(sctx_ sctxp stream_sb->id, "extern void __builtin_prefetch (const void *, ...);\n");
	add_pre_buffer(sctx_ sctxp stream_sb->id, "extern long __builtin_alpha_extbl(long, long);\n");
	add_pre_buffer(sctx_ sctxp stream_sb->id, "extern long __builtin_alpha_extwl(long, long);\n");
	add_pre_buffer(sctx_ sctxp stream_sb->id, "extern long __builtin_alpha_insbl(long, long);\n");
	add_pre_buffer(sctx_ sctxp stream_sb->id, "extern long __builtin_alpha_inswl(long, long);\n");
	add_pre_buffer(sctx_ sctxp stream_sb->id, "extern long __builtin_alpha_insql(long, long);\n");
	add_pre_buffer(sctx_ sctxp stream_sb->id, "extern long __builtin_alpha_inslh(long, long);\n");
	add_pre_buffer(sctx_ sctxp stream_sb->id, "extern long __builtin_alpha_cmpbge(long, long);\n");
	add_pre_buffer(sctx_ sctxp stream_sb->id, "extern long __builtin_labs(long);\n");
	add_pre_buffer(sctx_ sctxp stream_sb->id, "extern double __builtin_fabs(double);\n");
	add_pre_buffer(sctx_ sctxp stream_sb->id, "extern void __sync_synchronize();\n");
	add_pre_buffer(sctx_ sctxp stream_sb->id, "extern int __sync_bool_compare_and_swap(void *, ...);\n");

	/* Add Blackfin-specific stuff */
	add_pre_buffer(sctx_ sctxp stream_sb->id, 
		"#ifdef __bfin__\n"
		"extern void __builtin_bfin_csync(void);\n"
		"extern void __builtin_bfin_ssync(void);\n"
		"extern int __builtin_bfin_norm_fr1x32(int);\n"
		"#endif\n"
	);

	/* And some floating point stuff.. */
	add_pre_buffer(sctx_ sctxp stream_sb->id, "extern int __builtin_isgreater(float, float);\n");
	add_pre_buffer(sctx_ sctxp stream_sb->id, "extern int __builtin_isgreaterequal(float, float);\n");
	add_pre_buffer(sctx_ sctxp stream_sb->id, "extern int __builtin_isless(float, float);\n");
	add_pre_buffer(sctx_ sctxp stream_sb->id, "extern int __builtin_islessequal(float, float);\n");
	add_pre_buffer(sctx_ sctxp stream_sb->id, "extern int __builtin_islessgreater(float, float);\n");
	add_pre_buffer(sctx_ sctxp stream_sb->id, "extern int __builtin_isunordered(float, float);\n");

	/* And some __FORTIFY_SOURCE ones.. */
	add_pre_buffer (sctx_ sctxp stream_sb->id, "extern __SIZE_TYPE__ __builtin_object_size(void *, int);\n");
	add_pre_buffer (sctx_ sctxp stream_sb->id, "extern void * __builtin___memcpy_chk(void *, const void *, __SIZE_TYPE__, __SIZE_TYPE__);\n");
	add_pre_buffer (sctx_ sctxp stream_sb->id, "extern void * __builtin___memmove_chk(void *, const void *, __SIZE_TYPE__, __SIZE_TYPE__);\n");
	add_pre_buffer (sctx_ sctxp stream_sb->id, "extern void * __builtin___mempcpy_chk(void *, const void *, __SIZE_TYPE__, __SIZE_TYPE__);\n");
	add_pre_buffer (sctx_ sctxp stream_sb->id, "extern void * __builtin___memset_chk(void *, int, __SIZE_TYPE__, __SIZE_TYPE__);\n");
	add_pre_buffer (sctx_ sctxp stream_sb->id, "extern int __builtin___sprintf_chk(char *, int, __SIZE_TYPE__, const char *, ...);\n");
	add_pre_buffer (sctx_ sctxp stream_sb->id, "extern int __builtin___snprintf_chk(char *, __SIZE_TYPE__, int , __SIZE_TYPE__, const char *, ...);\n");
	add_pre_buffer (sctx_ sctxp stream_sb->id, "extern char * __builtin___stpcpy_chk(char *, const char *, __SIZE_TYPE__);\n");
	add_pre_buffer (sctx_ sctxp stream_sb->id, "extern char * __builtin___strcat_chk(char *, const char *, __SIZE_TYPE__);\n");
	add_pre_buffer (sctx_ sctxp stream_sb->id, "extern char * __builtin___strcpy_chk(char *, const char *, __SIZE_TYPE__);\n");
	add_pre_buffer (sctx_ sctxp stream_sb->id, "extern char * __builtin___strncat_chk(char *, const char *, __SIZE_TYPE__, __SIZE_TYPE__);\n");
	add_pre_buffer (sctx_ sctxp stream_sb->id, "extern char * __builtin___strncpy_chk(char *, const char *, __SIZE_TYPE__, __SIZE_TYPE__);\n");
	add_pre_buffer (sctx_ sctxp stream_sb->id, "extern int __builtin___vsprintf_chk(char *, int, __SIZE_TYPE__, const char *, __builtin_va_list);\n");
	add_pre_buffer (sctx_ sctxp stream_sb->id, "extern int __builtin___vsnprintf_chk(char *, __SIZE_TYPE__, int, __SIZE_TYPE__, const char *, __builtin_va_list ap);\n");
	add_pre_buffer (sctx_ sctxp stream_sb->id, "extern void __builtin_unreachable(void);\n");
}

void create_builtin_stream(SCTX)
{
	add_pre_buffer(sctx_ sctxp stream_sb->id, "#weak_define __GNUC__ %d\n", sctxp gcc_major);
	add_pre_buffer(sctx_ sctxp stream_sb->id, "#weak_define __GNUC_MINOR__ %d\n", sctxp gcc_minor);
	add_pre_buffer(sctx_ sctxp stream_sb->id, "#weak_define __GNUC_PATCHLEVEL__ %d\n", sctxp gcc_patchlevel);

	/* We add compiler headers path here because we have to parse
	 * the arguments to get it, falling back to default. */
	add_pre_buffer(sctx_ sctxp stream_sb->id, "#add_system \"%s/include\"\n", sctxp gcc_base_dir);
	add_pre_buffer(sctx_ sctxp stream_sb->id, "#add_system \"%s/include-fixed\"\n", sctxp gcc_base_dir);

	add_pre_buffer(sctx_ sctxp stream_sb->id, "#define __extension__\n");
	add_pre_buffer(sctx_ sctxp stream_sb->id, "#define __pragma__\n");

	// gcc defines __SIZE_TYPE__ to be size_t.  For linux/i86 and
	// solaris/sparc that is really "unsigned int" and for linux/x86_64
	// it is "long unsigned int".  In either case we can probably
	// get away with this.  We need the #weak_define as cgcc will define
	// the right __SIZE_TYPE__.
	if (sctxp size_t_ctype == &sctxp ulong_ctype)
		add_pre_buffer(sctx_ sctxp stream_sb->id, "#weak_define __SIZE_TYPE__ long unsigned int\n");
	else
		add_pre_buffer(sctx_ sctxp stream_sb->id, "#weak_define __SIZE_TYPE__ unsigned int\n");
	add_pre_buffer(sctx_ sctxp stream_sb->id, "#weak_define __STDC__ 1\n");

	switch (sctxp standard)
	{
		case STANDARD_C89:
			add_pre_buffer(sctx_ sctxp stream_sb->id, "#weak_define __STRICT_ANSI__\n");
			break;

		case STANDARD_C94:
			add_pre_buffer(sctx_ sctxp stream_sb->id, "#weak_define __STDC_VERSION__ 199409L\n");
			add_pre_buffer(sctx_ sctxp stream_sb->id, "#weak_define __STRICT_ANSI__\n");
			break;

		case STANDARD_C99:
			add_pre_buffer(sctx_ sctxp stream_sb->id, "#weak_define __STDC_VERSION__ 199901L\n");
			add_pre_buffer(sctx_ sctxp stream_sb->id, "#weak_define __STRICT_ANSI__\n");
			break;

		case STANDARD_GNU89:
			break;

		case STANDARD_GNU99:
			add_pre_buffer(sctx_ sctxp stream_sb->id, "#weak_define __STDC_VERSION__ 199901L\n");
			break;

		default:
			assert (0);
	}

	add_pre_buffer(sctx_ sctxp stream_sb->id, "#define __builtin_stdarg_start(a,b) ((a) = (__builtin_va_list)(&(b)))\n");
	add_pre_buffer(sctx_ sctxp stream_sb->id, "#define __builtin_va_start(a,b) ((a) = (__builtin_va_list)(&(b)))\n");
	add_pre_buffer(sctx_ sctxp stream_sb->id, "#define __builtin_ms_va_start(a,b) ((a) = (__builtin_ms_va_list)(&(b)))\n");
	add_pre_buffer(sctx_ sctxp stream_sb->id, "#define __builtin_va_arg(arg,type)  ({ type __va_arg_ret = *(type *)(arg); arg += sizeof(type); __va_arg_ret; })\n");
	add_pre_buffer(sctx_ sctxp stream_sb->id, "#define __builtin_va_alist (*(void *)0)\n");
	add_pre_buffer(sctx_ sctxp stream_sb->id, "#define __builtin_va_arg_incr(x) ((x) + 1)\n");
	add_pre_buffer(sctx_ sctxp stream_sb->id, "#define __builtin_va_copy(dest, src) ({ dest = src; (void)0; })\n");
	add_pre_buffer(sctx_ sctxp stream_sb->id, "#define __builtin_va_end(arg)\n");
	add_pre_buffer(sctx_ sctxp stream_sb->id, "#define __builtin_ms_va_end(arg)\n");

	/* FIXME! We need to do these as special magic macros at expansion time! */
	add_pre_buffer(sctx_ sctxp stream_sb->id, "#define __BASE_FILE__ \"base_file.c\"\n");

	if (sctxp optimize)
		add_pre_buffer(sctx_ sctxp stream_sb->id, "#define __OPTIMIZE__ 1\n");
	if (sctxp optimize_size)
		add_pre_buffer(sctx_ sctxp stream_sb->id, "#define __OPTIMIZE_SIZE__ 1\n");

	/* GCC defines these for limits.h */
	add_pre_buffer(sctx_ sctxp stream_sb->id, "#weak_define __SHRT_MAX__ " SPARSE_STRINGIFY(__SHRT_MAX__) "\n");
	add_pre_buffer(sctx_ sctxp stream_sb->id, "#weak_define __SCHAR_MAX__ " SPARSE_STRINGIFY(__SCHAR_MAX__) "\n");
	add_pre_buffer(sctx_ sctxp stream_sb->id, "#weak_define __INT_MAX__ " SPARSE_STRINGIFY(__INT_MAX__) "\n");
	add_pre_buffer(sctx_ sctxp stream_sb->id, "#weak_define __LONG_MAX__ " SPARSE_STRINGIFY(__LONG_MAX__) "\n");
	add_pre_buffer(sctx_ sctxp stream_sb->id, "#weak_define __LONG_LONG_MAX__ " SPARSE_STRINGIFY(__LONG_LONG_MAX__) "\n");
	add_pre_buffer(sctx_ sctxp stream_sb->id, "#weak_define __WCHAR_MAX__ " SPARSE_STRINGIFY(__WCHAR_MAX__) "\n");
	add_pre_buffer(sctx_ sctxp stream_sb->id, "#weak_define __SIZEOF_POINTER__ " SPARSE_STRINGIFY(__SIZEOF_POINTER__) "\n");
}

static struct symbol_list *sparse_tokenstream(SCTX_ struct expansion *e)
{
	struct token *token;
	// Preprocess the stream
	token = preprocess(sctx_ e);

	sctxp pp_tokenlist = token;
	if (sctxp preprocess_only) {
	        while (!eof_token(token)) {
			int prec = 1;
			struct token *next = token->next;
			const char *separator = "";
			if (next->pos.whitespace)
				separator = " ";
			if (next->pos.newline) {
				separator = "\n\t\t\t\t\t";
				prec = next->pos.pos;
				if (prec > 4)
					prec = 4;
			}
			printf("%s%.*s", show_token(sctx_ token), prec, separator);
			token = next;
		}
		putchar('\n');

		return NULL;
	}

	// Parse the resulting C code
	while (!eof_token(token))
		token = external_declaration(sctx_ token, &sctxp translation_unit_used_list);
	return sctxp translation_unit_used_list;
}

static struct symbol_list *sparse_file(SCTX_ const char *filename)
{
	int fd;
	struct expansion *e;

	if (strcmp (filename, "-") == 0) {
		fd = 0;
	} else {
		fd = open(filename, O_RDONLY);
		if (fd < 0)
			sparse_die(sctx_ "No such file: %s", filename);
	}

	// Tokenize the input stream
	e = tokenize(sctx_ filename, fd, NULL, sctxp includepath);
	close(fd);

	return sparse_tokenstream(sctx_ e);
}

/*
 * This handles the "-include" directive etc: we're in global
 * scope, and all types/macros etc will affect all the following
 * files.
 *
 * NOTE NOTE NOTE! "#undef" of anything in this stage will
 * affect all subsequent files too, i.e. we can have non-local
 * behaviour between files!
 */
static struct symbol_list *sparse_initial(SCTX)
{
	int i; struct expansion *e;

	// Prepend any "include" file to the stream.
	// We're in global scope, it will affect all files!
	for (i = 0; i < sctxp cmdline_include_nr; i++)
		add_pre_buffer(sctx_ sctxp stream_sc->id, "#argv_include \"%s\"\n", sctxp cmdline_include[i]);
	
	e = expansion_new(sctx_ EXPANSION_CMDLINE);

	e->s = sctxp pre_buffer_begin;
	list_e(sctx_ e->s, 0, e);

	return sparse_tokenstream(sctx_ e);
}

struct symbol_list *sparse_initialize(SCTX_ int argc, char **argv, struct string_list **filelist)
{
	char **args;
	struct symbol_list *list;

	// Initialize symbol stream first, so that we can add defines etc
	init_symbols(sctx );

	args = argv;
	for (;;) {
		char *arg = *++args;
		if (!arg)
			break;

		if (arg[0] == '-' && arg[1]) {
			args = handle_switch(sctx_ arg+1, args);
			continue;
		}
		add_ptr_list_notag(filelist, arg);
	}
	handle_switch_W_finalize(sctx);
	handle_switch_v_finalize(sctx);

	handle_arch_finalize(sctx);

	list = NULL;
	if (!ptr_list_empty(filelist)) {
		// Initialize type system
		init_ctype(sctx);

		create_builtin_stream(sctx);
		add_pre_buffer(sctx_ sctxp stream_sb->id, "#define __CHECKER__ 1\n");
		if (!sctxp preprocess_only)
			declare_builtin_functions(sctx);

		list = sparse_initial(sctx );

		/*
		 * Protect the initial token allocations, since
		 * they need to survive all the others
		 */
		protect_token_alloc(sctx );
	}
	return list;
}

struct symbol_list * sparse_keep_tokens(SCTX_ char *filename)
{
	struct symbol_list *res;

	/* Clear previous symbol list */
	sctxp translation_unit_used_list = NULL;

	new_file_scope(sctx );
	res = sparse_file(sctx_ filename);

	/* And return it */
	return res;
}


struct symbol_list * __sparse(SCTX_ char *filename)
{
	struct symbol_list *res;

	res = sparse_keep_tokens(sctx_ filename);

	/* Drop the tokens for this file after parsing */
	clear_token_alloc(sctx );

	/* And return it */
	return res;
}

struct symbol_list * sparse(SCTX_ char *filename)
{
	struct symbol_list *res = __sparse(sctx_ filename);

	/* Evaluate the complete symbol list */
	evaluate_symbol_list(sctx_ res);

	return res;
}
