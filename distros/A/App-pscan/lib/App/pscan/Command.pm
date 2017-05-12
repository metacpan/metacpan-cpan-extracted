package App::pscan::Command;
use App::pscan;
use base qw(App::CLI App::CLI::Command);

use constant global_options => ( 'help' => 'help' );

sub alias { (
        "t"  => "tcp",
        "u" => "udp",
        "d" => "discover"

        
    ) }

sub invoke {
    my ($pkg, $cmd, @args) = @_;
    local *ARGV = [$cmd, @args];
    my $ret = eval {
        $pkg->dispatch();
    };
    if( $@ ) {
        warn $@;
    }
}

sub run(){
    my $self=shift;
        $self->global_help if ($self->{help});
}

sub global_help {
    print <<'END';
App::pscan
____________

help (--help for full)
    - show help message

tcp [ip, iprange]:[port] (payload)
    - try to send the payload

udp [ip, iprange]:[port] (payload)
    - try to send the payload

discover [ip, iprange]
    - try to discover hosts in the network

END
}

1;
