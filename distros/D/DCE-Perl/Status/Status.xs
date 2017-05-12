#include "../DCE_Perl.h"

MODULE = DCE::Status  PACKAGE = DCE::Status PREFIX = dce_ 

char *
dce_error_inq_text(status)
error_status_t	status

    ALIAS:
    DCE::Status::error_string = 1

    CODE:
    {
    int error_stat;
    unsigned char error_string[dce_c_error_string_len];

    dce_error_inq_text(status, error_string, &error_stat);
    RETVAL = (status == 0) ? NULL : error_string;
    }

    OUTPUT:
    RETVAL

MODULE = DCE::Status  PACKAGE = DCE::Status PREFIX = dce_status_

SV *
dce_status_FETCH(rv)
SV *rv

    CODE:
    {
    int error_stat; 
    unsigned char error_string[dce_c_error_string_len]; 
    SV *sv = SvRV((SV*)ST(0)); 
    RETVAL = newSV(0);
    sv_setnv(RETVAL, (double)SvNV(sv)); 
    dce_error_inq_text(SvIV(sv), error_string, &error_stat); 
    sv_setpv(RETVAL, error_string); 
    SvNOK_on(RETVAL); /* ah, magic */ 
    }

    OUTPUT:
    RETVAL
