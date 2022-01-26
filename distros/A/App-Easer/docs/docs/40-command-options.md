---
title: Command options
layout: default
---

# Command options

One of the most important design goals of [App::Easer][] is to allow the
definition of hierarchical command-line interfaces that make it easy to
get inputs *the usual way* and allow the developer to concentrate on
implementing the actual logic of all commands.

Of course *the usual way* is somehow opinionated, but the approach in
[App::Easer][] is more or less in line with what can be seen around:
single character options prepended with a single minus sign, long
alternatives with two, boolean options, same option multiple times,
etc., all thanks to the venerable [Getopt::Long][].

Options directly from the command line are only part of the story,
anyway, as they might come from other sources as well, like e.g.
configuration files or the environment. [App::Easer][] aims at covering
all of them.

## Sources

To cope with the different *sources*, [App::Easer][] has the concept
of... *source*. By default, the following sources are available:

- *command line*: these are the usual options like `-k` or `--foo`, and
  have the highest priority;

- *environment*: options from the environment;

- *parent*: options that are defined in the parent command of a
  sub-command;

- *default*: default values that can be set when [Defining
  options](#defining-options).

When gathering values for those options, the sources in the list are
processed in order, and the whole configuration is built by adding new
values only if the associated keys are not already set in the
configuration available so far. This means that a sequence like this:

```
source1    source2    source3
```

will privilege values coming from `source1`, then values from `source2`,
and last values coming from `source3`.

> Source `+Default` behaves as an "always low-priority" source even if
> it appears early in the list, or as the first item. See [The Default
> source](#the-default-source) for additional details.

The incremental additions process makes it possible for later sources to
leverage values set by previous sources. As an example, `source3` might
gather options from a file whose path is set in `source1`.

## Default sources

The sources in the opening section are set by default, in that the
`sources` key inside the `configuration` is populated with their
associated identifiers, very much like this:

```perl
my $app = {
    configuration => {
        sources => [qw< +Default +CmdLine +Environment +Parent >],
        ...
    },
    ...
};
```

`+Default` appears first and it's not a typo. Even in this case, it will
be the one with the lowest priority of all, see more details in [The
Default source](#the-default-source).

The configuration above is the same as setting `sources` to the shortcut
value `+DefaultSources`. Again, this is not necessary as it's the
default:

```perl
my $app = {
    configuration => {
        sources => '+DefaultSources',
        ...
    },
    ...
};
```

It is customary to make the command-line arguments be the top-priority
sources for option values, which is why it's set as such in the default
sources. There might be cases, though, where *environment variables*
should take the precedence, which can be obtained like this:

```perl
my $app = {
    configuration => {
        sources => [qw< +Default +Environment +CmdLine +Parent >],
        ...
    },
    ...
};
```

An example where this kind of behaviour has been deemed useful is in
module [Email::Sender][].


## Defining options

Options are defined within each command through the `options` key.
Options are specified as one hash for each option, where all options for
a command are put within an array (which is the one pointed to by
`options`). Example:

```perl
my $app = {
    commands => {
        MAIN => {
            options => [ # "options" points to an array reference
                {
                    # option 1
                    ...
                },
                {
                    # option 2
                    ...
                },
                ...
            ],
            ...
        },
        ...
    },
    ...
};
```

Each hash for an option provides a specification for the option itself.
[App::Easer][] recognizes the following keys:

- `help`: a string of text providing a description for the option,
  printed when the `help` command is invoked;
- `name`: the name of the option. This is optional, potentially derived
  automatically from the `getopt` option;
- `getopt`: a string specification that is suitable for `Getopt::Long`
  ([The CmdLine source](#the-cmdline-source));
- `environment`: the name of the environment variable that is looked for
  to find a value. If configuration `auto-environment` is set (this is
  the default), it's possible to set this value to `1` and the
  environment variable name will be generated automatically;
- `default`: a default value to assign to the option, in case no other
  source provides one.

Example:

```perl
my $app = {
    commands => {
        MAIN => {
            options => [ # "options" points to an array reference
                {
                    help => 'the mighty foo option, you know it!',
                    getopt => 'foo|f=s',
                    environment => 'GAH_FOO',
                    default => 'bar',
                },
                {
                    help => 'the less-known baz option',
                    getopt => 'baz|B!', # this is boolean
                    environment => 1,   # auto-generated name
                    # no default
                },
                ...
            ],
            ...
        },
        ...
    },
    ...
};
```

## Where to put sources specifications

It's possible to put a specification of the sources both at the global
application level, as well as the single-command level. The latter will
take precedence over the former:

```perl
my $app = {
    configuration => {
        sources => '+DefaultSources', # unnecessary, it's the default!
    },
    commands => { # enable a configuration file for the MAIN entry point
        MAIN => {
            sources => [qw< +Default +CmdLine +Environment +Parent
                +JsonFileFromConfig
            >],
            'config-option' => 'config', # unnecessary, default!
            options => [
                {
                    getopt => 'config|c=s',
                    environment => 'GAH_CONFIG_FILE',
                    default => "$HOME/.gah.json",
                    help => 'path to the configuration file',
                }
            ],
            children => [qw< foo bar >]
            ...
        },
        foo => {
            sources => [qw< +Parent >],
            'allow-residual-options' => 1,
        },
        bar => {...},
    },
};
```

In the example above:

- the default is set to... the default, just explicitly so that it's
  clear what's going on. Hence, configurations will be taken from the
  "usual" sources;
- the `MAIN` command overrides the list of sources to also allow for a
  configuration file, which is collected from the `config` option (again
  this is stated explicitly for sake of clarity in this tutorial);
- the `foo` child takes options from the parent command `MAIN` only, and
  allows the rest of the command line to contain options-looking
  arguments. This is useful if `foo` is just a wrapper around an
  external command, and the rest of the command line has to be taken
  verbatim to be passed down the line. Setting `allow-residual-options`
  to a true value in this case is not strictly needed, because we're not
  using the `+CmdLine` option so we're not checking the command line at
  all; anyway, it's good to document this.
- last, the `bar` child uses the defaults set in the main application
  configuration.

## Option values validation

[Getopt::Long][] enables a first coarse validation, by providing input
types for integers, strings and booleans. Sometimes, though, this might
not be sufficient, e.g. if some options are mutually exclusive and
incompatible.

To address this, it is possible to set key `validate` for performing
validation upon the collected options. This can happen at the top
`configuration` level or inside each command's specification.

In the first case, `validate` must point to an *executable* (i.e.
something that can be resolved by [App::Easer][] into a sub) with the
following signature:

```perl
sub validator ($global, $spec, $args) { die 'sorry!' if error(); }
```

The passed parameters are:

- `$global` the global application object;
- `$spec` the specification for the command under analysis;
- `$args` any command-line arguments residual up to this point.

The *latest* configuration to be checked is available in
`$global->{configs}[-1]` (not exactly an easy place...):

```perl
sub validator ($global, $spec, $args) {
   require Params::Validate;
   Params::Validate::validate(
      $self->{configs}[-1]->%*,  # configuration to validate
      {...}                      # hash for Params::Validate
   );
}
```

The interface above is not officially documented and is subject to
change, e.g. to make it easier to do the validation without having to
fiddle with the internals of `$global`.

When the `validate` key is set in a command's specification, it can
either be an *executable* like described above, or a hash reference. In
this latter case, [Params::Validate][] is used to validate the
configuration against that hash reference. This particular approach can
be considered stable and not subject to changes in the future.


## Configuration file from another option

It's possible to expand the options values gathering with loading them
from a JSON file, whose path is provided among the available options.
This allows e.g. to add a command-line option `-c|--config` to point to
a file with further values.

The indication to also look for a configuration file is usually best
placed at the end of the list:

```perl
my $app = {
    configuration => {
        sources => [qw< +Default +CmdLine +Environment +Parent
            +JsonFileFromConfig
        >],
        ...
    },
    ...
};
```

By default, source `+JsonFileFromConfig` will look into the built
configuration (i.e. coming from all previus sources) for an option
called exactly `config`, and use that as a path to the configuration
file to load.

> This is the exact reason why [The Default source](#the-default-source)
> works differently. It allows setting a default value for this option,
> so that it's considered at the right time if it's not provided on the
> command line, in the environment or from a parent's configuration.

It is possible to set a different configuration key to be used to gather
the path, though, through the command's configuration key
`config-option`. Example:

```perl
my $app = {
    configuration => {
        sources => [qw< +Default +CmdLine +Environment +Parent
            +JsonFileFromConfig
        >],
        ...
    },
    commands => {
        MAIN => {
            'config-option' => 'cnfile',
            options => [
                {
                    getopt => 'cnfile|C=s',
                    environment => 'MAH_CONFIGURATION_FILE',
                    default => "$HOME/.mah-app.json",
                    help => 'path to a JSON configuration file',
                },
                ...
            ],
            ...
        },
        ...
    },
};
```

In this case, the command line option for specifying a configuration
file would be `-C|--cnfile`, as well as the key to look for this
configuration would be `cnfile`.

## Getting options from specific files

A lot of tools provide a pre-defined way of setting options in
configuration files, e.g. looking in the home directory, in `/etc`, and
so on.

[App::Easer][] supports providing such a list and iterating over it with
source `+JsonFiles`:

```perl
my $app = {
    configuration => {
        sources => [qw< +Default +CmdLine +Environment +Parent
            +JsonFiles
        >],
        ...
    },
    commands => {
        MAIN => {
            'config-files' => [ "$HOME/.gah.json", '/etc/gah.json' ],
        },
    },
    ...
};
```

Files set in `config-files` will be loaded if present, and added to the
configuration with the usual rule that what appears earlier takes
precedence over what appears further down the list.

*All* existing files will be loaded. If a different behaviour is needed
(e.g. the first that works stops everything else), then a [Custom
source](#custom-sources) should be coded.


## Sources with configuration files

If the program should support configuration files from both the command
line and default pre-defined positions, it's possible to use the global
source specification `+SourcesWithFiles`:

```perl
my $app = {
    configuration => {
        sources => '+SourcesWithFiles',
        ...
    },
    ...
};
```

This is equivalent to the following

```perl
my $app = {
    configuration => {
        sources => [qw< +Default +CmdLine +Environment +Parent
            +JsonFileFromConfig +JsonFiles
        >],
        ...
    },
    ...
};
```

## The CmdLine source

The `+CmdLine` source is probably the most important one, and it's
backed by the venerable [Getopt::Long][] module, which is CORE as of
perl 5.

This source leverages the key `getopt` within an option definition. This
is supposed to be a specification valid according to [Getopt::Long][]:

```perl
my $app = {
    commands => {
        MAIN => {
            options => [
                {
                    getopt => 'foo|f=s',
                    ...
                },
                ...
```

By default, the configuration for this module is as follows:

- `gnu_getopt` as a basic configuration
- `require_order` and `pass_through` are added for *intermediate*
  (i.e. non-leaf, i.e. having children) commands;
- `pass_through` is added for commands where the addional configuration
  `allow-residual-options` is set inside the command specification. This
  allows keeping lists of command-line options intact to e.g. pass them
  to an external command.

It is possible to set the exact list of [Getopt::Long][] configurations
through key `getopt-config`:

```perl
my $app = {
    commands => {
        MAIN => {
            'getopt-config' => [qw< posix_default >],
            ...
        },
    },
};
```

## The Environment source

The `+Environment` source allows taking options from environment
variables, providing support for reading the key `environment`,
providing the environment variable name:

```perl
my $app = {
    commands => {
        MAIN => {
            options => [
                {
                    environment => 'MYAPP_FOO',
                    ...
                },
                ...
```

If configuration `auto-environment` is set (either at the top level, or
for the specific command), it's also possible to set the `environment`
key to `1` and let [App::Easer][] figure out the variable name
automatically, based on the `name` global configuration and the name of
the option itself:

```perl
my $app = {
    configuration => {
        name => 'MYAPP',
        ...
    },
    commands => {
        MAIN => {
            options => [
                {
                    name => 'foo',
                    environment => 1,
                    ...
                },
                ...
```

The example above generates the same environment variable name
`MYAPP_FOO` as in the previous example.

## The Parent source

The `+Parent` source allows forwarding option values from parent
commands down to the descendants. This allows e.g. to refactor all
global options at the parent level, while still being able to consume
them in actual leaf commands.

Any option that overlaps with a parent's will also override by default.
For this reason, caution should be exercised to avoid collisions.

## The Default source

As explained in section [Sources](#sources), the configuration is built
incrementally by adding more new key/value pairs as the different
sources are processed in order. This means that sources appearing early
in the list have precedence over those appearing later.

The `+Default` source works specially in that it always gives way to any
option coming from a source that appears *later* in the list.

This is why it is best put *at the beginning*: everything else is
capable of overriding it. In this way, it is possible to set default
values for options that are useful for *sources themselves*.

As an example, source `+JsonFileFromConfig` uses one configuration
option to determine the path to a JSON file with configurations to load.
This arrangement allows setting a default path for this file, which can
be overridden by `+CmdLine`, `+Environment`, etc., but still be
available when the `+JsonFileFromConfig` source is processed, while at
the same time allowing the options from the JSON file to override any
*other* default value that might have been set.

So, in a nutshell, if default values are of interest in defining the
options list for a command, it's best to always put `+Default` at the
beginning.

## Custom sources

The sources provided with [App::Easer][] might cover a lot, but not
everything. In this case, it's possible to create *custom sources*.

A new source is defined by its *handler function*:

```perl
sub custom_Foo ($general, $spec, $args) { ... }
```

The parameters that are passed in are:

- `$general`: the overall tracking object.

- `$spec`: the command specification (a hash reference).

- `$args`: the command line parameters, or better what's left of them
  after having passed through parent commands.

The interesting bit should normally be `$spec`. Let's see an example for
replicating the behaviour of `+JsonFileFromConfig`, but to read YAML
instead:

```perl
sub custom_YamlConfigFile ($general, $spec, $args) {

   # The accumulated configuration so far is passed in the "config" key.
   my $conf = $spec->{config};

   # By default we will look into key "config", e.g. resulting from
   # cmdline option "-c|--config", but we will also support overriding
   # needed, just like +JsonFileFromConfig.
   # Sorry for the overlapping names, this is at a different level!
   my $key = $spec->{'config-option'} // 'config';

   # This is the file path, although it might not be defined
   my $path = $conf->{$key} // return {};

   # Load the file with a YAML module
   require YAML::XS;
   return YAML::XS::LoadFile($path);
} ## end sub stock_JsonFileFromConfig
```

The key is to return a hash reference with the (additional) key/value
pairs to be added to the configuration; [App::Easer][] will make sure to
get them onboard in the right precedence order.

If any option value should be considered with *least* precedence order,
much like `+Default` does ([Default source](#default-source)), the
associated key in the hash must be prefixed with the string `//=`, like
this example where defaults are loaded from a YAML file whose name is
available directly in the command specification:

```perl
sub custom_YamlConfigFile ($general, $spec, $args) {

   # This is the file path for our defaults
   my $path = $spec->{'defaults-file'};
   return {} unless defined $path && -e $path;

   require YAML::XS;
   my $data = YAML::XS::LoadFile($path);
   my %output;
   while (my ($key, $value) = each %$data) {
      $output{'//=' . $key} = $value;
   }
   return \%output;
} ## end sub stock_JsonFileFromConfig
```

After the handler is available, it's possible to add it to the list of
sources ([Where to put sources
specifications](#where-to-put-sources-specifictions)):

```perl
my $app = {
    configuration => {
        sources => [qw< +Default +CmdLine +Environment +Parent >,
            \&custom_YamlConfigFile,
        ],
    },
    ...
};
```

All sources are subject to the automatic resolution mechanism provided
by [App::Easer][], so as an example this works:

```perl
my $app = {
    factory => {
        prefixes => { '^' => __PACKAGE__ . '#custom_' },
    },
    configuration => {
        sources => [qw< +Default +CmdLine +Environment +Parent >,
            '^YamlConfigFile',
        ],
    },
    ...
};
```

The resolution process will transform `^YamlConfigFile` into
`main#custom_YamlConfigFile` (assuming the current package is `main`, of
course) and then to a reference to the `custom_YamlConfigFile` function
in the example above.

## Custom merging

The default approach to merge option values coming from several sources
is to privilege the sources that appear first and to operate only on the
base of overriding.

In case this behaviour is not good (e.g. because instead of *overriding*
some different action should be performed), it's possible to set a
different merging function than the default one, either at the overall
`configuration` level, or at the single command level:

```perl
$app = {
    configuration => {
        merge => \&new_merger_default,
    },
    commands => [
        MAIN => {
            merge => \&new_merger_main,
            ...
        },
    ],
};
```

The `merge` key supports the resolution mechanism that is pervasive in
[App::Easer][].

The new merging function(s) must support the following signature:

```perl
sub new_merger_default(@list_of_hash_references) { ... }
```

where the input array is the list of hash references to merge, provided
in the same order as the `sources` (but possibly not all of them,
because sources are processed in order).

It is important to consider that the `+Default` source provides a hash
where all the keys are prefixed with the string `//=`, like in this
example:

```perl
my $typical_defaults_hash = {
    '//=foo' => 'bar',
    '//=baz' => 'nothing special',
};
```

This allows implementing the mechanism by which all these options are
always considered at the least possible priority.

## Custom collecting

The whole process of option values collection can be overridden with a
custom behaviour by means of the `collect` configuration, either at the
top `configuration` level, or at the single command level:

```perl
$app = {
    configuration => {
        collect => \&new_collector_default,
    },
    commands => [
        MAIN => {
            collect => \&new_collector_main,
            ...
        },
    ],
};
```

A new collector function must support the following signature:

```perl
sub new_collector_default ($app, $spec, $args) {
    ...;
    return (\%config, \@residual_args);
}
```

The positional parameters are:

- `$app`: the overall hash keeping track of the application;
- `$spec`: the specification of a command under process;
- `$args`: the command-line arguments left.

The new collector is supposed to return a list of two items, in order:

- the collected option values as a reference to a hash;
- the residual command line arguments from `$args` (it might be the
  whole `$args` in case no command-line argument is consumed).

The main goal of [App::Easer][] is, of course, to never make this
flexibility needed; sometimes, though, it might be that a specific
command needs such a peculiar handling that it's just best to recode the
basic collection mechanism altogether.

[App::Easer]: https://metacpan.org/pod/App::Easer
[Installing Perl Modules]: https://github.polettix.it/ETOOBUSY/2020/01/04/installing-perl-modules/
[Perl]: https://www.perl.org/
[App::FatPacker]: https://metacpan.org/pod/App::FatPacker
[latest]: https://raw.githubusercontent.com/polettix/App-Easer/main/lib/App/Easer.pm
[download]: {{ '/assets/template.pl' | prepend: site.baseurl }}
[Getopt::Long]: https://metacpan.org/pod/Getopt::Long
[Email::Sender]: https://metacpan.org/pod/Email::Sender::Manual::QuickStart#specifying-transport-in-the-environment
[Params::Validate]: https://metacpan.org/pod/Params::Validate
