#! perl -I. -w
use t::Test::abeltje;

use ExtUtils::Manifest qw/ manicheck filecheck /;
$ExtUtils::Manifest::Quiet = 1;

my @missing = filecheck();
if (@missing) {
    diag("Files missing from MANIFEST: @missing");
}
ok(!@missing, "No files missing from MANIFEST");

my @extra = manicheck();
if (@extra) {
    diag("Files in MANIFEST but not here: @extra");
}
ok(!@extra, "No extra files in MANIFEST");

BAIL_OUT("FIX MANIFEST FIRST!") if @missing || @extra;

abeltje_done_testing();
