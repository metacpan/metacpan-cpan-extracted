#!/usr/bin/perl
package Constants;
use strict;
use warnings;

use base qw(Exporter);
our (@EXPORT,@EXPORT_OK, %EXPORT_TAGS);
use Constant::Generate
    [qw(CONST_ONE CONST_TWO)],
    -start_at => 1;
    
use Test::More;

ok(CONST_ONE == 1 && CONST_TWO == 2, "Integer counters");

use Constant::Generate
    [qw(FLAG_ONE FLAG_TWO)],
    -type => "bitfield",
    -mapname => "bit_to_str";
    
ok(FLAG_ONE == 1 << 0 && FLAG_TWO == 1 << 1, "Bitfield counters");
my $s = bit_to_str(FLAG_ONE|FLAG_TWO);
ok($s =~  /ONE/ && $s =~ /TWO/, "Bitfield strings");

use Constant::Generate {
    FOO => 42,
    BAR => 666,
},
    -type => "integer",
    -mapname => "int_to_str";

ok(FOO == 42 && BAR == 666, "Manual values");
ok(int_to_str(FOO) eq 'FOO' && int_to_str(BAR) eq 'BAR', "Manual stringify");

use Constant::Generate
    [qw(EXPORTED_FOO EXPORTED_BAR EXPORTED_BAZ)],
    -type => "bitfield",
    -start_at => 4,
    -tag => 'exconst',
    -export_ok => 1,
    -export_tags => 1;


use Constant::Generate
    [qw(SIMPLE_ONE SIMPLE_TWO)],
    export => 1;

package User;
use Test::More;

BEGIN {
    Constants->import(':exconst');
}

my $flags = EXPORTED_FOO | EXPORTED_BAR | EXPORTED_BAZ;
ok(
    exconst_to_str($flags) =~ /FOO/ &&
    exconst_to_str($flags) =~ /BAR/ &&
    exconst_to_str($flags) =~ /BAZ/,
    "Exported");
done_testing();