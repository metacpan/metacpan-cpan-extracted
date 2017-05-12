use strict; #-*-cperl-*-
use warnings;

=head1 NAME

Algorithm::Evolutionary::Op::Base - Base class for Algorithm::Evolutionary operators,

=head1 SYNOPSIS

    my $op = new Algorithm::Evolutionary::Op::Base; #Creates empty op, with rate

    print $op->rate();  #application rate; relative number of times it must be applied
    print "Yes" if $op->check( 'Algorithm::Evolutionary::Individual::Bit_Vector' ); #Prints Yes, it can be applied to Bit_Vector individual
    print $op->arity(); #Prints 1, number of operands it can be applied to

=head1 DESCRIPTION

Base class for operators applied to Individuals and Populations and
all the rest.  An operator is any object with the "apply" method,
which does things to individuals or populations. It is intendedly
quite general so that any genetic or population operator can fit in. 

=head1 METHODS

=cut

package Algorithm::Evolutionary::Op::Base;

use lib qw( ../.. ../../.. );

use Memoize;
memoize('arity'); #To speed up this frequent computation

use B::Deparse; #For serializing code
use Algorithm::Evolutionary::Utils qw(parse_xml);

use Carp;
our ($VERSION) = ( '$Revision: 3.3 $ ' =~ / (\d+\.\d+)/ ) ;
our %parameters;

=head2 AUTOLOAD

Automatically define accesors for instance variables. You should
probably not worry about this unless you are going to subclass.

=cut

sub AUTOLOAD {
  my $self = shift;
  our $AUTOLOAD;
  my ($method) = ($AUTOLOAD =~ /::(\w+)/);
  my $instanceVar = "_".lcfirst($method);
  if (defined ($self->{$instanceVar})) {
    if ( @_ ) {
	  $self->{$instanceVar} = shift;
    } else {
	  return $self->{$instanceVar};
    }
  }    

}

=head2 new( [$priority] [,$options_hash] )

Takes a hash with specific parameters for each subclass, creates the 
object, and leaves subclass-specific assignments to subclasses

=cut

sub new {
  my $class = shift;
  carp "Should be called from subclasses" if ( $class eq  __PACKAGE__ );
  my $rate = shift || 1;
  my $hash = shift; #No carp here, some operators do not need specific stuff
  my $self = { rate => $rate,
	       _arity => eval( "\$"."$class"."::ARITY" )}; # Create a reference
  bless $self, $class; # And bless it
  $self->set( $hash ) if $hash ;
  return $self;
}

=head2 create( [@operator_parameters] )

Creates an operator via its default parameters. Probably obsolete

=cut

sub create {
  my $class = shift;
  my $self;
  for my $p ( keys %parameters ) {
    $self->{"_$p"} = shift || $parameters{$p}; # Default
  }
  bless $self, $class;
  return $self;
}

=head2 fromXML()

Takes a definition in the shape <op></op> and turns it into an object, 
if it knows how to do it. The definition must have been processed using XML::Simple.

It parses the common part of the operator, and leaves specific parameters for the
subclass via the "set" method.

=cut

sub fromXML {
  my $class = shift;
  my $xml = shift || croak "XML fragment missing ";
  my $fragment; # Inner part of the XML
  if ( ref $xml eq ''  ) { #We are receiving a string, parse it
    $xml = parse_xml( $xml );
    croak "Incorrect XML fragment" if !$xml->{'op'}; #
    $fragment = $xml->{'op'};
  } else {
    $fragment = $xml;
  }
  my $rate = shift;
  if ( !defined $rate && $fragment->{'-rate'} ) {
    $rate = $fragment->{'-rate'};
  }
  my $self = { rate => $rate }; # Create a reference

  if ( $class eq  __PACKAGE__ ) { #Deduct class from the XML
    $class = $fragment->{'-name'} || shift || croak "Class name missing";
  }
  
  $class = "Algorithm::Evolutionary::Op::$class" if $class !~ /Algorithm::Evolutionary/;
  bless $self, $class; # And bless it
  
  my (%params, %code_fragments, %ops);
  
  for ( @{ (ref $fragment->{'param'} eq 'ARRAY')?
	     $fragment->{'param'}:
	       [ $fragment->{'param'}] } ) {
    if  ( defined $_->{'-value'} ) {
      $params{$_->{'-name'}} = $_->{'-value'};
    } elsif ( $_->{'param'} ) {
      my %params_hash;
      for my $p ( @{ (ref $_->{'param'} eq 'ARRAY')?
		       $_->{'param'}:
			 [ $_->{'param'}] } ) {
	$params_hash{ $p->{'-name'}} = $p->{'-value'};
      }
      $params{$_->{'-name'}} = \%params_hash;
    }
  }
  
  if ($fragment->{'code'} ) {
    $code_fragments{$fragment->{'code'}->{'-type'}} = $fragment->{'code'}->{'src'};
  }    
       
  for ( @{$fragment->{'op'}} ) { 
    $ops{$_->{'-name'}} = [$_->{'-rate'}, $_];
  }

  #If the class is not loaded, we load it. The 
  eval "require $class" || croak "Can't find $class Module";

  #Let the class configure itself
  $self->set( \%params, \%code_fragments, \%ops );
  return $self;
}


=head2 asXML( [$id] )

Prints as XML, following the EvoSpec 0.2 XML specification. Should be
called from derived classes, not by itself. Provides a default
implementation of XML serialization, with a void tag that includes the
name of the operator and the rate (all operators have a default
rate). For instance, a C<foo> operator would be serialized as C< E<lt>op
name='foo' rate='1' E<gt> >.

If there is not anything special, this takes also care of the instance
variables different from C<rate>: they are inserted as C<param> within
the XML file. In this case, C<param>s are void tags; if you want
anything more fancy, you will have to override this method. An
optional ID can be used.

=cut

sub asXML {
  my $self = shift;
  my ($opName) = ( ( ref $self) =~ /::(\w+)$/ );
  my $name = shift; #instance variable it corresponds to
  my $str =  "<op name='$opName' ";
  $str .= "id ='$name' " if $name;
  if ( $self->{rate} ) { # "Rated" ops, such as genetic ops
	$str .= " rate='".$self->{rate}."'";
  }
  if (keys %$self == 1 ) {
    $str .= " />" ; #Close void tag, only the "rate" param
  } else {
    $str .= " >";
    for ( keys %$self ) {
      next if !$self->{$_};
      if (!/\brate\b/ ) {
	my ($paramName) = /_(\w+)/;
	if ( ! ref $self->{$_}  ) {
	  $str .= "\n\t<param name='$paramName' value='$self->{$_}' />";
	} elsif ( ref $self->{$_} eq 'ARRAY' ) {
	  for my $i ( @{$self->{$_}} ) {
	    $str .= $i->asXML()."\n";
	  }
	} elsif ( ref $self->{$_} eq 'CODE' ) {
	  my $deparse = B::Deparse->new;
	  $str .="<code type='eval' language='perl'>\n<src><![CDATA[".$deparse->coderef2text($self->{$_})."]]>\n </src>\n</code>";
	} elsif ( (ref $self->{$_} ) =~ 'Algorithm::Evolutionary' ) { #Composite object, I guess...
	  $str .= $self->{$_}->asXML( $_ );
	}
      }
    }
    $str .= "\n</op>";
  }
  return $str;
}

=head2 rate( [$rate] )

Gets or sets the rate of application of the operator

=cut

sub rate {
  my $self = shift ;
  $self->{rate} = shift if @_;
  return $self;
}

=head2 check()

Check if the object the operator is applied to is in the correct
class. 

=cut

sub check {
  my $self = (ref  $_[0] ) ||  $_[0] ;
  my $object =  $_[1];
  my $at = eval ("\$"."$self"."::APPLIESTO");
  return $object->isa( $at ) ;
}

=head2 arity()

Returns the arity, ie, the number of individuals it can be applied to

=cut

sub arity {
  my $class = ref shift;
  return eval( "\$"."$class"."::ARITY" );
}

=head2 set( $options_hashref )

Converts the parameters passed as hash in instance variables. Default
method, probably should be overriden by derived classes. If it is not,
it sets the instance variables by prepending a C<_> to the keys of the
hash. That is, 
    $op->set( { foo => 3, bar => 6} );
will set C<$op-E<gt>{_foo}> and  C<$op-E<gt>{_bar}> to the corresponding values

=cut

sub set {
  my $self = shift;
  my $hashref = shift || croak "No params here";
  for ( keys %$hashref ) {
    $self->{"_$_"} = $hashref->{$_};
  }
}

=head2 Known subclasses

This is quite incomplete. Should be either generated automatically or
suppressed altogether 

=over 4

=item * 

L<Algorithm::Evolutionary::Op::Creator|Algorithm::Evolutionary::Op::Creator>

=item * 

L<Algorithm::Evolutionary::Op::Mutation|Algorithm::Evolutionary::Op::Mutation>

=item * 

L<Algorithm::Evolutionary::Op::Mutation|Algorithm::Evolutionary::Op::IncMutation>

=item * 

L<Algorithm::Evolutionary::Op::BitFlip|Algorithm::Evolutionary::Op::BitFlip>

=item * 

L<Algorithm::Evolutionary::Op::GaussianMutation|Algorithm::Evolutionary::Op:GaussianMutation>

=item * 

L<Algorithm::Evolutionary::Op::Novelty_Mutation>

=item * 

L<Algorithm::Evolutionary::Op:Crossover>

=item * 

L<Algorithm::Evolutionary::Op::VectorCrossover|Algorithm::Evolutionary::Op:VectorCrossover>

=item * 

L<Algorithm::Evolutionary::Op::CX|Algorithm::Evolutionary::Op:CX>

=item * 

L<Algorithm::Evolutionary::Op::ChangeLengthMutation|Algorithm::Evolutionary::Op::ChangeLengthMutation>


=item * 

L<Algorithm::Evolutionary::Op::ArithCrossover|Algorithm::Evolutionary::Op::ArithCrossover> 

=item * 

L<Algorithm::Evolutionary::Op::NoChangeTerm|Algorithm::Evolutionary::Op::NoChangeTerm>

=item * 

L<Algorithm::Evolutionary::Op::DeltaTerm|Algorithm::Evolutionary::Op::DeltaTerm>

=item * 

L<Algorithm::Evolutionary::Op::Easy|Algorithm::Evolutionary::Op::Easy>

=item * 

L<Algorithm::Evolutionary::Op::FullAlgorithm>


=back

=head1 See Also

The introduction to the XML format used here, L<XML>

=head1 Copyright
  
  This file is released under the GPL. See the LICENSE file included in this distribution,
  or go to http://www.fsf.org/licenses/gpl.txt

=cut

"What???";
