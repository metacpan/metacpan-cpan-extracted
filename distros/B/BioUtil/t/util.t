#!/usr/bin/env perl
use Test::Simple tests => 6;

use strict;
use lib '../lib';

use BioUtil::Util;

# =========================================================

my $list = get_file_list(
    "./",
    sub {
        if (/\.pl/i) {
            return 1;
        }
        return 0;
    },
    1
);

ok( @$list == 1 and $$list[0] =~ /Makefile\.PL$/ );

# =========================================================

my $s = "key1=abc; key2=123; conf.a=file; conf.b=12; ";

my $pa = extract_parameters_from_string($s);
ok( keys %$pa == 4 );

# =========================================================

$pa = get_parameters_from_file("t/para.txt");
ok( keys %$pa == 2 );

# =========================================================

$list = get_list_from_file("t/list.txt");
ok( @$list == 2 );

# =========================================================

$list = get_column_data( "t/table.txt", 2 );
ok( @$list == 3 );

# =========================================================

my $hashref = { "a" => 1, "b" => 2, "han" => "汉字" };
my $file = "t/test.json";
write_json_file( $hashref, $file );
my $hash = read_json_file($file);
ok ($$hash{"a"} == 1 && $$hash{"b"} == 2 );
# ok ($$hash{"han"} eq "汉字" );

#  binmode(STDOUT, ":utf8");
# print $$hash{"han"},"\n";
