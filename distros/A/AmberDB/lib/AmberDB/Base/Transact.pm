package AmberDB::Base::Transact;

use 5.016;
use warnings;
use Carp qw(croak cluck);
use Fcntl qw(:flock);
use IO::Handle;

our $VERSION = '5.25.1';

my $CREATED = '2026-08-11';

# Journal field separator — ASCII Record Separator (0x1E).
# Tab cannot be used because raw DB values contain literal tabs.
my $TXN_SEP = "\x1e";

# $adb->transact_error($file_path, $message);
# -
# Records a file/write error during database operations.
# Tags with txn_id if transaction is active.
# Base table write errors (matching configured .$db_ext) trigger immediate rollback
# unless configured with 'no_transact => 1'.
# Secondary files (.inx, .src, .fld, .fac, .slg, etc.) do NOT trigger rollback.
# -
sub transact_error {
    my ( $self, $file_path, $message ) = @_;

    return unless defined $file_path && length $file_path;
    $message ||= "database write error";

    my $db_ext = $self->{db_ext} || "db";
    my $no_rollback = 1;

    # Veri tablosu dosyasi kontrolu: dosya yolu .$db_ext ile bitiyorsa ana tablodur
    if ( my ($t_name) = $file_path =~ m{([^/\\:]+)\.\Q$db_ext\E$} ) {
        my $t_info = eval { $self->table_info($t_name) };
        $no_rollback = ( $t_info && $t_info->{no_transact} ) ? 1 : 0;
    }

    my $error = {
        context     => $file_path,
        message     => $message,
        txn_id      => ( $self->{_txn} && $self->{_txn}->{file} ) || undef,
        no_rollback => $no_rollback ? 1 : 0,
    };

    push @{ $self->{_error} ||= [] }, $error;
    shift @{ $self->{_error} } if @{ $self->{_error} } > 100;

    unless ( $error->{no_rollback} ) {
        cluck "[DB_TXN_ERROR] $file_path: $message\n";
        if ( $self->{_txn} && $self->{_txn}->{active} ) {
            return $self->transact_rollback();
        }
    }

    return;
}

# $ok = $adb->is_transact([$tableid]);
# ------------------------------------------------
# Returns 1 if transaction is active and table is eligible (not no_transact).
# Caches eligibility per table in $self->{_txn}->{tbl_enabled} during active transaction.
# ------------------------------------------------
sub is_transact {
    my ( $self, $tableid ) = @_;

    return 0 if $self->{_no_txn};

    my $txn = $self->{_txn};
    return 0 unless $txn && $txn->{active};
    return 1 unless defined $tableid && length($tableid);

    if ( exists $txn->{tbl_enabled}->{$tableid} ) {
        return $txn->{tbl_enabled}->{$tableid};
    }

    my $t_info = eval { $self->table_info($tableid) };
    my $is_enabled = ( $t_info && $t_info->{no_transact} ) ? 0 : 1;

    $txn->{tbl_enabled}->{$tableid} = $is_enabled;
    return $is_enabled;
}

# $adb->transact_start();
# -
# Starts a new transaction. Opens a journal file for undo logging.
# Applies non-blocking exclusive flock to claim ownership.
# Must be paired with transact_end() or transact_rollback().
# -
sub transact_start {
    my ( $self ) = @_;

    if ( $self->{_txn} && $self->{_txn}->{active} ) {
        $self->transact_error( $self->{_txn}->{file} || "txn", "Transaction already active: $self->{_txn}->{file}" );
        return;
    }

    # Recover orphaned transactions from previous crashes
    $self->transact_recover();

    my $journal_dir = $self->journal_dir();
    unless ( -d $journal_dir ) {
        $self->transact_error( $journal_dir, "Transaction directory does not exist: $journal_dir" );
        return;
    }

    our $TXN_SEQ;
    $TXN_SEQ = 0 unless defined $TXN_SEQ;
    my $txn_id   = time() . "_" . (++$TXN_SEQ) . "_$$";
    my $txn_file = "$journal_dir/txn_$txn_id";

    open my $fh, "+>>", $txn_file or do {
        $self->transact_error( $txn_file, "Cannot open journal: $txn_file ($!)" );
        return;
    };

    # Lock journal file non-blocking to establish active process ownership
    unless ( flock( $fh, LOCK_EX | LOCK_NB ) ) {
        close $fh;
        $self->transact_error( $txn_file, "Cannot lock journal file (in use): $txn_file" );
        return;
    }

    # Autoflush via IO::Handle for crash safety
    $fh->autoflush(1);

    $self->{_txn} = {
        active      => 1,
        file        => $txn_file,
        fh          => $fh,
        ops         => 0,
        locks       => {},
        logged      => {},
        tbl_enabled => {},
    };

    return 1;
}

# Releases all record locks acquired during active transaction.
# ------------------------------------------------
sub _txn_release_locks {
    my ( $self ) = @_;
    return unless $self->{_txn} && ref( $self->{_txn}->{locks} ) eq "HASH";

    foreach my $lock_key ( keys %{ $self->{_txn}->{locks} } ) {
        my ( $t_id, $r_id ) = split /_/, $lock_key, 2;
        if ( defined $t_id && defined $r_id ) {
            $self->flock_close( $t_id, $r_id );
        }
    }
}

# $result = $adb->transact_end();
# -
# Finalizes the active transaction.
# If base errors occurred → rollback all operations.
# If no base errors → commit (journal deleted, data stays).
# Index errors do NOT trigger rollback.
# Returns: { status => "commit"|"rollback", ops => N, ... }
# -
sub transact_end {
    my ( $self ) = @_;
    return unless $self->{_txn};

    if ( $self->{_txn}->{rolled_back} ) {
        my $res = delete $self->{_txn}->{result};
        delete $self->{_txn};
        return $res;
    }

    return unless $self->{_txn}->{active};

    my $txn_file = $self->{_txn}->{file};

    # Only base errors (no_rollback is false) for this transaction trigger rollback
    my @critical = grep {
        ( $_->{txn_id} // '' ) eq $txn_file && !$_->{no_rollback}
    } @{ $self->{_error} || [] };

    if ( $self->{_txn}->{fh} ) {
        flock( $self->{_txn}->{fh}, LOCK_UN );
        close $self->{_txn}->{fh};
    }
    $self->{_txn}->{active} = 0;

    if (@critical) {
        $self->_txn_apply_rollback($txn_file) if -e $txn_file;
        unlink $txn_file if -e $txn_file;

        $self->_txn_release_locks();
        my $txn_state = delete $self->{_txn};

        return {
            status => "rollback",
            errors => \@critical,
            txn_id => $txn_file,
            ops    => $txn_state->{ops},
        };
    }

    unlink $txn_file if -e $txn_file;
    $self->_txn_release_locks();
    my $txn_state = delete $self->{_txn};

    return {
        status => "commit",
        txn_id => $txn_file,
        ops    => $txn_state->{ops},
    };
}

# $result = $adb->transact_commit();
# ------------------------------------------------
# Alias to transact_end() for explicit commit semantics.
# ------------------------------------------------
sub transact_commit {
    my ( $self ) = @_;
    return $self->transact_end();
}

# $result = $adb->transact_rollback();
# ------------------------------------------------
# Forces rollback regardless of error state.
# Use for business-logic driven rollbacks (e.g. insufficient stock).
# ------------------------------------------------
sub transact_rollback {
    my ( $self ) = @_;
    return unless $self->{_txn};

    if ( $self->{_txn}->{rolled_back} ) {
        return $self->{_txn}->{result};
    }

    return unless $self->{_txn}->{active};

    my $txn_file = $self->{_txn}->{file};

    my @critical = grep {
        ( $_->{txn_id} // '' ) eq $txn_file && !$_->{no_rollback}
    } @{ $self->{_error} || [] };

    if ( $self->{_txn}->{fh} ) {
        flock( $self->{_txn}->{fh}, LOCK_UN );
        close $self->{_txn}->{fh};
        delete $self->{_txn}->{fh};
    }
    $self->{_txn}->{active} = 0;

    $self->_txn_apply_rollback($txn_file) if -e $txn_file;
    unlink $txn_file if -e $txn_file;
    $self->set_cache();

    $self->_txn_release_locks();

    my $ops = $self->{_txn}->{ops} || 0;
    my $result = {
        status => "rollback",
        errors => \@critical,
        txn_id => $txn_file,
        ops    => $ops,
    };
    $self->{_txn}->{rolled_back} = 1;
    $self->{_txn}->{result}      = $result;

    return $result;
}

# $adb->_txn_log( $type, $tableid, $file_path, $key, $action, $old_val );
# ------------------------------------------------
# Appends one undo-log entry to the journal file.
# Flushes buffer and optionally calls sync (fsync) for durability.
# Noop if no active transaction.
# ------------------------------------------------
sub _txn_log {
    my ( $self, $type, $tableid, $file_path, $key, $action, $old_val ) = @_;

    return unless $self->{_txn} && $self->{_txn}->{active};
    my $fh = $self->{_txn}->{fh} or return;

    $type      //= 'recs';
    $tableid   //= '';
    $file_path //= '';
    $key       //= '';
    $action    //= 'put';
    $old_val   //= '__NULL__';

    my $ts = $self->_txn_timestamp();

    my $safe_enc = sub {
        my ($s) = @_;
        return "" unless defined $s && length($s);
        $s =~ s/\\/\\\\/g;
        $s =~ s/\n/\\n/g;
        $s =~ s/\r/\\r/g;
        $s =~ s/\x1e/\\e/g;
        return $s;
    };

    my $val_safe = ( $type eq 'recs' && $old_val ne '__NULL__' )
        ? $safe_enc->($old_val)
        : "$old_val";

    print $fh join( $TXN_SEP, $ts, $type, $tableid, $file_path, $key, $action, $val_safe ), "\n";

    $fh->flush;
    if ( $self->config('txn_sync') ) {
        eval { $fh->sync };
    }

    $self->{_txn}->{ops}++;
    return 1;
}

# $adb->_txn_apply_rollback($txn_file);
# ------------------------------------------------
# Reads journal in reverse order (LIFO), applies generic undo operations:
# - recs  (add -> delete, edit/del -> restore old raw record)
# - index (add -> delete key, edit/del -> restore binary buffer from Hex)
# Independent of business logic, indexes, junk, or ramdisk configurations.
# Clears caches for all affected tables after rollback.
# ------------------------------------------------
sub _txn_apply_rollback {
    my ( $self, $txn_source ) = @_;

    my @lines;
    if ( ref($txn_source) eq 'ARRAY' ) {
        @lines = @$txn_source;
    }
    elsif ( ref($txn_source) && ref($txn_source) =~ /GLOB|IO/ ) {
        seek( $txn_source, 0, 0 );
        @lines = <$txn_source>;
    }
    else {
        open my $fh, "<", $txn_source or do {
            cluck "[DB_TXN] Cannot read journal for rollback: $txn_source ($!)\n";
            return;
        };
        @lines = <$fh>;
        close $fh;
    }

    my %affected_tables;
    my %open_files;

    my $safe_dec = sub {
        my ($s) = @_;
        return "" unless defined $s && length($s);
        $s =~ s/\\([nre\\])/$1 eq 'n' ? "\n" : $1 eq 'r' ? "\r" : $1 eq 'e' ? "\x1e" : "\\"/eg;
        return $s;
    };

    foreach my $line ( reverse @lines ) {
        chomp $line;
        my ( $ts, $type, $tableid, $file_path, $key, $action, $old_val ) = split /\x1e/, $line, 7;
        next unless defined $file_path && defined $key;
        $affected_tables{$tableid} = 1 if $tableid;

        unless ( $open_files{$file_path} ) {
            $self->table_write($file_path) or next;
            $open_files{$file_path} = 1;
        }
        my $db = $self->{_db}->{$file_path} or next;

        my $is_unq = ( $file_path =~ /\.unq$/ ) ? 1 : 0;
        my $k = ( $type eq 'recs' || $is_unq ) ? $self->utf_encode("$key") : "$key";

        if ( $type eq 'recs' ) {
            if ( $action eq 'add' || $old_val eq '__NULL__' ) {
                $db->del($k);
            }
            else {
                $old_val = $safe_dec->($old_val);
                $db->put( $k, $self->utf_encode($old_val) );
            }
        }
        elsif ( $type eq 'index' ) {
            if ( $action eq 'add' || $old_val eq '__NULL__' ) {
                $db->del($k);
            }
            else {
                my $raw_bin = pack( "H*", $old_val );
                $db->put( $k, $raw_bin );
            }
        }
    }

    # Close all files touched during rollback
    foreach my $file_path ( keys %open_files ) {
        $self->table_close($file_path);
    }

    # Clear in-memory caches for affected tables
    foreach my $tableid ( keys %affected_tables ) {
        $self->clear_cache($tableid);
        delete $self->{_auth}->{$tableid} if $self->{_auth};
    }

    return 1;
}

# $adb->transact_recover();
# ------------------------------------------------
# Scans journal/ directory for orphaned transaction files left by dead/crashed processes.
# Uses non-blocking exclusive flock to safely claim ownership without race conditions.
# Rolls back and removes confirmed orphaned journals.
# Called automatically at the start of each new transaction.
# ------------------------------------------------
sub transact_recover {
    my ( $self ) = @_;

    my $journal_dir = $self->journal_dir();
    my @orphans = $self->dir_files( $journal_dir, "txn_*" );
    return unless @orphans;

    foreach my $orphan ( sort @orphans ) {
        my ($pid) = $orphan =~ /[-_](\d+)$/;
        next unless $pid;

        # Skip our own active transaction file
        next if $self->{_txn} && $self->{_txn}->{file} && $orphan eq $self->{_txn}->{file};

        # Open candidate orphan journal file
        open my $ofh, "+<", $orphan or next;

        # Try to acquire exclusive non-blocking lock.
        # If another running process owns this transaction, flock will FAIL.
        if ( flock( $ofh, LOCK_EX | LOCK_NB ) ) {
            # Acquired lock: No active process holds this transaction
            # Double check PID liveness if possible
            if ( $pid != $$ && kill( 0, $pid ) ) {
                # Process is alive; release lock and leave alone
                flock( $ofh, LOCK_UN );
                close $ofh;
                next;
            }

            # Confirmed orphan: process is dead — read journal and rollback
            cluck "[DB_TXN] Orphan transaction rollback: $orphan\n";
            seek( $ofh, 0, 0 );
            my @lines = <$ofh>;
            flock( $ofh, LOCK_UN );
            close $ofh;

            $self->_txn_apply_rollback(\@lines);
            unlink $orphan;
        }
        else {
            # File is actively locked by a living process — skip safely (race-condition free)
            close $ofh;
            next;
        }
    }

    return 1;
}

# $ts = $adb->_txn_timestamp();
# ------------------------------------------------
# Returns epoch timestamp. Uses Time::HiRes for microsecond precision
# if available, otherwise falls back to time().
# ------------------------------------------------
sub _txn_timestamp {
    my ( $self ) = @_;
    if ( eval { require Time::HiRes; 1 } ) {
        return sprintf( "%.6f", Time::HiRes::time() );
    }
    return time();
}

1;

__END__

=head1 NAME

AmberDB::Transact - ACID-compliant transactions with Strict Two-Phase Locking (Strict 2PL) and undo journaling engine

=head1 SYNOPSIS

  # Transaction operations are called directly on the AmberDB instance:

  # 1. Start transaction
  $adb->transact_start();

  # 2. Perform atomic CRUD operations across multiple tables
  $adb->modify_id("inventory_stock", $product_id, @updated_stock);
  $adb->insert_id("orders_item", @order_item_record);

  # 3. Finalize transaction (commits if clean, automatically rolls back on database errors)
  my $res = $adb->transact_end();
  if ($res->{status} eq 'commit') {
      print "Transaction committed successfully (operations: $res->{ops})\n";
  }
  else {
      warn "Transaction aborted and rolled back due to error: " . join(", ", map { $_->{message} } @{$res->{errors}});
  }

  # 4. Manual business-logic rollback (e.g. payment gateway declined or insufficient stock)
  if ($payment_failed) {
      $adb->transact_rollback();
  }

  # 5. Recovery of orphaned transactions from previous system/process crashes
  $adb->transact_recover();

=head1 DESCRIPTION

C<AmberDB::Transact> provides ACID-compliant transaction undo logging, Strict Two-Phase Locking (Strict 2PL), and automated LIFO rollback for C<AmberDB>.
It records binary undo journal entries (C<journal/txn_*>) using ASCII record separators (0x1E) for atomic operations across base database files (C<.db>), soft-delete archives (C<.del>), user audit histories (C<.aut>), and all associated index files (C<.inx>, C<.src>, C<.fld>, C<.fac>, C<.slg>).

Transactions maintain process ownership via exclusive non-blocking C<flock> on journal files, hold record-level write locks throughout the transaction lifecycle, and guarantee crash durability through C<IO::Handle> buffer flushing, optional filesystem sync (C<txn_sync =E<gt> 1>), and automated orphaned journal recovery (C<transact_recover>).

B<Inheritance Note:> C<AmberDB> inherits from C<AmberDB::Transact> via C<use parent>. All transaction methods documented below are invoked directly on C<$adb>.

=head1 BATCH ETL OPERATIONS VS BUSINESS TRANSACTIONS

Transaction undo logging is designed for single-record business operations (C<insert_id>, C<modify_id>, C<delete_id>) where inter-record atomicity and consistency are required.
Bulk batch methods (C<insert_list>, C<modify_list>, C<delete_list>) are optimized for high-throughput data ingestion (e.g. XML/JSON ETL imports) and purposely bypass the transaction journal for maximum I/O performance.
If transactional atomicity is required for bulk records, execute individual CRUD methods in a loop enclosed within C<transact_start()> and C<transact_end()>.

=head1 METHODS

=head2 transact_start()

Starts a new transaction. Creates an undo journal file under C<dbstore/journal/> (e.g. C<txn_1741512300_1_4820>), acquires an exclusive non-blocking lock, and initializes the transaction state. Also triggers C<transact_recover> to clean up any orphaned journals from previous crashes.

  my $ok = $adb->transact_start();

=head2 transact_commit()

Unconditionally commits the active transaction, flushes changes to physical tables, releases all acquired locks, and removes the journal file.

  my $result = $adb->transact_commit();

=head2 transact_end()

Finalizes the active transaction. Evaluates error log for base database failures:
=over 4
=item * If critical errors occurred: performs a full LIFO rollback of all modifications across base tables and indexes, clears caches, and unlinks the journal. Returns C<{ status =E<gt> "rollback", errors =E<gt> [...] }>.
=item * If no critical errors occurred: commits the transaction (releases locks and unlinks journal). Returns C<{ status =E<gt> "commit", ops =E<gt> $count }>.
=back

  my $result = $adb->transact_end();

=head2 transact_rollback()

Forces an immediate manual rollback of the active transaction regardless of whether database errors were logged. Reverts all modified records in reverse order (LIFO), restores index states, clears affected table caches, releases locks, and unlinks the journal file.

  my $result = $adb->transact_rollback();

=head2 transact_recover()

Scans the C<dbstore/journal/> directory for orphaned transaction journals left behind by crashed or killed processes. Uses non-blocking C<flock> to safely identify dead processes without race conditions and rolls back uncommitted operations to restore consistency.

  $adb->transact_recover();

=head2 transact_error($context, $message)

Logs a context-aware error during transaction processing. Errors originating from base data tables will trigger an automatic rollback when C<transact_end()> is called.

  $adb->transact_error("order_processing", "Failed to update balance");

=head1 AUTHOR

Maruf Cetin <marufcetin@gmail.com>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Maruf Cetin.

This library is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0.

=cut
