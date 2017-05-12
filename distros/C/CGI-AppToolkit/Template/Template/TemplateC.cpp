// Copyright 2002 Robert Giseburt. All rights reserved.
// This library is free software; you can redistribute it
// and/or modify it under the same terms as Perl itself.

// Email: rob@heavyhosting.net

#include <string.h>
#include <ctype.h>
#include <typeinfo>
#include "TemplateC.h"
#include "TextNode.h"
#include "TokenNode.h"
#include "DecisionNode.h"
#include "RepeatNode.h"


#define PUSH_TO_STACK(x) mystack.push(x); mystacktop = x
#define POP_STACK() mystack.pop(); mystacktop = mystack.top()
#define STACK_TOP() mystacktop
#define LENGTH_LEFT(x) (length - (x - text))
#define MATCH_END(x) ((((*x == '?') && (*(x+1) == closer))))
#define match(x, y) ((strncasecmp(x, y, strlen(y)) == 0))

#define CLEAR() while (items.size() > 0) {\
		delete items.back();\
		items.pop_back();\
	}

#define CHECK_MY_VARS() if (in_variable_text) {\
		add_errorf("Malformed template at line %d: token in the middle of a {?my $%0.*s --?} ... {?-- $%0.*s?} block",\
			line, key_length, key, key_length, key);\
			failed = 1;\
			break;\
	}

/*
#define BAIL(string) warn(string, );\
					items.clear();\
					return 0;
*/

TemplateC::TemplateC() : items() {
	error = false;
	key = NULL;
	key_length = 0;
}

TemplateC::TemplateC(const TemplateC& t) : items(t.items) {
	error = false;
	key = NULL;
	key_length = 0;
	warn("TemplateC copied!\n");
}

TemplateC::TemplateC(char* text) : items() {
	error = false;
	key = NULL;
	key_length = 0;
	
	init(text);
}

TemplateC::~TemplateC() {

#if (RG_DEBUG)
	warn("~TemplateC (0x%x)\n", this);
#endif //(RG_DEBUG)

	CLEAR();
//	delete items;
	clear_error();

//	if (vars != NULL)
//		SvREFCNT_dec((SV*)vars);

	clear_key();
}

/*
<?...?> and {?...?} may be used interchangably

NOTE: secondary HTML-style tokens are not yet supported

Tokens:
	{?$token?}
	{?$token escape()?}
	<token name="token">
	<token name="token" do="escape()">
	
Decisions:
	{?if $token --?}...{?-- $token --?}...{?-- $token?}
	{?if $token=123 --?} for numbers
	{?if $token="abc" --?} for strings
	
	<iftoken name="token">...<elseif>...</iftoken>
	<iftoken name="token" number="123"> for numbers
	<iftoken name="token" string="abc"> for strings
	<iftoken name="token" eq="abc"> for strings

Repeats:
	{?@token?} for line repeat
	{?@token --?}...{?-- @token --?}...{?-- @token?}
	
	<repeattoken name="token"/> for line repeat
	<repeattoken name="token">...<elserepeat>...</repeattoken>

Variables:
	{?my $token="this"?}
	{?my $token --?}this{?-- $token?}
	<vartoken name="token" value="this">
	<vartoken name="token">this</vartoken>
*/

void TemplateC::unescape(char* &text, char* &end_text) {
	char* temp_loc = text;
	int offset = 0;
	bool escaped = 0;
	
	while (temp_loc < end_text) {
		if (!escaped && *temp_loc == '\\') {
			offset++;
			escaped = 1;

		} else if (offset > 0) {
			*(temp_loc - offset) = *temp_loc;
			if (escaped)
				escaped = 0;	

		}

		temp_loc++;
	}
	end_text -= offset;
}

void TemplateC::skip_spaces(char* &text) {	
	while (isspace(*text)) {
		text++;
	}
}

char* TemplateC::get_word(char* &text) {
	char* old_text = text;
	
	while (isalnum(*text) || *text == '_' || *text == '-') {
		text++;
	}
	
	if (text > old_text) {
		return old_text;
	} else {
		text = old_text;
		return NULL;
	}
}

char* TemplateC::get_number(char* &text) {
	char* old_text = text;
	
	if (*text == '-')
		text++;
	
	while (isdigit(*text)) {
		text++;
	}
	
	if (*text == '.') {
		text++;
		while (isdigit(*text)) {
			text++;
		}
	}

	if (text > old_text) {
		return old_text;
	} else {
		text = old_text;
		return NULL;
	}
}

char* TemplateC::get_word_number(char* &text) {
	char* old_text = text;
	
	while (isalnum(*text) || *text == '_' || *text == '-' || *text == '.') {
		text++;
	}
	
	if (text > old_text) {
		return old_text;
	} else {
		text = old_text;
		return NULL;
	}
}

char* TemplateC::get_string(char* &text) {
	char* old_text = text;
		
	char delim = *text;
	
	if (delim != '"' && delim != '\'') {
		return NULL;
	}
	
	text++;
	
	while (*text && *text != delim) {	
		if (*text == '\\')
			text++;
		text++;
	}
	
	text++;
	
	if (text > old_text) {
		return old_text;
	} else {
		text = old_text;
		return NULL;
	}
}

char* TemplateC::get_token(char start, char* &text) {
	char* old_text = text;

	if (*text == start) {
		text++;
		old_text = get_word(text);
		
		if (old_text && text > old_text) {
			return old_text;
		}
	}
	
	text = old_text;
	return NULL;
}

char* TemplateC::get_filter(char* &text, char* &filter_end_pos, AV* &array) {
	char* old_text = text;
	char* end_word = text;
	char* next_pos = text;
	char* temp_pos = text;
	char* temp_end_pos = text;
	SV* tempSV = NULL;
	
	array = newAV();
	
	if ((end_word = get_word(text)) != NULL) {
		if (text > old_text) {
			filter_end_pos = text;
			if (*text == '(') {
				temp_pos = text + 1;
				next_pos = text + 1;
				//next_pos = strpbrk(text + 1, "'\",)");
				
				while ((next_pos = strpbrk(next_pos, "'\",)")) != NULL) {
					if (*next_pos == ',' || *next_pos == ')') {
					
						temp_end_pos = next_pos;
						while (isspace(*temp_end_pos) && temp_end_pos > temp_pos) {
							temp_end_pos--;
						}

						while (isspace(*temp_pos) && temp_end_pos > temp_pos) {
							temp_pos++;
						}						

						if (temp_end_pos-temp_pos) {
							unescape(temp_pos, temp_end_pos);
							tempSV = newSVpv(temp_pos, temp_end_pos-temp_pos);
							av_push(array, tempSV);
						}
						
						if (*next_pos == ')') {
							text = next_pos+1;
							break;
						}
						
						next_pos++;
						//continue;
						
					} else if (*next_pos == '\'' || *next_pos == '"') {
						temp_pos = get_string(next_pos);
						
						if (temp_pos != NULL) {
							temp_pos++;
							temp_end_pos = next_pos - 1;
							
							unescape(temp_pos, temp_end_pos);
							tempSV = newSVpv(temp_pos, temp_end_pos-temp_pos);
							av_push(array, tempSV);
						}
						
						//next_pos++;
						//continue;
					}
					
					temp_pos = next_pos;
					//next_pos = strpbrk(next_pos+1, "'\",)");
				}
			}
			return old_text;
		}
	}
	
	text = old_text;
	av_undef(array);
	array = NULL;
	return NULL;
}

void TemplateC::add(TemplateNode* node) {
	this->items.push_back(node);
}

TemplateNode* TemplateC::last_node() {
	return items.back();
}

/*

blah blah blah {?$token?} blah string {?$token?}
^              ^         ^            ^         ^
pos            next_pos  pos          next_pos  pos

*/

int TemplateC::init(char* text) {
	char* pos, * last_line, * next_pos, * temp_pos;
	char* word_pos, * word_end_pos, * filter_pos, * filter_end_pos, * string_pos, * string_end_pos, * le_pos = NULL;
	char closer;
	
	bool want_line_ending = 0;
	bool in_variable_text = 0;
	bool failed = 0;

	// determine the line endings
	char line_ending;
	next_pos = strpbrk(text, "\r\n");
	
	if (!next_pos) {
		line_ending = '\n';
	} else if (*next_pos == '\r') {
		if (*(next_pos+1) == '\n')
			line_ending = '\n';
		else
			line_ending = '\r';		
	} else {
		line_ending = '\n';		
	}

	long line = 1;

	char* looking_for = new char[5];
	strncpy(looking_for, "{<\\_", 5);
	looking_for[3] = line_ending;
//warn("(%0.*s)", 4, looking_for);
	
	SV* mySV;
	vars = newHV();
	
	_compare_type comp_type = DN_eq;
	
	size_t length = strlen(text);
	TemplateCStack mystack;
	TemplateCPtr mystacktop;
	PUSH_TO_STACK(this);

	clear_error();

	pos = text;
	next_pos = text;
	le_pos = text;
	
	while (next_pos > 0 && LENGTH_LEFT(next_pos)) {
		// jump to next token
		next_pos = strpbrk(next_pos, looking_for);
		
		if (next_pos) {
			closer = (*next_pos == '<' ? '>' : '}');
			temp_pos = next_pos+1;

//warn("%0.*s", 1, next_pos);

			// \escape
			if (*next_pos == '\\') {
				next_pos += 2;
				continue;			

			// line ending
			} else if (*next_pos == line_ending) {
				// create string node
				if (want_line_ending) {
					if (pos < temp_pos)
						STACK_TOP()->add(new TextNode(pos, temp_pos - pos));
	
					POP_STACK();
						
					next_pos = temp_pos;
					pos = next_pos;
					want_line_ending = 0;
					line++;
					continue;
					
				} else {
					le_pos = temp_pos;
					next_pos = temp_pos;
					line++;
					continue;
				}
			
			// {? ... ?} or <? ... ?>
			} else if (*temp_pos == '?') {
				temp_pos++;
				skip_spaces(temp_pos);
				
				// {?$token?} or {?$token filter?}
				//    ^    ^word_end_pos
				//    'word_pos
				if (word_pos = get_token('$', temp_pos)) {
					word_end_pos = temp_pos;
					skip_spaces(temp_pos);
					
					AV* array;
					
					if (filter_pos = get_filter(temp_pos, filter_end_pos, array)) {
						skip_spaces(temp_pos);
						
					} else {
						filter_pos = NULL;
						filter_end_pos = NULL;
					}

					if (MATCH_END(temp_pos)) {
						CHECK_MY_VARS();

						// create string node
						if (pos < next_pos)
							STACK_TOP()->add(new TextNode(pos, next_pos - pos));

						// create token node and update pos
						STACK_TOP()->add(new TokenNode(word_pos, word_end_pos - word_pos, filter_pos, filter_end_pos - filter_pos, array));
						next_pos = temp_pos+2;
						pos = next_pos;
						continue;
					}

				// {? if $token ... ?}
				} else if (match(temp_pos, "if") && isspace(*(temp_pos+2))) {
					temp_pos += 3;
					skip_spaces(temp_pos);
					comp_type = DN_true;
					mySV = NULL;
										
					if (*temp_pos == '!') {
						temp_pos++;
						comp_type = (_compare_type)(comp_type ^ DN_not);
					}
					
					word_pos = get_token('$', temp_pos);
					if (word_pos) {
						word_end_pos = temp_pos;
						skip_spaces(temp_pos);
						
						if (*temp_pos == '!') {
							temp_pos++;
							comp_type = (_compare_type)(comp_type ^ DN_not);
						}

						if (*temp_pos == '=' || *temp_pos == '<' || *temp_pos == '>') {
							
							switch (*temp_pos) {
								
								case '=':
									comp_type = (_compare_type)((comp_type & DN_not) + DN_eq);
									temp_pos++;
									break;
									
								case '<':
									if (*(temp_pos+1) == '=') {
										comp_type = (_compare_type)((comp_type & DN_not) | DN_lt | DN_eq);
										temp_pos += 2;
									} else {
										comp_type = (_compare_type)((comp_type & DN_not) | DN_lt);										
										temp_pos++;
									}
									break;
								
								case '>':
									if (*(temp_pos+1) == '=') {
										comp_type = (_compare_type)((comp_type & DN_not) | DN_gt | DN_eq);
										temp_pos += 2;
									} else {
										comp_type = (_compare_type)((comp_type & DN_not) | DN_gt);										
										temp_pos++;
									}
									break;
								
							}
							
							skip_spaces(temp_pos);
							
							char opener = *temp_pos;
							if ((*temp_pos == '"' || *temp_pos == '\'') && (string_pos = get_string(temp_pos)) != NULL) {
								string_pos++;
								string_end_pos = temp_pos - 1;
								mySV = newSVpv(string_pos, string_end_pos-string_pos);
								//sv_2mortal(mySV);
								
								if (opener == '"')
									comp_type = (_compare_type)(comp_type | DN_subtemplate);
								else
									comp_type = (_compare_type)(comp_type | DN_string);
									
								skip_spaces(temp_pos);

							} else if ((string_pos = get_number(temp_pos)) != NULL) {
								string_end_pos = temp_pos;
								mySV = newSVpv(string_pos, string_end_pos-string_pos);
								//sv_2mortal(mySV);
								//comp_type = (_compare_type)(comp_type + DN_eq);
								skip_spaces(temp_pos);
							}
						}
						
						if (match(temp_pos, "--")) {
							temp_pos += 2;
							skip_spaces(temp_pos);
							
							if (MATCH_END(temp_pos)) {
								CHECK_MY_VARS();
								
								// create string node
								if (pos < next_pos)
									STACK_TOP()->add(new TextNode(pos, next_pos - pos));

								// create token node and update pos
								DecisionNode *dn = new DecisionNode(word_pos, word_end_pos - word_pos, comp_type, mySV);
								STACK_TOP()->add(dn);

								PUSH_TO_STACK(dn->get_true_value());
								
								next_pos = temp_pos+2;
								pos = next_pos;
								continue;
							}						
						} else if (mySV) {
								SvREFCNT_dec(mySV);
						}
					}
				

				// {? my $token ... ?}
				} else if (match(temp_pos, "my") && isspace(*(temp_pos+2))) {
					temp_pos += 3;
					skip_spaces(temp_pos);
					
					word_pos = get_token('$', temp_pos);
					if (word_pos) {
						word_end_pos = temp_pos;
						skip_spaces(temp_pos);
						
						if (*temp_pos == '=') {
							temp_pos++;
							skip_spaces(temp_pos);
							if ((*temp_pos == '"' || *temp_pos == '\'') && (string_pos = get_string(temp_pos)) != NULL) {
								string_pos++;
								string_end_pos = temp_pos - 1;
								mySV = newSVpv(string_pos, string_end_pos-string_pos);

								if (MATCH_END(temp_pos)) {
									CHECK_MY_VARS();
									// create string node
									if (pos < next_pos)
										STACK_TOP()->add(new TextNode(pos, next_pos - pos));
	
									//add value to vars
									hv_store(vars, word_pos, word_end_pos - word_pos, mySV, 0);
									
									//SvREFCNT_dec(mySV);
									mySV = NULL;
									
									next_pos = temp_pos+2;
									pos = next_pos;
									continue;
								}
							}

						
						} else if (match(temp_pos, "--")) {
							temp_pos += 2;
							skip_spaces(temp_pos);
							
							if (MATCH_END(temp_pos)) {
								CHECK_MY_VARS();
								// create string node
								if (pos < next_pos)
									STACK_TOP()->add(new TextNode(pos, next_pos - pos));

								in_variable_text = 1;
								set_key(word_pos, word_end_pos - word_pos);
								
								next_pos = temp_pos+2;
								pos = next_pos;
								continue;
							}
							
						} else if (mySV) {
								SvREFCNT_dec(mySV);
						}
					}
					
				// {?@token?} or {?@token --?}
				} else if (word_pos = get_token('@', temp_pos)) {
					word_end_pos = temp_pos;
					skip_spaces(temp_pos);
					
					// {?@token --?}
					if (match(temp_pos, "--")) {
						temp_pos += 2;
						skip_spaces(temp_pos);
						
						if (MATCH_END(temp_pos)) {
							CHECK_MY_VARS();
							// create string node
							if (pos < next_pos)
								STACK_TOP()->add(new TextNode(pos, next_pos - pos));

							// create token node and update pos
							RepeatNode *rn = new RepeatNode(word_pos, word_end_pos - word_pos);
							STACK_TOP()->add(rn);

							PUSH_TO_STACK(rn->get_true_value());
							
							next_pos = temp_pos+2;
							pos = next_pos;
							continue;
						}
										
					// {?@token?}
					} else {
						skip_spaces(temp_pos);
												
						if (MATCH_END(temp_pos)) {
							CHECK_MY_VARS();
							add_errorf("Malformed template at line %d: multiple {?@%0.*s?} style tokens on the same line",
								line, word_end_pos - word_pos, word_pos);
							
							failed = 1;
							break;				
/*
							// The Template.pm code will eliminate {?@template?} or <repeattoken ... /> style
							// tokens .. unless there are more than one on a line, which is an error.
							// Here's the old code:

							// create string node for before line
							if (pos < le_pos)
								STACK_TOP()->add(new TextNode(pos, le_pos - pos));

							// create token node and update pos
							RepeatNode *rn = new RepeatNode(word_pos, word_end_pos - word_pos);
							STACK_TOP()->add(rn);

							PUSH_TO_STACK(rn->get_true_value());

							// create string node for true value
							if (pos < le_pos && le_pos < next_pos)
								STACK_TOP()->add(new TextNode(le_pos, next_pos - le_pos));
							else if (pos < next_pos)
								STACK_TOP()->add(new TextNode(pos, next_pos - pos));
							
							want_line_ending = 1;
						
							next_pos = temp_pos+2;
							pos = next_pos;
							continue;
*/
						}							
					}
				
				// {?-- $token --?} or {?-- $token?} or {?-- @token --?} or {?-- @token?}
				} else if (match(temp_pos, "--")) {
					temp_pos+=2;
					skip_spaces(temp_pos);
				
					// {?-- $token --?} or {?-- $token?}
					if (word_pos = get_token('$', temp_pos)) {
						word_end_pos = temp_pos;
						skip_spaces(temp_pos);
						
						// {?-- $token --?}
						if (match(temp_pos, "--")) {
							temp_pos += 2;
							skip_spaces(temp_pos);
							
							if (MATCH_END(temp_pos)) {
								CHECK_MY_VARS();
								// create string node
								if (pos < next_pos)
									STACK_TOP()->add(new TextNode(pos, next_pos - pos));

								POP_STACK();								
								
								if (typeid(*(STACK_TOP()->last_node())) != typeid(DecisionNode) ||
								   	!STACK_TOP()->last_node()->key_is(word_pos, word_end_pos - word_pos)
								   ) {
								  
								  add_errorf("Malformed template at line %d: {?-- $%0.*s --?} out of order",
								  	line, word_end_pos - word_pos, word_pos);
							
									failed = 1;
									break;				
								}
								
								DecisionNode *dn = (DecisionNode *)(STACK_TOP()->last_node());
								PUSH_TO_STACK(dn->get_false_value());
								
								next_pos = temp_pos+2;
								pos = next_pos;
								continue;
							}
											
						// {?-- $token?}
						} else {
							skip_spaces(temp_pos);
							
							if (MATCH_END(temp_pos)) {
								if (in_variable_text) {
								
									if ((word_end_pos - word_pos) != key_length ||
											strncasecmp(key, word_pos, key_length) != 0
											) {
	
										add_errorf("Malformed template at line %d: {?-- $%0.*s ?} out of order (should be {?-- $%0.*s ?})",
											line, word_end_pos - word_pos, word_pos, key_length, key);
										
										failed = 1;
										break;				
									}

									mySV = newSVpv(pos, next_pos - pos);
									hv_store(vars, key, key_length, mySV, 0);
									clear_key();
									in_variable_text = 0;
									
								} else {
								
									// create string node
									if (pos < next_pos)
										STACK_TOP()->add(new TextNode(pos, next_pos - pos));
	
									POP_STACK();
									
									if (typeid(*(STACK_TOP()->last_node())) != typeid(DecisionNode) ||
											!STACK_TOP()->last_node()->key_is(word_pos, word_end_pos - word_pos)
										 ) {
	
										add_errorf("Malformed template at line %d: {?-- $%0.*s ?} out of order",
											line, word_end_pos - word_pos, word_pos);
						
										failed = 1;
										break;				
									}
									
								}
													
								next_pos = temp_pos+2;
								pos = next_pos;
								continue;
							}							
						}
						
					// {?-- @token --?} or {?-- @token?}
					} else if (word_pos = get_token('@', temp_pos)) {
						word_end_pos = temp_pos;
						skip_spaces(temp_pos);
						
						// {?-- @token --?}
						if (match(temp_pos, "--")) {
							temp_pos += 2;
							skip_spaces(temp_pos);
							
							if (MATCH_END(temp_pos)) {
								CHECK_MY_VARS();
								// create string node
								if (pos < next_pos)
									STACK_TOP()->add(new TextNode(pos, next_pos - pos));

								POP_STACK();								
								
								if (typeid(*(STACK_TOP()->last_node())) != typeid(RepeatNode) ||
								   	!STACK_TOP()->last_node()->key_is(word_pos, word_end_pos - word_pos)
								   ) {
								  
								  add_errorf("Malformed template at line %d: {?-- @%0.*s --?} out of order", line, word_end_pos - word_pos, word_pos);
							
									failed = 1;
									break;				
								}

								// create token node and update pos
								RepeatNode *rn = (RepeatNode *)(STACK_TOP()->last_node());
								PUSH_TO_STACK(rn->get_false_value());
								
								next_pos = temp_pos+2;
								pos = next_pos;
								continue;
							}
											
						// {?-- @token?}
						} else {
							skip_spaces(temp_pos);
							
							if (MATCH_END(temp_pos)) {
								CHECK_MY_VARS();
								// create string node
								if (pos < next_pos)
									STACK_TOP()->add(new TextNode(pos, next_pos - pos));

								POP_STACK();
								
								if (typeid(*(STACK_TOP()->last_node())) != typeid(RepeatNode) ||
								   	!STACK_TOP()->last_node()->key_is(word_pos, word_end_pos - word_pos)
								   ) {
								  
								  add_errorf("Malformed template at line %d: {?-- @%0.*s ?} out of order", line, word_end_pos - word_pos, word_pos);
									
									failed = 1;
									break;				
								}
													
								next_pos = temp_pos+2;
								pos = next_pos;
								continue;
							}							
						}
					}
				}
			
			// <token ...>, <iftoken ...>, or <repeattoken ...>
			} else {
				skip_spaces(temp_pos);
				
				/*
					<token tokenname>
					<token name="tokenname">
					<token name="tokenname" do="escape()">
				*/
				if (match(temp_pos, "token") && isspace(*(temp_pos+5))) {
					temp_pos += 5;
					skip_spaces(temp_pos);
					
					AV* array;
					
					bool bail = 0;
					
					//word_pos is NULL when we haven't found a name yet
					word_pos = NULL;
					
					//set when we've found a Do="" (filter)
					filter_pos = NULL;
					filter_end_pos = NULL;
					
					while (!bail && *temp_pos && *temp_pos != '>') {
						char* try_pos = temp_pos;

						if (match(try_pos, "name")) {
							try_pos += 4;
							skip_spaces(try_pos);
							if (*try_pos == '=') {
								try_pos += 1;
								skip_spaces(try_pos);
								
								if ((*try_pos == '\'' || *try_pos == '"') && (word_pos = get_string(try_pos))) {
									word_pos++;
									word_end_pos = try_pos - 1;
									
									temp_pos = try_pos;
								} else if (word_pos = get_word(try_pos)) {
									word_end_pos = try_pos;
									
									temp_pos = try_pos;
								} else {
									bail = 1;
									break;
								}
								
								skip_spaces(temp_pos);
								continue;
							}
							
						}
						try_pos = temp_pos;

						if (match(try_pos, "do")) {
							try_pos += 2;
							skip_spaces(try_pos);
							if (*try_pos == '=') {
								try_pos += 1;
								skip_spaces(try_pos);
								
								if ((*try_pos == '\'' || *try_pos == '"')) {
									char quote = *try_pos;
									try_pos++;
									skip_spaces(try_pos);

									if (filter_pos = get_filter(try_pos, filter_end_pos, array)) {
										//find the end of our quote
										while (*try_pos && *try_pos != quote && *try_pos != '>') {	
											if (*try_pos == '\\')
												try_pos++;
											try_pos++;
										}
										
										if (*try_pos == quote) {
											try_pos++;
										}
										
										temp_pos = try_pos;
									}
									
								} else if (filter_pos = get_filter(try_pos, filter_end_pos, array)) {									
									temp_pos = try_pos;

								} else {
									bail = 1;
									break;
								}
								
								skip_spaces(temp_pos);
								continue;
							}
						}
						try_pos = temp_pos;
						
						// if we're here, then we didn't match anything ... future enhancements?
						// anyway -- we need to look for plain style code: <token thingy filter()>
						
						if ((!word_pos) && (word_pos = get_word(temp_pos))) {
								word_end_pos = temp_pos;
								skip_spaces(temp_pos);
								
						} else if ((word_pos) && (!filter_pos) && (filter_pos = get_filter(temp_pos, filter_end_pos, array))) {
							skip_spaces(temp_pos);								

						} else {
							//I don't know what we've got here, but I'd rather be compatible as possible, so keep looking
							temp_pos++;
						}
						
					}
	
					if (!bail && word_pos) {
						CHECK_MY_VARS();

						// create string node
						if (pos < next_pos)
							STACK_TOP()->add(new TextNode(pos, next_pos - pos));

						// create token node and update pos
						STACK_TOP()->add(new TokenNode(word_pos, word_end_pos - word_pos, filter_pos, filter_end_pos - filter_pos, array));
						next_pos = temp_pos+1;
						pos = next_pos;
						continue;
					}
				}

/*
	<iftoken name="token">...<else>...</iftoken>
	<iftoken name="token" value="123" as="[number|string|template]" comparison="[ne|eq|lt|gt|le|ge]">
*/

				//<iftoken name="token">
				else if (match(temp_pos, "iftoken") && isspace(*(temp_pos+7))) {
					temp_pos += 7;
					skip_spaces(temp_pos);
					
					AV* array;
					
					bool bail = 0;
					
					//word_pos is NULL when we haven't found a name yet
					word_pos = NULL;
					
					comp_type = DN_true;
					mySV = NULL;
					
					while (!bail && *temp_pos && *temp_pos != '>') {
						char* try_pos = temp_pos;
						char* temp2_pos = temp_pos;

						if (match(try_pos, "name")) {
							try_pos += 4;
							skip_spaces(try_pos);
							if (*try_pos == '=') {
								try_pos += 1;
								skip_spaces(try_pos);
								
								if ((*try_pos == '\'' || *try_pos == '"') && (word_pos = get_string(try_pos))) {
									word_pos++;
									word_end_pos = try_pos - 1;
									
									temp_pos = try_pos;
								} else if (word_pos = get_word(try_pos)) {
									word_end_pos = try_pos;
									
									temp_pos = try_pos;
								} else {
									bail = 1;
									break;
								}

								skip_spaces(temp_pos);
								continue;
							}
							
						}
						try_pos = temp_pos;
						
						if (match(try_pos, "value")) {
							try_pos += 5;
							skip_spaces(try_pos);
							if (*try_pos == '=') {
								try_pos += 1;
								skip_spaces(try_pos);
								
								if ((*try_pos == '\'' || *try_pos == '"') && (string_pos = get_string((try_pos))) != NULL) {
									string_pos++;
									string_end_pos = try_pos - 1;
									temp_pos = try_pos;
									mySV = newSVpv(string_pos, string_end_pos-string_pos);
									comp_type = (_compare_type)(comp_type - (comp_type & DN_true));

									
								} else if (string_pos = get_word_number(try_pos)) {									
									string_end_pos = try_pos;
									temp_pos = try_pos;
									comp_type = (_compare_type)(comp_type - (comp_type & DN_true));

								} else {
									bail = 1;
									break;
								}
								
								skip_spaces(temp_pos);
								continue;
							}
						}
						try_pos = temp_pos;

						if (match(try_pos, "as")) {
							try_pos += 2;
							skip_spaces(try_pos);
							if (*try_pos == '=') {
								try_pos += 1;
								skip_spaces(try_pos);
								
								//NOTE: we're setting temp2_pos to the beginning, and try_pos to the end of the ... in as="..."
								if ((*try_pos == '\'' || *try_pos == '"') && (temp2_pos = get_string((try_pos))) != NULL) {
									temp2_pos++;
									// skip spaces at the beginning
									skip_spaces(temp2_pos);

									//we've officially made it here, even if we don't match
									temp_pos = try_pos;
									
									//back off of the quote
									try_pos--;
									
									//skip spaces backwards
									while (isspace(*try_pos)) {
										try_pos--;
									}
									
								} else if (temp2_pos = get_word_number(try_pos)) {									
									temp_pos = try_pos;

								} else {
									bail = 1;
									break;
								}
								
								skip_spaces(temp_pos);
								
								//try to match our as="..." and set comp_type
								if (match(temp2_pos, "string"))
									comp_type = (_compare_type)(comp_type | DN_string);
								else if (match(temp2_pos, "template"))
									comp_type = (_compare_type)(comp_type | DN_subtemplate);
								else if (match(temp2_pos, "number"))
									comp_type = (_compare_type)(comp_type - (comp_type & (DN_string | DN_subtemplate)));

								continue;
							}
						}
						try_pos = temp_pos;

						if (match(try_pos, "comparison")) {
							try_pos += 10;
							skip_spaces(try_pos);
							if (*try_pos == '=') {
								try_pos += 1;
								skip_spaces(try_pos);
								
								//NOTE: we're setting temp2_pos to the beginning, and try_pos to the end of the ... in comparison="..."
								if ((*try_pos == '\'' || *try_pos == '"') && (temp2_pos = get_string((try_pos))) != NULL) {
									temp2_pos++;
									// skip spaces at the beginning
									skip_spaces(temp2_pos);

									//we've officially made it here, even if we don't match
									temp_pos = try_pos;
									
									//back off of the quote
									try_pos--;
									
									//skip spaces backwards
									while (isspace(*try_pos)) {
										try_pos--;
									}
									
								} else if (temp2_pos = get_word_number(try_pos)) {									
									temp_pos = try_pos;

								} else {
									bail = 1;
									break;
								}
								
								skip_spaces(temp_pos);
								
								//try to match our comparison="..." and set comp_type
								
								if (match(temp2_pos, "not"))
									comp_type = (_compare_type)((comp_type & (DN_string | DN_subtemplate)) | DN_not | DN_true);
								else if (match(temp2_pos, "ne"))
									comp_type = (_compare_type)((comp_type & (DN_string | DN_subtemplate)) | DN_not | DN_eq);
								else if (match(temp2_pos, "eq"))
									comp_type = (_compare_type)((comp_type & (DN_string | DN_subtemplate)) | DN_eq);
								else if (match(temp2_pos, "lt"))
									comp_type = (_compare_type)((comp_type & (DN_string | DN_subtemplate)) | DN_lt);
								else if (match(temp2_pos, "le"))
									comp_type = (_compare_type)((comp_type & (DN_string | DN_subtemplate)) | DN_eq | DN_lt);
								else if (match(temp2_pos, "gt"))
									comp_type = (_compare_type)((comp_type & (DN_string | DN_subtemplate)) | DN_gt);
								else if (match(temp2_pos, "ge"))
									comp_type = (_compare_type)((comp_type & (DN_string | DN_subtemplate)) | DN_eq | DN_gt);

								continue;
							}
						}
						
						
						// if we're here, then we didn't match anything ... future enhancements?
						// anyway -- we need to look for plain style code: <iftoken thingy>
						
						if ((!word_pos) && (word_pos = get_word(temp_pos))) {
								word_end_pos = temp_pos;
								skip_spaces(temp_pos);

						} else {
							//I don't know what we've got here, but I'd rather be compatible as possible, so keep looking
							temp_pos++;
						}
						
					}
						
					// OOPS: we ate up the rest of it!
					if (!*temp_pos) {
						next_pos++;
						continue;
					}

					if (!bail && word_pos) {
						CHECK_MY_VARS();

						// create string node
						if (pos < next_pos)
							STACK_TOP()->add(new TextNode(pos, next_pos - pos));

						// check for valid comp_type comparison
						// if DN_true is not set, then we have a value, use DN_eq
						if (!(_compare_type)(comp_type & (DN_true | DN_eq | DN_lt | DN_gt)))
							comp_type = (_compare_type)(comp_type | DN_eq);
	
						// create token node and update pos
						DecisionNode *dn = new DecisionNode(word_pos, word_end_pos - word_pos, comp_type, mySV);
						STACK_TOP()->add(dn);

						PUSH_TO_STACK(dn->get_true_value());
								
						next_pos = temp_pos+1;
						pos = next_pos;
						continue;
					}
				}

				//<else>
				//NOTE: this could be a <else> for a <iftoken ...> or a <repeattoken ...>
				else if (match(temp_pos, "else") && (isspace(*(temp_pos+4)) || *(temp_pos+4) == '>')) {
					temp_pos += 4;

					if (*temp_pos != '>') {
						skip_spaces(temp_pos);
						
						// ignore and skip the rest
						while (*temp_pos && *temp_pos != '>') {
							temp_pos++;
						}
						
						// OOPS: we ate up the rest of it!
						if (!*temp_pos) {
							next_pos++;
							continue;
						}
					}
					
					CHECK_MY_VARS();
					// create string node
					if (pos < next_pos)
						STACK_TOP()->add(new TextNode(pos, next_pos - pos));

					POP_STACK();								
						
					if (typeid(*(STACK_TOP()->last_node())) != typeid(DecisionNode) && typeid(*(STACK_TOP()->last_node())) != typeid(RepeatNode)) {
						
						add_errorf("Malformed template at line %d: <else> out of order", line);
				
						failed = 1;
						break;				
					}
						
					if (typeid(*(STACK_TOP()->last_node())) == typeid(DecisionNode)) {
						DecisionNode *dn = (DecisionNode *)(STACK_TOP()->last_node());
						PUSH_TO_STACK(dn->get_false_value());
					
					} else if (typeid(*(STACK_TOP()->last_node())) == typeid(RepeatNode)) {
						RepeatNode *rn = (RepeatNode *)(STACK_TOP()->last_node());
						PUSH_TO_STACK(rn->get_false_value());
					}
					
					next_pos = temp_pos+1;
					pos = next_pos;
					continue;
				}

				//</iftoken>
				else if (match(temp_pos, "/iftoken") && (isspace(*(temp_pos+8)) || *(temp_pos+8) == '>')) {
					temp_pos += 8;
					
					if (*temp_pos != '>') {
						skip_spaces(temp_pos);
						
						// ignore and skip the rest
						while (*temp_pos && *temp_pos != '>') {
							temp_pos++;
						}
						
						// OOPS: we ate up the rest of it!
						if (!*temp_pos) {
							next_pos++;
							continue;
						}
					}

					CHECK_MY_VARS();

					// create string node
					if (pos < next_pos)
						STACK_TOP()->add(new TextNode(pos, next_pos - pos));

					POP_STACK();								
						
					if (typeid(*(STACK_TOP()->last_node())) != typeid(DecisionNode)) {
						
						add_errorf("Malformed template at line %d: </iftoken> out of order", line);
				
						failed = 1;
						break;				
					}
					
					next_pos = temp_pos+1;
					pos = next_pos;
					continue;
				}
				
/*
	<repeattoken name="token"/> for line repeat
	<repeattoken name="token">...<else>...</repeattoken>
*/
				//<repeattoken name="token"> or <repeattoken name="token"/>
				else if (match(temp_pos, "repeattoken") && isspace(*(temp_pos+11))) {
					temp_pos += 11;
					skip_spaces(temp_pos);
					
					AV* array;
					
					bool bail = 0;
					bool line_repeat = 0;
					
					//word_pos is NULL when we haven't found a name yet
					word_pos = NULL;
					
					comp_type = DN_true;
					mySV = NULL;
					
					while (!bail && *temp_pos && *temp_pos != '>') {
						char* try_pos = temp_pos;
						char* temp2_pos = temp_pos;

						if (match(try_pos, "name")) {
							try_pos += 4;
							skip_spaces(try_pos);
							if (*try_pos == '=') {
								try_pos += 1;
								skip_spaces(try_pos);
								
								if ((*try_pos == '\'' || *try_pos == '"') && (word_pos = get_string(try_pos))) {
									word_pos++;
									word_end_pos = try_pos - 1;
									
									temp_pos = try_pos;
								} else if (word_pos = get_word(try_pos)) {
									word_end_pos = try_pos;
									
									temp_pos = try_pos;
								} else {
									bail = 1;
									break;
								}

								skip_spaces(temp_pos);
								continue;
							}
							
						}
						
						if (*try_pos == '/') {
							try_pos++;
							skip_spaces(try_pos);
							
							line_repeat = 1;
						}
																		
						// if we're here, then we didn't match anything ... future enhancements?
						// anyway -- we need to look for plain style code: <repeattoken thingy>
						
						if ((!word_pos) && (word_pos = get_word(temp_pos))) {
								word_end_pos = temp_pos;
								skip_spaces(temp_pos);
								
						} else {
							//I don't know what we've got here, but I'd rather be compatible as possible, so keep looking
							temp_pos++;
						}
						
					}
						
					// OOPS: we ate up the rest of it!
					if (!*temp_pos) {
						next_pos++;
						continue;
					}
					
					// The Template.pm code will eliminate {?@template?} or <repeattoken ... /> style
					// tokens .. unless there are more than one on a line, which is an error.
					if (line_repeat) {
						add_errorf("Malformed template at line %d: multiple {?@%0.*s?} or <repeattoken name=\"%0.*s\"/> style tokens on the same line",
								line, word_end_pos - word_pos, word_pos, word_end_pos - word_pos, word_pos);
							
						failed = 1;
						break;				
					}

					if (!bail && word_pos) {
						CHECK_MY_VARS();

						// create string node
						if (pos < next_pos)
							STACK_TOP()->add(new TextNode(pos, next_pos - pos));

						// create token node and update pos
						RepeatNode *rn = new RepeatNode(word_pos, word_end_pos - word_pos);
						STACK_TOP()->add(rn);

						PUSH_TO_STACK(rn->get_true_value());
								
						next_pos = temp_pos+1;
						pos = next_pos;
						continue;
					}
				}

				//</repeattoken>
				else if (match(temp_pos, "/repeattoken") && (isspace(*(temp_pos+12)) || *(temp_pos+12) == '>')) {
					temp_pos += 12;
					
					if (*temp_pos != '>') {
						skip_spaces(temp_pos);
						
						// ignore and skip the rest
						while (*temp_pos && *temp_pos != '>') {
							temp_pos++;
						}
						
						// OOPS: we ate up the rest of it!
						if (!*temp_pos) {
							next_pos++;
							continue;
						}
					}

					CHECK_MY_VARS();

					// create string node
					if (pos < next_pos)
						STACK_TOP()->add(new TextNode(pos, next_pos - pos));

					POP_STACK();								
						
					if (typeid(*(STACK_TOP()->last_node())) != typeid(RepeatNode)) {
						
						add_errorf("Malformed template at line %d: </repeattoken> out of order", line);
				
						failed = 1;
						break;				
					}
					
					next_pos = temp_pos+1;
					pos = next_pos;
					continue;
				}				

/*
	<vartoken name="token" value="this">
	<vartoken name="token">this</vartoken>
*/

				//<vartoken name="token" value="this">
				else if (match(temp_pos, "vartoken") && isspace(*(temp_pos+8))) {
					temp_pos += 8;
					skip_spaces(temp_pos);
					
					AV* array;
					
					bool bail = 0;
					
					//word_pos is NULL when we haven't found a name yet
					word_pos = NULL;
					
					mySV = NULL;
					
					while (!bail && *temp_pos && *temp_pos != '>') {
						char* try_pos = temp_pos;
						char* temp2_pos = temp_pos;

						if (match(try_pos, "name")) {
							try_pos += 4;
							skip_spaces(try_pos);
							if (*try_pos == '=') {
								try_pos += 1;
								skip_spaces(try_pos);
								
								if ((*try_pos == '\'' || *try_pos == '"') && (word_pos = get_string(try_pos))) {
									word_pos++;
									word_end_pos = try_pos - 1;
									
									temp_pos = try_pos;
								} else if (word_pos = get_word(try_pos)) {
									word_end_pos = try_pos;
									
									temp_pos = try_pos;
								} else {
									bail = 1;
									break;
								}

								skip_spaces(temp_pos);
								continue;
							}
							
						}
						try_pos = temp_pos;

						if (match(try_pos, "value")) {
							try_pos += 5;
							skip_spaces(try_pos);
							if (*try_pos == '=') {
								try_pos += 1;
								skip_spaces(try_pos);
								
								if ((*try_pos == '\'' || *try_pos == '"') && (string_pos = get_string((try_pos))) != NULL) {
									string_pos++;
									string_end_pos = try_pos - 1;
									temp_pos = try_pos;
									mySV = newSVpv(string_pos, string_end_pos-string_pos);

									
								} else if (string_pos = get_word_number(try_pos)) {									
									string_end_pos = try_pos;
									temp_pos = try_pos;

								} else {
									bail = 1;
									break;
								}
								
								skip_spaces(temp_pos);
								continue;
							}
						}
											
						// if we're here, then we didn't match anything ... future enhancements?						
						//I don't know what we've got here, but I'd rather be compatible as possible, so keep looking
						temp_pos++;
						
					}
						
					// OOPS: we ate up the rest of it!
					if (!*temp_pos) {
						next_pos++;
						continue;
					}

					if (!bail && word_pos) {
						CHECK_MY_VARS();

						// create string node
						if (pos < next_pos)
							STACK_TOP()->add(new TextNode(pos, next_pos - pos));

						// if value was set
						if (mySV) {
							//add value to vars
							hv_store(vars, word_pos, word_end_pos - word_pos, mySV, 0);
							
							//SvREFCNT_dec(mySV);
							mySV = NULL;
						
						} else {
							in_variable_text = 1;
							set_key(word_pos, word_end_pos - word_pos);
						}
								
						next_pos = temp_pos+1;
						pos = next_pos;
						continue;
					}
				}

				//</vartoken>
				else if (match(temp_pos, "/vartoken") && (isspace(*(temp_pos+9)) || *(temp_pos+9) == '>')) {
					temp_pos += 9;
					
					if (*temp_pos != '>') {
						skip_spaces(temp_pos);
						
						// ignore and skip the rest
						while (*temp_pos && *temp_pos != '>') {
							temp_pos++;
						}
						
						// OOPS: we ate up the rest of it!
						if (!*temp_pos) {
							next_pos++;
							continue;
						}
					}

					if (!in_variable_text) {
						add_errorf("Malformed template at line %d: </vartoken> out of order", line);
				
						failed = 1;
						break;				
					}					

					mySV = newSVpv(pos, next_pos - pos);
					hv_store(vars, key, key_length, mySV, 0);
					clear_key();
					in_variable_text = 0;
					
					next_pos = temp_pos+1;
					pos = next_pos;
					continue;
				}
			
			}
			
			next_pos++;
			
		}
	}

	if (want_line_ending) {
		// create string node
		if (pos < temp_pos)
			STACK_TOP()->add(new TextNode(pos, temp_pos - pos));

		POP_STACK();
		
		want_line_ending = 0;				

	} else {
		// the rest is a string
		STACK_TOP()->add(new TextNode(pos, LENGTH_LEFT(pos)));
	}
	
	if (!failed && mystack.size() > 1 || in_variable_text) {
		POP_STACK();

		char* typecode;
		char* typecode_html;
		
		if (typeid(*(STACK_TOP()->last_node())) == typeid(RepeatNode)) {
			typecode = "@";
			typecode_html = "repeattoken";
		} else {
			typecode = "$";
			typecode_html = "iftoken";
		}
		
		add_errorf("Malformed template at end of file: missing {?-- %s%s ?} or </%s>",
			typecode,
			STACK_TOP()->last_node()->get_key(),
			typecode_html
			);
				
		failed = 1;
	}
	
	delete looking_for;	
	
	if (failed) {
		CLEAR();
		return 0;	
	}
	
	return 1;
}

SV* TemplateC::value(SV* callback, SV* data) {
	STRLEN length;
	return TemplateC::value(callback, data, length);
}

SV* TemplateC::value(SV* callback, SV* data, STRLEN &length) {
	AV* array;
	if (data && SvROK(data) && SvTYPE(SvRV(data)) == SVt_PVAV) {
		array = (AV*) SvRV(data);
		return TemplateC::value(callback, array, length);
	}
	
	return &PL_sv_undef;
}

SV* TemplateC::value(SV* callback, AV* data, STRLEN &inlength) {
	//I32 count = items.size();
	SV* retVal = newSVpvn("", 0);
	STRLEN length;
	
	TemplateNode* node;
	char* buffer;
	
	for (mylist::iterator i = items.begin(); i != items.end(); i++) {
		node = *i;
		buffer = node->value(callback, data, length);

		if (buffer != NULL) {
			sv_catpvn(retVal, buffer, length);
			inlength += length;
		}
	}
		
	return retVal;
}

//void TemplateC::clear() {
//	I32 count = items->size();
//
//	for (I32 i = 0; i < count; i++) {
//		delete (items->get(i));
//	}
//}