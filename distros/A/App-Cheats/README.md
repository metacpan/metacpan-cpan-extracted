# LOGO

    ~         __               __       ~
    ~   _____/ /_  ___  ____ _/ /______ ~
    ~  / ___/ __ \/ _ \/ __ `/ __/ ___/ ~
    ~ / /__/ / / /  __/ /_/ / /_(__  )  ~
    ~ \___/_/ /_/\___/\__,_/\__/____/   ~
    ~                                   ~

# NAME

App::Cheats - Cheatsheet

# Summary

Useful commands collected over the years

# Installation:

Install bash completion support.

    % apt install bash-completion

Install cpanm.

    % cpan App::cpanminus

Install module dependencies.

    % cpanm --installdeps .

Install tab completion.

    % source bashrc_pod

# Usage:

    # Show help.
    pod
    pod -h

# Examples:

View summary of Mojo::UserAgent:

    % pod Mojo::UserAgent

View summary of a specific method.

    % pod Mojo::UserAgent get

Edit the module

    % pod Mojo::UserAgent -e

Edit the module and jump to the specific method definition right away.
(Press "n" to next match if neeeded).

    % pod Mojo::UserAgent get -e

Run perldoc on the module (for convience)

    % pod Mojo::UserAgent -d

List all available methods.
If no methods are found normally, then this will automatically be enabled.
(pod was made to work with Mojo pod styling).

    % pod Mojo::UserAgent -a

# ENVIRONMENT

cheat expects to find a cheat\* file somewhere
in $CHEAT\_DIRS.

You can start with mine as an example:
   https://github.com/poti1/cheats/blob/main/cheats.txt

Save it and set this variable:
   export CHEAT\_DIRS="PATH\_TO\_CHEAT\_DIRS"

Optionally you can set this flag:
   --cheat\_dirs "PATH\_TO\_CHEAT\_DIRS"

If neither is provided, will search for a cheat
file in the same location as this script.

# LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by Tim Potapov.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)

# AUTHOR

Tim Potapov, `<Tim.Potapov[AT]gmail.com>`
