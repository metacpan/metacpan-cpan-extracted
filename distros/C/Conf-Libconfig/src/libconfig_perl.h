/*
 * Conf::Libconfig - Internal C function declarations
 * Auto-parsed by ExtUtils::XSBuilder for XS binding generation.
 */

#ifndef LIBCONFIG_PERL_H
#define LIBCONFIG_PERL_H

#include <libconfig.h>
#include <EXTERN.h>
#include <perl.h>

#define UINTNUM 2147483647
#define LIBCONFIG_OK                0
#define LIBCONFIG_ERR_COMMON        -1
#define LIBCONFIG_ERR_INPUT         -2

typedef config_t *Conf__Libconfig;
typedef config_setting_t *Conf__Libconfig__Settings;

void auto_check_and_create(Conf__Libconfig, const char *, config_setting_t **, char **);
int sv2int(config_setting_t *, SV *);
int sv2float(config_setting_t *, SV *);
int sv2string(config_setting_t *, SV *);
int sv2addint(const char *, config_setting_t *, config_setting_t *, SV *);
int sv2addfloat(const char *, config_setting_t *, config_setting_t *, SV *);
int sv2addstring(const char *, config_setting_t *, config_setting_t *, SV *);
int sv2addarray(config_setting_t *, char *, config_setting_t *, SV *);
int sv2addobject(config_setting_t *, char *, config_setting_t *, SV *);

void set_scalar(config_setting_t *, SV *, int, int *);
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
int populate_scalar_sv(config_setting_t *, SV **);

int set_boolean_value(Conf__Libconfig, const char *, SV *);
int set_general_value(Conf__Libconfig, const char *, SV *);

void remove_scalar_node(config_setting_t *, const char *, int, int *);

#endif /* LIBCONFIG_PERL_H */