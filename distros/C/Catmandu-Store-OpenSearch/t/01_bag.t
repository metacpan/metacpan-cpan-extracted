use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu;
use Catmandu::Sane;
use Catmandu::Util qw(:is);
use File::Basename;
use File::Spec;

plan skip_all => 'To test Modules, set OS_HOST, OS_USER, OS_PASS, OS_INDEX in ENV'
  unless is_string($ENV{OS_HOST}) && exists($ENV{OS_USER}) && exists($ENV{OS_PASS}) && is_string($ENV{OS_INDEX});

sub gen_records {
  my ($size, $cb) = @_;
  state $types = [qw(book journal)];
  for (my $i = 0;$i < $size; $i++) {
    $cb->(+{
      _id   => sprintf("%09d", $i +1),
      title => "Title $i",
      year  => int(rand() * 2024),
      type  => $types->[int(rand()*scalar(@$types))]
    });
  }
}

my $this_dir = dirname(__FILE__);
Catmandu->load($this_dir);

my $config = Catmandu->config;
$config->{store}{search}{options}{hosts} = [$ENV{OS_HOST}];
$config->{store}{search}{options}{user} = $ENV{OS_USER};
$config->{store}{search}{options}{pass} = $ENV{OS_PASS};
$config->{store}{search}{options}{bags}{publication}{index} = $ENV{OS_INDEX};

my $store;
my $bag;

lives_ok(sub {
  $store = Catmandu->store('search');
}, 'initialize catmandu store');
isa_ok($store, 'Catmandu::Store::OpenSearch');

ok($store->does('Catmandu::Store'), 'implements Catmandu::Store');

lives_ok(sub {
  $bag = $store->bag('publication');
}, 'initialize catmandu bag');
isa_ok($bag, 'Catmandu::Store::OpenSearch::Bag');

for (qw(Catmandu::Bag Catmandu::Droppable Catmandu::Flushable Catmandu::CQLSearchable)) {
  ok($bag->does($_), "implements $_");
}

# Bag functionality
lives_ok(sub {
  $bag->delete_all;
  $bag->commit;
}, 'clear index on start');

my $records = [];
gen_records(10, sub { push @$records, shift; });
$records    = [sort { $a->{_id} <=> $b->{_id} } @$records];

lives_ok(sub {
  $bag->add_many($records);
}, 'add multiple records (without commit)');

is($bag->count, 0, 'no records found without commit');

lives_ok(sub {
  $bag->commit;
}, 'commit changes');

is($bag->count, scalar(@$records), 'expected amount of records found after commit');

is_deeply($records, $bag->to_array, 'records in index are exactly the same');

for my $record (@$records) {
  lives_ok(sub {
    my $irecord = $bag->get($record->{_id});
    is_deeply($record, $irecord, "$record->{_id} same in index as stored");
  }, "retrieve and compare record $record->{_id} by bag->get");
}

lives_ok(sub {
  $bag->delete($records->[0]->{_id});
}, 'delete first record (without commit)');

is($bag->count, scalar(@$records), 'no deletion applied without commit');

lives_ok(sub {
  $bag->commit;
}, 'commit delete changes');

is($bag->count, scalar(@$records) - 1, 'deletions applied after commit');

shift(@$records);

lives_ok(sub {
  $bag->delete_by_query(query => {match_all => {}});
}, 'remove all records (without commit)');

is($bag->count, scalar(@$records), 'no deletion applied without commit');

lives_ok(sub {
  $bag->commit;
}, 'commit delete changes');

is($bag->count, 0, 'deletions applied after commit');

# Searcher functionality
my $count_records = 100;
lives_ok(sub {
  gen_records($count_records, sub {
    $bag->add(shift);
  });
  $bag->commit;
});

my $searcher;
lives_ok(sub {
  $searcher = $bag->searcher(query => {match_all => {}});
}, 'searcher requires query');

isa_ok($searcher, 'Catmandu::Store::OpenSearch::Searcher');

is($searcher->count, $count_records);

is($searcher->slice(1)->count, $count_records - 1);
is($searcher->slice(2)->count, $count_records - 2);
is($searcher->slice(0, 2)->count, 2);
is($searcher->slice(0, 2000)->count, $count_records);

done_testing;