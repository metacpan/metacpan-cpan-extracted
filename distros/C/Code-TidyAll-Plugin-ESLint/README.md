# NAME

Code::TidyAll::Plugin::ESLint - Use eslint with tidyall

# SYNOPSIS

    In configuration:

    [ESLint]
    select = static/**/*.js
    argv = -c $ROOT/.eslintrc --color

# DESCRIPTION

Runs [eslint](http://eslint.org//), pluggable linting utility for JavaScript
and JSX.

# INSTALLATION

Install [npm](https://npmjs.org/), then run

    npm install eslint

# CONFIGURATION

- argv

    Arguments to pass to eslint. Use `--color` to force color output.

- cmd

    Full path to eslint
