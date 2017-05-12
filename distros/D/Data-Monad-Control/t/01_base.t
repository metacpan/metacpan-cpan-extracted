use strict;
use warnings;
use Test::More;

use Data::Monad::Control qw( try );

subtest 'try' => sub {
  subtest 'will live' => sub {
    my $e = try { 'ok' };
    isa_ok $e, 'Data::Monad::Either';
    ok $e->is_right;
    is $e->value, 'ok';
  };
  subtest 'will live (with multiple values)' => sub {
    my ($e) = try { ('ok', 1) };
    isa_ok $e, 'Data::Monad::Either';
    ok $e->is_right;
    is_deeply [ $e->value ], [ 'ok', 1 ];
  };
  subtest 'will live (no values bound)' => sub {
    local $@;
    eval { try { 'ok' } };
    is $@, '', 'no errors';
  };
  subtest 'will die' => sub {
    my $e = try { die 'Oops'; 'ok'; };
    isa_ok $e, 'Data::Monad::Either';
    ok $e->is_left;
    like $e->value, qr/Oops at/;
  };
};

done_testing;
