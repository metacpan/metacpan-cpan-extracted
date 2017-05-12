#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <libecasoundc/ecasoundc.h>

MODULE = Audio::Ecasound        PACKAGE = Audio::Ecasound

PROTOTYPES: ENABLE

BOOT:
eci_init();

void
eci_cleanup()

void
eci_command(cmd)
    const char *    cmd

void
eci_command_float_arg(arg0, arg)
    const char *    arg0
    double    arg

double
eci_last_float()

int
eci_last_integer()

long int
eci_last_long_integer()

const char *
eci_last_string()

int
eci_last_string_list_count()

const char *
eci_last_string_list_item(n)
    int    n

const char *
eci_last_type()

int
eci_error()

const char *
eci_last_error()




eci_handle_t
eci_init_r()

void
eci_cleanup_r(p)
    eci_handle_t    p

void
eci_command_float_arg_r(p, arg1, arg)
    eci_handle_t    p
    const char *    arg1
    double    arg

void
eci_command_r(p, cmd)
    eci_handle_t    p
    const char *    cmd

double
eci_last_float_r(p)
    eci_handle_t    p

int
eci_last_integer_r(p)
    eci_handle_t    p

long int
eci_last_long_integer_r(p)
    eci_handle_t    p

int
eci_last_string_list_count_r(p)
    eci_handle_t    p

const char *
eci_last_string_list_item_r(p, n)
    eci_handle_t    p
    int    n

const char *
eci_last_string_r(p)
    eci_handle_t    p

const char *
eci_last_type_r(p)
    eci_handle_t    p

int
eci_error_r(p)
    eci_handle_t    p

const char *
eci_last_error_r(p)
    eci_handle_t    p
