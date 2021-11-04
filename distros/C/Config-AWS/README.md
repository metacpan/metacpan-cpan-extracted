# NAME

Config::AWS - Parse AWS config files

# SYNOPSIS

    use Config::AWS ':all';

    # Read the data for a specific profile
    $config = read( $source, $profile );

    # Or read the default profile from the default file
    $config = read();

    # Which is the same as
    $config = read(
        -r credentials_file() ? credentials_file() : config_file(),
        default_profile()
    );

    # Read all of the profiles from a file
    $profiles = read_all( $source );

    # Or if you have cycles to burn
    $profiles = {
        map { $_ => read( $source, $_ ) } list_profiles( $source )
    };

# DESCRIPTION

Config::AWS is a small distribution with generic methods to correctly parse
the contents of config files for the AWS CLI client as described in
[the AWS documentation](https://docs.aws.amazon.com/cli/latest/topic/config-vars.html).

Although it is common to see these files parsed as standard INI files, this
is not appropriate since AWS config files have an idiosyncratic format for
nested values (as shown in the link above).

Standard INI parsers (like [Config::INI](https://metacpan.org/pod/Config%3A%3AINI)) are not made to parse this sort of
structure (nor should they). So Config::AWS exists to provide a suitable
and lightweight ad-hoc parser that can be used in other applications.

# ROUTINES

Config::AWS does not export anything by default. All the functions
described in this document can be requested by name at the time of import.
Alternatively, the `:all` tag can be used to import all of them into your
namespace in one go. Other tags are explained in the sections below.

## Parsing routines

These are the prefered methods for parsing AWS config data. These can be
imported with the `:read` tag.

- **read**
- **read\_all**
- **list\_profiles**

        $profiles = read_all();                       # Use defaults
        $profiles = read_all( $source );              # Specify source

        @profile_names = list_profiles();             # Use default file
        @profile_names = list_profiles( $source );    # Specify source

        $profile = read();                            # Use defaults
        $profile = read( $source );                   # Use default profile
        $profile = read( $source, $profile );         # Specify source and profile
        $profile = read( undef,   $profile );         # Use default file

    Parse AWS config data. All these functions take the data source to use as
    their first argument. The source can be any of the following:

    - A **string** with the path to the file
    - A **Path::Tiny object** for the config file
    - An **array reference** of lines to parse
    - A **scalar reference** with the entire slurped contents of the file
    - An **undefined** value

    If the source is undefined, a default file name will be used. This will be
    the result of calling **credentials\_file** (if it is a readable file) or the
    result of calling **config\_file** otherwise.

    **read\_all** will return the results of parsing all of the content in the
    source, for all profiles that may be defined in it.

    **read** will instead return the data _for a single profile only_. This
    profile can be specified as the second argument. If no profile is provided,
    **read** will use the result of calling **default\_profile** as the default.

    **list\_profiles** will return only the names of the profiles specified in the
    config as a list. The order will be the same as that used in the source.

## AWS defaults

These routines provide information about the default values, as understood
by the AWS CLI interface. These can be imported with the `:aws` tag.

- **default\_profile**

    Returns the contents of the `AWS_DEFAULT_PROFILE` environment variable, or
    `default` if undefined.

- **config\_file**

    Returns the contents of the `AWS_CONFIG_FILE` environment variable, or
    `~/.aws/config` if undefined.

- **credentials\_file**

    Returns the contents of the `AWS_SHARED_CREDENTIALS_FILE` environment
    variable, or `~/.aws/credentials` if undefined.

## Compatibility with Config::INI

This module includes routines that allow it to be used as a drop-in
replacement of [Config::INI](https://metacpan.org/pod/Config%3A%3AINI). The **read\_file**, **read\_string**, and
**read\_handle** functions behave like those described in the documentation
for that distribution. They can be imported with the `:ini` tag.

Unlike the functions described above, they do not use the default values
for AWS config files or profiles, and require the source to be explicitly
stated.

To more closely mimic the behaviour of the methods they emulate, they return
the entire parsed config data. As a concesion, an optional profile can be
specified as a second argument, in which case only the data for that profile
will be returned.

# CONTRIBUTIONS AND BUG REPORTS

Contributions of any kind are most welcome!

The main repository for this distribution is on
[GitLab](https://gitlab.com/jjatria/Config-AWS), which is where patches
and bug reports are mainly tracked.

Bug reports can also be sent through the CPAN RT system, or by mail directly
to the developers at the address below, although these might not be as
closely tracked.

# AUTHOR

- José Joaquín Atria <jjatria@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2018-2021 by José Joaquín Atria.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
