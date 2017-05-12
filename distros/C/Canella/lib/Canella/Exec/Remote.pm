package Canella::Exec::Remote;
use Moo;
use AnyEvent::Handle;
use Canella::Log;
use Net::OpenSSH;
use POSIX ();

extends 'Canella::Exec::Local';

has '+cmd' => (
    is => 'rw',
    required => 0
);

has host => (
    is => 'ro',
    required => 1,
);

has user => (
    is => 'ro',
    required => 1,
);

has connection => (
    is => 'ro',
    lazy => 1,
    builder => 'build_connection'
);

sub build_connection {
    my $self = shift;
    return Net::OpenSSH->new($self->host, user => $self->user);
}

sub execute {
    my ($self) = @_;

    my $cmd = $self->cmd;
    infof "[%s :: executing] %s", $self->host, join ' ', @$cmd;
#$Net::OpenSSH::debug = 24;
    my $conn = $self->connection;
    my ($stdin, $stdout, $stderr, $pid) = $conn->open3({ tty => 1}, @$cmd);

    my @handles;
    my @state = (
        { name => 'stdout', fh => $stdout, lines => [] },
        { name => 'stderr', fh => $stderr, lines => [] },
    );
    my $host = $self->host;
    my $cv = AnyEvent->condvar;
    foreach my $state (@state) {
        my $name = $state->{name};
        my $lines = $state->{lines};
        $cv->begin;
        my $handle;
        $handle = AnyEvent::Handle->new(
            fh => $state->{fh},
            on_read => sub {
                $_[0]->push_read(line => qr|\r?\n|, sub {
                    push @$lines, $_[1];
                    infof("[%s :: %s] %s", $host, $name, $_[1]);
                });
            },
            on_eof => sub { $cv->end },
            on_error => sub {
                if ($! != POSIX::EPIPE) {
                    critf("[%s :: %s] %s", $host, $name, $_[2]);
                }
                $cv->end;
            }
        );
        $state->{handle} = $handle;
    }

    $cv->recv;
    foreach my $state (@state) {
        $state->{handle}->destroy;
    }

    local $? = 0;
    waitpid $pid, 0;
    my $exitcode = $?;

    $self->stdout($state[0]->{lines});
    $self->stderr($state[1]->{lines});
    $self->has_error($exitcode != 0);
    $self->error($exitcode);
}

1;