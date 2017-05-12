package DBIx::QueryByName::DbhPool;

use utf8;
use strict;
use warnings;

use DBI;
use DBIx::QueryByName::Logger qw(get_logger debug);
use Scalar::Util qw(weaken);

sub new {
    return bless( { connections => {}, config => {} }, $_[0] );
}

sub parent {
    my ($self, $parent) = @_;
    $self->{sthpool} = $parent->_sth_pool;
    weaken $self->{sthpool};
}

sub add_credentials {
    my ($self, $session, @params) = @_;
	my $log = get_logger();
    $log->logcroak("undefined session name") if (!defined $session);
    $log->logcroak("no session parameters provided") if (scalar @params == 0);
    $log->logcroak("credentials for session [$session] are already declared") if ($self->knows_session($session));
    $self->{config}->{$session} = \@params;
    return $self;
}

sub knows_session {
    my ($self, $session) = @_;
	my $log = get_logger();
    $log->logcroak("undefined session name") if (!defined $session);
    return (exists $self->{config}->{$session}) ? 1 : 0;
}

sub _inactivate_parent_connections {
    my $self = shift;

    foreach my $pid ( keys %{$self->{connections}} ) {
        foreach my $session ( keys %{$self->{connections}->{$pid}} ) {
            if ( $$ != $pid ) {
                if ( defined $self->{connections}->{$pid}->{$session}->{InactiveDestroy} &&
                     $self->{connections}->{$pid}->{$session}->{InactiveDestroy} != 1 ) {
                    # the connection belongs to an other process than self.
                    # Prevent forked child (this pid) from disconnecting the database connection
                    debug "Setting connection for pid $$ and session $session as InactiveDestroy";
                    $self->{connections}->{$pid}->{$session}->{InactiveDestroy} = 1;
                    delete $self->{connections}->{$pid}->{$session};
                }
            }
        }
    }    
    
    1;
}

# open database connection for the given session and return a database
# handler
sub connect {
    my ($self, $session) = @_;
	my $log = get_logger();
    $log->logcroak("undefined session name") if (!defined $session);

    return $self->{connections}->{$$}->{$session} if (defined $self->{connections}->{$$}->{$session});

    # Before opening connection, we need to set InactiveDestroy on
    # other processes connections. Even then, there is a risk that a
    # process that just forks but open no own connections will close
    # all the connections of related processes upon exit.
    $self->_inactivate_parent_connections();
    
    # try to open database connection
    # TODO: implement a giveup limit?
    my $error_reported = 0;
    while (1) {
        $log->logcroak("don't know how to open connection [$session]")
            if (!$self->knows_session($session));

        debug "Trying to connect to database for session $session";
        my $dbh = DBI->connect( @{$self->{config}->{$session}} );

        if (!defined $dbh) {
            # TODO: croak after a number of attempts?
            $log->error("Unable to connect to database [$session]: ".$DBI::errstr) if ($error_reported == 0);
            $error_reported = 1;
            sleep(1);
            next;
        }

        $self->{connections}->{$$}->{$session} = $dbh;
        if ($error_reported == 1) {
            $log->info( "Database is back online [$session]");
        } else {
            debug "Connected to database";
        }

        return $dbh;
    }
}

sub disconnect {
    my ($self, $session) = @_;

    my $log = get_logger();
    $log->logcroak("undefined session name")   if (!defined $session);
    $log->logcroak("not a known session name") if (!$self->knows_session($session));

    if (defined $self->{connections}->{$$}->{$session}) {
        debug "Disconnecting session $session for pid $$";
        $self->{connections}->{$$}->{$session}->disconnect();
        delete $self->{connections}->{$$}->{$session};
    }
    return $self;
}

sub disconnect_all {
    my $self = shift;
    $self->_inactivate_parent_connections;
    debug "Disconnecting all dbhs for process $$";
    foreach my $session ( keys %{$self->{connections}->{$$}} ) {
            $self->disconnect($session);
    }
}

sub DESTROY {
    my $self = shift;

    debug "DESTROY DbhPool -> calling finish_all_sths and disconnect_all";
    # either this DESTROY is called first, or SthPool's DESTROY is
    $self->{sthpool}->finish_all_sths() if (defined $self->{sthpool});
    $self->disconnect_all();
}

1;

__END__

=head1 NAME

DBIx::QueryByName::DbhPool - A pool of database handles

=head1 DESCRIPTION

An instance of DBIx::QueryByName::DbhPool stores the all opened
database handles used by the corresponding instances of
DBIx::QueryByName, as well as information on how to open database
connections.

DO NOT USE DIRECTLY!

=head1 INTERFACE

This API is subject to change!

=over 4

=item C<< my $pool = DBIx::QueryByName::DbhPool->new(); >>

Instanciate DBIx::QueryByName::DbhPool.

=item C<< $pool->parent($dbixquerybyname) >>

Called after new() to tell the dbh pool of which instance of
DBIx::QueryByName it is related to.

=item C<< $pool->add_credentials($session, @params); >>

Store credentials for opening the database connection named
C<$session>. C<@params> is a standard DBI connection string or list.
Return the pool.

=item C<< $pool->knows_session($session); >>

Return true if the pool knows connection credentials for a database
connection named C<$session>. False otherwise.

=item C<< my $dbh = $pool->connect($session); >>

Tries to open the database connection associated with the session name
C<$session>. Will retry every second indefinitely until success.
Return the database handle for the new connection.

=item C<< my $dbh = $pool->disconnect($session); >>

Disconnects the database connection associated with the session name
C<$session>. Return the pool.

=item C<< my $dbh = $pool->disconnect_all(); >>

Disconnects all the database connections in the pool that belong to the running process.
Doesn't affect any parent/child process's connections.

=back

=cut
