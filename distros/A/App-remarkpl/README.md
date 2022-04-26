# NAME

App::remarkpl - Web based presentation tool

# VERSION

0.06

# DESCRIPTION

[App::remarkpl](https://metacpan.org/pod/App%3A%3Aremarkpl) is is a [Mojolicious](https://metacpan.org/pod/Mojolicious) based webserver for showing
[remark](http://remarkjs.com) powered presentations locally.

Have a look at [https://github.com/gnab/remark/wiki](https://github.com/gnab/remark/wiki) for more information
about how to write slides.

# SYNOPSIS

    # Start a slideshow server
    $ remarkpl slides.markdown

    # Start the server on a different listen address
    $ remarkpl slides.markdown --listen http://*:5000

    # Show an example presentation
    $ remarkpl example.markdown
    $ remarkpl example.markdown --print

After starting the server, you can open your favorite (modern) browser
at [http://localhost:3000](http://localhost:3000).

# ENVIRONMENT VARIABLES

- REMARK\_JS

    Can be set to an external URL such as
    [https://remarkjs.com/downloads/remark-latest.min.js](https://remarkjs.com/downloads/remark-latest.min.js) to use a different
    version than the bundled remarkjs version.

- REMARK\_STATIC

    Path to static files to include. Default value is the current working
    directory.

- REMARK\_TEMPLATES

    Path to custom Mojolicious templates. Default to `./templates` in the current
    working directory.

# COPYRIGHT AND LICENSE

Copyright (C) Jan Henning Thorsen

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

# AUTHOR

Jan Henning Thorsen - `jhthorsen@cpan.org`
