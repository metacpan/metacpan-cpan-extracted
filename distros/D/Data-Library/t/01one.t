#!/usr/bin/perl

use strict;
use Test::Simple tests => 3;

use Data::Library::OnePerFile;
use Log::Channel;

disable Log::Channel "Data::Library";
Log::Channel->commandeer ("Data::Library");

#disable Log::Channel 
# test scenario - finding length of strings in the library

my $lib = new Data::Library::OnePerFile({LIB => "t/ts",
					 EXTENSION => "str",
					});

my @items = $lib->toc;
ok($#items == 1 && $items[0] eq "foo" && $items[1] eq "two",
   "toc");

ok(check("foo"), "should work");
ok(!check("bar"), "missing file");

sub check {
    my ($tag) = @_;

    my $string = $lib->lookup($tag);
    if (!$string) {
	$string = $lib->find($tag);
    }
    return if !$string;

    my $len = length($string);
    $lib->cache($tag, $len);

    return 1;
}

