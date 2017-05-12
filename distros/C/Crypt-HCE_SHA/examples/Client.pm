package Client;

use IO::Select;
use IO::Socket;
use strict;
use Carp;
use Sys::Syslog;
use Crypt::HCE_SHA;

my @response;
my $data;

sub new {
    my $class = shift;
    my $self = {};

    bless $self, $class;
    if ((scalar(@_) % 2) != 0) {
	croak "incorrect number of parameters";
    }
    while (@_) {
	my $key = shift(@_);
	my $value = shift(@_);
	$self->{$key} = $value;
    }
    $self->_initialize;
    return $self;
}

sub _initialize {
    my $self = shift;
    my $timeout;

    if (!defined($self->{'Server'})) {
	croak "Client not initialized properly : Server parameter missing";
    }
    if (!defined($self->{'Port'})) {
	croak "Client not initialized properly : Port parameter missing";
    }
    if (!defined($self->{'SKey'})) {
	croak "Client not initialized properly : SKey parameter missing";
    }
    if (!eval {$self->{'Socket'} = IO::Socket::INET->new(PeerAddr => $self->{'Server'},
							 PeerPort => $self->{'Port'},
							 Proto => 'tcp',
							 Reuse => 1); })
    {
	croak "Client couldn't establish a connection to $self->{'Server'}";
    }
    $self->{'Socket'}->autoflush(1);
    srand($$|time()); # poor random generator should be replaced
    $self->{'RKey'} = rand(100000000)+1000000;
    $self->{'HCE'} = Crypt::HCE_SHA->new($self->{'SKey'}, $self->{'RKey'});
    print { $self->{'Socket'} } "$self->{'RKey'}\n";
}

sub send {
    my $self = shift;
    my @items = @_;
    my ($item, $enc_item);

    if (defined($self->{'HCE'})) {
	foreach $item (@items) {
#	    syslog('debug','Client encode: %s',$item);
	    $enc_item = $self->{'HCE'}->hce_block_encode_mime($item);
#	    syslog('debug','Client sending: %s', $enc_item);
	    print { $self->{'Socket'} } "$enc_item\n;
	}
	$enc_item = $self->{'HCE'}->hce_block_encode_mime("+END_OF_LIST");
	print { $self->{'Socket'} } "$enc_item\n";
    } else {
	foreach $item (@items) {
#	    syslog('debug','Client sending: %s',$item);
	    print { $self->{'Socket'} } "$item\n";
	}
	print { $self->{'Socket'} } "+END_OF_LIST\n";
    }
    return 0;
}

sub recv {
    my $self = shift;
    my $fh = $self->{'Socket'};
    my ($data, $dec_data);

    if (defined($self->{'HCE'})) {
	$data = "";
	undef(@response);
	while (<$fh>) {
	    chomp;
	    $data = 1;
#	    syslog('debug','Client recv: %s', $_);
	    $dec_data = $self->{'HCE'}->hce_block_decode_mime($_);
#	    syslog('debug','Client decode: %s', $dec_data);
	    last if ($dec_data eq "+END_OF_LIST");
	    push @response, $dec_data;
	};
	if (!defined $data) {
	    close ($self->{'Socket'});
	    return $data;

	} else {
	    close ($self->{'Socket'});
	    return @response;
	};
    } else {
	$data = "";
	undef(@response);
	while (<$fh>) {
	    chomp;
	    $data = 1;
	    push @response, $_;
	};
	if (!defined $data) {
	    close ($self->{'Socket'});
	    return $data;
	} else {
	    close ($self->{'Socket'});
	    return @response;
	};
    }
}

1;
__END__

#------- POD ------
