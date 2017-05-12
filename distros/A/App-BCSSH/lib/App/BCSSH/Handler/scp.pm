package App::BCSSH::Handler::scp;
use Moo;
my $have_pty;
BEGIN { eval {require IO::Pty::Easy; $have_pty = 1} }

with 'App::BCSSH::Handler';

has destination => (
    is => 'ro',
    default => sub {
        -d && return $_
            for ("$ENV{HOME}/Desktop", "$ENV{HOME}/desktop", $ENV{HOME});
    },
);
has scp => (
    is => 'ro',
    default => sub { 'scp' },
);

sub handle {
    my ($self, $send, $args) = @_;
    my $files = $args->{files};
    for my $file (@$files) {
        $file = $self->host.':'.$file;
    }
    my $socket = $send->();
    fork and return;
    my @scp = ref $self->scp ? @{ $self->scp } : $self->scp;
    my @command = (@scp, '-r', '--', @$files, $self->destination);
    if ($have_pty) {
        my $pty = IO::Pty::Easy->new;
        $pty->spawn(@command);

        while ($pty->is_active) {
            my $output = $pty->read;
            last if defined($output) && $output eq '';
            $socket->syswrite($output);
        }
        $pty->close;
    }
    else {
        system @command;
    }
    $socket->shutdown(2);
    exit;
}

1;
