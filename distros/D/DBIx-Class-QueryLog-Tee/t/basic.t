#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Deep;

use aliased 'DBIx::Class::QueryLog::Tee';

subtest instantiation => sub {
   ok(Tee->new, 'vanilla');
   ok(Tee->new(loggers => {}), 'empty loggers');
   ok(
      Tee->new(loggers => { a => ValidLogger->new }),
      'valid logger'
   );
   ok(
      exception { Tee->new(loggers => { a => InValidLogger->new }) },
      'invalid logger',
   );
};

subtest mutation => sub {
   my $empty = Tee->new;

   ok(!exception { $empty->add_logger(a => ValidLogger->new) }, 'valid add_logger');
   ok(!exception { $empty->replace_logger(a => ValidLogger->new) }, 'valid replace_logger');
   ok(!exception { $empty->replace_logger(b => ValidLogger->new) }, 'invalid replace_logger');
   ok(!exception { $empty->remove_logger('a') }, 'valid remove_logger');
   ok(exception { $empty->add_logger(a => InValidLogger->new) }, 'invalid add_logger');
   ok(exception { $empty->remove_logger('a') }, 'invalid remove_logger');
   ok(exception { $empty->replace_logger(a => InValidLogger->new) }, 'invalid replace_logger');
};

subtest log => sub {
   my ($a, $b, $c) = map ValidLogger->new, 1..3;
   my $tee = Tee->new(
      loggers => {
         a => $a,
         b => $b,
         c => $c,
      },
   );

   $tee->query_start('foo');
   $tee->query_end('foo');

   cmp_deeply([ $a->_data, $b->_data, $c->_data ],
      [
         [ ['query_start', 1, 'foo'], ['query_end', 4, 'foo']],
         [ ['query_start', 2, 'foo'], ['query_end', 5, 'foo']],
         [ ['query_start', 3, 'foo'], ['query_end', 6, 'foo']],
      ],
      'things get run in the right order',
   );

};

done_testing;

BEGIN {
   package ValidLogger;
   use Sub::Name 'subname';
   use Moo;

   our $i = 1;

   has _data => (
      is => 'ro',
      default => sub { [] },
   );

   for my $m (qw(txn_begin txn_commit txn_rollback svp_begin svp_release svp_rollback query_start query_end)) {
      no strict 'refs';
      *{$m} = subname $m => sub { push @{shift->_data}, [$m, $i++, @_] }
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
