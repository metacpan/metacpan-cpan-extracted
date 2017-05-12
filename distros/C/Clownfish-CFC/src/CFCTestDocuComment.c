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

#define CFC_USE_TEST_MACROS
#include "CFCBase.h"
#include "CFCDocuComment.h"
#include "CFCDocument.h"
#include "CFCCHtml.h"
#include "CFCCMan.h"
#include "CFCClass.h"
#include "CFCHierarchy.h"
#include "CFCParcel.h"
#include "CFCParser.h"
#include "CFCPerlClass.h"
#include "CFCPerlPod.h"
#include "CFCTest.h"
#include "CFCUtil.h"

#ifndef true
  #define true 1
  #define false 0
#endif

static void
S_run_tests(CFCTest *test);

const CFCTestBatch CFCTEST_BATCH_DOCU_COMMENT = {
    "Clownfish::CFC::Model::DocuComment",
    19,
    S_run_tests
};

static void
S_test_parser(CFCTest *test) {
    CFCDocuComment *docucomment;

    docucomment = CFCDocuComment_parse("/** foo. */");
    OK(test, docucomment != NULL, "parse");
    CFCBase_decref((CFCBase*)docucomment);

    CFCParser *parser = CFCParser_new();
    const char *text =
        "/**\n"
        " * Brief description.  Long description.\n"
        " *\n"
        " * More long description.\n"
        " *\n"
        " * @param foo A foo.\n"
        " * @param bar A bar.\n"
        " *\n"
        " * @param baz A baz.\n"
        " * @return a return value.\n"
        " */\n";
    CFCBase *result = CFCParser_parse(parser, text);
    OK(test, result != NULL, "parse with CFCParser");
    const char *klass = CFCBase_get_cfc_class(result);
    STR_EQ(test, klass, "Clownfish::CFC::Model::DocuComment", "result class");
    docucomment = (CFCDocuComment*)result;

    const char *brief_desc = CFCDocuComment_get_brief(docucomment);
    const char *brief_expect = "Brief description.";
    STR_EQ(test, brief_desc, brief_expect, "brief description");

    const char *long_desc = CFCDocuComment_get_long(docucomment);
    const char *long_expect =
        "Long description.\n"
        "\n"
        "More long description.";
    STR_EQ(test, long_desc, long_expect, "long description");

    const char *description = CFCDocuComment_get_description(docucomment);
    char *desc_expect = CFCUtil_sprintf("%s  %s", brief_expect, long_expect);
    STR_EQ(test, description, desc_expect, "description");
    FREEMEM(desc_expect);

    const char **param_names = CFCDocuComment_get_param_names(docucomment);
    int num_param_names = 0;
    for (const char **p = param_names; *p; ++p) { ++num_param_names; }
    INT_EQ(test, num_param_names, 3, "number of param names");
    const char *param_names_expect[3] = { "foo", "bar", "baz" };
    for (int i = 0; i < 3; ++i) {
        STR_EQ(test, param_names[i], param_names_expect[i],
               "param name %d", i);
    }

    const char **param_docs = CFCDocuComment_get_param_docs(docucomment);
    int num_param_docs = 0;
    for (const char **p = param_docs; *p; ++p) { ++num_param_docs; }
    INT_EQ(test, num_param_docs, 3, "number of param docs");
    const char *param_docs_expect[3] = { "A foo.", "A bar.", "A baz." };
    const char *param_docs_test[3] = {
        "@param terminated by @",
        "@param terminated by empty line",
        "@param terminated next element, @return"
    };
    for (int i = 0; i < 3; ++i) {
        STR_EQ(test, param_docs[i], param_docs_expect[i], param_docs_test[i]);
    }

    const char *retval = CFCDocuComment_get_retval(docucomment);
    const char *retval_expect = "a return value.";
    STR_EQ(test, retval, retval_expect, "retval");

    CFCBase_decref((CFCBase*)docucomment);
    CFCBase_decref((CFCBase*)parser);
}

static void
S_test_md_to_pod(CFCTest *test) {
    const char *md =
        "[Link\n"
        "with newline](http://example.com/)\n";
    char *pod = CFCPerlPod_md_to_pod(md, NULL, 1);
    const char *expect =
        "L<Link\n"
        "with newline|http://example.com/>\n\n";
    STR_EQ(test, pod, expect, "Markdown link with newline to POD");
    FREEMEM(pod);
}

static void
S_test_generator(CFCTest *test) {
    CFCHierarchy *hierarchy = CFCHierarchy_new("autogen");
    CFCParcel *parcel = CFCParcel_new("Neato", NULL, NULL, NULL, NULL);
    CFCParcel_register(parcel);

    CFCDocuComment *docu = CFCDocuComment_parse(
        "/** Test documentation generator.\n"
        " * \n"
        " * # Heading 1\n"
        " * \n"
        " * Paragraph: *emphasized*, **strong**, `code`.\n"
        " * \n"
        " * Paragraph: [link](http://example.com/), [](cfish:@null).\n"
        " * \n"
        " *     Code 1\n"
        " *     Code 2\n"
        " * \n"
        " * * List item 1\n"
        " *   * List item 1.1\n"
        " *     > Blockquote\n"
        " * \n"
        " *   Paragraph in list\n"
        " * \n"
        " * Paragraph after list\n"
        " */\n"
    );
    CFCClass *klass
        = CFCClass_create(parcel, "public", "Neato::Object", NULL, docu, NULL,
                          NULL, 0, 0, 0);

    char *man_page = CFCCMan_create_man_page(klass);
    const char *expected_man =
        ".TH Neato::Object 3\n"
        ".SH NAME\n"
        "Neato::Object \\- Test documentation generator.\n"
        ".SH DESCRIPTION\n"
        ".SS\n"
        "Heading 1\n"
        "Paragraph: \\fIemphasized\\f[], \\fBstrong\\f[], \\FCcode\\F[]\\&.\n"
        "\n"
        "Paragraph: \n"
        ".UR http://example.com/\n"
        "link\n"
        ".UE\n"
        ", NULL\\&.\n"
        ".IP\n"
        ".nf\n"
        ".fam C\n"
        "Code 1\n"
        "Code 2\n"
        ".fam\n"
        ".fi\n"
        ".IP \\(bu\n"
        "List item 1\n"
        ".RS\n"
        ".IP \\(bu\n"
        "List item 1.1\n"
        ".RS\n"
        ".IP\n"
        "Blockquote\n"
        ".RE\n"
        ".RE\n"
        ".IP\n"
        "Paragraph in list\n"
        ".P\n"
        "Paragraph after list\n";
    STR_EQ(test, man_page, expected_man, "create man page");

    CFCCHtml *chtml = CFCCHtml_new(hierarchy, "", "");
    char *html = CFCCHtml_create_html_body(chtml, klass);
    const char *expected_html =
        "<h1>Neato::Object</h1>\n"
        "<table>\n"
        "<tr>\n"
        "<td class=\"label\">parcel</td>\n"
        "<td><a href=\"../neato.html\">Neato</a></td>\n"
        "</tr>\n"
        "<tr>\n"
        "<td class=\"label\">class variable</td>\n"
        "<td><code><span class=\"prefix\">NEATO_</span>OBJECT</code></td>\n"
        "</tr>\n"
        "<tr>\n"
        "<td class=\"label\">struct symbol</td>\n"
        "<td><code><span class=\"prefix\">neato_</span>Object</code></td>\n"
        "</tr>\n"
        "<tr>\n"
        "<td class=\"label\">class nickname</td>\n"
        "<td><code><span class=\"prefix\">neato_</span>Object</code></td>\n"
        "</tr>\n"
        "<tr>\n"
        "<td class=\"label\">header file</td>\n"
        "<td><code>class.h</code></td>\n"
        "</tr>\n"
        "</table>\n"
        "<h2>Name</h2>\n"
        "<p>Neato::Object – Test documentation generator.</p>\n"
        "<h2>Description</h2>\n"
        "<h1>Heading 1</h1>\n"
        "<p>Paragraph: <em>emphasized</em>, <strong>strong</strong>, <code>code</code>.</p>\n"
        "<p>Paragraph: <a href=\"http://example.com/\">link</a>, NULL.</p>\n"
        "<pre><code>Code 1\n"
        "Code 2\n"
        "</code></pre>\n"
        "<ul>\n"
        "<li>\n"
        "<p>List item 1</p>\n"
        "<ul>\n"
        "<li>List item 1.1\n"
        "<blockquote>\n"
        "<p>Blockquote</p>\n"
        "</blockquote>\n"
        "</li>\n"
        "</ul>\n"
        "<p>Paragraph in list</p>\n"
        "</li>\n"
        "</ul>\n"
        "<p>Paragraph after list</p>\n";
    STR_EQ(test, html, expected_html, "create HTML");

    CFCPerlClass *perl_class = CFCPerlClass_new(NULL, "Neato::Object");
    CFCPerlPod *perl_pod = CFCPerlPod_new();
    CFCPerlClass_set_pod_spec(perl_class, perl_pod);
    char *pod = CFCPerlClass_create_pod(perl_class);
    const char *expected_pod =
        "=encoding utf8\n"
        "\n"
        "=head1 NAME\n"
        "\n"
        "Neato::Object - Test documentation generator.\n"
        "\n"
        "=head1 DESCRIPTION\n"
        "\n"
        "=head2 Heading 1\n"
        "\n"
        "Paragraph: I<emphasized>, B<strong>, C<code>.\n"
        "\n"
        "Paragraph: L<link|http://example.com/>, undef.\n"
        "\n"
        "    Code 1\n"
        "    Code 2\n"
        "\n"
        "=over\n"
        "\n"
        "=item *\n"
        "\n"
        "List item 1\n"
        "\n"
        "=over\n"
        "\n"
        "=item *\n"
        "\n"
        "List item 1.1\n"
        "\n"
        "=over\n"
        "\n"
        "Blockquote\n"
        "\n"
        "=back\n"
        "\n"
        "=back\n"
        "\n"
        "Paragraph in list\n"
        "\n"
        "=back\n"
        "\n"
        "Paragraph after list\n"
        "\n"
        "=cut\n"
        "\n";
    STR_EQ(test, pod, expected_pod, "create POD");

    FREEMEM(pod);
    CFCBase_decref((CFCBase*)perl_pod);
    CFCBase_decref((CFCBase*)perl_class);
    FREEMEM(html);
    CFCBase_decref((CFCBase*)chtml);
    FREEMEM(man_page);
    CFCBase_decref((CFCBase*)klass);
    CFCBase_decref((CFCBase*)docu);
    CFCBase_decref((CFCBase*)parcel);
    CFCBase_decref((CFCBase*)hierarchy);

    CFCDocument_clear_registry();
    CFCParcel_reap_singletons();
}

static void
S_run_tests(CFCTest *test) {
    S_test_parser(test);
    S_test_md_to_pod(test);
    S_test_generator(test);
}

