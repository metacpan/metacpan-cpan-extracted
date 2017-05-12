/* Be::Attribute */
/* Copyright 1999 Tom Spindler */
/* This file is covered by the Artistic License. */
/* $Id: attribute.xs,v 1.2 1999/04/29 18:46:35 dogcow Exp dogcow $ */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <errno.h>
#include <string.h>
#include <be/storage/Node.h>

/* See http://www.be.com/documentation/be_book/The%20Storage%20Kit/Node.html
   for more info on how the node stuff works. */

MODULE = Be::Attribute          PACKAGE = Be::Attribute

PROTOTYPES: ENABLE

SV *
GetBNode(filename)
        char * filename;
ALIAS:
	Be::Attribute::GetBNode = 0
	Be::Attribute::GetNode = 1
PREINIT:
        BNode *node = NULL;
CODE:

	/* stuff BNode object ptr in IV */

        node = new BNode((const char *) filename);
        if (node && node->InitCheck() == B_OK) {
          node->SetTo((const char *) filename);
          RETVAL = newSViv((IV) node);
        } else {
	  XSRETURN_UNDEF;
	}
OUTPUT:
        RETVAL


SV *
CloseNode(node)
        long node;
CODE:
	/* destroy BNode object */

        ((BNode *) node)->~BNode();
        RETVAL = newSViv(1);
OUTPUT:
        RETVAL



SV *
SetBNode(node, filename)
	long node;
	char *filename;
PREINIT:
	status_t err;
CODE:
	/* reset BNode filename */

	err = ((BNode *) node)->SetTo((const char *) filename);
	RETVAL = newSViv(err == B_OK);
OUTPUT:
	RETVAL



void
ListAttrs(node)
        long node;
PREINIT:
        char buf[B_ATTR_NAME_LENGTH];
        status_t err;
PPCODE:
	/* list what attrs BNode finds */

        while ((err = ((BNode *) node)->GetNextAttrName(buf)) == B_OK) {
                XPUSHs(sv_2mortal(newSVpv(buf, strlen(buf))));
        }



SV *
ReadAttr(node, attr)
        long node;
        char *attr;
PREINIT:
        char buf[B_ATTR_NAME_LENGTH];
        char *name;
        STRLEN len;
        ssize_t err;
CODE:
	/* get attr value */

        err = ((BNode *) node)->ReadAttr((const char *) attr, (type_code) 0,
          (off_t) 0, (void *) buf, B_ATTR_NAME_LENGTH);
        if (err != 0) {
          RETVAL = newSVpv(buf, strlen(buf));
        } else {
          XSRETURN_UNDEF;
        }
OUTPUT:
        RETVAL

	   

SV *
WriteAttr(node, attr, what, type, howbig)
        long node;
        char *attr;
        char *what;
        int type;
        int howbig;
PREINIT:
        char buf[B_ATTR_NAME_LENGTH];
        char *name, *whatstr;
        ssize_t err;
        size_t buflen;
CODE:

	/* I haven't tested this at all. That's why I'm not documenting
	   it. :) */

        err = ((BNode *)node)->WriteAttr((const char *) attr,
               (type_code) type, (off_t) 0, (void *) what, howbig);
        if (err != 0) {
          RETVAL = newSViv(1);
        } else {
/*        whatstr = strerror(errno); */
          RETVAL = newSVpv(whatstr, strlen(whatstr));
	}
OUTPUT:
	RETVAL


