############################################################################
#
# Apache::Session::Lock::Sybase
# Sybase locking for Apache::Session
# Copyright(c) 2003 Oliver Maul (oli@42.nu)
# Distribute under the Perl License
#
############################################################################

package Apache::Session::Lock::Sybase;

use strict;

use DBI;
use vars qw($VERSION);

$VERSION = '1.00';

sub new {
    my $class = shift;
    
    return bless {lock => 0, lockid => undef, dbh => undef, mine => 0}, $class;
}

sub acquire_read_lock  {
    my $self    = shift;
    my $session = shift;
    
    return if $self->{lock};

    if (!defined $self->{dbh}) {
        if (defined $session->{args}->{LockHandle}) {
            $self->{dbh} = $session->{args}->{LockHandle};
        }
        else {
            $self->{dbh} = DBI->connect(
                $session->{args}->{LockDataSource},
                $session->{args}->{LockUserName},
                $session->{args}->{LockPassword},
                { RaiseError => 1, AutoCommit => 1 }
            );
            $self->{mine} = 1;
        }
    }

    local $self->{dbh}->{RaiseError} = 1;

    $self->{lockid} = "Apache-Session-$session->{data}->{_session_id}";
    
    my $sth = $self->{dbh}->prepare(q{sp_getapplock @Resource = '}.$self->{lockid}.q{',@LockMode='Exclusive',@LockOwner='Session',@LockTimeout = '3600000'});
    $sth->execute() || die $DBI::errstr;
    
    $self->{lock} = 1;
}

sub acquire_write_lock {
    $_[0]->acquire_read_lock($_[1]);
}

sub release_read_lock {
    my $self = shift;

    if ($self->{lock}) {
        local $self->{dbh}->{RaiseError} = 1;
        
        my $sth = $self->{dbh}->prepare(q{sp_releaseapplock @Resource='}.$self->{lockid}.q{',@Lookowner='Session'});
        $sth->execute() || die $DBI::errstr;
        
        $self->{lock} = 0;
    } 
}

sub release_write_lock {
    $_[0]->release_read_lock;
}

sub release_all_locks  {
    $_[0]->release_read_lock;
}

sub DESTROY {
    my $self = shift;
    
    $self->release_all_locks;
    
    if ($self->{mine}) {
        $self->{dbh}->disconnect;
    }
}

1;

=pod

=head1 NAME

Apache::Session::Lock::Sybase - Provides mutual exclusion using Sybase

=head1 SYNOPSIS

 use Apache::Session::Lock::Sybase;

 my $locker = new Apache::Session::Lock::Sybase;

 $locker->acquire_read_lock($ref);
 $locker->acquire_write_lock($ref);
 $locker->release_read_lock($ref);
 $locker->release_write_lock($ref);
 $locker->release_all_locks($ref);

=head1 DESCRIPTION

Apache::Session::Lock::Sybase fulfills the locking interface of 
Apache::Session.  Mutual exclusion is achieved through the use of Sybase's
sp_getapplock and sp_releaseapplock functions. Sybase does not support the
notion
of read and write locks, so this module only supports exclusive locks.  When
you request a shared read lock, it is instead promoted to an exclusive
write lock.

=head1 CONFIGURATION

The module must know how to connect to your MySQL database to acquire locks.
You must provide a datasource name, a user name, and a password.  These options
are passed in the usual Apache::Session style, and are very similar to the
options for Apache::Session::Store::Sybase.  Example:

 tie %hash, 'Apache::Session::Sybase', $id, {
     LockDataSource => 'dbi:sybase:database',
     LockUserName   => 'database_user',
     LockPassword   => 'K00l'
 };

Instead, you may pass in an already opened DBI handle to your database.

 tie %hash, 'Apache::Session::Sybase', $id, {
     LockHandle => $dbh
 };

=head1 AUTHOR

This module was written by Oliver Maul <oli@42.nu>.

=head1 SEE ALSO

L<Apache::Session>
