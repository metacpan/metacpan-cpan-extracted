# NAME

App::git::ship - Git command for shipping your project

# VERSION

0.34

# SYNOPSIS

See ["SYNOPSIS" in App::git::ship::perl](https://metacpan.org/pod/App::git::ship::perl#SYNOPSIS) for how to build Perl projects.

Below is a list of useful git aliases:

    # git build
    $ git config --global alias.build 'ship build'

    # git cl
    $ git config --global alias.cl 'ship clean'

    # git start
    # git start My/Project.pm
    $ git config --global alias.start 'ship start'

# DESCRIPTION

[App::git::ship](https://metacpan.org/pod/App::git::ship) is a [git](http://git-scm.com/) command for building and
shipping your project.

The main focus is to automate away the boring steps, but at the same time not
get in your (or any random contributor's) way. Problems should be solved with
sane defaults according to standard rules instead of enforcing more rules.

[App::git::ship](https://metacpan.org/pod/App::git::ship) differs from other tools like [dzil](https://metacpan.org/pod/Dist::Zilla) by _NOT_
requiring any configuration except for a file containing the credentials for
uploading to CPAN.

## Supported project types

Currently, only [App::git::ship::perl](https://metacpan.org/pod/App::git::ship::perl) is supported.

# ENVIRONMENT VARIABLES

Environment variables can also be set in a config file named `.ship.conf`, in
the root of the project directory. The format is:

    # some comment
    bugtracker = whatever
    new_version_format = %v %Y-%m-%dT%H:%M:%S%z

Any of the keys are the lower case version of ["ENVIRONMENT VARIABLES"](#environment-variables), but
without the "GIT\_SHIP\_" prefix.

Note however that all environment variables are optional, and in many cases
[App::git::ship](https://metacpan.org/pod/App::git::ship) will simply do the right thing, without any configuration.

## GIT\_SHIP\_AFTER\_SHIP

It is possible to add hooks. These hooks are
programs that runs in your shell. Example hooks:

    GIT_SHIP_AFTER_SHIP="bash script/new-release.sh"
    GIT_SHIP_AFTER_BUILD="rm -r lib/My/App/templates lib/My/App/public"
    GIT_SHIP_AFTER_SHIP="cat Changes | mail -s "Changes for My::App" all@my-app.com"

## GIT\_SHIP\_AFTER\_BUILD

See ["GIT\_SHIP\_AFTER\_SHIP"](#git_ship_after_ship).

## GIT\_SHIP\_BEFORE\_BUILD

See ["GIT\_SHIP\_AFTER\_SHIP"](#git_ship_after_ship).

## GIT\_SHIP\_BEFORE\_SHIP

See ["GIT\_SHIP\_AFTER\_SHIP"](#git_ship_after_ship).

## GIT\_SHIP\_BUGTRACKER

URL to the bugtracker for this project.

## GIT\_SHIP\_CLASS

This class is used to build the object that runs all the actions on your
project. This is autodetected by looking at the structure and files in
your project. For now this value can be [App::git::ship](https://metacpan.org/pod/App::git::ship) or
[App::git::ship::perl](https://metacpan.org/pod/App::git::ship::perl), but any customization is allowed.

## GIT\_SHIP\_CONTRIBUTORS

Comma-separated list with `name <email>` of the contributors to this project.

## GIT\_SHIP\_DEBUG

Setting this variable will make "git ship" output more information.

## GIT\_SHIP\_HOMEPAGE

URL to the home page for this project.

## GIT\_SHIP\_LICENSE

The name of the license to use. Defaults to "artistic\_2".

## GIT\_SHIP\_SILENT

Setting this variable will make "git ship" output less information.

# METHODS

These methods are interesting in case you want to extend [App::git::ship](https://metacpan.org/pod/App::git::ship) with
your own functionality. [App::git::ship::perl](https://metacpan.org/pod/App::git::ship::perl) does exactly this.

## abort

    $ship->abort($str);
    $ship->abort($format, @args);

Will abort the application run with an error message.

## build

    $ship->build;

This method builds the project. The default behavior is to ["abort"](#abort).
Needs to be overridden in the subclass.

## can\_handle\_project

    $bool = $class->can_handle_project($file);

This method is called by ["detect" in App::git::ship](https://metacpan.org/pod/App::git::ship#detect) and should return boolean
true if this module can handle the given git project.

This is a class method which gets a file as input to detect or have to
auto-detect from current working directory.

All the modules in the [App::git::ship](https://metacpan.org/pod/App::git::ship) namespace will be loaded and asked if
they can handle the given project you are in or trying to create.

## config

    $hash_ref = $ship->config;
    $str      = $ship->config($name);
    $self     = $ship->config($name => $value);

Holds the configuration from end user. The config is by default read from
`.ship.conf` in the root of your project if such a file exists.
["ENVIRONMENT VARIABLES"](#environment-variables) can also be used to build the config, but the
settings in `.ship.conf` has priority.

## detect

    $class = $ship->detect;
    $class = $ship->detect($file);

Will detect the sub class in the [App::git::ship::perl](https://metacpan.org/pod/App::git::ship::perl) namespace which can be
used to handle a project. Will first check ["GIT\_SHIP\_CLASS"](#git_ship_class) or call
["can\_handle\_project"](#can_handle_project) on all the classes in the [App::git::ship::perl](https://metacpan.org/pod/App::git::ship::perl)
namespace if not.

## dump

    $str = $ship->dump($any);

Will serialize `$any` into a perl data structure, using [Data::Dumper](https://metacpan.org/pod/Data::Dumper).

## new

    $ship = App::git::ship->new(\%attributes);

Creates a new instance of `$class`.

## render\_template

    $ship->render_template($file, \%args);

Used to render a template by the name `$file` to a `$file`. The template
needs to be defined in the `DATA` section of the current class or one of
the super classes.

## run\_hook

    $ship->run_hook($name);

Used to run a hook before or after an event. The hook is a command which needs
to be defined in ["config"](#config). See also ["GIT\_SHIP\_AFTER\_BUILD"](#git_ship_after_build),
["GIT\_SHIP\_AFTER\_SHIP"](#git_ship_after_ship), ["GIT\_SHIP\_BEFORE\_BUILD"](#git_ship_before_build) and
["GIT\_SHIP\_BEFORE\_SHIP"](#git_ship_before_ship).

## ship

    $ship->ship;

This method ships the project to some online repository. The default behavior
is to make a new tag and push it to "origin". Push occurs only if origin is
defined in git.

## start

    $ship->start;

This method is called when initializing the project. The default behavior is
to populate ["config"](#config) with default data:

## system

    $ship->system($program, @args);

Same as perl's `system()`, but provides error handling and logging.

# SEE ALSO

- [Dist::Zilla](https://metacpan.org/pod/Dist::Zilla)

    This project can probably get you to the moon.

- [Minilla](https://metacpan.org/pod/Minilla)

    This looks really nice for shipping your project. It has the same idea as
    this distribution: Guess as much as possible.

- [Shipit](https://metacpan.org/pod/Shipit)

    One magical tool for doing it all in one bang.

# COPYRIGHT AND LICENSE

Copyright (C) 2014-2018, Jan Henning Thorsen

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

# AUTHOR

Jan Henning Thorsen - `jhthorsen@cpan.org`

mohawk2 - `mohawk2@users.noreply.github.com`

Rolf Stöckli - `tekki@cpan.org`

Shoichi Kaji - `skaji@cpan.org`
