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

#include "charmony.h"

#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#define CFC_NEED_BASE_STRUCT_DEF
#include "CFCBase.h"
#include "CFCPython.h"
#include "CFCPyClass.h"
#include "CFCPyMethod.h"
#include "CFCParcel.h"
#include "CFCClass.h"
#include "CFCMethod.h"
#include "CFCHierarchy.h"
#include "CFCUtil.h"
#include "CFCBindCore.h"

struct CFCPython {
    CFCBase base;
    CFCHierarchy *hierarchy;
    char *header;
    char *footer;
};

static void
S_destroy(CFCPython *self);

static const CFCMeta CFCPYTHON_META = {
    "Clownfish::CFC::Binding::Python",
    sizeof(CFCPython),
    (CFCBase_destroy_t)S_destroy
};

CFCPython*
CFCPython_new(CFCHierarchy *hierarchy) {
    CFCUTIL_NULL_CHECK(hierarchy);
    CFCPython *self = (CFCPython*)CFCBase_allocate(&CFCPYTHON_META);
    self->hierarchy  = (CFCHierarchy*)CFCBase_incref((CFCBase*)hierarchy);
    self->header     = CFCUtil_strdup("");
    self->footer     = CFCUtil_strdup("");
    return self;
}

static void
S_destroy(CFCPython *self) {
    CFCBase_decref((CFCBase*)self->hierarchy);
    FREEMEM(self->header);
    FREEMEM(self->footer);
    CFCBase_destroy((CFCBase*)self);
}

void
CFCPython_set_header(CFCPython *self, const char *header) {
    CFCUTIL_NULL_CHECK(header);
    free(self->header);
    self->header = CFCUtil_make_c_comment(header);
}

void
CFCPython_set_footer(CFCPython *self, const char *footer) {
    CFCUTIL_NULL_CHECK(footer);
    free(self->footer);
    self->footer = CFCUtil_make_c_comment(footer);
}

static void
S_write_hostdefs(CFCPython *self) {
    const char pattern[] =
        "%s\n"
        "\n"
        "#ifndef H_CFISH_HOSTDEFS\n"
        "#define H_CFISH_HOSTDEFS 1\n"
        "\n"
        "#include \"Python.h\"\n"
        "\n"
        "#define CFISH_OBJ_HEAD \\\n"
        "    PyObject_HEAD\n"
        "\n"
        "#endif /* H_CFISH_HOSTDEFS */\n"
        "\n"
        "%s\n";
    char *content
        = CFCUtil_sprintf(pattern, self->header, self->footer);

    // Write if the content has changed.
    const char *inc_dest = CFCHierarchy_get_include_dest(self->hierarchy);
    char *filepath = CFCUtil_sprintf("%s" CHY_DIR_SEP "cfish_hostdefs.h",
                                     inc_dest);
    CFCUtil_write_if_changed(filepath, content, strlen(content));

    FREEMEM(filepath);
    FREEMEM(content);
}

static char*
S_gen_callbacks(CFCPython *self, CFCParcel *parcel, CFCClass **ordered) {
    CHY_UNUSED_VAR(self);
    CHY_UNUSED_VAR(parcel);
    char *callbacks  = CFCUtil_strdup("");

    // Generate implementation files containing callback definitions.
    for (size_t i = 0; ordered[i] != NULL; i++) {
        CFCClass *klass = ordered[i];
        if (CFCClass_included(klass)
            || CFCClass_inert(klass)
            //|| CFCClass_get_parcel(klass) != parcel
           ) {
            continue;
        }

        CFCMethod **fresh_methods = CFCClass_fresh_methods(klass);
        for (int meth_num = 0; fresh_methods[meth_num] != NULL; meth_num++) {
            CFCMethod *method = fresh_methods[meth_num];

            // Define callback.
            if (CFCMethod_novel(method) && !CFCMethod_final(method)) {
                char *cb_def = CFCPyMethod_callback_def(method, klass);
                callbacks = CFCUtil_cat(callbacks, cb_def, "\n", NULL);
                FREEMEM(cb_def);
            }
        }
    }

    static const char helpers[] =
        "static PyObject*\n"
        "S_pack_tuple(int num_args, ...) {\n"
        "    PyObject *tuple = PyTuple_New(num_args);\n"
        "    va_list args;\n"
        "    va_start(args, num_args);\n"
        "    for (int i = 0; i < num_args; i++) {\n"
        "        PyObject *arg = va_arg(args, PyObject*);\n"
        "        PyTuple_SET_ITEM(tuple, i, arg);\n"
        "    }\n"
        "    va_end(args);\n"
        "    return tuple;\n"
        "}\n"
        "#define CFBIND_TRY(routine) \\\n"
        "    do { \\\n"
        "        jmp_buf env; \\\n"
        "        jmp_buf *prev_env = CFBind_swap_env(&env); \\\n"
        "        if (!setjmp(env)) { \\\n"
        "            routine; \\\n"
        "        } \\\n"
        "        CFBind_swap_env(prev_env); \\\n"
        "    } while (0)\n"
        "\n"
        "static PyObject*\n"
        "S_call_pymeth(PyObject *self, const char *meth_name, PyObject *args,\n"
        "              const char *file, int line, const char *func) {\n"
        "    PyObject *callable = PyObject_GetAttrString(self, meth_name);\n"
        "    if (!PyCallable_Check(callable)) {\n"
        "        cfish_String *mess\n"
        "            = cfish_Err_make_mess(file, line, func, \"Attr '%s' not callable\",\n"
        "                                  meth_name);\n"
        "        cfish_Err_throw_mess(CFISH_ERR, mess);\n"
        "    }\n"
        "    PyObject *result = PyObject_CallObject(callable, args);\n"
        "    Py_DECREF(args);\n"
        "    if (result == NULL) {\n"
        "        cfish_String *mess\n"
        "            = cfish_Err_make_mess(file, line, func,\n"
        "                                  \"Callback to '%s' failed\", meth_name);\n"
        "        CFBind_reraise_pyerr(CFISH_ERR, mess);\n"
        "    }\n"
        "    return result;\n"
        "}\n"
        "\n"
        "#define CALL_PYMETH_VOID(self, meth_name, args) \\\n"
        "    S_call_pymeth_void(self, meth_name, args, \\\n"
        "        __FILE__, __LINE__, CFISH_ERR_FUNC_MACRO)\n"
        "\n"
        "static void\n"
        "S_call_pymeth_void(PyObject *self, const char *meth_name, PyObject *args,\n"
        "                   const char *file, int line, const char *func) {\n"
        "    PyObject *py_result\n"
        "        = S_call_pymeth(self, meth_name, args, file, line, func);\n"
        "    if (py_result == NULL) {\n"
        "        cfish_String *mess\n"
        "            = cfish_Err_make_mess(file, line, func, \"Call to %s failed\",\n"
        "                                  meth_name);\n"
        "        CFBind_reraise_pyerr(CFISH_ERR, mess);\n"
        "    }\n"
        "    Py_DECREF(py_result);\n"
        "}\n"
        "\n"
        "#define CALL_PYMETH_BOOL(self, meth_name, args) \\\n"
        "    S_call_pymeth_bool(self, meth_name, args, \\\n"
        "        __FILE__, __LINE__, CFISH_ERR_FUNC_MACRO)\n"
        "\n"
        "static bool\n"
        "S_call_pymeth_bool(PyObject *self, const char *meth_name, PyObject *args,\n"
        "                   const char *file, int line, const char *func) {\n"
        "    PyObject *py_result\n"
        "        = S_call_pymeth(self, meth_name, args, file, line, func);\n"
        "    int truthiness = py_result != NULL\n"
        "                     ? PyObject_IsTrue(py_result)\n"
        "                     : -1;\n"
        "    if (truthiness == -1) {\n"
        "        cfish_String *mess\n"
        "            = cfish_Err_make_mess(file, line, func, \"Call to %s failed\",\n"
        "                                  meth_name);\n"
        "        CFBind_reraise_pyerr(CFISH_ERR, mess);\n"
        "    }\n"
        "    Py_DECREF(py_result);\n"
        "    return !!truthiness;\n"
        "}\n"
        "\n"
        "#define CALL_PYMETH_OBJ(self, meth_name, args, ret_class, nullable) \\\n"
        "    S_call_pymeth_obj(self, meth_name, args, ret_class, nullable, \\\n"
        "        __FILE__, __LINE__, CFISH_ERR_FUNC_MACRO)\n"
        "\n"
        "static cfish_Obj*\n"
        "S_call_pymeth_obj(PyObject *self, const char *meth_name,\n"
        "                  PyObject *args, cfish_Class *ret_class, bool nullable,\n"
        "                  const char *file, int line, const char *func) {\n"
        "    PyObject *py_result\n"
        "        = S_call_pymeth(self, meth_name, args, file, line, func);\n"
        "    cfish_Obj *result = CFBind_py_to_cfish(py_result, ret_class);\n"
        "    Py_DECREF(py_result);\n"
        "    if (!nullable && result == NULL) {\n"
        "        CFISH_THROW(CFISH_ERR, \"%s cannot return NULL\", meth_name);\n"
        "    }\n"
        "    else if (!cfish_Obj_is_a(result, ret_class)) {\n"
        "        cfish_Class *result_class = cfish_Obj_get_class(result);\n"
        "        CFISH_DECREF(result);\n"
        "        CFISH_THROW(CFISH_ERR, \"%s returned %o instead of %o\", meth_name,\n"
        "                    CFISH_Class_Get_Name(result_class),\n"
        "                    CFISH_Class_Get_Name(ret_class));\n"
        "    }\n"
        "    return result;\n"
        "}\n"
        "\n"
        "#define CALL_PYMETH_DOUBLE(self, meth_name, args) \\\n"
        "    S_call_pymeth_f64(self, meth_name, args, \\\n"
        "        __FILE__, __LINE__, CFISH_ERR_FUNC_MACRO)\n"
        "#define CALL_PYMETH_FLOAT(self, meth_name, args) \\\n"
        "    ((float)S_call_pymeth_f64(self, meth_name, args, \\\n"
        "        __FILE__, __LINE__, CFISH_ERR_FUNC_MACRO))\n"
        "\n"
        "static double\n"
        "S_call_pymeth_f64(PyObject *self, const char *meth_name, PyObject *args,\n"
        "                  const char *file, int line, const char *func) {\n"
        "    PyObject *py_result\n"
        "        = S_call_pymeth(self, meth_name, args, file, line, func);\n"
        "    PyErr_Clear();\n"
        "    double result = PyFloat_AsDouble(py_result);\n"
        "    if (PyErr_Occurred()) {\n"
        "        cfish_String *mess\n"
        "            = cfish_Err_make_mess(file, line, func,\n"
        "                                  \"Converting result of '%s' to double failed\",\n"
        "                                  meth_name);\n"
        "        CFBind_reraise_pyerr(CFISH_ERR, mess);\n"
        "    }\n"
        "    Py_DECREF(py_result);\n"
        "    return result;\n"
        "}\n"
        "\n"
        "#define CALL_PYMETH_INT64_T(self, meth_name, args) \\\n"
        "    S_call_pymeth_i64(self, meth_name, args, INT64_MAX, INT64_MIN, \\\n"
        "        __FILE__, __LINE__, CFISH_ERR_FUNC_MACRO)\n"
        "#define CALL_PYMETH_INT32_T(self, meth_name, args) \\\n"
        "    ((int32_t)S_call_pymeth_i64(self, meth_name, args, INT32_MAX, INT32_MIN, \\\n"
        "        __FILE__, __LINE__, CFISH_ERR_FUNC_MACRO))\n"
        "#define CALL_PYMETH_INT16_T(self, meth_name, args) \\\n"
        "    ((int16_t)S_call_pymeth_i64(self, meth_name, args, INT16_MAX, INT16_MIN, \\\n"
        "        __FILE__, __LINE__, CFISH_ERR_FUNC_MACRO))\n"
        "#define CALL_PYMETH_INT8_T(self, meth_name, args) \\\n"
        "    ((int8_t)S_call_pymeth_i64(self, meth_name, args, INT8_MAX, INT8_MIN, \\\n"
        "        __FILE__, __LINE__, CFISH_ERR_FUNC_MACRO))\n"
        "#define CALL_PYMETH_CHAR(self, meth_name, args) \\\n"
        "    ((char)S_call_pymeth_i64(self, meth_name, args, CHAR_MAX, CHAR_MIN, \\\n"
        "        __FILE__, __LINE__, CFISH_ERR_FUNC_MACRO))\n"
        "#define CALL_PYMETH_SHORT(self, meth_name, args) \\\n"
        "    ((short)S_call_pymeth_i64(self, meth_name, args, SHRT_MAX, SHRT_MIN, \\\n"
        "        __FILE__, __LINE__, CFISH_ERR_FUNC_MACRO))\n"
        "#define CALL_PYMETH_INT(self, meth_name, args) \\\n"
        "    ((int16_t)S_call_pymeth_i64(self, meth_name, args, INT_MAX, INT_MIN, \\\n"
        "        __FILE__, __LINE__, CFISH_ERR_FUNC_MACRO))\n"
        "#define CALL_PYMETH_LONG(self, meth_name, args) \\\n"
        "    ((int16_t)S_call_pymeth_i64(self, meth_name, args, LONG_MAX, LONG_MIN, \\\n"
        "        __FILE__, __LINE__, CFISH_ERR_FUNC_MACRO))\n"
        "\n"
        "static int64_t\n"
        "S_call_pymeth_i64(PyObject *self, const char *meth_name, PyObject *args,\n"
        "                  int64_t max, int64_t min,\n"
        "                  const char *file, int line, const char *func) {\n"
        "    PyObject *py_result\n"
        "        = S_call_pymeth(self, meth_name, args, file, line, func);\n"
        "    PyErr_Clear();\n"
        "    int64_t result = PyLong_AsLongLong(py_result);\n"
        "    if (PyErr_Occurred() || result > max || result < min) {\n"
        "        cfish_String *mess\n"
        "            = cfish_Err_make_mess(file, line, func,\n"
        "                                  \"Converting result of '%s' to int64_t failed\",\n"
        "                                  meth_name);\n"
        "        CFBind_reraise_pyerr(CFISH_ERR, mess);\n"
        "    }\n"
        "    Py_DECREF(py_result);\n"
        "    return result;\n"
        "}\n"
        "\n"
        "#define CALL_PYMETH_UINT64_T(self, meth_name, args) \\\n"
        "    S_call_pymeth_u64(self, meth_name, args, UINT64_MAX, \\\n"
        "        __FILE__, __LINE__, CFISH_ERR_FUNC_MACRO)\n"
        "#define CALL_PYMETH_UINT32_T(self, meth_name, args) \\\n"
        "    ((uint32_t)S_call_pymeth_u64(self, meth_name, args, UINT32_MAX, \\\n"
        "        __FILE__, __LINE__, CFISH_ERR_FUNC_MACRO))\n"
        "#define CALL_PYMETH_UINT16_T(self, meth_name, args) \\\n"
        "    ((uint32_t)S_call_pymeth_u64(self, meth_name, args, UINT16_MAX, \\\n"
        "        __FILE__, __LINE__, CFISH_ERR_FUNC_MACRO))\n"
        "#define CALL_PYMETH_UINT8_T(self, meth_name, args) \\\n"
        "    ((uint32_t)S_call_pymeth_u64(self, meth_name, args, UINT8_MAX, \\\n"
        "        __FILE__, __LINE__, CFISH_ERR_FUNC_MACRO))\n"
        "#define CALL_PYMETH_SIZE_T(self, meth_name, args) \\\n"
        "    S_call_pymeth_u64(self, meth_name, args, SIZE_MAX, \\\n"
        "        __FILE__, __LINE__, CFISH_ERR_FUNC_MACRO)\n"
        "\n"
        "static uint64_t\n"
        "S_call_pymeth_u64(PyObject *self, const char *meth_name, PyObject *args,\n"
        "                  uint64_t max,\n"
        "                  const char *file, int line, const char *func) {\n"
        "    PyObject *py_result\n"
        "        = S_call_pymeth(self, meth_name, args, file, line, func);\n"
        "    PyErr_Clear();\n"
        "    uint64_t result = PyLong_AsUnsignedLongLong(py_result);\n"
        "    if (PyErr_Occurred()) {\n"
        "        cfish_String *mess\n"
        "            = cfish_Err_make_mess(file, line, func,\n"
        "                                  \"Converting result of '%s' to uint64_t failed\",\n"
        "                                  meth_name);\n"
        "        CFBind_reraise_pyerr(CFISH_ERR, mess);\n"
        "    }\n"
        "    Py_DECREF(py_result);\n"
        "    return result;\n"
        "}\n"
        ;

    static const char pattern[] =
        "%s\n"
        "\n"
        "%s"
        ;
    char *content = CFCUtil_sprintf(pattern, helpers, callbacks);

    FREEMEM(callbacks);
    return content;
}

static char*
S_gen_type_linkups(CFCPython *self, CFCParcel *parcel, CFCClass **ordered) {
    CHY_UNUSED_VAR(self);
    CHY_UNUSED_VAR(parcel);
    char *handles  = CFCUtil_strdup("");
    char *py_types = CFCUtil_strdup("");
    int num_items = 0;

    for (size_t i = 0; ordered[i] != NULL; i++) {
        CFCClass *klass = ordered[i];
        if (CFCClass_included(klass) || CFCClass_inert(klass)) {
            continue;
        }
        const char *class_var = CFCClass_full_class_var(klass);
        const char *struct_sym = CFCClass_get_struct_sym(klass);
        char *handles_temp
            = CFCUtil_sprintf("%s    handles[%d]  = &%s;\n",
                              handles, num_items, class_var);
        char *py_types_temp
            = CFCUtil_sprintf("%s    py_types[%d] = &%s_pytype_struct;\n",
                              py_types, num_items, struct_sym);
        FREEMEM(handles);
        FREEMEM(py_types);
        handles  = handles_temp;
        py_types = py_types_temp;
        num_items++;
    }

    char pattern[] =
        "static void\n"
        "S_link_py_types(void) {\n"
        "    const int num_items = %d;\n"
        "    size_t handles_size  = num_items * sizeof(cfish_Class**);\n"
        "    size_t py_types_size = num_items * sizeof(PyTypeObject*);\n"
        "    cfish_Class ***handles  = (cfish_Class***)CFISH_MALLOCATE(handles_size);\n"
        "    PyTypeObject **py_types = (PyTypeObject**)CFISH_MALLOCATE(py_types_size);\n"
        "%s\n"
        "%s\n"
        "    CFBind_assoc_py_types(handles, py_types, num_items);\n"
        "    CFISH_FREEMEM(handles);\n"
        "    CFISH_FREEMEM(py_types);\n"
        "}\n"
        ;
    char *content = CFCUtil_sprintf(pattern, num_items, handles, py_types);

    FREEMEM(handles);
    FREEMEM(py_types);
    return content;
}

static char*
S_gen_class_bindings(CFCPython *self, CFCParcel *parcel,
                     const char *pymod_name, CFCClass **ordered) {
    CHY_UNUSED_VAR(self);
    CHY_UNUSED_VAR(parcel);
    CHY_UNUSED_VAR(pymod_name);
    char *bindings = CFCUtil_strdup("");
    for (size_t i = 0; ordered[i] != NULL; i++) {
        CFCClass *klass = ordered[i];
        if (CFCClass_included(klass)) {
            continue;
        }
        const char *class_name = CFCClass_get_name(klass);
        CFCPyClass *class_binding = CFCPyClass_singleton(class_name);
        if (!class_binding) {
            // No binding spec'd out, so create one using defaults.
            class_binding = CFCPyClass_new(klass);
            CFCPyClass_add_to_registry(class_binding);
        }

        char *code = CFCPyClass_gen_binding_code(class_binding);
        bindings = CFCUtil_cat(bindings, code, NULL);
        FREEMEM(code);
    }
    return bindings;
}

static void
S_write_module_file(CFCPython *self, CFCParcel *parcel, const char *dest) {
    const char *parcel_name = CFCParcel_get_name(parcel);
    char *pymod_name = CFCUtil_strdup(parcel_name);
    // TODO: Stop lowercasing when parcels are restricted to lowercase.
    for (int i = 0; pymod_name[i] != '\0'; i++) {
        pymod_name[i] = CFCUtil_tolower(pymod_name[i]);
    }
    const char *last_dot = strrchr(pymod_name, '.');
    const char *last_component = last_dot != NULL
                                 ? last_dot + 1
                                 : pymod_name;
    char *helper_mod_name = CFCUtil_sprintf("%s._%s", pymod_name, last_component);
    for (int i = 0; helper_mod_name[i] != '\0'; i++) {
        helper_mod_name[i] = CFCUtil_tolower(helper_mod_name[i]);
    }

    CFCClass  **ordered = CFCHierarchy_ordered_classes(self->hierarchy);
    CFCParcel **parcels = CFCParcel_all_parcels();
    char *privacy_syms       = CFCUtil_strdup("");
    char *callbacks          = S_gen_callbacks(self, parcel, ordered);
    char *type_linkups       = S_gen_type_linkups(self, parcel, ordered);
    char *pound_includes     = CFCUtil_strdup("");
    char *class_bindings     = S_gen_class_bindings(self, parcel, pymod_name, ordered);
    char *parcel_boots       = CFCUtil_strdup("");
    char *pytype_ready_calls = CFCUtil_strdup("");
    char *module_adds        = CFCUtil_strdup("");

    // Add privacy defines and parcel bootstrapping calls.
    for (size_t i = 0; parcels[i]; ++i) {
        if (!CFCParcel_included(parcels[i])) {
            const char *privacy_sym = CFCParcel_get_privacy_sym(parcels[i]);
            privacy_syms = CFCUtil_cat(privacy_syms, "#define ", privacy_sym,
                                       "\n", NULL);
            const char *prefix = CFCParcel_get_prefix(parcels[i]);
            parcel_boots = CFCUtil_cat(parcel_boots, "    ", prefix,
                                       "bootstrap_parcel();\n", NULL);
        }
    }

    for (size_t i = 0; ordered[i] != NULL; i++) {
        CFCClass *klass = ordered[i];
        if (CFCClass_included(klass)) { continue; }
        const char *struct_sym = CFCClass_get_struct_sym(klass);

        const char *include_h  = CFCClass_include_h(klass);
        pound_includes = CFCUtil_cat(pound_includes, "#include \"",
                                     include_h, "\"\n", NULL);

        // The PyType_Ready invocations for instantiable classes are handled
        // via bootstrapping of Clownfish Class objects.  Since inert classes
        // do not at present have Class objects, we need to handle their
        // PyType_Ready calls independently.
        if (CFCClass_inert(klass)) {
            pytype_ready_calls = CFCUtil_cat(pytype_ready_calls,
                "    if (PyType_Ready(&", struct_sym,
                "_pytype_struct) < 0) { return NULL; }\n", NULL);
        }

        module_adds = CFCUtil_cat(module_adds, "    PyModule_AddObject(module, \"",
                                  struct_sym, "\", (PyObject*)&", struct_sym,
                                  "_pytype_struct);\n", NULL);
    }

    const char pattern[] =
        "%s\n"
        "\n"
        "%s"
        "\n"
        "#include \"Python.h\"\n"
        "#include \"cfish_parcel.h\"\n"
        "#include \"CFBind.h\"\n"
        "%s\n"
        "\n"
        "%s\n" // callbacks
        "\n"
        "static PyModuleDef module_def = {\n"
        "    PyModuleDef_HEAD_INIT,\n"
        "    \"%s\",\n" // module name
        "    NULL,\n" // docstring
        "    -1,\n"
        "    NULL, NULL, NULL, NULL, NULL\n"
        "};\n"
        "\n"
        "%s" // class bindings
        "\n"
        "%s" // S_link_py_types function
        "\n"
        "PyMODINIT_FUNC\n"
        "PyInit__%s(void) {\n"
        "    cfish_Class_bootstrap_hook1 = CFBind_class_bootstrap_hook1;\n"
        "\n"
        "%s\n" // PyType_Ready calls
        "\n"
        "    S_link_py_types();\n"
        "\n"
        "%s\n" // parcel boots
        "\n"
        "    PyObject *module = PyModule_Create(&module_def);\n"
        "%s\n" // Add types to module
        "\n"
        "    return module;\n"
        "}\n"
        "\n"
        "%s\n"
        "\n";

    char *content
        = CFCUtil_sprintf(pattern, self->header, privacy_syms, pound_includes,
                          callbacks, helper_mod_name, class_bindings,
                          type_linkups, last_component, pytype_ready_calls,
                          parcel_boots, module_adds, self->footer);

    char *filepath = CFCUtil_sprintf("%s" CHY_DIR_SEP "_%s.c", dest,
                                     last_component);
    CFCUtil_write_if_changed(filepath, content, strlen(content));
    FREEMEM(filepath);

    FREEMEM(content);
    FREEMEM(module_adds);
    FREEMEM(pytype_ready_calls);
    FREEMEM(parcel_boots);
    FREEMEM(class_bindings);
    FREEMEM(helper_mod_name);
    FREEMEM(pymod_name);
    FREEMEM(pound_includes);
    FREEMEM(type_linkups);
    FREEMEM(callbacks);
    FREEMEM(privacy_syms);
    FREEMEM(ordered);
}

void
CFCPython_write_bindings(CFCPython *self, const char *parcel_name, const char *dest) {
    CFCParcel *parcel = CFCParcel_fetch(parcel_name);
    if (parcel == NULL) {
        CFCUtil_die("Unknown parcel: %s", parcel_name);
    }
    S_write_hostdefs(self);
    S_write_module_file(self, parcel, dest);
}

