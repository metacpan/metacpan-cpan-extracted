package Config::Abstraction;

use strict;
use warnings;

use Carp;
use JSON::MaybeXS 'decode_json';	# Doesn't behave well with require
use File::Slurp qw(read_file);
use File::Spec;
use Hash::Merge qw(merge);
use Params::Get 0.15;
use Params::Validate::Strict 0.37;
use Scalar::Util;
use Readonly;

# AES-256-GCM constants — do not change without updating _decrypt_enc_value and encrypt_value
Readonly::Scalar my $_AES_NONCE_SIZE  => 12;	# GCM standard nonce length in bytes
Readonly::Scalar my $_AES_TAG_SIZE    => 16;	# GCM authentication tag length in bytes
Readonly::Scalar my $_AES_KEY_SIZE    => 32;	# AES-256 key length in bytes
Readonly::Scalar my $_ENC_PAYLOAD_MIN => 28;	# shortest valid payload: nonce(12) + tag(16)
Readonly::Scalar my $_HEX_KEY_LEN     => 64;	# 32 bytes expressed as hexadecimal
Readonly::Scalar my $_B64_KEY_MIN     => 43;	# minimum base64/base64url chars for 32 bytes
Readonly::Scalar my $_B64_KEY_MAX     => 44;	# maximum base64/base64url chars for 32 bytes


=head1 NAME

Config::Abstraction - Merge and manage configuration data from different sources

=head1 VERSION

Version 0.40

=cut

our $VERSION = '0.40';

=head1 SYNOPSIS

=head2 Pattern 1: Environment overrides file overrides in-code defaults

The most common pattern for twelve-factor-style apps.
The C<data> argument supplies defaults, a YAML file supplies site configuration,
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

=head2 Pattern 2: Command-line arguments override everything

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

=head2 Pattern 3: Multi-file layering (base + local override)

Separates shared defaults from machine-specific tweaks.
Every developer has a C<base.yaml>; only the production server has C<local.yaml>.

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

=head1 DESCRIPTION

C<Config::Abstraction> is a flexible configuration management layer that sits above C<Config::*> modules.
It provides a simple way to layer multiple configuration sources with predictable merge order.
It lets you define sources such as:

=over 4

=item * Perl hashes (in-memory defaults or dynamic values)

=item * Environment variables (with optional prefixes)

=item * Configuration files (YAML, JSON, INI, or plain key=value)

=item * Command-line arguments

=back

Sources are applied in the order they are provided. Later sources override
earlier ones unless a key is explicitly set to C<undef> in the later source.

In addition to using drivers to load configuration data from multiple file
formats (YAML, JSON, XML, and INI),
it also allows levels of configuration, each of which overrides the lower levels.
So, it also integrates environment variable
overrides and command line arguments for runtime configuration adjustments.
This module is designed to help developers manage layered configurations that can be loaded from files and overridden at run-time for debugging,
offering a modern, robust and dynamic approach
to configuration management.

=head2 Merge Precedence

Sources are applied in the order shown below.  Each row wins over every row
above it.  When the same key appears in multiple sources, the highest-priority
source always determines the final value - including when that value is C<undef>.

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

The active environment is set by the C<environment> constructor option, or
auto-detected from C<{env_prefix}ENV> (e.g. C<APP_ENV>), C<PLACK_ENV>, or
C<NODE_ENV>.  When no environment is configured, rows 3 and 5 are skipped.

Within the file tier (rows 2-7), later files override earlier files using
C<Hash::Merge> LEFT_PRECEDENT: every key in the later file wins over the same
key in an earlier file, even when the later value is C<undef> (YAML C<~>).
Nested hashes are merged recursively, so a C<local.yaml> that only sets
C<database.host> will not erase C<database.port> from C<base.yaml>.

  Example - what wins for the key C<database.host> when APP_ENV=prod:

  data              =>  'localhost'              (overridden by base.yaml)
  base.yaml         =>  'db.example.com'         (overridden by base.prod.yaml)
  base.prod.yaml    =>  'db.prod.example.com'    (overridden by local.yaml)
  local.yaml        =>  'db.local.example.com'   (overridden by local.prod.yaml)
  local.prod.yaml   =>  'db.prod-local.example.com'  (overridden by $APP_DATABASE__HOST)
  $APP_DATABASE__HOST  =>  'db.override.example.com'    <-- this wins

=head2 KEY FEATURES

=over 4

=item * Multi-Format Support

Supports configuration files in YAML, JSON, XML, and INI formats.
Automatically merges configuration data from these different formats,
allowing hierarchical configuration management.

=item * Environment Variable Overrides

Allows environment variables to override values in the configuration files.
By setting environment variables with a specific prefix (default: C<APP_>),
values in the configuration files can be dynamically adjusted without modifying
the file contents.

=item * Flattened Configuration Option

Optionally supports flattening the configuration structure. This converts deeply
nested configuration keys into a flat key-value format (e.g., C<database.user>
instead of C<database-E<gt>{user}>). This makes accessing values easier for
applications that prefer flat structures or need compatibility with flat
key-value stores.

=item * Layered Configuration

Supports merging multiple layers of configuration files. For example, you can
have a C<base.yaml> configuration file that provides default values, and a
C<local.yaml> (or C<local.json>, C<local.xml>, etc.) file that overrides
specific values. This allows for environment-specific configurations while
keeping defaults intact.

=item * Merge Strategy

The module merges the configuration data intelligently, allowing values in more
specific files (like C<local.yaml>, C<local.json>, C<local.xml>, C<local.ini>)
to override values in base files. This enables a flexible and layered configuration
system where you can set defaults and override them for specific environments.

=item * Error Handling

Includes error handling for loading configuration files.
If any file fails to
load (e.g., due to syntax issues), the module will throw descriptive error
messages to help with debugging.

=item * Centralized Configuration Management

Supports remote configuration management files,
so that configuration on remote machines can be centrally managed.

=back

=head2 SUPPORTED FILE FORMATS

=over 4

=item * YAML (C<*.yaml>, C<*.yml>)

Loaded with C<YAML::XS>.

=item * JSON (C<*.json>)

Loaded with C<JSON::MaybeXS>.

=item * XML (C<*.xml>)

Loaded with C<XML::Simple> (preferred) or C<XML::PP> (fallback).

=item * INI (C<*.ini>)

Loaded with C<Config::IniFiles>.

=item * TOML (C<*.toml>)

Loaded with C<TOML::Tiny>, which implements TOML 1.0.  TOML is a good choice
for human-editable configuration because its syntax is unambiguous: all values
are typed, strings must be quoted, and nesting uses C<[section]> headers or
dotted keys rather than indentation.

  # Example: config/base.toml
  [database]
  host   = "db.example.com"
  port   = 5432
  user   = "app"

  [cache]
  ttl    = 300
  debug  = false

C<base.toml> and C<local.toml> are discovered automatically in C<config_dirs>;
C<local.toml> has higher precedence than C<base.toml>, following the same
layering rules as all other formats.  TOML is also tried as a fallback parser
in the all-parsers chain used for extensionless C<config_file> entries.

If C<TOML::Tiny> is not installed, TOML files are silently skipped with a
C<carp> warning.

=back

=head2 ENVIRONMENT VARIABLE HANDLING

Configuration values can be overridden via environment variables. Environment variables use double underscores (__) to denote nested configuration keys and single underscores remain as part of the key name under the prefix namespace.

For example:

  APP_DATABASE__USER becomes database.user (nested structure)

    $ export APP_DATABASE__USER="env_user"

will override any value set for `database.user` in the configuration files.

  APP_LOGLEVEL becomes APP.loglevel (flat under prefix namespace)

  APP_API__RATE_LIMIT becomes api.rate_limit (mixed usage)

This allows you to override both top-level and nested configuration values using environment variables.

Configuration values can be overridden via the command line (C<@ARGV>).
For instance, if you have a key in the configuration such as C<database.user>,
you can override it by adding C<"--APP_DATABASE__USER=other_user_name"> to the command line arguments.
This will override any value set for C<database.user> in the configuration files.

=head2 EXAMPLE CONFIGURATION FLOW

=over 4

=item 1. Data Argument

The data passed into the constructor via the C<data> argument is the starting point.
Essentially,
this contains the default values.

=item 2. Loading Files

The module then looks for configuration files in the specified directories.
It loads the following files in order of preference:
C<base.yaml>, C<local.yaml>, C<base.json>, C<local.json>, C<base.xml>,
C<local.xml>, C<base.ini>, and C<local.ini>.

If C<config_file> or C<config_files> is set, those files are loaded last.

If no C<config_dirs> is given, try hard to find the files in various places.

The value of C<config_dirs> can be overridden at runtime by the environment variable CONFIG_DIR
(note that is just one directory, hence it's CONFIG_DIR not CONFIG_DIRS).

=item 3. Merging and Resolving

The module merges the contents of these files, with more specific configurations
(e.g., C<local.*>) overriding general ones (e.g., C<base.*>).

=item 4. Environment Overrides

After loading and merging the configuration files,
the environment variables are
checked and used to override any conflicting settings.

=item 5. Command Line

Next, the command line arguments are checked and used to override any conflicting settings.

=item 6. Accessing Values

Values in the configuration can be accessed using a dotted notation
(e.g., C<'database.user'>), regardless of the file format used.

=back

=head1 METHODS

=head2 new

Constructor for creating a new configuration object.

Options:

=over 4

=item * C<config_dirs>

An arrayref of directories to look for configuration files
(default: C<$CONFIG_DIR>, C<$HOME/.conf>, C<$HOME/config>, C<$HOME/conf>, C<$DOCUMENT_ROOT/conf>, C<$DOCUMENT_ROOT/../conf>, C<conf>).

For centralised configuration management,
entries beginning with C</../> are treated as remote specifications using the
Newcastle Connection convention -- see L</Remote configuration directories (Newcastle Connection)>.

=item * C<config_file>

Points to a configuration file of any format.

=item * C<config_files>

An arrayref of files to look for in the configuration directories.
Put the more important files later,
since later files override earlier ones.

Considers the files C<default> and C<$script_name> before looking at C<config_file> and C<config_files>.

=item * C<data>

A hash ref of default data to prime the configuration with.
These are applied before loading
other sources and can be overridden by later sources or by explicitly passing
options directly to C<new>.

  $config = Config::Abstraction->new(
      data => {
          log_level => 'info',
          retries => 3,
      }
  );

=item * C<defaults>

A hash reference that provides default values for the object's own attributes (such as C<config_dirs>, C<logger>, C<flatten>, etc.).
If this option is supplied,
the object is initialized using the keys in this hash as the base;
any other options passed directly to C<new()> (aside from C<env_prefix>) are ignored.
This allows you to pre-define a standard configuration profile for the object itself.
Note that C<defaults> is distinct from the C<data> option - C<data> supplies the initial configuration values that will be merged with files, environment, and command line,
while C<defaults> sets the object's internal parameters.
The C<env_prefix> value,
if provided as a top-level argument,
still takes precedence over any C<env_prefix> that might exist inside the C<defaults> hash.

=item * C<encryption_key>

A 256-bit (32-byte) AES key used to transparently decrypt C<ENC[...]> values found in any
configuration source after the full merge.  The key may be supplied as:

=over 4

=item 32 raw bytes

=item 64 lowercase or uppercase hex characters

=item 44 Base64 or Base64url characters (standard or URL-safe alphabet, with or without trailing C<=>)

=back

If no key is configured (and neither C<encryption_key_file> nor the corresponding
environment variables are set), C<ENC[...]> tokens are left as literal strings.
Decryption requires L<CryptX> (C<Crypt::AuthEnc::GCM>); if that module is absent a
C<croak> is raised when an encrypted value is encountered.

See L</ENCRYPTED VALUES> for the full workflow.

=item * C<encryption_key_file>

Path to a file whose first line contains the encryption key in any of the formats accepted
by C<encryption_key>.  Takes precedence over the C<ENCRYPTION_KEY_FILE> and
C<{env_prefix}ENCRYPTION_KEY_FILE> environment variables, but is overridden by a key
supplied directly via C<encryption_key>.

=item * C<env_prefix>

A prefix for environment variable keys and comment line options, e.g. C<MYAPP_DATABASE__USER>,
(default: C<'APP_'>).

=item * C<environment>

The name of the active deployment environment (e.g. C<'dev'>, C<'staging'>, C<'prod'>).
When set, config files named C<base.{env}.*> are loaded immediately after their C<base.*>
equivalents, and C<local.{env}.*> files are loaded immediately after C<local.*> files,
giving two additional override tiers at no cost to the base configuration.

  my $cfg = Config::Abstraction->new(
      config_dirs => ['config'],
      environment => 'prod',          # loads base.prod.yaml, local.prod.yaml, ...
  );

If C<environment> is not given, the value is auto-detected in this order:

=over 4

=item 1. C<{env_prefix}ENV> environment variable (e.g. C<APP_ENV>)

=item 2. C<PLACK_ENV>

=item 3. C<NODE_ENV>

=back

When none of these is set, the environment-specific tiers are silently skipped.
The environment name must contain only ASCII letters, digits, hyphens, and underscores
(matched against C</^[A-Za-z0-9_\-]+$/>); any other value causes a C<croak>.

=item * C<file>

Synonym for C<config_file>

=item * C<flatten>

If true, returns a flat hash structure like C<{database.user}> (default: C<0>) instead of C<{database}{user}>.
`
=item * C<level>

Level for logging.

=item * C<logger>

Used for warnings and traces.
It can be an object that understands warn() and trace() messages,
such as a L<Log::Log4perl> or L<Log::Any> object,
a reference to code,
a reference to an array,
or a filename.

=item * C<path>

A synonym of C<config_dirs>.

=item * C<sep_char>

The separator in keys.
The default is a C<'.'>,
as in dotted notation,
such as C<'database.user'>.

=item * C<schema>

A L<Params::Validate::Strict> compatible schema to validate the configuration file against.

=item * C<validators>

A hashref mapping dotted config keys to validation rules.  Each rule is applied to the
corresponding value in the merged configuration immediately after all sources have been
merged (or on first access when C<lazy> is set).  A validation failure croaks.

Each rule may be one of:

=over 4

=item A type name string

  validators => {
      'database.port' => 'integer',
      'app.name'      => 'string',
      'price'         => 'number',
      'enabled'       => 'boolean',
      'tags'          => 'array',
      'settings'      => 'hash',
  }

Supported types: C<integer> (matches C</^-?\d+$/> -- no decimal point),
C<number> or C<float> (C<Scalar::Util::looks_like_number>), C<boolean>
(C<0>, C<1>, C<true>, C<false>, C<yes>, C<no> -- case-insensitive),
C<string> (any defined non-reference scalar), C<array> (arrayref),
C<hash> (hashref).

=item A compiled regular expression

  validators => {
      'log.level' => qr/^(?:debug|info|warn|error|fatal)$/i,
      'app.name'  => qr/^\w[\w\-]{1,63}$/,
  }

The value must be defined and must match the regex.

=item A coderef

  validators => {
      'database.port' => sub { my $v = shift; defined($v) && $v >= 1 && $v <= 65535 },
  }

Called with the value as its only argument.  Must return a true value; otherwise the
constructor croaks.

=item A hashref combining multiple constraints

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

Keys: C<type> (type-name string as above), C<pattern> (compiled regex), C<min> (numeric
lower bound, inclusive), C<max> (numeric upper bound, inclusive), C<required> (if true,
the key must exist and its value must be defined).

=back

All constraint types may be freely combined: specifying both C<type> and C<pattern>
requires the value to satisfy both.

=item * C<checker>

A prototype string (YAML) or hashref passed to L<Config::Checker> for template-based
structural validation.  C<Config::Checker> must be installed; if it is absent a C<carp>
warning is emitted and validation is skipped.

The prototype mirrors the expected config structure.  Keys and values can carry type
annotations (C<[INTEGER]>, C<[PATH]>, C<[HOSTNAME]>, ...), custom code checks
(C<{...}>), and quantity specifiers (C<?>: optional, C<+>: one or more, C<*>: zero or
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

See L<Config::Checker> for the full prototype syntax.

=item * C<lazy>

When set to a true value, all source discovery and file I/O are deferred until the first
call to C<get()>, C<exists()>, C<all()>, C<explain_sources()>, C<prefer_*()>,
C<merge_defaults()>, or any AUTOLOAD accessor.  This can reduce startup time in
applications that construct a C<Config::Abstraction> object before they know whether
they will access it.

B<Differences from the default (eager) behaviour, and the debugging problems they cause:>

=over 4

=item 1. C<new()> always succeeds, even when no configuration exists.

In eager mode, C<new()> returns C<undef> immediately when no files are found and no
C<data> was supplied, so a missing config is caught at the point of construction.
In lazy mode, C<new()> always returns a blessed object.  If the configuration
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

=item 2. Schema validation errors appear at the wrong place in the call stack.

When a C<schema> is supplied, eager mode validates the merged configuration inside
C<new()> and throws immediately if the config does not match.  In lazy mode,
validation is deferred to the first accessor call.  A schema violation therefore
surfaces as an exception thrown by C<get()> or C<all()>, not by C<new()>, and the
stack trace points to the accessor call rather than the construction site.  If the
object is created in one module and accessed in another, the error message can be
very misleading.

=item 3. Environment variables and C<@ARGV> are captured at access time, not construction time.

The module reads C<%ENV> and C<@ARGV> during C<_load_config()>.  In eager mode that
happens in C<new()>, so the configuration reflects the environment at the moment the
object is built.  In lazy mode, any change to C<%ENV> or C<@ARGV> between C<new()>
and the first accessor call is silently picked up.  This makes test isolation harder:
setting an environment variable I<after> constructing a lazy object will affect the
values it returns, which is not the case with an eager object.

=item 4. File system state may change between construction and first use.

Because lazy mode defers all I/O, the files that are read are those that exist at the
moment of first access, not at the moment C<new()> is called.  If a config file is
written, deleted, or replaced between those two points (for example, by another
process or test fixture), the object will silently use the new state.  An eager object
is immune to this race.

=item 5. Errors from format parsers appear at accessor call sites.

Malformed YAML, JSON, XML, or INI files emit a C<carp> warning and are skipped during
loading.  In eager mode those warnings appear near the program's startup.  In lazy mode
they appear during the first accessor call, which can make it look as though a routine
in your business logic is generating configuration warnings.

=back

B<When to use lazy loading:> It is most useful when a C<Config::Abstraction> object is
created speculatively at module-load time and may never be accessed (for example, in a
web framework where the config object is built for every request but some request paths
never read it).  Avoid it when startup correctness is important, when you rely on
C<new()> returning C<undef> to detect missing configuration, or when you use schema
validation and need errors to point at the construction site.

=back

If just one argument is given, it is assumed to be the name of a file.

=cut

sub new
{
	my $class = shift;
	my $params;

	if(scalar(@_) == 1) {
		# Just one parameter - the name of a file
		$params = Params::Get::get_params('file', \@_);
	} else {
		$params = Params::Get::get_params(undef, \@_) || {};
	}

	$params->{'config_dirs'} //= $params->{'path'};	# Compatibility with Config::Auto

	$params->{config_dirs} = [ $ENV{CONFIG_DIR} ] if(defined($ENV{CONFIG_DIR}));

	$params->{'config_file'} //= $params->{'file'} if($params->{'file'});

	if(!defined($params->{'config_dirs'})) {
		if($params->{'config_file'} && File::Spec->file_name_is_absolute($params->{'config_file'})) {
			$params->{'config_dirs'} = [''];
		} else {
			# Set up the default value for config_dirs
			if($^O ne 'MSWin32') {
				$params->{'config_dirs'} = [ '/etc', '/usr/local/etc' ];
			} else {
				$params->{'config_dirs'} = [''];
			}
			if($ENV{'HOME'}) {
				push @{$params->{'config_dirs'}},
					File::Spec->catdir($ENV{'HOME'}, '.conf'),
					File::Spec->catdir($ENV{'HOME'}, '.config'),
					File::Spec->catdir($ENV{'HOME'}, 'conf'),
			} elsif($ENV{'DOCUMENT_ROOT'}) {
				push @{$params->{'config_dirs'}},
					File::Spec->catdir($ENV{'DOCUMENT_ROOT'}, File::Spec->updir(), 'conf'),
					File::Spec->catdir($ENV{'DOCUMENT_ROOT'}, 'conf'),
					File::Spec->catdir($ENV{'DOCUMENT_ROOT'}, 'config');
			}
			if(my $dir = $ENV{'CONFIG_DIR'}) {
				push @{$params->{'config_dirs'}}, $dir;
			} else {
				push @{$params->{'config_dirs'}}, 'conf', 'config';
			}
		}
	}

	my $self = bless {
		sep_char => '.',
		%{$params->{defaults} ? $params->{defaults} : $params},
		env_prefix => $params->{env_prefix} || 'APP_',
		config => {},
	}, $class;

	# Cache the compiled sep_char regex once so get() and exists() do not
	# recompile it on every key lookup.
	$self->{'_sep_re'} = qr/\Q$self->{'sep_char'}\E/;

	if(my $logger = $self->{'logger'}) {
		if(!Scalar::Util::blessed($logger)) {
			# Don't call $self->_load_driver('Log::Abstraction') as it can make a call to logger, which is yet to be set up
			eval "require Log::Abstraction";
			if($@) {
				carp(ref($self), ": Log::Abstraction failed to load: $@, disabling logging");
				if(ref($logger) eq 'ARRAY') {
					push @{$logger}, "Log::Abstraction failed to load: $@, disabling logging";
				}
				$self->{'logger'} = undef;	# disable: unblessed ref would fatal on method calls
			} else {
				Log::Abstraction->import();
				$self->{'logger'} = Log::Abstraction->new($logger);
				if($params->{'level'} && $self->{'logger'}->can('level')) {
					$self->{'logger'}->level($params->{'level'});
				}
			}
		}
	}
	# Fail early when an explicitly-specified key file is missing rather than
	# silently falling back to unencrypted operation (env-var key files are optional).
	if(defined $self->{'encryption_key_file'}) {
		my $kf = $self->{'encryption_key_file'};
		Carp::croak(ref($self) . ": encryption_key_file '$kf' does not exist") unless -f $kf;
	}

	if($self->{'lazy'}) {
		# Defer all source scanning to the first accessor call.
		# Stash validators/checker/schema for later (after _load_config runs).
		$self->{'_lazy_schema'}     = delete $self->{'schema'}     if $self->{'schema'};
		$self->{'_lazy_validators'} = delete $self->{'validators'} if $self->{'validators'};
		$self->{'_lazy_checker'}    = delete $self->{'checker'}    if $self->{'checker'};
		return $self;
	}

	$self->_load_config();

	if(my $schema = $params->{'schema'}) {
		$self->{'config'} = Params::Validate::Strict::validate_strict(schema => $schema, input => $self->{'config'});
	}
	if(my $validators = $params->{'validators'}) {
		$self->_run_validators($validators);
	}
	if(my $checker = $params->{'checker'}) {
		$self->_run_checker($checker);
	}

	if(defined($self->{'config'}) && scalar(keys %{$self->{'config'}})) {
		return $self;
	}
	return undef;
}

# Trigger deferred loading when the object was constructed with lazy => 1.
# Safe to call unconditionally: it is a no-op once loading has completed.
sub _ensure_loaded
{
	my $self = shift;
	return unless $self->{'lazy'};    # fast-path: not a lazy object
	delete $self->{'lazy'};           # prevent re-entry on recursive calls
	$self->_load_config();
	if(my $schema = delete $self->{'_lazy_schema'}) {
		$self->{'config'} = Params::Validate::Strict::validate_strict(schema => $schema, input => $self->{'config'});
	}
	if(my $validators = delete $self->{'_lazy_validators'}) {
		$self->_run_validators($validators);
	}
	if(my $checker = delete $self->{'_lazy_checker'}) {
		$self->_run_checker($checker);
	}
}

# Resolve the active deployment environment name.
# Checked in order: 'environment' constructor option, {prefix}ENV env var,
# PLACK_ENV, NODE_ENV.  Returns undef when none is set.
# The value must match /^[A-Za-z0-9_\-]+$/ or a croak is raised.
sub _get_environment
{
	my $self = shift;

	my $env;

	if(defined($self->{'environment'})) {
		$env = $self->{'environment'};
	} else {
		my $prefix = $self->{'env_prefix'} // 'APP_';
		$env = $ENV{$prefix . 'ENV'}
			// $ENV{'PLACK_ENV'}
			// $ENV{'NODE_ENV'};
	}

	return undef unless defined $env;
	return undef if $env eq '';

	unless($env =~ /^[A-Za-z0-9_-]+$/) {
		Carp::croak(ref($self) . ": invalid environment name '$env': must contain only alphanumerics, hyphens, or underscores");
	}

	return $env;
}

# _sanitize_yaml_values: Recursively replace CODE and GLOB refs with undef.
# YAML::XS can produce CODE refs from !!perl/code tags regardless of DisableCode.
# Applying this after LoadFile prevents executable references from reaching callers.
sub _sanitize_yaml_values
{
	my ($self, $val) = @_;
	my $r = ref($val);
	return undef if $r eq 'CODE' || $r eq 'GLOB';
	if($r eq 'HASH') {
		return { map { $_ => $self->_sanitize_yaml_values($val->{$_}) } keys %$val };
	}
	if($r eq 'ARRAY') {
		return [ map { $self->_sanitize_yaml_values($_) } @$val ];
	}
	return $val;
}

# Resolve the AES-256 encryption key from constructor option, env vars, or key file.
# Returns 32 raw bytes, or undef when no key is configured.
sub _get_encryption_key
{
	my $self = shift;

	my $raw = $self->{'encryption_key'};

	if(!defined($raw)) {
		my $prefix = $self->{'env_prefix'} // 'APP_';
		$raw = $ENV{$prefix . 'ENCRYPTION_KEY'} // $ENV{'ENCRYPTION_KEY'};
	}

	if(!defined($raw)) {
		my $prefix = $self->{'env_prefix'} // 'APP_';
		my $kf = $self->{'encryption_key_file'}
			// $ENV{$prefix . 'ENCRYPTION_KEY_FILE'}
			// $ENV{'ENCRYPTION_KEY_FILE'};
		if(defined($kf) && -f $kf) {
			open my $fh, '<', $kf
				or Carp::croak(ref($self) . ": cannot open encryption_key_file '$kf': $!");
			$raw = <$fh>;
			close $fh;
			chomp $raw if defined $raw;
		}
	}

	return undef unless defined $raw;
	return $self->_decode_encryption_key($raw);
}

# Accept a key as 32 raw bytes, 64 hex chars, or 43-44 base64/base64url chars.
# Returns 32 raw bytes or croaks.
sub _decode_encryption_key
{
	my ($self, $raw) = @_;

	return $raw if length($raw) == $_AES_KEY_SIZE;

	if(length($raw) == $_HEX_KEY_LEN && $raw =~ /^[0-9A-Fa-f]{$_HEX_KEY_LEN}$/) {
		return pack('H*', $raw);
	}

	if(length($raw) >= $_B64_KEY_MIN && length($raw) <= $_B64_KEY_MAX) {
		require MIME::Base64;
		(my $b64 = $raw) =~ tr/-_/+\//;   # base64url → base64
		$b64 .= '=' x ((4 - length($b64) % 4) % 4);
		my $bytes = MIME::Base64::decode_base64($b64);
		return $bytes if length($bytes) == $_AES_KEY_SIZE;
	}

	Carp::croak(ref($self) . ': encryption_key must be ' . $_AES_KEY_SIZE . ' raw bytes, ' . $_HEX_KEY_LEN . ' hex chars, or ' . $_B64_KEY_MAX . ' base64 chars (got length ' . length($raw) . ')');
}

# Recursively walk $href and decrypt any leaf value matching ENC[...].
# $seen guards against circular references (possible when Hash::Merge
# no-clone mode is active and sub-hashes are shared across the merge tree).
sub _decrypt_config_values
{
	my ($self, $href, $key, $seen) = @_;
	$seen //= {};
	return if $seen->{Scalar::Util::refaddr($href)}++;

	for my $k (keys %{$href}) {
		next if $k eq 'config_path';
		my $v = $href->{$k};
		if(ref($v) eq 'HASH') {
			$self->_decrypt_config_values($v, $key, $seen);
		} elsif(ref($v) eq 'ARRAY') {
			for my $i (0..$#{$v}) {
				if(!ref($v->[$i]) && defined($v->[$i]) && $v->[$i] =~ /^ENC\[/) {
					$v->[$i] = $self->_decrypt_enc_value($v->[$i], $key);
				}
			}
		} elsif(!ref($v) && defined($v) && $v =~ /^ENC\[/) {
			$href->{$k} = $self->_decrypt_enc_value($v, $key);
		}
	}
}

# Decrypt a single ENC[AES256GCM,<base64url>] token.
# Returns the plaintext string or croaks on failure.
sub _decrypt_enc_value
{
	my ($self, $token, $key) = @_;

	unless($token =~ /^
		ENC\[
		([A-Za-z0-9]+)		# algorithm name  (e.g. AES256GCM)
		,
		([A-Za-z0-9_-]+)	# base64url payload (RFC 4648 §5 alphabet)
		\]
	$/x) {
		Carp::croak(ref($self) . ": malformed ENC token: $token");
	}
	my ($algo, $b64) = ($1, $2);

	unless(lc($algo) eq 'aes256gcm') {
		Carp::croak(ref($self) . ": unsupported encryption algorithm '$algo' in ENC token");
	}

	# Decode and validate payload length before requiring CryptX: a structurally
	# invalid token should be rejected regardless of whether the crypto library
	# is installed.  MIME::Base64 is a core module and always available.
	require MIME::Base64;
	my $raw = MIME::Base64::decode_base64url($b64);

	if(length($raw) < $_ENC_PAYLOAD_MIN) {
		Carp::croak(ref($self) . ": ENC token payload is too short to be valid");
	}

	unless($self->_load_driver('Crypt::AuthEnc::GCM')) {
		Carp::croak(ref($self) . ': CryptX (Crypt::AuthEnc::GCM) is required to decrypt ENC[] values; install it with: cpanm CryptX');
	}

	my $nonce = substr($raw,  0, $_AES_NONCE_SIZE);
	my $tag   = substr($raw, -$_AES_TAG_SIZE);
	my $ct    = substr($raw, $_AES_NONCE_SIZE, length($raw) - $_ENC_PAYLOAD_MIN);

	my $gcm = Crypt::AuthEnc::GCM->new('AES', $key);
	$gcm->iv_add($nonce);
	my $pt = $gcm->decrypt_add($ct);

	my $ok = eval { $gcm->decrypt_done($tag) };
	unless($ok && !$@) {
		Carp::croak(ref($self) . ": decryption failed (wrong key or tampered data)");
	}

	return $pt;
}

# Apply the validators hash supplied as a constructor option.
# Each key is a dotted config key; each value is a coderef, regex, type string, or spec hashref.
sub _run_validators
{
	my ($self, $validators) = @_;

	for my $key (sort keys %{$validators}) {
		my $spec  = $validators->{$key};
		my $value = $self->get($key);

		if(ref($spec) eq 'CODE') {
			unless($spec->($value)) {
				Carp::croak(ref($self) . ": validation failed for '$key': custom validator returned false");
			}
		} elsif(ref($spec) eq 'Regexp') {
			unless(defined($value) && $value =~ $spec) {
				Carp::croak(ref($self) . ": '$key' value " .
					(defined($value) ? "'$value'" : '(undef)') . " does not match required pattern");
			}
		} elsif(ref($spec) eq 'HASH') {
			$self->_validate_value_spec($key, $value, $spec);
		} elsif(!ref($spec)) {
			_validate_type($key, $value, $spec);
		} else {
			Carp::croak(ref($self) . ": invalid validator for '$key': must be a type string, regex, coderef, or hashref");
		}
	}
}

# Apply a hashref spec (type / pattern / min / max / required) to a single value.
sub _validate_value_spec
{
	my ($self, $key, $value, $spec) = @_;

	if($spec->{'required'} && (!$self->exists($key) || !defined($value))) {
		Carp::croak(ref($self) . ": required key '$key' is missing or undefined");
	}
	if(my $type = $spec->{'type'}) {
		_validate_type($key, $value, $type);
	}
	if(my $pattern = $spec->{'pattern'}) {
		unless(defined($value) && $value =~ $pattern) {
			Carp::croak(ref($self) . ": '$key' value " .
				(defined($value) ? "'$value'" : '(undef)') . " does not match required pattern");
		}
	}
	if(defined(my $min = $spec->{'min'})) {
		Carp::croak(ref($self) . ": '$key' value '$value' is less than minimum $min")
			if defined($value) && $value < $min;
	}
	if(defined(my $max = $spec->{'max'})) {
		Carp::croak(ref($self) . ": '$key' value '$value' exceeds maximum $max")
			if defined($value) && $value > $max;
	}
}

# Validate a single value against a named type.
# Not a method — takes (key, value, type_string).
sub _validate_type
{
	my ($key, $value, $type) = @_;
	my $ltype = lc($type);

	if($ltype eq 'integer') {
		Carp::croak("Config::Abstraction: '$key' must be an integer (got " .
			(defined $value ? "'$value'" : 'undef') . ')')
			unless defined($value) && $value =~ /^-?[0-9]+$/;
	} elsif($ltype eq 'number' || $ltype eq 'float') {
		Carp::croak("Config::Abstraction: '$key' must be a number (got " .
			(defined $value ? "'$value'" : 'undef') . ')')
			unless defined($value) && Scalar::Util::looks_like_number($value);
	} elsif($ltype eq 'boolean') {
		Carp::croak("Config::Abstraction: '$key' must be a boolean (0/1/true/false/yes/no), got " .
			(defined $value ? "'$value'" : 'undef'))
			unless defined($value) && $value =~ /^(?:1|0|true|false|yes|no)$/i;
	} elsif($ltype eq 'string') {
		Carp::croak("Config::Abstraction: '$key' must be a defined string (got undef)")
			unless defined($value) && !ref($value);
	} elsif($ltype eq 'array') {
		Carp::croak("Config::Abstraction: '$key' must be an array reference")
			unless ref($value) eq 'ARRAY';
	} elsif($ltype eq 'hash') {
		Carp::croak("Config::Abstraction: '$key' must be a hash reference")
			unless ref($value) eq 'HASH';
	} else {
		Carp::croak("Config::Abstraction: unknown type '$type' in validators for '$key'");
	}
}

# Invoke Config::Checker with the merged config and caller-supplied prototype.
# prototype may be a YAML string or a hashref.
sub _run_checker
{
	my ($self, $prototype) = @_;

	unless($self->_load_driver('Config::Checker')) {
		Carp::carp(ref($self) . ': Config::Checker not available; skipping checker validation');
		return;
	}

	# config_checker_source() returns Perl source text (a sub { ... } literal)
	# that must be eval'd so it can import into our namespace.
	my $checker = eval Config::Checker::config_checker_source();	## no critic (ProhibitStringyEval)
	Carp::croak(ref($self) . ": failed to compile Config::Checker: $@") if $@;

	eval { $checker->($self->{'config'}, $prototype) };
	Carp::croak(ref($self) . ": checker validation failed: $@") if $@;
}

# Determine if a value is a plain, unblessed, non-reference scalar
# safe to use in regex/string operations.
# Args:   value to test
# Returns: 1 if plain scalar, 0 otherwise
sub _is_plain_scalar
{
	my $val = $_[0];

	return 0 if !defined($val);
	return 0 if Scalar::Util::blessed($val);
	return 0 if ref($val);
	return 1;
}

# Recursively flatten a nested hashref to dotted keys (always uses '.' as separator).
# Skips the meta-key 'config_path'. Used by explain_sources() and source tracking.
# $seen guards against circular references (e.g. those possible when
# Hash::Merge::set_clone_behavior(0) is active).
#
# _flatten_into writes into a caller-supplied hashref accumulator so that
# each leaf key is written exactly once -- O(N) total writes vs the previous
# O(N^2) pattern of %flat = (%flat, _flatten_keys(...)) at each recursion level.
sub _flatten_into
{
	my ($acc, $hash, $prefix, $seen) = @_;
	return unless ref($hash) eq 'HASH';
	my $addr = Scalar::Util::refaddr($hash);
	return if $seen->{$addr}++;
	for my $k (keys %$hash) {
		next if $k eq 'config_path';
		my $full = length($prefix) ? "$prefix.$k" : $k;
		if(ref($hash->{$k}) eq 'HASH') {
			_flatten_into($acc, $hash->{$k}, $full, $seen);
		} else {
			$acc->{$full} = $hash->{$k};
		}
	}
}

sub _flatten_keys
{
	my ($hash, $prefix, $seen) = @_;
	my %flat;
	_flatten_into(\%flat, $hash, $prefix // '', $seen // {});
	return %flat;
}

sub _load_config
{
	if(!UNIVERSAL::isa((caller)[0], __PACKAGE__)) {
		Carp::croak('Illegal Operation: This method can only be called by a subclass');
	}

	my $self = shift;

	# Disable Hash::Merge cloning for the duration of this method.
	# Storable::dclone (used when clone=1) cannot handle coderefs or blessed
	# objects that may appear in the 'data' argument; sharing references is
	# safe here because %merged is a fresh, method-local accumulator.
	my $saved_clone = Hash::Merge::get_clone_behavior();
	Hash::Merge::set_clone_behavior(0);

	my %merged;

	if($self->{'data'}) {
		# The data argument given to 'new' contains defaults that this routine will override
		if(ref($self->{'data'}) eq 'HASH') {
			%merged = %{$self->{'data'}};
			push @{$self->{'_source_records'}}, {
				type      => 'data',
				label     => 'constructor data argument',
				flat_data => { _flatten_keys($self->{'data'}) },
			};
		} else {
			Carp::carp(ref($self) . ': data argument must be a hashref; ignoring non-hashref value');
		}
	}

	my $logger = $self->{'logger'};
	if($logger) {
		$logger->trace(ref($self), ' ', __LINE__, ': Entered _load_config');
	}

	my $environment = $self->_get_environment();
	my @_formats    = qw(yaml yml json xml ini toml);
	my @_file_list  = (
		(map { "base.$_"              } @_formats),
		($environment ? (map { "base.$environment.$_"  } @_formats) : ()),
		(map { "local.$_"             } @_formats),
		($environment ? (map { "local.$environment.$_" } @_formats) : ()),
	);

	my @dirs = @{$self->{'config_dirs'}};
	if($self->{'config_file'} && (scalar(@dirs) > 1)) {
		if(File::Spec->file_name_is_absolute($self->{'config_file'})) {
			# Handle absolute paths
			@dirs = ('');
		} else {
			# Look in the current directory
			push @dirs, File::Spec->curdir();
		}
	}
	for my $dir (@dirs) {
		next if(!defined($dir));

		# Newcastle Connection: /../hostname/path means read from a remote host.
		# /../ is unreachable on any real filesystem, so this is unambiguous.
		# When the hostname resolves to the local machine (localhost, 127.0.0.1,
		# ::1, or the system hostname) the /../host/ wrapper is unwrapped and the
		# enclosed path is processed through the normal local pipeline instead.
		my $effective_dir = $dir;
		if(my ($host, $remote_dir) = $self->_parse_remote_dir($dir)) {
			if($self->_is_local_host($host)) {
				$effective_dir = $remote_dir;
			} else {
				$self->_load_remote_dir($host, $remote_dir, \%merged, \@_file_list);
				next;
			}
		}

		if(length($effective_dir) && !-d $effective_dir) {
			next;
		}

		for my $file (@_file_list) {
			my $path = File::Spec->catfile($effective_dir, $file);
			if($logger) {
				$logger->debug(ref($self), ' ', __LINE__, ": Looking for configuration $path");
			}
			next unless -f $path;
			next unless -r $path;

			if($logger) {
				$logger->debug(ref($self), ' ', __LINE__, ": Loading data from $path");
			}

			my $data;
			# Only load config modules when they are needed
			if ($file =~ /\.ya?ml$/) {
				$self->_load_driver('YAML::XS', ['LoadFile']);
				$data = eval { LoadFile($path) };
				if($@) {
					if($logger) {
						$logger->notice("Failed to load YAML from $path: $@");
					} else {
						Carp::carp("Failed to load YAML from $path: $@");
					}
					next;
				}
				$data = $self->_sanitize_yaml_values($data) if defined($data) && ref($data);
			} elsif ($file =~ /\.json$/) {
				$data = eval { decode_json(read_file($path)) };
					if($@) {
						if($logger) {
							$logger->notice("Failed to load JSON from $path: $@");
						} else {
							Carp::carp("Failed to load JSON from $path: $@");
						}
						next;
					}
			} elsif($file =~ /\.xml$/) {
				my $rc;
				if($self->_load_driver('XML::Simple', ['XMLin'])) {
					my $xml_raw = eval { read_file($path) };
					if(defined($xml_raw) && $xml_raw =~ /<!ENTITY\s+\w+\s+(?:SYSTEM|PUBLIC)\b/i) {
						Carp::carp(ref($self) . ": skipping $path: XML external entity declarations not permitted");
					} elsif(defined($xml_raw)) {
						eval { $rc = XMLin(\$xml_raw, ForceArray => 0, KeyAttr => []) };
						if($@) {
							if($logger) {
								$logger->notice("Failed to load XML from $path: $@");
							} else {
								Carp::carp("Failed to load XML from $path: $@");
							}
							undef $rc;
						} elsif($rc) {
							$data = $rc;
						}
					}
				}
				if((!defined($rc)) && $self->_load_driver('XML::PP')) {
					my $xml_pp = XML::PP->new();
					$data = read_file($path);
					if(my $tree = $xml_pp->parse(\$data)) {
						if($data = $xml_pp->collapse_structure($tree)) {
							$self->{'type'} = 'XML';
							if($data->{'config'}) {
								$data = $data->{'config'};
							}
						}
					}
				}
			} elsif ($file =~ /\.ini$/) {
				$self->_load_driver('Config::IniFiles');
				if(my $ini = Config::IniFiles->new(-file => $path)) {
					$data = { map {
						my $section = $_;
						$section => { map { $_ => $ini->val($section, $_) } $ini->Parameters($section) }
					} $ini->Sections() };
				} else {
					if($logger) {
						$logger->notice("Failed to load INI from $path: $@");
					} else {
						Carp::carp("Failed to load INI from $path: $@");
					}
				}
			} elsif ($file =~ /\.toml$/) {
				if($self->_load_driver('TOML::Tiny', ['from_toml'])) {
					# scalar() forces read_file into scalar context; without it
					# read_file returns a list of lines and from_toml (no prototype)
					# only sees the first line.
					my ($toml_data, $toml_err) = from_toml(scalar(read_file($path)));
					if($toml_err) {
						if($logger) {
							$logger->notice("Failed to load TOML from $path: $toml_err");
						} else {
							Carp::carp("Failed to load TOML from $path: $toml_err");
						}
					} elsif(ref($toml_data) eq 'HASH' && scalar(keys %$toml_data)) {
						$data = $toml_data;
					}
				}
			}
			if($data) {
				if(!ref($data)) {
					if($logger) {
						$logger->debug(ref($self), ' ', __LINE__, ": ignoring data from $path ($data)");
					}
					next;
				}
				if(ref($data) ne 'HASH') {
					if($logger) {
						$logger->debug(ref($self), ' ', __LINE__, ": ignoring data from $path (not a hashref)");
					}
					next;
				}
				if($logger) {
					$logger->debug(ref($self), ' ', __LINE__, ": Loaded data from $path");
				}
				push @{$self->{'_source_records'}}, {
					type      => 'file',
					label     => $path,
					flat_data => { _flatten_keys($data) },
				};
				%merged = %{ merge( $data, \%merged ) };
				push @{$merged{'config_path'}}, $path;
			}
		}

		# Put $self->{config_file} through all parsers, ignoring all errors, then merge that in
		if(!$self->{'script_name'}) {
			require File::Basename && File::Basename->import() unless File::Basename->can('basename');

			# Determine script name
			$self->{'script_name'} = File::Basename::basename($ENV{'SCRIPT_NAME'} || $0);
		}

		my $script_name = $self->{'script_name'};
		for my $config_file ('default', $script_name, "$script_name.cfg", "$script_name.conf", "$script_name.config", $self->{'config_file'}, @{$self->{'config_files'}}) {
			next unless defined($config_file);
			# Note that loading $script_name in the current directory could mean loading the script as its own config.
			# This test is not foolproof, buyer beware
			next if(($config_file eq $script_name) && ((length($effective_dir) == 0) || ($effective_dir eq File::Spec->curdir())));
			my $path = length($effective_dir) ? File::Spec->catfile($effective_dir, $config_file) : $config_file;
			if($logger) {
				$logger->debug(ref($self), ' ', __LINE__, ": Looking for configuration $path");
			}
			if((-f $path) && (-r $path)) {
				my $data = read_file($path);
				my $raw_content = $data;
				if($logger) {
					$logger->debug(ref($self), ' ', __LINE__, ": Loading data from $path");
				}
				eval {
					if(($data =~ /^\s*<\?xml/) || ($data =~ /<\/[^>]+>/)) {
						if($self->_load_driver('XML::Simple', ['XMLin'])) {
							if($data =~ /<!ENTITY\s+\w+\s+(?:SYSTEM|PUBLIC)\b/i) {
								Carp::carp(ref($self) . ": skipping $path: XML external entity declarations not permitted");
								undef $data;
							} elsif(my $xml_data = XMLin(\$data, ForceArray => 0, KeyAttr => [])) {
								$data = $xml_data;
								$self->{'type'} = 'XML';
							}
						} elsif($self->_load_driver('XML::PP')) {
							my $xml_pp = XML::PP->new();
							if(my $tree = $xml_pp->parse(\$data)) {
								if($data = $xml_pp->collapse_structure($tree)) {
									$self->{'type'} = 'XML';
									if($data->{'config'}) {
										$data = $data->{'config'};
									}
								}
							}
						}
					} elsif($data =~ /
						\{		# opening brace
						.+		# key material; dot matches newlines because of the s modifier
						:		# colon separator
						.		# one value character
						\}		# closing brace
					/xs) {
						$self->_load_driver('JSON::Parse');
						# CPanel::JSON is very noisy, so be careful before attempting to use it
						my $is_json;
						eval { $is_json = JSON::Parse::parse_json($data) };
						if($is_json) {
							eval { $data = decode_json($data) };
							if($@) {
								undef $data;
							}
						} else {
							undef $data;
						}
						if($data) {
							$self->{'type'} = 'JSON';
						}
					} else {
						undef $data;
					}
					if(!$data && $raw_content !~ /<!ENTITY\s+\w+\s+(?:SYSTEM|PUBLIC)\b/i) {
						$self->_load_driver('YAML::XS', ['LoadFile']);
						if((eval { $data = LoadFile($path) }) && (ref($data) eq 'HASH')) {
							$data = $self->_sanitize_yaml_values($data);
							# Could be colon file, could be YAML, whichever it is break the configuration fields
							# foreach my($k, $v) (%{$data}) {
							foreach my $k (keys %{$data}) {
								my $v = $data->{$k};
								if(!defined($v)) {
									# e.g. a simple line
									#	foo:
									# with nothing under it
									$data->{$k} = undef;
									next;
								}
								# Do not inspect or modify coderefs, blessed objects, or any reference
								next unless _is_plain_scalar($v);

								next if($v =~ /^"[^"]+"$/);	# Single-quoted field — skip comma-splitting
								if($v =~ /,/) {
									my @vals = split(/\s*,\s*/, $v);
									delete $data->{$k};
									foreach my $val (@vals) {
										if($val =~ /([^=]+)=(.+)/) {
											$data->{$k}{$1} = $2;
										} else {
											$data->{$k}{$val} = 1;
										}
									}
								}
							}
							if($data) {
								$self->{'type'} = 'YAML';
							}
						}
						if((!$data) || (ref($data) ne 'HASH')) {
							if($self->_load_driver('TOML::Tiny', ['from_toml'])) {
								# scalar() forces read_file into scalar context; without it
								# read_file returns a list of lines and from_toml (no prototype)
								# only sees the first line.
								my ($toml_data, $toml_err) = eval { from_toml(scalar(read_file($path))) };
								if(!$toml_err && ref($toml_data) eq 'HASH' && scalar(keys %$toml_data)) {
									$data = $toml_data;
									$self->{'type'} = 'TOML';
								}
							}
						}
						if((!$data) || (ref($data) ne 'HASH')) {
							$self->_load_driver('Config::IniFiles');
							if(my $ini = Config::IniFiles->new(-file => $path)) {
								$data = { map {
									my $section = $_;
									$section => { map { $_ => $ini->val($section, $_) } $ini->Parameters($section) }
								} $ini->Sections() };
								if($data) {
									$self->{'type'} = 'INI';
								}
							}
							if((!$data) || (ref($data) ne 'HASH')) {
								# Maybe XML without the leading XML header
								if($self->_load_driver('XML::Simple', ['XMLin'])) {
									my $xml_raw = eval { read_file($path) };
									if(defined($xml_raw) && $xml_raw !~ /<!ENTITY\s+\w+\s+(?:SYSTEM|PUBLIC)\b/i) {
										eval { $data = XMLin(\$xml_raw, ForceArray => 0, KeyAttr => []) };
									}
								}
								if((!$data) || (ref($data) ne 'HASH')) {
									if($self->_load_driver('Config::Abstract')) {
										# Handle RT#164587
										open my $oldSTDERR, '>&STDERR';
										close STDERR;
										eval { $data = Config::Abstract->new($path) };
										my $err = $@;
										open STDERR, '>&', $oldSTDERR;
										if($err) {
											undef $data;
										} elsif($data) {
											$data = $data->get_all_settings();
											if(scalar(keys %{$data}) == 0) {
												undef $data;
											}
										}
										$self->{'type'} = 'Perl';
									}
								}
								if((!$data) || (ref($data) ne 'HASH')) {
									$self->_load_driver('Config::Auto');
									my $ca = Config::Auto->new(source => $path);
									if($data = $ca->parse()) {
										$self->{'type'} = $ca->format();
									}
								}
							}
						}
					}
				};
				if($logger) {
					if($@) {
						$logger->warn(ref($self), ' ', __LINE__, ": $@");
						undef $data;
					} else {
						$logger->debug(ref($self), ' ', __LINE__, ': Loaded data from', $self->{'type'}, "file $path");
					}
				}
				if($data && ref($data) eq 'HASH') {
					push @{$self->{'_source_records'}}, {
						type      => 'file',
						label     => $path,
						flat_data => { _flatten_keys($data) },
					};
				}
				if(scalar(keys %merged)) {
					if($data) {
						%merged = %{ merge($data, \%merged) };
					}
				} elsif($data && (ref($data) eq 'HASH')) {
					%merged = %{$data};
				} elsif((!$@) && $logger) {
					$logger->debug(ref($self), ' ', __LINE__, ': No configuration file loaded');
				}

				push @{$merged{'config_path'}}, $path;
			}
		}
	}

	# Merge ENV vars
	my $prefix = $self->{env_prefix};
	$prefix =~ s/__$//;
	$prefix =~ s/_$//;
	$prefix =~ s/::$//;
	for my $key (keys %ENV) {
		next unless $key =~ /^\Q$self->{env_prefix}\E(.*)$/i;
		my $path = lc($1);
		if($path =~ /__/) {
			my @parts = split /__/, $path;
			my $ref = \%merged;
			$ref = ($ref->{$_} //= {}) for @parts[0..$#parts-1];
			$ref->{ $parts[-1] } = $ENV{$key};
			push @{$self->{'_source_records'}}, {
				type      => 'env',
				label     => $key,
				flat_data => { join('.', @parts) => $ENV{$key} },
			};
		} else {
			$merged{$prefix}->{$path} = $ENV{$key};
			push @{$self->{'_source_records'}}, {
				type      => 'env',
				label     => $key,
				flat_data => { "$prefix.$path" => $ENV{$key} },
			};
		}
	}

	# Merge command line options
	foreach my $arg(@ARGV) {
		next unless($arg =~ /=/);
		my ($key, $value) = split(/=/, $arg, 2);
		next unless $key =~ /^--\Q$self->{env_prefix}\E(.*)$/;

		my $path = lc($1);
		my @parts = split(/__/, $path);
		if(scalar(@parts) > 0) {
			my $ref = \%merged;
			if(scalar(@parts) > 1) {
				$ref = ($ref->{$_} //= {}) for @parts[0..$#parts-1];
			}
			$ref->{$parts[-1]} = $value;
			push @{$self->{'_source_records'}}, {
				type      => 'argv',
				label     => $arg,
				flat_data => { join('.', @parts) => $value },
			};
		}
	}

	if($self->{'flatten'}) {
		$self->_load_driver('Hash::Flatten', ['flatten']);
	} else {
		$self->_load_driver('Hash::Flatten', ['unflatten']);
	}
	# $self->{config} = $self->{flatten} ? flatten(\%merged) : unflatten(\%merged);
	# Don't unflatten because of RT#166761
	$self->{config} = $self->{flatten} ? flatten(\%merged) : \%merged;

	Hash::Merge::set_clone_behavior($saved_clone);

	if(my $enc_key = $self->_get_encryption_key()) {
		$self->_decrypt_config_values($self->{'config'}, $enc_key);
	}
}

=head2 get(key)

Retrieve a configuration value using dotted key notation (e.g.,
C<'database.user'>). Returns C<undef> if the key doesn't exist or if
C<key> is C<undef>.

=head3 EXAMPLE

  my $cfg = Config::Abstraction->new(
      data        => { database => { host => 'localhost', port => 5432 } },
      config_dirs => [],
  );

  my $host = $cfg->get('database.host');   # 'localhost'
  my $port = $cfg->get('database.port');   # 5432
  my $miss = $cfg->get('database.user');   # undef  -- key absent

=head3 API SPECIFICATION

=head4 Input

  key  -- SCALAR  -- dotted key path (e.g. 'database.host').
                     C<undef> is allowed and returns C<undef> silently.

=head4 Output

  SCALAR or reference -- the value stored under C<key>, or C<undef> if absent.

=head3 MESSAGES

  (none) -- missing keys return undef, no warning is raised.

=head3 PSEUDOCODE

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

=cut

sub get
{
	my ($self, $key) = @_;

	return undef unless defined $key;

	$self->_ensure_loaded();

	if($self->{flatten}) {
		return $self->{config}{$key};
	}
	my $ref = $self->{'config'};
	for my $part (split $self->{'_sep_re'}, $key) {
		return undef unless ref $ref eq 'HASH';
		return unless exists $ref->{$part};
		$ref = $ref->{$part};
	}
	if((defined($ref) && (ref($ref) eq 'HASH') && !$self->{'no_fixate'})) {
		if($self->_load_data_reuse()) {
			if(ref($ref) eq 'HASH') {
				if(!tied %$ref) {
					# Pass the hashref directly (not dereferenced) so fixate receives
					# a named scalar it can make read-only without flattening the hash
					# FIXME:
					# What works on MacOS doesn't work
					# on Linux and vice versa.
					# Something is wrong.
					# Data::Reuse::fixate(%{$ref}) if scalar(keys %{$ref});
					# Data::Reuse::fixate($ref) if scalar(keys %{$ref});
				}
			} elsif(ref($ref) eq 'ARRAY') {
				# RT#171980
				# Data::Reuse::fixate(@{$ref});
			}
		}
	}
	return $ref;
}

sub _load_data_reuse
{
	my $self = $_[0];

	# Skip fixation entirely if caller has opted out
	return 0 if($self->{'no_fixate'});

	# Return cached result to avoid repeated require attempts
	return 1 if($self->{reuse_loaded});
	return 0 if($self->{reuse_failed});

	eval {
		require Data::Reuse;
		Data::Reuse->import();
	};
	if($@) {
		# Cache the failure so we do not attempt to load again
		$self->{reuse_failed} = 1;
		return 0;
	}
	$self->{reuse_loaded} = 1;
	return 1;
}

=head2 exists(key)

Test whether a configuration key is present, using dotted key notation
(e.g., C<'database.user'>).  Returns C<1> when the key exists (even if its
value is C<undef>), C<0> otherwise.  Returns C<0> when C<key> is C<undef>.

=head3 EXAMPLE

  my $cfg = Config::Abstraction->new(
      data        => { timeout => undef, retries => 3 },
      config_dirs => [],
  );

  $cfg->exists('timeout');   # 1 -- key present even though value is undef
  $cfg->exists('retries');   # 1
  $cfg->exists('missing');   # 0
  $cfg->exists(undef);       # 0

=head3 API SPECIFICATION

=head4 Input

  key  -- SCALAR  -- dotted key path.  C<undef> returns C<0>.

=head4 Output

  boolean

=head3 MESSAGES

  (none)

=cut

sub exists
{
	my ($self, $key) = @_;

	return 0 unless defined $key;

	$self->_ensure_loaded();

	if($self->{flatten}) {
		return exists($self->{config}{$key}) ? 1 : 0;
	}
	my $ref = $self->{'config'};
	for my $part (split $self->{'_sep_re'}, $key) {
		return 0 unless ref $ref eq 'HASH';
		return 0 if(!exists($ref->{$part}));
		$ref = $ref->{$part};
	}
	return 1;
}

=head2 all()

Returns the entire merged configuration as a hashref, or C<undef> when no
configuration data was found.  When C<flatten =E<gt> 1> was given to the
constructor the keys are dotted strings (e.g. C<'database.host'>); otherwise
the hash is nested.

The special key C<config_path> within the returned hashref is an arrayref
listing every file that was loaded, in load order.

=head3 EXAMPLE

  my $cfg = Config::Abstraction->new(
      data        => { host => 'localhost', port => 5432 },
      config_dirs => [],
  );

  my $all = $cfg->all();
  # { host => 'localhost', port => 5432, config_path => [] }

=head3 API SPECIFICATION

=head4 Input

  (none)

=head4 Output

  HASHREF  -- the full merged config (includes C<config_path> key).
  undef    -- when the merged config is empty and no data was supplied.

=head3 MESSAGES

  (none) -- returns undef silently when empty.

=cut

sub all
{
	my $self = shift;

	$self->_ensure_loaded();

	return if(!$self->{config});

	# This is good for debugging, but not much more and it breaks inheritance, so disabled
	# if($self->_load_data_reuse()) {
		# Data::Reuse::fixate($self->{config});
	# }

	return(scalar(keys %{$self->{'config'}})) ? $self->{'config'} : undef;
}

=head2 explain_sources()

Returns a hashref describing where each configuration key came from and in
what order the sources that set it were applied.

Each key of the returned hashref is a dotted key name (e.g. C<'database.user'>).
The corresponding value is a hashref with two fields:

=over 4

=item * C<value>

The final merged value for that key after all sources have been applied.

=item * C<sources>

An arrayref of hashrefs, ordered from lowest to highest precedence (i.e. the
last element is always the winning source). Each entry has:

=over 4

=item * C<type> -- one of C<'data'>, C<'file'>, C<'env'>, or C<'argv'>

=item * C<label> -- a human-readable identifier: a file path, an environment
variable name (e.g. C<'APP_DATABASE__USER'>), a CLI argument string, or
C<'constructor data argument'>

=item * C<value> -- what this source set the key to (may differ from C<value>
at the top level if a later source overrode it)

=back

=back

Keys set by exactly one source have a single-element C<sources> list.
Keys whose value was never overridden will show the same C<value> in both the
top-level field and the sole C<sources> entry.

=head3 USAGE EXAMPLE

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

=head3 API SPECIFICATION

=head4 Input

None (instance method; takes no arguments beyond C<$self>).

=head4 Output

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

=cut

sub explain_sources
{
	my $self = shift;

	$self->_ensure_loaded();

	my %final_flat = _flatten_keys($self->{'config'});
	my %result;

	for my $key (keys %final_flat) {
		my @key_sources;
		for my $layer (@{$self->{'_source_records'} // []}) {
			if(exists $layer->{'flat_data'}{$key}) {
				push @key_sources, {
					type  => $layer->{'type'},
					label => $layer->{'label'},
					value => $layer->{'flat_data'}{$key},
				};
			}
		}
		$result{$key} = {
			value   => $final_flat{$key},
			sources => \@key_sources,
		};
	}
	return \%result;
}

# ---------------------------------------------------------------------------
# _value_from_type -- scan _source_records for the last record of the given
# type that provided a value for $key.  Source records always use '.' as the
# key separator regardless of sep_char, so we normalise $key before the lookup.
#
# Returns ($found, $value): $found is true when the source type contributed to
# the key, letting callers distinguish "source set key to undef" from "source
# never set it".
# ---------------------------------------------------------------------------
sub _value_from_type
{
	my ($self, $type, $key) = @_;

	return (0, undef) unless defined $key;

	$self->_ensure_loaded();

	my $sep = $self->{'sep_char'};
	my $flat_key = ($sep eq '.') ? $key : join('.', split /\Q$sep\E/, $key);

	my ($found, $val);
	for my $layer (@{$self->{'_source_records'} // []}) {
		next unless $layer->{'type'} eq $type;
		if(exists $layer->{'flat_data'}{$flat_key}) {
			$found = 1;
			$val   = $layer->{'flat_data'}{$flat_key};
		}
	}
	return ($found, $val);
}

=head2 prefer_env(key)

Return the value that an environment variable provided for C<key>, bypassing
any later sources (e.g. CLI arguments) that may have overridden it.
Falls back to the normal merged value from C<get(key)> when no environment
variable contributed to C<key>.

=head3 EXAMPLE

  local $ENV{APP_DATABASE__HOST} = 'env-host';
  my $host = $cfg->prefer_env('database.host');
  # Returns 'env-host' even if --APP_DATABASE__HOST=cli-host was also passed.

=head3 API SPECIFICATION

=head4 Input

  key -- SCALAR -- dotted key path.

=head4 Output

  SCALAR  -- the env-layer value, or C<get(key)> when no env var set it.

=cut

sub prefer_env
{
	my ($self, $key) = @_;
	my ($found, $val) = $self->_value_from_type('env', $key);
	return $found ? $val : $self->get($key);
}

=head2 prefer_file(key)

Return the value that a configuration file provided for C<key>, bypassing
environment variables and CLI arguments that may have overridden it.
Falls back to the normal merged value from C<get(key)> when no file
contributed to C<key>.

=head3 EXAMPLE

  my $host = $cfg->prefer_file('database.host');
  # Returns the file-sourced value even if APP_DATABASE__HOST is set.

=head3 API SPECIFICATION

=head4 Input

  key -- SCALAR -- dotted key path.

=head4 Output

  SCALAR  -- the file-layer value, or C<get(key)> when no file set it.

=cut

sub prefer_file
{
	my ($self, $key) = @_;
	my ($found, $val) = $self->_value_from_type('file', $key);
	return $found ? $val : $self->get($key);
}

=head2 prefer_data(key)

Return the value that the C<data> constructor argument provided for C<key>,
bypassing files, environment variables, and CLI arguments that may have
overridden it.
Falls back to the normal merged value from C<get(key)> when C<data> did not
contribute to C<key>.

=head3 EXAMPLE

  my $cfg = Config::Abstraction->new(
      data        => { timeout => 30 },
      config_dirs => ['/etc/myapp'],
  );
  my $t = $cfg->prefer_data('timeout');   # always 30, regardless of files/env

=head3 API SPECIFICATION

=head4 Input

  key -- SCALAR -- dotted key path.

=head4 Output

  SCALAR  -- the data-layer value, or C<get(key)> when C<data> did not set it.

=cut

sub prefer_data
{
	my ($self, $key) = @_;
	my ($found, $val) = $self->_value_from_type('data', $key);
	return $found ? $val : $self->get($key);
}

=head2 prefer_argv(key)

Return the value that a CLI argument provided for C<key>.
Falls back to the normal merged value from C<get(key)> when no CLI argument
contributed to C<key>.

Because CLI arguments are the highest-precedence source, this method is
primarily useful for writing self-documenting code or for detecting whether
a key was explicitly supplied on the command line.

=head3 EXAMPLE

  my $level = $cfg->prefer_argv('log.level');
  # Equivalent to $cfg->get('log.level') unless you specifically need to
  # confirm the value came from @ARGV.

=head3 API SPECIFICATION

=head4 Input

  key -- SCALAR -- dotted key path.

=head4 Output

  SCALAR  -- the argv-layer value, or C<get(key)> when no CLI arg set it.

=cut

sub prefer_argv
{
	my ($self, $key) = @_;
	my ($found, $val) = $self->_value_from_type('argv', $key);
	return $found ? $val : $self->get($key);
}

=head2 encrypt_value($plaintext)

Encrypt a plaintext string using the configured AES-256-GCM key and return an
C<ENC[AES256GCM,...]> token suitable for storing in a configuration file.

Each call generates a fresh random nonce, so the same plaintext produces a
different token every time.  The token is authenticated (GCM tag); any
modification causes decryption to croak.

Requires L<CryptX> (C<Crypt::AuthEnc::GCM>, C<Crypt::PRNG>).

=head3 EXAMPLE

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

=head3 API SPECIFICATION

=head4 Input

  plaintext  -- SCALAR  -- the string to encrypt.  May be empty.

=head4 Output

  SCALAR  -- the ENC[AES256GCM,...] token (always a printable ASCII string).

=head3 MESSAGES

  "<class>: no encryption key configured ..." -- croak when no key is available.
  "<class>: CryptX (Crypt::AuthEnc::GCM) is required ..." -- croak when CryptX absent.

=head3 PSEUDOCODE

  call _ensure_loaded
  key = _get_encryption_key() -- croak if undef
  load Crypt::AuthEnc::GCM and Crypt::PRNG -- croak if absent
  nonce = 12 random bytes
  gcm = new GCM('AES', key)
  gcm.iv_add(nonce)
  ciphertext = gcm.encrypt_add(plaintext)
  tag = gcm.encrypt_done()
  return "ENC[AES256GCM," + base64url(nonce + ciphertext + tag) + "]"

=cut

sub encrypt_value
{
	my ($self, $plaintext) = @_;

	$self->_ensure_loaded();

	my $key = $self->_get_encryption_key()
		or Carp::croak(ref($self) . ': no encryption key configured (set encryption_key, encryption_key_file, or ENCRYPTION_KEY env var)');

	unless($self->_load_driver('Crypt::AuthEnc::GCM')) {
		Carp::croak(ref($self) . ': CryptX (Crypt::AuthEnc::GCM) is required; install it with: cpanm CryptX');
	}
	unless($self->_load_driver('Crypt::PRNG', ['random_bytes'])) {
		Carp::croak(ref($self) . ': CryptX (Crypt::PRNG) is required; install it with: cpanm CryptX');
	}

	require MIME::Base64;

	my $nonce = random_bytes($_AES_NONCE_SIZE);
	my $gcm   = Crypt::AuthEnc::GCM->new('AES', $key);
	$gcm->iv_add($nonce);
	my $ct  = $gcm->encrypt_add($plaintext);
	my $tag = $gcm->encrypt_done();

	return 'ENC[AES256GCM,' . MIME::Base64::encode_base64url($nonce . $ct . $tag, '') . ']';
}

=head2 merge_defaults

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

=over 4

=item * merge

Usually,
what's in the object will overwrite what's in the defaults hash,
if given,
the result will be a combination of the hashes.

=item * section

Merge in that section from the configuration file.

=item * deep

Try harder to merge all configurations from the global section of the configuration file.

=back

=cut

sub merge_defaults
{
	my $self = shift;
	my $config = $self->all();

	return $config if(scalar(@_) == 0);

	my $params = Params::Get::get_params('defaults', @_);
	my $defaults = $params->{'defaults'};
	return $config if(!defined($defaults));
	my $section = $params->{'section'};

	# Work on a shallow copy so we never mutate $self->{'config'} directly.
	# Without this, 'delete $config->{global}' below would permanently alter
	# the live internal hash on every call.
	my %config_copy = %{$config};
	$config = \%config_copy;

	# Save and restore Hash::Merge's clone behaviour so we don't leak the
	# no-clone global state into unrelated merge() calls (e.g. inside
	# _load_config when a new object is constructed after this method runs).
	my $saved_clone = Hash::Merge::get_clone_behavior();
	Hash::Merge::set_clone_behavior(0);

	if(exists $config->{'global'}) {
		if($params->{'deep'}) {
			$defaults = merge($config->{'global'}, $defaults);
		} else {
			$defaults = { %{$defaults}, %{$config->{'global'}} };
		}
		delete $config->{'global'};
	}
	if($section && exists $config->{$section}) {
		$config = $config->{$section};
	}
	my $result;
	if($params->{'merge'}) {
		$result = merge($config, $defaults);
	} else {
		$result = { %{$defaults}, %{$config} };
	}
	Hash::Merge::set_clone_behavior($saved_clone);
	return $result;
}

# Helper routine to load a driver.
# NOTE: Log::Abstraction must NOT be loaded via this method - it is
# bootstrapped directly in new() to avoid a circular initialisation
# dependency where _load_driver would attempt to log via an as-yet
# uninitialised logger.
sub _load_driver
{
	my($self, $driver, $imports) = @_;

	return 1 if($self->{'loaded'}{$driver});
	return 0 if($self->{'failed'}{$driver});

	eval "require $driver";
	if($@) {
		if(my $logger = $self->{'logger'}) {
			$logger->warn(ref($self), ": $driver failed to load: $@");
		}
		$self->{'failed'}{$driver} = 1;
		return;
	}
	$driver->import(@{ $imports // [] });
	$self->{'loaded'}{$driver} = 1;
	return 1;
}

=head2 Remote configuration directories (Newcastle Connection)

Any entry in C<config_dirs> whose path begins with C</../> is treated as a
remote specification rather than a local directory:

  /../hostname/path/to/dir

The hostname and directory are extracted, and the same standard files searched
locally (C<base.yaml>, C<local.yaml>, C<base.json>, etc.) are fetched from
the remote machine via L<File::Slurp::Remote> over SSH.

When the hostname resolves to the local machine -- C<localhost>, C<127.0.0.1>,
C<::1>, or the value returned by C<Sys::Hostname::hostname()> (checked as
both fully-qualified and short form, case-insensitively) -- the C</../host/>
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
C<~/.ssh/config> for host-specific settings.

L<File::Slurp::Remote> must be installed for remote directories to work.
If it is absent the directory is silently skipped and a warning is emitted.

=head3 Why C</../> (the Newcastle Connection convention)

Several syntaxes were considered for marking a C<config_dirs> entry as remote.
Each alternative was rejected for a concrete reason:

=over 4

=item C<hostname/path> -- ambiguous

Indistinguishable from a relative local directory named C<hostname>.
The module cannot tell at parse time whether C<myserver/etc> is a two-level
local path or a remote specification.

=item C<hostname:/path> -- collides with Windows drive letters

The C<X:\> drive-letter convention on Windows uses exactly the same
C<letter:> prefix.  A single-letter hostname would be misidentified as a
drive, and path-normalisation code on Windows would mangle it.

=item C<file://hostname/path> -- wrong semantics

RFC 8089 defines C<file://> as a reference to a B<local> file.
C<file:///etc/passwd> (three slashes, empty host) is the canonical local form;
C<file://hostname/path> is reserved for the host component but is explicitly
discouraged for general use and is not understood by most tooling as meaning
SSH.

=item C<ssh://hostname/path> -- requires URI parsing

Introduces a dependency on URI parsing (or a bespoke prefix check) and
implies a specific transport.  C<File::Slurp::Remote> already abstracts
the transport; encoding C<ssh://> in the path would be misleading if a future
version of that module supports other transports such as C<rsync://>.

=item C</../hostname/path> -- the Newcastle Connection

The Newcastle Connection (Brownbridge, Dion, Elsworth, 1982) is a distributed
Unix convention in which the token C</../> at the start of a pathname means
"leave the local namespace and enter the named remote host".
It works because C</../> B<cannot exist> as a real filesystem path:
C<..> from the root directory resolves back to the root on every POSIX system,
so C</../> always denotes the root itself, never a child of the root.
No pathname-normalisation step, C<chdir>, or filesystem traversal will ever
produce a path that legitimately begins with C</../>, which means the prefix
is a permanent, collision-free sentinel that requires only a regex to detect.

=back

The Newcastle Connection prefix is therefore the only choice that is:

=over 4

=item * unambiguous on all platforms (POSIX and Windows)

=item * impossible to produce accidentally from a real local path

=item * detectable with a single C<m{^\Q/../\E}> regex, no URI parser needed

=item * transport-neutral (the hostname is passed to whatever remote driver is installed)

=back

=head2 AUTOLOAD

This module supports dynamic access to configuration keys via AUTOLOAD.
Nested keys are accessible using the separator,
so C<$config-E<gt>database_user()> resolves to C<< $config->{database}->{user} >>,
when C<sep_char> is set to '_'.

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

    my $user = $config->database_user();	# returns 'alice'

    # or
    $user = $config->database()->{'user'};	# returns 'alice'

    # Attempting to call a nonexistent key
    my $foo = $config->nonexistent_key();	# dies with error

=cut

# ---------------------------------------------------------------------------
# _parse_remote_dir -- detect Newcastle Connection style paths.
#
# Returns ($host, $dir) when $dir begins with /../, empty list otherwise.
# The /../ prefix is syntactically impossible for a real local path so no
# real directory entry is ever misidentified.
# ---------------------------------------------------------------------------
sub _parse_remote_dir
{
	my ($self, $dir) = @_;

	return unless defined($dir);
	return unless $dir =~ m{^\Q/../\E([^/]+)(/.+)?$};
	return ($1, $2 // '/');
}

# ---------------------------------------------------------------------------
# _is_local_host -- true when $host refers to the machine running this code.
#
# Strips any user@ prefix first, then checks the four common ways a caller
# might spell "here": the loopback name, the two loopback addresses, and the
# system hostname (both fully-qualified and short).  Comparison is
# case-insensitive because hostnames are case-insensitive by RFC 1034.
# ---------------------------------------------------------------------------
sub _is_local_host
{
	my ($self, $host) = @_;

	return 0 unless defined($host) && length($host);

	(my $bare = $host) =~ s/^[^@]+@//;	# strip optional user@ prefix

	return 1 if lc($bare) eq 'localhost';
	return 1 if $bare eq '127.0.0.1';
	return 1 if $bare eq '::1';

	# Cache the resolved hostname on the object so Sys::Hostname::hostname()
	# (a syscall) is only made once per Config::Abstraction instance.
	unless(defined $self->{'_cached_hostname'}) {
		require Sys::Hostname;
		$self->{'_cached_hostname'} = lc(Sys::Hostname::hostname());
		($self->{'_cached_short_hostname'} = $self->{'_cached_hostname'}) =~ s/\..*$//;
	}
	return 1 if lc($bare) eq $self->{'_cached_hostname'};
	return 1 if lc($bare) eq $self->{'_cached_short_hostname'};

	return 0;
}

# ---------------------------------------------------------------------------
# _load_remote_dir -- fetch and merge standard config files from one remote
# host/directory pair.
#
# Silently skips files that do not exist; warns (or logs) on parse errors.
# Merges into %$merged_ref using the same Hash::Merge LEFT_PRECEDENT strategy
# as the local pipeline, so remote values override earlier local values.
# ---------------------------------------------------------------------------
sub _load_remote_dir
{
	if(!UNIVERSAL::isa((caller)[0], __PACKAGE__)) {
		Carp::croak('Illegal Operation: This method can only be called by a subclass');
	}

	my ($self, $host, $remote_dir, $merged_ref, $file_list) = @_;
	my $logger = $self->{'logger'};

	unless($self->_load_driver('File::Slurp::Remote')) {
		my $msg = ref($self) . ": File::Slurp::Remote required for /../$host$remote_dir but is not installed";
		$logger ? $logger->warn($msg) : Carp::carp($msg);
		return;
	}

	# Use the same file list as the local pipeline (includes TOML and env-specific tiers).
	# Fall back to the legacy list if none was passed (e.g. from very old callers).
	my @files = $file_list ? @{$file_list}
		: qw(base.yaml base.yml base.json base.xml base.ini base.toml
		     local.yaml local.yml local.json local.xml local.ini local.toml);

	for my $file (@files) {
		my $remote_path = "/../$host$remote_dir/$file";

		if($logger) {
			$logger->debug(ref($self), ' ', __LINE__, ": Looking for remote config $remote_path");
		}

		my $raw = $self->_slurp_remote($host, "$remote_dir/$file");
		next unless defined($raw);

		if($logger) {
			$logger->debug(ref($self), ' ', __LINE__, ": Loading remote config $remote_path");
		}

		my $data = $self->_parse_config_string($raw, $file, $remote_path);
		next unless defined($data);

		if(ref($data) ne 'HASH') {
			my $msg = ref($self) . ": remote $remote_path did not yield a hash; skipping";
			$logger ? $logger->warn($msg) : Carp::carp($msg);
			next;
		}

		push @{$self->{'_source_records'}}, {
			type      => 'file',
			label     => $remote_path,
			flat_data => { _flatten_keys($data) },
		};
		%{$merged_ref} = %{ merge($data, $merged_ref) };
		push @{$merged_ref->{'config_path'}}, $remote_path;
	}
}

# ---------------------------------------------------------------------------
# _slurp_remote -- read a single file from a remote host via SSH.
#
# Wraps File::Slurp::Remote::read_file; returns the raw string on success
# or undef on any error (connection refused, file absent, permission denied).
# Errors are logged at debug level so missing files are not noisy.
# ---------------------------------------------------------------------------
sub _slurp_remote
{
	my ($self, $host, $path) = @_;
	my $logger = $self->{'logger'};

	# NOTE: verify the calling convention of your installed File::Slurp::Remote.
	# Common forms: read_file("$host:$path") or read_file($host, $path).
	my $content = eval { File::Slurp::Remote::read_file($host, $path) };

	if($@) {
		if($logger) {
			$logger->debug(ref($self), ' ', __LINE__, ": Could not read $path from $host: $@");
		}
		return undef;
	}
	return $content;
}

# ---------------------------------------------------------------------------
# _parse_config_string -- parse a raw config string by extension.
#
# Mirrors the format-detection logic used for local files.  INI content is
# written to a File::Temp scratch file because Config::IniFiles requires a
# real filesystem path; the temp file is removed as soon as parsing returns.
#
# Returns a hashref on success, undef on failure.
# ---------------------------------------------------------------------------
sub _parse_config_string
{
	if(!UNIVERSAL::isa((caller)[0], __PACKAGE__)) {
		Carp::croak('Illegal Operation: This method can only be called by a subclass');
	}

	my ($self, $raw, $filename, $label) = @_;
	my $logger = $self->{'logger'};
	my $data;

	eval {
		if($filename =~ /\.ya?ml$/i) {
			$self->_load_driver('YAML::XS', ['Load']);
			$data = YAML::XS::Load($raw);
			$data = $self->_sanitize_yaml_values($data) if defined($data) && ref($data);

		} elsif($filename =~ /\.json$/i) {
			$data = decode_json($raw);

		} elsif($filename =~ /\.xml$/i) {
			if($self->_load_driver('XML::Simple', ['XMLin'])) {
				if($raw !~ /<!ENTITY\s+\w+\s+(?:SYSTEM|PUBLIC)\b/i) {
					$data = XMLin(\$raw, ForceArray => 0, KeyAttr => []);
				}
			} elsif($self->_load_driver('XML::PP')) {
				my $pp = XML::PP->new();
				if(my $tree = $pp->parse(\$raw)) {
					$data = $pp->collapse_structure($tree);
					$data = $data->{'config'} if ($data && $data->{'config'});
				}
			}

		} elsif($filename =~ /\.ini$/i) {
			$self->_load_driver('Config::IniFiles');
			require File::Temp;
			my $tmp = File::Temp->new(SUFFIX => '.ini', UNLINK => 1);
			print {$tmp} $raw;
			$tmp->flush();
			if(my $ini = Config::IniFiles->new(-file => $tmp->filename())) {
				$data = { map {
					my $section = $_;
					$section => { map { $_ => $ini->val($section, $_) } $ini->Parameters($section) }
				} $ini->Sections() };
			}
		}
	};

	if($@) {
		my $err = $@;
		my $msg = ref($self) . ": Failed to parse $label: $err";
		$logger ? $logger->warn($msg) : Carp::carp($msg);
		return undef;
	}

	return $data;
}

sub AUTOLOAD
{
	our $AUTOLOAD;

	my $self = shift;
	my $key = $AUTOLOAD;

	$key =~ s/.*:://;	# remove package name
	return if $key eq 'DESTROY';

	$self->_ensure_loaded();

	# my $val = $self->get($key);
	# return $val if(defined($val));

	# Always use the merged config, not the raw pre-merge $self->{data}.
	# Using $self->{data} here would bypass file and env overrides entirely.
	my $data = $self->{'config'};
	my $sep  = $self->{'sep_char'};

	# When flattening is ON, Hash::Flatten stores keys with '.' as separator.
	# Convert the sep_char-separated AUTOLOAD key to the dotted form first,
	# then fall back to the raw key in case sep_char happens to be '.'.
	if($self->{flatten}) {
		my $dot_key = ($sep ne '.') ? do { (my $k = $key) =~ s/\Q$sep\E/./g; $k } : $key;
		return $data->{$dot_key} if exists $data->{$dot_key};
		return $data->{$key}     if exists $data->{$key};
		croak "No such config key '$key'";
	}

	# Nested (non-flat) mode: walk the config tree one part at a time.
	my $val = $data;
	foreach my $part (split /\Q$sep\E/, $key) {
		if((ref($val) eq 'HASH') && (exists $val->{$part})) {
			$val = $val->{$part};
		} else {
			croak "No such config key '$key'";
		}
	}
	return $val;
}

1;

=head1 ENCRYPTED VALUES

Config::Abstraction supports transparent AES-256-GCM encryption of individual
configuration values.  This lets you store secrets (passwords, API keys, tokens)
in config files without exposing them as plaintext, even when those files are
committed to version control.

=head2 Quick start

B<Step 1 -- generate a key:>

  # 32 random bytes, encoded as 64 hex chars
  perl -e 'use Crypt::PRNG qw(random_bytes); use MIME::Base64 qw(encode_base64url);
           print encode_base64url(random_bytes(32)), "\n"'

Store the result in an environment variable or a key file (outside version control):

  export ENCRYPTION_KEY=<the 44-char base64url output>

B<Step 2 -- encrypt a secret value:>

  perl -MConfig::Abstraction -e '
    my $cfg = Config::Abstraction->new(data => {});
    print $cfg->encrypt_value("my_secret_password"), "\n";
  '

This prints something like:

  ENC[AES256GCM,QkJCQkJCQkJCQkJCO6Gfb0o5...]

B<Step 3 -- paste the token into your config file:>

  # config/base.yaml
  database:
    host: db.example.com
    user: myapp
    password: 'ENC[AES256GCM,QkJCQkJCQkJCQkJCO6Gfb0o5...]'

B<Step 4 -- load and use normally:>

  my $cfg = Config::Abstraction->new(config_dirs => ['config']);
  # $cfg->get('database.password') returns 'my_secret_password' -- already decrypted

=head2 Key configuration

The encryption key is resolved in this order (first match wins):

=over 4

=item 1. C<encryption_key> constructor option (raw bytes, hex, or base64)

=item 2. C<{env_prefix}ENCRYPTION_KEY> environment variable (default: C<APP_ENCRYPTION_KEY>)

=item 3. C<ENCRYPTION_KEY> environment variable

=item 4. File at C<encryption_key_file> constructor option

=item 5. File at C<{env_prefix}ENCRYPTION_KEY_FILE> environment variable

=item 6. File at C<ENCRYPTION_KEY_FILE> environment variable

=back

The key file should contain the key on its first line in any supported format.
B<Never commit the key to version control.>

=head2 Token format

  ENC[AES256GCM,<base64url(nonce || ciphertext || tag)>]

=over 4

=item * C<AES256GCM> -- AES-256 in GCM mode (authenticated encryption)

=item * Nonce -- 12 random bytes (fresh per encryption, never reused)

=item * GCM authentication tag -- 16 bytes; any modification causes decryption to croak

=item * Base64url encoding -- URL-safe alphabet, no padding ambiguity

=back

=head2 Behaviour when no key is configured

If no key is found, C<ENC[...]> tokens are left as literal strings.  This means
the feature is purely opt-in: existing deployments without a key configured are
unaffected.

=head2 Requirements

L<CryptX> (C<Crypt::AuthEnc::GCM>, C<Crypt::PRNG>) must be installed:

  cpanm CryptX

=head1 COMMON PITFALLS

=head2 1. new() returns undef when no configuration is found

C<new()> returns C<undef>, not a blessed object, when no configuration data is
found and no C<data> argument was supplied.  Every caller must check the return value.

  my $cfg = Config::Abstraction->new(config_dirs => ['/etc/myapp']);
  die "No configuration found" unless defined $cfg;
  my $host = $cfg->get('database.host');   # safe

Forgetting the check leads to a cryptic "Can't call method on undef" error later,
with a stack trace that points to C<get()> rather than to the missing config file.

=head2 2. merge_defaults() requires a named argument, not a bare hashref

  # WRONG -- Params::Get fast-path returns the whole config unchanged
  my $merged = $cfg->merge_defaults(\%my_defaults);

  # RIGHT
  my $merged = $cfg->merge_defaults(defaults => \%my_defaults);

With the first form, C<Params::Get> treats the single hashref as the entire
parameter bag and returns the full config without merging anything.

=head2 3. Shallow merge in merge_defaults() silently drops nested keys from defaults

Without C<merge =E<gt> 1>, C<merge_defaults()> uses a plain Perl hash merge
(C<{ %defaults, %config }>) at the top level.  If the config contains a nested hash
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

=head2 4. undef from a higher-priority source permanently wins

C<Hash::Merge> LEFT_PRECEDENT means that an explicit C<undef> (YAML C<~>) in a
higher-priority source overrides a real value in a lower-priority source, including
when the lower-priority value is defined.

  # base.yaml:  timeout: 30
  # local.yaml: timeout: ~

  my $t = $cfg->get('timeout');   # undef -- local.yaml's null wins over base.yaml

This is intentional: it lets a local config deliberately unset a value.  If you
want to detect whether a key was explicitly nulled versus simply absent, use
C<explain_sources()> and inspect the C<sources> list.

=head2 5. Double underscore vs. single underscore in environment variable names

Single underscores are part of the key name; double underscores create a nesting level.

  APP_LOG_LEVEL=debug       => key 'log_level'   (single underscore, flat key)
  APP_DATABASE__HOST=db     => key 'database.host' (double underscore, nested)
  APP_API__RATE_LIMIT=100   => key 'api.rate_limit' (double underscore + single)

A common mistake is using single underscores expecting nested keys:

  APP_DATABASE_HOST=db   # produces key 'database_host', NOT 'database.host'

=head2 6. Using AUTOLOAD requires sep_char set to '_'

AUTOLOAD translates method names to config keys using C<sep_char>.  The default
C<sep_char> is C<'.'>, but method names cannot contain dots.  Set C<sep_char =E<gt> '_'>
to use AUTOLOAD, and be aware that this makes single underscores into hierarchy separators.

  my $cfg = Config::Abstraction->new(
      data    => { database => { host => 'localhost' } },
      sep_char => '_',
      config_dirs => [],
  );
  my $host = $cfg->database_host();   # works
  my $bad  = $cfg->no_such_key();    # dies: No such config key 'no_such_key'

=head2 7. Absolute config_file paths require an empty or omitted config_dirs

On Unix, C<File::Spec-E<gt>catfile('/etc', '/absolute/path.yaml')> concatenates the
two strings instead of letting the absolute path take over, producing a wrong path.
When C<config_file> is an absolute path, either omit C<config_dirs> entirely
(the constructor sets it to C<['']> automatically) or pass C<config_dirs =E<gt> ['']>
explicitly.

  # WRONG on Unix -- produces '/etc/etc/myapp/app.yaml'
  Config::Abstraction->new(
      config_file => '/etc/myapp/app.yaml',
      config_dirs => ['/etc'],
  );

  # RIGHT
  Config::Abstraction->new( config_file => '/etc/myapp/app.yaml' );

=head2 8. Tests must isolate from the developer's real config files

A call to C<new()> without C<config_dirs> will scan C</etc>, C<~/.conf>,
C<~/.config>, and other default locations and load any C<base.yaml> or
C<local.yaml> it finds there.  In a test suite this injects real host
configuration into your test object, causing non-deterministic failures.

Always pass C<config_dirs =E<gt> []> in tests that use only in-memory C<data>:

  my $cfg = Config::Abstraction->new(
      data        => { key => 'value' },
      config_dirs => [],              # do not scan the filesystem
  );

=head2 9. lazy => 1 defers errors until the first accessor call

With C<lazy =E<gt> 1>, C<new()> always returns a blessed object - it cannot return
C<undef> for a missing config, and any schema validation errors surface at the first
C<get()> or C<all()> call rather than at construction time.  See the C<lazy>
option documentation in L</new> for the full list of debugging implications.

=head1 VERSION HISTORY

Notable changes by release.  Full details are in the C<Changes> file.

=over 4

=item * B<0.40> (unreleased)

TOML file support (C<*.toml>) via C<TOML::Tiny>; C<base.toml> and C<local.toml>
are now discovered automatically alongside the YAML/JSON/XML/INI equivalents,
and TOML is also tried in the all-parsers chain for extensionless C<config_file>
entries.
Lazy loading (C<lazy =E<gt> 1> constructor option) defers all source discovery
and file I/O until the first accessor call.
New C<explain_sources()> method returns a per-key audit trail showing every
source that contributed to a value, in precedence order.
New C<prefer_env()>, C<prefer_file()>, C<prefer_data()>, and C<prefer_argv()>
shortcut methods return the value from a specific source layer without re-ordering.
Fixed C<merge_defaults()> permanently mutating the internal config hash
(now works on a shallow copy).
Fixed C<Hash::Merge> clone-behaviour global state leaking between calls
(C<get_clone_behavior()> is now saved and restored, preventing "Can't store CODE
items" crashes when C<data> contains coderefs).
Newcastle Connection remote configuration: C<config_dirs> entries beginning with
C</../hostname/path> are fetched over SSH via L<File::Slurp::Remote>.
Local-host entries (C</../localhost/>, C</../127.0.0.1/>, etc.) are short-circuited
to a plain local read - no SSH connection is made.

=item * B<0.39> (2026-05-24)

Disabled C<Data::Reuse::fixate()> - behaviour differed between Linux and macOS
in a way that could not be resolved portably.

=item * B<0.38> (2026-05-20)

Fixed corruption of coderefs and blessed objects passed via the C<data> argument
(added C<_is_plain_scalar()> guard in the YAML value-munging loop).
Fixed C<exists()> to return explicit C<0> rather than empty string in flat mode.
Fixed C<Data::Reuse::fixate()> crash in C<get()>.
Fixed circular initialisation crash when the C<logger> option is provided.
Documented the C<defaults> argument to C<new()>.

=item * B<0.36> (2025-10-15)

Added C<exists()> method.
Files that fail to parse now emit a warning and are skipped rather than aborting
construction.

=item * B<0.34> (2025-09-05)

Added C<bin/config-dump> CLI tool.
Schema validation via C<Params::Validate::Strict> (C<schema> option).

=item * B<0.25> (2025-05-15)

Added C<merge_defaults()> C<merge> option (recursive Hash::Merge merge).

=item * B<0.20> (2025-05-06)

Added C<merge_defaults()>.

=item * B<0.19> (2025-05-06)

The C<data> constructor argument now sets default values that are overridden by files.

=item * B<0.13> (2025-04-22)

Added C<data> option to C<new()>.
Added AUTOLOAD support for method-style key access.
Added C<sep_char> option.

=item * B<0.06> (2025-04-09)

C<config_path> key in C<all()> output lists the files actually loaded.
Format drivers are now lazy-loaded (only C<require>d when a file of that format is
found).

=item * B<0.01> (2025-04-07)

First release.

=back

=head1 LIMITATIONS

=over 4

=item * B<No separator escaping>

The separator character (C<sep_char>, default C<.>) cannot be embedded in a key name.
A key that literally contains a dot cannot be accessed via C<get()> when C<sep_char> is
the default.  Workaround: set C<sep_char> to a character not present in any key.

=item * B<Data::Reuse fixation disabled>

The C<Data::Reuse::fixate()> call inside C<get()> is currently a no-op because the
behaviour of C<Crypt::Storable::dclone> differs between Linux and macOS in a way
that cannot be resolved portably (RT#100461).  Hash values returned by C<get()> are
mutable references, not read-only copies.

=item * B<Windows environment variable case sensitivity>

On Windows, environment variable names are case-insensitive at the OS level but
case-sensitive in C<%ENV> as seen by Perl.  Overriding config keys via environment
variables may silently fail if the case does not match exactly.

=item * B<AUTOLOAD requires sep_char set to '_'>

AUTOLOAD method dispatch converts underscores to key separators.  If C<sep_char> is
the default C<'.'>, AUTOLOAD cannot reach nested keys because Perl method names cannot
contain dots.

=item * B<Remote directory TOML support requires File::Slurp::Remote>

TOML files in Newcastle Connection remote directories are only fetched when the
C<File::Slurp::Remote> module is installed.  Without it, remote directories are
skipped entirely regardless of file format.

=back

=head1 BUGS

It should be possible to escape the separator character either with backslashes or quotes.

Due to the case-insensitive nature of environment variables on Windows,
it may be challenging to override values using environment variables on that platform.

=head1 REPOSITORY

L<https://github.com/nigelhorne/Config-Abstraction>

=head1 SUPPORT

This module is provided as-is without any warranty.

Please report any bugs or feature requests to C<bug-config-abstraction at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Config-Abstraction>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

You can find documentation for this module with the perldoc command.

    perldoc Config::Abstraction

=head1 SEE ALSO

=over 4

=item * L<File::Slurp::Remote>

    Used to fetch configuration from remote hosts when C<config_dirs> contains
    Newcastle Connection paths (C</../hostname/path>).

=item * L<Config::Any>

=item * L<Config::Auto>

=item * L<Data::Reuse>

Used to C<fixate()> elements when installed, unless C<no-fixate> is given

=item * L<Hash::Merge>

=item * L<Log::Abstraction>

=item * L<Test Dashboard|https://nigelhorne.github.io/Config-Abstraction/coverage/>

=item * Development version on GitHub L<https://github.com/nigelhorne/Config-Abstraction>

=back

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=encoding UTF-8

=head1 FORMAL SPECIFICATION

=head2 get

  get : Config x Key → Value ∪ {⊥}
  get(c, k) ≜ if k = ⊥ then ⊥
              else lookup(c.config, split(c.sep_char, k))
  lookup(h, [])      ≜ h
  lookup(h, p:rest)  ≜ if p ∉ dom(h) then ⊥
                        else lookup(h[p], rest)

=head2 encrypt_value

  encrypt_value : Config x Plaintext → Token
  encrypt_value(c, p) ≜
    let k  = resolve_key(c)  where k ≠ ⊥
    let n  ~ Uniform(Bytes^12)            -- fresh random nonce
    let ct = AES256GCM_enc(k, n, p)
    let t  = GCM_tag(k, n, p)
    in "ENC[AES256GCM," || base64url(n || ct || t) || "]"

=head2 exists

  exists : Config x Key → {0, 1}
  exists(c, k) ≜ if k = ⊥ then 0
                 else 1 if lookup(c.config, split(c.sep_char, k)) ≠ ⊥
                 else 0

=head2 all

  all : Config → HashRef ∪ {⊥}
  all(c) ≜ if |dom(c.config)| = 0 then ⊥ else c.config

=head1 LICENCE AND COPYRIGHT

Copyright 2025-2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut

1;
