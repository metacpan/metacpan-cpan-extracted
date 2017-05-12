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

#include <ctype.h>
#include <string.h>

#include "CFCJson.h"
#include "CFCUtil.h"

struct CFCJson {
    int type;
    char *string;
    int bool_val;
    struct CFCJson **kids;
    size_t num_kids;
};

static CFCJson*
S_parse_json_hash(const char **json);

static CFCJson*
S_parse_json_string(const char **json);

static CFCJson*
S_parse_json_null(const char **json);

static CFCJson*
S_parse_json_bool(const char **json);

static void
S_skip_whitespace(const char **json);

/*****************************************************************************
 * The hack JSON parser coded up below is only meant to parse Clownfish parcel
 * file content.  It is limited in its capabilities because so little is legal
 * in .cfp and .cfx files.
 */

CFCJson*
CFCJson_parse(const char *json) {
    if (!json) {
        return NULL;
    }
    S_skip_whitespace(&json);
    if (*json != '{') {
        return NULL;
    }
    CFCJson *parsed = S_parse_json_hash(&json);
    S_skip_whitespace(&json);
    if (*json != '\0') {
        CFCJson_destroy(parsed);
        parsed = NULL;
    }
    return parsed;
}

static void
S_append_kid(CFCJson *self, CFCJson *child) {
    size_t size = (self->num_kids + 2) * sizeof(CFCJson*);
    self->kids = (CFCJson**)REALLOCATE(self->kids, size);
    self->kids[self->num_kids++] = child;
    self->kids[self->num_kids]   = NULL;
}

static CFCJson*
S_parse_json_hash(const char **json) {
    const char *text = *json;
    S_skip_whitespace(&text);
    if (*text != '{') {
        return NULL;
    }
    text++;
    CFCJson *node = (CFCJson*)CALLOCATE(1, sizeof(CFCJson));
    node->type = CFCJSON_HASH;
    while (1) {
        // Parse key.
        S_skip_whitespace(&text);
        if (*text == '}') {
            text++;
            break;
        }
        else if (*text == '"') {
            CFCJson *key = S_parse_json_string(&text);
            S_skip_whitespace(&text);
            if (!key || *text != ':') {
                CFCJson_destroy(node);
                return NULL;
            }
            text++;
            S_append_kid(node, key);
        }
        else {
            CFCJson_destroy(node);
            return NULL;
        }

        // Parse value.
        S_skip_whitespace(&text);
        CFCJson *value = NULL;
        if (*text == '"') {
            value = S_parse_json_string(&text);
        }
        else if (*text == '{') {
            value = S_parse_json_hash(&text);
        }
        else if (*text == 'n') {
            value = S_parse_json_null(&text);
        }
        else if (*text == 't' || *text == 'f') {
            value = S_parse_json_bool(&text);
        }
        if (!value) {
            CFCJson_destroy(node);
            return NULL;
        }
        S_append_kid(node, value);

        // Parse comma.
        S_skip_whitespace(&text);
        if (*text == ',') {
            text++;
        }
        else if (*text == '}') {
            text++;
            break;
        }
        else {
            CFCJson_destroy(node);
            return NULL;
        }
    }

    // Move pointer.
    *json = text;

    return node;
}

// Parse a double quoted string.  Don't allow escapes.
static CFCJson*
S_parse_json_string(const char **json) {
    const char *text = *json;
    if (*text != '\"') {
        return NULL;
    }
    text++;
    const char *start = text;
    while (*text != '"') {
        if (*text == '\\' || *text == '\0') {
            return NULL;
        }
        text++;
    }
    CFCJson *node = (CFCJson*)CALLOCATE(1, sizeof(CFCJson));
    node->type = CFCJSON_STRING;
    node->string = CFCUtil_strndup(start, (size_t)(text - start));

    // Move pointer.
    text++;
    *json = text;

    return node;
}

// Parse a JSON null value.
static CFCJson*
S_parse_json_null(const char **json) {
    static const char null_str[] = "null";

    if (strncmp(*json, null_str, sizeof(null_str) - 1) != 0) {
        return NULL;
    }

    CFCJson *node = (CFCJson*)CALLOCATE(1, sizeof(CFCJson));
    node->type = CFCJSON_NULL;

    // Move pointer.
    *json += sizeof(null_str) - 1;

    return node;
}

// Parse a JSON Boolean.
static CFCJson*
S_parse_json_bool(const char **json) {
    static const char true_str[]  = "true";
    static const char false_str[] = "false";

    int val;

    if (strncmp(*json, true_str, sizeof(true_str) - 1) == 0) {
        val = 1;
        *json += sizeof(true_str) - 1;
    }
    else if (strncmp(*json, false_str, sizeof(false_str) - 1) == 0) {
        val = 0;
        *json += sizeof(false_str) - 1;
    }
    else {
        return NULL;
    }

    CFCJson *node = (CFCJson*)CALLOCATE(1, sizeof(CFCJson));
    node->type     = CFCJSON_BOOL;
    node->bool_val = val;

    return node;
}

static void
S_skip_whitespace(const char **json) {
    while (CFCUtil_isspace(json[0][0])) { *json = *json + 1; }
}

void
CFCJson_destroy(CFCJson *self) {
    if (!self) {
        return;
    }
    if (self->kids) {
        for (size_t i = 0; self->kids[i] != NULL; i++) {
            CFCJson_destroy(self->kids[i]);
        }
    }
    FREEMEM(self->string);
    FREEMEM(self->kids);
    FREEMEM(self);
}

int
CFCJson_get_type(CFCJson *self) {
    return self->type;
}

const char*
CFCJson_get_string(CFCJson *self) {
    if (self->type != CFCJSON_STRING) {
        CFCUtil_die("Not a JSON string");
    }
    return self->string;
}

int
CFCJson_get_bool(CFCJson *self) {
    if (self->type != CFCJSON_BOOL) {
        CFCUtil_die("Not a JSON Boolean");
    }
    return self->bool_val;
}

size_t
CFCJson_get_num_children(CFCJson *self) {
    if (self->type != CFCJSON_HASH) {
        CFCUtil_die("Not a JSON hash");
    }
    return self->num_kids;
}

CFCJson**
CFCJson_get_children(CFCJson *self) {
    if (self->type != CFCJSON_HASH) {
        CFCUtil_die("Not a JSON hash");
    }
    return self->kids;
}

CFCJson*
CFCJson_find_hash_elem(CFCJson *self, const char *key) {
    if (self->type != CFCJSON_HASH) {
        CFCUtil_die("Not a JSON hash");
    }

    for (int i = 0; self->kids[i]; i += 2) {
        if (strcmp(self->kids[i]->string, key) == 0) {
            return self->kids[i+1];
        }
    }

    return NULL;
}

