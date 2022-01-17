[![Actions Status](https://github.com/delphinus/p5-App-efm_perl/workflows/test/badge.svg)](https://github.com/delphinus/p5-App-efm_perl/actions)
# NAME

efm-perl - perl -c executable with errorformat friendly outputs.

# SYNOPSIS

    # load the script from -f option
    efm-perl -f /path/to/script.pl

    # load the script from STDIN but filter out messages by filename from -f option
    cat /tmp/script.pl | efm-perl -f /path/to/script.pl

# OPTIONS

- **--lib**, **-I**

    Additional paths for `$PERL5LIB`

- **--filename**, **-f**

    Filename to lint. This is mandatory.

- **--verbose**, **-v**

    Print out all outputs. Without this, it shows errors only.

- **--help**, **-h**

    Print a help message.

- **--version**

    Show the version string.

# DESCRIPTION

This is a tiny script to use with
[mattn/efm-langserver](https://github.com/mattn/efm-langserver). It parses
`perl -c` outputs and arrange them to errorformat-friendly ones.

For efm-langserver, set config.yaml as below.

    tools:
      efm-perl: &efm-perl
        lint-command: efm-perl -f ${INPUT}
        lint-ignore-exit-code: true
        lint-stdin: true
        lint-formats:
          - '%l:%m'

    languages:
      perl:
        - <<: *efm-perl

efm-perl borrows many ideas from the original
[efm\_perl.pl](https://github.com/vim-perl/vim-perl/blob/dev/tools/efm_perl.pl).
This has improvements below after that.

- efm-perl can read STDIN.

    `efm_perl.pl` can only read the supplied filename. efm-perl can parse from
    STDIN to lint codes on your text editor without saving to disk.

- efm-perl can deal with plenv & direnv.

    It detects the filename and chdir to Git root automatically. Then it setups
    [plenv](https://github.com/tokuhirom/plenv) and
    [direnv](https://github.com/direnv/direnv), and lint with the desired Perl
    version and enviromental variables.

# USAGE

You can install `efm-perl` with `cpanm`.

    cpanm install App::efm_perl

Or you can use simply by copying the script.

    cp script/efm-perl /path/to/your/$PATH

# LICENSE

Copyright (C) delphinus.

This library is free software; you can redistribute it and/or modify it under
MIT License.

# AUTHOR

delphinus <me@delphinus.dev>
