// vi:filetype=c noet sw=4 ts=4 fdm=marker

#ifdef __cplusplus
extern "C" {
#endif
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>
#ifdef __cplusplus
}
#endif

#include <libconfig.h>

#define UINTNUM 2147483647
#define LIBCONFIG_OK				0
#define LIBCONFIG_ERR_COMMON		-1
#define LIBCONFIG_ERR_INPUT			-2

typedef config_t *Conf__Libconfig;
typedef config_setting_t *Conf__Libconfig__Settings;

void auto_check_and_create(Conf__Libconfig , const char *, config_setting_t **, char **);
int sv2int(config_setting_t *, SV *);
int sv2float(config_setting_t *, SV *);
int sv2string(config_setting_t *, SV *);
int sv2addint(const char *, config_setting_t *, config_setting_t *, SV *);
int sv2addfloat(const char *, config_setting_t *, config_setting_t *, SV *);
int sv2addstring(const char *, config_setting_t *, config_setting_t *, SV *);
int sv2addarray(config_setting_t *, SV *);
int sv2addobject(config_setting_t *, SV *);

void set_scalar(config_setting_t *, SV *, int , int *);
void set_scalar_elem(config_setting_t *, int, SV *, int, int *);
void set_array(config_setting_t *, AV *, int *);
void set_hash(config_setting_t *, HV *, int *, int);
int set_scalarvalue(config_setting_t *, const char *, SV *, int, int);
int set_arrayvalue(config_setting_t *, const char *, AV *, int);
int set_hashvalue(config_setting_t *, const char *, HV *, int);

int get_general_array(config_setting_t *, SV **);
int get_general_list(config_setting_t *, SV **);
int get_general_object(config_setting_t *, SV **);
int get_general_value(Conf__Libconfig, const char *, SV **);

int set_boolean_value(Conf__Libconfig, const char *, SV *);
int set_general_value(Conf__Libconfig, const char *, SV *);

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
}

void
set_array(config_setting_t *settings, AV *value, int *status)
{
	SV *sv;
	int valueMaxIndex;
	int i;
	int type;
	int elemStatus;
	int allStatus;
	SV *g_v = newSViv(2);

	allStatus = 1;
	valueMaxIndex = av_len(value);
	for (i = 0; i <= valueMaxIndex; i ++)
	{
		sv = *(av_fetch(value, i, 0));
		type = (int)(log(SvIOK(sv) + SvNOK(sv) + SvPOK(sv))/log(2)) - (SvIOK(g_v) == 256 ? 5 : 13);
		if (type == 3) {
			if (SvUV(sv) <= UINTNUM) type = 2;
		}
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
	SV* sv;

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
	if (type == 3) {
		if (SvUV(value) <= UINTNUM) type = 2;
		if ((SvUV(value) == 0 || SvUV(value) == 1) && booldefined == 2) type = 6;
	}
	returnStatus = 0;
	settings_parent = settings->parent;
	switch (flag) {
		case 1:
			{
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
			}
		default:
			{
				settings_item = config_setting_add(settings, key, type);
				set_scalar(settings_item, value, type, &returnStatus);
			}
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
			set_array(settings, value, &returnStatus);
			break;
		case CONFIG_TYPE_GROUP:
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

/* {{{ remove_scalar_node */
void
remove_scalar_node(config_setting_t *settings, const char *name, int type, int *status)
{
	if (type == CONFIG_TYPE_INT || type == CONFIG_TYPE_INT64 || type == CONFIG_TYPE_FLOAT || type == CONFIG_TYPE_STRING || type == CONFIG_TYPE_BOOL)
		*status = config_setting_remove(settings, name);
	else
		Perl_croak(aTHX_ "[ERROR] Only can remove scalar setttings!");
}
/* }}} */

/* {{{ function */
int sv2int(config_setting_t *setting, SV *val)
{
	int ret = LIBCONFIG_OK;
	if (SvUV(val) > INT_MAX || SvIV(val) < INT_MIN) {
		setting->type = CONFIG_TYPE_INT64;
		ret = CONFIG_TRUE == config_setting_set_int64(setting, (long long)SvIV(val)) ? LIBCONFIG_OK : LIBCONFIG_ERR_COMMON;
	} else {
		setting->type = CONFIG_TYPE_INT;
		ret = CONFIG_TRUE == config_setting_set_int(setting, SvIV(val)) ? LIBCONFIG_OK : LIBCONFIG_ERR_COMMON;
	}
	return ret;
}

int sv2float(config_setting_t *setting, SV *val)
{
	setting->type = CONFIG_TYPE_FLOAT;
	return CONFIG_TRUE == config_setting_set_float(setting, SvNV(val)) ? LIBCONFIG_OK : LIBCONFIG_ERR_COMMON;
}

int sv2string(config_setting_t *setting, SV *val)
{
	setting->type = CONFIG_TYPE_STRING;
	return CONFIG_TRUE == config_setting_set_string(setting, SvPV_nolen(val)) ? LIBCONFIG_OK : LIBCONFIG_ERR_COMMON;
}

int sv2addint(const char *key, config_setting_t *setting, config_setting_t *child_setting, SV *val)
{
	int ret = LIBCONFIG_OK;
	// boolean and int32 are IV, so they can only be reduced to one, namely int32
	if (SvUV(val) > INT_MAX || SvIV(val) < INT_MIN)
	{
		if (child_setting == NULL)
		{
			child_setting = config_setting_add(setting, key, CONFIG_TYPE_INT64);
		}
		else
		{
			child_setting->type = CONFIG_TYPE_INT64;
		}
		ret = CONFIG_TRUE == config_setting_set_int64(child_setting, (long long)SvIV(val)) ? LIBCONFIG_OK : LIBCONFIG_ERR_COMMON;
	}
	else
	{
		if (child_setting == NULL)
		{
			child_setting = config_setting_add(setting, key, CONFIG_TYPE_INT);
		}
		else
		{
			child_setting->type = CONFIG_TYPE_INT;
		}
		ret = CONFIG_TRUE == config_setting_set_int(child_setting, SvIV(val)) ? LIBCONFIG_OK : LIBCONFIG_ERR_COMMON;
	}
	return ret;
}

int sv2addfloat(const char *key, config_setting_t *setting, config_setting_t *child_setting, SV *val)
{
	if (child_setting == NULL)
	{
		child_setting = config_setting_add(setting, key, CONFIG_TYPE_FLOAT);
	} else {
		child_setting->type = CONFIG_TYPE_FLOAT;
	}
	return CONFIG_TRUE == config_setting_set_float(child_setting, SvNV(val)) ? LIBCONFIG_OK : LIBCONFIG_ERR_COMMON;
}

int sv2addstring(const char *key, config_setting_t *setting, config_setting_t *child_setting, SV *val)
{
	if (child_setting == NULL)
	{
		child_setting = config_setting_add(setting, key, CONFIG_TYPE_STRING);
	} else {
		child_setting->type = CONFIG_TYPE_STRING;
	}
	return CONFIG_TRUE == config_setting_set_string(child_setting, SvPV_nolen(val)) ? LIBCONFIG_OK : LIBCONFIG_ERR_COMMON;
}

int sv2addarray(config_setting_t *setting, SV *sv)
{
	int ret = LIBCONFIG_OK;
	AV *av = (AV *)SvRV(sv);
	int avlen = (int)av_count(av);
	int settinglen = config_setting_length(setting);
	config_setting_t *child_setting;
	for (int i = 0; i < avlen; i ++)
	{
		SV *child_sv = *(av_fetch(av, i, 0));
		switch (SvTYPE(child_sv))
		{
			case SVt_IV:
				{
					child_setting = config_setting_get_elem(setting, i);
					ret += sv2addint(NULL, setting, child_setting, child_sv);
					break;
				}
			case SVt_NV:
				{
					child_setting = config_setting_get_elem(setting, i);
					ret += sv2addfloat(NULL, setting, child_setting, child_sv);
					break;
				}
			case SVt_PV:
				{
					child_setting = config_setting_get_elem(setting, i);
					ret += sv2addstring(NULL, setting, child_setting, child_sv);
					break;
				}
			default:
		}
	}
	while (settinglen > avlen)
	{
		ret += CONFIG_TRUE == config_setting_remove_elem(setting, avlen) ? LIBCONFIG_OK : LIBCONFIG_ERR_COMMON;
		settinglen = config_setting_length(setting);
	}
	return ret;
}

int sv2addobject(config_setting_t *setting, SV *sv)
{
	int ret = LIBCONFIG_OK;
	HV *hv = (HV *)SvRV(sv);
	hv_iterinit(hv);
	HE *he = NULL;
	while ((he = hv_iternext(hv)))
	{
		I32 len;
		char *key = hv_iterkey(he, &len);
		SV *val = hv_iterval(hv, he);
		config_setting_t *child_setting = NULL;
		if (SvROK(val))
		{
			switch (SvTYPE(SvRV(val)))
			{
				case SVt_PVAV:
					{
						config_setting_t *child_setting = config_setting_add(setting, key, CONFIG_TYPE_ARRAY);
						ret += sv2addarray(child_setting, val);
						break;
					}
				case SVt_PVHV:
					{
						config_setting_t *child_setting = config_setting_add(setting, key, CONFIG_TYPE_GROUP);
						sv2addobject(child_setting, val);
						break;
					}
				default:
			}
		}
		else
		{
			switch (SvTYPE(val))
			{
				case SVt_IV:
					{
						ret += sv2addint(key, setting, child_setting, val);
						break;
					}
				case SVt_NV:
					{
						ret += sv2addfloat(key, setting, child_setting, val);
						break;
					}
				case SVt_PV:
					{
						ret += sv2addstring(key, setting, child_setting, val);
						break;
					}
				default:
			}
		}
	}
	return ret;
}
/* }}} */

/* {{{ set value */
int set_general_value(Conf__Libconfig conf, const char *path, SV *sv)
{
	int ret = LIBCONFIG_OK;
	config_setting_t *elem = path != NULL && strlen(path) == 0 ? config_root_setting(conf) : config_lookup(conf, path);
	if (!elem)
	{
		config_setting_t *parent_setting;
		char *start_path;
		auto_check_and_create(conf, path, &parent_setting, &start_path);
		if (SvROK(sv))
		{
			switch (SvTYPE(SvRV(sv)))
			{
				case SVt_PVAV:
				{
					elem = config_setting_add(parent_setting, start_path, CONFIG_TYPE_ARRAY);
					ret += sv2addarray(elem, sv);
					break;
				}
				case SVt_PVHV:
				{
					elem = config_setting_add(parent_setting, start_path, CONFIG_TYPE_GROUP);
					ret += sv2addobject(elem, sv);
					break;
				}
				default:
			}
		}
		else
		{
			// create the setting
			config_setting_t *child_setting = NULL;
			switch (SvTYPE(sv))
			{
				case SVt_IV:
					{
						ret = sv2addint(start_path, parent_setting, child_setting, sv);
						break;
					}
				case SVt_NV:
					{
						ret = sv2addfloat(start_path, parent_setting, child_setting, sv);
						break;
					}
				case SVt_PV:
					{
						ret = sv2addstring(start_path, parent_setting, child_setting, sv);
						break;
					}
				default:
			}
		}
	}
	else
	{
		if (SvROK(sv))
		{
			switch (SvTYPE(SvRV(sv)))
			{
				case SVt_PVAV:
				{
					elem->type = CONFIG_TYPE_ARRAY;
					ret += sv2addarray(elem, sv);
					break;
				}
				case SVt_PVHV:
				{
					elem->type = CONFIG_TYPE_GROUP;
					ret += sv2addobject(elem, sv);
					break;
				}
				default:
			}
		}
		else
		{
			switch (SvTYPE(sv))
			{
				case SVt_IV:
					{
						sv2int(elem, sv);
						break;
					}
				case SVt_NV:
					{
						sv2float(elem, sv);
						break;
					}
				case SVt_PV:
					{
						sv2string(elem, sv);
						break;
					}
				default:
			}
		}
	}
	return ret;
}

void auto_check_and_create(Conf__Libconfig conf, const char *path, config_setting_t **parent_setting_pptr, char **start_path_pptr)
{
	config_setting_t *root_setting = config_root_setting(conf);
	config_setting_t *parent_setting = root_setting;
	config_setting_t *child_setting = root_setting;
	int path_len = strlen(path);
	char *tmp_path = (char *)malloc(path_len + 1);

	char *start_path = (char *)path;
	char *end_path = strchr(start_path, '.');
	if (end_path != NULL)
	{
		sprintf(tmp_path, "%.*s", (int)(end_path - start_path), start_path);
		start_path = end_path + 1;
		child_setting = config_setting_get_member(parent_setting, tmp_path);
		if (child_setting == NULL)
		{
			child_setting = config_setting_add(parent_setting, tmp_path, CONFIG_TYPE_GROUP);
		}
		parent_setting = child_setting;
		while ((end_path = strrchr(start_path, '.')))
		{
			sprintf(tmp_path, "%.*s", (int)(end_path - start_path), start_path);
			start_path = end_path + 1;
			child_setting = config_setting_get_member(parent_setting, tmp_path);
			if (child_setting == NULL)
			{
				child_setting = config_setting_add(parent_setting, tmp_path, CONFIG_TYPE_GROUP);
			}
			parent_setting = child_setting;
		}
	}
	free(tmp_path);
	*parent_setting_pptr = parent_setting;
	*start_path_pptr = start_path;
}

int set_boolean_value(Conf__Libconfig conf, const char *path, SV *sv)
{
	int ret = LIBCONFIG_OK;
	switch (SvTYPE(sv))
	{
		case SVt_IV:
		case SVt_PV:
			{
				config_setting_t *elem = path != NULL && strlen(path) == 0 ? config_root_setting(conf) : config_lookup(conf, path);
				if (!elem)
				{
					config_setting_t *parent_setting;
					char *start_path;
					auto_check_and_create(conf, path, &parent_setting, &start_path);
					elem = config_setting_add(parent_setting, start_path, CONFIG_TYPE_BOOL);
				} else {
					elem->type = CONFIG_TYPE_BOOL;
				}
				if (SvTYPE(sv) == SVt_PV) {
					if (strcasecmp(SvPV_nolen(sv), "true") == 0) {
						ret = CONFIG_TRUE == config_setting_set_bool(elem, 1) ? LIBCONFIG_OK : LIBCONFIG_ERR_COMMON;
					} else if (strcasecmp(SvPV_nolen(sv), "false") == 0) {
						ret = CONFIG_TRUE == config_setting_set_bool(elem, 0) ? LIBCONFIG_OK : LIBCONFIG_ERR_COMMON;
					} else {
						ret = LIBCONFIG_ERR_INPUT;
					}
				} else {
					ret = CONFIG_TRUE == config_setting_set_bool(elem, SvIV(sv)) ? LIBCONFIG_OK : LIBCONFIG_ERR_COMMON;
				}
				break;
			}
		default:
			{
				ret = LIBCONFIG_ERR_INPUT;
			}
	}
	return ret;
}

/* }}} */

/* {{{ get value */
int
get_general_value(Conf__Libconfig conf, const char *path, SV **svref)
{
	config_setting_t *elem = path != NULL && strlen(path) == 0 ? config_root_setting(conf) : config_lookup(conf, path);
	if (!elem)
	{
		return LIBCONFIG_ERR_INPUT;
	}
	switch (config_setting_type(elem))
	{
		case CONFIG_TYPE_BOOL:
			*svref = newSViv(config_setting_get_bool(elem));
			break;
		case CONFIG_TYPE_INT:
			*svref = newSViv(config_setting_get_int(elem));
			break;
		case CONFIG_TYPE_INT64:
			*svref = newSViv(elem->value.llval);
			break;
		case CONFIG_TYPE_FLOAT:
			*svref = newSVnv(config_setting_get_float(elem));
			break;
		case CONFIG_TYPE_STRING:
			const char *val = config_setting_get_string(elem);
			*svref = newSVpvn(val, strlen(val));
			break;
		case CONFIG_TYPE_ARRAY:
			{
				return get_general_array(elem, svref);
			}
		case CONFIG_TYPE_LIST:
			{
				return get_general_list(elem, svref);
			}
		case CONFIG_TYPE_GROUP:
			{
				return get_general_object(elem, svref);
			}
		default:
			Perl_warn(aTHX_ "Scalar have not this type: %d in %s", config_setting_type(elem), path);
			return LIBCONFIG_ERR_COMMON;
	}
	return LIBCONFIG_OK;
}

int get_general_array(config_setting_t *setting, SV **sv_pptr)
{
	if (setting->type != CONFIG_TYPE_ARRAY)
	{
		return LIBCONFIG_ERR_COMMON;
	}
	AV *child_av_ptr = newAV();
	int arr_len = config_setting_length(setting);
	for (int i = 0; i < arr_len; i++)
	{
		config_setting_t *child_setting = config_setting_get_elem(setting, i);
		switch (config_setting_type(child_setting))
		{
			case CONFIG_TYPE_BOOL:
				{
					av_push(child_av_ptr, newSViv(config_setting_get_bool(child_setting)));
					break;
				}
			case CONFIG_TYPE_INT:
				{
					av_push(child_av_ptr, newSViv(config_setting_get_int(child_setting)));
					break;
				}
			case CONFIG_TYPE_INT64:
				{
					av_push(child_av_ptr, newSViv(child_setting->value.llval));
					break;
				}
			case CONFIG_TYPE_FLOAT:
				{
					av_push(child_av_ptr, newSVnv(config_setting_get_float(child_setting)));
					break;
				}
			case CONFIG_TYPE_STRING:
				{
					const char *child_val = config_setting_get_string(child_setting);
					av_push(child_av_ptr, newSVpvn(child_val, strlen(child_val)));
					break;
				}
			default:
				{
					Perl_warn(aTHX_ "Array have not this type: %d", config_setting_type(setting));
					return LIBCONFIG_ERR_COMMON;
				}
		}
	}
	*sv_pptr = newRV_inc((SV *)child_av_ptr);
	return LIBCONFIG_OK;
}

int get_general_list(config_setting_t *setting, SV **sv_pptr)
{
	if (setting->type != CONFIG_TYPE_LIST)
	{
		return LIBCONFIG_ERR_INPUT;
	}
	AV *child_av_ptr = newAV();
	int list_size = config_setting_length(setting);
	for (int i = 0; i < list_size; i++)
	{
		config_setting_t *child_setting = config_setting_get_elem(setting, i);
		switch (config_setting_type(child_setting))
		{
			case CONFIG_TYPE_BOOL:
				{
					av_push(child_av_ptr, newSViv(config_setting_get_bool(child_setting)));
					break;
				}
			case CONFIG_TYPE_INT:
				{
					av_push(child_av_ptr, newSViv(config_setting_get_int(child_setting)));
					break;
				}
			case CONFIG_TYPE_INT64:
				{
					av_push(child_av_ptr, newSViv(child_setting->value.llval));
					break;
				}
			case CONFIG_TYPE_FLOAT:
				{
					av_push(child_av_ptr, newSVnv(config_setting_get_float(child_setting)));
					break;
				}
			case CONFIG_TYPE_STRING:
				{
					const char *child_val = config_setting_get_string(child_setting);
					av_push(child_av_ptr, newSVpvn(child_val, strlen(child_val)));
					break;
				}
			case CONFIG_TYPE_ARRAY:
				{
					SV *sv;
					if (get_general_array(child_setting, &sv) == LIBCONFIG_OK)
					{
						av_push(child_av_ptr, sv);
					}
					// ignore error
					break;
				}
			case CONFIG_TYPE_LIST:
				{
					SV *sv;
					if (get_general_list(child_setting, &sv) == LIBCONFIG_OK);
					{
						av_push(child_av_ptr, sv);
					}
					// ignore error
					break;
				}
			case CONFIG_TYPE_GROUP:
				{
					SV *sv;
					if (get_general_object(child_setting, &sv) == LIBCONFIG_OK);
					{
						av_push(child_av_ptr, sv);
					}
					// ignore error
					break;
				}
			default:
				{
					Perl_warn(aTHX_ "List have not this type: %d in [%d]", config_setting_type(setting), i);
					return LIBCONFIG_ERR_COMMON;
				}
		}
	}
	*sv_pptr = newRV_inc((SV *)child_av_ptr);
	return LIBCONFIG_OK;
}

int get_general_object(config_setting_t *setting, SV **sv_pptr)
{
	if (setting->type != CONFIG_TYPE_GROUP)
	{
		return LIBCONFIG_ERR_INPUT;
	}
	HV *child_hv_ptr = newHV();
	int obj_cnt = config_setting_length(setting);
	for (int i = 0; i < obj_cnt; i++)
	{
		config_setting_t *child_setting = config_setting_get_elem(setting, i);
		switch (config_setting_type(child_setting))
		{
			case CONFIG_TYPE_BOOL:
				{
					hv_store(child_hv_ptr, child_setting->name, strlen(child_setting->name), newSViv(config_setting_get_bool(child_setting)), 0);
					break;
				}
			case CONFIG_TYPE_INT:
				{
					hv_store(child_hv_ptr, child_setting->name, strlen(child_setting->name), newSViv(config_setting_get_int(child_setting)), 0);
					break;
				}
			case CONFIG_TYPE_INT64:
				{
					hv_store(child_hv_ptr, child_setting->name, strlen(child_setting->name), newSViv(child_setting->value.llval), 0);
					break;
				}
			case CONFIG_TYPE_FLOAT:
				{
					hv_store(child_hv_ptr, child_setting->name, strlen(child_setting->name), newSVnv(config_setting_get_float(child_setting)), 0);
					break;
				}
			case CONFIG_TYPE_STRING:
				{
					const char *child_val = config_setting_get_string(child_setting);
					hv_store(child_hv_ptr, child_setting->name, strlen(child_setting->name), newSVpvn(child_val, strlen(child_val)), 0);
					break;
				}
			case CONFIG_TYPE_ARRAY:
				{
					SV *sv;
					if (get_general_array(child_setting, &sv) == LIBCONFIG_OK)
					{
						hv_store(child_hv_ptr, child_setting->name, strlen(child_setting->name), sv, 0);
					}
					// ignore error
					break;
				}
			case CONFIG_TYPE_LIST:
				{
					SV *sv;
					if (get_general_list(child_setting, &sv) == LIBCONFIG_OK)
					{
						hv_store(child_hv_ptr, child_setting->name, strlen(child_setting->name), sv, 0);
					}
					// ignore error
					break;
				}
			case CONFIG_TYPE_GROUP:
				{
					SV *sv;
					if (get_general_object(child_setting, &sv) == LIBCONFIG_OK)
					{
						hv_store(child_hv_ptr, child_setting->name, strlen(child_setting->name), sv, 0);
					}
					// ignore error
					break;
				}
			default:
				{
					Perl_warn(aTHX_ "Object have not this type: %d", config_setting_type(setting));
					return LIBCONFIG_ERR_COMMON;
				}
		}
	}
	*sv_pptr = newRV_inc((SV *)child_hv_ptr);
	return LIBCONFIG_OK;
}

/* }}} */

/*
 * Module start
 **/
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
		get_general_value(conf, path, &sv);
        RETVAL = sv;
    }
    OUTPUT:
        RETVAL

SV *
libconfig_value(conf, path)
    Conf::Libconfig conf
    const char *path
    PREINIT:
        SV *sv;
    CODE:
    {
		get_general_value(conf, path, &sv);
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
    CODE:
    {
		if (path != NULL && strlen(path) == 0)
		{
			settings = config_root_setting(conf);
		} else {
			settings = config_lookup(conf, path);
		}
		SV *sv;
		get_general_array(settings, &sv);
		if (SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVAV)
		{
			RETVAL = (AV *)SvRV(sv);
		} else {
			RETVAL = (AV *)sv_2mortal((SV *)newAV());
		}
    }
    OUTPUT:
        RETVAL

HV *
libconfig_fetch_hashref(conf, path)
    Conf::Libconfig conf
    const char *path
    PREINIT:
        config_setting_t *settings;
    CODE:
    {
		if (path != NULL && strlen(path) == 0)
		{
			settings = config_root_setting(conf);
		} else {
			settings = config_lookup(conf, path);
		}
		SV *sv;
		get_general_object(settings, &sv);
		if (SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVHV)
		{
			RETVAL = (HV *)SvRV(sv);
		} else {
			RETVAL = (HV *)sv_2mortal((SV *)newHV());
		}
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
		if (path != NULL && strlen(path) == 0)
		{
			RETVAL = config_root_setting(conf);
		} else {
			RETVAL = config_lookup(conf, path);
		}
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
libconfig_set_value(conf, path, value)
	Conf::Libconfig conf
    const char *path
	SV *value
	CODE:
	{
		RETVAL = set_general_value(conf, path, value);
	}
	OUTPUT:
		RETVAL

int
libconfig_set_boolean_value(conf, path, value)
	Conf::Libconfig conf
    const char *path
	SV *value
	CODE:
	{
		RETVAL = set_boolean_value(conf, path, value);
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
		if (path != NULL && strlen(path) == 0)
		{
			settings = config_root_setting(conf);
		} else {
			settings = config_lookup(conf, path);
		}
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
		if (path != NULL && strlen(path) == 0)
		{
			settings = config_root_setting(conf);
		} else {
			settings = config_lookup(conf, path);
		}
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
		if (path != NULL && strlen(path) == 0)
		{
			settings = config_root_setting(conf);
		} else {
			settings = config_lookup(conf, path);
		}
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
		if (path != NULL && strlen(path) == 0)
		{
			settings = config_root_setting(conf);
		} else {
			settings = config_lookup(conf, path);
		}
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
		if (path != NULL && strlen(path) == 0)
		{
			settings = config_root_setting(conf);
		} else {
			settings = config_lookup(conf, path);
		}
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
		if (path != NULL && strlen(path) == 0)
		{
			settings = config_root_setting(conf);
		} else {
			settings = config_lookup(conf, path);
		}
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

