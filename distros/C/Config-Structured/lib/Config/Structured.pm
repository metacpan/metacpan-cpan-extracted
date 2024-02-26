package Config::Structured 2.006;
use v5.22;
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
        host     => {
          isa         => 'Str',
          default     => 'localhost',
          description => 'the database server hostname',
        },
        username => {
          isa         => 'Str',
          default     => 'dbuser',
          description => 'the database user's username',
        },
        password => {
          isa         => 'Str',
          description => 'the database user's password',
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
  say $conf->db->password(); # *mD9ua&ZSVzEeWkm93bmQzG

Hooks example showing how to ensure config directories exist prior to first 
use:

  my $conf = Config::Structured->new(
    ...
    hooks => {
      '/paths/*' => {
        on_load => sub($node,$value) {
          Mojo::File->new($value)->make_path
        }
      }
    }
  )

=head1 DESCRIPTION

L<Config::Structured> provides a structured method of accessing configuration values

This is predicated on the use of a configuration C<structure> (required), This structure
provides a hierarchical structure of configuration branches and leaves. Each branch becomes
a L<Config::Structured> method which returns a new L<Config::Structured> instance rooted at
that node, while each leaf becomes a method which returns the configuration value.

The configuration value is normally provided in the C<config> hash. However, a C<config> node
for a non-Hash value can be a hash containing the "source" and "ref" keys. This permits sourcing
the config value from a file (when source="file") whose filesystem location is given in the "ref"
value, or an environment variable (when source="env") whose name is given in the "ref" value.

I<Structure Leaf Nodes> are required to include an "isa" key, whose value is a type 
(see L<Moose::Util::TypeConstraints>). If typechecking is not required, use isa => 'Any'.
There are a few other keys that L<Config::Structured> respects in a leaf node:

=over

=item C<default>

This key's value is the default configuration value if a data source or value is not provided by
the configuation.

=item C<description>

=item C<notes>

A human-readable description and implementation notes, respectively, of the configuration node. 
L<Config::Structured> does not do anything with these values at present, but they provides inline 
documentation of configuration directivess within the structure (particularly useful in the common 
case where the structure is read from a file)

=back

Besides C<structure> and C<config>, L<Config::Structured> also accepts a C<hooks> argument at 
initialization time. This argument must be a HashRef whose keys are patterns matching config
node paths, and whose values are HashRefs containing C<on_load> and/or C<on_access> keys. These
in turn point to CodeRefs which are run when the config value is initially loaded, or every time
it is accessed, respectively.

=cut

=pod

=head1 CONSTRUCTORS

=head2 Config::Structured->new( config => {...}, structure => {...} )

Returns a new C<Config::Structured> instance. C<config> and C<structure> are
required parameters and must either be HashRefs or strings containing a data
structure in C<JSON>, C<YAML>, or C<perl> (i.e., L<Data::Dumper>) formats. The
format of the structure will be autodetected. The content of these data 
structures is detailed above in the C<DESCRIPTION> section.

=head1 METHODS

=head2 get( [$name] )

Class method.

Returns a registered L<Config::Structured> instance.  If C<$name> is not provided, returns the default instance.
Instances can be registered with C<__register_default> or C<__register_as>. This mechanism is used to provide
global access to a configuration, even from code contexts that otherwise cannot share data.

=head2 __register_default()

Call on a L<Config::Structured> instance to set the instance as the default.

=head2 __register_as( $name )

Call on a L<Config::Structured> instance to register the instance as the provided name.

=head2 __get_child_node_names()

Returns a list of names (strings) of all immediate child nodes of the current config node

=cut

use Moose;

use Carp;
use Data::DPath qw(dpath);
use Data::Printer;    # not debug, used for Carp message in $make_leaf_generator
use Data::Structure::Deserialize::Auto;
use IO::All;
use List::Util qw(reduce);
use Mojo::DynamicMethods -dispatch;
use Moose::Util::TypeConstraints;
use Perl6::Junction qw(any);
use Readonly;
use Text::Glob qw(match_glob);

use experimental qw(signatures lexical_subs);

# Symbol constants
Readonly::Scalar my $EMPTY => q{};
Readonly::Scalar my $SLASH => q{/};

# Token key constants
Readonly::Scalar my $DEF_ISA     => q{isa};
Readonly::Scalar my $DEF_DEFAULT => q{default};
Readonly::Scalar my $CFG_SOURCE  => q{source};
Readonly::Scalar my $CFG_REF     => q{ref};

# Token value constants
Readonly::Scalar my $CONF_FROM_FILE => q(file);
Readonly::Scalar my $CONF_FROM_ENV  => q(env);

# Method names that are needed by Config::Structured and cannot be overridden by config node names
Readonly::Array my @RESERVED =>
  qw(get meta BUILDCARGS BUILD BUILD_DYNAMIC _config _structure _hooks _base _add_helper __register_default __register_as __get_child_node_names);

#
# The configuration structure (e.g., $app.conf.def contents)
#
has '_structure_v' => (
  is       => 'ro',
  isa      => 'Str|HashRef',
  init_arg => 'structure',
  required => 1,
);

has '_structure' => (
  is       => 'ro',
  isa      => 'HashRef',
  init_arg => undef,
  lazy     => 1,
  default  => sub($self) {Data::Structure::Deserialize::Auto::deserialize($self->_structure_v)}
);

has '_hooks' => (
  is       => 'ro',
  isa      => 'HashRef[HashRef[CodeRef]]',
  init_arg => 'hooks',
  required => 0,
  default  => sub {{}},
);

#
# The file-based configuration (e.g., $app.conf contents)
#
has '_config_v' => (
  is       => 'ro',
  isa      => 'Str|HashRef',
  init_arg => 'config',
  required => 1,
);

has '_config' => (
  is       => 'ro',
  isa      => 'HashRef',
  init_arg => undef,
  lazy     => 1,
  default  => sub($self) {Data::Structure::Deserialize::Auto::deserialize($self->_config_v)}
);

#
# This instance's base path (e.g., /db)
#   Recursively constucted through re-instantiation of non-leaf config nodes
#
has '_base' => (
  is      => 'ro',
  isa     => 'Str',
  default => $SLASH,
);

#
# Convenience method for adding dynamic methods to an object
#
sub _add_helper (@args) {
  Mojo::DynamicMethods::register __PACKAGE__, @args;
}

around BUILDARGS => sub ($orig, $class, @args) {
  my %args = ref($args[0]) eq 'HASH' ? %{$args[0]} : @args;
  delete($args{hooks}) unless (defined($args{hooks}));
  return $class->$orig(%args);
};

#
# Dynamically create methods at instantiation time, corresponding to configuration structure's dpaths
# Use lexical subs and closures to avoid polluting namespace unnecessarily (preserving it for config nodes)
#
sub BUILD ($self, $args) {
  # lexical subroutines

  state sub pkg_prefix ($msg) {
    '[' . __PACKAGE__ . "] $msg";
  }

  state sub is_hashref ($node) {
    return ref($node) eq 'HASH';
  }

  state sub is_leaf_node ($node) {
    exists($node->{isa});
  }

  state sub is_ref_node ($def, $node) {
    return 0 if ($def->{isa} =~ /hash/i);
    return 0 unless (ref($node) eq 'HASH');
    return (exists($node->{$CFG_SOURCE}) && exists($node->{$CFG_REF}));
  }

  state sub ref_content_value ($node) {
    my $source = $node->{$CFG_SOURCE};
    my $ref    = $node->{$CFG_REF};
    if ($source eq $CONF_FROM_FILE) {
      if (-f -r $ref) {
        chomp(my $contents = io->file($ref)->slurp);
        return $contents;
      }
    } elsif ($source eq $CONF_FROM_ENV) {
      return $ENV{$ref} if (exists($ENV{$ref}));
    }
    return;
  }

  state sub node_value ($el, $node) {
    if (defined($node)) {
      my $v = is_ref_node($el, $node) ? ref_content_value($node) : $node;
      return $v if (defined($v));
    }
    return $el->{$DEF_DEFAULT};
  }

  state sub concat_path($base, $p) {
    reduce {local $/ = $SLASH; chomp($a); join(($b =~ m|^$SLASH|) ? $EMPTY : $SLASH, $a, $b)} ($base, $p);
  }

  state sub typecheck ($isa, $value) {
    my $tc = Moose::Util::TypeConstraints::find_or_parse_type_constraint($isa);
    if (defined($tc)) {
      return $tc->check($value);
    } else {
      carp(pkg_prefix "Invalid typeconstraint '$isa'. Skipping typecheck");
      return 1;
    }
  }

  # Closures
  my $get_node_value = sub ($el, $path) {
    return node_value($el, dpath($path)->matchr($self->_config)->[0]);
  };

  my $get_hooks = sub ($path) {
    return map {$self->_hooks->{$_}} grep {match_glob($_, $path) ? $_ : ()} keys(%{$self->_hooks});
  };

  my $make_leaf_generator = sub ($el, $path) {
    my $isa = $el->{isa};
    my $v   = $get_node_value->($el, $path);

    if (defined($v)) {
      if (typecheck($isa, $v)) {
        my @hooks = grep {defined} map {$_->{on_access}} $get_hooks->($path);
        return sub {
          # access hook
          foreach (@hooks) {$_->($path, $v)}
          return $v;
        }
      } else {
        carp(pkg_prefix "Value '" . np($v) . "' does not conform to type '$isa' for node $path");
      }
    }
    return sub {
      return;
    }
  };

  my $make_branch_generator = sub ($path) {
    return sub {
      return __PACKAGE__->new(
        structure => $self->_structure,
        config    => $self->_config,
        hooks     => $self->_hooks,
        _base     => $path
      );
    }
  };

  foreach my $el (dpath($self->_base)->match($self->_structure)) {
    if (is_hashref($el)) {
      foreach my $def (keys(%{$el})) {
        carp(pkg_prefix "Reserved word '$def' used as config node name: ignored") and next if ($def eq any(@RESERVED));
        $self->meta->remove_method($def)
          ;    # if the config node refers to a method already defined on our instance, remove that method
        my $path = concat_path($self->_base, $def);    # construct the new directive path by concatenating with our base

        # Detect whether the resulting node is a branch or leaf node (leaf nodes are required to have an "isa" attribute)
        # if it's a branch node, return a new Config instance with a new base location, for method chaining (e.g., config->db->pass)
        $self->_add_helper(
          $def => (is_leaf_node($el->{$def}) ? $make_leaf_generator->($el->{$def}, $path) : $make_branch_generator->($path)));
      }
    }
  }

  # Run on_load hooks immediately from root node only since we can't assume that non-root nodes will be created immediately
  if ($self->_base eq $SLASH) {
    sub ($path, $node) {
      foreach (keys(%{$node})) {
        my $p = join($path eq $SLASH ? $EMPTY : $SLASH, $path, $_);    #don't duplicate initial slash in path
        my $n = $node->{$_};
        if (is_leaf_node($n)) {
          my @hooks = grep {defined} map {$_->{on_load}} $get_hooks->($p);
          if (@hooks) {
            my $v = $get_node_value->($n, $p);    #put off resolving the node value until we know we need it
            foreach (@hooks) {$_->($p, $v)}
          }
        } else {
          __SUB__->($p, $n);                      #recurse on the new branch node
        }
      }
      }
      ->($self->_base, $self->_structure);    #initially call on root of structure
  }
}

#
# Handle dynamic method dispatch
#
sub BUILD_DYNAMIC($class, $method, $dyn_methods) {
  return sub($self, @args) {
    my $dynamic = $dyn_methods->{$self}{$method};
    return $self->$dynamic(@args) if ($dynamic);
    my $package = ref $self;
    croak qq{Can't locate object method "$method" via package "$package"};
  }
}

#
# Saved Named/Default Config instances
#
our $saved_instances = {
  default => undef,
  named   => {}
};

#
# Instance method
# Saves the current instance as the default instance
#
sub __register_default ($self) {
  $saved_instances->{default} = $self;
  return $self;
}

#
# Instance method
# Saves the current instance by the specified name
# Parameters:
#  Name (Str), required
#
sub __register_as ($self, $name) {
  croak 'Registration name is required' unless (defined $name);

  $saved_instances->{named}->{$name} = $self;
  return $self;
}

#
# Class method
# Return a previously saved instance. Returns undef if no instances have been saved. Returns the default instance if no name is provided
# Parameters:
#  Name (Str), optional
#
sub get ($class, $name = undef) {
  if (defined $name) {
    return $saved_instances->{named}->{$name};
  } else {
    return $saved_instances->{default};
  }
}

#
# Instance method
# Get all the node names that are children of the current node in config structure
# Returns:
#   List of strings
sub __get_child_node_names ($self) {
  my ($node) = dpath($self->_base)->match($self->_structure);
  return (keys($node->%*));
}

=pod

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
