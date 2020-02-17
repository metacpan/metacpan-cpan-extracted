# NAME

App::unbelievable - Dancer2 static site generator

# SYNOPSIS

In your Dancer2 app:

    use App::unbelievable;  # Pulls in Dancer2
    # your routes here
    unbelievable;           # At EOF, fills in the rest of the routes.

Then:

    $ unbelievable build    # Make the HTML
    $ unbelievable serve    # Run a local development server

App::unbelievable makes a Dancer2 application into a static site generator.
App::unbelievable adds routes for `/` and `/**` that will render Markdown
files in `content/`.  The [unbelievable](https://metacpan.org/pod/unbelievable) script generates static HTML
and other assets into `_built/`.

# FEATURES

## Markdown rendering

All non-hidden files in `content/` are rendered as Markdown files.
Hidden files are those that start with a `.` (the Unix convention).

## Fenced code blocks

Fenced code blocks are syntax-highlighted using
[Syntax::Highlight::Engine::Kate](https://metacpan.org/pod/Syntax::Highlight::Engine::Kate).  Language names are the lowercased
versions of the module suffixes in
[Syntax::Highlight::Engine::Kate::All](https://metacpan.org/source/MANWAR/Syntax-Highlight-Engine-Kate-0.14/lib/Syntax/Highlight/Engine/Kate/All.pm).

## Shortcodes

In Markdown inputs, shortcode tags of the form:

    {{< KEY [args] >}}

are replaced with the Dancer2 template `shortcodes/KEY`
(e.g., `views/shortcodes/foo.tt`).  Currently, only one argument is supported;
it is passed to the template as variable `_0`.

## Templates

Use whatever you want in your routes!  Use regular Dancer2 templating.

## Static files

Everything in `public/` is available under `/`, just as in Dancer2.

# WHY?

Yet another site generator --- can you believe it?  And now you know where
the package name comes from ;) .

This package's roadmap is feature parity with [Hugo](https://gohugo.io/).

My motivation for writing unbelievable was two-fold:

1. Perl.com is currently using Hugo, which is not written in Perl!
2. "every self-respecting programmer has written at least one static site
generator ... since writing a basic one is easy and often tends to be easier
than learning an existing one." --- SHLOMIF
([here](http://web-cpan.shlomifish.org/latemp/)).  :D

# FUNCTIONS

## import

Imports [Dancer2](https://metacpan.org/pod/Dancer2), among others, into the caller's namespace.

## unbelievable

Make default routes to render Markdown files in `content/` into HTML.
Usage: `unbelievable;`.  Returns a truthy value, so can be used as the
last line in a module.

# THANKS

- Thanks to [Getopt::Long::Subcommand](https://metacpan.org/pod/Getopt::Long::Subcommand) --- I used some code from its Synopsis.
- Thanks to [App::Wallflower](https://metacpan.org/pod/App::Wallflower), [Dancer2](https://metacpan.org/pod/Dancer2), and
[Syntax::Highlight::Engine::Kate](https://metacpan.org/pod/Syntax::Highlight::Engine::Kate) for doing the heavy lifting!

# LICENSE

Copyright (C) 2020 Chris White.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Chris White <cxwembedded@gmail.com>
