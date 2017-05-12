#include "httpd.h"
#include "http_config.h"
#include "http_core.h"
#include "http_request.h"
#include "http_protocol.h"
#include "http_log.h"
#include "http_main.h"
#include "util_script.h"

module MODULE_VAR_EXPORT icon_module;

typedef struct {
    char *default_icon;
    array_header *icon_list, *alt_list;
} icon_dir_config;

typedef struct {
    int decline_cmd;
} icon_srv_config;

char *ap_icon_find(request_rec *r, int path_only);
char *ap_icon_default(request_rec *r, char *name);
char *ap_icon_alt(request_rec *r, int path_only);
