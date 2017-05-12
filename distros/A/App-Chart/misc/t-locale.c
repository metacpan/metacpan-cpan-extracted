/*
  Copyright 2008, 2016 Kevin Ryde

  This file is part of Chart.

  Chart is free software; you can redistribute it and/or modify it under the
  terms of the GNU General Public License as published by the Free Software
  Foundation; either version 3, or (at your option) any later version.

  Chart is distributed in the hope that it will be useful, but WITHOUT ANY
  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
  FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
  details.

  You should have received a copy of the GNU General Public License along
  with Chart.  If not, see <http://www.gnu.org/licenses/>.
*/

#include <stdio.h>
#include <locale.h>
int
main (void)
{
  char *l;
  struct lconv* lconv;
  
  l = setlocale (LC_ALL, "");
  printf ("%s\n", l);

  l = setlocale (LC_MONETARY, "");
  printf ("%s\n", l);

  l = setlocale (LC_NUMERIC, "C");
  printf ("%s\n", l);

  lconv = localeconv();
  printf ("dec  '%s'\n", lconv->decimal_point);
  printf ("thou '%s'\n", lconv->thousands_sep);
  return 0;
}
