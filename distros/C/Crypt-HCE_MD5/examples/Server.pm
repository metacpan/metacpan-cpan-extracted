package Server;

use IO::Select;
use IO::Socket;
use strict;
use Carp;
use Sys::Syslog;
use Crypt::HCE_MD5;

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

    if (!defined($self->{'Server'})) {
	croak "Server not initialized properly : Server parameter missing";
    }
    if (!defined($self->{'Port'})) {
	croak "Server not initialized properly : Port parameter missing";
    }
    if (!defined($self->{'Queue'})) {
	croak "Server not initialized properly : Queue parameter missing";
    }
    if (!eval {$self->{'Socket'} = IO::Socket::INET->new(LocalAddr => $self->{'Server'},
							 LocalPort => $self->{'Port'},
							 Proto => 'tcp',
							 Reuse => 1,
							 Listen => $self->{'Queue'} 
							 ); })
    {
	croak "Server couldn't establish a port on $self->{'Server'}";
    }
    $self->{'Socket'}->autoflush(1);
    delete $self->{'HCE'};
    $self->{'Select'} = IO::Select->new($self->{'Socket'});
}

sub accept {
    my $self = shift;
    my ($time) = @_; # how long to wait
    my (@ready_to_read, $size);

    @ready_to_read = $self->{'Select'}->can_read($time);
    $size = scalar(@ready_to_read);
    if ($size == 1) {
	$self->{'Connect'} = $self->{'Socket'}->accept;
	$self->{'Connect'}->autoflush(1); # don't buffer return messages
    } else {
	delete $self->{'Connect'};
    }
    return $size;
}

sub close {
    my $self = shift;

    $self->{'Connect'}->close;
    delete $self->{'Connect'};
    delete $self->{'HCE'};
    return 0;
}

sub send {
    my $self = shift;
    my @items = @_;
    my ($item, $enc_item);

    if (!defined($self->{'Connect'})) {
	croak "No Connection established: did you accept?";
    }
    if (defined($self->{'HCE'})) {
	foreach $item (@items) {
#	    syslog('debug','Server encode: %s',$item);
	    $enc_item = $self->{'HCE'}->hce_block_encode_mime($item);
#	    syslog('debug','Server sending: %s', $enc_item);
	    print { $self->{'Connect'} } "$enc_item\n";
	}
	$enc_item = $self->{'HCE'}->hce_block_encode_mime("+END_OF_LIST");
	print { $self->{'Connect'} } "$enc_item\n";
    } else {
	foreach $item (@items) {
#	    syslog('debug','Server sending: %s',$item);
	    print { $self->{'Connect'} } "$item\n";
	}
    }
    return 0;
}

sub recv {
    my $self = shift;
    my ($data, $dec_data, $fh);

    if (!defined($self->{'Connect'})) {
	croak "No Connection established: did you accept?";
    }
    $fh = $self->{'Connect'};
    undef(@response);
    if (!defined($self->{'SKey'})) {
	while (<$fh>) {
	    chomp;
#           syslog('debug','Server recv: %s', $_);
	    tr/\n\r\t//d;
	    last if ($_ eq '+END_OF_LIST');
	    push @response, $_;
	};
	if (!defined(@response)) {
	    return;
	} else {
	    return @response;
	}
    }
    if (defined($self->{'HCE'})) {
	while (<$fh>) {
	    chomp;
#	    syslog('debug','Server recv: %s',$_);
	    $dec_data = $self->{'HCE'}->hce_block_decode_mime($_);
	    $dec_data =~ tr/\n\r\t//d;
#	    syslog('debug','Server decode: %s', $dec_data);
	    last if ($dec_data eq "+END_OF_LIST");
	    push @response, $dec_data;
	};
	if (!defined(@response)) {
	    return;
	} else {
	    return @response;
	};
    } else {
	$_ = <$fh>; # get RKey
	chomp;
	$self->{'RKey'} = $_;
	$self->{'HCE'} = Crypt::HCE_MD5->new($self->{'SKey'}, $self->{'RKey'});
	return $self->recv();
    }
}

1;
__END__

#------- POD ------
