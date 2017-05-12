#!/usr/local/bin/perl -wT
use strict;
use warnings;

use AnyData;
use Test::More;

my $table =
  adTie( 'CSV',
    ["word,number\none,1\ntwo,2\nthree,3\nunknown\nunknowncomma,\nzero,0"] );

eval { require Test::Output; Test::Output->import(); };
if ($@) {
    plan tests => 1;
}
else {
    plan tests => 2;

    #adDump prints to SDTOUT :/
    stdout_is( sub { adDump($table) }, <<'HERE', 'export fixed format' );
<word:number>
[one][1]
[two][2]
[three][3]
[unknown][]
[unknowncomma][]
[zero][0]
HERE
}

ok( 6 == adRows($table), "Failed rows" );

__END__
