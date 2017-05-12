package Context::Set::Storage::BlackHole;
use Moose;

=head1 NAME

Context::Set::Storage::BlackHole - A Storage that doesnt do anything.

=cut

extends qw/Context::Set::Storage/;


=head2 populate_context

See super class L<Context::Set::Storage>

=cut

sub populate_context{}

=head2 set_context_property

See super class L<Context::Set::Storage>

=cut

sub set_context_property{
  my ($self, $context, $prop , $v , $after) = @_;
  return &{$after}();
}

=head2 delete_context_property

See superclass L<Context::Set::Storage>

=cut

sub delete_context_property{
  my ($self, $context, $prop , $after) = @_;
  return &{$after}();
}

__PACKAGE__->meta->make_immutable();
1;
