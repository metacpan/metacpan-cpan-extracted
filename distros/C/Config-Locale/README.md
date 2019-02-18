# NAME

Config::Locale - Load and merge locale-specific configuration files.

# SYNOPSIS

    use Config::Locale;
    
    my $locale = Config::Locale->new(
        identity => \@values,
        directory => $config_dir,
    );
    
    my $config = $locale->config();

# DESCRIPTION

This module takes an identity array, determines the permutations of the identity using
[Algorithm::Loops](https://metacpan.org/pod/Algorithm::Loops), loads configuration files using [Config::Any](https://metacpan.org/pod/Config::Any), and finally combines
the configurations using [Hash::Merge](https://metacpan.org/pod/Hash::Merge).

So, given this setup:

    Config::Locale->new(
        identity => ['db', '1', 'qa'],
    );

The following configuration stems will be looked for (listed from least specific to most):

    default
    all.all.qa
    all.1.all
    all.1.qa
    db.all.all
    db.all.qa
    db.1.all
    db.1.qa
    override

For each file found the contents will be parsed and then merged together to produce the
final configuration hash.  The hashes will be merged so that the most specific configuration
file will take precedence over the least specific files.  So, in the example above,
"db.1.qa" values will overwrite values from "db.1.all".

The term `stem` comes from [Config::Any](https://metacpan.org/pod/Config::Any), and means a filename without an extension.

# ARGUMENTS

## identity

The identity that configuration files will be loaded for.  In a typical hostname-based
configuration setup this will be the be the parts of the hostname that declare the class,
number, and cluster that the current host identifies itself as.  But, this could be any
list of values.

## directory

The directory to load configuration files from.  Defaults to the current
directory.

## wildcard

The wildcard string to use when constructing the configuration filenames.
Defaults to `all`.  This may be explicitly set to undef wich will cause
the wildcard string to not be added to the filenames at all.

## default\_stem

A stem to load first, before all other stems.

Defaults to `default`.  A relative path may be specified which will be assumed
to be relative to ["directory"](#directory).  If an absolute path is used then no change
will be made.

Note that ["prefix"](#prefix) and ["suffix"](#suffix) are not applied to this stem.

## override\_stem

A stem to load last, after all other stems.

Defaults to `override`.  A relative path may be specified which will be assumed
to be relative to ["directory"](#directory).  If an absolute path is used then no change
will be made.

Note that ["prefix"](#prefix) and ["suffix"](#suffix) are not applied to this stem.

## require\_defaults

If true, then any key that appears in a non-default stem must exist in the
default stem or an error will be thrown.  Defaults to false.

## separator

The character that will be used to separate the identity keys in the
configuration filenames.  Defaults to `.`.

## prefix

An optional prefix that will be prepended to the configuration filenames.

## suffix

An optional suffix that will be appended to the configuration filenames.
While it may seem like the right place, you probably should not be using
this to specify the extension of your configuration files.  [Config::Any](https://metacpan.org/pod/Config::Any)
automatically tries many various forms of extensions without the need
to explicitly declare the extension that you are using.

## algorithm

Which algorithm used to determine, based on the identity, what configuration
files to consider for inclusion.

The default, `NESTED`, keeps the order of the identity.  This is most useful
for identities that are derived from the name of a resource as resource names
(such as hostnames of machines) typically have a defined structure.

`PERMUTE` finds configuration files that includes any number of the identity
values in any order.  Due to the high CPU demands of permutation algorithms this does
not actually generate every possible permutation - instead it finds all files that
match the directory/prefix/separator/suffix and filters those for values in the
identity and is very fast.

## merge\_behavior

Specify a [Hash::Merge](https://metacpan.org/pod/Hash::Merge) merge behavior.  The default is `LEFT_PRECEDENT`.

# ATTRIBUTES

## config

Contains the final configuration hash as merged from the hashes in ["default\_config"](#default_config),
["stem\_configs"](#stem_configs), and ["override\_configs"](#override_configs).

## default\_config

A merged hash of all the hashrefs in ["default\_configs"](#default_configs).  This is computed
separately, but then merged with, ["config"](#config) so that the ["stem\_configs"](#stem_configs) and
["override\_configs"](#override_configs) can be checked for valid keys if ["require\_defaults"](#require_defaults)
is set.

## default\_configs

An array of hashrefs, each hashref containing a single key/value pair as returned
by [Config::Any](https://metacpan.org/pod/Config::Any)->load\_stems() where the key is the filename found, and the value
is the parsed configuration hash for any ["default\_stem"](#default_stem) configuration.

## stem\_configs

Like ["default\_configs"](#default_configs), but for any ["stems"](#stems) configurations.

## override\_configs

Like ["default\_configs"](#default_configs), but for any ["override\_stem"](#override_stem) configurations.

## stems

Contains an array of file paths for each value in ["combinations"](#combinations).

## combinations

Holds an array of arrays containing all possible permutations of the
identity, per the specified ["algorithm"](#algorithm).

## merge\_object

The [Hash::Merge](https://metacpan.org/pod/Hash::Merge) object that will be used to merge the configuration
hashes.

## default\_stem\_path

## override\_stem\_path

# AUTHOR

Aran Clary Deltac <bluefeet@gmail.com>

# LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
