/*
 * Sparse c2xml
 *
 * Dumps the parse tree as an xml document
 *
 * Copyright (C) 2007 Rob Taylor
 *
 * Licensed under the Open Software License version 1.1
 */
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <assert.h>
#include <libxml/parser.h>
#include <libxml/tree.h>

#include "expression.h"
#include "parse.h"
#include "scope.h"
#include "symbol.h"
#include "token.h"

static xmlDocPtr doc = NULL;       /* document pointer */
static xmlNodePtr root_node = NULL;/* root node pointer */
static int idcount = 0;

static void examine_symbol(SCTX_ struct symbol *sym, xmlNodePtr node);

static xmlAttrPtr newProp(SCTX_ xmlNodePtr node, const char *name, const char *value)
{
	return xmlNewProp(node, BAD_CAST name, BAD_CAST value);
}

static xmlAttrPtr newNumProp(SCTX_ xmlNodePtr node, const char *name, int value)
{
	char buf[256];
	snprintf(buf, 256, "%d", value);
	return newProp(sctx_ node, name, buf);
}

static xmlAttrPtr newIdProp(SCTX_ xmlNodePtr node, const char *name, unsigned int id)
{
	char buf[256];
	snprintf(buf, 256, "_%d", id);
	return newProp(sctx_ node, name, buf);
}

static xmlNodePtr new_sym_node(SCTX_ struct symbol *sym, const char *name, xmlNodePtr parent)
{
	xmlNodePtr node;
	const char *ident = show_ident(sctx_ sym->ident);

	assert(name != NULL);
	assert(sym != NULL);
	assert(parent != NULL);

	node = xmlNewChild(parent, NULL, BAD_CAST "symbol", NULL);

	newProp(sctx_ node, "type", name);

	newIdProp(sctx_ node, "id", idcount);

	if (sym->ident && ident)
		newProp(sctx_ node, "ident", ident);
	newProp(sctx_ node, "file", stream_name(sctx_ sym->pos->pos.stream));

	newNumProp(sctx_ node, "start-line", sym->pos->pos.line);
	newNumProp(sctx_ node, "start-col", sym->pos->pos.pos);

	if (sym->endpos) {
		newNumProp(sctx_ node, "end-line", sym->endpos->pos.line);
		newNumProp(sctx_ node, "end-col", sym->endpos->pos.pos);
		if (sym->pos->pos.stream != sym->endpos->pos.stream)
			newProp(sctx_ node, "end-file", stream_name(sctx_ sym->endpos->pos.stream));
        }
	sym->aux = node;

	idcount++;

	return node;
}

static inline void examine_members(SCTX_ struct symbol_list *list, xmlNodePtr node)
{
	struct symbol *sym;

	FOR_EACH_PTR(list, sym) {
		examine_symbol(sctx_ sym, node);
	} END_FOR_EACH_PTR(sym);
}

static void examine_modifiers(SCTX_ struct symbol *sym, xmlNodePtr node)
{
	const char *modifiers[] = {
			"auto",
			"register",
			"static",
			"extern",
			"const",
			"volatile",
			"signed",
			"unsigned",
			"char",
			"short",
			"long",
			"long-long",
			"typedef",
			NULL,
			NULL,
			NULL,
			NULL,
			NULL,
			"inline",
			"addressable",
			"nocast",
			"noderef",
			"accessed",
			"toplevel",
			"label",
			"assigned",
			"type-type",
			"safe",
			"user-type",
			"force",
			"explicitly-signed",
			"bitwise"};

	int i;

	if (sym->namespace != NS_SYMBOL)
		return;

	/*iterate over the 32 bit bitfield*/
	for (i=0; i < 32; i++) {
		if ((sym->ctype.modifiers & 1<<i) && modifiers[i])
			newProp(sctx_ node, modifiers[i], "1");
	}
}

static void
examine_layout(SCTX_ struct symbol *sym, xmlNodePtr node)
{
	examine_symbol_type(sctx_ sym);

	newNumProp(sctx_ node, "bit-size", sym->bit_size);
	newNumProp(sctx_ node, "alignment", sym->ctype.alignment);
	newNumProp(sctx_ node, "offset", sym->offset);
	if (is_bitfield_type(sym)) {
		newNumProp(sctx_ node, "bit-offset", sym->bit_offset);
	}
}

static void examine_symbol(SCTX_ struct symbol *sym, xmlNodePtr node)
{
	xmlNodePtr child = NULL;
	const char *base;
	int array_size;

	if (!sym)
		return;
	if (sym->aux)		/*already visited */
		return;

	if (sym->ident && sym->ident->reserved)
		return;

	child = new_sym_node(sctx_ sym, get_type_name(sctx_ sym->type), node);
	examine_modifiers(sctx_ sym, child);
	examine_layout(sctx_ sym, child);

	if (sym->ctype.base_type) {
		if ((base = builtin_typename(sctx_ sym->ctype.base_type)) == NULL) {
			if (!sym->ctype.base_type->aux) {
				examine_symbol(sctx_ sym->ctype.base_type, root_node);
			}
			xmlNewProp(child, BAD_CAST "base-type",
			           xmlGetProp((xmlNodePtr)sym->ctype.base_type->aux, BAD_CAST "id"));
		} else {
			newProp(sctx_ child, "base-type-builtin", base);
		}
	}
	if (sym->array_size) {
		/* TODO: modify get_expression_value to give error return */
		array_size = get_expression_value(sctx_ sym->array_size);
		newNumProp(sctx_ child, "array-size", array_size);
	}


	switch (sym->type) {
	case SYM_STRUCT:
	case SYM_UNION:
		examine_members(sctx_ sym->symbol_list, child);
		break;
	case SYM_FN:
		examine_members(sctx_ sym->arguments, child);
		break;
	case SYM_UNINITIALIZED:
		newProp(sctx_ child, "base-type-builtin", builtin_typename(sctx_ sym));
		break;
	}
	return;
}

static struct token *get_expansion_end (SCTX_ struct token *token)
{
	struct token *p1, *p2;

	for (p1=NULL, p2=NULL;
	     !eof_token(token);
	     p2 = p1, p1 = token, token = token->next);

	if (p2)
		return p2;
	else
		return NULL;
}

static void examine_macro(SCTX_ struct symbol *sym, xmlNodePtr node)
{
	struct token *pos;

	/* this should probably go in the main codebase*/
	pos = get_expansion_end(sctx_ sym->expansion);
	if (pos)
		sym->endpos = pos;
	else
		sym->endpos = sym->pos;

	new_sym_node(sctx_ sym, "macro", node);
}

static void examine_namespace(SCTX_ struct symbol *sym)
{
	if (sym->ident && sym->ident->reserved)
		return;

	switch(sym->namespace) {
	case NS_MACRO:
		examine_macro(sctx_ sym, root_node);
		break;
	case NS_TYPEDEF:
	case NS_STRUCT:
	case NS_SYMBOL:
		examine_symbol(sctx_ sym, root_node);
		break;
	case NS_NONE:
	case NS_LABEL:
	case NS_ITERATOR:
	case NS_UNDEF:
	case NS_PREPROCESSOR:
	case NS_KEYWORD:
		break;
	default:
		sparse_die(sctx_ "Unrecognised namespace type %d",sym->namespace);
	}

}

static int get_stream_id (SCTX_ const char *name)
{
	int i;
	for (i=0; i<sctxp input_stream_nr; i++) {
		if (strcmp(name, stream_name(sctx_ i))==0)
			return i;
	}
	return -1;
}

static inline void examine_symbol_list(SCTX_ const char *file, struct symbol_list *list)
{
	struct symbol *sym;
	int stream_id = get_stream_id (sctx_ file);

	if (!list)
		return;
	FOR_EACH_PTR(list, sym) {
		if (sym->pos->pos.stream == stream_id)
			examine_namespace(sctx_ sym);
	} END_FOR_EACH_PTR(sym);
}

int main(int argc, char **argv)
{
	struct string_list *filelist = NULL;
	struct symbol_list *symlist = NULL;
	char *file;
	SPARSE_CTX_INIT;

	doc = xmlNewDoc(BAD_CAST "1.0");
	root_node = xmlNewNode(NULL, BAD_CAST "parse");
	xmlDocSetRootElement(doc, root_node);

/* - A DTD is probably unnecessary for something like this

	dtd = xmlCreateIntSubset(doc, "parse", "http://www.kernel.org/pub/software/devel/sparse/parse.dtd" NULL, "parse.dtd");

	ns = xmlNewNs (root_node, "http://www.kernel.org/pub/software/devel/sparse/parse.dtd", NULL);

	xmlSetNs(root_node, ns);
*/
	symlist = sparse_initialize(sctx_ argc, argv, &filelist);

	FOR_EACH_PTR_NOTAG(filelist, file) {
		examine_symbol_list(sctx_ file, symlist);
		sparse_keep_tokens(sctx_ file);
		examine_symbol_list(sctx_ file, sctxp file_scope->symbols);
		examine_symbol_list(sctx_ file, sctxp global_scope->symbols);
	} END_FOR_EACH_PTR_NOTAG(file);


	xmlSaveFormatFileEnc("-", doc, "UTF-8", 1);
	xmlFreeDoc(doc);
	xmlCleanupParser();

	return 0;
}

