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

#define CFC_USE_TEST_MACROS
#include "CFCBase.h"
#include "CFCClass.h"
#include "CFCFile.h"
#include "CFCFileSpec.h"
#include "CFCParcel.h"
#include "CFCParser.h"
#include "CFCTest.h"
#include "CFCType.h"
#include "CFCUtil.h"
#include "CFCVariable.h"

static void
S_run_tests(CFCTest *test);

const CFCTestBatch CFCTEST_BATCH_FILE = {
    "Clownfish::CFC::Model::File",
    20,
    S_run_tests
};

static void
S_run_tests(CFCTest *test) {
#define STUFF_THING "Stuff" CHY_DIR_SEP "Thing"

    CFCParser *parser = CFCParser_new();
    CFCFileSpec *file_spec = CFCFileSpec_new(".", STUFF_THING, ".cfh", 0);

    {
        const char *string =
            "parcel Stuff;\n"
            "class Stuff::Thing {\n"
            "    Foo *foo;\n"
            "    Bar *bar;\n"
            "}\n"
            "class Foo {}\n"
            "class Bar {}\n"
            "__C__\n"
            "int foo;\n"
            "__END_C__\n";
        CFCFile *file = CFCParser_parse_file(parser, string, file_spec);

        STR_EQ(test, CFCFile_get_path(file),
               "." CHY_DIR_SEP STUFF_THING ".cfh", "get_path");
        STR_EQ(test, CFCFile_get_source_dir(file), ".", "get_source_dir");
        STR_EQ(test, CFCFile_get_path_part(file), STUFF_THING,
               "get_path_part");
        OK(test, !CFCFile_included(file), "included");

        STR_EQ(test, CFCFile_guard_name(file), "H_STUFF_THING", "guard_name");
        STR_EQ(test, CFCFile_guard_start(file),
               "#ifndef H_STUFF_THING\n#define H_STUFF_THING 1\n",
               "guard_start");
        STR_EQ(test, CFCFile_guard_close(file), "#endif /* H_STUFF_THING */\n",
               "guard_close");

        OK(test, !CFCFile_get_modified(file), "modified false at start");
        CFCFile_set_modified(file, 1);
        OK(test, CFCFile_get_modified(file), "set_modified, get_modified");

#define PATH_TO_STUFF_THING \
    "path" CHY_DIR_SEP \
    "to" CHY_DIR_SEP \
    "Stuff" CHY_DIR_SEP \
    "Thing"

        char *c_path = CFCFile_c_path(file, "path/to");
        STR_EQ(test, c_path, PATH_TO_STUFF_THING ".c", "c_path");
        FREEMEM(c_path);
        char *h_path = CFCFile_h_path(file, "path/to");
        STR_EQ(test, h_path, PATH_TO_STUFF_THING ".h", "h_path");
        FREEMEM(h_path);

        CFCClass **classes = CFCFile_classes(file);
        OK(test,
           classes[0] != NULL && classes[1] != NULL && classes[2] != NULL
           && classes[3] == NULL,
           "classes() filters blocks");
        CFCVariable **member_vars = CFCClass_fresh_member_vars(classes[0]);
        CFCType *foo_type = CFCVariable_get_type(member_vars[0]);
        CFCType_resolve(foo_type);
        STR_EQ(test, CFCType_get_specifier(foo_type), "stuff_Foo",
               "file production picked up parcel def");
        CFCType *bar_type = CFCVariable_get_type(member_vars[1]);
        CFCType_resolve(bar_type);
        STR_EQ(test, CFCType_get_specifier(bar_type), "stuff_Bar",
               "parcel def is sticky");

        CFCParcel *parcel = CFCFile_get_parcel(file);
        STR_EQ(test, CFCParcel_get_name(parcel), "Stuff", "get_parcel");

        CFCBase **blocks = CFCFile_blocks(file);
        STR_EQ(test, CFCBase_get_cfc_class(blocks[0]),
               "Clownfish::CFC::Model::Class", "blocks[0]");
        STR_EQ(test, CFCBase_get_cfc_class(blocks[1]),
               "Clownfish::CFC::Model::Class", "blocks[1]");
        STR_EQ(test, CFCBase_get_cfc_class(blocks[2]),
               "Clownfish::CFC::Model::Class", "blocks[2]");
        STR_EQ(test, CFCBase_get_cfc_class(blocks[3]),
               "Clownfish::CFC::Model::CBlock", "blocks[3]");
        OK(test, blocks[4] == NULL, "blocks[4]");

        CFCBase_decref((CFCBase*)file);

        CFCClass_clear_registry();
    }

    CFCBase_decref((CFCBase*)file_spec);
    CFCBase_decref((CFCBase*)parser);

    CFCParcel_reap_singletons();
}

