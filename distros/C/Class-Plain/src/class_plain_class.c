/* vi: set ft=xs : */
#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "class_plain_class.h"
#include "class_plain_field.h"
#include "class_plain_method.h"

#include "perl-backcompat.c.inc"

ClassMeta *ClassPlain_create_class(pTHX_ IV type, SV* name) {
  ClassMeta *class;
  Newxz(class, 1, ClassMeta);

  class->name = SvREFCNT_inc(name);

  class->role_names = newAV();
  class->fields = newAV();
  class->methods = newAV();

  return class;
}

void ClassPlain_class_apply_attribute(pTHX_ ClassMeta *class, const char *name, SV* value) {
  if(value && (!SvPOK(value) || !SvCUR(value))) {
    value = NULL;
  }
  
  // The isa attribute
  if (strcmp(name, "isa") == 0) {
    SV* super_class_name = value;
    
    if (value) {
      HV *superstash = gv_stashsv(super_class_name, 0);
      
      IV is_load_module;
      if (superstash) {
        // The new method
        SV** new_method = hv_fetchs(superstash, "new", 0);
        
        // The length of the classes in @ISA
        SV* super_class_isa_name = newSVpvf("%" SVf "::ISA", super_class_name);
        SAVEFREESV(super_class_isa_name);
        AV* super_class_isa = get_av(SvPV_nolen(super_class_isa_name), GV_ADD | (SvFLAGS(super_class_isa_name) & SVf_UTF8));
        IV super_class_isa_classes_length = av_count(super_class_isa);
        
        if (new_method) {
          is_load_module = 0;
        }
        else if (super_class_isa_classes_length > 0) {
          is_load_module = 0;
        }
        else {
          is_load_module = 1;
        }
      }
      else {
        is_load_module = 1;
      }
      
      // Original logic: if(!superstash || !hv_fetchs(superstash, "new", 0)) {
      if(is_load_module) {
        /* Try to `require` the module then attempt a second time */
        /* load_module() will modify the name argument and take ownership of it */
        load_module(PERL_LOADMOD_NOIMPORT, newSVsv(super_class_name), NULL, NULL);
        superstash = gv_stashsv(super_class_name, 0);
      }

      if(!superstash)
        croak("Superclass %" SVf " does not exist", super_class_name);

      // Push the super class to @ISA
      {
        SV* isa_name = newSVpvf("%" SVf "::ISA", class->name);
        SAVEFREESV(isa_name);
        AV *isa = get_av(SvPV_nolen(isa_name), GV_ADD | (SvFLAGS(isa_name) & SVf_UTF8));
        av_push(isa, SvREFCNT_inc(super_class_name));
      }
    }
    else {
      class->isa_empty = 1;
    }
    
  }
  // The does attribute
  else if (strcmp(name, "does") == 0) {
    SV* role_name = value;
    ClassPlain_add_role_name(aTHX_ class, role_name);
  }
  else {
    croak("Unrecognised class attribute :%s", name);
  }
}

void ClassPlain_add_role_name(pTHX_ ClassMeta* class, SV* role_name) {
  AV *role_names = class->role_names;
  
  if (role_name) {
    av_push(role_names, SvREFCNT_inc(role_name));
  }
}

void ClassPlain_begin_class_block(pTHX_ ClassMeta* class) {
  SV* isa_name = newSVpvf("%" SVf "::ISA", class->name);
  SAVEFREESV(isa_name);
  AV *isa = get_av(SvPV_nolen(isa_name), GV_ADD | (SvFLAGS(isa_name) & SVf_UTF8));
  
  if (!class->isa_empty) {
    if(!av_count(isa)) {
      av_push(isa, newSVpvs("Class::Plain::Base"));
    }
  }

  if (class->is_role) {
    // The source code of Role::Tiny->import
    SV* sv_source_code = sv_2mortal(newSVpv("", 0));
    sv_catpv(sv_source_code, "{\n");
    sv_catpv(sv_source_code, "  package ");
    sv_catpv(sv_source_code, SvPV_nolen(class->name));
    sv_catpv(sv_source_code, ";\n");
    sv_catpv(sv_source_code, "  Role::Tiny->import;\n");
    sv_catpv(sv_source_code, "}\n");
    
    // Role::Tiny->import
    Perl_eval_pv(aTHX_ SvPV_nolen(sv_source_code), 1);
  }
}

MethodMeta* ClassPlain_class_add_method(pTHX_ ClassMeta* class, SV* method_name) {
  AV *methods = class->methods;

  if(!method_name || !SvOK(method_name) || !SvCUR(method_name))
    croak("method_name must not be undefined or empty");

  MethodMeta* method;
  Newx(method, 1, MethodMeta);

  method->name = SvREFCNT_inc(method_name);
  method->class = class;

  av_push(methods, (SV*)method);
  
  return method;
}

FieldMeta* ClassPlain_class_add_field(pTHX_ ClassMeta* class, SV* field_name) {
  AV *fields = class->fields;

  if(!field_name || !SvOK(field_name) || !SvCUR(field_name))
    croak("field_name must not be undefined or empty");

  U32 i;
  for(i = 0; i < av_count(fields); i++) {
    FieldMeta* field = (FieldMeta* )AvARRAY(fields)[i];
    if(SvCUR(field->name) < 2)
      continue;

    if(sv_eq(field->name, field_name))
      croak("Cannot add another field named %" SVf, field_name);
  }

  FieldMeta* field = ClassPlain_create_field(aTHX_ field_name, class);

  av_push(fields, (SV*)field);

  return field;
}
