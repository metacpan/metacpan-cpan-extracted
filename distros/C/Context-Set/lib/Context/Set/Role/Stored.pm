package Context::Set::Role::Stored;
use Moose::Role;

=head1 NAME

Context::Set::Role::Stored - A stored context holds a Context::Set::Storage and uses it.

=cut

has 'storage' => ( is => 'rw' , isa => 'Context::Set::Storage', weak_ref => 1  );

around 'set_property' => sub{
  my ($orig, $self, $prop , $v ) = @_;

  return $self->storage->set_context_property($self,
                                              $prop,
                                              $v,
                                              sub{
                                                $self->$orig($prop,$v);
                                              });
};

=head2 refresh_from_storage

Refreshes this context from the storage it is stored in.

Usage:

 $this->refresh_from_storage();

=cut

sub refresh_from_storage{
  my ($self) = @_;
  $self->storage->populate_context($self);
  return $self;
}

around 'delete_property' => sub{
  my ($orig, $self, $prop) = @_;
  return $self->storage->delete_context_property($self,
                                                 $prop,
                                                 sub{
                                                   $self->$orig($prop);
                                                 });
};

1;
