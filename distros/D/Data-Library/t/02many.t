#!/usr/bin/perl

use strict;
use Test::Simple tests => 5;

use Data::Library::ManyPerFile;
use Log::Channel;

disable Log::Channel "Data::Library";
Log::Channel->commandeer ("Data::Library");

my $lib2 = new Data::Library::ManyPerFile({LIB => "t/ts",
					   EXTENSION => "multi",
					  });

my @items = $lib2->toc;
ok($#items == 2, "toc count");

ok(check("foo"));
ok(check("bar"));
ok(check("baz"));
ok(!check("missing"));

sub check {
    my ($tag) = @_;

    my $string = $lib2->lookup($tag);
    if (!$string) {
	$string = $lib2->find($tag);
    }
    return if !$string;

    my $len = length($string);
    $lib2->cache($tag, $len);

    return 1;
}
