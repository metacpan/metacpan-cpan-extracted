# NAME

Dancer2::Template::Simple - Pure Perl 5 template engine for Dancer2

# VERSION

version 2.0.0

# SYNOPSIS

To use this engine, you may configure [Dancer2](https://metacpan.org/pod/Dancer2) via `config.yaml`:

    template: simple

# DESCRIPTION

This template engine is primarily to serve as a migration path for users of
[Dancer](https://metacpan.org/pod/Dancer). It should be fine for development purposes, but you would be
better served by using [Dancer2::Template::Tiny](https://metacpan.org/pod/Dancer2%3A%3ATemplate%3A%3ATiny),
[Dancer2::Template::TemplateToolkit](https://metacpan.org/pod/Dancer2%3A%3ATemplate%3A%3ATemplateToolkit) or one of the many alternatives
available on CPAN to power an application with Dancer2 in production environment.

`Dancer2::Template::Simple` is written in pure Perl and has no C bindings
to accelerate the template processing.

# METHODS

## render($template, \\%tokens)

Renders the template.  The first arg is a filename for the template file
or a reference to a string that contains the template.  The second arg
is a hashref for the tokens that you wish to pass to
[Template::Toolkit](https://metacpan.org/pod/Template%3A%3AToolkit) for rendering.

# SYNTAX

A template written for `Dancer2::Template::Simple` should work just fine
with [Dancer2::Template::TemplateToolkit](https://metacpan.org/pod/Dancer2%3A%3ATemplate%3A%3ATemplateToolkit). The opposite is not true though.

- **variables**

    To interpolate a variable in the template, use the following syntax:

        <% var1 %>

    If **var1** exists in the tokens hash given, its value will be written there.

# SEE ALSO

[Dancer2](https://metacpan.org/pod/Dancer2), [Dancer2::Core::Role::Template](https://metacpan.org/pod/Dancer2%3A%3ACore%3A%3ARole%3A%3ATemplate),
[Dancer2::Template::Tiny](https://metacpan.org/pod/Dancer2%3A%3ATemplate%3A%3ATiny), [Dancer2::Template::TemplateToolkit](https://metacpan.org/pod/Dancer2%3A%3ATemplate%3A%3ATemplateToolkit).

# AUTHOR

Dancer Core Developers

# COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Dancer Core Developers.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
