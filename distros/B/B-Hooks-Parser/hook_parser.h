#ifndef __HOOK_PARSER_H__
#define __HOOK_PARSER_H__

#include "perl.h"
#include "hook_op_check.h"

hook_op_check_id hook_parser_setup (pTHX);
void hook_parser_teardown (hook_op_check_id id);
char *hook_parser_get_linestr (pTHX);
IV hook_parser_get_linestr_offset (pTHX);
void hook_parser_set_linestr (pTHX_ const char *new_value);

char *hook_parser_get_lex_stuff (pTHX);
void hook_parser_clear_lex_stuff (pTHX);
char *hook_toke_skipspace (pTHX_ char *s);
char *hook_toke_scan_str (pTHX_ char *s);
char *hook_toke_scan_word (pTHX_ int offset, int handle_package, char *dest, STRLEN destlen, STRLEN *res_len);

#ifndef __PARSER_XS__
#define hook_parser_setup() hook_parser_setup(aTHX)
#endif

#endif
