#!/usr/bin/env perl

use strict;
use Test::More;
use Test::Exception;

my $pkg;
BEGIN {
  $pkg = 'Catmandu::Fix::uuid';
  use_ok $pkg;
}
require_ok $pkg;

dies_ok {$pkg->new()->fix({})} "path required";

lives_ok {$pkg->new('my.field')->fix({})} "path required";

my $x = $pkg->new('my.field')->fix({});

like $x->{my}->{field} , qr/^[0-9a-f-]+$/, "generate a new uuid";

my $y = $pkg->new('my.field')->fix({ my => { field => "!!!" }});

like $x->{my}->{field} , qr/^[0-9a-f-]+$/, "generate a new uuid in existing field";

done_testing;