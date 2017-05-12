#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include <dce/rpcbase.h>

static int
not_here(s)
char *s;
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant(name, arg)
char *name;
int arg;
{
    errno = 0;
    switch (*name) {
    case 'a':
	break;
    case 'b':
	break;
    case 'c':
	break;
    case 'd':
	break;
    case 'e':
	break;
    case 'f':
	break;
    case 'g':
	break;
    case 'h':
	break;
    case 'i':
	break;
    case 'j':
	break;
    case 'k':
	break;
    case 'l':
	break;
    case 'm':
	break;
    case 'n':
	break;
    case 'o':
	break;
    case 'p':
	break;
    case 'q':
	break;
    case 'r':
	if (strEQ(name, "rpc_c_authn_dce_dummy"))
#ifdef rpc_c_authn_dce_dummy
	    return rpc_c_authn_dce_dummy;
#else
	    goto not_there;
#endif
	if (strEQ(name, "rpc_c_authn_dce_public"))
#ifdef rpc_c_authn_dce_public
	    return rpc_c_authn_dce_public;
#else
	    goto not_there;
#endif
	if (strEQ(name, "rpc_c_authn_dce_secret"))
#ifdef rpc_c_authn_dce_secret
	    return rpc_c_authn_dce_secret;
#else
	    goto not_there;
#endif
	if (strEQ(name, "rpc_c_authn_default"))
#ifdef rpc_c_authn_default
	    return rpc_c_authn_default;
#else
	    goto not_there;
#endif
	if (strEQ(name, "rpc_c_authn_dssa_public"))
#ifdef rpc_c_authn_dssa_public
	    return rpc_c_authn_dssa_public;
#else
	    goto not_there;
#endif
	if (strEQ(name, "rpc_c_authn_none"))
#ifdef rpc_c_authn_none
	    return rpc_c_authn_none;
#else
	    goto not_there;
#endif
	if (strEQ(name, "rpc_c_authz_dce"))
#ifdef rpc_c_authz_dce
	    return rpc_c_authz_dce;
#else
	    goto not_there;
#endif
	if (strEQ(name, "rpc_c_authz_name"))
#ifdef rpc_c_authz_name
	    return rpc_c_authz_name;
#else
	    goto not_there;
#endif
	if (strEQ(name, "rpc_c_authz_none"))
#ifdef rpc_c_authz_none
	    return rpc_c_authz_none;
#else
	    goto not_there;
#endif
	if (strEQ(name, "rpc_c_binding_default_timeout"))
#ifdef rpc_c_binding_default_timeout
	    return rpc_c_binding_default_timeout;
#else
	    goto not_there;
#endif
	if (strEQ(name, "rpc_c_binding_infinite_timeout"))
#ifdef rpc_c_binding_infinite_timeout
	    return rpc_c_binding_infinite_timeout;
#else
	    goto not_there;
#endif
	if (strEQ(name, "rpc_c_binding_max_count_default"))
#ifdef rpc_c_binding_max_count_default
	    return rpc_c_binding_max_count_default;
#else
	    goto not_there;
#endif
	if (strEQ(name, "rpc_c_binding_max_timeout"))
#ifdef rpc_c_binding_max_timeout
	    return rpc_c_binding_max_timeout;
#else
	    goto not_there;
#endif
	if (strEQ(name, "rpc_c_binding_min_timeout"))
#ifdef rpc_c_binding_min_timeout
	    return rpc_c_binding_min_timeout;
#else
	    goto not_there;
#endif
	if (strEQ(name, "rpc_c_call_brdcst"))
#ifdef rpc_c_call_brdcst
	    return rpc_c_call_brdcst;
#else
	    goto not_there;
#endif
	if (strEQ(name, "rpc_c_call_idempotent"))
#ifdef rpc_c_call_idempotent
	    return rpc_c_call_idempotent;
#else
	    goto not_there;
#endif
	if (strEQ(name, "rpc_c_call_in_pipe"))
#ifdef rpc_c_call_in_pipe
	    return rpc_c_call_in_pipe;
#else
	    goto not_there;
#endif
	if (strEQ(name, "rpc_c_call_maybe"))
#ifdef rpc_c_call_maybe
	    return rpc_c_call_maybe;
#else
	    goto not_there;
#endif
	if (strEQ(name, "rpc_c_call_non_idempotent"))
#ifdef rpc_c_call_non_idempotent
	    return rpc_c_call_non_idempotent;
#else
	    goto not_there;
#endif
	if (strEQ(name, "rpc_c_call_out_pipe"))
#ifdef rpc_c_call_out_pipe
	    return rpc_c_call_out_pipe;
#else
	    goto not_there;
#endif
	if (strEQ(name, "rpc_c_cancel_infinite_timeout"))
#ifdef rpc_c_cancel_infinite_timeout
	    return rpc_c_cancel_infinite_timeout;
#else
	    goto not_there;
#endif
	if (strEQ(name, "rpc_c_ep_max_annotation_size"))
#ifdef rpc_c_ep_max_annotation_size
	    return rpc_c_ep_max_annotation_size;
#else
	    goto not_there;
#endif
	if (strEQ(name, "rpc_c_listen_max_calls_default"))
#ifdef rpc_c_listen_max_calls_default
	    return rpc_c_listen_max_calls_default;
#else
	    goto not_there;
#endif
	if (strEQ(name, "rpc_c_mgmt_inq_if_ids"))
#ifdef rpc_c_mgmt_inq_if_ids
	    return rpc_c_mgmt_inq_if_ids;
#else
	    goto not_there;
#endif
	if (strEQ(name, "rpc_c_mgmt_inq_princ_name"))
#ifdef rpc_c_mgmt_inq_princ_name
	    return rpc_c_mgmt_inq_princ_name;
#else
	    goto not_there;
#endif
	if (strEQ(name, "rpc_c_mgmt_inq_stats"))
#ifdef rpc_c_mgmt_inq_stats
	    return rpc_c_mgmt_inq_stats;
#else
	    goto not_there;
#endif
	if (strEQ(name, "rpc_c_mgmt_is_server_listen"))
#ifdef rpc_c_mgmt_is_server_listen
	    return rpc_c_mgmt_is_server_listen;
#else
	    goto not_there;
#endif
	if (strEQ(name, "rpc_c_mgmt_stop_server_listen"))
#ifdef rpc_c_mgmt_stop_server_listen
	    return rpc_c_mgmt_stop_server_listen;
#else
	    goto not_there;
#endif
	if (strEQ(name, "rpc_c_ns_dec_dns"))
#ifdef rpc_c_ns_dec_dns
	    return rpc_c_ns_dec_dns;
#else
	    goto not_there;
#endif
	if (strEQ(name, "rpc_c_ns_default_exp_age"))
#ifdef rpc_c_ns_default_exp_age
	    return rpc_c_ns_default_exp_age;
#else
	    goto not_there;
#endif
	if (strEQ(name, "rpc_c_ns_none"))
#ifdef rpc_c_ns_none
	    return rpc_c_ns_none;
#else
	    goto not_there;
#endif
	if (strEQ(name, "rpc_c_ns_syntax_dce"))
#ifdef rpc_c_ns_syntax_dce
	    return rpc_c_ns_syntax_dce;
#else
	    goto not_there;
#endif
	if (strEQ(name, "rpc_c_ns_syntax_dec_dns"))
#ifdef rpc_c_ns_syntax_dec_dns
	    return rpc_c_ns_syntax_dec_dns;
#else
	    goto not_there;
#endif
	if (strEQ(name, "rpc_c_ns_syntax_default"))
#ifdef rpc_c_ns_syntax_default
	    return rpc_c_ns_syntax_default;
#else
	    goto not_there;
#endif
	if (strEQ(name, "rpc_c_ns_syntax_internet_dns"))
#ifdef rpc_c_ns_syntax_internet_dns
	    return rpc_c_ns_syntax_internet_dns;
#else
	    goto not_there;
#endif
	if (strEQ(name, "rpc_c_ns_syntax_unknown"))
#ifdef rpc_c_ns_syntax_unknown
	    return rpc_c_ns_syntax_unknown;
#else
	    goto not_there;
#endif
	if (strEQ(name, "rpc_c_ns_syntax_uuid"))
#ifdef rpc_c_ns_syntax_uuid
	    return rpc_c_ns_syntax_uuid;
#else
	    goto not_there;
#endif
	if (strEQ(name, "rpc_c_ns_syntax_x500"))
#ifdef rpc_c_ns_syntax_x500
	    return rpc_c_ns_syntax_x500;
#else
	    goto not_there;
#endif
	if (strEQ(name, "rpc_c_profile_all_elts"))
#ifdef rpc_c_profile_all_elts
	    return rpc_c_profile_all_elts;
#else
	    goto not_there;
#endif
	if (strEQ(name, "rpc_c_profile_default_elt"))
#ifdef rpc_c_profile_default_elt
	    return rpc_c_profile_default_elt;
#else
	    goto not_there;
#endif
	if (strEQ(name, "rpc_c_profile_match_by_both"))
#ifdef rpc_c_profile_match_by_both
	    return rpc_c_profile_match_by_both;
#else
	    goto not_there;
#endif
	if (strEQ(name, "rpc_c_profile_match_by_if"))
#ifdef rpc_c_profile_match_by_if
	    return rpc_c_profile_match_by_if;
#else
	    goto not_there;
#endif
	if (strEQ(name, "rpc_c_profile_match_by_mbr"))
#ifdef rpc_c_profile_match_by_mbr
	    return rpc_c_profile_match_by_mbr;
#else
	    goto not_there;
#endif
	if (strEQ(name, "rpc_c_protect_level_call"))
#ifdef rpc_c_protect_level_call
	    return rpc_c_protect_level_call;
#else
	    goto not_there;
#endif
	if (strEQ(name, "rpc_c_protect_level_connect"))
#ifdef rpc_c_protect_level_connect
	    return rpc_c_protect_level_connect;
#else
	    goto not_there;
#endif
	if (strEQ(name, "rpc_c_protect_level_default"))
#ifdef rpc_c_protect_level_default
	    return rpc_c_protect_level_default;
#else
	    goto not_there;
#endif
	if (strEQ(name, "rpc_c_protect_level_none"))
#ifdef rpc_c_protect_level_none
	    return rpc_c_protect_level_none;
#else
	    goto not_there;
#endif
	if (strEQ(name, "rpc_c_protect_level_pkt"))
#ifdef rpc_c_protect_level_pkt
	    return rpc_c_protect_level_pkt;
#else
	    goto not_there;
#endif
	if (strEQ(name, "rpc_c_protect_level_pkt_integ"))
#ifdef rpc_c_protect_level_pkt_integ
	    return rpc_c_protect_level_pkt_integ;
#else
	    goto not_there;
#endif
	if (strEQ(name, "rpc_c_protect_level_pkt_privacy"))
#ifdef rpc_c_protect_level_pkt_privacy
	    return rpc_c_protect_level_pkt_privacy;
#else
	    goto not_there;
#endif
	if (strEQ(name, "rpc_c_protseq_max_reqs_default"))
#ifdef rpc_c_protseq_max_reqs_default
	    return rpc_c_protseq_max_reqs_default;
#else
	    goto not_there;
#endif
	if (strEQ(name, "rpc_s_ok"))
#ifdef rpc_s_ok
	    return rpc_s_ok;
#else
	    goto not_there;
#endif
	if (strEQ(name, "rpcbase_v0_0_included"))
#ifdef rpcbase_v0_0_included
	    return rpcbase_v0_0_included;
#else
	    goto not_there;
#endif
	break;
    case 's':
	break;
    case 't':
	break;
    case 'u':
	break;
    case 'v':
	if (strEQ(name, "volatile"))
#ifdef volatile
	    return volatile;
#else
	    goto not_there;
#endif
	break;
    case 'w':
	break;
    case 'x':
	break;
    case 'y':
	break;
    case 'z':
	break;
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}


MODULE = DCE::rpcbase		PACKAGE = DCE::rpcbase		


double
constant(name,arg)
	char *		name
	int		arg

