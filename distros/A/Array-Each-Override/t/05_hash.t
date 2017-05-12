#! /usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;

use File::Find qw<find>;
use Array::Each::Override qw<each>;

my %hash;
find({no_chdir => 1, wanted => sub {
    return if !-f || -B;
    open my $fh, '<', $_
        or return;
    while (my $line = <$fh>) {
        chomp $line;
        $hash{$line}++;
    }
} }, '.');

{
    my (@core_results, @my_results);
    while (my ($k, $v) = CORE::each %hash) {
        push @core_results, [$k, $v];
    }
    while (my ($k, $v) = each %hash) {
        push @my_results, [$k, $v];
    }
    is_deeply(\@my_results, \@core_results, "each %hash returns results");
}
