use strict; #-*-cperl-*-
use warnings;

=head1 NAME

Tree - A Direct Acyclic Graph, or tree, useful for Genetic Programming-Style stuff

=head1 SYNOPSIS

    use Algorithm::Evolutionary::Individual::Tree;
    #Hash with primitives, arity, and range for constants that multiply it

    my $primitives = { sum => [2, -1, 1],
				   multiply => [2, -1, 1],
				   substract => [2, -1, 1],
				   divide => [2, -1, 1],
				   x => [0, -10, 10],
				   y => [0, -10, 10] };

    my $indi = new Algorithm::Evolutionary::Individual::Tree $primitives, 5 ; # Build random tree with knwo primitives
                                           # and depth up to 5

    my $indi5 = $indi->clone(); #Creates a copy of the individual

    print $indi3->asString(); #Prints the individual
    print $indi3->asXML() #Prints it as XML. See L<XML> for more info on this

=head1 Base Class

L<Algorithm::Evolutionary::Individual::Base|Algorithm::Evolutionary::Individual::Base>

=head1 DESCRIPTION

Tree-like individual for genetic programming. Uses direct acyclic graphs
as representation for trees, which is very convenient. This class has
not been tested extensively, so it might not work.

=cut

package Algorithm::Evolutionary::Individual::Tree;

use Carp;
use Exporter;

our ($VERSION) = ( '$Revision: 3.1 $ ' =~ / (\d+\.\d+)/ );

use Tree::DAG_Node;

use Algorithm::Evolutionary::Individual::Base;

our @ISA = qw (Algorithm::Evolutionary::Individual::Base);

=head1 METHODS

=head2 new( $primitives, $depth, $fitness )

Creates a new tree using a primitives hashref, max depth, and a
ref-to-fitness 

=cut

sub new {
  my $class = shift; 
  my $self = {_primitives => shift,
	      _depth => shift,
	      _fitness => undef };
  my @keys = keys %{$self->{_primitives}};
  $self->{_keys} = \@keys;
  bless $self, $class;
  $self->randomize();
  return $self;
}

=head2 set

Sets values of an individual; takes a hash as input

=cut

sub set {
  my $self = shift; 
  my $hash = shift || croak "No params here";
  for ( keys %{$hash} ) {
    $self->{"_$_"} = $hash->{$_};
  }
  $self->{_tree} = undef;
  $self->{_fitness} = undef;
}

=head2 randomize

Assigns random values to the elements

=cut

sub randomize {
  my $self = shift; 
  $self->{_tree} = Tree::DAG_Node->new();
  my $name;
  do {
	$name =  $self->{'_keys'}[rand( @{$self->{'_keys'}} - 1 )];
  } until $self->{'_primitives'}{$name}[0] > 1; #0 is arity
  #Compute random constant
  my $ct = $self->{'_primitives'}{$name}[1] 
	+ rand( $self->{'_primitives'}{$name}[2] -  $self->{'_primitives'}{$name}[1]);
  $self->{'_tree'}->name( $name ); #Root node
  $self->{'_tree'}->attributes( { constant => $ct} );
  $self->growSubTree( $self->{'_tree'}, $self->{_depth} );
}


=head2 fromString

Probably useless, in this case. To be evolved.

=cut

sub fromString  {
  my $class = shift; 
  my $str = shift;
  my $sep = shift || ",";
  my $self = { _array => split( $sep, $str ),
               _fitness => undef };
  bless $self, $class;
  return $self;
}

=head2 clone

Similar to a copy ctor: creates a new individual from another one

=cut

sub clone {
  my $indi = shift || croak "Indi to clone missing ";
  my $self = { _fitness => undef,
	       _depth => $indi->{_depth} };
  %{$self->{_primitives}} =  %{$indi->{_primitives}};
  @{$self->{_keys}} =  @{$indi->{_keys}};			      
  $self->{_tree} = $indi->{_tree}->copy_tree();
  bless $self, __PACKAGE__;
  return $self;
}


=head2 asString

Prints it

=cut

sub asString {
  my $self = shift;
  #my $lol =  $self->{_tree}->tree_to_lol();
#  my $str = lolprint( @$lol );
#  $str .= " -> ";
#  if ( defined $self->{_fitness} ) {
#	$str .=$self->{_fitness};
#  }
  my $node =  $self->{_tree};
  my $str;
  $node->walk_down( { callback => \&nodePrint,
					  callbackback => \&closeParens,
					  str => \$str,
					  primitives => $self->{_primitives}} );
#  print $self->{_tree}->tree_to_lol_notation();
  return $str;
}

=head2 nodePrint

Prints a node

=cut

sub nodePrint {
  my $node = shift;
  my $options = shift;
  my $strRef = $options->{str};
  ${$strRef} .= ($node->attributes()->{constant}?($node->attributes()->{constant}. "*"):""). $node->name();
  if ( $options->{primitives}{$node->name()}[0] > 0 ) { #That's the arity
	${$strRef} .= "( ";
  } elsif ( $options->{primitives}{$node->name()}[0] == 0 ){ #Add comma
    if ($node->right_sister() ) {
      ${$strRef} .= ", ";
    }
  }
  
}

=head2 closeParens

Internal subrutine: closes node parenthesis

=cut 

sub closeParens {
  my $node = shift;
  my $options = shift;
  my $strRef = $options->{str};
  if ( $options->{primitives}{$node->name()}[0] > 0 ) { #That's the arity
	${$strRef} .= " ) ";
    if ($node->right_sister() ) {
      ${$strRef} .= ", ";
    }
  }
 
}


=head2 Atom

Returns the tree, which is atomic by itself. Cannot be used as lvalue

=cut

sub Atom {
  my $self = shift;
  return $self->{'_tree'};
}

=head2 asXML

Prints it as XML. It prints the tree as String, which does not mean
you will be able to get it back from this form. It's done just for
compatibity, reading from this format will be available. In the future.

=cut

sub asXML {
  my $self = shift;
  my $str = $self->SUPER::asXML();
#  my $str2 = ">\n<atom><![CDATA[".$self->asString()."]]></atom> ";
  my $str2 = ">\n<atom><![CDATA[dummy root node]]></atom> ";
  $str =~ s/\/>/$str2/e ;
  return $str.$str2."\n</indi>";
}


=head2 addAtom

Dummy sub

=cut 

sub addAtom {
  my $self = shift;
  $self->{_tree} = Tree::DAG_Node->new();
  $self->{'_tree'}->name( "dummy root node" ); #Root node
  $self->{'_tree'}->attributes( { constant => 0 } );
}

=head2 lolprint

Print the list of lists that composes the tree, using prefix notation

=cut 

sub lolprint {
  my @ar = @_;
  my $str;
  if ( $#ar > 0 ) {
	$str = $ar[$#ar]."(";
	for ( @ar[0..$#ar-1] ) {
	  if ( ref $_ eq 'ARRAY' ) {
		$str .= lolprint( @$_ );
	  } else {
		$str .= $_;
	  }
	  $str .= ", " if ($_ != $ar[$#ar-1]);
	}
	$str .= " )";

  } else {
	$str = $ar[0];
  }
  return $str;
}

=head2 growSubTree

Grows a random tree, with primitives as indicated, and a certain depth. Depth
defaults to 4

=cut

sub growSubTree { 
  my $self = shift;
  my $tree = shift;
  my $depth = shift || 4;
  return if $depth == 1;
  for ( my $i = 0; $i < $self->{_primitives}{$tree->name()}[0]; $i++ ) {
	my $primitive;
	if ( $depth > 2 ) {
	  $primitive = $self->{_keys}[rand( @{$self->{_keys}} )];
	} else {
	  do {
		$primitive = $self->{_keys}[rand( @{$self->{_keys}} )];
	  } until $self->{_primitives}{$primitive}[0] == 0;
	}
	my $shiquiya = $tree->new_daughter();
	#Generate constant
	my $ct = $self->{_primitives}{$primitive}[1] 
	  + rand( $self->{_primitives}{$primitive}[2] -  $self->{_primitives}{$primitive}[1]);
	$shiquiya->name($primitive);
	$shiquiya->attributes( { constant => $ct} );
	$self->growSubTree( $shiquiya, $depth-1);
  }
}

=head2 size()

Returns 1, since it's got only 1 Atom

=cut

sub size {
  my $self = shift;
  return 1;
}

=head1 Copyright
  
  This file is released under the GPL. See the LICENSE file included in this distribution,
  or go to http://www.fsf.org/licenses/gpl.txt

  CVS Info: $Date: 2009/07/28 11:30:56 $ 
  $Header: /media/Backup/Repos/opeal/opeal/Algorithm-Evolutionary/lib/Algorithm/Evolutionary/Individual/Tree.pm,v 3.1 2009/07/28 11:30:56 jmerelo Exp $ 
  $Author: jmerelo $ 
  $Revision: 3.1 $
  $Name $

=cut
