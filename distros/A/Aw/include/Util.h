/* This is part of the Aw:: Perl module.  A Perl interface to the ActiveWorks(tm) 
   libraries.  Copyright (C) 1999-2001 Daniel Yacob.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; if not, write to the Free
   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/

#ifndef UTIL_H
#define UTIL_H 1

#ifdef AWXS_WARNS
char * setErrMsg ( char ** gErrMsg, int count, ... );
#endif /* AWXS_WARNS */

char * stradd ( char* stringA, char* stringB );

#endif /* UTIL_H */
