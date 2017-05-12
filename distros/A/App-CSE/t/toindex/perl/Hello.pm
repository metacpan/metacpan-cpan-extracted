package Hello;

use Moose;

sub some_method{
  print "Doing stuff. Bonsoir\n";
}

__PACKAGE__->meta->make_immutable();

=head1 NAME

Hello - Some Hello class. Nothing to do with Helicopter

=cut

