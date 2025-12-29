package Crypt::SecretBuffer::ConsoleState;
# VERSION
# ABSTRACT: Disable TTY echo within a scope
$Crypt::SecretBuffer::ConsoleState::VERSION = '0.017';
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::SecretBuffer::ConsoleState - Disable TTY echo within a scope

=head1 DESCRIPTION

This object provides a cross-platform way to inspect the TTY echo flag on Unix or the Console
echo flag on Windows, disable echo, and restore it on scope end.

=head1 CONSTRUCTORS

=head2 new

  $console_state= Crypt::SecretBuffer::ConsoleState->new($handle);
  $console_state= Crypt::SecretBuffer::ConsoleState->new(%options);

Return a new object which caches the console/tty state of the provided file handle.
If the handle is not a console/tty, this dies.

Options:

  handle        => $fh,
  auto_restore  => $bool
  echo          => $bool
  line_input    => $bool

=head2 maybe_new

  $console_state= Crypt::SecretBuffer::ConsoleState->maybe_new($handle);
  $console_state= Crypt::SecretBuffer::ConsoleState->maybe_new(%options);

Return a new object B<unless> the C<$handle> is not a console/tty, or if you request an echo
state and the console/tty is already in that state.  In other words, instead of writing

  my $st= eval { Crypt::SecretBuffer::ConsoleState->new($handle) };
  if ($st && $st->echo) {
    $st->echo(0);
    $st->auto_restore(1);
  }

you can write

  my $scope_guard= Crypt::SecretBuffer::ConsoleState->maybe_new(
    handle => $fh,
    auto_restore => 1,
    echo => 0
  );

and if it is not a tty or echo is already off, it returns C<undef> and skips the creation of
the object entirely.

=head1 ATTRIBUTES

=head2 auto_restore

Automatically call C<restore> on object destruction, such as when it goes out of scope.
Boolean, read/write.

=head2 echo

Get or set the C<ECHO> flag on the console/tty.
Boolean, read/write.

=head2 line_input

Get or set the line-buffering feature of the console/tty.  On Windows this is the
C<ENABLE_LINE_INPUT> flag.  On Posix, this is the C<ICANON> flag, with the caveat that disabling
it also enables the C<ISIG> flag so that the OS continues to handle C<^C> for you.
Boolean, read/write.

=head1 METHODS

=head2 restore

Set the console/tty state to the original value seen when the object was created.

=head1 VERSION

version 0.017

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
