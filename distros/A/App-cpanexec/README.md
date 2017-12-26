# NAME

App::cpanexec - Execute application within local environment.

# SYNOPSIS

    cpane myscript arg1 arg2 ...

    cpane plackup hello.psgi

    cpane env

# DESCRIPTION

The program `cpane` executes command within the local environment.

Perl package managers like [Carton](https://metacpan.org/pod/Carton) or [cpm](https://metacpan.org/pod/cpm) install the dependencies into
`local` folder near the `cpanfile`.

The library [local::lib](https://metacpan.org/pod/local::lib) prepares appropriate environment for executing script
or executable program within such local environment. However it is necessary
to do some passes to configure such environment and configured environment
need to be deconfigured.

This program `cpane` requires command line passed as its arguments. The command
line may be script installed in local folder or generic executable may be with
arguments. It runs passed command line in the local environment configured for
the current dir and does not modify current environment. Folder `local` must
be exists in current dir.

The `cpane` may be used with Carton or cpm or without it. It works like
`exec` subcommand of ruby [bundler](http://bundler.io/man/bundle-exec.1.html)
or perl [Carton](https://metacpan.org/pod/Carton) or like `run` subcommand of node
[npm](https://docs.npmjs.com/cli/run-script). It configures runtime
environments accordings to the generaly accepted perl workflows provided by
[local::lib](https://metacpan.org/pod/local::lib).

# DEPENDENCIES

[local::lib](https://metacpan.org/pod/local::lib)

# SEE ALSO

[Carton](https://metacpan.org/pod/Carton)

[cpm](https://metacpan.org/pod/cpm)

[perlrocks](https://metacpan.org/pod/perlrocks)

[cpanfile](https://metacpan.org/pod/cpanfile)

[bundler](http://bundler.io/man/bundle-exec.1.html)

[npm](https://docs.npmjs.com/cli/run-script)

# LICENSE

MIT

# AUTHOR

Serguei Okladnikov <oklaspec@gmail.com>
