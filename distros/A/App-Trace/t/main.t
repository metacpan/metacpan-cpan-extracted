#!/usr/local/bin/perl -w

use Test::More qw(no_plan);
use lib "lib";
use lib "../lib";

use App::Options;

my ($dir);

$dir = ".";
$dir = "t" if (! -f "main.t");

use_ok("App::Trace", "Loaded App::Trace OK");

exit(0);


exit 0;

__END__

sub printargs {
sub sub_entry {
sub sub_exit {
sub in_debug_scope {
sub debug_indent {

