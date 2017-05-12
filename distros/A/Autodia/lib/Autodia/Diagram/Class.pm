package Autodia::Diagram::Class;
use strict;

=head1 NAME

Autodia::Diagram::Class - Class that holds, updates and outputs the values of a diagram element of type class.

=head1 SYNOPSIS

use Autodia::Diagram::Class;

my $Class = Autodia::Diagram::Class->new;

=head2 Description

Autodia::Diagram::Class is an object that represents the Dia UML Class element within a Dia diagram. It holds, outputs and allows the addition of attributes, relationships and methods.

=cut

use Data::Dumper;

use base qw(Autodia::Diagram::Object);

=head1 METHODS

=head2 Constructor

my $Class = Autodia::Diagram::Class->new($name);

creates and returns a simple Autodia::Diagram::Class object, containing its name and its original position (default 0,0).

=head2 Accessors

Autodia::Diagram::Class attributes are accessed through methods, rather than directly. Each attribute is available through calling the method of its name, ie Inheritances(). The methods available are : 

Operations, Attributes, Inheritances, Dependancies, Parent, and has_child. The first 4 return a list, the later return a string.

Adding elements to the Autodia::Diagram::Class is acheived through the add_<attribute> methods, ie add_inheritance().

Rather than remove an element from the diagram it is marked as redundant and replaced with a superceding element, as Autodia::Diagram::Class has highest precedence it won't be superceded and so doesn't have a redundant() method. Superclass and Component do.

=head2 Accessing and manipulating the Autodia::Diagram::Class

$Class->Attributes(), Inheritances(), Operations(), and Dependancies() all return a list of their respective elements.

$Class->Parent(), and has_child() return the value of the parent or child respectively if present otherwise a false.

$Class->add_attribute(), add_inheritance(), add_operation(), and add_dependancy() all add a new element of their respective types.

=cut

#####################
# Constructor Methods

sub new {
  my $class = shift;
  my $name = shift;
  my $self = {};
  bless ($self, ref($class) || $class);
  $self->_initialise($name);
  return $self;
}

#-------------------------------------------------------------------------

################
# Access Methods

sub Dependancies {
  my $self = shift;
  if (defined $self->{"dependancies"}) {
    my @dependancies = @{$self->{"dependancies"}};
    return @dependancies;
  } else {
    return;
  }
}


sub add_dependancy {
  my $self = shift;
  my $new_dependancy = shift;
  my @dependancies;

  if (defined $self->{"dependancies"}) {
    @dependancies = @{$self->{"dependancies"}};
  }

  push(@dependancies, $new_dependancy);
  $self->{"dependancies"} = \@dependancies;

  return scalar(@dependancies);
}

sub Inheritances {
  my $self = shift;
  if (ref $self->{"inheritances"}) {
    return $self->{"inheritances"};
  } else {
    return undef;
  }
}

sub add_inheritance {
  my $self = shift;
  my $new_inheritance = shift;
  my @inheritances;

  if (defined $self->{"inheritances"}) {
    @inheritances = @{$self->{"inheritances"}};
  }

  push(@inheritances, $new_inheritance);
  $self->{"inheritances"} = \@inheritances;
  $self->Parent($new_inheritance->Id);

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


sub Attributes {
  my $self = shift;

  if (defined $self->{"attributes"}) {
    my @attributes = @{$self->{"attributes"}};
    return \@attributes;
  } else {
    return;
  }
}

sub add_attribute {
  my $self = shift;
  my %new_attribute = %{shift()};

  # discard new attribute if duplicate
  my $discard = 0;
  foreach my $attribute ( @{$self->{"attributes"}} ) {
    my %attribute = %$attribute;
    if ($attribute{name} eq $new_attribute{name}) {
      $discard = 1;
    }
  }

  unless ($discard) {
    push (@{$self->{"attributes"}},\%new_attribute);
    $self->_set_updated("attributes");
    $self->_update;
  }

  return scalar(@{$self->{"attributes"}});
}

sub has_child {
  my $self   = shift;
  my $child  = shift;
  my $return = 0;

  if (defined $child) {
    $self->{"child"} = $child;
  } else {
    $return = $self->{"child"};
  }
}

sub Parent {
  my $self   = shift;
  my $parent = shift;
  my $return = 0;

  if (defined $parent) {
    $self->{"parent"} = $parent;
  } else {
    $return = $self->{"parent"};
  }
}

sub replace_superclass {
  my $self       = shift;
  my $superclass = shift;

  if (ref ($superclass->Inheritances)) {
    my @inheritances = @{$superclass->Inheritances};
    foreach my $inheritance (@inheritances) {
      $inheritance->Parent($self->Id);
    }
  }

  if (ref ($superclass->Relations)) {
    my @relations = @{$superclass->Relations};
    foreach my $relation (@relations) {
      $relation->Parent($self->Id);
    }
  }

  return 1;
}

sub replace_component {
  my $self = shift;
  my $component = shift;

  if (ref ($component->Dependancies) ) {
    my @dependancies = $component->Dependancies;
    foreach my $dependancy (@dependancies) {
      $dependancy->Parent($self->Id);
    }
  }

  return 1;
}

sub Operations {
  my $self = shift;

  if (defined $self->{"operations"}) {
    my @operations = $self->{"operations"};
    return @operations;
  } else {
    return;
  }
}

sub add_operation {
  my $self = shift;
  my $operation = shift();
  $operation->{_id} = ( ref $self->{"operations"} ) ? scalar @{$self->{"operations"}} : 0 ;
  push (@{$self->{"operations"}},$operation);
  $self->{operation_index}{$operation->{name}} = $operation;

  $self->_set_updated("operations");
  $self->_update;

  return scalar(@{$self->{"operations"}});
}

sub get_operation {
    my ($self, $name) = @_;
    return $self->{operation_index}{$name};
}

sub update_operation {
    my $self = shift;
    my $operation = shift;
    
    $self->{"operations"}[$operation->{_id}] = $operation;
    $self->{operation_index}{$operation->{name}} = $operation;

    $self->_set_updated("operations");
    $self->_update;

    return;
}

sub Realizations {
  my $self = shift;
  if( defined $self->{"realizations"} ) {
    my @realizations = @{ $self->{"realizations"} };
    return @realizations;
  }
  else {
    return;
  }
}
 
sub add_realization {
  my $self            = shift;
  my $new_realization = shift;
  my @realizations;
 
  if( defined $self->{"realizations"} ) {
    @realizations = @{ $self->{"realizations"} };
  }
 
  push( @realizations, $new_realization );
  $self->{"realizations"} = \@realizations;
 
  return scalar(@realizations);
}


#-----------------------------------------------------------------------

##################
# Internal Methods

# over-rides method in DiagramObject
sub _initialise {
  my $self = shift;
  $self->{"name"} = shift;
  $self->{"type"} = "class";
  $self->{"top_y"} = 1;
  $self->{"left_x"} = 1;
  $self->{"width"} = 2; # arbitary
  $self->{"height"} = 2; # arbitary
  #$self->{"operations"} = [];
  #$self->{"attributes"} = [];
  $self->{operation_index} = {};

  return 1;
}

sub _update {
  my $self = shift;

  my %updated = %{$self->{_updated}};

  if ($updated{"attributes"}) {
    my $longest_element = ($self->{"width"} -1) / 0.5;
    my @attributes = @{$self->{"attributes"}};
    my $last_element = pop @attributes;
    if (length $last_element > $longest_element) {
      $self->{"width"} = (length $last_element * 0.5) + 1;
    }
    $self->{height} += 0.8;
  }

  if ($updated{"operations"}) {
    my $longest_element = ($self->{width} -1) / 0.5;
    my @operations = @{$self->{"operations"}};
    my $last_element = pop @operations;
    if (length $last_element > $longest_element) {
      $self->{"width"} = (length $last_element * 0.5) + 1;
    }
    $self->{"height"} += 0.8;
  }

  undef $self->{"_updated"};

  return 1;
}


1;

##############################################################################


=head2 See Also

L<Autodia::DiagramObject>

L<Autodia::Diagram>

L<Autodia::DiagramSuperclass>

L<Autodia::DiagramInheritance>

=head1 AUTHOR

Aaron Trevena, E<lt>aaron.trevena@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Aaron Trevena

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.

=cut

########################################################################
