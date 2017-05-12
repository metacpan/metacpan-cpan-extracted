# NAME

Dancer2::Template::Mason2 - Mason 2.x engine for Dancer2

# VERSION

version 0.01

# SYNOPSIS

In `config.yml`

    template: "mason2"

In `MyApp.pm`

    get '/foo' => sub {
        template foo => {
            title => 'bar',
        };
    };

In `views/foo.mc`

    <%args>
    $.title
    </%args>

    <h1><% $.title %></h1>
    <p>Hello World!</p>

# DESCRIPTION

Dancer2::Template::Mason2 is a template engine that allows you
to use [Mason 2.x](https://metacpan.org/pod/Mason) with [Dancer2](https://metacpan.org/pod/Dancer2).

In order to use this engine, set the template to 'mason2' in
the Dancer2 configuration file:

    template: "mason2"

The default template extension is '.mc'.

# CONFIGURATION

Paramters can also be passed to `Mason->new()` via the
configuration file like so:

    engines:
      mason2:
         data_dir: /path/to/data_dir

`comp_root` defaults to the `views` configuration setting or,
if it is undefined, to the `/views` subdirectory of the application.

`data_dir` defaults to `/data` subdirectory in the project root
directory.

# SEE ALSO

[Dancer2](https://metacpan.org/pod/Dancer2), [Mason](https://metacpan.org/pod/Mason)

# AUTHOR

David Betz <hashref@gmail.com>

# LICENSE

Copyright (C) David Betz.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
