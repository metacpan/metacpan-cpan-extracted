package DBIx::Loop::Future;

use 5.008003;
use strict;
use warnings;
use DBIx::Loop;

our $VERSION = '0.05';


1;

__END__

=head1 NAME

DBIx::Loop::Future - the canonical future for DBIx::Loop

=head1 DESCRIPTION

A minimal, one-shot future. The hot primitives (C<new>, C<done>, C<fail>,
C<on_ready>, C<is_ready>, C<is_done>, C<is_failed>, C<failure>, C<get>) are
implemented in C, and so are C<then> and C<else>: a continuation is an array
on the future's own callback queue rather than a compiled closure, so settling
a chain runs no Perl frame except your own callbacks.

This is the future DBIx::Loop returns on loops that have no native future
(AnyEvent, POE). On loops that do (IO::Async C<Future>, Mojo C<Mojo::Promise>,
Hyperman C<hmf>), the loop adapter's future factory returns that native type
instead. See L<DBIx::Loop>.

C<get> returns the result only once the future is ready; awaiting a pending
future is the event loop's job, not the future's.

=head1 AUTHOR

LNATION <email@lnation.org>

=cut
