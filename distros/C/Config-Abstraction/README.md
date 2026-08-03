# NAME

Config::Abstraction - Merge and manage configuration data from different sources

# VERSION

Version 0.40

# SYNOPSIS

## Pattern 1: Environment overrides file overrides in-code defaults

The most common pattern for twelve-factor-style apps.
The `data` argument supplies defaults, a YAML file supplies site configuration,
and environment variables allow per-deployment overrides without touching any file.

    # config/base.yaml
    #   database:
    #     host: db.example.com
    #     port: 5432
    #     user: app

    use Config::Abstraction;

    my $config = Config::Abstraction->new(
        data        => { database => { host => 'localhost', port => 5432 } },
        config_dirs => ['config'],
        env_prefix  => 'APP_',
    );

    # In production, set APP_DATABASE__HOST=db.prod.example.com in the environment.
    # That silently overrides the file value, which in turn overrides the default.
    my $host = $config->get('database.host');
    my $port = $config->get('database.port');

## Pattern 2: Command-line arguments override everything

Useful for CLI tools where operator flags must win over every other source.

    # Run as: myscript.pl --APP_LOGLEVEL=debug --APP_DATABASE__HOST=localhost

    use Config::Abstraction;

    my $config = Config::Abstraction->new(
        config_dirs => ['config'],
        env_prefix  => 'APP_',
    );

    # @ARGV is consumed and stripped during new(); the resulting config already
    # has cli-layer values at the highest precedence.
    my $loglevel = $config->get('loglevel');       # 'debug'  (from --APP_LOGLEVEL)
    my $db_host  = $config->get('database.host');  # 'localhost' (from --APP_DATABASE__HOST)

## Pattern 3: Multi-file layering (base + local override)

Separates shared defaults from machine-specific tweaks.
Every developer has a `base.yaml`; only the production server has `local.yaml`.

    # config/base.yaml   -- checked into version control
    #   database:
    #     host: localhost
    #     user: dev
    #
    # config/local.yaml  -- NOT checked in; production only
    #   database:
    #     host: db.prod.example.com
    #     user: produser
    #     password: s3cr3t

    use Config::Abstraction;

    my $config = Config::Abstraction->new(
        config_dirs => ['config'],   # loads base.yaml then local.yaml
        env_prefix  => 'APP_',
    );

    # On a dev machine (no local.yaml): host='localhost', user='dev'
    # On the prod server:               host='db.prod.example.com', user='produser'
    my $db = $config->get('database.host');
    my $user = $config->get('database.user');

# DESCRIPTION

`Config::Abstraction` is a flexible configuration management layer that sits above `Config::*` modules.
It provides a simple way to layer multiple configuration sources with predictable merge order.
It lets you define sources such as:

- Perl hashes (in-memory defaults or dynamic values)
- Environment variables (with optional prefixes)
- Configuration files (YAML, JSON, INI, or plain key=value)
- Command-line arguments

Sources are applied in the order they are provided. Later sources override
earlier ones unless a key is explicitly set to `undef` in the later source.

In addition to using drivers to load configuration data from multiple file
formats (YAML, JSON, XML, and INI),
it also allows levels of configuration, each of which overrides the lower levels.
So, it also integrates environment variable
overrides and command line arguments for runtime configuration adjustments.
This module is designed to help developers manage layered configurations that can be loaded from files and overridden at run-time for debugging,
offering a modern, robust and dynamic approach
to configuration management.

## Merge Precedence

Sources are applied in the order shown below.  Each row wins over every row
above it.  When the same key appears in multiple sources, the highest-priority
source always determines the final value - including when that value is `undef`.

    Priority   Source                         Set with
    --------   ------                         --------
       1 (lo)  data constructor argument      data => { key => 'default' }
       2        base.*  config files          config/base.yaml, base.json, ...
       3        base.{env}.* config files     config/base.prod.yaml, ...
       4        local.* config files          config/local.yaml, local.json, ...
       5        local.{env}.* config files    config/local.prod.yaml, ...
       6        default / script-name files   config/default.yaml, myapp.yaml, ...
       7        config_file / config_files    config_file => '/etc/myapp.yaml'
       8        Environment variables         APP_DATABASE__HOST=db.prod.example.com
       9 (hi)  CLI arguments (@ARGV)          --APP_DATABASE__HOST=db.prod.example.com

The active environment is set by the `environment` constructor option, or
auto-detected from `{env_prefix}ENV` (e.g. `APP_ENV`), `PLACK_ENV`, or
`NODE_ENV`.  When no environment is configured, rows 3 and 5 are skipped.

Within the file tier (rows 2-7), later files override earlier files using
`Hash::Merge` LEFT\_PRECEDENT: every key in the later file wins over the same
key in an earlier file, even when the later value is `undef` (YAML `~`).
Nested hashes are merged recursively, so a `local.yaml` that only sets
`database.host` will not erase `database.port` from `base.yaml`.

    Example - what wins for the key C<database.host> when APP_ENV=prod:

    data              =>  'localhost'              (overridden by base.yaml)
    base.yaml         =>  'db.example.com'         (overridden by base.prod.yaml)
    base.prod.yaml    =>  'db.prod.example.com'    (overridden by local.yaml)
    local.yaml        =>  'db.local.example.com'   (overridden by local.prod.yaml)
    local.prod.yaml   =>  'db.prod-local.example.com'  (overridden by $APP_DATABASE__HOST)
    $APP_DATABASE__HOST  =>  'db.override.example.com'    <-- this wins

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

- Centralized Configuration Management

    Supports remote configuration management files,
    so that configuration on remote machines can be centrally managed.

## SUPPORTED FILE FORMATS

- YAML (`*.yaml`, `*.yml`)

    Loaded with `YAML::XS`.

- JSON (`*.json`)

    Loaded with `JSON::MaybeXS`.

- XML (`*.xml`)

    Loaded with `XML::Simple` (preferred) or `XML::PP` (fallback).

- INI (`*.ini`)

    Loaded with `Config::IniFiles`.

- TOML (`*.toml`)

    Loaded with `TOML::Tiny`, which implements TOML 1.0.  TOML is a good choice
    for human-editable configuration because its syntax is unambiguous: all values
    are typed, strings must be quoted, and nesting uses `[section]` headers or
    dotted keys rather than indentation.

        # Example: config/base.toml
        [database]
        host   = "db.example.com"
        port   = 5432
        user   = "app"

        [cache]
        ttl    = 300
        debug  = false

    `base.toml` and `local.toml` are discovered automatically in `config_dirs`;
    `local.toml` has higher precedence than `base.toml`, following the same
    layering rules as all other formats.  TOML is also tried as a fallback parser
    in the all-parsers chain used for extensionless `config_file` entries.

    If `TOML::Tiny` is not installed, TOML files are silently skipped with a
    `carp` warning.

## ENVIRONMENT VARIABLE HANDLING

Configuration values can be overridden via environment variables. Environment variables use double underscores (\_\_) to denote nested configuration keys and single underscores remain as part of the key name under the prefix namespace.

For example:

    APP_DATABASE__USER becomes database.user (nested structure)

      $ export APP_DATABASE__USER="env_user"

will override any value set for \`database.user\` in the configuration files.

    APP_LOGLEVEL becomes APP.loglevel (flat under prefix namespace)

    APP_API__RATE_LIMIT becomes api.rate_limit (mixed usage)

This allows you to override both top-level and nested configuration values using environment variables.

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

    The value of `config_dirs` can be overridden at runtime by the environment variable CONFIG\_DIR
    (note that is just one directory, hence it's CONFIG\_DIR not CONFIG\_DIRS).

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

    For centralised configuration management,
    entries beginning with `/../` are treated as remote specifications using the
    Newcastle Connection convention -- see ["Remote configuration directories (Newcastle Connection)"](#remote-configuration-directories-newcastle-connection).

- `config_file`

    Points to a configuration file of any format.

- `config_files`

    An arrayref of files to look for in the configuration directories.
    Put the more important files later,
    since later files override earlier ones.

    Considers the files `default` and `$script_name` before looking at `config_file` and `config_files`.

- `data`

    A hash ref of default data to prime the configuration with.
    These are applied before loading
    other sources and can be overridden by later sources or by explicitly passing
    options directly to `new`.

        $config = Config::Abstraction->new(
            data => {
                log_level => 'info',
                retries => 3,
            }
        );

- `defaults`

    A hash reference that provides default values for the object's own attributes (such as `config_dirs`, `logger`, `flatten`, etc.).
    If this option is supplied,
    the object is initialized using the keys in this hash as the base;
    any other options passed directly to `new()` (aside from `env_prefix`) are ignored.
    This allows you to pre-define a standard configuration profile for the object itself.
    Note that `defaults` is distinct from the `data` option - `data` supplies the initial configuration values that will be merged with files, environment, and command line,
    while `defaults` sets the object's internal parameters.
    The `env_prefix` value,
    if provided as a top-level argument,
    still takes precedence over any `env_prefix` that might exist inside the `defaults` hash.

- `encryption_key`

    A 256-bit (32-byte) AES key used to transparently decrypt `ENC[...]` values found in any
    configuration source after the full merge.  The key may be supplied as:

    - 32 raw bytes
    - 64 lowercase or uppercase hex characters
    - 44 Base64 or Base64url characters (standard or URL-safe alphabet, with or without trailing `=`)

    If no key is configured (and neither `encryption_key_file` nor the corresponding
    environment variables are set), `ENC[...]` tokens are left as literal strings.
    Decryption requires [CryptX](https://metacpan.org/pod/CryptX) (`Crypt::AuthEnc::GCM`); if that module is absent a
    `croak` is raised when an encrypted value is encountered.

    See ["ENCRYPTED VALUES"](#encrypted-values) for the full workflow.

- `encryption_key_file`

    Path to a file whose first line contains the encryption key in any of the formats accepted
    by `encryption_key`.  Takes precedence over the `ENCRYPTION_KEY_FILE` and
    `{env_prefix}ENCRYPTION_KEY_FILE` environment variables, but is overridden by a key
    supplied directly via `encryption_key`.

- `env_prefix`

    A prefix for environment variable keys and comment line options, e.g. `MYAPP_DATABASE__USER`,
    (default: `'APP_'`).

- `environment`

    The name of the active deployment environment (e.g. `'dev'`, `'staging'`, `'prod'`).
    When set, config files named `base.{env}.*` are loaded immediately after their `base.*`
    equivalents, and `local.{env}.*` files are loaded immediately after `local.*` files,
    giving two additional override tiers at no cost to the base configuration.

        my $cfg = Config::Abstraction->new(
            config_dirs => ['config'],
            environment => 'prod',          # loads base.prod.yaml, local.prod.yaml, ...
        );

    If `environment` is not given, the value is auto-detected in this order:

    - 1. `{env_prefix}ENV` environment variable (e.g. `APP_ENV`)
    - 2. `PLACK_ENV`
    - 3. `NODE_ENV`

    When none of these is set, the environment-specific tiers are silently skipped.
    The environment name must contain only ASCII letters, digits, hyphens, and underscores
    (matched against `/^[A-Za-z0-9_\-]+$/`); any other value causes a `croak`.

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

- `schema`

    A [Params::Validate::Strict](https://metacpan.org/pod/Params%3A%3AValidate%3A%3AStrict) compatible schema to validate the configuration file against.

- `validators`

    A hashref mapping dotted config keys to validation rules.  Each rule is applied to the
    corresponding value in the merged configuration immediately after all sources have been
    merged (or on first access when `lazy` is set).  A validation failure croaks.

    Each rule may be one of:

    - A type name string

            validators => {
                'database.port' => 'integer',
                'app.name'      => 'string',
                'price'         => 'number',
                'enabled'       => 'boolean',
                'tags'          => 'array',
                'settings'      => 'hash',
            }

        Supported types: `integer` (matches `/^-?\d+$/` -- no decimal point),
        `number` or `float` (`Scalar::Util::looks_like_number`), `boolean`
        (`0`, `1`, `true`, `false`, `yes`, `no` -- case-insensitive),
        `string` (any defined non-reference scalar), `array` (arrayref),
        `hash` (hashref).

    - A compiled regular expression

            validators => {
                'log.level' => qr/^(?:debug|info|warn|error|fatal)$/i,
                'app.name'  => qr/^\w[\w\-]{1,63}$/,
            }

        The value must be defined and must match the regex.

    - A coderef

            validators => {
                'database.port' => sub { my $v = shift; defined($v) && $v >= 1 && $v <= 65535 },
            }

        Called with the value as its only argument.  Must return a true value; otherwise the
        constructor croaks.

    - A hashref combining multiple constraints

            validators => {
                'database.port' => {
                    type     => 'integer',
                    min      => 1,
                    max      => 65535,
                    required => 1,
                },
                'api.key' => {
                    pattern  => qr/^[A-Za-z0-9]{32}$/,
                    required => 1,
                },
            }

        Keys: `type` (type-name string as above), `pattern` (compiled regex), `min` (numeric
        lower bound, inclusive), `max` (numeric upper bound, inclusive), `required` (if true,
        the key must exist and its value must be defined).

    All constraint types may be freely combined: specifying both `type` and `pattern`
    requires the value to satisfy both.

- `checker`

    A prototype string (YAML) or hashref passed to [Config::Checker](https://metacpan.org/pod/Config%3A%3AChecker) for template-based
    structural validation.  `Config::Checker` must be installed; if it is absent a `carp`
    warning is emitted and validation is skipped.

    The prototype mirrors the expected config structure.  Keys and values can carry type
    annotations (`[INTEGER]`, `[PATH]`, `[HOSTNAME]`, ...), custom code checks
    (`{...}`), and quantity specifiers (`?`: optional, `+`: one or more, `*`: zero or
    more):

        my $config = Config::Abstraction->new(
            config_dirs => ['config'],
            checker     => <<'END_PROTOTYPE',
        database:
          host: hostname of the database server[HOSTNAME]
          port: '?<5432>port number[INTEGER]'
          user: database username
        END_PROTOTYPE
        );

    See [Config::Checker](https://metacpan.org/pod/Config%3A%3AChecker) for the full prototype syntax.

- `lazy`

    When set to a true value, all source discovery and file I/O are deferred until the first
    call to `get()`, `exists()`, `all()`, `explain_sources()`, `prefer_*()`,
    `merge_defaults()`, or any AUTOLOAD accessor.  This can reduce startup time in
    applications that construct a `Config::Abstraction` object before they know whether
    they will access it.

    **Differences from the default (eager) behaviour, and the debugging problems they cause:**

    - 1. `new()` always succeeds, even when no configuration exists.

        In eager mode, `new()` returns `undef` immediately when no files are found and no
        `data` was supplied, so a missing config is caught at the point of construction.
        In lazy mode, `new()` always returns a blessed object.  If the configuration
        directories do not exist, the files are missing, or the prefix is wrong, you will
        not find out until the first accessor call - which may be deep inside your business
        logic, far from where the object was created.

            # Problem: the typo in config_dirs goes unnoticed until runtime
            my $cfg = Config::Abstraction->new(
                config_dirs => ['/etc/myapp/conifg'],   # typo - directory does not exist
                lazy => 1,
            );
            # ... many lines later ...
            my $host = $cfg->get('database.host');      # silently returns undef here

    - 2. Schema validation errors appear at the wrong place in the call stack.

        When a `schema` is supplied, eager mode validates the merged configuration inside
        `new()` and throws immediately if the config does not match.  In lazy mode,
        validation is deferred to the first accessor call.  A schema violation therefore
        surfaces as an exception thrown by `get()` or `all()`, not by `new()`, and the
        stack trace points to the accessor call rather than the construction site.  If the
        object is created in one module and accessed in another, the error message can be
        very misleading.

    - 3. Environment variables and `@ARGV` are captured at access time, not construction time.

        The module reads `%ENV` and `@ARGV` during `_load_config()`.  In eager mode that
        happens in `new()`, so the configuration reflects the environment at the moment the
        object is built.  In lazy mode, any change to `%ENV` or `@ARGV` between `new()`
        and the first accessor call is silently picked up.  This makes test isolation harder:
        setting an environment variable _after_ constructing a lazy object will affect the
        values it returns, which is not the case with an eager object.

    - 4. File system state may change between construction and first use.

        Because lazy mode defers all I/O, the files that are read are those that exist at the
        moment of first access, not at the moment `new()` is called.  If a config file is
        written, deleted, or replaced between those two points (for example, by another
        process or test fixture), the object will silently use the new state.  An eager object
        is immune to this race.

    - 5. Errors from format parsers appear at accessor call sites.

        Malformed YAML, JSON, XML, or INI files emit a `carp` warning and are skipped during
        loading.  In eager mode those warnings appear near the program's startup.  In lazy mode
        they appear during the first accessor call, which can make it look as though a routine
        in your business logic is generating configuration warnings.

    **When to use lazy loading:** It is most useful when a `Config::Abstraction` object is
    created speculatively at module-load time and may never be accessed (for example, in a
    web framework where the config object is built for every request but some request paths
    never read it).  Avoid it when startup correctness is important, when you rely on
    `new()` returning `undef` to detect missing configuration, or when you use schema
    validation and need errors to point at the construction site.

If just one argument is given, it is assumed to be the name of a file.

## get(key)

Retrieve a configuration value using dotted key notation (e.g.,
`'database.user'`). Returns `undef` if the key doesn't exist or if
`key` is `undef`.

### EXAMPLE

    my $cfg = Config::Abstraction->new(
        data        => { database => { host => 'localhost', port => 5432 } },
        config_dirs => [],
    );

    my $host = $cfg->get('database.host');   # 'localhost'
    my $port = $cfg->get('database.port');   # 5432
    my $miss = $cfg->get('database.user');   # undef  -- key absent

### API SPECIFICATION

#### Input

    key  -- SCALAR  -- dotted key path (e.g. 'database.host').
                       C<undef> is allowed and returns C<undef> silently.

#### Output

    SCALAR or reference -- the value stored under C<key>, or C<undef> if absent.

### MESSAGES

    (none) -- missing keys return undef, no warning is raised.

### PSEUDOCODE

    if key is undef: return undef
    call _ensure_loaded
    if flatten mode: return config[key] (direct lookup)
    parts = split sep_char from key
    ref = config hashref
    for each part:
      if ref is not a HASH: return undef
      if part not in ref:   return undef
      ref = ref[part]
    return ref

## exists(key)

Test whether a configuration key is present, using dotted key notation
(e.g., `'database.user'`).  Returns `1` when the key exists (even if its
value is `undef`), `0` otherwise.  Returns `0` when `key` is `undef`.

### EXAMPLE

    my $cfg = Config::Abstraction->new(
        data        => { timeout => undef, retries => 3 },
        config_dirs => [],
    );

    $cfg->exists('timeout');   # 1 -- key present even though value is undef
    $cfg->exists('retries');   # 1
    $cfg->exists('missing');   # 0
    $cfg->exists(undef);       # 0

### API SPECIFICATION

#### Input

    key  -- SCALAR  -- dotted key path.  C<undef> returns C<0>.

#### Output

    boolean

### MESSAGES

    (none)

## all()

Returns the entire merged configuration as a hashref, or `undef` when no
configuration data was found.  When `flatten => 1` was given to the
constructor the keys are dotted strings (e.g. `'database.host'`); otherwise
the hash is nested.

The special key `config_path` within the returned hashref is an arrayref
listing every file that was loaded, in load order.

### EXAMPLE

    my $cfg = Config::Abstraction->new(
        data        => { host => 'localhost', port => 5432 },
        config_dirs => [],
    );

    my $all = $cfg->all();
    # { host => 'localhost', port => 5432, config_path => [] }

### API SPECIFICATION

#### Input

    (none)

#### Output

    HASHREF  -- the full merged config (includes C<config_path> key).
    undef    -- when the merged config is empty and no data was supplied.

### MESSAGES

    (none) -- returns undef silently when empty.

## explain\_sources()

Returns a hashref describing where each configuration key came from and in
what order the sources that set it were applied.

Each key of the returned hashref is a dotted key name (e.g. `'database.user'`).
The corresponding value is a hashref with two fields:

- `value`

    The final merged value for that key after all sources have been applied.

- `sources`

    An arrayref of hashrefs, ordered from lowest to highest precedence (i.e. the
    last element is always the winning source). Each entry has:

    - `type` -- one of `'data'`, `'file'`, `'env'`, or `'argv'`
    - `label` -- a human-readable identifier: a file path, an environment
    variable name (e.g. `'APP_DATABASE__USER'`), a CLI argument string, or
    `'constructor data argument'`
    - `value` -- what this source set the key to (may differ from `value`
    at the top level if a later source overrode it)

Keys set by exactly one source have a single-element `sources` list.
Keys whose value was never overridden will show the same `value` in both the
top-level field and the sole `sources` entry.

### USAGE EXAMPLE

    use Config::Abstraction;

    local $ENV{APP_HOST} = 'prod.example.com';

    my $cfg = Config::Abstraction->new(
        data        => { host => 'localhost', port => 5432 },
        config_dirs => ['/etc/myapp'],
    );

    use Data::Dumper;
    print Dumper( $cfg->explain_sources() );
    # {
    #   'host' => {
    #     value   => 'prod.example.com',
    #     sources => [
    #       { type => 'data', label => 'constructor data argument', value => 'localhost' },
    #       { type => 'env',  label => 'APP_HOST',                  value => 'prod.example.com' },
    #     ],
    #   },
    #   'port' => {
    #     value   => 5432,
    #     sources => [
    #       { type => 'data', label => 'constructor data argument', value => 5432 },
    #     ],
    #   },
    # }

### API SPECIFICATION

#### Input

None (instance method; takes no arguments beyond `$self`).

#### Output

HASHREF where each key is a dotted config key and each value is:

    {
        value   => SCALAR,
        sources => [
            {
                type  => 'data'|'file'|'env'|'argv',
                label => SCALAR,
                value => SCALAR,
            },
            ...
        ],
    }

## prefer\_env(key)

Return the value that an environment variable provided for `key`, bypassing
any later sources (e.g. CLI arguments) that may have overridden it.
Falls back to the normal merged value from `get(key)` when no environment
variable contributed to `key`.

### EXAMPLE

    local $ENV{APP_DATABASE__HOST} = 'env-host';
    my $host = $cfg->prefer_env('database.host');
    # Returns 'env-host' even if --APP_DATABASE__HOST=cli-host was also passed.

### API SPECIFICATION

#### Input

    key -- SCALAR -- dotted key path.

#### Output

    SCALAR  -- the env-layer value, or C<get(key)> when no env var set it.

## prefer\_file(key)

Return the value that a configuration file provided for `key`, bypassing
environment variables and CLI arguments that may have overridden it.
Falls back to the normal merged value from `get(key)` when no file
contributed to `key`.

### EXAMPLE

    my $host = $cfg->prefer_file('database.host');
    # Returns the file-sourced value even if APP_DATABASE__HOST is set.

### API SPECIFICATION

#### Input

    key -- SCALAR -- dotted key path.

#### Output

    SCALAR  -- the file-layer value, or C<get(key)> when no file set it.

## prefer\_data(key)

Return the value that the `data` constructor argument provided for `key`,
bypassing files, environment variables, and CLI arguments that may have
overridden it.
Falls back to the normal merged value from `get(key)` when `data` did not
contribute to `key`.

### EXAMPLE

    my $cfg = Config::Abstraction->new(
        data        => { timeout => 30 },
        config_dirs => ['/etc/myapp'],
    );
    my $t = $cfg->prefer_data('timeout');   # always 30, regardless of files/env

### API SPECIFICATION

#### Input

    key -- SCALAR -- dotted key path.

#### Output

    SCALAR  -- the data-layer value, or C<get(key)> when C<data> did not set it.

## prefer\_argv(key)

Return the value that a CLI argument provided for `key`.
Falls back to the normal merged value from `get(key)` when no CLI argument
contributed to `key`.

Because CLI arguments are the highest-precedence source, this method is
primarily useful for writing self-documenting code or for detecting whether
a key was explicitly supplied on the command line.

### EXAMPLE

    my $level = $cfg->prefer_argv('log.level');
    # Equivalent to $cfg->get('log.level') unless you specifically need to
    # confirm the value came from @ARGV.

### API SPECIFICATION

#### Input

    key -- SCALAR -- dotted key path.

#### Output

    SCALAR  -- the argv-layer value, or C<get(key)> when no CLI arg set it.

## encrypt\_value($plaintext)

Encrypt a plaintext string using the configured AES-256-GCM key and return an
`ENC[AES256GCM,...]` token suitable for storing in a configuration file.

Each call generates a fresh random nonce, so the same plaintext produces a
different token every time.  The token is authenticated (GCM tag); any
modification causes decryption to croak.

Requires [CryptX](https://metacpan.org/pod/CryptX) (`Crypt::AuthEnc::GCM`, `Crypt::PRNG`).

### EXAMPLE

    # Generate a token to paste into base.yaml:
    my $cfg = Config::Abstraction->new(
        encryption_key => $hex_key,
        config_dirs    => [],
        lazy           => 1,
    );
    my $token = $cfg->encrypt_value('s3cr3t_password');
    # ENC[AES256GCM,QkJCQkJCQkJCQkJCO6Gfb0o5jwqB1R...]

    # Or use config-dump from the command line:
    #   config-dump --encrypt-value 's3cr3t_password' --encryption-key $KEY

### API SPECIFICATION

#### Input

    plaintext  -- SCALAR  -- the string to encrypt.  May be empty.

#### Output

    SCALAR  -- the ENC[AES256GCM,...] token (always a printable ASCII string).

### MESSAGES

    "<class>: no encryption key configured ..." -- croak when no key is available.
    "<class>: CryptX (Crypt::AuthEnc::GCM) is required ..." -- croak when CryptX absent.

### PSEUDOCODE

    call _ensure_loaded
    key = _get_encryption_key() -- croak if undef
    load Crypt::AuthEnc::GCM and Crypt::PRNG -- croak if absent
    nonce = 12 random bytes
    gcm = new GCM('AES', key)
    gcm.iv_add(nonce)
    ciphertext = gcm.encrypt_add(plaintext)
    tag = gcm.encrypt_done()
    return "ENC[AES256GCM," + base64url(nonce + ciphertext + tag) + "]"

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

## Remote configuration directories (Newcastle Connection)

Any entry in `config_dirs` whose path begins with `/../` is treated as a
remote specification rather than a local directory:

    /../hostname/path/to/dir

The hostname and directory are extracted, and the same standard files searched
locally (`base.yaml`, `local.yaml`, `base.json`, etc.) are fetched from
the remote machine via [File::Slurp::Remote](https://metacpan.org/pod/File%3A%3ASlurp%3A%3ARemote) over SSH.

When the hostname resolves to the local machine -- `localhost`, `127.0.0.1`,
`::1`, or the value returned by `Sys::Hostname::hostname()` (checked as
both fully-qualified and short form, case-insensitively) -- the `/../host/`
wrapper is silently unwrapped and the enclosed path is processed through the
normal local file pipeline instead.  No SSH connection is made.  This means a
configuration written for a shared remote host degrades gracefully when run on
that host itself:

    # On any other machine: fetches /etc/myapp over SSH
    # On cfg-server itself: reads /etc/myapp from disk directly
    config_dirs => ['/../cfg-server/etc/myapp']

Remote directories participate in the normal merge pipeline and can be freely
mixed with local ones:

    my $cfg = Config::Abstraction->new(
        config_dirs => [
            '/etc/myapp',                        # local
            '/../deploy@cfg-server/etc/myapp',   # remote via SSH (local on cfg-server)
        ],
    );

SSH authentication is handled by the system SSH client.
No extra constructor options are required; use your SSH agent or
`~/.ssh/config` for host-specific settings.

[File::Slurp::Remote](https://metacpan.org/pod/File%3A%3ASlurp%3A%3ARemote) must be installed for remote directories to work.
If it is absent the directory is silently skipped and a warning is emitted.

### Why `/../` (the Newcastle Connection convention)

Several syntaxes were considered for marking a `config_dirs` entry as remote.
Each alternative was rejected for a concrete reason:

- `hostname/path` -- ambiguous

    Indistinguishable from a relative local directory named `hostname`.
    The module cannot tell at parse time whether `myserver/etc` is a two-level
    local path or a remote specification.

- `hostname:/path` -- collides with Windows drive letters

    The `X:\` drive-letter convention on Windows uses exactly the same
    `letter:` prefix.  A single-letter hostname would be misidentified as a
    drive, and path-normalisation code on Windows would mangle it.

- `file://hostname/path` -- wrong semantics

    RFC 8089 defines `file://` as a reference to a **local** file.
    `file:///etc/passwd` (three slashes, empty host) is the canonical local form;
    `file://hostname/path` is reserved for the host component but is explicitly
    discouraged for general use and is not understood by most tooling as meaning
    SSH.

- `ssh://hostname/path` -- requires URI parsing

    Introduces a dependency on URI parsing (or a bespoke prefix check) and
    implies a specific transport.  `File::Slurp::Remote` already abstracts
    the transport; encoding `ssh://` in the path would be misleading if a future
    version of that module supports other transports such as `rsync://`.

- `/../hostname/path` -- the Newcastle Connection

    The Newcastle Connection (Brownbridge, Dion, Elsworth, 1982) is a distributed
    Unix convention in which the token `/../` at the start of a pathname means
    "leave the local namespace and enter the named remote host".
    It works because `/../` **cannot exist** as a real filesystem path:
    `..` from the root directory resolves back to the root on every POSIX system,
    so `/../` always denotes the root itself, never a child of the root.
    No pathname-normalisation step, `chdir`, or filesystem traversal will ever
    produce a path that legitimately begins with `/../`, which means the prefix
    is a permanent, collision-free sentinel that requires only a regex to detect.

The Newcastle Connection prefix is therefore the only choice that is:

- unambiguous on all platforms (POSIX and Windows)
- impossible to produce accidentally from a real local path
- detectable with a single `m{^\Q/../\E}` regex, no URI parser needed
- transport-neutral (the hostname is passed to whatever remote driver is installed)

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
        flatten => 1,
        sep_char => '_'
    );

    my $user = $config->database_user();        # returns 'alice'

    # or
    $user = $config->database()->{'user'};      # returns 'alice'

    # Attempting to call a nonexistent key
    my $foo = $config->nonexistent_key();       # dies with error

# ENCRYPTED VALUES

Config::Abstraction supports transparent AES-256-GCM encryption of individual
configuration values.  This lets you store secrets (passwords, API keys, tokens)
in config files without exposing them as plaintext, even when those files are
committed to version control.

## Quick start

**Step 1 -- generate a key:**

    # 32 random bytes, encoded as 64 hex chars
    perl -e 'use Crypt::PRNG qw(random_bytes); use MIME::Base64 qw(encode_base64url);
             print encode_base64url(random_bytes(32)), "\n"'

Store the result in an environment variable or a key file (outside version control):

    export ENCRYPTION_KEY=<the 44-char base64url output>

**Step 2 -- encrypt a secret value:**

    perl -MConfig::Abstraction -e '
      my $cfg = Config::Abstraction->new(data => {});
      print $cfg->encrypt_value("my_secret_password"), "\n";
    '

This prints something like:

    ENC[AES256GCM,QkJCQkJCQkJCQkJCO6Gfb0o5...]

**Step 3 -- paste the token into your config file:**

    # config/base.yaml
    database:
      host: db.example.com
      user: myapp
      password: 'ENC[AES256GCM,QkJCQkJCQkJCQkJCO6Gfb0o5...]'

**Step 4 -- load and use normally:**

    my $cfg = Config::Abstraction->new(config_dirs => ['config']);
    # $cfg->get('database.password') returns 'my_secret_password' -- already decrypted

## Key configuration

The encryption key is resolved in this order (first match wins):

- 1. `encryption_key` constructor option (raw bytes, hex, or base64)
- 2. `{env_prefix}ENCRYPTION_KEY` environment variable (default: `APP_ENCRYPTION_KEY`)
- 3. `ENCRYPTION_KEY` environment variable
- 4. File at `encryption_key_file` constructor option
- 5. File at `{env_prefix}ENCRYPTION_KEY_FILE` environment variable
- 6. File at `ENCRYPTION_KEY_FILE` environment variable

The key file should contain the key on its first line in any supported format.
**Never commit the key to version control.**

## Token format

    ENC[AES256GCM,<base64url(nonce || ciphertext || tag)>]

- `AES256GCM` -- AES-256 in GCM mode (authenticated encryption)
- Nonce -- 12 random bytes (fresh per encryption, never reused)
- GCM authentication tag -- 16 bytes; any modification causes decryption to croak
- Base64url encoding -- URL-safe alphabet, no padding ambiguity

## Behaviour when no key is configured

If no key is found, `ENC[...]` tokens are left as literal strings.  This means
the feature is purely opt-in: existing deployments without a key configured are
unaffected.

## Requirements

[CryptX](https://metacpan.org/pod/CryptX) (`Crypt::AuthEnc::GCM`, `Crypt::PRNG`) must be installed:

    cpanm CryptX

# COMMON PITFALLS

## 1. new() returns undef when no configuration is found

`new()` returns `undef`, not a blessed object, when no configuration data is
found and no `data` argument was supplied.  Every caller must check the return value.

    my $cfg = Config::Abstraction->new(config_dirs => ['/etc/myapp']);
    die "No configuration found" unless defined $cfg;
    my $host = $cfg->get('database.host');   # safe

Forgetting the check leads to a cryptic "Can't call method on undef" error later,
with a stack trace that points to `get()` rather than to the missing config file.

## 2. merge\_defaults() requires a named argument, not a bare hashref

    # WRONG -- Params::Get fast-path returns the whole config unchanged
    my $merged = $cfg->merge_defaults(\%my_defaults);

    # RIGHT
    my $merged = $cfg->merge_defaults(defaults => \%my_defaults);

With the first form, `Params::Get` treats the single hashref as the entire
parameter bag and returns the full config without merging anything.

## 3. Shallow merge in merge\_defaults() silently drops nested keys from defaults

Without `merge => 1`, `merge_defaults()` uses a plain Perl hash merge
(`{ %defaults, %config }`) at the top level.  If the config contains a nested hash
for a key, it entirely replaces the corresponding nested hash in your defaults - any
keys that exist only in the defaults' nested hash are silently discarded.

    my $cfg = Config::Abstraction->new(
        data        => { db => { host => 'localhost', port => 5432 } },
        config_dirs => [],
    );

    my $merged = $cfg->merge_defaults(defaults => { db => { user => 'guest' } });
    # $merged->{db}{user} is UNDEF -- the whole 'db' hash was replaced by the config's version

    # To combine nested keys from both sides, pass merge => 1:
    my $merged = $cfg->merge_defaults(defaults => { db => { user => 'guest' } }, merge => 1);
    # $merged->{db}{user} is 'guest', $merged->{db}{host} is 'localhost'

## 4. undef from a higher-priority source permanently wins

`Hash::Merge` LEFT\_PRECEDENT means that an explicit `undef` (YAML `~`) in a
higher-priority source overrides a real value in a lower-priority source, including
when the lower-priority value is defined.

    # base.yaml:  timeout: 30
    # local.yaml: timeout: ~

    my $t = $cfg->get('timeout');   # undef -- local.yaml's null wins over base.yaml

This is intentional: it lets a local config deliberately unset a value.  If you
want to detect whether a key was explicitly nulled versus simply absent, use
`explain_sources()` and inspect the `sources` list.

## 5. Double underscore vs. single underscore in environment variable names

Single underscores are part of the key name; double underscores create a nesting level.

    APP_LOG_LEVEL=debug       => key 'log_level'   (single underscore, flat key)
    APP_DATABASE__HOST=db     => key 'database.host' (double underscore, nested)
    APP_API__RATE_LIMIT=100   => key 'api.rate_limit' (double underscore + single)

A common mistake is using single underscores expecting nested keys:

    APP_DATABASE_HOST=db   # produces key 'database_host', NOT 'database.host'

## 6. Using AUTOLOAD requires sep\_char set to '\_'

AUTOLOAD translates method names to config keys using `sep_char`.  The default
`sep_char` is `'.'`, but method names cannot contain dots.  Set `sep_char => '_'`
to use AUTOLOAD, and be aware that this makes single underscores into hierarchy separators.

    my $cfg = Config::Abstraction->new(
        data    => { database => { host => 'localhost' } },
        sep_char => '_',
        config_dirs => [],
    );
    my $host = $cfg->database_host();   # works
    my $bad  = $cfg->no_such_key();    # dies: No such config key 'no_such_key'

## 7. Absolute config\_file paths require an empty or omitted config\_dirs

On Unix, `File::Spec->catfile('/etc', '/absolute/path.yaml')` concatenates the
two strings instead of letting the absolute path take over, producing a wrong path.
When `config_file` is an absolute path, either omit `config_dirs` entirely
(the constructor sets it to `['']` automatically) or pass `config_dirs => ['']`
explicitly.

    # WRONG on Unix -- produces '/etc/etc/myapp/app.yaml'
    Config::Abstraction->new(
        config_file => '/etc/myapp/app.yaml',
        config_dirs => ['/etc'],
    );

    # RIGHT
    Config::Abstraction->new( config_file => '/etc/myapp/app.yaml' );

## 8. Tests must isolate from the developer's real config files

A call to `new()` without `config_dirs` will scan `/etc`, `~/.conf`,
`~/.config`, and other default locations and load any `base.yaml` or
`local.yaml` it finds there.  In a test suite this injects real host
configuration into your test object, causing non-deterministic failures.

Always pass `config_dirs => []` in tests that use only in-memory `data`:

    my $cfg = Config::Abstraction->new(
        data        => { key => 'value' },
        config_dirs => [],              # do not scan the filesystem
    );

## 9. lazy => 1 defers errors until the first accessor call

With `lazy => 1`, `new()` always returns a blessed object - it cannot return
`undef` for a missing config, and any schema validation errors surface at the first
`get()` or `all()` call rather than at construction time.  See the `lazy`
option documentation in ["new"](#new) for the full list of debugging implications.

# VERSION HISTORY

Notable changes by release.  Full details are in the `Changes` file.

- **0.40** (unreleased)

    TOML file support (`*.toml`) via `TOML::Tiny`; `base.toml` and `local.toml`
    are now discovered automatically alongside the YAML/JSON/XML/INI equivalents,
    and TOML is also tried in the all-parsers chain for extensionless `config_file`
    entries.
    Lazy loading (`lazy => 1` constructor option) defers all source discovery
    and file I/O until the first accessor call.
    New `explain_sources()` method returns a per-key audit trail showing every
    source that contributed to a value, in precedence order.
    New `prefer_env()`, `prefer_file()`, `prefer_data()`, and `prefer_argv()`
    shortcut methods return the value from a specific source layer without re-ordering.
    Fixed `merge_defaults()` permanently mutating the internal config hash
    (now works on a shallow copy).
    Fixed `Hash::Merge` clone-behaviour global state leaking between calls
    (`get_clone_behavior()` is now saved and restored, preventing "Can't store CODE
    items" crashes when `data` contains coderefs).
    Newcastle Connection remote configuration: `config_dirs` entries beginning with
    `/../hostname/path` are fetched over SSH via [File::Slurp::Remote](https://metacpan.org/pod/File%3A%3ASlurp%3A%3ARemote).
    Local-host entries (`/../localhost/`, `/../127.0.0.1/`, etc.) are short-circuited
    to a plain local read - no SSH connection is made.

- **0.39** (2026-05-24)

    Disabled `Data::Reuse::fixate()` - behaviour differed between Linux and macOS
    in a way that could not be resolved portably.

- **0.38** (2026-05-20)

    Fixed corruption of coderefs and blessed objects passed via the `data` argument
    (added `_is_plain_scalar()` guard in the YAML value-munging loop).
    Fixed `exists()` to return explicit `0` rather than empty string in flat mode.
    Fixed `Data::Reuse::fixate()` crash in `get()`.
    Fixed circular initialisation crash when the `logger` option is provided.
    Documented the `defaults` argument to `new()`.

- **0.36** (2025-10-15)

    Added `exists()` method.
    Files that fail to parse now emit a warning and are skipped rather than aborting
    construction.

- **0.34** (2025-09-05)

    Added `bin/config-dump` CLI tool.
    Schema validation via `Params::Validate::Strict` (`schema` option).

- **0.25** (2025-05-15)

    Added `merge_defaults()` `merge` option (recursive Hash::Merge merge).

- **0.20** (2025-05-06)

    Added `merge_defaults()`.

- **0.19** (2025-05-06)

    The `data` constructor argument now sets default values that are overridden by files.

- **0.13** (2025-04-22)

    Added `data` option to `new()`.
    Added AUTOLOAD support for method-style key access.
    Added `sep_char` option.

- **0.06** (2025-04-09)

    `config_path` key in `all()` output lists the files actually loaded.
    Format drivers are now lazy-loaded (only `require`d when a file of that format is
    found).

- **0.01** (2025-04-07)

    First release.

# LIMITATIONS

- **No separator escaping**

    The separator character (`sep_char`, default `.`) cannot be embedded in a key name.
    A key that literally contains a dot cannot be accessed via `get()` when `sep_char` is
    the default.  Workaround: set `sep_char` to a character not present in any key.

- **Data::Reuse fixation disabled**

    The `Data::Reuse::fixate()` call inside `get()` is currently a no-op because the
    behaviour of `Crypt::Storable::dclone` differs between Linux and macOS in a way
    that cannot be resolved portably (RT#100461).  Hash values returned by `get()` are
    mutable references, not read-only copies.

- **Windows environment variable case sensitivity**

    On Windows, environment variable names are case-insensitive at the OS level but
    case-sensitive in `%ENV` as seen by Perl.  Overriding config keys via environment
    variables may silently fail if the case does not match exactly.

- **AUTOLOAD requires sep\_char set to '\_'**

    AUTOLOAD method dispatch converts underscores to key separators.  If `sep_char` is
    the default `'.'`, AUTOLOAD cannot reach nested keys because Perl method names cannot
    contain dots.

- **Remote directory TOML support requires File::Slurp::Remote**

    TOML files in Newcastle Connection remote directories are only fetched when the
    `File::Slurp::Remote` module is installed.  Without it, remote directories are
    skipped entirely regardless of file format.

# BUGS

It should be possible to escape the separator character either with backslashes or quotes.

Due to the case-insensitive nature of environment variables on Windows,
it may be challenging to override values using environment variables on that platform.

# REPOSITORY

[https://github.com/nigelhorne/Config-Abstraction](https://github.com/nigelhorne/Config-Abstraction)

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

- [File::Slurp::Remote](https://metacpan.org/pod/File%3A%3ASlurp%3A%3ARemote)

        Used to fetch configuration from remote hosts when C<config_dirs> contains
        Newcastle Connection paths (C</../hostname/path>).

- [Config::Any](https://metacpan.org/pod/Config%3A%3AAny)
- [Config::Auto](https://metacpan.org/pod/Config%3A%3AAuto)
- [Data::Reuse](https://metacpan.org/pod/Data%3A%3AReuse)

    Used to `fixate()` elements when installed, unless `no-fixate` is given

- [Hash::Merge](https://metacpan.org/pod/Hash%3A%3AMerge)
- [Log::Abstraction](https://metacpan.org/pod/Log%3A%3AAbstraction)
- [Test Dashboard](https://nigelhorne.github.io/Config-Abstraction/coverage/)
- Development version on GitHub [https://github.com/nigelhorne/Config-Abstraction](https://github.com/nigelhorne/Config-Abstraction)

# AUTHOR

Nigel Horne, `<njh at nigelhorne.com>`

# FORMAL SPECIFICATION

## get

    get : Config x Key → Value ∪ {⊥}
    get(c, k) ≜ if k = ⊥ then ⊥
                else lookup(c.config, split(c.sep_char, k))
    lookup(h, [])      ≜ h
    lookup(h, p:rest)  ≜ if p ∉ dom(h) then ⊥
                          else lookup(h[p], rest)

## encrypt\_value

    encrypt_value : Config x Plaintext → Token
    encrypt_value(c, p) ≜
      let k  = resolve_key(c)  where k ≠ ⊥
      let n  ~ Uniform(Bytes^12)            -- fresh random nonce
      let ct = AES256GCM_enc(k, n, p)
      let t  = GCM_tag(k, n, p)
      in "ENC[AES256GCM," || base64url(n || ct || t) || "]"

## exists

    exists : Config x Key → {0, 1}
    exists(c, k) ≜ if k = ⊥ then 0
                   else 1 if lookup(c.config, split(c.sep_char, k)) ≠ ⊥
                   else 0

## all

    all : Config → HashRef ∪ {⊥}
    all(c) ≜ if |dom(c.config)| = 0 then ⊥ else c.config

# LICENCE AND COPYRIGHT

Copyright 2025-2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.
