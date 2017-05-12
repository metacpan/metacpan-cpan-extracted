package Class::Contract::Production;
use strict;
use vars qw( $VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS );
require Exporter;
use Carp;

$VERSION = '1.14';

@ISA = qw(Exporter);
@EXPORT = qw(contract ctor dtor attr method pre impl post invar inherits
             self value class abstract private optional check callstate
             failmsg clon);
@EXPORT_OK = qw(scalar_attrs array_attrs hash_attrs methods old);
%EXPORT_TAGS = (DEFAULT  => \@EXPORT,
                EXTENDED => \@EXPORT_OK,
                ALL      => [@EXPORT, @EXPORT_OK]);

my %contract;
my %data;  
my %class_attr;
my $current;
my $msg_target;

my @class_dtors;
END { $_->()  foreach (@class_dtors) }

my ($carp, $croak) = (
  sub {
    my (@c) = caller(0);
    ($c[3] eq 'Class::Contract::Production::__ANON__')
      ? print STDERR (@_, " at $c[1] line $c[2]\n") : &carp
  },
  sub {
    my (@c) = caller(0);
    ($c[3] eq 'Class::Contract::Production::__ANON__')
      ? die(@_, " at $c[1] line $c[2]\n") : &croak 
  }
);

sub import {
  my $class = $_[0];
  my $caller = caller;
  $contract{$caller}{use_old} = grep(/^old$/, @_) ? 1 : 0;
  push @_, @EXPORT;
  no strict 'refs';
  INIT {
    *{$caller .'::croak'} = $croak  if defined *{$caller .'::croak'}{'CODE'};
    *{$caller .'::carp'}  = $carp   if defined *{$caller .'::carp'}{'CODE'};
  }
  goto &Exporter::import;
}

sub unimport {
  my $class = shift;
  my $caller = caller;
  $contract{$caller}{use_old} = 0  if grep /^old$/, @_; 
}

sub contract(&) {  $_[0]->();  _build_class(caller) }

sub check(\%;$) {
}


sub _location { # scalar context returns file and line of external code
                # array context returns package aka 'owner', file and line
  my ($i, @c, $owner);
  while (@c = (caller($i++))[0..2]) {
    if ($c[0] !~ /^Class::Contract::Production$/) {
      $owner = $c[0]  if !$owner;
      if ($c[1] !~ /^\(eval \d+\)$/) {
        return (wantarray ? $owner : (), join ' line ', @c[1,2]);
      }
    }
  }
}

my %def_type = (
  'attr'   => 'SCALAR',
  'method' => '',
  'ctor'   => '',
  'dtor'   => '',
  'clon'   => '',
);

sub _member {
  my ($kind, $name, $type) = @_;
  my ($owner, $location) = _location;
  $name = ''  unless $name;

  if (defined $contract{$owner}{$kind}{$name}) {
    croak "\u$kind ${owner}::$name redefined"  if $name;
    croak "Unnamed $kind redefined";
  }
  
  $contract{$owner}{$kind}{$name} = $current =
    bless {'name'     => $name,
           'type'     => $type || $def_type{$kind},
           'loc'      => $location,
           'shared'   => 0,
           'private'  => 0,
           'abstract' => 0,
          }, "Class::Contract::Production::$kind";

  return $current;
}

sub attr($;$) { _member('attr'   => @_) }
sub method($) { _member('method' => @_) }
sub ctor(;$)  { _member('ctor'   => @_) }
sub dtor()    { _member('dtor') }
sub clon()    { _member('clone') }

sub scalar_attrs(@) { map _member('attr', $_, 'SCALAR'), @_ }
sub array_attrs(@)  { map _member('attr', $_, 'ARRAY'),  @_ }
sub hash_attrs(@)   { map _member('attr', $_, 'HASH'),   @_ }
sub methods(@)      { map _member('attr', $_),           @_ }

sub class(@)    { $_->{'shared'}   = 1  foreach(@_); @_ }
sub abstract(@) { $_->{'abstract'} = 1  foreach(@_); @_ }
sub private(@)  { $_->{'private'}  = 1  foreach(@_); @_ }

my %def_msg = (
  'pre'   => 'Pre-condition at %s failed',
  'post'  => 'Post-condition at %s failed',
  'invar' => 'Class invariant at %s failed',
  'impl'  => undef
);

sub _current {
  my ($field, $code) = @_;
  croak "Unattached $field"  unless defined $current;
  croak "Attribute cannot have implementation"
    if $current->isa('Class::Contract::Production::attr') && $field eq 'impl';

  my $descriptor = bless {
    'code'  => $code,
    'msg'   => $def_msg{$field},
  }, 'Class::Contract::Production::current';
  @{$descriptor}{qw(owner loc)} = _location;

  if ($field eq 'impl' && !( $current->isa('Class::Contract::Production::ctor') 
                          || $current->isa('Class::Contract::Production::dtor') 
                          || $current->isa('Class::Contract::Production::clone') )) { 
    $current->{$field} = $descriptor
  } else {
    push @{$current->{$field}}, $descriptor
  }
  
  $msg_target = $descriptor;
}

sub failmsg {
  croak "Unattached failmsg"  unless $msg_target;
  $msg_target->{'msg'} = shift;
}

sub pre(&)  { _current('pre'  => @_) }
sub post(&) { _current('post' => @_) }
sub impl(&) { _current('impl' => @_) }

sub optional { # my (@descriptors) = @_;
}

sub invar(&) {
  my ($code) = @_;

  my $descriptor = {
    'code'  => $code,
    'msg'   => $def_msg{'invar'},
  };
  @{$descriptor}{qw(owner loc)} = _location;

  push @{$contract{$descriptor->{'owner'}}{'invar'}}, $descriptor;
  $msg_target = $descriptor;
}


sub inherits(@)  {
  my ($owner) = _location;
  foreach (@_) {
    croak "Can't create circular reference in inheritence\n$_ is a(n) $owner" 
      if $_->isa($owner)
  }
  push @{$contract{$owner}{'parents'}}, @_;
}

sub _build_class($) {
  my ($class) = @_;
  my $spec = $contract{$class};
  _inheritance($class, $spec);
  _attributes($class, $spec);
  _methods($class, $spec);
  _constructors($class, $spec);
  _destructors($class, $spec);
  _clones($class, $spec);
  1;
}

localscope: {
  my @context;
  sub _set_context  {
    push @context, {'__SELF__' => shift};

  }
  sub _free_context {
    return pop @context
  }
  sub old() {
    croak "No context. Can't call &old"  unless @context;
    my $self = $context[-1]{__SELF__};
    my $class = ref($self) || $self;
    croak "Support for &old has been toggled off"
      unless ($contract{$class}{'use_old'});
  }

  my @value;
  sub _set_value  { push @value, \@_ }
  sub _free_value { my $v = pop @value; wantarray ? @$v : $v->[0] }

  sub value { 
    croak "Can't call &value "  unless @value;
    return $value[-1];
  }

  sub self() {
    if (@_) {
      $context[-1]{__SELF__} = shift;
    }
    croak "No context. Can't call &self"  unless @context;
    $context[-1]{__SELF__}
  }

  sub callstate() {
    croak "No context. Can't call &callstate"  unless @context;
    return $context[-1];
  }
}

sub _inheritance {                                  #  A  D  Invokation order
# Inheritence is left-most depth-first. Destructors #  /\ |   
# are called in reversed order as the constructors  # B C E    ctor: ABCDEF
# Diamond patterns in inheritence are 'handled' by  #  \//     dtor: FEDCBA
# looking for and skipping duplicate anonymous refs #   F

  my ($classname, $spec) = @_;
  my (%inherited_clause, %inherited_impl);
  foreach my $ancestor ( reverse @{$spec->{'parents'} || [] } ) {
    my $parent = $contract{$ancestor} || next;
    if ($parent->{'use_old'} and not $spec->{'use_old'}) {
      croak("Derived class $classname, has not toggled on support for ->old\n",
            "which is required by ancestor $ancestor. Did you forget to\n",
            "declare: use Class::Contract::Production 'old'; ?");
    }
    foreach my $clause ( qw( attr method ctor clone dtor ) ) {
      foreach my $name ( keys %{ $parent->{$clause} || {} } ) {
        # Inherit each clause from ancestor unless defined
        if (! defined $spec->{$clause}{$name}
            and not exists $inherited_clause{$name}) {
          $inherited_clause{$name}++;
          %{$spec->{$clause}{$name}} = (%{$parent->{$clause}{$name}});
          next;
        }

        # Inherit ctor/clone/dtor invokation from ancestors
        if ($clause =~ /^(ctor|clone|dtor)$/) {
          if (defined $parent->{$clause}{$name}{'impl'}
              and @{$parent->{$clause}{$name}{'impl'}}) {
            my (@impl, %seen) = (@{$spec->{$clause}{$name}{'impl'}});
            if (@impl) {
              $seen{$impl[$_]} = $_  foreach (0..$#impl);
              foreach my $item ( @{$parent->{$clause}{$name}{'impl'}} ) {
                splice(@{$spec->{$clause}{$name}{'impl'}}, $seen{$item}, 1)
                   if exists $seen{$item};
              }
            }
            $clause ne 'dtor'
            ? unshift(@{$spec->{$clause}{$name}{'impl'}},
                      @{$parent->{$clause}{$name}{'impl'}})
            : push(@{$spec->{$clause}{$name}{'impl'}},
                   @{$parent->{$clause}{$name}{'impl'}});
          }
        }

        # Get implementation from ancestor if derived but not redefined
        if ($clause eq 'method') {
          if (! defined $spec->{$clause}{$name}{'impl'}
              or $inherited_impl{$name}) {
            $inherited_impl{$name}++;
            $spec->{$clause}{$name}{'impl'}=$parent->{$clause}{$name}{'impl'};
          }
          croak("Forget 'private'? $classname inherits private $name from ",
                "$ancestor\n")
            if ($parent->{$clause}{$name}{'private'} 
                and not $spec->{$clause}{$name}{'private'})
        }
      }
    }
  }

  no strict 'refs';
  unshift @{"${classname}::ISA"}, @{ $spec->{'parents'} || [] };
}

sub _attributes {
  my ($classname, $spec) = @_;

  while ( my ($name, $attr) = each %{$spec->{'attr'}} ) {
    if ($attr->{'shared'}) {
      my $ref = $class_attr{$classname}{$name} = 
        $attr->{'type'} eq 'ARRAY'  ? []
      : $attr->{'type'} eq 'HASH'   ? {}
      : $attr->{'type'} eq 'SCALAR' ? do { \ my $scalar }
      : eval { $attr->{'type'}->new }
        || croak "Unable to create $attr->{'type'} object ",
                 "for class attribute $name";
    }

    localscope: {
      no strict 'refs';
      local $^W;
      *{"${classname}::$name"} = sub {
        croak(qq|Can\'t access object attr w/ class reference |,$attr->{'loc'})
          unless ($attr->{'shared'} or ref($_[0]));

        my $caller = caller;
        croak "attribute ${classname}::$name inaccessible from package $caller"
          unless $classname->isa($caller);

        my $self = shift;
        _set_context(($attr->{'shared'} ? ref($self)||$self : $self),
                     join ' line ', [caller]->[1,2]);
        my $attr_ref = ($attr->{'shared'})
          ? $class_attr{$classname}{$name}
          : $data{$$self}{$name};
        _set_value $attr_ref;  

        
        _free_context;
        

        scalar _free_value;
        return $attr_ref;
      };
    }
  }
}

sub _methods {
  my ($classname, $spec) = @_;

  while ( my ($name, $method) = each %{$spec->{'method'}} ) {
    $spec->{'abstract'} ||= $method->{'abstract'};
    unless ($method->{'impl'}) {
      if ($method->{'abstract'}) {
        $method->{'impl'} = {'code' => sub {
          croak "Can't call abstract method ${classname}::$name"
        } }
      } else {
        croak qq{No implementation for method $name at $method->{'loc'}.\n},
        qq{(Did you forget to declare it 'abstract'?)\n}
      }
    }

    local_scope: {
      local $^W;
      no strict 'refs';
      *{"${classname}::$name"} = sub {
        my $caller = caller;
        croak("private method ${classname}::$name inaccessible from ",
              scalar caller)
          if ($method->{'private'}
              and not ($classname->isa($caller))); # or $caller->isa($classname)));

        my $self = shift;
        _set_context(($method->{'shared'} ? ref($self)||$self : $self),
                     join ' line ', [caller]->[1,2]);
  

        _set_value wantarray
          ? $method->{'impl'}{'code'}->(@_)
          : scalar $method->{'impl'}{'code'}->(@_);
        

        _free_context;
        _free_value;
      };
    }
  }
}


sub generic_ctor {
  my ($class) = @_;

  croak "Class $class has abstract methods. Can't create $class object"
    if $contract{$class}{'abstract'};

  my $key = \ my $undef;
  my $obj = \ $key;
  bless $obj, $class;

  my $attr = $contract{$class}{'attr'};
        
  foreach my $attrname ( keys %$attr ) {
    unless ($attr->{$attrname} && $attr->{$attrname}{'shared'}) {
      my $ref = $data{$key}{$attrname}
      = $attr->{$attrname}{'type'} eq 'ARRAY'  ? []
      : $attr->{$attrname}{'type'} eq 'HASH'   ? {}
      : $attr->{$attrname}{'type'} eq 'SCALAR' ? do { \my $scalar }
      : eval { $attr->{$attrname}{type}->new }
      || croak "Unable to create $attr->{$attrname}{'type'} ",
               "object for attribute $attrname";
    }
  }

  return $obj;
}

sub generic_clone ($) {
  my $self = shift;
  my $ref = ref($self);
  croak "usage: \$object->clone -Invalid arg $self"
    unless ($ref and 
            $ref !~ /^(HASH|ARRAY|SCALAR|GLOB|FORMAT|CODE|Regexp|REF)$/);
  my $key  = \ my $undef;
  my $obj  = bless \$key, $ref;
  $data{$key} = _dcopy($data{$$self})  if exists $data{$$self};
  return $obj;
}


sub _constructors {
  my ($classname, $spec) = @_;
  my $noctor = 1;

  while ( my ($name, $ctor) = each %{$spec->{'ctor'}} ) {
    $noctor &&= $ctor->{'shared'}
  }

  $spec->{'ctor'}{'new'} = bless {
    'name'     => 'new',
    'shared'   => 0,
    'abstract' => 0,
    'loc'      => '<implicit>'
  }, 'Class::Contract::Production::ctor'
    if $noctor;

  while ( my ($name, $ctor) = each %{$spec->{'ctor'}} ) {
    $spec->{'abstract'} ||= $ctor->{'abstract'};

    if ($ctor->{'shared'}) {
      localscope: {
        local $^W;
        no strict 'refs';
        my $classctor = sub {
          my $self = shift;
          _set_context ref($self)||$self; 
                                

          $_->{'code'}->(@_)  foreach ( @{$ctor->{'impl'}} );      


          _free_context;
        };
        $classname->$classctor();
#        *{"${classname}::$name"} = $classctor  if $name;
      }
    } else {
      localscope:{
        local $^W;
        no strict 'refs';
        *{"${classname}::$name"} = sub {
          my $proto = shift;
          my $class = ref($proto)||$proto;
          my $self = Class::Contract::Production::generic_ctor($class);
          _set_context $self;
      
      
          $_->{'code'}->(@_)  foreach ( @{$ctor->{'impl'}} );
      
      
          _free_context;
          return $self;
        }
      }
    }
  }
}

use Data::Dumper;
sub _destructors {

  my ($classname, $spec) = @_;
  my $dtorcount = 0;

  while ( my ($name, $dtor) = each %{$spec->{'dtor'}} ) {
    $spec->{'abstract'} ||= $dtor->{'abstract'};
    
    if ($dtor->{'shared'}) {
      localscope: {
        local $^W;
        no strict 'refs';
        my $classdtor = sub {
          croak "Illegal explicit invokation of class dtor", $dtor->{'loc'}
            if caller() ne 'Class::Contract::Production';
          my $self = shift;
          $self = ref $self  if ref $self;
          
          _set_context $self;
          
          
          $_->{'code'}->(@_)  foreach ( @{$dtor->{'impl'}} );
          
          _free_context;
        };
        
        push @class_dtors, sub { $classname->$classdtor() };
      }
    } else {
      croak "Class $classname has too many destructors"  if $dtorcount++;
      
      localscope: {
        local $^W;
        no strict 'refs';
        my $objdtor = sub {
          croak "Illegal explicit invokation of object dtor", $dtor->{'loc'}
            if caller() ne 'Class::Contract::Production';
          
          my $self = shift;
          _set_context $self;
          
          
          $_->{'code'}->(@_)  foreach ( @{$dtor->{'impl'}||[]} );
          
          
          _free_context;
          return;
        };
        
        *{"${classname}::DESTROY"} = sub {
          $_[0]->$objdtor();
          delete $data{${$_[0]}}  if exists $data{${$_[0]}};
        };
      }
    }
  }
  unless (defined &{"${classname}::DESTROY"}) {
    local $^W;
    no strict 'refs';
    *{"${classname}::DESTROY"} = sub {
      delete $data{${$_[0]}}  if exists $data{${$_[0]}};
    };
  }
}

sub _clones {
  my ($classname, $spec) = @_;
  my $clone_count = 0;
  
  $spec->{'clone'}{''} = bless {
    'name'     => '',
    'shared'   => 0,
    'abstract' => 0,
    'loc'      => '<implicit>'
  }, 'Class::Contract::Production::clone'
    unless $spec->{'clone'};

  while ( my ($name, $clause) = each %{$spec->{'clone'}} ) {
    
    $spec->{'abstract'} ||= $clause->{'abstract'};
    croak "'class' clause can not be used to qualify 'clon'"
      if $clause->{'shared'};
    croak "too many clon clauses"  if $clone_count++;
  
    localscope: {
      local $^W;
      no strict 'refs';
      *{"${classname}::clone"} = sub {
        my $self = shift;
        $self = generic_clone($self);
        _set_context $self;
          
        
        $_->{'code'}->(@_)  foreach ( @{$clause->{'impl'}||[]} );
          
          
        _free_context;
        return $self;
      };
    }
  }
}

localscope: {
  my ($a,$z) = (qr/(^|^.*?=)/, qr/\(.*?\)$/);
  my %seen = ();
  my $depth = 0;
  sub _dcopy { # Dereference and return a deep copy of whatever's passed
    my ($r, $ref, $rval);
    $ref = ref($_[0])   or return $_[0];
    exists $seen{$_[0]} and return $seen{$_[0]};
    $depth++;

    $r =
      ($_[0] =~ /${a}HASH$z/)   ? {map _dcopy($_), (%{$_[0]})}
    : ($_[0] =~ /${a}ARRAY$z/)  ? [map _dcopy($_), @{$_[0]} ]
    : ($_[0] =~ /${a}SCALAR$z/) ? do { my $v = _dcopy(${$_[0]}); \$v }
    : ($_[0] =~ /${a}FORMAT$z/) ? $_[0]
    : ($_[0] =~ /${a}CODE$z/)   ? $_[0]
    : ($_[0] =~ /${a}Regexp$z/) ? $_[0]
    : ($_[0] =~ /${a}REF$z/)    ? $_[0]
    : ($_[0] =~ /${a}GLOB$z/)   ? $_[0]
    : $_[0]->can('clone') ? $_[0]->clone : $_[0];

    $rval = $ref =~ /^(HASH|ARRAY|SCALAR|GLOB|FORMAT|CODE|Regexp|REF)$/ 
             ? $r
             : bless $r, $ref;

    --$depth 
      and $seen{$_[0]} = $rval
      or  %seen = (); 

    return $rval;
  }
}


1;

__END__

=head1 NAME

Class::Contract - Design-by-Contract OO in Perl.

=head1 VERSION

This document describes version 1.10 of Class::Contract,
released February  9, 2001.

=head1 SYNOPSIS

    package ClassName
    use Class::Contract;

    contract {
      inherits 'BaseClass';

      invar { ... };

      attr 'data1';
      attr 'data2' => HASH;

      class attr 'shared' => SCALAR;

      ctor 'new';

      method 'methodname';
        pre  { ... };
          failmsg 'Error message';

        post  { ... };
          failmsg 'Error message';

        impl { ... };

      method 'nextmethod';
        impl { ... };

      class method 'sharedmeth';
        impl { ... };

      # etc.
    };


=head1 DESCRIPTION

=head2 Background

Design-by-contract is a software engineering technique in which each
module of a software system specifies explicitly what input (or data or
arguments) it requires, and what output (or information or results) it
guarantees to produce in response.

These specifications form the "clauses" of a contract between a
module and the client software that uses it. If the client software
abides by the input requirements, the module guarantees to produce
the correct output. Hence by verifying these clauses at each
interaction with a module, the overall behaviour of the system can
be confidently predicted.

Design-by-contract reinforces the benefits of modular design techniques
by inserting explicit compile-time or run-time checks on a contract.
These checks are most often found in object-oriented languages
and are typically implemented as pre-conditions and post-conditions
on methods, and invariants on classes.

Note that these features differ from simple verification statements
such as the C C<assert> statement. Conditions and invariants are
properties of a class, and are inherited by derived classes.

An additional capacity that is often provided in design-by-contract
systems is the ability to selectively disable checking in production
code. This allows the contractual testing to be carried out
during implementation, without impinging on the performance of
the final system.

=head2 Adding design-by-contract to Perl

The Class::Contract module provides a framework for specifying
methods and attributes for a class (much like the existing class
definition modules Class::Struct, Class::MethodMaker, and 
Class::Generate). Class::Contract allows both per-object and per-class
methods and attributes to be defined. Attributes may be scalar-, array-,
hash-, or object-based.

Class::Contract differs from other class-specification modules (except
Class::Generate) in that it also provides the ability to specify
invariant conditions on classes, and pre- and post-conditions on methods
and attributes. All of these clauses are fully inheritable, and may be
selectively disabled. It differs from all other modules in that it has a
cleaner, simpler specification syntax, and -- more importantly -- it
enforces encapsulation of object attributes, thereby ensuring that the
class contract cannot be subverted.


=head2 Defining classes

Class::Contract provides an explicit syntax for defining the attributes,
methods, and constructors of a class. The class itself is defined using
the C<contract> subroutine. C<contract> takes a single argument -- a
subroutine reference or a block. That block is executed once and the
results used to construct and install the various components of the
class in the current package:

        package Queue;
        contract {
          # specification of class Queue attributes and methods here
        };

=head2 Defining attributes

Attributes are defined within the C<contract> block via the C<attr> subroutine.
Attributes must be given a name, and may also be given a type: C<SCALAR>,
C<ARRAY>, C<HASH>, or a class name:

        contract {
                attr 'last';                   # Scalar attribute (by default)
                attr 'lest' => SCALAR;         # Scalar attribute
                attr 'list' => ARRAY;          # Array attribute
                attr 'lost' => HASH;           # Hash attribute
                attr 'lust' => MyClass;        # Object attribute
        };

For each attribute so declared, Class::Contract creates an I<accessor> -- a
method that returns a reference to the attribute in question. Code using these
accessors might look like this:

        ${$obj->last}++;
        push @{$obj->list}, $newitem;
        print $obj->lost->{'marbles'};
        $obj->lust->after('technology stocks');

Attributes are normally object-specific, but it is also possible to define
attributes that are shared by all objects of a class. Class objects are
specified by prefixing the call to C<attr> with a call to the C<class>
subroutine:

        class Queue;
        contract {
                class attr 'obj_count';
        };

The accessor for this shared attribute can now be called either as an
object method:

        print ${$obj->obj_count};

or as a class method:

        print ${Queue->obj_count};

In order to ensure that the clauses of a class' contract (see below)
are honoured, both class and object attributes are only accessible via
their accessors, and those accessors may only be called within methods
belonging to the same class hierarchy. Objects are implemented as
"flyweight scalars" in order to ensure this strict encapsulation is
preserved.

=head2 Defining methods

Methods are defined in much the same way as attributes. The C<method>
subroutine is used to specify the name of a method, then the C<impl>
subroutine is used to provide an implementation for it:

        contract {
                attr list => ARRAY;

                method 'next';
                    impl { shift @{self->list} };

                method 'enqueue';
                    impl { push @{self->list}, $_[1] };
        };

C<impl> takes a block (or a reference to a subroutine), which is used as
the implementation of the method named by the preceding C<method> call.
Within that block, the subroutine C<self> may be used to return a
reference to the object on which the method was called. Unlike, regular
OO Perl, the object reference is not passed as the method's first argument.
(Note: this change occurred in version 1.10)

Like attributes, methods normally belong to -- and are accessed via -- a
specific object. To define methods that belong to the entire class, the
C<class> qualifier is once again used:

        contract {
                class attr 'obj_count';

                class method 'inc_count';
                        impl { ${self->obj_count}++ };
        };

Note that the C<self> subroutine can still be used -- within a class
method it returns the appropriate class name, rather than an object
reference.

=head2 Defining constructors

Class::Contract requires constructors to be explicitly defined using
the C<ctor> subroutine:

        contract {
                ctor 'new';
                    impl { @{self->list} = ( $_[0] ) }
        };

Note that the implementation section of a constructor I<doesn't> specify
code to build or bless the new object. That is taken care of
automatically (in order to ensure the correct "flyweight"
implementation of the object).

Instead, the constructor implementation is invoked I<after> the object
has been created and blessed into the class. Hence the implementation
only needs to initialize the various attributes of the C<self> object.
In addition, the return value of the implementation is ignored:
constructor calls always return a reference to the newly created object.

Any attribute that is not initialized by a constructor is
automatically "default initialized". By default, scalar attributes
remain C<undef>, array and hash attributes are initialized to an empty
array or hash, and object attributes are initialized by having their
C<new> constructor called (with no arguments). This is the only
reasonable default for object attributes, but it is usually advisable to
initialize them explicitly in the constructor.

It is also possible to define a "class constructor", which may be used
to initialize class attributes:

        contract {
                class attr 'obj_count';

                class ctor;
                        impl { ${self->obj_count} = 0 };
        };

The class constructor is invoked at the very end of the call to
C<contract> in which the class is defined.

Note too that the class constructor does not require a name. It may,
however, be given one, so that it can be explicitly called again (as a
class method) later in the program:

        class MyClass;
        contract {
                class attr 'obj_count';

                class ctor 'reset';
                        impl { ${self->obj_count} = 0 };
        };

        # and later...

        MyClass->reset;


=head2 Defining destructors

Destructors are also explicitly defined under Class::Contract,
using the C<dtor> subroutine:

        contract {
                dtor;
                    impl { print STDLOG "Another object died\n" }
        };

As with the constructor, the implementation section of a destructor
doesn't specify code to clean up the "flyweight" implementation of
the object. Class::Contract takes care of that automatically.

Instead, the implementation is invoked I<before> the object is
deallocated, and may be used to clean up any of the internal structure
of the object (for example to break reference cycles).

It is also possible to define a "class destructor", which may be used
to clean up class attributes:

        contract {
                class attr 'obj_count';

                class dtor;
                    impl { print STDLOG "Total was ${self->obj_count}\n" };
        };

The class destructor is invoked from an C<END> block within Class::Contract
(although the implementation itself is a closure, so it executes in the
namespace of the original class).


=head2 Constraining class elements

As described so far, Class::Contract doesn't provide any features that
differ greatly from those of any other class definition module. But
Class::Contract does have one significant difference: it allows the
class designer to specify "clauses" that implement and enforce a
contract on the class's interface.

Contract clauses are specified as labelled blocks of code, associated
with a particular class, method, or attribute definition. 

=head2 Class invariants

Classes may be given I<invariants>: clauses than must be satisfied at
the end of any method call that is invoked from outside the class
itself. For example, to specify that a class's object count attribute
must never fall below zero:

        contract {
                invar { ${self->obj_count} >= 0 };
        };

The block following C<invar> is treated as if it were a class method
that is automatically invoked after every other method invocation. If the
method returns false, C<croak> is invoked with the error message:
C<'Class invariant at %s failed'> (where the C<'%s'> is replaced by the file
and line number at which the invariant was defined).

This error message can be customized, using the C<failmsg> subroutine:

        contract {
                invar { ${self->obj_count} >= 0 };
                    failmsg 'Anti-objects detected by invariant at %s';
        };

Once again, the C<'%s'> is replaced by the appropriate file name and
line number. A C<failmsg> can be specified after other types of clause
too (see below).

A class may have as many invariants as it requires, and
they may be specified anywhere throughout the the body of the C<contract>.

=head2 Attribute and method pre- and post-conditions

Pre- and post-conditions on methods and attributes are specified
using the C<pre> and C<post> subroutines respectively.

For attributes, pre-conditions are called before the attribute's
accessor is invoked, and post-conditions are called after the reference
returned by the accessor is no longer accessible. This is
achieved by having the accessor return a tied scalar whose C<DESTROY>
method invokes the post-condition.

Method pre-conditions are tested before their method's implementation is
invoked; post-conditions are tested after the implementation finishes
(but before the method's result is returned). Constructors are (by
definition) class methods and may have pre- and post-conditions, just
like any other method.

Both types of condition clause receive the same argument list as the
accessor or method implementation that they constrain. Both are expected
to return a false value if they fail:

        contract {
                class attr 'obj_count';
                    post { ${&value} > 0 };
                      failmsg 'Anti-objects detected by %s';

                method 'inc_count';
                    post { ${self->obj_count} < 1000000 };
                      failmsg 'Too many objects!';
                    impl { ${self->obj_count}++ };
        };

Note that within the pre- and post-conditions of an attribute, the
special C<value> subroutine returns a reference to the attribute itself,
so that conditions can check properties of the attribute they guard.

Methods and attributes may have as many distinct pre- and
post-conditions as they require, specified in any convenient order.


=head2 Checking state changes.

Post-conditions and invariants can access the previous state of an object or
the class, via the C<old> subroutine. Within any post-condition or invariant,
this subroutine returns a reference to a copy of the object or class
state, as it was just before the current method or accessor was called.

For example, an C<append> method might use C<old> to verify the appropriate
change in size of an object:

        contract {
            method 'append';
                post { @{self->queue} == @{old->queue} + @_ }
                impl { push @{self->queue}, @_ };
        };

Note that the implementation's return value is also available in the
method's post-condition(s) and the class's invariants, through the
subroutine C<value>. In the above example, the implementation of C<append>
returns the new size of the queue (i.e. what C<push> returns), so the
post-condition could also be written:

        contract {
            method 'append';
                post { ${&value} == @{old->queue} + @_ }
                impl { push @{self->queue}, @_ };
        };

Note that C<value> will return a reference to a scalar or to
an array, depending on the context in which the method was originally
called.


=head2 Clause control

Any type of clause may be declared optional:

        contract {
                optional invar { @{self->list} > 0 };
                failmsg 'Empty queue detected at %s after call';
        };

By default, optional clauses are still checked every time a method or
accessor is invoked, but they may also be switched off (and back on) at
run-time, using the C<check> method:

        local $_ = 'Queue';         # Specify in $_ which class to disable
        check my %contract => 0;    # Disable optional checks for class Queue

This (de)activation is restricted to the scope of the hash that is passed as
the first argument to C<check>. In addition, the change only affects the
class whose name is held in the variable $_ at the time C<check> is called.
This makes it easy to (de)activate checks for a series of classes:

        check %contract => 0 for qw(Queue PriorityQueue DEQueue);  # Turn off
        check %contract => 1 for qw(Stack PriorityStack Heap);     # Turn on


The special value C<'__ALL__'> may also be used as a (pseudo-)class name:

        check %contract => 0 for __ALL__;

This enables or disables checking on every class defined using
Class::Contract. But note that only clauses that were originally
declared C<optional> are affected by calls to C<check>. Non-optional
clauses are I<always> checked.

Optional clauses are typically universally disabled in production code,
so Class::Contract provides a short-cut for this. If the module is 
imported with the single argument C<'production'>, optional clauses
are universally and irrevocably deactivated. In fact, the C<optional>
subroutine is replaced by:

        sub Class::Contract::optional {}

so that optional clauses impose no run-time overhead at all.

In production code, contract checking ought to be disabled completely,
and the requisite code optimized away.  To do that, simply change:

  use Class::Contract;

to

  use Class::Contract::Production;


=head2 Inheritance

The semantics of class inheritance for Class::Contract classes
differ in several respects from those of normal object-oriented Perl.

To begin with, classes defined using Class::Contract have a I<static
inheritance hierarchy>. The inheritance relationships of contracted classes
are defined using the C<inherits> subroutine within the class's C<contract>
block:

        package PriorityQueue;
        contract {
                inherits qw( Queue OrderedContainer );
        };


That means that ancestor classes are fixed at compile-time
(rather than being determined at run-time by the @ISA array). Note
that multiple inheritance is supported.

Method implementations are only inherited if they are not explicitly
provided. As with normal OO Perl, a method's implementation is inherited
from the left-most ancestral class that provides a method of the same name
(though with Class::Contract, this is determined at compile-time).

Constructors are a special case, however. Their "constructive"
behaviour is always specific to the current class, and hence involves
no inheritance under any circumstances. However, the "initialising"
behaviour specified by a constructor's C<impl> block I<is> inherited. In
fact, the implementations of I<all> base class constructors are
called automatically by the derived class constructor (in left-most,
depth-first order), and passed the same argument list as the invoked
constructor. This behaviour is much more like that of other OO
programming languages (for example, Eiffel or C++).

Methods in a base class can also be declared as being I<abstract>:

        contract {
            abstract method 'remove';
                post { ${self->count} == ${old->count}-1 };
        };

Abstract methods act like placeholders in an inheritance hierarchy.
Specifically, they have no implementation, existing only to reserve
the name of a method and to associate pre- and post-conditions with it.

An abstract method cannot be directly called (although its associated
conditions may be). If such a method is ever invoked, it immediately
calls C<croak>. Therefore, the presence of an abstract method in a base
class requires the derived class to redefine that method, if the
derived class is to be usable. To ensure this, any constructor built by
Class::Contract will refuse to create objects belonging to classes with
abstract methods.

Methods in a base class can also be declared as being I<private>:

        contract {
            private method 'remove';
                impl { pop @{self->queue} };
        };

Private methods may only be invoked by the class or one of its 
descendants. 

=head2 Inheritance and condition checking

Attribute accessors and object methods inherit I<all> post-conditions of
every ancestral accessor or method of the same name. Objects and classes
also inherit all invariants from any ancestor classes. That is,
methods accumulate all the post- and invariant checks that their
ancestors performed, as well as any new ones they define for themselves,
and must satisfy I<all> of them in order to execute successfully.

Pre-conditions are handled slightly differently. The principles of
design-by-contract programming state that pre-conditions in derived
classes can be no stronger than those in base classes (and may well be
weaker). In other words, a derived class must handle every case that
its base class handled, but may choose to handle other cases as well,
by being less demanding regarding its pre-conditions.

Meyers suggests an efficient way to achieve this relaxation of
constraints without the need for detailed logical analysis of
pre-conditions. His solution is to allow a derived class method or
accessor to run if I<either> the pre-conditions it inherits are
satisfied I<or> its own pre-conditions are satisfied. This is precisely
the semantics that Class::Contract uses when checking pre-conditions in
derived classes.

=head2 A complete example

The following code implements a PriorityStack class, in which elements pushed
onto the stack "sink" until they encounter an element with lower priority.
Note the use of C<old> to check that object state has changed correctly, and
the use of explicit dispatch (e.g. C<self-E<gt>Stack::pop>) to invoke
inherited methods from the derived-class methods that redefine them.

        package PriorityStack;
        use Class::Contract;

        contract {
            # Reuse existing implementation...
            inherits 'Stack';

            # Name the constructor (nothing special to do, so no implementation)
            ctor 'new';

            method 'push';
                # Check that data to be added is okay...
                pre  { defined $_[0] };
                    failmsg 'Cannot push an undefined value';
                pre  { $_[1] > 0 };
                    failmsg 'Priority must be greater than zero';

                # Check that push increases stack depth appropriately...
                post { self->count == old->count+1 };

                # Check that the right thing was left on top...
                post { old->top->{'priority'} <= self->top->{'priority'} };

                # Implementation reuses inherited methods: pop any higher
                # priority entries, push the new entry, then re-bury it...
                impl {
                    my ($newval, $priority) = @_[0,1];
                    my @betters;
                    unshift @betters, self->Stack::pop 
                        while self->count
                           && self->Stack::top->{'priority'} > $priority;
                    self->Stack::push( {'val'=>$newval, priority=>$priority} );
                    self->Stack::push( $_ )  foreach @betters;
                };

            method 'pop';
                # Check that pop decreases stack depth appropriately...
                post { self->count == old->count-1 };

                # Reuse inherited method...
                impl {
                    return  unless self->count;
                    return self->Stack::pop->{'val'};
                };

            method 'top';
                post { old->count == self->count }
                impl {
                    return  unless self->count;
                    return self->Stack::top->{'val'};
                };
        };


=head1 FUTURE WORK

Future work on Class::Contract will concentrate on three areas:

=over 4

=item 1.  Improving the attribute accessor mechanism 

Lvalue subroutines will be introduced in perl version 5.6. They will allow
a return value to be treated as an alias for the (scalar) argument of a
C<return> statement. This will make it possible to write subroutines whose
return value may be assigned to (like the built-in C<pos> and C<substr>
functions).

In the absence of this feature, Class::Contract accessors of all types
return a reference to their attribute, which then requires an explicit
dereference:

        ${self->value} = $newval;
        ${self->access_count}++;

When this feature is available, accessors for scalar attributes will be
able to return the actual attribute itself as an lvalue. The above code
would then become cleaner:

        self->value = $newval;
        self->access_count++;


=item 2.  Providing better software engineering tools.

Contracts make the consequences of inheritance harder to predict, since
they significantly increase the amount of ancestral behaviour (i.e.
contract clauses) that a class inherits.

Languages such as Eiffel provide useful tools to help the
software engineer make sense of this extra information. In
particular, Eiffel provides two alternate ways of inspecting a
particular class -- flat form and short form.

"Flattening" a class produces an equivalent class definition without any
inheritance. That is, the class is modified by making explicit all the
attributes, methods, conditions, and invariants it inherits from other
classes. This allows the designer to see every feature a class possesses
in one location.

"Shortening" a class, takes the existing class definition and removes all 
implementation aspects of it -- that is, those that have no bearing on its
public interface. A shortened representation of a class therefore has all
attribute specifications and method implementations removed. Note that
the two processes can be concatenated: shortening a flattened class
produces an explicit listing of its complete public interface. Such a
representation can be profitably used as a basis for documenting the
class.

It is envisaged that Class::Contract will eventually provide a mechanism to 
produce equivalent class representations in Perl.


=item 3.  Offering better facilities for retrofitting contracts.

At present, adding contractual clauses to an existing class requires a
major restructuring of the original code. Clearly, if design-by-contract
is to gain popularity with Perl programmers, this transition cost must
be minimized.

It is as yet unclear how this might be accomplished, but one possibility
would be to allow the implementation of certain parts of a
Class::Contract class (perhaps even the underlying object implementation
itself) to be user-defined.

=back

=head1 AUTHOR

Damian Conway (damian@conway.org)

=head1 MAINTAINER

C. Garrett Goebel (ggoebel@cpan.org)

=head1 BUGS

There are undoubtedly serious bugs lurking somewhere in code this funky :-)
Bug reports and other feedback are most welcome.

=head1 COPYRIGHT

Copyright (c) 1997-2000, Damian Conway. All Rights Reserved.
This module is free software. It may be used, redistributed
and/or modified under the terms of the Perl Artistic License
  (see http://www.perl.com/perl/misc/Artistic.html)

Copyright (c) 2000-2001, C. Garrett Goebel. All Rights Reserved.
This module is free software. It may be used, redistributed
and/or modified under the terms of the Perl Artistic License
  (see http://www.perl.com/perl/misc/Artistic.html)
