package DBIx::Async::Worker::SQLite;
$DBIx::Async::Worker::SQLite::VERSION = '0.003';
use strict;
use warnings;

use parent qw(DBIx::Async::Worker);

use constant DEBUG => 0;

# Just a no-op, if anything this should be configurable behaviour.
sub setup {
	my $self = shift;
	my $dbh = $self->dbh;
	if(0) {
		# This doesn't really serve any valid purpose with
		# sqlite running in a separate process, but it
		# can make writes more predictable.
		warn "Enable journal mode...\n" if DEBUG;
		$dbh->do(q{PRAGMA journal_mode=WAL});
		warn "Disable autocheckpoint...\n" if DEBUG;
		$dbh->do(q{PRAGMA wal_autocheckpoint=0});
		warn "Switch to sync=NORMAL...\n" if DEBUG;
		$dbh->do(q{PRAGMA synchronous=NORMAL});

		$dbh->sqlite_commit_hook(sub {
			warn "Manual checkpoint...\n" if DEBUG;
			my $sth = $dbh->prepare(q{PRAGMA wal_checkpoint(FULL)});
			$sth->execute;
			while(my $row = $sth->fetchrow_arrayref) {
				warn "Checkpoint result: @$row\n" if DEBUG;
			}
			warn "Done\n" if DEBUG;
			0
		});
	}
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@perlsite.co.uk>

=head1 LICENSE

Copyright Tom Molesworth 2012-2015. Licensed under the same terms as Perl itself.

