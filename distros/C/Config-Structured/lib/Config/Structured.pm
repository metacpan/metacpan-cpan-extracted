package Config::Structured 3.01;
use v5.26;
use warnings;

# ABSTRACT: Provides generalized and structured configuration value access

=encoding UTF-8

=head1 NAME

Config::Structured - provides generalized and structured configuration value access

=head1 SYNOPSIS

Basic usage:

  use Config::Structured;

  my $conf = Config::Structured->new(
    structure => { 
      db => {
        dsn     => {
          isa         => 'Str',
          default     => '',
          description => 'Data Source Name for connecting to the database',
          url         => "https://en.wikipedia.org/wiki/Data_source_name",
          examples    => ["dbi:SQLite:dbname=:memory:", "dbi:mysql:host=localhost;port=3306;database=prod_myapp"]
        },
        username => {
          isa         => 'Str',
          default     => 'dbuser',
          description => "the database user's username",
        },
        password => {
          isa         => 'Str',
          description => "the database user's password",
          sensitive   => 1,
          notes       => "Often ref'd via file or ENV for security"
        },
      }
    },
    config => { 
      db => {
        username => 'appuser',
        host     => {
          source   => 'env',
          ref      => 'DB_HOSTNAME',
        },
        password => {
          source => 'file',
          ref    => '/run/secrets/db_password',
        },
      }
    }
  );

  say $conf->db->username(); # appuser
  # assuming that the hostname value has been set in the DB_HOSTNAME env var
  say $conf->db->host; # prod_db_1.mydomain.com
  # assuming that the password value has been stored in /run/secrets/db_password
  say $conf->db->password(1); # *mD9ua&ZSVzEeWkm93bmQzG

Hooks example showing how to ensure config directories exist prior to first 
use:

  use File::Path qw(make_path);

  my $conf = Config::Structured->new(
    ...
    hooks => {
      '/paths/*' => {
        on_load => sub($node,$value) {
          make_path($value)
        }
      }
    }
  )

=head1 DESCRIPTION

L<Config::Structured> is a configuration value manager and accessor. Its design
is based on the premise of predefining a structure (which is essentially a schema
plus some metadata) to which the configuration must adhere. This has the effect
of ensuring that when the application accesses its configuration, it has confidence
that the values are of appopriate types, defaults are declared in a consistent
manner, and new configuration nodes cannot be added ad hoc (i.e., without being
declared within the structure).

A configuration  structure is a hierarchical system of nodes. Nodes may be 
branches (containing only other nodes) or leaves (identified by their C<isa> 
key). Any keys are allowed within a leaf node, for custom tracking of arbitrary
metadata, but the following are handled specially by C<Config::Structured>:

=over

=item C<isa>

Required

Type constraint against which the configured value for the given key will be
checked. See L<Moose::Util::TypeConstraints>. Can be set to C<Any> to opt out of
type checking. If a typecheck fails, the L<on_typecheck_error> handler is 
invoked.

=item C<default>

Optional

This key's value is the default configuration value if a data source or value is 
not provided by the configuation.

=item C<sensitive>

Optional

Set to true to mark this key's value as sensitive (e.g., password data). 
Sensitive values will be returned as a string of asterisks unless a truth-y 
value is passed to the accessor

    use builtin qw(true);

    conf->db->pass        # ************
    conf->db->pass(true)  # uAjH9PmjH9^knCy4$z3TM4

This behavior is mimicked in L</to_hash> and L</get_node>.

=item C<description>

Optional

A human-readable description of the configuration option.

=item C<notes>

Optional

Human-readable implementation notes of the configuration node. 

=item C<examples>

Optional

One or more example values for the given configuration node.

=item C<url>

Optional

A web URL to additional information about the configuration node or resource

=back

=head1 CONSTRUCTORS

=head2 Config::Structured->new( %params )

Returns a C<Config::Structured> node (a dynamically-generated subclass of 
C<Config::Structured::Node>). Nodes implement all methods in the L<METHODS> 
section, plus those corresponding to the configuration keys defined in their 
structure definition. 

Parameters:

=head4 structure

Required

Either a string or a HashRef. If a string is passed, it is handed off to 
L<Data::Structure::Deserialize::Auto>, which attempts to parse a 
YAML, JSON, TOML, or perl string value or filename of an existing, readable file
containing data in one of those formats, into its corresponding perl data 
structure. The format of such a structure is detailed in the L</DESCRIPTION> 
section.

=head4 config

Required

Either a string or a HashRef. If a string is passed, it is handed off to 
L<Data::Structure::Deserialize::Auto>, which attempts to parse a 
YAML, JSON, TOML, or perl string value or filename of an existing, readable file
containing data in one of those formats, into its corresponding perl data 
structure. Its format should mirror that of its C<structure> except that its 
leaf nodes should contain the configured value for that key.

=head5 Referenced Value

In some cases, however, it is inconvenient or insecure to store the configuation
value here (such as with passwords). In that case, the actual configuration 
value may be stored in a separate file or an environment variable, and a 
reference may be used in C<config> to point to it. To invoke this behavior,
the node's L</isa> must be a string type (such as C<Str> or C<Str|Undef>). Then,
set the config value to a HashRef containing two keys:

=over

=item * source - C<"file"> or C<"env">

=item * ref - the filesystem path (relative or absolute) or the name of the environment variable holding the value

=back

If the value is pulled from a file, it will be L<chomp|https://perldoc.perl.org/functions/chomp>ed.

=head4 hooks

Optional

A HashRef whose keys are config paths. A config path is a slash-separated string
of config node keys, beginning with a root slash. Asterisks are valid placeholders
for full or partial path components. E.g.:

    /db/user
    /db/*
    /email/recipients/admin_*
    /*/password

The values corresponding to these keys are HashRefs whose keys are supported 
hook types. Two types of hooks are supported:

=over

=item * on_load - these hooks are run once, when the applicable config node is constructed

=item * on_access - these hooks are run each time the applicable config node is invoked

=back

The values corresponding to those keys are CodeRefs (or ArrayRefs of CodeRefs) to
run when the appropriate events occur on the specified config paths.

The hook function is passed two arguments: the configuration node path, and the
configuration value (which is not obscured, even for sensitive data nodes)

=head4 on_typecheck_error

Optional.

Controls the behavior occurring when a value type constraint check fails. 

=over

=item * fail - die with an error message about the constraint failure

=item * warn (default) - emit a warning and set the value to undef

=item * undef (or any other value) - do nothing and set the value to undef

=back

=head1 METHODS

=pod

=head2 to_hash( $reveal_sensitive = 0 )

Returns the entire configuration tree as hashref. Sensitive values are obscured
unless C<$reveal_sensitive> is true.

=head2 get_node( $child = undef, $reveal_sensitive = 0 )

Get all data and metadata for a given node. If given, C<$child> is the name
of a direct child node to get the data for, otherwise data for the called 
object is returned. For leaf nodes, sensitive values are obscured unless
C<$reveal_sensitive> is true.

Returns a HashRef which always contains the following keys:

=over

=item * C<path> - the full configuration path of the node

=item * C<depth> - how many levels deep this node is in the config (1-based)

=item * C<branches> - ArrayRef of the names of all branch children of this node

=item * C<leaves> - ArrayRef of the names of all leaf children of this node

=back

Additionally, for leaf nodes:

=over

=item * C<value> - the value of the configuration node (possibly obscured)

=item * C<overridden> - boolean value that reflects whether the configuration value for this node is the default (0) or from C<config> (1)

=item * C<reference> - present only if the node uses a L</Referenced Value>, in which case it is a HashRef containing the C<source> and C<ref> keys and values

=item * {structure keys} - all keys and values from the node's structure are present as well (e.g., L</isa>, L</description>, etc., as well as any custom data)

=back

=cut

use Class::Prototyped;
use Data::Structure::Deserialize::Auto qw(deserialize);
use IO::All;
use Moose::Util::TypeConstraints;
use Scalar::Util qw(looks_like_number);
use Syntax::Keyword::Try;
use Readonly;

use experimental qw(signatures);

Readonly::Array my @RESERVED => qw(clone clonePackage destroy DESTROY import new newCore newPackage reflect to_hash get_node);

Readonly::Scalar my $PERL_IDENTIFIER => qr/^ (?[ ( \p{Word} & \p{XID_Start} ) + [_] ])
  (?[ ( \p{Word} & \p{XID_Continue} ) ]) *    $/x;

Readonly::Hash my %TCF_HANDLERS => (
  warn => sub($msg) {warn($msg)},
  fail => sub($msg) {die($msg)}
);

Readonly::Hash my %REF_HANDLERS => (
  env  => sub($ref) {$ENV{$ref}},
  file => sub($ref) {
    try {join($/, io($ref)->chomp->slurp)} catch ($e) {
      die("Can't read referenced file at '$ref': $e")
    }
  },
);

my $base_class = Class::Prototyped->newPackage(__PACKAGE__ . '::Node');

###
#  PRIVATE FUNCTIONS
###
my sub join_path(@path_components) {
  join(q{/}, q{}, @path_components)    #insert an empty string so that the result starts with a slash
}

my sub is_branch($node) {
  try {$node->isa('Class::Prototyped')}
  catch ($e) {0}                       # throws if $node is not blessed
}

my sub check_value_type ($isa, $value) {
  my $tc = Moose::Util::TypeConstraints::find_or_parse_type_constraint($isa);
  die("invalid typeconstraint '$isa'") unless (defined($tc));
  return $tc->check($value);
}

my sub is_ref_value($def, $cfg) {
  return 0 if ($def->{isa} !~ /^str/i);
  return 0 if (ref($cfg) ne 'HASH');
  return exists($cfg->{ref}) && exists($cfg->{source});
}

my sub resolve_ref_value($def, $cfg) {
  my ($ref, $src) = @{$cfg}{qw(ref source)};
  my $h = $REF_HANDLERS{$src};
  die("invalid reference source type: '$src'") unless (defined($h));
  return $h->($ref);
}

my sub stringify_value($v) {
  return 'undef' unless (defined($v));
  return encode_json($v) if (ref($v));
  return qq{"$v"}        if (!looks_like_number($v));
  return $v;
}

my sub resolve_value($k, $def, $cfg) {
  my $v;
  if (!exists($cfg->{$k})) {
    $v = $def->{default};
  } elsif (is_ref_value($def, $cfg->{$k})) {    # indirect value
    $v = resolve_ref_value($def, $cfg->{$k});
  } else {
    $v = $cfg->{$k};
  }
  return $v if (check_value_type($def->{isa}, $v));
  die("value " . stringify_value($v) . " does not conform to type '" . $def->{isa} . "'");
  return ();
}

my sub get_hooks($hooks, $path, $type) {
  my @h;
  foreach my $p (keys($hooks->%*)) {
    my $pat = $p =~ s|[*]|[^/]*|gr;    # path wildcard to regex
    if ($path =~ /$p/) {
      my $t = $hooks->{$p}->{$type};
      push(@h, grep {ref($_) eq 'CODE'} (ref($t) eq 'ARRAY' ? $t->@* : ($t)));
    }
  }
  return @h;
}

my sub valid_children(@list) {
  my @v;
  foreach my $i (@list) {
    next if ($i =~ /[*]$/);                 # skip parent slots (ending in *)
    next if (grep {$_ eq $i} @RESERVED);    # skip reserved words
    push(@v, $i);
  }
  return @v;
}

###
#  CONSTRUCTOR
###
sub new($class, %args) {
  die("structure is a required parameter") unless (defined($args{structure}));
  die("config is a required parameter")    unless (defined($args{config}));

  # process %args
  my $config    = ref($args{config})    ? $args{config}    : deserialize($args{config});
  my $structure = ref($args{structure}) ? $args{structure} : deserialize($args{structure});
  my $hooks     = $args{hooks} // {};
  my $path      = $args{path}  // [];
  my $tc_fail   = $TCF_HANDLERS{exists($args{on_typecheck_error}) ? $args{on_typecheck_error} : 'warn'};

  my $obj = Class::Prototyped->new(
    '*'     => $base_class,
    to_hash => sub($self, $reveal = 0) {
      return {
        (map {$_ => $self->$_($reveal)} $self->get_node->{leaves}->@*),
        (map {$_ => $self->$_->to_hash($reveal)} $self->get_node->{branches}->@*),
      };
    },
    get_node => sub($self, $name = undef, $reveal = 0) {
      my @children = valid_children($self->reflect->slotNames);
      my $node     = defined($name) ? $self->$name($reveal) : $self;
      my $details  = {};
      unless (is_branch($node)) {
        $details               = {$structure->{$name}->%*};
        $details->{overridden} = (exists($config->{$name}) ? 1 : 0), $details->{value} = $node;
        $details->{reference}  = $config->{$name} if (is_ref_value($structure->{$name}, $config->{$name}));
      }
      $details->{branches} = [grep {is_branch($self->$_)} @children];
      $details->{leaves}   = [grep {!is_branch($self->$_)} @children];
      $details->{path}     = join_path(grep {defined} ($path->@*, $name));
      $details->{depth}    = defined($name) ? scalar($path->@*) + 1 : scalar($path->@*);
      return $details;
    },
  );

  foreach my $k (keys($structure->%*)) {
    # Ensure key does not conflict with a method
    warn("Reserved token '$k' found in structure definition. Skipping...") and next
      if ($k !~ $PERL_IDENTIFIER || grep {$_ eq $k} @RESERVED);
    my $npath = join_path($path->@*, $k);
    if (exists($structure->{$k}->{isa})) {    # leaf node
      my $v;
      try {
 # actually finding the value is complicated: it can come from default, config, env, or a file, so abstract it away in resolve_value
        $v = resolve_value($k, $structure->{$k}, $config);
      } catch ($e) {
        # Catch any errors in value resolutuion and call preferred handler
        $e =~ /(.*) (at .* line .*)$/;
        $tc_fail->(__PACKAGE__ . " $1 for cfg path $npath\n") if (defined($tc_fail));
      }
      # ON_LOAD HANDLER
      $_->($npath, $v) foreach (get_hooks($hooks, $npath, 'on_load'));
      # sub that's run on access to leaf node
      $obj->reflect->addSlot(
        $k => sub($self, $reveal_sensitive = 0) {
          # ON_ACCESS HANDLER
          $_->($npath, $v) foreach (get_hooks($hooks, $npath, 'on_access'));
          # Return the value, unless it's sensitive in which case obscure it
          return ($structure->{$k}->{sensitive} && !$reveal_sensitive && defined($v)) ? '*' x 12 : $v;
        }
      );
    } else {    # branch node - recursively call constructor for the next-level down node
                # important! recursively create node outside of sub so that we frontend all node value resolution
                # otherwise, on_load handlers wouldnt't get called until the parent node was accessed
      my $branch = __PACKAGE__->new(
        config    => $config->{$k} // {},
        structure => $structure->{$k},
        path      => [$path->@*, $k],
        hooks     => $hooks,
      );
      # sub that's run on access to branch node (use same signature to be consistent with leaves)
      $obj->reflect->addSlot($k => sub($self, $reveal_sensitive = 0) {$branch});
    }
  }

  return $obj;
}

=pod

=head1 CAVEATS

Some tokens are unavailable to be used as configuration node keys. The following 
keys, as well as any key that is not a 
L<valid perl identifier|https://perldoc.pl/perldata#Identifier-parsing>, are
disallowed - if used in a structure file, a warning will be emitted and the 
applicable node will be discarded.

=over

=item * C<clone>

=item * C<clonePackage>

=item * C<destroy>

=item * C<DESTROY>

=item * C<import>

=item * C<new>

=item * C<newCore>

=item * C<newPackage>

=item * C<reflect>

=item * C<to_hash>

=item * C<get_node>

=back

=head1 AUTHOR

Mark Tyrrell C<< <mark@tyrrminal.dev> >>

=head1 LICENSE

Copyright (c) 2024 Mark Tyrrell

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut

1;

__END__
