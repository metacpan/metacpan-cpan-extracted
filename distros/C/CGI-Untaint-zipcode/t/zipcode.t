#!/usr/bin/perl -w

use Test::More tests => 32;

use strict;
use CGI;
use CGI::Untaint;

my @ok = ('10022', '12345', '90210', '44155', '00123', '76543',
	  '10022-9371', '12345-6789', '90210-0001', '44155-9999',
	  '00123-0000', '76543-2102');

my @not = ('', '123456', '12f45', 'a1234', 'pEaRl', '9876',
	   '10022-', '10022-1', '10022-12', '10022-123', '10022-12345',
	   '10022-1a23', '10022-1234-', '10022-1234-1234',' 12f45-1234',
	   ' 12345', 'OX2 6DP', 'M6H 4E2');

my $count = 1;
my %hash = map { "var" . $count++ => $_ } @ok, @not;
my $q = CGI->new({%hash});
isa_ok( $q, 'CGI' );

my $data = CGI::Untaint->new( $q->Vars );
isa_ok($data, 'CGI::Untaint' );

$count = 0;
foreach (@ok) {
  ++$count;
  ok($data->extract(-as_zipcode => "var$count"), "Valid: " . $q->param("var$count"));
}

foreach (@not) {
  ++$count;
  ok(!$data->extract(-as_zipcode => "var$count"), "Not valid: " . $q->param("var$count"));
}
