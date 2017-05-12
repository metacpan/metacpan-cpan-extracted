################################################################
# AutoDia - Automatic Dia XML.   (C)Copyright 2001 A Trevena   #
#                                                              #
# AutoDia comes with ABSOLUTELY NO WARRANTY; see COPYING file  #
# This is free software, and you are welcome to redistribute   #
# it under certain conditions; see COPYING file for details    #
################################################################
package Autodia::Diagram::Object;

use strict;

require Exporter;
use vars qw($VERSION @ISA @EXPORT);

@ISA = qw(Exporter);


#---------------------------------------------------------------

#####################
# Constructor Methods

sub new
{
  my $class = shift;
  my $self = {};

  bless ($self, ref($class) || $class);
  $self->_initialise();

  return $self;
}

#------------------------------------------------------------------------
# Access Methods

sub set_location
{
  my $self = shift;
  my $new_x = shift || 1;
  my $new_y = shift || 1;

  if (defined $new_x )
  {
      $self->{"left_x"} = $new_x;
      $self->{"top_y"} = $new_y;
  }
  my @bottom_right_xy = split(",",$self->BottomRightPos);

  return \@bottom_right_xy;
}

sub TopLeftPos
{
    my $self = shift;
    my $return = sprintf("%.3f",$self->{"left_x"}) . "," . sprintf("%.3f",$self->{"top_y"});
    return $return;
}

sub BottomRightPos
{
    my $self = shift;


     $self->{"left_x"} ||= 1; # hack
     $self->{"width"}  ||= 1; # these aren't getting initialised for some reason
     $self->{"top_y"}  ||= 1;
     $self->{"height"} ||= 1;

    my $x = sprintf("%.3f",$self->{"width"} + $self->{"left_x"});
    my $y = sprintf("%.3f",$self->{"top_y"} + $self->{"height"});

    return "$x,$y";
}

sub Width
  {
    my $self = shift;
    return sprintf("%.3f",$self->{"width"});
  }

sub Height
  {
    my $self = shift;
    return sprintf("%.3f",$self->{"height"});
  }

sub Id
{
  my $self = shift;
  return $self->{"id"};
}

sub Set_Id
{
  my $self = shift;
  $self->{"id"} = shift;
  return 1;
}

sub Type
  {
    my $self = shift;
    my $return_val = "-";
    my $type = $self->{"type"} || 0;
    if ($type) { $return_val = $type; }
    return $return_val;
  }

sub Name
{
  my $self = shift;
  my $name = shift;
  if ($name)
    {
      $self->{"name"} = $name;
      return 1;
    }
  else
    {
     return $self->{"name"};
    }
}

sub LocalId
{
  my $self = shift;
  my $new_id = shift;
  my $return = 1;

  if (defined $new_id)
    { $self->{"local_id"} = $new_id; }
  else
    { $return = $self->{"local_id"}; }

  return $return;
}

#-----------------------------------------------------------------------------
# Internal Methods

sub _initialise
{
  my $self = shift;
  $self->{"width"}  = 1;
  $self->{"height"} = 1;
  $self->{"name"}   = "";
  $self->{"top_y"}  = 0;
  $self->{"left_x"} = 0;
  return;
}

sub _update
  {
    return 1;
  }

sub _width
  {
    my $self = shift;
    $self->{"width"} = 0.5 + (0.6 * length($self->{"name"}));
    return 1;
  }

sub _height
  {
    my $self = shift;
    $self->{"height"} = 2.5;
    return 1;
  }

sub _set_updated
  {
    my $self = shift;
    my $field = shift;

    ${$self->{"_updated"}}{$field} = 1;

    return 1;
  }

1;

###############################################################################

=head1

=cut
