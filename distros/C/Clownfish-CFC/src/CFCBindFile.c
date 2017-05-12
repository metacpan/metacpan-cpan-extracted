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

#include <stdio.h>
#include <string.h>
#include "CFCBindFile.h"
#include "CFCBindClass.h"
#include "CFCBase.h"
#include "CFCFile.h"
#include "CFCClass.h"
#include "CFCCBlock.h"
#include "CFCParcel.h"
#include "CFCUtil.h"

void
CFCBindFile_write_h(CFCFile *file, const char *dest, const char *header,
                    const char *footer) {
    CFCUTIL_NULL_CHECK(file);
    CFCUTIL_NULL_CHECK(dest);
    CFCUTIL_NULL_CHECK(header);
    CFCUTIL_NULL_CHECK(footer);

    char *h_path = CFCFile_h_path(file, dest);

    // Create the include-guard strings.
    const char *include_guard_start = CFCFile_guard_start(file);
    const char *include_guard_close = CFCFile_guard_close(file);

    // Include parcel header.
    char *content = CFCUtil_strdup("");
    CFCParcel *parcel = CFCFile_get_parcel(file);
    const char *prefix = CFCParcel_get_prefix(parcel);
    content = CFCUtil_cat(content, "#include \"", prefix, "parcel.h\"\n\n",
                          NULL);

    // Aggregate block content.
    CFCBase **blocks = CFCFile_blocks(file);
    for (int i = 0; blocks[i] != NULL; i++) {
        const char *cfc_class = CFCBase_get_cfc_class(blocks[i]);

        if (strcmp(cfc_class, "Clownfish::CFC::Model::Class") == 0) {
            CFCBindClass *class_binding
                = CFCBindClass_new((CFCClass*)blocks[i]);
            char *c_header = CFCBindClass_to_c_header(class_binding);
            content = CFCUtil_cat(content, c_header, "\n", NULL);
            FREEMEM(c_header);
            CFCBase_decref((CFCBase*)class_binding);
        }
        else if (strcmp(cfc_class, "Clownfish::CFC::Model::CBlock") == 0) {
            const char *block_contents 
                = CFCCBlock_get_contents((CFCCBlock*)blocks[i]);
            content = CFCUtil_cat(content, block_contents, "\n", NULL);
        }
        else {
            CFCUtil_die("Unexpected class: %s", cfc_class);
        }
    }

    char pattern[] =
        "%s\n"
        "\n"
        "%s\n"
        "\n"
        "#ifdef __cplusplus\n"
        "extern \"C\" {\n"
        "#endif\n"
        "\n"
        "%s\n"
        "\n"
        "#ifdef __cplusplus\n"
        "}\n"
        "#endif\n"
        "\n"
        "%s\n"
        "\n"
        "%s\n"
        "\n";
    char *file_content
        = CFCUtil_sprintf(pattern, header, include_guard_start, content,
                          include_guard_close, footer);

    // Unlink then write file.
    remove(h_path);
    CFCUtil_write_file(h_path, file_content, strlen(file_content));

    FREEMEM(content);
    FREEMEM(file_content);
    FREEMEM(h_path);
}

