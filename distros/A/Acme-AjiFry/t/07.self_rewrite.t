#!perl

use strict;
use utf8;
use File::Compare;
use File::Copy;
use File::Spec::Functions qw/catfile/;
use FindBin;

use Test::More;

my $rewrite            = catfile($FindBin::Bin, 'rewrite');
my $original_rewrite   = catfile($FindBin::Bin, 'rewrite.orig');
my $translated_rewrite = catfile($FindBin::Bin, 'rewrite.translated');
File::Copy::copy $original_rewrite, $rewrite;

my $got;
$got = `$^X $rewrite`;
is($got, 'hello', 'rewrite: stdout-1');
$got = File::Compare::compare($rewrite, $translated_rewrite);
is($got, 0, 'rewrite: Translate truly?');
$got = `$^X $rewrite`;
is($got, 'hello', 'rewrite: stdout-2');

done_testing();
