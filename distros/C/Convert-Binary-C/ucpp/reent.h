/*
 * (c) Thomas Pornin 1999 - 2002
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 4. The name of the authors may not be used to endorse or promote
 *    products derived from this software without specific prior written
 *    permission.
 *
 * THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY EXPRESS OR 
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHORS OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
 * OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR 
 * BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE 
 * OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
 * EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */

#ifndef UCPP__REENT__
#define UCPP__REENT__

#include "tune.h"

#ifdef UCPP_REENTRANT

#include "nhash.h"

#define pCPP	struct CPP *REENTR
#define pCPP_	pCPP,
#define aCPP	REENTR
#define aCPP_	aCPP,

#define useCPP	(void) aCPP

typedef struct _cppm *CPPM;

struct CPP {
	int	no_special_macros,
		emit_dependencies,
		emit_defines,
		emit_assertions;
	int	c99_compliant,
		c99_hosted;
	FILE	*emit_output;
	char	*current_filename,
		*current_long_filename;

	/*
	 * Can be used to store an arbitrary pointer value
	 * that can be retrieved by the callback functions
	 * ucpp_(ouch|error|warning).
	 */
	void	*callback_arg;

	void	(*ucpp_ouch)(pCPP_ char *, ...);
	void	(*ucpp_error)(pCPP_ long, char *, ...);
	void	(*ucpp_warning)(pCPP_ long, char *, ...);

	int	*transient_characters;

	struct protect {
		char *macro;
		int state;
		struct found_file *ff;
	}	protect_detect;

	struct {

	/* from macro.c */
		struct lexer_state dsharp_lexer;
		char compile_time[12], compile_date[24];
#ifdef PRAGMA_TOKENIZE
		struct lexer_state tokenize_lexer;
#endif

	/* from eval.c */
		long eval_line;
		JMP_BUF eval_exception;

	}	_global;

	struct {
		HTT assertions;
		int assertions_init_done;
	}	_assert;

	struct {
		HTT macros;
		int macros_init_done;
	}	_macro;

	struct {
		char **include_path;
		size_t include_path_nb;
		int current_incdir;
		struct file_context *ls_stack;
		size_t ls_depth;
		int find_file_error;
		struct protect *protect_detect_stack;
		HTT found_files;
		HTT found_files_sys;
		int found_files_init_done;
		int found_files_sys_init_done;
	}	_cpp;

	struct {
		int emit_eval_warnings;
	}	_eval;

	struct {
		CPPM sm;
	}	_lexer;
};

#else

#define pCPP	void
#define pCPP_
#define aCPP
#define aCPP_

#define useCPP	(void) 0

#endif

#endif
