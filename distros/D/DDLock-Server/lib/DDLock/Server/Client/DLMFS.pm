package DDLock::Server::Client::DLMFS;

# I don't think this code was ever tested, back when I wrote this
# dlmfs was causing my kernel to crash all the time.

use strict;
use warnings;

use base 'DDLock::Server::Client';
use Fcntl;
use Errno qw(EEXIST ETXTBSY);

sub FLAGS () { O_NONBLOCK | O_RDWR | O_CREAT | O_EXCL }
sub PATH () { "/dlm/ddlockd" };

sub _setup {
    -d "/dlm" or die( "DLMFS mount at /dlm not found\n" );
    mkdir PATH;
}

sub _trylock {
    my DDLock::Server::Client::Internal $self = shift;
    my $lock = shift;

    return $self->err_line("empty_lock") unless length($lock);

    if (sysopen( my $handle, PATH . "/$lock", FLAGS )) {
        $self->{locks}{$lock} = 1;
        return $self->ok_line();
    }
    else {
        if ($! == EEXIST) {
            return $self->err_line( "local taken" );
        }
        elsif( $! == ETXTBSY) {
            unlink( PATH . "/$lock" );
            return $self->err_line( "remote taken" );
        }
        else {
            return $self->err_line( "unknown: $!" );
        }
    }
}

sub _release_lock {
    my DDLock::Server::Client::Internal $self = shift;
    my $lock = shift;

    # TODO: notify waiters
    delete $self->{locks}{$lock};
    unlink( PATH . "/$lock" );
    return 1;
}

sub _get_locks {
# TODO
#    return map { "  $_ = " . $holder{$_}->as_string } (sort keys %holder);
}

1;
