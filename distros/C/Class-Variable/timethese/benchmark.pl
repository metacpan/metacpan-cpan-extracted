#!/usr/bin/perl -I../blib/lib -I../blib/arch -I../t
use Foo;
my $foo = Foo->new();
$foo->benchmark();
