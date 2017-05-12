# -*- perl -*-
use strict;
use warnings;
use Test::More tests => 39;
use Path::Class qw{file};

BEGIN { use_ok( 'DBIx::Array::Connect' ); }

my $dir=file($0)->dir;

my $dac=DBIx::Array::Connect->new;
isa_ok($dac, 'DBIx::Array::Connect');
can_ok($dac, qw{new initialize});
can_ok($dac, qw{cfg file basename path});
can_ok($dac, qw{connect});

isa_ok($dac->path, "ARRAY");
is(scalar(@{$dac->path}), 1, "sizeof");

isa_ok($dac->path(qw{. ..}), "ARRAY");
is(scalar(@{$dac->path}), 2, "sizeof");
is($dac->path->[0], ".", "path method");
is($dac->path->[1], "..", "path method");

isa_ok($dac->path($dir), "ARRAY");
is(scalar(@{$dac->path}), 1, "sizeof");
is($dac->path->[0], $dir, "path method");

is($dac->basename, "database-connections-config.ini", "basename method default");
is($dac->basename("cool.ini"), "cool.ini", "basename method");
is($dac->basename("db-config.ini"), "db-config.ini", "basename method");

is($dac->file, file($dir=>"db-config.ini"), "file method");
is($dac->basename("foo.ini"), "foo.ini", "basename method");
is($dac->path("bar")->[0], "bar", "path method");
is($dac->file, file($dir=>"db-config.ini"), "file method is cached");

my $sections=$dac->sections;
isa_ok($sections, "ARRAY", "sections method");
is(scalar(@$sections), 4, "sizeof");
is($sections->[0], "db1");
is($sections->[1], "db-foo");
is($sections->[2], "db-bar");
is($sections->[3], "db-baz");

$sections=$dac->sections("db");
isa_ok($sections, "ARRAY", "sections method");
is(scalar(@$sections), 1, "sizeof");
is($sections->[0], "db1");

$sections=$dac->sections("foo");
isa_ok($sections, "ARRAY", "sections method");
is(scalar(@$sections), 1, "sizeof");
is($sections->[0], "db-foo");

$sections=$dac->sections("bar");
isa_ok($sections, "ARRAY", "sections method");
is(scalar(@$sections), 2, "sizeof");
is($sections->[0], "db-bar");
is($sections->[1], "db-baz");

$sections=$dac->sections("baz");
isa_ok($sections, "ARRAY", "sections method");
is(scalar(@$sections), 0, "sizeof");
