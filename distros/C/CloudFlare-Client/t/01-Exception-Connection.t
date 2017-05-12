#!perl -T
use strict; use warnings; no indirect 'fatal'; use namespace::autoclean;

use Test::More; use Test::Moose; use Test::Exception;
use Try::Tiny;
use Readonly;

use CloudFlare::Client::Exception::Connection;

plan tests => 8;

# Test for superclass
Readonly my $CLASS => 'CloudFlare::Client::Exception::Connection';
isa_ok( $CLASS, 'Throwable::Error', 'Class superclass');
# Test for status accessor
can_ok( $CLASS, 'status');
# Tests for moose
Readonly my $MSG    => 'Doesn\'t Matter';
Readonly my $STATUS => '404';
meta_ok($CLASS);
has_attribute_ok( $CLASS, 'status', 'status attribute');
my $e = try { $CLASS->new( message => $MSG, status => $STATUS)};
meta_ok($e);

# Construction
# with status
lives_and { new_ok( $CLASS => [ message   => $MSG, status => $STATUS])}
          "construction works with status attr";
# Missing message attr
throws_ok { $CLASS->new(status => $STATUS)}
          qr/^Attribute \(message\) is required/,
          'Construction with missing message attr dies';
# Extra attr
throws_ok { $CLASS->new( message => $MSG, status => $STATUS, extra => 'arg')}
          qr/^Found unknown attribute\(s\)/,
          'construction with extra attr throws exception';
