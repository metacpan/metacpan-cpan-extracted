package DBIx::Loop::Loop::Hyperman;

use 5.008003;
use strict;
use warnings;

use DBIx::Loop ();   # the XS bootstrap defines this package's methods

our $VERSION = '0.01';

1;

__END__

=head1 NAME

DBIx::Loop::Loop::Hyperman - drive DBIx::Loop on a Hyperman event loop, in C

=head1 SYNOPSIS

    use Hyperman;                       # must be loaded first (runtime ABI)
    use DBIx::Loop;
    use DBIx::Loop::Loop::Hyperman;

    my $adapter = DBIx::Loop::Loop::Hyperman->new;   # or (loop => $hm_loop)
    my $db = DBIx::Loop->connect($dsn, $u, $p, \%attr, loop => $adapter);

    my $f = $db->query("SELECT ...");
    $adapter->await($f);           # run the loop until ready
    my $res = ($f->get)[0];

=head1 DESCRIPTION

The pure-XS loop adapter for L<Hyperman>. It implements the DBIx::Loop loop
seam (C<add_reader>, C<add_writer>, C<remove>, C<timer>, C<new_future>) plus
C<await> and C<cancel_timer>, entirely in C over Hyperman's public C ABI
(resolved at runtime through C<Hyperman::_abi_ptr> - Hyperman is never a
build-time dependency). It also carries an internal C vtable, so DBIx::Loop
backends dispatch worker-fd readiness C-to-C with no Perl call frame on the
hot path.

C<new_future> returns a pending L<Hyperman::Future>, the native future of the
Hyperman ecosystem. C<await> pumps the loop until the future settles and
accepts both Hyperman futures and L<DBIx::Loop::Future>s (bridged in C).

C<new> takes an optional C<< loop => $hyperman_loop >>; without one it uses
the currently running Hyperman loop (inside a worker) or creates a fresh
C<Hyperman::Loop>. Loading L<Hyperman> before constructing the adapter is
required; without it C<new> croaks.

C<timer($after, $cb)> returns a handle; C<cancel_timer($handle)> cancels a
timer that has not fired yet. Never cancel a timer after its callback ran -
the handle dies with the fire.

=head1 SEE ALSO

L<DBIx::Loop>, L<DBIx::Loop::Loop::IOAsync>, L<Hyperman>

=head1 AUTHOR

LNATION <email@lnation.org>

=cut
