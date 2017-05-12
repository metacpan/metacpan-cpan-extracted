require DataStore::CAS;
1;
# PODNAME: DataStore::CAS::FileCreatorHandle
# ABSTRACT: Handle-emulation object used for writing content into a CAS

__END__

=pod

=head1 NAME

DataStore::CAS::FileCreatorHandle - Handle-emulation object used for writing content into a CAS

=head1 VERSION

version 0.020001

=head1 DESCRIPTION

Specialized instance of L<DataStore::CAS::VirtualHandle> which writes to
temporary space while hashing the data you write to it.  No actual
functionality is contained in this class- it just passes calls to the
CAS implementation.

=head1 METHODS

This class extends the VirtualHandle interface with 5 new methods.
Four of these methods would happen using the built-in AUTOLOAD, but they are
enumerated as real methods for the sake of method introspection on handle
objects.

=head2 commit

  Closes the handle, commits all written data to the CAS, and returns the
  digest hash of that data.

  Passes through to C<$cas-E<gt>commit_write_handle($handle, ...)>

=head2 close

  See IO::Handle API.

  Passes through to C<$cas-E<gt>_handle_close($handle, ...)>

=head2 seek

  See IO::Handle API.

  Passes through to C<$cas-E<gt>_handle_close($handle, ...)>

=head2 tell

  See IO::Handle API.

  Passes through to C<$cas-E<gt>_handle_close($handle, ...)>

=head2 write

  See IO::Handle API.

  Passes through to C<$cas-E<gt>_handle_close($handle, ...)>

=head1 AUTHOR

Michael Conrad <mconrad@intellitree.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Michael Conrad, and IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
