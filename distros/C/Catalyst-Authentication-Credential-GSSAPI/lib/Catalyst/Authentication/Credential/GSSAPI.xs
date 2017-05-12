#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <gssapi.h>
#include <gssapi/gssapi.h>
#include <gssapi/gssapi_generic.h>
#include <gssapi/gssapi_krb5.h>
#include <gssapi/gssapi_ext.h>

#define k_token "token"
#define k_status "status"
#define k_minor_status "minor_status"
#define k_name_status "name_status"
#define k_name_minor_status "name_minor_status"
#define k_src_name "src_name"
#define k_src_name_type "src_name_type"
#define k_mech_type "mech_type"
#define k_output_token "output_token"
#define k_ret_flags "ret_flags"
#define k_time_rec "time_rec"
#define ks(x) sizeof(x)-1

#define rsc(x) sprintf(int2str,"%d",x); hv_store(ret_hash, int2str, strlen(int2str), newSVpv(#x,ks(#x)), 0)

static gss_ctx_id_t context_hndl = GSS_C_NO_CONTEXT;

MODULE = Catalyst::Authentication::Credential::GSSAPI PACKAGE = Catalyst::Authentication::Credential::GSSAPI PREFIX = cacgssapi_

SV *
cacgssapi_status_codes()
CODE:
{
  char int2str[32] = "";
  HV* ret_hash = newHV();
  rsc(GSS_S_COMPLETE);
  rsc(GSS_S_CALL_INACCESSIBLE_READ);
  rsc(GSS_S_CALL_INACCESSIBLE_WRITE);
  rsc(GSS_S_CALL_BAD_STRUCTURE);
  rsc(GSS_S_BAD_MECH);
  rsc(GSS_S_BAD_NAME);
  rsc(GSS_S_BAD_NAMETYPE);
  rsc(GSS_S_BAD_BINDINGS);
  rsc(GSS_S_BAD_STATUS);
  rsc(GSS_S_BAD_SIG);
  rsc(GSS_S_NO_CRED);
  rsc(GSS_S_NO_CONTEXT);
  rsc(GSS_S_DEFECTIVE_TOKEN);
  rsc(GSS_S_DEFECTIVE_CREDENTIAL);
  rsc(GSS_S_CREDENTIALS_EXPIRED);
  rsc(GSS_S_CONTEXT_EXPIRED);
  rsc(GSS_S_FAILURE);
  rsc(GSS_S_BAD_QOP);
  rsc(GSS_S_UNAUTHORIZED);
  rsc(GSS_S_UNAVAILABLE);
  rsc(GSS_S_DUPLICATE_ELEMENT);
  rsc(GSS_S_NAME_NOT_MN);
  rsc(GSS_S_BAD_MECH_ATTR);
  rsc(GSS_S_CONTINUE_NEEDED);
  rsc(GSS_S_DUPLICATE_TOKEN);
  rsc(GSS_S_OLD_TOKEN);
  rsc(GSS_S_UNSEQ_TOKEN);
  rsc(GSS_S_GAP_TOKEN);
  rsc(GSS_S_CRED_UNAVAIL);
  RETVAL = newRV_noinc((SV*) ret_hash);
}
OUTPUT:
RETVAL

void
cacgssapi_reset_negotiation()
  CODE:
{
  int minor_status = 0;
  if (context_hndl != GSS_C_NO_CONTEXT) {
    gss_delete_sec_context(&minor_status, &context_hndl, GSS_C_NO_BUFFER);
    context_hndl = GSS_C_NO_CONTEXT;
  }
}

SV *
cacgssapi_perform_negotiation(args_hr)
  SV* args_hr
  CODE:
{
  gss_buffer_desc input_token_struct;
  gss_buffer_t input_token = &input_token_struct;
  int release_buffer_status = 0;

  unsigned int status = 0;
  unsigned int minor_status = 0;
  gss_name_t src_name = NULL;
  gss_OID src_name_type = NULL;
  gss_buffer_desc src_name_buf_struct;
  gss_buffer_t src_name_buf = &src_name_buf_struct;
  gss_OID mech_type = NULL;
  gss_buffer_desc output_token_struct;
  gss_buffer_t output_token = &output_token_struct;
  unsigned int ret_flags = 0;
  unsigned int time_rec = 0;
  gss_cred_id_t delegated_cred_handle = NULL;
  if (SvROK(args_hr)) {
    HV* args_val = (HV*)SvRV(args_hr);
    if (SvTYPE(args_val) == SVt_PVHV) {
      if (hv_exists(args_val, k_token, ks(k_token))) {
	SV** tokensv = hv_fetch(args_val, k_token, ks(k_token), 0);
	input_token->value = SvPV(*tokensv, input_token->length);
    
	status = gss_accept_sec_context
	  (
	   &minor_status,
	   &context_hndl,
	   GSS_C_NO_CREDENTIAL,
	   input_token,
	   GSS_C_NO_CHANNEL_BINDINGS,
	   &src_name,
	   &mech_type,
	   output_token,
	   &ret_flags,
	   &time_rec,
	   &delegated_cred_handle);
    
	HV* ret_hash = newHV();
	hv_store(ret_hash, k_status, ks(k_status),
		 newSViv(status), 0);
	hv_store(ret_hash, k_minor_status, ks(k_minor_status),
		 newSViv(minor_status), 0);
	if (src_name) {
	  int name_status = 0;
	  int name_minor_status = 0;
	  name_status = gss_display_name
	    (
	     &name_minor_status,
	     src_name,
	     src_name_buf,
	     &src_name_type
	     );
	  hv_store(ret_hash, k_name_status, ks(k_name_status),
		   newSViv(status), 0);
	  hv_store(ret_hash, k_name_minor_status, ks(k_name_minor_status),
		   newSViv(minor_status), 0);
	  if (src_name_buf) {
	    hv_store(ret_hash, k_src_name, ks(k_src_name),
		     newSVpv((char*)src_name_buf->value,
			     src_name_buf->length), 0);
	    gss_release_buffer(&release_buffer_status, src_name_buf);
	  }
	  if (src_name_type) {
	    hv_store(ret_hash, k_src_name_type, ks(k_src_name_type),
		     newSVpv((char*)src_name_type->elements,
			     src_name_type->length), 0);
	  }
	  int release_name_status;
	  gss_release_name(&release_name_status, &src_name);
	}
	if (mech_type) {
	  hv_store(ret_hash, k_mech_type, ks(k_mech_type),
		   newSVpv((char*)mech_type->elements,
			   mech_type->length), 0);
	}
	if (output_token) {
	  hv_store(ret_hash, k_output_token, ks(k_output_token),
		   newSVpv((char*)output_token->value,
			   output_token->length), 0);
	}
	hv_store(ret_hash, k_ret_flags, ks(k_ret_flags),
		 newSViv(ret_flags), 0);
	hv_store(ret_hash, k_time_rec, ks(k_time_rec),
		 newSViv(time_rec), 0);
    
	gss_release_buffer(&release_buffer_status, output_token);
	
	RETVAL = newRV_noinc((SV*) ret_hash);
      } else {
        //fprintf(stderr, "No token in arguments\n");
	RETVAL = &PL_sv_undef;
      }
    } else {
      //fprintf(stderr, "Not a hash reference\n");
      RETVAL = &PL_sv_undef;
    }
  } else {
    //fprintf(stderr, "Not a reference\n");
    RETVAL = &PL_sv_undef;
  }
}
OUTPUT:
RETVAL


// ----------------------------------------------------------------------------
// Copyright 2015 Bloomberg Finance L.P.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// ----------------------------- END-OF-FILE ----------------------------------
