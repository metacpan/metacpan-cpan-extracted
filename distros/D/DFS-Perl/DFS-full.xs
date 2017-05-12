/*
 * DFS-Perl version 0.35
 *
 * Paul Henson <henson@acm.org>
 * California State Polytechnic University, Pomona
 *
 * Copyright (c) 1997,1998,1999 Paul Henson -- see COPYRIGHT file for details
 *
 */

#ifdef __cplusplus
extern "C" {
#endif

#include <sys/types.h>
#include <time.h>
#include <errno.h>
#include <netinet/in.h>
#include <netdb.h>
#include <arpa/inet.h>
#include <dce/dce_error.h>
#include <dce/rpc.h>
#include <dce/exc_handling.h>
#include <dce/secsts.h>
#include <dce/sec_login.h>
#include <dce/pthread.h>
#include <dcedfs/param.h>
#include <dcedfs/afsvl_proc.h>
#include <dcedfs/aggr.h>
#include <dcedfs/cm.h>
#include <dcedfs/fldb_proc.h>
#include <dcedfs/flserver.h>
#include <dcedfs/ftserver.h>
#include <dcedfs/ftserver_proc.h>
#include <dcedfs/ioctl.h>
#include <dcedfs/vol_init.h>
#include <dcedfs/rep_errs.h>
#include <dcedfs/vol_errs.h>
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#undef pthread_getspecific

typedef afsFid *DCE__DFS__fid;

#define FLSERVER_MAX 5
typedef struct flserver_obj {
  rpc_binding_handle_t flserver_h[FLSERVER_MAX];
  int flserver_h_count;
  int flserver_h_index;
  
  /* VL_GenerateSites */
  unsigned32 site_start, site_nextstart;
  bulkSites site_info;
  unsigned32 site_count;
  unsigned32 site_index;

  /* VL_ListByAttributes */
  VldbListByAttributes attributes;
  bulkentries entry_info;
  unsigned32 entry_start, entry_nextstart;
  unsigned32 entry_index;

} flserver_obj;

typedef flserver_obj *DCE__DFS__flserver;


typedef struct ftserver_obj {
  rpc_binding_handle_t ftserver_h;
  afsNetAddr addr;

  /* FTSERVER_ListAggregates */ 
  ftserver_iterator aggr_start, aggr_nextstart;
  ftserver_aggrEntries aggr_entries;
  unsigned32 aggr_index;

} ftserver_obj;

typedef ftserver_obj *DCE__DFS__ftserver;


typedef struct aggregate_obj {
  rpc_binding_handle_t ftserver_h;
  afsNetAddr addr;

  unsigned32 id;
  ftserver_aggrInfo aggr_info;
} aggregate_obj;

typedef aggregate_obj *DCE__DFS__aggregate;


typedef struct fileset_obj {
  vldbentry entry;
  unsigned32 rw_mask;
  unsigned32 bk_mask;
  unsigned32 ro_mask;
  unsigned32 vol_id_rw_index;
  unsigned32 vol_id_ro_index;
  unsigned32 vol_id_bk_index;
  int ftserver_rw_index;
  rpc_binding_handle_t ftserver_h[16];
  int ftserver_h_initialized;
  ftserver_status rw_status;
  ftserver_status bk_status;
  ftserver_status ro_status[16];
} fileset_obj;

typedef fileset_obj *DCE__DFS__fileset;
  

static error_status_t bind_flservers(char *cell_fs, flserver_obj *flserver)
{
  unsigned32 import_status, group_status, rpc_status;
  rpc_ns_handle_t import_context;
  rpc_ns_handle_t group_context;
  unsigned_char_t *name, *string_binding, *protseq, *network_addr;
  uuid_t obj_uuid;
  unsigned_char_t *string_uuid;
  rpc_binding_handle_t temp_h;

  rpc_ns_entry_object_inq_begin(rpc_c_ns_syntax_default, cell_fs, &import_context, &import_status);

  if (import_status)
    return import_status;

  rpc_ns_entry_object_inq_next(import_context, &obj_uuid, &import_status);

  if (import_status)
    return import_status;

  rpc_ns_entry_object_inq_done(&import_context, &import_status);

  uuid_to_string(&obj_uuid, &string_uuid, &import_status);

  if (import_status)
    return import_status;

  
  rpc_ns_group_mbr_inq_begin(rpc_c_ns_syntax_default, cell_fs, rpc_c_ns_syntax_default,
                             &group_context, &group_status);

  if (group_status)
    return group_status;
  
  while ((!group_status) &&  (flserver->flserver_h_count < FLSERVER_MAX))
    {
      rpc_ns_group_mbr_inq_next(group_context, &name, &group_status);

      if (!group_status)
        {
          rpc_ns_binding_import_begin(rpc_c_ns_syntax_default, name, NULL,
                                      NULL, &import_context, &import_status);

          if (import_status)
            {
              rpc_ns_binding_import_done(&import_context, &import_status);
              continue;
            }

          rpc_ns_binding_import_next(import_context, &temp_h, &import_status);

          if (import_status)
            {
              rpc_ns_binding_import_done(&import_context, &import_status);
              continue;
            }

          rpc_binding_to_string_binding(temp_h, &string_binding, &import_status);
          rpc_binding_free(&temp_h, &rpc_status);
          
          if (import_status)
            {
              rpc_ns_binding_import_done(&import_context, &import_status);
              continue;
            }
          
          rpc_string_binding_parse(string_binding, NULL, &protseq, &network_addr,
                                   NULL, NULL, &import_status);
          rpc_string_free(&string_binding, &rpc_status);

          if (import_status)
            {
              rpc_ns_binding_import_done(&import_context, &import_status);
              continue;
            }
          
          rpc_string_binding_compose(string_uuid,
                                     protseq, network_addr, NULL, NULL,
                                     &string_binding, &import_status);
          rpc_string_free(&protseq, &rpc_status);
          rpc_string_free(&network_addr, &rpc_status);

          if (import_status)
            {
              rpc_ns_binding_import_done(&import_context, &import_status);
              continue;
            }
          
          rpc_binding_from_string_binding(string_binding,
                                          &flserver->flserver_h[flserver->flserver_h_count],
                                          &import_status);
          rpc_string_free(&string_binding, &rpc_status);

          if (!import_status)
            flserver->flserver_h_count++;
          
          rpc_ns_binding_import_done(&import_context, &import_status);
        }
    }
  rpc_ns_group_mbr_inq_done(&group_context, &group_status);
  rpc_string_free(&string_uuid, &import_status);

  flserver->flserver_h_index = time(NULL) % flserver->flserver_h_count;

  return 0;
}

static error_status_t init_ftserver_h(rpc_binding_handle_t *ftserver_h, afsNetAddr *addr)
{
  unsigned_char_t *string_binding, *s_name;
  sec_login_handle_t login_context;
  error_status_t status, status2;

  rpc_string_binding_compose(NULL, "ncadg_ip_udp",
			     inet_ntoa(((struct sockaddr_in *)(addr))->sin_addr),
                             NULL, NULL, &string_binding, &status);

  if (status) return status;

  rpc_binding_from_string_binding(string_binding, ftserver_h, &status);
  rpc_string_free(&string_binding, &status2);

  if (status) return status;

  sec_login_get_current_context(&login_context,	&status);
  if (!status)
    {
      rpc_ep_resolve_binding(*ftserver_h, FTSERVER_v4_0_c_ifspec, &status);
      if (!status) {
	rpc_mgmt_inq_server_princ_name(*ftserver_h, rpc_c_authn_default, &s_name, &status);
	if (!status) {
	  rpc_binding_set_auth_info(*ftserver_h, s_name, rpc_c_protect_level_default,
				    rpc_c_authn_default, login_context,
				    rpc_c_authz_dce, &status);
	  rpc_string_free(&s_name, &status);
	}
      }
    }

  return status;
}

static error_status_t init_ftserver_state(DCE__DFS__ftserver ftserver)
{
  ftserver->aggr_start.index = ftserver->aggr_nextstart.index = ftserver->aggr_index = 0;
  ftserver->aggr_entries.ftserver_aggrList_len = 0;

  return 0;
}

static error_status_t init_ftserver(DCE__DFS__ftserver ftserver)
{
  error_status_t status;

  if (status = init_ftserver_h(&ftserver->ftserver_h, &ftserver->addr))
    return status;

  return init_ftserver_state(ftserver);
}

static error_status_t update_fileset(DCE__DFS__fileset fileset, int ftserver_index, int fileset_type)
{
  error_status_t status = 0;
  
  if (ftserver_index < 0 || ftserver_index >= fileset->entry.nServers || fileset_type < 0 || fileset_type > 2)
    status = REP_ERR_INVAL_PARAM;
  else
    {
      if (!(fileset->ftserver_h_initialized & (1 << ftserver_index)))
	if (!(status = init_ftserver_h(&fileset->ftserver_h[ftserver_index], &fileset->entry.siteAddr[ftserver_index])))
	  fileset->ftserver_h_initialized |= (1 << ftserver_index);

      if (!status)
	if (fileset_type == 0)
	  status = FTSERVER_GetOneVolStatus(fileset->ftserver_h[ftserver_index], &fileset->entry.VolIDs[fileset->vol_id_rw_index],
					    fileset->entry.sitePartition[ftserver_index], 0, &fileset->rw_status);
	else if (fileset_type == 1)
	  status = FTSERVER_GetOneVolStatus(fileset->ftserver_h[ftserver_index], &fileset->entry.VolIDs[fileset->vol_id_ro_index],
					    fileset->entry.sitePartition[ftserver_index], 0, &fileset->ro_status[ftserver_index]);
	else
	  status = FTSERVER_GetOneVolStatus(fileset->ftserver_h[ftserver_index], &fileset->entry.VolIDs[fileset->vol_id_bk_index],
					    fileset->entry.sitePartition[ftserver_index], 0, &fileset->bk_status);
    }
  return status;
}

static int
not_here(s)
char *s;
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant(name, arg)
char *name;
int arg;
{
    errno = 0;
    switch (*name) {
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}


MODULE = DCE::DFS		PACKAGE = DCE::DFS

void
cellname(path)
     char *path
     CODE:
       struct afs_ioctl ioctl_buf;
       char cellname[300];

       ioctl_buf.in_size = 0;
       ioctl_buf.out_size = sizeof(cellname);
       ioctl_buf.out = cellname;

       if (!pioctl(path, VIOC_FILE_CELL_NAME, &ioctl_buf, 1))
         ST(0) = sv_2mortal(newSVpv(cellname, strlen(cellname)));
       else
         ST(0) = &PL_sv_undef;


int
crmount(path, fileset, read_write = 0)
    char *path
    char *fileset
    int read_write
    CODE:
    {
      char ioctl_data[2048+1];
      struct afs_ioctl ioctl_buf;
      struct cm_CreateMountPoint *mountp;
      char *mount_dir;
      char *mount_name;
      char *index;
      char link[1024+1];

      if (index = rindex(path, '/'))
	{
	  *index = '\0';
	  mount_dir = path;
	  mount_name = index + 1; 
	}
      else
	{
	  mount_dir = ".";
	  mount_name = path;
	}
      
      link[0] = read_write ? '%' : '#';
      link[1] = '\0';
      strcat(link, fileset);
      strcat(link, ".");
      
      bzero(ioctl_data, sizeof(ioctl_data));
      mountp = (struct cm_CreateMountPoint *) ioctl_data;

      mountp->nameOffset = sizeof(struct cm_CreateMountPoint);
      mountp->nameLen = strlen(mount_name);
      mountp->nameTag = 0;
      
      mountp->pathOffset = mountp->nameOffset + mountp->nameLen + 1;
      mountp->pathLen = strlen(link);
      mountp->pathTag = 0;
      
      if ((mountp->pathOffset + mountp->pathLen) <= 2048)
	{
	  strcpy(&ioctl_data[mountp->nameOffset], mount_name);
	  strcpy(&ioctl_data[mountp->pathOffset], link);
      
	  ioctl_buf.out_size = 0;
	  ioctl_buf.out = 0;
	  ioctl_buf.in = ioctl_data;
	  ioctl_buf.in_size = mountp->pathOffset + mountp->pathLen + 1;
	  
	  RETVAL = pioctl(mount_dir, VIOC_AFS_CREATE_MT_PT, &ioctl_buf, 1);
	}
      else      
	RETVAL = ENOMEM;

    }
    OUTPUT:
      RETVAL

int
delmount(path)
     char *path
     CODE:
     {
       struct afs_ioctl ioctl_buf;
       char *mount_dir;
       char *mount_name;
       char *index;

       index = path + strlen(path) - 1;
       while ((index >= path) && (*index == '/'))
	 *index-- = '\0';

       ioctl_buf.out_size = 0;
       ioctl_buf.out = 0;
  
       if (index = rindex(path, '/'))
	 {
	   *index = '\0';
	   mount_name = index + 1;
	   mount_dir = path;
	 }
       else
	 {
	   mount_name = path;
	   mount_dir = ".";
	 }
       
       ioctl_buf.in = mount_name;
       ioctl_buf.in_size = strlen(mount_name) + 1;
  
       if (*mount_dir)
	 RETVAL = pioctl(mount_dir, VIOC_AFS_DELETE_MT_PT, &ioctl_buf, 1);
       else
	 RETVAL = EINVAL;
     }
     OUTPUT:
       RETVAL

void
fid(path)
    char *path
    PPCODE:
    {   
      struct afs_ioctl ioctl_buf;
      DCE__DFS__fid fid;
      error_status_t status = 0;
      SV *sv = &PL_sv_undef;

      if (!(fid = (DCE__DFS__fid)malloc(sizeof(struct afsFid))))
	status = sec_s_no_memory;
      else {
        ioctl_buf.in_size = 0;
        ioctl_buf.out_size = sizeof(struct afsFid);
        ioctl_buf.out = (caddr_t) fid;

        if (!(status = pioctl(path, VIOCGETFID, &ioctl_buf, 1))) {
          sv = sv_newmortal();
          sv_setref_pv(sv, "DCE::DFS::fid", (void*)fid);
	}
        else {
          free(fid);
        }
      }
      XPUSHs(sv);
      sv = sv_2mortal(newSViv(status));
      XPUSHs(sv); 
    }

void
flserver(cell_fs = "/.:/fs")
     char *cell_fs
     PPCODE:
     {
       SV *sv;
       DCE__DFS__flserver flserver;
       error_status_t status;

       if (!(flserver = (DCE__DFS__flserver)malloc(sizeof(flserver_obj))))
	 {
	   sv = &PL_sv_undef;
	   XPUSHs(sv);
	   sv = sv_2mortal(newSViv(sec_s_no_memory));
	   XPUSHs(sv);
	 }
       else
	 {
	   flserver->flserver_h_count = 0;
	   flserver->flserver_h_index = 0;
	   flserver->site_start = flserver->site_count = flserver->site_index = 0;
	   
	   flserver->attributes.Mask = 0;
	   flserver->entry_info.bulkentries_len = flserver->entry_start = flserver->entry_nextstart = 0;
	   flserver->entry_index = 0;

	   status = bind_flservers(cell_fs, flserver);
	   if ( (status) || (flserver->flserver_h_count == 0) )
	     {
	       free(flserver);
	       sv = &PL_sv_undef;
	       XPUSHs(sv);
	       sv = sv_2mortal(newSViv((status) ? (status) : (-1)));
	       XPUSHs(sv);
	     }
	   else
	     {
	       sv = sv_newmortal();
	       sv_setref_pv(sv,"DCE::DFS::flserver", (void *)flserver);
	       XPUSHs(sv);
	       sv = sv_2mortal(newSViv(0));
	       XPUSHs(sv);
	     }
	 }
     }


MODULE = DCE::DFS		PACKAGE = DCE::DFS::fid

void
DESTROY(fid)
     DCE::DFS::fid fid
     CODE:
       free((void *)fid);

void
id(fid)
     DCE::DFS::fid fid
     PPCODE:
     {
       char buf[32];

       sprintf(buf, "%d,,%d", AFS_hgethi(fid->Volume), AFS_hgetlo(fid->Volume));
       XPUSHs(sv_2mortal(newSVpv(buf, strlen(buf))));
     }

MODULE = DCE::DFS		PACKAGE = DCE::DFS::flserver

void
DESTROY(flserver)
     DCE::DFS::flserver flserver
     CODE:
     {
       int index;
       unsigned32 status;
       
       for (index = 0; index < flserver->flserver_h_count; index++)
	 rpc_binding_free(&flserver->flserver_h[index], &status);
       
       free((void *)flserver);
     }

void
ftserver_reset(flserver)
     DCE::DFS::flserver flserver
     CODE:
     {
       flserver->site_start = flserver->site_count = flserver->site_index = 0;
     }

void
ftserver(flserver)
     DCE::DFS::flserver flserver
     PPCODE:
     {
       DCE__DFS__ftserver ftserver;
       error_status_t status = 0;
       int index;
       SV *sv = &PL_sv_undef;
       
       if (flserver->site_index >= flserver->site_count)
	 {   
	   for(index = 0; index < flserver->flserver_h_count; index++)
	     {
	       error_status_t reset_status;
	       
	       status = VL_GenerateSites(flserver->flserver_h[flserver->flserver_h_index],
					 flserver->site_start, &flserver->site_nextstart,
					 &flserver->site_info, &flserver->site_count);
	       
	       if (!(status >= rpc_s_mod && status <= rpc_s_mod+4096))
		 break;
	       
	       rpc_binding_reset(flserver->flserver_h[flserver->flserver_h_index], &reset_status);
	       flserver->flserver_h_index = ((flserver->flserver_h_index + 1) % flserver->flserver_h_count);
	     }
	   
	   flserver->site_start = flserver->site_nextstart;
	   flserver->site_index = 0;
	 }
       if (status)
	 {
	   flserver->site_start = flserver->site_count = flserver->site_index = 0;
	 }
       else
	 {
	   if (ftserver = (DCE__DFS__ftserver)malloc(sizeof(ftserver_obj)))
	     {
	       ftserver->addr = flserver->site_info.Sites[flserver->site_index].Addr[0];
	       if (!(status = init_ftserver(ftserver)))
		 {
		   sv = sv_newmortal();
		   sv_setref_pv(sv,"DCE::DFS::ftserver", (void *)ftserver);
		 }
	       else
		 {
		   free(ftserver);
		 }
	     }
	   else
	     status = sec_s_no_memory;
	   
	   flserver->site_index++;
	 }
       XPUSHs(sv);
       XPUSHs(sv_2mortal(newSViv(status)));
     }

void
ftserver_by_name(flserver, name)
     DCE::DFS::flserver flserver
     char *name
     PPCODE:
     {
       DCE__DFS__ftserver ftserver;
       error_status_t status;
       u_long addr = 0;
       struct hostent *host;
       SV *sv = &PL_sv_undef;
       
       if ((int)(addr = inet_addr(name)) == -1)
	 if (host = gethostbyname(name))
	   memcpy(&addr, host->h_addr, sizeof(addr));
	 else
	   addr = 0;
       
       if (!addr)
	 status = REP_ERR_INVAL_PARAM;
       else if (!(ftserver = (DCE__DFS__ftserver)malloc(sizeof(ftserver_obj))))
	 status = sec_s_no_memory;
       else
	 {
	   memcpy(&((struct sockaddr_in *)(&ftserver->addr))->sin_addr, &addr, sizeof(((struct sockaddr_in *)(&ftserver->addr))->sin_addr));
	   
	   if (!(status = init_ftserver(ftserver)))
	     {
	       sv = sv_newmortal();
	       sv_setref_pv(sv,"DCE::DFS::ftserver", (void *)ftserver);
	     }
	   else
	       free(ftserver);
	 }
       XPUSHs(sv);
       XPUSHs(sv_2mortal(newSViv(status)));
     }

void
fileset_reset(flserver)
     DCE::DFS::flserver flserver
     CODE:
     {
       flserver->attributes.Mask = 0;
       flserver->entry_info.bulkentries_len = flserver->entry_start = flserver->entry_nextstart = 0;
       flserver->entry_index = 0;
     }

void
fileset_mask_ftserver(flserver, ftserver)
     DCE::DFS::flserver flserver
     DCE::DFS::ftserver ftserver
     CODE:
     {
       flserver->attributes.site = ftserver->addr;
       flserver->attributes.Mask |= VLLIST_SITE;
     }

void
fileset_mask_aggregate(flserver, aggr)
     DCE::DFS::flserver flserver
     DCE::DFS::aggregate aggr
     CODE:
     {
       flserver->attributes.partition = aggr->id;
       flserver->attributes.Mask |= VLLIST_PARTITION;
     }

void
fileset_mask_type(flserver, type)
     DCE::DFS::flserver flserver
     int type
     CODE:
     {
       flserver->attributes.volumetype = VOLTIX_TO_VOLTYPE(type);
       flserver->attributes.Mask |= VLLIST_VOLUMETYPE;
     }

void
fileset(flserver)
     DCE::DFS::flserver flserver
     PPCODE:
     {
       DCE__DFS__fileset fileset;
       error_status_t status = 0;
       unsigned32 dummy, dummy2;
       int index;
       SV *sv = &PL_sv_undef;
       
       if (flserver->entry_index >= flserver->entry_info.bulkentries_len)
	 {
	   for(index = 0; index < flserver->flserver_h_count; index++)
	     {
	       error_status_t reset_status;

	       status = VL_ListByAttributes(flserver->flserver_h[flserver->flserver_h_index],
					    &flserver->attributes, flserver->entry_start,
					    &dummy, &flserver->entry_info, &flserver->entry_nextstart, &dummy2);
	       
	       if (!(status >= rpc_s_mod && status <= rpc_s_mod+4096))
		 break;
		   
	       rpc_binding_reset(flserver->flserver_h[flserver->flserver_h_index], &reset_status);
	       flserver->flserver_h_index = ((flserver->flserver_h_index + 1) % flserver->flserver_h_count);
	     }
	   
	   flserver->entry_start = flserver->entry_nextstart;
	   flserver->entry_index = 0;
	 }
       if (status)
	 {
	   flserver->entry_start = flserver->entry_info.bulkentries_len = flserver->entry_index = 0;
	 }
       else
	 {
	   if (fileset = (DCE__DFS__fileset)malloc(sizeof(fileset_obj)))
	     {
	       fileset->entry = flserver->entry_info.bulkentries_val[flserver->entry_index];

	       for (index = 0; index < MAXVOLTYPES && !AFS_hiszero(fileset->entry.VolIDs[index]); index++)
		 switch (fileset->entry.VolTypes[index])
		   {
		   case VOLTIX_TO_VOLTYPE(RWVOL):
		     fileset->rw_mask = ((unsigned32)VLSF_ZEROIXHERE) >> index;
		     fileset->vol_id_rw_index = index;
		     break;
		   case VOLTIX_TO_VOLTYPE(ROVOL):
		     fileset->ro_mask = ((unsigned32)VLSF_ZEROIXHERE) >> index;
		     fileset->vol_id_ro_index = index;
		     break;
		   case VOLTIX_TO_VOLTYPE(BACKVOL):
		     fileset->bk_mask = ((unsigned32)VLSF_ZEROIXHERE) >> index;
		     fileset->vol_id_bk_index = index;
		     break;
		   }
		   
	       for (index = 0; index < fileset->entry.nServers; index++)
		 if (fileset->entry.siteFlags[index] & fileset->rw_mask)
		   fileset->ftserver_rw_index = index;

	       fileset->ftserver_h_initialized = 0;
	       sv = sv_newmortal();
	       sv_setref_pv(sv,"DCE::DFS::fileset", (void *)fileset);

	       flserver->entry_index++;
	     }
	   else {
	     status = sec_s_no_memory;
	   }
	 }
       XPUSHs(sv);
       sv = sv_2mortal(newSViv(status));
       XPUSHs(sv);
     }

void
fileset_by_name(flserver, name)
     DCE::DFS::flserver flserver
     char *name
     PPCODE:
     {
       error_status_t status;
       DCE__DFS__fileset fileset;
       SV *sv = &PL_sv_undef;
       int index;

       if (fileset = (DCE__DFS__fileset)malloc(sizeof(fileset_obj)))
	 {
	   for(index = 0; index < flserver->flserver_h_count; index++)
	     {
	       error_status_t reset_status;

	       status = VL_GetEntryByName(flserver->flserver_h[flserver->flserver_h_index], name, &fileset->entry);

	       if (!(status >= rpc_s_mod && status <= rpc_s_mod+4096))
		 break;
	       
	       rpc_binding_reset(flserver->flserver_h[flserver->flserver_h_index], &reset_status);
	       flserver->flserver_h_index = ((flserver->flserver_h_index + 1) % flserver->flserver_h_count);
	     }
 
	   if (!status)
	     {
	       fileset->ftserver_h_initialized = 0;
	       sv = sv_newmortal();
	       sv_setref_pv(sv,"DCE::DFS::fileset", (void *)fileset);

	       for (index = 0; index < MAXVOLTYPES && !AFS_hiszero(fileset->entry.VolIDs[index]); index++)
		 switch (fileset->entry.VolTypes[index])
		   {
		   case VOLTIX_TO_VOLTYPE(RWVOL):
		     fileset->rw_mask = ((unsigned32)VLSF_ZEROIXHERE) >> index;
		     fileset->vol_id_rw_index = index;
		     break;
		   case VOLTIX_TO_VOLTYPE(ROVOL):
		     fileset->ro_mask = ((unsigned32)VLSF_ZEROIXHERE) >> index;
		     fileset->vol_id_ro_index = index;
		     break;
		   case VOLTIX_TO_VOLTYPE(BACKVOL):
		     fileset->bk_mask = ((unsigned32)VLSF_ZEROIXHERE) >> index;
		     fileset->vol_id_bk_index = index;
		     break;
		   }
	       
	       for (index = 0; index < fileset->entry.nServers; index++)
		 if (fileset->entry.siteFlags[index] & fileset->rw_mask)
		   fileset->ftserver_rw_index = index;
	     }
	   else
	     {
	       free(fileset);
	     }
	 }
       else
	 status = sec_s_no_memory;
       
       XPUSHs(sv);
       sv = sv_2mortal(newSViv(status));
       XPUSHs(sv);
     }


void
fileset_by_id(flserver, fid)
     DCE::DFS::flserver flserver
     DCE::DFS::fid fid

     PPCODE:
     {
       error_status_t status;
       DCE__DFS__fileset fileset;
       SV *sv = &PL_sv_undef;
       int index;
       
       if (fileset = (DCE__DFS__fileset)malloc(sizeof(fileset_obj)))
	 {
	   for(index = 0; index < flserver->flserver_h_count; index++)
	     {
	       error_status_t reset_status;

	       status = VL_GetEntryByID(flserver->flserver_h[0], &fid->Volume, -1, &fileset->entry);

	       if (!(status >= rpc_s_mod && status <= rpc_s_mod+4096))
		 break;
		   
	       rpc_binding_reset(flserver->flserver_h[flserver->flserver_h_index], &reset_status);
	       flserver->flserver_h_index = ((flserver->flserver_h_index + 1) % flserver->flserver_h_count);
	     }
	   
	   if (!status)
	     {
	       fileset->ftserver_h_initialized = 0;
	       sv = sv_newmortal();
	       sv_setref_pv(sv,"DCE::DFS::fileset", (void *)fileset);

	       for (index = 0; index < MAXVOLTYPES && !AFS_hiszero(fileset->entry.VolIDs[index]); index++)
		 switch (fileset->entry.VolTypes[index])
		   {
		   case VOLTIX_TO_VOLTYPE(RWVOL):
		     fileset->rw_mask = ((unsigned32)VLSF_ZEROIXHERE) >> index;
		     fileset->vol_id_rw_index = index;
		     break;
		   case VOLTIX_TO_VOLTYPE(ROVOL):
		     fileset->ro_mask = ((unsigned32)VLSF_ZEROIXHERE) >> index;
		     fileset->vol_id_ro_index = index;
		     break;
		   case VOLTIX_TO_VOLTYPE(BACKVOL):
		     fileset->bk_mask = ((unsigned32)VLSF_ZEROIXHERE) >> index;
		     fileset->vol_id_bk_index = index;
		     break;
		   }
		   
	       for (index = 0; index < fileset->entry.nServers; index++)
		 if (fileset->entry.siteFlags[index] & fileset->rw_mask)
		   fileset->ftserver_rw_index = index;
	     }
	 }
       else
	 status = sec_s_no_memory;

       XPUSHs(sv);
       sv = sv_2mortal(newSViv(status));
       XPUSHs(sv);
     }


MODULE = DCE::DFS		PACKAGE = DCE::DFS::ftserver

void
DESTROY(ftserver)
     DCE::DFS::ftserver ftserver
     CODE:
     {
       unsigned32 status;

       rpc_binding_free(&ftserver->ftserver_h, &status);
       free((void *)ftserver);
     }

void
address(ftserver)
     DCE::DFS::ftserver ftserver
     CODE:
     {
       char *address = inet_ntoa(((struct sockaddr_in *)(&ftserver->addr))->sin_addr);

       if (address)
	 ST(0) = sv_2mortal(newSVpv(address, strlen(address)));
       else
	 ST(0) = &PL_sv_undef;
     }

void
hostname(ftserver)
     DCE::DFS::ftserver ftserver
     CODE:
     {
       struct hostent *host = gethostbyaddr((const char *)&((struct sockaddr_in *)(&ftserver->addr))->sin_addr,
					    sizeof(((struct sockaddr_in *)(&ftserver->addr))->sin_addr),
					    AF_INET);
       char *retval;

       if (host)
	 retval = host->h_name;
       else
	 retval = inet_ntoa(((struct sockaddr_in *)(&ftserver->addr))->sin_addr);

       if (retval)
	 ST(0) = sv_2mortal(newSVpv(retval, strlen(retval)));
       else
	 ST(0) = &PL_sv_undef;
     }


void
aggregate(ftserver)
     DCE::DFS::ftserver ftserver
     PPCODE:
     {
       DCE__DFS__aggregate aggr;
       error_status_t status = 0;
       SV *sv = &PL_sv_undef;
       
       if (ftserver->aggr_index >= ftserver->aggr_entries.ftserver_aggrList_len)
	 {
	   status = FTSERVER_ListAggregates(ftserver->ftserver_h, &ftserver->aggr_start,
					    &ftserver->aggr_nextstart, &ftserver->aggr_entries);
	     
	   if (ftserver->aggr_start.index == ftserver->aggr_nextstart.index)
	     ftserver->aggr_start.index = ftserver->aggr_nextstart.index = 0;
	   else
	     ftserver->aggr_start = ftserver->aggr_nextstart;
	   
	   ftserver->aggr_index = 0;
	 }
       if (!status)
	 if (ftserver->aggr_entries.ftserver_aggrList_len > 0)
	   {
	     if (aggr = (DCE__DFS__aggregate)malloc(sizeof(aggregate_obj)))
	       {
		 status = FTSERVER_AggregateInfo(ftserver->ftserver_h,
						 ftserver->aggr_entries.ftserver_aggrEntries_val[ftserver->aggr_index].Id,
						 &aggr->aggr_info);
		 
		 if (!status)
		   {
		     rpc_binding_copy(ftserver->ftserver_h, &aggr->ftserver_h, &status);
		     aggr->addr = ftserver->addr;
		     aggr->id = ftserver->aggr_entries.ftserver_aggrEntries_val[ftserver->aggr_index].Id;
		     sv = sv_newmortal();
		     sv_setref_pv(sv, "DCE::DFS::aggregate", (void *)aggr);
		   }
		 else
		   {
		     free(aggr);
		   }
	       }
	     else
	       status = sec_s_no_memory;
	     
	     ftserver->aggr_index++;
	   }
       else
	 status = VL_ENDOFLIST;
       
       XPUSHs(sv);
       XPUSHs(sv_2mortal(newSViv(status)));
     }



MODULE = DCE::DFS		PACKAGE = DCE::DFS::aggregate

void
DESTROY(aggr)
     DCE::DFS::aggregate aggr
     CODE:
     {
       unsigned32 status;

       rpc_binding_free(&aggr->ftserver_h, &status);
       free((void *)aggr);
     }

void
ftserver(aggr)
     DCE::DFS::aggregate aggr
     PPCODE:
     {
       DCE__DFS__ftserver ftserver;
       error_status_t status = 0;
       SV *sv = &PL_sv_undef;
       
       if (ftserver = (DCE__DFS__ftserver)malloc(sizeof(ftserver_obj)))
	 {
	   ftserver->addr = aggr->addr;
	   rpc_binding_copy(aggr->ftserver_h, &ftserver->ftserver_h, &status);
	   init_ftserver_state(ftserver);
	   
	   sv = sv_newmortal();
	   sv_setref_pv(sv,"DCE::DFS::ftserver", (void *)ftserver);
	 }
       else
	 status = sec_s_no_memory;
       
       XPUSHs(sv);
       sv = sv_2mortal(newSViv(status));
       XPUSHs(sv);
     }

void
name(aggr)
     DCE::DFS::aggregate aggr
     CODE:
       ST(0) = sv_2mortal(newSVpv(aggr->aggr_info.name, strlen(aggr->aggr_info.name)));

void
device(aggr)
     DCE::DFS::aggregate aggr
     CODE:
       ST(0) = sv_2mortal(newSVpv(aggr->aggr_info.devName, strlen(aggr->aggr_info.devName)));

int
id(aggr)
     DCE::DFS::aggregate aggr
     CODE:
       RETVAL = aggr->id;
     OUTPUT:
       RETVAL

int
type(aggr)
     DCE::DFS::aggregate aggr
     CODE:
       RETVAL = aggr->aggr_info.type;
     OUTPUT:
       RETVAL

int
size(aggr)
     DCE::DFS::aggregate aggr
     CODE:
       RETVAL = aggr->aggr_info.totalUsable;
     OUTPUT:
       RETVAL

int
free(aggr)
     DCE::DFS::aggregate aggr
     CODE:
       RETVAL = aggr->aggr_info.curFree;
     OUTPUT:
       RETVAL


MODULE = DCE::DFS		PACKAGE = DCE::DFS::fileset

void
DESTROY(fileset)
     DCE::DFS::fileset fileset
     CODE:
     {
       unsigned32 status;
       int index;

       for (index = 0; index < 16; index++)
	 if (fileset->ftserver_h_initialized & (1 << index))
	   rpc_binding_free(&fileset->ftserver_h[index], &status);
       
       free((void *)fileset);
     }

void
ftserver(fileset, ftserver_index = -1)
     DCE::DFS::fileset fileset
     int ftserver_index
     PPCODE:
     {
       DCE__DFS__ftserver ftserver;
       error_status_t status = 0;
       SV *sv = &PL_sv_undef;
       int index = ((ftserver_index == -1) ? fileset->ftserver_rw_index : ftserver_index);

       if (index < 0 || index >= fileset->entry.nServers)
	 status = REP_ERR_INVAL_PARAM;
       else if (!(ftserver = (DCE__DFS__ftserver)malloc(sizeof(ftserver_obj))))
	 status = sec_s_no_memory;
       else
	   {
	     if (!(fileset->ftserver_h_initialized & (1 << index)))
	       if (!(status = init_ftserver_h(&fileset->ftserver_h[index], &fileset->entry.siteAddr[index])))
		 fileset->ftserver_h_initialized |= (1 << index);

	     if (!status) {	       
	       ftserver->addr = fileset->entry.siteAddr[index];
	       rpc_binding_copy(fileset->ftserver_h[index], &ftserver->ftserver_h, &status);
	       init_ftserver_state(ftserver);
	       
	       sv = sv_newmortal();
	       sv_setref_pv(sv,"DCE::DFS::ftserver", (void *)ftserver);
	     }
	   }
       XPUSHs(sv);
       sv = sv_2mortal(newSViv(status));
       XPUSHs(sv);
     }

void
aggregate(fileset, ftserver_index = -1)
     DCE::DFS::fileset fileset
     int ftserver_index
     PPCODE:
     {
       DCE__DFS__aggregate aggr;
       error_status_t status = 0;
       int index = ((ftserver_index == -1) ? fileset->ftserver_rw_index : ftserver_index);
       SV *sv = &PL_sv_undef;

       if (index < 0 || index >= fileset->entry.nServers)
	 status = REP_ERR_INVAL_PARAM;
       else if (!(aggr = (DCE__DFS__aggregate)malloc(sizeof(aggregate_obj))))
	 status = sec_s_no_memory;
       else
	 {
	   if (!(fileset->ftserver_h_initialized & (1 << index)))
	     if (!(status = init_ftserver_h(&fileset->ftserver_h[index], &fileset->entry.siteAddr[index])))
	       fileset->ftserver_h_initialized |= (1 << index);

	   if (!status) {
	     
	     status = FTSERVER_AggregateInfo(fileset->ftserver_h[index],
					     fileset->entry.sitePartition[index], &aggr->aggr_info);
	       
	     if (!status)
	       {
		 rpc_binding_copy(fileset->ftserver_h[index], &aggr->ftserver_h, &status);
		 aggr->addr = fileset->entry.siteAddr[index];
		 aggr->id = fileset->entry.sitePartition[index];
		 sv = sv_newmortal();
		 sv_setref_pv(sv, "DCE::DFS::aggregate", (void *)aggr);
	       }
	   }
	 }
       XPUSHs(sv);
       sv = sv_2mortal(newSViv(status));
       XPUSHs(sv);
     }

void
name(fileset)
     DCE::DFS::fileset fileset
     CODE:
       ST(0) = sv_2mortal(newSVpv(fileset->entry.name, strlen(fileset->entry.name)));

int
ftserver_count(fileset)
     DCE::DFS::fileset fileset
     CODE:
     {
       RETVAL = fileset->entry.nServers;
     }
     OUTPUT:
       RETVAL

int
ftserver_index(fileset, ftserver)
     DCE::DFS::fileset fileset
     DCE::DFS::ftserver ftserver
     CODE:
     {
       int ftserver_index = -1;
       int index;

       for (index = 0; index < fileset->entry.nServers; index++)
	 if (memcmp((void *)&fileset->entry.siteAddr[index], (void *)&ftserver->addr, sizeof(ftserver->addr)) == 0)
	   ftserver_index = index;

       RETVAL = ftserver_index;
     }
     OUTPUT:
       RETVAL

int
exists(fileset, fileset_type, ftserver_index = -1)
     DCE::DFS::fileset fileset
     int fileset_type
     int ftserver_index
     CODE:
     {
       int exists = 0;

       if (ftserver_index == -1)
	 switch (fileset_type)
	   {
	   case 0:
	     exists = fileset->entry.flags & VLF_RWEXISTS;
	     break;
	   case 1:
	     exists = fileset->entry.flags & VLF_ROEXISTS;
	     break;
	   case 2:
	     exists = fileset->entry.flags & VLF_BACKEXISTS;
	     break;
	   }
       else if (ftserver_index >= 0 && ftserver_index < fileset->entry.nServers)
	 switch (fileset_type)
	   {
	   case 0:
	     exists = fileset->entry.siteFlags[ftserver_index] & fileset->rw_mask;
	     break;
	   case 1:
	     exists = fileset->entry.siteFlags[ftserver_index] & fileset->ro_mask;
	     break;
	   case 2:
	     exists = fileset->entry.siteFlags[ftserver_index] & fileset->bk_mask;
	     break;
	   }

       RETVAL = exists;
     }
     OUTPUT:
       RETVAL

void
usage(fileset, ftserver_index = -1, fileset_type = 0)
     DCE::DFS::fileset fileset
     int ftserver_index
     int fileset_type
     PPCODE:
     {
       SV *sv;
       error_status_t status;
       int index = ((ftserver_index == -1) ? fileset->ftserver_rw_index : ftserver_index);
       ftserver_status *ft_status = NULL;
       unsigned32 seconds, reads, writes;
       time_t now;

       status = update_fileset(fileset, index, fileset_type);
       now = time(NULL);

       if (!status)
	 {
	   
	   if (index < 0 || index >= fileset->entry.nServers || fileset_type < 0 || fileset_type > 2)
	     status = REP_ERR_INVAL_PARAM;
	   else if (fileset_type == 0) {
	     if (fileset->entry.siteFlags[index] & fileset->rw_mask)
	       ft_status = &fileset->rw_status;
	   }
	   else if (fileset_type == 1) {
	     if (fileset->entry.siteFlags[index] & fileset->ro_mask)
	       ft_status = &fileset->ro_status[index];
	   }
	   else if (fileset_type == 2) {
	     if (fileset->entry.siteFlags[index] & fileset->bk_mask)
	       ft_status = &fileset->bk_status;
	   }
	   
	   if (!ft_status)
	     status = REP_ERR_INVAL_PARAM;
	   else
	     {
	       seconds = now - ft_status->vss.countInitTime;
	       reads = ft_status->vss.readVnopCount;
	       writes = ft_status->vss.writeVnopCount;
	     }
	 }
       sv = sv_2mortal(newSViv(seconds));
       XPUSHs(sv);
       sv = sv_2mortal(newSViv(reads));
       XPUSHs(sv);
       sv = sv_2mortal(newSViv(writes));
       XPUSHs(sv);
       sv = sv_2mortal(newSViv(status));
       XPUSHs(sv);
     }
       
void
quota(fileset)
     DCE::DFS::fileset fileset
     PPCODE:
     {
       SV *sv;
       error_status_t status;
       unsigned32 quota, used;

       status = update_fileset(fileset, fileset->ftserver_rw_index, 0);
       
       if (!status) {
	 quota = ((0xffc00000 & (AFS_hgethi(fileset->rw_status.vsd.visQuotaLimit) << 22)) | (0x003fffff & (AFS_hgetlo(fileset->rw_status.vsd.visQuotaLimit) >> 10)));
	 used = ((0xffc00000 & (AFS_hgethi(fileset->rw_status.vsd.visQuotaUsage) << 22)) | (0x003fffff & (AFS_hgetlo(fileset->rw_status.vsd.visQuotaUsage) >> 10)));
       }
       
       sv = sv_2mortal(newSViv(quota));
       XPUSHs(sv);
       sv = sv_2mortal(newSViv(used));
       XPUSHs(sv);
       sv = sv_2mortal(newSViv(status));
       XPUSHs(sv);
     }

int
set_quota(fileset, quota)
     DCE::DFS::fileset fileset
     int quota
     CODE:
     {
       struct ftserver_status ft_status;
       long trans_id;
       error_status_t status = 0;

       if (!(fileset->ftserver_h_initialized & (1 << fileset->ftserver_rw_index)))
	 if (!(status = init_ftserver_h(&fileset->ftserver_h[fileset->ftserver_rw_index], &fileset->entry.siteAddr[fileset->ftserver_rw_index])))
	   fileset->ftserver_h_initialized |= (1 << fileset->ftserver_rw_index);

       if (!status)
	 if (!(status = FTSERVER_CreateTrans(fileset->ftserver_h[fileset->ftserver_rw_index], &fileset->entry.VolIDs[fileset->vol_id_rw_index],
					     fileset->entry.sitePartition[fileset->ftserver_rw_index],
					     FLAGS_ENCODE(FTSERVER_OP_SETSTATUS, VOLERR_TRANS_SETQUOTA),
					     &trans_id)))
	   {
	     AFS_hset32(ft_status.vsd.visQuotaLimit, quota);
	     AFS_hleftshift(ft_status.vsd.visQuotaLimit, 10);
	     
	     if (status = FTSERVER_SetStatus(fileset->ftserver_h[fileset->ftserver_rw_index], trans_id, VOL_STAT_VISLIMIT, &ft_status, 0))
	       FTSERVER_AbortTrans(fileset->ftserver_h[fileset->ftserver_rw_index], trans_id);
	     else
	       FTSERVER_DeleteTrans(fileset->ftserver_h[fileset->ftserver_rw_index], trans_id);
	   }
       
       RETVAL = status;
     }
     OUTPUT:
       RETVAL



