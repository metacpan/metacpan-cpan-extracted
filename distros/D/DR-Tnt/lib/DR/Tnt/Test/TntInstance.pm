use utf8;
use strict;
use warnings;

package DR::Tnt::Test::TntInstance;
use File::Temp;
use File::Spec::Functions 'rel2abs', 'catfile';
use Time::HiRes ();
use IO::Socket::INET;
use POSIX;

sub new {
    my ($class, %opts) = @_;

    die "-lua or -make_lua option is not defined"
        unless $opts{-lua} or $opts{-make_lua};
    $opts{-lua} = rel2abs $opts{-lua} if $opts{-lua};
    my $self = bless \%opts => ref($class) || $class;


    if ($self->{-dir}) {
        die "$self->{-dir} not found" unless -d $self->{-dir};
    } else {
        $self->{-dir} = File::Temp::tempdir;
        $self->{-clean} = [ $self->{-dir} ];
    }

    $self->{-log} = rel2abs catfile $self->{-dir}, 'tarantool.log';
    $self->{-log_seek} = 0;
    if (-r $self->{-log}) {
        open my $fh, '<', $self->{-log};
        seek $fh, 0, 2;
        $self->{-log_seek} = tell $fh;
        close $fh;
    }


    $self->start; 
}


sub start {
    my ($self) = @_;
    if ($self->{pid} = fork) {
        for (1 .. 50) {
            Time::HiRes::sleep .1;
            last unless $self->{-port};
            
            next unless IO::Socket::INET->new(
                PeerHost => '127.0.0.1',
                PeerPort => $self->{-port},
                Proto    => 'tcp',
                (($^O eq 'MSWin32') ? () : (ReuseAddr => 1)),
            );
            last if $self->log =~ /entering the event loop/;
        }

        return $self;
    }
    
    for (open my $fh, '>>', $self->{-log}) {
        POSIX::dup2(fileno($fh), fileno(STDOUT));
        POSIX::dup2(fileno($fh), fileno(STDERR));
        close $fh;
    }

    unless ($self->{-lua}) {
        $self->{-lua} = catfile $self->{-dir}, 'make_lua.lua';
        open my $fh, '>:raw', $self->{-lua}
            or warn "Can't create $self->{-lua}: $!\n";
        my $lua = $self->{-make_lua};
        utf8::encode $lua if utf8::is_utf8 $lua;
        print $fh $lua;
        close $fh;
    }

    chdir $self->{-dir};
    if ($self->port) {
        $ENV{PRIMARY_PORT} = $self->port;
    }
    $ENV{WORK_DIR} = $self->{-dir};
    exec tarantool => $self->{-lua};
    die "Can't start tarantool";
}

sub stop {
    my ($self) = @_;
    $self->kill('TERM');
}

sub port { $_[0]->{-port} }
sub is_started {
    return $_[0]->log =~ /entering the event loop/;
}

sub log {
    my ($self) = @_;
    return '' unless -r $self->{-log};
    open my $fh, '<', $self->{-log};
    seek $fh, 0, $self->{-log_seek};
    local $/;
    my $data = <$fh>;
    return $data;
}

sub clean {
    my ($self) = @_;
    return unless $self->{-clean};
    for (@{ $self->{-clean} }) {
        system "rm -fr $_";
    }
}

sub pid { $_[0]->{pid} };

sub kill {
    my ($self, $sig) = @_;
    return unless $self->pid;
    $sig ||= 'TERM';
    if (kill $sig, $self->pid) {
        waitpid $self->pid, 0;
    } else {
        warn sprintf "Can't kill -$sig %s\n", $self->pid;
    }
    delete $self->{pid};
}

sub DESTROY {
    my ($self) = @_;
    $self->kill('KILL');
    $self->clean;
}


1;
