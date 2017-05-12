#!/usr/bin/perl

use IO::Scalar;
my ($out, $SH);
BEGIN {
  $SH = new IO::Scalar \$out;
};

use Acme::Echo qw/after/, 'src_fmt' => "CODE RAN WAS:<br>\n<pre>\n%s\n</pre>\n", fh => $SH;

use strict;
use warnings;
use Test::More tests => 2;
my $s = 0;
foreach (1 .. 10){
  $s += $_;
}

no Acme::Echo;

my $expected = do { local $/ = undef; <DATA> };
is( $out, $expected, "output matches" );
is( $s, 55, "s=55" );

__DATA__
CODE RAN WAS:<br>
<pre>

use strict;
use warnings;
use Test::More tests => 2;
my $s = 0;
foreach (1 .. 10){
  $s += $_;
}


</pre>
