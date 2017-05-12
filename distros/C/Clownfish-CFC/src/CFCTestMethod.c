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
#include "CFCMethod.h"
#include "CFCParamList.h"
#include "CFCParcel.h"
#include "CFCParser.h"
#include "CFCSymbol.h"
#include "CFCTest.h"
#include "CFCType.h"
#include "CFCUtil.h"

static void
S_run_tests(CFCTest *test);

static void
S_run_basic_tests(CFCTest *test);

static void
S_run_parser_tests(CFCTest *test);

static void
S_run_overridden_tests(CFCTest *test);

static void
S_run_final_tests(CFCTest *test);

const CFCTestBatch CFCTEST_BATCH_METHOD = {
    "Clownfish::CFC::Model::Method",
    84,
    S_run_tests
};

static void
S_run_tests(CFCTest *test) {
    S_run_basic_tests(test);
    S_run_parser_tests(test);
    S_run_overridden_tests(test);
    S_run_final_tests(test);
}

static char*
S_try_new_method(const char *name, CFCType *return_type,
                 CFCParamList *param_list, const char *class_name) {
    CFCMethod *method = NULL;
    char      *error;

    CFCUTIL_TRY {
        method = CFCMethod_new(NULL, name, return_type, param_list, NULL,
                               class_name, 0, 0);
    }
    CFCUTIL_CATCH(error);

    CFCBase_decref((CFCBase*)method);
    return error;
}

static void
S_run_basic_tests(CFCTest *test) {
    CFCParser *parser = CFCParser_new();
    CFCParcel *neato_parcel
        = CFCTest_parse_parcel(test, parser, "parcel Neato;");

    CFCType *return_type = CFCTest_parse_type(test, parser, "Obj*");
    CFCParamList *param_list
        = CFCTest_parse_param_list(test, parser,
                                   "(Foo *self, int32_t count = 0)");
    CFCMethod *method
        = CFCMethod_new(NULL, "Return_An_Obj", return_type, param_list, NULL,
                        "Neato::Foo", 0, 0);
    OK(test, method != NULL, "new");
    OK(test, CFCSymbol_parcel((CFCSymbol*)method),
       "parcel exposure by default");

    {
        char *error = S_try_new_method("return_an_obj", return_type,
                                       param_list, "Neato::Foo");
        OK(test, error && strstr(error, "name"),
           "invalid name kills constructor");
        FREEMEM(error);
    }

    {
        static const char *bad_class_names[4] = {
            "foo", "1Foo", "Foo_Bar", "1FOOBAR"
        };
        for (int i = 0; i < 4; i++) {
            const char *bad_class_name = bad_class_names[i];
            char *error;

            error = S_try_new_method("Return_An_Obj", return_type,
                                     param_list, bad_class_name);
            OK(test, error && strstr(error, "class_name"),
               "Reject invalid class name %s", bad_class_name);
            FREEMEM(error);

            char *bogus_middle
                = CFCUtil_sprintf("Foo::%s::Bar", bad_class_name);
            error = S_try_new_method("Return_An_Obj", return_type,
                                     param_list, bogus_middle);
            OK(test, error && strstr(error, "class_name"),
               "Reject invalid class name %s", bogus_middle);
            FREEMEM(error);
            FREEMEM(bogus_middle);
        }
    }

    {
        CFCMethod *dupe
            = CFCMethod_new(NULL, "Return_An_Obj", return_type, param_list,
                            NULL, "Neato::Foo", 0, 0);
        OK(test, CFCMethod_compatible(method, dupe), "compatible");
        CFCBase_decref((CFCBase*)dupe);
    }

    {
        CFCMethod *name_differs
            = CFCMethod_new(NULL, "Eat", return_type, param_list, NULL,
                            "Neato::Foo", 0, 0);
        OK(test, !CFCMethod_compatible(method, name_differs),
           "different name spoils compatible");
        OK(test, !CFCMethod_compatible(name_differs, method),
           "... reversed");
        CFCBase_decref((CFCBase*)name_differs);
    }

    {
        static const char *param_strings[5] = {
            "(Foo *self, int32_t count = 0, int b)",
            "(Foo *self, int32_t count = 1)",
            "(Foo *self, int32_t count)",
            "(Foo *self, int32_t countess = 0)",
            "(Foo *self, uint32_t count = 0)"
        };
        static const char *test_names[5] = {
            "extra param",
            "different initial_value",
            "missing initial_value",
            "different param name",
            "different param type"
        };
        for (int i = 0; i < 5; ++i) {
            CFCParamList *other_param_list
                = CFCTest_parse_param_list(test, parser, param_strings[i]);
            CFCMethod *other
                = CFCMethod_new(NULL, "Return_An_Obj", return_type,
                                other_param_list, NULL, "Neato::Foo", 0, 0);
            OK(test, !CFCMethod_compatible(method, other),
               "%s spoils compatible", test_names[i]);
            OK(test, !CFCMethod_compatible(other, method),
               "... reversed");
            CFCBase_decref((CFCBase*)other_param_list);
            CFCBase_decref((CFCBase*)other);
        }
    }

    {
        CFCParamList *self_differs_list
            = CFCTest_parse_param_list(test, parser,
                                       "(Bar *self, int32_t count = 0)");
        CFCMethod *self_differs
            = CFCMethod_new(NULL, "Return_An_Obj", return_type,
                            self_differs_list, NULL, "Neato::Bar", 0, 0);
        OK(test, CFCMethod_compatible(method, self_differs),
           "different self type still compatible(),"
           " since can't test inheritance");
        OK(test, CFCMethod_compatible(self_differs, method),
           "... reversed");
        CFCBase_decref((CFCBase*)self_differs_list);
        CFCBase_decref((CFCBase*)self_differs);
    }

    {
        CFCMethod *aliased
            = CFCMethod_new(NULL, "Aliased", return_type, param_list, NULL,
                            "Neato::Foo", 0, 0);
        OK(test, !CFCMethod_get_host_alias(aliased),
           "no host alias by default");
        CFCMethod_set_host_alias(aliased, "Host_Alias");
        STR_EQ(test, CFCMethod_get_host_alias(aliased), "Host_Alias",
               "set/get host alias");
        CFCBase_decref((CFCBase*)aliased);
    }

    {
        CFCMethod *excluded
            = CFCMethod_new(NULL, "Excluded", return_type, param_list, NULL,
                            "Neato::Foo", 0, 0);
        OK(test, !CFCMethod_excluded_from_host(excluded),
           "not excluded by default");
        CFCMethod_exclude_from_host(excluded);
        OK(test, CFCMethod_excluded_from_host(excluded), "exclude from host");
        CFCBase_decref((CFCBase*)excluded);
    }

    CFCBase_decref((CFCBase*)parser);
    CFCBase_decref((CFCBase*)neato_parcel);
    CFCBase_decref((CFCBase*)return_type);
    CFCBase_decref((CFCBase*)param_list);
    CFCBase_decref((CFCBase*)method);

    CFCParcel_reap_singletons();
}

static void
S_run_parser_tests(CFCTest *test) {
    CFCParser *parser = CFCParser_new();
    CFCParcel *neato_parcel
        = CFCTest_parse_parcel(test, parser, "parcel Neato;");
    CFCParser_set_class_name(parser, "Neato::Obj");

    {
        static const char *method_strings[4] = {
            "public int Do_Foo(Obj *self);",
            "Obj* Gimme_An_Obj(Obj *self);",
            "void Do_Whatever(Obj *self, uint32_t a_num, float real);",
            "Foo* Fetch_Foo(Obj *self, int num);",
        };
        for (int i = 0; i < 4; ++i) {
            CFCMethod *method
                = CFCTest_parse_method(test, parser, method_strings[i]);
            CFCBase_decref((CFCBase*)method);
        }
    }

    {
        CFCMethod *method
            = CFCTest_parse_method(test, parser,
                                   "public final void The_End(Obj *self);");
        OK(test, CFCMethod_final(method), "final");
        CFCBase_decref((CFCBase*)method);
    }

    CFCBase_decref((CFCBase*)neato_parcel);
    CFCBase_decref((CFCBase*)parser);

    CFCParcel_reap_singletons();
}

static void
S_run_overridden_tests(CFCTest *test) {
    CFCParser *parser = CFCParser_new();
    CFCParcel *neato_parcel
        = CFCTest_parse_parcel(test, parser, "parcel Neato;");
    CFCType *return_type = CFCTest_parse_type(test, parser, "Obj*");

    CFCParamList *param_list
        = CFCTest_parse_param_list(test, parser, "(Foo *self)");
    CFCMethod *orig
        = CFCMethod_new(NULL, "Return_An_Obj", return_type, param_list, NULL,
                        "Neato::Foo", 0, 0);

    CFCParamList *overrider_param_list
        = CFCTest_parse_param_list(test, parser, "(FooJr *self)");
    CFCMethod *overrider
        = CFCMethod_new(NULL, "Return_An_Obj", return_type,
                        overrider_param_list, NULL, "Neato::Foo::FooJr", 0, 0);

    CFCMethod_override(overrider, orig);
    OK(test, !CFCMethod_novel(overrider),
       "A Method which overrides another is not 'novel'");

    CFCBase_decref((CFCBase*)parser);
    CFCBase_decref((CFCBase*)neato_parcel);
    CFCBase_decref((CFCBase*)return_type);
    CFCBase_decref((CFCBase*)param_list);
    CFCBase_decref((CFCBase*)orig);
    CFCBase_decref((CFCBase*)overrider_param_list);
    CFCBase_decref((CFCBase*)overrider);

    CFCParcel_reap_singletons();
}

static void
S_run_final_tests(CFCTest *test) {
    CFCParser *parser = CFCParser_new();
    CFCParcel *neato_parcel
        = CFCTest_parse_parcel(test, parser, "parcel Neato;");
    CFCClass *obj_class
        = CFCTest_parse_class(test, parser, "class Obj {}");
    CFCClass *foo_class
        = CFCTest_parse_class(test, parser, "class Neato::Foo {}");
    CFCType *return_type = CFCTest_parse_type(test, parser, "Obj*");
    CFCParamList *param_list
        = CFCTest_parse_param_list(test, parser, "(Foo *self)");

    CFCMethod *not_final
        = CFCMethod_new(NULL, "Return_An_Obj", return_type, param_list, NULL,
                        "Neato::Foo", 0, 0);
    CFCMethod_resolve_types(not_final);
    CFCMethod *final = CFCMethod_finalize(not_final);
    OK(test, CFCMethod_compatible(not_final, final),
       "finalize clones properly");
    OK(test, !CFCMethod_final(not_final), "not final by default");
    OK(test, CFCMethod_final(final), "finalize");

    {
        char *error;

        CFCUTIL_TRY {
            CFCMethod_override(not_final, final);
        }
        CFCUTIL_CATCH(error);
        OK(test, error && strstr(error, "final"),
           "Can't override final method");

        FREEMEM(error);
    }

    CFCBase_decref((CFCBase*)parser);
    CFCBase_decref((CFCBase*)neato_parcel);
    CFCBase_decref((CFCBase*)obj_class);
    CFCBase_decref((CFCBase*)foo_class);
    CFCBase_decref((CFCBase*)return_type);
    CFCBase_decref((CFCBase*)param_list);
    CFCBase_decref((CFCBase*)not_final);
    CFCBase_decref((CFCBase*)final);

    CFCClass_clear_registry();
    CFCParcel_reap_singletons();
}

