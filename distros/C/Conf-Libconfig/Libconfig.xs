// vi:filetype=c noet sw=4 ts=4 fdm=marker

#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include <libconfig.h>

#define UINTNUM 2147483647

typedef config_t *Conf__Libconfig;
typedef config_setting_t *Conf__Libconfig__Settings;

void set_scalar(config_setting_t *, SV *, int , int *);
void set_scalar_elem(config_setting_t *, int, SV *, int, int *);
void set_array(config_setting_t *, AV *, int *);
void set_hash(config_setting_t *, HV *, int *, int);
int set_scalarvalue(config_setting_t *, const char *, SV *, int, int);
int set_arrayvalue(config_setting_t *, const char *, AV *, int);
int set_hashvalue(config_setting_t *, const char *, HV *, int);

void get_value(Conf__Libconfig, const char *, SV **);
void get_scalar(config_setting_t *, SV **);
void get_array(config_setting_t *, SV **);
void get_list(config_setting_t *, SV **);
void get_group(config_setting_t *, SV **);
int get_hashvalue(config_setting_t *, HV *);
int get_arrayvalue(config_setting_t *, AV *);

void remove_scalar_node(config_setting_t *, const char *, int, int *);

void
set_scalar(config_setting_t *settings, SV *value, int valueType, int *status)
{
	if (settings == NULL) {
		Perl_warn(aTHX_ "[WARN] Settings is null in set_scalar!");
	}
	switch (valueType) {
        case CONFIG_TYPE_INT:
			*status = config_setting_set_int(settings, SvIV(value));
            break;
        case CONFIG_TYPE_INT64:
			*status = config_setting_set_int64(settings, SvUV(value));
            break;
        case CONFIG_TYPE_BOOL:
			*status = config_setting_set_bool(settings, SvIV(value));
            break;
        case CONFIG_TYPE_FLOAT:
			*status = config_setting_set_float(settings, SvNV(value));
            break;
        case CONFIG_TYPE_STRING:
			*status = config_setting_set_string(settings, SvPV_nolen(value));
			/*Perl_warn(aTHX_ "[STATUS] %d", *status);*/
            break;
		default:
            Perl_croak(aTHX_ "Scalar have not this type!");
	}
}

void
set_scalar_elem(config_setting_t *settings, int idx, SV *value, int valueType, int *status)
{
	config_setting_t *settings_item;
	if (settings == NULL) {
		Perl_warn(aTHX_ "[WARN] Settings is null in set_scalar_elem!");
	}
	switch (valueType) {
        case CONFIG_TYPE_INT:
			settings_item = config_setting_set_int_elem(settings, idx, SvIV(value));
            break;
        case CONFIG_TYPE_INT64:
			settings_item = config_setting_set_int64_elem(settings, idx, SvUV(value));
            break;
        case CONFIG_TYPE_BOOL:
			settings_item = config_setting_set_bool_elem(settings, idx, SvIV(value));
            break;
        case CONFIG_TYPE_FLOAT:
			settings_item = config_setting_set_float_elem(settings, idx, SvNV(value));
            break;
        case CONFIG_TYPE_STRING:
			settings_item = config_setting_set_string_elem(settings, idx, SvPV_nolen(value));
            break;
		default:
            Perl_croak(aTHX_ "Scalar element have not this type!");
	}
	*status = !settings_item ? 0 : 1;
	/*config_setting_set_format(settings_item, CONFIG_FORMAT_DEFAULT);*/
}

void
set_array(config_setting_t *settings, AV *value, int *status)
{
	SV *sv;// = newSV(0);
	int valueMaxIndex;
	int i;
	int type;
	int elemStatus;
	int allStatus;
	SV *g_v = newSViv(2);

	allStatus = 1;
	valueMaxIndex = av_len(value);
	/*Perl_warn(aTHX_ "[INDEX] %d", valueMaxIndex);*/
	for (i = 0; i <= valueMaxIndex; i ++)
	{
		/*sv = av_shift(value);*/
		sv = *(av_fetch(value, i, 0));
		type = (int)(log(SvIOK(sv) + SvNOK(sv) + SvPOK(sv))/log(2)) - (SvIOK(g_v) == 256 ? 5 : 13);
		if (type == 3) {
			if (SvUV(sv) <= UINTNUM) type = 2;
//			if ((SvUV(value) == 0 || SvUV(value) == 1) && flag == 2) type = 6;
		}
		//Perl_warn(aTHX_ "[DEBUG] %d | %d\n", SvPOK(value), type);
		/*Perl_warn(aTHX_ "[NUM] %s %d", settings->name, (int)SvIV(sv));*/
		set_scalar_elem(settings, -1, sv, type, &elemStatus);
		allStatus = allStatus | elemStatus;
	}
	*status = allStatus;
}

void
set_hash(config_setting_t *settings, HV *value, int *status, int booldefinedflag)
{
	HE* he;
	I32 keyLen;
	char *key;
	int elemStatus;
	int allStatus;
	SV* sv;// = newSV(0);

	allStatus = 1;
	hv_iterinit(value);
	while ((he = hv_iternext(value)))
	{
		key = hv_iterkey(he, &keyLen);
		sv = hv_iterval(value, he);
		// Only support simple hash
		elemStatus = set_scalarvalue(settings, key, sv, 0, booldefinedflag);
		allStatus = allStatus | elemStatus;
	}
	*status = allStatus;
}

int
set_scalarvalue(config_setting_t *settings, const char *key, SV *value, int flag, int booldefined)
{
	int type;
	int returnStatus;
	config_setting_t *settings_item;
	config_setting_t *settings_parent;
	SV *g_v = newSViv(2);

	if (settings == NULL) {
		Perl_warn(aTHX_ "[WARN] Settings is null in set_scalarvalue!");
		return 0;
	}
	if (SvIOK(value) + SvNOK(value) + SvPOK(value) == 0) {
		type = (int)(log(SvROK(value))/log(2)) - (SvIOK(g_v) == 256 ? 10 : 18);
	} else {
		type = (int)(log(SvIOK(value) + SvNOK(value) + SvPOK(value) + SvROK(value))/log(2)) - (SvIOK(g_v) == 256 ? 5 : 13);
	}
//	Perl_warn(aTHX_ "[DEBUG] %d | %d | %d | %d | %f | %d | %d\n", (int)SvPOK(value), (int)SvIOK(value), (int)SvNOK(value), (int)SvROK(value), log(SvIOK(value) + SvNOK(value) + SvPOK(value)), type, (int)SvIOK(g_v));
	if (type == 3) {
		if (SvUV(value) <= UINTNUM) type = 2;
		if ((SvUV(value) == 0 || SvUV(value) == 1) && booldefined == 2) type = 6;
	}
//	Perl_warn(aTHX_ "[DEBUG] %d | %d | %p\n", (int)SvPOK(value), type, value);
	returnStatus = 0;
	settings_parent = settings->parent;
	switch (flag) {
		case 1:
			if (settings->type == type)
				set_scalar(settings, value, type, &returnStatus);
			else {
				size_t nameLength = strlen(settings->name);
				char *name = (char *)malloc(nameLength + 1);
				if (!name) Perl_croak(aTHX_ "[ERROR] malloc is fail!!");
				strncpy(name, settings->name, nameLength);
				name[nameLength] = 0;
				remove_scalar_node(settings_parent, settings->name, settings->type, &returnStatus);
				set_scalarvalue(settings_parent, name, value, 0, 0);
				if (name) free(name);
			}
			break;
		default:
//		Perl_warn(aTHX_ "[WARN] ##### %s %d #%d##", key, type, settings->type);
//			if (type == CONFIG_TYPE_GROUP) {
//				set_hashvalue(settings, key, SvSTASH(SvRV(value)), booldefined);
//				set_hashvalue(settings, key, SVt_PVHV(value), booldefined);
//			} else {
				settings_item = config_setting_add(settings, key, type);
				set_scalar(settings_item, value, type, &returnStatus);
//			}
	}
	return returnStatus;
}

int
set_arrayvalue(config_setting_t *settings, const char *key, AV *value, int flag)
{
	int returnStatus;
	config_setting_t *settings_item;

	if (settings == NULL) {
		Perl_warn(aTHX_ "[WARN] Settings is null in set_arrayvalue!");
		return 0;
	}
	/*if (SVt_PVAV != SvTYPE(SvRV(value))) {*/
		/*Perl_warn(aTHX_ "[WARN] Value is not array");*/
		/*return 0;*/
	/*}*/
	/*Perl_warn(aTHX_ "[TYPE] %d", settings->type);*/
	returnStatus = 0;
	switch (settings->type) {
		case CONFIG_TYPE_INT:
		case CONFIG_TYPE_INT64:
		case CONFIG_TYPE_FLOAT:
		case CONFIG_TYPE_BOOL:
		case CONFIG_TYPE_STRING:
			Perl_croak(aTHX_ "Scalar can't add array node!");
			break;
		case CONFIG_TYPE_ARRAY:
		case CONFIG_TYPE_LIST:
			/*Perl_warn(aTHX_ "new list");*/
			settings_item = config_setting_add(settings, NULL, (flag ? CONFIG_TYPE_LIST : CONFIG_TYPE_ARRAY));
			set_array(settings_item, value, &returnStatus);
			break;
		case CONFIG_TYPE_GROUP:
			/*Perl_warn(aTHX_ "new group");*/
			settings_item = config_setting_add(settings, key, (flag ? CONFIG_TYPE_LIST : CONFIG_TYPE_ARRAY));
			set_array(settings_item, value, &returnStatus);
			break;
	}
	return returnStatus;
}

int
set_hashvalue(config_setting_t *settings, const char *key, HV *value, int booldefinedflag)
{
	int returnStatus;
	config_setting_t *settings_item;

	if (settings == NULL) {
		Perl_warn(aTHX_ "[WARN] Settings is null in set_hashvalue!");
		return 0;
	}
	returnStatus = 0;
	switch (settings->type) {
		case CONFIG_TYPE_INT:
		case CONFIG_TYPE_INT64:
		case CONFIG_TYPE_FLOAT:
		case CONFIG_TYPE_BOOL:
		case CONFIG_TYPE_STRING:
			Perl_croak(aTHX_ "Scalar can't add hash node!");
			break;
		case CONFIG_TYPE_ARRAY:
			Perl_croak(aTHX_ "Array can't add hash node!");
			break;
		case CONFIG_TYPE_LIST:
			settings_item = config_setting_add(settings, NULL, CONFIG_TYPE_GROUP);
			set_hash(settings_item, value, &returnStatus, booldefinedflag);
			break;
		case CONFIG_TYPE_GROUP:
			settings_item = config_setting_add(settings, key, CONFIG_TYPE_GROUP);
			set_hash(settings_item, value, &returnStatus, booldefinedflag);
			break;
	}
	return returnStatus;
}

/* {{{ */
void
remove_scalar_node(config_setting_t *settings, const char *name, int type, int *status)
{
	if (type == CONFIG_TYPE_INT || type == CONFIG_TYPE_INT64 || type == CONFIG_TYPE_FLOAT || type == CONFIG_TYPE_STRING || type == CONFIG_TYPE_BOOL)
		*status = config_setting_remove(settings, name);
	else
		Perl_croak(aTHX_ "[ERROR] Only can remove scalar setttings!");
}
/* }}} */

/* {{{ */
void
get_value(Conf__Libconfig conf, const char *path, SV **svref)
{
#if (((LIBCONFIG_VER_MAJOR == 1) && (LIBCONFIG_VER_MINOR >= 4)) \
		               || (LIBCONFIG_VER_MAJOR > 1))
	int valueInt;
#else
	long valueInt;
#endif
	long long valueBigint;
	char valueBigintArr[256];
	STRLEN valueBigintArrLen;
	int valueBool;
	char *valueChar;
	double valueFloat;
	if (config_lookup_int64(conf, path, &valueBigint)) {
		valueBigintArrLen = sprintf(valueBigintArr, "%lld", valueBigint);
		*svref = newSVpv(valueBigintArr, valueBigintArrLen);
	} else if (config_lookup_int(conf, path, &valueInt)) {
		*svref = newSViv((int)valueInt);
	} else if (config_lookup_float(conf, path, &valueFloat)) {
		*svref = newSVnv(valueFloat);
	} else if (config_lookup_string(conf, path, (const char **)&valueChar)) {
		*svref = newSVpvn(valueChar, strlen(valueChar));
	} else if (config_lookup_bool(conf, path, &valueBool)) {
		*svref = newSViv(valueBool);
	} else {
		*svref = newSV(0);
	}
}

void
get_scalar(config_setting_t *settings, SV **svref)
{
    long long vBigint;
    char vBigintArr[256];
    size_t vBigintArrLen;
    const char *vChar;

	if (settings == NULL) {
		Perl_warn(aTHX_ "[WARN] Settings is null in get_scalar!");
	}
    switch (settings->type) {
        case CONFIG_TYPE_INT:
            *svref = newSViv(config_setting_get_int(settings));
            break;
        case CONFIG_TYPE_INT64:
            vBigint = config_setting_get_int64(settings);
            vBigintArrLen = sprintf(vBigintArr, "%lld", vBigint);
            *svref = newSVpv(vBigintArr, vBigintArrLen);
            break;
        case CONFIG_TYPE_BOOL:
            *svref = newSViv(config_setting_get_bool(settings));
            break;
        case CONFIG_TYPE_FLOAT:
            *svref = newSVnv(config_setting_get_float(settings));
            break;
        case CONFIG_TYPE_STRING:
            vChar = config_setting_get_string(settings);
            *svref = newSVpvn(vChar, strlen(vChar));
            break;
        default:
			*svref = newSV(0);
            Perl_croak(aTHX_ "Scalar have not this type!");
    }
}

void
get_array(config_setting_t *settings, SV **svref)
{
	SV *sv;
	AV *av;
	int settings_count;
	int i;
	config_setting_t *settings_item;

	if (settings == NULL) {
		Perl_warn(aTHX_ "[WARN] Settings is null in get_array!");
	}
    av = newAV();
	settings_count = config_setting_length(settings);

	for (i = 0; i < settings_count; i ++) {
		settings_item = config_setting_get_elem(settings, i);
		if (settings_item) {
			if (settings_item->name != NULL) {
				Perl_warn(aTHX_ "[WARN] It is not array, skip.");
			}
			switch (settings_item->type) {
				case CONFIG_TYPE_INT:
				case CONFIG_TYPE_INT64:
				case CONFIG_TYPE_BOOL:
				case CONFIG_TYPE_FLOAT:
				case CONFIG_TYPE_STRING:
					get_scalar(settings_item, &sv);
					av_push(av, sv);
					break;
				case CONFIG_TYPE_ARRAY:
					get_array(settings_item, &sv);
					av_push(av, sv);
					break;
				case CONFIG_TYPE_LIST:
					get_list(settings_item, &sv);
					av_push(av, sv);
					break;
				case CONFIG_TYPE_GROUP:
					get_group(settings_item, &sv);
					av_push(av, sv);
					break;
				default:
					Perl_croak(aTHX_ "Not this type!");
			}
		}
	}
	*svref = newRV_noinc((SV *)av);
}

void
get_list(config_setting_t *settings, SV **svref)
{
	get_array(settings, svref);
}

void
get_group(config_setting_t *settings, SV **svref)
{
	SV *sv;
	HV *hv = newHV();
	int settings_count;
	int i;
	config_setting_t *settings_item;

	if (settings == NULL) {
		Perl_warn(aTHX_ "[WARN] Settings is null in get_group!");
	}
	settings_count = config_setting_length(settings);

	for (i = 0; i < settings_count; i ++) {
		settings_item = config_setting_get_elem(settings, i);
		if (settings_item) {
			switch (settings_item->type) {
				case CONFIG_TYPE_INT:
				case CONFIG_TYPE_INT64:
				case CONFIG_TYPE_BOOL:
				case CONFIG_TYPE_FLOAT:
				case CONFIG_TYPE_STRING:
					get_scalar(settings_item, &sv);
					if (!hv_store(hv, settings_item->name, strlen(settings_item->name), sv, 0)) {
						Perl_warn(aTHX_ "[Notice] it is some wrong with saving simple type in hv.");
					}
					break;
				case CONFIG_TYPE_ARRAY:
					get_array(settings_item, &sv);
					if (!hv_store(hv, settings_item->name, strlen(settings_item->name), sv, 0)) {
						Perl_warn(aTHX_ "[Notice] it is some wrong with array type in hv.");
					}
					break;
				case CONFIG_TYPE_LIST:
					get_list(settings_item, &sv);
					if (!hv_store(hv, settings_item->name, strlen(settings_item->name), sv, 0)) {
						Perl_warn(aTHX_ "[Notice] it is some wrong with list type in hv.");
					}
					break;
				case CONFIG_TYPE_GROUP:
					get_group(settings_item, &sv);
					if (!hv_store(hv, settings_item->name, strlen(settings_item->name), sv, 0)) {
						Perl_warn(aTHX_ "[Notice] it is some wrong with group type in hv.");
					}
					break;
				default:
					Perl_croak(aTHX_ "Not this type!");
			}
		}
	}
	*svref = newRV_noinc((SV *)hv);
}
/* }}} */

int
get_arrayvalue(config_setting_t *settings, AV *av)
{
	SV *sv;
	int settings_count;
	int i;
	config_setting_t *settings_item;

	if (settings == NULL) {
		Perl_warn(aTHX_ "[WARN] Settings is null in get_arrayvalue");
		return 1;
	}
	settings_count = config_setting_length(settings);
	if (settings->type == CONFIG_TYPE_INT || settings->type == CONFIG_TYPE_INT64 || settings->type == CONFIG_TYPE_FLOAT
			|| settings->type == CONFIG_TYPE_STRING || settings->type == CONFIG_TYPE_BOOL) {
		get_scalar(settings, &sv);
		av_push(av, sv);
		return 0;
	}
	if (settings->type == CONFIG_TYPE_GROUP) {
		get_group(settings, &sv);
		av_push(av, sv);
		return 0;
	}

	for (i = 0; i < settings_count; i ++) {
		settings_item = config_setting_get_elem(settings, i);
		if (settings_item) {
			switch (settings_item->type) {
				case CONFIG_TYPE_INT:
				case CONFIG_TYPE_INT64:
				case CONFIG_TYPE_BOOL:
				case CONFIG_TYPE_FLOAT:
				case CONFIG_TYPE_STRING:
					get_scalar(settings_item, &sv);
					av_push(av, sv);
					break;
				case CONFIG_TYPE_ARRAY:
					get_array(settings_item, &sv);
					av_push(av, sv);
					break;
				case CONFIG_TYPE_LIST:
					get_list(settings_item, &sv);
					av_push(av, sv);
					break;
				case CONFIG_TYPE_GROUP:
					get_group(settings_item, &sv);
					av_push(av, sv);
					break;
				default:
					Perl_croak(aTHX_ "Not this type!");
			}
		}
	}
	return 0;
}

int
get_hashvalue(config_setting_t *settings, HV *hv)
{
	SV *sv;// = newSV(0);
	int settings_count;
	int i;
	config_setting_t *settings_item;

	if (settings == NULL) {
		Perl_warn(aTHX_ "[WARN] Settings is null in get_hashvalue");
		return 1;
	}
	settings_count = config_setting_length(settings);
	if (settings->type == CONFIG_TYPE_INT || settings->type == CONFIG_TYPE_INT64 || settings->type == CONFIG_TYPE_FLOAT
			|| settings->type == CONFIG_TYPE_STRING || settings->type == CONFIG_TYPE_BOOL) {
		get_scalar(settings, &sv);
		if (!hv_store(hv, settings->name, strlen(settings->name), sv, 0)) {
			Perl_warn(aTHX_ "[Notice] it is some wrong with saving simple type in hv.");
		}
		return 0;
	}
	if (settings->type == CONFIG_TYPE_ARRAY || settings->type == CONFIG_TYPE_LIST) {
		get_array(settings, &sv);
		if (!hv_store(hv, settings->name, strlen(settings->name), sv, 0)) {
			Perl_warn(aTHX_ "[Notice] it is some wrong with saving simple type in hv.");
		}
		return 0;
	}

	for (i = 0; i < settings_count; i ++) {
		settings_item = config_setting_get_elem(settings, i);
		if (settings_item) {
			switch (settings_item->type) {
				case CONFIG_TYPE_INT:
				case CONFIG_TYPE_INT64:
				case CONFIG_TYPE_BOOL:
				case CONFIG_TYPE_FLOAT:
				case CONFIG_TYPE_STRING:
					get_scalar(settings_item, &sv);
					if (!hv_store(hv, settings_item->name, strlen(settings_item->name), sv, 0)) {
						Perl_warn(aTHX_ "[Notice] it is some wrong with saving simple type in hv.");
					}
					break;
				case CONFIG_TYPE_ARRAY:
					get_array(settings_item, &sv);
					if (!hv_store(hv, settings_item->name, strlen(settings_item->name), sv, 0)) {
						Perl_warn(aTHX_ "[Notice] it is some wrong with array type in hv.");
					}
					break;
				case CONFIG_TYPE_LIST:
					get_list(settings_item, &sv);
					if (!hv_store(hv, settings_item->name, strlen(settings_item->name), sv, 0)) {
						Perl_warn(aTHX_ "[Notice] it is some wrong with list type in hv.");
					}
					break;
				case CONFIG_TYPE_GROUP:
					get_group(settings_item, &sv);
					if (!hv_store(hv, settings_item->name, strlen(settings_item->name), sv, 0)) {
						Perl_warn(aTHX_ "[Notice] it is some wrong with group type in hv.");
					}
					break;
				default:
					Perl_croak(aTHX_ "Not this type!");
			}
		}
	}
	return 0;
}

MODULE = Conf::Libconfig     PACKAGE = Conf::Libconfig  PREFIX = libconfig_

Conf::Libconfig
libconfig_new(packname="Conf::Libconfig")
	char *packname
	PREINIT:
	CODE:
	{
		config_t *pConf = (config_t *)safemalloc(sizeof(config_t));
		if (pConf)
			config_init(pConf);
		RETVAL = pConf;
	}
    OUTPUT:
        RETVAL

void
libconfig_delete(conf)
    Conf::Libconfig conf
    CODE:
		config_destroy(conf);

void
libconfig_DESTROY(conf)
    Conf::Libconfig conf
    CODE:
		config_destroy(conf);

double
libconfig_getversion(conf)
    Conf::Libconfig conf
    CODE:
	{
#if (((LIBCONFIG_VER_MAJOR == 1) && (LIBCONFIG_VER_MINOR >= 4)) \
		               || (LIBCONFIG_VER_MAJOR > 1))
		char tmpChar[16];
        sprintf(tmpChar, "%d.%d%d", LIBCONFIG_VER_MAJOR, LIBCONFIG_VER_MINOR, LIBCONFIG_VER_REVISION);
		RETVAL = atof(tmpChar);
#else
		RETVAL = 1.32;
#endif
	}
    OUTPUT:
        RETVAL

int
libconfig_read(conf, stream)
	Conf::Libconfig conf
	FILE *stream
	PREINIT:
	CODE:
		config_read(conf, stream);

int
libconfig_read_file(conf, filename)
    Conf::Libconfig conf
    const char *filename
    CODE:
    {
        RETVAL = config_read_file(conf, filename);
    }
    OUTPUT:
        RETVAL

int
libconfig_read_string(conf, string)
    Conf::Libconfig conf
    const char *string
    CODE:
    {
#if (((LIBCONFIG_VER_MAJOR == 1) && (LIBCONFIG_VER_MINOR >= 4)) \
		               || (LIBCONFIG_VER_MAJOR > 1))
        RETVAL = config_read_string(conf, string);
#else
		RETVAL = 0;
#endif
    }
    OUTPUT:
        RETVAL

const char *
libconfig_get_include_dir(conf)
    Conf::Libconfig conf
    PREINIT:
    CODE:
    {
#if (((LIBCONFIG_VER_MAJOR == 1) && (LIBCONFIG_VER_MINOR >= 4)) \
		               || (LIBCONFIG_VER_MAJOR > 1))
        RETVAL = config_get_include_dir(conf);
#else
		RETVAL = 0;
#endif
    }
    OUTPUT:
        RETVAL

void
libconfig_set_include_dir(conf, string)
    Conf::Libconfig conf
    const char *string
	PREINIT:
    CODE:
    {
#if (((LIBCONFIG_VER_MAJOR == 1) && (LIBCONFIG_VER_MINOR >= 4)) \
		               || (LIBCONFIG_VER_MAJOR > 1))
        config_set_include_dir(conf, string);
#endif
    }

long
libconfig_lookup_int(conf, path)
    Conf::Libconfig conf
    const char *path
    PREINIT:
#if (((LIBCONFIG_VER_MAJOR == 1) && (LIBCONFIG_VER_MINOR >= 4)) \
		               || (LIBCONFIG_VER_MAJOR > 1))
		int value;
#else
        long value;
#endif
    CODE:
    {
        config_lookup_int(conf, path, &value);
        RETVAL = value;
    }
    OUTPUT:
        RETVAL

SV *
libconfig_lookup_int64(conf, path)
    Conf::Libconfig conf
    const char *path
    PREINIT:
        long long int value;
        char valueArr[256];
        STRLEN valueArrLen;
    CODE:
    {
        config_lookup_int64(conf, path, &value);
        valueArrLen = sprintf(valueArr, "%lld", value);
        RETVAL = sv_2mortal(newSVpv(valueArr, valueArrLen));
    }
    OUTPUT:
        RETVAL

int
libconfig_lookup_bool(conf, path)
    Conf::Libconfig conf
    const char *path
    PREINIT:
        int value;
    CODE:
    {
        config_lookup_bool(conf, path, &value);
        RETVAL = value;
    }
    OUTPUT:
        RETVAL

double
libconfig_lookup_float(conf, path)
    Conf::Libconfig conf
    const char *path
    PREINIT:
        double value;
    CODE:
    {
        config_lookup_float(conf, path, &value);
        RETVAL = value;
    }
    OUTPUT:
        RETVAL

char *
libconfig_lookup_string(conf, path)
    Conf::Libconfig conf
    const char *path
    PREINIT:
        char *value;
    CODE:
    {
        config_lookup_string(conf, path, (const char **)&value);
        RETVAL = value;
    }
    OUTPUT:
        RETVAL

SV *
libconfig_lookup_value(conf, path)
    Conf::Libconfig conf
    const char *path
    PREINIT:
        SV *sv;
    CODE:
    {
		get_value(conf, path, &sv);
        RETVAL = sv;
    }
    OUTPUT:
        RETVAL

AV *
libconfig_fetch_array(conf, path)
    Conf::Libconfig conf
    const char *path
    PREINIT:
        config_setting_t *settings;
        AV *av = newAV();
    CODE:
    {
        settings = config_lookup(conf, path);
        get_arrayvalue(settings, av);
//		ST(0) = sv_2mortal((SV *)av);
        RETVAL = (AV *)sv_2mortal((SV *)av);
//		XPUSHs(sv_2mortal((SV *)av));
    }
    OUTPUT:
        RETVAL

HV *
libconfig_fetch_hashref(conf, path)
    Conf::Libconfig conf
    const char *path
    PREINIT:
        config_setting_t *settings;
        HV *hv = newHV();
    CODE:
    {
        settings = config_lookup(conf, path);
		get_hashvalue(settings, hv);
		RETVAL = (HV *)sv_2mortal((SV *)hv);
    }
    OUTPUT:
        RETVAL


Conf::Libconfig::Settings
libconfig_setting_lookup(conf, path)
    Conf::Libconfig conf
    const char *path
    PREINIT:
    CODE:
    {
        RETVAL = config_lookup(conf, path);
    }
    OUTPUT:
        RETVAL

void
libconfig_write(conf, stream)
	Conf::Libconfig conf
	FILE *stream
	PREINIT:
	CODE:
		config_write(conf, stream);

int
libconfig_write_file(conf, filename)
	Conf::Libconfig conf
	const char *filename
	PREINIT:
	CODE:
	{
		RETVAL = config_write_file(conf, filename);
	}
	OUTPUT:
		RETVAL

int
libconfig_add_scalar(conf, path, key, value)
	Conf::Libconfig conf
    const char *path
	const char *key
	SV *value
    PREINIT:
        config_setting_t *settings;
	CODE:
	{
        settings = config_lookup(conf, path);
		RETVAL = set_scalarvalue(settings, key, value, 0, 0);
	}
	OUTPUT:
		RETVAL

int
libconfig_add_boolscalar(conf, path, key, value)
	Conf::Libconfig conf
    const char *path
	const char *key
	SV *value
    PREINIT:
        config_setting_t *settings;
	CODE:
	{
        settings = config_lookup(conf, path);
		RETVAL = set_scalarvalue(settings, key, value, 0, 2);
	}
	OUTPUT:
		RETVAL

int
libconfig_modify_scalar(conf, path, value)
	Conf::Libconfig conf
    const char *path
	SV *value
    PREINIT:
        config_setting_t *settings;
	CODE:
	{
        settings = config_lookup(conf, path);
		if (settings != NULL)
			RETVAL = set_scalarvalue(settings, settings->name, value, 1, 0);
		else
		{
			Perl_warn(aTHX_ "[WARN] Path is null!");
			RETVAL = 0;
		}
	}
	OUTPUT:
		RETVAL

int
libconfig_modify_boolscalar(conf, path, value)
	Conf::Libconfig conf
    const char *path
	SV *value
    PREINIT:
        config_setting_t *settings;
	CODE:
	{
        settings = config_lookup(conf, path);
		if (settings != NULL)
			RETVAL = set_scalarvalue(settings, settings->name, value, 1, 2);
		else
		{
			Perl_warn(aTHX_ "[WARN] Path is null!");
			RETVAL = 0;
		}
	}
	OUTPUT:
		RETVAL

int
libconfig_add_array(conf, path, key, value)
	Conf::Libconfig conf
    const char *path
	const char *key
	AV *value
    PREINIT:
        config_setting_t *settings;
	CODE:
		settings = config_lookup(conf, path);
		RETVAL = set_arrayvalue(settings, key, value, 0);
	OUTPUT:
		RETVAL

int
libconfig_add_list(conf, path, key, value)
	Conf::Libconfig conf
    const char *path
	const char *key
	AV *value
    PREINIT:
        config_setting_t *settings;
	CODE:
        settings = config_lookup(conf, path);
		RETVAL = set_arrayvalue(settings, key, value, 1);
	OUTPUT:
		RETVAL

int
libconfig_add_hash(conf, path, key, value)
	Conf::Libconfig conf
    const char *path
	const char *key
	HV *value
    PREINIT:
        config_setting_t *settings;
	CODE:
        settings = config_lookup(conf, path);
		RETVAL = set_hashvalue(settings, key, value, 0);
	OUTPUT:
		RETVAL

int
libconfig_add_boolhash(conf, path, key, value)
	Conf::Libconfig conf
    const char *path
	const char *key
	HV *value
    PREINIT:
        config_setting_t *settings;
	CODE:
        settings = config_lookup(conf, path);
		RETVAL = set_hashvalue(settings, key, value, 2);
	OUTPUT:
		RETVAL

int
libconfig_delete_node(conf, path)
    Conf::Libconfig conf
    const char *path
    PREINIT:
        config_setting_t *settings;
		char *key;
		char parentpath[256];
    CODE:
	{
		key = strrchr(path, '.') + 1;
		sprintf(parentpath, "%.*s", (int)(strlen(path) - strlen(key) - 1), path);
        settings = config_lookup(conf, parentpath);
		if (!settings) {
			Perl_croak (aTHX_ "Not the node of path: %s", parentpath);
		}
		RETVAL = 1 | config_setting_remove(settings, key);
	}
    OUTPUT:
        RETVAL

int
libconfig_delete_node_key(conf, path, key)
    Conf::Libconfig conf
    const char *path
	const char *key
    PREINIT:
        config_setting_t *settings;
    CODE:
        settings = config_lookup(conf, path);
		if (!settings) {
			Perl_croak (aTHX_ "Not the node of path.!");
		}
		RETVAL = 1 | config_setting_remove(settings, key);
    OUTPUT:
        RETVAL

int
libconfig_delete_node_elem(conf, path, idx)
    Conf::Libconfig conf
    const char *path
	unsigned int idx
    PREINIT:
        config_setting_t *settings;
    CODE:
        settings = config_lookup(conf, path);
		if (!settings) {
			Perl_croak (aTHX_ "Not the node of path.!");
		}
		RETVAL = 1 | config_setting_remove_elem(settings, idx);
    OUTPUT:
        RETVAL

MODULE = Conf::Libconfig     PACKAGE = Conf::Libconfig::Settings    PREFIX = libconfig_setting_

int
libconfig_setting_length(setting)
    Conf::Libconfig::Settings setting
    PREINIT:
    CODE:
    {
        RETVAL = config_setting_length(setting);
    }
    OUTPUT:
        RETVAL

SV *
libconfig_setting_get_type(setting)
	Conf::Libconfig::Settings setting
    PREINIT:
        SV *sv = newSV(0);
	CODE:
	{
		switch(setting->type)
		{
			case CONFIG_TYPE_INT:
			case CONFIG_TYPE_INT64:
			case CONFIG_TYPE_FLOAT:
			case CONFIG_TYPE_STRING:
			case CONFIG_TYPE_BOOL:
				sv_setpv(sv, "SCALAR");
				break;
			case CONFIG_TYPE_ARRAY:
			case CONFIG_TYPE_LIST:
				sv_setpv(sv, "ARRAY");
				break;
			case CONFIG_TYPE_GROUP:
				sv_setpv(sv, "HASH");
				break;
			default:
				sv_setsv(sv, &PL_sv_undef);
		}
		RETVAL = sv;
	}
	OUTPUT:
		RETVAL

SV *
libconfig_setting_get_item(setting, i)
    Conf::Libconfig::Settings setting
    int i
    PREINIT:
        const char *itemChar;
        double itemFloat;
        long long itemBigint;
        char itemBigintArr[256];
        STRLEN itemBigintArrLen;
#if (((LIBCONFIG_VER_MAJOR == 1) && (LIBCONFIG_VER_MINOR >= 4)) \
		               || (LIBCONFIG_VER_MAJOR > 1))
        long itemInt;
#else
		int itemInt;
#endif
        int itemBool;
        SV *sv;
    CODE:
    {
        if ((itemInt = config_setting_get_int_elem(setting, i)))
            sv = newSViv(itemInt);
        else if ((itemBigint = config_setting_get_int64_elem(setting, i))) {
            itemBigintArrLen = sprintf(itemBigintArr, "%lld", itemBigint);
            sv = newSVpv(itemBigintArr, itemBigintArrLen);
        } else if ((itemBool = config_setting_get_bool_elem(setting, i)))
            sv = newSViv(itemBool);
        else if ((itemFloat = config_setting_get_float_elem(setting, i)))
            sv = newSVnv(itemFloat);
        else if ((itemChar = config_setting_get_string_elem(setting, i)))
            sv = newSVpvn(itemChar, strlen(itemChar));
		else
			sv = newSV(0);
        RETVAL = sv;
    }
    OUTPUT:
        RETVAL


