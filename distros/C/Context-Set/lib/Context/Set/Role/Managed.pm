package Context::Set::Role::Managed;
use Moose::Role;

=head1 NAME

Context::Set::Role::Managed - Make Managed context use the manager operations in place of their native ones.

=cut

has 'manager' => ( is => 'rw' , isa => 'Context::Set::Manager', weak_ref => 1  );


override 'unite' => sub{
  my ($self , $other ) = @_;
  return $self->manager()->unite($self, $self->manager->manage($other));
};

override 'restrict' => sub{
  my ($self, $restriction_name) = @_;
  return $self->manager()->restrict($self, $restriction_name);
};
1;
