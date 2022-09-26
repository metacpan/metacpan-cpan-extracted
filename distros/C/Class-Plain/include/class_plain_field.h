#ifndef CLASS_PLAIN_FIELD_H
#define CLASS_PLAIN_FIELD_H

typedef struct FieldMeta FieldMeta;

#include "class_plain_class.h"

struct FieldMeta {
  SV *name;
  ClassMeta *class;
};

/* Field API */
FieldMeta *ClassPlain_create_field(pTHX_ SV *field_name, ClassMeta *class_meta);

void ClassPlain_field_apply_attribute(pTHX_ FieldMeta *fieldmeta, const char *name, SV *value);

#endif
