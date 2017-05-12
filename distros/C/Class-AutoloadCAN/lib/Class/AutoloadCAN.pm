package Class::AutoloadCAN;
$VERSION = 0.03;
use strict;
no strict 'refs';
use vars qw($AUTOLOAD);

my %base_install;

sub import {
  shift;  # Get rid of class
  @_ = scalar caller unless @_;
  for (@_) {
    # For giggles and grins, archaic compatibility.  This should work with
    # Perl 5.003.  (Untested.)
    my $class = $_;
    $base_install{$class}++;
    *{"$class\::AUTOLOAD"} = sub {
      my $method = _can($AUTOLOAD, @_);
      if ($method) {
        return &$method;
      }
      my ($package, $file, $line) = caller;
      my $where = qq(package "$class" at $file line $line.);
      if ($AUTOLOAD =~ /(.*)::([^:]+)/) {
        my $package = $1;
        my $method = $2;
	die qq(Can't locate object method "$method" via package "$package" at $where\n);
      }
      else {
        die qq(AUTOLOAD saw no \$AUTOLOAD after $where\n);
      }
    };
  }
}

# The arguments have been rearranged here.  That is for the promise I made
# that you can do anything with this strategy that you can with AUTOLOAD.
# I even support the case where you've AUTOLOADed calling an autoloaded
# function directly without arguments.
sub _can {
  my ($method, @args) = @_;
  my $self = $args[0];

  my %checked;
  # Need to reset these on the off chance that people are dynamically
  # changing @ISA.  Right behaviour over speed...
  reset_installed();

  my $base_class = ref($self) || $self;
  $method =~ s/'/::/g;
  if ($method =~ /^(.*)::([^:]+)/) {
    $base_class = $1;
    $method = $2;
  }
  my %seen;
  my @classes = ($base_class, 'UNIVERSAL');
  while (@classes) {
    my $class = shift @classes;
    next if $seen{$class}++;


    if (my $CAN = *{"$class\::CAN"}{CODE}) {
      # Need to figure out whether I pay attention to CAN.
      # I probably do - I'm only called if you inherit from
      # someone who does, but I might have gone past where I
      # was installed to, in which case I can prune the
      # inheritance tree slightly.
      next unless installed($class);
      my $sub = $CAN->($base_class, $method, @args);
      return $sub if $sub;
    }

    unshift @classes, @{"$class\::ISA"};

  }
};

local $^W;
my $original_can = \&UNIVERSAL::can;
*UNIVERSAL::can = sub {
  my $sub = $original_can->(@_[0,1]);
  return $sub if $sub;
  _can(@_[1,0,2..$#_]);
};

# These hashes track which classes I'm paying attention to CAN in.
my %installed;
my %not_installed;
my %testing_install;
sub reset_installed {
  %installed = %base_install;
  %not_installed = %testing_install = ();
}

# This function takes a class and sets %installed or %not_installed
# appropriately for that class;
sub installed {
  my $base_class = shift;
  return 1 if $installed{$base_class};
  return if $not_installed{$base_class};
  return if $testing_install{$base_class}++; # Avoid infinite recursion.
  my @classes = (@{"$base_class\::ISA"}, 'UNIVERSAL');
  foreach (@classes) {
    # For giggles and grins, archaic compatibility.  This should work with
    # Perl 5.003.  (Untested.)
    my $class = $_;
    return $installed{$base_class} = 1
      if installed($class);
  }
  $not_installed{$base_class} = 1;
  return;
}

1;

__END__

=head1 NAME

Class::AutoloadCAN - Make AUTOLOAD, can and inheritance cooperate.

=head1 SYNOPSIS

  package Foo;
  use Class::AutoloadCAN;

  sub CAN {
    my ($starting_class, $method, $self, @arguments) = @_;
    return sub {
      my $self = shift;
      print join ", ", $method, @_;
      print "\n";
    };
  }

  # And this prints the famous greeting.
  Foo->hello("world");

=head1 DESCRIPTION

This module solves a fundamental conflict between AUTOLOAD, can and
inheritance.  The problem is that while you can implement anything in
AUTOLOAD, UNIVERSAL::can is not aware that it is there.  Attempting to
modify UNIVERSAL::can to document those methods is very hard.  And if a
parent class uses AUTOLOAD then subclasses have to do a lot of work to
make their AUTOLOADs cooperate with the parent one.  It is harder still
if 2 parent classes in a multiple inheritance tree wish to cooperate
with each other.  Few try to do this, which may be good since those who
try usually get it wrong.  See http://www.perlmonks.org/?node_id=342804
for a fuller discussion.

With this module instead of writing AUTOLOADs, you write CANs.  Based on
what they return, Class::AutoloadCAN will decide whether you handle the
call or it needs to search higher up the inheritance chain.

Here are the methods and functions that matter for the operation of
this module.

=over 4

=item C<AUTOLOAD>

An AUTOLOAD will be installed in every package that uses this module.
You can choose to have it installed in other packages.  If you write
your own AUTOLOADs, you can easily break this module.  So don't do
that.  Write CANs instead.

=item C<can>

UNIVERSAL::can will be modified to be aware of the functions provided
dynamically through this module.  You are free to override can in any
subclass and this module will not interfere.  I have no idea why you
would want to, though.

=item

=item C<CAN>

If there is a method named CAN in a class that inherits from one that
Universal::AutoloadCAN was installed to, it may be called in deciding
how a method is implemented.  It will be passed the class that the
method search started in, the method name, the object called, and the
arguments to the function.  It is expected to do nothing but return a
subroutine reference if it implements that method on that object, or
undef otherwise.

If that subroutine is actually called, it will be passed all of the
usual arguments that a method call gets, and the AUTOLOAD that found
it will erase itself from the callstack.

=item C<Class::AutoloadCAN::import>

If the import method for Class::AutoloadCAN is called with no
arguments it installs an AUTOLOAD in the calling class.  If it is
called with arguments, it installs an AUTOLOAD in those classes as
well.  Use with caution: this is a convenience feature that is not
expected to be used very often.

=back

=head1 SUGGESTION

Many people use AUTOLOAD to implement large numbers of fixed and
straightforward methods.  Such as accessors.  If you are doing this,
then I suggest implementing them by typeglobbing closures instead of
by using AUTOLOAD or this module.  Here is a simple example:

  package Parent;
  use strict;

  sub make_accessors {
    my ($class, @attributes) = @_;
    foreach my $attribute (@attributes) {
      no strict 'refs';
      *{"$class\::$attribute"} = sub {
        my $self = shift;
        if (@_) {
          $self->{$attribute} = shift;
        }
        return $self->{$attribute};
      };
    }
  }
  
  
  package Child;
  our @ISA = 'Parent';
  __PACKAGE__->make_accessors(qw(this that the other));

This approach is simpler, often faster, and avoids some of the
problems that AUTOLOAD has, like mistaking function calls as
method calls.

=head1 BUGS AND LIMITATIONS

There are many other issues with AUTOLOAD that this module does
not address.  Primary among them is the fact that if you call a
function that does not exist in a package that inherits from one
with an AUTOLOAD, Perl will do a method search for that AUTOLOAD.
This is why this module does not install AUTOLOAD in UNIVERSAL by
default, and it is strongly suggested that you not do so either.

Also many people like to lazily install AUTOLOADed methods in the
local package so that they will be found more quickly in the
future.  This module won't do that for you, but you can easily do
that from within CAN.  The reason that this module doesn't do that
is that some useful CANs may decide whether to support a method on
an object by object basis.

=head1 ACKNOWLEDGEMENTS

My thanks to various people on Perlmonks for conversations that
clarified what problems AUTOLOAD raises, and convinced me that it
would be good to have a solution to them.

=head1 AUTHOR AND COPYRIGHT

Ben Tilly (btilly@gmail.com).

Copyright 2005.  This may be copied, modified and distributed on
the same terms as Perl.
