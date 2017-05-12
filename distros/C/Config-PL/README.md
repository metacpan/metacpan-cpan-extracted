# NAME

Config::PL - Using '.pl' file as a configuration

# SYNOPSIS

    use Config::PL;
    my $config = config_do 'config.pl';
    my %config = config_do 'config.pl';

# DESCRIPTION

Config::PL is a utility module for using '.pl' file as a configuration.

This module provides `config_do` function for loading '.pl' file.

Using '.pl' file which returns HashRef as a configuration is good idea.
We can write flexible and DRY configuration by it.
(But, sometimes it becomes too complicated :P)

`do "$file"` idiom is often used for loading configuration.

But, there is some problems and [Config::PL](http://search.cpan.org/perldoc?Config::PL) cares these problems.

## Ensure returns HashRef

`do EXPR` function of Perl core is not sane because it does not die
when the file contains parse error or is not found.

`config_do` function croaks errors and ensures that the returned value is HashRef.

## Expected file loading

`do "$file"` searches files in `@INC`. It sometimes causes intended file loading.

`config_do` function limits the search path only in `cwd` and `basename(__FILE__)`.

You can easily load another configuration file in the config files as follows.

    # config.pl
    use Config:PL;
    config_do "$ENV{PLACK_ENV}.pl";

You need not write `do File::Spec->catfile(File::Basename::dirname(__FILE__), 'config.pl') ...` any more!

You can add search path by specifying path as follows. (EXPERIMENTAL)

    use Config::PL ':path' => 'path/config/dir';

__THIS SOFTWARE IS IN ALPHA QUALITY. IT MAY CHANGE THE API WITHOUT NOTICE.__

# FUNCTION

## `my ($conf|%conf) = config_do $file_name;`

Loading configuration from '.pl' file.

# LICENSE

Copyright (C) Masayuki Matsuki.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Masayuki Matsuki <y.songmu@gmail.com>
