#!/usr/local/bin/perl

#
# Test that the primitive operators are working
#

use Convert::BER;

my $sock = require IO::Socket;

print $sock ? "1..5\n" : "1..2\n";

my  $result = pack("C*", 0x30, 0x3D, 0x04, 0x04, 0x46, 0x72, 0x65, 0x64,
			 0x30, 0x13, 0x04, 0x11, 0x41, 0x20, 0x73, 0x74,
			 0x72, 0x69, 0x6E, 0x67, 0x20, 0x66, 0x6F, 0x72,
			 0x20, 0x66, 0x72, 0x65, 0x64, 0x04, 0x03, 0x4A,
			 0x6F, 0x65, 0x30, 0x1B, 0x04, 0x03, 0x68, 0x61,
			 0x73, 0x04, 0x01, 0x61, 0x04, 0x04, 0x6C, 0x69,
			 0x73, 0x74, 0x04, 0x02, 0x6F, 0x66, 0x04, 0x07,
			 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x73);

my $ber = Convert::BER->new($result);

($file = $0) =~ s/t$/dat/;
open(OUT,"> $file");
$ber->write(\*OUT);
close(OUT);

open(IN,"< $file");
sysread(IN,$buffer,1024);
close(IN);

print "not " unless $buffer eq $result;
print "ok 1\n";

open(IN,"< $file");
$ber = Convert::BER->new;
$ber->read(\*IN);
close(IN);

print "not " unless $ber->buffer eq $result;
print "ok 2\n";

unlink($file);

if( require IO::Socket ) {
  use Socket;
  my $src = IO::Socket::INET->new(Proto => 'udp');
  my $dst = IO::Socket::INET->new(Proto => 'udp');
  bind($dst, pack_sockaddr_in(0, INADDR_ANY));
  my $host = $dst->sockhost eq '0.0.0.0' ? '127.0.0.1' : $dst->sockhost;
  my $addr = pack_sockaddr_in($dst->sockport, inet_aton($host));
  $ber->send($src,$addr) or print "not ";
  print "ok 3\n";
  
  my $b2 = Convert::BER->recv($dst) or print "not ";
  print "ok 4\n";
  
  print "not " unless $b2 && $b2->buffer eq $result;
  print "ok 5\n";
  
}
