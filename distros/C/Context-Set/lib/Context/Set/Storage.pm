package Context::Set::Storage;
use Moose;

=head1 NAME

Context::Set::Storage - A base class for context storages.

=cut


=head2 populate_context

Populates the context from the storage, setting all its stored properties in one go.

Usage:

 $this->populate_context($context);

=cut

sub populate_context{
  my ($self, $context) = @_;
  confess("Please implement that on $self");
}

=head2 set_context_property

Gets called at set_property time by the framework.

Dont forget to return the result of the given $after code ref
if you want to propagate the change in the memory object (which is what you want I suppose).

usage:

   $this->set_context_property($context, $prop_name, $values,
                               sub{
                                  ... Something done after the storage is set ...
                               });



=cut

sub set_context_property{
  my ($self,$context, $prop, $v, $after) = @_;
  confess("Please implement that on $self");
}



__PACKAGE__->meta->make_immutable();
1;
