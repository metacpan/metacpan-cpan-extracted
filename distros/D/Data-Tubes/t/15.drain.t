use strict;
use Test::More;
use Data::Dumper;
use Storable qw< dclone >;

use Data::Tubes qw< drain >;

my $AREF = [qw< yadda blah >];

sub test_tubes {
   return {
      empty           => sub { return },
      single_simple   => sub { return 'whatevah' },
      single_arrayref => sub { return $AREF },
      records_empty   => sub { return records => [] },
      records_single  => sub { return records => [1] },
      records_multi   => sub { return records => [1 .. 3] },
      iterator_empty => sub {
         return iterator => sub { return }
      },
      iterator_single => sub {
         my @items = (100);
         return iterator => sub {
            return unless @items;
            return shift @items;
           }
      },
      iterator_multi => sub {
         my @chunks = ([1 .. 3], [4 .. 6], [7]);
         return iterator => sub {
            return unless @chunks;
            return @{shift @chunks};
           }
      },
   };
} ## end sub test_tubes

my %results_for;

$results_for{'0.734'} = {
   scalar => {
      empty           => undef,
      single_simple   => 'whatevah',
      single_arrayref => $AREF,
      records_empty   => [],
      records_single  => [1],
      records_multi   => [1 .. 3],
      iterator_empty  => [],
      iterator_single => [100],
      iterator_multi  => [1 .. 7],
   },
   list => {
      empty           => [],
      single_simple   => ['whatevah'],
      single_arrayref => [$AREF],
      records_empty   => [],
      records_single  => [1],
      records_multi   => [1 .. 3],
      iterator_empty  => [],
      iterator_single => [100],
      iterator_multi  => [1 .. 7],
   },
};

$results_for{'0.736'}{scalar} = $results_for{'0.736'}{list} =
  $results_for{'0.734'}{list};

for my $version (sort keys %results_for) {
   local $Data::Tubes::API_VERSION = $version;
   for my $context (qw< scalar list >) {
      my $results = $results_for{$version}{$context};
      my $tubes   = test_tubes();
      for my $name (sort keys %$results) {
         my $tube = $tubes->{$name};
         my $got =
           ($context eq 'scalar')
           ? drain($tube, 0)
           : [drain($tube, 42)];
         is_deeply $got, $results->{$name}, "$version $context $name"
           or diag Dumper($got);
      } ## end for my $name (keys %$results)
   } ## end for my $context (qw< scalar list >)
} ## end for my $version (sort keys...)

done_testing();
