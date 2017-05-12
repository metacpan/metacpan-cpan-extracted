package DBIx::PgLink::Adapter::Roles::Reconnect;

# based on DBIx::RetryOverDisconnects by Oleg Pronin <syber@cpan.org>

use Moose::Role;
use DBIx::PgLink::Logger;

our $VERSION   = '0.01';

requires 'is_disconnected';
requires 'is_transaction_active';

has 'reconnect_retries'  => ( is => 'rw', isa => 'Int', lazy => 1, default => 3 ); # times
has 'reconnect_interval' => ( is => 'rw', isa => 'Int', lazy => 1, default => 5 ); # seconds
has 'reconnect_timeout'  => ( is => 'rw', isa => 'Int', lazy => 1, default => 5 ); # seconds


override 'dbi_method' => sub {
  my $self = shift;
  my $dbi_handle = shift; # dbh or sth
  my $func_name = shift;
  my $wa = wantarray;
  my ($retval, @retval);
  # super method is never called! this method must be installed on top
  while (1) {
    my $ok = eval {
      # critical: do not try execute Class::MOP method here!
      # second try cause a core dump
      defined $wa ? $wa ? ( @retval = $dbi_handle->$func_name(@_) )
                        : ( $retval = $dbi_handle->$func_name(@_) )
                        :             $dbi_handle->$func_name(@_);
      1;
    };
    last if $ok;
    my $exception = $@;
    my $in_trans = $self->is_transaction_active;
    return unless $self->check_connection_error($exception);
    die $exception if $in_trans;
  }
  return $wa ? @retval : $retval;
};


sub check_connection_error {
  my $self = shift;
  my $exception = shift;
  if (!defined $exception || $exception eq '') {
    # no operation performed yet, execute valid SQL statement and check for error
    return 1 if $self->ping; # no disconnection
    if ($self->can('always_valid_query')) {
      eval { $self->dbh->do($self->always_valid_query) }; # no ping, try simple query
      $exception = $@;
    }
    return 2 unless defined $exception; # hmm, no ping, but query ok
  }
  die $exception unless $self->is_disconnected($exception); # 'normal' database error
  trace_msg('WARNING', $exception);
  return $self->reconnect;
}


sub reconnect {
  my $self = shift;
  my $try_num = 0;
  my $dbh = $self->dbh;
  my $new_dbh;
  TRY:
  while ($try_num++ < $self->reconnect_retries) {
    trace_msg('INFO', "Reconnect try #$try_num");
    if ($self->reconnect_timeout) {
      # TODO: check signal handling in plperl on different platforms
      local $SIG{ALRM} = sub {
        alarm(0);
        trace_msg('WARNING', "Connection timed out");
        die "Connection timed out";
      };
      eval {
        alarm($self->reconnect_timeout);
        eval {
          $new_dbh = $dbh->clone;
        };
        alarm(0);
      };
    } else { # no timeout
        eval {
          $new_dbh = $dbh->clone;
        };
        trace_msg('WARNING', "Reconnect try #$try_num failed: $@") if $@;
    }
    if ($new_dbh) {
      trace_msg('INFO', "Reconnected");
      last TRY;
    }
    sleep $self->reconnect_interval;
  }
  unless ($new_dbh) {
    $dbh->disconnect;
    trace_msg('ERROR', "Unrecoverable connection loss");
    die "Unrecoverable connection loss", $@;
  }

  # --------------------------------------- DBI handles black magic

  $dbh->swap_inner_handle($new_dbh);
  $new_dbh->STORE('Active', 0);

  #refresh all prepared statements

  my $cnt = 0;
  for my $sth (@{$new_dbh->{ChildHandles}}) {
    next unless defined $sth;
    my $new_sth = $dbh->prepare($sth->{Statement});
    $sth->swap_inner_handle($new_sth, 1);
    $new_sth->finish;
    $cnt++;
  }
  trace_msg('INFO', "Statements prepared: $cnt");

  $dbh->{ChildHandles} = $new_dbh->{ChildHandles};
  $dbh->{CachedKids} = $new_dbh->{CachedKids};

  $new_dbh->disconnect;

  $self->initialize_session if $self->can('initialize_session');

  return 1;
}


1;


__END__

=pod

=head1 NAME

DBIx::PgLink::Roles::Reconnect - detect connection loss, reconnect and restart DBI call

=head1 DESCRIPTION

The role wraps some calls to DBI methods so that operation that fails 
due to connection break ( server shutdown, network troubles, etc), 
is automatically reconnected.

Failed operation will be repeated if AutoCommit mode on (no transaction). 
If transaction in progress than exception always raised, but connection has restored anyway.

=head1 REQUIREMENTS

DBI calls that needs protection must be executed via C<dbi_method>
in base Adapter class.

Adapter class that does the role B<must> implement following methods: 

=over

=item is_disconnected

Must check supplied exception and return true value for disconnection error 
and false for any 'normal' database error.


=item is_transaction_active

Must return true if there is transaction in progress.

=back

Adapter class B<may> implement following methods: 

=over

=item always_valid_query

Return SQL query that always executed successfully ('SELECT 1').

=item initialize_session

Restore database session state (SET options, create temporary tables, etc).

=back


=head1 METHODS

=over

=item dbi_method

    $self->dbi_method($handle, $func_name, @_)

Execute $func_name method of $handle object (DBI database or statement handle). 
Check for disconnection error, reconnect and retry the function (unless in transaction).

=item check_connection_error

    $self->check_connection_error($exception)

Check if $exception is disconnection error and try to reconnect.
If not $exception specified, can execute C<always_valid_query> SQL query 
to ensure the valid connection status.

=item reconnect

    $self->reconnect

Try to reconnect C<reconnect_retries> times with C<reconnect_interval> pause between attempts.
Die if connection cannot be established or timed out.

=back


=head1 ATTRIBUTES

=over

=item reconnect_retries

Max number of tries before giving up.

Default: 3

=item reconnect_interval

Seconds to sleep after reconnection attempt fails

Default: 5

=item reconnect_timeout

Timeout (in seconds) for waiting the database to accept connection.

Default: 5

=back


=head1 CAVEATS

=over

=item All prepared statements are re-prepared at once, may cause heavy load

=item Transaction retry does not implemented

=back


=head1 TODO

Lazy prepare after reconnect (install subrole to Adapter::st)

Test reconnect timeout (SIGALRM) on different platforms

=head1 AUTHOR

Alexey Sharafutdinov E<lt>alexey.s.v.br@gmail.comE<gt>

Based on L<DBIx::RetryOverDisconnects> module by Oleg Pronin <syber@cpan.org>

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

