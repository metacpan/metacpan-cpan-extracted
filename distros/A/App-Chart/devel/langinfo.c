/* Copyright 2009, 2016 Kevin Ryde

   This file is part of Chart.

   Chart is free software; you can redistribute it and/or modify it under
   the terms of the GNU General Public License as published by the Free
   Software Foundation; either version 3, or (at your option) any later
   version.

   Chart is distributed in the hope that it will be useful, but WITHOUT ANY
   WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
   FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
   details.

   You should have received a copy of the GNU General Public License
   along with Chart.  If not, see <http://www.gnu.org/licenses/>.
*/

#define _GNU_SOURCE

#include <nl_types.h>
#include <langinfo.h>
#include <locale.h>
#include <stdio.h>

int
main (void)
{
  nl_item key;
  char *p, *l;
  int i, n;

  key = ERA;
  key = ALT_DIGITS;
  
  putenv ("LANGUAGE=ja_JP");
  putenv ("LANG=ja_JP");
  l = setlocale (LC_ALL, "");
  printf ("locale \"%s\"\n", l);

  p = nl_langinfo (key);
  printf ("key %#X %p '%s'\n", key, p, p);

  for (n = 0; ; n++) {
    int len = strlen(p);
    if (len == 0) break;

    printf ("  %d %p '%s'", n, p, p);
    for (i = 0; i < len; i++) {
      printf (" %02X", (int) (unsigned char) p[i]);
    }
    printf ("\n");
    p += len+1;
  }
  return 0;
}
