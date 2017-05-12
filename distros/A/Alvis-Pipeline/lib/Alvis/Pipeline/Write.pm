# $Id: Write.pm,v 1.7 2005/10/24 14:02:44 mike Exp $

package Alvis::Pipeline::Write;
use vars qw(@ISA);
@ISA = qw(Alvis::Pipeline);

use strict;
use warnings;


sub new {
    my $class = shift();
    my(%opts) = @_;

    my $this = bless {}, $class;
    $this->{host} = delete $opts{host}
	or die "new($class) with no host";
    $this->{port} = delete $opts{port}
	or die "new($class) with no port";

    $this->_setopts(%opts);
    $this->{socket} = new IO::Socket::INET(PeerAddr => $this->{host},
					   PeerPort => $this->{port},
					   Proto => "tcp")
	or die("can't connect to '" . $this->{host} . "', ",
	       "port '" . $this->{port} . "': $!");

    binmode $this->{socket}, ":utf8";
    return $this;
}


# Protocol.  Each packet consists of the following:
# 1. Magic string "Alvis::Pipeline\n"
# 2. Decimal-rendered protocol version-number [initially 1] followed by "\n"
# 3. Decimal-rendered integer byte-count, followed by "\n"
# 4. Binary object of length specified in #2.
# 5. Magic string "--end--\n";
#
sub write {
    my $this = shift();
    my($xmlDocument) = @_;

    $xmlDocument = $xmlDocument->toString()
	if ref($xmlDocument);

    my $socket = $this->{socket};
    $socket->print("Alvis::Pipeline\n",
		   1, "\n",
		   length($xmlDocument), "\n",
		   $xmlDocument,
		   "--end--\n");
}


sub close {
    my $this = shift();

    $this->{socket}->close()
	or die "can't close socket: $!";
}


1;
