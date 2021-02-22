package Hello;

use Moose;

sub some_method{
  print "Doing stuff. Bonsoir\n";
}

sub class_method{
    print "I am a class method\n";
}

sub exported_method{
    print "I am an exported method\n";
}

__PACKAGE__->meta->make_immutable();

=head1 NAME

Hello - Some Hello class. Nothing to do with Helicopter

=cut

