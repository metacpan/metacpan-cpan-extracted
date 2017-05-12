package Class::MakeMethods::Template;

use strict;
use Carp;

use Class::MakeMethods '-isasubclass';

use vars qw( $VERSION );
$VERSION = 1.008;

sub _diagnostic { &Class::MakeMethods::_diagnostic }

########################################################################
### TEMPLATE LOOKUP AND CACHING: named_method(), _definition()
########################################################################

use vars qw( %TemplateCache );

# @results = $class->named_method( $name, @arguments );
sub named_method {
  my $class = shift;
  my $name = shift;
  
  # Support direct access to cached Template information
  if (exists $TemplateCache{"$class\::$name"}) {
    return $TemplateCache{"$class\::$name"};
  }
  
  my @results = $class->$name( @_ );
  
  if ( scalar @results == 1 and ref $results[0] eq 'HASH' ) {
    # If this is a hash-definition format, cache the results for speed.
    my $def = $results[0];
    $TemplateCache{"$class\::$name"} = $def;
    _expand_definition($class, $name, $def);
    return $def;
  }
  
  return wantarray ? @results : $results[0];
}

# $mm_def = _definition( $class, $target );
sub _definition {
  my ($class, $target) = @_;
  
  while ( ! ref $target ) {
    $target =~ s/\s.*//;
    
    # If method name contains a colon or double colon, call the method on the
    # indicated class.
    my $call_class = ( ( $target =~ s/^(.*)\:{1,2}// ) 
      ? Class::MakeMethods::_find_subclass($class, $1) : $class );
    $target = $call_class->named_method( $target );
  }
  _diagnostic('mmdef_not_interpretable', $target) 
	unless ( ref($target) eq 'HASH' or ref($target) eq __PACKAGE__ );
  
  return $target;
}

########################################################################
### TEMPLATE INTERNALS: _expand_definition()
########################################################################

sub _expand_definition {
  my ($class, $name, $mm_def) = @_;
  
  return $mm_def if $mm_def->{'-parsed'};
  
  $mm_def->{'template_class'} = $class;
  $mm_def->{'template_name'} = $name;
  
  # Allow definitions to import values from each other.
  my $importer;
  foreach $importer ( qw( interface params behavior code_expr modifier ) ) {
    my $rules = $mm_def->{$importer}->{'-import'} || $mm_def->{'-import'};
    my @rules = ( ref $rules eq 'HASH' ? %$rules : ref $rules eq 'ARRAY' ? @$rules : () );
    unshift @rules, '::' . $class . ':generic' => '*' if $class->can('generic');
    while ( 
      my ($source, $names) = splice @rules, 0, 2
    ) {
      my $mmi = _definition($class, $source);
      foreach ( ( $names eq '*' ) ? keys %{ $mmi->{$importer} } 
			: ( ref $names ) ? @{ $names } : ( $names ) ) {
	my $current = $mm_def->{$importer}{$_};
	my $import = $mmi->{$importer}{$_};
	if ( ! $current ) {
	  $mm_def->{$importer}{$_} = $import;
	} elsif ( ref($current) eq 'ARRAY' ) {
	  my @imports = ref($import) ? @$import : $import;
	  foreach my $imp ( @imports ) {
	    push @$current, $imp unless ( grep { $_ eq $imp } @$current );
	  }
	}
      }
    }
    delete $mm_def->{$importer}->{'-import'};
  }
  delete $mm_def->{'-import'};
  
  _describe_definition( $mm_def ) if $Class::MakeMethods::CONTEXT{Debug};

  
  $mm_def->{'-parsed'} = "$_[1]";
  
  bless $mm_def, __PACKAGE__;
}

sub _describe_definition {
  my $mm_def = shift;
  
  my $def_type = "$mm_def->{template_class}:$mm_def->{template_name}";
  warn "----\nMethods info for $def_type:\n";
  if ( $mm_def->{interface} ) {
    warn join '', "Templates: \n", map {
	"  $_: " . _describe_value($mm_def->{interface}{$_}) . "\n"
      } keys %{$mm_def->{interface}};
  }
  if ( $mm_def->{modifier} ) {
    warn join '', "Modifiers: \n", map {
	"  $_: " . _describe_value($mm_def->{modifier}{$_}) . "\n"
      } keys %{$mm_def->{modifier}};
  }
}

sub _describe_value {
  my $value = $_[0];
  ref($value) eq 'ARRAY' ? join(', ', @$value) :
  ref($value) eq 'HASH'  ? join(', ', %$value) : 
				      "$value";
}

########################################################################
### METHOD GENERATION: make_methods()
########################################################################

sub make_methods {
  my $mm_def = shift;
  
  return unless ( scalar @_ );
  
  # Select default interface and initial method parameters
  my $defaults = { %{ ( $mm_def->{'params'} ||= {} ) } };
  $defaults->{'interface'} ||= $mm_def->{'interface'}{'-default'} || 'default';
  $defaults->{'target_class'} = $mm_def->_context('TargetClass');
  $defaults->{'template_class'} = $mm_def->{'template_class'};
  $defaults->{'template_name'} = $mm_def->{'template_name'};
  
  my %interface_cache;
  
  # Our return value is the accumulated list of method-name => method-sub pairs
  my @methods; 

  while (scalar @_) {

    ### PARSING ### Requires: $mm_def, $defaults, @_
    
    my $m_name = shift @_;
    _diagnostic('make_empty') unless ( defined $m_name and length $m_name );
    
    # Normalize: If we've got an array of names, replace it with those names 
    if ( ref $m_name eq 'ARRAY' ) {
      my @items = @{ $m_name };
      # If array is followed by a params hash, each one gets the same params
      if ( scalar @_ and ref $_[0] eq 'HASH' and ! exists $_[0]->{'name'} ) {
	my $params = shift;
	@items = map { $_, $params } @items
      }
      unshift @_, @items;
      next;
    }
    
    # Parse interfaces, modifiers and parameters
    if ( $m_name =~ s/^-// ) {
      if (  $m_name !~ s/^-// ) {
	# -param => value
	$defaults->{$m_name} = shift @_; 
      } else {
	if ( $m_name eq '' ) {
	  # '--' => { param => value ... }
	  %$defaults = ( %$defaults, %{ shift @_ } );
		
	} elsif ( exists $mm_def->{'interface'}{$m_name} ) {
	  # --interface
	  $defaults->{'interface'} = $m_name;
	
	} elsif ( exists $mm_def->{'modifier'}{$m_name} ) {
	  # --modifier
	  $defaults->{'modifier'} .= 
			    ( $defaults->{'modifier'} ? ' ' : '' ) . "-$m_name";
	
	} elsif ( exists $mm_def->{'behavior'}{$m_name} ) {
	  # --behavior as shortcut for single-method interface
	  $defaults->{'interface'} = $m_name;
	
	} else {
	  _diagnostic('make_bad_modifier', $mm_def->{'name'}, "--$m_name");
	}
      }
      next;
    }
    
    # Make a new meta-method hash
    my $m_info;
    
    # Parse string, string-then-hash, and hash-only meta-method parameters
    if ( ! ref $m_name ) {
      if ( scalar @_ and ref $_[0] eq 'HASH' and ! exists $_[0]->{'name'} ) {
	%$m_info = ( 'name' => $m_name, %{ shift @_ } );
      } else {
	$m_info = { 'name' => $m_name };
      }
    
    } elsif ( ref $m_name eq 'HASH' ) {
      unless ( exists $m_name->{'name'} and length $m_name->{'name'} ) {
	_diagnostic('make_noname');
      }
      $m_info = { %$m_name };
    
    } else {
      _diagnostic('make_unsupported', $m_name);
    }
    _diagnostic('debug_declaration', join(', ', map { defined $_ ? $_ : '(undef)' } %$m_info) );

    ### INITIALIZATION ### Requires: $mm_def, $defaults, $m_info
    
    my $interface = (
      $interface_cache{ $m_info->{'interface'} || $defaults->{'interface'} } 
	||= _interpret_interface( $mm_def, $m_info->{'interface'} || $defaults->{'interface'} )
    );
    %$m_info = ( 
      %$defaults, 
      ( $interface->{-params} ? %{$interface->{-params}} : () ),
      %$m_info 
    );

    
    # warn "Actual: " . Dumper( $m_info );


    # Expand * and *{...} strings.
    foreach (grep defined $m_info->{$_}, keys %$m_info) {
      $m_info->{$_} =~ s/\*(?:\{([^\}]+)?\})?/ $m_info->{ $1 || 'name' } /ge
    }
    if ( $m_info->{'modifier'} and $mm_def->{modifier}{-folding} ) {
      $m_info->{'modifier'} = _fold_modifiers( $m_info->{'modifier'}, 
			$mm_def->{modifier}{-folding} )
    }
    
    ### METHOD GENERATION ### Requires: $mm_def, $interface, $m_info
    
    # If the MM def provides an initialization "-init" call, run it.
    if ( local $_ = $mm_def->{'behavior'}->{'-init'} ) {
      push @methods, map $_->( $m_info ), (ref($_) eq 'ARRAY') ? @$_ : $_;
    }
    # Build Methods
    for ( grep { /^[^-]/ } keys %$interface ) { 
      my $function_name = $_;
      $function_name =~ s/\*/$m_info->{'name'}/g;
      
      my $behavior = $interface->{$_};
      
      # Fold in additional modifiers
      if ( $m_info->{'modifier'} ) { 
	if ( $behavior =~ /^\-/ and $mm_def->{modifier}{-folding} ) {
	  $behavior = $m_info->{'modifier'} = 
			_fold_modifiers( "$m_info->{'modifier'} $behavior", 
			    $mm_def->{modifier}{-folding} )
	} else {
	  $behavior = "$m_info->{'modifier'} $behavior";
	}
      }

      my $builder = 
	( $mm_def->{'-behavior_cache'}{$behavior} ) ? 
	$mm_def->{'-behavior_cache'}{$behavior} : 
	( ref($mm_def->{'behavior'}{$behavior}) eq 'CODE' ) ? 
	$mm_def->{'behavior'}{$behavior} : 
_behavior_builder( $mm_def, $behavior, $m_info );
      
      my $method = &$builder( $m_info );
      
      _diagnostic('debug_make_behave', $behavior, $function_name, $method);
      push @methods, ($function_name => $method) if ($method);
    }
    
    # If the MM def provides a "-subs" call, for forwarding and other
    # miscelaneous "subsidiary" or "contained" methods, run it.
    if ( my $subs = $mm_def->{'behavior'}->{'-subs'} ) {
      my @subs = (ref($subs) eq 'ARRAY') ? @$subs : $subs;
      foreach my $sub ( @subs ) {
	my @results = $sub->($m_info);
	if ( scalar @results == 1 and ref($results[0]) eq 'HASH' ) {
	  # If it returns a hash of helper method types, check the method info
	  # for any matching names and call the corresponding method generator.
	  my $types = shift @results;
	  foreach my $type ( keys %$types ) {
	    my $names = $m_info->{$type} or next; 
	    my @names = ref($names) eq 'ARRAY' ? @$names : split(' ', $names);
	    my $generator = $types->{$type};
	    push @results, map { $_ => &$generator($m_info, $_) } @names;
	  }	
	}
	push @methods, @results;
      }
    }
    
    # If the MM def provides a "-register" call, for registering meta-method
    # information for run-time access, run it.
    if ( local $_ = $mm_def->{'behavior'}->{'-register'} ) {
      push @methods, map $_->( $m_info ), (ref($_) eq 'ARRAY') ? @$_ : $_;
    }
  }
  
  return @methods;
}

# I'd like for the make_methods() sub to be simpler, and to take advantage
# of the standard _get_declarations parsing provided by the superclass.
# Sadly the below doesn't work, due to a few order-of-operations peculiarities 
# of parsing interfaces and modifiers, and their associated default paramters.
# Perhaps it might work if the processing of --options could be overridden with
# a callback sub, so that interfaces and their params can be parsed in order.
sub _x_get_declarations {	
  my $mm_def = shift;

  my @declarations = $mm_def::SUPER->_get_declarations( @_ );

  # use Data::Dumper;
  # warn "In: " . Dumper( \@_ );
  # warn "Auto: " . Dumper( \@declarations );

  my %interface_cache;

  while (scalar @declarations) {
    
    my $m_info = shift @declarations;

    # Parse interfaces and modifiers
    my @specials = grep $_, split '--', ( delete $m_info->{'--'} || '' );
    foreach my $special ( @specials ) {
      if ( exists $mm_def->{'interface'}{$special} ) {
	# --interface
	$m_info->{'interface'} = $special;
      
      } elsif ( exists $mm_def->{'modifier'}{$special} ) {
	# --modifier
	$m_info->{'modifier'} .= 
			  ( $m_info->{'modifier'} ? ' ' : '' ) . "-$special";
      
      } elsif ( exists $mm_def->{'behavior'}{$special} ) {
	# --behavior as shortcut for single-method interface
	$m_info->{'interface'} = $special;
      
      } else {
	_diagnostic('make_bad_modifier', $mm_def->{'name'}, "--$special");
      }
    }

    my $interface = (
	$interface_cache{ $m_info->{'interface'} } 
	  ||= _interpret_interface( $mm_def, $m_info->{'interface'} )
    );
    $m_info = { %$m_info, %{$interface->{-params}} } if $interface->{-params};

    _diagnostic('debug_declaration', join(', ', map { defined $_ ? $_ : '(undef)' } %$m_info) );
    
    # warn "Updated: " . Dumper( $m_info );
  }
}

########################################################################
### TEMPLATES: _interpret_interface()
########################################################################

sub _interpret_interface {
  my ($mm_def, $interface) = @_;
  
  if ( ref $interface eq 'HASH' ) { 
    return $interface if exists $interface->{'-parsed'};
  } 
  elsif ( ! defined $interface or ! length $interface ) { 
    _diagnostic('tmpl_empty');

  } 
  elsif ( ! ref $interface ) {
    if ( exists $mm_def->{'interface'}{ $interface } ) {
      if ( ! ref $mm_def->{'interface'}{ $interface } ) { 
	$mm_def->{'interface'}{ $interface } = 
				{ '*' => $mm_def->{'interface'}{ $interface } };
      }
    } elsif ( exists $mm_def->{'behavior'}{ $interface } ) {
      $mm_def->{'interface'}{ $interface } = { '*' => $interface };
    } else {
      _diagnostic('tmpl_unkown', $interface);
    }
    $interface = $mm_def->{'interface'}{ $interface };
    
    return $interface if exists $interface->{'-parsed'};
  }
  elsif ( ref $interface ne 'HASH' ) {
    _diagnostic('tmpl_unsupported', $interface);
  } 
  
  $interface->{'-parsed'} = "$_[1]";
  
  # Allow interface inheritance via -base specification
  if ( $interface->{'-base'} ) {
    for ( split ' ', $interface->{'-base'} ) {
      my $base = _interpret_interface( $mm_def, $_ );
      %$interface = ( %$base, %$interface );
    }
    delete $interface->{'-base'};
  }
  
  for (keys %$interface) {
    # Remove empty/undefined items.
    unless ( defined $interface->{$_} and length $interface->{$_} ) {
      delete $interface->{$_};
      next;
    }
  }
  # _diagnostic('debug_interface', $_[1], join(', ', %$interface ));
  
  return $interface;
}

########################################################################
### BEHAVIORS AND MODIFIERS: _fold_modifiers(), _behavior_builder()
########################################################################

sub _fold_modifiers {
  my $spec = shift;
  my $rules = shift;
  my %rules = @$rules;
  
  # Longest first, to prevent over-eager matching.
  my $rule = join '|', map "\Q$_\E", 
	sort { length($b) <=> length($a) } keys %rules;
  # Match repeatedly from the front.
  1 while ( $spec =~ s/($rule)/$rules{$1}/ );
  $spec =~ s/(^|\s)\s/$1/g;
  return $spec;
}

sub _behavior_builder {
  my ( $mm_def, $behavior, $m_info ) = @_;
  
  # We're going to have to do some extra work here, so we'll cache the result
  my $builder;
  
  # Separate the modifiers
  my $core_behavior = $behavior;
  my @modifiers;
  while ( $core_behavior =~ s/\-(\w+)\s// ) { push @modifiers, $1 }
  
  # Find either the built-in or universal behavior template
  if ( $mm_def->{'behavior'}{$core_behavior} ) {
    $builder = $mm_def->{'behavior'}{$core_behavior};
  } else {
    my $universal = _definition('Class::MakeMethods::Template::Universal','generic');
    $builder = $universal->{'behavior'}{$core_behavior} 
  }
  
  # Otherwise we're hosed.
  $builder or _diagnostic('make_bad_behavior', $m_info->{'name'}, $behavior);
  
  if ( ! ref $builder ) {
    # If we've got a text template, pass it off for interpretation.
    my $code = ( ! $Class::MakeMethods::Utility::DiskCache::DiskCacheDir ) ?
      _interpret_text_builder($mm_def, $core_behavior, $builder, @modifiers) 
    : _disk_cache_builder($mm_def, $core_behavior, $builder, @modifiers);
    
    # _diagnostic('debug_eval_builder', $name, $code);
    local $^W unless $Class::MakeMethods::CONTEXT{Debug};
    $builder = eval $code;
    if ( $@ ) { _diagnostic('behavior_eval', $@, $code) }
    unless (ref $builder eq 'CODE') { _diagnostic('behavior_eval', $@, $code) }
  
  } elsif ( scalar @modifiers ) {
    # Can't modify code subs
    _diagnostic('make_behavior_mod', join(', ', @modifiers), $core_behavior);
  }
  
  $mm_def->{'-behavior_cache'}{$behavior} = $builder;

  return $builder;
}

########################################################################
### CODE EXPRESSIONS: _interpret_text_builder(), _disk_cache_builder()
########################################################################

sub _interpret_text_builder {
  require Class::MakeMethods::Utility::TextBuilder;
  
  my ( $mm_def, $name, $code, @modifiers ) = @_;
  
  foreach ( @modifiers ) {
    exists $mm_def->{'modifier'}{$_} 
      or _diagnostic('behavior_mod_unknown', $name, $_);
  }
  
  my @exprs = grep { $_ } map { 
	$mm_def->{'modifier'}{ $_ }, 
	$mm_def->{'modifier'}{ "$_ $name" } || $mm_def->{'modifier'}{ "$_ *" }
      } ( '-all', ( scalar(@modifiers) ? @modifiers : '-default' ) );
  
  # Generic method template
  push @exprs, "return sub _SUB_ATTRIBS_ { \n  my \$self = shift;\n  * }";
  
  # Closure-generator
  push @exprs, "sub { my \$m_info = \$_[0]; * }";
  
  my $exprs = $mm_def->{code_expr};
  unshift @exprs, { 
	( map { $_=>$exprs->{$_} } grep /^[^-]/, keys %$exprs ),
	'_BEHAVIOR_{}' => $mm_def->{'behavior'},
	'_SUB_ATTRIBS_' => '',
  };
  
  my $result = Class::MakeMethods::Utility::TextBuilder::text_builder($code,
								       @exprs);
  
  my $modifier_string = join(' ', map "-$_", @modifiers);
  my $full_name = "$name ($mm_def->{template_class} $mm_def->{template_name}" .
		    ( $modifier_string ? " $modifier_string" : '' ) . ")";
  
  _diagnostic('debug_template_builder', $full_name, $code, $result);
  
  return $result;
}

sub _disk_cache_builder { 
  require Class::MakeMethods::Utility::DiskCache;
  my ( $mm_def, $core_behavior, $builder, @modifiers ) = @_;
  
  Class::MakeMethods::Utility::DiskCache::disk_cache( 
    "$mm_def->{template_class}::$mm_def->{template_name}", 
    join('.', $core_behavior, @modifiers),
    \&_interpret_text_builder, ($mm_def, $core_behavior, $builder, @modifiers)
  );
}

1;

__END__


=head1 NAME

Class::MakeMethods::Template - Extensible code templates 


=head1 SYNOPSIS

  package MyObject;
  use Class::MakeMethods::Template::Hash (
    'new'       => 'new',
    'string'    => 'foo',
    'number'    => 'bar',
  );
   
  my $obj = MyObject->new( foo => "Foozle", bar => 23 );
  print $obj->foo();
  $obj->bar(42);


=head1 MOTIVATION

If you compare the source code of some of the closure-generating
methods provided by other subclasses of Class::MakeMethods,
such as the C<hash> accessors provided by the various Standard::*
subclasses, you will notice a fair amount of duplication. This
module provides a way of assembling common pieces of code to
facilitate support the maintenance of much larger libraries of
generated methods.


=head1 DESCRIPTION

This module extends the Class::MakeMethods framework by providing
an abstract superclass for extensible code-templating method
generators.

Common types of methods are generalized into B<template definitions>.
For example, C<Template::Generic>'s C<new> provides a template for
methods that create object instances, while C<Template::Generic>'s
C<scalar> is a template for methods that allow you to get and set
individual scalar values.

Thse definitions are then re-used and modified by various B<template
subclasses>. For example, the C<Template::Hash> subclass supports
blessed-hash objects, while the C<Template::Global> subclass supports
shared data; each of them includes an appropriate version of the
C<scalar> accessor template for those object types.

Each template defines one or more B<behaviors>, individual methods
which can be installed in a calling package, and B<interfaces>,
which select from those behaviours and indicate the names to install
the methods under.

Each individual meta-method defined by a calling package requires
a B<method name>, and may optionally include other key-value
B<parameters>, which can control the operation of some meta-methods.


=head1 USAGE

=head2 Class::MakeMethods Calling Conventions

When you C<use> this package, the method declarations you provide
as arguments cause subroutines to be generated and installed in
your module.

You can also omit the arguments to C<use> and instead make methods
at runtime by passing the declarations to a subsequent call to
C<make()>.

You may include any number of declarations in each call to C<use>
or C<make()>. If methods with the same name already exist, earlier
calls to C<use> or C<make()> win over later ones, but within each
call, later declarations superceed earlier ones.

You can install methods in a different package by passing C<-TargetClass =E<gt> I<package>> as your first arguments to C<use> or C<make>. 

See L<Class::MakeMethods> for more details.

=head2 Passing Parameters

The following types of Basic declarations are supported:

=over 4

=item *

I<generator_type> => "I<method_name>"

=item *

I<generator_type> => "I<name_1> I<name_2>..."

=item *

I<generator_type> => [ "I<name_1>", "I<name_2>", ...]

=back

See L<Class::MakeMethods::Docs::Catalog/"TEMPLATE CLASSES"> for a list of the supported values of I<generator_type>.

For each method name you provide, a subroutine of the indicated
type will be generated and installed under that name in your module.

Method names should start with a letter, followed by zero or more
letters, numbers, or underscores.

=head2 Standard Declaration Syntax

The Standard syntax provides several ways to optionally associate
a hash of additional parameters with a given method name.

=over 4

=item *

I<generator_type> => [ "I<name_1>" => { I<param>=>I<value>... }, ... ]

A hash of parameters to use just for this method name. 

(Note: to prevent confusion with self-contained definition hashes,
described below, parameter hashes following a method name must not
contain the key 'name'.)

=item *

I<generator_type> => [ [ "I<name_1>", "I<name_2>", ... ] => { I<param>=>I<value>... } ]

Each of these method names gets a copy of the same set of parameters.

=item *

I<generator_type> => [ { "name"=>"I<name_1>", I<param>=>I<value>... }, ... ]

By including the reserved parameter C<name>, you create a self
contained declaration with that name and any associated hash values.

=back

Basic declarations, as described above, are treated as having an empty parameter hash.

=head2 Default Parameters

A set of default parameters to be used for several declarations
may be specified using any of the following types of arguments to
a Template method generator call:

=over 4

=item * 

'-I<param>' => 'I<value>'

Set a default value for the specified parameter.

=item * 

'--' => { 'I<param>' => 'I<value>', ... }

Set default values for one or more parameters. Equivalent to a series of '-I<param>' => 'I<value>' pairs for each pair in the referenced hash.

=item * 

'--I<special_param_value>' 

Specifies a value for special parameter; the two supported parameter types are: 

=over 4

=item -

'--I<interface_name>' 

Select a predefined interface; equivalent to '-interface'=> 'I<interface_name>'.

For more information about interfaces, see L<"Selecting Interfaces"> below.

=item -

'--I<modifier_name>' 

Select a global behavior modifier, such as '--private' or '--protected'.

For more information about modifiers, see L<"Selecting Modifiers"> below.

=back

=back

Parameters set in these ways are passed to each declaration that
follows it until the end of the method-generator argument array,
or until overridden by another declaration. Parameters specified
in a hash for a specific method name, as discussed above, will
override the defaults of the same name for that particular method.


=head1 PARAMETER REFERENCE

Each meta-method is allocated a hash in which to store its parameters
and optional information.

(Note that you can not override parameters on a per-object level.)

=head2 Special Parameters

The following parameters are pre-defined or have a special meaning:

=over 4

=item *

name

The primary name of the meta-method. Note that the subroutines
installed into the calling package may be given different names,
depending on the rules specified by the interface.

=item *

interface

The name of a predefined interface, or a reference to a custom
interface, to use for this meta-method. See L</Selecting Interfaces>, below.

=item *

modifier

The names of one or more predefined modifier flags. See L</Selecting Modifiers>, below.

=back

=head2 Informative Parameters

The following parameters are set automatically when your meta-method is declared:

=over 4

=item *

target_class

The class that requested the meta-method, into which its subroutines
will be installed.

=item *

template_name

The Class::MakeMethods::Template method used for this declaration.

=item *

template_class

The Class::MakeMethods::Template subclass used for this declaration.

=back

=head2 Other Parameters

Specific subclasses and template types provide support for additional
parameters.

Note that you generally should not arbitrarily assign additional
parameters to a meta-method unless you know that they do not conflict
with any parameters already defined or used by that meta-method.


=head2 Parameter Expansion

If a parameter specification contains '*', it is replaced with
the primary method name.

Example: The following defines counter (*, *_incr, *_reset)
meta-methods j and k, which use the hash keys j_index and k_index
to fetch and store their values.

  use Class::MakeMethods::Template::Hash
    counter => [ '-hash_key' => '*_index', qw/ j k / ];

(See L<Class::MakeMethods::Template::Hash> for information about the C<hash_key> parameter.)

If a parameter specification contains '*{I<param>}', it is replaced
with the value of that parameter.

Example: The following defines a Hash scalar meta-method which will
store its value in a hash key composed of the defining package's
name and individual method name, such as
C<$self-E<gt>{I<MyObject>-I<foo>}>:

  use Class::MakeMethods::Template::Hash
    'scalar' => [ '-hash_key' => '*{target_class}-*{name}', qw/ l / ];


=head2 Selecting Interfaces

Each template provides one or more predefined interfaces, each of which specifies one or more methods to be installed in your package, and the method names to use. Check the documentation for specific templates for a list of
which interfaces they define.

An interface may be specified for a single method by providing an
'interface' parameter:

=over 4

=item * 

'I<interface_name>'

Select a predefined interface.

Example: Instead of the normal Hash scalar method named x, the
following creates methods with "Java-style" names and behaviors,
getx and setx.

  use Class::MakeMethods::Template::Hash
    'scalar' => [ 'x' => { interface=>'java' } ];

(See L<Class::MakeMethods::Template::Generic/"scalar"> for a
description of the C<java> interface.)

=item * 

'I<behavior_name>'

A simple interface consisting only of the named behavior.

For example, the below declaration creates a read-only methods named q. (There
are no set or clear methods, so any value would have to be placed
in the hash by other means.)

  use Class::MakeMethods::Template::Hash (
    'scalar' => [ 'q' => { interface=>'get' } ] 
  );

=item * 

{  'I<subroutine_name_pattern>' => 'I<behavior_name>', ... }

A custom interface consists of a hash-ref that maps subroutine names to the associated behaviors. Any C<*> characters in I<subroutine_name_pattern> are replaced with the declared method name.

For example, the below delcaration creates paired get_w and set_w methods:

  use Class::MakeMethods::Template::Hash (
    'scalar' => [ 'w' => { interface=> { 'get_*'=>'get', 'set_*'=>'set' } } ] 
  );

=back

Some interfaces provide very different behaviors than the default
interface.

Example: The following defines a method g, which if called with an
argument appends to, rather than overwriting, the current value:

  use Class::MakeMethods::Template::Hash
    'string' => [ '--get_concat', 'g' ];

A named interface may also be specified as a default in the argument
list with a leading '--' followed by the interface's name.

Example: Instead of the normal Hash scalar methods (named x and
clear_x), the following creates methods with "Java-style" names
and behaviors (getx, setx).

  use Class::MakeMethods::Template::Hash
    'scalar' => [ '--java', 'x'  ];

An interface set in this way affects all meta-methods that follow it
until another interface is selected or the end of the array is
reached; to return to the original names request the 'default'
interface.

Example: The below creates "Java-style" methods for e and f, "normal
scalar" methods for g, and "Eiffel-style" methods for h.

  use Class::MakeMethods::Template::Hash
    'scalar' => [
      '--java'=> 'e', 'f', 
      '--default'=> 'g', 
      '--eiffel'=> 'h',
    ];


=head2 Selecting Modifiers

You may select modifiers, which will affect all behaviors.

  use Class::MakeMethods::Template::Hash
      'scalar' => [ 'a', '--protected' => 'b', --private' => 'c' ];

Method b croaks if it's called from outside of the current package
or its subclasses.

Method c croaks if it's called from outside of the current package.

See the documentation for each template to learn which modifiers it supports.


=head2 Runtime Parameter Access

If the meta-method is defined using an interface which includes the
attributes method, run-time access to meta-method parameters is
available.

Example: The following defines a counter meta-method named y, and
then later changes the 'join' parameter for that method at runtime.

  use Class::MakeMethods ( get_concat => 'y' );
  
  y_attributes(undef, 'join', "\t" )
  print y_attributes(undef, 'join')


=head1 EXTENDING

You can create your own method-generator templates by following the below outline.


=head2 Mechanisms

Dynamic generation of methods in Perl generally depends on one of two approaches: string evals, which can be as flexible as your string-manipulation functions allow, but are run-time resource intensive; or closures, which are limited by the number of subroutine constructors you write ahead of time but which are faster and smaller than evals. 

Class::MakeMethods::Template uses both of these approaches: To generate different types of subroutines, a simple text-substitution mechanism combines bits of Perl to produce the source code for a subroutine, and then evals those to produce code refs. Any differences which can be handled with only data changes are managed at the closure layer; once the subroutines are built, they are repeatedly bound as closures to hashes of parameter data.

=head2 Code Generation

A substitution-based "macro language" is used to assemble code strings. This happens only once per specific subclass/template/behavior combination used in your program. (If you have disk-caching enabled, the template interpretation is only done once, and then saved; see below.)

There are numerous examples of this within the Generic interface and its subclasses; for examples, look at the following methods: Universal:generic, Generic:scalar, Hash:generic, and Hash:scalar.

See L<Class::MakeMethods::Utility::TextBuilder> for more information.


=head2 Template Definitions

Template method generators are declared by creating a subroutine that returns a hash-ref of information about the template. When these subroutines are first called, the template information is filled in with imported and derived values, blessed as a Class::MakeMethods::Template object, and cached. 

Each C<use> of your subclass, or call to its C<make>, causes these objects to assemble the requested methods and return them to Class::MakeMethods for installation in the calling package.

Method generators defined this way will have support for parameters, custom interfaces, and the other features discussed above.

(Your module may also use the "Aliasing" and "Rewriting" functionality described in L<Class::MakeMethods/EXTENDING>.)

Definition hashes contain several types of named resources in a second level of hash-refs under the following keys:

=over 4

=item * 

interface - Naming styles (see L<"Defining Interfaces">, below)

=item *

params - Default parameters for meta-methods declared with this template (see L<"Default Parameters">, below)

=item *

behavior - Method recipes (see L<"Defining Behaviors">, below)

=item *

code_expr - Bits of code used by the behaviors

=back

=head2 Minimum Template Definition

You must at least specify one behavior; all other information is optional.

Class::MakeMethods will automatically fill in the template name and class
as 'template_name' and 'template_class' entries in the version of your
template definition hash that it caches and uses for future execution.

For example a simple sub-class that defines a method type
upper_case_get_set might look like this:

  package Class::MakeMethods::UpperCase;
  use Class::MakeMethods '-isasubclass';
  
  sub uc_scalar {
    return { 
      'behavior' => {
	'default' => sub { 
	  my $m_info = $_[0]; 
	  return sub {
	    my $self = shift;
	    if ( scalar @_ ) { 
	      $self->{ $m_info->{'name'} } = uc( shift ) 
	    } else {
	      $self->{ $m_info->{'name'} };
	    }
	  }
	},
      }
    }
  }

And a caller could then use it to generate methods in their package by invoking:

  Class::MakeMethods::UpperCase->make( 'uc_scalar' => [ 'foo' ] );

=head2 Default Parameters

Each template may include a set of default parameters for all declarations as C<params =E<gt> I<hash_ref>>.

Template-default parameters can be overrridden by interface '-params', described below, and and method-specific parameters, described above.

=head2 Defining Interfaces

Template definitions may have one or more interfaces, including
the default one, named 'default', which is automatically selected
if another interface is not requested. (If no default interface is
provided, one is constructed, which simply calls for a behavior
named default.)

Most commonly, an interface is specified as a hash which maps one or
more subroutine names to the behavior to use for each. The interface
subroutine names generally contain an asterisk character, '*', which
will be replaced by the name of each meta-method.

Example: The below defines methods e_get, e_set, and e_clear.

  use Class::MakeMethods::Template::Hash
    'scalar' => [
      -interface=>{ '*_clear'=>clear, '*_get'=>'get', '*_set'=>'set' }, 'e' 
    ];

If the provided name does not contain an asterisk, it will not be
modified for individual meta-methods; for examples, see the bit_fields
method generated by Generic bits, and the DESTROY method generated
by InsideOut meta-methods.

In addition to the name-to-behavior correspondences described above,
interfaces may also contain additional entries with keys begining
with the '-' character which are interpreted as follows:

=over 4

=item *

C<-params =E<gt> I<hash_ref>>

Interfaces may include a '-params' key and associated reference
to a hash of default parameters for that interface.

=item *

C<-base =E<gt> I<interface_name>>

Interfaces can be based on previously existing ones by including
a -base specification in the the hash. The base value should contain
one or more space-separated names of the interfaces to be included.

Example: The below defines methods getG, setG, and clearG.

  use Class::MakeMethods::Template::Hash
    'scalar' => [
      -interface => { -base=>'java', 'clear*'=>'clear' }, qw/ G / 
    ];

If multiple interfaces are included in the -base specification and
specify different behaviors for the same subroutine name, the later
ones will override the earlier. Names which appear in the base
interface can be overridden by providing a new value, or a name
can be removed by mapping it to undef or the empty string.

Example: The following defines a get-set meta-method h, but supresses
the clear_h method:

  use Class::MakeMethods::Template::Hash
    'scalar' => [
      -interface => { -base=>'with_clear', 'clear_*'=>'' }, qw/ h / 
    ];

=back


=head2 Defining Behaviors

Behaviors can be provided as text which is eval'd to form a
closure-generating subroutine when it's first used; C<$self> is
automatically defined and assigned the value of the first argument.

      'behavior' => {
	'default' => q{
	    if ( scalar @_ ) { $self->{ $m_info->{'name'} } = uc shift }
	    $self->{ $m_info->{'name'} };
	},
      }

A simple substitution syntax provides for macro interpretation with
definition strings. This functionality is currently undocumented;
for additional details see the _interpret_text_builder function in
Class::MakeMethods, and review the code_expr hashes defined in
Class::MakeMethods::Generic.


=head2 Importing

You can copy values out of other template definitions by specifying
an '-import' key and corresponding hash reference. You can specify
an -import for inside any of the template definition sub-hashes.
If no -import is specified for a subhash, and there is a top-level
-import value, it is used instead.

Inside an -import hash, provide C<I<TemplateClass>:I<type>> names
for each source you wish to copy from, and the values to import,
which can be a string, a reference to an array of strings, or '*'
to import everything available. (The order of copying is not
defined.)

Example: The below definition creates a new template
which is identical to an existing one.

  package Class::MakeMethods::MyMethods;
  sub scalarama {
    { -import => { 'Template::Hash:scalar' => '*' } }
  }

Values that are already set are not modified, unless they're an
array ref, in which case they're added to.

Example:

  package Class::MakeMethods::MyMethods;
  sub foo_method {
    { 'behavior' => {
      '-init' => [ sub {  warn "Defining foo_method $_[0]->{'name'}" } ],
      'default' => q{ warn "Calling foo_method behavior" }.
    } }
  }
  sub bar_method {
    { 'behavior' => {
      -import => { 'MyMethods:foo_method' => '*' },
      '-init' => [ sub {  warn "Defining bar_method $_[0]->{'name'}" } ],
      'default' => q{ warn "Calling bar_method behavior" }.
    } }
  }

In this case, the bar_method ends up with an array of two '-init'
subroutines, its own and the imported one, but only its own default
behavior.



=head2 Modifying Existing Templates

You can over-write information contained in template definitions
to alter their subsequent behavior. 

Example: The following extends the Hash:scalar template definition
by adding a new interface, and then uses it to create scalar accessor
methods named access_p and access_q that get and set values for
the hash keys 'p' and 'q':

  Class::MakeMethods::Template::Hash->named_method('scalar')->
	  {'interface'}{'frozzle'} = { 'access_*'=>'get_set' };

  package My::Object;
  Class::MakeMethods::Template::Hash->make( 'scalar' => [ --frozzle => qw( p q ) ] );

  $object->access_p('Potato');    # $object->{p} = 'Potato'
  print $object->access_q();      # print $object->{q}
  

Note that this constitutes "action at a distance" and will affect subsequent use by other packages; unless you are "fixing" the current behavior, you are urged to create your own template definition which imports the base behavior of the existing template and overrides the information in question.

Example: The following safely declares a new version of Hash:scalar with the desired additional interface:

  package My::Methods;
  
  sub scalar {
    { 
      -import => { 'Template::Hash:scalar' => '*' } ,
      interface => { 'frozzle' => { 'access_*'=>'get_set' } },
    }
  }

  package My::Object;
  My::Methods->make( 'scalar' => [ --frozzle => qw( p q ) ] );


=cut

=head2 Disk Caching

To enable disk caching of generated code, create an empty directory and pass it to the DiskCache package:

  use Class::MakeMethods::Utility::DiskCache qw( /my/code/dir );

This has a mixed effect on performance, but has the notable advantage of letting you view the subroutines that are being generated by your templates.

See L<Class::MakeMethods::Utility::DiskCache> for more information.


=head1 SEE ALSO

See L<Class::MakeMethods> for general information about this distribution. 

See L<Class::MakeMethods::Examples> for some illustrations of what you can do with this package.

For distribution, installation, support, copyright and license 
information, see L<Class::MakeMethods::Docs::ReadMe>.

=cut
