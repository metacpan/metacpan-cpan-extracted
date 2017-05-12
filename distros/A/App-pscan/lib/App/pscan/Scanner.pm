package App::pscan::Scanner;
use Net::IP;
use App::pscan::Utils;


sub run {
    my $self = shift;
    $self->_gen_range(shift);
    $self->scan();

}

sub _gen_range() {
    my $self = shift;
    my $cmd=shift;
    my $Ip;
    my $Port;
    if($cmd=~/:/){
         ( $Ip, $Port ) = split( /:/, $cmd );

    } else {
        $Ip=$cmd;
    }

    if ( my $IP = new Net::IP($Ip) ) {
        $Ip=$IP;

    }
    else {
        info "Resolving $Ip";
        $Ip = resolve($Ip);
        $Ip =new Net::IP($Ip);
    }

    if ( !defined($Ip) ) {
        error "! No ip to scan";
        exit;
    } else {
            info '- starting scan -';

    }

    my ( $f, $l ) = generate_ports($Port) if $Port;

    info 'Scanning for ' . ( ( $l + 1 ) - $f ) . ' port(s)' if $Port;

    $self->{'IP'}    = $Ip;
    $self->{'first'} = $f if $Port;
    $self->{'last'}  = $l if $Port;

}

1;
