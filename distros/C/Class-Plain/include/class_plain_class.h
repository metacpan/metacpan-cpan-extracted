#ifndef CLASS_PLAIN_CLASS_H
#define CLASS_PLAIN_CLASS_H

typedef struct ClassMeta ClassMeta;
typedef struct ClassAttributeRegistration ClassAttributeRegistration;

#include "class_plain_method.h"
#include "class_plain_field.h"

/* Metadata about a class */
struct ClassMeta {
  SV *name;
  AV *fields;   /* each elem is a raw pointer directly to a FieldMeta */
  AV *methods;  /* each elem is a raw pointer directly to a MethodMeta */
  IV isa_empty;
};

/* Class API */
ClassMeta *ClassPlain_create_class(pTHX_ IV type, SV *name);

void ClassPlain_class_apply_attribute(pTHX_ ClassMeta *class_meta, const char *name, SV *value);

void ClassPlain_begin_class_block(pTHX_ ClassMeta *meta);

MethodMeta *ClassPlain_class_add_method(pTHX_ ClassMeta *meta, SV *methodname);

FieldMeta *ClassPlain_class_add_field(pTHX_ ClassMeta *meta, SV *fieldname);


#endif
