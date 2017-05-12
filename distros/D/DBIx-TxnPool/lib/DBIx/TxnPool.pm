package DBIx::TxnPool;

use strict;
use warnings;
use Exporter 5.57 qw( import );

use Try::Tiny;
use Signal::Mask;
use Carp qw( confess );

our $VERSION = 0.12;
our $BlockSignals = [ qw( TERM INT ) ];
our @EXPORT = qw( txn_item txn_post_item txn_commit txn_sort );

# It's better to look for the "try restarting transaction" string
# because sometime may be happens other error: Lock wait timeout exceeded
use constant DEADLOCK_REGEXP    => qr/try restarting transaction/o;

sub new {
    my ( $class, %args ) = @_;

    confess( "The dbh should be defined" )
      unless $args{dbh};

    $args{size}                   ||= 100;
    $args{block_signals}          ||= $BlockSignals;
    $args{max_repeated_deadlocks} ||= 5;
    $args{_amnt_nested_signals}   = 0;
    $args{_saved_signal_masks}    = {};
    $args{pool}                   = [];
    $args{amount_deadlocks}       = 0;

    $args{repeated_deadlocks}     = 0;

    bless \%args, ref $class || $class;
}

sub DESTROY {
    local $@;

    $_[0]->finish
      unless ( $_[0]->{repeated_deadlocks} >= $_[0]->{max_repeated_deadlocks} );
}

sub txn_item (&@) {
    __PACKAGE__->new( %{ __make_chain( 'item_callback', @_ ) } );
}

sub txn_post_item (&@) {
    __make_chain( 'post_item_callback', @_ );
}

sub txn_commit (&@) {
    __make_chain( 'commit_callback', @_ );
}

sub txn_sort (&@) {
    my $ret = __make_chain( 'sort_callback', @_ );
    $ret->{sort_callback_package} = caller;
    $ret;
}

sub __make_chain {
    my $cb_name = shift;
    my $cb_func = shift;
    my $ret;

    ( $ret = ref $_[0] eq 'HASH' ? $_[0] : { @_ } )->{ $cb_name } = $cb_func;
    $ret;
}

sub dbh { $_[0]->{dbh} }

sub add {
    my ( $self, $data ) = @_;

    confess "assert: _amnt_nested_signals is not zero!"
      if $self->{_amnt_nested_signals};

    try {
        push @{ $self->{pool} }, $data;

        if ( ! $self->{sort_callback} ) {
            $self->start_txn;
            $self->_safe_signals( sub {
                local $_ = $data;
                $self->{item_callback}->( $self, $data );
            } );
        }
    }
    catch {
        $self->_check_deadlock( $_ );
    };

    $self->finish
      if ( @{ $self->{pool} } >= $self->{size} );

    confess "assert: _amnt_nested_signals is not zero!"
      if $self->{_amnt_nested_signals};
}

sub _check_deadlock {
    my ( $self, $error ) = @_;

    my $dbi_error = $DBI::err;

    $self->rollback_txn;

    # For example codes: https://dev.mysql.com/doc/refman/5.5/en/error-messages-server.html
    # MySQL codes 1213 & 1205 are reasons to redo transaction again
    # For other SQL engines i don't know codes - patches are walcome! ;-) [https://github.com/Perlover/DBIx-TxnPool]
    if ( defined $dbi_error && ( $dbi_error == 1213 || $dbi_error == 1205 ) ) {
        $self->{amount_deadlocks}++;
        if ( $self->{repeated_deadlocks} >= $self->{max_repeated_deadlocks} ) {
            $self->{pool} = []; # If DESTROY calls finish() there will not problems
            confess( "limit ($self->{repeated_deadlocks}) of deadlock resolvings" )
        }
        else {
            $self->play_pool;
        }
    } else {
        # Fatal error - may be bad SQL statement - finish
        $self->{pool} = []; # If DESTROY calls finish() there will not problems
        confess( "error in item callback ($error)" );
    }
}

sub play_pool {
    my $self = shift;

    $self->start_txn;

    $self->_safe_signals( sub {
        select( undef, undef, undef, 0.5 * ++$self->{repeated_deadlocks} );
    } );

    try {
        foreach my $data ( @{ $self->{pool} } ) {
            $self->_safe_signals( sub {
                local $_ = $data;
                $self->{item_callback}->( $self, $data );
            } );
        }
    }
    catch {
        $self->_check_deadlock( $_ );
    };
}

sub finish {
    my $self = shift;

    confess "assert: _amnt_nested_signals is not zero!"
      if $self->{_amnt_nested_signals};

    if ( $self->{sort_callback} && @{ $self->{pool} } ) {
        no strict 'refs';
        local *a = *{"$self->{sort_callback_package}\::a"};
        local *b = *{"$self->{sort_callback_package}\::b"};

        $self->{pool} = [ sort { $self->{sort_callback}->() } ( @{ $self->{pool} } ) ];

        $self->play_pool;
    }

    $self->commit_txn;

    if ( exists $self->{post_item_callback} ) {
        foreach my $data ( @{ $self->{pool} } ) {
            local $_ = $data;
            $self->{post_item_callback}->( $self, $data );
        }
    }

    $self->{pool} = [];

    confess "assert: _amnt_nested_signals is not zero!"
      if $self->{_amnt_nested_signals};
}

sub start_txn {
    my $self = shift;

    if ( ! $self->{in_txn} ) {
        $self->_safe_signals( sub {
            $self->{dbh}->begin_work or confess 'DBI error: ' . $self->{dbh}->errstr;
            $self->{in_txn} = 1;
        } );
    }
}

sub rollback_txn {
    my $self = shift;

    if ( $self->{in_txn} ) {
        $self->_safe_signals( sub {
            $self->{dbh}->rollback or confess 'DBI error: ' .  $self->{dbh}->errstr;
            $self->{in_txn} = undef;
        } );
    }
}

sub commit_txn {
    my $self = shift;

    if ( $self->{in_txn} ) {
        try {
            $self->_safe_signals( sub {
                $self->{dbh}->commit or confess 'DBI error: ' .  $self->{dbh}->errstr;
                $self->{in_txn} = undef;
            } );
            1;
        }
        catch {
            $self->_check_deadlock( $_ );
            $self->commit_txn;
            0;
        } or return;

        $self->{repeated_deadlocks} = 0;
        $self->{commit_callback}->( $self )
          if exists $self->{commit_callback};
    }
}

sub amount_deadlocks { $_[0]->{amount_deadlocks} }

sub _safe_signals {
    my ( $self, $code ) = @_;

    if ( ! $self->{_amnt_nested_signals}++ ) {
        for ( @{ $self->{block_signals} } ) {
            $self->{_saved_signal_masks}{ $_ } = $Signal::Mask{ $_ };
            $Signal::Mask{ $_ } = 1;
        }
    }
    try {
        $code->();
    }
    catch {
        die $_;
    }
    finally {
        if ( ! --$self->{_amnt_nested_signals} ) {
            for ( @{ $self->{block_signals} } ) {
                $Signal::Mask{ $_ } = delete $self->{_saved_signal_masks}{ $_ };
            }
        }
    };
}

1;

__END__

=pod

=head1 NAME

DBIx::TxnPool - Massive SQL updates by means of transactions with the deadlock & signal solution

=head1 SYNOPSIS

This module will help to you to make quickly DML statements of InnoDB engine. You can forget about deadlocks ;-)

    use DBIx::TxnPool;

    my $pool = txn_item {
        my ( $pool, $item ) = @_;

        $pool->dbh->do( "UPDATE table SET val=? WHERE key=?", undef, $_->{val}, $_->{key} );
        # or
        $dbh->do("INSERT INTO table SET val=?, key=?", undef, $_->{val}, $_->{key} );
    }
    txn_post_item {
        my ( $pool, $item ) = @_;

        # Here we are if transaction is successful
        unlink( 'some_file_' . $_->{key} );
        # or
        unlink( 'some_file_' . $item->{key} );
    }
    txn_commit {
        my $pool = shift;
        log( 'The commit was here...' );
    } dbh => $dbh, size => 100;

    # Here can be deadlocks but they will be resolved by module
    # and repeated (to see example in xt/03_deadlock_solution.t)
    $pool->add( { key => int( rand(100) ), val => $_ } ) for ( 0 .. 300 );
    $pool->finish;

Or other way:

    my $pool = txn_item {
        $dbh->do( "UPDATE table SET val=? WHERE key=?", undef, $_->{val}, $_->{key} );
    }
    txn_sort {
        $a->{key} <=> $b->{key}
    }
    dbh => $dbh, size => 100;

    # Here no deadlocks because all keys are sorted before transaction:
    # circle blocks inside the InnoDB not occur
    $pool->add( { key => int( rand(100) ), val => $_ } ) for ( 0 .. 300 );
    $pool->finish;

=head1 DESCRIPTION

If you need massive quickly updates or inserts into InnoDB database - this
module for you! It helps to wrap some SQL manipulation statements to one
transaction and has the deadlock and signal solution.

=head1 DETAILS

If you make alone insert/delete/update statement in the InnoDB engine, MySQL
server does fsync (data flushing to disk) after each statement. It can be very
slow for many updates. The best solution can be to wrap some
insert/delete/update statements in one transaction for example. But this raises
a new problem - deadlocks. If a deadlock occurs a DBI module throws exceptions
and ideal way to repeat SQL statements again. This module helps to make it. It
has a pool inside for data (FIFO buffer) and calls your callbacks for each
pushed item. When your pool to be fed by your data, it wraps data in one
transaction up to the maximum defined size or up to the finish method. If
deadlock occurs a pool repeats your callbacks for every item again. You can
define a second callback which will be executed for every item after wrapped
transaction. For example there can be non-SQL statements, for example a deleting
files, cleanups and etc.

=head1 CONSTRUCTOR

Please to see L</SYNOPSIS> section

=head2 Shortcuts:

The C<txn_item> should be first. Other sortcuts can follow in any order.
Parameters should be the last.

=over

=item txn_item B<(Required)>

The transaction item callback. There should be SQL statements and code should be safe for repeating (when a deadlock
occurs). The C<$_> consists a current item. You can modify it if one is hashref for example. Passing arguments will be
I<DBIx::TxnPool> object and I<current item> respectively. B<Please don't catch exceptions here (by try{} or eval{} for
example)> - by this way deadlocks are defined outside under the hood!

=item txn_sort B<(Optional)>

Here you can define sort function for your data before a transaction will be
made. If you have only one type SQL statement in L<txn_item|/"txn_item
(Required)"> but you didn't sort keys before transaction you can have deadlocks
(they will be resolved and transaction will be repeated but you will lose a
processing time) unless you define this function. This method minimize deadlock
events!

=item txn_post_item B<(Optional)>

The post transaction item callback. This code will be executed once for each item (defined in C<$_>). It is located
outside of the transaction. And it will be called if whole transaction was successful. Passing arguments are
I<DBIx::TxnPool> object and I<current item> respectively. You can do here your own error handling in callback. If your
code here will throw an excetption it will be propagated above.

=item txn_commit B<(Optional)>

This callback will be called after each SQL commit statement. Here you can put
code for logging for example. The first argument is I<DBIx::TxnPool> object

=back

=head2 Parameters:

=over

=item dbh B<(Required)>

The dbh to be needed for begin_work & commit method (wrap in a transaction).

=item size B<(Optional)>

The size of pool when a commit method will be called when feeding reaches the same size.

=item block_signals B<(Optional)>

An arrayref of signals (strings) which should be blocked in slippery places for
this I<pool>. Defaults are [ qw( TERM INT ) ]. You can change globaly this list
by setting: C<< $DBIx::TxnPool::BlockSignals = [ qw( TERM INT ALARM ... ) ] >>.
For details to see here L</"SIGNAL HANDLING">

=item max_repeated_deadlocks B<(Optional)>

The limit of consecutive deadlocks. The default is 5. After limit to be reached
the L</add> throws exception.

=back

=head1 METHODS

=over

=item add

You can add item of data to the pool. This method makes a wrap to transaction.
It can finish transaction if pool reaches up to size or can repeat a whole
transaction again if deadlock exception was thrown. The size of transaction may
be less than your defined size!

=item dbh

The accessor of C<dbh>. It's readonly.

=item finish

It makes a final transaction if pool is not empty.

=item amount_deadlocks

The amount of deadlocks (repeated transactions)

=back

=head1 SIGNAL HANDLING

In DBD::mysql and may be in other DB drivers there is a some bad behavior the
bug as i think. If a some signal will arrive (TERM, INT and other) in your
program during a some SQL socket work this driver throws an exception like
"MySQL lost connection". It happens because the C<recv> or C<read> system calls
into MySQL driver return with error code C<EINTR> if signal arrives inside this
system call. A right written software should recall a system call again because
the C<EINTR> is not fatal error. But i think MySQL driver decides this error as
I<lost connection error>. I<"Deferred Signals"> (or L<Safe
Signals|perlipc/"Deferred Signals (Safe Signals)">) of perl don't help because
the MySQL driver uses direct system calls.

Workaround is to use L<Signal::Mask> module for example and to block these
signals (TERM / INT) during working with DBI subroutines. The version 0.09 of
C<DBIx::TxnPool> has helpers for this. The C<DBIx::TxnPool> wraps all slippery
places by blocking your preferred signals (defaults are C<TERM> & C<INT> ones)
before entering and by unblocking after (for example the callback handler
L<txn_item|/"txn_item (Required)"> and transaction code). This should minimize
raised errors like the "MySQL lost connection".

=head1 AUTHOR

This module has been written by Perlover <perlover@perlover.com>

=head1 LICENSE

This module is free software and is published under the same terms as Perl
itself.

=head1 SEE ALSO

L<DBI>, L<Deadlock Detection and Rollback|http://dev.mysql.com/doc/refman/5.5/en/innodb-deadlock-detection.html>

=head1 TODO

=over

=item A supporting DBIx::Connector object instead DBI

=back

=cut
