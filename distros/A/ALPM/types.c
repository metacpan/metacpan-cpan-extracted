#include <stdlib.h>
#include <string.h>
#include <alpm.h>

/* Perl API headers. */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "types.h"

/* SCALAR CONVERSIONS */

SV*
c2p_str(void *str)
{
	return newSVpv(str, 0);
}

const char*
p2c_str(SV *sv)
{
	char *pstr, *cstr;
	STRLEN len;

	/* pstr is not guaranteed to be NULL terminated so make a copy */
	pstr = SvPV(sv, len);
	cstr = calloc(len + 1, sizeof(char));
	memcpy(cstr, pstr, len);
	return cstr;
}

SV*
c2p_pkg(void *p)
{
	SV *rv = newSV(0);
	return sv_setref_pv(rv, "ALPM::Package", p);
}

ALPM_Package
p2c_pkg(SV *pkgobj)
{
	return INT2PTR(ALPM_Package, SvIV((SV*)SvRV(pkgobj)));
}

ALPM_DB
p2c_db(SV *db)
{
	return INT2PTR(ALPM_DB, SvIV((SV*)SvRV(db)));
}

SV*
c2p_localdb(void *db)
{
	SV *rv = newSV(0);
	sv_setref_pv(rv, "ALPM::DB::Local", db);
	return rv;
}

SV*
c2p_syncdb(void *db)
{
	SV *rv = newSV(0);
	sv_setref_pv(rv, "ALPM::DB::Sync", db);
	return rv;
}

SV*
c2p_db(void *db)
{
    if(strcmp(alpm_db_get_name(db), "local") == 0) {
        return c2p_localdb(db);
    } else {
        return c2p_syncdb(db);
    }
}

SV*
c2p_depmod(alpm_depmod_t mod)
{
	char *cmp;
	switch(mod){
	case 0:
	case ALPM_DEP_MOD_ANY: cmp = ""; break; /* ? */
	case ALPM_DEP_MOD_EQ: cmp = "="; break;
	case ALPM_DEP_MOD_GE: cmp = ">="; break;
	case ALPM_DEP_MOD_LE: cmp = "<="; break;
	case ALPM_DEP_MOD_GT: cmp = ">"; break;
	case ALPM_DEP_MOD_LT: cmp = "<"; break;
	default: cmp = "?";
	}

	return newSVpv(cmp, 0);
}

alpm_depmod_t
p2c_depmod(SV* mod)
{
	char *cmp = SvPV_nolen(mod);
	if(!cmp || strcmp(cmp, "") == 0) { return ALPM_DEP_MOD_ANY; }
	else if(strcmp(cmp, "=") == 0) { return ALPM_DEP_MOD_EQ; }
	else if(strcmp(cmp, ">=") == 0) { return ALPM_DEP_MOD_GE; }
	else if(strcmp(cmp, "<=") == 0) { return ALPM_DEP_MOD_LE; }
	else if(strcmp(cmp, ">") == 0) { return ALPM_DEP_MOD_GT; }
	else if(strcmp(cmp, "<") == 0) { return ALPM_DEP_MOD_LT; }
	else { return 0; /* TODO: croak */ }
}

SV*
c2p_depend(void *p)
{
	alpm_depend_t *dep;
	HV *hv;
	hv = newHV();
	dep = p;

	hv_store(hv, "name", 4, newSVpv(dep->name, 0), 0);
	hv_store(hv, "version", 7, newSVpv(dep->version, 0), 0);
	hv_store(hv, "mod", 3, c2p_depmod(dep->mod), 0);
	if(dep->desc) hv_store(hv, "desc", 4, newSVpv(dep->desc, 0), 0);
	return newRV_noinc((SV*)hv);
}

alpm_depend_t*
p2c_depend(SV *rv)
{
	 if(SvROK(rv)) {
		 alpm_depend_t *dep = calloc(sizeof(alpm_depend_t), 1);
		 HV *hv = (HV*) SvRV(rv);
		 SV **v;

		 v = hv_fetch(hv, "name", 4, 0);
		 dep->name = v ? strdup(SvPV_nolen(*v)) : NULL;
		 v = hv_fetch(hv, "version", 7, 0);
		 dep->version = v ? strdup(SvPV_nolen(*v)) : NULL;
		 v = hv_fetch(hv, "desc", 4, 0);
		 dep->desc = v ? strdup(SvPV_nolen(*v)) : NULL;
		 v = hv_fetch(hv, "mod", 3, 0);
		 dep->mod = v ? p2c_depmod(*v) : 0;

		 return dep;
	 } else {
		 return alpm_dep_from_string(SvPV_nolen(rv));
	 }
}

SV*
c2p_conflict(void *p)
{
	alpm_conflict_t *c;
	HV *hv;
	hv = newHV();
	c = p;

	hv_store(hv, "package1", 8, newSVpv(c->package1, 0), 0);
	hv_store(hv, "package2", 8, newSVpv(c->package2, 0), 0);
	hv_store(hv, "reason", 6, c2p_depend(c->reason), 0);
	return newRV_noinc((SV*)hv);
}

static SV*
c2p_file(alpm_file_t *file){
	HV *hv;
	hv = newHV();
	hv_store(hv, "name", 4, newSVpv(file->name, 0), 0);
	hv_store(hv, "size", 4, newSViv(file->size), 0);
	hv_store(hv, "mode", 4, newSViv(file->mode), 0);
	return newRV_noinc((SV*)hv);
}

SV*
c2p_filelist(void *flistPtr){
	alpm_filelist_t *flist;
	AV *av;
	int i;

	flist = flistPtr;
	av = newAV();
	for(i = 0; i < flist->count; i++){
		av_push(av, c2p_file(flist->files + i));
	}
	return newRV_noinc((SV*)av);
}

/*
This deals with only raw bits, which is bad form, but I prefer the design.
If the alpm_siglevel_t bitflag enum was not so strange, I wouldn't have
chosen to do this.

The bit flags are separated into two halves with a special case of the
"default value" where bit 32 (the MSB) is on. Reading from LSB to MSB,
the package flags consist of the first four bits. 6 unused bits follow.
The database flags consist of the next four bits. 17 unused bits follow.
Finally, the bit flag for ALPM_USE_DEFAULT is the MSB.

Here is the form of the package and database bitmask. Remember the
database flags are shifted to the left by 10 places.

BIT	DESCRIPTION
1	Signature checking is enabled for packages or databases respectively.
2	Signature checking is optional, used only when available.
3	MARGINAL_OK?
4	UNKNOWN_OK?

A setting of TrustAll in pacman.conf enables MARGINAL_OK and UNKNOWN_OK.
These two flags are not enabled separately from one another.

ALPM_SIG_USE_DEFAULT is the default value when set_default_siglevel is never
called but I have no idea what that could mean when this is the value of the default.
This seems to be a circular argument with no end.

*/

#define MASK_ENABLE 1
#define MASK_OPT 3
#define MASK_TRUSTALL 12
#define MASK_ALL 15
#define OFFSET_DB 10

static
SV* truststring(unsigned long siglvl)
{
	SV *str;
	if(!(siglvl & MASK_ENABLE)){
		return newSVpv("never", 0);
	}else if(!(~siglvl & MASK_OPT)){
		str = newSVpv("optional", 0);
	}else{
		str = newSVpv("required", 0);
	}
	if(!(~siglvl & MASK_TRUSTALL)){
		sv_catpv(str, " trustall");
	}
	return str;
}

/* converts siglevel bitflags into a string (default/never) or hashref of strings */
SV*
c2p_siglevel(alpm_siglevel_t sig)
{
	HV *hv;

	if(sig & ALPM_SIG_USE_DEFAULT){
		return newSVpv("default", 7);
	}

	hv = newHV();
	hv_store(hv, "pkg", 3, truststring(sig & MASK_ALL), 0);
	hv_store(hv, "db", 2, truststring((sig >> OFFSET_DB) & MASK_ALL), 0);
	return newRV_noinc((SV*)hv);
}

static unsigned long
trustmask(char *str, STRLEN len)
{
	unsigned long flags;

	if(len == 5 && strncmp(str, "never", 5) == 0){
		return 0;
	}

	if(len < 8){
		goto badstr;
	}else if(strncmp(str, "required", 8) == 0){
		flags = MASK_ENABLE;
	}else if(strncmp(str, "optional", 8) == 0){
		flags = MASK_OPT;
	}else {
		goto badstr;
	}

	if(len == 8){
		/* Conveniently, the strings "required" and "optional" are both 8 characters long. */
		return flags;
	}else if(len != 17 || strncmp(str + 8, " trustall", 8) != 0){
		goto badstr;
	}
	return flags | MASK_TRUSTALL;

	badstr:
	croak("Unrecognized signature level string: %s", str);
}

static unsigned long
fetch_trustmask(HV *hv, const char *key){
	SV **val;
	char *str;
	STRLEN len;

	val = hv_fetch(hv, key, strlen(key), 0);
	if(val == NULL){
		croak("Invalid signature level hash: %s key is missing", key);
	}
	str = SvPV(*val, len);
	return trustmask(str, len);
}

/* converts a siglevel string or hashref into bitflags. */
alpm_siglevel_t
p2c_siglevel(SV *sig)
{
	char *str;
	STRLEN len;
	alpm_siglevel_t ret;
	HV *hv;

	if(SvPOK(sig)){
		str = SvPV(sig, len);
		if(len == 7 && strncmp(str, "default", len) == 0){
			return ALPM_SIG_USE_DEFAULT;
		}else {
			/* XXX: might not be null terminated? */
			croak("Unrecognized global signature level string: %s", str);
		}
	}else if(SvROK(sig) && SvTYPE(SvRV(sig)) == SVt_PVHV){
		hv = (HV*)SvRV(sig);
		ret = fetch_trustmask(hv, "pkg");
		ret |= fetch_trustmask(hv, "db") << OFFSET_DB;
		return ret;
	}
	croak("A global signature level must be a string or hash reference");
}

#undef MASK_ENABLE
#undef MASK_OPT
#undef MASK_TRUSTALL
#undef MASK_ALL
#undef OFFSET_DB

SV*
c2p_pkgreason(alpm_pkgreason_t rsn)
{
	switch(rsn){
	case ALPM_PKG_REASON_EXPLICIT:
		return newSVpv("explicit", 0);
	case ALPM_PKG_REASON_DEPEND:
		return newSVpv("implicit", 0);
	}

	croak("unrecognized pkgreason enum");
}

alpm_pkgreason_t
p2c_pkgreason(SV *sv)
{
	STRLEN len;
	char *rstr;

	if(SvIOK(sv)){
		switch(SvIV(sv)){
		case 0: return ALPM_PKG_REASON_EXPLICIT;
		case 1: return ALPM_PKG_REASON_DEPEND;
		}
		croak("integer reasons must be 0 or 1");
	}else if(SvPOK(sv)){
		rstr = SvPV(sv, len);
		if(strncmp(rstr, "explicit", len) == 0){
			return ALPM_PKG_REASON_EXPLICIT;
		}else if(strncmp(rstr, "implicit", len) == 0
			|| strncmp(rstr, "depend", len) == 0){
			return ALPM_PKG_REASON_DEPEND;
		}else{
			croak("string reasons can only be explicit or implicit/depend");
		}
	}else{
		croak("reasons can only be integers or strings");
	}
}

SV *
c2p_pkgfrom(alpm_pkgfrom_t from)
{
	char *str;

	switch(from){
	case ALPM_PKG_FROM_FILE: str = "file"; break;
	case ALPM_PKG_FROM_LOCALDB: str = "localdb"; break;
	case ALPM_PKG_FROM_SYNCDB: str = "syncdb"; break;
	default: str = "unknown"; break;
	}

	return newSVpv(str, 0);
}

SV *
c2p_pkgvalidation(alpm_pkgvalidation_t v)
{
	char buf[128] = "";
	int len;

	if(v == ALPM_PKG_VALIDATION_UNKNOWN) goto unknown;
	if(v & ALPM_PKG_VALIDATION_NONE) strcat(buf, "none ");
	if(v & ALPM_PKG_VALIDATION_MD5SUM) strcat(buf, "MD5 ");
	if(v & ALPM_PKG_VALIDATION_SHA256SUM) strcat(buf, "SHA ");
	if(v & ALPM_PKG_VALIDATION_SIGNATURE) strcat(buf, "PGP ");

	if((len = strlen(buf)) == 0) goto unknown;
	return newSVpv(buf, len-1);

unknown:
	return newSVpv("unknown", 0);
}

/* LIST CONVERSIONS */

AV *
list2av(alpm_list_t *L, scalarmap F)
{
	AV *av;
	av = newAV();
	while(L){
		av_push(av, F(L->data));
		L = alpm_list_next(L);
	}
	return av;
}

alpm_list_t *
av2list(AV *A, listmap F)
{
	alpm_list_t *L;
	int i;
	SV **sv;

	L = NULL;
	for(i = 0; i < av_len(A); i++){
		sv = av_fetch(A, i, 0);
		L = alpm_list_add(L, F(*sv));
	}
	return L;
}

void
freedepend(void *p)
{
	free((alpm_depend_t*)p);
}

void
freeconflict(void *p)
{
	alpm_conflict_t *c;
	c = p;
	freedepend(c->reason);
	free(c);
}
