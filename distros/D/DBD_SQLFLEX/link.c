/*
@(#)File:            $RCSfile: link.c,v $
@(#)Version:         $Revision: 56.2 $
@(#)Last changed:    $Date: 1997/07/08 21:56:43 $
@(#)Purpose:         Specialized doubly-linked list management routines
@(#)Author:          J Leffler
@(#)Copyright:       (C) Jonathan Leffler 1996,1997
@(#)Product:         $Product: DBD::Sqlflex Version 0.50 (1998-01-15) $
*/

/*TABSTOP=4*/

#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include "Sqlflex.h"

#ifdef DBD_IX_DEBUG_LINK
#define PRINT_LIST(s, x)	print_list(s, x)
#define PRINT_LINK(s, x)	print_link(s, x)
#else
#define PRINT_LIST(s, x)	/* As nothing */
#define PRINT_LINK(s, x)	/* As nothing */
#endif /* DBD_IX_DEBUG_LINK */

#ifndef lint
static const char rcs[] = "@(#)$Id: link.c,v 56.2 1997/07/08 21:56:43 johnl Exp $";
#endif

#ifdef DBD_IX_DEBUG_LINK
typedef unsigned long Ulong;
static void	print_link(const char *s, Link *x)
{
	fprintf(stderr, "%s: link 0x%08X, data 0x%08X, next 0x%08X, prev 0x%08X\n",
			s, (Ulong)x, (Ulong)x->data, (Ulong)x->next, (Ulong)x->prev);
}

static void	print_list(const char *s, Link *x)
{
	Link *y;
	fprintf(stderr, "-BEGIN- %s:\n", s);
	print_link("Start link", x);
	y = x;
	while ((y = y->next) != x)
	{
		print_link("Chain link", y);
	}
	fprintf(stderr, "--END-- %s:\n", s);
}
#endif /* DBD_IX_DEBUG_LINK */

/* Initialize the head link of a list */
void new_headlink(Link *link)
{
	link->next = link;
	link->prev = link;
	link->data = 0;
	PRINT_LIST("new_headlink", link);
}

/* Delete the link from the list and cleanup the data */
void delete_link(Link *link_d, void (*function)(void *))
{
	Link	*link_1;
	Link	*link_2;

	link_1 = link_d->prev;
	link_2 = link_d->next;
	PRINT_LINK("delete_link:delete", link_d);
	PRINT_LIST("delete_link:before", link_d);
	link_1->next = link_2;
	link_2->prev = link_1;
	PRINT_LIST("delete_link:after", link_2);
	link_d->next = link_d->prev = link_d;
	(*function)(link_d->data);
}

void destroy_chain(Link *head, void (*function)(void *))
{
	/* Delete all links */
	dbd_ix_debug(1, "%s::destroy_chain()\n", "DBD::Sqlflex");
	PRINT_LIST("destroy_chain:before", head);
	while (head->next->data != 0)
		delete_link(head->next, function);
	PRINT_LIST("destroy_chain:after", head);
}

/* Add the link (link_n) after a pre-existing link in a list (link_1) */
void add_link(Link *link_1, Link *link_n)
{
	Link	*link_2 = link_1->next;

	PRINT_LINK("add_link:insert", link_n);
	PRINT_LIST("add_link:before", link_1);
	assert(link_2->prev == link_1);
	link_n->next = link_2;
	link_n->prev = link_1;
	link_1->next = link_n;
	link_2->prev = link_n;
	PRINT_LIST("add_link:after", link_1);
}

