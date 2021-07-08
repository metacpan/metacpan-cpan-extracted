package Helpers;
use v5.24;
use warnings;
use experimental 'signatures';
no warnings 'experimental::signatures';

use Exporter 'import';
our @EXPORT = qw< sibling_of tpath >;

use File::Spec;

sub sibling_of ($reference, @path) {
   my ($v, $ds, $file) = File::Spec->splitpath($reference, -d $reference);
   $file = pop @path;
   $ds = File::Spec->catdir(File::Spec->splitdir($ds), @path) if @path;
   return File::Spec->catpath($v, $ds, $file);
} ## end sub sibling_of

sub tpath (@path) { sibling_of(__FILE__, @path) }

1;
