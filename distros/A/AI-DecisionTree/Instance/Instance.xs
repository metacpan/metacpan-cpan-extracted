#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

typedef struct {
  char *name;
  int result;
  int num_values;
  int *values;
} Instance;

MODULE = AI::DecisionTree::Instance         PACKAGE = AI::DecisionTree::Instance

PROTOTYPES: DISABLE

Instance *
new (class, values_ref, result, name)
    char * class
    SV *   values_ref
    int    result
    char * name
  CODE:
    {
      int i;
      Instance* instance;
      AV* values = (AV*) SvRV(values_ref);
      New(0, instance, 1, Instance);
    
      instance->name   = savepv(name);
      instance->result = result;
      instance->num_values = 1 + av_len(values);
      New(0, instance->values, instance->num_values, int);
    
      for(i=0; i<instance->num_values; i++) {
        instance->values[i] = (int) SvIV( *av_fetch(values, i, 0) );
      }
    
      RETVAL = instance;
    }
  OUTPUT:
    RETVAL

char *
name (instance)
    Instance*   instance
  CODE:
    {
      RETVAL = instance->name;
    }
  OUTPUT:
    RETVAL

void
set_result (instance, result)
    Instance*   instance
    int         result
  CODE:
    {
      instance->result = result;
    }

void
set_value (instance, attribute, value)
    Instance*   instance
    int         attribute
    int         value
  PPCODE:
    {
      int *new_values;
      int i;
    
      if (attribute >= instance->num_values) {
        if (!value) return; /* Nothing to do */
        
        printf("Expanding from %d to %d places\n", instance->num_values, attribute);
	Renew(instance->values, attribute, int);
        if (!instance->values)
          croak("Couldn't grab new memory to expand instance");
        
        for (i=instance->num_values; i<attribute-1; i++)
          instance->values[i] = 0;
        instance->num_values = 1 + attribute;
      }
    
      instance->values[attribute] = value;
    }

int
value_int (instance, attribute)
    Instance *  instance
    int         attribute
  CODE:
    {
      if (attribute >= instance->num_values) {
        RETVAL = 0;
      }
      else {
        RETVAL = instance->values[attribute];
      }
    }
  OUTPUT:
    RETVAL

int
result_int (instance)
    Instance *  instance
  CODE:
    {
      RETVAL = instance->result;
    }
  OUTPUT:
    RETVAL

void
DESTROY (instance)
    Instance *  instance
  PPCODE:
    {
      Safefree(instance->name);
      Safefree(instance->values);
      Safefree(instance);
    }

int
tally (pkg, instances_r, tallies_r, totals_r, attr)
    char * pkg
    SV *   instances_r
    SV *   tallies_r
    SV *   totals_r
    int    attr
  CODE:
    {
      AV *instances = (AV*) SvRV(instances_r);
      HV *tallies   = (HV*) SvRV(tallies_r);
      HV *totals    = (HV*) SvRV(totals_r);
      I32 top = av_len(instances);
      int num_undef = 0;
      
      I32 i, v;
      SV **instance_r, **hash_entry, **sub_hash_entry;
      Instance *instance;
      
      for (i=0; i<=top; i++) {
	instance_r = av_fetch(instances, i, 0);
	instance = (Instance *) SvIV(SvRV(*instance_r));
        v = attr < instance->num_values ? instance->values[attr] : 0;
	/* if (!v) { num_undef++; continue; } */
	
	/* $totals{$v}++ */
	hash_entry = hv_fetch(totals, (char *)&v, sizeof(I32), 1);
	if (!SvIOK(*hash_entry)) sv_setiv(*hash_entry, 0);
	sv_setiv( *hash_entry, 1+SvIV(*hash_entry) );
	
	/* $tallies{$v}{$_->result_int}++ */
	hash_entry = hv_fetch(tallies, (char *)&v, sizeof(I32), 0);
	
	if (!hash_entry) {
	  hash_entry = hv_store(tallies, (char *)&v, sizeof(I32), newRV_noinc((SV*) newHV()), 0);
	}
	
	sub_hash_entry = hv_fetch((HV*) SvRV(*hash_entry), (char *)&(instance->result), sizeof(int), 1);
	if (!SvIOK(*sub_hash_entry)) sv_setiv(*sub_hash_entry, 0);
	sv_setiv( *sub_hash_entry, 1+SvIV(*sub_hash_entry) );
      }

      RETVAL = num_undef;

	/*  Old code:
      foreach (@$instances) {
	my $v = $_->value_int($all_attr->{$attr});
	next unless $v;
	$totals{ $v }++;
	$tallies{ $v }{ $_->result_int }++;
      }
	*/
    }
  OUTPUT:
    RETVAL
