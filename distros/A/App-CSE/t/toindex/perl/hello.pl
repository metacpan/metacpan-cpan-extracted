#! /usr/bin/env perl

use Hello;

print "Bonjour world. Bonnaventure\n";

my $hello = Hello->new();

$hello->some_method();

Hello::class_method();

exported_method();
