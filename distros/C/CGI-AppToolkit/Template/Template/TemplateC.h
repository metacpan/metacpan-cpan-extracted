// Copyright 2002 Robert Giseburt. All rights reserved.
// This library is free software; you can redistribute it
// and/or modify it under the same terms as Perl itself.

// Email: rob@heavyhosting.net

#ifndef Template_H
#define Template_H

//pragma once

#include <list>
#include <stack>

#define RG_DEBUG 0

enum _compare_type {
	DN_true					= 0001,
	DN_not					= 0002,
	DN_eq						= 0004,
	DN_lt						= 0010,
	DN_gt						= 0020,
	DN_string				= 0040,
	DN_subtemplate	= 0100,
};

class TemplateNode;
typedef std::list<TemplateNode*> mylist;
typedef std::list<TemplateNode*>::iterator TemplateNodeIterator;

class TemplateC;
typedef TemplateC* TemplateCPtr;
typedef std::stack<TemplateCPtr> TemplateCStack;

extern "C" {
	#include "EXTERN.h"
	#include "perl.h"
}

class TemplateC {
	private:
		mylist items;

		void unescape(char* &text, char* &end_text);
		void skip_spaces(char* &text);
		char* get_word(char* &text);
		char* get_number(char* &text);
		char* get_word_number(char* &text);
		char* get_string(char* &text);
		char* get_token(char start, char* &text);
		char* get_filter(char* &text, char* &word_end, AV* &array);
		
		bool error;
		SV* error_SV;
		HV* vars;

		char* key;
		U32	key_length;

		void set_key(char* key, int length) {
			this->key = new char[length+1];
			this->key_length = length;
			strncpy(this->key, key, (size_t)length);
			this->key[length] = '\0';
		}
		
		void clear_key() {
			if (this->key != NULL)
				delete this->key;
			this->key = NULL;
			this->key_length = 0;
		}

		void add_errorf(const char *fmt, ...) {
				char *text;
				va_list ap;
				if ((text = new char[128]) == NULL)
							 return;
				va_start(ap, fmt);
				int length = vsnprintf(text, 128, fmt, ap);
				va_end(ap);
				
				if (length > 128)
					length = 128;
				
				if (!error) {
					error_SV = newSVpvn(text, length);
					error = true;
				} else
					sv_catpvn(error_SV, text, length);
					
				delete text;
			}

		void add_error(char* text) {
				if (!error) {
					error_SV = newSVpv(text, 0);
					error = true;
				} else
					sv_catpv(error_SV, text);
			};
		void add_error(char* text, int length) {
				if (!error) {
					error_SV = newSVpvn(text, length);
					error = true;
				} else
					sv_catpvn(error_SV, text, length);
			};
		void clear_error() {
				if (error) {
					SvREFCNT_dec(error_SV);
				}
				error = false;
			};

	public:
		// constructors //
		TemplateC();
		TemplateC(const TemplateC& t);
		TemplateC(char* text);
		
		// destructor //
		~TemplateC();
		
		// init - initialize a template //
		int init(char* text);
		
		// value - take data and fill in a template //
		SV* value(SV* callback, SV* data);
		SV* value(SV* callback, AV* data, STRLEN &length);
		SV* value(SV* callback, SV* data, STRLEN &length);
		
		// add & last_nod //
		void add(TemplateNode* node);
		TemplateNode* last_node();
		
		// error & errorstr //
		bool has_error() { return error; };
		SV* get_error() {
				if (error) {
					SV* tempSV = newSVsv(error_SV);
					return tempSV;
				} else {
					return &PL_sv_undef;
				}
			};

		SV* get_vars() {
				if (vars) {
					return newRV_inc((SV*)vars);
				} else {
					return &PL_sv_undef;
				}
			};
};

#endif /* Template_H */
