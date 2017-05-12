#define TRC if(0)
#define TRC0 if(0)
#define TRACE(X) TRC _trace(X)

typedef struct stag {
  GQuark nameq;
  void *data;
  /*  s_list *kids; */
  gboolean isterminal;
  GHashTable *kidhash;
} stag;


stag* stag_new();
G_CONST_RETURN gchar* stag_name(stag*, gchar*);
G_CONST_RETURN gchar* stag_getname(stag*);

