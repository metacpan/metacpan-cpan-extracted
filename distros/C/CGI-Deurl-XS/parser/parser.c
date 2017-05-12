/*
 * Portions taken from libapreq 1.33.
 * Copyright 2007 The Apache Software Foundation.
 * Used under the Apache License v2.0.
 * http://search.cpan.org/~stas/libapreq-1.33/
 */

#ifndef __USE_GNU
#define __USE_GNU
#endif
#include <string.h>
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>

#include "parser.h"

static
void
req_plustospace(char* str)
{
    register int x;
    for(x=0;str[x];x++)
        if(str[x] == '+')
            str[x] = ' ';
}

static
char
x2c(char* what)
{
    register char digit;

    digit = ((what[0] >= 'A') ? ((what[0] & 0xdf) - 'A') + 10 : (what[0] - '0'));
    digit *= 16;
    digit += (what[1] >= 'A' ? ((what[1] & 0xdf) - 'A') + 10 : (what[1] - '0'));
    return digit;
}

static
unsigned int
utf8_convert(char* str)
{
    long x = 0;
    int i = 0;
    while (i < 4 ) {
        if ( isxdigit(str[i]) != 0 ) {
            if( isdigit(str[i]) != 0 ) {
                x = x * 16 + str[i] - '0';
            }
            else {
                str[i] = tolower( str[i] );
                x = x * 16 + str[i] - 'a' + 10;
            }
        }
        else {
            return 0;
        }
        i++;
    }
    if(i < 3)
        return 0;
    return (x);
}

static
int
unescape_url_u(char* url)
{
    register int x, y, badesc, badpath;

    badesc = 0;
    badpath = 0;
    for (x = 0, y = 0; url[y]; ++x, ++y) {
        if (url[y] != '%'){
            url[x] = url[y];
        }
        else {
            if(url[y + 1] == 'u' || url[y + 1] == 'U'){
                unsigned int c = utf8_convert(&url[y + 2]);
                y += 5;
                if(c < 0x80){
                    url[x] = c;
                }
                else if(c < 0x800) {
                    url[x] = 0xc0 | (c >> 6);
                    url[++x] = 0x80 | (c & 0x3f);
                }
                else if(c < 0x10000){
                    url[x] = (0xe0 | (c >> 12));
                    url[++x] = (0x80 | ((c >> 6) & 0x3f));
                    url[++x] = (0x80 | (c & 0x3f));
                }
                else if(c < 0x200000){
                    url[x] = 0xf0 | (c >> 18);
                    url[++x] = 0x80 | ((c >> 12) & 0x3f);
                    url[++x] = 0x80 | ((c >> 6) & 0x3f);
                    url[++x] = 0x80 | (c & 0x3f);
                }
                else if(c < 0x4000000){
                    url[x] = 0xf8 | (c >> 24);
                    url[++x] = 0x80 | ((c >> 18) & 0x3f);
                    url[++x] = 0x80 | ((c >> 12) & 0x3f);
                    url[++x] = 0x80 | ((c >> 6) & 0x3f);
                    url[++x] = 0x80 | (c & 0x3f);
                }
                else if(c < 0x8000000){
                    url[x] = 0xfe | (c >> 30);
                    url[++x] = 0x80 | ((c >> 24) & 0x3f);
                    url[++x] = 0x80 | ((c >> 18) & 0x3f);
                    url[++x] = 0x80 | ((c >> 12) & 0x3f);
                    url[++x] = 0x80 | ((c >> 6) & 0x3f);
                    url[++x] = 0x80 | (c & 0x3f);
                }
            }
            else {
                if (!isxdigit(url[y + 1]) || !isxdigit(url[y + 2])) {
                    badesc = 1;
                    url[x] = '%';
                }
                else {
                    url[x] = x2c(&url[y + 1]);
                    y += 2;
                    if (url[x] == '/' || url[x] == '\0')
                        badpath = 1;
                }
            }
        }
    }
    url[x] = '\0';
    if (badesc)
        return 0;
    else if (badpath)
        return 0;
    else
        return 1;
}

static
char*
_strndup(char* str, size_t len)
{
    char *dup = (char*) malloc(len+1);
    if (dup) {
        strncpy(dup, str, len);
        dup[len] = '\0';
    }
    return dup;
}


static
char*
urlword(char** line)
{
    char* res = 0;
    char* pos = *line;
    char ch;

    while ( (ch = *pos) != '\0' && ch != ';' && ch != '&') {
        ++pos;
    }

    res = _strndup(*line, pos - *line);

    while (ch == ';' || ch == '&') {
        ++pos;
        ch = *pos;
    }

    *line = pos;

    return res;
}

char*
getword(char** line, char stop)
{
    char* pos = *line;
    int len;
    char* res;

    while ((*pos != stop) && *pos) {
        ++pos;
    }

    len = pos - *line;
    res = (char*)malloc(len + 1);
    memcpy(res, *line, len);
    res[len] = 0;

    if (stop) {
        while (*pos == stop) {
            ++pos;
        }
    }
    *line = pos;

    return res;
}

SV*
_split_to_parms(char* data)
{
    char* val;
    HV* hash = 0;

    while (*data && (val = urlword(&data))) {
        char* val_orig = val;
        char* key = getword(&val, '=');

        req_plustospace((char*)key);
        unescape_url_u((char*)key);
        req_plustospace((char*)val);
        unescape_url_u((char*)val);

        if (!hash) {
            hash = newHV();
        }

        int klen = strlen(key);
        SV* newval = newSVpv(val, 0);

        if (hv_exists(hash, key, klen)) {
            /* this param already exists */

            SV** entry = hv_fetch(hash, key, klen, 0);
            if (!entry) {
                return 0;
            }

            if (SvROK(*entry) && SvTYPE(SvRV(*entry)) == SVt_PVAV) {
                /* already an arrayref, just push to the end */
                av_push((AV*) SvRV(*entry), newval);
            }
            else {
                /* just a scalar; wrap the new and old values in an arrayref */
                SV* values[2] = { *entry, newval };
                AV* array = av_make(2, values);      /* this copies the SVs... */
                SvREFCNT_dec(newval);                /* ... so destroy the original. */
                SV* aref = newRV_noinc((SV*) array); /* create an array ref... */
                hv_store(hash, key, klen, aref, 0);  /* ... and stash it in the hash */
            }
        }
        else {
            /* no existing param, pop this one in */
            hv_store(hash, key, klen, newval, 0);
        }

        free(key);
        free(val_orig);
    }

    return hash ? newRV_noinc((SV*) hash) : 0;
}
