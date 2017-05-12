
############################################################################
# Connection object
# derived from Net::Inspect::L7::HTTP
# just pipes all input into conn->in(...)
############################################################################

use strict;
use warnings;

package App::HTTP_Proxy_IMP::Conn;
use base 'Net::Inspect::L7::HTTP';
use App::HTTP_Proxy_IMP::Debug;
use Scalar::Util 'weaken';
use fields (
    # all connections
    'pcapdir',     # dir for writing pcaps
    'mitm',        # IO::Socket::SSL::Intercept object for SSL interception
    'capath',      # path to file|direcory with CA certificates
    'imp_factory', # App::HTTP_Proxy_IMP::IMP factory
    # per connection
    'spool',       # any data which cannot be processed yet?
    'pcapw',       # Net::PcapWriter object
    'intunnel',    # true if connections is inside intercepted SSL tunnel
    'relay',       # weak reference to managing relay
);

sub new {
    my ($class,$upper_flow,%args) = @_;
    my $self = $class->SUPER::new($upper_flow);
    %$self = ( %$self, %args ) if %args;
    if ( ref($class)) { # from factory
	$self->{pcapdir} ||= $class->{pcapdir};
	$self->{imp_factory} ||= $class->{imp_factory};
	$self->{mitm} ||= $class->{mitm};
	$self->{capath} ||= $class->{capath};
    }
    return $self;
}

sub DESTROY { 
    my $self = shift or return;
    $self->xdebug("connection done"); 
    $self->SUPER::DESTROY();
}

sub clone {
    my $self = shift;
    return $self->new_connection(
	$self->{meta},
	$self->{relay}
    );
}

sub new_connection {
    my ($self,$meta,$relay) = @_;
    my $obj = $self->SUPER::new_connection($meta);

    if ( my $pcapdir = $self->{pcapdir} ) {
	open( my $fh,'>', sprintf("%s/%d.%d.pcap",$pcapdir,$$,$obj->{connid}))
	    or die "cannot open pcap file: $!";
	$fh->autoflush;
	my $w = Net::PcapWriter->new($fh);
	my $c = $w->tcp_conn( 
	    $meta->{daddr}, $meta->{dport},
	    $meta->{saddr}, $meta->{sport} 
	);
	$obj->{pcapw} = [$c,$w],
    }

    weaken( $obj->{relay} = $relay );
    return $obj;
}

sub in {
    my $self = shift;
    return $self->SUPER::in(@_) if ! $self->{pcapw};
    my ($dir,$data,$eof,$time) = @_;
    if ( defined ( my $bytes = eval { $self->SUPER::in(@_) } )) {
	$self->{pcapw}[0]->write($dir,substr($data,0,$bytes));
	return $bytes;
    } else {
	# save final data
	$self->{pcapw}[0]->write($dir,$data);
	die $@ if $@;
	return;
    }
}


sub id {
    my $self = shift;
    return "$$.$self->{connid}";
}


1;
