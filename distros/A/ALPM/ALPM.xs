#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <alpm.h>
#include "types.h"
#include "cb.h"

#define alpm_croak(HND)\
	croak("ALPM Error: %s", alpm_strerror(alpm_errno(HND)));

MODULE = ALPM	PACKAGE = ALPM

PROTOTYPES: DISABLE

# ALPM::PackageFree is a subclass of ALPM::Package.
# ALPM::DB::Sync and ALPM::DB::Local are each subclasses of ALPM::DB.
BOOT:
	av_push(get_av("ALPM::PackageFree::ISA", GV_ADD), newSVpv("ALPM::Package", 0));
	av_push(get_av("ALPM::DB::Sync::ISA", GV_ADD), newSVpv("ALPM::DB", 0));
	av_push(get_av("ALPM::DB::Local::ISA", GV_ADD), newSVpv("ALPM::DB", 0));

MODULE = ALPM	PACKAGE = ALPM::PackageFree

void
DESTROY(self)
	ALPM_PackageFree self;
 PPCODE:
	alpm_pkg_free(self);

#---------------------
# PUBLIC ALPM METHODS
#---------------------

MODULE = ALPM	PACKAGE = ALPM

ALPM_Handle
new(class, root, dbpath)
	SV * class
	char * root
	char * dbpath
 PREINIT:
	alpm_errno_t err;
	ALPM_Handle h;
 CODE:
	h = alpm_initialize(root, dbpath, &err);
	if(h == NULL){
		croak("ALPM Error: %s", alpm_strerror(err));
	}
	RETVAL = h;
 OUTPUT:
	RETVAL

void
DESTROY(self)
	ALPM_Handle self;
 PREINIT:
	int ret;
 CODE:
	ret = alpm_release(self);
	if(ret == -1){
		croak("ALPM Error: failed to release ALPM handle");
	}
	# errno is only inside a handle, which was just released...

void
caps(class)
	SV * class
 PREINIT:
	enum alpm_caps c;
 PPCODE:
	c = alpm_capabilities();
	if(c & ALPM_CAPABILITY_NLS){
		XPUSHs(sv_2mortal(newSVpv("nls", 0)));
	}	
	if(c & ALPM_CAPABILITY_DOWNLOADER){
		XPUSHs(sv_2mortal(newSVpv("download", 0)));
	}
	if(c & ALPM_CAPABILITY_SIGNATURES){
		XPUSHs(sv_2mortal(newSVpv("signatures", 0)));
	}

const char *
version(class)
	SV * class
 CODE:
	RETVAL = alpm_version();
 OUTPUT:
	RETVAL

const char *
strerror(self)
	ALPM_Handle self;
 CODE:
	RETVAL = alpm_strerror(alpm_errno(self));
 OUTPUT:
	RETVAL

int
errno(self)
	ALPM_Handle self
 CODE:
	RETVAL = alpm_errno(self);
 OUTPUT:
	RETVAL

ALPM_Package
find_satisfier(self, depstr, ...)
	SV * self
	const char * depstr
 PREINIT:
	alpm_list_t *pkgs;
	int i;
 CODE:
	i = 2;
	STACK2LIST(i, pkgs, p2c_pkg);
	RETVAL = alpm_find_satisfier(pkgs, depstr);
	alpm_list_free(pkgs);
 OUTPUT:
	RETVAL

ALPM_Package
find_dbs_satisfier(self, depstr, ...)
	ALPM_Handle self
	const char * depstr
 PREINIT:
	alpm_list_t *dbs;
	int i;
 CODE:
	i = 2;
	STACK2LIST(i, dbs, p2c_db);
	RETVAL = alpm_find_dbs_satisfier(self, dbs, depstr);
	alpm_list_free(dbs);
 OUTPUT:
	RETVAL

void
check_conflicts(self, ...)
	ALPM_Handle self
 PREINIT:
	alpm_list_t *L, *clist;
	int i;
 PPCODE:
	i = 1;
	STACK2LIST(i, L, p2c_pkg);
	L = clist = alpm_checkconflicts(self, L);
	LIST2STACK(clist, c2p_conflict);
	ZAPLIST(L, freeconflict);

SV *
fetch_pkgurl(self, url)
	ALPM_Handle self
	const char * url
 PREINIT:
	char * path;
 CODE:
	path = alpm_fetch_pkgurl(self, url);
	if(path == NULL){
		RETVAL = &PL_sv_undef;
	}else{
		RETVAL = sv_2mortal(newSVpv(path, strlen(path)));
	}
 OUTPUT:
	RETVAL

## Why name this register_sync when there is no register_local? Redundant.

ALPM_SyncDB
register(self, name, ...)
	ALPM_Handle self
	const char * name
 PREINIT:
	alpm_siglevel_t siglvl;
 CODE:
	if(items >= 3){
		siglvl = p2c_siglevel(ST(2));
	}else{
		siglvl = ALPM_SIG_USE_DEFAULT;
	}
	RETVAL = alpm_register_syncdb(self, name, siglvl);
 OUTPUT:
	RETVAL

negative_is_error
unregister_all(self)
	ALPM_Handle self
 CODE:
	RETVAL = alpm_unregister_all_syncdbs(self);
 OUTPUT:
	RETVAL

# Packages created with load_pkgfile must be freed by the caller.
# Hence we use ALPM_PackageFree. NULL pointers are converted
# into undef by the typemap.

ALPM_PackageFree
load_pkgfile(self, filename, full, siglevel)
	ALPM_Handle self
	const char *filename
	int full
	ALPM_SigLevel siglevel
 CODE:
	RETVAL = NULL;
	alpm_pkg_load(self, filename, full, siglevel, &RETVAL);
 OUTPUT:
	RETVAL

int
vercmp(unused, a, b)
	SV * unused
	const char *a
	const char *b
 CODE:
	RETVAL = alpm_pkg_vercmp(a, b);
 OUTPUT:
	RETVAL

INCLUDE: xs/Options.xs

INCLUDE: xs/Package.xs

INCLUDE: xs/DB.xs

# INCLUDE: xs/Transaction.xs

# EOF
