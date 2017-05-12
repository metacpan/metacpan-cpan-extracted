/*
 ******************************************************************************
 *
 * File:    Simple.xs
 *
 * Author:  Damien S. Stuart
 *
 * Purpose: .xs file for the Authen::Krb5::Simple Perl module.
 *
 *
 ******************************************************************************
*/
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <krb5.h>

int _krb5_auth(char* user, char* pass)
{
    int             krbret;
    krb5_context    ctx;
    krb5_creds      creds;
    krb5_principal  princ;

    int ret = 0;

    /* Initialize krb5 context...
    */
    if ((krbret = krb5_init_context(&ctx))) {
        return krbret;
    }

    memset(&creds, 0, sizeof(krb5_creds));

    /* Get principal name...
    */
    if ((krbret = krb5_parse_name(ctx, user, &princ))) {
        ret = krbret;
        goto free_context;
    }

    /* Check the user's pasword...
    */
    if ((krbret = krb5_get_init_creds_password(
      ctx, &creds, princ, pass, 0, NULL, 0, NULL, NULL))) {
        ret = krbret;
    }

    krb5_free_cred_contents(ctx, &creds);
    krb5_free_principal(ctx, princ);

free_context:
    krb5_free_context(ctx);

    return(ret);
}

MODULE = Authen::Krb5::Simple     PACKAGE = Authen::Krb5::Simple        

PROTOTYPES: DISABLE

int
krb5_auth(user, password)
    INPUT:
    char * user;
    char * password;
    CODE:
    RETVAL = _krb5_auth(user, password);
    OUTPUT:
    RETVAL

char*
krb5_errstr(errcode)
    INPUT:
    int errcode;
    INIT:
    char* result = (char*)error_message(errcode);
    CODE:
    RETVAL = result;
    OUTPUT:
    RETVAL

