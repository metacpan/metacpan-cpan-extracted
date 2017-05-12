package DBI::Transaction::Repeated;

use strict;
use vars qw($VERSION);

$VERSION = 0.101;

use Exporter;
use vars qw(@ISA @EXPORT_OK);
push @ISA, 'Exporter';
@EXPORT_OK = qw(&repeat_transaction
                &ERR_OK &ERR_REPEAT &ERR_FAILED &ERR_REPEAT_EXCEEDED);

use DBI::Transaction;

use vars qw($MAX_REPEAT);
$MAX_REPEAT = 100;

use constant ERR_OK              => {};
use constant ERR_CANNOT_ROLL     => {};
use constant ERR_REPEAT          => {};
use constant ERR_DBI_FAILED      => {};
use constant ERR_FAILED          => {};
use constant ERR_REPEAT_EXCEEDED => {};

sub new {
  my $class    = shift;
  my $dbh      = shift;
  my $callback = shift;
  my @named    = @_;

  my $self = {
    DBH => $dbh,
    CALLBACK => $callback,
    _COUNT => $MAX_REPEAT,
    _ARGS => [],
    PrintDeadlockWarn => $dbh->{PrintWarn}
  };
  die __PACKAGE__ . "::new: Wrong arguments." if @named % 2;
  while(@named) {
    my $id = shift @named;
    die __PACKAGE__ . "::new: Wrong arguments." if $id !~ /^-/;
    if($id eq '-count') {
      $self->{_COUNT} = shift @named;
    } elsif($id eq '-args') {
      $self->{_ARGS} = shift @named;
    } elsif($id eq '-PrintDeadlockErrors') {
      $self->{PrintDeadlockErrors} = shift @named;
    }
  }
  return bless $self, $class;
}

sub repeat_transaction {
  my $class = UNIVERSAL::isa($_[0], __PACKAGE__) ? shift : __PACKAGE__;

  return $class->new(@_)->run;
}

sub step {
  my $self = shift;

  my $dbh = $self->{DBH};

  my $T = DBI::Transaction->start($dbh);
  return ERR_DBI_FAILED unless $T;
  my $r = eval { &{$self->{CALLBACK}}($dbh, @{$self->{_ARGS}}) };
  local $dbh->{RaiseError} = 0;
  #local $dbh->{PrintError} = 0;
  if($r == ERR_REPEAT) {
    $T->rollback
      or # TODO: Broken API?..
    return UNIVERSAL::isa($dbh->errstr, "DBI::Transaction::CannotRollback")
      ? ERR_CANNOT_ROLL : ERR_DBI_FAILED;
  } elsif($r == ERR_OK) {
    if($self->{_COUNT} != 1 && !$self->{PrintDeadlockWarn}) {
      local $dbh->{PrintError} = 0;
      return ERR_OK if $T->commit;
    } else {
      return ERR_OK if $T->commit;
    }
  } else {
    if(!$T->rollback) { # Rollback failed counted as more serious error than callback failed
      return UNIVERSAL::isa($dbh->errstr, "DBI::Transaction::CannotRollback")
        ? ERR_CANNOT_ROLL : ERR_DBI_FAILED;
    }
    return ERR_FAILED;
  }

  return ERR_REPEAT unless $self->{_COUNT};
  --$self->{_COUNT};
  return $self->{_COUNT} ? ERR_REPEAT : ERR_REPEAT_EXCEEDED;
}

sub run {
  my $self = shift;

  my $err;
  1 while ($err = $self->step) == ERR_REPEAT;
  return $err;
}

1; # DBI::Transaction::Repeated;

__END__

=head1 NAME

DBI::Transaction::Repeated - repeat database transaction until success.

=head1 PURPOSE

Some database systems (e.g. InnoDB engine of MySQL) do not warrant that
any particular transaction will succeed because it may collide with
concurrent transactions. Documentation suggest to repeat a transaction
until it will succeed.

This module accomplishes repeating a transaction until success.

=head1 SYNOPSIS

 use DBI::Transaction::Repeated qw(repeat_transaction ERR_OK);

 $DBI::Transaction::Repeated::MAX_REPEAT = 20;

 sub do_transaction {
   my $dbh = shift;
   $dbh->do("INSERT INTO table SET x=23");
   return ERR_OK;
 }

 $err = repeat_transaction($dbh, \&do_transaction);
 die "Transaction failed." unless $err = ERR_OK;

=head1 CAVEATS

=over

=item

This package currently ignores $dbh->{RaiseError} (sets it to false
during transactional operations). So it should never throw exceptions.

However the callback is called with unchanged {RaiseError} (that value
of $dbh->{RaiseError} which was before calling a routine from this package).

=item

Any subtransaction embedded into an other transaction may fail with
ERR_CANNOT_ROLL.

If you get this error, you should try to roll back an upper level
transaction.

=item

See L<DBI::Transaction(3)> about problems with MySQL

=back

=head1 DESCRIPTION

=over

=item new()

  DBI::Transaction::Repeat->new($dbh, \&callback,
                                -count => 100,
                                -args => [...],
                                -PrintDeadlockErrors=>(0|1))

Named parameters are optional.

'count' is maximum number of attempts (default $MAX_REPEAT),

'args' is array of additional arguments to pass to the callback.

If 'PrintDeadlockErrors' is true, this package will warn about
deadlocks even if the transaction succeeded on a following attempt.
If omitted, 'PrintDeadlockErrors' is set to $dbh->{PrintWarn} (see L<DBI(3)>).

Callback is called with $dbh as the first argument.

Callback must return ERR_OK to indicate success, or ERR_REPEAT to
ask to repeat it more. Any other value or throwing an exception from
the callback is considered as a failure (ERR_FAILURE).

=item run()

Run the transaction maximum $MAX_REPEAT times.

TODO: Currently run() must be called no more than once on the same
DBI::Transaction::Repeat object. Should be allowed to call it
multiple times,.

=item repeat_transaction()

It is called with the same arguments as new() and is equivalent to

  DBI::Transaction::Repeat->new(@_)->run;

repeat_transaction() can be called either as a normal routine or a method.

=item step()

Make one step (TODO).

=item $MAX_REPEAT

The maximum number of repeats attempted.

Currently it is 100 by default.

=back

=head1 ERROR CODES

=over

=item ERR_OK

No error.

=item ERR_CANNOT_ROLL

Attempt to roll back a subtransaction failed. Try to roll back an upper
level transaction.

=item ERR_REPEAT

(Can be returned only by step() method.) Try again.

=item ERR_DBI_FAILED

L<DBI(3)> failed while attempting to commit, roll back, or start transaction.

=item ERR_FAILED

Transaction callback failed (not returned ERR_OK).

=item ERR_REPEAT_EXCEEDED

Transaction was tried $MAX_REPEAT times without success.

=back

=head1 AUTHOR

The original author Victor Porton <porton@ex-code.com> will gladly hear
your bug reports.

Module's homepage: http://ex-code.com/dbi-transactions/

=head1 LICENSE

General Public License version 2 (see also module's homepage).

=head1 SEE ALSO

L<DBI(3)>, L<DBI::Transaction(3)>
