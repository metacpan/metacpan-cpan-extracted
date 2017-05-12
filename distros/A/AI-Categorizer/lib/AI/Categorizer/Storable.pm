package AI::Categorizer::Storable;

use strict;
use Storable;
use File::Spec ();
use File::Path ();

sub save_state {
  my ($self, $path) = @_;
  if (-e $path) {
    File::Path::rmtree($path) or die "Couldn't overwrite $path: $!";
  }
  mkdir($path, 0777) or die "Can't create $path: $!";
  Storable::nstore($self, File::Spec->catfile($path, 'self'));
}

sub restore_state {
  my ($package, $path) = @_;
  return Storable::retrieve(File::Spec->catfile($path, 'self'));
}

1;
__END__

=head1 NAME

AI::Categorizer::Storable - Saving and Restoring State

=head1 SYNOPSIS

  $object->save_state($path);
  ... time passes ...
  $object = Class->restore_state($path);
  
=head1 DESCRIPTION

This class implements methods for storing the state of an object to a
file and restoring from that file later.  In C<AI::Categorizer> it is
generally used in order to let data persist across multiple
invocations of a program.

=head1 METHODS

=over 4

=item save_state($path)

This object method saves the object to disk for later use.  The
C<$path> argument indicates the place on disk where the object should
be saved.

=item restore_state($path)

This class method reads the file specified by C<$path> and returns the
object that was previously stored there using C<save_state()>.

=head1 AUTHOR

Ken Williams, ken@mathforum.org

=head1 COPYRIGHT

Copyright 2000-2003 Ken Williams.  All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

AI::Categorizer(3), Storable(3)

=cut
