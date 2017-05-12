// Copyright (c) 2017 Marcel Greter.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

// dont hook libc calls
#define NO_XSLOCKS

#ifdef __cplusplus
extern "C" {
#endif

#include "EXTERN.h"
#undef my_setlocale
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#ifdef __cplusplus
}
#endif

#include <stdbool.h>
#include <stdarg.h>
#include <stdio.h>
#include <zopfli.h>

#define Constant(c) newCONSTSUB(stash, #c, newSViv(c))

#undef free

MODULE = Compress::Zopfli		PACKAGE = Compress::Zopfli

BOOT:
{
    HV* stash = gv_stashpv("Compress::Zopfli", 0);

    Constant(ZOPFLI_FORMAT_GZIP);
    Constant(ZOPFLI_FORMAT_ZLIB);
    Constant(ZOPFLI_FORMAT_DEFLATE);
}

SV*
compress(input, format, options)
               SV* input
               SV* format
               HV* options
    CODE:
    {

        struct ZopfliOptions zopfliOptions;

        ZopfliInitOptions(&zopfliOptions);

        if (!SvIOKp(format)) croak("Format not numerical");

        if (hv_exists(options, "iterations", 10)) {
            SV** sv = hv_fetch(options, "iterations", 10, 0);
            if (!sv) croak("Null-ptr on `iterations` option");
            else if (!SvIOKp(*sv)) croak("`iterations` is not a number");
            else zopfliOptions.numiterations = SvIV(*sv);
        }

        if (hv_exists(options, "blocksplitting", 6)) {
            SV** sv = hv_fetch(options, "blocksplitting", 14, 0);
            if (!sv) croak("Null-ptr on `blocksplitting` option");
            else if (!SvIOKp(*sv)) croak("`blocksplitting` is not a number");
            else zopfliOptions.blocksplitting = SvIV(*sv);
        }

        if (hv_exists(options, "blocksplittingmax", 9)) {
            SV** sv = hv_fetch(options, "blocksplittingmax", 17, 0);
            if (!sv) croak("Null-ptr on `blocksplittingmax` option");
            else if (!SvIOKp(*sv)) croak("`blocksplittingmax` is not a number");
            else zopfliOptions.blocksplittingmax = SvIV(*sv);
        }

        char* zopfliOut = 0;
        size_t zopfliOutsize = 0;
        char* buffer = SvPVbyte(input, SvCUR(input));

        ZopfliCompress(&zopfliOptions, (ZopfliFormat)SvIV(format),
                       // do not treat binary buffer as strings!
                       (unsigned char*) buffer, SvCUR(input),
                       (unsigned char**) &zopfliOut, &zopfliOutsize);

        RETVAL = newSVpv(zopfliOut, zopfliOutsize);

    }
    OUTPUT:
             RETVAL

SV*
zopfli_version()
    CODE:
    {

        RETVAL = newSVpv("0.1.2", 0);

    }
    OUTPUT:
             RETVAL
