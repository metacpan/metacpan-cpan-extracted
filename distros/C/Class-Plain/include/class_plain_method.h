#ifndef CLASS_PLAIN_METHOD_H
#define CLASS_PLAIN_METHOD_H

typedef struct MethodMeta MethodMeta;
typedef void MethodAttributeHandler(pTHX_ MethodMeta *meta, const char *value, void *data);

struct MethodMeta {
  SV *name;
  ClassMeta *class;
  int8_t is_common;
  int8_t is_required;
};

struct MethodAttributeDefinition {
  char *attrname;
  /* TODO: int flags */
  MethodAttributeHandler *apply;
  void *applydata;
};

#endif
