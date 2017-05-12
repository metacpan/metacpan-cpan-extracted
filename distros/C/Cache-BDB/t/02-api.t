use Test::More tests => 60;
use Cache::BDB;
use BerkeleyDB;
use File::Path qw(rmtree);

my %options = (
	cache_root => './t/02',
	namespace => "Cache::BDB::02",
	default_expires_in => 10,
);	

END {
   rmtree($options{cache_root});
}

my $hash1 = {foo=>'bar'};
my $hash2 = {bleh => 'blah', doof => [4,6,9]};
my $array1 = [1, 'two', 3];
my $array2 = [3,12,123,213,213213,4354356,565465,'das1', 'two', 3];
my $obj1 = bless ( {foo => $hash1, bleh => $hash2, moobie => $array2},  'Some::Class');
my $c = Cache::BDB->new(%options);

ok(-e join('/', 
	   $options{cache_root},
	   'Cache::BDB::02.db'));

isa_ok($c, 'Cache::BDB');
can_ok($c, qw(set get remove purge size count namespace));

is($c->set(1, $hash1), 1);
is_deeply($c->get(1), $hash1);
is($c->count, 1);

is($c->set(2, $hash2),1);
is_deeply($c->get(2), $hash2);
is($c->count, 2);

is($c->set(3, $array1),1);
is_deeply($c->get(3), $array1);
is($c->count, 3);

is($c->set(4, $obj1),1);
is_deeply($c->get(4), $obj1);
is($c->count, 4);
is($c->count, scalar(keys %{$c->get_bulk}));

is($c->remove(1), 1);
is($c->get(1),undef);
is($c->count, 3);

is($c->set(5, $array2,2),1);
is($c->count, 4);

is($c->set(6, $hash1,5),1);
is($c->count, 5);

sleep 3;

is($c->is_expired(5), 1, "expired? (should be)");
is($c->purge(), 1);

is($c->is_expired(6), 0, "expired? (shouldn't be)");
is($c->get(5),undef);

is($c->count, 4);
is_deeply($c->get(6),$hash1);

is($c->clear(), 4);
is($c->get(2),undef);
is($c->get(3),undef);

is($c->count, 0);

is($c->set(7, $hash1),1);
is($c->set(8, $hash2),1);
is($c->set(9, $array1),1);
is($c->set(10, $array2),1);

is($c->count, 4);

is($c->set(10, $hash2), 1);

is_deeply($c->get(10), $hash2);

undef $c;
is(undef, $c);
my $c2 = Cache::BDB->new(%options);

is_deeply($c2->get(7), $hash1);
is_deeply($c2->get(8), $hash2);
is_deeply($c2->get(9), $array1);
is_deeply($c2->get(10), $hash2);

is($c2->set('foo', 'bar'),1);
is($c2->get('foo'), 'bar');

my %h = (some => 'data', goes => 'here');
is($c2->set(100, \%h), 1);

is_deeply(\%h, $c2->get(100));

is($c2->add(100, \%h), 0, "Can't add, already exists");
is($c2->replace(100, \%h), 1, 'Can replace, already exists');

is($c2->add(101, \%h), 1, "Can add, doesn't exist yet");
is($c2->replace(102, \%h), 0, "Can't replace, doesn't exist");

is($c2->is_expired(6), 0, "expired? (should be by now)");

SKIP: {
  eval { require Devel::Size };
  skip "Devel::Size note available", 3 if $@;

  ok($c2->size > 0);
  ok($c2->clear());
  ok($c2->size == 0);

}

SKIP: {
  skip "db->compact not available", 2  unless 
    ($BerkeleyDB::VERSION >= 0.29 && $BerkeleyDB::db_version >= 4.4);
  # add a bunch of data
  map { $c2->set($_, $_ * rand(int(20))) } (1 .. 12345);

  my $h = $c2->get_bulk();
  is(scalar(keys %$h), $c2->count);
  # and see how big the file is
  my $size_before = (stat(join('/', $options{cache_root}, 
			       'Cache::BDB::02.db')))[7];

  my $count_before = $c2->count();

  # clear it out
  is($c2->clear(), $count_before);

  # and check again.
  my $size_after = (stat(join('/', $options{cache_root},
			      'Cache::BDB::02.db')))[7];

  ok($size_before > $size_after);
}

