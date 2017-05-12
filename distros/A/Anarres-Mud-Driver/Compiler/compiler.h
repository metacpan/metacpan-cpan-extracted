#ifndef __AMDP_COMPILER_H__
#define __AMDP_COMPILER_H__

#include <stdarg.h>

#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include "amd.h"



	/* Provided by utils.c */
void amd_dump(const char *prefix, SV *sv);
void amd_peek(const char *prefix, SV *sv);
void amd_require(const char *package);



	/* Provided by Compiler.xs */
HV		*amd_kwtab;
HV		*amd_lvaltab;



	/* Provided by lexer.yy */
void amd_yylex_init(const char *str);
void amd_yyunput_map_end();
void amd_yywarnv(const char *fmt, va_list args);
void amd_yywarnf(const char *fmt, ...)
				__attribute__((format(printf, 1, 2)));
void amd_yyerror(const char *str);
void amd_yyerrorf(const char *str, ...)
				__attribute__((format(printf, 1, 2)));



	/* Provided by parser.y */
const char * amd_yytokname(int i);
int amd_yyparser_parse(SV *program, const char *str);

typedef struct __amd_parse_param_t {
	SV	*program;
	HV	*symtab;
} amd_parse_param_t;

#define AMDP_PROGRAM(x) (((amd_parse_param_t *)(x))->program)


	/* Random others */
int test_lexer(const char *str);

#endif
