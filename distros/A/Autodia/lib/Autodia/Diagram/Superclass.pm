################################################################
# Autodia - Automatic Dia XML.(C)Copyright 2001-2009 A Trevena #
#                                                              #
# AutoDia comes with ABSOLUTELY NO WARRANTY; see COPYING file  #
# This is free software, and you are welcome to redistribute   #
# it under certain conditions; see COPYING file for details    #
################################################################

package Autodia::Diagram::Superclass;
use strict;

use Carp qw(cluck);

use base qw(Autodia::Diagram::Object);

#---------------------------------------------------------------------

#####################
# Constructor Methods

sub new
{
  my $class = shift;
  my $name = shift;

  cluck "new method called with no name\n" unless ($name);

  my $DiagramSuperclass = {};

  bless ($DiagramSuperclass, ref($class) || $class);
  $DiagramSuperclass->_initialise($name);
  return $DiagramSuperclass;
}

#--------------------------------------------------------------------
# Access Methods

 sub Inheritances
{
  my $self = shift;

  my @inheritances = ();
  if (ref $self->{"inheritances"}) {
      @inheritances = @{$self->{"inheritances"}};
  }
  return @inheritances;

}


sub add_inheritance
{
  my $self = shift;
  my $new_inheritance = shift;
  my @inheritances;

  $new_inheritance->Parent($self->Id);

  if (defined $self->{"inheritances"})
    { @inheritances = @{$self->{"inheritances"}}; }
  push(@inheritances, $new_inheritance);
  $self->{"inheritances"} = \@inheritances;

  return scalar(@inheritances);
}


sub Relations {
  my $self = shift;
  return (ref $self->{"relations"}) ? @{$self->{"relations"}} : () ;
}

sub add_relation {
  my $self = shift;
  my $new_relation = shift;
  $self->{relations} ||= [];
  push(@{$self->{relations}}, $new_relation);
  return 1;
}

sub Redundant {
  my $self = shift;
  my $replacement = shift || 0;

  if ($replacement) {
    if ($self->{"_redundant"}) {
      my $current_replacement = $self->{"_redundant"};
      return -1;
    }
    $self->{"_redundant"} = $replacement;
    return 1;
  }
  $self->{_redundant} = 0;
  return 0;
}

sub Name {
  my $self = shift;
  my $name = shift;

  if ($name)
    {
      $self->{"name"} = $name;
      return 1;
    }
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

#--------------------------------------------------------------------------
# Internal Methods

sub _initialise # over-rides method in DiagramObject
{
  my $self = shift;
  my $name = shift;
  $self->{"name"} = $name;
  $self->{"type"} = "superclass";
  return 1;
}

sub _update # over-rides method in DiagramObject
  {
    my $self = shift;
    $self->reposition();
    return 1;
  }

1;

##########################################################################

=head1 

=cut
