package DBI::Transaction;

use strict;
use vars qw($VERSION);

$VERSION = 0.101;

use DBI();

sub start {
  my $class = shift;
  my $dbh   = shift;

  my $self = {
    DBH => $dbh,
    # 0 - finished, 1 - not finished, no need for commit, 2 - needs commit:
    _STATE => $dbh->{AutoCommit} ? 2 : 1
  };
  bless $self, $class;
  if($dbh->{AutoCommit}) {
    local $dbh->{HandleSetErr} = _handle_set_err("new");
    $dbh->begin_work or return undef;
  }
  return $self;
}

sub DESTROY {
  my $self = shift;

  return unless $self->{_STATE};
  my $dbh = $self->{DBH};

  # Crude hack against segfaults in
  # Perl 5.8.4 for i386-linux-thread-multi + DBI 1.41 + DBD::mysql 2.9003
  # Scripts are like:
  # use DBI; use DBI::Transaction;
  # $dbh=DBI->connect("DBI:mysql:database=XXX","XXX","XXX",{AutoCommit=>0});
  # $t=DBI::Transaction->start($dbh);
  return unless $dbh && ref($dbh) && tied($dbh) && $dbh->{Active};

  local $dbh->{HandleSetErr} = _handle_set_err("DESTROY");
  $dbh->set_err(0, "Unfinished transaction - may cause subtle bugs!");
  if($self->{_STATE} == 2) {
    #local $dbh->{RaiseError}; # TODO: What it should be?
    $self->{DBH}->rollback;
  } else {
    local $dbh->{PrintError} = 0;
    $dbh->set_err(1, DBI::Transaction::CannotRollback->new);
  }
}

sub _handle_set_err {
  my $method = shift;

  my $id = __PACKAGE__ . '::' . $method;
  return sub { $_[4] = $id; 0 };
}

sub commit {
  my $self = shift;

  my $dbh = $self->{DBH};
  local $dbh->{HandleSetErr} = _handle_set_err("commit");
  my $st = $self->{_STATE};
  if(!$st) {
    $dbh->set_err(1, "Attempt to commit a finished transaction.");
    return undef;
  }
  $self->{_STATE} = 0; # Want to prevent DESTROY warning.
  my $ret = $st == 2 ? $dbh->commit : 1;
  delete $self->{DBH}; # See DESTROY about the bug
  return $ret;
}

sub rollback {
  my $self = shift;

  my $dbh = $self->{DBH};
  local $dbh->{HandleSetErr} = _handle_set_err("commit");
  my $st = $self->{_STATE};
  if(!$st) {
    $dbh->set_err(1, "Attempt to roll back a finished transaction.");
    return undef;
  }
  $self->{_STATE} = 0; # Want to prevent DESTROY warning.
  return $dbh->rollback if $st == 2;
  local $dbh->{PrintError} = 0;
  $dbh->set_err(1, DBI::Transaction::CannotRollback->new);
  delete $self->{DBH}; # See DESTROY about the bug
  return undef;
}

sub is_finished {
  my $self = shift;

  return !$self->{_STATE};
}

1; # DBI::Transaction

# This exception is ONLY for the case when a subtransaction cannot
# be rolled back becuase it is a subtransaction, not for e.g.
# broken DB connection during rollback.
package DBI::Transaction::CannotRollback;
use overload '""' => sub { "(Sub)transaction cannot be rolled back." };
sub new { return bless {}, shift; }
1; # DBI::Transaction::CannotRollback

__END__

=head1 NAME

DBI::Transaction - advanced object-oriented support for database transactions

=head1 DOCUMENTATION STATE

Docs are incomplete and wrong!

=head1 PURPOSE

DBI::Transaction allows several transactions to be embedded inside each
other (but see CAVEATS about problems with rolling back).

This is inevitable for modular development to allow modules automatically
utilize transactions.

=head1 SYNOPSIS

 use DBI::Transaction;

 $transaction = DBI::Transaction->new($dbh);

 # ...

 $transaction->commit;
 # or
 $transaction->rollback; # See below for caveats.

=head1 CAVEATS

=over

=item

See below about destroying.

=item

When several transactions are embedded in each other, attempt
to rollback an inner transaction may throw an CannotRollback.

In this case you should rollback the entire upper level transaction.

=item

At least in MySQL (L<DBD::mysql(3)>) driver, connectiong with AutoCommit=>1
causes this module to commit three times rather than once! This is a bug
in L<DBD::mysql(3)>. So use AutoCommit=>0 and manually commit the uttermost
transaction:

  $transaction = DBI::Transaction->new($dbh);
  # ...
  $transaction->commit;
  $dbh->commit;

$dbh->commit should not be called if was rollback CannotRollback... XXX.
So, upper level transaction should be handled so (in MySQL):

  $transaction = DBI::Transaction->new($dbh);
  # ...
  $transaction->commit;
  $dbh->disconnect;

=item

When a library routine may call rollback() method from this class,
this routine documentation should document that it calls it.
The caller must trap the DBI::Transaction::CannotRollback, and (usually)
roll back parent transactions in response on this CannotRollback.

=back

=head1 DESTROYING

A transaction must be explicitly either commited or rolled back.
Otherwise destroying it will throw an CannotRollback (see below).

Destroying a not finished transaction is considered as an error
(TODO: Shouldn't we make it fatal?) and it meant only for debugging.

Destroying a not finished transaction attempts to roll back it
before throwing the CannotRollback. But roll back may fail for the
case of a subtransaction. (This useally signifies the need to roll
back its parent transaction.)

=head1 DESCRIPTION

See L<DBI(3)> for descriptions of database handles ($dbh).

=over

=item DBI::Transaction->new()

 $transaction = DBI::Transaction->new($dbh);

This starts a transaction.

=item commit()

Commits and finishes the transaction. Returns true on success.

=item rollback()

Rolls back and finishes the transaction. Returns true on success.

=item is_finished()

Returns false after commit or rollback,

=item DBI::Transaction::CannotRollback

Exception for rolling back a transaction failed because it was a
subtransaction of an other transaction.

=back

=head1 RATIONALE

This module may seem to be over-sophisticated as we
can use just

  local $dbh->{AutoCommit} = 0;

But because of L<DBI(3)> design deficiencies, we really need this module
and it cannot be made simpler than it is without making it broken (at least
without changing L<DBI(3)> itself).

=head1 SUGGESTIONS

DESTROY of not finished transaction is only a debugging mean.
You should not rely on its behavior.

If some routine may call $transaction->rollback() you should
wrap this routine with "eval" unless it is the uttermost level transaction.

=head1 TODO

Docs are incomplete.

"Rollback to savepoint" feature of some SQL engines (e.g. MySQL) is not
utilized.

=head1 AUTHOR

The original author Victor Porton <porton@ex-code.com> will gladly hear
your bug reports.

Module's homepage: http://ex-code.com/dbi-transactions/

=head1 LICENSE

General Public License version 2 (see also module's homepage).

=head1 SEE ALSO

L<DBI(3)>, L<DBI::Transaction::Repeated(3)>
