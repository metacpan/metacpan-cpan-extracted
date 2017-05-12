#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

MODULE = Data::Dump::XML PACKAGE = Data::Dump::XML

void
characters (p, str)
    HV * p
    HV * str
PREINIT:
	SV **  val_p;
	char * val_str;
	char * value;
	SV **  hash_p;
CODE:
{
	val_p = hv_fetch (str, "Data", 4, 0);
	if (val_p) {
		val_str = SvPVX (*val_p);
		while (*val_str) {
			if (!isSPACE (*val_str)) {
				value = val_str;
				break;
			}
			val_str++;
		}
	}
	
	# warn ("strlen is: %d", strlen (value));
	
	if (strlen (value)) {
		hash_p = hv_fetch (p, "char", 4, 0);
		if (hash_p) {
			# warn ("add string %s to string %s", SvPVX (*hash_p), value);
			sv_setpvf (*hash_p, "%s%s", SvPVX (newSVsv (*hash_p)), value);
		}
	}
}


void
ref_info (sv)
    SV *sv
PREINIT:
	char * class;
	char * type;
	unsigned int id;
PPCODE:
{
	EXTEND(SP, 3);
	
	if (SvMAGICAL (sv))
		mg_get (sv);

	//class
	if(!sv_isobject(sv)) {
		PUSHs (&PL_sv_undef);
	} else {
		class = (char*) sv_reftype (SvRV (sv), 1);
		PUSHs (sv_2mortal (newSVpv(class, 0)));
	}
	
	// type and addr 
	if (SvROK(sv)) {
		type = (char*) sv_reftype (SvRV (sv), 0);
		id = PTR2UV (SvRV (sv));
		PUSHs (sv_2mortal (newSVpv (type, 0)));
		PUSHs (sv_2mortal (newSVuv (id)));
		//XPUSHs (sv_2mortal (newSVpv ((char*) sv_reftype (SvRV (sv), 0), 0)));
		//XPUSHs (sv_2mortal (newSVuv (PTR2UV (SvRV (sv)))));
	}
}

void
dump_hashref (self, rval, keys, tag)
		SV * self
		HV * rval
		AV * keys
		SV * tag
	PREINIT:
		int i;
		SV * val;
		char * key;
		SV ** val_p;
		SV ** key_p;
		char key_prefix;
		char * key_name;
		char * ref_type;
		STRLEN len;
		char * key_walk;
		bool key_can_used_as_tag = 1;
	CODE:
		// warn ("key count is: %d\n", keys_len);
		
		for (i = 0; i <= av_len (keys); i++) {
			key_p = av_fetch (keys, i, 0);
			// we always get not empty array of keys
			if (key_p)
				key = SvPV (*key_p, len);
			
			val_p = hv_fetch (rval, key, strlen(key), 0);
			if (val_p)
				val = *val_p;
			
			key_prefix = *key;
			key_name = key;
			
			if (key_prefix == '@' || key_prefix == '#' || key_prefix == '<') {
				key_name = key + 1;
			}
			
			if (SvMAGICAL (val))
				mg_get (val);
			
			if (SvROK (val)) {
				ref_type = (char*) sv_reftype (SvRV (val), 0);
			}
			
			key_walk = key_name;
			
			if (key_walk == NULL || *key_walk == '\0' || !(
				isALPHA (*key_walk) || *key_walk == '_' || *key_walk == ':'
			)) key_can_used_as_tag = 0;
			
			key_walk++;
			
			while (*key_walk != '\0') {
				if (!(
					isALPHA (*key_walk) || isDIGIT (*key_walk) 
					|| *key_walk == '_' || *key_walk == ':'
					|| *key_walk == '-' || *key_walk == '.'
				)) {
					key_can_used_as_tag = 0;
					break;
				}
				key_walk++;
			}
			
			if (!key_can_used_as_tag) {
			//node = tag->addNewChild ('', $self->{hash_element});
			//$node->setAttribute ('name', $key);
			}
			
			// warn ("key %s typed as: %s; can be used as tag %d \n", key_name, ref_type, key_can_used_as_tag);
		}
		
		// warn ("Hello from XS\n");

char *
blessed(sv)
	SV * sv
PROTOTYPE: $
CODE: 
{
	if (SvMAGICAL(sv))
	mg_get(sv);
	if(!(SvROK(sv) && SvOBJECT(SvRV(sv)))) {
		XSRETURN_UNDEF;
	}
	RETVAL = (char*)sv_reftype(SvRV(sv),TRUE);
}
OUTPUT:
	RETVAL

char *
reftype(sv)
	SV * sv
PROTOTYPE: $
CODE: 
{
	if (SvMAGICAL(sv))
		mg_get(sv);
	if(!SvROK(sv)) {
		XSRETURN_UNDEF;
	}
	RETVAL = (char*)sv_reftype(SvRV(sv),FALSE);
}
OUTPUT:
	RETVAL

UV
refaddr(sv)
	SV * sv
PROTOTYPE: $
CODE: 
{
	if (SvMAGICAL(sv))
		mg_get(sv);
	if(!SvROK(sv)) {
		XSRETURN_UNDEF;
	}
	RETVAL = PTR2UV(SvRV(sv));
}
OUTPUT:
	RETVAL

void
key_info (self, hashref, key, val)
		SV * self
		HV * hashref
		SV * key
		SV * val
	PREINIT:
		char * key_str;
		char key_prefix;
		char * key_name;
		char * ref_type;
		char * key_walk;
		bool key_can_be_tag = 1;
		bool namespace = 0;
	PPCODE:
		// warn ("key count is: %d\n", keys_len);
		
		EXTEND(SP, 4);
		
		key_str = SvPVX (key);
		
		key_prefix = *key_str;
		key_name = key_str;
		
		if (key_prefix == '@' || key_prefix == '#' || key_prefix == '<') {
			key_name ++;
			PUSHs (sv_2mortal (newSVpvf ("%c", key_prefix)));
		} else 
			PUSHs (&PL_sv_undef);
		
		// warn ("key is %c %s\n", key_prefix, key_name);
		
		PUSHs (sv_2mortal (newSVpv (key_name, 0)));
		
		if (SvMAGICAL (val))
			mg_get (val);
		
		if (SvROK (val)) {
			ref_type = (char*) sv_reftype (SvRV (val), 0);
			PUSHs (sv_2mortal (newSVpv (ref_type, 0)));
		} else 
			PUSHs (&PL_sv_undef);
		
		key_walk = key_name;
		
		if (key_walk == NULL || *key_walk == '\0' || !(
			isALPHA (*key_walk) || *key_walk == '_' || *key_walk == ':'
		)) key_can_be_tag = 0;
		
		if (*key_walk == ':')
			namespace = 1;
		
		key_walk++;
		
		while (*key_walk != '\0') {
			if (!(
				isALPHA (*key_walk) || isDIGIT (*key_walk) 
				|| *key_walk == '_' || *key_walk == ':'
				|| *key_walk == '-' || *key_walk == '.'
			)) {
				key_can_be_tag = 0;
				break;
			}
			
			if (*key_walk == ':') {
				if (namespace == 1) {
					key_can_be_tag = 0;
					break;
				}
				namespace = 1;
			} 
			key_walk++;
		}
		
		PUSHs (sv_2mortal (newSViv (key_can_be_tag)));
			
		// warn ("key %s typed as: %s; can be used as tag %d \n", key_name, ref_type, key_can_be_tag);
		
		
