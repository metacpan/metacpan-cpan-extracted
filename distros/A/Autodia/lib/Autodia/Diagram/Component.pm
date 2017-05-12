################################################################
# Autodia - Automatic Dia XML.(C)Copyright 2001-2009 A Trevena #
#                                                              #
# Autodia comes with ABSOLUTELY NO WARRANTY; see COPYING file  #
# This is free software, and you are welcome to redistribute   #
# it under certain conditions; see COPYING file for details    #
################################################################
package Autodia::Diagram::Component;
use strict;

use Carp qw(cluck);

use base qw(Autodia::Diagram::Object);


#-------------------------------------------------------------------------------

#####################
# Constructor Methods

sub new
{
  my $class = shift;
  my $name = shift;
  cluck "new method called with no name\n" unless ($name);
  my $DiagramComponent = {};
  bless ($DiagramComponent, ref($class) || $class);
  $DiagramComponent->_initialise($name);
  return $DiagramComponent;
}

#-------------------------------------------------------------------------------
# Access Methods

sub Dependancies
{
  my $self = shift;
  if (defined $self->{"dependancies"})
    {
      my @dependancies = @{$self->{"dependancies"}};
      return @dependancies;
    }
  else
  { return -1; } # erk! this component has no dependancies 
}


sub add_dependancy
{
  my $self = shift;
  my $new_dependancy = shift;
  my @dependancies;

  if (defined $self->{"dependancies"})
    {
      @dependancies = @{$self->{"dependancies"}};
      push(@dependancies, $new_dependancy);
    }
  else
    { $dependancies[0] = $new_dependancy; }

  $self->{"dependancies"} = \@dependancies;
  $new_dependancy->Parent($self->Id);

  return scalar(@dependancies) ;
}

sub Redundant
{
    my $self = shift;
    my $replacement = shift;
    if (defined $replacement)
    {
	if ($self->{"_redundant"})
	{
	    my $current_replacement = $self->{"_redundant"};
	    return -1;
	}
	$self->{"_redundant"} = $replacement;
    }
    return $self->{"_redundant"};
}

sub Name
{
  my $self = shift;
  my $name = shift;

  if ($name)
    { $self->{"name"} = $name; return 1; }
  else
    { return $self->{"name"}; }
}

sub LocalId
{
    my $self = shift;
    my $return_val = 1;
    my $new_id = shift;

    if ($new_id)
    { $self->{"local_id"} = $new_id }
    else
    { $return_val = $self->{"local_id"}; }
    return $return_val;
}

sub TextPos
{
    my $self = shift;
    my $text_pos = $self->{"left_x"}+0.285;
    $text_pos .= ",";
    $text_pos .= $self->{"top_y"}+0.895;
    return $text_pos;
}

#-----------------------------------------------------------------------------
# Internal Methods

sub _initialise # over-rides method in DiagramObject
{
  my $self = shift;
  $self->{"name"} = shift;
  $self->{"type"} = "Component"; # Component in caps rest lower case (fix this)
  $self->{"left_x"} = 0;
  $self->{"top_y"} = 0;
  return 1;
}

sub _update # over-rides method in DiagramObject
  {
      # might use this later
      my $self = shift;
      $self->reposition();
      return 1;
  }

1;

############################################################################

=head1 NAME DiagramComponent - Handles elements of type UML Smallpackage

This is a subclass of DiagramObject, which acts as a UML package.

Used by autodia.pl and Handler (and handlers inheriting from Handler)

used as in $Component = DiagramComponent->New($name);

=cut
