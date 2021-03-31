use strict; #-*-cperl,hi-lock,auto-fill-*-
use warnings;

use lib qw( ../../../../lib );

=head1 NAME

Algorithm::Evolutionary::Individual::Base - Base class for chromosomes that knows how to build them, and has some helper methods.
                 
=head1 SYNOPSIS

  use  Algorithm::Evolutionary::Individual::Base;

  my $indi = Algorithm::Evolutionary::Individual::Base->fromParam( $param_hashref ); #From parametric description

  $binIndi2->Fitness( 3.5 ); #Sets or gets fitness
  print $binIndi2->Fitness();

  my $emptyIndi = new Algorithm::Evolutionary::Individual::Base;

=head1 DESCRIPTION

Base class for individuals, that is, "chromosomes" in evolutionary
computation algorithms. However, chromosomes needn't be bitstrings, so
the name is a bit misleading. This is, however, an "empty" base class,
that acts as a boilerplate for deriving others. 

=cut

package Algorithm::Evolutionary::Individual::Base;

use YAML qw(Dump Load LoadFile);
use Carp;

our $VERSION = '3.3';

use constant MY_OPERATORS => qw(None);

=head1 METHODS 


=head2 AUTOLOAD

Creates methods for instance variables automatically

=cut

sub AUTOLOAD {
    my $self = shift;
    my $attr = our $AUTOLOAD;
    $attr =~ s/.*:://;
    return unless $attr =~ /[^A-Z]/;  # skip DESTROY and all-cap methods
    my $instance_variable = "_$attr";
    $self->{$instance_variable} = shift if @_;
    return $self->{$instance_variable};
}

=head2 new( $options )

Creates a new Base individual of the required class, with a fitness, and sets fitnes to undef.
Takes as params a hash to the options of the individual, that will be passed
on to the object of the class when it iss initialized.

=cut

sub new {
  my $class = shift;
  if ( $class !~ /Algorithm::Evolutionary/ ) {
      $class = "Algorithm::Evolutionary::Individual::$class";
  }
  my $options = shift;
  my $self = { _fitness => undef }; # Avoid error
  bless $self, $class; # And bless it

  #If the class is not loaded, we load it. 
  if ( !$INC{"$class\.pm"} ) {
      eval "require $class" || croak "Can't find $class Module";
  }
  if ( $options ) {
      $self->set( $options );
  }

  return $self;
}

=head2 create( $ref_to_hash )

Creates a new individual, but uses a different interface: takes a
ref-to-hash, with named parameters, which gives it a common interface
to all the hierarchy. The main difference with respect to new is that
after creation, it is initialized with random values.

=cut

sub create {
  my $class = shift; 
  my $ref = shift ||  croak "Can't find the parameters hash";
  my $self = Algorithm::Evolutionary::Individual::Base::new( $class, $ref );
  $self->randomize();
  return $self;
}

=head2 set( $ref_to_hash )

Sets values of an individual; takes a hash as input. Keys are prepended an
underscore and turn into instance variables

=cut

sub set {
  my $self = shift; 
  my $hash = shift || croak "No params here";
  for ( keys %{$hash} ) {
    $self->{"_$_"} = $hash->{$_};
  }
}

=head2 as_yaml()

Prints it as YAML. 

=cut

sub as_yaml {
  my $self = shift;
  return Dump($self);
}

=head2 as_string()

Prints it as a string in the most meaningful representation possible

=cut

sub as_string {
  croak "This function is not defined at this level, you should override it in a subclass\n";
}

=head2 as_string_with_fitness( [$separator] )

Prints it as a string followed by fitness. Separator by default is C<;>

=cut

sub as_string_with_fitness {
  my $self = shift;
  my $separator = shift || "; ";
  return $self->as_string().$separator.$self->Fitness();
}

=head2 Atom( $index [, $value )

Sets or gets the value of an atom; each individual is divided in atoms, which
can be accessed sequentially. If that does not apply, Atom can simply return the
whole individual

=cut

sub Atom {
  croak "This function is not defined at this level, you should override it in a subclass\n";
}

=head2 Fitness( [$value] )

Sets or gets fitness

=cut

sub Fitness {
  my $self = shift;
  if ( defined $_[0] ) {
	$self->{_fitness} = shift;
  }
  return $self->{_fitness};
}

=head2 my_operators()

Operators that can act on this data structure. Returns an array with the names of the known operators

=cut

sub my_operators {
    my $self = shift;
    return $self->MY_OPERATORS;
}

=head2 evaluate( $fitness )

Evaluates using the $fitness thingy given. Can be a L<Algorithm::Evolutionary::Fitness::Base|Fitness> object or a ref-to-sub

=cut

sub evaluate {
  my $self = shift;
  my $fitness_func = shift || croak "Need a fitness function";
  if ( ref $fitness_func eq 'CODE' ) {
      return $self->Fitness( $fitness_func->($self) );
  } elsif (  ( ref $fitness_func ) =~ 'Fitness' ) {
      return $self->Fitness( $fitness_func->apply($self) );
  } else {
      croak "$fitness_func can't be used to evaluate";
  }

}

=head2 Chrom()

Sets or gets the chromosome itself, that is, the data
structure evolved. Since each derived class has its own
data structure, and its own name, it is left to them to return 
it

=cut

sub Chrom {
  my $self = shift;
  croak "To be implemented in derived classes!";
}

=head2 size()

OK, OK, this is utter inconsistence, but I'll re-consistence it
    eventually. Returns a meaningful size; but should be reimplemented
    by siblings

=cut

sub size() {
    croak "To be implemented in derived classes!";
}

=head1 Known subclasses

There are others, but I'm not so sure they work.

=over 4

=item * 

L<Algorithm::Evolutionary::Individual::Vector>

=item * 

L<Algorithm::Evolutionary::Individual::String>

=item * 

L<Algorithm::Evolutionary::Individual::Tree>

=item * 

L<Algorithm::Evolutionary::Individual::Bit_Vector>

=back

=head1 Copyright
  
  This file is released under the GPL. See the LICENSE file included in this distribution,
  or go to http://www.fsf.org/licenses/gpl.txt


=cut

"The plain truth";

