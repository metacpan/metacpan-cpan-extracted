#!/usr/bin/perl -w

use Test::More tests => 15;

use strict;
use CGI;
use CGI::Untaint;

my @ok = (
  'http://c2.com/cgi/wiki',
  'www.tmtm.com',
  'www.tmtm.com or www.ebay.com',
  'See: http://www.redmeat.com/redmeat/1996-09-30/',
  '[http://www.angelfire.com/la/carlosmay/Tof.html]',
  'ftp://ftp.ftp.org/',
);

my @not = (
  'random string of text',
  'tmtm.com', 
);

my $count = 1;
my %hash = map { "var" . $count++ => $_ } @ok, @not;
my $q = CGI->new({%hash});

ok(my $data = CGI::Untaint->new( $q->Vars ), "Can create the handler");

$count = 0;
foreach (@ok) {
  ++$count;
  my $url = $data->extract(-as_url => "var$count");
  isa_ok $url, 'URI::URL';
  ok($url, "Valid: $url");
}

foreach (@not) {
  ++$count;
  my $url = $data->extract(-as_url => "var$count");
  ok !$url, "Not valid: " . $q->param("var$count");
}
