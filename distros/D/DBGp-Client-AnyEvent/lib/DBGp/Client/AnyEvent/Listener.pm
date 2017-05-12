package DBGp::Client::AnyEvent::Listener;

use strict;
use warnings;

use AnyEvent::Socket qw(tcp_server);
use DBGp::Client::AnyEvent::Connection;
use Scalar::Util qw(weaken);

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        port            => $args{port},
        path            => $args{path},
        mode            => $args{mode},
        on_connection   => $args{on_connection},
        tcp_guard       => undef,
    }, $class;

    die "Specify either 'port' or 'path'" unless $self->{port} || $self->{path};

    return $self;
}

sub listen {
    my ($self) = @_;

    my $weak_self = $self;
    weaken($weak_self);
    my $cb = sub { $weak_self->_new_connection($_[0]) };
    my $prepare = ($self->{path} && defined $self->{mode}) ? sub {
        chmod $weak_self->{mode}, $weak_self->{path}
            or die "Unable to change file mode for socket: $!";
    } : undef;
    if ($self->{port}) {
        $self->{guard} = tcp_server('127.0.0.1', $self->{port}, $cb);
    } elsif ($self->{path}) {
        $self->{guard} = tcp_server('unix/', $self->{path}, $cb, $prepare);
    }
}

sub _new_connection {
    my ($self, $fh) = @_;
    my $connection = DBGp::Client::AnyEvent::Connection->new(socket => $fh);

    $self->{on_connection}->($connection);
}

1;
