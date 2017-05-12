use Test::More tests => 73;
use Cwd;
use File::Path qw(rmtree);

use_ok('Cache::BDB');
use Cache::BDB;

my $cache_root_base = './t/01';

END {
  rmtree($cache_root_base);
}

# verify that we can create a cache with no explicit file name and that its 
# db file will web named $namespace.db

my $c = Cache::BDB->new(cache_root => $cache_root_base,
			namespace => 'test',
			default_expires_in => 10,
			type => 'Btree');

ok(-e join('/', 
	   $cache_root_base,
	   'test.db'));

# verify that we'll create a full path if need be
my $f = Cache::BDB->new(cache_root => join('/',
					   $cache_root_base,
					   'Cache::BDB',
					   $$,
					   'test'),
			namespace => 'whatever');

ok(-e join('/', 
	   $cache_root_base,
	   'Cache::BDB',
	   $$,
	   'test',
	   'whatever.db'));


# verify that we can create a single file with multiple dbs
my @names = qw(one two three four five six seven eight nine ten);

for my $name (@names) {
  my %options = (
		 cache_root => $cache_root_base,
		 namespace => $name,
		 default_expires_in => 10,
    );	

    $options{type} = 'Hash' if $name eq 'two';
#    diag("\ncreating namespace $name in db one.db");
    my $c = Cache::BDB->new(%options);
    isa_ok($c, 'Cache::BDB');
    is($c->set('namespace', $name),1);
    is($c->count(), 1);
    is($c->close(), undef);
}

# verify that those databases can be connected to and contain what we
# put in them

for my $name (@names) {
    my %options = (
	cache_root => $cache_root_base,
	namespace => $name,
	default_expires_in => 10,
    );	

 #   diag("connecting to namespace $name in db one.db");
    diag("expect a warning here") if $name eq 'two';
    my $c = Cache::BDB->new(%options);
    isa_ok($c, 'Cache::BDB');
    is($c->get('namespace'), $name);
    is($c->count(), 1);
    undef $c;
}

