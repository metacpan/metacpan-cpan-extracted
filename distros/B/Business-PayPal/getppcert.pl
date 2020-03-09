#!/usr/bin/env perl
use strict;
use warnings;

#this is a hacked up version of one of the examples in the Net::SSLeay
#documentation,  It will return a x509 cert and contents sufficient for
#use in Business::PayPal.pm  just use
# perl ./getppcert.pl >> PayPal.pm to append the new data
use Socket;
use Net::SSLeay qw(die_now die_if_ssl_error) ;

Net::SSLeay::load_error_strings();
Net::SSLeay::SSLeay_add_ssl_algorithms();
Net::SSLeay::randomize();

my ($dest_serv, $port, $msg) = ('www.paypal.com', '443', 'GET /');
$port = getservbyname ($port, 'tcp') unless $port =~ /^\d+$/;
my $dest_ip = gethostbyname ($dest_serv);
my $dest_serv_params  = sockaddr_in($port, $dest_ip);

socket  (S, &AF_INET, &SOCK_STREAM, 0)  or die "socket: $!";
connect (S, $dest_serv_params)          or die "connect: $!";
select  (S); $| = 1; select (STDOUT);   # Eliminate STDIO buffering

# The network connection is now open, lets fire up SSL

my $ctx = Net::SSLeay::CTX_new() or die_now("Failed to create SSL_CTX $!");
Net::SSLeay::CTX_set_options($ctx, &Net::SSLeay::OP_ALL)
    and die_if_ssl_error("ssl ctx set options");

my $ssl = Net::SSLeay::new($ctx) or die_now("Failed to create SSL $!");
Net::SSLeay::set_fd($ssl, fileno(S));   # Must use fileno

my $res = Net::SSLeay::connect($ssl) and die_if_ssl_error("ssl connect");
#  print "Cipher `" . Net::SSLeay::get_cipher($ssl) . "'\n";
print Net::SSLeay::dump_peer_certificate($ssl),"\n";
my $cert = Net::SSLeay::get_peer_certificate($ssl);
print Net::SSLeay::PEM_get_string_X509($cert),"\n";
# print Net::SSLeay::get_verify_result($ssl),"\n";
# Exchange data

$res = Net::SSLeay::write($ssl, $msg);  # Perl knows how long $msg is
die_if_ssl_error("ssl write");
shutdown S, 1;  # Half close --> No more output, sends EOF to server

my $got = Net::SSLeay::read($ssl);         # Perl returns undef on failure
die_if_ssl_error("ssl read");
# print $got;

Net::SSLeay::free ($ssl);               # Tear down connection
Net::SSLeay::CTX_free ($ctx);
close S;

