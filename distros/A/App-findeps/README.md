[![Build Status](https://travis-ci.com/worthmine/App-findeps.svg?branch=master)](https://travis-ci.com/worthmine/App-findeps) [![MetaCPAN Release](https://badge.fury.io/pl/App-findeps.svg)](https://metacpan.org/release/App-findeps)
# NAME

findeps - A simple command-line tool that makes ready to run Perl script on any environment

# SYNOPSIS

    $ findeps your_product.pl | cpanm
    $ findeps Plack.psgi | cpanm
    $ findeps index.cgi | cpanm
    $ findeps t/00_compile.t | cpanm
    
    #On directory of the modules you made
    $ findeps Your::Module | cpanm

Now you're ready to run the product you've made with many modules
without installing them every single time

# DESCRIPTION

`findeps` is a command line tool that resolves dependencies from too many Perl modules

[scandeps.pl](https://metacpan.org/pod/scandeps.pl) requires you to have [CPANPLUS](https://metacpan.org/pod/CPANPLUS) that was deprecated in v5.17.9 and removed from v5.19.0 on CORE

So I did _reinvent_ what requires just only [cpanm](https://metacpan.org/pod/cpanm).

- -u --upgradeAll OPTION

        $ findeps -u index.cgi | cpanm

    tries to upgrade modules you've already installed to the newest

- -L --myLib OPTION

        $ findeps -L=modules Plack.psgi | cpanm

    If you have a local directory named 'modules' not to be 'lib',
    you can choose it and the modules in there are ignored
    because you've already holden them.

# DANGEROUS OPTION

    $ findeps --makeCpanfile Some::Module >| cpanfile

It may be useful when you build a new module with [Minilla](https://metacpan.org/pod/Minilla)
but **NOT recommended** yet

# SEE ALSO

- [cpanm](https://metacpan.org/pod/cpanm)
- [scandeps.pl](https://metacpan.org/pod/scandeps.pl)

# LICENSE

Copyright (C) worthmine.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Yuki Yoshida([worthmine](https://github.com/worthmine))
