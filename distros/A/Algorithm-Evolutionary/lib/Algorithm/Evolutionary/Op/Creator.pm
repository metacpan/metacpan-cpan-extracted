use strict;
use warnings;

=head1 NAME

Algorithm::Evolutionary::Op::Creator - Operator that generates groups of individuals, of the intended class

=head1 SYNOPSIS

    my $op = new Algorithm::Evolutionary::Op::Creator; #Creates empty op, with rate

    my $xmlStr=<<EOC;
    <op name='Creator' type='nullary'>
      <param name='number' value='20' />
      <param name='class' value='BitString' />
      <param name='options'>
        <param name='length' value='320 />
      </param>
    </op>
    EOC

    my $ref = XMLin($xmlStr); #This step is not really needed; only if it's going to be manipulated by another object
    my $op = Algorithm::Evolutionary::Op::Base->fromXML( $ref ); #Takes a hash of parsed XML and turns it into an operator    

    print $op->asXML(); #print its back in XML shape

    my $op2 = new Algorithm::Evolutionary::Op::Creator( 20, 'String', { chars => [a..j], length => '10' });

    my @pop;
    $op2->apply( \@pop ); #Generates population

=head1 DESCRIPTION

Base class for operators applied to Individuals and Populations and all the rest

=head1 METHODS

=cut

package Algorithm::Evolutionary::Op::Creator;

use lib qw( ../.. ../../.. );

use base 'Algorithm::Evolutionary::Individual::Base';

use Carp;

our ($VERSION) = ( '$Revision: 3.1 $ ' =~ / (\d+\.\d+)/ ) ;

=head2 new( $number_of_individuals, $class_to_generate, $options_hash )

Takes a hash with specific parameters for each subclass, creates the 
object, and leaves subclass-specific assignments to subclasses

=cut

sub new {
  my $class = shift;
  my $number = shift || croak "What?? No number??\n";
  my $classToGenerate = shift || croak "Need a class to generate, man!\n";  
  my $hash = shift; #No carp here, some operators do not need specific stuff
  my $self = { _number => $number,
	       _class => $classToGenerate,
	       _hash => $hash };
  bless $self, $class; # And bless it
  return $self;
}

=head2 apply( $population_hash )

Generates the population according to the parameters passed in the ctor

=cut

sub apply ($) {
  my $self = shift;
  my $popRef = shift || croak "Don't have a pop here\n";

  for ( my $i = 0; $i < $self->{_number}; $i ++ ) {
    my $indi = Algorithm::Evolutionary::Individual::Base::create( $self->{_class}, $self->{_hash});
    push( @{$popRef}, $indi );
  }
}

=head2 asXML()

Serializes the object as an XML nodeset

=cut
  
sub asXML {
  my $self = shift;
  
  my $str=<<EOC;
<op name='Creator'>
      <param name='number' value='$self->{_number}' />
      <param name='class' value='$self->{_class}' />
      <param name='options'>
EOC
  for ( keys %{$self->{_hash}} ){
    $str.="\t\t<param name='$_' value='$self->{_hash}->{$_}' />\n";
  }
  $str.= "\t</param>\n</op>\n";
  return $str;
}  

=head2 set( $params_hash )

Sets the instance variables of the object, which, so far, should be a 
bit "raw". Usually called from the base class

=cut

sub set {
  my $self = shift;
  my $hash = shift || croak "No params!";

  $self->{_number} = $hash->{number};
  $self->{_class} = $hash->{class};
  $self->{_hash} = {};
  for my $k ( keys %{$hash->{options}} ) {
    $self->{_hash}->{$k} = $hash->{'options'}->{$k};
  }
  
}


=head1 Copyright
  
  This file is released under the GPL. See the LICENSE file included in this distribution,
  or go to http://www.fsf.org/licenses/gpl.txt

  CVS Info: $Date: 2009/09/14 16:36:38 $ 
  $Header: /media/Backup/Repos/opeal/opeal/Algorithm-Evolutionary/lib/Algorithm/Evolutionary/Op/Creator.pm,v 3.1 2009/09/14 16:36:38 jmerelo Exp $ 
  $Author: jmerelo $ 
  $Revision: 3.1 $
  $Name $

=cut

"What???";
