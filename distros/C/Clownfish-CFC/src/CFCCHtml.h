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

#ifndef H_CFCCHTML
#define H_CFCCHTML

#ifdef __cplusplus
extern "C" {
#endif

typedef struct CFCCHtml CFCCHtml;
struct CFCClass;
struct CFCHierarchy;
struct CFCParcel;

/** Clownfish::CFC::Binding::C::Html - Generate C API documentation in HTML
 * format.
 */

/** Constructor.
 *
 * @param header HTML header.
 * @param footer HTML footer.
 */
CFCCHtml*
CFCCHtml_new(struct CFCHierarchy *hierarchy, const char *header,
             const char *footer);

CFCCHtml*
CFCCHtml_init(CFCCHtml *self, struct CFCHierarchy *hierarchy,
              const char *header, const char *footer);

void
CFCCHtml_destroy(CFCCHtml *self);

/** Write the HTML documentation.
 */
void
CFCCHtml_write_html_docs(CFCCHtml *self);

/** Return the HTML documentation for the class.
 */
char*
CFCCHtml_create_html_doc(CFCCHtml *self, struct CFCClass *klass);

char*
CFCCHtml_create_html_body(CFCCHtml *self, struct CFCClass *klass);

#ifdef __cplusplus
}
#endif

#endif /* H_CFCCHTML */

