# NAME

ASPEER::MakeMaker::Markdown::Publish::MM - generated publication target dispatcher

# DESCRIPTION

This class implements the MakeMaker-specific portion of
`ASPEER::MakeMaker::Markdown::Publish`. It inherits the common MakeMaker helper,
encodes `META_MERGE.x_documentation.publish` into a private Makefile macro, and
delegates generated targets to `Markdown::Publish`.

# METHODS

## const_config

Calls the shared `ASPEER::MakeMaker` `const_config` implementation, validates
the `x_documentation` metadata shape, and stores the JSON publication hash as a
Makefile-safe Base64 value.

## publish

Decodes the configuration passed by the generated target. When inline
configuration does not contain `name`, it uses the MakeMaker `NAME` as the
default site title. An external `config_file` remains authoritative. The method
then constructs `Markdown::Publish` and invokes the requested action on
the selected backend class.

# SEE ALSO

`ASPEER::MakeMaker::Markdown::Publish`, `Markdown::Publish`

# AUTHOR

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE AND COPYRIGHT

This software is copyright (c) 2026 by Andrew Speer. It may be distributed
under the same terms as Perl itself.
