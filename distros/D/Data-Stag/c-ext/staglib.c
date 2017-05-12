
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdarg.h>
#include <math.h>                                                             
#include <glib.h>
#include "staglib.h"

#define q2s g_quark_to_string
#define s2q g_quark_from_string

void* stag_throw(gchar *msg) {
  printf "EXCEPTION:%s\n", msg);
}

stag* stag_new() {
    stag *stag = g_malloc(sizeof(stag));
    stag->nameq = s2q("");
    stag->data = g_slist_alloc();
    stag->isterminal = FALSE;
    return stag;
}

G_CONST_RETURN gchar* stag_name(stag *node, gchar *name) {
  GQuark q;
  if (name != NULL) {
    node->nameq = s2q(name);
  }

  q = node->nameq;
  return g_quark_to_string(q);
}

G_CONST_RETURN gchar* stag_getname(stag *node) {
  return q2s(node->nameq);
}

char* stag_data(stag *node, void *data, gboolean isterminal) {
  if (data != NULL) {
    node->data = data;
    node->isterminal = isterminal;
  }
  return node->data;
}

GSList* stag_kids(stag *node) {
  if (node->isterminal) {
    stag_throw(stag, "terminal");
  }
  return (GSList*)node->data;
}

/*

GSList* stag_findnode(stag *node, 
                     gchar *name, 
                     stag *replacement_node) {

  int i;
  GQuark nameq = s2q(name);
  GSList* matchlist = g_slist_alloc();

  if (node->nameq == nameq) {
    g_slist_append(matchlist, node);
  }
  else if (node->isterminal) {
    return;
  }
  else {
    for (i=0; i < g_slist_length_foreach(node->data); i++) {
      stag* subnode = (stag*)g_slist_nth(node->data, i);
      GSList* sublist = stag_findnode(subnode, name, replacement_node);
      g_slist_concat(matchlist, sublist);
    }
  }
  return matchlist;
}
*/
