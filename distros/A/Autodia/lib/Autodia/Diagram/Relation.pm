################################################################
# Autodia - Automatic Dia XML. Copyright 2001 - 2008 A Trevena #
#                                                              #
#  AutoDIA comes with ABSOLUTELY NO WARRANTY; see COPYING file #
# This is free software, and you are welcome to redistribute   #
# it under certain conditions; see COPYING file for details    #
################################################################
package Autodia::Diagram::Relation;

use strict;

use vars qw($VERSION @ISA @EXPORT);
use Exporter;

use Autodia::Diagram::Object;

@ISA = qw(Autodia::Diagram::Object);

my $relation_count = 0;

#--------------------------------------------------------------------
# Constructor Methods

sub new
{
  my $class = shift;
  my $left = shift;
  my $right = shift;
  my $DiagramRelation = {};

  bless ($DiagramRelation, ref($class) || $class);
  $DiagramRelation->_initialise($left, $right);

  return $DiagramRelation;
}

#--------------------------------------------------------------------
# Access Methods

sub Left {
  my $self = shift;
  my $left = shift;

  if (defined $left) {
      $self->{"left"} = $left;
  }
  return $self->{"left"};
}

sub Right {
  my $self = shift;
  my $right = shift;

  if (defined $right){
    $self->{"_right"} = $right;
    $self->{"right"} = $right->Id;
  }
  return $self->{"right"};
}

sub Name {
  my $self = shift;
  my $name = shift;

  if (defined $name) {
    $self->{"name"} = $name;
  }
  return $self->{"name"};
}


sub Orth_Top_Left
{
  my $self = shift;
  return $self->{"top_connection"};
}

sub Orth_Bottom_Right
{
  my $self = shift;
  return $self->{"bottom_connection"};
}

sub Orth_Mid_Left
{
  my $self = shift;
  my $return = ($self->{"left_x"}). "," . $self->{"mid_y"};

  return $return;
}

sub Orth_Mid_Right
{
  my $self = shift;
  my $return = ($self->{"right_x"}). "," . $self->{"mid_y"};

  return $return;
}

sub Reposition
{
  my $self = shift;

  my $right =  $self->{"_right"};

  my ($right_x,$bottom_y) = split (",",$right->TopLeftPos);
  my $mid_y = $bottom_y - 1.5;
  my $top_y= $mid_y - 1.5;

  $right_x += 2 + ($right->Width / 2);
  my $left_x = $right_x - 5;

  $self->{"left_x"} = $left_x;
  ($self->{"right_x"}, $self->{"top_y"},
   $self->{"mid_y"}, $self->{"bottom_y"}) = ($right_x, $top_y, $mid_y, $bottom_y);
  $self->{"top_connection"} = $self->{left_x} . "," . $self->{"top_y"};
  $self->{"bottom_connection"} = $right_x . "," . $bottom_y;

  return 1;
}


#------------------------------------------------------
# Internal Methods

sub _initialise # over-rides method in DiagramObject
{
  my $self = shift;
  my $left = shift;
  my $right = shift;

  $self->{"_right"} = $right;
  $self->{"right"} = $right->Id;
  $self->{"type"} = "relation";
  $self->{"_left"} = $left;
  $self->{"left"} = $left->Id;
  $self->{"name"} = $self->{"left"}."-".$self->{"right"};

  # TODO:
  # add left label and right label
  # check for existing relationship between two objects, re-use that one if exists and set reverse label from that

  return 1;
}

sub _update # over-rides method in DiagramObject
  {
    my $self = shift;
    $self->reposition();
    return 1;
  }

1;
