#ifndef CLASS_PLAIN_METHOD_H
#define CLASS_PLAIN_METHOD_H

typedef struct MethodMeta MethodMeta;
typedef void MethodAttributeHandler(pTHX_ MethodMeta *meta, const char *value, void *data);

struct MethodMeta {
  SV *name;
  ClassMeta *class;
  /* We don't store the method body CV; leave that in the class stash */
  unsigned int is_common : 1;
};

struct MethodAttributeDefinition {
  char *attrname;
  /* TODO: int flags */
  MethodAttributeHandler *apply;
  void *applydata;
};

#endif
