require DataStore::CAS;
1;
# PODNAME: DataStore::CAS::VirtualHandle
# ABSTRACT: Handy base class for virtual filehandles

__END__

=pod

=head1 NAME

DataStore::CAS::VirtualHandle - Handy base class for virtual filehandles

=head1 VERSION

version 0.020001

=head1 DESCRIPTION

This class implements an API compatible with both IO::Handle and
original-style GLOBREF handles.  It acts as a proxy, passing all operations
to the L<CAS instance|DataStore::CAS> which created it.

This object is a blessed globref, but it has a handy C<_data> attribute which
gives you access to the hash portion of the glob, so the CAS implementation
can store per-handle details.

See L<DataStore::CAS::Virtual> for an example of how this is used, in the
methods C<new_write_handle>, C<_handle_write>, C<_handle_seek>,
C<_handle_tell>, and C<commit_write_handle>.

=head1 METHODS

All methods normally pass through to the CAS that created it:

  $handle->METHODNAME(@ARGS);
  # proxies to...
  $handle->_cas->_handle_METHODNAME($handle, @args)

thanks to AUTOLOAD.  There are a few methods that have been given specific
implementations though:

=head2 new

  $handle= $class->new( $cas_instance, \%data )
  # cas_instance is now found in $handle->_cas
  # a copy of \%data is now found in $handle->_data

Creates a new VirtualHandle object.  Blesses the globref and all that ugly
stuff.  Stores a reference to a CAS and some arbitrary fields for you.

=head2 _cas

The L<CAS instance|DataStore::CAS> this handle belongs to.

=head2 _data

A hashref of arbitrary data the CAS owner wants to keep in this handle.

=head2 READ

=head2 GETC

=head2 getc

These methods all proxy to, or are implemented using C<read>
(C<$cas-E<gt>_handle_read>).

=head2 READLINE

=head2 getlines

These methods all proxy to, or are implemented using C<getline>
(C<$cas-E<gt>_handle_getline>).

=head2 WRITE

=head2 PRINT

=head2 PRINTF

=head2 print

=head2 printf

These methods all proxy to, or are implemented using C<write>
(C<$cas-E<gt>_handle_write>).

=head2 FILENO

=head2 fileno

These methods return undef.  (If you actually have a file descriptor, why
would you need a virtual handle object?)

=head1 BUGS

The Perl I/O abstraction.

But more specifically, you cannot yet use "Perl IO Layers" on these objects,
because it appears I would have to re-implement the layers from scratch.

You also cannot use sysread/syswrite on them.  (there doesn't appear to be any
way to capture those calls with the TIE interface.)

These objects to not actually inherit from IO::Handle, because loading
IO::Handle in a program that doesn't intend to use it is wasteful, and because
it would make these objects appear to have methods which they don't support.

=head1 AUTHOR

Michael Conrad <mconrad@intellitree.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Michael Conrad, and IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
