# Basic publishing targets

This example publishes only Markdown beneath `doc/` and uses the generated
MkDocs configuration. Generate its Makefile with `perl Makefile.PL`, then run
`make doc`, `make publish_build`, or `make publish_serve`. Importing the
publication adapter supplies both the documentation-maintenance and publication
targets.

MkDocs is selected because no `module` is configured. Set
`MARKDOWN_PUBLISH_MODULE` to try another installed engine without
regenerating the Makefile.
