package B::CompilerPhase::Hook;
# ABSTRACT: Programatically install BEGIN/CHECK/INIT/UNITCHECK/END blocks

use strict;
use warnings;

our $VERSION;
our $AUTHORITY;

use XSLoader;
BEGIN {
    $VERSION   = '0.04';
    $AUTHORITY = 'cpan:STEVAN';
    XSLoader::load( __PACKAGE__, $VERSION );

    # now set up the DWIM methods ...
    *enqueue_BEGIN     = \&append_BEGIN;
    *enqueue_CHECK     = \&prepend_CHECK;
    *enqueue_INIT      = \&append_INIT;
    *enqueue_UNITCHECK = \&prepend_UNITCHECK;
    *enqueue_END       = \&prepend_END;
}

sub import {
    shift;
    if ( @_ ) {
        my $to   = caller;
        my $from = __PACKAGE__;
        foreach ( @_ ) {
            no strict 'refs';
            *{ $to . '::' . $_ } = $from->can( $_ );
        }
    }
}

1;

__END__

=pod

=head1 NAME

B::CompilerPhase::Hook - Programatically install BEGIN/CHECK/INIT/UNITCHECK/END blocks

=head1 VERSION

version 0.02

=head1 SYNOPSIS

  use B::CompilerPhase::Hook qw[
      enqueue_BEGIN
      enqueue_CHECK
      enqueue_INIT
      enqueue_UNITCHECK
      enqueue_END
  ];

  # We call these functions within BEGIN
  # blocks so that we can be assured they
  # will enqueue properly, see the docs
  # for more info.

  print                         "10. Ordinary code runs at runtime.\n";
  BEGIN {
      enqueue_END       { print "16. So this is the end of the tale.\n" };
      enqueue_INIT      { print " 7. INIT blocks run FIFO just before runtime.\n" };
      enqueue_UNITCHECK { print " 4. And therefore before any CHECK blocks.\n" };
      enqueue_CHECK     { print " 6. So this is the sixth line.\n" }
  }
  print                         "11. It runs in order, of course.\n";
  BEGIN {
      enqueue_BEGIN     { print " 1. BEGIN blocks run FIFO during compilation.\n" }
      enqueue_END       { print "15. Read perlmod for the rest of the story.\n" }
      enqueue_CHECK     { print " 5. CHECK blocks run LIFO after all compilation.\n" }
      enqueue_INIT      { print " 8. Run this again, using Perl's -c switch.\n" }
  }
  print                         "12. This is anti-obfuscated code.\n";
  BEGIN {
      enqueue_END       { print "14. END blocks run LIFO at quitting time.\n" }
      enqueue_BEGIN     { print " 2. So this line comes out second.\n" }
      enqueue_UNITCHECK { print " 3. UNITCHECK blocks run LIFO after each file is compiled.\n" }
      enqueue_INIT      { print " 9. You'll see the difference right away.\n" }
  }
  print                         "13.   It only _looks_ like it should be confusing.\n";

  # With apologies to the `BEGIN-UNITCHECK-CHECK-INIT-and-END` section of `perlmod`

=head1 DESCRIPTION

This module makes it possible to enqueue callbacks to be run during
the various Perl compiler phases, with the aim of doing multi-phase
meta programming in a reasonably clean way.

=head1 FUNCTIONS

These functions either C<push> or C<unshift> onto the respective internal
arrays for that phase. The distinction is there to preserve the FIFO and
LIFO patterns already inherent in the built-in form of compiler phase
hooks.

All of these functions have the C<&> prototype, as such can be called
in block form if desired.

=head2 C<enqueue_BEGIN( $cb )>

This will C<push> the C<$cb> onto the end of the internal
C<BEGIN> array.

=head2 C<enqueue_CHECK( $cb )>

This will C<unshift> the C<$cb> onto the end of the internal
C<CHECK> array.

=head2 C<enqueue_INIT( $cb )>

This will C<push> the C<$cb> onto the end of the internal
C<INIT> array.

=head2 C<enqueue_UNITCHECK( $cb )>

This will C<unshift> the C<$cb> onto the end of the internal
C<UNITCHECK> array.

=head2 C<enqueue_END( $cb )>

This will C<unshift> the C<$cb> onto the end of the internal
C<END> array.

=head1 LOWER LEVEL FUNCTIONS

For each of the phases we have a C<prepend_${phase}> function, which
will C<push> and an C<append_${phase}> function which will C<unshift>.

These should be used with caution and only if you really understand
what you are doing. For most cases you can just use the C<enqueue>
variants above and all will be well.

=head1 SEE ALSO

=over 4

=item L<Devel::Hook>

This module provides C<push> and C<unshift> access to the internal
arrays that hold the set of compiler phase callbacks. It relies on
you to do the right thing when choosing which of the two actions
(C<push> or C<unshift>) to take.

=back

=head1 AUTHOR

Stevan Little <stevan@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Stevan Little.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
