/* =====================================================
 * Adapted as a Perl library by Rene 'cavac' Schickbauer
 *
 * This roughly based on u2f-server.c from Yubico's
 * C library, see https://developers.yubico.com/libu2f-server/
 *
 * In order for this to work, you need to install that
 * library.
 *
 * This adaption is (C) 2014 Rene 'cavac' Schickbauer, but as it
 * is based on Yubico's code, the licence below applies!
 *
 * We, the community, would hereby thank Yubico for open
 * sourcing their code!
 * ======================================================
 */
/*
* Copyright (c) 2014 Yubico AB
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without
* modification, are permitted provided that the following conditions are
* met:
*
* * Redistributions of source code must retain the above copyright
* notice, this list of conditions and the following disclaimer.
*
* * Redistributions in binary form must reproduce the above
* copyright notice, this list of conditions and the following
* disclaimer in the documentation and/or other materials provided
* with the distribution.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
* "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
* LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
* A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
* OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
* SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
* LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
* DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
* THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
* (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
* OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#include <u2f-server/u2f-server.h>
#include "u2f.h"

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
//#include <stdbool.h>
#include <string.h>

char *p;
char errorstring[10000];
char kh[2048];

char* u2fclib_getError(void) {
    return errorstring;
}

int u2fclib_init(int debug) {
  u2fs_rc rc;

  errorstring[0] = 0; // init with empty string

  rc = u2fs_global_init(debug ? U2FS_DEBUG : 0);
  if (rc != U2FS_OK) {
    sprintf(errorstring, "error: u2fs_global_init (%d): %s", rc,
            u2fs_strerror(rc));
    return 0;
  }
  return 1;
}

void* u2fclib_get_context(void) {
  u2fs_rc rc;
  u2fs_ctx_t *ctx;

  rc = u2fs_init(&ctx);
  if (rc != U2FS_OK) {
    sprintf(errorstring, "error: u2fs_init (%d): %s", rc, u2fs_strerror(rc));
    return 0;
  }

  return (void *)ctx;
}

int u2fclib_setKeyHandle(void* ctx, char* buf) {
  u2fs_rc rc;

    rc = u2fs_set_keyHandle(ctx, buf);
    if (rc != U2FS_OK) {
      sprintf(errorstring, "error: u2fs_set_keyHandle (%d): %s", rc,
              u2fs_strerror(rc));
      return 0;
    }

    return 1;
}


int u2fclib_setPublicKey(void* ctx, char* buf) {
  u2fs_rc rc;

    rc = u2fs_set_publicKey(ctx, (unsigned char *) buf);
    if (rc != U2FS_OK) {
      sprintf(errorstring, "error: u2fs_set_publicKey (%d): %s", rc,
              u2fs_strerror(rc));
      return 0;
    }

    return 1;
}

int u2fclib_setOrigin(void* ctx, char* origin) {
  u2fs_rc rc;

  rc = u2fs_set_origin(ctx, origin);
  if (rc != U2FS_OK) {
    sprintf(errorstring, "error: u2fs_set_origin (%d): %s", rc, u2fs_strerror(rc));
    return 0;
  }
  return 1;
}

int u2fclib_setAppID(void* ctx, char* appid) {
  u2fs_rc rc;

  rc = u2fs_set_appid(ctx, appid);
  if (rc != U2FS_OK) {
    sprintf(errorstring, "error: u2fs_set_appid (%d): %s", rc,
            u2fs_strerror(rc));
    return 0;
  }
  return 1;
}

int u2fclib_setChallenge(void* ctx, char* challenge) {
  u2fs_rc rc;

    rc = u2fs_set_challenge(ctx, challenge);
    if (rc != U2FS_OK) {
      sprintf(errorstring, "error: u2fs_set_challenge (%d): %s", rc,
              u2fs_strerror(rc));
      return 0;
    }
    return 1;
}

char* u2fclib_calcRegistrationChallenge(void* ctx) {
  u2fs_rc rc;

    rc = u2fs_registration_challenge(ctx, &p);
    if (rc != U2FS_OK) {
        sprintf(errorstring, "error (%d): %s", rc, u2fs_strerror(rc));
        p[0] = 0;
    }
    return p;
}

char* u2fclib_calcAuthenticationChallenge(void* ctx) {
  u2fs_rc rc;

    rc = u2fs_authentication_challenge(ctx, &p);
    if (rc != U2FS_OK) {
        sprintf(errorstring, "error (%d): %s", rc, u2fs_strerror(rc));
        p[0] = 0;
    }
    return p;
}

char* u2fclib_verifyRegistration(void* ctx, char* buf, char** pk) {
    u2fs_rc rc;
    u2fs_reg_res_t *reg_result;
    int i;

    rc = u2fs_registration_verify(ctx, buf, &reg_result);
    if (rc != U2FS_OK) {
        sprintf(errorstring, "error (%d): %s", rc, u2fs_strerror(rc));
      return 0;
    }
    memcpy(pk, u2fs_get_registration_publicKey(reg_result), U2FS_PUBLIC_KEY_LEN);

    strncpy(kh, u2fs_get_registration_keyHandle(reg_result), 2048);
    return kh;

}

int u2fclib_verifyAuthentication(void* ctx, char* buf) {
  u2fs_rc rc;
    u2fs_auth_res_t *auth_result;

    rc = u2fs_authentication_verify(ctx, buf, &auth_result);
    if (rc == U2FS_OK) {
      u2fs_rc verified;
      uint32_t counter;
      uint8_t user_presence;
      rc = u2fs_get_authentication_result(auth_result, &verified, &counter,
                                          &user_presence);
      if (verified == U2FS_OK) {
        return 1;
      } else {
        sprintf(errorstring, "Authentication failed: %s", u2fs_strerror(rc));
        return 0;
      }
    } else if (rc != U2FS_OK) {
      sprintf(errorstring, "error: u2fs_authentication_verify (%d): %s", rc,
              u2fs_strerror(rc));
      return 0;
    }
}

int u2fclib_free_context(void* ctx) {
  u2fs_done(ctx);
  return 1;
}

int u2fclib_deInit(void) {
  u2fs_global_done();
  return 1;
}


