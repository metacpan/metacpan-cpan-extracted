use Test::More;
use strict;

use Config::Path;

my $conf = Config::Path->new(files => [ 't/conf/complex.yml' ]);
ok(defined($conf));

use Data::Dumper;
is_deeply($conf->fetch('thingies'), [ { name => 'thing1' }, { name => 'thing2' } ], 'fetching an array of hashes');

done_testing;