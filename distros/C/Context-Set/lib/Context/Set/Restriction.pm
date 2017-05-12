package Context::Set::Restriction;
use Moose;

extends qw/Context::Set/;

has '+name' => ( required => 1 );
has 'restricted' => ( is => 'ro' , isa => 'Context::Set' , required => 1 , weak_ref => 1 );

=head1 NAME

Context::Set::Restriction - A restriction of a Context.

=head2 SYNOPSYS

   $general->has_property('a'); # General has 'a'

   my $restriction = $general->restrict('specialized');

   $restriction->has_property('a'); # The restriction inherits from the properties of general.

   $restriction->set_property('b', 'value');
   $restriction->has_property('b'); # ONLY the restriction has property b.


=cut

=head2 fullname

See superclass.

=cut

sub fullname{
  my ($self) = @_;
  return $self->restricted()->fullname().'/'.$self->name();
}

=head2 is_inside

See superclass

=cut

sub is_inside{
  my ($self, $name) = @_;
  return $self->restricted->name() eq $name || $self->restricted->is_inside($name);
}

=head2 has_property

See superclass Context.

=cut

sub has_property{
  my ($self, $prop_name) = @_;
  return exists $self->properties()->{$prop_name} || $self->restricted->has_property($prop_name);
}


=head2 get_property

See Super Class.

=cut

sub get_property{
  my ($self, $prop_name) = @_;
  if( exists $self->properties()->{$prop_name} ){
    return $self->properties()->{$prop_name};
  }
  return $self->restricted()->get_property($prop_name);
}

sub _lookup_parents{
  my ($self,$propname) = @_;
  return $self->restricted->lookup($propname);
}

__PACKAGE__->meta->make_immutable();
1;
