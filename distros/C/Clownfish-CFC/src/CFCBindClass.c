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

#define CFC_NEED_BASE_STRUCT_DEF

#include <stdio.h>
#include <string.h>
#include "CFCBindClass.h"
#include "CFCBindFunction.h"
#include "CFCBindMethod.h"
#include "CFCBase.h"
#include "CFCClass.h"
#include "CFCFunction.h"
#include "CFCMethod.h"
#include "CFCParamList.h"
#include "CFCParcel.h"
#include "CFCType.h"
#include "CFCVariable.h"
#include "CFCUtil.h"

struct CFCBindClass {
    CFCBase base;
    CFCClass *client;
    char *short_names_macro;
};

// Generate C header for an inert class.
static char*
S_to_c_header_inert(CFCBindClass *self);

// Generate C header for a dynamic class.
static char*
S_to_c_header_dynamic(CFCBindClass *self);

// Create the definition for the instantiable object struct.
static char*
S_struct_definition(CFCBindClass *self);

// Declare typedefs for fresh methods, to ease casting.
static char*
S_method_typedefs(CFCBindClass *self);

// If class inherits from something, include the parent class's header.
static char*
S_parent_include(CFCBindClass *self);

// Add a C function definition for each method and each function.
static char*
S_sub_declarations(CFCBindClass *self);

// Declare class (a.k.a. "inert") variables.
static char*
S_inert_var_declarations(CFCBindClass *self);

// Define type-safe wrappers for Obj functions.
static char*
S_wrapper_defs(CFCBindClass *self);

// Define method invocation inline functions.
static char*
S_method_defs(CFCBindClass *self);

// Declare override symbols for functions which wrap host callbacks.
static char*
S_override_decs(CFCBindClass *self);

// Define short names for all of the symbols associated with this class.
static char*
S_short_names(CFCBindClass *self);

static const CFCMeta CFCBINDCLASS_META = {
    "Clownfish::CFC::Binding::Core::Class",
    sizeof(CFCBindClass),
    (CFCBase_destroy_t)CFCBindClass_destroy
};

CFCBindClass*
CFCBindClass_new(CFCClass *client) {
    CFCBindClass *self = (CFCBindClass*)CFCBase_allocate(&CFCBINDCLASS_META);
    return CFCBindClass_init(self, client);
}

CFCBindClass*
CFCBindClass_init(CFCBindClass *self, CFCClass *client) {
    CFCUTIL_NULL_CHECK(client);
    self->client = (CFCClass*)CFCBase_incref((CFCBase*)client);

    const char *PREFIX = CFCClass_get_PREFIX(client);
    self->short_names_macro = CFCUtil_sprintf("%sUSE_SHORT_NAMES", PREFIX);

    return self;
}

void
CFCBindClass_destroy(CFCBindClass *self) {
    FREEMEM(self->short_names_macro);
    CFCBase_decref((CFCBase*)self->client);
    CFCBase_destroy((CFCBase*)self);
}

char*
CFCBindClass_to_c_header(CFCBindClass *self) {
    if (CFCClass_inert(self->client)) {
        // Inert classes only output inert functions and vars.
        return S_to_c_header_inert(self);
    }
    else {
        return S_to_c_header_dynamic(self);
    }
}

static char*
S_to_c_header_inert(CFCBindClass *self) {
    char *inert_func_decs = S_sub_declarations(self);
    char *inert_var_defs  = S_inert_var_declarations(self);
    char *short_names     = S_short_names(self);

    char pattern[] =
        "/* Declare this class's inert variables.\n"
        " */\n"
        "\n"
        "%s\n"
        "\n"
        "/* Declare this class's inert functions.\n"
        " */\n"
        "\n"
        "%s\n"
        "\n"
        "/* Define \"short names\" for this class's symbols.\n"
        " */\n"
        "\n"
        "%s\n"
        "\n";
    char *content = CFCUtil_sprintf(pattern, inert_var_defs, inert_func_decs,
                                    short_names);

    FREEMEM(inert_var_defs);
    FREEMEM(inert_func_decs);
    FREEMEM(short_names);
    return content;
}

static char*
S_ivars_func(CFCBindClass *self) {
    CFCClass *client = self->client;
    const char *full_type    = CFCClass_full_struct_sym(client);
    const char *full_func    = CFCClass_full_ivars_func(client);
    const char *short_func   = CFCClass_short_ivars_func(client);
    const char *full_struct  = CFCClass_full_ivars_struct(client);
    const char *short_struct = CFCClass_short_ivars_struct(client);
    const char *full_offset  = CFCClass_full_ivars_offset(client);
    const char *PREFIX       = CFCClass_get_PREFIX(client);
    char pattern[] =
        "extern uint32_t %s;\n"
        "typedef struct %s %s;\n"
        "static CFISH_INLINE %s*\n"
        "%s(%s *self) {\n"
        "   char *ptr = (char*)self + %s;\n"
        "   return (%s*)ptr;\n"
        "}\n"
        "#ifdef %sUSE_SHORT_NAMES\n"
        "  #define %s %s\n"
        "  #define %s %s\n"
        "#endif\n";
    char *content = CFCUtil_sprintf(pattern,
                                    full_offset,
                                    full_struct, full_struct,
                                    full_struct,
                                    full_func, full_type,
                                    full_offset,
                                    full_struct,
                                    PREFIX,
                                    short_struct, full_struct,
                                    short_func, full_func);
    return content;
}

static char*
S_to_c_header_dynamic(CFCBindClass *self) {
    const char *privacy_symbol  = CFCClass_privacy_symbol(self->client);
    char *ivars                 = S_ivars_func(self);
    char *struct_def            = S_struct_definition(self);
    char *parent_include        = S_parent_include(self);
    char *sub_declarations      = S_sub_declarations(self);
    char *inert_var_defs        = S_inert_var_declarations(self);
    char *method_typedefs       = S_method_typedefs(self);
    char *wrapper_defs          = S_wrapper_defs(self);
    char *method_defs           = S_method_defs(self);
    char *override_decs         = S_override_decs(self);
    char *short_names           = S_short_names(self);

    char pattern[] =
        "/* Include the header for this class's parent. \n"
        " */\n"
        "\n"
        "%s\n"
        "\n"
        "/* Define the struct layout for instances of this class.\n"
        " */\n"
        "\n"
        "#ifdef %s\n"
        "%s\n"
        "%s\n"
        "#endif /* %s */\n"
        "\n"
        "/* Declare this class's inert variables.\n"
        " */\n"
        "\n"
        "%s\n"
        "\n"
        "/* Declare both this class's inert functions and the C functions which\n"
        " * implement this class's dynamic methods.\n"
        " */\n"
        "\n"
        "%s\n"
        "\n"
        "/* Define typedefs for each dynamic method, allowing us to cast generic\n"
        " * pointers to the appropriate function pointer type more cleanly.\n"
        " */\n"
        "\n"
        "%s\n"
        "\n"
        "/* Define type-safe wrappers for inert functions of Obj.\n"
        " */\n"
        "\n"
        "%s\n"
        "\n"
        "/* Define the inline functions which implement this class's virtual methods.\n"
        " */\n"
        "\n"
        "%s\n"
        "\n"
        "/* Declare callbacks for wrapping host overrides.\n"
        " */\n"
        "\n"
        "%s\n"
        "\n"
        "/* Define \"short names\" for this class's symbols.\n"
        " */\n"
        "\n"
        "%s\n"
        "\n";
    char *content
        = CFCUtil_sprintf(pattern, parent_include, privacy_symbol, ivars,
                          struct_def, privacy_symbol, inert_var_defs,
                          sub_declarations, method_typedefs, wrapper_defs,
                          method_defs, override_decs, short_names);

    FREEMEM(ivars);
    FREEMEM(struct_def);
    FREEMEM(parent_include);
    FREEMEM(sub_declarations);
    FREEMEM(inert_var_defs);
    FREEMEM(method_typedefs);
    FREEMEM(wrapper_defs);
    FREEMEM(method_defs);
    FREEMEM(override_decs);
    FREEMEM(short_names);
    return content;
}

char*
CFCBindClass_to_c_data(CFCBindClass *self) {
    CFCClass *client = self->client;

    if (CFCClass_inert(client)) {
        return CFCUtil_strdup("");
    }

    const char *ivars_offset = CFCClass_full_ivars_offset(client);
    const char *class_var    = CFCClass_full_class_var(client);

    CFCMethod **methods  = CFCClass_methods(client);

    char *offsets           = CFCUtil_strdup("");
    char *method_defs       = CFCUtil_strdup("");

    for (int meth_num = 0; methods[meth_num] != NULL; meth_num++) {
        CFCMethod *method = methods[meth_num];

        // Define method offset variable.
        char *full_offset_sym = CFCMethod_full_offset_sym(method, client);
        offsets = CFCUtil_cat(offsets, "uint32_t ", full_offset_sym, ";\n",
                              NULL);
        FREEMEM(full_offset_sym);

        int is_fresh = CFCMethod_is_fresh(method, client);

        // Create a default implementation for abstract methods.
        if (is_fresh && CFCMethod_abstract(method)) {
            char *method_def = CFCBindMeth_abstract_method_def(method, client);
            method_defs = CFCUtil_cat(method_defs, method_def, "\n", NULL);
            FREEMEM(method_def);
        }
    }

    const char pattern[] =
        "/* Offset from the top of the object at which the IVARS struct\n"
        " * can be found.\n"
        " */\n"
        "\n"
        "uint32_t %s;\n"
        "\n"
        "/* Offsets for method pointers, measured in bytes, from the top\n"
        " * of this class's singleton object.\n"
        " */\n"
        "\n"
        "%s\n"
        "\n"
        "/* Define abstract methods of this class.\n"
        " */\n"
        "\n"
        "%s\n"
        "\n"
        "/* Define the pointer to the Class singleton object.\n"
        " */\n"
        "\n"
        "cfish_Class *%s;\n"
        "\n";
    char *code
        = CFCUtil_sprintf(pattern, ivars_offset, offsets, method_defs,
                          class_var);

    FREEMEM(offsets);
    FREEMEM(method_defs);
    return code;
}

// Create the definition for the instantiable object struct.
static char*
S_struct_definition(CFCBindClass *self) {
    CFCClass *const client = self->client;
    const char *struct_sym;
    char       *member_decs = CFCUtil_strdup("");

    CFCParcel *parcel = CFCClass_get_parcel(client);
    if (CFCParcel_is_cfish(parcel)) {
        struct_sym = CFCClass_full_struct_sym(client);
        member_decs = CFCUtil_cat(member_decs, "\n    CFISH_OBJ_HEAD", NULL);
    }
    else {
        struct_sym = CFCClass_full_ivars_struct(client);
    }

    // Add all member variables declared by classes in this package.
    CFCVariable **member_vars = CFCClass_member_vars(client);
    size_t num_non_package_members = CFCClass_num_non_package_ivars(client);
    for (size_t i = num_non_package_members; member_vars[i] != NULL; i++) {
        const char *member_dec = CFCVariable_local_declaration(member_vars[i]);
        member_decs = CFCUtil_cat(member_decs, "\n    ", member_dec, NULL);
    }

    char *struct_def;

    if (member_decs[0] == '\0') {
        // Don't define empty struct.
        struct_def = CFCUtil_strdup("");
    }
    else {
        char pattern[] = "struct %s {%s\n};\n";
        struct_def = CFCUtil_sprintf(pattern, struct_sym, member_decs);
    }

    FREEMEM(member_decs);
    return struct_def;
}

// Declare typedefs for every method, to ease casting.
static char*
S_method_typedefs(CFCBindClass *self) {
    CFCMethod** methods = CFCClass_methods(self->client);
    char *typedefs = CFCUtil_strdup("");
    for (int i = 0; methods[i] != NULL; i++) {
        CFCMethod *method = methods[i];
        char *typedef_str = CFCBindMeth_typedef_dec(method, self->client);
        typedefs = CFCUtil_cat(typedefs, typedef_str, "\n", NULL);
        FREEMEM(typedef_str);
    }
    return typedefs;
}

// If class inherits from something, include the parent class's header.
static char*
S_parent_include(CFCBindClass *self) {
    char *parent_include = CFCUtil_strdup("");
    CFCClass *parent = CFCClass_get_parent(self->client);
    if (parent) {
        parent_include = CFCUtil_cat(parent_include, "#include \"",
                                     CFCClass_include_h(parent), "\"", NULL);
    }
    return parent_include;
}

// Add a C function definition for each method and each function.
static char*
S_sub_declarations(CFCBindClass *self) {
    const char *PREFIX = CFCClass_get_PREFIX(self->client);
    CFCFunction **functions = CFCClass_functions(self->client);
    CFCMethod** fresh_methods = CFCClass_fresh_methods(self->client);
    char *declarations = CFCUtil_strdup("");
    for (int i = 0; functions[i] != NULL; i++) {
        CFCFunction *func = functions[i];
        char *dec = CFCBindFunc_func_declaration(func, self->client);
        if (!CFCFunction_inline(func)) {
            declarations = CFCUtil_cat(declarations, PREFIX, "VISIBLE ", NULL);
        }
        declarations = CFCUtil_cat(declarations, dec, "\n\n", NULL);
        FREEMEM(dec);
    }
    for (int i = 0; fresh_methods[i] != NULL; i++) {
        CFCMethod *method = fresh_methods[i];
        char *dec = CFCBindMeth_imp_declaration(method, self->client);
        declarations = CFCUtil_cat(declarations, dec, "\n\n", NULL);
        FREEMEM(dec);
    }
    return declarations;
}

// Declare class (a.k.a. "inert") variables.
static char*
S_inert_var_declarations(CFCBindClass *self) {
    const char *PREFIX = CFCClass_get_PREFIX(self->client);
    CFCVariable **inert_vars = CFCClass_inert_vars(self->client);
    char *declarations = CFCUtil_strdup("");
    for (int i = 0; inert_vars[i] != NULL; i++) {
        char *global_c = CFCVariable_global_c(inert_vars[i], self->client);
        declarations = CFCUtil_cat(declarations, "extern ", PREFIX, "VISIBLE ",
                                   global_c, ";\n", NULL);
        FREEMEM(global_c);
    }
    return declarations;
}

// Define type-safe wrappers for Obj functions.
static char*
S_wrapper_defs(CFCBindClass *self) {
    CFCClass *client = self->client;

    if (strcmp(CFCClass_get_name(client), "Clownfish::Obj") == 0) {
        return CFCUtil_strdup("");
    }

    const char *prefix     = CFCClass_get_prefix(client);
    const char *nickname   = CFCClass_get_nickname(client);
    const char *struct_sym = CFCClass_full_struct_sym(client);

    const char *pattern =
        "static CFISH_INLINE cfish_Class*\n"
        "%s%s_get_class(%s *self) {\n"
        "    return cfish_Obj_get_class((cfish_Obj*)self);\n"
        "}\n"
        "\n"
        "static CFISH_INLINE cfish_String*\n"
        "%s%s_get_class_name(%s *self) {\n"
        "    return cfish_Obj_get_class_name((cfish_Obj*)self);\n"
        "}\n"
        "\n"
        "static CFISH_INLINE bool\n"
        "%s%s_is_a(%s *self, cfish_Class *ancestor) {\n"
        "    return cfish_Obj_is_a((cfish_Obj*)self, ancestor);\n"
        "}\n";

    return CFCUtil_sprintf(pattern,
                           prefix, nickname, struct_sym,
                           prefix, nickname, struct_sym,
                           prefix, nickname, struct_sym);
}

// Define method invocation inline functions.
static char*
S_method_defs(CFCBindClass *self) {
    CFCMethod **methods = CFCClass_methods(self->client);
    char *method_defs = CFCUtil_strdup("");
    for (int i = 0; methods[i] != NULL; i++) {
        CFCMethod *method = methods[i];
        char *def = CFCBindMeth_method_def(method, self->client);
        method_defs = CFCUtil_cat(method_defs, def, "\n", NULL);
        FREEMEM(def);
    }
    return method_defs;
}

static char*
S_override_decs(CFCBindClass *self) {
    CFCMethod **fresh_methods = CFCClass_fresh_methods(self->client);
    char *decs  = CFCUtil_strdup("");
    char *nulls = CFCUtil_strdup("");

    for (int i = 0; fresh_methods[i] != NULL; i++) {
        CFCMethod *method = fresh_methods[i];
        if (CFCMethod_final(method) || !CFCMethod_novel(method)) {
            continue;
        }
        char *override_sym = CFCMethod_full_override_sym(method, self->client);
        CFCType      *return_type  = CFCMethod_get_return_type(method);
        CFCParamList *param_list   = CFCMethod_get_param_list(method);
        const char   *ret_type_str = CFCType_to_c(return_type);
        const char   *params       = CFCParamList_to_c(param_list);
        char pattern[] =
            "%s\n"
            "%s(%s);\n";
        char *callback_dec
            = CFCUtil_sprintf(pattern, ret_type_str, override_sym, params);
        decs = CFCUtil_cat(decs, callback_dec, NULL);
        FREEMEM(callback_dec);

        nulls = CFCUtil_cat(nulls, "#define ", override_sym, " NULL\n", NULL);
        FREEMEM(override_sym);
    }

    char pattern[] =
        "#ifdef CFISH_NO_DYNAMIC_OVERRIDES\n"
        "%s"
        "#else\n"
        "%s"
        "#endif\n"
        ;
    char *content = CFCUtil_sprintf(pattern, nulls, decs);

    FREEMEM(nulls);
    FREEMEM(decs);
    return content;
}

// Define short names for all of the symbols associated with this class.
static char*
S_short_names(CFCBindClass *self) {
    CFCClass *client = self->client;
    char *short_names = CFCUtil_strdup("");
    short_names = CFCUtil_cat(short_names, "#ifdef ", self->short_names_macro,
                              "\n", NULL);

    if (!CFCClass_inert(client)) {
        const char *short_struct    = CFCClass_get_struct_sym(client);
        const char *full_struct     = CFCClass_full_struct_sym(client);
        const char *short_class_var = CFCClass_short_class_var(client);
        const char *full_class_var  = CFCClass_full_class_var(client);
        short_names = CFCUtil_cat(short_names, "  #define ",
                                  short_struct, " ", full_struct, "\n",
                                  "  #define ", short_class_var, " ",
                                  full_class_var, "\n", NULL);
    }

    CFCFunction **functions = CFCClass_functions(client);
    for (int i = 0; functions[i] != NULL; i++) {
        CFCFunction *func = functions[i];
        char *short_sym = CFCFunction_short_func_sym(func, client);
        char *full_sym  = CFCFunction_full_func_sym(func, client);
        short_names = CFCUtil_cat(short_names, "  #define ", short_sym, " ",
                                  full_sym, "\n", NULL);
        FREEMEM(short_sym);
        FREEMEM(full_sym);
    }

    CFCVariable **inert_vars = CFCClass_inert_vars(client);
    for (int i = 0; inert_vars[i] != NULL; i++) {
        CFCVariable *var = inert_vars[i];
        char *short_sym = CFCVariable_short_sym(var, client);
        char *full_sym  = CFCVariable_full_sym(var, client);
        short_names = CFCUtil_cat(short_names, "  #define ", short_sym, " ",
                                  full_sym, "\n", NULL);
        FREEMEM(short_sym);
        FREEMEM(full_sym);
    }

    // Wrappers.
    if (!CFCClass_inert(client)
        && strcmp(CFCClass_get_name(client), "Clownfish::Obj") != 0
       ) {
        static const char *wrapped_funcs[] = {
            "get_class",
            "get_class_name",
            "is_a"
        };
        static int num_wrapped_funcs
            = sizeof(wrapped_funcs) / sizeof(wrapped_funcs[0]);
        const char *prefix   = CFCClass_get_prefix(client);
        const char *nickname = CFCClass_get_nickname(client);
        for (int i = 0; i < num_wrapped_funcs; i++) {
            const char *func = wrapped_funcs[i];
            short_names
                = CFCUtil_cat(short_names, "  #define ", nickname, "_", func,
                              " ", prefix, nickname, "_", func, "\n", NULL);
        }
    }

    if (!CFCClass_inert(client)) {
        CFCMethod **fresh_methods = CFCClass_fresh_methods(client);
        for (int i = 0; fresh_methods[i] != NULL; i++) {
            CFCMethod *meth = fresh_methods[i];

            // Implementing functions.
            char *short_imp = CFCMethod_short_imp_func(meth, client);
            char *full_imp  = CFCMethod_imp_func(meth, client);
            short_names = CFCUtil_cat(short_names, "  #define ", short_imp,
                                      " ", full_imp, "\n", NULL);
            FREEMEM(short_imp);
            FREEMEM(full_imp);
        }

        CFCMethod  **methods = CFCClass_methods(client);
        for (int i = 0; methods[i] != NULL; i++) {
            CFCMethod *meth = methods[i];
            static const char pattern[] = "  #define %s %s\n";

            // Method invocation symbols.
            char *short_sym  = CFCMethod_short_method_sym(meth, client);
            char *full_sym   = CFCMethod_full_method_sym(meth, client);
            char *define_sym = CFCUtil_sprintf(pattern, short_sym, full_sym);
            short_names = CFCUtil_cat(short_names, define_sym, NULL);
            FREEMEM(short_sym);
            FREEMEM(full_sym);
            FREEMEM(define_sym);

            // Method typedefs.
            char *short_typedef  = CFCMethod_short_typedef(meth, client);
            char *full_typedef   = CFCMethod_full_typedef(meth, client);
            char *define_typedef = CFCUtil_sprintf(pattern, short_typedef,
                                                   full_typedef);
            short_names = CFCUtil_cat(short_names, define_typedef, NULL);
            FREEMEM(short_typedef);
            FREEMEM(full_typedef);
            FREEMEM(define_typedef);
        }
    }
    short_names = CFCUtil_cat(short_names, "#endif /* ",
                              self->short_names_macro, " */\n", NULL);

    return short_names;
}

char*
CFCBindClass_host_data_json(CFCBindClass *self) {
    if (CFCClass_final(self->client)) { return CFCUtil_strdup(""); }

    CFCMethod **fresh_methods = CFCClass_fresh_methods(self->client);
    char *methods_json = CFCUtil_strdup("");

    for (int i = 0; fresh_methods[i] != NULL; i++) {
        CFCMethod *method = fresh_methods[i];
        char *method_json = CFCBindMeth_host_data_json(method);
        if (method_json[0] != '\0') {
            const char *sep = methods_json[0] == '\0' ? "" : ",\n";
            methods_json = CFCUtil_cat(methods_json, sep, method_json, NULL);
        }
        FREEMEM(method_json);
    }

    char *json;

    if (methods_json[0] == '\0') {
        json = CFCUtil_strdup("");
    }
    else {
        const char *class_name = CFCClass_get_name(self->client);

        const char *pattern =
            "        \"%s\": {\n"
            "            \"methods\": {\n"
            "%s\n"
            "            }\n"
            "        }";
        json = CFCUtil_sprintf(pattern, class_name, methods_json);
    }

    FREEMEM(methods_json);
    return json;
}

