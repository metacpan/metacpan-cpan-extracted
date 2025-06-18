# NAME

Config::Abstraction - Configuration Abstraction Layer

# VERSION

Version 0.31

# SYNOPSIS

    use Config::Abstraction;

    my $config = Config::Abstraction->new(
      config_dirs => ['config'],
      env_prefix => 'MYAPP_',
      flatten => 0,
    );

    my $db_user = $config->get('database.user');

# DESCRIPTION

`Config::Abstraction` is a flexible configuration management layer that sits above `Config::*` modules.
In addition to using drivers to load configuration data from multiple file
formats (YAML, JSON, XML, and INI),
it also allows levels of configuration, each of which overrides the lower levels.
So, it also integrates environment variable
overrides and command line arguments for runtime configuration adjustments.
This module is designed to help developers manage layered configurations that can be loaded from files and overridden at run-time for debugging,
offering a modern, robust and dynamic approach
to configuration management.

## KEY FEATURES

- Multi-Format Support

    Supports configuration files in YAML, JSON, XML, and INI formats.
    Automatically merges configuration data from these different formats,
    allowing hierarchical configuration management.

- Environment Variable Overrides

    Allows environment variables to override values in the configuration files.
    By setting environment variables with a specific prefix (default: `APP_`),
    values in the configuration files can be dynamically adjusted without modifying
    the file contents.

- Flattened Configuration Option

    Optionally supports flattening the configuration structure. This converts deeply
    nested configuration keys into a flat key-value format (e.g., `database.user`
    instead of `database->{user}`). This makes accessing values easier for
    applications that prefer flat structures or need compatibility with flat
    key-value stores.

- Layered Configuration

    Supports merging multiple layers of configuration files. For example, you can
    have a `base.yaml` configuration file that provides default values, and a
    `local.yaml` (or `local.json`, `local.xml`, etc.) file that overrides
    specific values. This allows for environment-specific configurations while
    keeping defaults intact.

- Merge Strategy

    The module merges the configuration data intelligently, allowing values in more
    specific files (like `local.yaml`, `local.json`, `local.xml`, `local.ini`)
    to override values in base files. This enables a flexible and layered configuration
    system where you can set defaults and override them for specific environments.

- Error Handling

    Includes error handling for loading configuration files.
    If any file fails to
    load (e.g., due to syntax issues), the module will throw descriptive error
    messages to help with debugging.

## SUPPORTED FILE FORMATS

- YAML (`*.yaml`, `*.yml`)

    The module supports loading YAML files using the `YAML::XS` module.

- JSON (`*.json`)

    The module supports loading JSON files using `JSON::MaybeXS`.

- XML (`*.xml`)

    The module supports loading XML files using `XML::Simple`.

- INI (`*.ini`)

    The module supports loading INI files using `Config::IniFiles`.

## ENVIRONMENT VARIABLE HANDLING

Configuration values can be overridden via environment variables. For
instance, if you have a key in the configuration such as `database.user`,
you can override it by setting the corresponding environment variable
`APP_DATABASE__USER` in your system.

For example:

    $ export APP_DATABASE__USER="env_user"

This will override any value set for `database.user` in the configuration files.

## COMMAND LINE HANDLING

Configuration values can be overridden via the command line (`@ARGV`).
For instance, if you have a key in the configuration such as `database.user`,
you can override it by adding `"--APP_DATABASE__USER=other_user_name"` to the command line arguments.
This will override any value set for `database.user` in the configuration files.

## EXAMPLE CONFIGURATION FLOW

- 1. Data Argument

    The data passed into the constructor via the `data` argument is the starting point.
    Essentially,
    this contains the default values.

- 2. Loading Files

    The module then looks for configuration files in the specified directories.
    It loads the following files in order of preference:
    `base.yaml`, `local.yaml`, `base.json`, `local.json`, `base.xml`,
    `local.xml`, `base.ini`, and `local.ini`.

    If `config_file` or `config_files` is set, those files are loaded last.

    If no `config_dirs` is given, try hard to find the files in various places.

- 3. Merging and Resolving

    The module merges the contents of these files, with more specific configurations
    (e.g., `local.*`) overriding general ones (e.g., `base.*`).

- 4. Environment Overrides

    After loading and merging the configuration files,
    the environment variables are
    checked and used to override any conflicting settings.

- 5. Command Line

    Next, the command line arguments are checked and used to override any conflicting settings.

- 6. Accessing Values

    Values in the configuration can be accessed using a dotted notation
    (e.g., `'database.user'`), regardless of the file format used.

# METHODS

## new

Constructor for creating a new configuration object.

Options:

- `config_dirs`

    An arrayref of directories to look for configuration files
    (default: `$CONFIG_DIR`, `$HOME/.conf`, `$HOME/config`, `$HOME/conf`, `$DOCUMENT_ROOT/conf`, `$DOCUMENT_ROOT/../conf`, `conf`).

- `config_file`

    Points to a configuration file of any format.

- `config_files`

    An arrayref of files to look for in the configuration directories.
    Put the more important files later,
    since later files override earlier ones.

    Considers the files `default` and `$script_name` before looking at `config_file` and `config_files`.

- `data`

    A hash ref of data to prime the configuration with.
    Any other data will overwrite by this.

- `env_prefix`

    A prefix for environment variable keys and comment line options, e.g. `MYAPP_DATABASE__USER`,
    (default: `'APP_'`).

- `file`

    Synonym for `config_file`

- `flatten`

    If true, returns a flat hash structure like `{database.user}` (default: `0`) instead of `{database}{user}`.
    \`
    &#x3d;item \* `level`

    Level for logging.

- `logger`

    Used for warnings and traces.
    It can be an object that understands warn() and trace() messages,
    such as a [Log::Log4perl](https://metacpan.org/pod/Log%3A%3ALog4perl) or [Log::Any](https://metacpan.org/pod/Log%3A%3AAny) object,
    a reference to code,
    a reference to an array,
    or a filename.

- `path`

    A synonym of `config_dirs`.

- `sep_char`

    The separator in keys.
    The default is a `'.'`,
    as in dotted notation,
    such as `'database.user'`.

If just one argument is given, it is assumed to be the name of a file.

## get(key)

Retrieve a configuration value using dotted key notation (e.g.,
`'database.user'`). Returns `undef` if the key doesn't exist.

## all()

Returns the entire configuration hash,
possibly flattened depending on the `flatten` option.

The entry `config_path` contains a list of the files that the configuration was loaded from.

## merge\_defaults

Merge the configuration hash into the given hash.

    package MyPackage;
    use Params::Get;
    use Config::Abstraction;

    sub new
    {
      my $class = shift;

      my $params = Params::Get::get_params(undef, \@_) || {};

      if(my $config = Config::Abstraction->new(env_prefix => "${class}::")) {
        $params = $config->merge_defaults(defaults => $params, merge => 1, section => $class);
      }

      return bless $params, $class;
    }

Options:

- merge

    Usually,
    what's in the object will overwrite what's in the defaults hash,
    if given,
    the result will be a combination of the hashes.

- section

    Merge in that section from the configuration file.

- deep

    Try harder to merge all configurations from the global section of the configuration file.

## AUTOLOAD

This module supports dynamic access to configuration keys via AUTOLOAD.
Nested keys are accessible using the separator,
so `$config->database_user()` resolves to `$config->{database}->{user}`,
when `sep_char` is set to '\_'.

    $config = Config::Abstraction->new(
        data => {
            database => {
                user => 'alice',
                pass => 'secret'
            },
            log_level => 'debug'
        },
        flatten   => 1,
        sep_char  => '_'
    );

    my $user = $config->database_user();        # returns 'alice'

    # or
    $user = $config->database()->{'user'};      # returns 'alice'

    # Attempting to call a nonexistent key
    my $foo = $config->nonexistent_key();       # dies with error

# BUGS

It should be possible to escape the separator character either with backslashes or quotes.

Due to the case-insensitive nature of environment variables on Windows,
it may be challenging to override values using environment variables on that platform.

# SUPPORT

This module is provided as-is without any warranty.

Please report any bugs or feature requests to `bug-config-abstraction at rt.cpan.org`,
or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Config-Abstraction](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Config-Abstraction).
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

You can find documentation for this module with the perldoc command.

    perldoc Config::Abstraction

# SEE ALSO

- [Config::Auto](https://metacpan.org/pod/Config%3A%3AAuto)
- [Log::Abstraction](https://metacpan.org/pod/Log%3A%3AAbstraction)

# AUTHOR

Nigel Horne, `<njh at nigelhorne.com>`
