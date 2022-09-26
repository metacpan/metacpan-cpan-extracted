/* vi: set ft=xs : */
#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "class_plain_class.h"
#include "class_plain_field.h"
#include "class_plain_method.h"

#include "perl-backcompat.c.inc"

void ClassPlain_class_apply_attribute(pTHX_ ClassMeta *class_meta, const char *name, SV *value)
{
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
        SV *isa_name = newSVpvf("%" SVf "::ISA", class_meta->name);
        SAVEFREESV(isa_name);
        AV *isa = get_av(SvPV_nolen(isa_name), GV_ADD | (SvFLAGS(isa_name) & SVf_UTF8));
        av_push(isa, SvREFCNT_inc(super_class_name));
      }
    }
    else {
      class_meta->isa_empty = 1;
    }
    
  }
  else {
    croak("Unrecognised class attribute :%s", name);
  }
}

MethodMeta *ClassPlain_class_add_method(pTHX_ ClassMeta *meta, SV *methodname)
{
  AV *methods = meta->methods;

  if(!methodname || !SvOK(methodname) || !SvCUR(methodname))
    croak("methodname must not be undefined or empty");

  MethodMeta *methodmeta;
  Newx(methodmeta, 1, MethodMeta);

  methodmeta->name = SvREFCNT_inc(methodname);
  methodmeta->class = meta;

  av_push(methods, (SV *)methodmeta);

  return methodmeta;
}

FieldMeta *ClassPlain_class_add_field(pTHX_ ClassMeta *meta, SV *field_name)
{
  AV *fields = meta->fields;

  if(!field_name || !SvOK(field_name) || !SvCUR(field_name))
    croak("field_name must not be undefined or empty");

  U32 i;
  for(i = 0; i < av_count(fields); i++) {
    FieldMeta *fieldmeta = (FieldMeta *)AvARRAY(fields)[i];
    if(SvCUR(fieldmeta->name) < 2)
      continue;

    if(sv_eq(fieldmeta->name, field_name))
      croak("Cannot add another field named %" SVf, field_name);
  }

  FieldMeta *fieldmeta = ClassPlain_create_field(aTHX_ field_name, meta);

  av_push(fields, (SV *)fieldmeta);

  return fieldmeta;
}

ClassMeta *ClassPlain_create_class(pTHX_ IV type, SV *name)
{
  ClassMeta *meta;
  Newx(meta, 1, ClassMeta);

  meta->name = SvREFCNT_inc(name);

  meta->fields = newAV();
  meta->methods = newAV();
  meta->isa_empty = 0;

  return meta;
}

void ClassPlain_begin_class_block(pTHX_ ClassMeta *meta)
{
  SV *isa_name = newSVpvf("%" SVf "::ISA", meta->name);
  SAVEFREESV(isa_name);
  AV *isa = get_av(SvPV_nolen(isa_name), GV_ADD | (SvFLAGS(isa_name) & SVf_UTF8));
  
  if (!meta->isa_empty) {
    if(!av_count(isa)) {
      av_push(isa, newSVpvs("Class::Plain::Base"));
    }
  }
}
