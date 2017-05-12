/*
   DBIx::MyParse - a glue between Perl and MySQL's SQL parser
   Copyright (C) 2005 Philip Stoev

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "my_parse.h"

#include "assert.h"

void * my_parse_create_array () {
	return newAV();
}

void * my_parse_create_string (const char * string, STRLEN length) {
	return (void *) newSVpv(string, length);
}

void my_parse_free_array (perl_object * array_perl) {
	SvREFCNT_dec((SV *) array_perl);
}

perl_object * my_parse_bless (
	perl_object * array_perl,
	const char * perl_class
) {
	SV * array_perl_ref = newRV_noinc((SV*) array_perl);
	sv_bless(array_perl_ref, gv_stashpv(perl_class, TRUE));
	return (void *) array_perl_ref;
}

void * my_parse_get_array (
	perl_object * array_ref,
	int index
) {
	void * array_ref_real;

	if (SvROK((SV *) array_ref)) {
		array_ref_real = (void *) SvRV((SV *) array_ref);
	} else {
		array_ref_real = array_ref;
	}

	SV ** fetch_result = av_fetch ((AV *) array_ref_real, index, 0);

	if (fetch_result) {
		return (void *) *fetch_result;
	} else {
		return NULL;
	}
}

void * my_parse_get_string (
	perl_object * array_ref,
	int index
) {
	void * array_ref_real;

        if (SvROK((SV *) array_ref)) {
                array_ref_real = (void *) SvRV((SV *) array_ref);
        } else {
                array_ref_real = array_ref;
        }

        SV ** fetch_result = av_fetch ((AV *) array_ref_real, index, 0);

        if (fetch_result) {
		SV * sv_ptr = *fetch_result;
                return (void *) SvPV_nolen(sv_ptr);
        } else {
                return NULL;
        }
}

void * my_parse_set_array (
	perl_object * array_ref,
	int index,
	void * item_ref,
	int item_type
) {

	SV * item = NULL;
	unsigned long * item_long_ptr;
	unsigned long item_long;
	int * int_ptr;

	switch(item_type) {
		case MYPARSE_ARRAY_INT:
			int_ptr = (int *) item_ref;
			item_long = (unsigned long) *int_ptr;
			item = newSViv((IV) item_long);
			break;
		case MYPARSE_ARRAY_LONG:
			item_long_ptr = (unsigned long *) item_ref;
			item = newSViv((IV) *item_long_ptr);
			break;
		case MYPARSE_ARRAY_STRING:
			item = newSVpv((char *) item_ref, strlen((char *) item_ref));
			break;
		case MYPARSE_ARRAY_REF:
			if (SvROK((SV*) item_ref)) {
				item = (SV *) item_ref;
			} else {
				item = newRV_noinc((SV*) item_ref);
			}
			break;
		case MYPARSE_ARRAY_SV:
			item = (SV *) item_ref;
		default:
			assert(item_type);
	}

	assert(item);

	void * array_ref_real;

	if (SvROK((SV *) array_ref)) {
		array_ref_real = (void *) SvRV((SV *) array_ref);
	} else {
		array_ref_real = array_ref;
	}

	if (index == MYPARSE_ARRAY_APPEND) {
		av_push((AV *) array_ref_real, item);
	} else if (index == MYPARSE_ARRAY_PREPEND) {
		av_unshift((AV *) array_ref_real, 1);
		av_store((AV *) array_ref_real, 0, item);
	} else {
		assert(index < 32);
		av_store((AV *) array_ref_real, index, item);
	}

	return item;
}
