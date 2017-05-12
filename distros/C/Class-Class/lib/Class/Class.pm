package Class::Class;

require 5.005;
require Pragmatic;

use strict;


%Class::Class::BUILT_METHODS = ( );

@Class::Class::EXPORT_OK = qw (package_exists);

@Class::Class::ISA = qw(Pragmatic);

# Bookkeepping; use our own MEMBERS so that objects inherit this,
# instead of it being global:
%Class::Class::MEMBERS =
  (__inited => '%',
   __tried_polymorph => '%');

%Class::Class::PRAGMATA =
  (override_inherited =>
   sub { $Class::Class::OVERRIDE_INHERITED = 1; });

# The package version, both in 1.23 style *and* usable by MakeMaker:
$Class::Class::VERSION = (substr q$Revision: 1.18 $, 10) - 1;
my $rcs = ' $Id: Class.pm,v 1.18 2000/01/05 16:15:48 binkley Exp $ ' ;


use Carp ( );
use Class::ISA;
use Symbol ( );


BEGIN { $Class::Class::OVERRIDE_INHERITED = 0; }


# Yes, it's true: I provide a default "new" for you.  See the
# documentation (below) for an explanation of this so-called feature.
sub new ($;@) {
  # Why is this here?? --bko FIXME
  no strict qw(refs);

  my ($this, @args) = @_;
  my $class = ref ($this) || $this;
  my $self = { };
  bless $self, $class;

  $self->renew (@args);
}

# This is used to reinitialize objects:
sub renew ($;@) {
  my ($self, @args) = @_;

  return $self->_make_methods->_process_args (@args)->_initialize_parents;
}

# Copy an object:
sub clone ($;@) {
  my ($self, @args) = @_;

  return $self->new ($self, @args);
}

# NOT a method:
sub package_exists ($) {
  no strict qw (refs);

  my ($class) = @_;
  $class =~ s/^:://o; # catch ::TopLevelPackage
  # Start at the root stash:
  my $last = '::';

  # Look in each successive sub-stash: [NB - the RE there just keeps
  # the :: tacked onto the end of the preceding package label: a
  # zero-width positive lookbehind assertion :-]
  for (split /(?<=::)/o, "$class\::") {
    return undef unless exists ${$last}{$_};
    $last = $_;
  }

  return 1;
}

# NB -- This is not (presently) a supported method for Class::Class --
# as a matter of fact, I consider it quite broken.  Why is it here?
# Since Class::Class has such intimate knowlege of your classes
# inheritance tree, it was easy for me to implement object changing
# into other objects, a feature I use in a seperate dynamic
# web-content system.  If I get request to support this, I may fix
# "polymorph" properly: until then, caveat emptor.  Double extra so
# for polyvolve!

# Turn into a different class:
sub polymorph ($;$@) {
  no strict qw(refs);

  my ($self, $class, @args) = @_;

  # Catch ::TopLevelModule:
  $class =~ s/^:://o;

  # Safe to call with no arguments:
  return $self unless $class;

  # We've already initialized (I think... ? --bko FIXME), so just
  # upcast ourselves:
  return bless $self, $class
    if ($self->isa ($class) or $self->__tried_polymorph ($class));

  # Save time and effort for next time through (note, we cache this
  # even for non-existent classes, just to save the work):
  $self->__tried_polymorph ($class, 1);

  (my $file = $class) =~ s,::,/,go;
  $file .= '.pm';

  # Limit the scope of the __DIE__ handler by using a block:
  {
    # Watch out that someone else may have installed a handler ahead
    # of us:
    local $SIG{__DIE__} = sub {
      die $_[0] unless $_[0] =~ /^Can't locate $file in \@INC/;
    };

    # Since use must have a bareword, carry out it's operations
    # explicitly rather than fall back on eval "use $class".  This
    # avoids the overhead of recompiling the string each time:
    eval { require $file; };

    # Try to setup the class anyway, in case it's defined not in
    # it's own separate file, but watch out -- it is just fine to
    # have no import method defined; need to be very careful not to
    # artificially create a stash for the package where none existed
    # before:
    $class->import
      if (package_exists ($class) and $class->can ('import'));
  }

  return $self unless package_exists ($class);

  bless $self, $class;

  return $self->renew (@args);
}

# This is like polymorph, except that I keep trying until it works,
# stripping off the last ::package name from the target class.  Again,
# I use this for a dynamic-content web system.  It could go there, but
# this functionality has nothing to do with web pages.  An example to
# illustrate: turn a Fred into a Human::Caveman::Flintstone::Barney,
# else a Human::Caveman::Flintstone, else a Human::Caveman, else a
# Human, else return the original Fred.

sub polyvolve ($;$@) {
  my ($self, $class, @args) = @_;

  do {
    $self = $self->polymorph ($class, @args);
  } while ($class ne ref $self and $class =~ s/::[^:]+$//o);

  return $self;
}

# Yes, it's true: I provide a default DESTROY for you.  See the
# documentation (below) for an explanation of this so-called feature.
sub DESTROY ($) {
  no strict qw(refs);

  my ($self) = @_;
  my $class = ref $self;

  # Give ourselves a chance to call cleanup code:
  my $glob = ${"$class\::"}{uninitialize};
  # This is for the object's package itself defining the method:
  $self->unitialize if (defined $glob and defined *{$glob}{CODE});

  for (keys %{"$class\::MEMBERS"}) {
    # Use internal knowlege.  This needs fixing for array
    # representation:
    $self->{$_} = undef if exists $self->{$_};
  }

  for my $class (@{"$class\::ISA"}) {
    # Explicity run super DESTROYS so we can handle multiple
    # inheritance:
    bless $self, $class;
    $self->DESTROY;
  }

  # Make us ourselves again so that we don't try to run more super's
  # DESTROYS:
  bless $self, $class;
}

### Methods below here are for implementation only -- need to look
### into using arrays instead of hashes:

sub add_method ($$$) {
  no strict qw(refs);

  my ($this, $name, $type) = @_;
  # Allowed to call as Fred::Barney->add_method (...):
  my $class = ref ($this) || $this;
  my $glob = ${"$class\::"}{$name};

  if ($type eq '$') {		# scalar
    *{"$class\::$name"} = sub ($;$) {
      (scalar @_ == 2) ? ($_[0]->{$name} = $_[1])
	: ($_[0]->{$name});
    };

  } elsif ($type eq '\$') {	# scalar reference
    *{"$class\::$name"} = sub ($;$) {
      (scalar @_ == 2) ? \($_[0]->{$name} = $_[1])
        : \($_[0]->{$name});
    };

  } elsif ($type eq '@') {	# array
    *{"$class\::$name"} = sub ($;$$) {
      (scalar @_ == 3) ? ($_[0]->{$name}[$_[1]] = $_[2])
	: (scalar @_ == 2) ? ($_[0]->{$name}[$_[1]])
	  : ($_[0]->{$name} ||= [ ]);
    };

  } elsif ($type eq '\@') {	# array reference
    *{"$class\::$name"} = sub ($;$$) {
      (scalar @_ == 3) ? \($_[0]->{$name}[$_[1]] = $_[2])
      : (scalar @_ == 2) ? \($_[0]->{$name}[$_[1]])
        : ($_[0]->{$name} ||= [ ]);
      };

  } elsif ($type eq '%') {	# hash
    *{"$class\::$name"} = sub ($;$$) {
      (scalar @_ == 3) ? ($_[0]->{$name}{$_[1]} = $_[2])
	: (scalar @_ == 2) ? ($_[0]->{$name}{$_[1]})
	  : ($_[0]->{$name} ||= { });
    };

  } elsif ($type eq '\%') {	# hash reference
    *{"$class\::$name"} = sub ($;$$) {
      (scalar @_ == 3) ? \($_[0]->{$name}{$_[1]} = $_[2])
      : (scalar @_ == 2) ? \($_[0]->{$name}{$_[1]})
        : ($_[0]->{$name} ||= { });
      };

  } elsif ($type eq '*') {	# glob
    *{"$class\::$name"} = sub ($;$) {
      (scalar @_ == 2) ? ($_[0]->{$name} = $_[1])
	: ($_[0]->{$name} ||= *{Symbol::gensym ( )});
    };

  } elsif ($type eq '\*') {	# glob reference
    *{"$class\::$name"} = sub ($;$) {
      (scalar @_ == 2) ? \($_[0]->{$name} = $_[1])
        : \($_[0]->{$name} ||= *{Symbol::gensym ( )});
    };

  } elsif ($type eq '&') {		# coderef
    *{"$class\::$name"} = sub ($;$) {
      # Surpress subroutine redefined and prototype mismatch:
      local $^W = 0;
      local $SIG{__WARN__} = sub {
	warn @_ unless $_[0] =~ /^Prototype mismatch:/o;
      };
      (scalar @_ == 2) ? (*{"$class\::$name"} = $_[1])
	: Carp::croak ("No coderef defined for '$name' yet");
    };

  } elsif ($type eq '\&') {		# coderef reference
    *{"$class\::$name"} = sub ($;$) {
      my ($self, $value) = @_; # need lexicals
      (scalar @_ == 2) ? ($self->{$name} = $value)
	# Need to do it this way so that we can arrange for $self to
	# be at the front of the argument list, as if by magic:
	: (sub { $self->{$name}->($self, @_); });
    };

  } elsif ($type =~ /^[^\\]/) {	# class (we hope)
    *{"$class\::$name"} = sub ($;$) {
      Carp::croak ("Not a class or subclass of '$_[1]'")
	if defined $_[1] and not UNIVERSAL::isa ($_[1], $type);

      # Be super careful -- because of closure tricks, need to use
      # $type->new syntax instead of new $type.  (Why?  See TC's
      # "indirect object syntax considered harmful" whitepaper.)
      (scalar @_ == 2) ? ($_[0]->{$name} = $_[1])
	: ($_[0]->{$name} ||= $type->new);
    };

  } else {			# class reference (we hope)
    $type =~ s/^\\//o;		# object class is name sans leader

    *{"$class\::$name"} = sub ($;$) {
      Carp::croak ("Not a class or subclass of '$_[1]'")
        if defined $_[1] and not UNIVERSAL::isa ($_[1], $type);

      # Be super careful -- because of closure tricks, need to use
      # $type->new syntax instead of new $type.  (Why?  See TC's
      # "indirect object syntax considered harmful" whitepaper.)
      (scalar @_ == 2) ? \($_[0]->{$name} = $_[1])
        : \($_[0]->{$name} ||= $type->new);
    };
  }

  return $this;
}

sub _make_methods ($) {
  no strict qw(refs);

  my ($self) = @_;

  # Build from most derived to least derived order:
  foreach my $class (Class::ISA::self_and_super_path (ref $self)) {
    # Try to avoid fooling around with a parent class which defines
    # MEMBERS but for different purposes:
    next unless UNIVERSAL::isa ($class, __PACKAGE__);

    # Check the cache so we don't do this twice:
    next if $Class::Class::BUILT_METHODS{$class};

    for my $key (keys %{"$class\::MEMBERS"}) {
      # Careful not to override user-defined access methods:
      if ($Class::Class::OVERRIDE_INHERITED) {
	# This is for the object's package itself defining the method:
	my $glob = ${"$class\::"}{$key};
	next if (defined $glob and defined *{$glob}{CODE});

      } else {
	# This is for inherited methods:
	next if $self->can ($key);
      }

      $class->add_method ($key, ${"$class\::MEMBERS"}{$key});
    }

    $Class::Class::BUILT_METHODS{$class} = 1;
  }

  # Lastly, wire in our DESTROY:
  my $class = ref $self;
  *{"$class\::DESTROY"} = \&DESTROY;

  return $self;
};

sub _process_args ($;@) {
  my $self = shift; # important not to use my ($self) = @_;
  my @args;

  while (ref $_[0]) {
    push @args, %{(shift)};
  }

  # Include yourself so you don't delete existing keys:
  %$self = (%$self, @args, @_);

  return $self;
}

sub _initialize_parents ($) {
  no strict qw(refs);

  my ($self) = @_;
  # To restore my class after initing my parents:
  my $class = ref $self;

  # Initing is idempotent:
  return $self if $self->__inited ($class);
  # I'm not inited until after all my parents init, but this breaks
  # downcasting via polymorph.  Think about this more.  --bko FIXME
  $self->__inited ($class, 1);

  for (@{"$class\::ISA"}) {
    next unless UNIVERSAL::isa ($_, __PACKAGE__);

    # While initializing, self should be the class of the parent so
    # that ISA lookup doesn't check unconstructed subclasses:
    $self = (bless $self, $_)->_initialize_parents;
  }

  # Check if we've been polymorphed into a subclass already:
  bless $self, $class unless UNIVERSAL::isa (ref $self, $class);

  $self = &{"$class\::initialize"} ($self)
    if defined &{"$class\::initialize"};

  return $self;
}

1;


__END__


=head1 NAME

Class::Class - Adds data members to Perl packages

=head1 SYNOPSIS

In module MyModule.pm:

  package MyModule;
  use Class::Class;
  @ISA = qw (Class::Class);

  %MEMBERS =
    (scalar_ => '$', # "scalar" is a keyword
     scalarref => '\$',
     array => '@',
     arrayref => '\@',
     hash => '%',
     hashref => '\%',
     glob => '*',
     globref => '\*',
     object => 'Some::Package',
     objectref => '\Some::Package');

  sub initialize ($) {
    my ($self) = @_;

    # object initialization goes here: DO NOT USE 'new'

    return $self;
  }

  sub deinitialize ($) {
    my ($self) = @_;

    # object cleanup (if any) goes here: DO NOT USE 'DESTROY'

    return $self;
  }

In other files which wish to use MyModule:

  use MyModule;

  my $mm = new MyModule;

  $mm->scalar_ (42); # set "scalar_" to 42
  $mm->scalar_ ( ); # get value of "scalar_"
  $mm->scalarref (1.1); # set "scalarref" to 1.1
  $mm->scalarref ( ); # get reference to value of "scalarref"

  $mm->array ( ); # get arrayref stored in "array"
  $mm->array (1); # get 2nd element of "array"
  $mm->array (1, 'fish'); # set 2nd element of "array" to 'fish'
  $mm->arrayref ( ); # get arrayref stored in "arrayref"
  $mm->arrayref (1); # get reference to 2nd element of "arrayref"
  $mm->arrayref (1, 'fish'); # set 2nd element of "arrayref" to 'fish'

  $mm->hash ( ); # get hashref stored in "hash"
  $mm->hash ('bob'); # get 'bob' element of "hash"
  $mm->hash ('bob', 'one'); # set 'bob' element of "hash" to 'one'
  $mm->hashref ( ); # get hashref stored in "hashref"
  $mm->hashref ('bob'); # get reference to 'bob' element of "hashref"
  $mm->hashref ('bob', 'one'); # set 'bob' element of "hashref" to 'one'

  open G, '<blah.txt';
  $mm->glob (*G); # set "glob" to *G
  $mm->glob ( ); # get value of "glob"
  use Symbol;
  $mm->globref (gensym); # set "globref" to anonymous symbol
  $mm->globref ( ); # get reference to value of "globref"

  $mm->object ( ); # get object in "object"
  $mm->object->method; # invoke method on object in "object"
  $mm->objectref ( ); # get reference to object in "objectref"

=head1 DESCRIPTION

B<Class::Class> implements inheritable data methods for your packages
with the same rules of inheritance as your other methods by generating
creating accessor methods for your data the first time you make an
instance of your package.

Why reinvent the wheel, you say?  I got tired of the way
B<Class::Struct> worked, since the methods weren't inheritable the way
I expected (no initialization of parent members before child members,
for example), it was invoked programatically rather than
declaratively, and I wanted to learn more about globs and the like.
Plus I have a big head.  :-)

=head2 Using Class::Class Modules

Using B<Class::Class> modules is very simple.  Just inherit from them
as normal, but don't bother with writing a C<new> method --
B<Class::Class> provides one for you that arranges for superclasses to
be initialized before subclasses.  It also takes multiple inheritance
into account (correctly, I hope).

To initialize your package, instead of C<sub new>, write a C<sub
initialize> which takes an instance of your package as its only
argument, and returns an instance:

  sub initialize ($) {
    my ($self) = @_;

    # Do something clever here with your object...

    return $self;
  }

There is no requirement you return the same instance that was handed
to you.  The methods C<polymorph> and C<polyvolve> are provided for
this very purpose, to help with "virtual constructors".

=head2 Writing Class::Class Modules

Writing B<Class::Class> modules is straight-forward.

=head2 Polymorph and Polyvolve

=over

=item C<polymorph>

=item C<polyvolve>

=back

=head1 EXAMPLES

=head2 Using Class::Class Modules

=over

=item 1. Simple use:

=back

=head2 Writing Class::Class Modules

=over

=item 1. Setting a package global:

=back

=head1 SEE ALSO

L<Class::ISA>

B<Class::ISA> creates an inverted inheritance tree, permitting easy
traversal of a packages entire inheritance.

=head1 DIAGNOSTICS

The following are the diagnostics generated by B<Class::Class>.  Items
marked "(W)" are non-fatal (invoke C<Carp::carp>); those marked "(F)"
are fatal (invoke C<Carp::croak>).

=over

=item Not a class or subclass of '%s'

(F) The caller tried to assign to an object data member something
which isn't an instance of that object's class, or which isn't an
instance of a derived class.

=item No coderef defined for '%s' yet

(F) The caller tried to use a code reference without first providing
assigning a coderef to the member.

=back

=head1 BUGS AND CAVEATS

Presently, B<Class::Class> uses hashes for data members; array are
demonstrably better for several reasons (see XXX -- I<TPJ>) if you
don't need direct access to data members by name.  And even if you do,
B<fields> shows a good way to do that with recent versions of Perl.

=head1 AUTHORS

B. K. Oxley (binkley) at Home E<lt>binkley@bigfoot.comE<gt>

=head1 COPYRIGHT

  Copyright 1999, B. K. Oxley (binkley).

This library is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.

=cut
