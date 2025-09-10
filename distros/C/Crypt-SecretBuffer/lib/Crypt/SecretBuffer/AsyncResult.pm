package Crypt::SecretBuffer::AsyncResult;
# VERSION
# ABSTRACT: Observe results of a write_async operation
$Crypt::SecretBuffer::AsyncResult::VERSION = '0.006';
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::SecretBuffer::AsyncResult - Observe results of a write_async operation

=head1 DESCRIPTION

This object holds a reference to a background write operation started by
L<Crypt::SecretBuffer/write_async>.

=head1 METHODS

=head2 wait

  if (($bytes_written, $os_error)= $result->wait($seconds_or_undef)) {
   ...
  }

This waits up to C<$seconds> (or indefinitely if you pass undef) for the write operation to
complete.  If it has completed, this returns the number of bytes written and the OS error code
as a list.  On a timeout, it returns an empty list.

=head1 VERSION

version 0.006

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
