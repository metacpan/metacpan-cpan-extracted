package Audio::RaveMPClient;

use strict;
use RPC::PlClient ();
use Audio::RaveMP ();

my $PORT = 9886; #XXX config?
use constant DEBUG => 0;

{
    no strict;
    @ISA = qw(RPC::PlClient);
}

my @opts = ('peeraddr' => '127.0.0.1', 'peerport' => $PORT, 'debug' => DEBUG,
	    'application' => 'Audio::RaveMPDaemon', 'version' => 0.01,
	    'logfile' => 'STDERR', #XXX
	    'timeout' => 20);

sub new {
    my $class = shift;
    #these methods will throw exceptions
    my $client = RPC::PlClient->new(@opts, @_);

    return $client->ClientObject('Audio::RaveMPServer', 'new');
}

package Audio::RaveMPSlotRemote;

@Audio::RaveMPSlotRemote::ISA = qw(Audio::RaveMPSlot);

sub number {
    shift->{number};
}

sub type {
    shift->{type};
}

sub filename {
    shift->{filename};
}

sub download {
    my($self, $dest) = @_;
    $self->{rmp}->download($self->number, $dest);
}

sub remove {
    my $self = shift;
    $self->{rmp}->remove($self->number);
}

1;
__END__
