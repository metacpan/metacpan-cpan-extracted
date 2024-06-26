#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#include "libtcc.h"

/* ---- Zephram's book of preprocessor hacks ---- */
#define PERL_VERSION_DECIMAL(r,v,s) (r*1000000 + v*1000 + s)
#define PERL_DECIMAL_VERSION \
        PERL_VERSION_DECIMAL(PERL_REVISION,PERL_VERSION,PERL_SUBVERSION)
#define PERL_VERSION_GE(r,v,s) \
        (PERL_DECIMAL_VERSION >= PERL_VERSION_DECIMAL(r,v,s))

/* ---- pad_findmy_pv ---- */
#ifndef pad_findmy_pv
# if PERL_VERSION_GE(5,11,2)
#  define pad_findmy_pv(name, flags) pad_findmy(name, strlen(name), flags)
# else /* <5.11.2 */
#  define pad_findmy_pv(name, flags) pad_findmy(name)
# endif /* <5.11.2 */
#endif /* !pad_findmy_pv */

#ifndef GvCV_set
#define GvCV_set(gv, cv) (GvCV(gv) = (CV*)(cv))
#endif

#ifndef pad_compname_type
#define pad_compname_type(a)	Perl_pad_compname_type(aTHX_ a)
#endif

int (*next_keyword_plugin)(pTHX_ char *, STRLEN, OP **);

typedef void (*my_void_func)(pTHX);

typedef struct _available_extended_symtab {
	extended_symtab_p exsymtab;
	void ** dlls;
} available_extended_symtab;

XOP tcc_xop;
PP(tcc_pp) {
    dVAR;
    dSP;
	IV pointer_iv = POPi;
	my_void_func p_to_call = INT2PTR(my_void_func, pointer_iv);
	p_to_call(aTHX);
	RETURN;
}

#ifdef PERL_IMPLICIT_CONTEXT
	/* according to perl.h, these macros only exist we have
	 * PERL_IMPLICIT_CONTEXT defined */
	#define C_BLOCKS_THX_DECL tTHX aTHX
	#define C_BLOCKS_THX_DECL__ tTHX aTHX;
	#define C_BLOCKS_CALLBACK_MY_PERL(callback) callback->aTHX,
#else
	#define C_BLOCKS_THX_DECL
	#define C_BLOCKS_THX_DECL__
	#define C_BLOCKS_CALLBACK_MY_PERL(callback)
#endif

/* ---- Extended symbol table handling ---- */
typedef struct _extended_symtab_callback_data {
	TCCState * state;
	C_BLOCKS_THX_DECL__
	available_extended_symtab * available_extended_symtabs;
	int N_tables;
} extended_symtab_callback_data;

/******************************/
/**** Dynaloader interface ****/
/******************************/

void * dynaloader_get_symbol(pTHX_ void * dll, char * name) {
	dSP;
	int count;
	
	ENTER;
	SAVETMPS;
	
	PUSHMARK(SP);
	XPUSHs(sv_2mortal(newSViv(PTR2IV(dll))));
	XPUSHs(sv_2mortal(newSVpv(name, 0)));
	PUTBACK;
	
	count = call_pv("DynaLoader::dl_find_symbol", G_SCALAR);
	SPAGAIN;
	if (count != 1) croak("C::Blocks expected one return value from dl_find_symbol but got %d\n", count);
	SV * returned = POPs;
	void * to_return = NULL;
	if (SvOK(returned)) to_return = INT2PTR(void*, SvIV(returned));
	
	PUTBACK;
	FREETMPS;
	LEAVE;
	
	return to_return;
}

void * dynaloader_get_lib(pTHX_ char * name) {
	dSP;
	int count;
	
	ENTER;
	SAVETMPS;
	
	PUSHMARK(SP);
	XPUSHs(sv_2mortal(newSVpv(name, 0)));
	PUTBACK;
	
	count = call_pv("DynaLoader::dl_load_file", G_SCALAR);

	SPAGAIN;
	if (count != 1) croak("C::Blocks expected one return value from dl_load_file but got %d\n", count);
	void * to_return = INT2PTR(void*, POPi);
	
	PUTBACK;
	FREETMPS;
	LEAVE;
	
	return to_return;
}

/***************************/
/**** Testing Functions ****/
/***************************/

char * _c_blocks_get_msg() {
	dTHX;
	SV * msg_SV = get_sv("C::Blocks::_msg", 0);
	return SvPVbyte_nolen(msg_SV);
}
void _c_blocks_send_msg(char * msg) {
	dTHX;
	SV * msg_SV = get_sv("C::Blocks::_msg", 0);
	sv_setpv(msg_SV, msg);
}
void _c_blocks_send_bytes(char * msg, int bytes) {
	dTHX;
	SV * msg_SV = get_sv("C::Blocks::_msg", 0);
	sv_setpvn(msg_SV, msg, bytes);
}

/*****************************************/
/**** Extended symbol table callbacks ****/
/*****************************************/

TokenSym_p my_symtab_lookup_by_name(char * name, int len, void * data, extended_symtab_p* containing_symtab) {
	/* Unpack the callback data */
	extended_symtab_callback_data * callback_data = (extended_symtab_callback_data*)data;
	
	/* In all likelihood, name will *NOT* be null terminated */
	char name_to_find[len + 1];
	strncpy(name_to_find, name, len);
	name_to_find[len] = '\0';
	
	/* Run through all of the available extended symbol tables and look for this
	 * identifier. */
	int i;
	for (i = callback_data->N_tables - 1; i >= 0; i--) {
		extended_symtab_p my_symtab
			= callback_data->available_extended_symtabs[i].exsymtab;
		TokenSym_p ts = tcc_get_extended_tokensym(my_symtab, name_to_find);
		if (ts != NULL) {
			*containing_symtab = my_symtab;
			return ts;
		}
	}
	
	return NULL;
}

void my_symtab_sym_used(char * name, int len, void * data) {
	/* Unpack the callback data */
	extended_symtab_callback_data * callback_data = (extended_symtab_callback_data*)data;
	
	/* Name *IS* null terminated */
	
	/* Run through all of the available extended symbol tables and look for this
	 * identifier. If found, add the symbol to the state. */
	int i;
	void * pointer = NULL;
	for (i = callback_data->N_tables - 1; i >= 0; i--) {
		available_extended_symtab lookup_data
			= callback_data->available_extended_symtabs[i];
		
		/* Scan the dlls first */
		void ** curr_dll = lookup_data.dlls;
		if (curr_dll != NULL) {
			while (*curr_dll != NULL) {
				pointer = dynaloader_get_symbol(
					C_BLOCKS_CALLBACK_MY_PERL(callback_data) *curr_dll, name);
				if (pointer) break;
				curr_dll++;
			}
		}
		
		/* If we didn't find it, check if it's in the exsymtab */
		if (pointer == NULL) {
			pointer = tcc_get_extended_symbol(lookup_data.exsymtab, name);
		}
		
		/* found it? Then we're done */
		if (pointer != NULL) {
			tcc_add_symbol(callback_data->state, name, pointer);
			return;
		}
	}
	
	/* Out here only means one thing: couldn't find it! */
	// working here: warn("Could not find symbol '%s' to mark as used");
}

void my_prep_table (void * data) {
	/* Unpack the callback data */
	extended_symtab_callback_data * callback_data = (extended_symtab_callback_data*)data;
	
	/* Run through all of the available extended symbol tables and call the
	 * TokenSym preparation function. Order is important here: go from last
	 * to first!!! */
	int i;
	for (i = callback_data->N_tables - 1; i >= 0; i--) {
		extended_symtab_p my_symtab
			= callback_data->available_extended_symtabs[i].exsymtab;
		tcc_prep_tokensym_list(my_symtab);
	}
}


/************************/
/**** Error handling ****/
/************************/

/* Error handling should store the message and return to the normal execution
 * order. In other words, croak is inappropriate here. */
void my_tcc_error_func (void * message_ptr, const char * msg ) {
	SV* message_sv = (SV*)message_ptr;
	/* ignore "defined twice" errors */
	if (strstr(msg, "defined twice") != NULL) return;
	/* set the message in the error_message key of the compiler context */
	if (SvPOK(message_sv)) {
		sv_catpvf(message_sv, "%s\n", msg);
	}
	else {
		sv_setpvf(message_sv, "%s\n", msg);
	}
}

/**************************/
/**** Lexical Warnings ****/
/**************************/
void my_warnif (pTHX_ const char * category, SV * message) {
	dSP;
	
	/* Prepare the stack */
	ENTER;
	SAVETMPS;
	
	/* Push the category and message onto the stack. The message must
	 * be a mortalized SV. */
	PUSHMARK(SP);
	XPUSHs(sv_2mortal(newSVpvf("C::Blocks::%s", category)));
	XPUSHs(message);
	PUTBACK;
	
	/* Call */
	/* XXX why can't I just call warnings::warnif??? */
	call_pv("C::Blocks::warnif", G_VOID);
	
	/* cleanup */
	FREETMPS;
	LEAVE;
}

/********************************/
/**** Keyword Identification ****/
/********************************/

enum { IS_CBLOCK = 1, IS_CSHARE, IS_CLEX, IS_CSUB } keyword_type_list;

/* Functions to quickly identify our keywords, assuming that the first letter has
 * already been checked and found to be 'c' */
int identify_keyword (char * keyword_ptr, STRLEN keyword_len) {
	if (keyword_ptr[0] != 'c') return 0;
	if (keyword_len == 4) {
		if (	keyword_ptr[1] == 's'
			&&	keyword_ptr[2] == 'u'
			&&	keyword_ptr[3] == 'b') return IS_CSUB;
		
		if (	keyword_ptr[1] == 'l'
			&&	keyword_ptr[2] == 'e'
			&&	keyword_ptr[3] == 'x') return IS_CLEX;
		
		return 0;
	}
	if (keyword_len == 6) {
		if (	keyword_ptr[1] == 'b'
			&&	keyword_ptr[2] == 'l'
			&&	keyword_ptr[3] == 'o'
			&&	keyword_ptr[4] == 'c'
			&&	keyword_ptr[5] == 'k') return IS_CBLOCK;
		
		if (	keyword_ptr[1] == 's'
			&&	keyword_ptr[2] == 'h'
			&&	keyword_ptr[3] == 'a'
			&&	keyword_ptr[4] == 'r'
			&&	keyword_ptr[5] == 'e') return IS_CSHARE;
		
		return 0;
	}
	return 0;
}

int _is_whitespace_char(char to_check) {
	if (' ' == to_check || '\n' == to_check || '\r' == to_check || '\t' == to_check) {
		return 1;
	}
	return 0;
}

int _is_id_cont (char to_check) {
	if('_' == to_check || ('0' <= to_check && to_check <= '9')
		|| ('A' <= to_check && to_check <= 'Z')
		|| ('a' <= to_check && to_check <= 'z')
		|| ':' == to_check) return 1;
	return 0;
}

/*************************************/
/**** Keyword plugin declarations ****/
/*************************************/

#ifdef PL_bufptr
	#undef PL_bufptr
	#undef PL_bufend
#endif

#define PL_bufptr (PL_parser->bufptr)
#define PL_bufend (PL_parser->bufend)

/* XXX contents should be added to code_main here, rather than copied
 * with LEX_KEEP_PREVIOUS. That's a relic of a previous approach. */
#define ENSURE_LEX_BUFFER(end, croak_message)                   \
	if (end == PL_bufend) {                                     \
		int length_so_far = end - PL_bufptr;                    \
		if (!lex_next_chunk(LEX_KEEP_PREVIOUS)) {               \
			/* We only reach this point if we reached the end   \
			 * of the file. Croak with the given message */     \
			croak(croak_message);                               \
		}                                                       \
		/* revise our end pointer for the new buffer, which     \
		 * may have moved when pulling the next chunk */        \
		end = PL_bufptr + length_so_far;                        \
	}

typedef struct c_blocks_data {
	char * end;
	char * xs_c_name;
	char * xs_perl_name;
	char * xsub_name;
	COPHH* hints_hash;
	SV * exsymtabs;
	SV * add_test_SV;
	SV * code_top;
	SV * code_main;
	SV * code_bottom;
	SV * error_msg_sv;
	int N_newlines;
	int keep_curly_brackets;
	int has_loaded_perlapi;
} c_blocks_data;

void ensure_perlapi(pTHX_ c_blocks_data * data);


/*********************************/
/**** C code parser/extractor ****/
/*********************************/

/* The behavior of the parser is contained in the following bit of
 * state. */
struct parse_state_t;
typedef struct parse_state_t parse_state;
typedef int (*parse_func_t)(pTHX_ parse_state *);
struct parse_state_t {
	parse_func_t default_next_char; /* what we usually do */
	parse_func_t process_next_char; /* what we're doing next */
	c_blocks_data * data;           /* reference to c_blocks build state */
	char * sigil_start;             /* location where sigil found */
	int bracket_count;              /* unmatched open curly brackets */
	int interpolation_bracket_count_start; /* number of open brackets
											* when interpolation block began */
	char delimiter;                 /* for delimited next_char parsing */
};

/* PARSE RESULTS: Return values for the character parse functions */
enum {
	PR_CLOSING_BRACKET, /* found the final closing bracket */
	PR_MAYBE_SIGIL,     /* found character which may be a sigil (@ or %) */
	PR_NON_SIGIL,       /* called does not need to worry about sigil
						 * handling: either not a sigil, or sigil_start
						 * was already set. */
	PR_EXCEPTION,       /* interpolation block threw an exception */
};

int process_next_char_no_vars (pTHX_ parse_state * pstate);
int process_next_char_sigil_blocks_ok (pTHX_ parse_state * pstate);
int process_next_char_sigil_vars_ok (pTHX_ parse_state * pstate);
int process_next_char_delimited (pTHX_ parse_state * pstate);
int process_next_char_C_comment (pTHX_ parse_state * pstate);
int process_next_char_post_sigil (pTHX_ parse_state * pstate);
int process_next_char_sigiled_var (pTHX_ parse_state * pstate);
int process_next_char_sigiled_block (pTHX_ parse_state * pstate);
int process_next_char_colon(pTHX_ parse_state * pstate);
int execute_Perl_interpolation_block(pTHX_ parse_state * pstate);
int call_init_cleanup_builder_method(pTHX_ parse_state * pstate,
	char * type, char * long_name, int var_offset);

/* Base parser, and default text parser for clex and cshare. This parser
 * does not handle variables, but it does track where $-sigils are found
 * because interpolation blocks can be used anywhere. This is written
 * such that the variable-handling parsers call this function first, and
 * perform follow-ups if they get PR_MAYBE_SIGIL. Reinstates normal
 * parsing after interpolation blocks have been identified. */
int process_next_char_no_vars (pTHX_ parse_state * pstate) {
	switch (pstate->data->end[0]) {
		case '{':
			pstate->bracket_count++;
			if (pstate->bracket_count == 1) {
				/* Remove first bracket from the buffer */
				lex_unstuff(pstate->data->end + 1);
				pstate->data->end = PL_bufptr - 1;
			}
			return PR_NON_SIGIL;
		case '}':
			pstate->bracket_count--;
			if (pstate->bracket_count == 0) return PR_CLOSING_BRACKET;
			if (pstate->interpolation_bracket_count_start == pstate->bracket_count)
				return execute_Perl_interpolation_block(aTHX_ pstate);
			return PR_NON_SIGIL;
		case '\'': case '\"':
			/* Setup "delimited" extraction state, matching on the
			 * quotation character we just saw. */
			pstate->process_next_char = process_next_char_delimited;
			pstate->delimiter = pstate->data->end[0];
			return PR_NON_SIGIL;
		case '/':
			if (pstate->data->end > PL_bufptr && pstate->data->end[-1] == '/') {
				/* Handling C++ style comments is easy. They run until
				 * the newline, so set up a parse state that is
				 * delimited by a newline :-) */
				pstate->process_next_char = process_next_char_delimited;
				pstate->delimiter = '\n';
			}
			return PR_NON_SIGIL;
		case '*':
			if (pstate->data->end > PL_bufptr && pstate->data->end[-1] == '/') {
				/* C-style comments have their own parser */
				pstate->process_next_char = process_next_char_C_comment;
			}
			return PR_NON_SIGIL;
		case ':':
			/* No processing if we're extracting an interpolation block */
			if (pstate->interpolation_bracket_count_start) return PR_NON_SIGIL;
			/* This is a colon following something other than a colon,
			   and outside an interpolation block. Set up the parser to
			   detect and act on a potential second colon. */
			pstate->process_next_char = process_next_char_colon;
			return PR_NON_SIGIL;
		case '$':
			/* No processing if we're extracting an interpolation block */
			if (pstate->interpolation_bracket_count_start) return PR_NON_SIGIL;
			/* Otherwise setup post-sigil handling. Clear out the
			 * lexical buffer up to but not including this character
			 * and set up the parser. */
			sv_catpvn(pstate->data->code_main, PL_bufptr,
				pstate->data->end - PL_bufptr);
			lex_unstuff(pstate->data->end);
			pstate->data->end = PL_bufptr;
			pstate->process_next_char = process_next_char_post_sigil;
			pstate->sigil_start = pstate->data->end;
			return PR_NON_SIGIL;
			
	}
	/* Out here means it's not one of the special characters considered
	 * above, though it may be an array or hash sigil. */
	return PR_MAYBE_SIGIL;
}

char * replace_double_colons_with_double_underscores(pTHX_ SV * to_replace) {
	/* Replace any double-colons with double-underscores */
	int is_in_string;
	STRLEN i, len;
	char * to_return;
	
	to_return = SvPV(to_replace, len);
	is_in_string = to_return[0] == '"';
	for (i = 1; i < len; i++) {
		if (is_in_string) {
			if (to_return[i] == '"' && to_return[i-1] != '\\') {
				is_in_string = 0;
			}
		}
		else {
			if (to_return[i-1] == ':' && to_return[i] == ':') {
				to_return[i-1] = to_return[i] = '_';
			}
		}
	}
	return to_return;
}

int execute_Perl_interpolation_block(pTHX_ parse_state * pstate) {
	/* Temporarily replace the closing bracket with null so we can
	 * eval_pv the buffer without copying. */
	*pstate->data->end = '\0';
	/* XXX working here - should catch eval and return special value.
	 * For now, croak on error (and leak). */
	SV * returned_sv = eval_pv(pstate->sigil_start + 2, 1);
	
	char * fixed_returned
		= replace_double_colons_with_double_underscores(aTHX_ returned_sv);
	
	/* Replace the interpolation block with contents of eval. Be sure
	 * to get rid of the entire block up to the closing bracket, which
	 * is now the null character added above. */
	sv_catpv_nomg(pstate->data->code_main, fixed_returned);
	lex_unstuff(pstate->data->end + 1);
	pstate->data->end = PL_bufptr;
//	SvREFCNT_dec(returned_sv); // XXX is this correct?
	
	/* XXX working here - add #line to make sure tcc correctly indicates
	 * the line number of material that follows. There is no guarantee
	 * that the evaluated text has the same number of lines as the
	 * original block of Perl code just evaluated. */
	
	/* Return to default parse state */
	pstate->sigil_start = 0;
	pstate->process_next_char = pstate->default_next_char;
	pstate->interpolation_bracket_count_start = 0;
	
	/* There shall not be any need for sigil handling by any calling
	 * parsers. */
	return PR_NON_SIGIL;
}

/* Default text parser for cblock */
int process_next_char_sigil_vars_ok (pTHX_ parse_state * pstate) {
	int no_vars_result = process_next_char_no_vars(aTHX_ pstate);
	if (no_vars_result != PR_MAYBE_SIGIL) return no_vars_result;
	if (*pstate->data->end == '@' || *pstate->data->end == '%') {
		/* Clear out the lexical buffer up to but not including this
		 * character. */
		sv_catpvn(pstate->data->code_main, PL_bufptr,
			pstate->data->end - PL_bufptr);
		lex_unstuff(pstate->data->end);
		pstate->data->end = PL_bufptr;
		
		/* Set up the variable name extractor */
		pstate->process_next_char = process_next_char_post_sigil;
		pstate->sigil_start = pstate->data->end;
	}
	return PR_NON_SIGIL;
}

int process_next_char_delimited (pTHX_ parse_state * pstate) {
	if (pstate->data->end[0] == pstate->delimiter && pstate->data->end[-1] != '\\') {
		/* Reset to normal parse state */
		pstate->process_next_char = pstate->default_next_char;
	}
	else if (pstate->delimiter != '\n' && pstate->data->end[0] == '\n') {
		/* Strings do not wrap */
		pstate->process_next_char = pstate->default_next_char;
	}
	return PR_NON_SIGIL;
}

int process_next_char_C_comment (pTHX_ parse_state * pstate) {
	if (pstate->data->end[0] == '/' && pstate->data->end[-1] == '*') {
		/* Found comment closer. Reset to normal parse state */
		pstate->process_next_char = pstate->default_next_char;
	}
	return PR_NON_SIGIL;
}

int process_next_char_colon(pTHX_ parse_state * pstate) {
	/* No matter what, reset to the default parser. */
	pstate->process_next_char = pstate->default_next_char;
	if (pstate->data->end[0] == ':') {
		/* we just encountered a double-colon. Replace it with a
		   double-underscore. */
		pstate->data->end[0] = pstate->data->end[-1] = '_';
		/* Indicate we've handled this character */
		return PR_NON_SIGIL;
	}
	/* revert to the default parser to handle this character since it is
	   not a colon. */
	return pstate->default_next_char(aTHX_ pstate);
}

int process_next_char_post_sigil(pTHX_ parse_state * pstate) {
	/* Only called on the first character after the sigil. */
	
	/* If the sigil is a dollar sign and the next character is an
	 * opening bracket, then we have an interpolation block. */
	if (pstate->data->end[-1] == '$' && pstate->data->end[0] == '{') {
		pstate->process_next_char = process_next_char_no_vars;
		pstate->interpolation_bracket_count_start = pstate->bracket_count++;
		return PR_NON_SIGIL;
	}
	
	/* IF our default parser accepts sigiled variables, then check for a
	 * valid identifier character and set up continued searching for the
	 * end of the variable name. */
	if (pstate->default_next_char == process_next_char_sigil_vars_ok
		&& _is_id_cont(pstate->data->end[0]))
	{
		pstate->process_next_char = process_next_char_sigiled_var;
		return PR_NON_SIGIL;
	}
	
	/* We either have a lone sigil character followed by a space or a
	 * sigiled variable name being parsed when sigiled variable names
	 * are not allowed. Reset the state and defer to the default
	 * handler. */
	pstate->process_next_char = pstate->default_next_char;
	return pstate->default_next_char(aTHX_ pstate);
}

int direct_replace_double_colons(char * to_check) {
	if (to_check[0] == 0) return 0;
	int found = 0;
	for (to_check++; *to_check != 0; to_check++) {
		if (to_check[-1] == ':' && to_check[0] == ':') {
			to_check[-1] = to_check[0] = '_';
			found = 1;
		}
	}
	return found;
}

int process_next_char_sigiled_var(pTHX_ parse_state * pstate) {
	/* keep collecting if the current character looks like a valid
	 * identifier character */
	if (_is_id_cont(pstate->data->end[0])) return PR_NON_SIGIL;
	
	/* make sure we have the PerlAPI loaded */
	ensure_perlapi(aTHX_ pstate->data);
	
	/* We just identified the character that is one past the end of our
	 * Perl variable name. Identify the type and construct the mangled
	 * name for the C-side variable. */
	char backup = *pstate->data->end;
	*pstate->data->end = '\0';
	char * type;
	char * long_name;
	if (*pstate->sigil_start == '$') {
		type = "SV";
		long_name = savepv(form("_PERL_SCALAR_%s", 
			pstate->sigil_start + 1));
	}
	else if (*pstate->sigil_start == '@') {
		type = "AV";
		long_name = savepv(form("_PERL_ARRAY_%s", 
			pstate->sigil_start + 1));
	}
	else if (*pstate->sigil_start == '%') {
		type = "HV";
		long_name = savepv(form("_PERL_HASH_%s", 
			pstate->sigil_start + 1));
	}
	else {
		/* should never happen */
		*pstate->data->end = backup;
		croak("C::Blocks internal error: unknown sigil %c\n",
			*pstate->sigil_start);
	}
	
	/* replace any double-colons */
	int is_package_global = direct_replace_double_colons(long_name);
	
	/* Check if we need to add a declaration for the C-side variable */
	if (strstr(SvPVbyte_nolen(pstate->data->code_top), long_name) == NULL) {
		/* Add a new declaration for it */
		
		/* NOTE: pad_findmy_pv expects the sigil, but get_sv/get_av/get_hv
		   do not!! */
		
		if (is_package_global) {
			sv_catpvf(pstate->data->code_top, "%s * %s = (%s(\"%s\", GV_ADD)); ",
				type, long_name,
				  *pstate->sigil_start == '$' ? "get_sv"
				: *pstate->sigil_start == '@' ? "get_av"
				:                               "get_hv",
				pstate->sigil_start + 1);
		}
		else {
			int var_offset = (int)pad_findmy_pv(pstate->sigil_start, 0);
			/* Ensure that the variable exists in the pad */
			if (var_offset == NOT_IN_PAD) {
				CopLINE(PL_curcop) += pstate->data->N_newlines;
				*pstate->data->end = backup;
				croak("Could not find lexically scoped \"%s\"",
					pstate->sigil_start);
			}
			
			/* If the variable has an annotated type, use the type's
			 * code builder. Otherwise, declare the basic type. */
			if (!call_init_cleanup_builder_method(aTHX_ pstate, type,
					long_name, var_offset))
			{
				sv_catpvf(pstate->data->code_top, "%s * %s = (%s*)PAD_SV(%d); ",
					type, long_name, type, var_offset);
			}
		}
	}
	
	/* Reset the character just following the var name */
	*pstate->data->end = backup;
	
	/* Add the long name to the main code block in place of the sigiled
	 * expression, and remove the sigiled varname from the buffer. */
	sv_catpv_nomg(pstate->data->code_main, long_name);
	lex_unstuff(pstate->data->end);
	pstate->data->end = PL_bufptr;
	
	/* Cleanup memory */
	Safefree(long_name);
	
	/* Reset the parser state and process the current character with
	 * the default parser */
	pstate->process_next_char = pstate->default_next_char;
	return pstate->default_next_char(aTHX_ pstate);
}

/* Support for type-annotated variables. Save the SV in an even
 * more obfuscated variable, and the given type in the expected
 * variable. */
int call_init_cleanup_builder_method(pTHX_ parse_state * pstate,
	char * type, char * long_name, int var_offset)
{
	/* does this variable have a type? */
	HV * stash = PAD_COMPNAME_TYPE(var_offset);
	if (stash == 0) return 0;
	
	/* get the method; warn and exit if we can't find it */
	GV * declaration_gv;
	CV * declaration_cv;
	declaration_gv = gv_fetchmeth_autoload(stash, "c_blocks_init_cleanup", 21, 0);
	if (declaration_gv != 0) declaration_cv = GvCV(declaration_gv);
	if (declaration_gv == 0 || declaration_cv == 0) {
		my_warnif (aTHX_ "type", sv_2mortal(newSVpvf("C::Blocks could "
			"not find method 'c_blocks_init_cleanup' for %s's type, %s",
			pstate->sigil_start, HvENAME(stash))));
		return 0;
	}
	
	/* prepare the call stack for the init_cleanup method */
	dSP;
	int count;
	ENTER;
	SAVETMPS;
	PUSHMARK(SP);
	XPUSHs(sv_2mortal(newSVpv(HvENAME(stash), 0))); // class name
	XPUSHs(sv_2mortal(newSVpv(long_name, 0))); // long C name
	XPUSHs(sv_2mortal(newSVpv(type, 0)));      // var type: SV, AV, HV
	XPUSHs(sv_2mortal(newSViv(var_offset)));   // pad offset
	PUTBACK;
	
	/* call the init_cleanup method */
	count = call_sv((SV*)declaration_cv, G_ARRAY); /* G_EVAL | G_KEEPERR ??? */
	SPAGAIN;
	
	/* make sure we got the init and cleanup code */
	while (count > 2) {
		POPs;
		count--;
	}
	if (count == 2) {
		sv_catpv_nomg(pstate->data->code_bottom, 
			replace_double_colons_with_double_underscores(aTHX_ POPs));
		count--;
	}
	if (count == 1) {
		sv_catpv_nomg(pstate->data->code_top, 
			replace_double_colons_with_double_underscores(aTHX_ POPs));
	}
	
	/* final stack cleanup */
	PUTBACK;
	FREETMPS;
	LEAVE;
	
	/* warn and return failure if we didn't get any return values */
	if (count == 0) {
		my_warnif (aTHX_ "type", sv_2mortal(newSVpvf("C::Blocks expected "
			"one or two return values from %s::c_blocks_init_cleanup' "
			"but got none", HvENAME(stash))));
		return 0;
	}

	// success!
	return 1;
}

void extract_C_code(pTHX_ c_blocks_data * data, int keyword_type) {
	/* copy data out of the buffer until we encounter the matching
	 * closing bracket, accounting for brackets that may occur in
	 * comments and strings. Process sigiled variables as well. */
	
	/* Set up the parser state */
	parse_state my_parse_state;
	my_parse_state.data = data;
	my_parse_state.sigil_start = 0;
	my_parse_state.bracket_count = 0;
	my_parse_state.interpolation_bracket_count_start = 0;
	if (keyword_type == IS_CBLOCK) {
		my_parse_state.process_next_char = process_next_char_sigil_vars_ok;
		my_parse_state.default_next_char = process_next_char_sigil_vars_ok;
	}
	else {
		my_parse_state.process_next_char = process_next_char_no_vars;
		my_parse_state.default_next_char = process_next_char_no_vars;
	}
	
	
	data->end = PL_bufptr;
	int still_working;
	do {
		ENSURE_LEX_BUFFER(data->end, "C::Blocks expected closing curly brace but did not find it");
		
		if (*data->end == '\n') data->N_newlines++;
		still_working = my_parse_state.process_next_char(aTHX_ &my_parse_state);
		if (still_working == PR_EXCEPTION) {
			/* XXX working here - if an exception in Perl block, must clean up! */
		}
		data->end++;
	} while (still_working);
	
	/* Finish by moving the (remaining) contents of the lexical buffer
	 * into the main code container. Don't copy the final bracket, so
	 * that bottom's code can be appended later. */
	sv_catpvn(data->code_main, PL_bufptr, data->end - PL_bufptr - 1);
	/* end points to the first character after the closing bracket, so
	 * don't copy (or unstuff) that. */
	lex_unstuff(data->end);
	data->end = PL_bufptr;
	/* Add the closing bracket to the end, if appropriate */
	if (data->keep_curly_brackets) sv_catpvn(data->code_bottom, "}", 1);
}

void run_filters (pTHX_ c_blocks_data * data, int keyword_type) {
	/* Get $_ and place the code in it */
	SV * underbar = find_rundefsv();
	SV * under_backup = newSVsv(underbar);
	sv_setpvf(underbar, "%s%s%s", SvPVbyte_nolen(data->code_top),
		SvPVbyte_nolen(data->code_main), SvPVbyte_nolen(data->code_bottom));
	
	/* Apply the different filters */
	SV * filters_SV = cophh_fetch_pvs(data->hints_hash, "C::Blocks/filters", 0);
	if (filters_SV != &PL_sv_placeholder) {
		dSP;
		char * filters = SvPVbyte_nolen(filters_SV);
		char * start = filters;
		char backup;
		while(1) {
			if (*filters == '\0' && start == filters) break;
			if (*filters == '|') {
				backup = *filters;
				*filters = '\0';
				/* construct the function name to call */
				char * full_method;
				/* if it starts with an ampersand, it's a function name */
				if (*start == '&') {
					full_method = start + 1;
				}
				else {
					/* we have the package name; append the normal method */
					full_method = form("%s::c_blocks_filter", start);
				}
				PUSHMARK(SP);
				call_pv(full_method, G_DISCARD|G_NOARGS);
				start = filters + 1;
				*filters = backup;
			}
			filters++;
		}
	}
	
	/* copy contents of underbar into main */
	sv_setsv(data->code_main, underbar);
	
	/* restore underbar when done */
	sv_setsv(underbar, under_backup);
}

/*************************/
/**** Keyword plugin ****/
/************************/

void initialize_c_blocks_data(pTHX_ c_blocks_data* data) {
	data->N_newlines = 0;
	data->xs_c_name = 0;
	data->xs_perl_name = 0;
	data->xsub_name = 0;
	data->add_test_SV = 0;
	data->keep_curly_brackets = 1;
	
	/* The user may have loaded perlapi explicitly. However, we won't
	 * check unless we find a need to check. Start by assuming it's not
	 * loaded. */
	data->has_loaded_perlapi = 0;
	
	data->hints_hash = CopHINTHASH_get(PL_curcop);
	data->add_test_SV = get_sv("C::Blocks::_add_msg_functions", 0);
	data->code_top = newSVpvn("", 0);
	data->code_main = newSVpvn("", 0);
	data->code_bottom = newSVpvn("", 0);
	data->error_msg_sv = newSV(0);
	
	/* This is called after we have cleared out whitespace, so just assign */
	data->end = PL_bufptr;
	
	/* Get the current exsymtabs list. If this doesn't exist, we'll have */
	data->exsymtabs = cophh_fetch_pvs(data->hints_hash, "C::Blocks/extended_symtab_tables", 0);
}

void add_function_signature_to_block(pTHX_ c_blocks_data* data) {
	/* Add the function declaration. The definition of the THX_DECL
	 * macro will be defined later. */
	sv_catpv_nomg(data->code_top, "void op_func(C_BLOCKS_THX_DECL) {");
}

void cleanup_c_blocks_data(pTHX_ c_blocks_data* data) {
	SvREFCNT_dec(data->error_msg_sv);
	SvREFCNT_dec(data->code_top);
	SvREFCNT_dec(data->code_main);
	SvREFCNT_dec(data->code_bottom);
	/* Bottom and top, if they were even used, should have been
	 * de-allocated already. */
	//if (SvPOK(data->exsymtabs)) SvREFCNT_dec(data->exsymtabs);
	Safefree(data->xs_c_name);
	Safefree(data->xs_perl_name);
	Safefree(data->xsub_name);
}

void ensure_perlapi(pTHX_ c_blocks_data * data) {
	if (data->has_loaded_perlapi) return;
	
	/* XXX This will add a second perlapi symtab entry to the symtab
	 * list if the user already explicitly loaded PerlAPI. So this could
	 * be streamlined with a check for existenct of PerlAPI in current
	 * symtab list. */
	
	/* Load libperl and append to *just* *this* exsymtab list */
	SV * perlapi_module_name = newSVpvn("C::Blocks::PerlAPI", 18);
	load_module(PERL_LOADMOD_NOIMPORT, perlapi_module_name, NULL);
/* XXX Unnecessary? SvREFCNT is zero, according to tests... */
//	SvREFCNT_dec(perlapi_module_name);
	
	/* Make sure the PerlAPI symtab is available */
	SV * old_symtabs = data->exsymtabs;
	SV * perlapi_symtab = get_sv("C::Blocks::PerlAPI::__cblocks_extended_symtab_list",
			GV_ADDMULTI);
	data->exsymtabs = newSVsv(perlapi_symtab);
	/* If we had other symtabs, put them after the PerlAPI one. The
	 * symtabs are searched in reverse order, so this will ensure that
	 * the PerlAPI symtab is checked last. That prevents the PerlAPI
	 * symtab from potentially masking declarations. */
	if (SvPOK(old_symtabs)) sv_catsv(data->exsymtabs, old_symtabs);
	
	data->has_loaded_perlapi = 1;
}

void find_end_of_xsub_name(pTHX_ c_blocks_data * data) {
	data->end = PL_bufptr;
	ensure_perlapi(aTHX_ data);
	
	/* extract the function name */
	while (1) {
		ENSURE_LEX_BUFFER(data->end,
			data->end == PL_bufptr
			? "C::Blocks encountered the end of the file before seeing the csub name"
			: "C::Blocks encountered the end of the file before seeing the body of the csub"
		);
		if (data->end == PL_bufptr) {
			if(!isIDFIRST(*data->end)) croak("C::Blocks expects a name after csub");
		}
		else if (_is_whitespace_char(*data->end) || *data->end == '{') {
			break;
		}
		else if (!_is_id_cont(*data->end)){
			croak("C::Blocks csub name can contain only underscores, letters, and numbers");
		}
		
		data->end++;
	}
}

void fixup_xsub_name(pTHX_ c_blocks_data * data) {
	/* Find where the name ends, copy it, and replace it with the correct
	 * declaration */
	
	/* Find the name */
	find_end_of_xsub_name(aTHX_ data);
	data->xsub_name = savepvn(PL_bufptr, data->end - PL_bufptr);
	
	/* create the package name */
	char * name_buffer = form("%s::%s", SvPVbyte_nolen(PL_curstname),
		data->xsub_name);
	data->xs_perl_name = savepv(name_buffer);
	int perl_name_length = strlen(name_buffer);
	
	/* create the related, munged c function name. */
	Newx(data->xs_c_name, perl_name_length + 4, char);
	data->xs_c_name[0] = 'x';
	data->xs_c_name[1] = 's';
	data->xs_c_name[2] = '_';
	int i;
	for (i = 0; i <= perl_name_length; i++) {
		if (data->xs_perl_name[i] == ':')
			data->xs_c_name[i+3] = '_';
		else
			data->xs_c_name[i+3] = data->xs_perl_name[i];
	}
	
	/* copy also into the main code container */
	sv_catpvf(data->code_main, "XSPROTO(%s) {", data->xs_c_name);
	
	/* remove the name from the buffer */
	lex_unstuff(data->end);
}

/* Add testing functions if requested. This must be called before
 * add_function_signature_to_block is called. */
void add_msg_function_decl(pTHX_ c_blocks_data * data) {
	if (SvOK(data->add_test_SV)) {
		sv_catpv(data->code_top, "void c_blocks_send_msg(char * msg);"
			"void c_blocks_send_bytes(void * msg, int bytes);"
			"char * c_blocks_get_msg();"
		);
	}
}

/* inject C::Blocks::libloader's import method into the current package */
void inject_import(pTHX) {
	char * warn_message = "no warning (yet)";
	SV * name = NULL;
	/* Get CV for C::Blocks::libloader::import */
	CV * import_method_to_inject
		= get_cvn_flags("C::Blocks::libloader::import", 28, 0);
	if (!import_method_to_inject) {
		warn_message = "could not load C::Blocks::libloader::import";
		goto fail;
	}
	
	/* Get the symbol (hash) table entry */
	name = newSVpv("import", 6);
	HE * entry = hv_fetch_ent(PL_curstash, name, 1, 0);
	if (!entry) {
		warn_message = "unable to load symbol table entry for 'import'";
		goto fail;
	}
	
	/* Get the glob for the symbol table entry. Make sure it isn't
	 * already initialized. */
	GV * glob = (GV*)HeVAL(entry);
	if (isGV(glob)) {
		my_warnif(aTHX_ "import", sv_2mortal(newSVpvf("Could not inject 'import' "
			"into package %s: 'import' method already found",
			SvPVbyte_nolen(PL_curstname))));
		SvREFCNT_dec(name);
		return;
	}
	
	/* initialize the glob */
	SvREFCNT_inc(glob);
	gv_init(glob, PL_curstash, "import", 6, 1);
	if (HeVAL(entry)) {
		SvREFCNT_dec(HeVAL(entry));
	}
	HeVAL(entry) = (SV*)glob;
	
	/* Add the method to the symbol table entry. See Package::Stash::XS
	 * GvSetCV preprocessor macro (specifically taken from v0.28) */
	SvREFCNT_dec(GvCV(glob));
	GvCV_set(glob, import_method_to_inject);
	GvIMPORTED_CV_on(glob);
	GvASSUMECV_on(glob);
	GvCVGEN(glob) = 0;
	mro_method_changed_in(GvSTASH(glob));

	SvREFCNT_dec(name);
	return;

fail:
	if (name != NULL) SvREFCNT_dec(name);
	warn("Internal error while injecting 'import' into package %s: %s",
		SvPVbyte_nolen(PL_curstname), warn_message);
}

void setup_compiler (pTHX_ TCCState * state, c_blocks_data * data) {
	/* Get and reset the compiler options */
	SV * compiler_options = get_sv("C::Blocks::compiler_options", 0);
	if (SvPOK(compiler_options)) tcc_set_options(state, SvPVbyte_nolen(compiler_options));
	SvSetMagicSV(compiler_options, get_sv("C::Blocks::default_compiler_options", 0));
	
	/* Ensure output goes to memory */
	tcc_set_output_type(state, TCC_OUTPUT_MEMORY);
	
	/* Set the error function to write to the error message SV */
	tcc_set_error_func(state, data->error_msg_sv, my_tcc_error_func);
}

void execute_compiler (pTHX_ TCCState * state, c_blocks_data * data, int keyword_type) {
	int len = (int)(data->end - PL_bufptr);
	
	/* Set the extended callback handling */
	extended_symtab_callback_data callback_data = { state, aTHX_ NULL, 0 };
	
	/* Set the extended symbol table lists if they exist */
	if (SvPOK(data->exsymtabs) && SvCUR(data->exsymtabs)) {
		callback_data.N_tables = SvCUR(data->exsymtabs) / sizeof(available_extended_symtab);
		callback_data.available_extended_symtabs = (available_extended_symtab*) SvPV_nolen(data->exsymtabs);
	}
	tcc_set_extended_symtab_callbacks(state, &my_symtab_lookup_by_name,
		&my_symtab_sym_used, &my_prep_table, &callback_data);
	
	/* set the block function's argument, if any */
	if (keyword_type == IS_CBLOCK) {
		/* If this is a block, we need to define C_BLOCKS_THX_DECL.
		 * This will be based on whether tTHX is available or not. */
		#ifdef PERL_IMPLICIT_CONTEXT
			void * return_value_ignored;
			if (my_symtab_lookup_by_name("aTHX", 4, &callback_data, (void*) &return_value_ignored))
				tcc_define_symbol(state, "C_BLOCKS_THX_DECL", "PerlInterpreter * my_perl");
			else
				tcc_define_symbol(state, "C_BLOCKS_THX_DECL", "void * my_perl_NOT_USED");
		#else
			tcc_define_symbol(state, "C_BLOCKS_THX_DECL", "");
		#endif
	}
	
	/* compile the code, which is (by this time) stored entirely in main */
	STRLEN main_len;
	char * to_compile = SvPVbyte(data->code_main, main_len);
	tcc_compile_string_ex(state, to_compile, main_len,
		CopFILE(PL_curcop), CopLINE(PL_curcop));
	
	/* Handle any compilation errors */
	if (SvPOK(data->error_msg_sv)) {
		/* rewrite implicit function declarations as errors */
		char * loc;
		while(loc = strstr(SvPV_nolen(data->error_msg_sv),
			"warning: implicit declaration of function")
		) {
			/* replace "warning: implicit declaration of" with an error */
			sv_insert(data->error_msg_sv, loc - SvPV_nolen(data->error_msg_sv),
				32, "error: undeclared", 17);
		}
		/* Look for errors and croak */
		if (strstr(SvPV_nolen(data->error_msg_sv), "error")) {
			croak("C::Blocks compiler error:\n%s", SvPV_nolen(data->error_msg_sv));
		}
		
		/* Otherwise, report and clear the compiler warnings */
		my_warnif(aTHX_ "compiler", sv_2mortal(newSVsv(data->error_msg_sv)));
		SvPOK_off(data->error_msg_sv);
	}
}

OP * build_op(pTHX_ TCCState * state, int keyword_type) {
	/* build a null op if not creating a cblock */
	if (keyword_type != IS_CBLOCK) return newOP(OP_NULL, 0);
	
	/* get the function pointer for the block */
	IV pointer_IV = PTR2IV(tcc_get_symbol(state, "op_func"));
	if (pointer_IV == 0) {
		croak("C::Blocks internal error: got null pointer for op function!");
	}
	
	/* Store the address of the function pointer on the stack */
	OP * o = newUNOP(OP_RAND, 0, newSVOP(OP_CONST, 0, newSViv(pointer_IV)));
	
	/* Create an op that pops the address off the stack and invokes it */
	o->op_ppaddr = Perl_tcc_pp;
	
	return o;
}

void extract_xsub (pTHX_ TCCState * state, c_blocks_data * data) {
	/* Extract the xsub */
	XSUBADDR_t xsub_fcn_ptr = tcc_get_symbol(state, data->xs_c_name);
	if (xsub_fcn_ptr == NULL)
		croak("C::Blocks internal error: Unable to get pointer to csub %s\n", data->xsub_name);
	
	/* Add the xsub to the package's symbol table */
	char * filename = CopFILE(PL_curcop);
	newXS(data->xs_perl_name, xsub_fcn_ptr, filename);
}

void serialize_symbol_table(pTHX_ TCCState * state, c_blocks_data * data, int keyword_type) {
	/* Build an extended symbol table to serialize */
	available_extended_symtab new_table;
	new_table.exsymtab = tcc_get_extended_symbol_table(state);
	
	/* Store the pointers to the extended symtabs so that we can clean up
	 * when everything is over. */
	AV * extended_symtab_cache = get_av("C::Blocks::__symtab_cache_array", GV_ADDMULTI | GV_ADD);
	av_push(extended_symtab_cache, newSViv(PTR2IV(new_table.exsymtab)));

	/* Get the dll pointers if this is to be linked against dlls */
	AV * libs_to_link = get_av("C::Blocks::libraries_to_link", 0);
	new_table.dlls = NULL;
	if (libs_to_link != NULL && av_len(libs_to_link) >= 0) {
		int N_libs = av_len(libs_to_link) + 1;
		int i = 0;
		new_table.dlls = Newx(new_table.dlls, N_libs + 1, void*);
		while(av_len(libs_to_link) >= 0) {
			SV * lib_to_link = av_shift(libs_to_link);
			new_table.dlls[i] = dynaloader_get_lib(aTHX_ SvPVbyte_nolen(lib_to_link));
			if (new_table.dlls[i] == NULL) {
				croak("C::Blocks/DynaLoader unable to load library [%s]",
					SvPVbyte_nolen(lib_to_link));
			}
			SvSetMagicSV_nosteal(lib_to_link, &PL_sv_undef);
			i++;
		}
		new_table.dlls[i] = NULL;
		
		/* Store a copy so we can later clean up memory */
		AV * dll_list = get_av("C::Blocks::__dll_list_array", GV_ADDMULTI | GV_ADD);
		av_push(dll_list, newSViv(PTR2IV(new_table.dlls)));
	}
	
	/* add the serialized pointer address to the hints hash entry */
	if (SvPOK(data->exsymtabs)) {
		data->exsymtabs = newSVsv(data->exsymtabs);
		sv_catpvn(data->exsymtabs, (char*)&new_table, sizeof(available_extended_symtab));
	}
	else {
		data->exsymtabs = newSVpvn((char*)&new_table, sizeof(available_extended_symtab));
	}
	data->hints_hash = cophh_store_pvs(data->hints_hash, "C::Blocks/extended_symtab_tables", data->exsymtabs, 0);
	CopHINTHASH_set(PL_curcop, data->hints_hash);
	
	/* add the serialized pointer address to the package symtab list */
	if (keyword_type == IS_CSHARE) {
		SV * package_lists = get_sv(form("%s::__cblocks_extended_symtab_list",
			SvPVbyte_nolen(PL_curstname)), GV_ADDMULTI | GV_ADD);
		if (SvPOK(package_lists)) {
			sv_catpvn_mg(package_lists, (char*)&new_table, sizeof(available_extended_symtab));
		}
		else {
			sv_setpvn_mg(package_lists, (char*)&new_table, sizeof(available_extended_symtab));
		}
		
		/* inject the import method */
		SV * has_import = get_sv(form("%s::__cblocks_injected_import",
			SvPVbyte_nolen(PL_curstname)), GV_ADDMULTI | GV_ADD);
		if (!SvOK(has_import)) {
			inject_import(aTHX);
			sv_setuv(has_import, 1);
		}
	}
}

int my_keyword_plugin(pTHX_
	char *keyword_ptr, STRLEN keyword_len, OP **op_ptr
) {
	/* See if this is a keyword we know */
	int keyword_type = identify_keyword(keyword_ptr, keyword_len);
	if (!keyword_type)
		return next_keyword_plugin(aTHX_ keyword_ptr, keyword_len, op_ptr);
	
	/**********************/
	/*   Initialization   */
	/**********************/
	
	/* Clear out any leading whitespace, including comments. Do this before
	 * initialization so that the assignment of the end pointer is correct. */
	lex_read_space(0);
	
	/* Create the compilation data struct */
	c_blocks_data data;
	initialize_c_blocks_data(aTHX_ &data);
	
	add_msg_function_decl(aTHX_ &data);
	if (keyword_type == IS_CBLOCK) add_function_signature_to_block(aTHX_ &data);
	else if (keyword_type == IS_CSUB) fixup_xsub_name(aTHX_ &data);
	else if (keyword_type == IS_CSHARE || keyword_type == IS_CLEX) {
		data.keep_curly_brackets = 0;
	}
	
	/************************/
	/* Extract and compile! */
	/************************/
	
	extract_C_code(aTHX_ &data, keyword_type);
	run_filters(aTHX_ &data, keyword_type);
	
	TCCState * state = tcc_new();
	if (!state) croak("Unable to create C::TinyCompiler state!\n");
	setup_compiler(aTHX_ state, &data);
	
	/* Ask to save state if it's a cshare or clex block*/
	if (keyword_type == IS_CSHARE || keyword_type == IS_CLEX) {
		tcc_save_extended_symtab(state);
	}
	
	/* Compile the extracted code */
	execute_compiler(aTHX_ state, &data, keyword_type);
	
	/******************************************/
	/* Apply the list of symbols and relocate */
	/******************************************/
	
	/* test symbols */
	if (SvOK(data.add_test_SV)) {
		tcc_add_symbol(state, "c_blocks_send_msg", _c_blocks_send_msg);
		tcc_add_symbol(state, "c_blocks_send_bytes", _c_blocks_send_bytes);
		tcc_add_symbol(state, "c_blocks_get_msg", _c_blocks_get_msg);
	}
	
	/* prepare for relocation; store in a global so that we can free everything
	 * at the end of the Perl program's execution. Allocate up to on page size
	 * more memory than we need so that we can align the code at the start of
	 * the page. */
	int machine_code_size = tcc_relocate(state, 0);
	if (machine_code_size > 0) {
		/* XXX uses hard-coded page sizes. This could stand to be cleaned up, I suspect */
		SV * machine_code_SV = newSV(machine_code_size + 4096);
		AV * machine_code_cache = get_av("C::Blocks::__code_cache_array", GV_ADDMULTI | GV_ADD);
		uintptr_t machine_code_loc = (uintptr_t)SvPVX(machine_code_SV);
		unsigned int PAGESIZE = 4096;
		if ((machine_code_loc & 0xfff) != 0) {
			machine_code_loc &= ~0xfff;
			machine_code_loc += 4096;
		}
		int relocate_returned = tcc_relocate(state, (void*)machine_code_loc);
		av_push(machine_code_cache, machine_code_SV);
		if (SvPOK(data.error_msg_sv)) {
			/* Look for errors and croak */
			if (strstr(SvPV_nolen(data.error_msg_sv), "error")) {
				croak("C::Blocks linker error:\n%s", SvPV_nolen(data.error_msg_sv));
			}
			/* Otherwise report warnings */
			my_warnif(aTHX_ "linker", sv_2mortal(newSVsv(data.error_msg_sv)));
		}
		if (relocate_returned < 0) {
			croak("C::Blocks linker error: unable to relocate\n");
		}
	}
	
	/********************************************************/
	/* Build op tree or serialize the symbol table; cleanup */
	/********************************************************/

	*op_ptr = build_op(aTHX_ state, keyword_type);
	if (keyword_type == IS_CSUB) extract_xsub(aTHX_ state, &data);
	else if (keyword_type == IS_CSHARE || keyword_type == IS_CLEX) {
		serialize_symbol_table(aTHX_ state, &data, keyword_type);
	}
	
	/* cleanup */
	cleanup_c_blocks_data(aTHX_ &data);
	tcc_delete(state);
	
	/* insert a semicolon to make the parser happy */
	lex_stuff_pvn(";", 1, 0);
	
	/* Make the parser count the number of lines correctly */
	int i;
	for (i = 0; i < data.N_newlines; i++) lex_stuff_pv("\n", 0);
	
	/* Return success */
	return KEYWORD_PLUGIN_STMT;
}

MODULE = C::Blocks       PACKAGE = C::Blocks

void
_import()
CODE:
	if (PL_keyword_plugin != my_keyword_plugin) {
		PL_keyword_plugin = my_keyword_plugin;
	}
	
	/*
	COPHH* hints_hash = CopHINTHASH_get(PL_curcop);
	SV * extended_symtab_tables_SV = cophh_fetch_pvs(hints_hash, "C::Blocks/extended_symtab_tables", 0);
	if (extended_symtab_tables_SV == &PL_sv_placeholder) extended_symtab_tables_SV = newSVpvn("", 0);
	hints_hash = cophh_store_pvs(hints_hash, "C::Blocks/extended_symtab_tables", extended_symtab_tables_SV, 0);
	*/


void
unimport(...)
CODE:
	/* This appears to be broken. But I'll put it on the backburner
	 * for now and see if switching to Devel::CallChecker and
	 * Devel::CallParser fix it. */
	PL_keyword_plugin = next_keyword_plugin;

void
_cleanup()
CODE:
	/* Remove all of the extended symol tables. Note that the code pages
	 * were stored directly into Perl SV's, which were pushed into an
	 * array, so they are cleaned up for us automatically. */
	AV * cache = get_av("C::Blocks::__symtab_cache_array", GV_ADDMULTI | GV_ADD);
	int i;
	SV ** elem_p;
	for (i = 0; i < av_len(cache); i++) {
		elem_p = av_fetch(cache, i, 0);
		if (elem_p != 0) {
			tcc_delete_extended_symbol_table(INT2PTR(extended_symtab_p, SvIV(*elem_p)));
		}
		else {
			warn("C::Blocks had trouble freeing extended symbol table, index %d", i);
		}
	}
	cache = get_av("C::Blocks::__dll_list_array", GV_ADDMULTI | GV_ADD);
	for (i = 0; i < av_len(cache); i++) {
		elem_p = av_fetch(cache, i, 0);
		if (elem_p != 0) {
			Safefree(INT2PTR(void*, SvIV(*elem_p)));
		}
		else {
			warn("C::Blocks had trouble freeing dll list, index %d", i);
		}
	}
	

BOOT:
	/* Set up the keyword plugin to a useful initial value. */
	next_keyword_plugin = PL_keyword_plugin;
	
	/* Set up the custom op */
	XopENTRY_set(&tcc_xop, xop_name, "tccop");
	XopENTRY_set(&tcc_xop, xop_desc, "Op to run jit-compiled C code");
	Perl_custom_op_register(aTHX_ Perl_tcc_pp, &tcc_xop);
