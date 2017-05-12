#! /usr/bin/perl

use strict;
use warnings;

use blib;

use Benchmark qw<cmpthese>;
use File::Find qw<find>;
use Array::Each::Override qw<:safe>;

my %hash;
find({no_chdir => 1, wanted => sub {
    return if !-f;
    open my $fh, '<', $_
        or return;
    while (my $line = <$fh>) {
        $hash{$line}++;
    }
} }, '.');

print "\neach %hash:\n";
cmpthese(-10, {
    core => sub { my $n = 0;  while (my ($k, $v) = CORE::each %hash) { $n++ } },
    mine => sub { my $n = 0;  while (my ($k, $v) = array_each %hash) { $n++ } },
});

print "\nscalar keys %hash:\n";
cmpthese(-10, {
    core => sub { my $n = CORE::keys %hash },
    mine => sub { my $n = array_keys %hash },
});

print "\nscalar values %hash:\n";
cmpthese(-10, {
    core => sub { my $n = CORE::values %hash },
    mine => sub { my $n = array_values %hash },
});

print "\nlist keys %hash:\n";
cmpthese(-10, {
    core => sub { my $n = 0; $n++ for CORE::keys %hash },
    mine => sub { my $n = 0; $n++ for array_keys %hash },
});

print "\nlist values %hash:\n";
cmpthese(-10, {
    core => sub { my $n = 0; $n++ for CORE::values %hash },
    mine => sub { my $n = 0; $n++ for array_values %hash },
});
