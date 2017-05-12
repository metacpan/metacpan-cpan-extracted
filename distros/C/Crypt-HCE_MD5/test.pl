# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..4\n"; }
END {print "not ok 1\n" unless $loaded;}
use Crypt::HCE_MD5;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$text = "Encrypt and Base64 this information, and we will make sure this is longer than 64 characters just to make sure it is working and not getting caught in a block roll over";

#$text = "short text";
$hce_md5 = Crypt::HCE_MD5->new("SharedSecret", "Random01,39j309ad");

$crypted = $hce_md5->hce_block_encrypt("Encrypt this information");
$info = $hce_md5->hce_block_decrypt($crypted);
if ($info eq "Encrypt this information") {
    print "ok 2\n";
} else {
    print "not ok 2\n";
}

$mime_crypted = $hce_md5->hce_block_encode_mime($text);
$info = $hce_md5->hce_block_decode_mime($mime_crypted);

if ($info eq $text) {
    print "ok 3\n";
} else {
    $l_info = length($info);
    $l_text = length($text);
    print "not ok 3 [$info] [$l_info =? $l_text]\n";
}

$pid = fork();
if ($pid < 0) {
    die "Couldn't fork";
}
if ($pid != 0) {
    $server = Server->new(Server => 0, Port => 5050, SKey => "SharedSecret", Queue => 1);
    $cons = $server->accept(5);
    if ($cons == 0) {
	die "accept timed out";
    }
    print "server waiting to recieve\n";
    @info = $server->recv();
    print "server received, server sending\n";
    $server->send(@info);
    print "server waiting\n";
    wait;
} else {
    sleep 3;
    $client = Client->new(Server => localhost, Port => 5050, SKey => "SharedSecret");
    print "client sending\n";
    $client->send($text."-- Encrypt this information");
    print "client recieving\n";
    @info_back = $client->recv();
    print "client checking response\n";
    if ($info_back[0] eq $text."-- Encrypt this information") {
	print "ok 4\n";
    } else {
	print "not ok 4\n";
    }
    exit 0;
}

package Server;

use IO::Select;
use IO::Socket;
use strict;
use Carp;
#use HCE_MD5;

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
	    print "Server encode: $item\n";
	    $enc_item = $self->{'HCE'}->hce_block_encode_mime($item);
	    print "Server sending: $enc_item\n";
	    print { $self->{'Connect'} } "$enc_item\n";
	}
	$enc_item = $self->{'HCE'}->hce_block_encode_mime("+END_OF_LIST");
	print { $self->{'Connect'} } "$enc_item\n";
    } else {
	foreach $item (@items) {
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
            print "Server recv: $_\n";
	    tr/\n\r\t//d;
	    last if ($_ eq '+END_OF_LIST');
	    push @response, $_;
	};
	if (!(@response)) {
	    return;
	} else {
	    return @response;
	}
    }
    if (defined($self->{'HCE'})) {
	while (<$fh>) {
	    chomp;
	    print "Server recv: $_\n";
	    $dec_data = $self->{'HCE'}->hce_block_decode_mime($_);
	    $dec_data =~ tr/\n\r\t//d;
	    print "Server decode: $dec_data\n";
	    last if ($dec_data eq "+END_OF_LIST");
	    push @response, $dec_data;
	};
	if (!(@response)) {
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

package Client;

use IO::Select;
use IO::Socket;
use strict;
use Carp;
#use HCE_MD5;

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
    $self->{'HCE'} = Crypt::HCE_MD5->new($self->{'SKey'}, $self->{'RKey'});
    print { $self->{'Socket'} } "$self->{'RKey'}\n";
}

sub send {
    my $self = shift;
    my @items = @_;
    my ($item, $enc_item);

    if (defined($self->{'HCE'})) {
	foreach $item (@items) {
	    $enc_item = $self->{'HCE'}->hce_block_encode_mime($item);
	    print { $self->{'Socket'} } "$enc_item\n";
	}
	$enc_item = $self->{'HCE'}->hce_block_encode_mime("+END_OF_LIST");
	print { $self->{'Socket'} } "$enc_item\n";
    } else {
	foreach $item (@items) {
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
	    print "Client recv: $_\n";
	    $dec_data = $self->{'HCE'}->hce_block_decode_mime($_);
	    print "Client decode: $dec_data\n";
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

