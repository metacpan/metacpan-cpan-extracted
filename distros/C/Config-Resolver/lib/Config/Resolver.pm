package Config::Resolver;

use strict;
use warnings;

use Carp;
use Data::Dumper;
use English qw(-no_match_vars);
use JSON;
use Module::Load;
use Scalar::Util qw(looks_like_number reftype blessed);

use Config::Resolver::Utils qw(is_hash is_array slurp_file);

local $SIG{__WARN__} = 'DEFAULT';
local $SIG{__DIE__}  = 'DEFAULT';

use Readonly;

Readonly::Scalar our $TRUE  => 1;
Readonly::Scalar our $FALSE => 0;
Readonly::Scalar our $EMPTY => q{};

use parent qw(Class::Accessor::Fast);

__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_accessors(
  qw(
    debug
    function_map
    functions
    parameters
    backends
    handler_map
    plugins
    warning_level
    logger
  )
);

our $VERSION = '1.0.10';

########################################################################
sub new {
########################################################################
  my ( $class, @args ) = @_;

  my $options = ref $args[0] ? $args[0] : {@args};

  $options->{warning_level} //= 'error';

  my $self = $class->SUPER::new($options);

  if ( $self->get_logger ) {
    $self->get_logger->debug('initializing resolver...');
  }

  $self->init($options);

  return $self;
}

########################################################################
sub resolve {
########################################################################
  my ( $self, @args ) = @_;

  my ($resolved) = $self->finalize_parameters(@args);

  return $resolved;
}

########################################################################
sub init {
########################################################################
  my ( $self, $options ) = @_;

  # 1. Define our "base" whitelist. These are always safe.
  my %base_functions = (
    uc => sub { return uc( $_[0] // $EMPTY ) },  # (Safer with // '')
    lc => sub { return lc( $_[0] // $EMPTY ) },
  );

  # 2. Get the user's custom functions from the 'new' options.
  #    Default to an empty hash if none are provided.
  my $user_functions = $self->get_functions // {};

  croak "ERROR: 'allowed_functions' must be a HASH reference\n"
    if reftype($user_functions) ne 'HASH';

  # 3. Merge them. The user's functions override the base.
  #    This is the "append" you were talking about.
  my $final_function_map = { %base_functions, %{$user_functions}, };

  # 4. Store the final, merged map in our new accessor.
  $self->set_function_map($final_function_map);

  $self->init_plugins($options);

  return $self;
}

########################################################################
sub init_plugins {
########################################################################
  my ( $self, $options ) = @_;

  # 1. Define our "base" handlers. These are always included.
  my %base_handlers = (
    'env' => sub {
      my ( $path, $params ) = @_;
      return $ENV{$path};
    },
    'file' => sub {
      my ( $path, $params ) = @_;
      # We can use slurp_file now that we've imported it
      return slurp_file($path);
    },
  );

  my $plugin_list   = $self->get_plugins  // [];
  my $user_handlers = $self->get_backends // {};

  # This is the master config: { ssm => { region => ... }, vault => { ... } }
  my $plugin_config_all = $options->{plugin_config} // {};

  my %plugin_handlers;

  foreach my $plugin_name ( @{$plugin_list} ) {
    my $class = "Config::Resolver::Plugin::${plugin_name}";
    load $class;

    # 1. Get the config key from the new package variable
    # This is the "correct" way to check for the package var
    my $protocol;

    my $stash_name = $class . q{::};  # e.g., 'Config::Resolver::Plugin::SSM::'

    {
      no strict 'refs';               ## no critic

      $protocol = ${ $stash_name . 'PROTOCOL' };

      croak "Plugin $class must define a package variable '\$PROTOCOL'."
        if !$protocol;
    }

    # 2. Get the config for this plugin
    my $plugin_specific_config = $plugin_config_all->{$protocol} // {};

    my $logger = $self->get_logger;
    my $log_level;

    if ($logger) {
      $log_level = $logger->level;
    }

    # 3. Create the object
    my $plugin_obj = $class->new(
      { debug         => $options->{debug},
        warning_level => $options->{warning_level},
        logger        => $logger,
        %{$plugin_specific_config},
      }
    );

    if ($logger) {
      $logger->level($log_level);
    }

    $plugin_handlers{$protocol} = $plugin_obj;
  }

  my $final_handler_map = { %base_handlers, %plugin_handlers, %{$user_handlers}, };

  $self->set_handler_map($final_handler_map);

  return $self;
}

########################################################################
sub resolve_value {
########################################################################
  my ( $self, $value, $parameters ) = @_;

  my $handlers = $self->get_handler_map;

  # It checks for the "protocol" pattern first.
  if ( $value =~ /^(\w+):\/\/(.+)$/xsm ) {
    my ( $prefix, $path ) = ( $1, $2 );  # $prefix is the 'xxx'

    if ( my $handler = $handlers->{$prefix} ) {

      my $resolved_val;

      if ( reftype($handler) eq 'CODE' ) {
        $resolved_val = $handler->( $path, $parameters );
      }
      elsif ( blessed($handler) && $handler->can('resolve') ) {
        $resolved_val = $handler->resolve( $path, $parameters );
      }
      else {
        croak "Invalid handler for protocol '$prefix': "
          . 'handler must be a coderef or a blessed object '
          . q{that implements a 'resolve' method.};
      }

      # Handle errors/undefs
      die "could not resolve [$value]\n"
        if !defined $resolved_val && $self->get_warning_level eq 'error';

      # Return the resolved value, defaulting undef to empty string
      return ( $resolved_val // $EMPTY, $parameters );
    }

    # If no backend plugin exists, we can either 'croak' or just
    # fall through and treat it as a literal string.
  }

  if ( $value =~ /\$[{]([\S]+?)[}]/xsm ) {
    my %vars;

    while ( $value =~ /\$[{]([\S]+?)[}]/xsmg ) {
      my $p = $1;

      my $v = $self->get_parameter( $parameters, $p );

      {
        local $SIG{__DIE__} = 'DEFAULT';

        die "could not resolve [$p]\n"
          if !defined $v && $self->get_warning_level eq 'error';
      }

      $vars{$p} = $v;
    }

    foreach my $k ( keys %vars ) {
      if ( !exists $vars{$k} || !defined $vars{$k} ) {
        $vars{$k} = q{};
        print {*STDERR} "WARNING: $k is undefined!\n";
      }

      $value =~ s/\$[{]\Q$k\E[}]/$vars{$k}/xsmg;
    }
    return ( $value, $parameters );
  }

  if ( $value =~ /\$[{]([\S]+?)\s+([\w!=><]+)\s+(.+?)\s+\?\s+(.+?)\s+\:\s+(.+?)\s*[}]/ ) {
    my %dispatch_ops = (
      # Numeric
      q{==} => sub { $_[0] == $_[1] },
      q{!=} => sub { $_[0] != $_[1] },
      q{>}  => sub { $_[0] > $_[1] },
      q{<}  => sub { $_[0] < $_[1] },
      q{>=} => sub { $_[0] >= $_[1] },
      q{<=} => sub { $_[0] <= $_[1] },

      # String
      q{eq} => sub { $_[0] eq $_[1] },
      q{ne} => sub { $_[0] ne $_[1] },
      q{gt} => sub { $_[0] gt $_[1] },
      q{lt} => sub { $_[0] lt $_[1] },
      q{ge} => sub { $_[0] ge $_[1] },
      q{le} => sub { $_[0] le $_[1] },
    );

    # ternary
    my $lhs       = $self->get_parameter( $parameters, $1 );
    my $rhs       = $self->eval_arg( $3, $parameters );
    my $op        = $2;
    my $alt_true  = $self->eval_arg( $4, $parameters );
    my $alt_false = $self->eval_arg( $5, $parameters );

    croak "Invalid operator $op in ternary"
      if !exists $dispatch_ops{$op};

    my $is_true = $dispatch_ops{$op}->( $lhs, $rhs );
    my $val     = $is_true ? $alt_true : $alt_false;

    $value =~ s/\$[{]([\S]+?)\s+([\w!=><]+)\s+(.+?)\s+\?\s+(.+?)\s+\:\s+(.+?)\s*[}]/$val/;

    return ( $value, $parameters );
  }

  return ( $value, $parameters );
}

########################################################################
sub eval_arg {
########################################################################
  my ( $self, $arg, $parameters ) = @_;

  # 1. Is it a number? (e.g., 123)
  if ( looks_like_number($arg) ) {
    return $arg;
  }

  # 2. Is it a quoted string? (e.g., "prod-db" or 'dev-db')
  if ( $arg =~ / ^ (["']) (.*?) \1 $ /xsm ) {
    my $val = $2;  # Get the captured content

    # Un-escape any backslashed quotes
    $val =~ s/ \\ (["']) /$1/gx;

    return $val;
  }

  # 3. If it's not a number or quoted string, it must be a
  #    variable path (e.g., database.dev).
  return $self->get_parameter( $parameters, $arg );
}

########################################################################
sub _resolve_array {
########################################################################
  my ( $self, $obj, $parameters ) = @_;

  foreach my $val ( @{$obj} ) {
    ( $val, $parameters ) = $self->finalize_parameters( $val, $parameters );
  }

  return ( $obj, $parameters );
}

########################################################################
sub _resolve_hash {
########################################################################
  my ( $self, $obj, $parameters ) = @_;

  foreach my $key ( keys %{$obj} ) {
    my $val;

    ( $val, $parameters ) = $self->finalize_parameters( $obj->{$key}, $parameters );

    $obj->{$key} = $val;
  }

  return ( $obj, $parameters );
}

########################################################################
sub finalize_parameters {
########################################################################
  my ( $self, $obj, $parameters ) = @_;

  $parameters //= $self->get_parameters // {};

  return $self->resolve_value( $obj, $parameters )
    if !is_hash($obj) && !is_array($obj);

  return $self->_resolve_hash( $obj, $parameters )
    if is_hash($obj);

  return $self->_resolve_array( $obj, $parameters );
}

########################################################################
sub get_value {
########################################################################
  my ( $self, $obj, $path ) = @_;

  my @parts = split /[.]/xsm, $path;

  croak "error: invalid path [$path]\n"
    if !@parts;

  while ( @parts > 1 ) {
    last if !ref $obj;

    my ( $key, $idx ) = is_key_or_idx( shift @parts );

    if ( defined $key ) {
      $obj = $obj->{$key};
    }

    if ( defined $idx ) {
      $obj = $obj->[$idx];
    }
  }

  my ( $key, $idx ) = is_key_or_idx( shift @parts );

  return
    if !ref $obj;

  if ( defined $key ) {
    $obj = $obj->{$key};
  }

  if ( defined $idx ) {
    $obj = $obj->[$idx];
  }

  return $obj;
}

########################################################################
sub get_parameter {
########################################################################
  my ( $self, $obj, $path ) = @_;

  die "error: no path\n"
    if !$path;

  die "error: no parameter store defined\n"
    if !$obj;

  # --- FETCH THE PRE-BUILT MAP ---
  # It no longer defines its own hash.
  my $func_map = $self->get_function_map;

  my $function;

  if ( $path =~ /^([[:alpha:]_:]+)[(](.*?)[)]$/ixsm ) {
    ( $function, $path ) = ( $1, $2 );
  }

  return $self->get_value( $obj, $path )
    if !$function;

  # 1. Check if the requested function exists in our map
  croak "ERROR: function '$function' is not permitted in resolver.\n"
    if !exists $func_map->{$function};

  # 2. Get the argument's value
  my $arg = $self->get_value( $obj, $path );

  # 3. Safely call the function via its code reference
  my $result = $func_map->{$function}->($arg);

  return $result;
}

########################################################################
sub is_key_or_idx {
########################################################################
  my ($p) = @_;

  my ( $key, $idx );

  # array?
  if ( $p =~ /^([ _[:alpha:][:digit:]]+)\[(\d+)\]$/ixsm ) {
    $key = $1;
    $idx = $2;
  }
  # hash key?
  elsif ( $p =~ /^([ _[:alpha:][:digit:]]+)/ixsm ) {
    $key = $1;
  }

  return ( $key, $idx );
}

1;

__END__

=pod

=head1 NAME

Config::Resolver - Recursively resolve placeholders in a data structure

=head1 SYNOPSIS

 use Config::Resolver;

 # 1. Base use (default, safe functions)
 my $resolver = Config::Resolver->new();
 my $config = $resolver->resolve(
     '${uc(greeting)}', { greeting => 'hello' }
 );
 # $config is now 'HELLO'

 # 2. Extended use (injecting a custom "allowed" function)
 my $resolver_ext = Config::Resolver->new(
     functions => {
         'reverse' => sub { return scalar reverse( $_[0] // '' ) },
     }
 );
 my $config_ext = $resolver_ext->resolve(
     '${reverse(greeting)}', { greeting => 'hello' }
 );
 # $config_ext is now 'olleh'
 
 # 3. Pluggable Backends (for ssm://, vault://, etc.)
 
 # A) Dynamically load installed plugins...

 my $my_plugin_config = {
     'ssm' => { 'endpoint_url' => 'http://localhost:4566' }
 };

 my $resolver_plugins = Config::Resolver->new(
     plugins       => [ 'SSM' ],
     plugin_config => $my_plugin_config,
 );
 
 my $ssm_val = $resolver_plugins->resolve('ssm://my/ssm/path');

 # B) Manual "shim" injection
 my $resolver_manual = Config::Resolver->new(
     backends => {
         'my_db' => sub {
             my ($path, $parameters) = @_;
             # ... logic to resolve $path using $parameters ...
             return "value_for_${path}";
         }
     }
 );

 my $db_val = $resolver_manual->resolve('my_db://foo');
 # $db_val is now 'value_for_foo'

=head1 DESCRIPTION

C<Config::Resolver> is a powerful and extensible engine for dynamically
resolving placeholders in complex data structures.

While this module can be used directly in any Perl application
(see L<SYNOPSIS>), it is primarily designed as the engine for the
L<config-resolver.pl> command-line utility .

The C<config-resolver.pl> harness provides a complete, robust, and
testable solution for managing configuration files. It is intended to
replace complex and brittle C<sed>, C<awk>, or C<envsubst> logic
in deployment scripts, such as those found in `docker-entrypoint.sh`
scripts or CI/CD pipelines.

This class allows you to define a configuration that contains
placeholders that can be resolved from multiple sources.

=over 5

=item From a hash reference 

=item By a safe, "allowed-list" function call 

=item By pluggable, protocol-based backends (e.g., C<ssm://>) 

=back

=head1 FEATURES

The C<Config::Resolver> engine (and its harness) are built to
solve common, real-world DevOps and configuration challenges.

=over 4

=item * B<Command-Line Harness>

The primary interface is L<config-resolver.pl>, a robust,
feature-complete utility for all configuration tasks. 

=item * B<"Batteries Included" Backends>

Includes built-in protocol handlers for common use cases,
such as injecting environment variables (C<env://PATH>) and
file contents (C<file://PATH>). See L<"Accessing values from Backends (Protocols)">
for details. 

=item * B<Powerful Conditional Logic>

Replaces complex shell `if/then` logic with a safe, built-in
ternary operator for conditional values. See L<"Using the Ternary Operator">
for details. 

=item * B<Extensible Plugin Architecture>

Dynamically fetch secrets from external systems via plugins
(like the included L<Config::Resolver::Plugin::SSM>)  or manually
injected C<backends>. See L<PLUGIN API> for details. 

=item * B<Safe Function "Allow-List">

Perform simple data transformations (e.g., C<${uc(hostname)}>)
using a safe, `eval`-free "allow-list" of functions that
you can extend. See L<"Accessing values from a function call">
for details. 

=item * B<Robust Batch Processing>

The L<config-resolver.pl> harness supports a powerful C<--manifest>
feature for "Convention Over Configuration" batch processing.

=back

=head1 PLACEHOLDERS

Placeholders in the configuration object can be used to access data
from a hash of provided values, a pluggable backend, or a function
call.

=head2 Accessing values from a hash

You can access values from the C<$parameters> hash using a
dot-notation path. The resolver can traverse nested hash references
and array references.

To access a hash key, use its name:

 ${database.host}

To access an array element, use bracket notation with an index:

 ${servers[0].ip}

The path is split by periods, and each part is checked for either a
hash key or an array index.

=head2 Accessing values from a function call

You can perform simple, safe data transformations by wrapping a
parameter path in a function call.

 ${function_name(arg_path)}

The C<arg_path> (e.g., C<database.host>) is first resolved using
C<get_value()>, and its result is then passed as the only argument
to the function.

The C<function_name> must exist in the "allow-list" of functions
configured when C<Config::Resolver> was instantiated (see the
C<functions> option for C<new()>). This is a safe, C<eval>-free
ispatch.

A base set of functions (C<uc>, C<lc>) are provided by default.
Example:

 # Resolves 'database.host', then passes it to 'uc'
 ${uc(database.host)}

=head2 Accessing values from Backends (Protocols)

This module supports a "protocol" pattern (C<xxx://path>) to resolve
values from external data sources.

=head3 Batteries Included Backends

C<Config::Resolver> ships with two "B-U-T-FULL," built-in backends
that are always available:

=over 4

=item B<env://PATH>

Resolves the value from C<$ENV{PATH}>. This is the "Merlin" move
for injecting environment variables.

 # Resolves to the value of the $USER environment variable
 ${env://USER}

=item B<file://PATH>

Resolves the value by "slurping" the entire contents of the file
at C<PATH>. This is the "show-stopper" for injecting secrets,
certificates, or tokens.

 # Slurps the contents of /var/run/secrets/token
 ${file:///var/run/secrets/token}

=back

=head3 Pluggable Backends

You can add *dynamic* plugins for services like AWS or Vault.
These are loaded via the C<plugins> and C<backends>
options in the C<new()> constructor.

 # (Assuming the 'SSM' plugin is loaded) ssm://my/parameter/path

=head2 Using the Ternary Operator

The resolver supports a powerful, C-style ternary operator for
simple conditional logic directly within your templates. This is
the "Merlin" move that avoids complex shell scripting and replaces
brittle `sed` commands.

The syntax is:

  ${variable_path op "value" ? "true_result" : "false_result"}

=over 4

=item * B<LHS (Left-Hand Side):> This must be a variable path from
your parameters, like C<env> or C<database.host>.

=item * B<OP (Operator):> A "B-U-T-FULL" set of safe string (C<eq>,
C<ne>, C<gt>, C<lt>, C<ge>, C<le>) and numeric (C<==>, C<!= C<E<gt>>>,
C<E<lt>>, C<E<gt>=>, C<E<lt>=>) operators are supported.

=item * B<RHS (Right-Hand Side):> This argument is safely parsed
It can be a literal number (C<123>), a quoted string (C<"prod"> or
C<'staging'>), or another variable path (C<other.variable>)

=item * B<Results (True/False):> These are also safely parsed
and can be literals, quoted strings, or variable paths.

=back

=head3 Example

Given the parameters:
C<< { env => 'prod', db_host => 'prod.db', dev_host => 'dev.db' } >>

This template:

  db_host: ${env eq "prod" ? db_host : dev_host}
  db_port: ${env eq "prod" ? 5432 : 1234}

Will resolve to:

  db_host: prod.db
  db_port: 5432

=head1 METHODS AND SUBROUTINES

=head2 new

Creates a new Resolver object. 

 my $resolver = Config::Resolver->new(
     {
         functions       => { 'reverse' => sub { ... } },
         plugins         => [ 'SSM' ],
         backends        => { 'file' => sub { ... } },
         warning_level   => 'warn',
         debug           => $FALSE,
     }
 ); 

Accepts a hash reference with the following keys: 

=over 5

=item functions

A HASH reference of custom functions to add to the "allow-list"
for C<${...}> function-call placeholders.  (e.g., C<${uc(foo)}>)
These are merged with a base list of safe functions (C<uc>, C<lc>). 

Example:

 functions => { 'reverse' => sub { scalar reverse( $_[0] // '' ) } } 

=item plugins

An ARRAY reference of plugin names to auto-load.  For each name
(e.g., C<'SSM'>), the module will attempt to load
C<Config::Resolver::Plugin::SSM>. 

Loaded plugins register to handle one or more protocols (e.g., C<ssm://>). 

=item backends

A HASH reference mapping protocol prefixes to a handler.  This is
used for manually injecting a "shim" or private handler. 

The key is the protocol prefix (e.g., C<'ssm'>) and the value is a
subroutine reference or an object that implements a C<resolve($path, $parameters)> method. 

B<Note:> Handlers provided here will *override* any auto-loaded
plugins that register the same protocol. 

Example:

 backends => { 'file' => sub { my ($path, $parameters) = @_; return read_file($path); } } 

=item warning_level

Indicates whether a warning or error should be generated when
values cannot be resolved. 

Valid values: 'warn', 'error' 

Default: 'error' 

=item debug

Sets debug mode for this class. 

=back

=head2 resolve( $obj, $parameters )

Recursively resolves all placeholders within a given data structure. 
This is the main method you will call after C<new()>.

=over 5

=item $obj

The data structure (scalar, array ref, or hash ref) to resolve.

=item $parameters (optional)

A HASH reference of key/value pairs used to resolve C<${...}>
placeholders. If not provided, the C<parameters> passed to
C<new()> will be used.

=back

Returns the resolved data structure.

=head2 finalize_parameters( $obj, $parameters )

The internal recursive-descent engine. This is called by C<resolve()>.
It checks the type of C<$obj> and dispatches to C<_resolve_array> (for ARRAY refs) .

=head2 resolve_value( $scalar, $parameters )

Resolves all placeholders within a single scalar value. This method
is the "workhorse" of the resolver and applies resolution in the
following order:

1. Pluggable Backends (e.g., C<ssm://...>) 

2. Simple Hash Lookups (e.g., C<${foo.bar}>) 

3. Ternary Operators (e.g., C<${... ? ...}>) 

Returns the resolved scalar.

=head2 get_parameter( $parameters, $path_string )

Retrieves a value from the C<$parameters> hash, supporting
dot-notation (C<foo.bar>), array-indexing (C<foo.bar[0]>), and
safe function calls (C<uc(foo.bar)>). 

Function calls are validated against the "allow-list" of functions
provided to C<new()>. 

=head2 get_value( $parameters, $path_string )

The core path-traversal engine. Given a HASH ref and a
dot-notation path, this method walks the data structure and
returns the value. 

=head2 eval_arg( $arg_string, $parameters )

A safe, C<eval>-free parser for arguments within a ternary operator. 
It correctly identifies and returns:

1. Numbers (C<123>) 

2. Quoted Strings (C<"foo"> or C<'bar'>), with un-escaping. 

3. Other values, which are assumed to be parameter paths (C<foo.bar>) and are resolved. 

=head1 PLUGIN API

This module is extensible via a plugin architecture. A plugin
is a class in the C<Config::Resolver::Plugin::*> namespace. 
It must adhere to the following contract:

=over 5

=item B<Package Variable: $PROTOCOL>

The plugin package *must* define C<our $PROTOCOL = '...'> . This
variable serves as the *single, explicit key* that C<Config::Resolver>
will use to find this plugin's configuration within the
C<plugin_config> hash.

By convention, this should be the same as the protocol prefix the
plugin handles (e.g., C<'ssm'>).

=item new( $options )

The constructor. It will receive a HASH reference containing *only*
the following keys from the main C<Config::Resolver> instance:

=over 4

=item * C<debug>

=item * C<warning_level>

=item * (and all keys from its specific config hash)

For example, if C<Config::Resolver->new()> is called with:
C<< plugins => ['SSM'], plugin_config => { ssm => { region => 'us-west-2' } } >>

The C<Config::Resolver::Plugin::SSM> `new()` method will receive a
hash reference equivalent to:

 {
   debug         => 0,         # (or 1, if set)
   warning_level => 'error',   # (or 'warn')
   region        => 'us-west-2', # (from the plugin_config)
 }

=back 

=item init( )

This method is called after construction. It must return the
protocol prefix (e.g., C<'ssm'>) or an ARRAY ref of protocols
that this plugin will handle .

=item resolve( $path, $parameters )

The workhorse method. It receives the path string (e.g., C<my/key>)
from the C<xxx://my/key> placeholder and the full parameter hash.
The method must return the resolved value.

=back

=head1 SEE ALSO

L<Config::Resolver::Utils>

=head1 AUTHOR

Rob Lauer - <rclauer@gmail.com>

=cut

