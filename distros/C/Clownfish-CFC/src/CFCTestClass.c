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
#include "CFCFileSpec.h"
#include "CFCFunction.h"
#include "CFCMethod.h"
#include "CFCParamList.h"
#include "CFCParcel.h"
#include "CFCParser.h"
#include "CFCSymbol.h"
#include "CFCTest.h"
#include "CFCType.h"
#include "CFCUtil.h"
#include "CFCVariable.h"

#ifndef true
  #define true 1
  #define false 0
#endif

static void
S_run_tests(CFCTest *test);

static int
S_has_symbol(CFCSymbol **symbols, const char *name);

const CFCTestBatch CFCTEST_BATCH_CLASS = {
    "Clownfish::CFC::Model::Class",
    97,
    S_run_tests
};

static char*
S_try_create(CFCParcel *parcel, const char *name, const char *nickname) {
    CFCClass *klass = NULL;
    char     *error;

    CFCUTIL_TRY {
        klass = CFCClass_create(parcel, NULL, name, nickname, NULL, NULL, NULL,
                                false, false, false);
    }
    CFCUTIL_CATCH(error);

    CFCBase_decref((CFCBase*)klass);
    return error;
}

static void
S_run_tests(CFCTest *test) {
    CFCParser *parser = CFCParser_new();

    CFCParcel *neato = CFCTest_parse_parcel(test, parser, "parcel Neato;");
    CFCFileSpec *file_spec = CFCFileSpec_new(".", "Foo/FooJr", ".cfh", 0);
    CFCClass *thing_class
        = CFCTest_parse_class(test, parser, "class Thing {}");
    CFCClass *widget_class
        = CFCTest_parse_class(test, parser, "class Widget {}");

    CFCVariable *thing;
    CFCVariable *widget;
    CFCFunction *tread_water;

    {
        CFCType *thing_type = CFCTest_parse_type(test, parser, "Thing*");
        thing = CFCVariable_new(NULL, "thing", thing_type, 0);

        CFCType *widget_type = CFCTest_parse_type(test, parser, "Widget*");
        widget = CFCVariable_new(NULL, "widget", widget_type, 0);

        CFCType *return_type = CFCTest_parse_type(test, parser, "void");
        CFCParamList *param_list
            = CFCTest_parse_param_list(test, parser, "()");
        tread_water = CFCFunction_new(NULL, "tread_water", return_type,
                                      param_list, NULL, 0);

        CFCBase_decref((CFCBase*)thing_type);
        CFCBase_decref((CFCBase*)widget_type);
        CFCBase_decref((CFCBase*)return_type);
        CFCBase_decref((CFCBase*)param_list);
    }

    CFCClass *foo
        = CFCClass_create(neato, NULL, "Foo", NULL, NULL, NULL, NULL, false,
                          false, false);
    CFCClass_add_function(foo, tread_water);
    CFCClass_add_member_var(foo, thing);
    CFCClass_add_inert_var(foo, widget);

    {
        CFCClass *should_be_foo = CFCClass_fetch_singleton("Foo");
        OK(test, should_be_foo == foo, "fetch_singleton");
    }

    {
        char *error = S_try_create(neato, "Foo", NULL);
        OK(test, error && strstr(error, "Two classes with name"),
           "Can't call create for the same class more than once");
        FREEMEM(error);
    }

    {
        char *error = S_try_create(neato, "Other::Foo", NULL);
        OK(test, error && strstr(error, "Class name conflict"),
           "Can't create classes wth the same final component");
        FREEMEM(error);
    }

    {
        char *error = S_try_create(neato, "Bar", "Foo");
        OK(test, error && strstr(error, "Class nickname conflict"),
           "Can't create classes wth the same nickname");
        FREEMEM(error);
    }

    CFCClass *foo_jr
        = CFCClass_create(neato, NULL, "Foo::FooJr", NULL, NULL, NULL, "Foo",
                          false, false, false);
    STR_EQ(test, CFCClass_get_struct_sym(foo_jr), "FooJr",
           "get_struct_sym");
    STR_EQ(test, CFCClass_full_struct_sym(foo_jr), "neato_FooJr",
           "full_struct_sym");
    STR_EQ(test, CFCClass_get_nickname(foo_jr), "FooJr",
           "derive class nickname from class name");

    CFCClass *final_foo
        = CFCClass_create(neato, NULL, "Foo::FooJr::FinalFoo", NULL, NULL,
                          file_spec, "Foo::FooJr", true, false, false);
    OK(test, CFCClass_final(final_foo), "final");
    STR_EQ(test, CFCClass_include_h(final_foo), "Foo/FooJr.h",
           "include_h uses path_part");
    STR_EQ(test, CFCClass_get_parent_class_name(final_foo), "Foo::FooJr",
           "get_parent_class_name");

    {
        CFCParcel *parsed_neato
            = CFCTest_parse_parcel(test, parser, "parcel Neato;");
        CFCBase_decref((CFCBase*)parsed_neato);
    }

    CFCParser_set_parcel(parser, neato);
    CFCParser_set_class_name(parser, "Foo");
    CFCMethod *do_stuff
        = CFCTest_parse_method(test, parser, "void Do_Stuff(Foo *self);");
    CFCClass_add_method(foo, do_stuff);

    CFCClass *inert_foo
        = CFCClass_create(neato, NULL, "InertFoo", NULL, NULL, NULL, NULL,
                          false, true, false);

    {
        CFCParser_set_class_name(parser, "InertFoo");
        CFCMethod *inert_do_stuff
            = CFCTest_parse_method(test, parser,
                                   "void Do_Stuff(InertFoo *self);");
        char *error;

        CFCUTIL_TRY {
            CFCClass_add_method(inert_foo, inert_do_stuff);
        }
        CFCUTIL_CATCH(error);
        OK(test, error && strstr(error, "inert class"),
           "Error out on conflict between inert attribute and object method");

        FREEMEM(error);
        CFCBase_decref((CFCBase*)inert_do_stuff);
    }

    {
        char *error;
        CFCUTIL_TRY {
            CFCClass_add_child(foo, inert_foo);
        }
        CFCUTIL_CATCH(error);
        OK(test, error && strstr(error, "Inert class"),
           "inert class can't inherit");
        FREEMEM(error);
    }

    {
        char *error;
        CFCUTIL_TRY {
            CFCClass_add_child(inert_foo, foo);
        }
        CFCUTIL_CATCH(error);
        OK(test, error && strstr(error, "from inert class"),
           "can't inherit from inert class");
        FREEMEM(error);
    }

    CFCClass_resolve_types(foo);
    CFCClass_resolve_types(foo_jr);
    CFCClass_resolve_types(final_foo);

    CFCClass_add_child(foo, foo_jr);
    CFCClass_add_child(foo_jr, final_foo);

    {
        CFCClass *bar
            = CFCClass_create(neato, NULL, "Foo::FooJr::FinalFoo::Bar", NULL,
                              NULL, NULL, "Foo::FooJr::FinalFoo", false, false,
                              false);
        char *error;

        CFCUTIL_TRY {
            CFCClass_add_child(final_foo, bar);
        }
        CFCUTIL_CATCH(error);
        OK(test, error && strstr(error, "final class"),
           "Can't add_child to final class");

        FREEMEM(error);
        CFCBase_decref((CFCBase*)bar);
    }

    CFCClass_grow_tree(foo);

    {
        char *error;
        CFCUTIL_TRY {
            CFCClass_grow_tree(foo);
        }
        CFCUTIL_CATCH(error);
        OK(test, error && strstr(error, "grow_tree"),
           "call grow_tree only once.");
        FREEMEM(error);
    }

    {
        char *error;
        CFCUTIL_TRY {
            CFCClass_add_method(foo_jr, do_stuff);
        }
        CFCUTIL_CATCH(error);
        OK(test, error && strstr(error, "grow_tree"),
           "Forbid add_method after grow_tree.");
        FREEMEM(error);
    }

    OK(test, CFCClass_get_parent(foo_jr) == foo, "grow_tree, one level" );
    OK(test, CFCClass_get_parent(final_foo) == foo_jr,
       "grow_tree, two levels");
    OK(test, CFCClass_fresh_method(foo, "Do_Stuff") == do_stuff,
       "fresh_method");
    OK(test, CFCClass_method(foo_jr, "Do_Stuff") == do_stuff,
       "inherited method");
    OK(test, CFCClass_fresh_method(foo_jr, "Do_Stuff") == NULL,
       "inherited method not 'fresh'");
    OK(test, CFCMethod_final(CFCClass_method(final_foo, "Do_Stuff")),
       "Finalize inherited method");
    OK(test, !CFCMethod_final(CFCClass_method(foo_jr, "Do_Stuff")),
       "Don't finalize method in parent");

    {
        CFCVariable **inert_vars = CFCClass_inert_vars(foo);
        OK(test, inert_vars[0] == widget, "inert_vars[0]");
        OK(test, inert_vars[1] == NULL, "inert_vars[1]");

        CFCFunction **functions = CFCClass_functions(foo);
        OK(test, functions[0] == tread_water, "functions[0]");
        OK(test, functions[1] == NULL, "functions[1]");

        CFCMethod **methods = CFCClass_methods(foo);
        OK(test, methods[0] == do_stuff, "methods[0]");
        OK(test, methods[1] == NULL, "methods[1]");

        CFCMethod **fresh_methods = CFCClass_fresh_methods(foo);
        OK(test, fresh_methods[0] == do_stuff, "fresh_methods[0]");
        OK(test, fresh_methods[1] == NULL, "fresh_methods[1]");

        CFCVariable **fresh_member_vars = CFCClass_fresh_member_vars(foo);
        OK(test, fresh_member_vars[0] == thing, "fresh_member_vars[0]");
        OK(test, fresh_member_vars[1] == NULL, "fresh_member_vars[1]");
    }

    {
        CFCVariable **member_vars = CFCClass_member_vars(foo_jr);
        OK(test, member_vars[0] == thing, "member_vars[0]");
        OK(test, member_vars[1] == NULL, "member_vars[1]");

        CFCFunction **functions = CFCClass_functions(foo_jr);
        OK(test, functions[0] == NULL, "functions[0]");

        CFCVariable **fresh_member_vars = CFCClass_fresh_member_vars(foo_jr);
        OK(test, fresh_member_vars[0] == NULL, "fresh_member_vars[0]");

        CFCVariable **inert_vars = CFCClass_inert_vars(foo_jr);
        OK(test, inert_vars[0] == NULL, "inert_vars[0]");
    }

    {
        CFCMethod **fresh_methods = CFCClass_fresh_methods(final_foo);
        OK(test, fresh_methods[0] == NULL, "fresh_methods[0]");
    }

    {
        CFCClass **ladder = CFCClass_tree_to_ladder(foo);
        OK(test, ladder[0] == foo, "ladder[0]");
        OK(test, ladder[1] == foo_jr, "ladder[1]");
        OK(test, ladder[2] == final_foo, "ladder[2]");
        OK(test, ladder[3] == NULL, "ladder[3]");
        FREEMEM(ladder);
    }

    {
        CFCClass *final_class
            = CFCTest_parse_class(test, parser, "final class Iamfinal { }");
        OK(test, CFCClass_final(final_class), "class modifer: final");
        CFCClass *inert_class
            = CFCTest_parse_class(test, parser, "inert class Iaminert { }");
        OK(test, CFCClass_inert(inert_class), "class modifer: inert");

        CFCBase_decref((CFCBase*)final_class);
        CFCBase_decref((CFCBase*)inert_class);
    }

    {
        static const char *names[2] = { "Fooble", "Foo::FooJr::FooIII" };
        for (int i = 0; i < 2; ++i) {
            const char *name = names[i];
            char *class_src
                = CFCUtil_sprintf("class Fu::%s inherits %s { }", name, name);
            CFCClass *klass = CFCTest_parse_class(test, parser, class_src);
            STR_EQ(test, CFCClass_get_parent_class_name(klass), name,
                   "class_inheritance: %s", name);
            FREEMEM(class_src);
            CFCBase_decref((CFCBase*)klass);
        }
    }

    {
        const char *class_src =
            "public class Foo::Foodie nickname Foodie inherits Foo {\n"
            "    int num;\n"
            "}\n";
        CFCClass *klass = CFCTest_parse_class(test, parser, class_src);
        CFCSymbol **member_vars
            = (CFCSymbol**)CFCClass_fresh_member_vars(klass);
        OK(test, S_has_symbol(member_vars, "num"),
           "parsed member var");

        CFCBase_decref((CFCBase*)klass);
    }

    {
        const char *class_src =
            "/**\n"
            " * Bow wow.\n"
            " *\n"
            " * Wow wow wow.\n"
            " */\n"
            "public class Animal::Dog inherits Animal {\n"
            "    public inert Dog* init(Dog *self, String *name,\n"
            "                           String *fave_food);\n"
            "    inert uint32_t count();\n"
            "    inert uint64_t num_dogs;\n"
            "    public inert Dog *top_dog;\n"
            "\n"
            "    String  *name;\n"
            "    bool     likes_to_go_fetch;\n"
            "    ChewToy *squishy;\n"
            "    Owner   *mom;\n"
            "\n"
            "    void               Destroy(Dog *self);\n"
            "    public String*     Bark(Dog *self);\n"
            "    public void        Eat(Dog *self);\n"
            "    public void        Bite(Dog *self, Enemy *enemy);\n"
            "    public Thing      *Fetch(Dog *self, Thing *thing);\n"
            "    public final void  Bury(Dog *self, Bone *bone);\n"
            "    public abstract incremented nullable Thing*\n"
            "    Scratch(Dog *self);\n"
            "\n"
            "    int32_t[1]  flexible_array_at_end_of_struct;\n"
            "}\n";
        CFCClass *klass = CFCTest_parse_class(test, parser, class_src);

        CFCSymbol **inert_vars  = (CFCSymbol**)CFCClass_inert_vars(klass);
        CFCSymbol **member_vars
            = (CFCSymbol**)CFCClass_fresh_member_vars(klass);
        CFCSymbol **functions   = (CFCSymbol**)CFCClass_functions(klass);
        CFCSymbol **methods     = (CFCSymbol**)CFCClass_fresh_methods(klass);
        OK(test, S_has_symbol(inert_vars, "num_dogs"), "parsed inert var");
        OK(test, S_has_symbol(inert_vars, "top_dog"), "parsed public inert var");
        OK(test, S_has_symbol(member_vars, "mom"), "parsed member var");
        OK(test, S_has_symbol(member_vars, "squishy"), "parsed member var");
        OK(test, S_has_symbol(functions, "init"), "parsed function");
        OK(test, S_has_symbol(methods, "Destroy"), "parsed parcel method");
        OK(test, S_has_symbol(methods, "Bury"), "parsed public method");
        OK(test, S_has_symbol(methods, "Scratch"),
           "parsed public abstract nullable method");

        CFCMethod *scratch = CFCClass_fresh_method(klass, "Scratch");
        OK(test, scratch != NULL, "find method 'Scratch'");
        OK(test, CFCType_nullable(CFCMethod_get_return_type(scratch)),
           "public abstract incremented nullable flagged as nullable");

        int num_public_methods = 0;
        for (int i = 0; methods[i]; ++i) {
            if (CFCSymbol_public(methods[i])) { ++num_public_methods; }
        }
        INT_EQ(test, num_public_methods, 6, "pass acl to Method constructor");

        CFCBase_decref((CFCBase*)klass);
    }

    {
        const char *class_src =
            "inert class Rigor::Mortis nickname Mort {\n"
            "    inert void lie_still();\n"
            "}\n";
        CFCClass *klass = CFCTest_parse_class(test, parser, class_src);
        OK(test, CFCClass_inert(klass),
           "inert modifier parsed and passed to constructor");

        CFCBase_decref((CFCBase*)klass);
    }

    {
        const char *class_src =
            "final class Ultimo {\n"
            "    /** Throws an error.\n"
            "     */\n"
            "    void Say_Never(Ultimo *self);\n"
            "}\n";
        CFCClass *klass = CFCTest_parse_class(test, parser, class_src);
        OK(test, CFCClass_final(klass), "final class_declaration");
        CFCBase_decref((CFCBase*)klass);
    }

    CFCBase_decref((CFCBase*)parser);
    CFCBase_decref((CFCBase*)neato);
    CFCBase_decref((CFCBase*)file_spec);
    CFCBase_decref((CFCBase*)thing_class);
    CFCBase_decref((CFCBase*)widget_class);
    CFCBase_decref((CFCBase*)thing);
    CFCBase_decref((CFCBase*)widget);
    CFCBase_decref((CFCBase*)tread_water);
    CFCBase_decref((CFCBase*)foo);
    CFCBase_decref((CFCBase*)foo_jr);
    CFCBase_decref((CFCBase*)final_foo);
    CFCBase_decref((CFCBase*)inert_foo);
    CFCBase_decref((CFCBase*)do_stuff);

    CFCClass_clear_registry();
    CFCParcel_reap_singletons();
}

static int
S_has_symbol(CFCSymbol **symbols, const char *name) {
    for (int i = 0; symbols[i]; ++i) {
        if (strcmp(CFCSymbol_get_name(symbols[i]), name) == 0) {
            return 1;
        }
    }

    return 0;
}

