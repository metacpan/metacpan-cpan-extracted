package Config::Validate;

use strict;
use warnings;
use 5.008005;

# There is too much DWIMery here for this to be practical
## no critic (RequireArgUnpacking, ProhibitDoubleSigils)

{
  use Object::InsideOut;

  use Data::Dumper;
  use Clone::PP qw(clone);
  use Scalar::Util qw(blessed);
  use Params::Validate qw(:types validate_with);
  use Carp::Clan;
  use List::MoreUtils qw(any);

  use Exporter qw(import);
  our @EXPORT_OK = qw(validate mkpath);
  our %EXPORT_TAGS = ('all' => \@EXPORT_OK);
  
  our $VERSION = '0.2.6';

  my @schema              :Field 
                          :Accessor(schema) 
                          :Arg(schema);
  my @array_allows_scalar :Field 
                          :Accessor(array_allows_scalar) 
                          :Arg(array_allows_scalar)
                          :Default(1);
  my @debug               :Field 
                          :Accessor(debug) 
                          :Arg(debug);
  my @on_debug            :Field 
                          :Accessor(on_debug) 
                          :Arg(on_debug) 
                          :Default(\&_debug_print);
  my @data_path           :Field 
                          :Accessor(data_path) 
                          :Arg(data_path)
                          :Default(0);
  my @data_path_options   :Field 
                          :Accessor(data_path_options)
                          :Arg(data_path_options)
                          :Default( {} );

  my @types               :Field;

  ## no critic(ProhibitSubroutinePrototypes)
  sub _throw (@);
  ## use critic

  my %default_types = (
    integer   => { validate => \&_validate_integer },
    float     => { validate => \&_validate_float },
    string    => { validate => \&_validate_string },
    boolean   => { validate => \&_validate_boolean },
    hash      => { validate => \&_validate_hash }, 
    array     => { validate => \&_validate_array,
                   byreference => 1,
                 }, 
    directory => { validate => \&_validate_directory },
    file      => { validate => \&_validate_file },
    domain    => { validate => \&_validate_domain },
    hostname  => { validate => \&_validate_hostname },
    nested    => { validate => sub { _throw "'nested' is not valid here"; }},
  );

  my %types = %default_types;

  my $have_data_path;

  sub _init :Init {
    my ($self, $args) = @_;
    
    $types[$$self] = clone(\%types);

    unless (defined $have_data_path) {
      eval { require Data::Path; };
      $have_data_path = $@ eq '' ? 1 : 0;
    }

    if ($self->data_path and not $have_data_path) {
      _throw "Data::Path requested, but cannot find module";
    }

    return;
  }

  sub _parse_add_type_params {
    # TODO: This should be updated to allow 'byreference'
    my $spec = { name => { type => SCALAR },
                 validate => { type => CODEREF,
                               optional => 1,
                             },
                 init     => { type => CODEREF,
                               optional => 1,
                             },
                 finish   => { type => CODEREF,
                               optional => 1,
                             },
               };
    return validate_with(params         => \@_,
                         spec           => $spec,
                         stack_skip     => 2,
                         normalize_keys => sub {
                           return lc $_[0];
                         },
                        );
  }

  sub add_default_type {
    # this is a function, but if it's called as a method, that's
    # fine too.
    my $self;
    if (@_) {
      $self = shift if blessed $_[0];
      shift if $_[0] eq 'Config::Validate';
    }
      
    my %p = _parse_add_type_params(@_);    
    if ($self) {
      $self->add_type(%p);
    }

    if (defined $types{$p{name}}) {
      _throw "Attempted to add type '$p{name}' that already exists";
    }

    my $type = clone(\%p);
    delete $type->{name};
    if (keys %$type == 0) {
      _throw "No callbacks defined for type '$p{name}'";
    }
    $types{$p{name}} = $type;
    

    return;
  }

  sub add_type {
    my $self = shift;
    my %p = _parse_add_type_params(@_);
    
    if (defined $types[$$self]{$p{name}}) {
      _throw "Attempted to add type '$p{name}' that already exists";
    }
    
    my $type = clone(\%p);
    delete $type->{name};
    if (keys %$type == 0) {
      _throw "No callbacks defined for type '$p{name}'";
    }
    $types[$$self]{$p{name}} = $type;
    return;
  }

  sub reset_default_types {
    %types = %default_types;
    return;
  }

  sub _type_callback {
    my ($self, $callback, @args) = @_;

    while (my ($name, $value) = each %{ $types[$$self] }) {
      if (defined $value->{$callback}) {
        $value->{$callback}(@args);
      }
    }
    return;
  }  

  # Unfortunately, the validate function/method used to not use
  # Params::Validate, and used to instead be callable as a one
  # argument version as an instance method, or a two argument version
  # (schema and config) as a function.  This functin is to detect
  # which way it is being called, and normalize the argument list.
  sub _parse_validate_args {
    my (@args) = @_;

    if (@args < 2) {
      _throw "Config::Validate::validate requires at least two arguments";
    }

    my $self;
    if (blessed $args[0]) {
      # called as a method
      $self = shift @args;
      if (@args == 1) {
        @args = (schema => $schema[$$self], 
                 config => $args[0]);
      } else {
        push(@args, schema => $self->schema);
      }
    } else {
      $self = Config::Validate->new();
      if (@args == 2) {
        @args = (config => $args[0],
                 schema => $args[1]);
      }
    }

    my $spec = { schema => { type => HASHREF },
                 config => { type => HASHREF },
               };
    my %args = validate_with(params         => \@args,
                             spec           => $spec,
                             stack_skip     => 2,
                             normalize_keys => sub { 
                               return lc $_[0];
                             },
                            );
    
    return ($self, %args);
  }

  sub validate {
    my ($self, %args) = _parse_validate_args(@_);
    my ($config, $schema) = (clone($args{config}), 
                             clone($args{schema}));

    # Not sure if Config::General object will be extended or not, so
    # assume anything in Config::General namespace as a getall method.
    my $config_type = ref $config;
    if ($config_type =~ /^Config::General/ix) {
      $config = { $config->getall() };
    }

    $self->_type_callback('init', $self, $schema, $config);
    $self->_validate($config, $schema, []);
    $self->_type_callback('finish', $self, $schema, $config);

    if ($self->data_path) {
      return Data::Path->new($config, $self->data_path_options);
    }
    return $config;
  }

  sub _validate {
    my ($self, $cfg, $schema, $path) = @_;

    $schema = clone($schema);
    my $orig = clone($cfg);

    while (my ($canonical_name, $def) = each %$schema) {
      my @curpath = (@$path, $canonical_name);
      my @names = _get_aliases($canonical_name, $def, @curpath);
      $self->_check_definition_type($def, @curpath);

      my $found = 0;
      foreach my $name (@names) {
        next unless defined $cfg->{$name};
        
        if ($name ne $canonical_name) {
          $cfg->{$canonical_name} = $cfg->{$name};
          delete $cfg->{$name};
          delete $orig->{$name};
        }
        
        $self->_debug("Validating ", mkpath(@curpath));
        if (lc($def->{type}) eq 'nested') {
          $self->_validate($cfg->{$canonical_name}, $schema->{$name}{child}, \@curpath);
        } else {
          $self->_invoke_validate_callback($cfg, $canonical_name, $def, \@curpath);
        }
        
        if (defined $def->{callback}) {
          if (ref $def->{callback} ne 'CODE') {
            _throw sprintf("%s: callback specified is not a code reference", 
                        mkpath(@curpath));
          }
          $def->{callback}($self, $cfg->{$canonical_name}, $def, \@curpath);
        }
        $found++;
      }
      
      if (not $found and defined $def->{default}) {
        $cfg->{$canonical_name} = $def->{default};
        $found++;
      }
      
      delete $orig->{$canonical_name};

      if (not $found and (not defined $def->{optional} or not $def->{optional})) {
        _throw "Required item " . mkpath(@curpath) . " was not found";
      }
    }

    my @unknown = sort keys %$orig;
    if (@unknown != 0) {
      _throw sprintf("%s: the following unknown items were found: %s",
                  mkpath($path), join(', ', @unknown));
    }

    return;
  }

  sub _invoke_validate_callback {
    my ($self, $cfg, $canonical_name, $def, $curpath) = @_;

    my $typeinfo = $types[$$self]{$def->{type}};
    my $callback = $typeinfo->{validate};

    if (not defined $callback) {
      _throw("No callback defined for type '$def->{type}'");
    }
      
    if ($typeinfo->{byreference}) {
      $callback->($self, \$cfg->{$canonical_name}, $def, $curpath);
    } else {
      $callback->($self,  $cfg->{$canonical_name}, $def, $curpath);
    }
      
    return;
  }
  
  sub _get_aliases {
    my ($canonical_name, $definition, @curpath) = @_;
    
    my @names = ($canonical_name);
    if (defined $definition->{alias}) {
      if (ref $definition->{alias} eq 'ARRAY') {
        push(@names, @{$definition->{alias}});
      } elsif (ref $definition->{alias} eq '') {
        push(@names, $definition->{alias});
      } else {
        _throw sprintf("Alias defined for %s is type %s, but must be " . 
                      "either an array reference, or scalar",
                      mkpath(@curpath), ref $definition->{alias},
                     );
      }
    }
    return @names;
  }

  sub _check_definition_type {
    my ($self, $definition, @curpath) = @_;
    if (not defined $definition->{type}) {
      _throw "No type specified for " . mkpath(@curpath);
    }

    if (not defined $types[$$self]{$definition->{type}}) {
      _throw "Invalid type '$definition->{type}' specified for ", 
        mkpath(@curpath);
    }

    return;
  }

  # TODO: Make this callable as a method or function
  sub mkpath {
    @_ = @{$_[0]} if ref $_[0] eq 'ARRAY';
    
    return '[/' . join('/', @_) . ']';
  }

  sub _validate_hash {
    my ($self, $value, $def, $path) = @_;
    
    if (not defined $def->{keytype}) {
      _throw "No keytype specified for " . mkpath(@$path);
    }
    
    if (not defined $types[$$self]{$def->{keytype}}) {
      _throw "Invalid keytype '$def->{keytype}' specified for " . mkpath(@$path);
    }

    if (ref $value ne 'HASH') {
      _throw sprintf("%s: should be a 'HASH', but instead is '%s'", 
                  mkpath($path), ref $value);
    }

    while (my ($k, $v) = each %$value) {
      my @curpath = (@$path, $k);
      $self->_debug("Validating ", mkpath(@curpath));
      my $callback = $types[$$self]{$def->{keytype}}{validate};
      $callback->($self, $k, $def, \@curpath);
      if ($def->{child}) {
        $self->_validate($v, $def->{child}, \@curpath);
      }
    }
    return;
  }

  sub _validate_array {
    my ($self, $value, $def, $path) = @_;
    
    if (not defined $def->{subtype}) {
      _throw "No subtype specified for " . mkpath(@$path);
    }

    if (not defined $types[$$self]{$def->{subtype}}) {
      _throw "Invalid subtype '$def->{subtype}' specified for " . mkpath(@$path);
    }
    
    if (ref $value eq 'SCALAR' and $array_allows_scalar[$$self]) {
      $$value = [ $$value ];
      $value = $$value;
    } elsif (ref $value eq 'REF' and ref $$value eq 'ARRAY') {
      $value = $$value;
    }

    if (ref $value ne 'ARRAY') {
      _throw sprintf("%s: should be an 'ARRAY', but instead is a '%s'", 
                  mkpath($path), ref $value);
    }

    my $index = 0;
    foreach my $item (@$value) {
      my @path = ( @$path, "[$index]" );
      $self->_debug("Validating ", mkpath(@path));
      my $callback = $types[$$self]{$def->{subtype}}{validate};
      $callback->($self, $item, $def, \@path);
      $index++;
    }
    return;
  }

  sub _validate_integer {
    my ($self, $value, $def, $path) = @_;
    if ($value !~ /^ -? \d+ $/xo) {
      _throw sprintf("%s should be an integer, but has value of '%s' instead",
                  mkpath($path), $value);
    }
    if (defined $def->{max} and $value > $def->{max}) {
      _throw sprintf("%s: %d is larger than the maximum allowed (%d)", 
                  mkpath($path), $value, $def->{max});
    }
    if (defined $def->{min} and $value < $def->{min}) {
      _throw sprintf("%s: %d is smaller than the minimum allowed (%d)", 
                  mkpath($path), $value, $def->{max});
    }

    return;
  }

  sub _validate_float {
    my ($self, $value, $def, $path) = @_;
    if ($value !~ /^ -? \d*\.?\d+ $/xo) {
      _throw sprintf("%s should be an float, but has value of '%s' instead",
                  mkpath($path), $value);
    }
    if (defined $def->{max} and $value > $def->{max}) {
      _throw sprintf("%s: %f is larger than the maximum allowed (%f)", 
                  mkpath($path), $value, $def->{max});
    }
    if (defined $def->{min} and $value < $def->{min}) {
      _throw sprintf("%s: %f is smaller than the minimum allowed (%f)", 
                  mkpath($path), $value, $def->{max});
    }
    
    return;
  }

  sub _validate_string {
    my ($self, $value, $def, $path) = @_;
    
    if (defined $def->{maxlen}) {
      if (length($value) > $def->{maxlen}) {
        _throw sprintf("%s: length of string is %d, but must be less than %d",
                    mkpath($path), length($value), $def->{maxlen});
      }
    }
    if (defined $def->{minlen}) {
      if (length($value) < $def->{minlen}) {
        _throw sprintf("%s: length of string is %d, but must be greater than %d",
                    mkpath($path), length($value), $def->{minlen});
      }
    }
    if (defined $def->{regex}) {
      if ($value !~ $def->{regex}) {
        _throw sprintf("%s: regex (%s) didn't match '%s'", mkpath($path),
                    $def->{regex}, $value);
      }
    }

    return;
  }

  sub _validate_boolean {
    my ($self, $value, $def, $path) = @_;
    
    my @true  = qw(y yes t true on);
    my @false = qw(n no f false off);
    $value =~ s/\s+//xg;
    $value = 1 if any { lc($value) eq $_ } @true;
    $value = 0 if any { lc($value) eq $_ } @false;
    
    if ($value !~ /^ [01] $/x) {
      _throw sprintf("%s: invalid value '%s', must be: %s", mkpath($path),
                  $value, join(', ', (0, 1, @true, @false)));
    }

    return;
  }
  
  sub _validate_directory {
    my ($self, $value, $def, $path) = @_;

    if (not -d $value) {
      _throw sprintf("%s: '%s' is not a directory", mkpath($path), $value)
    }
    return;
  }
  
  sub _validate_file {
    my ($self, $value, $def, $path) = @_;

    if (not -f $value) {      
      _throw sprintf("%s: '%s' is not a file", mkpath($path), $value);
    }
    return;
  }

  sub _validate_domain {
    my ($self, $value, $def, $path) = @_;

    use Data::Validate::Domain qw(is_domain);
    
    my $rc = is_domain($value, { domain_allow_single_label => 1,
                                 domain_private_tld => qr/.*/x,
                                }
                      );
    if (not $rc) {
      _throw sprintf("%s: '%s' is not a valid domain name.", 
                     mkpath($path), $value);
    }
    return;
  }
  
  sub _validate_hostname {
    my ($self, $value, $def, $path) = @_;

    use Data::Validate::Domain qw(is_hostname);
    
    my $rc = is_hostname($value, { domain_allow_single_label => 1,
                                   domain_private_tld => qr/\. acmedns $/xi,
                                  }
                      );
    if (not $rc) {
      _throw sprintf("%s: '%s' is not a valid hostname.", 
                     mkpath($path), $value);
    }

    return;
  }

  sub _debug {
    my $self = shift;

    return unless $debug[$$self];
    return $on_debug[$$self]->($self, @_);    
  }

  sub _debug_print {
    my $self = shift;

    print join('', @_), "\n";
    return;
  }

  ## no critic
  sub _throw (@) {
    # Turn off O::IO exception handler
    local $SIG{__DIE__};
    croak @_;
  }
  ## use critic

}
1;

__END__

=head1 NAME

Config::Validate - Validate data structures generated from
configuration files. (Or anywhere else)

=head1 VERSION

Version 0.2.6

=head1 DESCRIPTION

This module is for validating configuration data that has been read in
already and is in a Perl data structure.  It does not handle reading
or parsing configuration files since there are a plethora of available
modules on CPAN to do that task.  Instead it concentrates on verifying
that the data read is correct, and providing defaults where
appropriate.  It also allows you to specify that a given configuration
key may be available under several aliases, and have those renamed to
the canonical name automatically.

The basic model used is that the caller provides a schema as a perl
data structure that describes the constraints to verify against.  The
caller can then use the C<Config::Validate> object to validate any
number of data structures against the configured schema.  If the data
structure conforms to the schema given, then a new data structure will
be returned, otherwise an exception is thrown.

Probably the easiest way to explain the intent is that
C<Config::Validate> is trying to be like C<Params::Validate> for
configuration files and other data structures.

This module has the following features:

=over

=item 
* Data structure depth is only limited by stack depth

=item
* Can provide defaults for missing items at any level of the data structure.

=item * Can require that items exist, or items can be optional.

=item * Can validate items in the data structure against a number of built in data types, and users can easily add more data types.

=item * Configuration keys can be known by several names, and will be normalized to the canonical name in the data structure returned by the validation.

=back

=head1 SCHEMA DEFINITION

The most complex part of using C<Config::Validate> is defining the
schema to validate against.  The schema takes the form of set of
nested hashes.

Here is an example schema you might use if you were writing something
that needs to validate a database connection configuration file.

  my $schema = { db => { 
                    type => 'nested',
                    alias => 'dbinfo',
                    child => { 
                       hostname => { 
                          type => 'hostname'
                          alias => [ qw(host server) ],
                          default => 'localhost,
                       },
                       port => { 
                          type => 'integer',
                          max => 64*1024 - 1,
                          min => 1,
                          default => '3306',
                       },
                       username => { 
                          type => 'string'
                          optional => 1,
                          alias => 'user',
                       },
                       password => { 
                          type => 'string',
                          optional => 1,
                          alias => [ qw(pass passwd) ],
                       },
                       database => {
                          type => 'string',
                          alias => 'dbname',
                       },
                       column_types => {
                          type => 'hash',
                          keytype => 'string',
                          child => {
                            id => { 
                               type => 'string',
                               default => 'INT',
                          },
                       },
                    },
                 allowed_users => {
                    type => 'array',
                    subtype => 'string',
                 },
              };

This is a somewhat long example of what a schema can look like.  This
uses most of the features available.  The basic format is that a
schema consists of a hash of hashes.  Each of it's children describe a
single field in the data structure to be validated.  The only required
key in the field definition is C<type>, which defines how that element
in the data/config hash should be validated.

=head2 VALIDATION TYPES

Below is a list of the built in validation types, and the options they
take.  There are several global options that any of these can take
that are documented below.

=head3 nested

The C<nested> type provides a way to validate nested hash references.
Valid options are:

=over 8

=item * child

Hash reference that defines all the valid keys and values in the
nested section.  Required.

=back

=head3 integer

The C<integer> type expects a whole number that can be positive or
negative.  Valid options are:

=over 8

=item * min

Smallest valid value

=item * max

Largest valid value

=back

=head3 float

The C<float> type verifies that the value meets the
C<looks_like_number> test from L<Scalar::Util>.  Valid options are:

=over 8

=item * min

Smallest valid value

=item * max

Largest valid value

=back

=head3 string

The C<string> type does no validation if no addition restrictions are
specified.  Valid options are:

=over 8

=item * min

Minimum length

=item * max

Maximum length

=item * regex

String must match the regex provided.

=back

=head3 boolean

The C<boolean> type looks for a number of specific values, and converts
them to C<0> or C<1>.  The values considered to be true are: C<1>,
C<y>, C<yes>, C<t>, C<true> and C<on>.  The values considered to be
false are C<0>, C<n>, C<no>, C<f>, C<false>, C<off>.  These values are
not case sensitive.  The C<boolean> type takes no options.

=head3 directory

The C<directory> type verifies that the value is a directory that
exists.  The C<directory> type takes no options.

=head3 file

The C<file> type verifies that the value is a file, or a symlink that
points at a file that exists.  The C<file> type takes no options.

=head3 domain

The C<domain> type uses the Data::Validate::Domain C<is_domain>
function to verify that the value is a validate domain name.  This
does not look the value up in DNS and verify that it exists.  The
C<domain> type takes no options.

=head3 hostname

The C<hostname> type uses the Data::Validate::Domain C<is_hostname>
function to verify that the value is a validate hostname name.  This
does not look the value up in DNS and verify that it exists.  The
C<hostname> type takes no options.

=head3 array

The C<array> type verifies that the value is an array reference.  If
the C<array_allows_scalar> option is turned on (it is by default),
then if a scalar value is found, then it will automatically be
converted to an array reference with a single element.

=over 8

=item * subkey

Required option that specifies the type of the elements of the array.

=back

=head3 hash

The C<hash> type validates a hash reference of key/value pairs.  

=over 8

=item * keytype

Required option that specifies the type of validation to do on hash
keys 

=item * child

If the C<hash> type finds a C<child> option, then it will validate any
keys in the hash against the fields in the C<child> definition.  Note
that it is B<NOT> an error if elements are found in the hash that are not
in child.  If you want that behavior, you should use the C<nested>
type instead.

=back

=head2 COMMON OPTIONS

There are a set of options that can be added to any field definition,
that provide a common set of functionality to all.

=over 8

=item * alias

The C<alias> option allows you to specify other names that a
particular field might be known by.  For example, you may have a field
named C<password>, but also want to accept C<pass>, C<passwd> and
C<pw>.  If any of the aliases are found, then they will be renamed in
the data structure that is returned by C<validate>.  This option can
point to a scalar, or an array reference.

=item * callback

The C<callback> option allows you to specify a callback that will be
called after any other validation has been done for a specific field
in the data structure.  The callback sub is called with a reference to
the C<Config::Validate> object (one is created automatically if you're
using the functional interface), the value to be verified, the
definition of the field, and an array reference containing the path
into the data structure.  You can use the C<mkpath> method to convert
the path to a more readable form for error messages and such.

=item * default

The C<default> option allows you to specify a default for the field.
This implicitly means the field is not required to exist in the data
structure being validated.  As many levels as necessary will be
created in the resulting data structure to insure the default is created.

=item * optional

If the C<optional> option is true, then the field is not required.  If
C<optional> is false, or not defined, then the field is required.

=back

=head1 SUBROUTINES/METHODS

=head2 new

The new method constructs a C<Config::Validate> object, and returns
it.  It accepts the following arguments:

=over 8

=item * schema

A validation schema as described in the L<SCHEMA DEFINITION> section
above. 

=item * data_path

If this is set to true, and the C<Data::Path> module is available,
then the C<validate> method/function will encapsulate the results
returned in a C<Data::Path> instance.  Defaults to false;

=item * data_path_options

If the C<data_path> option is true, then this should be a hash
reference to be passed in as the second argument to the C<Data:Path>
constructor.

=item * array_allows_scalar

If this is true, then scalars will be autopromoted to a single element
array reference when validating C<array> types.

=item * debug

Enables debugging output.

=item * on_debug

Allows you to define a callback for debugging output.  A default
callback will be provided if this isn't set.  The default callback
simply prints the debug output to STDOUT.  If you set the callback,
then will be called with the object as the first parameter, and the
additional parameters should be joined to form the entire message.

=back

In addition, any of these can read or changed after the object is
created, via an accessor with the same name as the parameter.

=head2 validate

The validate sub can be called as either a function, or as a instance
method.  

If it is called as an instance method, then it expects a single
C<config> parameter which should be the data structure/config to be
validated.

  my $result = $obj->validate(config => $config)

If it is called as a function, then it accepts two parameters.  The
C<config> parameter should be the data structure/config to be validated,
and the C<schema> parameter should be the schema.

  my $result = validate(config => $config, schema => $schema)

The C<config> parameter above can be a hash reference, or it can be a
C<Config::General> object.  If it is a C<Config::General> object, then
the validate sub will automatically call the C<getall> method on the
object.

If any errors are encountered, then the validate sub will call die to
throw an exception.  In that case the value of C<$@> contain an error
message describing the problem.

There was formerly a one and two argument variant of this sub.  It is
still supported, but deprecated.

=head2 add_type

The C<add_type> method allows you to register a validation type on
just a single instance of C<Config::Validate>.  The parameters are as
follows: 

=over 8

=item * name

This is the name to be specified in the schema to use this validation
type.  This is a mandatory parameter.

=item * validate

The value of C<validate> should be a callback that will be run when it
is necessary to validate a field of this type.  The callback will be
passed the C<Config::Validate> object, the name of the field being
validated, the schema definition of that field, and an array reference
containing the path into the data structure.  You can use the
C<mkpath> method to convert the path to a more readable form for error
messages and such.

=item * init

The value of C<init> should be a callback that will be run before any
validation is done.  The callback will be passed the
C<Config::Validate> object, the schema, and the configuration being
validated.

=item * finish

The value of C<finish> should be a callback that will be run after any
validation is done.  The callback will be passed the
C<Config::Validate> object, the schema, and the configuration being
validated.

=back

=head2 add_default_type

The C<add_default_type> method allows you to register a validation
type for all new C<Config::Validate> instances.  It can be called as a
function, class method, or instance method.  If it is called as an
instance method, then the new type will also be added to that
instance.  The parameters are the same as C<add_type>.

=head2 reset_default_types

The C<reset_default_types> method removes all user defined types from
the base class.  Any instances that are alread created will retain
their existing type configuration.

=head2 mkpath

This is a convenience function for people writing callbacks and user
defined type validation.  It takes either an array or array reference
and returns a string that represents the path to a specific item in
the configuration.  This might be useful if you're interested in
having your error messages be consistent with the rest of
C<Config::Validate>.  This is available for export, but not exported
by default.  Note: this is a function, not a method.

=head1 AUTHOR

Clayton O'Neill

Eval for e-mail address: C<join('@', join('.', qw(cv 20 coneill)), 'xoxy.net')>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2007-2008 by Clayton O'Neill

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.


=cut
