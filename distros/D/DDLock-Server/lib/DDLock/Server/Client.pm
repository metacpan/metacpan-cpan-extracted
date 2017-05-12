#####################################################################
### C L I E N T   C L A S S
#####################################################################
package DDLock::Server::Client;

use strict;
use warnings;

use Danga::Socket;
use base 'Danga::Socket';
use fields (
            'locks',  # hashref of locks held by this connection. values are 1
            'read_buf',
            );

# TODO: out %waiters, lock -> arrayref of client waiters (waker should check not closed)

my $lock_successes = 0;
my $lock_failures = 0;

sub new {
    my DDLock::Server::Client $self = shift;
    $self = fields::new($self) unless ref $self;
    $self->SUPER::new( @_ );

    $self->{locks} = {};
    $self->{read_buf} = '';
    return $self;
}

# Client
sub event_read {
    my DDLock::Server::Client $self = shift;

    my $bref = $self->read(1024);
    return $self->close() unless defined $bref;
    $self->{read_buf} .= $$bref;

    if ($self->{read_buf} =~ s/^(.+?)\r?\n//) {
        my $line = $1;
        $self->process_line( $line );
    }
}

sub process_line {
    my DDLock::Server::Client $self = shift;
    my $line = shift;

    if ($line =~ /^(\w+)\s*(.*)/) {
        my ($cmd, $args) = ($1, $2);
        $cmd = lc($cmd);

        no strict 'refs';
        my $cmd_handler = *{"cmd_$cmd"}{CODE};
        if ($cmd_handler) {
            my $args = decode_url_args(\$args);
            $cmd_handler->($self, $args);
            return;
        }
    }

    return $self->err_line('unknown_command');
}

sub close {
    my DDLock::Server::Client $self = shift;

    foreach my $lock (keys %{$self->{locks}}) {
        $self->_release_lock($lock);
    }

    $self->SUPER::close;
}


# Client
sub event_err { my $self = shift; $self->close; }
sub event_hup { my $self = shift; $self->close; }

sub cmd_status {
    my DDLock::Server::Client $self = shift;

    my $runtime = time - $^T;

    $self->write("STATUS: OK\n");
    $self->write("SUCCESSES: $lock_successes\n");
    $self->write("FAILURES: $lock_failures\n");
    $self->write("RUNTIME: $runtime\n");
    $self->write("\n");

    return 1;
}

# gets a lock or fails with 'taken'
sub cmd_trylock {
    my DDLock::Server::Client $self = shift;
    my $args = shift;

    my $lock = $args->{lock};
    my $lockstate = $self->_trylock( $lock );

    if ($lockstate) {
        $lock_successes++;
    } else {
        $lock_failures++;
    }

    return $lockstate;
}

# releases a lock or fails with 'didnthave'
sub cmd_releaselock {
    my DDLock::Server::Client $self = shift;
    my $args = shift;

    my $lock = $args->{lock};
    return $self->err_line("empty_lock") unless length($lock);
    return $self->err_line("didnthave") unless $self->{locks}{$lock};

    $self->_release_lock($lock);
    return $self->ok_line;
}

# shows current locks
sub cmd_locks {
    my DDLock::Server::Client $self = shift;
    my $args = shift;

    $self->write("LOCKS:\n");
    $self->write( join( "\n", $self->_get_locks ) );
    $self->write("\n");

    return 1;
}

sub cmd_noop {
    my DDLock::Server::Client $self = shift;
    # TODO: set self's last activity time so it isn't cleaned in a purge
    #       of stale connections?
    return $self->ok_line;
}

sub ok_line {
    my DDLock::Server::Client $self = shift;
    my $args = shift || {};
    my $argline = join('&', map { eurl($_) . "=" . eurl($args->{$_}) } keys %$args);
    $self->write("OK $argline\r\n");
    return 1;
}

sub err_line {
    my DDLock::Server::Client $self = shift;
    my $err_code = shift;
    my $err_text = {
        'unknown_command' => "Unknown server command",
    }->{$err_code};

    $self->write("ERR $err_code " . eurl($err_text) . "\r\n");
    return 0;
}

sub eurl
{
    my $a = $_[0];
    $a = '' unless defined $a;
    $a =~ s/([^a-zA-Z0-9_\,\-.\/\\\: ])/uc sprintf("%%%02x",ord($1))/eg;
    $a =~ tr/ /+/;
    return $a;
}

sub durl
{
    my ($a) = @_;
    $a =~ tr/+/ /;
    $a =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
    return $a;
}

sub decode_url_args
{
    my $a = shift;
    my $buffer = ref $a ? $a : \$a;
    my $ret = {};

    my $pair;
    my @pairs = split(/&/, $$buffer);
    my ($name, $value);
    foreach $pair (@pairs)
    {
        ($name, $value) = split(/=/, $pair);
        $value =~ tr/+/ /;
        $value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
        $name =~ tr/+/ /;
        $name =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
        $ret->{$name} .= $ret->{$name} ? "\0$value" : $value;
    }
    return $ret;
}

1;
