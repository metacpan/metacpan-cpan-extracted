/* vi: set ft=xs : */
#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "class_plain_class.h"
#include "class_plain_field.h"

void ClassPlain_need_PLparser(pTHX);

FieldMeta *ClassPlain_create_field(pTHX_ SV *field_name, ClassMeta *class_meta)
{
  FieldMeta *fieldmeta;
  Newx(fieldmeta, 1, FieldMeta);

  fieldmeta->name = SvREFCNT_inc(field_name);
  fieldmeta->class = class_meta;

  return fieldmeta;
}

void ClassPlain_field_apply_attribute(pTHX_ FieldMeta *fieldmeta, const char *name, SV *value)
{
  if(value && (!SvPOK(value) || !SvCUR(value))) {
    value = NULL;
  }
  
  {
    ENTER;
    
    // The reader
    if (strcmp(name, "reader") == 0) {
      // The reader code
      SV* sv_reader_code = sv_2mortal(newSVpv("", 0));
      sv_catpv(sv_reader_code, "sub ");
      sv_catpv(sv_reader_code, SvPV_nolen(fieldmeta->class->name));
      sv_catpv(sv_reader_code, "::");
      if (value) {
        sv_catpv(sv_reader_code, SvPV_nolen(value));
      }
      else {
        sv_catpv(sv_reader_code, SvPV_nolen(fieldmeta->name));
      }
      sv_catpv(sv_reader_code,  " {\n  my $self = shift;\n  $self->{");
      sv_catpv(sv_reader_code, SvPV_nolen(fieldmeta->name));
      sv_catpv(sv_reader_code, "};\n}");
      
      // Generate the reader
      Perl_eval_pv(aTHX_ SvPV_nolen(sv_reader_code), 1);
    }
    // The writer
    else if (strcmp(name, "writer") == 0) {
      // The writer code
      SV* sv_writer_code = sv_2mortal(newSVpv("", 0));
      sv_catpv(sv_writer_code, "sub ");
      sv_catpv(sv_writer_code, SvPV_nolen(fieldmeta->class->name));
      sv_catpv(sv_writer_code, "::");
      if (value) {
        sv_catpv(sv_writer_code, SvPV_nolen(value));
      }
      else {
        sv_catpv(sv_writer_code, "set_");
        sv_catpv(sv_writer_code, SvPV_nolen(fieldmeta->name));
      }
      sv_catpv(sv_writer_code,  " {\n  my $self = shift;\n  $self->{");
      sv_catpv(sv_writer_code, SvPV_nolen(fieldmeta->name));
      sv_catpv(sv_writer_code, "} = shift;\n  return $self;\n}");
      
      // Generate the writer
      Perl_eval_pv(aTHX_ SvPV_nolen(sv_writer_code), 1);
    }
    // The read-write accessor
    else if (strcmp(name, "rw") == 0) {
      // The rw code
      SV* sv_rw_code = sv_2mortal(newSVpv("", 0));
      sv_catpv(sv_rw_code, "sub ");
      sv_catpv(sv_rw_code, SvPV_nolen(fieldmeta->class->name));
      sv_catpv(sv_rw_code, "::");
      if (value) {
        sv_catpv(sv_rw_code, SvPV_nolen(value));
      }
      else {
        sv_catpv(sv_rw_code, SvPV_nolen(fieldmeta->name));
      }
      sv_catpv(sv_rw_code,  " {\n  my $self = shift;\n  if (@_) {\n  $self->{");
      sv_catpv(sv_rw_code, SvPV_nolen(fieldmeta->name));
      sv_catpv(sv_rw_code, "} = shift;\n  return $self;\n }\n");
      sv_catpv(sv_rw_code,  "$self->{");
      sv_catpv(sv_rw_code, SvPV_nolen(fieldmeta->name));
      sv_catpv(sv_rw_code, "};\n}");
      
      // Generate the rw
      Perl_eval_pv(aTHX_ SvPV_nolen(sv_rw_code), 1);
    }
    
    LEAVE;
  }
}
