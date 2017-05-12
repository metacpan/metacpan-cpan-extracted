#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Deep;

use aliased 'DBIx::Class::QueryLog::Conditional';

subtest instantiation => sub {
   ok(
      Conditional->new(logger => ValidLogger->new ),
      'valid logger'
   );
   ok(
      exception { Conditional->new(logger => InValidLogger->new ) },
      'invalid logger',
   );
};

subtest 'vanilla log' => sub {
   my $a = ValidLogger->new;
   my $tee = Conditional->new( logger => $a );

   $tee->query_start('foo');
   $tee->query_end('foo');

   cmp_deeply($a->_data,
      [ ['query_start', 'foo'], ['query_end', 'foo'] ],
      'messages passed through correctly',
   );

   $a->reset_data;

   $tee->enabled(0);

   $tee->query_start('foo');
   $tee->query_end('foo');

   cmp_deeply($a->_data,
      [],
      'disabling logger works',
   );

};

subtest 'custom log' => sub {
   my $a = ValidLogger->new;
   my $b = 1;
   my $tee = Conditional->new(
      logger => $a,
      enabled_method => sub { $b },
   );

   $tee->query_start('foo');
   $tee->query_end('foo');

   cmp_deeply($a->_data,
      [ ['query_start', 'foo'], ['query_end', 'foo'] ],
      'messages passed through correctly',
   );

   $a->reset_data;

   $b = 0;

   $tee->query_start('foo');
   $tee->query_end('foo');

   cmp_deeply($a->_data,
      [],
      'disabling logger works',
   );

};

done_testing;

BEGIN {
   package ValidLogger;
   use Sub::Name 'subname';
   use Moo;

   has _data => (
      is => 'ro',
      lazy => 1,
      default => sub { [] },
      clearer => 'reset_data',
   );

   for my $m (qw(txn_begin txn_commit txn_rollback svp_begin svp_release svp_rollback query_start query_end)) {
      no strict 'refs';
      *{$m} = subname $m => sub { push @{shift->_data}, [$m, @_] }
   }
}

BEGIN {
   package InValidLogger;
   use Sub::Name 'subname';
   sub new { bless {}, shift }
   for my $m (qw(txn_begin txn_commit txn_rollback svp_begin svp_release svp_rollback)) {
      no strict 'refs';
      *{$m} = subname $m => sub { }
   }
}
