use strict;
use warnings;

use Test::More;

use DBIO::Test;
use DBIO::ResultClass::HashRefInflator;

# Exercises both invocation styles from the DBIO::ResultClass::HashRefInflator
# SYNOPSIS: setting result_class on a resultset, and passing it as a search
# attribute. Either way, iteration must yield plain unblessed hashrefs
# instead of Row objects.

my $schema  = DBIO::Test->init_schema(no_deploy => 1);
my $storage = $schema->storage;

subtest 'SYNOPSIS: $rs->result_class(...) then $rs->next returns a plain hashref' => sub {
  $storage->mock(qr/SELECT.*FROM "artist"/i, [
    [ 1, 'Caterwauler McCrae', 13, undef ],
    [ 2, 'Random Boy Band',     5, undef ],
  ]);

  my $rs = $schema->resultset('Artist');
  $rs->result_class('DBIO::ResultClass::HashRefInflator');

  my $first = $rs->next;
  is ref($first), 'HASH', 'next() returns a plain HASH ref, not a Row object';
  ok !eval { $first->isa('DBIO::Row') }, 'the hashref is not a blessed Row';
  is_deeply(
    $first,
    { artistid => 1, name => 'Caterwauler McCrae', rank => 13, charfield => undef },
    'the hashref carries the correct column data for the first row'
  );

  my $second = $rs->next;
  is_deeply(
    $second,
    { artistid => 2, name => 'Random Boy Band', rank => 5, charfield => undef },
    'the hashref carries the correct column data for the second row'
  );
};

subtest 'SYNOPSIS: result_class as a search attribute' => sub {
  $storage->mock(qr/SELECT.*FROM "artist"/i, [
    [ 3, 'We Are Goth', 1, undef ],
  ]);

  my $rs = $schema->resultset('Artist')->search({}, {
    result_class => 'DBIO::ResultClass::HashRefInflator',
  });

  my @all = $rs->all;
  is scalar(@all), 1, 'one row returned';
  is ref($all[0]), 'HASH', 'result_class as a search attribute also yields a plain hashref';
  is $all[0]{name}, 'We Are Goth', 'the hashref data is correct';
};

done_testing;
