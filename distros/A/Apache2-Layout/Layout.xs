#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "httpd.h"
#include "http_request.h"
#include "util_filter.h"

int _call_xs(char *uri, request_rec *r, ap_filter_t *f) {
    request_rec *subr;
    int status;
    subr = ap_sub_req_lookup_uri(uri, r, f->next);
    status = ap_run_sub_req(subr);
    ap_destroy_sub_req(subr);
    return status;
}

MODULE = Apache2::Layout            PACKAGE = Apache2::Layout

int _call_xs(uri, r, f)
	char *uri
	void *r
	void *f
