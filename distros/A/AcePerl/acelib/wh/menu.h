/*  Last edited: Aug 19 09:44 1998 (rd) */

/* $Id: menu.h,v 1.1 2002/11/14 20:00:06 lstein Exp $ */

#ifndef DEF_MENU_H
#define DEF_MENU_H

#include "regular.h"

/************* types *****************/

#ifndef MENU_DEFINED
#define MENU_DEFINED
typedef void *MENU, *MENUITEM ;	/* public handles */
typedef void (*MENUFUNCTION)(MENUITEM) ;
#endif

typedef struct menuspec
  { MENUFUNCTION f ;	/* NB can be 0 if using menuSetCall() below */
    char *text ;
  } MENUSPEC ;

/********** MENUITEM flags ***********/

#define MENUFLAG_DISABLED	0x01
#define MENUFLAG_TOGGLE		0x02
#define MENUFLAG_TOGGLE_STATE	0x04
#define MENUFLAG_START_RADIO	0x08
#define MENUFLAG_END_RADIO	0x10
#define MENUFLAG_RADIO_STATE	0x20
#define MENUFLAG_SPACER		0x40
#define MENUFLAG_HIDE		0x80

/************* functions *************/

MENU menuCreate (char *title) ;
	/* makes a blank menu */
MENU menuInitialise (char *title, MENUSPEC *spec) ;
	/* makes a simple menu from a spec terminated with label = 0 */
	/* if called on same spec, give existing menu */
MENU menuCopy (MENU menu) ;
	/* a copy that you can then vary */
void menuDestroy (MENU menu) ;
	/* also destroys items */

MENUITEM menuCreateItem (char *label, MENUFUNCTION func) ;
MENUITEM menuItem (MENU menu, char *label) ;  
	/* find item from label */
BOOL menuAddItem (MENU menu, MENUITEM item, char *beforeLabel) ;
	/* add an item; if before == 0 then add at end */
BOOL menuDeleteItem (MENU menu, char *label) ; 
	/* also destroys item */
BOOL menuSelectItem (MENUITEM item) ;
        /* triggers a call back and adjusts toggle/radio states */
        /* returns true if states changed - mostly for graph library to use */

	/* calls to set properties of items */
	/* can use by name e.g. menuSetValue (menuItem (menu, "Frame 3"), 3) */
BOOL menuSetCall (MENUITEM item, char *callName) ;
BOOL menuSetFunc (MENUITEM item, MENUFUNCTION func) ;
BOOL menuSetFlags (MENUITEM item, unsigned int flags) ;
BOOL menuUnsetFlags (MENUITEM item, unsigned int flags) ;
BOOL menuSetValue (MENUITEM item, int value) ;
BOOL menuSetPtr (MENUITEM item, void *ptr) ;
BOOL menuSetMenu (MENUITEM item, MENU menu) ; /* pulldown for boxes */
	/* and to get properties */
unsigned int	menuGetFlags (MENUITEM item) ;
int	        menuGetValue (MENUITEM item) ;
void*		menuGetPtr (MENUITEM item) ;

	/* extra routines */

void menuSuppress (MENU menu, char *string) ; /* HIDE block */
void menuRestore (MENU menu, char *string) ; /* reverse of Suppress */

void menuSpacer (void) ; /* dummy routine for spaces in opt menus */

#endif /* DEF_MENU_H */
