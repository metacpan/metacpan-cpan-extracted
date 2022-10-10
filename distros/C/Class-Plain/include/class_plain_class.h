#ifndef CLASS_PLAIN_CLASS_H
#define CLASS_PLAIN_CLASS_H

typedef struct ClassMeta ClassMeta;
typedef struct ClassAttributeRegistration ClassAttributeRegistration;

#include "class_plain_method.h"
#include "class_plain_field.h"

struct ClassMeta {
  SV* name;
  AV* fields;
  AV* methods;
  IV isa_empty;
  IV is_role;
  AV* role_names;
};

ClassMeta *ClassPlain_create_class(pTHX_ IV type, SV* name);

void ClassPlain_class_apply_attribute(pTHX_ ClassMeta* class, const char* name, SV *value);

void ClassPlain_add_role_name(pTHX_ ClassMeta* class, SV* role_name);

void ClassPlain_begin_class_block(pTHX_ ClassMeta* class);

MethodMeta* ClassPlain_class_add_method(pTHX_ ClassMeta* class, SV* method_name);

FieldMeta* ClassPlain_class_add_field(pTHX_ ClassMeta* class, SV* field_name);


#endif
