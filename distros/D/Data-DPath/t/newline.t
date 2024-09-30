#! /usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 4;

use Data::Dumper;

use_ok( 'Data::DPath::Path' );

my $value1 = <<"HERE";
foo1 bar1
baz1
HERE

my $value2 = <<"HERE";
foo2 bar2
baz2
HERE

my $data = {
    'details1' => 'foo1 bar1 baz1',
    'details2' => $value2,
};

my $path1 = "/details1[ value eq 'foo1 bar1 baz1' ]";
my $path2 = "/details1[ value eq '$value1' ]";
my $path3 = "/details2[ value eq '$value2' ]";

sub _match {
    my ($path, $data) = @_;
    my $dpath  = Data::DPath::Path->new( path => $path );
    return $dpath->matchr($data);
}

my $expected_res1 = ['foo1 bar1 baz1'];
my $expected_res2 = [];
my $expected_res3 = [$value2];

is_deeply(_match($path1, $data), $expected_res1, 'found expected result: ["foo1 bar1 baz1"]');
 TODO: {
     local $TODO = "Unclear handling of newlines in data";
     is_deeply(_match($path2, $data), $expected_res2, 'found expected result: []');
};
is_deeply(_match($path3, $data), $expected_res3, "found expected result: [$value2]");

