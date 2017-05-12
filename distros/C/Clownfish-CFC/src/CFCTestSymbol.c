/* Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include <string.h>

#define CFC_USE_TEST_MACROS
#include "CFCBase.h"
#include "CFCClass.h"
#include "CFCParcel.h"
#include "CFCSymbol.h"
#include "CFCTest.h"
#include "CFCUtil.h"

#ifndef true
  #define true 1
  #define false 0
#endif

static void
S_run_tests(CFCTest *test);

const CFCTestBatch CFCTEST_BATCH_SYMBOL = {
    "Clownfish::CFC::Model::Symbol",
    24,
    S_run_tests
};

static char*
S_try_new_symbol(const char *name) {
    CFCSymbol *symbol = NULL;
    char      *error;

    CFCUTIL_TRY {
        symbol = CFCSymbol_new("parcel", name);
    }
    CFCUTIL_CATCH(error);

    CFCBase_decref((CFCBase*)symbol);
    return error;
}

static void
S_run_tests(CFCTest *test) {
    CFCParcel *parcel = CFCParcel_new("Parcel", NULL, NULL, NULL, NULL);

    {
        static const char *exposures[4] = {
            "public", "private", "parcel", "local"
        };
        static int (*accessors[4])(CFCSymbol *sym) = {
            CFCSymbol_public,
            CFCSymbol_private,
            CFCSymbol_parcel,
            CFCSymbol_local
        };
        for (int i = 0; i < 4; ++i) {
            CFCSymbol *symbol = CFCSymbol_new(exposures[i], "sym");
            for (int j = 0; j < 4; ++j) {
                int has_exposure = accessors[j](symbol);
                if (i == j) {
                    OK(test, has_exposure, "exposure %s", exposures[i]);
                }
                else {
                    OK(test, !has_exposure, "%s means not %s", exposures[i],
                       exposures[j]);
                }
            }
            CFCBase_decref((CFCBase*)symbol);
        }
    }

    {
        CFCSymbol *public_exposure = CFCSymbol_new("public", "sym");
        CFCSymbol *parcel_exposure = CFCSymbol_new("parcel", "sym");
        int equal = CFCSymbol_equals(public_exposure, parcel_exposure);
        OK(test, !equal, "different exposure spoils equals");
        CFCBase_decref((CFCBase*)public_exposure);
        CFCBase_decref((CFCBase*)parcel_exposure);
    }

    {
        static const char *names[4] = {
            "1foo", "*", "0", "\xE2\x98\xBA"
        };
        for (int i = 0; i < 4; i++) {
            char *error = S_try_new_symbol(names[i]);
            OK(test, error && strstr(error, "name"), "reject bad name");
            FREEMEM(error);
        }
    }

    {
        CFCSymbol *ooga  = CFCSymbol_new("parcel", "ooga");
        CFCSymbol *booga = CFCSymbol_new("parcel", "booga");
        int equal = CFCSymbol_equals(ooga, booga);
        OK(test, !equal, "different name spoils equals");
        CFCBase_decref((CFCBase*)ooga);
        CFCBase_decref((CFCBase*)booga);
    }

    {
        CFCParcel *eep_parcel = CFCParcel_new("Eep", NULL, NULL, NULL, NULL);
        CFCParcel_register(eep_parcel);
        CFCClass *ork
            = CFCClass_create(eep_parcel, NULL, "Op::Ork", NULL, NULL, NULL,
                              NULL, false, false, false);
        CFCSymbol *eep = CFCSymbol_new("parcel", "ah_ah");
        char *short_sym = CFCSymbol_short_sym(eep, ork);
        STR_EQ(test, short_sym, "Ork_ah_ah", "short_sym");
        FREEMEM(short_sym);
        char *full_sym = CFCSymbol_full_sym(eep, ork);
        STR_EQ(test, full_sym, "eep_Ork_ah_ah", "full_sym");
        FREEMEM(full_sym);
        CFCBase_decref((CFCBase*)eep_parcel);
        CFCBase_decref((CFCBase*)ork);
        CFCBase_decref((CFCBase*)eep);
    }

    CFCBase_decref((CFCBase*)parcel);
    CFCParcel_reap_singletons();
}

