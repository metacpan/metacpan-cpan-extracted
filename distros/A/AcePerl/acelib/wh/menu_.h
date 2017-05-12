/*  File: menu_.h
 *  Author: Richard Durbin (rd@sanger.ac.uk)
 *  Copyright (C) J Thierry-Mieg and R Durbin, 1995
 *-------------------------------------------------------------------
 * This file is part of the ACEDB genome database package, written by
 * 	Richard Durbin (MRC LMB, UK) rd@mrc-lmb.cam.ac.uk, and
 *	Jean Thierry-Mieg (CRBM du CNRS, France) mieg@kaa.cnrs-mop.fr
 *
 * Description: private header for menu package with full structures
 * Exported functions:
 * HISTORY:
 * Last edited: Jan 14 15:01 1995 (rd)
 * Created: Mon Jan  9 22:54:36 1995 (rd)
 *-------------------------------------------------------------------
 */

/* $Id: menu_.h,v 1.1 2002/11/14 20:00:06 lstein Exp $ */

#ifndef DEF_MENU_H

typedef struct MenuStruct *MENU ;
typedef struct MenuItemStruct *MENUITEM ;
typedef void (*MENUFUNCTION)(MENUITEM) ;
#define MENU_DEFINED

struct MenuItemStruct {
  char*		label ;
  MENUFUNCTION	func ;
  unsigned int	flags ;
  char*		call ;
  int		value ;
  void*		ptr ;
  MENU		submenu ;
  MENUITEM	up, down ;
} ;

struct MenuStruct {
  char *title ;
  MENUITEM items ;
} ;

#include "menu.h"

#endif /* DEF_MENU_H */
 
