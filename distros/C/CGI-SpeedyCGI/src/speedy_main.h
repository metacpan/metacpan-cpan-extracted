/*
 * Copyright (C) 2003  Sam Horrocks
 * 
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 *
 */

/* 
 * Glue
 */

#define speedy_memcpy(d,s,n)	memcpy(d,s,n)
#define speedy_memmove(d,s,n)	memmove(d,s,n)
#define speedy_bzero(s,n)	memset(s,'\0',n)
#define speedy_free(s)		free(s)
#define speedy_new(s,n,t)	\
    do { (s) = (t*)malloc((n)*sizeof(t)); } while (0)
#define speedy_renew(s,n,t)	\
    do {(s) = (t*)realloc((s),(n)*sizeof(t));} while (0)
#define speedy_execvp(f,a)	execvp(f,(char * const *)a)

void speedy_abort(const char *s);
