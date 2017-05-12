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

#include "CFCPyTypeMap.h"
#include "CFCType.h"
#include "CFCUtil.h"

char*
CFCPyTypeMap_c_to_py(CFCType *type, const char *cf_var) {
    char *result = NULL;

    if (CFCType_is_object(type)) {
        result = CFCUtil_sprintf("CFBind_cfish_to_py((cfish_Obj*)%s)", cf_var);
    }
    else if (CFCType_is_primitive(type)) {
        const char *specifier = CFCType_get_specifier(type);

        if (strcmp(specifier, "double") == 0
            || strcmp(specifier, "float") == 0
           ) {
            result = CFCUtil_sprintf("PyFloat_FromDouble(%s)", cf_var);
        }
        else if (strcmp(specifier, "int") == 0
                 || strcmp(specifier, "short") == 0
                 || strcmp(specifier, "long") == 0
                 || strcmp(specifier, "char") == 0 // OK if char is unsigned
                 || strcmp(specifier, "int8_t") == 0
                 || strcmp(specifier, "int16_t") == 0
                 || strcmp(specifier, "int32_t") == 0
                ) {
            result = CFCUtil_sprintf("PyLong_FromLong(%s)", cf_var);
        }
        else if (strcmp(specifier, "int64_t") == 0) {
            result = CFCUtil_sprintf("PyLong_FromLongLong(%s)", cf_var);
        }
        else if (strcmp(specifier, "uint8_t") == 0
                 || strcmp(specifier, "uint16_t") == 0
                 || strcmp(specifier, "uint32_t") == 0
                ) {
            result = CFCUtil_sprintf("PyLong_FromUnsignedLong(%s)", cf_var);
        }
        else if (strcmp(specifier, "uint64_t") == 0) {
            result = CFCUtil_sprintf("PyLong_FromUnsignedLongLong(%s)", cf_var);
        }
        else if (strcmp(specifier, "size_t") == 0) {
            result = CFCUtil_sprintf("PyLong_FromSize_t(%s)", cf_var);
        }
        else if (strcmp(specifier, "bool") == 0) {
            result = CFCUtil_sprintf("PyBool_FromLong(%s)", cf_var);
        }
    }

    return result;
}

