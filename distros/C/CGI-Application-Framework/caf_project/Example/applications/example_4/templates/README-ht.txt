Example 4 -- to show the use of the "included_template_registry", so
that you can create web applications, pages and sites where the
displayed pages are made up from "elements" (e.g. top header, bottom
footer, left-hand-side nav bar, widgets on the right hand side), each
with their own template file, which are brought into the display of the
template currently being shown by the run-mode through its
&lt;!-- TMPL_VAR NAME="cgiapp_embed('some_run_mode')" -- &gt; tags.

This special tag runs the run mode called "some_run_mode" and includes
its output within the page.