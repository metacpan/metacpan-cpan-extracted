#------------------------
# PUBLIC DATABASE METHODS
#------------------------

MODULE = ALPM	PACKAGE = ALPM::DB

void
pkgs(db)
	ALPM_DB db
 PREINIT:
	alpm_list_t *pkgs;
 PPCODE:
	pkgs = alpm_db_get_pkgcache(db);
	# If pkgs is NULL, we can't report the error because errno is in the handle object.
	LIST2STACK(pkgs, c2p_pkg);

# groups returns a list of pairs. Each pair is a group name followed by
# an array ref of packages belonging to the group.

void
groups(db)
	ALPM_DB db
 PREINIT:
	alpm_list_t *grps;
	alpm_group_t *grp;
	AV *pkgarr;
 PPCODE:
	grps = alpm_db_get_groupcache(db);
	while(grps){
		grp = grps->data;
		XPUSHs(sv_2mortal(newSVpv(grp->name, strlen(grp->name))));
		pkgarr = list2av(grp->packages, c2p_pkg);
		XPUSHs(sv_2mortal(newRV_noinc((SV*)pkgarr)));
		grps = alpm_list_next(grps);
	}

const char *
name(db)
	ALPM_DB db
 CODE:
	RETVAL = alpm_db_get_name(db);
 OUTPUT:
	RETVAL

SV *
find(db, name)
	ALPM_DB db
	const char *name
 PREINIT:
	ALPM_Package pkg;
 CODE:
	pkg = alpm_db_get_pkg(db, name);
	RETVAL = (pkg == NULL ? &PL_sv_undef
		: c2p_pkg(pkg));
 OUTPUT:
	RETVAL

void
find_group(db, name)
	ALPM_DB db
	const char *name
 PREINIT:
	alpm_group_t *grp;
	alpm_list_t *pkgs;
 PPCODE:
	grp = alpm_db_get_group(db, name);
	if(grp){
		pkgs = grp->packages;
		LIST2STACK(pkgs, c2p_pkg);
	}

void
search(db, ...)
	ALPM_DB db
 PREINIT:
	alpm_list_t *L, *terms, *fnd;
	int i;
 PPCODE:
	i = 1;
	STACK2LIST(i, terms, p2c_str);
	L = fnd = alpm_db_search(db, terms);
	ZAPLIST(terms, free);
	LIST2STACK(fnd, c2p_pkg);
	alpm_list_free(L);

#-----------------------------
# PUBLIC LOCAL DATABASE METHODS
#-----------------------------

MODULE = ALPM   PACKAGE = ALPM::DB::Local

negative_is_error
set_install_reason(self, pkg, rsn)
	ALPM_LocalDB self
	ALPM_Package pkg
	alpm_pkgreason_t rsn
 CODE:
	RETVAL = alpm_pkg_set_reason(pkg, rsn);
 OUTPUT:
	RETVAL

#-----------------------------
# PUBLIC SYNC DATABASE METHODS
#-----------------------------

MODULE = ALPM   PACKAGE = ALPM::DB::Sync

int
update(db)
	ALPM_SyncDB db
 PREINIT:
	int ret;
 CODE:
	ret = alpm_db_update(0, db);
	switch(ret){
	case 0: RETVAL = 1; break;
	case 1: RETVAL = -1; break; /* DB did not need to be updated */
	case -1: RETVAL = 0; break;
	default: croak("Unrecognized return value of alpm_db_update");
	}
 OUTPUT:
	RETVAL

negative_is_error
force_update(db)
	ALPM_SyncDB db
 CODE:
	RETVAL = alpm_db_update(1, db);
 OUTPUT:
	RETVAL

ALPM_SigLevel
siglvl(db)
	ALPM_SyncDB db
 CODE:
	RETVAL = alpm_db_get_siglevel(db);
 OUTPUT:
	RETVAL

MODULE = ALPM   PACKAGE = ALPM::DB::Sync    PREFIX = alpm_db_

negative_is_error
alpm_db_unregister(self)
	ALPM_SyncDB self

negative_is_error
alpm_db_add_server(self, url)
	ALPM_SyncDB self
	const char *url

negative_is_error
alpm_db_remove_server(self, url)
	ALPM_SyncDB self
	const char *url

void alpm_db_get_servers(self)
	ALPM_SyncDB self
 PREINIT:
	alpm_list_t *srvs;
 PPCODE:
	srvs = alpm_db_get_servers(self);
	LIST2STACK(srvs, c2p_str);

negative_is_error
alpm_db_set_servers(self, ...)
	ALPM_SyncDB self
 PREINIT:
	alpm_list_t *L;
	int i;
 CODE:
	i = 1;
	STACK2LIST(i, L, p2c_str);
	RETVAL = alpm_db_set_servers(self, L);
 OUTPUT:
	RETVAL

MODULE = ALPM	PACKAGE = ALPM::DB::Sync	PREFIX = alpm_db_get_

int
alpm_db_get_valid(db)
	ALPM_SyncDB db
