# NAME

Code::TidyAll::Plugin::TSLint - Use tslint with tidyall

# SYNOPSIS

    In configuration:

    [TSLint]
    select = static/**/*.js
    argv = -c $ROOT/.tslintrc --color

# DESCRIPTION

Runs tslint, a pluggable linting utility for TypeScript.

# INSTALLATION

Install [npm](https://npmjs.org/), then run

    npm install tslint

# CONFIGURATION

- argv

    Arguments to pass to tslint. Use `--color` to force color output.

- cmd

    Full path to tslint
