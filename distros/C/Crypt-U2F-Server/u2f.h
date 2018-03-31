/* =====================================================
 * Adapted as a Perl library by Rene 'cavac' Schickbauer
 *
 * This roughly based on u2f-server.c from Yubico's
 * C library, see https://developers.yubico.com/libu2f-server/
 *
 * In order for this to work, you need to install that
 * library.
 *
 * This adaption is (C) 2014-2015 Rene 'cavac' Schickbauer, but as it
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

char* u2fclib_getError(void);
int u2fclib_init(int debug);
void* u2fclib_get_context(void);
int u2fclib_setKeyHandle(void* ctx, char* buf);
int u2fclib_setPublicKey(void* ctx, char* buf);
int u2fclib_setOrigin(void* ctx, char* origin);
int u2fclib_setAppID(void* ctx, char* appid);
int u2fclib_setChallenge(void* ctx, char* challenge);
char* u2fclib_calcRegistrationChallenge(void* ctx);
char* u2fclib_calcAuthenticationChallenge(void* ctx);
char* u2fclib_verifyRegistration(void* ctx, char* buf, char** pk);
int u2fclib_verifyAuthentication(void* ctx, char* buf);
int u2fclib_free_context(void* ctx);
int u2fclib_deInit(void);
