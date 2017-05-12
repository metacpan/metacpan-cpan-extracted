[![Build Status](https://travis-ci.org/Songmu/App-LJ.svg?branch=master)](https://travis-ci.org/Songmu/App-LJ)
# NAME

lj - detect json from logfile and prettify it

# SYNOPSIS

    % echo '2015-01-31 [21:06:22] json: {"key": "value", "array": [1,2,3]}' | lj [--no-color]'
    2015-01-31 [21:06:22] json:
    {
       "array": [
          1,
          2,
          3
       ],
       "key": "value"
    }

# DESCRIPTION

[lj](https://metacpan.org/pod/lj) is command line utility for prettify the log containing JSON.

# INSTALLATION

    % cpanm App::LJ

or you can get single packed executable file.

    % curl -L https://raw.githubusercontent.com/Songmu/App-LJ/master/lj > /usr/local/bin/lj; chmod +x /usr/local/bin/lj

# LICENSE

Copyright (C) Songmu.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Songmu <y.songmu@gmail.com>
