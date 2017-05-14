
package App::OverWatch::ServiceLock;
# ABSTRACT: ServiceLock base class

use strict;
use warnings;

use App::OverWatch::DB;
use App::OverWatch::Lock;

use Module::Load qw( load );

sub new {
    my $class = shift;
    my $rh_options = shift || {};

    my $DB = $rh_options->{db} // die "Require 'db'";

    my $type = $DB->type();

    my $subclass = "$class::$type";
    load($subclass);

    my $self = bless( {}, $subclass );

    $self->{DB} = $DB;

    return $self;
}

sub create_lock {
    my $self    = shift;
    my $rh_args = shift;

    my $system  = $rh_args->{system} || die "Error: require 'system'";

    my $now_sql = $self->generate_now_sql();

    my $sql =<<"SQL";
INSERT INTO
    servicelocks ( system, worker, status, mtime )
VALUES
    ( ?, '', 'UNLOCKED', $now_sql )
SQL

    my $ret = $self->{DB}->dbix_run( $sql, $system );
    return $ret;
}

sub get_all_locks {
    my $self = shift;

    my $sql =<<"SQL";
SELECT
    *
FROM
    servicelocks
SQL

    my $sth = $self->{DB}->dbix_select( $sql );
    return undef if (!defined($sth));
    my @locks;
    while ( my $rh_row = $sth->fetchrow_hashref() ) {
        my $Lock = App::OverWatch::Lock->new($rh_row);
        push(@locks, $Lock);
    }
    return @locks;
}

sub get_lock {
    my $self = shift;
    my $rh_args = shift;

    my $system  = $rh_args->{system} || die "Error: require 'system'";

    my $sql =<<"SQL";
SELECT
    *
FROM
    servicelocks
WHERE
    system = ?
SQL

    my $sth = $self->{DB}->dbix_select( $sql, $system );
    return undef if (!defined($sth));
    my $rh_row = $sth->fetchrow_hashref();
    die "Error: No such lock '$system'\n"
        if ($sth->rows() == 0 || !defined($rh_row));
    my $Lock = App::OverWatch::Lock->new($rh_row);
    return $Lock;
}

##

sub try_lock {
    my $self = shift;
    my $rh_args = shift;

    my $system  = $rh_args->{system} || die "Error: require 'system'";
    my $worker  = $rh_args->{worker} || die "Error: require 'worker'";
    my $expiry  = $rh_args->{expiry} // 0;
    my $text    = $rh_args->{text}   || die "Error: require 'text'";

    my $expiry_sql = $self->timestamp_calculate_sql($expiry);
    my $now_sql    = $self->generate_now_sql();

    my $sql =<<"SQL";
UPDATE
    servicelocks
SET
    worker = ?,
    status = 'LOCKED',
    expiry = $expiry_sql,
    text   = ?,
    mtime  = $now_sql
WHERE
    system = ? AND
    (
      status = 'UNLOCKED' OR
     (
      expiry IS NOT NULL AND expiry < $now_sql
     )
    )
SQL

    my $ret = $self->{DB}->dbix_run( $sql, $worker, $text, $system );
    return $ret == 1 ? 1 : 0;
}

sub try_update {
    my $self = shift;
    my $rh_args = shift;

    my $system  = $rh_args->{system} || die "Error: require 'system'";
    my $worker  = $rh_args->{worker} || die "Error: require 'worker'";
    my $expiry  = $rh_args->{expiry};
    my $text    = $rh_args->{text}   || die "Error: require 'text'";

    my $full_expiry_sql = "";
    if (defined($expiry)) {
        my $expiry_sql = $self->timestamp_calculate_sql($expiry);
        $full_expiry_sql = "expiry = $expiry_sql,";
    }

    my $now_sql = $self->generate_now_sql();

    my $sql =<<"SQL";
UPDATE
    servicelocks
SET
    $full_expiry_sql
    text   = ?,
    mtime  = $now_sql
WHERE
    system = ? AND
    worker = ? AND
    status = 'LOCKED'
SQL

    my $ret = $self->{DB}->dbix_run( $sql, $text, $system, $worker );
    return $ret == 1 ? 1 : 0;
}

sub try_unlock {
    my $self = shift;
    my $rh_args = shift;

    my $system  = $rh_args->{system} || die "Error: require 'system'";
    my $worker  = $rh_args->{worker} || die "Error: require 'worker'";

    my $now_sql = $self->generate_now_sql();

    my $sql =<<"SQL";
UPDATE
    servicelocks
SET
    worker = '',
    status = 'UNLOCKED',
    expiry = NULL,
    text = '',
    mtime = $now_sql
WHERE
    system = ? AND
    worker = ? AND
    status = 'LOCKED'
SQL

    my $ret = $self->{DB}->dbix_run( $sql, $system, $worker );
    return $ret == 1 ? 1 : 0;
}

sub force_unlock {
    my $self    = shift;
    my $rh_args = shift;

    my $system  = $rh_args->{system} || die "Error: require 'system'";

    my $sql =<<"SQL";
UPDATE
    servicelocks
SET
    worker = '',
    status = 'UNLOCKED',
    expiry = NULL,
    text = ''
WHERE
    system = ? AND
    status = 'LOCKED'
SQL

    my $ret = $self->{DB}->dbix_run( $sql, $system );
    return $ret == 1 ? 1 : 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::OverWatch::ServiceLock - ServiceLock base class

=head1 VERSION

version 0.003

=head1 SYNOPSIS

  use App::OverWatch;
  my $OverWatch = App::OverWatch->new();
  [...]
  my $ServiceLock = $OverWatch->ServiceLock();

=head1 DESCRIPTION

Provides a simple mechanism for allowing the locking of named resources
via a central database.  Locks can have expiry periods, so could perhaps be
considered leases.

=head1 NAME

App::OverWatch::ServiceLock - App::OverWatch Locking System

=head1 METHODS

=head2 new

Create an App::OverWatch::EventLog object - usualy handled by App::OverWatch.

=head2 create_lock

Create a lock

  $ServiceLock->create_lock({
     system => $system,
  })

=head2 get_all_locks

Return a list of App::OverWatch::Lock objects representing all created locks.

  my @Locks = $ServiceLock->get_all_locks();

=head2 get_lock

Return an App::OverWatch::Lock object for a given lock.

  my $Lock = $ServiceLock->get_lock({
     system => $Options->{system},
  });

=head2 try_lock

Attempt to gain a lock.

  $ServiceLock->try_unlock({
     system => $system,
     worker => 'myworkerid',
     expiry => $expiry_in_minutes,   # Optional
  });

=head2 try_update

Attempt to update details of a lock in place.  This can only succeed if the
worker already owns the lock.

  $ServiceLock->try_update({
     system => $system,
     worker => 'myworkerid',
     text   => 'New text',
     expiry => $new_expiry_in_minutes,
  });

=head2 try_unlock

Attempt to release a lock.

  $ServiceLock->try_unlock({
     system => $system,
     worker => 'myworkerid',
  });

=head2 force_unlock

Force a lock to be released.

  $ServiceLock->force_unlock({
     system => $system,
  });

=head1 AUTHOR

Chris Hughes <chrisjh@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Chris Hughes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
