package DBIO::MySQL::MariaDBForkGuard;
# ABSTRACT: keep a forked child's exit from closing DBD::MariaDB connections it inherited

use strict;
use warnings;

our $VERSION = '0.900004';

# Set once, to the pid that installed the guard. The wrapper compares against it.
my $OWNER;



sub install {
  return 1 if defined $OWNER;

  return 0 unless eval { require DBD::MariaDB; 1 };

  my $original = DBD::MariaDB::dr->can('disconnect_all') or return 0;

  $OWNER = $$;

  no warnings 'redefine';
  no strict 'refs';
  *{'DBD::MariaDB::dr::disconnect_all'} = sub {
    return 1 if $$ != $OWNER;
    goto &$original;
  };

  return 1;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MySQL::MariaDBForkGuard - keep a forked child's exit from closing DBD::MariaDB connections it inherited

=head1 VERSION

version 0.900004

=head1 SYNOPSIS

  DBIO::MySQL::MariaDBForkGuard->install;

Nothing calls this by hand: the sync storage and the C<future_io> transport
install it after every connect that belongs to L<DBD::MariaDB>.

=head1 DESCRIPTION

L<DBI>'s C<END> block calls C<< DBI->disconnect_all >> at every normal exit.
L<DBD::MariaDB> (measured with 1.24) carries that out on every connection it
lists, whatever C<InactiveDestroy> or C<AutoInactiveDestroy> say. In a forked
child that is every connection the child inherited from its parent: the close
sends C<COM_QUIT> down the socket both processes share, and the server ends the
parent's session. Where a handle had already been destroyed under
C<AutoInactiveDestroy> but is still listed, the same call instead dies in a DBI
C<active kids> panic and the child's exit status becomes 22. L<DBD::mysql> has
no such C<disconnect_all> and is not affected. The report for DBD::MariaDB is
drafted in F<docs/upstream/dbd-mariadb-disconnect-all-after-fork.md> and not
sent; this class is the workaround (this dist's ADR 0009).

=head1 METHODS

=head2 install

  DBIO::MySQL::MariaDBForkGuard->install;

Load L<DBD::MariaDB> and wrap its C<disconnect_all>. Idempotent: a second call,
from any process, changes nothing -- the owner stays the first installer.
Returns true when the guard is in place, false when L<DBD::MariaDB> cannot be
loaded.

=head1 WHAT IT DOES

C<install> wraps C<DBD::MariaDB::dr::disconnect_all>. In the process that
installed the guard the wrapper hands over to the original, unchanged. In any
other process -- a forked child, however deep -- it does nothing: closing a
connection inherited across a fork is never right.

This is process-wide and covers every L<DBD::MariaDB> handle of the process,
not only the ones DBIO opened. Two consequences, both deliberate:

=over 4

=item * A connection a child opens B<itself> is not closed by
C<disconnect_all> either. Its C<DESTROY> closes it (the handle was created in
that process, so C<AutoInactiveDestroy> does not skip it), and so does an
explicit C<disconnect>.

=item * The guard is installed by the first DBIO connect over L<DBD::MariaDB>,
so it must happen before the fork for the child to have it. A process that
forks first and only then opens its first DBIO connection is the installer and
treats its own pid as the owner.

=back

It changes no C<@ISA> and no C<connection()> hook: the wrapped sub is replaced
in the DBD's own package, once.

=head1 SEE ALSO

=pod

=over 4

=item * L<DBIO::MySQL::Storage> - installs it from C<_run_connection_actions>

=item * L<DBIO::MySQL::Storage::Async> - installs it from C<_mysql_connect>

=back

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
