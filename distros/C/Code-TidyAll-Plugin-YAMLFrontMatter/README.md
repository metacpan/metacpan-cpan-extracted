# NAME

Code::TidyAll::Plugin::YAMLFrontMatter - TidyAll plugin for validating YAML Front Matter

# VERSION

version 1.000002

# SYNOPSIS

In your .tidyallrc file:

    [YAMLFrontMatter]
    select = **/*.md
    required_top_level_keys = title layout

# DESCRIPTION

This is a validator plugin for [Code::TidyAll](https://metacpan.org/pod/Code::TidyAll) that can be used to check
that files have valid YAML Front Matter, like Jekyll et al use.

It will complain if:

- There's no YAML Front Matter
- The YAML Front Matter isn't valid YAML
- There's a UTF-8 BOM at the start of the file
- The file isn't encoded in the configured encoding (UTF-8 by default)
- The YAML Front Matter is missing one or more configured top level keys
- The YAML Front Matter contains circular references

## Options

- `required_top_level_keys`

    Keys that must be present at the top level of the YAML Front Matter.

- `encoding`

    The encoding the file is in.  Defaults to UTF-8 (just like Jekyll 2.0 and
    later.)

# SEE ALSO

[Jekyll's Front Matter Documentation](https://jekyllrb.com/docs/frontmatter/)

# SUPPORT

Please report all issues with this code using the GitHub issue tracker at
[https://github.com/maxmind/Code-TidyAll-Plugin-YAMLFrontMatter/issues](https://github.com/maxmind/Code-TidyAll-Plugin-YAMLFrontMatter/issues).

Bugs may be submitted through [https://github.com/maxmind/Code-Tidyall-Plugin-YAMLFrontMatter/issues](https://github.com/maxmind/Code-Tidyall-Plugin-YAMLFrontMatter/issues).

# AUTHOR

Mark Fowler <mfowler@maxmind.com>

# CONTRIBUTORS

- Dave Rolsky <autarch@urth.org>
- Greg Oschwald <goschwald@maxmind.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by MaxMind, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
