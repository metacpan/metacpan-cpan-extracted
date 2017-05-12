################################################################
# Autodia - Automatic Dia XML. Copyright 2001 - 2008 A Trevena #
#                                                              #
#  AutoDIA comes with ABSOLUTELY NO WARRANTY; see COPYING file #
# This is free software, and you are welcome to redistribute   #
# it under certain conditions; see COPYING file for details    #
################################################################
package Autodia::Diagram::Inheritance;

use strict;

use vars qw($VERSION @ISA @EXPORT);
use Exporter;

use Autodia::Diagram::Object;

@ISA = qw(Autodia::Diagram::Object);

my $inheritance_count = 0;

#--------------------------------------------------------------------
# Constructor Methods

sub new
{
  my $class = shift;
  my $child = shift;
  my $parent = shift;
  my $DiagramInheritance = {};

  bless ($DiagramInheritance, ref($class) || $class);
  $DiagramInheritance->_initialise($child, $parent);

  return $DiagramInheritance;
}


#--------------------------------------------------------------------
# Access Methods

sub Parent
{
  my $self = shift;
  my $parent = shift;
  my $return_val = 1;

  if (defined $parent)
  { $self->{"parent"} = $parent; }
  else
  { $return_val = $self->{"parent"}; }

  return $return_val;
}

sub Child
{
  my $self = shift;
  my $child = shift;
  my $return_val = 1;

  if (defined $child)
  { $self->{"child"} = $child; }
  else
  { $return_val = $self->{"child"}; }

  return $return_val;
}

sub Name
{
  my $self = shift;
  my $name = shift;

  if (defined $name)
    {
      $self->{"name"} = $name;
      return 1;
    }
  else
    { return $self->{"name"}; }
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

  my $child =  $self->{"_child"};

  my ($right_x,$bottom_y) = split (",",$child->TopLeftPos);
  my $mid_y = $bottom_y - 1.5;
  my $top_y= $mid_y - 1.5;

  $right_x += 2 + ($child->Width / 2);
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
  my $child = shift;
  my $parent = shift;

  $self->{"_child"} = $child;
  $self->{"child"} = $child->Id;
  $self->{"type"} = "inheritance";
  $self->{"_parent"} = $parent;
  $self->{"parent"} = $parent->Id;
  $self->{"name"} = $self->{"parent"}."-".$self->{"child"};

  return 1;
}

sub _update # over-rides method in DiagramObject
  {
    my $self = shift;
    $self->reposition();
    return 1;
  }

1;

##############################################################

=head1

=cut

