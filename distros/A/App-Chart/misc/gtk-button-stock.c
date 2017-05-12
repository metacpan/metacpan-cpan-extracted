/*
  Copyright 2010, 2016 Kevin Ryde

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
#include <stdlib.h>
#include <gtk-2.0/gtk/gtk.h>

void
do_destroy (GtkWidget *toplevel)
{
  printf ("toplevel destroy, call gtk_main_quit\n");
  gtk_main_quit();
}

int
main (int argc, char **argv)
{
  gtk_init (&argc, &argv);

  GtkWidget *toplevel = gtk_window_new (GTK_WINDOW_TOPLEVEL);
  g_signal_connect (G_OBJECT(toplevel), "destroy",
                    (GCallback) &do_destroy, NULL);

  GtkWidget *button = g_object_new (GTK_TYPE_BUTTON,
                                    "label",     "gtk-go-back",
                                    "use-stock", 1);
  gtk_container_add (GTK_CONTAINER(toplevel), button);

  gtk_widget_show_all (toplevel);
  printf ("main loop runs ... press the window manager 'delete-event'\n");
  gtk_main ();

  return 0;
}
