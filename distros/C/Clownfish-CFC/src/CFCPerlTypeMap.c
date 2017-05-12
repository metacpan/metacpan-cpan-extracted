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
#include <stdio.h>
#include "CFCPerlTypeMap.h"
#include "CFCUtil.h"
#include "CFCHierarchy.h"
#include "CFCClass.h"
#include "CFCType.h"

#ifndef true
    #define true 1
    #define false 0
#endif

// Convert from a Perl scalar to a primitive type.
struct char_map {
    char *key;
    char *value;
};


char*
CFCPerlTypeMap_from_perl(CFCType *type, const char *xs_var,
                         const char *label) {
    char *result = NULL;

    if (CFCType_is_object(type)) {
        const char *struct_sym   = CFCType_get_specifier(type);
        const char *class_var    = CFCType_get_class_var(type);
        const char *nullable_str = CFCType_nullable(type) ? "_nullable" : "";
        const char *allocation;
        if (strcmp(struct_sym, "cfish_String") == 0
            || strcmp(struct_sym, "cfish_Obj") == 0
           ) {
            // Share buffers rather than copy between Perl scalars and
            // Clownfish string types.
            allocation = "CFISH_ALLOCA_OBJ(CFISH_STRING)";
        }
        else {
            allocation = "NULL";
        }
        const char pattern[]
            = "(%s*)XSBind_arg_to_cfish%s(aTHX_ %s, \"%s\", %s, %s)";
        result = CFCUtil_sprintf(pattern, struct_sym, nullable_str, xs_var,
                                 label, class_var, allocation);
    }
    else if (CFCType_is_primitive(type)) {
        const char *specifier = CFCType_get_specifier(type);

        if (strcmp(specifier, "double") == 0) {
            result = CFCUtil_sprintf("SvNV(%s)", xs_var);
        }
        else if (strcmp(specifier, "float") == 0) {
            result = CFCUtil_sprintf("(float)SvNV(%s)", xs_var);
        }
        else if (strcmp(specifier, "int") == 0) {
            result = CFCUtil_sprintf("(int)SvIV(%s)", xs_var);
        }
        else if (strcmp(specifier, "short") == 0) {
            result = CFCUtil_sprintf("(short)SvIV(%s)", xs_var);
        }
        else if (strcmp(specifier, "long") == 0) {
            const char pattern[] =
                "((sizeof(long) <= sizeof(IV)) ? (long)SvIV(%s) "
                ": (long)SvNV(%s))";
            result = CFCUtil_sprintf(pattern, xs_var, xs_var);
        }
        else if (strcmp(specifier, "size_t") == 0) {
            result = CFCUtil_sprintf("(size_t)SvIV(%s)", xs_var);
        }
        else if (strcmp(specifier, "uint64_t") == 0) {
            result = CFCUtil_sprintf("(uint64_t)SvNV(%s)", xs_var);
        }
        else if (strcmp(specifier, "uint32_t") == 0) {
            result = CFCUtil_sprintf("(uint32_t)SvUV(%s)", xs_var);
        }
        else if (strcmp(specifier, "uint16_t") == 0) {
            result = CFCUtil_sprintf("(uint16_t)SvUV(%s)", xs_var);
        }
        else if (strcmp(specifier, "uint8_t") == 0) {
            result = CFCUtil_sprintf("(uint8_t)SvUV(%s)", xs_var);
        }
        else if (strcmp(specifier, "int64_t") == 0) {
            result = CFCUtil_sprintf("(int64_t)SvNV(%s)", xs_var);
        }
        else if (strcmp(specifier, "int32_t") == 0) {
            result = CFCUtil_sprintf("(int32_t)SvIV(%s)", xs_var);
        }
        else if (strcmp(specifier, "int16_t") == 0) {
            result = CFCUtil_sprintf("(int16_t)SvIV(%s)", xs_var);
        }
        else if (strcmp(specifier, "int8_t") == 0) {
            result = CFCUtil_sprintf("(int8_t)SvIV(%s)", xs_var);
        }
        else if (strcmp(specifier, "bool") == 0) {
            result = CFCUtil_sprintf("XSBind_sv_true(aTHX_ %s)", xs_var);
        }
        else {
            FREEMEM(result);
            result = NULL;
        }
    }

    return result;
}

char*
CFCPerlTypeMap_to_perl(CFCType *type, const char *cf_var) {
    char *result = NULL;

    if (CFCType_is_object(type)) {
        const char pattern[] = "XSBind_cfish_to_perl(aTHX_ (cfish_Obj*)%s)";
        result = CFCUtil_sprintf(pattern, cf_var);
    }
    else if (CFCType_is_primitive(type)) {
        // Convert from a primitive type to a Perl scalar.
        const char *specifier = CFCType_get_specifier(type);

        if (strcmp(specifier, "double") == 0) {
            result = CFCUtil_sprintf("newSVnv(%s)", cf_var);
        }
        else if (strcmp(specifier, "float") == 0) {
            result = CFCUtil_sprintf("newSVnv(%s)", cf_var);
        }
        else if (strcmp(specifier, "int") == 0) {
            result = CFCUtil_sprintf("newSViv(%s)", cf_var);
        }
        else if (strcmp(specifier, "short") == 0) {
            result = CFCUtil_sprintf("newSViv(%s)", cf_var);
        }
        else if (strcmp(specifier, "long") == 0) {
            char pattern[] =
                "((sizeof(long) <= sizeof(IV)) ? "
                "newSViv((IV)%s) : newSVnv((NV)%s))";
            result = CFCUtil_sprintf(pattern, cf_var, cf_var);
        }
        else if (strcmp(specifier, "size_t") == 0) {
            result = CFCUtil_sprintf("newSViv(%s)", cf_var);
        }
        else if (strcmp(specifier, "uint64_t") == 0) {
            char pattern[] =
                "sizeof(UV) == 8 ? "
                "newSVuv((UV)%s) : newSVnv((NV)CFISH_U64_TO_DOUBLE(%s))";
            result = CFCUtil_sprintf(pattern, cf_var, cf_var);
        }
        else if (strcmp(specifier, "uint32_t") == 0) {
            result = CFCUtil_sprintf("newSVuv(%s)", cf_var);
        }
        else if (strcmp(specifier, "uint16_t") == 0) {
            result = CFCUtil_sprintf("newSVuv(%s)", cf_var);
        }
        else if (strcmp(specifier, "uint8_t") == 0) {
            result = CFCUtil_sprintf("newSVuv(%s)", cf_var);
        }
        else if (strcmp(specifier, "int64_t") == 0) {
            char pattern[] = "sizeof(IV) == 8 ? newSViv((IV)%s) : newSVnv((NV)%s)";
            result = CFCUtil_sprintf(pattern, cf_var, cf_var);
        }
        else if (strcmp(specifier, "int32_t") == 0) {
            result = CFCUtil_sprintf("newSViv(%s)", cf_var);
        }
        else if (strcmp(specifier, "int16_t") == 0) {
            result = CFCUtil_sprintf("newSViv(%s)", cf_var);
        }
        else if (strcmp(specifier, "int8_t") == 0) {
            result = CFCUtil_sprintf("newSViv(%s)", cf_var);
        }
        else if (strcmp(specifier, "bool") == 0) {
            result = CFCUtil_sprintf("newSViv(%s)", cf_var);
        }
        else {
            FREEMEM(result);
            result = NULL;
        }
    }

    return result;
}

static const char typemap_start[] =
    "# Auto-generated file.\n"
    "\n"
    "TYPEMAP\n"
    "bool\tCFISH_BOOL\n"
    "int8_t\tCFISH_SIGNED_INT\n"
    "int16_t\tCFISH_SIGNED_INT\n"
    "int32_t\tCFISH_SIGNED_INT\n"
    "int64_t\tCFISH_BIG_SIGNED_INT\n"
    "uint8_t\tCFISH_UNSIGNED_INT\n"
    "uint16_t\tCFISH_UNSIGNED_INT\n"
    "uint32_t\tCFISH_UNSIGNED_INT\n"
    "uint64_t\tCFISH_BIG_UNSIGNED_INT\n"
    "\n";


static const char typemap_input[] =
    "INPUT\n"
    "\n"
    "CFISH_BOOL\n"
    "    $var = ($type)XSBind_sv_true(aTHX_ $arg);\n"
    "\n"
    "CFISH_SIGNED_INT \n"
    "    $var = ($type)SvIV($arg);\n"
    "\n"
    "CFISH_UNSIGNED_INT\n"
    "    $var = ($type)SvUV($arg);\n"
    "\n"
    "CFISH_BIG_SIGNED_INT \n"
    "    $var = (sizeof(IV) == 8) ? ($type)SvIV($arg) : ($type)SvNV($arg);\n"
    "\n"
    "CFISH_BIG_UNSIGNED_INT \n"
    "    $var = (sizeof(UV) == 8) ? ($type)SvUV($arg) : ($type)SvNV($arg);\n"
    "\n";

static const char typemap_output[] =
    "OUTPUT\n"
    "\n"
    "CFISH_BOOL\n"
    "    sv_setiv($arg, (IV)$var);\n"
    "\n"
    "CFISH_SIGNED_INT\n"
    "    sv_setiv($arg, (IV)$var);\n"
    "\n"
    "CFISH_UNSIGNED_INT\n"
    "    sv_setuv($arg, (UV)$var);\n"
    "\n"
    "CFISH_BIG_SIGNED_INT\n"
    "    if (sizeof(IV) == 8) { sv_setiv($arg, (IV)$var); }\n"
    "    else                 { sv_setnv($arg, (NV)$var); }\n"
    "\n"
    "CFISH_BIG_UNSIGNED_INT\n"
    "    if (sizeof(UV) == 8) { sv_setuv($arg, (UV)$var); }\n"
    "    else {\n"
    "        sv_setnv($arg, (NV)CFISH_U64_TO_DOUBLE($var));\n"
    "    }\n"
    "\n";

void
CFCPerlTypeMap_write_xs_typemap(CFCHierarchy *hierarchy) {
    CFCClass **classes = CFCHierarchy_ordered_classes(hierarchy);
    char *start  = CFCUtil_strdup("");
    char *input  = CFCUtil_strdup("");
    char *output = CFCUtil_strdup("");
    for (int i = 0; classes[i] != NULL; i++) {
        CFCClass *klass = classes[i];
        const char *full_struct_sym = CFCClass_full_struct_sym(klass);
        const char *class_var       = CFCClass_full_class_var(klass);

        start = CFCUtil_cat(start, full_struct_sym, "*\t", class_var, "_\n",
                            NULL);
        const char *allocation;
        if (strcmp(full_struct_sym, "cfish_String") == 0) {
            // Share buffers rather than copy between Perl scalars and
            // Clownfish string types.
            allocation = "CFISH_ALLOCA_OBJ(CFISH_STRING)";
        }
        else {
            allocation = "NULL";
        }
        input = CFCUtil_cat(input, class_var, "_\n"
                            "    $var = (", full_struct_sym,
                            "*)XSBind_perl_to_cfish_noinc(aTHX_ $arg, ",
                            class_var, ", ", allocation, ");\n\n", NULL);

        output = CFCUtil_cat(output, class_var, "_\n"
                             "    $arg = (SV*)CFISH_Obj_To_Host((cfish_Obj*)$var, NULL);\n"
                             "    CFISH_DECREF($var);\n"
                             "\n", NULL);
    }

    char *content = CFCUtil_strdup("");
    content = CFCUtil_cat(content, typemap_start, start, "\n\n",
                          typemap_input, input, "\n\n",
                          typemap_output, output, "\n\n", NULL);
    CFCUtil_write_if_changed("typemap", content, strlen(content));

    FREEMEM(content);
    FREEMEM(output);
    FREEMEM(input);
    FREEMEM(start);
    FREEMEM(classes);
}

