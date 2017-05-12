MODULE = ALPM	PACKAGE = ALPM

## CALLBACKS

SV*
get_logcb(...)
 CODE:
	RETVAL = (logcb_ref ? newSVsv(logcb_ref) : &PL_sv_undef);
 OUTPUT:
	RETVAL

SV*
get_dlcb(...)
 CODE:
	RETVAL = (dlcb_ref ? newSVsv(dlcb_ref) : &PL_sv_undef);
 OUTPUT:
	RETVAL

SV*
get_fetchcb(...)
 CODE:
	RETVAL = (fetchcb_ref ? newSVsv(fetchcb_ref) : &PL_sv_undef);
 OUTPUT:
	RETVAL

SV*
get_totaldlcb(...)
 CODE:
	RETVAL = (totaldlcb_ref ? newSVsv(totaldlcb_ref) : &PL_sv_undef);
 OUTPUT:
	RETVAL

MODULE = ALPM	PACKAGE = ALPM	PREFIX = alpm_option_

void
alpm_option_set_logcb(self, cb)
	ALPM_Handle self
	SV * cb
 CODE:
	DEFSETCB(log, self, cb)

void
alpm_option_set_dlcb(self, cb)
	ALPM_Handle self
	SV * cb
 CODE:
	DEFSETCB(dl, self, cb)

void
alpm_option_set_fetchcb(self, cb)
	ALPM_Handle self
	SV * cb
 CODE:
	DEFSETCB(fetch, self, cb)

void
alpm_option_set_totaldlcb(self, cb)
	ALPM_Handle self
	SV * cb
 CODE:
	DEFSETCB(totaldl, self, cb)

## REGULAR OPTIONS

StringOption
option_string_get(self)
	ALPM_Handle self
 INTERFACE:
	alpm_option_get_logfile
	alpm_option_get_lockfile
	alpm_option_get_arch
	alpm_option_get_gpgdir
	alpm_option_get_root
	alpm_option_get_dbpath

SetOption
option_string_set(self, string)
	ALPM_Handle self
	const char * string
 INTERFACE:
	alpm_option_set_logfile
	alpm_option_set_arch
	alpm_option_set_gpgdir

# String List Options

void
alpm_option_get_cachedirs(self)
	ALPM_Handle self
 PREINIT:
	alpm_list_t *lst;
 PPCODE:
	lst = alpm_option_get_cachedirs(self);
	LIST2STACK(lst, c2p_str);

void
alpm_option_get_noupgrades(self)
	ALPM_Handle self
 PREINIT:
	alpm_list_t *lst;
 PPCODE:
	lst = alpm_option_get_noupgrades(self);
	LIST2STACK(lst, c2p_str);

void
alpm_option_get_noextracts(self)
	ALPM_Handle self
 PREINIT:
	alpm_list_t *lst;
 PPCODE:
	lst = alpm_option_get_noextracts(self);
	LIST2STACK(lst, c2p_str);

void
alpm_option_get_ignorepkgs(self)
	ALPM_Handle self
 PREINIT:
	alpm_list_t *lst;
 PPCODE:
	lst = alpm_option_get_ignorepkgs(self);
	LIST2STACK(lst, c2p_str);

void
alpm_option_get_ignoregroups(self)
	ALPM_Handle self
 PREINIT:
	alpm_list_t *lst;
 PPCODE:
	lst = alpm_option_get_ignoregroups(self);
	LIST2STACK(lst, c2p_str);

SetOption
option_stringlist_add(self, add_string)
	ALPM_Handle self
	const char *add_string
 INTERFACE:
	alpm_option_add_noupgrade
	alpm_option_add_noextract
	alpm_option_add_ignorepkg
	alpm_option_add_ignoregroup
	alpm_option_add_cachedir

SetOption
alpm_option_set_cachedirs(self, ...)
	ALPM_Handle self
 PREINIT:
	alpm_list_t *lst;
	int i;
 CODE:
	i = 1;
	STACK2LIST(i, lst, p2c_str);
	RETVAL = alpm_option_set_cachedirs(self, lst);
	ZAPLIST(lst, free);
 OUTPUT:
	RETVAL

SetOption
alpm_option_set_noupgrades(self, ...)
	ALPM_Handle self
 PREINIT:
	alpm_list_t *lst;
	int i;
 CODE:
	i = 1;
	STACK2LIST(i, lst, p2c_str);
	RETVAL = alpm_option_set_noupgrades(self, lst);
	ZAPLIST(lst, free);
 OUTPUT:
	RETVAL

SetOption
alpm_option_set_noextracts(self, ...)
	ALPM_Handle self
 PREINIT:
	alpm_list_t *lst;
	int i;
 CODE:
	i = 1;
	STACK2LIST(i, lst, p2c_str);
	RETVAL = alpm_option_set_noextracts(self, lst);
	ZAPLIST(lst, free);
 OUTPUT:
	RETVAL

SetOption
alpm_option_set_ignorepkgs(self, ...)
	ALPM_Handle self
 PREINIT:
	alpm_list_t *lst;
	int i;
 CODE:
	i = 1;
	STACK2LIST(i, lst, p2c_str);
	RETVAL = alpm_option_set_ignorepkgs(self, lst);
	ZAPLIST(lst, free);
 OUTPUT:
	RETVAL

SetOption
alpm_option_set_ignoregroups(self, ...)
	ALPM_Handle self
 PREINIT:
	alpm_list_t *lst;
	int i;
 CODE:
	i = 1;
	STACK2LIST(i, lst, p2c_str);
	RETVAL = alpm_option_set_ignoregroups(self, lst);
	ZAPLIST(lst, free);
 OUTPUT:
	RETVAL

# Use IntOption to return the number of items removed (0 or 1).

IntOption
option_stringlist_remove(self, badstring)
	ALPM_Handle self
	const char * badstring
INTERFACE:
	alpm_option_remove_cachedir
	alpm_option_remove_noupgrade
	alpm_option_remove_noextract
	alpm_option_remove_ignorepkg
	alpm_option_remove_ignoregroup

IntOption
option_int_get(self)
	ALPM_Handle self
INTERFACE:
	alpm_option_get_usesyslog
	alpm_option_get_checkspace

SetOption
option_int_set(self, new_int)
	ALPM_Handle self
	int new_int
INTERFACE:
	alpm_option_set_usesyslog
	alpm_option_set_checkspace

double
alpm_option_get_deltaratio(self)
	ALPM_Handle self

SetOption
alpm_option_set_deltaratio(self, ratio)
	ALPM_Handle self
	double ratio

SetOption
alpm_option_add_assumeinstalled(self, dep)
	 ALPM_Handle self
	 ALPM_Depend dep

SetOption
alpm_option_remove_assumeinstalled(self, dep)
	 ALPM_Handle self
	 ALPM_Depend dep

void
alpm_option_get_assumeinstalled(self)
	 ALPM_Handle self
 PREINIT:
	 alpm_list_t *l;
 PPCODE:
	 l = alpm_option_get_assumeinstalled(self);
	 LIST2STACK(l, c2p_depend);

SetOption
alpm_option_set_assumeinstalled(self, ...)
	ALPM_Handle self
 PREINIT:
	alpm_list_t *lst = NULL;
	int i = 1;
 CODE:
	STACK2LIST(i, lst, p2c_depend);
	RETVAL = alpm_option_set_assumeinstalled(self, lst);
 OUTPUT:
	RETVAL

MODULE = ALPM	PACKAGE = ALPM	PREFIX = alpm_option_

# Why have get_localdb when there is no set_localdb? s/get_//;

ALPM_LocalDB
localdb(self)
	ALPM_Handle self
 CODE:
	RETVAL = alpm_get_localdb(self);
 OUTPUT:
	RETVAL

# Ditto.

void
syncdbs(self)
	ALPM_Handle self
 PREINIT:
	alpm_list_t *lst;
 PPCODE:
	lst = alpm_get_syncdbs(self);
	if(lst == NULL && alpm_errno(self)) alpm_croak(self);
	LIST2STACK(lst, c2p_syncdb);

ALPM_SigLevel
get_defsiglvl(self)
	ALPM_Handle self
 CODE:
	RETVAL = alpm_option_get_default_siglevel(self);
 OUTPUT:
	RETVAL

SetOption
set_defsiglvl(self, siglvl)
	ALPM_Handle self
	SV* siglvl
 CODE:
	if(strcmp(SvPV_nolen(siglvl), "default") == 0){
		croak("Default signature level cannot itself be set to default. You hear the sound of one hand clapping");
	}else{
		RETVAL = alpm_option_set_default_siglevel(self, p2c_siglevel(siglvl));
	}
 OUTPUT:
	RETVAL

# EOF
