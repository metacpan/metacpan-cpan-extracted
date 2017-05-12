[![Build Status](https://travis-ci.org/yusukebe/App-mookview.png?branch=master)](https://travis-ci.org/yusukebe/App-mookview)
# NAME

App::mookview - View Markdown texts as a "Mook-Book" style

# SYNOPSIS

    mookview text.md

Then open "http://localhost:5000/" with your web-browser.

You can use "plackup options" in command line.

    mookview --port 9000 text.md

# DESCRIPTION

App::mookview is Plack/PSGI application for viewing Markdown texts as a "Mook-book".

"mookview command" is useful when you are writing a book using Markdown format.

## Features

- 2 columns page layouts
- count characters
- support fenced code blocks in Markdown
- use the new font in OSX "mervericks"

# LICENSE

Copyright (C) Yusuke Wada.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Yusuke Wada <yusuke@kamawada.com>
