package Class::Interface;

=pod

=head1 NAME

Class::Interface - A class for implementing/extending interfaces/abstracts in Perl.

=head1 SYNOPSIS

=head2 Declaring an interface

  package Bouncable;

  use Class::Interface;
  &interface;   # this actually declares the interface

  sub bounce;
  sub getBounceBack;

  1;

This creates an interface (a contract between classes if you like)
that specifies that each class implementing the Bouncable
interface must have an implementation of the routines bounce
and getBounceBack.

=head2 Declaring an implementing class

  package Ball;

  use Class::Interface;
  &implements( 'Bouncable' );

  sub bounce {
    my $self = shift;
    print "The ball is bouncing @ ".$self->getBounceBack." strength"
  }

  sub getBounceBack {
    return 10;
  }

  1;

=head2 Declaring an abstract

  package AbstractInterestCalculator;

  use Class::Interface;
  &abstract;   # this actually declares this class to be abstract;

  use Class::AccessorMaker {
    interest => 5.1,
    maxInterestValue => 0,
  }

  # a hook for doing calculations
  sub calculate {
    my ( $self, $value ) = @_;

    $self->prepare();
    $value += $self->getInterestValue( $value );

    return $value;
  }

  sub prepare;          # prepare calculations
  sub getInterstValue;  # get the interest value

  1;

=head2 Extending from an abstract class

  package LowInterestCalculator;

  use Class::Interface;
  &extends( 'AbstractInterestCalculator' );

  sub prepare {
    my ( $self ) = @_;
    $self->interest(1.3);

    # we don't give interest if the value of the account is or
    # exceeds $10.000
    $self->maxInterestValue(10000)
  }

  sub getInterstValue {
    my ( $self, $value ) = @_

    if ( $self->maxInterestValue &&
         $value >= $self->maxInterestValue ) {
      return 0;
    }

    $value *= $self->interest;

    return $value;
  }

=head1 DESCRIPTION

Performs some underwater perl-magic to ensure interfaces are
interfaces and classes that implement the interface actually do so.

=head1 INTERFACE RULES

=over 4

=item * An interface must use the Class::Interface module.

=item * An interface must call the 'interface' method.

=item * An interface must declare at least one routine

=item * Routines may not have an implementation

=back

=head1 ABSTRACT RULES

=over 4

=item * An abstract must use the Class::Interface module.

=item * An abstract must call the 'abstract' method.

=item * An abstract must declare at least one abstract routine.

=back

=head1 ROUTINE RULES

=over 4

=item * Routines must be declared as one of:

=over 4

=item - sub routine;

=item - sub routine {}

=back

B<NOTE>: When using curly braces in routine declarations they must stay
on the same line. The amount of whitespace between them and/or the
routine name is free of ruling.

=back

=head1 ANNOTATIONS

It helps to think of these methods as Java style annotations. But
instead of calling them with @interface you use &interface.

=cut

use strict;
no strict 'refs';

use base qw(Exporter);
@Class::Interface::EXPORT = qw(implements interface extends abstract);

use Carp;

# some default class vars
$Class::Interface::VERSION = "1.01";

# some class vars for changing behaviour
$Class::Interface::AUTO_CONSTRUCTOR = 0;
$Class::Interface::CONFESS = 0;

# define a contract
sub error(*);

=pod

=head2 &interface()

Turns the calling class into an interface.

=cut
sub interface() {
  my $caller = caller();

  return if !$caller || $caller eq "main";

  # interfaces should be usable.
  eval "use $caller";
  error $@ if $@;

  my @subs = inspectInterface($caller);

  error "Interface $caller does not provide any methods" if $#subs < 0;

  # first prevent usage of interfaces (but allow it from me).
  *{ $caller . "::import" } = sub {
    my $caller = caller();

    if ( $caller ne "Class::Interface" and $caller ne "main" ) {
      error "$caller is an interface. It can't be used";
    }
  };

  # tell any interface users this is an interface and return the
  # expected routines.
  *{ $caller . "::__get_interface_methods__" } = sub {
    return @subs;
  };
}

=pod

=head2 &abstract()

Turns the calling class into an abstract.

=cut
sub abstract() {
  my $caller = caller();

  return if !$caller || $caller eq "main";

  # interfaces should be usable.
  eval "use $caller";
  error $@ if $@;

  my @subs = inspectInterface( $caller, 1 );

  # abstract classes must have abstract methods
  error "Abstract interface $caller does not provide any methods" if $#subs < 0;

  # tell any abstract users this is an abstract and return the
  # expected routines.
  *{ $caller . "::__get_abstract_methods__" } = sub {
    return @subs;
  };

  # overwrite the abstract routines and make them die on invocation
  foreach my $sub (@subs) {
    *{ $caller . "::" . $sub } = sub {
      die("You are trying to invoke the abstract method $sub from $caller");
    };
  }
}

=pod

=head2 &implements()

Loads the given interfaces and checks the calling class for presence
of the wanted routines.

If all goes well pushes the name of the interface to the ISA array of
the class.

=cut
sub implements(@) {
  my $caller = caller;

  my %missing;
  foreach my $implements (@_) {
    eval "use $implements;";
    error
      "$caller tries to implement non existing interface $implements -- $@"
      if $@;

    unless ( defined ( &{ $implements . "::__get_interface_methods__" } ) ) {
      error "$caller tries to implement non-interface $implements"
    }

    # find the subs from the interface
    foreach my $sub ( &{ $implements . "::__get_interface_methods__" } ) {
      unless ( UNIVERSAL::can( $caller, $sub ) ) {
        $missing{$implements} = [] unless exists $missing{$implements};
        push @{ $missing{$implements} }, $sub;
      }
    }
  }

  if ( keys %missing ) {
    my $dieMessage = "";
    foreach my $interface ( keys %missing ) {
      foreach my $sub ( @{ $missing{$interface} } ) {
        $dieMessage .= ",\n" if $dieMessage;
        $dieMessage .= "$caller fails to implement $sub from $interface";
      }
    }

    error $dieMessage;
  }

  # make sure the import is not found through inheritance.
  unless ( defined &{ $caller . "::import" } ) {
    *{ $caller . "::import" } = sub {

      # don't cascade up to the interface.
      }
  }

  makeMagicConstructor($caller);

  push @{ $caller . "::ISA" }, @_;
}

=pod

=head2 &extends()

Loads the given abstract class and checks the calling class for presence
of the abstract routines.

If all goes well pushes the name of the abstract class to the ISA
array of the class.

=cut
sub extends(*) {
  my $caller = caller();

  my %missing;
  foreach my $extends (@_) {
    eval "use $extends;";
    error
      "$caller tries to implement non existing abstract class $extends -- $@"
      if $@;

    unless ( defined ( &{ $extends . "::__get_abstract_methods__" } ) ) {
      error "$caller tries to implement non-abstract $extends"
    }


    # find the subs from the interface
    foreach my $sub ( &{ $extends . "::__get_abstract_methods__" } ) {
      unless ( UNIVERSAL::can( $caller, $sub ) ) {
        $missing{$extends} = [] unless exists $missing{$extends};
        push @{ $missing{$extends} }, $sub;
      }
    }
  }

  if ( keys %missing ) {
    my $dieMessage = "";
    foreach my $abstract ( keys %missing ) {
      foreach my $sub ( @{ $missing{$abstract} } ) {
        $dieMessage .= ",\n" if $dieMessage;
        $dieMessage .=
          "$caller fails to implement $sub from abstract class $abstract";
      }
    }

    error $dieMessage;
  }

  makeMagicConstructor($caller);

  push @{ $caller . "::ISA" }, @_;
}

# private methods
#

# perform interface inspections
sub inspectInterface {
  my $interface  = shift;
  my $asAbstract = shift || 0;

  no warnings 'uninitialized';

  ( my $keyName = $interface ) =~ s/\:\:/\//g;
  $keyName .= ".pm";

  my $file = $INC{$keyName};
  open( local *IN, "<$file" );

  my @subs = ();
  my $usesInterfaces;
  my $callsInterface;
  while ( chomp( my $line = <IN> ) ) {
    # leave if the source file says so.
    last if $line eq "__END__";

    $usesInterfaces = 1 if $line =~ /^use Class::Interface/i;
    $callsInterface = 1 if $line =~ /^\&?interface\(?\)?/;
    $callsInterface = 1 if ( $asAbstract && $line =~ /^\&?abstract\(?\)?/ );

    if ( $line =~ /^sub/ ) {
      # strip of any comments
      unless ( ( my $commentChar = index($line, "#") ) < 0 ) {
        $line = substr($line, 0, $commentChar);
      }

      # trim trailing whitespace
      $line =~ s/\ +$//;

      my ($sub) = $line =~ /sub ([^\s]+)/;
      my $lineEnd = substr( $line, length($line) - 1 );

      if ( $lineEnd ne ";" and $lineEnd ne "}" ) {
        # if this is an abstract, implementations are OK
        next if $asAbstract;

        # ai. The sub has an implementation
        error
          "$interface is not a valid interface. $sub has an implementation";
      }

      # strip any funny chars from the routine name
      $sub =~ tr/\;\{\}//d;

      push @subs, $sub;
    }
  }

  if ( !$usesInterfaces ) {
    error("Interface $interface does not use the interface module.");
  }
  if ( !$callsInterface ) {
    error( ( $asAbstract ? "Abstract" : "Interface" ) . " $interface does not load the interface magic.");
  }

  return @subs;
}

# add a default constructor to the caller
sub makeMagicConstructor {
  return if !$Class::Interface::AUTO_CONSTRUCTOR;

  my $caller = shift;

  unless ( defined &{ $caller."::new" } ) {
    *{ $caller."::new"} = sub {
      my $class = ref($_[0]) || $_[0]; shift;
      my $self  = bless({}, $class);

      my %value = @_;
      foreach my $field ( keys %value ) {
        $self->$field( $value{$field} ) if $self->can( $field )
      }

      return $self
    };
  }
}

# die
sub error(*) {
  my $strings = join("", @_);

  if ( $Class::Interface::CONFESS == 1 ) {
    confess $strings;
  } else {
    croak $strings;
  }
}

=pod

=head1 MAGIC CONSTRUCTORS

To add even more Java behaviour to perl...

Extending or implementing classes that do not already have a constructor
can get one injected automaticly.

The code for such a routine is as follows:

  sub new {
    my $class = ref($_[0]) || $_[0]; shift;
    my $self  = bless({}, $class);

    my %value = @_;
    foreach my $field ( keys %value ) {
      $self->$field( $value{$field} ) if $self->can( $field )
    }

    return $self
  }

In english: An object with a hashref is setup. The constructor can be called
like this:

  my $object = Object->new( attribute1 => "value",
                            attribute2 => [ qw(a b c)],
                           );

if attributeX exists as an accessor routine in the object it will be set by
calling the actual routine.

I would strongly advice using something like Class::AccessorMaker though...

If you want magic constructors; set $Class::Interface::AUTO_CONSTRUCTOR to 1

=head1 ERROR HANDLING

If anything fails uses Carp::croak. Once you set $Class::Interface::CONFESS
to 1 it will spill the guts using confess.

=head1 FAQ

=over 4

=item Q: Will it see the routines I create dynamicly?

Using things like Class::AccessorMaker accessors are dynamcly created.
Class contracts can specify some getters to be present. Does Class::Interface
recognize them?

=item A: Yes.

The checks implements() and extends() perform happen well after use time. So
using Class::AccessorMaker is save. It performs it magic in use time. Any class
that will dynamicly create methods in use time should be usable with
Class::Interface.

=back

=head1 CAVEATS, BUGS, ETC.

=head2 Order of annotations

If your class extends an abstract which provides methods for an interface you
are implementing you must first call the &extends annotation.

So:

  &extends('Runner');
  &implements('Runnable');

And not:

  &implements('Runnable');
  &extends('Runner');


=head1 SEE ALSO

L<Carp>, L<UNIVERSAL>

=head1 AUTHOR

Hartog C. de Mik

=head1 COPYRIGHT

(cc-sa) 2008, Hartog C. de Mik

cc-sa : L<http://creativecommons.org/licenses/by-sa/3.0/>

=cut

1;


