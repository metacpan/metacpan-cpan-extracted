#!perl -T

use Test::More tests => 2;

BEGIN {
  use_ok('Authen::CAS::Client');
}

diag("Testing Authen::CAS::Client $Authen::CAS::Client::VERSION, Perl $], $^X");

my $cas = Authen::CAS::Client->new( 'https://example.com/cas' );

isa_ok($cas, 'Authen::CAS::Client');
