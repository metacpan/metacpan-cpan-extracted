[![Actions Status](https://github.com/kaz-utashiro/greple-frame/workflows/test/badge.svg)](https://github.com/kaz-utashiro/greple-frame/actions) [![MetaCPAN Release](https://badge.fury.io/pl/App-Greple-frame.svg)](https://metacpan.org/release/App-Greple-frame)
# NAME

App::Greple::frame - Greple frame output module

# SYNOPSIS

greple -Mframe --frame ...

# DESCRIPTION

Greple -Mframe module provide a capability to put surrounding frames
for each blocks.

`top`, `middle` and `bottom` frames are printed for blocks.

By default **--join-blocks** option is enabled to collect consecutive
lines into a single block.  If you don't like this, override it by
**--no-join-blocks** option.

# OPTIONS

- **--frame**

    Set frame options.

    Put next line in your `~/.greplerc` to autoload **App::Greple::frame** module.

        autoload -Mframe --frame

    Then you can use **--frame** option whenever you want.

<div>
    <p><img width="75%" src="https://github.com/kaz-utashiro/greple-frame/blob/main/images/terminal-small.png">
</div>

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright 2022 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
