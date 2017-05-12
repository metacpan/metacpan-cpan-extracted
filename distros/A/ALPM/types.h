#ifndef _ALPMXS_TYPES
#define _ALPMXS_TYPES

/* TYPEDEFS */

/* Used in typemap and xs/Options.xs. */
typedef int SetOption;
typedef int IntOption;
typedef char * StringOption;

typedef int negative_is_error;
typedef alpm_handle_t * ALPM_Handle;
typedef alpm_db_t * ALPM_DB;
typedef alpm_db_t * ALPM_LocalDB;
typedef alpm_db_t * ALPM_SyncDB;
typedef alpm_pkg_t * ALPM_Package;
typedef alpm_pkg_t * ALPM_PackageFree;
typedef alpm_siglevel_t ALPM_SigLevel;
typedef alpm_pkgfrom_t ALPM_Origin;
typedef alpm_pkgvalidation_t ALPM_Validity;

typedef alpm_depend_t * ALPM_Depend;
typedef alpm_conflict_t * ConflictArray;

typedef alpm_list_t * StringListFree;
typedef alpm_list_t * StringList;
typedef alpm_list_t * PackageListNoFree;
typedef alpm_list_t * DependList;
typedef alpm_list_t * ListAutoFree;

typedef alpm_filelist_t * ALPM_FileList;

/* these are for list converter functions */
typedef SV* (*scalarmap)(void*);
typedef void* (*listmap)(SV*);

/* CONVERTER FUNC PROTOS */

SV* c2p_str(void*);
const char* p2c_str(SV*);

SV* c2p_pkg(void*);
ALPM_Package p2c_pkg(SV*);

ALPM_DB p2c_db(SV*);

SV* c2p_db(void*);
SV* c2p_localdb(void*);
SV* c2p_syncdb(void*);
SV* c2p_depmod(alpm_depmod_t);
alpm_depmod_t p2c_depmod(SV*);
SV* c2p_depend(void *);
alpm_depend_t* p2c_depend(SV*);
SV* c2p_conflict(void *);
SV* c2p_filelist(void *);

SV* c2p_siglevel(alpm_siglevel_t);
alpm_siglevel_t p2c_siglevel(SV*);

SV* c2p_pkgreason(alpm_pkgreason_t);
alpm_pkgreason_t p2c_pkgreason(SV*);

SV* c2p_pkgfrom(alpm_pkgfrom_t);
SV* c2p_pkgvalidation(alpm_pkgvalidation_t);

/* LIST CONVERTER FUNC PROTOS */

AV* list2av(alpm_list_t*, scalarmap);
alpm_list_t* av2list(AV*, listmap);

#define LIST2STACK(L, F)\
	while(L){\
		XPUSHs(sv_2mortal(F(L->data)));\
		L = alpm_list_next(L);\
	}

#define STACK2LIST(I, L, F)\
	L = NULL;\
	while(I < items){\
		L = alpm_list_add(L, (void*)F(ST(I++)));\
	}

#define ZAPLIST(L, F)\
	alpm_list_free_inner(L, F);\
	alpm_list_free(L);\
	L = NULL

/* MEMORY DEALLOCATION */

void freedepend(void *);
void freeconflict(void *);

#endif /*_ALPMXS_TYPES */
