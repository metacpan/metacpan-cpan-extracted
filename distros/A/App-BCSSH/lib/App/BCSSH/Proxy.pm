package App::BCSSH::Proxy;
use Moo;
use File::Temp ();
use IO::Select;
use IO::Socket::UNIX;
use App::BCSSH::Message;
use Try::Tiny;

has agent_path  => (is => 'ro');
has handlers    => (is => 'ro', default => sub { { } } );
has umask       => (is => 'ro', default => sub { 0077 } );
has _temp_dir   => (is => 'lazy', init_arg => undef);
sub _build__temp_dir {
    my $self = shift;
    my $old_mask = umask($self->umask);
    my $dir = File::Temp->newdir(TMPDIR => 1);
    umask($old_mask);
    return $dir;
}
has socket_path => (is => 'ro', lazy => 1, default => sub { $_[0]->_temp_dir . '/agent-proxy' } );
has _select     => (is => 'ro', default => sub { IO::Select->new });
has server_socket => (is => 'lazy');
sub _build_server_socket {
    my $self = shift;
    unlink $self->socket_path;
    my $old_mask = umask($self->umask);
    my $server = IO::Socket::UNIX->new(
        Local => $self->socket_path,
        Listen => 10,
    ) or die "$!";
    umask($old_mask);
    $self->_select->add($server);
    return $server;
}
has _clients => (is => 'ro', default => sub { { } });

sub proxy {
    my ($self, $parent_fh) = @_;
    my $done;
    local $SIG{$_} = sub { $done = 1 } for qw(HUP INT TERM QUIT);
    my $select = $self->_select;
    $select->add($parent_fh)
        if $parent_fh;

    my $server = $self->server_socket;
    my $clients = $self->_clients;
    until ($done) {
        for my $socket ($select->can_read) {
            if ($parent_fh && $socket == $parent_fh) {
                $done = 1;
            }
            elsif ($socket == $server) {
                $self->new_client($socket);
            }
            elsif ($socket->sysread(my $buf, 4096)) {
                $self->read_message($clients->{$socket}, $buf);
            }
            else {
                $self->close_client($clients->{$socket}{client});
            }
        }
    }
    for my $client (values %$clients) {
        $self->close_client($client->{client});
    }
    $select->remove($parent_fh)
        if $parent_fh;
}

sub read_message {
    my $self = shift;
    my $client = shift;
    my $buffer = shift;
    if (! $client->{filtered}) {
        $client->{remote}->syswrite($buffer);
        return;
    }
    $client->{buffer} .= $buffer;
    my $len = $client->{message_length};
    if (!$len && length $client->{buffer} >= 4) {
        $len = $client->{message_length} = unpack 'N', substr($client->{buffer}, 0, 4, '');
    }
    if ( $len && length $client->{buffer} >= $len ) {
        my $message = substr($client->{buffer}, 0, $len, '');
        my $type = unpack 'c', substr($message, 0, 1, '');
        delete $client->{message_length};
        if (my $handler = $self->handlers->{$type}) {
            my $socket = $client->{client};
            my $send = sub {
                my ($type, $out_message) = @_;
                my $response = make_response($type, $out_message);
                $socket->syswrite($response);
            };
            try {
                $handler->($message, $send, $socket);
            }
            catch {
                $socket->syswrite(make_response(SSH_AGENT_FAILURE));
            };
        }
        elsif (my $remote = $client->{remote}) {
            $remote->syswrite(make_response($type, $message));
        }
        else {
            $remote->syswrite(make_response(SSH_AGENT_FAILURE));
        }
    }
}

sub new_client {
    my $self = shift;
    my $server = shift;
    my $client = $server->accept;
    my $agent_path = $self->agent_path;
    my $agent = $agent_path && IO::Socket::UNIX->new(Peer => $agent_path);
    $self->_select->add($client);
    $self->_clients->{$client} = {
        filtered => 1,
        buffer => '',
        client => $client,
        remote  => $agent,
    };
    if ($agent) {
        $self->_select->add($agent);
        $self->_clients->{$agent} = {
            client => $agent,
            remote => $client,
        };
    }
    return 1;
}

sub close_client {
    my $self = shift;
    my $socket = shift;
    $self->_select->remove($socket);
    $socket->close;
    my $client = delete $self->_clients->{$socket};
    if ($client && $client->{remote}) {
        $self->close_client($client->{remote});
    }
}

1;
__END__

=head1 NAME

App::BCSSH::Proxy - ssh-agent proxy with message intercept

=head1 SYNOPSIS

    my $proxy = App::BCSSH::Proxy->new(
        agent_path => $agent_path,
        handlers => {
            (BCSSH_COMMAND) => sub {
                my ($message, $send, $socket) = @_;
                ...;
            },
        },
    );
    $ENV{SSH_AUTH_SOCK} = $proxy->socket_path;
    $proxy->proxy(\*STDIN);

=cut
