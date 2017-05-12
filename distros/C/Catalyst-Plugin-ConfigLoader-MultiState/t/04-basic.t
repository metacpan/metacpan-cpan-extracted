use strict;
use warnings;
use Test::More qw/no_plan/;
use FindBin;
use lib "$FindBin::Bin/lib";

use Catalyst::Test 'TestApp';

my $cfg = TestApp->cfg;

is(ref $cfg->{root}, 'Path::Class::Dir', 'basic_catbase');

is($cfg->{s}, 1, 'basic_scalar');

is(ref $cfg->{a}, 'ARRAY', 'basic_array1');
is($cfg->{a}[2], 3, 'basic_array2');

is(ref $cfg->{h}, 'HASH', 'basic_hash1');
is($cfg->{h}{b}, 2, 'basic_hash2');

1;
