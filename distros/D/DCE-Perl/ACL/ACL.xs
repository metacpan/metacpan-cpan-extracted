/* $Id: ACL.xs,v 1.19 1997/06/23 03:45:20 dougm Exp $ */

#include <dce/rpc.h>
#include <dce/daclif.h>
#include <dce/aclif.h>
#include <dce/sec_acl_encode.h>
#include <dce/secidmap.h>

#include "../DCE_Perl.h"

#define BLESS_ACL_HANDLE \
  sv = sv_newmortal(); \
  sv_setref_pv(sv,package,(void*)handle); \
  XPUSHs(sv); \
  DCESTATUS

#define BLESS_ACL_ENTRY(e) \
{ \
    SV *sv = sv_newmortal(); \
    sv_setref_pv(sv, "DCE::ACL::entry", (void*)e); \
    XPUSHs(sv); \
}

#define BLESS_ACL(acl) \
{ \
    SV *sv = sv_newmortal(); \
    sv_setref_pv(sv, "DCE::ACL", (void*)acl); \
    XPUSHs(sv); \
}

#define IS_FOREIGN_TYPE(t) ((t==sec_acl_e_type_foreign_user)||(t==sec_acl_e_type_foreign_group))

#define SNAG_FIRST_MANAGER(h, mgr, type, mgr_sv) \
if(!SvTRUE(mgr_sv)) { \
    unsigned32 size_used, num_types; \
    uuid_t manager_types[1]; \
    error_status_t status; \
    sec_acl_get_manager_types(h, type, 1, &size_used, &num_types, manager_types, &status); \
    mgr = manager_types[0]; \
    if(mgr_sv != &PL_sv_undef) \
       __bless_uuid(mgr, mgr_sv); \
} \
else { \
    UUIDmagic_sv(manager_type, mgr_sv); \
}
  
typedef sec_acl_handle_t    DCE__ACL__handle;
typedef sec_acl_list_t  *   DCE__ACL__list;
typedef sec_acl_t       *   DCE__ACL;
typedef sec_acl_entry_t *   DCE__ACL__entry;
typedef sec_acl_printstring_t * DCE__ACL__printstring;

static boolean32
acl_entry_compare(sec_acl_entry_t *e1,
		  sec_acl_entry_t *e2,
		  boolean32 permset_filled)
{
    boolean32 entry_equal = FALSE;
    error_status_t status;

    /*
     * Compare ACL entry types
     */
    if (e1->entry_info.entry_type == e2->entry_info.entry_type)
	entry_equal = TRUE;

    /*
     * Compare ACL entry keys if applicable
     */
    if (entry_equal){
        switch (e1->entry_info.entry_type){
	    case sec_acl_e_type_user:
	    case sec_acl_e_type_group:
	    case sec_acl_e_type_foreign_other:
	    case sec_acl_e_type_user_deleg:
	    case sec_acl_e_type_group_deleg:
	    case sec_acl_e_type_for_other_deleg:
		if (! uuid_equal(&e1->entry_info.tagged_union.id.uuid,
		                 &e2->entry_info.tagged_union.id.uuid, 
				 &status))
		    entry_equal = FALSE;
	        break;
	    case sec_acl_e_type_foreign_user:
	    case sec_acl_e_type_foreign_group:
	    case sec_acl_e_type_for_user_deleg:
	    case sec_acl_e_type_for_group_deleg:
	      if (! uuid_equal(&e1->entry_info.tagged_union.foreign_id.id.uuid,
		               &e2->entry_info.tagged_union.foreign_id.id.uuid, 			      &status))
		    entry_equal = FALSE;
	        break;
	    case sec_acl_e_type_extended:
	    /* extended has a key but does not need to be compared */
	        break;
	    /*
	     * These ACL entries have no keys
	     */
	    case sec_acl_e_type_mask_obj:
	    case sec_acl_e_type_user_obj:
	    case sec_acl_e_type_group_obj:
	    case sec_acl_e_type_user_obj_deleg:
	    case sec_acl_e_type_group_obj_deleg:
	    case sec_acl_e_type_other_obj:
	    case sec_acl_e_type_other_obj_deleg:
	    case sec_acl_e_type_unauthenticated:
	    case sec_acl_e_type_any_other:
	    case sec_acl_e_type_any_other_deleg:
	    default:
	        break;
        } 
    } 

    /*
     * Compare ACL permsets 
     */
    if (entry_equal && permset_filled) {
	if (e1->perms != e2->perms) {
	    entry_equal = FALSE;
	}
    }
    return(entry_equal);
}

static void
free_existing_entry_keys(DCE__ACL acl)
{
    int i;
    sec_acl_entry_t *entry_p;

   if ((acl != NULL) && 
	(acl->sec_acl_entries != NULL)) {
	for (i = 0; i < acl->num_entries; i++) {
	    entry_p = &(acl->sec_acl_entries[i]);
	    if (entry_p) {
		switch (entry_p->entry_info.entry_type)  {
		    case sec_acl_e_type_user:
		    case sec_acl_e_type_group:
		    case sec_acl_e_type_foreign_other:
		    case sec_acl_e_type_user_deleg:
		    case sec_acl_e_type_group_deleg:
		    case sec_acl_e_type_for_other_deleg:
		      if (entry_p->entry_info.tagged_union.id.name)
			 free((void *)entry_p->entry_info.tagged_union.id.name);
		       break;
		    case sec_acl_e_type_foreign_user:
		    case sec_acl_e_type_foreign_group:
		    case sec_acl_e_type_for_user_deleg:
		    case sec_acl_e_type_for_group_deleg:
		      if (entry_p->entry_info.tagged_union.foreign_id.id.name)
			 free((void *)entry_p->entry_info.tagged_union.foreign_id.id.name);
	       	      break;
		    case sec_acl_e_type_extended:
		      if (entry_p->entry_info.tagged_union.extended_info)
			 free((void *)entry_p->entry_info.tagged_union.extended_info);
		      break;
		    default:
		      break;
		} 
	    }
	} 
    }

}

MODULE = DCE::ACL		PACKAGE = DCE::ACL::handle	PREFIX = sec_acl_

void
sec_acl_DESTROY(handle)
DCE::ACL::handle handle

   PPCODE:
   {
   error_status_t status; 
   /* some problems here on DEC & Solaris */
#ifdef HPUX
   sec_acl_release_handle(handle, &status);
#endif
   }

void
sec_acl_get_manager_types(handle, sec_acl_type=sec_acl_type_object, size_avail=1)
DCE::ACL::handle handle
sec_acl_type_t  sec_acl_type
unsigned32 size_avail

    PPCODE: 
    {  
    unsigned32 size_used, num_types;
    uuid_t *manager_types = malloc(sizeof(uuid_t) * size_avail);
    error_status_t status;
    SV *uuid_sv;
    AV *av;
    int i;

    if (! manager_types) croak("malloc");
    sec_acl_get_manager_types(handle, sec_acl_type, size_avail, 
			      &size_used, &num_types, manager_types, &status);
    CHK_STS(3);
    iniAV;

    for(i=0; i<size_avail; i++) {
      BLESS_UUID(manager_types[i]);
      av_push(av, uuid_sv);
    }

    if(WANTARRAY) {
	XPUSHs_iv(size_used);
	XPUSHs_iv(num_types);
	XPUSHs(newRV((SV*)av));
	DCESTATUS;
    }
    else 
	XPUSHs(newRV((SV*)av));
    free(manager_types);
    }

void
sec_acl_replace(handle, mgr_sv, sec_acl_type, l)
DCE::ACL::handle handle
SV *mgr_sv
sec_acl_type_t  sec_acl_type
DCE::ACL::list l

    PPCODE:
    {
      error_status_t status;
      uuid_t manager_type;

      SNAG_FIRST_MANAGER(handle, manager_type, sec_acl_type, mgr_sv);
      sec_acl_replace(handle, &manager_type, sec_acl_type, l, &status); 
      DCESTATUS;
    }

void
sec_acl_get_printstring(handle, mgr_sv=&PL_sv_undef, printstring_len=32)
DCE::ACL::handle handle
SV *mgr_sv
unsigned32 printstring_len

    PPCODE:
    {
      uuid_t manager_type, manager_type_chain;
      sec_acl_printstring_t manager_info;
      boolean32 tokenize;
      unsigned32 total_num_printstrings, num_printstrings;
      sec_acl_printstring_t *printstrings = malloc(printstring_len*sizeof(sec_acl_printstring_t));
      error_status_t status;
      HV *hv, *info_hv;
      AV *av;
      SV *uuid_sv, *info;
      int i;

      if (! printstrings) croak("malloc");
      SNAG_FIRST_MANAGER(handle, manager_type, sec_acl_type_object, mgr_sv);

      sec_acl_get_printstring(handle, &manager_type, printstring_len,
			  &manager_type_chain, 
			  &manager_info,
			  &tokenize, 
			  &total_num_printstrings,
			  &num_printstrings, 
			  printstrings, 
			  &status);
      CHK_STS(6);

      iniAV;
      for(i=0; i<num_printstrings; i++) {
	iniHV;
	hv_store(hv, "permissions", 11, 
		 newSViv((IV)printstrings[i].permissions), 0);
 	hv_store(hv, "printstring", 11, 
		 newSVpv(printstrings[i].printstring,0), 0);
 	hv_store(hv, "helpstring", 10, 
		 newSVpv(printstrings[i].helpstring,0), 0);

        /* DCE_TIEHASH(&printstrings[i], "DCE::ACL::printstring", hv); */	    
	av_push(av, newRV((SV*)hv));
      }

      if(WANTARRAY) {
	  EXTEND(sp, 6);
	  BLESS_UUID_mortal(manager_type_chain);
	  PUSHs(uuid_sv); /*chain*/
          DCE_TIEHASH(&manager_info, "DCE::ACL::printstring", info_hv);
          PUSHs(newRV((SV*)info_hv)); /*manager_info*/
	  PUSHs_iv(tokenize);
	  PUSHs_iv(total_num_printstrings);
	  PUSHs_iv(num_printstrings);
	  PUSHs(newRV((SV*)av));
	  DCESTATUS;
      }
      else	  
	  XPUSHs(newRV((SV*)av));
      free(printstrings);
      }	  

void
sec_acl_test_access(handle, mgr_sv, permset)
DCE::ACL::handle handle
SV *mgr_sv
sec_acl_permset_t permset

   PPCODE:
   {
     uuid_t manager_type;
     error_status_t status;
     boolean32 res;

     SNAG_FIRST_MANAGER(handle, manager_type, sec_acl_type_object, mgr_sv);
     res = sec_acl_test_access(handle, &manager_type, permset, &status);
     XPUSHs_iv(res);
     if(WANTARRAY)
	 DCESTATUS;
   }

void
sec_acl_test_access_on_behalf(handle, uuid, pac, desired_permset)
DCE::ACL::handle handle
SV *uuid
SV *pac
sec_acl_permset_t desired_permset

    PPCODE:
    {
     uuid_t mgr_type;
     sec_id_pac_t subject;
     error_status_t status;
     boolean32 res;
     HV *hv, *id;
     SV **svp;

     subject.pac_type = sec_id_pac_format_v1;
     hv = (HV*)SvRV(pac);
     subject.authenticated = (boolean32)SvIV(*hv_fetch(hv, "authenticated", 13, 0));
     FETCH_SEC_ID(subject.realm, hv, "realm", 5);
     FETCH_SEC_ID(subject.principal, hv, "principal", 9);
     FETCH_SEC_ID(subject.group, hv, "group", 5);
     subject.num_groups = 0;

     UUIDmagic_sv(mgr_type, uuid);
     res = sec_acl_test_access_on_behalf(handle, &mgr_type, &subject, desired_permset, &status); 

     XPUSHs_iv(res);
     if(WANTARRAY)
	 DCESTATUS;
   }

void
sec_acl_get_access(handle, mgr_sv)
DCE::ACL::handle handle
SV *mgr_sv

   PPCODE:
   {
     sec_acl_permset_t permset;
     uuid_t manager_type;
     error_status_t status;
   
     SNAG_FIRST_MANAGER(handle, manager_type, sec_acl_type_object, mgr_sv);
     sec_acl_get_access(handle, &manager_type, &permset, &status);

     XPUSHs_iv(permset);
     DCESTATUS;
   }

void
sec_acl_lookup(handle, mgr_sv, sec_acl_type=sec_acl_type_object) 
DCE::ACL::handle handle
SV      *mgr_sv
sec_acl_type_t  sec_acl_type

    PPCODE:
    {
    sec_acl_list_t *l = 
	(sec_acl_list_t *)safemalloc(sizeof(sec_acl_list_t));  
    uuid_t manager_type;
    error_status_t status, rstatus;
    SV *list = sv_newmortal();

    SNAG_FIRST_MANAGER(handle, manager_type, sec_acl_type_object, mgr_sv);    
    sec_acl_lookup(handle, &manager_type, sec_acl_type, 
		   l, &status);
    CHK_STS(1);
    sv_setref_pv(list, "DCE::ACL::list", (void*)l);
    XPUSHs(list);
    DCESTATUS;
    }

MODULE = DCE::ACL		PACKAGE = DCE::ACL::list

void
DESTROY(l)
DCE::ACL::list l

    CODE:
    safefree((DCE__ACL__list)l);

unsigned32
num_acls(l)
DCE::ACL::list l

   CODE:
   RETVAL = l->num_acls;
    
   OUTPUT:
   RETVAL

DCE::ACL
acls(l, ...)
DCE::ACL::list l

   PPCODE:
   {
   int i;
   if(items > 1) {
       i = (int)SvIV(ST(1));
       BLESS_ACL(l->sec_acls[i]);
   }
   else {
       if(WANTARRAY) {
	   for(i=0; i < l->num_acls; i++)
	       BLESS_ACL(l->sec_acls[i]);
       }
       else {
	   BLESS_ACL(l->sec_acls[0]);
       }   
   }
   }

MODULE = DCE::ACL		PACKAGE = DCE::ACL        PREFIX = dce_acl_obj_

void
dce_acl_obj_init(self, mgr_sv)
SV *self
SV *mgr_sv

    PPCODE:
    {
    uuid_t manager_type;	
    sec_acl_t *acl = (sec_acl_t *)safemalloc(sizeof(sec_acl_t));
    error_status_t status;
    
    UUIDmagic_sv(manager_type, mgr_sv); 

    dce_acl_obj_init(&manager_type, acl, &status);
    BLESS_ACL(acl);
    if(WANTARRAY)
	DCESTATUS;
    }

void
dce_acl_obj_add_any_other_entry(acl, permset)
DCE::ACL acl
sec_acl_permset_t permset

    PPCODE:
    {
    error_status_t status;
    dce_acl_obj_add_any_other_entry(acl, permset, &status);
    DCESTATUS;
    }

MODULE = DCE::ACL		PACKAGE = DCE::ACL        PREFIX = sec_acl_

void
sec_acl_bind(package, entry_name, bind_to_entry=FALSE)
char *package
unsigned char *entry_name
boolean32 bind_to_entry

    PPCODE:
    {
    sec_acl_handle_t  handle;
    error_status_t status;
    SV *sv;
    package = "DCE::ACL::handle"; 

    sec_acl_bind(entry_name, bind_to_entry, &handle, &status);
    CHK_STS(1);
    BLESS_ACL_HANDLE;
    }

void
sec_acl_bind_to_addr(package, site_addr, component_name)
char *package
unsigned char *site_addr
unsigned char *component_name

    PPCODE:
    {
    sec_acl_handle_t  handle;
    error_status_t status;
    SV *sv;
    package = "DCE::ACL::handle"; 

    sec_acl_bind_to_addr(site_addr, component_name, &handle, &status);
    CHK_STS(1);
    BLESS_ACL_HANDLE;
    }

unsigned32
num_entries(acl)
DCE::ACL acl

    CODE:
    RETVAL = acl->num_entries;

    OUTPUT:
    RETVAL

SV *
default_realm(acl)
DCE::ACL acl

    CODE:
    {
    HV *hv;	 
    SV *uuid_sv;
    
    iniHV;
    BLESS_UUID(acl->default_realm.uuid); 
    hv_store(hv, "uuid", 4, uuid_sv, 0);
    hv_store(hv, "name", 4, newSVpv(acl->default_realm.name,0), 0); 
    RETVAL = newRV((SV*)hv);
    }

    OUTPUT:
    RETVAL

SV *
manager_type(acl)
DCE::ACL acl

    CODE: 
    {
    SV *uuid_sv;
    BLESS_UUID(acl->sec_acl_manager_type); 
    RETVAL = uuid_sv;
    }

    OUTPUT:
    RETVAL

void
entries(acl, ...)
DCE::ACL acl

    PPCODE:
    {
    int i;
    if(items > 1) {	
	i = (int)SvIV(ST(1));
	BLESS_ACL_ENTRY(&acl->sec_acl_entries[i]);
    }
    else {
	for(i=0; i<acl->num_entries; i++)
	    BLESS_ACL_ENTRY(&acl->sec_acl_entries[i]);
    }
    }

DCE::ACL::entry
new_entry(acl)
SV *acl

    ALIAS:
    DCE::ACL::new = 1
    DCE::ACL::entry::new = 2

    CODE:
    {
    sec_acl_entry_t *e = (sec_acl_entry_t *)NULL;
    e = (sec_acl_entry_t *)safemalloc(sizeof(sec_acl_entry_t));
    /* e->entry_info.tagged_union.id.uuid = NULL; */
    RETVAL = e;
    }

    OUTPUT:
    RETVAL

void
add(acl, e)
DCE::ACL acl
DCE::ACL::entry e

    PPCODE:
    {
    int i;
    sec_acl_entry_t *new_sec_acl_entries;
    boolean32       entry_found = FALSE;
    error_status_t status;

    SET_STATUS(&status, error_status_ok);

    new_sec_acl_entries = (sec_acl_entry_t *)safemalloc(
       (acl->num_entries + 1) * sizeof(sec_acl_entry_t));

    if (new_sec_acl_entries == NULL){
	SET_STATUS(&status, sec_s_no_memory);
	CHK_STS(0);
    }

    for (i = 0; i < acl->num_entries; i++) {
	if (acl_entry_compare(&acl->sec_acl_entries[i], e, FALSE))
	    entry_found = TRUE;
	new_sec_acl_entries[i] =
			acl->sec_acl_entries[i];
    }

    /* check to see if the entry already exists, if so return */
    if (entry_found) {
	croak("ACL entry already exists!");
	CHK_STS(0);
    } 
    
    /*
     * Discard the old, existing entries
     */
    if (acl->num_entries > 0) 
	safefree((void *) acl->sec_acl_entries);

    /* 
     * Add the new entry 
     */
    new_sec_acl_entries[acl->num_entries] = *e;
			
    acl->sec_acl_entries = new_sec_acl_entries;
    acl->num_entries++;
    DCESTATUS;
    }

void
remove(acl, e)
DCE::ACL acl
DCE::ACL::entry e

    PPCODE:
    {
    int i, j;
    boolean32       entry_found = FALSE;
    error_status_t  status;

    SET_STATUS(&status, error_status_ok);
    /* 
     * We have existing ACL, now check for no ACL entries
     */
    if ((acl->num_entries > 0) &&
	(acl->sec_acl_entries == NULL)){
	SET_STATUS(&status, sec_acl_no_acl_found);
	CHK_STS(0);
    }

    /* 
     * If the specified entry is found, remove it 
     */
    for (i = 0; i < acl->num_entries; i++) {
	if (acl_entry_compare(
			     &(acl->sec_acl_entries[i]),
			     e, 
			     FALSE)) {
	    entry_found = TRUE;

            /* Shift any remaining entries down the list */
	    for (j = i; j < acl->num_entries-1; j++)
	       acl->sec_acl_entries[j] = acl->sec_acl_entries[j+1];
	    acl->num_entries--;
	} 
    } 

    if (! entry_found)
	SET_STATUS(&status, sec_acl_object_not_found);
    DCESTATUS;
    }

int
delete(acl)
DCE::ACL acl

    CODE:
    {
    /* 
     * We have existing ACL, now check for no ACL entries
     */
    if ((acl->num_entries > 0) &&
	(acl->sec_acl_entries == NULL)){
	RETVAL = -1;
    }

    /*
     * Perform request to delete entries 
     */
    if (acl->num_entries > 0) {
	free_existing_entry_keys(acl);
	free((void *) acl->sec_acl_entries);
    }
    acl->num_entries = 0;

    RETVAL = 0;
    }
   
    OUTPUT:
    RETVAL

MODULE = DCE::ACL		PACKAGE = DCE::ACL::entry

void
DESTROY(e)
DCE::ACL::entry e
    
    CODE:
    /* free((void *)e); */

unsigned32
perms(e, ...)
DCE::ACL::entry e

    CODE:
    RETVAL = e->perms;

    if(items > 1) 
       e->perms = (unsigned32)SvIV(ST(1));

    OUTPUT:
    RETVAL
    
SV *
entry_info(e, ...)
DCE::ACL::entry e

    CODE:
    {
    HV *hv;	
    SV *uuid_sv;

    iniHV;
    hv_store(hv, "entry_type", 10,
	     newSViv((IV)e->entry_info.entry_type), 0);

    if (IS_FOREIGN_TYPE(e->entry_info.entry_type)) {
      STORE_FOREIGN_ID(e->entry_info.tagged_union.foreign_id, hv);
    }
    else {
      STORE_SEC_ID(e->entry_info.tagged_union.id, hv, "id", 2);
    }

    if (items > 1) {
	HV *set_hv, *f_hv;
	SV **svp;
	set_hv = (HV*)SvRV(ST(1));

	svp = hv_fetch(set_hv, "entry_type", 10, 1);
	if(SvOK(*svp)) 
	    e->entry_info.entry_type = (sec_acl_entry_type_t)SvIV(*svp);

	if (IS_FOREIGN_TYPE(e->entry_info.entry_type))  {
	  FETCH_FOREIGN_ID(e->entry_info.tagged_union.foreign_id, set_hv);
        }
        else {
	  FETCH_SEC_ID(e->entry_info.tagged_union.id, set_hv, "id", 2);
        }

    }
    RETVAL = newRV((SV*)hv);
    }

    OUTPUT:
    RETVAL

boolean32
compare(e1, e2)
DCE::ACL::entry e1
DCE::ACL::entry e2

    CODE: 
    RETVAL = acl_entry_compare(e1,e2,FALSE);
    
    OUTPUT:
    RETVAL	

MODULE = DCE::ACL       PACKAGE = DCE::ACL::printstring

SV *
FETCH(p, key)
DCE::ACL::printstring p
char *key

    CODE:
    /* printf("FETCH '%s'\n", (char *)p->helpstring); */
    if(strEQ(key, "permissions")) 
	RETVAL = newSViv((IV)p->permissions);
    else if(strEQ(key, "printstring"))
        RETVAL = newSVpv(p->printstring, 0);
    else if(strEQ(key, "helpstring"))
        RETVAL = newSVpv(p->helpstring, 0);
    else
        RETVAL = &PL_sv_undef;

    OUTPUT:
    RETVAL


