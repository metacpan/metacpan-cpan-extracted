#!/usr/bin/perl

use IO::File;
use DIME::Message;
use DIME::Payload;
use DIME::Parser;

sub generate
{
# Generate a DIME message

my $payload = new DIME::Payload;
$payload->attach(Path => "./test.txt",
		 MIMEType => 'text/plain',
		 Dynamic => 1);

my $payload2 = new DIME::Payload;
my $data = "Hello World!!!";
$payload2->attach(Data => \$data,
		 MIMEType => 'text/plain');

my $message = new DIME::Message;
$message->add_payload($payload);
$message->add_payload($payload2);

my $out = new IO::File("dime.message","w");

$message->print($out);
$out->close();
}

generate();
