package DDLock::Client;

use vars qw($VERSION);
$VERSION = '0.50';

=head1 NAME

DDLock::Client - Client library for distributed lock daemon

=head1 SYNOPSIS

  use DDLock::Client ();

  my $cl = DDLock::Client->new(
        servers => ['locks.localnet:7004', 'locks2.localnet:7002', 'localhost']
  );

  # Do something that requires locking
  if ( my $lock = $cl->trylock("foo") ) {
    ...do some 'foo'-synchronized stuff...
  } else {
    die "Failed to lock 'foo': $!";
  }

  # You can either just let $lock go out of scope or explicitly release it:
  $lock->release;

=head1 DESCRIPTION

This is a client library for ddlockd, a distributed lock daemon not entirely
unlike a very simplified version of the CPAN module IPC::Locker.

This can be used as a drop in replacment for the unreleased DDLockClient class
that some of us in the world may be using. Simply replace the class name.

=head1 EXPORTS

Nothing.

=head1 MAINTAINER

Jonathan Steinert <hachi@cpan.org>

=head1 AUTHOR

Brad Fitzpatrick <brad@danga.com>

Copyright (c) 2004 Danga Interactive, Inc.

=cut

use strict;
use Socket;

use DDLock::Client::Daemon;
use DDLock::Client::File;

BEGIN {
    use fields qw( servers lockdir sockcache hooks );
    use vars qw{$Error};
}

$Error = undef;

our $Debug = 0;

sub get_sock_onlycache {
    my ($self, $addr) = @_;
    return $self->{sockcache}{$addr};
}

sub get_sock {
    my ($self, $addr) = @_;
    my $sock = $self->{sockcache}{$addr};
    return $sock if $sock && getpeername($sock);
    # TODO: cache unavailability for 'n' seconds?
    return $self->{sockcache}{$addr} =
        IO::Socket::INET->new(
                              PeerAddr    => $addr,
                              Proto       => "tcp",
                              Type        => SOCK_STREAM,
                              ReuseAddr   => 1,
                              Blocking    => 1,
                              );
}

### (CLASS) METHOD: DebugLevel( $level )
sub DebugLevel {
    my $class = shift;

    if ( @_ ) {
        $Debug = shift;
        if ( $Debug ) {
            *DebugMsg = *RealDebugMsg;
        } else {
            *DebugMsg = sub {};
        }
    }

    return $Debug;
}


sub DebugMsg {}


### (CLASS) METHOD: DebugMsg( $level, $format, @args )
### Output a debugging messages formed sprintf-style with I<format> and I<args>
### if I<level> is greater than or equal to the current debugging level.
sub RealDebugMsg {
    my ( $class, $level, $fmt, @args ) = @_;
    return unless $Debug >= $level;

    chomp $fmt;
    printf STDERR ">>> $fmt\n", @args;
}


### (CONSTRUCTOR) METHOD: new( %args )
### Create a new DDLock::Client
sub new {
    my DDLock::Client $self = shift;
    my %args = @_;

    $self = fields::new( $self ) unless ref $self;
    die "Servers argument must be an arrayref if specified"
        unless !exists $args{servers} || ref $args{servers} eq 'ARRAY';
    $self->{servers} = $args{servers} || [];
    $self->{lockdir} = $args{lockdir} || '';
    $self->{sockcache} = {};  # "host:port" -> IO::Socket::INET
    $self->{hooks} = {};      # hookname -> coderef

    return $self;
}


sub set_hook {
    my DDLock::Client $self = shift;
    my $hookname = shift || return;

    if (@_) {
        $self->{hooks}->{$hookname} = shift;
    } else {
        delete $self->{hooks}->{$hookname};
    }
}

sub run_hook {
    my DDLock::Client $self = shift;
    my $hookname = shift || return;

    if (my $hook = $self->{hooks}->{$hookname}) {
        local $@;
        eval { $hook->($self) };
        warn "DDLock::Client hook '$hookname' threw error: $@" if $@;
    }
}

### METHOD: trylock( $name )
### Try to get a lock from the lock daemons with the specified I<name>. Returns
### a DDLock object on success, and undef on failure.
sub trylock {
    my DDLock::Client $self = shift;
    my $lockname = shift;

    $self->run_hook('trylock', $lockname);

    my $lock;
    local $@;

    # If there are servers to connect to, use a network lock
    if ( @{$self->{servers}} ) {
        $self->DebugMsg( 2, "Creating a new DDLock object." );
        $lock = eval { DDLock::Client::Daemon->new($self, $lockname, @{$self->{servers}}) };
    }

    # Otherwise use a file lock
    else {
        $self->DebugMsg( 2, "No servers configured: Creating a new DDFileLock object." );
        $lock = eval { DDLock::Client::File->new($lockname, $self->{lockdir}) };
    }

    # If no lock was acquired, fail and put the reason in $Error.
    unless ( $lock ) {
        my $eval_error = $@;
        $self->run_hook('trylock_failure');
        return $self->lock_fail( $eval_error ) if $eval_error;
        return $self->lock_fail( "Unknown failure." );
    }

    $self->run_hook('trylock_success', $lockname, $lock);

    return $lock;
}


### (PROTECTED) METHOD: lock_fail( $msg )
### Set C<$!> to the specified message and return undef.
sub lock_fail {
    my DDLock::Client $self = shift;
    my $msg = shift;

    $Error = $msg;
    return undef;
}


1;


# Local Variables:
# mode: perl
# c-basic-indent: 4
# indent-tabs-mode: nil
# End:
