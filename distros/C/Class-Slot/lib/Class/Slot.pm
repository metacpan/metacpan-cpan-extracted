package Class::Slot;
# ABSTRACT: Simple, efficient, comple-time class declaration
$Class::Slot::VERSION = '0.08';
use strict;
use warnings;

no strict 'refs';
no warnings 'redefine';

use Scalar::Util qw(refaddr);
use Filter::Simple;
use Carp;

our $DEBUG_ALL = $ENV{CLASS_SLOT_DEBUG}; # Enable debugging for all classes
our %DEBUG;                              # Enable debugging for individual classes
our $XS;                                 # Class::XSAccessor support
our $LATE;                               # Set to true in INIT to trigger run-time over compile-time behavior
our %CLASS;                              # Class slot data
our %TYPE;                               # Stores type objects outside of %CLASS for easier printf debugging
our %C3;                                 # Enable breadth-first resolution for individual classes

BEGIN {
  $DEBUG_ALL = $ENV{CLASS_SLOT_DEBUG} ? 1 : 0;

  if ($ENV{CLASS_SLOT_NO_XS}) {
    $XS = 0;
  } else {
    eval 'use Class::XSAccessor';
    $XS = $@ ? 0 : 1;
  }
}

INIT {
  $LATE = 1;

  # When multiple packages are defined in a single file or top-level string
  # eval, they will generate a definition before INIT is called. If they refer
  # to each other, one may call a method of the other before the class' init
  # has been called.
  #
  # To handle this case, we scan the %CLASS definitions for classes which have
  # been defined but not yet initialized - that is, they are in %CLASS but the
  # 'init' function hasn't been run yet (it deletes itself when it completes) -
  # and then run those classes' initializers..
  for my $class (keys %CLASS) {
    next unless exists $Class::Slot::CLASS{$class}{init};

    *{$class. '::new'} = sub {
      $Class::Slot::CLASS{$class}{init}->();
      goto $class->can('new');
    };
  }
}

sub import {
  my $class = shift;
  my $name  = shift;
  my ($caller, $file, $line) = caller;

  # Initialize the class
  unless (exists $CLASS{$caller}) {
    $C3{$caller} ||= 0;

    *{ $caller . '::get_slots' } = \&get_slots;

    $CLASS{$caller} = {
      slot  => {}, # slot definitions
      slots => [], # list of slot names

      # Generate initialization code for the class itself. Because all slots
      # are not yet known, this will be executed in a CHECK block at compile
      # time. If the class is being generated after CHECK (such as from a
      # string eval), it will be lazily evaluated the first time 'new' is
      # called on the class.

      init => sub{
        # Ensure any accessor methods defined by $caller's parent class(es)
        # have been built.
        for (@{ $caller . '::ISA' }) {
          if (exists $CLASS{$_} && defined $CLASS{$_}{init}) {
            $CLASS{$_}{init}->();
          }
        }

        my %slots = %{ $caller->get_slots };

        # Build constructor
        my $ctor = _build_ctor($caller);

        # Build accessors
        my $acc = join "\n", map{ _build_accessor($caller, $_) }
          keys %slots;

        # Build delegate accessors
        my $delegates = join "\n", map{ _build_delegates($caller, $_) }
          keys %slots;

        # Build @SLOTS
        my $slots = join ' ', map{ quote_identifier($_) }
          sort keys %slots;

        my $pkg  = qq{package $caller;
no warnings 'redefine';
no Class::Slot;
use Carp;

our \@SLOTS = qw($slots);

#-------------------------------------------------------------------------------
# Constructor
#-------------------------------------------------------------------------------
$ctor

#-------------------------------------------------------------------------------
# Accessors
#-------------------------------------------------------------------------------
$acc

#-------------------------------------------------------------------------------
# Delegate accessors
#-------------------------------------------------------------------------------
$delegates};

        if ($DEBUG_ALL || $DEBUG{$caller}) {
          print "\n";
          print "================================================================================\n";
          print "# slot generated the following code:\n";
          print "================================================================================\n";
          print "$pkg\n";
          print "================================================================================\n";
          print "# end of slot-generated code\n";
          print "================================================================================\n";
          print "\n";
        }

        # Install into calling package
        eval $pkg;
        $@ && die $@;

        delete $CLASS{$caller}{init};
      },
    };

    # Whereas with a run-time eval the definitions of all slots are not yet
    # known and CHECK is not available, so methods may be installed on the
    # first call to 'new'.
    if ($LATE) {
      *{$caller . '::new'} = sub {
        $Class::Slot::CLASS{$caller}{init}->();
        goto $caller->can('new');
      };
    }
    # Compile-time generation allows use of CHECK to install our methods once
    # the entire class has been loaded.
    else {
      eval qq{
# line $line "$file"
CHECK {
  \$Class::Slot::CLASS{'$caller'}{init}->()
    if exists \$Class::Slot::CLASS{'$caller'}{init};
}
};

      $@ && die $@;
    }
  }

  if (defined $name) {
    # Handle special parameters
    if ($name eq '-debugall') {
      $DEBUG_ALL = 1;
      return;
    }

    if ($name eq '-debug') {
      $DEBUG{$caller} = 1;
      return;
    }

    if ($name =~ /^c3$/i) {
      $C3{$caller} = 1;
      return;
    }

    # Suss out slot parameters
    my ($type, %param) = (@_ % 2 == 0)
      ? (undef, @_)
      : @_;

    $type = Class::Slot::AnonType->new($type)
      if ref $type eq 'CODE';

    croak "slot ${name}'s type is invalid"
      if defined $type
      && !ref $type
      && !$type->can('can_be_inlined')
      && !$type->can('inline_check')
      && !$type->can('check');

    # Ensure that the default value is valid if the type is set
    if (exists $param{def} && $type) {
      croak "default value for $name is not a valid $type"
        unless $type->check(ref $param{def} eq 'CODE' ? $param{def}->() : $param{def});
    }

    # Validate that delegate methods are defined as an array or hash ref
    if (exists $param{fwd}) {
      croak "delegate forwarding for $name must be expressed as an array ref or hash ref"
        if ref($param{fwd}) !~ /^(?:ARRAY)|(?:HASH)$/;

      if (ref $param{fwd} eq 'ARRAY') {
        my %tmp;
        $tmp{$_} = $_ for @{$param{fwd}};
        $param{fwd} = \%tmp;
      }
    }

    $CLASS{$caller}{slot}{$name} = {
      pkg  => $caller,
      file => $file,
      line => $line,
    };

    if (defined $type) {
      my $addr = refaddr $type;
      $CLASS{$caller}{slot}{$name}{type} = $addr;
      $TYPE{$addr} = $type;
    }

    for (qw(def req rw fwd)) {
      $CLASS{$caller}{slot}{$name}{$_} = $param{$_}
        if exists $param{$_};
    }

    push @{ $CLASS{$caller}{slots} }, $name;
  }
}

#-------------------------------------------------------------------------------
# Constructor
#-------------------------------------------------------------------------------
sub _build_ctor {
  my $class = shift;

  my $code = qq{sub new \{
  my \$class = shift;
};

  my $has_parents = @{ $class . '::ISA' };

  # Look for constructor in inheritence change
  my $can_ctor = 0;
  for (@{ $class . '::ISA' }) {
    if ($_->can('new')) {
      $can_ctor = 1;
      last;
    }
  }

  if ($can_ctor) {
    $code .= "  my \$self = \$class->SUPER::new(\@_);\n";
  } else {
    $code .= "  my \$self = bless { \@_ }, \$class;\n";
  }

  $code .= qq{
  # Skip type validation when called as a SUPER method from a recognized child class' constructor.
  return \$self if ref(\$self) ne '$class' && exists \$Class::Slot::CLASS{ref(\$self)};
};

  my $slots = $class->get_slots;

  for my $name (keys %$slots) {
    my $slot  = $slots->{$name};
    my $line  = qq{# line $slot->{line} "$slot->{file}"};
    my $req   = $slot->{req};
    my $def   = $slot->{def};
    my $type  = $TYPE{$slot->{type}} if exists $slot->{type};
    my $ident = quote_identifier($name);

    if ($req && !defined $def) {
      $code .= "\n$line\n  croak '$ident is a required field' unless exists \$self->{'$ident'};\n";
    }

    if ($type) {
      my $addr = refaddr $type;
      my $check = $type->can_be_inlined
        ? $type->inline_check("\$self->{'$ident'}")
        : "\$Class::Slot::TYPE{'$addr'}->check(\$self->{'$ident'})";

      $code .= qq{$line
  croak '${class}::$ident did not pass validation as type $type' unless !exists \$self->{'$ident'} || $check;

};
    }

    if (defined $def) {
      $code .= "$line\n  \$self->{'$ident'} = ";
      $code .= (ref $def eq 'CODE')
        ? "\$CLASS{'$class'}{slot}{'$ident'}{def}->(\$self)"
        : "\$CLASS{'$class'}{slot}{'$ident'}{def}";

      $code .= " unless exists \$self->{'$ident'};\n";
    }
  }

  $code .= "  \$self;\n}\n";

  return $code;
}

#-------------------------------------------------------------------------------
# Slot data
#-------------------------------------------------------------------------------
sub get_mro {
  my @todo = ( $_[0] );
  my %seen;
  my @mro;

  while (my $class = shift @todo) {
    next if $seen{$class};
    $seen{$class} = 1;

    if (@{$class . '::ISA'}) {
      if ($C3{$class}) {
        push @todo, @{$class . '::ISA'};
      } else {
        unshift @todo, @{$class . '::ISA'};
      }
    }

    push @mro, $class;
  }

  return @mro;
}

sub get_slots {
  my ($class, $name) = @_;
  my @mro = get_mro $class;
  my %slots;

  for my $class (@mro) {
    next unless exists $CLASS{$class};

    my @slots = defined $name ? ($name) : @{$CLASS{$class}{slots}};

    for my $slot (@slots) {
      if (!exists $slots{$slot}) {
        $slots{$slot} = $CLASS{$class}{slot}{$slot};
      }
      else {
        for my $cfg (qw(rw req def line file)) {
          if (!exists $slots{$slot}{$cfg} && exists $CLASS{$class}{slot}{$slot}{$cfg}) {
            $slots{$slot}{$cfg} = $CLASS{$class}{slot}{$slot}{$cfg};
          }
        }

        if (!exists $slots{$slot}{type} && exists $CLASS{$class}{slot}{$slot}{type}) {
          $slots{$slot}{type} = $TYPE{$CLASS{$class}{slot}{$slot}{type}};
        }
      }
    }
  }

  if (defined $name) {
    return $slots{$name};
  } else {
    return \%slots;
  }
}

#-------------------------------------------------------------------------------
# Delegate methods
#-------------------------------------------------------------------------------
sub _build_delegates {
  my ($class, $name) = @_;
  my $slot = $class->get_slots($name);
  return '' unless exists $slot->{fwd};

  my $fwd   = $slot->{fwd};
  my $line  = qq{# line $slot->{line} "$slot->{file}"};
  my $ident = quote_identifier($name);
  my $code  = '';

  for (keys %$fwd) {
    my $local_method  = quote_identifier($_);
    my $remote_method = quote_identifier($fwd->{$_});
    $code .= "$line\nsub $local_method { shift->${ident}->${remote_method}(\@_) }";
  }

  return $code;
}

#-------------------------------------------------------------------------------
# Accessors
#-------------------------------------------------------------------------------
sub _build_accessor {
  my ($class, $name) = @_;
  return $class->get_slots($name)->{'rw'}
    ? _build_setter($class, $name)
    : _build_getter($class, $name);
}

#-------------------------------------------------------------------------------
# Read-only accessor
#-------------------------------------------------------------------------------
sub _build_getter {
  my ($class, $name) = @_;
  if ($XS) {
    return _build_getter_xs($class, $name);
  } else {
    return _build_getter_pp($class, $name);
  }
}

sub _build_getter_xs {
  my ($class, $name) = @_;
  my $ident = quote_identifier($name);
  return "use Class::XSAccessor getters => {'$ident' => '$ident'}, replace => 1, class => '$class';\n";
}

sub _build_getter_pp {
  my ($class, $name) = @_;
  my $ident = quote_identifier($name);
  my $slot  = $class->get_slots($name);
  my $line  = qq{# line $slot->{line} "$slot->{file}"};
  return qq{sub $ident \{
$line
  croak "${class}::$ident is protected" if \@_ > 1;
  return \$_[0]->{'$ident'} if defined wantarray;
\}
};
}

#-------------------------------------------------------------------------------
# Read-write accessor
#-------------------------------------------------------------------------------
sub _build_setter {
  my ($class, $name) = @_;
  if ($XS && !$class->get_slots($name)->{type}) {
    return _build_setter_xs($class, $name);
  } else {
    return _build_setter_pp($class, $name);
  }
}

sub _build_setter_xs {
  my ($class, $name) = @_;
  my $ident = quote_identifier($name);
  return "use Class::XSAccessor accessors => {'$ident' => '$ident'}, replace => 1, class => '$class';\n";
}

sub _build_setter_pp {
  my ($class, $name) = @_;
  my $slot  = $class->get_slots($name);
  my $line  = qq{# line $slot->{line} "$slot->{file}"};
  my $type  = $TYPE{$slot->{type}} if $slot->{type};
  my $ident = quote_identifier($name);

  my $code = "sub $ident {\n  if (\@_ > 1) {";

  if ($type) {
    my $addr = refaddr $type;
    my $check = $type->can_be_inlined
      ? $type->inline_check('$_[1]')
      : "\$Class::Slot::TYPE{'$addr'}->check(\$_[1])";

      $code .= qq{
$line
    croak '${class}::$ident did not pass validation as type $type' unless $check;
};
  }

  $code .= qq{    \$_[0]->{'$ident'} = \$_[1];
  \}

  return \$_[0]->{'$ident'} if defined wantarray;
\}
};
}

#-------------------------------------------------------------------------------
# Helpers
#-------------------------------------------------------------------------------
sub quote_identifier {
  my $ident = shift;
  $ident =~ s/([^a-zA-Z0-9_]+)/_/g;
  return $ident;
}

sub install_sub {
  my ($class, $name, $code) = @_;
  my $caller = caller;
  my $sym = $class . '::' . quote_identifier($name);

  *{$sym} = sub {
    eval qq{
package $class;
sub $name \{
$code
\}
package $caller;
    };

    $@ && die $@;
    goto $class->can($name);
  };
}

sub install_method {
  my ($class, $name, $code) = @_;
  install_sub($class, $name, "  my \$self = shift;\n$code");
}

#-------------------------------------------------------------------------------
# Source filter:
#   * 'use slot' -> 'use Class::Slot'
#   * 'slot'     -> 'use Class::Slot'
#   * 'slot::'   -> 'Class::Slot::'
#-------------------------------------------------------------------------------
FILTER {
  s/\buse slot\b/use Class::Slot/g;
  s/\bslot::/Class::Slot::/g;
  s/^\s*slot\b/use Class::Slot/gsm;
};

1;


package Class::Slot::AnonType;
$Class::Slot::AnonType::VERSION = '0.08';
use strict;
use warnings;
use Carp;

use overload
  '""' => sub{ '(anon code type)' };

sub new {
  my ($class, $code) = @_;
  bless $code, $class;
}

sub can_be_inlined { 0 }
sub inline_check { croak 'not supported' }

sub check {
  my $self = shift;
  $self->(shift);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Class::Slot - Simple, efficient, comple-time class declaration

=head1 VERSION

version 0.08

=head1 SYNOPSIS

  package Point;

  use Class::Slot;
  use Types::Standard -types;

  slot x => Int, rw => 1, req => 1;
  slot y => Int, rw => 1, req => 1;
  slot z => Int, rw => 1, def => 0;

  1;

  my $p = Point->new(x => 10, y => 20);
  $p->x(30); # x is set to 30
  $p->y;     # 20
  $p->z;     # 0

=head1 DESCRIPTION

Similar to the L<fields> pragma, C<slot> declares individual fields in a
class, building a constructor and slot accessor methods.

Although not nearly as full-featured as L<other|Moose> L<solutions|Moo>,
C<Class::Slot> is light-weight, fast, works with basic Perl objects, and
imposes no dependencies outside of the Perl core distribution. Currently, only
the unit tests require non-core packages.

C<Class::Slot> is intended for use with Perl's bare metal objects. It provides
a simple mechanism for building accessor and constructor code at compile time.

It does I<not> provide inheritance; that is done by setting C<@ISA> or via the
C<base> or C<parent> pragmas.

It does I<not> provide method wrappers; that is done with the C<SUPER>
pseudo-class.

It I<does> build a constructor method, C<new>, with support for default and
required slots as keyword arguments and type validation of caller-supplied
values.

It I<does> build accesor methods (reader or combined reader/writer, using the
slot's name) for each slot declared, with support for type validation.

=head1 @SLOTS

The C<@SLOTS> package variable is added to the declaring package and is a list
of quoted slot identifiers. C<@SLOTS> includes I<all> slots available to this
class, including those defined in its ancestors.

=head1 CONSTRUCTOR

C<Class::Slot> generates a constructor method named C<new>. If there is already
an existing method with that name, it may be overwritten, depending on the
order of execution.

=head1 DECLARING SLOTS

The pragma itself accepts two positional parameters: the slot name and optional
type. The type is validated during construction and in the setter, if the slot
is read-write.

Slot names must be valid perl identifiers suitable for subroutine names. Types
must be either a code ref which returns true for valid values or an instance of
a class that supports the C<can_be_inlined>, C<inline_check>, and C<check>
methods (see L<Type::Tiny/Inlining methods>).

The C<slot> pragma may be used as either a keyword or a pragma. The following
are equivalent:

  use Class::Slot x => Int;
  use slot x => Int;
  slot x => Int;

A simple source filter is used to translate uses of C<slot> and C<use slot>
into C<use Class::Slot>. This is a somewhat brittle solution to ensuring
compile time code generation while avoiding a clash with
L<Tie::Hash::KeysMask>, which uses the C<slot> namespace internally but
nevertheless holds the keys to it on CPAN.

As a result, care must be taken when defining slots using the C<slot name ...>
syntax (rather than C<use Class::Slot name ...>). The source filter identifies
the keyword C<slot> when it appears as the first value on a line, followed by
a word boundary. There is the potential for false positives, such as with:

  my @ots = qw(
    slot blot glot clot
  );

=head1 OPTIONS

=head2 rw

When true, the accessor method accepts a single parameter to modify the slot
value. If the slot declares a type, the accessor will croak if the new value
does not validate.

=head2 req

When true, this constructor will croak if the slot is missing from the named
parameters passed to the constructor. If the slot also declares a
L<default|/def> value, this attribute is moot.

=head2 def

When present, this value or code ref which returns a value is used as the
default if the slot is missing from the named parameters passed to the
constructor.

If the default is a code ref which generates a value and a type is specified,
note that the code ref will be called during compilation to validate its type
rather than re-validating it with every accessor call.

=head2 fwd

When present, generates delegate accessor methods that forward to a mapped
method on the object stored in the slot. For example:

  # Foo.pm
  class Foo;

  sub life{ 42 }

  1;


  # Bar.pm
  class Bar;
  use Class::Slot;
  use parent 'Foo';

  slot 'foo', fwd => ['life'];

  1;


  # main.pl
  my $bar = Bar->new(foo => Foo->new);
  say $bar->life; # calls $bar->foo->life

Alternately, C<fwd> may be defined as a hash ref mapping new local method
names to method names in the delegate class:

  # Bar.pm
  class Bar;
  use Class::Slot;
  use parent 'Foo';

  slot 'foo', fwd => {barlife => 'life'};

  1;


  # main.pl
  my $bar = Bar->new(foo => Foo->new);
  say $bar->barlife; # calls $bar->foo->life
  say $bar->life;    # dies: method not found

=head1 INHERITANCE

When a class declares a slot which is also declared in the parent class, the
parent class' settings are overridden. Any options I<not> included in the
overriding class' slot declaration remain in effect in the child class.

  package A;
  use Class::Slot;

  slot 'foo', rw => 1;
  slot 'bar', req => 1, rw => 1;

  1;

  package B;
  use Class::Slot;
  use parent -norequire, 'A';

  slot 'foo', req => 1; # B->foo is req, inherits rw
  slot 'bar', rw => 0;  # B->bar inherits req, but is no longer rw

  1;

=head1 COMPILATION PHASES

=head2 BEGIN

C<slot> statements are evaluated by the perl interpreter at the earliest
possible moment. At this time, C<Class::Slot> is still gathering slot
declarations and the class is not fully assembled.

=head2 CHECK

All slots are assumed to be declared by the C<CHECK> phase. The first slot
declaration adds a C<CHECK> block to the package that installs all generated
accessor methods in the declaring class. This may additionally trigger any
parent classes (identified by C<@ISA>) which are not yet complete.

=head2 RUNTIME

If C<CHECK> is not available (for example, because the class was generated in a
string eval), the generated code will be evaluated at run-time the first time
the class' C<new> method is called.

=head1 DEBUGGING

Adding C<use Class::Slot -debug> to your class will cause C<Class::Slot> to
print the generated constructor and accessor code just before it is evaluated.

Adding C<use Class::Slot -debugall> anywhere will cause C<Class::Slot> to emit
debug messages globally.

These may be set from the shell with the C<CLASS_SLOT_DEBUG> environmental
variable.

=head1 PERFORMANCE

C<Class::Slot> is designed to be fast and have a low overhead. When available,
L<Class::XSAccessor> is used to generate the class accessors. This applies to
slots that are not writable or are writable but have no declared type.

This behavior can be disabled by setting C<$Class::Slot::XS> to a falsey value,
although this must be done in a C<BEGIN> block before declaring any slots, or
by setting the environmental variable C<CLASS_SLOT_NO_XS> to a truthy value
before the module is loaded.

A minimal benchmark on my admittedly underpowered system compares L<Moose>,
L<Moo>, and L<Class::Slot>. The test includes multiple setters using a mix of
inherited, typed and untyped, attributes, which ammortizes the benefit of
Class::XSAccessor to L<Moo> and L<Class::Slot>.

  |           Rate   moo moose  slot
  | moo   355872/s    --  -51%  -63%
  | moose 719424/s  102%    --  -25%
  | slot  961538/s  170%   34%    --

Oddly, L<Moo> seemed to perform better running the same test without
L<Class::XSAccessor> installed.

  |           Rate   moo moose  slot
  | moo   377358/s    --  -50%  -56%
  | moose 757576/s  101%    --  -12%
  | slot  862069/s  128%   14%    --

=head1 AUTHOR

Jeff Ober <sysread@fastmail.fm>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Jeff Ober.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
