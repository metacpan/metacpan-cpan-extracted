#!/usr/bin/perl
use strict;
use warnings;
my $num_tests;
BEGIN { $num_tests = 0; };
use Test::More;
use Test::Exception;
use File::Temp qw(tempfile);
use IO::File;

use aliased 'AI::Evolve::Befunge::Blueprint' => 'Blueprint';

# new
my $blueprint = Blueprint->new(code => '0'x16, dimensions => 4);
ok(ref($blueprint) eq "AI::Evolve::Befunge::Blueprint", "create an blueprint object");
is($blueprint->code,    '0000000000000000','code as passed');
is($blueprint->dims,    4,                 '4 dimensions');
is($blueprint->id,      1,                 'default id');
is($blueprint->host,    $ENV{HOST},    'default hostname');
is($blueprint->fitness, 0,                 'default fitness');
dies_ok( sub { Blueprint->new(); }, "Blueprint->new dies without code argument");
like($@, qr/Usage: /, "died with usage message");
dies_ok( sub { Blueprint->new(code => 'abc'); }, "Blueprint->new dies without dimensions argument");
like($@, qr/Usage: /, "died with usage message");
dies_ok( sub { Blueprint->new(code => 'abc', dimensions => 4); }, "Blueprint->new dies without code argument");
like($@, qr/non-orthogonal/, "died with non-orthogonality message");
lives_ok( sub { Blueprint->new(code => 'a'x16, dimensions => 4); }, "Blueprint->new lives");
$blueprint = Blueprint->new(code => ' 'x8, dimensions => 3, fitness => 1, id => 321, host => 'foo');
is($blueprint->code,    '        ','code as passed');
is($blueprint->dims,    3,         'dims as passed');
is($blueprint->id,      321,       'id as passed');
is($blueprint->host,    'foo',     'hostname as passed');
is($blueprint->fitness, 1,         'fitness as passed');
BEGIN { $num_tests += 18 };

# new_from_string
$blueprint = Blueprint->new_from_string("[I42 D4 F316512 Hfoo]k\n");
is($blueprint->id,      42,     "id parsed successfully");
is($blueprint->dims,    4,      "dims parsed successfully");
is($blueprint->fitness, 316512, "fitness parsed successfully");
is($blueprint->host,    'foo',  "host parsed successfully");
is($blueprint->code,    'k',    "code parsed successfully");
is($blueprint->as_string, "[I42 D4 F316512 Hfoo]k\n", "stringifies back to the same thing");
is(Blueprint->new_from_string(),      undef, "new_from_string barfs on undef string");
is(Blueprint->new_from_string('wee'), undef, "new_from_string barfs on malformed string");
BEGIN { $num_tests += 8 };

# new_from_file
my ($fh, $fn) = tempfile();
$fh->autoflush(1);
$fh->print($blueprint->as_string);
$blueprint = Blueprint->new_from_file(IO::File->new($fn));
is($blueprint->id,      42,     "id parsed successfully");
is($blueprint->dims,    4,      "dims parsed successfully");
is($blueprint->fitness, 316512, "fitness parsed successfully");
is($blueprint->host,    'foo',  "host parsed successfully");
is($blueprint->code,    'k',    "code parsed successfully");
is($blueprint->as_string, "[I42 D4 F316512 Hfoo]k\n", "stringifies back to the same thing");
BEGIN { $num_tests += 6 };

BEGIN { plan tests => $num_tests };
