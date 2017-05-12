/*
 * Copyright (C) 2008 Tsukasa Hamano <hamano@cpan.org>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307  USA
 *
 * $Id: TCC.xs,v 1.1.1.1 2008-03-17 04:04:17 hamano Exp $
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <libtcc.h>

MODULE = C::TCC		PACKAGE = C::TCC

int
tcc_add_file(s, filename)
	TCCState *	s
	const char *	filename

int
tcc_add_include_path(s, pathname)
	TCCState *	s
	const char *	pathname

int
tcc_add_library(s, libraryname)
	TCCState *	s
	const char *	libraryname

int
tcc_add_library_path(s, pathname)
	TCCState *	s
	const char *	pathname

int
tcc_add_symbol(s, name, val)
	TCCState *	s
	const char *	name
	void *	val

int
tcc_add_sysinclude_path(s, pathname)
	TCCState *	s
	const char *	pathname

int
tcc_compile_string(s, buf)
	TCCState *	s
	const char *	buf

void
tcc_define_symbol(s, sym, value)
	TCCState *	s
	const char *	sym
	const char *	value

void
tcc_delete(s)
	TCCState *	s

#void
#tcc_enable_debug(s)
#	TCCState *	s

void *
tcc_get_symbol(s, name)
	TCCState *	s
	const char *	name

TCCState *
tcc_new()

int
tcc_output_file(s, filename)
	TCCState *	s
	const char *	filename

int
tcc_relocate(s, ptr)
	TCCState *	s
    void *  ptr

int
tcc_run(s, args)
	TCCState *	s
	AV* args
PREINIT:
CODE:
    int i, ret;
    char *arg;
    int argc = av_len(args) + 1;
    STRLEN arg_len;
    char **argv;

    if(argc > 0){
        argv = malloc(sizeof(char*) * argc);
//        printf("argc = %d\n", argc);
        for(i=0; i<argc; i++){
            SV **tmp = av_fetch(args, i, 0);
            argv[i] = (char *)SvPV(*tmp, arg_len);
//            printf("argv[%d] = %s\n", i, argv[i]);
        }
    }else{
        argc = 0;
        argv = NULL;
    }
    RETVAL = tcc_run(s, argc,argv);
OUTPUT:
    RETVAL

#void
#tcc_set_error_func(s, error_opaque, arg2)
#	TCCState *	s
#	void *	error_opaque
#	void ( * error_func ) ( void * opaque, const char * msg )	arg2

int
tcc_set_output_type(s, output_type)
	TCCState *	s
	int	output_type

int
tcc_set_warning(s, warning_name, value)
	TCCState *	s
	const char *	warning_name
	int	value

void
tcc_undefine_symbol(s, sym)
	TCCState *	s
	const char *	sym
