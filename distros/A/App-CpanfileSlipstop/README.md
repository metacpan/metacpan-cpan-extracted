[![Build Status](https://travis-ci.org/pokutuna/p5-App-CpanfileSlipstop.svg?branch=master)](https://travis-ci.org/pokutuna/p5-App-CpanfileSlipstop) [![Coverage Status](https://img.shields.io/coveralls/pokutuna/p5-App-CpanfileSlipstop/master.svg?style=flat)](https://coveralls.io/r/pokutuna/p5-App-CpanfileSlipstop?branch=master) [![MetaCPAN Release](https://badge.fury.io/pl/App-CpanfileSlipstop.svg)](https://metacpan.org/release/App-CpanfileSlipstop)
# NAME

cpanfile-slipstop - write installed module versions back to cpanfile

# SYNOPSIS

    # update moduels & write versions from cpanfile.snapshot to cpanfile
    > carton update
    > cpanfile-slipstop

    # write module versions as 'minimum'
    > cpanfile-slipstop --stopper=minimum

    # only see versions to write
    > cpanfile-slipstop --dry-run

    # remove current version specification from cpanfile
    > cpanfile-slipstop --remove

# OPTIONS

    --stopper=identifier (default: exact)
        type of version constraint
            exact   : '== 1.00'
            minimum : '1.00' (same as >= 1.00)
            maximum : '<= 1.00'
    --dry-run
        do not save to cpanfile
    --with-core
        write core module versions
    --silent
        stop to output versions
    --cpanfile=path (default: ./cpanfile)
    --snapshot=path (default: ./cpanfile.snapshot)
        specify cpanfile and cpanfile.snapshot location
    --remove
        delete all version specifications from cpanfile
    -h, --help
        show this help

# DESCRIPTION

`cpanfile-slipstop` is a support tool for more definite and safety version bundling on [cpanfile](https://metacpan.org/pod/cpanfile) and [Carton](https://metacpan.org/pod/Carton).

The `carton install` command checks only to satisfy version specifications in cpanfile and `local/`. Even if some module versions are updated in cpanfile.snapshot, the saved versions are not referred until you need to install it. This sometimes causes confusion and version discrepancy between development environment and production. This tool writes versions snapshot to cpanfile to fix module versions.

# SEE ALSO

[Carton](https://metacpan.org/pod/Carton), [Module::CPANfile](https://metacpan.org/pod/Module::CPANfile), [CPAN::Meta::Requirements](https://metacpan.org/pod/CPAN::Meta::Requirements)

# LICENSE

Copyright (C) pokutuna.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

pokutuna <popopopopokutuna@gmail.com>
