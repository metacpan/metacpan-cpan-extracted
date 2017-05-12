/*
 * @(#)$Id: link.h,v 2003.1 2003/01/14 23:52:40 jleffler Exp $
 *
 * Copyright 1998    Jonathan Leffler
 * Copyright 2002-03 IBM
 *
 * You may distribute under the terms of either the GNU General Public
 * License or the Artistic License, as specified in the Perl README file.
 */

#ifndef LINK_H
#define LINK_H

/* Doubly linked list for tracking connections and statements */
typedef struct Link Link;

struct Link
{
	Link	*next;
	Link	*prev;
	void	*data;
};

extern void dbd_ix_link_add(Link *link_1, Link *link_n);
extern void dbd_ix_link_delete(Link *link_d, void (*function)(void *));
extern void dbd_ix_link_delchain(Link *head, void (*function)(void *));
extern void dbd_ix_link_newhead(Link *link);

#endif	/* LINK_H */
