#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use DBIx::Class::QueryLog::NotifyOnMax;

ok(
   my $ql = DBIx::Class::QueryLog::NotifyOnMax->new,
   'instantiation',
);

{
   my @warnings;

   local $SIG{__WARN__} = sub { push @warnings, \@_ };

   for (1 .. 1000 ) {
      $ql->query_start('SELECT * from foo');
      $ql->query_end('SELECT * from foo');
   }

   is(scalar @warnings, 0, 'no warnings...');

   for (1 .. 1000 ) {
      $ql->query_start('SELECT * from foo');
      $ql->query_end('SELECT * from foo');
   }

   is(scalar @warnings, 1, 'got single warning');

   like($warnings[0][0], qr/query count .* exceeded/, 'got correct warning');
}

$ql->reset;

subtest 'reset works' => sub {
   my @warnings;

   local $SIG{__WARN__} = sub { push @warnings, \@_ };

   for (1 .. 1000 ) {
      $ql->query_start('SELECT * from foo');
      $ql->query_end('SELECT * from foo');
   }

   is(scalar @warnings, 0, 'no warnings...');

   for (1 .. 1000 ) {
      $ql->query_start('SELECT * from foo');
      $ql->query_end('SELECT * from foo');
   }

   is(scalar @warnings, 1, 'got single warning');

   like($warnings[0][0], qr/query count .* exceeded/, 'got correct warning');
};

done_testing;
