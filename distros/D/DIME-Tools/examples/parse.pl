#!/usr/bin/perl

use IO::File;
use DIME::Message;
use DIME::Payload;
use DIME::Parser;

# Open a file a with a DIME message and parse it...

sub parse
{
my $parser = new DIME::Parser();
$f = new IO::File("dime.message","r");
my $message = $parser->parse($f);
$f->close();
for my $i ($message->payloads())
{
	print $i->print_content(\*STDOUT);
}
}

parse();
