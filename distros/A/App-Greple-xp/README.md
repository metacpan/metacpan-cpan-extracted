[![Build Status](https://travis-ci.com/kaz-utashiro/greple-xp.svg?branch=master)](https://travis-ci.com/kaz-utashiro/greple-xp)
# NAME

App::Greple::xp - extended pattern module

# VERSION

Version 0.03

# SYNOPSIS

greple -Mxp

# DESCRIPTION

This module provides functions can be used by **greple** pattern and
region options.

# OPTIONS

- **--le-pattern** _file_
- **--inside-pattern** _file_
- **--outside-pattern** _file_
- **--include-pattern** _file_
- **--exclude-pattern** _file_

    Read file contents and use each lines as a pattern for options.

    Lines start with hash mark (`#`) is ignored as a comment line.

    String after double slash (`//`) is also ignored.

    Because file name is globbed, you can use wild card to give multiple
    files.

        $ greple -Mxp --exclude-pattern '*.exclude' ...

- **--le-string** _file_
- **--inside-string** _file_
- **--outside-string** _file_
- **--include-string** _file_
- **--exclude-string** _file_

    Almost same as **\*-pattern** option but each line is concidered as a
    fixed string rather than regular expression.

# SEE ALSO

[https://github.com/kaz-utashiro/greple](https://github.com/kaz-utashiro/greple)

[https://github.com/kaz-utashiro/greple-xp](https://github.com/kaz-utashiro/greple-xp)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright 2019- Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
