#!/usr/bin/perl

use strict;
use FCGI;
use Data::Dumper;
use IO::Handle;

my $count = 0;

my $in = new IO::Handle;
my $out = new IO::Handle;
my $err = new IO::Handle;
my $r = FCGI::Request($in,$out,$err);

while($r->Accept() >= 0) {
  my $me = `whoami`;
  $out->print( "Content-type: text/html\r\n\r\n");
  $out->print( "<pre>");
  $out->print( "Count: ",($count+=3),"\n");
  $out->print( "Me: $me\n");
  $out->print( "Env: " . Dumper(\%ENV) . "\n");
  $out->print( "Len: " . $ENV{'CONTENT_LENGTH'} . "\n");
  if($ENV{'CONTENT_LENGTH'}) {
    my $len = $ENV{'CONTENT_LENGTH'};
    my $buf;
    read(STDIN,$buf,$len);
    $out->print( "POST ($len): $buf\n");
  }
}

